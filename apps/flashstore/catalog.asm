; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2005
;
; FlashStore is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

Module CatalogFiles

; This module contains the file navigation functionality in the File Area Window.

     xdef DispFilesWindow, DispFiles, FilesAvailable
     xdef CompressedFileEntryName
     xdef MoveToFirstFile
     xdef MoveToLastFile
     xdef InitFirstFileBar
     xdef FileSelected
     xdef MoveFileBarDown
     xdef MoveFileBarUp

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprLastFile           ; Return poiter to last File Entry on File Eprom
     lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
     lib FileEprPrevFile           ; Return pointer to previous File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprCntFiles           ; Return total of active and deleted files
     lib FileEprFileStatus         ; Return Active/Deleted status of file entry

     xref DispMainWindow, DisplBar
     xref IntAscii
     xref disp_no_filearea_msg
     xref cls, rightjustify, leftjustify
     xref yesno, no_msg, done_msg
     xref pwait, rdch
     xref VduCursor
     xref no_files                 ; errmsg.asm

     ; system definitions
     include "stdio.def"
     include "fileio.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
; Initialize File Bar (CursorFilePtr) to first point at first file entry in File Area.
;
; Returns
;       Fc = 0
;       BHL = pointer to first file
;       (CursorFilePtr) = BHL
;
; If no file area were found, or no files present in file area:
;       Fc = 1
;       (CursorFilePtr) = 0
;
.InitFirstFileBar
                    xor  a
                    ld   (FileBarPosn),a        ; File Bar at top of window

                    ld   a,(curslot)
                    ld   c,a
                    push bc                     ; File Area in slot C?
                    call FileEprRequest
                    pop  bc
                    jr   c, nofilesavail        ; no file area...
                    jr   nz, nofilesavail

                    call FileEprCntFiles        ; any files available in File Area?
                    ld   a,h
                    or   l
                    or   d
                    or   e
                    jr   z, nofilesavail        ; no files available...

                    call FileEprFirstFile       ; get BHL of first file in File area
.getFirstFile       jr   c, nofilesavail        ; hmm..
                    jr   nz, foundFile

                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e                      ; CDE = 0?
                    jr   nz, foundFile          ; accept normal deleted file...
                    call FileEprNextFile        ; skip system file
                    jr   c, nofilesavail        ; officially, file area is empty...
.foundFile
                    ld   (CursorFilePtr),hl
                    ld   a,b
                    ld   (CursorFilePtr+2),a
                    ret
.nofilesavail
                    xor  a
                    ld   h,a
                    ld   l,a
                    ld   (CursorFilePtr),hl
                    ld   (CursorFilePtr+2),a    ; indicate no files (pointer = 0)
                    scf
                    ret


; *************************************************************************************
; Move the File Bar one file down the list - scroll the window contents one line
; upwards and display next file line, when file bar goes beyond the window bottom
;
.MoveToLastFile
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprLastFile
                    ret  c                      ; File Area not available...

                    push bc
                    push hl                     ; CursorFilePtr = FileEprLastFile(slot)
                    ld   e,0
.fill_loop
                    ld   a,6
                    cp   e
                    jr   z, exit_fill_loop      ; try to fill window (7 lines) from bottom...
                    inc  e
                    ld   (CursorFilePtr),hl
                    ld   a,b
                    ld   (CursorFilePtr+2),a

                    call FileEprPrevFile
                    jr   c, exit_fill_loop      ; reached top of files!
                    jr   nz, fill_loop          ; previous file was available, go back one more
                    push de
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e
                    pop  de
                    jr   nz, fill_loop          ; deleted file wasn't Intel system file...
.exit_fill_loop
                    dec  e
                    ld   a,e
                    ld   (FileBarPosn),a        ; File Bar position at last file
                    CALL DispFiles

                    pop  hl
                    pop  bc
                    ld   (CursorFilePtr),hl
                    ld   a,b
                    ld   (CursorFilePtr+2),a    ; real last file pointer
                    ret


; *************************************************************************************
; Move the File Bar one file up the list - scroll the window contents one line
; downwards and display previous file line, when file bar goes beyond the window bottom
;
.MoveFileBarUp
                    ld   hl,(CursorFilePtr)
                    ld   a,(CursorFilePtr+2)
                    ld   b,a
                    call FileEprPrevFile
                    jr   c, MoveToLastFile      ; File Bar at top of file list, wrap to last...
                    jr   nz, dispPrevFile       ; previous file is available, display it...
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e
                    jr   nz, dispPrevFile
                    jr   MoveToLastFile         ; ignore hidden system file, wrap to last file...
.dispPrevFile
                    ld   (CursorFilePtr),hl
                    ld   a,b
                    ld   (CursorFilePtr+2),a    ; CursorFilePtr = FileEprPrevFile(CursorFilePtr)

                    ld   a,(FileBarPosn)
                    cp   0
                    jr   z, scroll_filearea_down
                    dec  a
                    ld   (FileBarPosn),a
                    ret
.scroll_filearea_down
                    push bc
                    push hl
                    ld   hl, scroll_up
                    call_oz Gn_sop

                    LD   B,0
                    LD   A,(FileBarPosn)        ; get Y position of File Bar
                    LD   C,A
                    Call VduCursor
                    pop  hl
                    pop  bc

                    call DisplayFile
                    ret


; *************************************************************************************
; Move the File Bar one file down the list - scroll the window contents one line
; upwards and display next file line, when file bar goes beyond the window bottom
;
.MoveFileBarDown
                    ld   hl,(CursorFilePtr)
                    ld   a,(CursorFilePtr+2)
                    ld   b,a
                    call FileEprNextFile
                    jr   c, MoveToFirstFile     ; File Bar at end of file list, wrap to first...

                    ld   (CursorFilePtr),hl
                    ld   a,b
                    ld   (CursorFilePtr+2),a    ; CursorFilePtr = FileEprNextFile(CursorFilePtr)

                    ld   a,(FileBarPosn)
                    cp   6
                    jr   z, scroll_filearea_up
                    inc  a                      ; file cursor in window not yet reached bottom line...
                    ld   (FileBarPosn),a
                    ret
.scroll_filearea_up                             ; cursor at bottom line, scroll window contents
                    push bc                     ; one line upwards and display the next file
                    push hl                     ; at bottom line of window
                    ld   hl, scroll_down
                    call_oz Gn_sop

                    LD   B,0
                    LD   A,(FileBarPosn)        ; get Y position of File Bar
                    LD   C,A
                    Call VduCursor

                    pop  hl
                    pop  bc
                    call DisplayFile
                    ret


; *************************************************************************************
; Move the File Bar to top of file list, place window cursor at top line in window
; and display the file list.
.MoveToFirstFile    call InitFirstFileBar       ; File Bar placed at first file in area
                    ret  c                      ; no files
                    call DispFiles              ; update file area window.
                    ret


; *************************************************************************************
; Display name and size of stored files on Flash Eprom.
;
.DispFilesWindow
                    ld   hl, filearea_banner
                    call DispMainWindow

                    xor  a
                    ld   (FileBarPosn),a        ; File Bar at top of window

                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    jr   z, check_availfiles    ; File Area header was found..
                    call disp_no_filearea_msg
                    ret                         ; abort - File Area apparently not available...
.check_availfiles
                    call FilesAvailable
                    push af
                    call z,nofilesavail
                    pop  af
                    jp   z, no_files            ; Fz = 1, no files available...
.DispFiles
                    call cls
                    res  1,(iy+0)               ; preset to no lines displayed

                    xor  a
                    ld   hl, linecnt
                    ld   (hl),a
.begin_catalogue
                    ld   hl,(CursorFilePtr)
                    ld   a,(CursorFilePtr+2)
                    ld   b,a
.cat_main_loop
                    call DisplayFile
                    ret  c
.get_next_filename
                    call FileEprNextFile        ; get pointer to next File Entry in BHL...

                    bit  1,(iy+0)
                    jr   z, cat_main_loop       ; no file were displayed, fetch new filename
                    push hl
                    res  1,(iy+0)
                    ld   hl, linecnt
                    inc  (hl)
                    ld   a,7
                    cp   (hl)
                    jr   nz,next_row
                    ld   (hl),0
                    pop  hl
                    ret
.next_row
                    CALL_OZ gn_nln
                    pop  hl
                    jp   cat_main_loop

.norm_aff           ld   hl,norm_sq
                    jr   dispsq
.tiny_aff           ld   hl,tiny_sq
                    jr   dispsq
.jrsz_aff           ld   hl, rightjustify
                    jr   dispsq
.jnsz_aff           ld   hl, leftjustify
.dispsq             push af
                    CALL_OZ gn_sop
                    pop  af
                    ret



; *************************************************************************************
; Display file name and size information to current VDU cursor in current active
; windfow, as defined by file entry BHL.
;
.DisplayFile
                    call FileEprFileStatus
                    jr   c, end_cat             ; Ups - last file(name) has been displayed...
                    jr   nz, disp_filename      ; active file, display...

                    ex   af,af'
                    bit  0,(iy+0)
                    jr   z,get_next_filename    ; ignore deleted file(name)...
                    ex   af,af'

.disp_filename      set  1,(iy+0)               ; indicate display of filename...
                    call CompressedFileEntryName
                    push bc
                    push hl

                    push de
                    call nz,norm_aff
                    call z,tiny_aff
                    pop  hl
                    CALL_OZ(Gn_sop)             ; display filename

                    pop  hl
                    pop  bc
                    push bc
                    push hl
                    call FileEprFileSize        ; get size of File Entry in CDE
                    ld   (flen),de
                    ld   b,0
                    ld   (flen+2),bc

                    call jrsz_aff
                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop              ; display size of current File Entry
                    call jnsz_aff
                    pop  hl
                    pop  bc
                    ret
.end_cat
                    push af
                    ld   hl,endf_msg
                    CALL_OZ gn_sop
                    pop  af
                    ret


; *************************************************************************************
; Fetches the filename of the current file entry (supplied as BHL) The filename is
; compressed using GN_Fcm to use max. 45 characters (so that a very long filename
; can be displayed sensibly in the file area window).
;
; IN:
;    BHL = pointer to current File Entry (B = absolute bank number)
;
; OUT:
;    DE = local pointer to compressed filename
.CompressedFileEntryName
                    push af
                    push bc
                    push hl

                    ld   de, buffer             ; write filename at (DE), null-terminated
                    call FileEprFilename        ; copy filename from current file entry at (DE)
                    jr   c, end_GetCompressedFilename
                    cp   42
                    jr   c, end_GetCompressedFilename  ; complete filename fits within 43 characters
                    ex   de,hl
                    ld   b,0                    ; HL pointer to local filename
                    ld   c,42                   ; compressed filename max. 45 chars (including '/..')
                    ld   de,buf1                ; make compressed filename at buf1
                    push de
                    ld   a,'/'
                    ld   (de),a
                    inc  de
                    ld   a,'.'
                    ld   (de),a
                    inc  de
                    ld   (de),a                 ; preset the filename with '/..' before compressed filename
                    inc  de
                    call_oz GN_Fcm              ; compress filename..
                    xor  a
                    ld   (de),a                 ; null-terminate
                    pop  de                     ; start of compressed filename
.end_GetCompressedFilename
                    pop  hl
                    pop  bc
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; Check if there's active/deleted files availabe in the File Area
;
.FilesAvailable
                    push bc
                    push de
                    push hl

                    ld   a,(curslot)
                    ld   c,a
                    call FileEprCntFiles          ; any files available in File Area?
                    jr   c, exit_checkfiles       ; no file area!
                    ld   a,h
                    or   l
                    jr   nz, exit_checkfiles      ; active files available...
                    ld   a,d
                    or   e
                    jr   z, exit_checkfiles       ; no active nor deleted files available...
                    cp   1                        ; check for Intel deleted file...
.exit_checkfiles
                    pop  hl
                    pop  de
                    pop  bc
                    ret


; *************************************************************************************
; constants
.filearea_banner    DEFM "FILE AREA", 0
.norm_sq            DEFM 1,"2-G",1,"4+TRUF",1,"4-TRU ",0
.tiny_sq            DEFM 1,"5+TRGUd",1,"3-RU ",0

.endf_msg           DEFM 1,"2-G",1,"4+TUR END ",1,"4-TUR",0
.scroll_up          DEFM 1, SD_UP, 0
.scroll_down        DEFM 1, SD_DWN, 0

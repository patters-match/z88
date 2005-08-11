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

Module BrowseFiles

; This module contains the file navigation functionality in the File Area Window.

     xdef DispFilesWindow, DispFiles, FilesAvailable
     xdef StoreCursorFilePtr, GetCursorFilePtr
     xdef CompressedFileEntryName
     xdef MoveFileBarDown, MoveFileBarUp
     xdef MoveToFirstFile, MoveToLastFile
     xdef MoveFileBarPageDown, MoveFileBarPageUp
     xdef InitFirstFileBar
     xdef PollFileArea
     xdef FileSelected
     xdef GetFirstFilePtr, GetNextFilePtr
     xdef FileAreaBannerText
     xdef endf_msg

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprLastFile           ; Return poiter to last File Entry on File Eprom
     lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
     lib FileEprPrevFile           ; Return pointer to previous File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprCntFiles           ; Return total of active and deleted files
     lib FileEprFileStatus         ; Return Active/Deleted status of file entry

     xref DispMainWindow, cls      ; fsapp.asm
     xref DisplBar                 ; fsapp.asm
     xref rightjustify             ; fsapp.asm
     xref leftjustify              ; fsapp.asm
     xref yesno, no_msg            ; fsapp.asm
     xref pwait, rdch              ; fsapp.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref no_files                 ; errmsg.asm
     xref IntAscii                 ; filestat.asm
     xref done_msg                 ; fetchfile.asm
     xref VduCursor                ; selectcard.asm

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

                    call FilesAvailable         ; any files available in File Area?
                    jp   c, ResetFilePtr        ; no file area...
                    jp   z, ResetFilePtr        ; no files available...

                    ld   a,(curslot)
                    ld   c,a
                    call GetFirstFilePtr        ; get BHL of first file in File area in slot C
                    jp   c, ResetFilePtr        ; hmm..
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr)
                    ld   a,255
                    or   a                      ; Fc = 0, Fz = 0
                    ret
; *************************************************************************************


; *************************************************************************************
; Move the File Bar to top of file list, place window cursor at top line in window
; and display the file list.
.MoveToFirstFile    call InitFirstFileBar       ; File Bar placed at first file in area
                    ret  c                      ; no files
                    call DispFiles              ; update file area window.
                    ld   a,255
                    or   a                      ; Fc = 0, Fz = 0
                    ret
; *************************************************************************************


; *************************************************************************************
; Move the File Bar one file down the list - scroll the window contents one line
; upwards and display next file line, when file bar goes beyond the window bottom
;
.MoveToLastFile
                    ld   a,(curslot)
                    ld   c,a
                    call GetLastFilePtr
                    ret  c                      ; File Area not available...

                    push bc
                    push hl
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), CursorFilePtr = FileEprLastFile(slot)
                    ld   c,6
                    call pageup_loop            ; move 6 file entries upwards, if possible. C return no of entries left of 6
                    ld   a,6
                    sub  c
                    ld   (FileBarPosn),a        ; File Bar at last file entry in window
                    pop  hl
                    pop  bc
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), CursorFilePtr = FileEprLastFile(slot)
                    ld   a,255
                    or   a                      ; Fc = 0, Fz = 0
                    ret
; *************************************************************************************


; *************************************************************************************
; Move the File Bar one file up the list - scroll the window contents one line
; downwards and display previous file line, when file bar goes beyond the window bottom
;
.MoveFileBarUp
                    call GetCursorFilePtr       ; BHL <-- (CursorFilePtr)
                    call GetPrevFilePtr
                    jr   c, MoveToLastFile      ; File Bar at top of file list, wrap to last...
                    jr   nz, dispPrevFile       ; previous file is available, display it...
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e
                    jr   nz, dispPrevFile
                    jr   MoveToLastFile         ; ignore hidden system file, wrap to last file...
.dispPrevFile
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), CursorFilePtr = GetPrevFilePtr(CursorFilePtr)

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

                    LD   A,(FileBarPosn)        ; get Y position of File Bar
                    LD   B,A
                    LD   C,0                    ; start of line
                    Call VduCursor
                    pop  hl
                    pop  bc

                    call DisplayFile
                    ret
; *************************************************************************************


; *************************************************************************************
; Move the File Bar one file down the list - scroll the window contents one line
; upwards and display next file line, when file bar goes beyond the window bottom
;
.MoveFileBarDown
                    call GetCursorFilePtr       ; BHL <-- (CursorFilePtr)
                    call GetNextFilePtr
                    jr   c, MoveToFirstFile     ; File Bar at end of file list, wrap to first...

                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), CursorFilePtr = GetNextFilePtr(CursorFilePtr)
                    ld   a,(FileBarPosn)
                    cp   6
                    jr   z, scroll_filearea_up
                    inc  a                      ; file cursor in window not yet reached bottom line...
                    ld   (FileBarPosn),a
                    or   a                      ; Fc = 0, Fz = 0
                    ret
.scroll_filearea_up                             ; cursor at bottom line, scroll window contents
                    push bc                     ; one line upwards and display the next file
                    push hl                     ; at bottom line of window

                    ld   hl, scroll_down
                    call_oz Gn_sop

                    LD   A,(FileBarPosn)        ; get Y position of File Bar
                    LD   B,A
                    LD   C,0                    ; start of line...
                    Call VduCursor

                    pop  hl
                    pop  bc
                    call DisplayFile
                    ld   a,255
                    or   a                      ; Fc = 0, Fz = 0
                    ret
; *************************************************************************************


; *************************************************************************************
; Move the File Bar one page up (7 items) in the list of file entries -
; Clear window and position the Bar cursor at the top line and list file entries.
;
.MoveFileBarPageUp
                    xor  a
                    ld   (FileBarPosn),a        ; File Bar at top of window
                    ld   c,7                    ; move 7 file entries upwards, if possible
.pageup_loop
                    call GetCursorFilePtr       ; BHL <-- (CursorFilePtr)
                    call GetPrevFilePtr
                    jr   c, end_MovePgUp        ; reached top of list, update file area window
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), CursorFilePtr = GetPrevFilePtr(CursorFilePtr)
                    dec  c
                    jr   nz, pageup_loop
.end_MovePgUp       jp   DispFiles
; *************************************************************************************


; *************************************************************************************
; Move the File Bar one page down (7 items) in the list of file entries -
; Clear window and position the Bar cursor at the top line and list file entries.
;
.MoveFileBarPageDown
                    xor  a
                    ld   (FileBarPosn),a        ; File Bar at top of window
                    ld   c,7                    ; move 7 file entries downwards, if possible
.pagedwn_loop
                    call GetCursorFilePtr       ; BHL <-- (CursorFilePtr)
                    call GetNextFilePtr
                    jr   c, end_MovePgDwn       ; reached bottom of list, update file area window
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), CursorFilePtr = GetNextFilePtr(CursorFilePtr)
                    dec  c
                    jr   nz, pagedwn_loop
.end_MovePgDwn      jp   DispFiles
; *************************************************************************************


; *************************************************************************************
; Poll current file area, and update File entry pointer if necessary
;
.PollFileArea
                    call FilesAvailable
                    jp   c, ResetFilePtr          ; no file area found in slot
                    jp   z, ResetFilePtr          ; no files in file area

                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr)
                    or   h
                    or   l
                    call z,InitFirstFileBar       ; File Entry was zero, initialize to first in file area

                    call FileEprFileStatus
                    ret  nz                       ; current file entry is active, all OK whatever view...
                    bit  dspdelfiles,(iy+0)
                    ret  nz                       ; current deleted file may be displayed (display deleted files mode)...
                    call MoveFileBarDown          ; get next (active) file to be displayed, Fc = 1, if there is no next file...
                    jp   c, ResetFilePtr
                    ret
; *************************************************************************************


; *************************************************************************************
; Display name and size of stored files on Flash Eprom.
;
.DispFilesWindow
                    ld   hl, filearea_banner
                    ld   bc, 9
                    call FileAreaBannerText       ; HL = banner for file area window
                    call DispMainWindow

                    call PollFileArea
                    jp   c, disp_no_filearea_msg  ; file area not available
                    jp   z, no_files              ; Fz = 1, no files available in file area...
.DispFiles
                    call cls
                    xor  a
                    ld   (linecnt),a
                    xor  a
                    ld   (FileBarPosn),a          ; File Bar at top of window
                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr)
.cat_main_loop
                    call DisplayFile
                    ret  c
.get_next_filename
                    call GetNextFilePtr           ; get pointer to next File Entry in BHL...
                    push hl
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


; *************************************************************************************
; Make the banner for the file area window.
; Depending on the current view settings, the banner text is dynamically created
; as follows:
;    "FILE AREA [VIEW SAVED & DELETED FILES]" or
;    "FILE AREA [VIEW ONLY SAVED FILES]"
;
; IN:
;       HL = Base banner text
;       BC = length of banner text
;
.FileAreaBannerText
                    ld   de, buf3
                    push de
                    ldir
                    ld   hl, allfiles_banner
                    ld   c, 29
                    bit  dspdelfiles,(iy+0)
                    jr   nz, append_viewtypetext  ; all files are displayed
                    ld   hl, savedfiles_banner
                    ld   c, 24                    ; only saved files displayed
.append_viewtypetext
                    ldir
                    xor  a
                    ld   (de),a                   ; null-terminate completed banner string
                    pop  hl                       ; return pointer to start of banner text.
                    ret
; *************************************************************************************


; *************************************************************************************
; Display file name and size information to current VDU cursor in current active
; window, as defined by file entry BHL.
;
.DisplayFile
                    call FileEprFileStatus
                    jr   c, end_cat             ; Ups - last file(name) has been displayed...
                    jr   nz, disp_filename      ; active file, display...

                    ex   af,af'
                    cp   a                      ; fc = 0...
                    bit  dspdelfiles,(iy+0)
                    ret  z                      ; ignore deleted file(name)...
                    ex   af,af'

.disp_filename      ld   de,buffer
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


; *************************************************************************************
; Fetches the filename of the current file entry (supplied as BHL) The filename is
; compressed using GN_Fcm to use max. 45 characters (so that a very long filename
; can be displayed sensibly in the file area window).
;
; IN:
;    DE  = local pointer to compressed filename
;    BHL = pointer to current File Entry (B = absolute bank number)
;
; OUT:
;    DE = DE(in)
.CompressedFileEntryName
                    push af
                    push bc
                    push hl
                                                ; write filename at (DE), null-terminated
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
; Check if there's active/deleted files availabe in the current File Area.
; If current file display setting signals also display of deleted files, Fz = 1 is
; returned if there are also no deleted files.
;
; return Fz = 1, if no files available, and Fc = 1 if no file area available.
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

                    bit  dspdelfiles,(iy+0)       ; no active files, are deleted files to be displayed in file area?
                    jr   z, exit_checkfiles       ; no, only active files are displayed, then signal no files...
                    ld   a,e
                    or   d                        ; If no deleted files are available, then Fz = 0...
.exit_checkfiles
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************

; *************************************************************************************
; Get pointer to first file entry. If only active files are currently displayed,
; deleted file entries are skipped until an active file entry is found.
;
; IN:
;    C = slot number of File area
;
; OUT:
;    Fc = 1, End of list reached
;    Fc = 0
;         BHL = pointer to first file entry
;
.GetFirstFilePtr
                    call FileEprFirstFile
                    ret  c
                    ret  nz                       ; an active file entry was found...
.found_delfile
                    bit  dspdelfiles,(iy+0)       ; are deleted files to be displayed in file area?
                    call z,GetNextFilePtr         ; skip deleted file(s) until active file is found
                    ret                           ; (and return BHL to that entry)
; *************************************************************************************


; *************************************************************************************
; Get pointer to next file entry. If only active files are currently displayed,
; deleted file entries are skipped until an active file entry is found.
;
; IN:
;    BHL = current file entry pointer
;
; OUT:
;    Fc = 1, End of list reached
;    Fc = 0
;         BHL = pointer to next file entry
;
.GetNextFilePtr
.fetch_next_loop
                    call FileEprNextFile
                    ret  c
                    ret  nz                       ; an active file entry was found...

                    bit  dspdelfiles,(iy+0)       ; are deleted files to be displayed in file area?
                    jr   z, fetch_next_loop       ; only active files, scan forward until active file..
                    ret                           ; return 'marked as deleted' file entry
; *************************************************************************************


; *************************************************************************************
; Get pointer to previous file entry. If only active files are currently displayed,
; deleted file entries are skipped until an active file entry is found.
;
; IN:
;    BHL = current file entry pointer
;
; OUT:
;    Fc = 1, Top of list reached
;    Fc = 0
;         BHL = pointer to previous file entry
;
.GetPrevFilePtr
.fetch_prev_loop
                    call FileEprPrevFile
                    ret  c
                    ret  nz                       ; an active file entry was found...

                    bit  dspdelfiles,(iy+0)       ; are deleted files to be displayed in file area?
                    jr   z, fetch_prev_loop       ; only active files, scan backward until active file..
                    ret                           ; return 'marked as deleted' file entry
; *************************************************************************************


; *************************************************************************************
; Get pointer to last file entry. If only active files are currently displayed,
; deleted file entries are skipped (backwards) until an active file entry is found.
;
; IN:
;    C = slot number of File area
;
; OUT:
;    Fc = 1, End of list reached
;    Fc = 0
;         BHL = pointer to first file entry
;
.GetLastFilePtr
                    call FileEprLastFile
                    ret  c
                    ret  nz                       ; an active file entry was found...

                    bit  dspdelfiles,(iy+0)       ; are deleted files to be displayed in file area?
                    call z,GetPrevFilePtr         ; skip deleted file(s) backward until active file is found
                    ret                           ; (and return BHL to that entry)
; *************************************************************************************


; *************************************************************************************
; BHL --> (CursorFilePtr)
;
.StoreCursorFilePtr
                    ld   (CursorFilePtr),hl
                    ld   a,b
                    ld   (CursorFilePtr+2),a    ; real last file pointer
                    ret
; *************************************************************************************


; *************************************************************************************
; BHL <-- (CursorFilePtr)
;
.GetCursorFilePtr
                    ld   hl,(CursorFilePtr)
                    ld   a,(CursorFilePtr+2)
                    ld   b,a
                    ret
; *************************************************************************************


; *************************************************************************************
.ResetFilePtr
                    ld   b,0
                    ld   h,b
                    ld   l,b
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), indicate no files (pointer = 0)
                    LD   (barMode),A            ; get cursor out of file window
                    ret
; *************************************************************************************


; *************************************************************************************
; constants
;
.filearea_banner    DEFM "FILE AREA"
.allfiles_banner    DEFM " [VIEW SAVED & DELETED FILES]"
.savedfiles_banner  DEFM " [VIEW ONLY SAVED FILES]"

.norm_sq            DEFM 1,"2-G",1,"4+TRUF",1,"4-TRU ",0
.tiny_sq            DEFM 1,"5+TRGUd",1,"3-RU ",0

.endf_msg           DEFM 1,"2-G",1,"4+TUR END ",1,"4-TUR",0
.scroll_up          DEFM 1, SD_UP, 0
.scroll_down        DEFM 1, SD_DWN, 0

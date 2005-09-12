; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2005
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
     xdef ResetFilesWindow, PollFileCardWatermark, ResetWatermark
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
     xdef LeftJustifyText, RightJustifyText

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprLastFile           ; Return poiter to last File Entry on File Eprom
     lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
     lib FileEprPrevFile           ; Return pointer to previous File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprCntFiles           ; Return total of active and deleted files
     lib FileEprFileStatus         ; Return Active/Deleted status of file entry
     lib FileEprRandomID           ; Return File Eprom "oz" Header Random ID

     xref DispMainWindow, cls      ; fsapp.asm
     xref DispCmdWindow            ; fsapp.asm
     xref GetCurrentSlot, DisplBar ; fsapp.asm
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
; Display name and size of stored files on Flash Eprom.
;
.DispFilesWindow
                    ld   hl, filearea_banner
                    ld   bc, 29
                    call FileAreaBannerText       ; HL = banner for file area window
                    call DispMainWindow

                    call PollFileArea
                    jp   c, disp_no_filearea_msg  ; file area not available
                    jp   z, no_files              ; Fz = 1, no files available in file area...
.DispFiles
                    call cls
                    xor  a
                    ld   (linecnt),a
                    call GetWindowFilePtr         ; BHL <-- (WindowFilePtr), top file entry of the window
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

.NormalAttrText     ld   hl,norm_sq
                    jr   dispsq
.TinyAttrText       ld   hl,tiny_sq
                    jr   dispsq
.RightJustifyText   ld   hl, rightjustify
                    jr   dispsq
.LeftJustifyText    ld   hl, leftjustify
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
                    ld   c, 22
                    bit  dspdelfiles,(iy+0)
                    jr   nz, append_viewtypetext  ; all files are displayed
                    ld   hl, savedfiles_banner
                    ld   c, 17                    ; only saved files displayed
.append_viewtypetext
                    ldir
                    xor  a
                    ld   (de),a                   ; null-terminate completed banner string
                    pop  hl                       ; return pointer to start of banner text.
                    ret
; *************************************************************************************


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
;       (WindowFilePtr) = 0
;
.InitFirstFileBar
                    xor  a
                    ld   (FileBarPosn),a        ; File Bar at top of window

                    call FilesAvailable         ; any files available in File Area?
                    jp   c, ResetFilePtrs       ; no file area...
                    jp   z, ResetFilePtrs       ; no files available...

                    call GetCurrentSlot         ; C = (curslot)
                    call GetFirstFilePtr        ; get BHL of first file in File area in slot C
                    jp   c, ResetFilePtrs       ; hmm..
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr)
                    call StoreWindowFilePtr     ; BHL --> (WindowFilePtr)
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
; Move the File Bar to the last file entry (top of file area) and try to fill the
; list with 6 file entries above.
;
.MoveToLastFile
                    xor  a                      ; get a cache of all file entries
                    call CacheFileEntries       ; and return BHL = last file entry in file area
                    ret  c                      ; no file entries or no File Area available...

                    push bc
                    push hl
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr)
                    ld   c,6
                    call pageup_loop            ; move 6 file entries upwards, if possible. C return no of entries left of 6
                    ld   a,6
                    sub  c
                    ld   (FileBarPosn),a        ; File Bar at last file entry in window
                    call GetCursorFilePtr
                    call StoreWindowFilePtr     ; update the file entry pointer that is the top entry in the window
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
                    ld   a,255                  ; get a cache of all file entries until
                    call CacheFileEntries       ; file entry in BHL, DE = pointer to cached entry
                    ret  c                      ; no file entries or no File Area available...
                    call GetPrevCachedFilePtr
                    jr   c, MoveToLastFile      ; File Bar at top of file list, wrap to last...
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr)

                    ld   a,(FileBarPosn)
                    cp   0
                    jr   z, scroll_filearea_down
                    dec  a
                    ld   (FileBarPosn),a
                    ret
.scroll_filearea_down
                    call StoreWindowFilePtr     ; new top window file entry pointer...
                    push bc
                    push hl
                    ld   hl, scroll_up
                    call_oz Gn_sop

                    ld   bc,0                   ; (0,0) - the start of the top line in the file area window
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

                    call GetWindowFilePtr
                    call GetNextFilePtr
                    call StoreWindowFilePtr     ; update the top window file entry to the next file entry...

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
                    call GetCursorFilePtr       ; BHL <-- (CursorFilePtr)
                    ld   a,255                  ; get a cache of all file entries until
                    call CacheFileEntries       ; file entry in BHL, DE = pointer to cached entry
                    ret  c                      ; no file entries or no File Area available...
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr)

                    xor  a
                    ld   (FileBarPosn),a        ; File Bar at top of window
                    ld   c,7                    ; move 7 file entries upwards, if possible
.pageup_loop
                    call GetCursorFilePtr       ; BHL <-- (CursorFilePtr)
                    call GetPrevCachedFilePtr
                    jr   c, end_MovePgUp        ; reached top of list, update file area window
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr)
                    call StoreWindowFilePtr     ; the top window file entry will be the same as the new file entry
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
                    call StoreWindowFilePtr     ; the top window file entry will be the same as the new file entry
                    dec  c
                    jr   nz, pagedwn_loop
.end_MovePgDwn      jp   DispFiles
; *************************************************************************************


; *************************************************************************************
; Get pointer to first file entry. If only active files are currently displayed,
; deleted file entries are skipped until an active file entry is found.
;
; IN:
;    C = slot number of File area
;
; OUT:
;    Fc = 1, No file area or no file entries in file area.
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
; Poll current file area, and update File entry pointer if necessary.
;
; Return Fc = 1, if no file area is available (possibly card was removed)
; Return Fz = 1, if no files are available in file area
;
.PollFileArea
                    call PollFileCardWatermark    ; same card still available in current slot?
                    jp   c, ResetFilePtrs         ; no file area found in slot
                    jr   z, ResetFilesWindow      ; Ups, the card has been changed in the current slot!

                    call FilesAvailable           ; same card still present, check if files area available...
                    jp   z, ResetFilePtrs         ; no files in file area

                    call AdjustWindowFileEntryPtr ; File Area Window top line points at file entry according to view setting
                    jp   c, InitFirstFileBar      ; no files in file area
                    call AdjustFileEntryPtr       ; Current file Entry File Bar adjusted to match adjusted Window File File Ptr

                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr)
                    or   h
                    or   l
                    call z,InitFirstFileBar       ; File Entry was zero, initialize to first in file area
                    ret
; *************************************************************************************


; *************************************************************************************
; Reset file area window to point at first file and refresh the entire file window
;
.ResetFilesWindow   push af
                    call InitFirstFileBar         ; Place the file cursor at the beginning of the file list
                    call DispFilesWindow          ; and redraw the entire file area window
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; For the current slot, compare the random ID and size of the file area
; (identified as the watermark) with the current stored values at (watermark).
;
; return Fc = 1, if no file area was found (watermark reset to 0)
; return Fz = 1, if a new file area was found (watermark updated to new value)
;
.PollFileCardWatermark
                    push bc
                    push de
                    push hl

                    call getRandomId
                    call c, resetwatermark        ; Ups, no card available in current slot
                    jr   c, exit_PollFileCardWatermark
                    ld   hl,watermark+4
                    cp   (hl)
                    jr   nz, newFileArea          ; a new card with a different size file area has been inserted
                    call getRandomId              ; get Random ID of file header in DEBC...
                    ld   hl,(watermark)
                    sbc  hl,bc
                    jr   nz,newFileArea           ; compare previous stored watermark with current from file area
                    ld   hl,(watermark+2)
                    sbc  hl,de
                    jr   nz,newFileArea           ; watermark doesn't match - a new file area was found in slot
                    or   a                        ; Fz = 0, indicate same file area...
.exit_PollFileCardWatermark
                    pop  hl
                    pop  de
                    pop  bc
                    ret
.newFileArea
                    call getRandomId              ; get Random ID of file header in DEBC...
                    ld   (watermark),bc
                    ld   (watermark+2),de
                    ld  (watermark+4),a           ; size of file area in 16K banks
                    cp   a                        ; Fz = 1, indicate new file area
                    jr   exit_PollFileCardWatermark
.getRandomId
                    call GetCurrentSlot           ; C = (curslot)
                    call FileEprRandomID
                    ret
.ResetWatermark
                    ld   a,0
                    ld   h,a
                    ld   l,a
                    ld  (watermark),hl
                    ld  (watermark+2),hl
                    ld  (watermark+4),a
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
                    call nz,NormalAttrText
                    call z,TinyAttrText
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

                    call RightJustifyText
                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop              ; display size of current File Entry
                    call LeftJustifyText
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
; buf1 is used internally, so should not be used as external pointer (otherwise
; no compression will be executed).
;
; IN:
;    DE  = local pointer to put (optionally) compressed filename
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
                    push de                     ; remember buffer pointer
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
                    pop  hl
                    pop  de                     ; start of original buffer
                    push de
                    ld   bc,46                  ; copy compressed filename (including null-terminator) to original buffer
                    ldir
                    pop  de
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

                    ld   hl,0
                    ld   (file),hl                ; reset active files count
                    ld   (fdel),hl                ;       deleted

                    call GetCurrentSlot           ; C = (curslot)
                    call FileEprCntFiles          ; any files available in File Area?
                    jr   c, exit_checkfiles       ; no file area!
                    ld   (file),hl                ; update active files count
                    ld   (fdel),de                ;        deleted

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
; BHL --> (WindowFilePtr)
;
.StoreWindowFilePtr
                    ld   (WindowFilePtr),hl
                    ld   a,b
                    ld   (WindowFilePtr+2),a    ; real last file pointer
                    ret
; *************************************************************************************


; *************************************************************************************
; BHL <-- (WindowFilePtr)
;
.GetWindowFilePtr
                    ld   hl,(WindowFilePtr)
                    ld   a,(WindowFilePtr+2)
                    ld   b,a
                    ret
; *************************************************************************************


; *************************************************************************************
; Adjust the top window line File entry to point at a file entry that matches the
; current display setting, if necessary.
; If the current file entry is marked as deleted and file view setting is
; "only saved files", then try to move to next or previous saved file without wrapping
; beyond end or start of list.
;
; return Fc = 1, if File Entry couldn't be updated (list is empty according to view setting)
;
.AdjustWindowFileEntryPtr
                    call GetWindowFilePtr
                    or   h
                    or   l                      ; BHL = 0?
                    jr   nz, check_entrystat
                    scf                         ; nothing to update!
                    ret
.check_entrystat
                    call FileEprFileStatus
                    ret  nz                     ; top window line is an active file, no adjustment needed

                    bit  dspdelfiles,(iy+0)
                    ret  nz                     ; top file entry is marked as deleted, and deleted file view is active
                    call GetNextFilePtr
.updwptr
                    call nc, StoreWindowFilePtr ; updated the top line File entry to an active file
                    ret  nc

                    call GetWindowFilePtr       ; reached end of list,
                    call GetPrevFilePtr         ; try to get a previous active file entry
                    jr   nc,updwptr             ; and update to that...
                    call ResetFilePtrs          ; no active files available...
                    ret                         ; return Fc = 1
; *************************************************************************************


; *************************************************************************************
; adjust the current file entry pointer relative to the Window top line file entry
.AdjustFileEntryPtr
                    call GetWindowFilePtr
                    ld   a,(FileBarPosn)
                    ld   c,a                    ; position File Cursor relative to Window File Ptr
.adjust_loop        call StoreCursorFilePtr
                    inc  c
                    dec  c
                    ret  z                      ; File Entry cursor relocated according to file bar position in window
                    call GetNextFilePtr         ; get next file entry according to display setting
                    jr   c, adjustFileBarPosn   ; reached end of list before the current File Bar position
                    dec  c
                    jr   adjust_loop
.adjustFileBarPosn                              ; the File Bar moves upwards toward the Window top line File entry
                    ld   a,(FileBarPosn)
                    sub  c
                    ld   (FileBarPosn),a        ; the new File Bar Position points at last file entry in list
                    ret
; *************************************************************************************


; *************************************************************************************
.ResetFilePtrs
                    ld   b,0
                    ld   h,b
                    ld   l,b
                    call StoreCursorFilePtr     ; BHL --> (CursorFilePtr), indicate no files (pointer = 0)
                    call StoreWindowFilePtr     ; BHL --> (WindowFilePtr), indicate no files (pointer = 0)
                    LD   (barMode),A            ; get cursor out of file window into menu window...
                    ret
; *************************************************************************************


; *************************************************************************************
; Cache file entries for current view mode from beginning of file card until current
; file entry in BHL, or all file entries.
;
; Caching is used for fast display of <Last File Entry> and <Page Up> browsing.
;
; The file entries will be be stored as three-byte entities beginning at (buffer+3),
; onwards. (buffer) contains three zeroes to indicate bottom-of-file-list.
; A pointer (16bit) will be returned that indicates the current file entry. The cache
; can store 512 entries. This size is defined by size of <buffer> + <buf1> + <buf2> +
; <buf3> = 1024 + 128 + 128 + 256 = 1536 / 3 = 512.
; Last entry + 1 contains three zeroes to define top of file list.
;
; The cache needs to be built be before each <Page Up> or <Top File> cursor move
; command.
;
; IN:
;   A = 0: cache all file entries in file area (BHL not used)
;   A <> 0: cache only file entries until current current entry.
;       BHL = current file entry
; OUT:
;   Fc = 1
;       No entries or no file area found.
;   Fc = 0
;       A(in) = 0,
;           DE = pointer to last file entry in file area cache (current view).
;           BHL = last file entry pointer in current slot
;       A(in) <> 0,
;           DE = pointer to current file entry in file area cache (current view).
;           BHL = BHL(in)
;
.CacheFileEntries   push ix
                    ld   ix,flentry

                    push af
                    ld   (flentry),hl
                    ld   a,b
                    ld   (flentry+2),a          ; remember current file entry
                    pop  af

                    ld   de,buffer
                    call NUllEntry              ; (buffer) = 0, DE points at first cache entry

                    call GetCurrentSlot         ; C = (curslot)
                    call GetFirstFilePtr
                    jr   c,exit_buildcache      ; couldn't get the first file entry...
.cache_entries_loop
                    call CacheFileEntry         ; (DE) <- BHL, DE = DE + 3
                    or   a
                    call nz,CompareFileEntry    ; build cache to current file entry?
                    call GetNextFilePtr         ; BHL = GetNextFileEntry(BHL) (current view)
                    jr   c, end_buildcache      ; reached end of file area..
                    jr   cache_entries_loop
.end_buildcache
                    cp   a                      ; Fc = 0, indicate no error
.exit_buildcache
                    dec  de
                    dec  de
                    dec  de                     ; point at start of current cached file entry in BHL
                    push af
                    call GetCachedFileEntry     ; BHL <- (DE)
                    pop  af
                    pop  ix
                    ret
.CompareFileEntry                               ; reached the current file entry during caching?
                    push af
                    ld   a,b
                    cp   (ix+2)
                    jr   nz, fe_notequal
                    ld   a,h
                    cp   (ix+1)
                    jr   nz, fe_notequal
                    ld   a,l
                    cp   (ix+0)
                    jr   nz, fe_notequal
                    pop  af                     ; stop caching at found BHL file entry...
                    pop  af                     ; (pop return address)
                    cp   a                      ; Fc = 0...
                    jr   exit_buildcache
.fe_notequal
                    pop  af                     ; caching not reached file entry...
                    ret

.CacheFileEntry     push af                     ; store BHL at (DE), DE = DE+3
                    ld   a,l
                    ld   (de),a
                    inc  de
                    ld   a,h
                    ld   (de),a
                    inc  de
                    ld   a,b
                    ld   (de),a
                    inc  de
                    pop  af
                    ret
.NullEntry                                      ; (DE) = 0
                    push af
                    push bc
                    xor  a
                    ld   b,3
.null_entry_loop
                    ld   (de),a
                    inc  de
                    djnz null_entry_loop
                    pop  bc
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; Get previous cached file entry.
;
; IN:
;   DE = pointer to current cached file entry
;
.GetPrevCachedFilePtr
                    dec  de
                    dec  de
                    dec  de
.GetCachedFileEntry                               ; Get cached file entry at (DE), returned in BHL
                    push de
                    ld   a,(de)
                    inc  de
                    ld   l,a
                    ld   a,(de)
                    inc  de
                    ld   h,a
                    ld   a,(de)
                    ld   b,a
                    or   h
                    or   l
                    jr   nz, end_getcachedfe
                    scf                           ; reached beyond first file entry
.end_getcachedfe
                    pop  de
                    ret
; *************************************************************************************


; *************************************************************************************
; constants
;
.filearea_banner    DEFM "FILE AREA [VIEW/FETCH/DELETE "
.allfiles_banner    DEFM "SAVED & DELETED FILES]"
.savedfiles_banner  DEFM "ONLY SAVED FILES]"

.norm_sq            DEFM 1,"3-GT",1,"2+BF",1,"2-B ",0
.tiny_sq            DEFM 1,"5+TGRUD",1,"4-GRU ", 0

.endf_msg           DEFM 1,"2-G",1,"4+TUR END ",1,"4-TUR",0
.scroll_up          DEFM 1, SD_UP, 0
.scroll_down        DEFM 1, SD_DWN, 0

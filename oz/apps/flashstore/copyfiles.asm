; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2007
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

Module CopyFiles

; This module contains the command to copy files directly between File Cards

     xdef CopyFileAreaCommand, QuickCopyFileCommand

     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry

     xref FilesAvailable           ; browse.asm
     xref CompressedFileEntryName  ; browse.asm
     xref GetCursorFilePtr         ; browse.asm
     xref DispFilesSaved           ; savefiles.asm
     xref CountFileSaved           ; savefiles.asm
     xref DeleteOldFile            ; savefiles.asm
     xref FindFile                 ; savefiles.asm
     xref disp_flcovwrite_msg      ; savefiles.asm
     xref DispBoldFilename         ; deletefile.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref no_files, DispErrMsg     ; errmsg.asm
     xref noeprfiles_msg           ; errmsg.asm
     xref DispErrMsgNoWait         ; errmsg.asm
     xref DispIntelSlotErr         ; errmsg.asm
     xref DispMainWindow           ; fsapp.asm
     xref YesNo, no_msg, yes_msg   ; fsapp.asm
     xref ResSpace, failed_msg     ; fsapp.asm
     xref GetCurrentSlot, rdch     ; fsapp.asm
     xref CheckBarMode, sopnln     ; fsapp.asm
     xref PromptOverWrite          ; restorefiles.asm
     xref VduCursor                ; selectcard.asm
     xref PollSlots                ; selectcard.asm
     xref SelectDefaultSlot        ; selectcard.asm
     xref selectdev_msg            ; defaultram.asm
     xref disp16bitInt             ; fetchfile.asm
     xref DisplayFileSize          ; fetchfile.asm
     xref DispCompletedMsg         ; fetchfile.asm
     xref FlashWriteSupport        ; format.asm
     xref disp_exis_msg

     ; system definitions
     include "stdio.def"
     include "eprom.def"
     include "error.def"
     include "syspar.def"
     include "flashepr.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
; Copy ALL active files from current file card to another user defined file card.
;
.CopyFileAreaCommand
                    ld   hl,copy_banner
                    call DispMainWindow

                    ld   hl,0
                    ld   (savedfiles),hl          ; reset counter to No files saved...

                    call FilesAvailable
                    jp   c, disp_no_filearea_msg  ; no file area avaible in current slot
                    jr   nz, prompt_ovwrmode

.no_active_files    ld   hl, noeprfiles_msg       ; Fz = 1, no files available...
                    jp   DispErrMsg
.disp_faovwrite
                    ld   hl, disp_flcovwrite_msg
                    call_oz GN_Sop
                    ret
.prompt_ovwrmode
                    call SelectDestinationSlot
                    ret  c                        ; User aborted or there were only a single file card...
.single_destination
                    call_oz GN_nln
                    call DispCopyStatus
                    call_oz GN_nln
                    call CheckDestSlotWriteSupport
                    ret  c                        ; destination slot is not writeable!

                    ld   hl, disp_faovwrite
                    ld   de, no_msg               ; default 'No' to overwrite file
                    call PromptOverwrite          ; prompt for existing files in destination file area to be overwritten
                    cp   IN_ESC
                    ret  z                        ; user aborted with ESC
                    call_oz GN_nln
                    call_oz GN_nln

                    call GetCurrentSlot           ; C = (curslot)
                    ld   a,EP_First
                    oz   OS_Epr                   ; get BHL pointer to first file on Eprom
.copy_loop
                    jr   c, copy_completed        ; all file entries copied...
                    jr   z, fetch_next            ; File Entry marked as deleted, get next...

                    push bc
                    ld   bc,2
                    call_oz OS_Tin
                    cp   RC_ESC                   ; has user tried to abort file copy to file card?
                    pop  bc
                    jr   z, copy_completed

                    call CopyFileEntry            ; BHL to slot (dstslot)
                    jr   c, filecreerr            ; not possible to copy, exit copy file area...

                    call CountFileSaved
                    call_oz GN_Nln
.fetch_next                                       ; BHL = current File Entry
                    ld   a,EP_Next
                    oz   OS_Epr                   ; get pointer to next File Entry...
                    jr   nc, copy_loop
.copy_completed
                    jp   DispFilesSaved
.filecreerr
                    cp   rc_esc
                    jr   z, copy_completed        ; user aborted with ESC

                    call_oz Gn_Err                ; report fatal error and exit to main menu...
                    ld   hl, failed_msg
                    jp   DispErrMsg
; *************************************************************************************


; *************************************************************************************
.CheckDestSlotWriteSupport
                    ld   a,(dstslot)
                    ld   c,a
                    call FlashWriteSupport
                    ret  nc
                    call GetCurrentSlot
                    push bc
                    ld   a,(dstslot)
                    ld   (curslot),a
                    call DispIntelSlotErr
                    pop  bc
                    ld   a,c
                    ld   (curslot),a
                    ret
; *************************************************************************************


; *************************************************************************************
; Copy selected file in browsing window to another user selected file card.
;
.QuickCopyFileCommand                             ; 'C' key pressed - copy single file entry to another slot
                    ld   hl,copy_single_banner
                    call DispMainWindow

                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr), ptr to cur. file entry
                    call DisplayFileSize
                    ld   de,buffer
                    call DispBoldFilename

                    call SelectDestinationSlot
                    ret  c                        ; User aborted or there was only a single file card...

                    res  overwrfiles,(IY+0)       ; preset to not overwrite existing files by default
                    cp   2
                    jr   nz, start_single_copy    ; user has selected destination manually, so start copying...

                    ld   hl, copy_txt
                    call_oz GN_Sop
                    ld   hl,CopyToSlotPrompt
                    ld   de, yes_msg
                    call yesno                    ; copy file to default destination?
                    jr   z,start_single_copy
                    ret
.start_single_copy
                    call_oz GN_nln
                    call CheckDestSlotWriteSupport
                    ret  c                        ; destination slot is not writeable!
                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr), ptr to cur. file entry
                    call CopyFileEntry            ; finally, copy BHL entry to slot (dstslot)
                    jr   c, filecreerr
                    jp   DispCompletedMsg
.CopyToSlotPrompt
                    call DispToSlotStatus
                    ld   a,'?'
                    call_oz OS_Out
                    call_oz GN_nln
                    ret
; *************************************************************************************


; *************************************************************************************
; Copy file entry BHL to slot defined in (dstslot)
;
.CopyFileEntry
                    ld   de,buf3
                    call FileEprFilename          ; copy filename from current file entry at (DE)

                    push bc
                    push hl                       ; preserve file entry pointer temporarily...
                    ld   de, buf2
                    call CompressedFileEntryName  ; get a displayable file entry filename at (buf2)
                    ex   de,hl
                    call_oz gn_sop                ; display file entry filename (optionally compressed, if too long)...

                    ld   a,(dstslot)
                    ld   c,a
                    ld   de,buf3
                    call FindFile
                    jr   nz, copy_file            ; file does not exist on destination

                    bit  overwrfiles,(IY+0)
                    jr   nz, copy_file            ; default - overwrite files...
                    ld   hl, buf2
                    push de                       ; preserve pointer to file area filename
                    ld   de, disp_exis_msg
                    call PromptOverWrFileEntry    ; Does File entry exist at destination slot?...
                    pop  de
                    jr   c, check_copy_abort      ; does not exist...
                    jr   z, display_copy          ; file exists, user acknowledged Yes...
                    jr   copy_ignored             ; file exists, user acknowledged No...
.check_copy_abort
                    cp   RC_ESC
                    jr   nz, copy_file            ; file doesn't exist (or in use)
                         pop  hl
                         pop  bc
                         scf                      ; copy command aborted with ESC.
                         ret
.copy_ignored
                    call_oz Gn_Nln
                    pop  hl
                    pop  bc
                    cp   a
                    ret                           ; user acknowledged No to overwrite...
.display_copy
                    ld   hl, copying_txt
                    call sopnln
.copy_file
                    pop  hl
                    pop  bc                       ; restore pointer to current File Entry

                    ld   a,(dstslot)
                    ld   c,a                      ; copy to slot X
                    ld   a,FEP_CPFL
                    oz   OS_Fep                   ; copy file at BHL to slot C
                    ret  c
                    jp   DeleteOldFile            ; mark old file entry at destination as deleted, if new copy was made...
; *************************************************************************************


; *************************************************************************************
;
; Prompt user to overwrite File entry defined if it exist, (flentry) <> 0.
;
; IN:
;    HL = (local) ptr to filename (null-terminated)
;    DE = pointer to prompt file overwrite message routine
;
; OUT:
;    Fc = 0, file exists
;         Fz = 1, Yes, user acknowledged overwrite file
;         Fz = 0, No - acknowledged preserve file
;
;    Fc = 1,
;         file doesn't exists or
;         or user aborted with ESC (during Yes/No) prompt.
;
; Registers changed after return:
;    ..BC..HL/IXIY same
;    AF..DE../.. different
;
.PromptOverWrFileEntry
                    push bc
                    push hl
                    push de

                    ld   a,(flentry+2)
                    ld   b,a
                    ld   hl,(flentry)
                    or   h
                    or   l                        ; Valid pointer to File Entry?
                    jr   z, exit_overwrflentry    ; no file entry exists to overwritten

                    call_oz GN_nln
                    pop  hl                       ; pointer to prompt display routine
                    ld   de, yes_msg
                    call yesno                    ; file exists, prompt "Overwrite file?"
                    jr   z,exit_overwrflentry
.check_ESC
                    cp   IN_ESC
                    jr   z, abort_file
                         or   a
                         jr   exit_overwrflentry
.abort_file
                    ld   a,RC_ESC
                    or   a                        ; Fz = 0, Fc = 1
                    scf
.exit_overwrflentry
                    pop  hl
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Select the destination file card slot, either automatically by choosing the
; opposite of the current slot (if two file cards are found), or let the user choose
; if three or more file card areas exist in the system.
;
; IN:
;    -
; OUT:
;    Fc = 0,
;         A = total of available file cards, (dstslot) selected destination slot number
;    Fc = 1,
;         A = Error code
;
; All registers changed on return.
;
.SelectDestinationSlot
                    call GetCurrentSlot
                    call SelectDefaultSlot        ; select a default destination slot (not current slot!)
                    jp   c, single_filearea
                    ld   (dstslot),a

                    call PollSlots
                    cp   1
                    jp   z, single_filearea       ; copying has no meaning for only one file area (return Fc = 1)...
                    cp   2
                    ret  z                        ; return default single destination...

                    ld   hl, selctfcard_msg
                    call_oz GN_Sop                ; "Select File Card"

                    ld   hl, selectdev_msg
                    call sopnln                   ; (then execute file card selection)
; *************************************************************************************


; *************************************************************************************
; User selects File Card by using keys 0-3 or using <>J to toggle between available
; file cards. Current slot is automatically discarded during selection...
;
; IN:
;         -
; OUT:
;    Fc = 0,
;         A = no. of available file cards in slots 0-3
;         Slot Number (0 - 3) of selected File Card, stored in (dstslot).
;    Fc = 1,
;         User aborted or error occurred.
;
.SelectFileCard
                    ld   hl,slot_txt
                    call_oz GN_Sop
                    xor  a
                    ld   bc, NQ_WCUR
                    call_oz OS_Nq                 ; get current VDU cursor for current window
.inp_dev_loop
                    call VduCursor                ; put VDU cursor at (X,Y) = (C,B)
                    ld   a,(dstslot)
                    or   48
                    call_oz OS_Out                ; display the pre-selected destination file card.
                    ld   a,8
                    call_oz OS_Out                ; put blinking cursor over slot number of device

                    call rdch                     ; get another device slot number from user
                    cp   IN_ESC
                    jr   z, dev_aborted           ; user aborted selection
                    cp   IN_ENT
                    jp   z,PollSlots              ; user has selected a file card, return no. of file cards...
                    cp   LF
                    jr   z, toggle_device         ; <>J
                    cp   48
                    jr   c,inp_dev_loop
                    cp   52
                    jr   nc,inp_dev_loop          ; only "0" to "3" allowed

                    sub  48
                    call CheckCurSlot
                    jr   z, inp_dev_loop          ; destination and source slot cannot be the same...
                    call CheckFileCard
                    jr   nz, inp_dev_loop         ; there's no File Area in selected slot, find a valid device
                    ld   a,e
                    ld   (dstslot),a
                    jr   inp_dev_loop             ; and let it be displayed.
.CheckCurSlot
                    ld   e,a                      ; preserve slot number
                    ld   a,(curslot)
                    cp   e
                    ld   a,e
                    ret
.toggle_device
                    ld   a,(dstslot)
.toggle_device_loop
                    inc  a
                    cp   4
                    jr   z, wrap_slot0            ; only scan slots 0 - 3
                    call CheckCurSlot
                    jr   z, toggle_device_loop
                    call CheckFileCard            ; File Card in slot A?
                    ld   a,e
                    ld   (dstslot),a
                    jr   z, inp_dev_loop          ; Yes, toggled to a new slot ...
                    jr   toggle_device_loop       ; No, didn't find a file area...
.wrap_slot0
                    ld   a,-1
                    jr   toggle_device_loop
.dev_aborted
                    scf                           ; indicate abort command
                    ret
.CheckFileCard
                    push bc                       ; preserve VDU X,Y cursor...
                    ld   c,a
                    ld   a,EP_Req
                    oz   OS_Epr                   ; check if there's a File Card in selected slot
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
.single_filearea
                    ld   hl, singlefilearea_msg
                    call DispErrMsgNoWait
                    call ResSpace                 ; "Press SPACE to resume" ...
                    scf
                    ret
; *************************************************************************************


; *************************************************************************************
.DispCopyStatus
                    ld   hl,copying_txt
                    call_oz GN_Sop
                    ld   hl,files_txt
                    call_oz GN_Sop
                    ld   hl,from_txt
                    call_oz GN_Sop
                    ld   hl,slot_txt
                    call_oz GN_Sop
                    ld   a,(curslot)
                    ld   h,0
                    ld   l,a
                    call disp16bitInt             ; Copying files from slot X
.DispToSlotStatus
                    ld   hl,to_txt
                    call_oz GN_Sop
                    ld   hl,slot_txt
                    call_oz GN_Sop
                    ld   a,(dstslot)
                    ld   h,0
                    ld   l,a
                    call disp16bitInt             ; to slot Y
                    ret
; *************************************************************************************


; *************************************************************************************
; constants

.copy_banner        defm "COPY ALL FILES TO ANOTHER FILE CARD", 0
.copy_single_banner defm "COPY SELECTED FILE TO ANOTHER FILE CARD", 0

.selctfcard_msg     defm 13, 10, " Select File Card.", 13, 10, 0
.copying_txt        defm " Copying ", 0
.copy_txt           defm " Copy", 0
.singlefilearea_msg defm "Only current file card is available.", 0
.slot_txt           defm " Slot ", 0
.files_txt          defm "files ", 0
.from_txt           defm "from", 0
.to_txt             defm " to", 0
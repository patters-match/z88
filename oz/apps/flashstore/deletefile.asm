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
;
; *************************************************************************************

Module DeleteFile

     xdef DeleteFileCommand        ; Mark as Deleted command, <>ER
     xdef QuickDeleteFile          ; interactive command, DEL key on current file in file area window
     xdef DispBoldFilename

     xref StoreCursorFilePtr, GetCursorFilePtr    ; browse.asm
     xref CompressedFileEntryName, FilesAvailable ; browse.asm
     xref InitFirstFileBar, DispFiles             ; browse.asm
     xref MoveToFirstFile, GetNextFilePtr         ; browse.asm
     xref DispErrMsg, disp_no_filearea_msg        ; errmsg.asm
     xref DispIntelSlotErr, no_files              ; errmsg.asm
     xref SlotWriteSupport                       ; format.asm
     xref InputFileName, exct_msg                 ; fetchfile.asm
     xref fnam_msg                                ; savefiles.asm
     xref FileEpromStatistics                     ; filestat.asm
     xref DispMainWindow, GetCurrentSlot, sopnln  ; fsapp.asm
     xref YesNo, no_msg, yes_msg                  ; fsapp.asm

     ; system definitions
     include "stdio.def"
     include "error.def"
     include "flashepr.def"
     include "eprom.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
; Initialize middle window with 'mark as deleted file' command window.
; and evaluate whether a flash card supports byte programming in current slot.
;
.InitDeleteCommand
                    ld   de,delfile_bnr
                    call DispMainWindow

                    call GetCurrentSlot           ; C = (curslot)
                    call SlotWriteSupport        ; check if Flash Card in current slot supports saveing files?
                    jp   c,DispIntelSlotErr
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Mark file as Deleted in File Area
; User enters name of file that will be searched for, and if found,
; it will be marked as deleted.
;
.DeleteFileCommand
                    call InitDeleteCommand        ; init command window and check if Flash Card supports deleting files?
                    ret  c                        ; it didn't...
                    ret  nz                       ; (and flash chip was not found in slot!)

                    push bc
                    ld   a,EP_Req
                    oz   OS_Epr                   ; check if there's a File Card in slot C
                    pop  bc
                    jr   z, check_deletable_files
                    jp   disp_no_filearea_msg
.check_deletable_files
                    call FilesAvailable
                    jp   z, no_files              ; Fz = 1, no files available...

                    ld   hl,exct_msg
                    call sopnln
                    ld   hl,fnam_msg
                    CALL_OZ gn_sop

                    LD   HL,buffer                ; preset input line with '/'
                    LD   (HL),'/'
                    INC  HL
                    LD   (HL),0
                    DEC  HL

                    EX   DE,HL
                    LD   C,$01
                    CALL InputFileName            ; users enters filename to be searched in File Area
                    RET  C

                    CALL_OZ gn_nln
                    JP   FindToMarkDeleted        ; try to find entered filename, and confirm to mark deleted
; *************************************************************************************


; *************************************************************************************
; User pressed DEL key on current file in file area window
; If the file is an active type (not yet marked as deleted), then allow the file
; to be deleted if the current slot contains a Flash Card that supports byte programming.
;
.QuickDeleteFile
                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr), ptr to cur. file entry
                    ld   a,EP_Stat
                    oz   OS_Epr                   ; check file entry status...
                    ret  c                        ; no file area...
                    ret  z

                    call InitDeleteCommand        ; init command window and check if Flash Card supports deleting files?
                    ret  c                        ; it didn't...
                    ret  nz                       ; (and flash chip was not found in slot!)

                    call_oz GN_Nln

                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr), ptr to cur. file entry
                    call ConfirmDelete            ; ask user to confirm mark as deleted.
                    call z, exec_delete           ; User acknowledged with Yes...
                    or   a
                    ret
; *************************************************************************************


; *************************************************************************************
; DE = pointer to buffer to store compressed filename
;
.DispBoldFilename
                    call CompressedFileEntryName  ; get compressed filename from file entry (BHL) to (DE)

                    push bc
                    push hl
                    ld   hl, pre_filename
                    call_oz GN_sop
                    ex   de,hl
                    call_oz GN_sop                ; display filename (may have been compressed..)
                    ld   hl, post_filename
                    call_oz GN_sop                ; display filename in Bold, followed by newline
                    pop  hl
                    pop  bc                       ; restored BHL = file entry
                    ret
; *************************************************************************************


; *************************************************************************************
.ConfirmDelete
                    push bc
                    push hl

                    ld   de,buffer
                    call DispBoldFilename

                    ld   hl, disp_markdel_prompt
                    ld   de, no_msg               ; default to no
                    call YesNo                    ; "mark file as deleted?"
                    pop  hl
                    pop  bc                       ; BHL = file entry to mark as deleted
                    ret
.disp_markdel_prompt
                    LD   HL,markdel_prompt
                    CALL_OZ GN_Sop
                    RET
; *************************************************************************************


; *************************************************************************************
;
.FindToMarkDeleted
                    call GetCurrentSlot           ; C = (curslot)
                    LD   DE,buffer
                    LD   A,EP_Find
                    OZ   OS_Epr                   ; search for <buffer> filename on File Eprom...
                    JR   C, delfile_notfound      ; File Eprom or File Entry was not available
                    JR   NZ, delfile_notfound     ; File Entry was not found...

                    push hl
                    ld   hl, found_msg
                    call_oz GN_sop
                    pop  hl

                    call ConfirmDelete            ; file found, confirm to mark as deleted.
                    ret  nz                       ; User aborted...
.exec_delete
                    LD   A,EP_Delete              ; user pressed Y...
                    OZ   OS_Epr                   ; Mark File Entry as deleted
                    JR   C, delfile_failed
                    LD   HL,filedel_msg
                    JP   DispErrMsg
.delfile_failed
                    LD   HL,markdelete_failed
                    CALL DispErrMsg
.delfile_notfound
                    LD   HL,delfile_err_msg
                    JP   DispErrMsg
; *************************************************************************************


; *************************************************************************************
; constants

.delfile_bnr        DEFM "MARK FILE AS DELETED IN FILE AREA",0

.delfile_err_msg    DEFM "File not found.", 0
.found_msg          DEFM 13, 10, " Found", 0
.markdelete_failed  DEFM "Error. File was not marked as deleted.",0
.filedel_msg        DEFM 1,"2JC", "File marked as deleted.",1,"2JN", 0
.markdel_prompt     DEFM " Mark file as deleted?", 13, 10, 0
.pre_filename       DEFM 1, "B ", 0
.post_filename      DEFM 1, "B", 13, 10, 0

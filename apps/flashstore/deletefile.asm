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

Module DeleteFile

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFileStatus         ;
     lib FileEprFindFile           ; Find File Entry using search string (of null-term. filename)
     lib FileEprFilename           ; get filename at (DE) from current file entry
     lib FlashEprFileDelete        ; Mark file as deleted on Flash Eprom

     xdef DeleteFileCommand        ; Mark as Deleted command, <>ER
     xdef QuickDeleteFile          ; interactive command, DEL key on current file in file area window

     xref StoreCursorFilePtr, GetCursorFilePtr
     xref CompressedFileEntryName
     xref InitFirstFileBar
     xref DispMainWindow, sopnln
     xref DispErrMsg, disp_no_filearea_msg
     xref FilesAvailable, no_files
     xref FlashWriteSupport
     xref DispIntelSlotErr
     xref exct_msg, fnam_msg
     xref YesNo, no_msg, yes_msg

     ; system definitions
     include "stdio.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
; Initialize middle window with 'mark as deleted file' command window.
; and evaluate whether a flash card supports byte programming in current slot.
;
.InitDeleteCommand
                    ld   hl,delfile_bnr
                    call DispMainWindow

                    ld   a,(curslot)
                    ld   c,a
                    call FlashWriteSupport        ; check if Flash Card in current slot supports saveing files?
                    call c,DispIntelSlotErr
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
                    call FileEprRequest
                    pop  bc
                    jr   z, check_deletable_files
                    call disp_no_filearea_msg
                    ret
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

                    LD   A,@00100011
                    LD   BC,$FF01
                    LD   L,$28
                    CALL_OZ gn_sip
                    jp   c,sip_error
                    CALL_OZ gn_nln

                    CALL FindToMarkDeleted        ; try to find entered filename, and confirm to mark deleted
                    RET
.sip_error
                    CP   RC_SUSP
                    JR   Z, DeleteFileCommand
                    RET
; *************************************************************************************


; *************************************************************************************
; User pressed DEL key on current file in file area window
; If the file is an active type (not yet marked as deleted), then allow the file
; to be deleted if the current slot contains a Flash Card that supports byte programming.
;
.QuickDeleteFile
                    call GetCursorFilePtr         ; BHL <-- (CursorFilePtr), ptr to cur. file entry
                    call FileEprFileStatus        ; check file entry status...
                    ret  c                        ; no file area...
                    ret  z                        ; file already marked as deleted..

                    push bc
                    push hl
                    call InitDeleteCommand        ; init command window and check if Flash Card supports deleting files?
                    pop  hl
                    pop  bc
                    ret  c                        ; it didn't...
                    ret  nz                       ; (and flash chip was not found in slot!)

                    call_oz GN_Nln
                    call ConfirmDelete            ; ask user to confirm mark as deleted.
                    jr   z, exec_delete           ; User acknowledged with Yes...
                    ret
; *************************************************************************************


; *************************************************************************************
.ConfirmDelete
                    call CompressedFileEntryName  ; get compressed filename from file entry (BHL) to (DE)

                    push bc
                    push hl
                    ld   hl, pre_filename
                    call_oz GN_sop
                    ex   de,hl
                    call_oz GN_sop                ; display filename (may have been compressed..)
                    ld   hl, post_filename
                    call_oz GN_sop                ; display filename in Bold, followed by newline

                    ld   hl, disp_markdel_prompt
                    ld   de, no_msg               ; default to no
                    call YesNo                    ; "mark file as deleted?"
                    pop  hl
                    pop  bc                       ; BHL = file entry to mark as deleted
                    ret
; *************************************************************************************


; *************************************************************************************
;
.FindToMarkDeleted
                    LD   A,(curslot)
                    LD   C,A
                    LD   DE,buffer
                    CALL FileEprFindFile          ; search for <buf1> filename on File Eprom...
                    JR   C, delfile_notfound      ; File Eprom or File Entry was not available
                    JR   NZ, delfile_notfound     ; File Entry was not found...

                    push hl
                    ld   hl, found_msg
                    call_oz GN_sop
                    pop  hl

                    call ConfirmDelete            ; file found, confirm to mark as deleted.
                    ret  nz                       ; User aborted...
.exec_delete
                    CALL FlashEprFileDelete       ; User pressed Y (for Yes)
                    JR   NC, file_deleted
                    LD   HL,markdelete_failed
                    CALL DispErrMsg
.delfile_notfound
                    LD   HL,delfile_err_msg
                    CALL DispErrMsg
                    RET
.file_deleted
                    LD   HL,filedel_msg
                    CALL DispErrMsg
                    RET
; *************************************************************************************


.disp_markdel_prompt
                    LD   HL,markdel_prompt
                    CALL_OZ GN_Sop
                    RET


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

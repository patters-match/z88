; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2004
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

     xdef DeleteFileCommand

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFindFile           ; Find File Entry using search string (of null-term. filename)
     lib FlashEprFileDelete        ; Mark file as deleted on Flash Eprom

     xref cls, wbar, sopnln
     xref DispErrMsg, disp_no_filearea_msg
     xref FilesAvailable, no_files
     xref FlashWriteSupport
     xref DispIntelSlotErr
     xref exct_msg, fnam_msg

     ; system definitions
     include "stdio.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
; Mark file as Deleted in File Area
; User enters name of file that will be searched for, and if found,
; it will be marked as deleted.
;
.DeleteFileCommand
                    call cls

                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    jr   z, check_deletable_files
                    call disp_no_filearea_msg
                    ret
.check_deletable_files
                    call FilesAvailable
                    jp   z, no_files              ; Fz = 1, no files available...

                    call FlashWriteSupport        ; check if Flash Card in current slot supports saveing files?
                    call c,DispIntelSlotErr
                    ret  c                        ; it didn't...
                    ret  nz                       ; (and flash chip was not found in slot!)

                    call cls
                    ld   hl,delfile_bnr
                    call wbar
                    ld   hl,exct_msg
                    call sopnln
                    ld   hl,fnam_msg
                    CALL_OZ gn_sop

                    LD   HL,buf1                  ; preset input line with '/'
                    LD   (HL),'/'
                    INC  HL
                    LD   (HL),0
                    DEC  HL
                    EX   DE,HL

                    LD   A,@00100011
                    LD   BC,$4001
                    LD   L,$20
                    CALL_OZ gn_sip
                    jp   c,sip_error
                    CALL_OZ gn_nln

                    CALL file_markdeleted
                    RET
.sip_error
                    CP   RC_SUSP
                    JR   Z, DeleteFileCommand
                    RET
; *************************************************************************************



; *************************************************************************************
;
.file_markdeleted
                    LD   A,(curslot)
                    LD   C,A
                    LD   DE,buf1
                    CALL FileEprFindFile          ; search for <buf1> filename on File Eprom...
                    JR   C, delfile_notfound      ; File Eprom or File Entry was not available
                    JR   NZ, delfile_notfound     ; File Entry was not found...

                    CALL FlashEprFileDelete
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



; *************************************************************************************
; constants

.delfile_bnr        DEFM "DELETE FILE IN FILE AREA",0

.delfile_err_msg    DEFM "File not found.", 0
.markdelete_failed  DEFM "Error. File not deleted.",0
.filedel_msg        DEFM 1,"2JC", "File deleted.",1,"2JN", 0

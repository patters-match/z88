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

Module ErrorMessages

; This module contains functionality to display various error messages from the
; available commands in FlashStore.

     XDEF ReportStdError, DispSlotErrorMsg, DispErrMsg
     XDEF NoAppFileAreaMsg, disp_empty_flcard_msg
     XDEF disp_no_filearea_msg, DispIntelSlotErr
     XDEF no_files

     XREF DispCmdWindow, FileEpromStatistics
     XREF VduEnableCentreJustify, VduEnableNormalJustify
     XREF cls, sopnln, ResSpace

     ; system definitions
     include "stdio.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
.ReportStdError     PUSH AF
                    CALL_OZ(Gn_Err)
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Display a centre-justified message, which is defined by two null-terminated strings.
; The current slot number is displayed between the two strings.
;
; IN:
;    HL = Pointer to address block, containg (string1), (string2)
;
; Registers changed after return:
;    AFBCDE../IXIY same
;    ......HL/.... different
;
.DispSlotErrorMsg   PUSH AF
                    PUSH DE
                    CALL VduEnableCentreJustify
                    CALL GetMsgAddr
                    CALL_OZ GN_Sop
                    LD   A,(curslot)
                    ADD  A,48
                    CALL_OZ OS_Out
                    EX   DE,HL
                    CALL GetMsgAddr
                    CALL sopnln
                    CALL VduEnableNormalJustify
                    POP  DE
                    POP  AF
                    RET
.GetMsgAddr         LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    EX   DE,HL
                    RET


; *************************************************************************************
.NoAppFileAreaMsg   PUSH HL
                    LD   HL, no_appflarea_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.disp_empty_flcard_msg
                    PUSH HL
                    LD   HL, empty_flcard_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************



; *************************************************************************************
.disp_no_filearea_msg
                    PUSH HL
                    LD   HL, nofilearea_msgs
                    CALL DispSlotErrorMsg

                    CALL DispCmdWindow       ; Update the command window (Grey out)
                    CALL FileEpromStatistics ; Update the File Area Statistics window
                    CALL ResSpace            ; "Press SPACE to resume" ...
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.no_files
                    LD   HL, noeprfilesmsg
                    CALL DispErrMsg
                    RET
; *************************************************************************************


; *************************************************************************************
.DispIntelSlotErr
                    push af
                    push hl
                    call cls
                    ld   hl, intelslot_msgs
                    CALL DispSlotErrorMsg
                    CALL ResSpace            ; "Press SPACE to resume" ...
                    pop  hl
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Write Error message, and wait for SPACE key to be pressed.
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.DispErrMsg
                    PUSH AF                  ; preserve error status...
                    PUSH HL
                    CALL_OZ GN_Nln
                    CALL VduEnableCentreJustify
                    CALL sopnln
                    CALL VduEnableNormalJustify
                    CALL ResSpace            ; "Press SPACE to resume" ...
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; constants

.no_appflarea_msgs  DEFW no_appflarea1_msg
                    DEFW no_appflarea2_msg
.no_appflarea1_msg  DEFM 13, 10, 1,"BNo File Area available on Application Card in slot ",0
.no_appflarea2_msg  DEFM ".",1,"B",0

.empty_flcard_msgs  DEFW empty_flcard1_msg
                    DEFW empty_flcard2_msg
.empty_flcard1_msg  DEFM 13, 10, 1,"BFlash Card is empty in slot ", 0
.empty_flcard2_msg  DEFM ".",1,"B",0


.intelslot_msgs     DEFW intelslot_err1_msg
                    DEFW intelslot_err2_msg
.intelslot_err1_msg DEFM 13, 10, 1,"BIntel Flash Card found in slot ",0
.intelslot_err2_msg DEFM ".",1,"B", 13, 10, "You can only format file area, save files or", 13, 10
                    DEFM "delete files in slot 3.", 13, 10, 0

.nofilearea_msgs    DEFW nofilearea1_msg
                    DEFW nofilearea2_msg
.nofilearea1_msg    DEFM 13, 10, 1,"BFile Area not detected in slot ",0
.nofilearea2_msg    DEFM ".",1,"B", 13, 10, "(card might have been removed whilst FlashStore running)", 13, 10, 0

.noeprfilesmsg      DEFM "Empty File Area.",$0D,$0A,0
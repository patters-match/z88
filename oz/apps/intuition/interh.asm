; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
;***************************************************************************************************

     MODULE Intuition_Error_handler

     INCLUDE "defs.h"
     INCLUDE "error.def"
     INCLUDE "stdio.def"
     INCLUDE "time.def"
     INCLUDE "director.def"

     XREF Save_alternate, Restore_Alternate
     XREF Write_Err_msg
     XREF Toggle_CLI
     XREF Disp_monitor_win, RST_INT_window, REL_appl_window

     XDEF Use_IntErrhandler, RST_ApplErrhandler, Int_Errhandler


; ******************************************************************************
;
; Activate Intuition Error Handler (to be bound into segment 3)
;
.Use_IntErrhandler  PUSH AF
                    PUSH BC
                    PUSH HL
                    XOR  A
                    LD   B,A
                    LD   HL, Int_Errhandler
                    CALL_OZ(Os_Erh)
.RET_os_erh         LD   (IY + ApplErhClvl),A          ; preserve call level and
                    LD   (IY + ApplErhAddr  ),L        ; address of
                    LD   (IY + ApplErhAddr+1),H        ; application error handler
                    POP  HL
                    POP  BC
                    POP  AF
                    RET



; ******************************************************************************
;
; Restore Application Error Handler.
;
.RST_ApplErrhandler PUSH AF
                    PUSH BC
                    PUSH HL
                    LD   A,(IY + ApplErhClvl)          ; get call level and
                    LD   L,(IY + ApplErhAddr)          ; address of
                    LD   H,(IY + ApplErhAddr+1)        ; application error handler
                    LD   B,0
                    CALL_OZ(Os_Erh)
                    POP  HL
                    POP  BC
                    POP  AF
                    RET



; ******************************************************************************************
;
; Intuition Error handler                               ** V0.31
;
.Int_Errhandler     RET  Z
                    CP   RC_ROOM
                    JR   Z, no_room
                    CP   RC_SUSP
                    JR   Z, suspension
                    CP   RC_TIME
                    JR   Z, timeout
                    CP   RC_DRAW                        ; application screen corrupted
                    JR   Z,corrupt_scr
                    CP   RC_QUIT
                    JR   Z, Intuition_suicide
                    CP   RC_ESC
                    JR   Z, ackn_esc
                    CALL Disp_Monitor_win               ; display Intuition screen
                    CALL Write_Err_Msg
                    XOR  A                              ; ignore rest of errors
                    RET

.timeout
.suspension         XOR  A
                    RET

.no_room            CALL_OZ(Gn_Err)                     ; Display system error window

.Intuition_suicide  CALL RST_INT_window                 ; restore Intuition window...
                    LD   A,12
                    CALL_OZ(Os_out)                     ; clear Intuition window
                    LD   A, ERR_KILL_request
                    CALL Write_err_msg
                    LD   A,7
                    CALL_OZ(Os_Out)                     ; warning bleep...
                    LD   BC,100
                    CALL_OZ(Os_Dly)                     ; delay 1 second...
                    CALL REL_appl_window                ; release application screen window
                    XOR  A
                    CALL_OZ(Os_Bye)                     ; kill Appl. & Intuition; ret. to Index

.corrupt_scr        PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX
                    CALL Save_alternate
                    BIT  Flg_IntScr, (IY + Flagstat1)
                    CALL Z, Disp_Monitor_win            ; no screen saved, re-display Intuition window
                    CALL NZ, RST_INT_window             ; restore Intuition window
                    CALL Restore_alternate
                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    XOR  A
                    RET

.ackn_esc           CALL Save_alternate
                    CALL_OZ(Os_Esc)                     ; acknowledge ESC, A = RC_ESC...
                    CALL Restore_alternate
                    LD   A,27                           ; ESC code
                    CP   A                              ; Fc = 0 ...
                    RET

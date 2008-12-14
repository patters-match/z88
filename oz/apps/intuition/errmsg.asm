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
; $Id$
;
;***************************************************************************************************

     MODULE Error_messages


     XREF Write_Msg

     ; Routines & strings globally available:
     XDEF Syntax_error
     XDEF Write_err_msg, Get_errmsg

     INCLUDE "defs.h"
     INCLUDE "error.def"
     INCLUDE "stdio.def"


; *******************************************************************
.Syntax_error       LD   A, RC_SNTX
                    CALL Write_Err_Msg
                    SCF
                    RET


; ******************************************************************************
.Write_err_msg      BIT  7,A                              ; Intuition error message?
                    CALL NZ, Get_errmsg
                    JP   NZ, Write_Msg
                    CP   A
                    CALL_OZ(Gn_Esp)                       ; get ext. pointer
                    CALL_OZ(Gn_Soe)                       ; write error msg. to std. output
                    CALL_OZ(Gn_Nln)                       ; terminate line with CRLF
                    RET


; ******************************************************************************
;
; Return pointer to error message from code in A                V0.26e
;
.Get_errmsg         PUSH AF
                    LD   D,0
                    LD   E,A
                    SLA  E                                ; word boundary
                    LD   HL, Errmsg_lookup
                    ADD  HL,DE                            ; HL points at index containing pointer
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                           ; pointer fetched in
                    EX   DE,HL                            ; HL
                    POP  AF
                    RET

.Errmsg_lookup      DEFW Error_msg_80
                    DEFW Error_msg_81
                    DEFW Error_msg_82
                    DEFW Error_msg_83
                    DEFW Error_msg_84
                    DEFW Error_msg_85

; Intuition specific errors
.Error_Msg_80       DEFM "unknown Z80 opc.",0
.Error_Msg_81       DEFM "unbalanced RET",0
.Error_Msg_82       DEFM "not found",0
.Error_Msg_83       DEFM "none",0
.Error_Msg_84       DEFM "KILL request",0
.Error_Msg_85       DEFM "Bindout alert!",0

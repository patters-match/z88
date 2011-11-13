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

     MODULE Display_information

     XREF Save_alternate, Restore_alternate
     XDEF Write_Msg, Display_char, Display_string, Write_CRLF

     INCLUDE "defs.h"
     INCLUDE "stdio.def"


; *******************************************************************
;
; Write message to window
; HL points to Null-terminated string
;
.Write_Msg        PUSH AF
                  PUSH HL
                  CALL Display_String
                  CALL Write_CRLF
                  POP  HL
                  POP  AF
                  RET


; ******************************************************************************
;
; Display a character in current window at cursor position
; V0.17
;
; IN: A = character
;
; F, IX different on return
;
.Display_Char     CALL Save_alternate       ; alternate registers used by OZ...
                  PUSH AF
                  CALL_OZ(Os_Out)
                  POP  AF
                  CALL Restore_Alternate
                  RET



; ******************************************************************************
;
; Display a string in current window at cursor position
; V0.17
;
; IN: HL points at string.
;
; HL, IX different on return
; Alternate registers are preserved due to information needed by disassembler
;
.Display_String   CALL Save_alternate
                  CALL_OZ(Gn_Sop)           ; write string
                  CALL Restore_Alternate
                  RET


; *******************************************************************
;
; execute a CRLF
;
.Write_CRLF       CALL Save_alternate
                  CALL_OZ(Gn_Nln)
                  CALL Restore_Alternate
                  RET

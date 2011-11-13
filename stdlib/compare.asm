     XLIB Compare

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
;
;***************************************************************************************************


; ******************************************************************************
;
;    Compare two signed 8bit integers in A and B.
;
;    Result return as:
;         Fz = 1:   A >= B
;         Fz = 0:   A < B
;
;    Register affected on return:
;         A.BCDEHL/IXIY
;         .F....../....
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Compare            PUSH BC
                    LD   C,A                      ; preserve original value of A
                    CP   B                        ; execute real comparison
                    LD   A,0
                    LD   B,A                      ; now use registers as logical flags
                    CALL PE,Set_Overflow          ; set overflow flag
                    CALL M,Set_Minus              ; set minus flag
                    XOR  B                        ; perform P/V XOR S
                    LD   A,C                      ; restore A
                    POP  BC                       ; restore BC
                    RET                           ; if (P/V XOR S) = 0, then A >= B
.Set_overflow       CPL                           ; A logical true
                    RET
.Set_minus          LD   B,$FF                    ; B logical true
                    RET

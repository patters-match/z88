     XLIB Set_pointer

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB Bind_bank_s1


; ******************************************************************************
;
;    Set (store) at extended address BHL,A the pointer in CDE
;
;    Register affected on return:
;         AFBCDEHL/IXIY
;         ......../.... af
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Set_pointer        PUSH HL
                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; pointer adjusted to offset
                    POP  DE
                    PUSH AF
                    LD   A,B
                    CALL Bind_bank_s1
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    INC  HL
                    LD   (HL),C
                    CALL Bind_bank_s1
                    POP  AF
                    POP  HL
                    RET

     XLIB MemReadWord

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
; $Id$  
;
;***************************************************************************************************

     LIB MemDefBank


; ******************************************************************************
;
; Read word at record defined as extended (base) address in BHL, offset A.
; Segment mask must be specified in H.
;
; Return word in DE.
;
;    Register affected on return:
;         AFBC..HL/IXIY same
;         ....DE../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, July 1998
; ----------------------------------------------------------------------
;
.MemReadWord        PUSH HL
                    PUSH BC
                    PUSH AF

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE               ; add offset to pointer

                    LD   A,H
                    RLCA
                    RLCA
                    AND  3                   ; top address bits of pointer identify
                    LD   C,A                 ; B = Bank, C = MS_Sx Segment Specifier

                    CALL MemDefBank          ; page in bank temporarily
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    CALL MemDefBank          ; restore prev. binding

                    POP  AF
                    POP  BC
                    POP  HL
                    RET

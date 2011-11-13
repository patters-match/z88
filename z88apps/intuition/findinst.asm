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

     MODULE Find_Instruction

     XDEF FindInstruction

     INCLUDE "defs.h"


; **********************************************************************************
;
; Find instruction bit pattern at virtual processor PC.
;
; Entry : DE = current virtual processor PC
; Return: If instruction found:  Fz = 1,
;                         else:  Fz = 0
;
; Register status after return:
;
;       ......../IXIY  same
;       AFBCDEHL/....  different
;
.FindInstruction  LD   BC,InstrBreakPatt
                  PUSH IY                   ;
                  POP  HL                   ;
                  ADD  HL,BC                ; HL = base pointer to instruction pattern
                  LD   B,(HL)               ; get size of instruction bit pattern
.srch_instr_loop  INC  HL                   ; HL to base address of breakpoints
                  LD   A,(DE)               ; Get byte from (PC)
                  CP   (HL)
                  RET  NZ                   ; instruction bit pattern not found
                  INC  DE
                  DJNZ srch_instr_loop      ; match found, continue until all matched...
                  RET                       ; Fz = 1, Bit pattern found

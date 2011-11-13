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

     MODULE Find_breakpoint

     XDEF FindBreakPoint

     INCLUDE "defs.h"



; **********************************************************************************
;
; Find a breakpoint in breakpoint list.
;
; Entry : DE = breakpoint address (usually taken directly from PC)
; Return: DE = breakpoint address
;         If breakpoint found:  Fz = 1, (HL) points at low byte address
;                        else:  Fz = 0
;
; Register status after return:
;
;       ....DE../IXIY  same
;       AFBC..HL/....  different
;
.FindBreakPoint   LD   BC,BreakPoints
                  PUSH IY
                  POP  HL
                  ADD  HL,BC
                  LD   B,(HL)               ; get number of breakpoints
.search_bp_loop   INC  HL                   ; HL to base address of breakpoints         ** V0.28
                  LD   A,(HL)               ; Get high byte of address
                  INC  HL                   ; point at low byte
                  CP   D                    ; found high byte?
                  JR   NZ, not_found        ; no, get next high byte
                  LD   A,(HL)               ; get low byte of br.p. address
                  CP   E
                  RET  Z                    ; breakpoint found!
.not_found        DJNZ search_bp_loop       ; not found, continue if more breakpoints   ** V0.28
                  RET                       ; Fz = 0, 'Not found'                       ** V0.28

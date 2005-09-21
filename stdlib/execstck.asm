
    XLIB ExecRoutineOnStack

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


; ***************************************************************
;
; Clone small subroutine on stack and execute it.
; The subroutine must be ended with a RET instruction.
;
; IN:
;     BC' = size of routine.
;     IX = pointer to routine.
;
;     Available input parameter registers for the executing routine:
;          A, A', BC, DE, HL & IY
;
; OUT:
;     Register changes are subroutine dependent
;
; Registers changed on return:
;    ......../.... af...... same
;    ????????/???? ..bcdehl different
;
.ExecRoutineOnStack
                    EXX      
                    PUSH AF
                    LD   HL,0
                    ADD  HL,SP
                    LD   D,H
                    LD   E,L                 ; current SP in DE...
                    CP   A                   ; Fc = 0
                    SBC  HL,BC               ; BC' = length of routine, make room on stack (which moves downwards...)
                    LD   SP,HL               ; new SP defined, space for buffer for routine ready...
                    EX   DE,HL               ; HL = old SP (top of buffer), DE = new SP (destination)
                    PUSH HL                  ; original SP will be restored after routine has completed
                    PUSH DE                  ; execute routine by using a RET instruction

                    PUSH IX
                    POP  HL   
                    LDIR                     ; copy routine to stack buffer...
                    LD   HL,exit_routine
                    EX   (SP),HL             ; the RET at the end of the routine will jump to
                    PUSH HL                  ; .exit_routine, which will restore the original SP and get
                    EXX                      ; back to the outside world 
                    POP  AF
                    RET                      ; (SP) = CALL routine on stack...
.exit_routine
                    EXX
                    POP  HL
                    LD   SP,HL               ; restore original SP (purge buffer routine on stack)
                    EXX
                    RET                      ; return to back to outside world (registers changed by IX routine)


    XLIB ExecRoutineOnStack


; ***************************************************************
;
; Clone small subroutine on stack and execute it.
;
; IN:
;     BC = size of routine.
;     IX = pointer to routine.
; OUT:
;     Register changes are subroutine dependent
;
; Registers changed on return:
;    ......../.... ........ same
;    ????????/???? afbcdehl different
;
.ExecRoutineOnStack
                    PUSH BC
                    EXX
                    POP  BC                  ; length of routine
                    LD   HL,0
                    ADD  HL,SP
                    LD   D,H
                    LD   E,L                 ; current SP in DE...
                    CP   A                   ; Fc = 0
                    SBC  HL,BC               ; make room for routine on stack (which moves downwards...)
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
                    RET                      ; (SP) = CALL routine on stack...
.exit_routine
                    EXX
                    POP  HL
                    LD   SP,HL               ; restore original SP (purge buffer routine on stack)
                    EXX
                    RET                      ; return to back to outside world (registers changed by IX routine)

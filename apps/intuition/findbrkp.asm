
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
.FindBreakPoint   LD   BC,31                ;                                           ** V0.19
                  PUSH IY                   ;                                           ** V0.19
                  POP  HL                   ;                                           ** V0.19
                  ADD  HL,BC                ; HL = IY + 31                              ** V0.19
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

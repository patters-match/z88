
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
.FindInstruction  LD   BC,84                ;
                  PUSH IY                   ;
                  POP  HL                   ;
                  ADD  HL,BC                ; HL = IY + 31
                  LD   B,(HL)               ; get size of instruction bit pattern
.srch_instr_loop  INC  HL                   ; HL to base address of breakpoints
                  LD   A,(DE)               ; Get byte from (PC)
                  CP   (HL)
                  RET  NZ                   ; instruction bit pattern not found
                  INC  DE
                  DJNZ srch_instr_loop      ; match found, continue until all matched...
                  RET                       ; Fz = 1, Bit pattern found

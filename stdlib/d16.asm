module d16

org $2000

ld   hl, 64
ld   de, 9
call d16
ret


; *************************************************************
;
; Unsigned 16bit division
;
; IN:
;    HL = dividend
;    DE = divisor
;
; OUT, if call successful:
;    Fc = 0
;    HL = quotient
;    DE = remainder
;
; OUT, if call failed:
;    Fc = 1
;    division by zero attempted
;
; Registers changed after return:
;    ..BC..../IXIY same
;    AF..DEHL/.... different
;
.D16
     PUSH BC

     LD   A,E
     OR   D
     JR   NZ,L_EDE3
     SCF  
     JR   L_EE04
.L_EDE3   LD   C,L
     LD   A,H
     LD   HL,0
     LD   B,16
     OR   A
.L_EDEB   RL   C
     RLA  
     RL   L
     RL   H
     PUSH HL
     SBC  HL,DE
     CCF  
     JR   C,L_EDF9
     EX   (SP),HL
.L_EDF9   INC  SP
     INC  SP
     DJNZ L_EDEB
     EX   DE,HL
     RL   C
     LD   L,C
     RLA  
     LD   H,A
     OR   A

.L_EE04   POP  BC
     RET  


     XLIB Set_long

     LIB Bind_bank_s1


; ******************************************************************************
;
;    Set long integer (in debc) at pointer in BHL,A.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Register affected on return:
;         ..BCDEHL/IXIY ..bcde..   same
;         AF....../.... af....hl   different
;
.Set_long           PUSH HL
                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; set pointer at offset
                    LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    PUSH HL
                    EXX
                    POP  HL
                    LD   (HL),C
                    INC  HL
                    LD   (HL),B
                    INC  HL
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    EXX
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  DE
                    POP  HL
                    RET

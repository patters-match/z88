     XLIB Set_word

     LIB Bind_bank_s1


; ******************************************************************************
;
;    Set word in DE at pointer in BHL,A.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Register affected on return:
;         ..BCDEHL/IXIY
;         AF....../.... af
;
.Set_word           PUSH HL
                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; set pointer at offset
                    LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    POP  DE
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  HL
                    RET

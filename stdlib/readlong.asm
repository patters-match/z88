     XLIB Read_long
     LIB Bind_bank_s1


; ******************************************************************************
;
;    Read long integer (in debc) at pointer in BHL,A.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Register affected on return:
;         ..BCDEHL/IXIY .......   same
;         AF....../.... afbcdehl   different
;
.Read_long          PUSH HL
                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; set pointer at offset
                    LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    PUSH HL
                    EXX
                    POP  HL
                    LD   C,(HL)
                    INC  HL
                    LD   B,(HL)
                    INC  HL
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    EXX
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  DE
                    POP  HL
                    RET

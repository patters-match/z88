     XLIB Set_pointer

     LIB Bind_bank_s1



; ******************************************************************************
;
;    Set (store) at extended address BHL,A the pointer in CDE
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Register affected on return:
;         AFBCDEHL/IXIY
;         ......../.... af
;
.Set_pointer        PUSH HL
                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; pointer adjusted to offset
                    POP  DE
                    PUSH AF
                    LD   A,B
                    CALL Bind_bank_s1
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    INC  HL
                    LD   (HL),C
                    CALL Bind_bank_s1
                    POP  AF
                    POP  HL
                    RET

     XLIB Set_byte

     LIB Bind_bank_s1


; ******************************************************************************
;
;    Set byte in C, at pointer in BHL,A.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Register affected on return:
;         ..BCDEHL/IXIY
;         AF....../.... af
;
.Set_byte           PUSH HL
                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; set pointer at offset
                    LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    LD   (HL),C                   ; set byte in extended address
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  DE
                    POP  HL
                    RET

     XLIB Read_word
     LIB Bind_bank_s1


; ******************************************************************************
;
;    Read word at pointer in BHL,A. Return word in DE.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Register affected on return:
;         ..BC..HL/IXIY
;         AF..DE../.... af
;
.Read_word          PUSH HL
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; set pointer at offset
                    LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                   ; read word at ext. address
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  HL
                    RET

     XLIB Read_pointer

     LIB Bind_bank_s1


; ******************************************************************************
;
;    Read pointer at record defined as extended (base) address in BHL, offset A.
;    Return (extended) pointer in BHL.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Register affected on return:
;         AF.CDE../IXIY
;         ..B...HL/.... af
;
.Read_pointer       PUSH DE
                    PUSH AF
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; set pointer at offset
                    LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    LD   B,(HL)
                    EX   DE,HL                    ; extended pointer in BHL
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  AF
                    POP  DE
                    RET

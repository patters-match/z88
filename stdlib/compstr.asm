
     XLIB StrCmp

     LIB Bind_bank_s1
     LIB Read_byte


; ******************************************************************************
;
; Compare two strings, both stored at extended address.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    IN:  BHL = extended pointer to string a
;         CDE = extended pointer to string b
;   OUT:
;         Fz = 1; Fc = 0:     A = B
;         Fz = 0; Fc = 1:     A < B
;         Fz = 0; Fc = 0:     A > B
;
;         Both strings must have the length identifier stored at position 0.
;
;         The strings are both compared in segment 1, either locally or as extended
;         adresses in different banks.
;
; Registers changed after return:
;
;    A.BCDEHL/IXIY  same
;    .F....../....  different
;
.Strcmp             PUSH BC
                    PUSH AF
                    PUSH DE
                    PUSH HL
                    LD   A,B
                    CP   C                        ; both strings in same bank?
                    JR   Z, compare_local_strings

                    EXX
                    PUSH BC
                    PUSH DE
                    PUSH HL                       ; preserve alternate registers
                    EXX
                    PUSH BC
                    PUSH DE
                    EXX
                    POP  HL
                    POP  BC
                    LD   B,C                      ; string b pointer
                    XOR  A
                    CALL Read_byte
                    INC  HL
                    EXX
                    LD   E,A                      ; E = length of string b
                    XOR  A
                    CALL Read_byte
                    INC  HL

                    LD   D,A                      ; D = length of string a
                    CP   E                        ; use shortest string
                    PUSH DE
                    JR   C, cmp_extstrings        ; A < B
                    LD   D,E                      ; A >= B
.cmp_extstrings          EXX
                         XOR  A
                         CALL Read_byte           ; get byte from string b
                         INC  HL
                         EXX
                         LD   C,A
                         XOR  A
                         CALL Read_byte           ; get byte from string a
                         INC  HL
                         CP   C                   ; compare with char from string b
                         JR   NZ, extstr_not_equal; the two bytes do not match
                    DEC  D
                    JR   NZ, cmp_extstrings       ; continue until string is checked
                    POP  DE
                    LD   A,D                      ; compare string lengths
                    CP   E                        ; Fz = 0; Fc = 1, A < B
                    JR   exit_extstrcompare       ; Fz = 1, A = B. Fc = 0, A > B
.extstr_not_equal   POP  DE
.exit_extstrcompare EXX
                    POP  HL
                    POP  DE
                    POP  BC                       ; alternate registers restored
                    EXX
                    POP  HL                       ; original HL restored
                    POP  DE                       ; original DE restored
                    POP  BC
                    LD   A,B                      ; original A restored
                    POP  BC                       ; original BC restored
                    RET

.compare_local_strings
                    CALL Bind_Bank_s1             ; make sure both strings are paged in
                    PUSH AF                       ; preserve old binding of segm. 1
                    LD   A,(DE)                   ; C = length of string b
                    INC  DE                       ; point at first byte of string 2
                    LD   C,A
                    LD   A,(HL)                   ; B = length of string a
                    INC  HL
                    EX   DE,HL
                    LD   B,A
                    CP   C                        ; use shortest string
                    PUSH BC
                    JR   C, cmp_strings           ; A < B
                    LD   B,C                      ; A >= B
.cmp_strings             LD   A,(DE)              ; get char from string a
                         INC  DE
                         CP   (HL)                ; compare with char from string b
                         INC  HL
                         JR   NZ,str_not_equal    ; the two bytes do not match
                    DJNZ cmp_strings              ; continue until string is checked
                    POP  DE                       ; get string lengths
                    POP  AF                       ; get old segment bank binding
                    CALL Bind_bank_s1             ; restore binding...
                    LD   A,D
                    CP   E
                    JR   exit_strcompare          ; Fz = 0; Fc = 1, A < B
                                                  ; Fz = 1, A = B. Fc = 0, A > B

.str_not_equal      POP  DE                       ; get string lengths
                    POP  BC                       ; get old segment bank binding
                    LD   A,B
                    PUSH AF                       ; preserve flags from comparison
                    CALL Bind_bank_s1             ; restore binding...
                    POP  AF

.exit_strcompare    POP  HL                       ; original HL restored
                    POP  DE                       ; original DE restored
                    POP  BC
                    LD   A,B                      ; original A restored
                    POP  BC                       ; original BC restored
                    RET


     XLIB StrChr

; ******************************************************************************
;
; StrChr - find character in string.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;  IN:    A  = ASCII byte
;         HL = pointer to string, first byte defined as length byte.
; OUT:    Fz = 1: if byte was found in string.
;                 A = position of found character in string (0 = first).
;         Fz = 0, byte not found, A last position of string.
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.StrChr             PUSH BC
                    PUSH HL
                    LD   B,0
                    LD   C,(HL)              ; get length of string
                    INC  HL                  ; point at first character
                    CPIR                     ; search...
                    POP  HL
                    PUSH AF                  ; preserve search flags
                    INC  C
                    LD   A,(HL)
                    SUB  C                   ; A = position of found char.
                    LD   B,A
                    POP  AF                  ; restore search flags
                    LD   A,B                 ; position in A
                    POP  BC
                    RET


     XLIB IsAlpha

; ******************************************************************************
;
; IsAlpha - check whether the ASCII byte is an alphabetic character or not.
; The underscore character is defined as an alphabetic character.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;  IN:    A = ASCII byte
; OUT:    Fz = 1, if byte was alphabetic, otherwise Fz = 0
;
; Registers changed after return:
;
;    A.BCDEHL/IXIY  same
;    .F....../....  different
;
.IsAlpha            CP   'z'
                    RET  NC                  ; byte >= 'z'
                    CP   'a'
                    JR   C, test_underscore
                    CP   A                   ; 'a' <= byte < 'z'
                    RET
.test_underscore    CP   '_'
                    RET  NC                  ; '_' <= byte < 'a'
                    CP   'Z'
                    RET  NC                  ; 'Z' <= byte < '_'
                    CP   'A'
                    RET  C                   ; byte < 'A', not alphabetic
                    CP   A                   ; 'A' <= byte < 'Z', alphabtic found
                    RET


     XLIB InvCase


; ******************************************************************************
;
; Invert character case to either upper or lower case.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;  IN:    A = ASCII byte
; OUT:    A = converted ASCII byte
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.InvCase            CP   '['       ; if A <= 'Z'  &&
                    JR   NC, check_lowercase
                    CP   'A'       ; if A >= 'A'
                    RET  C
                    XOR  32        ; inverse case...
                    RET
.check_lowercase    CP   '{'       ; if A <= 'z'  &&
                    JR   NC, check_latin1
                    CP   'a'       ; if A >= 'a'
                    RET  C
                    XOR  32        ; inverse case
                    RET
.check_latin1       CP   $FF       ; if A <= $FE  &&
                    RET  Z
                    CP   $C0       ; if A >= $C0
                    RET  C
                    XOR  32        ; then inverse case
                    RET

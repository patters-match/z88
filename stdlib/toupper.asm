
     XLIB ToUpper

; ******************************************************************************
;
; ToUpper - convert character to upper case if possible.
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
.ToUpper            CP   '{'       ; if A <= 'z'  &&
                    JR   NC, check_latin1
                    CP   'a'       ; if A >= 'a'
                    RET  C
                    SUB  32        ; then A = A - 32
                    RET
.check_latin1       CP   $FF       ; if A <= $FE  &&
                    RET  Z
                    CP   $E1       ; if A >= $E1
                    RET  C
                    SUB  32        ; then A = A - 32
                    RET

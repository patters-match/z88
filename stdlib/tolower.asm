
     XLIB ToLower

; ******************************************************************************
;
; ToLower - convert character to lower case if possible.
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
.ToLower            CP   '['       ; if A <= 'Z'  &&
                    JR   NC, check_latin1
                    CP   'A'       ; if A >= 'A'
                    RET  C
                    ADD  A,32      ; then A = A + 32
                    RET
.check_latin1       CP   $DF       ; if A <= $DE  &&
                    RET  Z
                    CP   $C0       ; if A >= $C0
                    RET  C
                    ADD  A,32      ; then A = A + 32
                    RET

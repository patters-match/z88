
     XLIB IsDigit

; ******************************************************************************
;
; IsDigit - check whether the ASCII byte is a digit or not.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;  IN:    A = ASCII byte
; OUT:    Fz = 1, if byte was a digit, otherwise Fz = 0
;
; Registers changed after return:
;
;    A.BCDEHL/IXIY  same
;    .F....../....  different
;
.IsDigit            CP   '9'
                    RET  NC                  ; byte >= '9'
                    CP   '0'
                    RET  C
                    CP   A                   ; '0' <= byte < '9'
                    RET

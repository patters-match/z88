     XLIB IsAlNum

     LIB IsDigit, IsAlpha


; ******************************************************************************
;
; IsAlNum - check whether the ASCII byte is an alphanumeric character or not.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;  IN:    A = ASCII byte
; OUT:    Fz = 1, if byte was alphanumeric, otherwise Fz = 0
;
; Registers changed after return:
;
;    A.BCDEHL/IXIY  same
;    .F....../....  different
;
.IsAlNum            CALL IsDigit
                    RET  Z
                    CALL IsAlpha
                    RET

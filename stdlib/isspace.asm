
     XLIB IsSpace

; ******************************************************************************
;
; IsSpace - check whether the ASCII byte is a white space
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;  IN:    A = ASCII byte
; OUT:    Fz = 1, if byte was a white space, otherwise Fz = 0
;
; Registers changed after return:
;
;    A.BCDEHL/IXIY  same
;    .F....../....  different
;
.IsSpace            CP   ' '
                    RET  Z                   ; byte = ' '
                    RET  NC                  ; byte > ' ', not a white space
                    CP   A                   ; 0 <= byte < ' '
                    RET


     XLIB CmpPtr

; ******************************************************************************
;
; Compare two pointers
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    IN:  BHL, CDE
;   OUT:  Fz = 1 if equal, otherwise Fz = 0
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.CmpPtr             LD   A,B
                    CP   C
                    RET  NZ
                    LD   A,H
                    CP   D
                    RET  NZ
                    LD   A,L
                    CP   E
                    RET

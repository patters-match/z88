
     XLIB Compare

; ******************************************************************************
;
;    Compare two signed 8bit integers in A and B.
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    Result return as:
;         Fz = 1:   A >= B
;         Fz = 0:   A < B
;
;    Register affected on return:
;         A.BCDEHL/IXIY
;         .F....../....
;
.Compare            PUSH BC
                    LD   C,A                      ; preserve original value of A
                    CP   B                        ; execute real comparison
                    LD   A,0
                    LD   B,A                      ; now use registers as logical flags
                    CALL PE,Set_Overflow          ; set overflow flag
                    CALL M,Set_Minus              ; set minus flag
                    XOR  B                        ; perform P/V XOR S
                    LD   A,C                      ; restore A
                    POP  BC                       ; restore BC
                    RET                           ; if (P/V XOR S) = 0, then A >= B
.Set_overflow       CPL                           ; A logical true
                    RET
.Set_minus          LD   B,$FF                    ; B logical true
                    RET


     XLIB Bind_bank_s2

; ******************************************************************************
;
;    Bind bank, defined in A, into segment 2. Return old bank binding in A.
;    This is the functional equivalent of OS_MPB, but much faster.
;
;    Register affected on return:
;         ..BCDEHL/IXIY
;         AF....../.... af
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
.Bind_bank_s2       PUSH BC
                    LD   B,A
                    EX   AF,AF'
                    LD   A,($04D2)
                    CP   B
                    POP  BC
                    RET  Z                   ; bank already bound into segment
                    PUSH AF
                    EX   AF,AF'
                    LD   ($04D2),A
                    OUT  ($D2),A
                    POP  AF
                    RET

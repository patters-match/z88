
     XLIB Open_pool

if MSDOS | UNIX
    INCLUDE "memory.def"
else
    INCLUDE ":*//memory.def"
endif


; ******************************************************************************
;
; INTERNAL MALLOC ROUTINE
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; Open a memory pool for segment 1. Memory handle returned in IX if Fc = 0.
; If no memory is available, Fc = 1 is returned (IX unchanged).
;
; Register status on return:
; A.BCDEHL/..IY  same
; .F....../IX..  different
;
.Open_pool          PUSH BC
                    PUSH AF                         ; preserve A
                    LD   A,MM_S1                    ; memory mask for segment 1 (&40)
                    LD   BC,0
                    CALL_OZ(OS_MOP)                 ; open pool (initial 256 byte size)
                    POP  BC
                    LD   A,B                        ; A restored
                    POP  BC                         ; BC restored
                    RET

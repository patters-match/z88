     XLIB EnableInt

     INCLUDE "interrpt.def"


; ***************************************************************************
;
; Enable (previous) Interrupt Status (performed by <DisableInt>).
;
; IN:
;    IX = old interrupt status
;
; OUT:
;    -
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.EnableInt          PUSH AF
                    PUSH IX
                    POP  AF
                    CALL OZ_EI               ; restore old Int. status
                    POP  AF
                    RET

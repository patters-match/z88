     XLIB DisableInt

     INCLUDE "interrpt.def"

; ***************************************************************************
;
; Disable Maskable Interrupt Status
;
; IN:
;    -
;
; OUT:
;    IX = old interrupt status
;
; Registers changed after return:
;    AFBCDEHL/..IY same
;    ......../IX.. different
;
.DisableInt         PUSH AF
                    CALL OZ_DI
                    PUSH AF
                    POP  IX                  ; preserve Int. status
                    POP  AF
                    RET

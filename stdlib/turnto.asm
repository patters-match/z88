
     xlib turnto

     xref HEADING

if z88
     include ":*//fpp.def"
else
     include "fpp.def"
endif


; ****************************************************************************
;
; Move turtle heading in absolute degrees.
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; IN:     HL = absolute heading in degrees
; OUT:    None.
;
;    Registers affected after return:
;         AFBCDEHL/IXIY  same
;         ......../....  different
;
.turnto             push af
                    push bc
                    push de
                    push hl

                    exx
                    ld   c,0
                    ld   hl,0
                    fpp(FP_ABS)              ; absolute heading always positive
                    ld   b,0
                    ld   de,0
                    exx
                    ld   de,360
                    exx
                    fpp(FP_MOD)              ; degrees always modululus 360...
                    exx
                    ld   (HEADING),hl        ; new heading in absolute degrees...
                    exx

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret

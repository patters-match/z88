
     xlib turn

     xref HEADING

     if z88
          include ":*//fpp.def"
     else
          include "fpp.def"
     endif


; ****************************************************************************
;
; Move turtle heading in relative degrees (+/-)
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; IN:     HL = relative heading in degrees (+/-)
; OUT:    None.
;
;    Registers affected after return:
;         AFBCDEHL/IXIY  same
;         ......../....  different
;
.turn               push af
                    push bc
                    push de
                    push hl

                    ld   de,360
                    ld   bc,(HEADING)        ; calculate relative heading direction
                    add  hl,bc
                    exx
                    ld   bc,0
                    ld   hl,0
                    ld   de,0
                    fpp(FP_MOD)              ; heading modulus 360
                    exx
                    ld   (HEADING),hl        ; new heading in absolute degrees...

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret





     xlib randomize

     xref SEED

if z88
     include ":*//fpp.def"
else
     include "fpp.def"
endif


; *****************************************************************
;
; Initiate randomize sequense
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; IN:  BC = seed
; OUT: None.
;
; If <seed> is 0, then a seed is created from the Z88 clock.
;
; Registers changed after return:
;   AF..DEHL/IXIY same
;   ..BC..../.... different
;
.Randomize          push af
                    ld   a,b
                    or   c
                    jr   z, get_seed
                    ld   (SEED),bc
                    pop  af
                    ret
.get_seed           ld   c,$d0
                    in   a,(c)               ; low byte of seed is 1/1000 sec.
                    inc  c
                    in   b,(c)               ; high byte of seed is 1/60 min.
                    ld   c,a
                    ld   (SEED),bc           ; new seed
                    pop  af
                    ret

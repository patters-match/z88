
     xlib rnd

     xref seed

     if z88
          include ":*//fpp.def"
     else
          include "fpp.def"
     endif


; *****************************************************************
;
; Get a random number [0; 1]. Algorithm based on ZX SPECTRUM code!
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; IN:  None.
; OUT: HLhlC = random number
;
; Registers changed after return:
;   AF....../IXIY ........ same
;   ..BCDEHL/.... afbcdehl different
;
.rnd                push af
                    ld   bc,0
                    ld   de,0
                    ld   hl,0
                    exx
                    ld   hl,(SEED)
                    inc  hl                                 ; SEED+1
                    ld   de,75
                    exx
                    fpp(FP_MUL)                             ; (SEED+1)*75
                    ld   b,0
                    ld   de,1
                    exx
                    ld   de,1                               ; DEdeB = 65537
                    exx
                    fpp(FP_MOD)                             ; ((SEED+1)*75) MOD 65537
                    exx
                    dec  hl
                    ld   (SEED),hl                          ; SEED = (((SEED+1)*75) MOD 65537)-1
                    ld   de,0
                    exx                                     ; HLhlC = SEED
                    ld   b,0
                    ld   de,1                               ; DEdeB = 65536
                    fpp(FP_DIV)
                    pop  af                                 ; HLhlC = SEED/65536
                    ret

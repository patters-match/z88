; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0da5
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc3

        org     $cda5                           ; 11 bytes

        include "sysvar.def"

xdef    Delay300Kclocks

;       ----

;       delay ~300 000 clock cycles

.Delay300Kclocks
        ld      hl, 10000                       ; 10 000*30 cycles
        ld      b, $ff
.dlay_1
        ld      c, $ff                          ; 7+11+12 cycles
        add     hl, bc
        jr      c, dlay_1
        ret

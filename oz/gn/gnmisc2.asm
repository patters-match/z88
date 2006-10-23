; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $cb72
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNMisc2

        org $cb72                               ; 35 bytes

        include "sysvar.def"

;       ----

xdef    NormalizeCDEcsec

;       ----

;       used by GNAlp

;IN:    CDE=centiseconds
;OUT:   CDE=normalized csec, Fc=1 if CDE(in)>24h

;       8640 000 is centiseconds / day

.NormalizeCDEcsec
        push    hl

        ld      a, c
        cp      8640000/65536                   ; CDE < 8640 000? Fc=0
        jr      c, n2
        jr      nz, n1

        ex      de, hl
        ld      de, 8640000%65536
        push    hl
        sbc     hl, de
        pop     hl
        ex      de, hl
        jr      c, n2
.n1
        ld      hl, 8640000%65536               ; CDE -= 8640 000, Fc=1
        ld      a, c
        or      a
        ex      de, hl
        sbc     hl, de
        sbc     a, 8640000/65536
        ld      c, a
        ex      de, hl

        or      a
.n2
        ccf
        pop     hl
        ret

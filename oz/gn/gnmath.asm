; -----------------------------------------------------------------------------
; Bank 3 @ S3
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNMath

        include "error.def"
        include "sysvar.def"

;       ----

xdef    GND16
xdef    GNM16
xdef    GNM24
xdef    GND24

;       ----

xref    Divu16
xref    Divu24
xref    GN_ret1c
xref    Mulu16
xref    Mulu24
xref    PutOsf_BHL
xref    PutOsf_DE
xref    PutOsf_HL

;       ----

;       16-bit unsigned multiplication
;
;IN:    HL=multiplicant, DE=multiplier
;OUT    HL=product
;
;CHG:   .F....HL/....
;
;       !! could return Fc=1 if overflow

.GNM16
        call    Mulu16
        call    PutOsf_HL
        ret

;       ----

;       16-bit unsigned division
;
;IN:    HL=divident, DE=divisor
;OUT    HL=quotient, DE=remainder
;       Fc=1, A=error if divide by zero
;
;CHG:   AF..DEHL/....

.GND16
        call    Divu16
        jr      nc, gnd16_1
        set     Z80F_B_C, (iy+OSFrame_F)
        ld      (iy+OSFrame_A), RC_Fail
        jr      gnd16_2                         ; !! 'ret'
.gnd16_1
        call    PutOsf_HL
        call    PutOsf_DE
.gnd16_2
        ret

;       ----

;        24bit unsigned multiplication
;
;IN:    BHL=multiplicant, CDE=multiplier
;OUT    BHL=product
;
;CHG:   .FB...HL/....
;
;       !! could return Fc=1 if overflow

.GNM24
        call    Mulu24
        call    PutOsf_BHL
        ret

;       ----

;       24-bit unsigned division
;
;IN:    BHL=divident, CDE=divisor
;OUT    BHL=quotient, CDE=remainder
;       Fc=1, A=error if divide by zero
;
;CHG:   AFBCDEHL/....

.GND24
        call    Divu24
        jp      GN_ret1c

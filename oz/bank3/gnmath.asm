; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $e841
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNMath

        org $e841                               ; 42 bytes

        include "all.def"
        include "sysvar.def"

defc    GN_ret1c                =$C0DD
defc    Divu16                  =$EDE7
defc    Divu24                  =$EE12
defc    Mulu16                  =$EE9A
defc    Mulu24                  =$EEE8
defc    PutOsf_DE               =$EF79
defc    PutOsf_BHL              =$EF80
defc    PutOsf_HL               =$EF83

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

; **************************************************************************************************
; Floating Point Package (addressed for segment 3).
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module FPP


        include "blink.def"
        include "error.def"
        include "oz.def"

        include "../os/lowram/lowram.def"

        org     FPPCALLTBL

        cp      a                               ; Fc=0 Fz=1
.FPret
        dec     iy
        dec     iy
        ld      sp, iy
        pop     ix
        pop     iy
        ex      af, af'
        jp      FPP_RET

;       ----

.FPError
        cp      0
        scf
        jr      FPret

        defb    0,0,0,0,0,0,0,0,0,0,0,0,0

.FuncTbl
        jp      FPAnd
        jp      FPIdv
        jp      FPEor
        jp      FPMod
        jp      FPOr
        jp      FPLeq
        jp      FPNeq
        jp      FPGeq
        jp      FPLt
        jp      FPEq
        jp      FPMul
        jp      FPAdd
        jp      FPGt
        jp      FPSub
        jp      FPPwr
        jp      FPDiv
        jp      FPAbs
        jp      FPAcs
        jp      FPAsn
        jp      FPAtn
        jp      FPCos
        jp      FPDeg
        jp      FPExp
        jp      FPInt
        jp      FPLn
        jp      FPLog
        jp      FPNot
        jp      FPRad
        jp      FPSgn
        jp      FPSin
        jp      FPSqr
        jp      FPTan
        jp      FPZer
        jp      FPOne
        jp      FPTru
        jp      FPPi
        jp      FPVal
        jp      FPStr
        jp      FPFix
        jp      FPFlt
        jp      FPTst
        jp      FPCmp
        jp      FPNeg
        jp      FPBas

;       ----

.FPBas
        push    hl
        ld      l, a
        add     a, a
        add     a, l                            ; A= 3*L
        add     a, <FuncTbl                     ; !! 'ld hl, FuncTbl; add a,l; ld l,a'
        ld      l, a
        ld      h, >FuncTbl
        ex      (sp), hl                        ; return to function
        ret

;       ----

.FPAnd
        ld      a, b                            ; !! put this code sequence
        or      c                               ; !! into subroutine
        jr      z, and_1
        call    FltBoth
        call    FixBoth

.and_1
        ld      a, h                            ; HLhl &= DEde
        and     d
        ld      h, a
        ld      a, l
        and     e
        ld      l, a
        exx
        ld      a, h
        and     d
        ld      h, a
        ld      a, l
        and     e
        ld      l, a
        exx
        ret

;       ----

.FPEor
        ld      a, b
        or      c
        jr      z, eor_1
        call    FltBoth
        call    FixBoth

.eor_1
        ld      a, h                            ; HLhl ^= DEde
        xor     d
        ld      h, a
        ld      a, l
        xor     e
        ld      l, a
        exx
        ld      a, h
        xor     d
        ld      h, a
        ld      a, l
        xor     e
        ld      l, a
        exx
        ret

;       ----

.FPOr
        ld      a, b
        or      c
        jr      z, or_1
        call    FltBoth
        call    FixBoth

.or_1
        ld      a, h                            ; HLhl |= DEde
        or      d
        ld      h, a
        ld      a, l
        or      e
        ld      l, a
        exx
        ld      a, h
        or      d
        ld      h, a
        ld      a, l
        or      e
        ld      l, a
        exx
        ret

;       ----

;       HLhlC=MOD(HLhlC,DEdeB)

.FPMod
        ld      a, b
        or      c
        jr      z, mod_1
        call    FltBoth
        call    FixBoth

.mod_1
        ld      a, h
        xor     d                               ; Fs=1 if signs differ
        bit     7, h                            ; Fz=1 if HLhl positive
        ex      af, af'
        bit     7, h
        call    nz, NegHLhl0                    ; make divident positive
        call    ExHLhlC_DEdeB
        bit     7, h
        call    nz, NegHLhl0                    ; make divisor positive

        ld      b, h                            ; BCbc=divisor, HLhl=0
        ld      c, l
        ld      hl, 0
        exx
        ld      b, h
        ld      c, l
        ld      hl, 0
        ld      a, $100-33
        call    Division
        exx
        ld      c, 0
        ex      af, af'
        ret     z                               ; HLhl(in) was positive
        jp      NegHLhl0                        ; else negate it

;       ----

;               HLhlC=Fix(HLhlC/DEdeB)

.FPIdv
        ld      a, b
        or      c
        jr      z, idv_1
        call    FltBoth
        call    FixBoth

.idv_1
        call    mod_1
        or      a
        call    ExHLhlC_DEdeB
        ld      c, 0
        ret     p
        jp      NegHLhl0

;       ----

.FPSub
        ld      a, b
        or      c
        jr      nz, sub_1

        call    SubHLhl_DEde                    ; try integer substraction,
        ret     po                              ; return if no overflow

        call    AddHLhl_DEde                    ; else restore HLhl

.sub_1
        call    FltBoth

.sub_2
        ld      a, d                            ; negate DEde and add
        xor     $80
        ld      d, a
        jr      add_2

.sub_3
        ld      a, h                            ; negate HLhl and add
        xor     $80
        ld      h, a
        jr      add_2

;       ----

.FPAdd
        ld      a, b
        or      c
        jr      nz, add_1

        call    AddHLhl_DEde                    ; try integer addition,
        ret     po                              ; return if no overflow

        call    SubHLhl_DEde                    ; else restore HLhl

.add_1
        call    FltBoth

.add_2
        dec     b
        inc     b
        ret     z                               ; DEdeB=0
        dec     c
        inc     c
        jp      z, ExHLhlC_DEdeB                ; HLhlC=0

        exx
        ld      bc, 0                           ; clear extra bits
        exx
        ld      a, h
        xor     d
        push    af                              ; sign difference in Fs

        ld      a, b                            ; make sure HLhlC has smaller exponent
        cp      c
        call    c, ExHLhlC_DEdeB
        ld      a, b
        set     7, h                            ; set missing bit
        call    nz, Fix                         ; match exponents

        pop     af
        ld      a, d                            ; remember D sign
        set     7, d                            ; set missing bit

        jp      m, add_3                        ; original signs different

        call    AddHLhl_DEde                    ; add them
        call    c, SrlHLhl                      ; fix mantissa if overflow
        set     7, h                            ; set missing bit
        jr      add_4

.add_3
        call    SubHLhl_DEde                    ; sub them
        call    c, NegHLhl                      ; negate mantissa if overflow
        call    NormalizeHLhlC                  ; normalize mantissa
        cpl                                     ; swap sign to match original H

.add_4
        exx                                     ; if bc>$8000 increment HLhl
        ex      de, hl
        ld      hl, $8000
        or      a
        sbc     hl, bc
        ex      de, hl
        exx
        call    z, HalfIncHLhl
        call    c, IncHLhl
        call    c, IncC

        res     7, h                            ; prepare for positive
        dec     c
        inc     c
        jp      z, FPZer                        ; it's zero
        or      a
        ret     p
        set     7, h                            ; make it negative
        ret

;       ----

.FPDiv
        call    FltBoth

.div_1
        dec     b                               ; Division by zero if DEdeB=0
        inc     b
        ld      a, RC_Dvz
        jp      z, FPError

        dec     c
        inc     c
        ret     z                               ; 0 if HLhlC=0

        ld      a, h                            ; save sign
        xor     d
        ex      af, af'

        set     7, d                            ; insert missing bits
        set     7, h
        push    bc
        ld      b, d                            ; BC=DE, DE=0
        ld      c, e
        ld      de, 0
        exx
        ld      b, d                            ; bc=de, de=0
        ld      c, e
        ld      de, 0

        ld      a, $100-32
        call    Division
        exx
        bit     7, d                            ; D
        exx
        call    z, loc_0_E3FB
        ex      de, hl
        exx
        srl     b
        rr      c
        or      a
        sbc     hl, bc
        ccf
        ex      de, hl
        call    z, HalfIncHLhl
        call    c, IncHLhl
        pop     bc
        call    c, IncC
        rra
        ld      a, c
        sbc     a, b
        ccf
        jp      mul_2

.div_2
        ld      a, h                            ; save sign
        xor     d
        ex      af, af'

        bit     7, h
        call    nz, NegHLhl0                    ; make HLhl positive
        call    ExHLhlC_DEdeB
        bit     7, h
        call    nz, NegHLhl0                    ; make DLdl positive

        ld      b, h                            ; BCbc = HLhl, HLhl = 0
        ld      c, l
        ld      hl, 0
        exx
        ld      b, h
        ld      c, l
        ld      hl, 0

        ld      a, $100-33
        call    sub_0_E40E
        exx
        ld      c, $100-65
        call    TstHLhl
        jr      nz, div_3                       ; normalize HLhl, adjust DEdeC
        bit     7, d
        jr      nz, div_3
        call    ExHLhlC_DEdeB
        ld      c, d
        ex      af, af'
        ret     p
        jp      NegHLhl0

.div_3
        dec     c                               ; adjust DEdeC
        exx
        sla     e
        rl      d
        exx
        rl      e
        rl      d

        exx                                     ; HLhl = 2*HLhl +1
        adc     hl, hl
        exx
        adc     hl, hl
        jp      p, div_3                        ; high bit not set, do again

        ex      af, af'                         ; return with correct sign
        ret     m
        res     7, h
        ret

;       ----

.FPMul
        ld      a, b
        or      c
        jp      z, div_2
        call    FltBoth

.mul_1
        dec     b
        inc     b
        jp      z, FPZer                        ; DEdeB=0, zero

        dec     c
        inc     c
        ret     z                               ; HLhlC=0, zero

        ld      a, h                            ; sign
        xor     d
        ex      af, af'

        set     7, d                            ; insert midding bits
        set     7, h
        push    bc

        ld      b, h                            ; BCbc=HLhl, HLhl=0
        ld      c, l
        ld      hl, 0
        exx
        ld      b, h
        ld      c, l
        ld      hl, 0

        ld      a, $100-32
        call    sub_0_E40E
        call    c, sub_0_E422

        exx                                     ; cp $8000, DE
        push    hl
        ld      hl, $8000
        or      a
        sbc     hl, de
        pop     hl

        call    z, HalfIncHLhl
        call    c, IncHLhl
        pop     bc
        call    c, IncC
        rra
        ld      a, c
        adc     a, b
.mul_2
        jr      c, mul_3
        jp      p, FPZer
        jr      mul_4

.mul_3
        jp      m, ErrTooBig

.mul_4
        add     a, $80
        ld      c, a
        jp      z, FPZer
        ex      af, af'
        res     7, h
        ret     p
        set     7, h
        ret

;       ----

.FPPwr
        ld      a, b
        or      c
        jr      z, pwr_1

        call    FltBoth
        jp      pwr_9

.pwr_1
        call    ExHLhlC_DEdeB
        bit     7, h
        push    af
        call    nz, NegHLhl0

.pwr_2
        ld      c, b
        ld      b, 32

.pwr_3
        call    HLhl_x2
        jr      c, pwr_4
        djnz    pwr_3

        pop     af
        exx
        inc     l
        exx
        ld      c, h
        ret

.pwr_4
        pop     af
        push    bc
        ex      de, hl
        push    hl
        exx
        ex      de, hl
        push    hl
        exx
        ld      ix, 0
        add     ix, sp
        jr      z, pwr_7
        push    bc
        exx
        push    de
        exx
        push    de
        call    FPFlt
        call    sub_0_DDF8
        ld      (ix+4), c                       ; (IX)=HLhlC
        exx
        ld      (ix+0), l
        ld      (ix+1), h
        exx
        ld      (ix+2), l
        ld      (ix+3), h
        jr      pwr_6

.pwr_5
        push    bc
        exx
        sla     e
        rl      d
        push    de
        exx
        rl      e
        rl      d
        push    de
        push    af
        call    LdDEdeB_HLhlC
        call    FPMul
        pop     af
        call    LdDEdeB_IX
        call    c, FPMul

.pwr_6
        pop     de
        exx
        pop     de
        exx
        ld      a, c
        pop     bc
        ld      c, a

.pwr_7
        djnz    pwr_5
        pop     af
        pop     af
        pop     af
        ret

.pwr_8
        pop     af
        pop     af
        pop     af
        jr      pwr_2

.pwr_9
        bit     7, d
        push    af
        call    ExHLhlC_DEdeB
        call    PushHLhlC
        dec     c
        inc     c
        jr      z, pwr_8
        ld      a, $80+30
        cp      c
        jr      c, pwr_10
        inc     a
        call    Fix
        ex      af, af'
        jp      p, pwr_8

.pwr_10
        call    ExHLhlC_DEdeB
        call    sub_0_DE0F
        call    PopDEdeB
        pop     af
        call    mul_1
        jp      loc_0_DD84

;       ----

.FPLt
        ld      a, b
        or      c
        jr      z, Lt_1

        call    FltBoth
        call    SFcp_False
        jr      Lt_2

.Lt_1
        call    SIcp_False

.Lt_2
        ret     nc
        jr      FPTru

;       ----

.FPGt
        ld      a, b
        or      c
        jr      z, Gt_1

        call    FltBoth
        call    SFcp_False
        jr      Gt_2

.Gt_1
        call    SIcp_False

.Gt_2
        ret     z
        ret     c
        jr      FPTru

;       ----

.FPGeq
        ld      a, b
        or      c
        jr      z, Geq_1

        call    FltBoth
        call    SFcp_False
        jr      Geq_2

.Geq_1
        call    SIcp_False

.Geq_2
        ret     c
        jr      FPTru

;       ----

.FPLeq
        ld      a, b
        or      c
        jr      z, Leq_1

        call    FltBoth
        call    SFcp_False
        jr      Leq_2

.Leq_1
        call    SIcp_False

.Leq_2
        jr      z, FPTru
        ret     nc
        jr      FPTru

;       ----

.FPNeq
        ld      a, b
        or      c
        jr      z, Neq_1

        call    FltBoth
        call    SFcp_False
        jr      Neq_2

.Neq_1
        call    SIcp_False

.Neq_2
        ret     z
        jr      FPTru

;       ----

.FPEq
        ld      a, b
        or      c
        jr      z, Eq_1

        call    FltBoth
        call    SFcp_False
        jr      Eq_2

.Eq_1
        call    SIcp_False

.Eq_2
        ret     nz

;       ----

.FPTru
        ld      hl, $FFFF
        exx
        ld      hl, $FFFF
        exx
        xor     a
        ld      c, a
        ret

;       ----

.FPNeg
        dec     c
        inc     c
        jp      z, NegHLhl0
        ld      a, h
        xor     $80
        ld      h, a
        ret

;       ----

.FPAbs
        bit     7, h
        ret     z
        dec     c
        inc     c
        jp      z, NegHLhl0
        res     7, h
        ret

;       ----

.FPNot
        call    FPFix
        ld      a, h                            ; HLhl = !HLhl
        cpl
        ld      h, a
        ld      a, l
        cpl
        ld      l, a
        exx
        ld      a, h
        cpl
        ld      h, a
        ld      a, l
        cpl
        ld      l, a
        exx
        xor     a
        ret

;       ----

;       return PI, 490FDAA2.81

.FPPi
        ld      hl, $490F
        exx
        ld      hl, $DAA2
        exx
        ld      c, $81
        xor     a
        ret
;       ----
.FPDeg
        call    loc_0_DC15
        call    mul_1
        xor     a
        ret
;       ----
.FPRad
        call    loc_0_DC15
        call    div_1
        xor     a
        ret
;       ----
;
;               180/PI

.loc_0_DC15
        call    FPFlt
        ld      de, $652E
        exx
        ld      de, $E0D3
        exx
        ld      b, $85
        ret
;       ----
.FPSgn
        call    TstHLhl
        or      c
        ret     z
        bit     7, h
        jp      nz, FPTru
        call    FPZer
        jp      IncHLhl
;       ----
.FPVal
        push    hl
        pop     ix
        call    GetNumStart
        push    af
        call    sub_0_E0DE
        pop     af
        cp      '-'
        ld      a, 0
        jr      nz, val_2
        dec     c
        inc     c
        jr      z, val_1
        ld      a, h
        xor     $80
        ld      h, a
        xor     a
        jr      val_2

.val_1
        call    NegHLhl0

.val_2
        push    ix
        pop     de
        ret
;       ----
.FPInt
        dec     c
        inc     c
        ret     z
        ld      a, $80+31
        ld      b, h
        call    Fix
        ex      af, af'
        and     b
        call    m, IncHLhl
        ld      a, b
        or      a
        call    m, NegHLhl0
        xor     a
        ld      c, a
        ret
;       ----
.FPSqr
        call    FPFlt

.sqr_1
        bit     7, h                            ; Negative root, error
        ld      a, RC_Nvr
        jp      nz, FPError

        dec     c                               ; Sqr(0), exit
        inc     c
        ret     z

        set     7, h
        bit     0, c
        call    z, SrlHLhl
        ld      a, c
        sub     $80
        sra     a
        add     a, $80
        ld      c, a
        push    bc
        ex      de, hl
        ld      hl, 0
        ld      b, h
        ld      c, l
        exx
        ex      de, hl
        ld      hl, 0
        ld      b, h
        ld      c, l
        ld      a, $100-31
        call    sub_0_E441
        exx
        bit     7, b
        exx
        call    z, sub_0_E441
        call    sub_0_E47A
        or      a
        call    loc_0_E3FB
        rr      e
        ld      h, b
        ld      l, c
        exx
        ld      h, b
        ld      l, c
        call    c, IncHLhl
        pop     bc
        call    c, IncC
        rra
        sbc     a, a
        add     a, c
        ld      c, a
        res     7, h
        xor     a
        ret

;       ----

.FPTan
        call    FPFlt
        call    PushHLhlC
        call    cos_1
        call    PopDEdeB
        call    PushHLhlC
        call    ExHLhlC_DEdeB
        call    sin_1
        call    PopDEdeB
        call    div_1
        xor     a
        ret

;       ----

.FPCos
        call    FPFlt

.cos_1
        call    sub_0_E1DA
        inc     e
        inc     e
        ld      a, e
        jr      loc_0_DCF5
;       ----
.FPSin
        call    FPFlt

.sin_1
        push    hl
        call    sub_0_E1DA
        pop     af
        rlca
        rlca

;       ----
.sub_0_DCF1
        rlca
        and     4
        xor     e
.loc_0_DCF5
        push    af
        res     7, h
        rra
        call    loc_0_DD76
        call    c, sub_3
        pop     af
        push    af
        and     3
        jp      po, loc_0_DD34
        call    PushHLhlC
        call    sub_0_E344
        call    sub_0_E37D

        defb    $B7,$A8,$11,$36,$6D             ;-2.7366953E-06         -1/365404.21667616
        defb    $26,$DE,$05,$D0,$73             ; 0.00015913704          1/6283.8923480438
        defb    $C0,$80,$88,$08,$79             ;-0.011749394           -1/85.110770797545
        defb    $9D,$AA,$AA,$AA,$7D             ;-0.15397135            -1/6.4947146139275
        defb     0 , 0 , 0 , 0 ,$80;            ; 1.0000

        call    PopDEdeB
        call    PopDEdeB
        call    mul_1
        jp      loc_0_DD56
;       ----
.loc_0_DD34
        call    sub_0_E344
        call    sub_0_E37D
;       ----
        defb    $71,$D5,$78,$4C,$70             ; 2.8828843E-05          1/34687.482504451
        defb    $AF,$94,$03,$B6,$76             ;-0.0013395552          -1/746.51644671521
        defb    $C8,$9C,$AA,$2A,$7B             ;-0.048977532           -1/20.417525343048
        defb    $DD,$FF,$FF,$FF,$7E             ;-0.43359375            -1/2.3063063162138
        defb     0 , 0 , 0 , 0 ,$80             ; 1.000
;       ----
        call    PopDEdeB
.loc_0_DD56
        pop     af
        and     4
        ret     z
        dec     c
        inc     c
        ret     z
        set     7, h
        ret
; End of function sub_0_DCF1
;       ----

;       HLhlC=1.0

.FPOne
        ld      hl, 0
        exx
        ld      hl, 0
        exx
        ld      c, $80
        ret

;       ----
.LdDEdeB_1
        ld      de, 0
        exx
        ld      de, 0
        exx
        ld      b, $80
        ret
; End of function LdDEdeB_1
;       ----

;       .7853981629014 1/1.2732395455393


.loc_0_DD76
        ld      de, $490F
        exx
        ld      de, $DAA2
        exx
        ld      b, $7F
        ret
;       ----
.FPExp
        call    FPFlt
.loc_0_DD84
        call    sub_0_DE01
        exx
        dec     e
        ld      bc, $D1CF
        exx
        push    hl
        call    sub_0_E1EA
        pop     af
        bit     7, e
        jr      z, loc_0_DD9F
        rla
        jp      c, FPZer
        ld      a, RC_Exr                       ; Exponent function range
        jp      FPError
;       ----
.loc_0_DD9F
        and     $80
        or      e
        push    af
        res     7, h
        call    PushHLhlC
        call    sub_0_E37D

        defb    $72,$40,$2E,$94,$73             ; .00023102828072297     1/4328.4744052575
        defb    $65,$6F,$4F,$2E,$76             ; .0017504486168036      1/571.28212185173
        defb    $37,$6D,$02,$88,$79             ; .011195423547179       1/89.322212400979
        defb    $12,$E5,$A0,$2A,$7B             ; .035863519180566       1/27.883487812927
        defb    $14,$4F,$AA,$AA,$7D             ; .14483515359461        1/6.9044011428258
        defb    $56,$FD,$FF,$7F,$7E             ; .41990659944713        1/2.3814819803181
        defb    $FE,$FF,$FF,$FF,$7F             ;-.99609374627471       -1/1.003921572382
        defb     0 , 0 , 0 , 0 ,$80

        call    PopDEdeB
        pop     af
        push    af
        call    p, sub_0_DDF8
        pop     af
        jp      p, loc_0_DDE3
        and     $7F
        neg
.loc_0_DDE3
        add     a, $80
        add     a, c
        jr      c, loc_0_DDED
        jp      p, FPZer
        jr      loc_0_DDF0
;       ----
.loc_0_DDED
        jp      m, ErrTooBig
.loc_0_DDF0
        add     a, $80
        jp      z, FPZer
        ld      c, a
        xor     a
        ret
;       ----

.sub_0_DDF8
        call    LdDEdeB_1
.loc_0_DDFB
        call    ExHLhlC_DEdeB
        jp      div_1

;       ----

.sub_0_DE01
        ld      de, $3172
        exx
        ld      de, $17F8
        exx
        ld      b, $7F
        ret
; End of function sub_0_DE01
;       ----
.FPLn
        call    FPFlt

;       ----
.sub_0_DE0F
        ld      a, RC_Lgr                       ; Log range
        bit     7, h
        jp      nz, FPError
        inc     c
        dec     c
        jp      z, FPError

        ld      de, $3504
        exx
        ld      de, $F333
        exx
        call    Icp
        ld      a, c
        ld      c, $80
        jr      c, loc_0_DE2D
        dec     c
        inc     a

.loc_0_DE2D
        push    af
        call    sub_0_E35F
        call    PushHLhlC
        call    sub_0_E344

.loc_0_DE37
        call    sub_0_E37D

        defb    $48,$CC,$FB,$74,$7D             ; .19609444495291        1/5.0995835207885
        defb    $AF,$AE,$FF,$11,$7E             ; .34313199110329        1/2.9143304207359
        defb    $8C,$D9,$CD,$4C,$7E             ;-.27509919553995       -1/3.6350524327679
        defb    $E3,$A9,$AA,$2A,$7F             ;-.88930762559175       -1/1.1244702858975
        defb     0 , 0 , 0 , 0 ,$81             ;2.0

        call    PopDEdeB
        call    PopDEdeB
        call    mul_1
        pop     af
        call    PushHLhlC
        ex      af, af'
        call    FPZer
        ex      af, af'
        sub     $80
        jr      z, loc_0_DE84
        jr      nc, loc_0_DE6D
        cpl
        inc     a
.loc_0_DE6D
        ld      h, a
        ld      c, $80+7
        push    af
        call    Normalize0HLhlC
        res     7, h
        call    sub_0_DE01
        call    mul_1
        pop     af
        jr      nc, loc_0_DE84
        jp      m, loc_0_DE84
        set     7, h

.loc_0_DE84
        call    PopDEdeB
        call    add_2
        xor     a
        ret
; End of function sub_0_DE0F
;       ----
.FPLog
        call    FPLn
        ld      de, $5E5B
        exx
        ld      de, $D8A9
        exx
        ld      b, $7E
        call    mul_1
        xor     a
        ret
;       ----
.FPAsn
        call    FPFlt
        call    PushHLhlC
        call    LdDEdeB_HLhlC
        call    mul_1
        call    LdDEdeB_1
        call    sub_3
        call    sqr_1
        call    PopDEdeB
        inc     c
        dec     c
        ld      a, 2
        push    de
        jr      z, loc_0_DF2D
        pop     de
        call    loc_0_DDFB
        jr      loc_0_DEC6
;       ----
.FPAtn
        call    FPFlt
.loc_0_DEC6
        push    hl
        res     7, h
        ld      de, $5413
        exx
        ld      de, $CCD0
        exx
        ld      b, $7E
        call    Fcp
        ld      b, 0
        jr      c, loc_0_DEF6
        ld      de, $1A82
        exx
        ld      de, $799A
        exx
        ld      b, $81
        call    Fcp
        jr      c, loc_0_DEF1
        call    sub_0_DDF8
        ld      b, 2
        jp      loc_0_DEF6
;       ----
.loc_0_DEF1
        call    sub_0_E35F
        ld      b, 1
.loc_0_DEF6
        push    bc
        call    PushHLhlC
        call    sub_0_E344
        call    sub_0_E37D

        defb    $35,$F3,$D8,$37,$7B             ; .044422001345083     1/22.511367559325
        defb    $91,$6B,$B9,$AA,$7C             ;-.071006250567734     1/14.083267205414
        defb    $DE,$41,$97,$61,$7C             ;-.10852354299277     1/9.2145904236338
        defb    $7B,$9D,$37,$92,$7D             ; .24571692291647     1/4.0697237623309
        defb    $5A,$2A,$CC,$4C,$7D             ; .21305388584733     1/4.693648257214
        defb    $5C,$A9,$AA,$AA,$7E             ; .43098195269704     1/2.3202827722648
        defb     0 , 0 , 0 , 0 ,$80


        call    PopDEdeB
        call    PopDEdeB
        call    mul_1
        pop     af
.loc_0_DF2D
        call    loc_0_DD76
        rra
        push    af
        call    c, add_2
        pop     af
        inc     b
        rra
.loc_0_DF38
        call    c, sub_3
        pop     af
        or      a
        ret     p
        set     7, h
        xor     a
        ret
; End of function FPAsn
;       ----
.FPAcs
        call    FPAsn
        ld      a, 2
        push    af
        jr      loc_0_DF2D
;       ----
.FPStr
        exx
        push    de
        exx
        ld      ix, 0
        add     ix, sp
        call    FPFlt
        ld      b, 0
        bit     7, h
        jr      z, loc_0_DF66
        res     7, h
        ld      a, '-'
        ex      de, hl
        call    WriteByteHL
        ex      de, hl
        inc     de
.loc_0_DF66
        xor     a
        cp      c
        jr      z, loc_0_DFB1
        push    de
        ld      a, b
.loc_0_DF6C
        push    af
        ld      a, c
        cp      $A1
        jr      nc, loc_0_DF8C
        cp      $9B
        jr      nc, loc_0_DF9B
        cpl
        cp      $E1
        jr      c, loc_0_DF7D
        ld      a, $F8
.loc_0_DF7D
        add     a, $1C
        call    sub_0_E3A4
        push    af
        call    mul_1
        pop     af
        ld      b, a
        pop     af
        sub     b
        jr      loc_0_DF6C
;       ----
.loc_0_DF8C
        sub     $20
        call    sub_0_E3A4
        push    af
        call    div_1
        pop     af
        ld      b, a
        pop     af
        add     a, b
        jr      loc_0_DF6C
;       ----
.loc_0_DF9B
        ld      a, 9
        call    sub_0_E3A4
        call    Fcp
        ld      a, c
        pop     bc
        ld      c, a
        set     7, h
        call    c, sub_0_E301
        pop     de
        res     7, c
        ld      a, 0
        rla
.loc_0_DFB1
        inc     c
        ex      af, af'
        ld      a, b
        bit     1, (ix+1)
        jr      nz, loc_0_DFC2
        xor     a
        cp      (ix+0)
        jr      z, loc_0_DFCA
        ld      a, $F6
.loc_0_DFC2
        add     a, (ix+0)
        or      a
        jp      m, loc_0_DFCA
        xor     a
.loc_0_DFCA
        push    af
        ex      af, af'
.loc_0_DFCC
        call    HLhl_x2
        adc     a, a
        cp      $0A
        jr      c, loc_0_DFD9
        sub     $0A
        exx
        inc     l
        exx
.loc_0_DFD9
        dec     c
        jr      nz, loc_0_DFCC
        ld      c, a
        ld      a, h
        and     $3F
        ld      h, a
        pop     af
        jp      p, loc_0_DFEF
        inc     a
        jr      nz, loc_0_E004
        ld      a, 4
        cp      c
        ld      a, 0
        jr      loc_0_E004
;       ----
.loc_0_DFEF
        push    af
        ld      a, c
        adc     a, $30
        cp      '0'
        jr      z, loc_0_DFFC
        cp      ':'
        ccf
        jr      nc, loc_0_E004
.loc_0_DFFC
        ex      (sp), hl
        bit     6, l
        ex      (sp), hl
        jr      nz, loc_0_E007
        ld      a, '0'
.loc_0_E004
        inc     a
        dec     a
        push    af
.loc_0_E007
        inc     b
        call    TstHLhl
        ld      c, $20
        ld      a, 0
        jr      nz, loc_0_DFCC
        pop     af
        push    af
        ld      a, 0
        jr      c, loc_0_DFCC
        ex      de, hl
        ld      c, $FF
        ld      d, 1
        ld      e, (ix+0)
        bit     0, (ix+1)
        jr      nz, loc_0_E057
        bit     1, (ix+1)
        jr      z, loc_0_E03C
        ld      a, b
        or      a
        jr      z, loc_0_E033
        jp      m, loc_0_E033
        ld      d, b
.loc_0_E033
        ld      a, d
        add     a, (ix+0)
        ld      e, a
        cp      $0B
        jr      c, loc_0_E053
.loc_0_E03C
        ld      a, b
        ld      de, $101
        or      a
        jp      m, loc_0_E057
        jr      z, loc_0_E053
        ld      a, (ix+0)
        or      a
        jr      nz, loc_0_E04E
        ld      a, $0A
.loc_0_E04E
        cp      b
        jr      c, loc_0_E057
        ld      d, b
        ld      e, b
.loc_0_E053
        ld      a, b
        add     a, $81
        ld      c, a
.loc_0_E057
        set     7, d
        dec     e
.loc_0_E05A
        ld      a, d
        cp      c
        jr      nc, loc_0_E06A
.loc_0_E05E
        pop     af
        jr      z, loc_0_E064
        jp      p, loc_0_E06C
.loc_0_E064
        push    af
        inc     e
        dec     e
        jp      m, loc_0_E082
.loc_0_E06A
        ld      a, '0'
.loc_0_E06C
        dec     d
        jp      po, loc_0_E078
        push    af
        ld      a, '.'
        call    WriteByteHL
        pop     af
        inc     hl
.loc_0_E078
        call    WriteByteHL
        inc     hl
        dec     e
        jp      p, loc_0_E05A
        jr      loc_0_E05E
;       ----
.loc_0_E082
        pop     af
        inc     c
        ld      c, l
        jr      nz, loc_0_E0C0
        ld      a, 'E'
        call    WriteByteHL
        inc     hl
        ld      a, b
        dec     a
        jp      p, loc_0_E09C
        push    af
        ld      a, '-'
        call    WriteByteHL
        pop     af
        inc     hl
        neg
.loc_0_E09C
        ld      d, 0
        ld      e, '0'
        jr      z, loc_0_E0B3
        cp      $0A
        ld      b, a
        ld      a, ':'
        jr      c, loc_0_E0AA
        ld      d, e
.loc_0_E0AA
        inc     e
        cp      e
        jr      nz, loc_0_E0B1
        ld      e, '0'
        inc     d
.loc_0_E0B1
        djnz    loc_0_E0AA
.loc_0_E0B3
        ld      a, d
        or      a
        jr      z, loc_0_E0BB
        call    WriteByteHL
        inc     hl
.loc_0_E0BB
        ld      a, e
        call    WriteByteHL
        inc     hl
.loc_0_E0C0
        xor     a
        call    WriteByteHL
        ex      de, hl
        pop     hl
        ret
;       ----
.LdDEdeB_IX
        ld      b, (ix+4)
        exx
        ld      e, (ix+0)
        ld      d, (ix+1)
        exx
        ld      e, (ix+2)
        ld      d, (ix+3)
        ret
;       ----
.ErrBadNum
        ld      a, RC_Bdn                       ; Bad number
        jp      FPError
;       ----

.sub_0_E0DE
        call    FPZer
        ld      c, 0
        call    sub_0_E16B
        cp      '.'
        ld      b, 0
        call    z, sub_0_E169
        cp      '.'
        jr      z, ErrBadNum
        cp      'E'
        jr      z, loc_0_E0F7
        cp      'e'
.loc_0_E0F7
        ld      a, 0
        call    z, sub_0_E13A
        bit     7, h
        jr      nz, loc_0_E108
        or      a
        jr      nz, loc_0_E108
        cp      b
        jr      nz, loc_0_E108
        cp      c
        ret     z

.loc_0_E108
        sub     b
        add     a, c
        ld      c, $80+31
        call    Normalize0HLhlC
        res     7, h
        or      a
        ret     z
        jp      m, loc_0_E11E
        call    sub_0_E3A4
        call    mul_1
        xor     a
        ret
;       ----
.loc_0_E11E
        cp      $DA
        jr      c, loc_0_E12C
        neg
        call    sub_0_E3A4
        call    div_1
        xor     a
        ret
;       ----
.loc_0_E12C
        push    af
        ld      a, $26
        call    sub_0_E3A4
        call    div_1
        pop     af
        add     a, $26
        jr      loc_0_E11E

;       ----

.sub_0_E13A
        push    bc
        ld      b, a
        ld      c, 2
        inc     ix
        call    GetNumStart
        ex      af, af'

.loc_0_E144
        call    ReadNum
        jr      c, loc_0_E160
        ld      a, b
        add     a, a
        add     a, a
        add     a, b
        add     a, a
        ld      b, a                            ; B=10*B
        call    ReadByteIX                      ; !! could use number from ReadNum instead of this
        inc     ix
        and     $0F
        add     a, b
        ld      b, a
        dec     c
        jp      p, loc_0_E144
        ld      b, $64
        jr      loc_0_E144
;       ----
.loc_0_E160
        ex      af, af'
        cp      '-'
        ld      a, b
        pop     bc
        ret     nz
        neg
        ret
; End of function sub_0_E13A
;       ----
.sub_0_E169
        inc     ix
; End of function sub_0_E169
;       ----
.sub_0_E16B
        call    ReadNum
        ret     c
        inc     b
        inc     ix
        call    HLhl_x10
        jr      c, loc_0_E18A
        dec     c
        inc     c
        jr      nz, loc_0_E18A
        and     $0F
        exx
        ld      b, 0
        ld      c, a
        add     hl, bc
        exx
        jr      nc, sub_0_E16B
        inc     hl
        ld      a, h
        or      l
        jr      nz, sub_0_E16B

.loc_0_E18A
        inc     c
        call    ExHLhl_DEde
        jr      sub_0_E16B
; End of function sub_0_E16B
;       ----

;

.Fix
        ex      af, af'
        xor     a
        ex      af, af'
        set     7, h                            ; set missing top bit
.fix_1
        call    SrlHLhl                         ; /2 until exponent reached
        cp      c
        ret     z
        jp      nc, fix_1
        jp      ErrTooBig

;       ----
.FixBoth
        call    ExHLhlC_DEdeB
        call    FPFix
        call    ExHLhlC_DEdeB
;       ----
.FPFix
        dec     c
        inc     c
        ret     z                               ; already int

        bit     7, h                            ;remember sign
        push    af

        ld      a, $80+31
        call    Fix

        pop     af                              ; return with correct sign
        ld      c, 0
        ret     z

;       ----

.NegHLhl0
        or      a
        exx

.loc_0_E1BA
        push    de
        ex      de, hl
        ld      hl, 0
        sbc     hl, de
        pop     de
        exx
        push    de
        ex      de, hl
        ld      hl, 0
        sbc     hl, de
        pop     de
        ret

.NegHLhl
        exx
        cpl
        push    hl                              ; negate extra bits
        or      a
        ld      hl, 0
        sbc     hl, bc
        ld      b, h
        ld      c, l
        pop     hl
        jr      loc_0_E1BA
;       ----

.sub_0_E1DA
        ld      a, $80+22
        cp      c
        ld      a, RC_Acl                       ; Accuracy lost
        jp      c, FPError

        call    loc_0_DD76
        exx
        ld      bc, $2169
        exx

;       ----
.sub_0_E1EA
        set     7, d
        set     7, h
        ld      a, c
        ld      c, 0
        ld      ix, 0
        push    ix
        cp      b
        jr      c, E1EA_5

.E1EA_1
        exx
        ex      (sp), hl
        sbc     hl, bc
        ex      (sp), hl
        sbc     hl, de
        exx
        sbc     hl, de
        jr      nc, E1EA_2
        exx
        ex      (sp), hl
        add     hl, bc
        ex      (sp), hl
        adc     hl, de
        exx
        adc     hl, de

.E1EA_2
        ccf
        rl      c
        jr      nc, E1EA_3
        set     7, c

.E1EA_3
        dec     a
        cp      b
        jr      c, E1EA_4
        ex      (sp), hl
        add     hl, hl
        ex      (sp), hl
        exx
        adc     hl, hl
        exx
        adc     hl, hl
        jr      nc, E1EA_1
        or      a
        exx
        ex      (sp), hl
        sbc     hl, bc
        ex      (sp), hl
        sbc     hl, de
        exx
        sbc     hl, de
        or      a
        jr      E1EA_2

.E1EA_4
        inc     a

.E1EA_5
        ld      e, c
        ld      c, a
        exx
        pop     bc
        exx

;       ----

.NormalizeHLhlC
        bit     7, h
        ret     nz                              ; normalized
        exx
        sla     c                               ; shift in extra bits from bc
        rl      b
        adc     hl, hl
        exx
        adc     hl, hl
        dec     c
        jp      nz, NormalizeHLhlC
        ret                                     ; zero

.Normalize0HLhlC
        bit     7, h
        ret     nz                              ; normalized
        exx
        add     hl, hl                          ; no extra bits
        exx
        adc     hl, hl
        dec     c
        jp      nz, Normalize0HLhlC
        ret                                     ; zero
;       ----

.FltBoth
        call    ExHLhlC_DEdeB
        call    FPFlt
        call    ExHLhlC_DEdeB

.FPFlt
        dec     c
        inc     c
        ret     nz                              ; already float
        call    TstHLhl
        ret     z                               ; zero

        ld      a, h
        or      a
        call    m, NegHLhl0                     ; make it positive
        ld      c, $80+31
        call    Normalize0HLhlC                 ; and normalize

        or      a                               ; return with correct sign
        ret     m
        res     7, h
        ret
;       ----
.IncHLhl
        exx
        ld      bc, 1
        add     hl, bc
        exx
        ret     nc
        push    bc
        ld      bc, 1
        add     hl, bc
        pop     bc
        ret

;       ----

;       clear carry, set HLhl lowest bit

.HalfIncHLhl
        or      a
        exx
        set     0, l
        exx
        ret

;       ----
.ExHLhlC_DEdeB
        ld      a, c
        ld      c, b
        ld      b, a

.ExHLhl_DEde
        ex      de, hl
        exx
        ex      de, hl
        exx
        ret
;       ----
.SrlHLhl
        call    SrlHLhl0
        exx
        rr      b
        rr      c
        ex      af, af'
        or      b
        ex      af, af'
        exx
;       ----
.IncC
        inc     c
        ret     nz

.ErrTooBig
        ld      a, RC_Tbg                       ; Too big
        jp      FPError
;       ----
;       Test HLhlC for zero

.FPTst
        call    TstHLhl
        or      c
        ret     z
        ld      a, h
        and     $80                             ; get negative bit
        or      $40                             ; set positive bit
        ret
;       ----
.TstHLhl
        ld      a, h
        or      l
        exx
        or      h
        or      l
        exx
        ret

;       ----
.FPCmp
        ld      a, b
        or      c
        jr      nz, loc_0_E2C6
        call    SIcp

.loc_0_E2BF
        ld      a, 0
        ret     z
        ld      a, $80
        rra
        ret
;       ----
.loc_0_E2C6
        call    FltBoth
        call    SFcp
        jr      loc_0_E2BF
;       ----

;       signed integer compare, preload FALSE

.SIcp_False
        call    SIcp

;       HLhlC=0

.FPZer
        ld      a, 0
        exx
        ld      h, a
        ld      l, a
        exx
        ld      h, a
        ld      l, a
        ld      c, a
        ret

;       ----

;       signed float compare, preload FALSE

.SFcp_False
        call    SFcp
        jr      FPZer
;       ----

;       float compare

.Fcp
        ld      a, c
        cp      b
        ret     nz

;       integer compare

.Icp
        sbc     hl, de
        add     hl, de
        ret     nz
        exx
        sbc     hl, de
        add     hl, de
        exx
        ret

;       ----

;       signed float compare

.SFcp
        ld      a, h
        xor     d
        ld      a, h
        rla
        ret     m
        jr      nc, Fcp
        call    Fcp
        ccf
        ret
;       ----

;       signed integer compare

.SIcp
        ld      a, h
        xor     d
        jp      p, Icp                          ; same sign
        ld      a, h
        rla                                     ; sign into Fc
        ret
;       ----
.sub_0_E301
        dec     b
        inc     c
; End of function sub_0_E301
;       ----
.sub_0_E303
        call    LdDEde_HLhl
        call    SrlHLhlC0
        call    SrlHLhlC0
        ex      af, af'
;       ----

.AddHLhl_DEde
        exx
        add     hl, de
        exx
        adc     hl, de
        ret

.SubHLhl_DEde
        exx
        or      a
        sbc     hl, de
        exx
        sbc     hl, de
        ret

.HLhl_x10
        call    LdDEde_HLhl
        call    HLhl_x2
        ret     c
        call    HLhl_x2
        ret     c
        call    AddHLhl_DEde
        ret     c

.HLhl_x2
        exx
        add     hl, hl
        exx
        adc     hl, hl
        ret

;       increment exponent, /2 mantissa

.SrlHLhlC0
        inc     c
.SrlHLhl0
        srl     h
        rr      l
        exx
        rr      h
        rr      l
        exx
        ret

.LdDEdeB_HLhlC
        ld      b, c
.LdDEde_HLhl
        ld      d, h
        ld      e, l
        exx
        ld      d, h
        ld      e, l
        exx
        ret

;       ----
.sub_0_E344
        call    LdDEdeB_HLhlC
        call    mul_1

;       ----

.PushHLhlC
        pop     ix                              ; return address
        push    bc
        push    hl
        exx
        push    hl
        exx
        jp      (ix)                            ; return

.PopDEdeB
        pop     ix                              ; return address
        exx
        pop     de
        exx
        pop     de
        ld      a, c
        pop     bc
        ld      b, c
        ld      c, a
        jp      (ix)                            ; return

;       ----
.sub_0_E35F
        call    PushHLhlC
        call    LdDEdeB_1
        call    add_2
        call    PopDEdeB
        call    PushHLhlC
        call    ExHLhlC_DEdeB
        call    LdDEdeB_1
        call    sub_2
        call    PopDEdeB
        jp      div_1

;       ----
.sub_0_E37D
        ld      ix, 2
        add     ix, sp                          ; IX=table
        ex      (sp), ix
        call    LdDEdeB_IX

.loc_0_E388
        call    mul_1
        ld      de, 5                           ; IX+=FP_SIZE
        add     ix, de
        call    LdDEdeB_IX
        ex      (sp), ix
        inc     b
        dec     b
        jp      m, add_2                        ; HLhlB=1/2
        call    add_2
        call    LdDEdeB_IX
        ex      (sp), ix
        jr      loc_0_E388
;       ----
.sub_0_E3A4
        inc     a
        ex      af, af'
        push    hl
        exx
        push    hl
        exx
        call    LdDEdeB_1
        call    ExHLhlC_DEdeB
        xor     a
.loc_0_E3B1
        ex      af, af'
        dec     a
        jr      z, loc_0_E3D5
        jp      p, loc_0_E3BC
        cp      c
        jr      c, loc_0_E3D5
        inc     a
.loc_0_E3BC
        ex      af, af'
        inc     a
        set     7, h
        call    sub_0_E303
        jr      nc, loc_0_E3CA
        ex      af, af'
        call    SrlHLhlC0
        ex      af, af'
.loc_0_E3CA
        ex      af, af'
        call    c, IncHLhl
        inc     c
        jp      m, loc_0_E3B1
        jp      ErrTooBig
;       ----
.loc_0_E3D5
        call    ExHLhlC_DEdeB
        res     7, d
        exx
        pop     hl
        exx
        pop     hl
        ex      af, af'
        ret

;       ----

;       DEde/BCbc -> DEde=quotient, HLhl=remainder

.Division
        or      a

.loc_0_E3E1
        sbc     hl, bc
        exx
        sbc     hl, bc
        exx
        jr      nc, loc_0_E3EE

        add     hl, bc                          ; undo sub
        exx
        adc     hl, bc
        exx

.loc_0_E3EE
        ccf

.loc_0_E3EF
        rl      e
        rl      d
        exx
        rl      e
        rl      d
        exx
        inc     a
        ret     p

.loc_0_E3FB
        adc     hl, hl
        exx
        adc     hl, hl
        exx
        jr      nc, loc_0_E3E1
        or      a
        sbc     hl, bc
        exx
        sbc     hl, bc
        exx
        scf
        jp      loc_0_E3EF
;       ----
.sub_0_E40E
        or      a
.loc_0_E40F
        exx
        rr      d
        rr      e
        exx
        rr      d
        rr      e
        jr      nc, loc_0_E420
        add     hl, bc
        exx
        adc     hl, bc
        exx
.loc_0_E420
        inc     a
        ret     p
; End of function sub_0_E40E
;       ----
.sub_0_E422
        exx
        rr      h
        rr      l
        exx
        rr      h
        rr      l
        jp      loc_0_E40F
; End of function sub_0_E422

;       ----
.loc_0_E42F
        sbc     hl, bc
        exx
        sbc     hl, bc
        exx
        inc     c
        jr      nc, loc_0_E43F
        dec     c
        add     hl, bc
        exx
        adc     hl, bc
        exx
        dec     c
.loc_0_E43F
        inc     a
        ret     p
;       ----
.sub_0_E441
        sla     c
        rl      b
        exx
        rl      c
        rl      b
        exx
        inc     c
        sla     e
        rl      d
        exx
        rl      e
        rl      d
        exx
        adc     hl, hl
        exx
        adc     hl, hl
        exx
        sla     e
        rl      d
        exx
        rl      e
        rl      d
        exx
        adc     hl, hl
        exx
        adc     hl, hl
        exx
        jp      nc, loc_0_E42F

.loc_0_E46F
        or      a
        sbc     hl, bc
        exx
        sbc     hl, bc
        exx
        inc     c
        jp      loc_0_E43F

;       ----

.sub_0_E47A
        add     hl, hl                          ; HLhl *= 2
        exx
        adc     hl, hl
        exx
        jr      c, loc_0_E46F
        inc     a
        inc     c                               ; increment exponent
        sbc     hl, bc                          ; HLhl -= BCbc
        exx
        sbc     hl, bc
        exx
        ret     nc
        add     hl, bc                          ; undo sub
        exx
        adc     hl, bc
        exx
        dec     c
        ret

;       ----
;       Read byte, return Fc=1 if it's not number


.ReadNum
        call    ReadByteIX
        cp      '9'+1
        ccf
        ret     c
        cp      '0'
        ret

;       Read first non-blank, skip + and -

.GetNumStart
        call    ReadByteIX
        inc     ix
        cp      ' '
        jr      z, GetNumStart                  ; skip leading blanks
        cp      '+'
        ret     z
        cp      '-'
        ret     z
        dec     ix
        ret

.ReadByteIX
        push    ix
        pop     de
        bit     7, d                            ; if DE not in S3 then just read it
        jr      z, rb_1                         ; !! 'ld a, (de); ... ; ret z'
        bit     6, d
        jr      z, rb_1
        ex      af, af'

        ld      a, (BLSC_SR1)                   ; store S1
        push    af
        ld      a, (iy+OSFrame_S3)
        ld      (BLSC_SR1), a                   ; caller S3 into S1
        out     (BL_SR1), a

        res     7, d                            ; fix DE into S1
        ex      af, af'
        ld      a, (de)                         ; read byte
        ex      af, af'
        set     7, d                            ; restore DE

        pop     af                              ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ret

.rb_1
        ld      a, (de)
        ret

;       ----

.WriteByteHL
        bit     7, h                            ; if HL not in S3 then just write it
        jr      z, wb_1
        bit     6, h
        jr      z, wb_1

        ex      af, af'
        ld      a, (BLSC_SR1)                   ; store S1
        push    af

        ld      a, (iy+OSFrame_S3)              ; bind caller S3 into S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a

        res     7, h                            ; fix HL into S1
        ex      af, af'
        ld      (hl), a                         ; write byte
        ex      af, af'
        set     7, h                            ; restore HL

        pop     af                              ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ret

.wb_1
        ld      (hl), a
        ret

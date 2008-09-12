; **************************************************************************************************
; Division/Multiplication API for 16/24bit integers (GN_D16, GN_M16, GN_M24, GN_D24)
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
; (C) Thierry Peycru (pek@users.sf.net), 2005,2006
; (C) Gunther Strube (gbs@users.sf.net), 2005,2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module GNMath

        include "error.def"
        include "sysvar.def"

;       ----

xdef    GND16, Divu16
xdef    GNM16, Mulu16
xdef    GNM24, Mulu24
xdef    GND24, Divu24

;       ----

xref    GN_ret1c
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


;       HL*DE -> HL=product
.Mulu16
        push    de
        push    bc
        ld      c, l                            ; BC=HL(in)
        ld      b, h
        ld      hl, 0                           ; HL=0
        ld      a, 15
.m16_1
        sla     e                               ; DE << 1
        rl      d
        jr      nc, m16_2
        add     hl, bc                          ; HL += HL(in)
.m16_2
        add     hl, hl                          ; HL << 1
        dec     a
        jr      nz, m16_1
        or      d
        jp      p, m16_3
        add     hl, bc                          ; HL += HL(in)
.m16_3
        pop     bc
        pop     de
        ret


;       HL/DE -> HL=quotient, DE=remainder
.Divu16
        push    bc
        ld      a, e
        or      d
        jr      nz, d16_1
        scf                                     ; divide by zero
        jr      d16_4

.d16_1
        ld      c, l                            ; AC=HL(in)
        ld      a, h
        ld      hl, 0                           ; HL=0
        ld      b, 16
        or      a                               ; Fc=0
.d16_2
        rl      c                               ; HLAC<<1 | Fc
        rla
        rl      l
        rl      h
        push    hl                              ; HL-DE(in)>=0? Fc = 1, HC -= DE(in)
        sbc     hl, de
        ccf
        jr      c, d16_3
        ex      (sp), hl                        ; else Fc=0
.d16_3
        inc     sp
        inc     sp
        djnz    d16_2

        ex      de, hl                          ; DE=remainder
        rl      c                               ; HL= AC<<1 | Fc
        ld      l, c
        rla
        ld      h, a
        or      a
.d16_4
        pop     bc
        ret


;       BHL*CDE -> BHL=product
.Mulu24
        push    de
        ex      de, hl                          ; BDE=BHL(in)
        xor     a                               ; AHL=0
        ld      h, a
        ld      l, a
        ex      af, af'                         ;       alt
        ld      a, c                            ; ade=CDE(in)
        exx                                     ;       alt
        pop     de
        ld      b, 23
.m24_1
        sla     e                               ; ade << 1
        rl      d
        rl      a
        exx                                     ;       main
        jr      nc, m24_2                       ; bit set? add total
        ex      af, af'                         ;       main
        add     hl, de                          ; AHL=AHL+BHL(in)
        adc     a, b
        ex      af, af'                         ;       alt
.m24_2
        ex      af, af'                         ;       main
        add     hl, hl                          ; AHL=AHL<<1
        adc     a, a
        exx                                     ;       alt
        ex      af, af'                         ;       alt
        djnz    m24_1
        exx                                     ;       main
        rlca                                    ; last bit
        jr      nc, m24_3
        ex      af, af'                         ;       main
        add     hl, de                          ; AHL += BHL(in)
        adc     a, b
        ex      af, af'                         ;       alt
.m24_3
        ex      af, af'                         ;       main
        ld      b, a
        ret


;       BHL/CDE -> BHL=quotient, CDE=remainder
.Divu24
        ld      a, e
        or      d
        or      c
        jr      nz, d24_1
        scf                                     ; division by zero
        jr      d24_5

.d24_1
        push    hl
        xor     a
        ld      hl, 0
        exx                                     ;       alt
        pop     hl
        ld      b, 24
.d24_2
        rl      l
        rl      h
        exx                                     ;       main
        rl      b
        rl      l
        rl      h
        rl      a
        push    af
        push    hl
        sbc     hl, de
        sbc     a, c
        ccf
        jr      c, d24_3
        pop     hl
        pop     af
        or      a
        jr      d24_4
.d24_3
        inc     sp
        inc     sp
        inc     sp
        inc     sp
.d24_4
        exx                                     ;       alt
        djnz    d24_2

        rl      l
        rl      h
        push    hl
        exx                                     ;       main
        rl      b
        ex      de, hl
        ld      c, a
        pop     hl
        or      a
.d24_5
        ret

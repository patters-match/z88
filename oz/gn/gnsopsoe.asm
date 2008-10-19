; **************************************************************************************************
; GN_Sop / GN_Soe interface.
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
; (C) Thierry Peycru (pek@users.sf.net), 2007
; (C) Gunther Strube (gbs@users.sf.net), 2007
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module GNSopSoe


        include "blink.def"
        include "memory.def"
        include "stdio.def"
        include "oz.def"


        xdef    GNSoe
        xdef    GNSop

        xref    GetOsf_HL, PutOsf_HL            ; gnmisc3.asm


; **********************************************************************************************************
; write local string to standard output
;
; IN:    HL = local pointer to null-terminated string
; OUT:   HL = pointer to null
;
; CHG:   .F....HL/....

.GNSop
        call    bix_s1s2                        ; fast OS_Bix
        push    de                              ; remember old S1S2 bindings

        ld      b, 0                            ; HL=local
        push    hl                              ; remember start of string in S1
        OZ      OS_Bout                         ; then display as local pointer beginning from S1 onwards
        pop     de
        sbc     hl,de                           ; get length of string that was sent to screen driver
        ex      de,hl
        call    GetOsf_HL
        add     hl,de
        call    PutOsf_HL                       ; return original HL now updated to point at null-terminator

        pop     bc                              ; restore S1 + S2 bindings
        call    bind_s1s2
        ret

.bix_s1s2
        ld      de, (BLSC_SR1)                  ; remember S2S1 in DE
        bit     7, h
        ret     z                               ; not kernel space, no bankswitching
        ld      b, (iy+OSFrame_S3)
        ld      c, (iy+OSFrame_S2)

        bit     6, h
        jr      z, bix_S2                       ; HL in S2 - S1=caller S2, S2=caller S3
        ld      c, b                            ; HL in S3
        ld      b, d                            ; S1=caller S2
.bix_S2
        call    bind_s1s2
        res     7, h                            ; S1 fix
        set     6, h
        ret
.bind_s1s2
        ld      (BLSC_SR1), bc
        ld      a, c
        out     (BL_SR1), a
        ld      a, b
        out     (BL_SR2), a
        ret


; **********************************************************************************************************
; write string at extended address to standard output
;
; IN:    BHL = pointer to null-terminated string (B=0 isn't local, it's bank 0)
; OUT:   HL = pointer to null
;
; CHG:   .F....HL/....

.GNSoe
        ld      c, MS_S1                        ; bind BHL into S1
        rst     OZ_MPB
        push    bc

        res     7, h                            ; then adjust offset to segment 1
        set     6, h
        OZ      OS_Bout

        res     6,h                             ; strip segment 1 mask (now a pure bank offset)
        ld      a,(iy+OSFrame_H)
        and     @11000000
        or      h
        ld      h,a                             ; restored original segment mask of pointer
        call    PutOsf_HL                       ; return pointer to null (bank unchanged)

        pop     bc                              ; restore S1 bank binding
        rst     OZ_MPB
        ret

; **************************************************************************************************
; Stack frame internal calls
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
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; ***************************************************************************************************


        Module stkframe

        include "oz.def"
        include "lowram.def"

xdef    OSFramePush
xdef    OSFramePushMain
xdef    OSFramePop
xdef    OSFramePopX
xdef    GetOSFrame_BC
xdef    GetOSFrame_DE
xdef    GetOSFrame_HL
xdef    PutOSFrame_BC
xdef    PutOSFrame_BHL
xdef    PutOSFrame_CDE
xdef    PutOSFrame_DE
xdef    PutOSFrame_HL


xref    MS2BankK1                               ; [Kernel0]/knlbind.asm
xref    MS2BankA                                ; [Kernel0]/knlbind.asm


.OSFramePush
        pop     hl                              ; caller PC
        pop     bc                              ; S2/S3
        call    MS2BankK1                       ; bind in more kernel code

.OSFramePushMain
        push    bc                              ; 0E - S2S3
        exx
        push    hl                              ; 0C - HL
        push    de                              ; 0A - DE
        push    bc                              ; 08 - BC
        ex      af, af'
        push    af                              ; 06 - AF
        exx
        push    de                              ; 04 - OZCall
        push    bc                              ; 02 - S2S3
        push    iy                              ; 00 - IY

        ld      iy, 0
        add     iy, sp
        ld      (iy+OSFrame_F), 0               ; clear flags

        push    hl                              ; RET caller
        exx                                     ; use caller registers
        ret

.OSFramePopError
        pop     iy                              ; 00 - IY
        ex      af, af'                         ; save return value
        pop     bc                              ; 02 - S2S3
        ld      a, c
        call    MS2BankA                        ; bind out other half of kernel
        ex      af, af'                         ; back to return value
        pop     bc                              ; 04 - OZCall
        pop     bc                              ; 06 - AF
        jr      osfpop_2                        ; restore BC-HL

.OSFramePop
        jr      c, OSFramePopError

.OSFramePopX                                    ; pop OSFrame without error
        pop     iy                              ; 00 - IY
        pop     bc                              ; 02 - S2S3
        ld      a, c
        call    MS2BankA                        ; bind out other half of kernel
        pop     af                              ; 04 - OZCall
        pop     af                              ; 06 - AF
.osfpop_2
        pop     bc                              ; 08 - BC
        pop     de                              ; 0A - DE
        pop     hl                              ; 0C - HL
        jp      OZCallReturn1                   ; restore S2S3 and return

.GetOSFrame_BC
        ld      b, (iy+OSFrame_B)
        ld      c, (iy+OSFrame_C)
        ret


.GetOSFrame_DE
        ld      d, (iy+OSFrame_D)
        ld      e, (iy+OSFrame_E)
        ret


.GetOSFrame_HL
        ld      h, (iy+OSFrame_H)
        ld      l, (iy+OSFrame_L)
        ret

.PutOSFrame_BC
        ld      (iy+OSFrame_B), b
        ld      (iy+OSFrame_C), c
        ret

.PutOSFrame_CDE
        ld      (iy+OSFrame_C), c
.PutOSFrame_DE
        ld      (iy+OSFrame_D), d
        ld      (iy+OSFrame_E), e
        ret


.PutOSFrame_BHL
        ld      (iy+OSFrame_B), b

.PutOSFrame_HL
        ld      (iy+OSFrame_H), h
        ld      (iy+OSFrame_L), l
        ret

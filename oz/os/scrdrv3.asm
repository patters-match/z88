; **************************************************************************************************
; Screen driver initialisation calls. The routines are located in Kernel 0.
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
; $Id$
;***************************************************************************************************; -----------------------------------------------------------------------------

        Module ScrDrv3

        include "sysvar.def"
        include "screen.def"
        include "stdio.def"


xdef    InitApplWd
xdef    InitSBF
xdef    InitWindowFrame
xdef    ResetWdAttrs

xref    DrawOZwd                                        ; [Kernel0]/ozwindow.asm
xref    Zero_ctrlprefix                                 ; [Kernel1]/scrdrv1.asm



; -----------------------------------------------------------------------------
.InitOZwd
        OZ      OS_Pout
        defm    1,"7#8",$80+104,$20+0,$20+4,$20+8,$40   ; window 8 @+104,0 4x8 $40
        defm    1,"2C8"                                 ; select & clear 8
        defm    1,"6#7",$80+0,$20+0,$20+10,$20+8        ; window 7 @+0,0 10x8
        defm    0

; -----------------------------------------------------------------------------
.InitApplWd
        OZ      OS_Pout
        defm    1,"6#1",$80+10,$20+0,$20+94,$20+8       ; window 1 @abs10,0 94x8
        defm    1,"2I1"                                 ; select & init 1
        defm    0
        ret

; -----------------------------------------------------------------------------
.InitSBF
        ld      hl, Wd1Frame
        ld      (sbf_ActiveWd), hl
        call    Zero_ctrlprefix
        call    InitOZwd
        OZ      OS_Pout
        defm    1,"3+CS"
        defm    0
        jp      DrawOZwd

; -----------------------------------------------------------------------------
;
;IN :   IX = window frame, A=flagsF4, B=height, C=width, D=ypos, E=xpos
;OUT:   -
;
; -----------------------------------------------------------------------------
.InitWindowFrame
        ex      af, af'
        ld      a, e
        sla     a                               ; *2 + 1
        cp      2*108                           ; line width * 2
        ccf
        ret     c                               ; x>=108? error
        ld      e, a

        ld      a, d
        cp      8
        ccf
        ret     c                               ; y>8? error
        add     a, SBF_PAGE
        ld      d, a

        dec     b                               ; lst_row=ypos+height-1
        add     a, b
        ret     c
        ld      b, a
        ld      a, SBF_PAGE+7
        cp      b
        ret     c                               ; height+y>$7f? error

        dec     c
        scf
        ret     m                               ; width<1 or width>128? error
        ld      a, c
        sla     a
        add     a, e
        ret     c
        cp      2*108                           ; line width * 2
        ccf
        ret     c                               ; end>=108? error

        ld      (ix+wdf_endx), a
        ld      (ix+wdf_rmargin), a
        ld      (ix+wdf_startx), e
        ld      (ix+wdf_crsrx), e
        ld      (ix+wdf_lmargin), e
        ld      (ix+wdf_starty), d
        ld      (ix+wdf_crsry), d
        ld      (ix+wdf_endy), b
        ex      af, af'
        ld      (ix+wdf_OpenFlags), a

; -----------------------------------------------------------------------------
.ResetWdAttrs
        ld      (ix+wdf_flagsHi), 0
        ld      (ix+wdf_f2), 0
        ld      bc, 0
        ld      (ix+wdf_f6), b
        ld      (ix+wdf_flagsLo), c
        cp      a                               ; Fc = 0, Fz = 0
        ret

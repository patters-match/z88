; **************************************************************************************************
; High Resolution Graphics Manipulation Interface, used by PipeDream and BBC BASIC.
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
;***************************************************************************************************


        Module OSMap

        include "screen.def"
        include "blink.def"
        include "error.def"
        include "stdio.def"
        include "syspar.def"
        include "sysvar.def"

xdef    OSMap

xref    Chk128KB                                ; bank0/resetx.asm
xref    GetWindowFrame                          ; bank0/scrdrv2.asm
xref    PeekHLinc                               ; bank0/misc5.asm
xref    PokeBHL                                 ; bank0/misc5.asm
xref    PutOSFrame_BC                           ; bank0/misc5.asm
xref    ScreenClose                             ; bank0/scrdrv4.asm
xref    ScreenOpen                              ; bank0/scrdrv4.asm

xref    GetCurrentWdInfo                        ; bank7/mth1.asm
xref    RestoreActiveWd                         ; bank7/mth1.asm



.OSMap
        push    ix
        call    OSMapMain
        pop     ix
        ret

.OSMapMain
        ld      b, c
        djnz    osmap_def
        push    hl                              ; write a line to the map
        ex      af, af'
        call    ScreenOpen                      ; get access to window data in segment 1, returns old bank binding in A
        ex      af, af'
        call    GetWindowFrame                  ; setup IX to point at base of Window frame (in segment 1)
        ld      b, 0                            ; BC=(rmargin+1)&$fffe
        ld      c, (ix+wdf_rmargin)
        inc     bc
        res     0, c                            ; BC = width of map in pixels (always even numbered)
        ex      af, af'
        call    ScreenClose                     ; restore previous bank binding of segment 1
        ex      af, af'
        jr      c, osmap_3                      ; GetWindowFrame failed? exit
        ld      a, e                            ; mask row number to 6 bits (only allow values 0-63)
        and     $3F
        ld      hl, 8                           ; prepare for entry
        sbc     hl, bc
.osmap_1
        add     hl, bc
        sub     8
        jr      nc, osmap_1
        push    bc
        ld      c, a                            ; row
        ld      b, $FF
        add     hl, bc
        ld      a, (BLSC_PB2L)
        and     1
        rrca
        rrca
        rrca
        ld      d, a
        ld      e, 0
        add     hl, de
        ex      de, hl
        pop     hl                              ; BC*=32
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      b, h                            ; no of bytes in pixel line to write to map
        pop     hl                              ; HL = pointer to pixel line data to write

        ld      a, (BLSC_PB2H)
        rra
        ld      a, (BLSC_PB2L)
        rra
        ld      c,a                             ; C = bank of HIRES0, the PipeDream Map Area
.osmap_2
        push    bc                              ; plot pixel line of B bytes to
        call    PeekHLinc                       ; A = byte from pixel line data (in caller address space)
        ex      de, hl
        ld      b, c
        call    PokeBHL                         ; plot 8 pixels in A at address pixel line at BHL, the PipeDream Map Area
        ld      bc, 8
        add     hl, bc                          ; point to next adjacent 8 bits in current pixel map line
        ex      de, hl
        pop     bc
        djnz    osmap_2
        or      a
        push    hl
.osmap_3
        pop     hl
        ret
.osmap_def
        djnz    osmap_gra
.osmap_5
        ex      af, af'                         ; define a map using the Panel default width
        call    ScreenOpen
        ex      af, af'
        call    GetWindowFrame
        jr      c, osmap_7
        call    sub_9EBC
        jr      c, osmap_6
        push    bc
        push    de
        OZ      OS_Pout
        defm    1,"7#",0
        ld      a, (iy+OSFrame_A) ; window A
        OZ      OS_Out
        ld      a, $7E                          ; x
        sub     c
        OZ      OS_Out
        ld      a, $20                          ; y
        OZ      OS_Out
        add     a, c                            ; width
        OZ      OS_Out
        call    GetCurrentWdInfo

        OZ      OS_Pout
        defm    "(",$60
        defm    1,"2C",0

        ld      a, (iy+OSFrame_A)
        OZ      OS_Out
        call    RestoreActiveWd
        pop     de
        pop     bc
        ld      (ix+wdf_rmargin), d
.osmap_6
        or      a
.osmap_7
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        jp      PutOSFrame_BC
.osmap_gra
        dec     b
        jr      z, osmap_5                      ; gra
        djnz    osmap_err
        or      a                               ; del
        ret
.osmap_err
        ld      a, RC_Unk                       ; Unknown request (parameter in register) *
        scf
        ret
;       ----
.sub_9EBC
        call    sub_9F0C
        ld      bc, 0
        ret     c
        ld      a, l
        cp      'Y'
        scf
        ret     nz
        call    sub_9EF6
        ld      bc, 0
        ret     c
        inc     l
        dec     l
        scf
        ret     z
        ld      a, l
        cp      $61
        jr      c, loc_9EDF
        call    Chk128KB
        jr      nc, loc_9EDF
        ld      l, $60
.loc_9EDF
        ld      a, l
        add     a, 7
        jr      nc, loc_9EE8
        ld      a, $FF
        jr      loc_9EEA
.loc_9EE8
        and     $F8
.loc_9EEA
        ld      d, a
        dec     a
        ld      c, 0
.loc_9EEE
        inc     c
        sub     6
        jr      nc, loc_9EEE
        ld      b, l
        or      a
        ret

;       ----
.sub_9EF6
        ld      l, (iy+OSFrame_L)
        ld      a, (iy+OSFrame_C)
        cp      3
        ret     z
        ld      bc, PA_Msz                      ; map size in pixels
        call    sub_9F17
        ret     c
        ld      a, h
        or      a
        ret     z
        ld      l, $FF
        ret

;       ----
.sub_9F0C
        ld      l, 'Y'
        ld      a, (iy+OSFrame_C)
        cp      3
        ret     z
        ld      bc, PA_Map                      ; PipeDream map 'Y' or 'N'

;       ----
.sub_9F17
        push    hl
        ld      hl, 0
        add     hl, sp
        ex      de, hl
        ld      a, 2
        OZ      OS_Nq
        pop     hl
        ret

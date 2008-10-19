; **************************************************************************************************
; OS_SCI system call (alter screen information)
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
; ***************************************************************************************************

        Module OsSci

        include "blink.def"
        include "error.def"
        include "sysvar.def"
        include "oz.def"

xdef    OsSci

xref    InitSBF                                 ; [Kernel0]/scrdrv3.asm
xref    ScreenClose                             ; [Kernel0]/scrdrv4.asm
xref    ScreenOpen                              ; [Kernel0]/scrdrv4.asm

; -----------------------------------------------------------------------------
;
; granularity table used by OSSci
; ! must start a page in kernel 1 !
;
; -----------------------------------------------------------------------------

.OSSciTable
        defb 0, 3, 6, 7, 5, 5                   ; #low bits ignored

IF (<$linkaddr(OSSciTable)) <> 0
        ERROR "OS_SCI table must start a page at $00!"
ENDIF

; -----------------------------------------------------------------------------
;
; alter screen information
;
;IN:    A=reason code
;               SC_LR0  LORES0 (512 bytes granularity, 13 bits width)
;               SC_LR1  LORES1 (4K granularity, 10 bits width)
;               SC_HR0  HIRES0 (8K granularity, 9 bits  width)
;               SC_HR1  HIRES1 (2K granularity, 11 bits width)
;               SC_SBR  screen base (2K granularity, 11 bits width)
;       B=0, get pointer address
;       B<>0, set pointer address
;OUT:   Fc=0, BHL = old pointer address
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/....
;
; -----------------------------------------------------------------------------

.OSSci
        or      a
        jr      z, ossci_4                      ; A = 0, bad reason
        cp      6
        jr      nc, ossci_4                     ; A > 5, bad reason

        ld      de, OSSciTable
        add     a, e
        ld      e, a
        add     a, BL_PB0-1
        ld      c, a                            ; BLINK register

        ld      a, (de)                         ; granularity
        push    bc
        inc     b
        dec     b
        push    af                              ; shift count, B=0 status

        sla     h                               ; H<<2, get rid of segment bits
        sla     h
.ossci_1
        srl     b                               ; BH>>A
        rr      h
        dec     a
        jr      nz, ossci_1

        pop     af                              ; B=0 status
        push    af

        ld      a, h                            ; AB=blink value
        ld      h, BLSC_PAGE                    ; HL=$047x
        ld      l, c
        ld      e, (hl)                         ; old value into DE
        res     4, l                            ; $046x
        ld      d, (hl)                         ; old value
        jr      z, ossci_2                      ; B=0? don't set

        set     4, l                            ; $047x
        ld      (hl), a
        res     4, l                            ; $046x
        ld      (hl), b
        out     (c), a

.ossci_2
        ld      a, c                            ; blink register
        ex      de, hl
        pop     bc                              ; B=shift count

.ossci_3
        add     hl, hl
        djnz    ossci_3
        srl     l                               ; normalize HL
        srl     l
        pop     de
        ld      (iy+OSFrame_B), h
        ld      (iy+OSFrame_H), l
        ld      (iy+OSFrame_L), 0
        xor     BL_SBR                          ; screen base reg.
        ret     nz                              ; not SBR? exit
        bit     6, c                            ; B=0
        ret     nz                              ; read only? exit

        ld      a, d                            ; init screen
        ld      (ubScreenBase), a
        call    ScreenOpen
        call    InitSBF
        call    ScreenClose
        or      a
        ret

.ossci_4
        ld      a, RC_Fail
        scf
        ret

; **************************************************************************************************
; ESC Key handling (OS_Esc)
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
; (C) Thierry Peycru (pek@users.sf.net), 2005,2008
; (C) Gunther Strube (gbs@users.sf.net), 2005,2008
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; ***************************************************************************************************


        Module Esc

        include "error.def"
        include "stdio.def"
        include "sysvar.def"
        include "interrpt.def"

        include "lowram.def"

xdef    OSEsc
xdef    TestEsc
xdef    MaySetEsc

xref    ResetTimeout                            ; [Kernel0]/nmi.asm


defc    AKBD_ESCENABLED         =$80
defc    AKBD_B_ESCENABLED       =7


; examine special condition
.OSEsc
        ld      hl, ubIntTaskToDo
        ex      af, af'
        ld      b, a                            ; B=reason
        or      a
        jr      z, osexc_bit

        djnz    osesc_set

.osesc_ack                                      ; ack escape, flush input buffer
        call    ResetTimeout
        bit     ITSK_B_ESC, (hl)
        jr      z, OSEsc_x
        res     ITSK_B_ESC, (hl)
        push    af
        exx
        OZ      OS_Pur                          ; purge keyboard buffer
        exx
        pop     af
        jr      OSEsc_x

.osesc_set
        djnz    osesc_res

        set     ITSK_B_ESC, (hl)                ; set escape
        jr      OSEsc_x

.osesc_res
        djnz    osesc_tst

        res     ITSK_B_ESC, (hl)                ; reset escape
        jr      OSEsc_x

.osesc_tst
        ld      hl, ubAppKbdBits
        djnz    osesc_ena

        bit     AKBD_B_ESCENABLED, (hl)         ; test if escape detection is enabled or disabled
        ld      a, SC_ENA
        jr      nz, OSEsc_x
        inc     a                               ; DC_DIS
        jr      OSEsc_x

.osesc_ena
        djnz    osesc_dis

        set     AKBD_B_ESCENABLED, (hl)         ; enable escape detection
        jr      OSEsc_x

.osesc_dis
        djnz    osesc_unk
        res     AKBD_B_ESCENABLED, (hl)         ; disable escape detection
        ld      hl, ubIntTaskToDo
        res     ITSK_B_ESC, (hl)                ; clear any pending ESC
        jr      OSEsc_x

.osesc_unk
        ld      a, RC_Unk
        jr      osesc_err

.osexc_bit
        call    ResetTimeout                    ; test for Escape
        bit     ITSK_B_ESC, (hl)
        jr      z, OSEsc_x

        ld      a, RC_Esc
.osesc_err
        scf
.OSEsc_x
        jp      OZCallReturn2

;       ----

.TestEsc
        or      a                               ; Fc=0
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_ESC, (hl)
        ret     z

        ld      a, RC_Esc
        scf
        ret

;       ----

.MaySetEsc
        ld      hl, ubAppKbdBits
        bit     AKBD_B_ESCENABLED, (hl)
        ret     z                               ; disabled? exit

        ld      hl, ubIntTaskToDo               ; set ESC flag
        set     ITSK_B_ESC, (hl)
        ret


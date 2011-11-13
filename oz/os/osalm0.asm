; **************************************************************************************************
; OS_Alm entry and alarm mangement during interrupt (kernel 0).
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

        Module Alarm0

        include "alarm.def"
        include "sysvar.def"
        include "oz.def"
        include "z80.def"
        include "interrpt.def"
        include "handle.def"

        include "lowram.def"

xdef    OSAlm
xdef    DoAlarms

xref    OSOff                                   ; [Kernel0]/nmi.asm
xref    OSFramePush                             ; [Kernel0]/stkframe.asm
xref    OSFramePopX                             ; [Kernel0]/stkframe.asm

xref    OSAlmMain                               ; [Kernel1]/osalm.asm
xref    SetPendingOZwd                          ; [Kernel0]/ozwindow.asm

.OSAlm
        call    OSFramePush

        ld      c, b
        ld      b, a

        call    OZ_DI
        push    af

        ld      a, c
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1
        call    OSAlmMain

        pop     af
        call    OZ_EI

        call    SetPendingOZwd                  ; request OZ window redraw
        jp      OSFramePopX                     ; pop OS frame without error

;       ----

.DoAlarms
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_SHUTDOWN, (hl)           ; process shutdown request
        call    nz, OSOff
        bit     ITSK_B_ALARM, (hl)
        ret     z                               ; no alarm? exit

        push    af
        ex      af, af'
        push    af
        exx
        push    bc
        push    de
        push    hl
        exx
        push    ix

        ld      ix, (pFirstAlarm)
        ld      a, (ix+ahnd_Func+2)
        ld      e, (ix+ahnd_Func)
        ld      d, (ix+ahnd_Func+1)
        push    de
        pop     ix
        or      a
        jr      nz,no_alm
        OZ      GN_Alp                          ; process an expired alarm
.no_alm
        pop     ix
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        pop     af
        ex      af, af'
        pop     af
        ret

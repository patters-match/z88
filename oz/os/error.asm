; **************************************************************************************************
; Error Handler Interface, located in Bank 0.
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


        Module Error

        include "error.def"
        include "sysvar.def"

        include "lowram.def"

xdef    CallErrorHandler
xdef    OSErc
xdef    OSErh

;       set error handler

.OSErh
        ld      hl, (pAppErrorHandler)          ; remember old handler
        push    hl
        exx
        ld      a, h                            ; if HL=0 use default handler
        or      l                               ; !! note that if you had AT2_IE set
        jr      nz, oserh_1                     ; !! in DOR this enables error return
        ld      hl, DefErrHandler               ; !! ld l,<DefErrHandler
.oserh_1
        ld      (pAppErrorHandler), hl
        pop     hl                              ; get old handler
        exx
        ld      a, (ubAppCallLevel)             ; remember old call level
        dec     a                               ; -1 for Os_Erh
        push    af                              ; !! just ex af,af' after setting new value
        ex      af, af'
        inc     a                               ; +1 for OS_Erh
        ld      (ubAppCallLevel), a             ; set new call level
        pop     af
        or      a
        jp      OZCallReturn2

;       ----

;       get error context

.OSErc
        ld      ix, 0
        exx
        ld      bc, (ubAppDynID)                ; resumption cycle, dynamic id
        exx
        ld      a, (ubAppLastError)             ; last error code
        or      a
        jp      OZCallReturn2

;       ----

.CallErrorHandler
        push    bc
        push    de
        push    hl
        exx
        push    bc
        push    de
        push    hl
        push    af

.cerh_1
        push    af                              ; push bank
        ex      af, af'
        ld      (ubAppLastError), a
        OZ      GN_Esp                          ; only for Fz
        scf                                     ; for AppErrorHandler
        ex      af, af'

        ld      hl, (pAppErrorHandler)
        pop     af                              ; bank
        push    af
        call    JpAHL
        pop     af
        ex      af, af'                         ; error/flags from AppErrorHandler
        jr      c, cerh_4
        jr      z, cerh_3                       ; not fatal? exit
        ex      af, af'
        call    JpAHL
        jr      $PC                             ; crash

.cerh_3
        scf
        ex      af, af'
        pop     af
        pop     hl
        pop     de
        pop     bc
        exx
        pop     hl
        pop     de
        pop     bc
        ret

.cerh_4
        ld      hl, ubAppCallLevel
        inc     (hl)
        OZ      GN_Err                          ; display an interactive error box
        dec     (hl)
        ex      af, af'
        pop     af
        push    af
        jr      cerh_1

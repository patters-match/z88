; **************************************************************************************************
; Clock, Alarm & Calendar popdown main source file (addressed for segment 3).
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

        Module  ClCalAlm

        org     $e7ee

        include "alarm.def"
        include "director.def"
        include "error.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"

        xdef Exit, MoveToXb, MoveToXYbc
        xdef ApplyToggles, JustifyC, JustifyN, ToggleTR, ToggleRvrs, ToggleTiny
        xdef ClrScr, ToggleCrsr, ClrEOL, PrntString
        xdef DATE_txt

        xdef DisplayTime, KeyJump, KeyJump0, TableJump, tj_2, GetTableEntry, NavigateTable
        xdef AskDate, AskTime, TestKeys, GetOutHandle



; common code shared by Alarm, Clock & Calendar popdowns

.Exit
        xor     a
        OZ      OS_Bye                          ; Application exit
        jr      Exit


.NavigateTable
        inc     hl                              ; skip start mark
        inc     hl

.navt_1
        push    hl
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        or      h
        jr      nz, navt_3                      ; not start? skip

;       find last entry in table

;       !! remove pop/push hell

.navt_2
        pop     hl
        inc     hl
        inc     hl
        push    hl
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        ld      a, l                            ; !! and h; cpl; jr nz navt_2
        cp      $ff
        jr      nz, navt_2
        ld      a, h
        cp      $ff
        jr      nz, navt_2                      ; not end? loop

        pop     hl
        dec     hl                              ; skip end mark
        dec     hl
        jr      navt_1

.navt_3
        ld      a, l                            ; !! ld a,l; and h; cpl; jr nz
        cp      $ff
        jr      nz, navt_5                      ; not end? skip
        ld      a, h
        cp      $ff
        jr      nz, navt_5

;       find first entry in the table

;       !! remove pop/push hell

.navt_4
        pop     hl
        dec     hl
        dec     hl
        push    hl
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        or      h
        jr      nz, navt_4                      ; not start? loop

        pop     hl
        inc     hl                              ; skip start mark
        inc     hl
        jr      navt_1

.navt_5
        push    hl                              ; !! use JpHL in low RAM
        ld      hl, navt_6
        ex      (sp), hl
        jp      (hl)

.navt_6
        pop     hl
        ret     c                               ; error? return

        cp      IN_ENT
        ret     z
        cp      IN_RGT
        jr      z, navt_7
        cp      IN_SRGT
        jr      z, navt_7
        cp      IN_DRGT
        jr      z, navt_7
        cp      IN_DWN
        jr      nz, navt_8
.navt_7
        inc     hl                              ; next entry !! could re-use INCs at NavigateTable
        inc     hl
        jr      navt_1

.navt_8
        dec     hl                              ; previous entry
        dec     hl
        jr      navt_1


.TableJump
        call    GetTableEntry
        push    hl                              ; !! call JpHL in low RAM
        ld      hl, tj_1
        ex      (sp), hl
        jp      (hl)
.tj_1
        ret     nc
.tj_2
        cp      RC_Esc
        scf
        ret     nz

        ld      a, SC_ACK                       ; !! already 1
        OZ      OS_Esc                          ; Examine special condition
        xor     a
        ret


.GetTableEntry
        add     a, a
        add     a, l
        ld      l, a
        jr      nc, gte_1
        inc     h
.gte_1
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        ret


.KeyJump
        push    bc
        ld      c, a
.kj_1
        ld      a, (hl)
        inc     hl
        or      a
        jr      z, kj_2                         ; no more keys? RC_Fail
        cp      c
        jr      z, kj_3                         ; same? execute

        inc     hl                              ; retry next entry
        inc     hl
        jr      kj_1

.kj_2
        ld      a, RC_Fail                      ; General Failure, cannot satisfy request
        scf
        jr      kj_4

.kj_3
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        ex      (sp), hl                        ; !! pop bc; jp (hl)
        push    hl
.kj_4
        pop     bc
        ret


.KeyJump0
        OZ      OS_In
        jr      c, kj0_2
        or      a
        jr      nz, kj0_1
        OZ      OS_In
        jr      c, kj0_2
.kj0_1
        push    hl
        call    KeyJump
        pop     hl
        jr      nc, KeyJump0                    ; loop until error

.kj0_2
        cp      RC_Susp
        jr      z, KeyJump0                     ; retry
        cp      RC_Fail
        jr      z, KeyJump0                     ; retry

        cp      RC_Esc
        jr      z, kj0_3                        ; ack ESC

        cp      RC_Quit                         ; return on Quit/Draw
        scf
        ret     z
        cp      RC_Draw
        scf
        ret     z
        jr      KeyJump0                        ; else retry

.kj0_3
        ld      a, SC_ACK                       ; !! already 1
        OZ      OS_Esc
        ret


.DisplayTime
        push    ix
        push    ix
        pop     hl
        ld      de, 0
        push    af
        call    GetOutHandle
        pop     af
        OZ      GN_Ptm                          ; print time
        pop     ix
        ret


.AskDate
        call    ToggleCrsr

        ld      hl, -14                         ; get stack buffer
        add     hl, sp
        ld      sp, hl
        ex      de, hl

        push    bc
        push    de

        push    ix
        pop     hl
        ld      a, $a1                          ; century, C delimeter, zero blanking
        ld      bc, 0<<8|'/'                    ; condensed form, '/' delimeter
        OZ      GN_Pdt                          ; print

        pop     hl
        ex      de, hl
        jr      c, ad_6

        ld      (hl), 0                         ; null-terminate
        ld      c, 0                            ; cursor position

        push    bc
.ad_1
        pop     hl
        pop     bc
        push    bc
        call    MoveToXYbc
        ld      b, 14
        ld      c, l
        ld      a, $0f                          ; has data, force overwrite, return special
        OZ      GN_Sip
        push    bc
        jr      nc, ad_2
        cp      RC_Susp
        jr      z, ad_1                         ; retry
        scf
        jr      ad_5                            ; exit

.ad_2
        call    TestKeys
        jr      nz, ad_1                        ; not special? retry

        push    af
        ex      de, hl
        push    hl
        ld      b, 14
        ld      de, 2
        xor     a
        OZ      GN_Gdt                          ; into internal date
        pop     de
        pop     hl
        jr      nc, ad_3                        ; ok? exit

        ld      a, 7                            ; beep and retry
        OZ      OS_Out
        jr      ad_1

.ad_3
        ld      (ix+2), a
        ld      (ix+1), b
        ld      (ix+0), c
        push    hl
        pop     af

.ad_5
        pop     bc
.ad_6
        pop     bc

        ex      af, af'                         ; restore stack
        ld      hl, 14
        add     hl, sp
        ld      sp, hl
        ex      af, af'
        push    af
        call    ToggleCrsr
        pop     af
        ret


.AskTime
        call    ToggleCrsr

        ld      hl, -9                          ; get stack buffer
        add     hl, sp
        ld      sp, hl

        ex      de, hl
        push    bc
        push    de

        push    ix
        pop     hl
        ld      a, $21
        OZ      GN_Ptm
        pop     de
        jr      c, at_5

        ld      c, 0                            ; cursor position
        push    bc
.at_1
        pop     hl
        pop     bc

        push    bc
        call    MoveToXYbc
        ld      b, 9
        ld      c, l
        ld      a, $0F
        OZ      GN_Sip
        push    bc
        jr      nc, at_2

        cp      RC_Susp
        jr      z, at_1                         ; retry
        scf
        jr      at_4                            ; exit

.at_2
        call    TestKeys
        jr      nz, at_1                        ; retry

        push    af
        ex      de, hl
        push    hl
        ld      b, 9
        ld      de, 2
        OZ      GN_Gtm                          ; into internal format
        pop     de
        pop     hl
        jr      nc, at_3

        ld      a, 7                            ; beep and retry
        OZ      OS_Out
        jr      at_1

.at_3
        ld      (ix+2), a
        ld      (ix+1), b
        ld      (ix+0), c
        push    hl
        pop     af
.at_4
        pop     bc
.at_5
        pop     bc

        ex      af, af'                         ; restore stack
        ld      hl, 9
        add     hl, sp
        ld      sp, hl
        ex      af, af'

        push    af
        call    ToggleCrsr
        pop     af
        ret


;       !! test smallest first with 'ret c; ret z', then in decrementing order with 'ret nc'
.TestKeys
        cp      IN_RGT
        ret     z
        cp      IN_LFT
        ret     z
        cp      IN_UP
        ret     z
        cp      IN_DWN
        ret     z
        cp      IN_SRGT
        ret     z
        cp      IN_SLFT
        ret     z
        cp      IN_DRGT
        ret     z
        cp      IN_DLFT
        ret     z
        cp      IN_ENT
        ret


.GetOutHandle
        push    bc
        ld      bc, NQ_Out
        OZ      OS_Nq                           ; get out handle
        pop     bc
        ret


.MoveToXb
        push    hl
        ld      hl, MoveToX_txt
        OZ      GN_Sop
        ld      a, $20
        add     a, b
        OZ      OS_Out
        pop     hl
        ret


.MoveToXYbc
        push    hl
        ld      hl, MoveToXY_txt
        OZ      GN_Sop
        pop     hl
        ld      a, b
        add     a, $20
        OZ      OS_Out
        ld      a, c
        add     a, $20
        OZ      OS_Out
        ret


.ApplyToggles
        push    af
        push    hl
        ld      hl, Apply_txt
        OZ      GN_Sop
        pop     hl
        pop     af
        OZ      OS_Out
        ret


.JustifyC
        push    hl
        ld      hl, JustC_txt
        jr      PrntString


.JustifyN
        push    hl
        ld      hl, JustN_txt
        jr      PrntString


.ToggleTR
        call    ToggleTiny


.ToggleRvrs
        push    hl
        ld      hl, Reverse_txt
        jr      PrntString


.ToggleTiny
        push    hl
        ld      hl, Tiny_txt
        jr      PrntString


.ClrScr
        push    hl
        ld      hl, Cls_txt
        jr      PrntString


.ToggleCrsr
        push    hl
        ld      hl, Cursor_txt
        jr      PrntString


.ClrEOL
        push    hl
        ld      hl, ClrEOL_txt

.PrntString
        OZ      GN_Sop
        pop     hl
        ret

.DATE_txt
        defm    "DATE",0
.MoveToXY_txt
        defm    1,"3@", 0
.MoveToX_txt
        defm    1,"2X", 0
.Cls_txt
        defm    1,"3@",$20+0,$20+0
        defm    1,"2C",$fe, 0
.ClrEOL_txt
        defm    1,"2C",$fd, 0
.Cursor_txt
        defm    1,"C", 0
.Tiny_txt
        defm    1,"T", 0
.Apply_txt
        defm    1,"2A", 0
.JustC_txt
        defm    1,"2JC", 0
.JustN_txt
        defm    1,"2JN", 0
.Reverse_txt
        defm    1,"R", 0

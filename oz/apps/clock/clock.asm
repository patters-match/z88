; **************************************************************************************************
; Clock popdown (Bank 1, addressed for segment 3).
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
; ***************************************************************************************************

        Module  Clock

        include "alarm.def"
        include "error.def"
        include "stdio.def"
        include "time.def"

        xdef ORG_CLOCK

        ; defined in clalalm.asm
        xref Exit, MoveToXb, MoveToXYbc
        xref ApplyToggles, JustifyC, JustifyN, ToggleTR, ToggleRvrs, ToggleTiny
        xref ClrScr
        xref DisplayTime, KeyJump, KeyJump0, TableJump, NavigateTable, AskDate, AskTime


.ORG_CLOCK
        ld      a, SC_ENA
        OZ      OS_Esc

        ld      b,0
        ld      hl, MainWindowDef
        oz      GN_Win

        ld      ix, -7
        add     ix, sp
        ld      sp, ix
        ld      (ix+6), 0                       ; selector position

.clk_1
        call    ClrScr

        OZ      OS_Pout
        defm    1,"3-SC", 1,"T"
        defm    1,"3@",$20+0,$20+6
        defm    "  EXIT     SET  "
        defm    1,"T",0

        call    ClkHighlight1

        ld      hl, -35                         ; reserve 38 bytes from stack,
        add     hl, sp                          ; point HL to it, DE to buf+3
        ex      de, hl                          ; first 3 bytes date value, rest is date string

        ld      hl, -38
        add     hl, sp
        ld      sp, hl

        ex      de, hl
        push    de
        OZ      GN_Gmd                          ; date into (DE)
        pop     de
        ex      de, hl                          ; read date from buf[0], write to buf[3]
        ld      a, $c0                          ; century, date suffix
        ld      b, $0f                          ; everything in full form
        OZ      GN_Pdt
        ex      af, af'

        pop     bc                              ; pop date value (keep C for GN_Gmt)
        inc     sp                              ; skip high byte
        ld      hl, 0                           ; point HL into string !! 3 * (inc hl)
        add     hl, sp
        push    bc                              ; push date value

        ex      af, af'
        jr      c, clk_6                        ; error? try to get time

        xor     a
        ld      (de), a                         ; null-terminate string
        ld      bc, 0<<8|1
        call    MoveToXYbc
        call    JustifyC

.clk_2                                          ; print weekday
        ld      a, (hl)
        inc     hl
        cp      ' '
        jr      z, clk_3
        OZ      OS_Out
        jr      clk_2

.clk_3
        OZ      GN_Nln

.clk_4                                          ; print day of month
        ld      a, (hl)
        inc     hl
        cp      ' '
        jr      z, clk_5
        OZ      OS_Out
        jr      clk_4

.clk_5                                          ; print month
        OZ      OS_Out
        ld      a, (hl)
        inc     hl
        cp      ' '
        jr      nz, clk_5

        OZ      GN_Nln
        OZ      GN_Sop                          ; print year
        call    JustifyN

.clk_6
        pop     bc                              ; remember C
        ld      hl, 35                          ; restore stack
        add     hl, sp
        ld      sp, hl
        push    bc

.clk_7
        pop     bc
        push    bc
        ld      de, 2
        OZ      GN_Gmt
        jr      z, clk_8                        ; time consistent? continue
        pop     bc
        jp      clk_1                           ; else read date again

.clk_8
        push    af                              ; push ABC
        inc     sp
        push    bc

        ld      bc, 4<<8|5
        call    MoveToXYbc
        push    ix
        ld      ix, 2
        add     ix, sp
        ld      a, $21                          ; seconds, leading xeroes
        call    DisplayTime
        pop     ix

        ld      hl, 3                           ; !! 3 * 'inc sp'
        add     hl, sp
        ld      sp, hl

.clk_9
        ld      bc, 25
        OZ      OS_Tin
        jr      c, clk_11                       ; error?

        or      a
        jr      nz, clk_10                      ; normal char?
        OZ      OS_In
        jr      c, clk_11                       ; error?

.clk_10
        ld      hl, ClkKeyCmds_tbl              ; handle using command table
        call    KeyJump
        jp      nc, clk_1                       ; no error? loop

.clk_11
        cp      RC_Susp
        jr      z, clk_7                        ; redraw seconds
        cp      RC_Time
        jr      z, clk_7                        ; ditto
        cp      RC_Fail
        jr      z, clk_9                        ; wait key
        cp      RC_Esc
        jr      nz, clk_12
        ld      a, SC_ACK                       ; !! unnecessary, already 1
        OZ      OS_Esc                          ; ack ESC

.clk_12
        jp      Exit

.ClkKeyCmds_tbl
        defb    IN_RGT
        defw    Clock_Right
        defb    IN_LFT
        defw    Clock_Left
        defb    IN_ENT
        defw    Clock_Enter
        defb    0

;       ----

; this code is written for more than two selectable values,
; that's why it's overcomplicated

.Clock_Enter
        ld      a, (ix+6)
        and     3                               ; !! and 1
        ld      hl, ClkCmds_tbl
        jp      TableJump

;       ----

.Clock_Left
        ld      a, (ix+6)                       ; toggle between 0/1  !! xor 1
        and     1
        jr      nz, clkl_1
        ld      a, 2                            ; num_choises
.clkl_1
        dec     a
.clklr_2
        ld      (ix+6), a
        push    bc
        call    ClkHighlight1
        pop     bc
        scf
        ld      a, RC_Fail
        ret

;       ----

.Clock_Right
        ld      a, (ix+6)                       ; toggle between 0/1  !! use code above
        and     1
        cp      1                               ; num_choices-1
        jr      nz, clkr_1
        ld      a, -1
.clkr_1
        inc     a
        jr      clklr_2

;       ----

.ClkHighlight1
        call    ToggleTiny
        ld      bc, 0<<8|6
        push    bc
        call    MoveToXYbc
        ld      a, $20+16
        call    ApplyToggles
        pop     bc                              ; B=0/9
        ld      a, (ix+6)
        and     1
        jr      z, chl1_1
        ld      b, 8
.chl1_1
        call    MoveToXYbc
        call    ToggleRvrs
        ld      a, $20+8
        call    ApplyToggles
        jp      ToggleTR

;       ----

.Cl_Set
        OZ      OS_Pout
        defm    1,"3@",$20+0,$20+0
        defm    1,"2C",$FE
        defm    1,"3@",$20+2,$20+1
        defm    1,"T"
        defm    1,"R"
        defm    "  NEW DATE  "
        defm    1,"3@",$20+2,$20+4
        defm    "  NEW TIME  "
        defm    1,"R"
        defm    1,"T", 0

        push    ix
        pop     de
        OZ      GN_Gmt                          ; time into buf[0]
        OZ      GN_Gmd                          ; date into buf[3]
        call    CsShowTime
        ld      hl, ClkSet_tbl
        call    NavigateTable
        jr      c, clset_1

        push    ix
        pop     hl
        ld      a, AH_AINC                      ; disable alarm list handling
        OZ      OS_Alm
        OZ      GN_Pmt                          ; set time
        inc     hl
        inc     hl
        inc     hl
        OZ      GN_Pmd                          ; set date
        ld      a, AH_ADEC
        OZ      OS_Alm                          ; enable alarm list handling

.clset_1
        push    af
        ld      a, (ix+6)                       ; select "exit" in first menu
        and     ~3
        ld      (ix+6), a
        pop     af
        ret

;       ----

.SetDate
        push    ix
        ld      bc, 3
        add     ix, bc
        ld      bc, 3<<8|2
        call    AskDate
        pop     ix
        ret

.SetTime
        ld      bc, 4<<8|5
        jp      AskTime

;       ----

.CsShowTime
        ld      bc, 4<<8|5
        call    MoveToXYbc
        ld      a, $21                          ; show seconds, leading zeroes
        jp      DisplayTime

;       ----

.ClkSet_tbl
        defw    0
        defw    SetDate
        defw    SetTime
        defw    -1

.ClkCmds_tbl
        defw    Exit
        defw    Cl_Set

.MainWindowDef
        DEFB    @10100000 | 5
        DEFW    $0032
        DEFW    $0810
        DEFW    clock_banner
.clock_banner
        defm    "CLOCK",0

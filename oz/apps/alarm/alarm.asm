; **************************************************************************************************
; Alarm popdown.
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

        Module  Alarm

        include "alarm.def"
        include "error.def"
        include "stdio.def"
        include "saverst.def"
        include "time.def"
        include "memory.def"
        include "integer.def"
        include "sysvar.def"

        xdef ORG_ALARM

        ; defined in clalalm.asm
        xref Exit, MoveToXb, MoveToXYbc
        xref ApplyToggles, JustifyC, JustifyN, ToggleTR, ToggleRvrs, ToggleTiny
        xref ClrScr, ToggleCrsr, ClrEOL, PrntString, DATE_txt
        xref DisplayTime, KeyJump, KeyJump0, TableJump, NavigateTable
        xref AskDate, AskTime, TestKeys, GetOutHandle

defc    ALM_UNSAFE_WS       = 16                ; defined in appdors.asm
defc    ALM_UNSAFE_START    = $1FFE - ALM_UNSAFE_WS

defvars ALM_UNSAFE_START
        MailDate                ds.b    3
        ubAlmActiveButton       ds.b    1
        ubSelectedAlmPos        ds.b    1
        ubNumVisibleAlarms      ds.b    1
        ubTopVisibleAlarm       ds.b    1
enddef

.ORG_ALARM
        ld      a, SC_ENA
        OZ      OS_Esc
        ld      a, AH_SUSP                      ; disable alarms while in app
        OZ      OS_Alm

.alm_1
        OZ      OS_Pout
        defm    1,"7#6",$20+20,$20+0,$20+54,$20+8,$83
        defm    1,"2C6"
        defm    1,"3-SC"
        defm    1,"R"
        defm    1,"2JC"
        defm    1,"T"
        defm    "ALARMS"
        defm    1,"R"
        defm    1,"2JN"
        defm    1,"3@",$20+0,$20+0
        defm    1,"R"
        defm    1,"2A",$20+54
        defm    1,"R"
        defm    "---DATE---     --TIME--  REASON/COMMAND"
        defm    1,"U"
        defm    13
        defm    1,"2A",$20+54
        defm    1,"U"
        defm    1,"T"
        defm    1,"6#5",$20+20,$20+2,$20+54,$20+6
        defm    1,"2C5"
        defm    1,"3-SC", 0

        xor     a
        ld      b, 7
        ld      hl, MailDate
.alm_2
        ld      (hl), a
        inc     hl
        djnz    alm_2

        ld      de, DATE_txt
        ld      hl, MailDate
        ld      bc, 3
        ld      a, SR_RPD
        OZ      OS_Sr                           ; read date
        jr      nc, alm_3                       ; ok? skip
        ld      de, MailDate
        OZ      GN_Gmd                          ; get current date

.alm_3
        call    RedrawAlarms
        ld      hl, AlmKeyCmds_tbl
        call    KeyJump0
        jr      nc, AlmExit                     ; ok? exit
        cp      RC_Draw
        jp      z, alm_1                        ; redraw

.AlmExit
        ld      a, AH_REV                       ; re-enable alars
        OZ      OS_Alm
        jp      Exit

;       ----

;       !! only low bits used in ubAlmActiveButton, remove masking

.Alm_Enter
        ld      a, (ubAlmActiveButton)
        and     3
        ld      hl, AlmButCmds_tbl
        jp      TableJump

;       ----

.Alm_Left
        ld      a, (ubAlmActiveButton)
        and     3
        jr      nz, alml_1
        ld      a, 4
.alml_1
        dec     a

.almlr_2
        ld      b, a

        cp      2                               ; prevent clr/view alarm if no alarms
        jr      c, almlr_3
        ld      a, (ubNumVisibleAlarms)
        or      a
        jr      z, almlr_4                      ; no alarms? exit

.almlr_3
        ld      a, (ubAlmActiveButton)
        and     ~3
        or      b
        ld      (ubAlmActiveButton), a
        call    AlmHighlightButton

.almlr_4
        ld      a, RC_Fail
        scf
        ret

.Alm_Right
        ld      a, (ubAlmActiveButton)
        and     3
        cp      3
        jr      nz, almr_1
        ld      a, -1
.almr_1
        inc     a
        jr      almlr_2

;       ----

.Alm_Up
        ld      a, (ubNumVisibleAlarms)
        or      a
        jr      z, almu_7                       ; no alarms? exit

        call    RemAlmHilight

        ld      a, (ubSelectedAlmPos)
        or      a
        jr      z, almu_1                       ; need scrolling?

        dec     a                               ; easy, just move up
        ld      (ubSelectedAlmPos), a
        jr      almu_6

.almu_1
        ld      a, (ubTopVisibleAlarm)
        or      a
        jr      z, almu_2                       ; we're on first alarm? go to last one

        OZ      OS_Pout
        defm    SOH,SD_UP, 0                    ; !! this causes visual bug on last line

        call    DrawAlmWdBottom
        ld      bc, 0<<8|0
        call    MoveToXYbc
        ld      a, (ubTopVisibleAlarm)          ; decrement top alarm and print it
        dec     a
        ld      (ubTopVisibleAlarm), a
        call    GetAlarmByNum
        call    PrintAlarm
        jr      almu_6

.almu_2
        xor     a
        call    GetAlarmByNum                   ; get first alarm
        ld      a, 4                            ; assume at least 5 alarms, last row
        ld      (ubSelectedAlmPos), a

;       count alarms in B

        ld      b, 1                            ; ld b,0; inc b to re-use inc
.almu_3
        push    bc
        call    GetNextAlarm
        pop     bc
        jr      c, almu_4
        inc     b
        jr      almu_3

.almu_4
        ld      a, b
        cp      5
        jr      c, almu_5
        jr      z, almu_5                       ; !! cp 6 so 'jr c' is enough

        sub     5
        ld      (ubTopVisibleAlarm), a
        call    DrawAlarms
        ld      a, 5
.almu_5
        dec     a
        ld      (ubSelectedAlmPos), a

.almu_6
        call    DrawAlmHilight
.almu_7
        scf
        ld      a, RC_Fail
        ret

;       ----

.Alm_Down
        ld      a, (ubNumVisibleAlarms)
        or      a
        jr      z, almd_4                       ; no alarms? exit

        call    RemAlmHilight

        ld      a, (ubNumVisibleAlarms)
        ld      c, a
        ld      a, (ubSelectedAlmPos)
        inc     a
        cp      c
        jr      nc, almd_1                      ; need scrolling/wrap

        ld      a, (ubSelectedAlmPos)           ; easy, just move down
        inc     a
        ld      (ubSelectedAlmPos), a
        jr      almd_3

.almd_1
        ld      a, (ubTopVisibleAlarm)
        ld      c, a
        ld      a, (ubNumVisibleAlarms)
        add     a, c
        call    GetAlarmByNum
        jr      c, almd_2                       ; no more alarms? go to top

        OZ      OS_Pout
        defm    SOH,SD_DWN, 0
        ld      a, (ubTopVisibleAlarm)
        inc     a
        ld      (ubTopVisibleAlarm), a
        ld      bc, 0<<8|4
        call    MoveToXYbc
        call    PrintAlarm
        call    DrawAlmWdBottom
        jr      almd_3

.almd_2
        xor     a                               ; move to first alarm
        ld      (ubSelectedAlmPos), a
        ld      a, (ubTopVisibleAlarm)
        or      a
        jr      z, almd_3                       ; first still visible? skip redraw

        xor     a
        ld      (ubTopVisibleAlarm), a
        call    DrawAlarms

.almd_3
        call    DrawAlmHilight
.almd_4
        scf
        ld      a, RC_Fail
        ret

;       ----

.AlmClear
        ld      a, (ubTopVisibleAlarm)
        ld      b, a
        ld      a, (ubSelectedAlmPos)
        add     a, b
        call    GetAlarmByNum                   ; get alarm to remove

        push    ix
        pop     hl
        OZ      GN_Uab                          ; unlink
        jr      c, aclr_1                       ; failed? don't free
        jr      nz, aclr_1                      ; not removed from queue? don't free
        OZ      GN_Fab                          ; free

.aclr_1
        push    af
        call    RedrawAlarms
        pop     af
        ret

;       ----

.AlmView
        ld      a, (ubTopVisibleAlarm)
        ld      b, a
        ld      a, (ubSelectedAlmPos)
        add     a, b
        call    GetAlarmByNum                   ; get alarm to view
        call    ViewSingleAlarm

.PressEsc_txt
        OZ      OS_Pout
        defm    1,"3@",$20+0,$20+5
        defm    1,"2JC"
        defm    1,"T"
        defm    "PRESS "
        defm    1,"R"
        defm    " ESC "
        defm    1,"R"
        defm    " WHEN READY"
        defm    1,"T"
        defm    1,"2JN", 0

.av_1
        OZ      OS_In
        jr      nc, av_1                        ; no error? loop
        cp      RC_Susp
        jr      z, av_1                         ; loop
        cp      RC_Draw
        jr      z, AlmView                      ; redraw
        cp      RC_Esc
        scf
        jr      nz, av_2                        ; no ESC? exit
        ld      a, SC_ACK                       ; !! already 1
        OZ      OS_Esc                          ; ack escape
        xor     a
.av_2
        ret     c                               ;!! call nc, ; ret is more clear
        jp      RedrawAlarms

;       ----

.AlmSet
        OZ      GN_Aab                          ; allocate
        jr      c, as_4                         ; error? exit

        push    bc
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind alarm in S1

        push    hl                              ; clear it
        pop     ix
        ld      b, 47
.as_1
        ld      (hl), 0
        inc     hl
        djnz    as_1

        push    ix                              ; alm_Time
        pop     de
        inc     de
        inc     de
        inc     de
        OZ      GN_Gmt                          ; get current time

        ld      de, (MailDate)
        ld      a, (MailDate+2)
        ld      (ix+alm_Date), e
        ld      (ix+7), d
        ld      (ix+8), a

        ld      (ix+alm_Flags), ALMF_BELL
        ld      (ix+alm_RepeatFlags), ALRF_NEVER

.as_2
        call    AlmSetMain
        pop     bc

        push    ix
        pop     hl
        jr      c, as_3                         ; error? free and exit

        OZ      GN_Lab                          ; put into chain
        jr      nc, as_4                        ; ok, exit
        cp      RC_Fail
        scf
        jr      nz, as_3

        ld      a, 7                            ; beep and retry
        OZ      OS_Out
        push    bc
        jr      as_2

.as_3
        push    af
        OZ      GN_Fab
        pop     af

.as_4
        jr      nc, as_5
        cp      RC_Esc
        scf
        jr      z, as_5
        OZ      GN_Err                          ; error box

        cp      RC_Quit                         ; don't bother redraw if quitting
        scf
        ret     z

.as_5
        push    af
        call    RedrawAlarms
        pop     af
        ret

;       ----

.RedrawAlarms
        call    DrawAlarms
        jp      DrawAlmHilight

;       ----

.DrawAlarms
        call    ClrScr
.dawd_1
        ld      a, (ubTopVisibleAlarm)
.dawd_2
        call    GetAlarmByNum
        ld      b, 5                            ; loop counter
        jr      nc, dawd_4
        ld      a, (ubTopVisibleAlarm)
        or      a
        jr      z, dawd_5                       ; no more above? exit
        xor     a                               ; go to top
        ld      (ubTopVisibleAlarm), a
        ld      (ubSelectedAlmPos), a
        jr      dawd_2

.dawd_3
        push    bc
        call    GetNextAlarm
        pop     bc
        jr      c, dawd_5                       ; no more? exit
.dawd_4
        call    PrintAlarm
        OZ      GN_Nln                          ; newline
        djnz    dawd_3

.dawd_5
        ld      a, 5
        sub     b
        ld      (ubNumVisibleAlarms), a
        ld      a, (ubAlmActiveButton)
        and     $fc
        ld      (ubAlmActiveButton), a

.DrawAlmWdBottom
        OZ      OS_Pout
        defm    1,"3@",$20+1,$20+5              ; !!start from column 0 with space to fix scroll_up bug
        defm    1,"2C",$fd
        defm    1,"T"
        defm    "    EXIT      SET ALARM   CLEAR ALARM   VIEW ALARM  "
        defm    1,"T" ,0

.AlmHighlightButton
        call    ToggleTiny
        ld      bc, 0<<8|5
        call    MoveToXYbc
        ld      a, $20+54
        call    ApplyToggles
        ld      c, 5
        ld      b, 1                            ; !! do this with loop, counter in b
        ld      a, (ubAlmActiveButton)          ; ld a,-13; add a,14; djnz add; ld b,a
        and     3
        jr      z, ahb_1
        ld      b, 14
        dec     a
        jr      z, ahb_1
        ld      b, 27
        dec     a
        jr      z, ahb_1
        ld      b, 40
.ahb_1
        call    MoveToXYbc
        call    ToggleRvrs
        ld      a, $20+12
        call    ApplyToggles
        jp      ToggleTR

;       ----

.GetAlarmByNum
        ld      e, a
        inc     e
        ld      ix, pAlarmList
.gabn_1
        call    GetNextAlarm
        ld      a, RC_Eof
        jr      c, gabn_x                       ; no more entries
        dec     e
        jr      nz, gabn_1
        or      a
.gabn_x
        ret

;       ----

.GetNextAlarm
        push    hl
        ld      l, (ix+alm_Next)
        ld      h, (ix+1)
        ld      b, (ix+2)
        ld      a, b
        or      l
        or      h
        scf                                     ; !! ld a,RC_Eof here to save it elsewhere
        jr      z, gna_1
        push    hl
        pop     ix                              ; return it in IX
        push    bc
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind it in S1
        or      a                               ; Fc = 0
        pop     bc
.gna_1
        pop     hl
        ret

;       ----

.PrintAlarm
        push    af
        push    bc
        ld      a, 13
        OZ      OS_Out
        call    ClrEOL

        push    ix
        pop     hl
        ld      bc, alm_Date
        add     hl, bc
        ld      de, 0
        ld      a, $a5                          ; century, use C delimeter, zero blanking, trailing space
        ld      bc, 0<<8|'/'                    ; short form, '/' delimeter
        push    ix
        call    GetOutHandle
        OZ      GN_Pdt                          ; print date
        pop     ix

        push    ix
        ld      b, 15
        call    MoveToXb
        ld      bc, alm_Time
        add     ix, bc
        ld      a, $21                          ; seconds, leading zeroes
        call    DisplayTime                     ; print time
        pop     ix

        push    ix
        pop     hl
        ld      b, 25
        call    MoveToXb
        ld      bc, alm_Reason
        add     hl, bc
        OZ      GN_Sop                          ; print reason/command

        ld      b, 50
        call    MoveToXb
        bit     ALMF_B_SHOWBELL, (ix+alm_Flags)
        jr      z, pa_1

        OZ      OS_Pout
        defm    1,"F"
        defm    SOH,SD_BLL
        defm    1,"F", 0

.pa_1
        pop     bc
        pop     af
        ret

;       ----

.AlmSetMain
        call    ViewSingleAlarm
        ld      hl, AlmSet_tbl
        jp      NavigateTable

;       ----

.ViewSingleAlarm
        call    ClrScr

        ld      bc, 0<<8|1
        call    MoveToXYbc
        call    PrintAlarm

        OZ      OS_Pout
        defm    1,"3@",$20+4,$20+3
        defm    1,"T"
        defm    1,"R"
        defm    " BELL"
        defm    1,$7c
        defm    "ALARM TYPE"
        defm    1,$7c
        defm    " REPEAT EVERY"
        defm    1,$7c
        defm    "No.OF TIMES"
        defm    1,"R"
        defm    1,"T", 0

        call    ToggleTiny
        call    AlmShowBell
        call    AlmShowType
        call    GetAlmRepeat
        call    AlmShowRepeat
        ld      h, (ix+alm_RepeatNum+1)
        ld      l, (ix+alm_RepeatNum)
        call    AlmShowNTimes
        jp      ToggleTiny

;       ----

.SetADate
        push    ix
        ld      bc, alm_Date
        add     ix, bc
        ld      bc, 0<<8|1
        call    AskDate
        pop     ix
        ret

;       ----

.SetATime
        push    ix
        ld      bc, alm_Time
        add     ix, bc
        ld      bc, 15<<8|1
        call    AskTime
        pop     ix
        ret

;       ----

.SetAReason
        call    ToggleCrsr
        push    ix
        pop     hl
        ld      de, alm_Reason
        add     hl, de
        ex      de, hl
        ld      c, 0                            ; cursor position

.sac_1
        push    bc
        ld      bc, 25<<8|1
        call    MoveToXYbc
        pop     bc

        ld      b, 23
        ld      a, 9                            ; has data, return special
        OZ      GN_Sip
        jr      nc, sac_2

        cp      RC_Susp
        jr      z, sac_1                        ; retry
        scf
        jr      sac_3                           ; else exit

.sac_2
        call    TestKeys
        jr      nz, sac_1                       ; not movement/return key? retry

.sac_3
        push    af
        call    ToggleCrsr
        pop     af
        ret

;       ----

.SetABell
        call    DrawBellHilight

.sab_1
        OZ      OS_In
        jr      c, sab_2
        or      a
        jr      nz, sab_3
        OZ      OS_In
        jr      nc, sab_3
.sab_2
        cp      RC_Susp
        jr      z, sab_1                        ; retry
        scf
        jr      sab_6

.sab_3
        cp      IN_UP
        jr      z, sab_4
        cp      IN_DWN
        jr      nz, sab_5
.sab_4
        ld      a, ALMF_BELL                    ; toggle bell and loop
        xor     (ix+alm_Flags)
        ld      (ix+alm_Flags), a
        call    AlmShowBell
        jr      sab_1

.sab_5
        call    TestKeys
        jr      nz, sab_1
.sab_6
        push    af
        call    RmBellHilight
        pop     af
        ret

;       ----

.SetAType
        call    DrawTypeHilight

.sat_1
        OZ      OS_In
        jr      c, sat_2
        or      a
        jr      nz, sat_3
        OZ      OS_In
        jr      nc, sat_3
.sat_2
        cp      RC_Susp
        jr      z, sat_1                        ; retry
        scf
        jr      sat_6

.sat_3
        cp      IN_UP
        jr      z, sat_4
        cp      IN_DWN
        jr      nz, sat_5
.sat_4
        ld      a, ALMF_EXECUTE                 ; toggle execute and loop
        xor     (ix+alm_Flags)
        ld      (ix+alm_Flags), a
        call    AlmShowType
        jr      sat_1

.sat_5
        call    TestKeys
        jr      nz, sat_1                       ; retry

.sat_6
        push    af
        call    RmTypeHilight
        pop     af
        ret

;       ----

.SetARepeat
        call    DrawRepeatHilight
        call    GetAlmRepeat

.sar_1
        OZ      OS_In
        jr      c, sar_2
        or      a
        jr      nz, sar_3
        OZ      OS_In
        jr      nc, sar_3
.sar_2
        cp      RC_Susp
        jr      z, sar_1                        ; retry
        scf
        jp      sar_17                          ; exit

.sar_3
        cp      IN_DWN
        jr      nz, sar_4

        ld      a, b                            ; BHL--
        ld      de, 1
        sbc     hl, de
        sbc     a, 0
        ld      b, a
        or      h
        or      l
        jr      nz, sar_10                      ; value >0
        jr      sar_6                           ; else decrement unit

.sar_4
        cp      IN_UP
        jr      nz, sar_5

        bit     ALRF_B_NEVER, (ix+alm_RepeatFlags)
        jr      nz, sar_8                       ; increment unit

        ld      a, b                            ; BHL++
        ld      de, 1
        add     hl, de
        adc     a, 0
        ld      b, a

        ld      a, (ix+alm_RepeatFlags)         ; limit sec/min to 59
        and     3                               ; ALRF_SEC|ALRF_MIN
        jr      z, sar_10                       ; neither? skip
        ld      a, l
        cp      60
        jr      c, sar_10
        jr      sar_8                           ; increment unit

.sar_5
        cp      IN_SDWN
        jr      nz, sar_7
.sar_6
        ld      a, (ix+alm_RepeatFlags)         ; decrement unit
        rrca
        jr      sar_9

.sar_7
        cp      IN_SUP
        jr      nz, sar_11
.sar_8
        ld      a, (ix+alm_RepeatFlags)         ; increment unit
        rlca

.sar_9
        ld      hl, 1                           ; BHL=1
        ld      b, 0
        ld      (ix+alm_RepeatFlags), a

.sar_10
        call    AlmShowRepeat                   ; show new value and retry
        jr      sar_1

.sar_11
        call    TestKeys
        jr      nz, sar_1                       ; retry

        push    af
        ld      a, (ix+alm_RepeatFlags)
        bit     ALRF_B_NEVER, a
        jr      nz, sar_16                      ; exit

        bit     ALRF_B_YEAR, a
        jr      nz, sar_15                      ; set years
        bit     ALRF_B_MONTH, a
        jr      nz, sar_15                      ; set months
        bit     ALRF_B_DAY, a
        jr      nz, sar_15                      ; set days
        bit     ALRF_B_WEEK, a
        jr      z, sar_12                       ; set centiseconds

        ld      c, 0                            ; multiply by 7 to handle weeks as days
        ld      de, 7
        OZ      GN_M24
        jr      sar_15

.sar_12

;       !! multiply by 100/6000/360000 - it's shorter

        ld      c, 0
        ld      de, 100
        OZ      GN_M24                          ; BHL*=CDE
        ld      a, (ix+alm_RepeatFlags)
        bit     ALRF_B_SEC, a
        jr      nz, sar_14
        bit     ALRF_B_MIN, a
        jr      z, sar_13
        ld      c, 0
        ld      de, 60
        OZ      GN_M24                          ; BHL*=CDE
        jr      sar_14
.sar_13
        ld      c, 0
        ld      de, 3600
        OZ      GN_M24                          ; BHL*=CDE

.sar_14
        ld      (ix+alm_RepeatTime), l
        ld      (ix+alm_RepeatTime+1), h
        ld      (ix+alm_RepeatTime+2), b
        jr      sar_16

.sar_15
        ld      (ix+alm_RepeatDays), l
        ld      (ix+alm_RepeatDays+1), h
        ld      (ix+alm_RepeatDays+2), b

.sar_16
        pop     af                              ; !! dbf OP_LDAn to skip push below
.sar_17
        push    af
        call    RmRepeatHilight
        pop     af
        ret

;       ----

.GetAlmRepeat
        xor     a                               ; !! ld hl,1; ld b,h
        ld      b, a
        ld      h, a
        ld      l, 1

        ld      a, (ix+alm_RepeatFlags)
        bit     ALRF_B_NEVER, a
        jr      nz, gar_2                       ; never? use 1

        and     7                               ; ALRF_SEC|ALRF_MIN|ALRF_HOUR
        jr      z, gar_1

        ld      l, (ix+alm_RepeatTime)
        ld      h, (ix+alm_RepeatTime+1)
        ld      b, (ix+alm_RepeatTime+2)

;       !! divide by 100/6000/360000 - it's shorter

        ld      c, 0
        ld      de, 100
        OZ      GN_D24                          ; seconds
        bit     ALRF_B_SEC, (ix+alm_RepeatFlags)
        jr      nz, gar_2

        ld      c, 0
        ld      de, 60
        OZ      GN_D24                          ; minutes
        bit     ALRF_B_MIN, (ix+alm_RepeatFlags)
        jr      nz, gar_2

        ld      c, 0
        ld      de, 60
        OZ      GN_D24                          ; hours
        jr      gar_2

.gar_1
        ld      l, (ix+alm_RepeatDays)
        ld      h, (ix+alm_RepeatDays+1)
        ld      b, (ix+alm_RepeatDays+2)

        ld      a, (ix+alm_RepeatFlags)
        bit     ALRF_B_DAY, a                   ; !! is this unnecessary? only needed if
        jr      nz, gar_2                       ; !! both day and week can be set simultaneously

        bit     ALRF_B_WEEK, a
        jr      z, gar_2
        ld      de, 7
        ld      c, 0
        OZ      GN_D24                          ; BHL/=7

.gar_2
        ret

;       ----

.SetATimes
        call    DrawTimesHilight
        ld      l, (ix+alm_RepeatNum)
        ld      h, (ix+alm_RepeatNum+1)

.san_1
        OZ      OS_In
        jr      c, san_2
        or      a
        jr      nz, san_3
        OZ      OS_In
        jr      nc, san_3
.san_2
        cp      RC_Susp
        jr      z, san_1                        ; retry
        scf
        jr      san_12

.san_3
        cp      IN_DWN
        jr      nz, san_4
        dec     hl
        jr      san_5

.san_4
        cp      IN_UP
        jr      nz, san_6
        inc     hl

.san_5
        call    AlmShowNTimes                   ; show value and loop
        jr      san_1

.san_6
        cp      IN_SDWN
        jr      nz, san_7
        ld      de, -10
        jr      san_10

.san_7
        cp      IN_DDWN
        jr      nz, san_8
        ld      de, -100
        jr      san_10

.san_8
        cp      IN_SUP
        jr      nz, san_9
        ld      de, 10
        jr      san_10

.san_9
        cp      IN_DUP
        jr      nz, san_11
        ld      de, 100

.san_10
        add     hl, de
        jr      san_5

.san_11
        call    TestKeys
        jr      nz, san_1                       ; retry

        ld      (ix+alm_RepeatNum), l
        ld      (ix+alm_RepeatNum+1), h

.san_12
        push    af
        call    RmTimesHilight
        pop     af
        ret

;       ----

.AlmShowBell
        ld      b, 4
        ld      a, (ix+alm_Flags)
        ld      hl, Off_txt
        bit     ALMF_B_BELL, a
        jr      z, almt_1
        ld      hl, On_txt
        jr      almt_1

;       ----

.AlmShowType
        ld      b, 10
        ld      a, (ix+alm_Flags)
        ld      hl, Alarm_txt
        bit     ALMF_B_EXECUTE, a
        jr      z, almt_1
        ld      hl, Execute_txt

.almt_1
        ld      c, 4
        push    hl
        call    MoveToXYbc
        pop     hl
        OZ      GN_Sop
        ret

;       ----

.AlmShowRepeat
        push    bc
        push    hl
        ld      bc, 21<<8|4
        push    bc
        call    MoveToXYbc

        ld      b, 13
.almsr_1
        ld      a, ' '
        OZ      OS_Out
        djnz    almsr_1

        pop     bc
        call    MoveToXYbc
        bit     ALRF_B_NEVER, (ix+alm_RepeatFlags)
        jr      nz, almsr_2                     ; don't show value

        pop     bc
        push    bc
        push    ix
        call    GetOutHandle
        ld      de, 0
        ld      hl, 2
        ld      a, $54                          ; 5 chars, trailing space
        OZ      GN_Pdn                          ; print integer
        pop     ix

.almsr_2
        ld      hl, RepeatUnits_tbl             ; !! ld hl,tbl-2; inc hl; inc hl to re-use inc
        ld      a, (ix+alm_RepeatFlags)
.almsr_3
        rrca
        jr      c, almsr_4
        inc     hl
        inc     hl
        jr      almsr_3

.almsr_4
        ld      a, (hl)                         ; get string pointer into HL and print
        inc     hl
        ld      h, (hl)
        ld      l, a
        OZ      GN_Sop

        pop     hl
        bit     ALRF_B_NEVER, (ix+alm_RepeatFlags)
        jr      nz, almsr_7                     ; exit

        ld      a, h                            ; add either ' ' or 'S'
        or      a
        jr      nz, almsr_5
        ld      a, l
        dec     a
        jr      z, almsr_6
.almsr_5
        ld      a, 'S'-' '
.almsr_6
        add     a, ' '
        OZ      OS_Out

.almsr_7
        pop     bc
        ret

;       ----

.AlmShowNTimes
        push    hl
        ld      bc, 35<<8|4
        call    MoveToXYbc
        pop     hl

        push    hl
        ld      a, h
        or      l
        jr      nz, almnt_1
        ld      hl, Never_txt                   ; 0? Never
        jr      almnt_2

.almnt_1
        ld      a, h                            ; !! ld a,h; and a,l; cpl; jr nz
        cp      $ff
        jr      nz, almnt_3
        ld      a, l
        cp      $ff
        jr      nz, almnt_3
        ld      hl, Forever_txt                 ; -1? forever
.almnt_2
        OZ      GN_Sop
        jr      almnt_4                         ; exit

.almnt_3
        pop     bc
        push    bc
        push    ix
        ld      hl, 2
        ld      de, 0
        call    GetOutHandle
        ld      a, $a4                          ; 10 chars, trailing space
        OZ      GN_Pdn                          ; print num
        pop     ix

.almnt_4
        pop     hl
        ret

;       ----

;       !! draw/remove hilight could be joined

.DrawBellHilight
        ld      b, 4
        ld      a, $20+5
        jr      DrawHilight

.DrawTypeHilight
        ld      b, 10
        ld      a, $20+10
        jr      DrawHilight

.DrawRepeatHilight
        ld      b, 21
        ld      a, $20+13
        jr      DrawHilight

.DrawTimesHilight
        ld      b, 35
        ld      a, $20+11

.DrawHilight
        push    af
        ld      c, 4
        call    MoveToXYbc
        call    ToggleTR
        pop     af
        jp      ApplyToggles

;       ----

.RmBellHilight
        ld      b, 4
        ld      a, $20+5
        jr      RemoveHiligh

.RmTypeHilight
        ld      b, 10
        ld      a, $20+10
        jr      RemoveHiligh

.RmRepeatHilight
        ld      b, 21
        ld      a, $20+13
        jr      RemoveHiligh

.RmTimesHilight
        ld      b, 35
        ld      a, $20+11

.RemoveHiligh
        push    af
        ld      c, 4
        call    MoveToXYbc
        call    ToggleTR
        call    ToggleTiny
        pop     af
        call    ApplyToggles
        jp      ToggleTiny

;       ----

.DrawAlmHilight
        push    af
        call    ToggleRvrs
        call    RemAlmHilight
        call    ToggleRvrs
        pop     af
        ret

;       ----

.RemAlmHilight
        push    af
        push    bc
        ld      a, (ubNumVisibleAlarms)
        or      a
        jr      z, rah_2                        ; no alarms? exit

        ld      c, a                            ; a=min(ubSelectedAlmPos,ubNumVisibleAlarms-1)
        ld      a, (ubSelectedAlmPos)
        cp      c
        jr      c, rah_1
        ld      a, c
        dec     a
        ld      (ubSelectedAlmPos), a

.rah_1
        ld      c, a
        ld      b, 0
        call    MoveToXYbc
        ld      a, $20+49
        call    ApplyToggles

.rah_2
        pop     bc
        pop     af
        ret

;       ----

.AlmKeyCmds_tbl
        defb    IN_RGT
        defw    Alm_Right
        defb    IN_LFT
        defw    Alm_Left
        defb    IN_UP
        defw    Alm_Up
        defb    IN_DWN
        defw    Alm_Down
        defb    IN_ENT
        defw    Alm_Enter
        defb    0

.AlmSet_tbl
        defw    0
        defw    SetADate
        defw    SetATime
        defw    SetAReason
        defw    SetABell
        defw    SetAType
        defw    SetARepeat
        defw    SetATimes
        defw    -1

.RepeatUnits_tbl
        defw    Sec_txt
        defw    Min_txt
        defw    Hour_txt
        defw    Day_txt
        defw    Week_txt
        defw    Month_txt
        defw    Year_txt
        defw    Never_txt

.AlmButCmds_tbl
        defw    AlmExit
        defw    AlmSet
        defw    AlmClear
        defw    AlmView

.On_txt
        defm    "  ON ",0
.Off_txt
        defm    " OFF ",0
.Alarm_txt
        defm    "  ALARM   ",0
.Execute_txt
        defm    "  EXECUTE ",0
.Never_txt
        defm    "   NEVER   ",0
.Forever_txt
        defm    "  FOREVER  ",0
.Sec_txt
        defm    "SEC",0
.Min_txt
        defm    "MIN",0
.Hour_txt
        defm    "HOUR",0
.Day_txt
        defm    "DAY",0
.Week_txt
        defm    "WEEK",0
.Month_txt
        defm    "MONTH",0
.Year_txt
        defm    "YEAR",0

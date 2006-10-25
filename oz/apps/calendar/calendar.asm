; **************************************************************************************************
; Calendar popdown (Bank 1, addressed for segment 3).
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

        Module  Calendar


        include "alarm.def"
        include "error.def"
        include "integer.def"
        include "memory.def"
        include "saverst.def"
        include "stdio.def"
        include "time.def"

        include "clcalalm.def"


        xdef CalendarMain

        ; defined in clalalm.asm
        xref Exit, MoveToXb, MoveToXYbc
        xref ApplyToggles, JustifyC, JustifyN, ToggleTR, ToggleRvrs, ToggleTiny
        xref ClrScr, ToggleCrsr, ClrEOL, PrntString, DATE_txt
        xref DisplayTime, KeyJump, KeyJump0, TableJump, tj_2, GetTableEntry, NavigateTable
        xref AskDate, AskTime, TestKeys, GetOutHandle


.CalendarMain
        ld      a, SC_ENA
        OZ      OS_Esc

        xor     a
        ld      hl, CurrentDay
        ld      b, 33
.cal_1
        ld      (hl), a
        inc     hl
        djnz    cal_1

        ld      hl, CalWindow_txt
        OZ      GN_Sop

        ld      de, DATE_txt
        ld      bc, 6
        ld      hl, CurrentDay
        ld      a, SR_RPD
        OZ      OS_Sr                           ; read date
        jr      c, cal_2                        ; no date in mail, use current

        ld      hl, (OrigDiaryEntry)
        ld      a, (OrigDiaryEntry+2)
        ld      b, a
        ld      c, 0
        ld      d, c
        ld      e, c
        OZ      GN_Xnx
        call    PutDiaryList
        call    nz, PutNxtDiaryDay
        ld      bc, (CurrentDay)
        ld      a, (CurrentDay+2)
        call    InitMonth
        jr      nc, cal_3

.cal_2
        ld      de, 2
        OZ      GN_Gmd                          ; get current machine date in internal format
        call    InitMonth
        jr      nc, cal_3

        ld      a, $25                          ; internal format for ???
        ld      bc, $55CD
        call    InitMonth

.cal_3
        ld      (CurrentDay+2), a
        ld      (CurrentDay), bc
        ld      de, DATE_txt
        ld      bc, 3
        ld      hl, CurrentDay
        ld      a, SR_WPD
        OZ      OS_Sr                           ; put date into mail

        ld      a, (CurrentDay+2)
        ld      bc, (CurrentDay)
        call    DrawMonth
        call    HighlightDay

        ld      hl, CalKeyCmds_tbl
        call    KeyJump0
        jr      nc, cal_4

        cp      RC_Draw
        jp      z, CalendarMain                 ; redraw

.cal_4
        jp      Exit

.CalKeyCmds_tbl
        defb    IN_ENT
        defw    Cal_Enter
        defb    IN_SUP
        defw    Cal_SUp
        defb    IN_SDWN
        defw    Cal_SDown
        defb    IN_DUP
        defw    Cal_DUp
        defb    IN_DDWN
        defw    Cal_DDown
        defb    IN_DWN
        defw    Cal_Down
        defb    IN_LFT
        defw    Cal_Left
        defb    IN_UP
        defw    Cal_Up
        defb    IN_RGT
        defw    Cal_Right
        defb    IN_ARGT
        defw    Cal_ARight
        defb    IN_ALFT
        defw    Cal_ALeft
        defb    0

;       ----

;       !! make this generic -1/1/-7/7 day change for left/right/up/down

.Cal_Right
        ld      a, (ubNMonthDays)
        ld      c, a
        ld      a, d
        cp      c
        jr      c, calr_1                       ; not last of month? skip

        call    NextMonth
        call    nc, InitMonth
        call    nc, DrawMonth
        jr      c, calr_2
        xor     a                               ; Fc=0

.calr_1
        inc     a
        ld      d, a
        call    c, LowlightDay                  ; remove highlight if no month change
        ld      bc, 1
        call    AddCurDay
        call    SetDayHighlight
.calr_2
        or      a
        ret

;       ----

.Cal_Left
        ld      a, d
        dec     a
        jr      nz, call_1                      ; not first of month? skip

        call    PrevMonth
        call    nc, InitMonth
        call    nc, DrawMonth
        jr      c, call_2
        xor     a                               ; Fz=1
        ld      a, (ubNMonthDays)

.call_1
        ld      d, a
        call    nz, LowlightDay                 ; remove highlight if no month change
        ld      bc, 1
        call    SubCurDay
        call    SetDayHighlight
.call_2
        or      a
        ret

;       ----

.Cal_Down
        ld      a, (ubNMonthDays)
        inc     a
        ld      c, a
        ld      a, d
        add     a, 7
        cp      c
        jr      c, cald_1                       ; can add week inside month? skip

        ld      a, c                            ; keep day of week
        dec     a
        sub     d
        ld      d, a
        call    NextMonth
        call    nc, InitMonth
        call    nc, DrawMonth
        jr      c, cald_2
        ld      a, 7
        sub     d
        or      a                               ; Fc=0

.cald_1
        ld      d, a
        call    c, LowlightDay                  ; remove highlight if no month change
        ld      bc, 7
        call    AddCurDay
        call    SetDayHighlight
.cald_2
        ld      a, (ubDay)
        ld      d, a
        or      a
        ret

;       ----

.Cal_Up
        ld      a, d
        cp      8
        jr      nc, calu_1                      ; can go back week inside month? skip

        call    PrevMonth
        call    nc, InitMonth
        call    nc, DrawMonth
        jr      c, calu_2
        ld      a, (ubNMonthDays)
        add     a, d
        scf

.calu_1
        call    nc, LowlightDay                 ; remove highlight if no month change
        sub     7
        ld      d, a
        ld      bc, 7
        call    SubCurDay
        call    SetDayHighlight
.calu_2
        or      a
        ret

;       ----

.Cal_SDown
        call    NextMonth
        jr      Cal_SUpDn

.Cal_SUp
        call    PrevMonth

.Cal_SUpDn
        call    nc, InitMonth
        jr      c, calsud_2
        ld      (CurrentDay), bc
        ld      (CurrentDay+2), a
        call    DrawMonth
        ld      a, (ubNMonthDays)               ; day=max(day,nDays)
        cp      d
        jr      nc, calsud_1
        ld      d, a
.calsud_1
        ld      c, d
        dec     c
        ld      b, 0
        call    AddCurDay
        call    SetDayHighlight

.calsud_2
        or      a
        ret

;       ----

.Cal_DDown
        push    de
        ld      hl, (swYear)
        ld      de, 1                           ; !! inc hl
        add     hl, de
        jr      caldud_1

.Cal_DUp
        push    de
        ld      hl, (swYear)
        ld      de, -1                          ; !! dec hl
        add     hl, de

.caldud_1
        ex      de, hl
        ld      a, (ubMonth)
        ld      b, a
        ld      c, 1                            ; 1st of month
        OZ      GN_Dei                          ; convert from zoned format to internal format
        pop     de
        jr      Cal_SUpDn

;       ----

.Cal_Enter
        ld      ix, -3
        add     ix, sp
        ld      sp, ix
        call    LowlightDay
        ld      bc, 11<<8|7
        call    MoveToXYbc
        ld      hl, LookFor_txt
        OZ      GN_Sop

        push    ix
        pop     de
        OZ      GN_Gmd                          ; get date into buf[0]

.cale_1
        ld      bc, 22<<8|7
        call    AskDate
        jr      nc, cale_2
        call    tj_2
        jr      cale_3

.cale_2
        ld      c, (ix+0)
        ld      b, (ix+1)
        ld      a, (ix+2)
        call    MoveToDay
        jr      c, cale_1
.cale_3
        push    af
        ld      bc, 11<<8|7
        call    MoveToXYbc
        call    ClrEOL
        call    HighlightDay
        pop     af
        inc     sp
        inc     sp
        inc     sp
        ret

;       ----

.PrevMonth
        push    de
        ld      a, (ubMonth)
        ld      de, (swYear)
        dec     a
        jr      nz, nxm_1                       ; month ok?

        ex      de, hl                          ; decrement year  !! dec de
        ld      de, -1
        add     hl, de
        ex      de, hl
        ld      a, 12
        jr      nxm_1

;       ----

.NextMonth
        push    de
        ld      a, (ubMonth)
        ld      de, (swYear)
        inc     a
        cp      13
        jr      nz, nxm_1                       ; month ok?

        ex      de, hl                          ; increment year  !! inc de
        ld      de, 1
        add     hl, de
        ex      de, hl
        ld      a, 1

.nxm_1
        ld      b, a                            ; month
        ld      c, 1                            ; 1st of month
        OZ      GN_Dei                          ; into internal format
        pop     de
        ret

;       ----

.InitMonth
        push    de
        push    bc
        ld      l, a
        OZ      GN_Die                          ; into zoned format
        jr      c, im_x
        ld      h, c                            ; remember weekday
        ld      c, 1                            ; and calc for 1st of month
        OZ      GN_Dei                          ; into internal format
        jr      c, im_x
        ld      (MonthStart), bc
        ld      (MonthStart+2), a
        OZ      GN_Die                          ; into zoned format
        jr      c, im_x
        ld      (swYear), de
        ld      (ubNMonthDays), a
        ld      a, b
        ld      (ubMonth), a
        ld      a, h
        and     $1F
        ld      (ubDay), a
        ld      a, c
        and     $e0
        rla
        rla
        rla
        rla
        ld      (ubWeekday), a
        or      a
.im_x
        ld      a, l
        pop     bc
        pop     de
        ret

;       ----

.MoveToDay
        call    InitMonth
        jr      c, mtd_5                        ; !! ret c
        ld      e, a
        push    de
        push    hl
        push    bc
        ld      hl, (DrawnMonthStart)
        ld      a, (DrawnMonthStart+2)
        or      a
        sbc     hl, bc
        sbc     a, e
        jr      c, mtd_1                        ; past drawn month? check next  !! why?

        or      h
        or      l
        jr      z, mtd_nodraw                   ; same month? no redraw
        jr      mtd_redraw

.mtd_1
        ld      hl, (NextMonthStart)
        ld      a, (NextMonthStart+2)
        or      a
        sbc     hl, bc
        sbc     a, e
        jr      c, mtd_redraw                   ; past next month? redraw

        or      h
        or      l
        jr      z, mtd_redraw                   ; next month? redraw

.mtd_nodraw
        or      a                               ; !! or OP_SCF, use operand for mtd_redraw
        jr      mtd_4
.mtd_redraw
        scf
.mtd_4
        pop     bc
        pop     hl
        pop     de
        ld      a, e
        ld      (CurrentDay+2), a
        ld      (CurrentDay), bc
        call    c, DrawMonth
        or      a
.mtd_5
        ret

;       ----

.DrawMonth
        push    de
        call    ClrScr
        call    ToggleTiny

        ld      hl, (MonthStart)
        ld      a, (MonthStart+2)
        ld      (DrawnMonthStart), hl
        ld      (DrawnMonthStart+2), a
        ld      (SearchDay), hl
        ld      (SearchDay+2), a

        push    af                              ; BC=ubNMonthDays
        ld      a, (ubNMonthDays)               ; !! ld bc,ubNMonthDays-1; ld c,0
        ld      c, a
        ld      b, 0
        pop     af
        add     hl, bc
        adc     a, 0
        ld      (NextMonthStart+2), a
        ld      (NextMonthStart), hl
        call    FindPrevDiaryEntry

        ld      a, (ubMonth)
        dec     a
        ld      hl, Months_tbl
        call    GetTableEntry
        call    JustifyC
        OZ      GN_Sop                          ; printh month name
        xor     a
        ld      de, (swYear)

        push    de
        bit     7, d
        jr      z, dm_1                         ; AD? skip
        ld      h, a                            ; DE=-DE
        ld      l, a
        sbc     hl, de
        ex      de, hl
.dm_1
        ld      b, d
        ld      c, e
        ex      de, hl                          ; if year<100 force 4 digits
        ld      de, 100
        xor     a
        sbc     hl, de
        jr      nc, dm_2
        ld      a, $40                          ; width=4
.dm_2
        ld      d, 0                            ; !! d already 0 from above
        ld      e, d
        push    af
        call    GetOutHandle
        pop     af
        or      3                               ; leading space, leading zeroes
        ld      hl, 2
        OZ      GN_Pdn                          ; print to screen
        pop     de

        bit     7, d
        jr      z, dm_3                         ; AD? skip
        ld      hl, BC_txt
        OZ      GN_Sop

.dm_3
        call    JustifyN
        call    ToggleTiny
        ld      bc, 0                           ; reverse first line
        call    MoveToXYbc
        call    ToggleRvrs
        ld      a, $20+35
        call    ApplyToggles
        call    ToggleRvrs

        ld      hl, CalendarHdr_txt
        OZ      GN_Sop

;       draw day numbers

        ld      a, (ubNMonthDays)
        ld      d, a
        ld      a, (ubWeekday)
        ld      e, a
        call    MoveToDayXY

        ld      c, 0
.dm_4
        ld      a, c
        cp      d
        jr      z, dm_6                         ; last day done? exit
        inc     c
        call    DrawMonthDay

        ld      a, e                            ; wrap E for each week
        cp      7
        jr      nz, dm_5
        ld      e, 0
.dm_5
        inc     e
        jr      dm_4

.dm_6
        pop     de
        ret

;       ----

.Cal_ARight
        call    SetSearchDay
        call    FindNextDiaryEntry
        jr      calalr_1

.Cal_ALeft
        call    SetSearchDay
        call    FindPrevDiaryEntry

.calalr_1
        jr      c, calalr_2                     ; no more diary entries? exit

        call    LowlightDay
        ld      a, (NextDiaryDay+2)
        ld      bc, (NextDiaryDay)
        call    MoveToDay
        call    HighlightDay

.calalr_2
        or      a
        ret

;       ----

.SetSearchDay
        ld      hl, (CurrentDay)
        ld      a, (CurrentDay+2)
        ld      (SearchDay), hl
        ld      (SearchDay+2), a
        ret

;       ----

.FindNextDiaryEntry
        push    de
        call    GetDiaryList

;       go backward until before search day

        call    ChgSearchDir

.nde_1
        jr      z, nde_2                        ; no more entries? go forward
        call    CpSearchDate
        jr      c, nde_2                        ; before search day? go forward
        call    FollowDiaryList
        jr      nde_1

;       go forward until past search day

.nde_2
        call    ChgSearchDir
.nde_3
        scf
        jr      z, de_x                         ; no more entries? exit
        call    CpSearchDate
        jr      c, nde_4                        ; not past search day? continue
        jr      nz, de_x                        ; not search day? found
.nde_4
        OZ      GN_Xnx
        jr      nde_3

;       ----

.FindPrevDiaryEntry
        push    de
        call    GetDiaryList

;       go forward until past search day

.pde_1
        jr      z, pde_2                        ; no more entries? go backward
        call    CpSearchDate
        jr      nc, pde_2                       ; past search day? go backward
        OZ      GN_Xnx
        jr      pde_1

;       go bacward until before search day

.pde_2
        call    ChgSearchDir
.pde_3
        scf
        jr      z, pde_4                        ; no more entries? exit
        call    CpSearchDate
        ccf
        jr      nc, pde_4
        call    FollowDiaryList
        jr      pde_3

.pde_4
        push    af
        call    nc, FollowDiaryList
        call    ChgSearchDir
        pop     af
.de_x
        call    PutDiaryList
        pop     de
        ret

;       ----

.PutDiaryList
        ld      (DiaryEntry), de
        ld      a, c
        ld      (DiaryEntry+2), a
        ld      (NextDiaryEntry), hl
        ld      a, b
        ld      (NextDiaryEntry+2), a
        ret

;       ----

;       Fz=1 if BHL is null

.GetDiaryList
        ld      de, (DiaryEntry)
        ld      a, (DiaryEntry+2)
        ld      c, a
        ld      hl, (NextDiaryEntry)
        ld      a, (NextDiaryEntry+2)
        ld      b, a
        or      h
        or      l
        ret

;       ----

;       Fz=1 if BHL=0 or BHL=OrigDiaryEntry


.ChgSearchDir
        ld      a, c                            ; swap BHL with CDE
        ld      c, b
        ld      b, a
        ex      de, hl
        or      h
        or      l
        ret     z                               ; BHL is null? return

;       Fz=1 if BHL=OrigDiaryEntry

.loc_EDF7
        ld      a, (OrigDiaryEntry+2)
        cp      b
        ret     nz
        ld      a, (OrigDiaryEntry+1)
        cp      h
        ret     nz
        ld      a, (OrigDiaryEntry)
        cp      l
        ret

;       ----

.FollowDiaryList
        OZ      GN_Xnx
        ret     z
        jr      loc_EDF7

;       ----

;OUT:   Fz=1 if match
;       Fc=1 if NextDiaryDay<SearchDay

.CpSearchDate
        call    PutNxtDiaryDay
        push    hl
        ld      hl, SearchDay+2
        ld      a, (NextDiaryDay+2)
        cp      (hl)
        jr      c, csd_1                        ; !! unnecessary
        jr      nz, csd_1
        dec     hl
        ld      a, (NextDiaryDay+1)
        cp      (hl)
        jr      c, csd_1                        ; !! unnecessary
        jr      nz, csd_1
        dec     hl
        ld      a, (NextDiaryDay)
        cp      (hl)
.csd_1
        pop     hl
        ret

;       ----

.PutNxtDiaryDay
        push    hl
        inc     hl
        inc     hl
        inc     hl
        OZ      GN_Rbe
        ld      (NextDiaryDay), a
        inc     hl
        OZ      GN_Rbe
        ld      (NextDiaryDay+1), a
        inc     hl
        OZ      GN_Rbe
        ld      (NextDiaryDay+2), a
        or      a
        pop     hl
        ret

;       ----

;       !! can combine these - use signed BC and 'add hl,bc; adc a,c'

.AddCurDay
        ld      hl, (CurrentDay)
        ld      a, (CurrentDay+2)
        add     hl, bc
        adc     a, 0
        jr      SetCurDay

.SubCurDay
        ld      hl, (CurrentDay)
        ld      a, (CurrentDay+2)
        or      a
        sbc     hl, bc
        sbc     a, 0

.SetCurDay
        ld      (CurrentDay), hl
        ld      (CurrentDay+2), a
        ret

;       ----

.SetDayHighlight
        ld      a, d
        ld      (ubDay), a

;       ----

.HighlightDay
        ld      a, (ubDay)
        ld      d, a
        ld      a, (ubWeekday)
        dec     a
        add     a, d
        call    MoveToDayXY
        call    ToggleRvrs
        ld      a, $20+5
        call    ApplyToggles
        jp      ToggleRvrs

;       ----

.LowlightDay
        push    af
        ld      a, (ubDay)
        ld      c, a
        ld      a, (ubWeekday)
        dec     a
        add     a, c
        call    MoveToDayXY
        ld      a, $20+5
        call    ApplyToggles
        pop     af
        ret

;       ----

.DrawMonthDay
        push    de
        push    bc
        ld      a, ' '
        OZ      OS_Out
.dmd_1
        ld      hl, (DrawnMonthStart)
        dec     c
        ld      b, 0
        add     hl, bc
        ld      a, (DrawnMonthStart+2)
        adc     a, 0
        inc     c
        push    af
        ld      de, (NextDiaryDay)
        ld      a, (NextDiaryDay+2)
        ld      b, a
        pop     af
        or      a
        sbc     hl, de
        sbc     a, b
        jr      c, dmd_3                        ; below next diary day? skip
        or      h
        or      l
        jr      nz, dmd_2                       ; above diary day? update it
        ld      hl, BulletR_txt
        OZ      GN_Sop                          ; write string to std. output
        jr      dmd_4
.dmd_2
        push    bc
        call    GetDiaryList
        OZ      GN_Xnx                          ; follow chain forward
        call    nc, PutDiaryList
        call    nc, PutNxtDiaryDay
        pop     bc
        jr      nc, dmd_1                       ; no error? compare again
.dmd_3
        ld      a, ' '
        OZ      OS_Out
.dmd_4
        pop     bc
        ld      b, 0
        ld      d, b
        ld      e, b
        ld      a, $24                          ; width=2, trailing space
        ld      hl, 2
        OZ      GN_Pdn                          ; print number
        pop     de
        ret
.BulletR_txt
        defm    SOH,SD_BRGT, 0

;       ----

.MoveToDayXY
        push    bc
        ld      c, 2                            ; start at row 2
        dec     a
.mdxy_1
        sub     7
        jr      c, mdxy_2
        inc     c                               ; next row
        jr      mdxy_1
.mdxy_2
        add     a, 7                            ; make it positive
        ld      b, a                            ; B=5*A
        add     a, a
        add     a, a
        add     a, b
        ld      b, a
        call    MoveToXYbc
        pop     bc
        ret

;       ----

.CalendarHdr_txt
        defm    1,"T"
        defm    1,"U"
if KBDK
        defm    " MAN  TIR  ONS  TOR  FRE  L",$F8,"R  S",$F8,"N "
ENDIF

if KBFI
        defm    "  MA   TI   KE   TO   PE   LA   SU "
ENDIF

if KBSE
        defm    " M",$C5,"N  TIS  ONS  TOR  FRE  L",$D6,"R  S",$D6,"N "
ENDIF

if KBFR
        defm    " LUN  MAR  MER  JEU  VEN  SAM  DIM "
ENDIF

if !KBFI & !KBSE & !KBFR & !KBDK
        ; default UK
        defm    " MON  TUE  WED  THU  FRI  SAT  SUN "
ENDIF
        defm    1,"T"
        defm    1,"U"
        defm    13, 10, 0

.BC_txt         defm    " BC",0
.LookFor_txt    defm    "Look for : ",0

.Months_tbl
        defw    jan_txt, feb_txt, mar_txt, apr_txt
        defw    may_txt, jun_txt, jul_txt, aug_txt
        defw    sep_txt, oct_txt, nov_txt, dec_txt

if KBDK
.jan_txt        defm    "JANUAR",0
.feb_txt        defm    "FEBRUAR",0
.mar_txt        defm    "MARTS",0
.apr_txt        defm    "APRIL",0
.may_txt        defm    "MAJ",0
.jun_txt        defm    "JUNI",0
.jul_txt        defm    "JULI",0
.aug_txt        defm    "AUGUST",0
.sep_txt        defm    "SEPTEMBER",0
.oct_txt        defm    "OKTOBER",0
.nov_txt        defm    "NOVEMBER",0
.dec_txt        defm    "DECEMBER",0
ENDIF

if KBSE
.jan_txt        defm    "JANUARI",0
.feb_txt        defm    "FEBRUARI",0
.mar_txt        defm    "MARS",0
.apr_txt        defm    "APRIL",0
.may_txt        defm    "MAJ",0
.jun_txt        defm    "JUNI",0
.jul_txt        defm    "JULI",0
.aug_txt        defm    "AUGUSTI",0
.sep_txt        defm    "SEPTEMBER",0
.oct_txt        defm    "OCTOBER",0
.nov_txt        defm    "NOVEMBER",0
.dec_txt        defm    "DECEMBER",0
ENDIF

if KBFI
.jan_txt        defm    "TAMMIKUU",0
.feb_txt        defm    "HELMIKUU",0
.mar_txt        defm    "MAALISKUU",0
.apr_txt        defm    "HUHTIKUU",0
.may_txt        defm    "TOUKOKUU",0
.jun_txt        defm    "KES",$C4,"KUU",0
.jul_txt        defm    "HEIN",$C4,"KUU",0
.aug_txt        defm    "ELOKUU",0
.sep_txt        defm    "SYYSKUU",0
.oct_txt        defm    "LOKAKUU",0
.nov_txt        defm    "MARRASKUU",0
.dec_txt        defm    "JOULUKUU",0
ENDIF

if KBFR
.jan_txt        defm    "janvier",0
.feb_txt        defm    "f",$e9,"vrier",0
.mar_txt        defm    "mars",0
.apr_txt        defm    "avril",0
.may_txt        defm    "mai",0
.jun_txt        defm    "juin",0
.jul_txt        defm    "juillet",0
.aug_txt        defm    "ao",$FB,"t",0
.sep_txt        defm    "septembre",0
.oct_txt        defm    "octobre",0
.nov_txt        defm    "novembre",0
.dec_txt        defm    "d",$e9,"cembre",0
ENDIF

if !KBFI & !KBSE & !KBFR & !KBDK
; default UK
.jan_txt        defm    "JANUARY",0
.feb_txt        defm    "FEBRUARY",0
.mar_txt        defm    "MARCH",0
.apr_txt        defm    "APRIL",0
.may_txt        defm    "MAY",0
.jun_txt        defm    "JUNE",0
.jul_txt        defm    "JULY",0
.aug_txt        defm    "AUGUST",0
.sep_txt        defm    "SEPTEMBER",0
.oct_txt        defm    "OCTOBER",0
.nov_txt        defm    "NOVEMBER",0
.dec_txt        defm    "DECEMBER",0
ENDIF

.CalWindow_txt
        defm    1,"7#5",$20+10,$20+0,$20+35,$20+8,$83
        defm    1,"2C5"
        defm    1,"3-SC", 0


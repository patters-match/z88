; -----------------------------------------------------------------------------
; Bank 1 @ S3           ROM offset $67ee
;
; $Id$
; -----------------------------------------------------------------------------

        Module  ClCalAlm

        org     $e7ee                           ; 4773 bytes

        include "alarm.def"
        include "director.def"
        include "error.def"
        include "integer.def"
        include "memory.def"
        include "saverst.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"
        include "sysvar.def"


defvars $1fd6 {
CurrentDay              ds.b    3
OrigDiaryEntry          ds.b    3
MonthStart              ds.b    3
NextMonthStart          ds.b    3
DrawnMonthStart         ds.b    3
NextDiaryDay            ds.b    3
SearchDay               ds.b    3
DiaryEntry              ds.b    3
NextDiaryEntry          ds.b    3
ubDay                   ds.b    1
ubMonth                 ds.b    1
ubNMonthDays            ds.b    1
ubWeekday               ds.b    1
swYear                  ds.b    1
}

;       ----

.Clock
        jp      ClockMain
.Calendar
        jp      CalendarMain
.Alarm
        jp      AlarmMain

;       ----

.ClockMain
        ld      a, SC_ENA
        OZ      OS_Esc

        ld      hl, ClockWinDef_txt
        OZ      GN_Sop

        ld      ix, -7
        add     ix, sp
        ld      sp, ix
        ld      (ix+6), 0                       ; selector position

.clk_1
        call    ClrScr
        ld      hl, Clock_txt
        OZ      GN_Sop
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
        ld      bc, 0<<8|2
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
        jr      clk_1                           ; else read date again

.clk_8
        push    af                              ; push ABC
        inc     sp
        push    bc

        ld      bc, 4<<8|6
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
        ld      bc, 0<<8|7
        push    bc
        call    MoveToXYbc
        ld      a, $20+16
        call    ApplyToggles
        pop     bc                              ; B=0/9
        ld      a, (ix+6)
        and     1
        jr      z, chl1_1
        ld      b, 9
.chl1_1
        call    MoveToXYbc
        call    ToggleRvrs
        ld      a, $20+8
        call    ApplyToggles
        jp      ToggleTR

;       ----

.Cl_Set
        ld      hl, ClockSet_txt
        OZ      GN_Sop

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
        ld      bc, 3<<8|3
        call    AskDate
        pop     ix
        ret

.SetTime
        ld      bc, 4<<8|7
        jp      AskTime

;       ----

.CsShowTime
        ld      bc, 4<<8|7
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

.ClockWinDef_txt
        defm    1,"7#5",$20+50,$20+0,$20+16,$20+8,$83
        defm    1,"2C5"
        defm    1,"3-SC", 0

.Clock_txt
        defm    1,"3@",$20+0,$20+0
        defm    1,"2JC"
        defm    1,"T"
        defm    1,"R"
        defm    "CLOCK"
        defm    1,"2JN"
        defm    1,"3@",$20+0,$20+0
        defm    1,"2A",$20+16
        defm    1,"R"
        defm    1,"3@",$20+0,$20+7
        defm    "  EXIT     SET  "
        defm    1,"T", 0

.ClockSet_txt
        defm    1,"3@",$20+0,$20+1
        defm    1,"2C",$FE
        defm    1,"3@",$20+2,$20+1
        defm    1,"T"
        defm    1,"R"
        defm    "  NEW DATE  "
        defm    1,"3@",$20+2,$20+5
        defm    "  NEW TIME  "
        defm    1,"R"
        defm    1,"T", 0

;       ----

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
        defm    " MON  TUE  WED  THU  FRI  SAT  SUN "
        defm    1,"T"
        defm    1,"U"
        defm    13, 10, 0

.BC_txt         defm    " BC",0
.LookFor_txt    defm    "Look for : ",0

.Months_tbl
        defw    jan_txt, feb_txt, mar_txt, apr_txt
        defw    may_txt, jun_txt, jul_txt, aug_txt
        defw    sep_txt, oct_txt, nov_txt, dec_txt

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

.CalWindow_txt
        defm    1,"7#5",$20+10,$20+0,$20+35,$20+8,$83
        defm    1,"2C5"
        defm    1,"3-SC", 0

;       ----

.AlarmMain
        ld      a, SC_ENA
        OZ      OS_Esc
        ld      a, AH_SUSP                      ; disable alarms while in app
        OZ      OS_Alm

.alm_1
        ld      hl, AlmListWd
        OZ      GN_Sop

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
        jr      z, alm_1                        ; redraw

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

        ld      hl, ScrollUp_txt                ; !! this causes visual bug on last line
        OZ      GN_Sop
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

        ld      hl, ScrollDown_txt
        OZ      GN_Sop
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

        ld      hl, PressEsc_txt
        OZ      GN_Sop

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
        ld      hl, AlmListWdBottom
        OZ      GN_Sop


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
        ld      hl, FlashBell_txt
        OZ      GN_Sop

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

        ld      hl, AlmSetWd_txt
        OZ      GN_Sop

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

.AlmListWd
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

.AlmListWdBottom
        defm    1,"3@",$20+1,$20+5              ; !!start from column 0 with space to fix scroll_up bug
        defm    1,"2C",$fd
        defm    1,"T"
        defm    "    EXIT      SET ALARM   CLEAR ALARM   VIEW ALARM  "
        defm    1,"T" ,0

.FlashBell_txt
        defm    1,"F"
        defm    SOH,SD_BLL
        defm    1,"F", 0

.AlmSetWd_txt
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

.PressEsc_txt
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

;       ----

;       common code shared by all apps

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

;       ----

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

;       ----

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

;       ----

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

;       ----

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

;       ----

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

;       ----

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

;       ----

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

;       ----

.GetOutHandle
        push    bc
        ld      bc, NQ_Out
        OZ      OS_Nq                           ; get out handle
        pop     bc
        ret

;       ----

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

;       ----

.Exit
        xor     a
        OZ      OS_Bye                          ; Application exit
        jr      Exit

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
.BulletR_txt
        defm    SOH,SD_BRGT, 0
.ScrollDown_txt
        defm    SOH,SD_DWN, 0
.ScrollUp_txt
        defm    SOH,SD_UP, 0
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

        defs 1 ($ff)                            ; padding - to be removed when using makeapp
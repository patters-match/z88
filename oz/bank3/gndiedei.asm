; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $e86b
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNDieDei

        org $e86b                               ; 1126 bytes

        include "all.def"
        include "sysvar.def"

;       ----

xdef    AddHwTime_GnDate
xdef    DateFilter
xdef    GetSysDateTime
xdef    GetSysTime
xdef    GNDeiMain
xdef    GNDieMain
xdef    SetSysTime

;       ----

xref    DEBCx60
xref    Divu48

;       ----

;       convert internal date to zoned format

;IN:    ABC=internal date
;OUT:   A=#days in month, B=month (1-12), DE=year
;       C4-C0=day of month (1-31), C7-C5=day of week (1-7, Mon-Sun)
;       Fc=1 if bad date
;
;CHG:   AFBCDE../....


.GNDieMain
        push    ix
        push    hl
        or      a                               ; !! too complicated test for 23160 years
        jp      m, die_Err                      ; !! unnecessary, catch it below
        cp      8453727/65536
        jp      nc, die_Err
        jr      nz, die_1
        ld      hl, 8453727%65536
        ld      d, b
        ld      e, c
        or      a
        sbc     hl, de
        jp      c, die_Err

.die_1
        push    bc
        push    af
        ld      hl, 0
        exx                                     ;         alt
        pop     bc                              ; chl'=date
        pop     hl
        ld      c, b

        push    hl
        push    bc
        call    GetWeekday                      ; A=0-6, mon-sun
        pop     bc
        pop     hl
        push    af                              ; remember weekday

;       !! what is the logic behind this? could be easier to use
;       !! $800000 for Jan 1st 0001

        ld      a, c
        ld      de, 2305142%65536               ; 2305 142 days, 6315+ years
        ld      c, 2305142/65536
        ld      b, 0
        or      a                               ; Ahl -= 2305 142
        sbc     hl, de
        sbc     a, c                            ; !! 'sbc $23', saves one byte
        jp      m, die_3                        ; was smaller

        or      a
        jr      nz, die_2                       ; > 65535
        ld      de, 365                         ; de'=365-days
        ex      de, hl
        sbc     hl, de
        ex      de, hl
        exx                                     ;         main
        jr      nc, die_12                      ; years done, do months

        exx                                     ;         alt
.die_2
        ld      de, 366                         ; Ahl -= 366 for AD
        or      a
        sbc     hl, de
        sbc     a, 0
.die_3
        exx                                     ;         main
        ld      ix, DaysInYears                 ; 3200/400/100/4/1 year rules
        ld      b, 5
.die_4
        call    GetYearDays                     ; DE=years, cde'=days
        or      a
        call    m, NegateDE_cde
        exx                                     ;         alt
        push    af
        push    hl
        or      a
        sbc     hl, de                          ; Ahl -= days in N years
        sbc     a, c
        push    af
        or      h
        or      l
        jr      nz, die_6

;       Ahl=0, finish years

        exx                                     ;         main
        bit     7, d                            ; increment year if AD
        jr      nz, die_5
        inc     de
.die_5
        exx                                     ;         alt
        jr      die_9                           ; almost done

.die_6
        pop     af                              ; get A
        push    af
        xor     c
        jp      p, die_10                       ; no overflow
        ld      de, 365
        exx                                     ;         main
        bit     0, b                            ; leap year?
        exx                                     ;         alt
        jr      nz, die_7                       ; no, skip
        inc     de                              ; 366
.die_7
        pop     af                              ; get flags
        push    af
        jp      p, die_8                        ; days>0, skip

        add     hl, de                          ; Ahl += 365(366)
        adc     a, 0
        inc     sp                              ; discard AF
        inc     sp
        push    af
        jr      nz, die_11                      ; didn't go positive

.die_8
        dec     de                              ; Ahl = 364(365)-days
        ex      de, hl
        ld      c, a
        xor     a
        sbc     hl, de
        sbc     a, c
        ex      de, hl
        ld      a, c
        jr      c, die_11

.die_9
        call    die_17
        jr      die_12

.die_10
        call    die_17
        jr      die_4                           ; redo rule

.die_11
        pop     af                              : discard AF
        pop     hl                              ; restore Ahl
        pop     af
        exx                                     ;         main
        ld      de, 5                           ; bump rule
        add     ix, de
        djnz    die_4

.die_12
        ld      ix, DaysInMonths
        ld      b, 11
.die_13
        exx                                     ;         alt
        ld      d, 0                            ; de' = days in month
        ld      e, (ix+0)
        inc     ix                              ; next month
        or      a
        push    hl
        sbc     hl, de                          ; hl' -= days in month
        jr      c, die_14
        inc     sp                              ; discard hl'
        inc     sp
        exx                                     ;         main
        djnz    die_13
        exx                                     ;         alt
        ld      e, (ix+0)                       ; days in Feb
        bit     0, b
        jr      nz, die_15
        inc     e                               ; 29 days if ly
        jr      die_15
.die_14
        pop     hl
.die_15
        ld      c, l
        inc     c
        exx                                     ;         main
        ld      de, 1
        ld      a, b                            ; Jan/Feb? bump hl
        cp      2
        call    c, die_AddHL_DE
        ld      a, 12                           ; adjust monts to start from Jan
        sub     b
        cp      11
        jr      c, die_16                       ; Mar-Dec? skip
        sub     12
.die_16
        add     a, 2
        ld      b, a                            ; 1-12
        exx                                     ;         alt
        ld      a, c
        push    af
        ld      a, e
        exx                                     ;         main
        ld      e, a                            ; e'
        pop     af
        ld      c, a                            ; c'
        pop     af                              ; get weekday
        inc     a                               ; 1-7
        add     a, a                            ; rotate to A5-A7
        add     a, a
        add     a, a
        add     a, a
        add     a, a
        or      c
        ld      c, a
        ld      a, e
        push    af
        ld      de, 1599                        ; final adjust
        call    die_AddHL_DE
        ex      de, hl
        pop     af
        jr      die_20
.die_17
        pop     de                              ; caller PC
        exx                                     ;         main
        ld      a, b
        exx                                     ;         alt
        rr      b                               ; move ly flag to b0
        rra
        rl      b
        pop     af                              ; restore AF
        inc     sp                              ; discard Ahl
        inc     sp
        inc     sp
        inc     sp
        push    de                              ; caller PC
        exx                                     ;         main
.die_AddHL_DE
        or      a
        adc     hl, de
        ret     po                              ; no overflow? ok
        inc     sp                              ; discard caller PC
        inc     sp
        pop     af                              ; pop weekday
.die_Err
        scf
.die_20
        pop     hl
        pop     ix
        ret

;       ----

;       convert zoned date to internal format
;
;IN:    B=month (1-12, Jan-Dec), DE=year,
;       C7-C5=day of week (0-7, 0=unspecified, 1= Mon)
;       C4-C0=day of month (1-31)
;
; OUT:  ABC=date in internal format
;       Fc=1 if bad date
;
;CHG:   AFBCDEHL/....

.GNDeiMain
        push    ix

;       validate month

        ld      a, b
        or      a                               ; !! 'dec a; cp 12; jp nc, dei_err; inc a'
        jp      z, dei_err
        cp      13
        jp      nc, dei_err

;       validate year

        ex      de, hl                          ; HL=year
        or      a                               ; HL=year-1599
        ld      de, 1599
        sbc     hl, de
        jp      pe, dei_err                     ; y< -31169, underflow
        jp      m, dei_1
        ld      de, 18253-1599                  ; DE=18253-year
        or      a
        ex      de, hl
        sbc     hl, de
        ex      de, hl                          ; restore year
        jp      c, dei_err                      ; year>18253

.dei_1
        exx                                     ;         alt
        ld      hl, 11382                       ; Ahl'~=6315 years (A comes later)
        ld      b, 0                            ; b'=0
        exx                                     ;         main
        cp      3                               ; Month>2?
        jr      nc, dei_2                       ; not affected by leap day

        ld      de, 1                           ; substract one year
        or      a
        sbc     hl, de
        jp      pe, dei_err
.dei_2
        ld      a, h
        or      l
        ld      a, 35                           ; Ahl=2305142 days ~= 6315 years
        jr      z, dei_9                        ; year=0? ok !! bug - there isn't year 0
        bit     7, h                            ; Ahl+=366 if AD
        jr      nz, dei_3
        exx                                     ;         alt
        ld      hl, 11382+366
        exx                                     ;         main
.dei_3
        push    bc
        push    hl
        ld      ix, DaysInYears
        ld      b, 5
.dei_4
        call    GetYearDays                     ; DE=#years, cde'=#days
        bit     7, h                            ; years negative?
        call    nz, NegateDE_cde                ; make days/years negative
        push    hl
        or      a                               ; HL-=#years
        sbc     hl, de
        push    af
        jr      z, dei_5                        ; went to zero
        ld      a, h
        xor     d
        jp      m, dei_6                        ; different sign, crossed year 0
        call    AddYearDays                     ; Ahl+=cde
        jr      dei_4
.dei_5
        call    AddYearDays                     ; Ahl+=cde
        jr      dei_7

.dei_6
        pop     af                              ; restore year
        pop     hl
        ld      de, 5                           ; bump table ptr
        add     ix, de
        djnz    dei_4                           ; and loop

.dei_7
        pop     hl
        pop     bc
        bit     7, h                            ; Ahl -= 365(366) if AD
        jr      nz, dei_9
        exx                                     ;         alt
        ld      c, -1
        ld      de, -365
        bit     0, b                            ; leap year?
        jr      nz, dei_8
        dec     de                              ; -366
.dei_8
        call    dei_Add_Ahl_cde
        exx                                     ;         main
.dei_9
        ex      af, af'                         ;         alt
        ld      a, b                            ; adjust B to start from March
        cp      3                               ; !! 'sub 3; jr nc, +2; add a, 12; inc a'
        jr      nc, dei_10
        add     a, 12
.dei_10
        sub     2
        ld      b, a
        ex      af, af'                         ;         main
        ld      ix, DaysInMonths
        jr      dei_12                          ; !! make B one smaller, drop thru here
.dei_11
        exx                                     ;         alt
        ld      e, (ix+0)                       ; cde' = #days
        ld      d, 0
        ld      c, d
        call    dei_Add_Ahl_cde
        inc     ix
        exx                                     ;         main
.dei_12
        djnz    dei_11
        ld      d, a                            ; D=days high
        ex      af, af'                         ;         alt
        ld      e, (ix+0)                       ; E=days inlast month
        cp      12                              ; February?
        jr      nz, dei_13                      ; no, skip
        exx                                     ;         alt
        bit     0, b                            ; leap year?
        exx                                     ;         main
        jr      nz, dei_13                      ; no skip
        inc     e                               ; days++
.dei_13
        ex      af, af'                         ;         main
        ld      a, c
        and     $1F                             ; monthday
        jr      z, dei_err                      ; !! unnecessary, catched below
        dec     a                               ; !! as it wraps to 255 here
        cp      e
        jr      nc, dei_err                     ; too many days in month
        push    de                              ; remember days high
        exx                                     ;         alt
        ld      e, a                            ; cde' = monthday
        xor     a
        ld      d, a
        ld      c, a
        pop     af                              ; A=days high
        call    dei_Add_Ahl_cde

        push    hl                              ; BHL=Ahl'
        exx                                     ;         main
        pop     hl
        jp      m, dei_err
        ld      b, a                            ; days in BHL

        ld      a, c                            ; validate weekday
        and     $0E0                            ; day of week
        jr      z, dei_14                       ; unspecified
        rla                                     ; !! 3*'rlca'
        rla
        rla
        rla
        ld      c, a                            ; weekday, 1-7
        ld      a, b
        exx                                     ;         alt
        ld      c, a
        call    GetWeekday
        exx                                     ;         main
        inc     a
        cp      c
        jr      nz, dei_err                     ; weekday doesn't match
.dei_14
        ld      a, b                            ; ABC=BHL=internal date
        ld      b, h
        ld      c, l
        jr      dei_18
.dei_Add_Ahl_cde
        add     hl, de
        adc     a, c
        ret     po
        exx                                     ;         main
.dei_errSP
        inc     sp
        inc     sp
.dei_err
        scf
.dei_18
        pop     ix
        ret

;       ----

.AddYearDays
        pop     de                              ; caller PC
        pop     af                              ; A !! isn't used at all?
        inc     sp                              ; discard year
        inc     sp
        push    de                              ; caller pc
        ex      af, af'                         ; remember A
        ld      a, b                            ; b'=B
        exx                                     ; !! B0=0 means leap year
        ld      b, a
        ex      af, af'                         ; restore A
        add     hl, de                          ; Ahl'+=cde'
        adc     a, c
        exx
        ret     po                              ; no overflow
        pop     hl                              ; restore stack
        pop     bc
        jr      dei_errSP                       ; and error

;       ----

;IN:    CHL=#days
;OUT:   A=weekday (CHL=#weeks, not used)
;
;       basically it's 24bit/8bit division

.GetWeekday
        ld      e, 7
        ld      b, 24
        xor     a                               ; a=0, Fc=0
.gwd_1
        rl      l                               ; ACHL << 1 + Fc
        rl      h                               ; !! 'adc hl, hl; rl c; rla'
        rl      c
        rl      a

        ld      d, a                            ; keep A in range 0-6
        sub     e
        ccf                                     ; !! just 'jr nc'
        jr      c, gwd_2
        ld      a, d
.gwd_2
        djnz    gwd_1
        ret

;       ----

.GetYearDays
        ld      e, (ix+3)                       ; DE = #years
        ld      d, (ix+4)
        exx
        ld      e, (ix+0)                       ; cde' = #days
        ld      d, (ix+1)
        ld      c, (ix+2)
        exx
        ret

;       ----

;
.NegateDE_cde
        push    hl                              ; DE = -DE
        ex      af, af'
        xor     a
        ld      h, a                            ; !! 'sub a, e;ld e, a'
        ld      l, a                            ; !! 'ld a, 0; sbc a, d; ld d, a'
        sbc     hl, de                          ; !! avoids push/pop
        ex      de, hl
        pop     hl

        exx                                     ; cde' = -cde'
        push    hl
        xor     a
        ld      h, a                            ; !! same here
        ld      l, a
        sbc     hl, de
        sbc     a, c
        ex      de, hl
        ld      c, a
        ex      af, af'
        pop     hl
        exx
        ret

;       ----

.DaysInYears

;       3200 years, 1168775 days, not leap year !! there's no such rule officially

        defb    1168775&255,1168775/256&255,1168775/65536&255           ; 3200*365+8*97-1
        defw    3200

;       400 years, 146097 days, leap year

        defb    146097&255,146097/256&255,146097/65536&255              ; 400*365+4*24+1
        defw    400

;       100 years, 36524 days, not leap year

        defb    36524&255,36524/256&255,36524/65536&255                 ; 100*365+25-1
        defw    100

;       4 years, 1461 days, leap year

        defb    1461&255,1461/256&255,1461/65536&255                    ; 4*365+1
        defw    4

;       1 year, 365 days, not leap year

        defb    365&255,365/256&255,365/65536&255
        defw    1

.DaysInMonths           ; Mar, Apr, ..., Dec, Jan, Feb
        defb    31,30,31,30,31,31,30,31,30,31,31,28

.DateFilter
        defw    $149
        defb    $20,$80
        defm    7,"Monday",     2,$81
        defm    4,"Mon",        2,$A1
        defm    8,"Tuesday",    2,$82
        defm    4,"Tue",        2,$A2
        defm    10,"Wednesday", 2,$83
        defm    4,"Wed",        2,$A3
        defm    9,"Thursday",   2,$84
        defm    4,"Thu",        2,$A4
        defm    7,"Friday",     2,$85
        defm    4,"Fri",        2,$A5
        defm    9,"Saturday",   2,$86
        defm    4,"Sat",        2,$A6
        defm    7,"Sunday",     2,$87
        defm    4,"Sun",        2,$A7
        defm    3,"st",         2,$88
        defm    3,"nd",         2,$89
        defm    3,"rd",         2,$8A
        defm    3,"th",         2,$8B
        defm    3,"AD",         2,$8C
        defm    3,"BC",         2,$8D
        defm    8,"January",    2,$C1
        defm    4,"Jan",        2,$E1
        defm    9,"February",   2,$C2
        defm    4,"Feb",        2,$E2
        defm    6,"March",      2,$C3
        defm    4,"Mar",        2,$E3
        defm    6,"April",      2,$C4
        defm    4,"Apr",        2,$E4
        defm    4,"May",        2,$C5
        defm    4,"May",        2,$E5
        defm    5,"June",       2,$C6
        defm    4,"Jun",        2,$E6
        defm    5,"July",       2,$C7
        defm    4,"Jul",        2,$E7
        defm    7,"August",     2,$C8
        defm    4,"Aug",        2,$E8
        defm    10,"September", 2,$C9
        defm    4,"Sep",        2,$E9
        defm    8,"October",    2,$CA
        defm    4,"Oct",        2,$EA
        defm    9,"November",   2,$CB
        defm    4,"Nov",        2,$EB
        defm    9,"December",   2,$CC
        defm    4,"Dec",        2,$EC

;       ----

.SetSysTime
        call    SysTimeSub
        ex      de, hl
.sst_1
        ld      a, (hl)                         ; copy into system time
        OZ      GN_Wbe
        inc     hl
        inc     de
        dec     c
        jr      nz, sst_1
        ret

;       ----

.SysTimeSub
        ld      a, HT_MDT
        OZ      Os_Ht                           ; BHL=$2180AB (system time)
        ld      de, uwGnDateLow
        ld      c, 11
        ret

;       ----

.GetSysTime
        call    SysTimeSub
.gst_1
        OZ      GN_Rbe                          ; copy from system time
        ld      (de), a
        inc     hl
        inc     de
        dec     c
        jr      nz, gst_1
        ret

;       ----

;       hlBHL=date, CDE=seconds, A=cseconds

.GetSysDateTime
        push    iy
        push    ix
        call    GetSysTime
        ld      hl, GnHwTimeBuf
        ld      a, HT_RD
        OZ      Os_Ht
        call    AddHwTime_GnDate
        push    iy
        ld      b, h                            ; BHL = top 24 bits
        ld      h, l
        ld      l, d
        ld      a, e
        exx
        ld      c, a                            ; cde = bottom 24 bits
        pop     de
        exx
        ld      a, (GnHwTimeBuf)                ; csec
        ld      c, 86400/65536
        ld      de, 86400&65535                 ; !! faster: (x/675 ) >> 7
        push    af
        call    Divu48                          ; BHLcde/86 400
        pop     af
        and     a
        pop     ix
        pop     iy
        ret

;       ----

.AddHwTime_GnDate
        ld      bc, (GnHwTimeBuf+2)
        ld      de, (GnHwTimeBuf+4)
        ld      d, 0
        call    DEBCx60
        ld      iy, (uwGnDateLow)               ; HLDEIY=GnDate+HwTime[234]*60+HwTime[1]
        add     iy, bc
        ld      hl, (uwGnDateMid)
        adc     hl, de
        ex      de, hl
        ld      hl, (uwGnDateHigh)
        ld      bc, 0
        adc     hl, bc
        ld      a, (GnHwTimeBuf+1)
        ld      c, a
        ld      b, 0
        add     iy, bc
        ld      c, 0
        ex      de, hl
        adc     hl, bc
        ex      de, hl
        adc     hl, bc
        ret

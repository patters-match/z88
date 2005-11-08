; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $c891
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNTime

        org $c891                               ; 737 bytes

        include "alarm.def"
        include "error.def"
        include "memory.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"

        include "sysvar.def"

;       ----

xdef    GNDei
xdef    GNDie
xdef    GNGmd
xdef    GNGmt
xdef    GNMsc
xdef    GNPmd
xdef    GNPmt
xdef    GNSdo

;       ----

xref    DEBCx60
xref    Divu16
xref    Divu24
xref    Divu48
xref    GetOsf_BHL
xref    GetOsf_DE
xref    GetOsf_HL
xref    GetSysDateTime
xref    GetSysTime
xref    GN_ret1c
xref    GNDeiMain
xref    GNDieMain
xref    Mulu16
xref    Mulu24
xref    Mulu40
xref    PrintStr
xref    PutOsf_ABC
xref    PutOsf_BC
xref    PutOsf_BHL
xref    PutOsf_DE
xref    PutOsf_Err
xref    PutOsf_HL
xref    ReadHL
xref    ReadOsfHL
xref    SetSysTime
xref    UngetOsfHL
xref    Wr_ABC_OsfDE
xref    WriteDE
xref    WriteOsfDE

;       ----

;       convert internal format date to zoned format
;
;IN:    ABC = internal date
;OUT:   A=number of days in month, B = month (1 = Jan, 12 = Dec)
;       C7-C5=day of week (1=Mon, 7=Sun)
;       C4-C0: day of month (1-31)
;       DE=year
;
;CHG:   AFBCDE../....

.GNDie
        push    hl
        call    GNDieMain                       ; ABC -> ABCDE
        pop     hl
        jp      GN_ret1c

;       ----

;       convert zoned, external format date to internal format
;
;IN:    B = month, C7-C5=weekday (0=unspecified), C4-C0: day of month
;       DE=year
;OUT:   ABC = internal date
;
;CHG:   AFBC..../....

.GNDei
        push    de
        push    hl
        call    GNDeiMain                       ; BCDE -> ABC
        pop     hl
        pop     de
        jp      GN_ret1c

;       ----

;       get the current machine system date in internal format
;
;IN:    DE=destination
;OUT:   ABC=date (if DE<256), DE=DE+3 (if DE>255)
;
;CHG:   AFBCD../....

.GNGmd
        call    GetSysDateTime                  ; time into BHL
        ld      a, b
        ld      b, h
        ld      c, l
        call    Wr_ABC_OsfDE                    ; write to DE(in)
        ret

;       ----

;       get (read) machine system time in internal format
;
;IN:    C=least significant byte from GN_Gmd (optional)
;       DE=destination
;OUT:   ABC=time (if DE<256), DE=DE+3 (if DE>255)
;       Fz=1 if C(in) is consistent with time
;
;CHG:   AFBCDE../....

.GNGmt
        call    GetSysDateTime                  ; BHL=date, CDE=seconds, A=cseconds
        push    af
        ld      a, (iy+OSFrame_C)               ; C(in) consistent? Fz=1
        cp      l
        jr      nz, gmt_1
        set     Z80F_B_Z, (iy+OSFrame_F)

.gmt_1
        push    hl                              ; save BHL  !! why?
        ld      a, b
        push    af

        ex      de, hl                          ; deconds to centiseconds
        ld      b, c
        ld      de, 100
        ld      c, 0
        call    Mulu24
        ex      de, hl
        ld      c, b

        pop     af                              ; restore BHL
        ld      b, a
        pop     hl

        pop     af
        add     a, e                            ; CDE += A
        ld      e, a
        jr      nc, gmt_2
        inc     d
        jr      nz, gmt_2
        inc     c
.gmt_2
        ld      a, c                            ; write CDE to DE(in)
        ld      b, d
        ld      c, e
        call    Wr_ABC_OsfDE
        ret

;       ----

;       set current machine date
;
;IN:    HL=source, ABC=date (ih HL=2)
;OUT:   -
;
;CHG:   .F....../..

.GNPmd
        ld      a, 11                           ; AH_AINC
        OZ      Os_Alm
        call    GetSysDateTime
        push    bc                              ; remember time in CDE
        push    de
        ld      a, (iy+OSFrame_H)
        or      a
        jr      nz, pmd_1                       ; HL(in)>255, read BHL from memory
        ld      b, (iy+OSFrame_A)               ; else use ABC(in)
        ld      h, (iy+OSFrame_B)
        ld      l, (iy+OSFrame_C)
        jr      pmd_2
.pmd_1
        call    GetOsf_HL
        call    ReadHL                          ; !! more efficient with Read_ABC_HL
        push    af
        call    ReadHL
        push    af
        call    ReadHL
        ld      b, a
        pop     af
        ld      h, a
        pop     af
        ld      l, a

.pmd_2
        ld      c, 0                            ; !! (675*BHL) << 7 would be faster
        ld      de, 5400                        ; !! (<<8)>>1 even faster
        call    Mulu40                          ; hlBHL = 5400 * BHL

        ld      a, b
        exx
        ld      d, 0                            ; dehl=hlB
        ld      e, h
        ld      h, l
        ld      l, a

        ld      b, 4                            ; *16, total 86 400, sec/day
.pmd_3
        exx                                     ; dehlHL<<1
        sla     l                               ; !! 'add HL,HL;exx;adc hl,hl;rl e; rl d' 
        rl      h
        exx
        rl      l
        rl      h
        rl      e
        rl      d
        djnz    pmd_3

        exx                                     ; GnDate = dehlHL + CDE(GetSysDateTime)
        pop     bc
        add     hl, bc
        ld      (uwGnDateLow), hl
        exx
        pop     bc
        ld      b, 0
        adc     hl, bc
        ld      (uwGnDateMid), hl
        ex      de, hl
        ld      c, b
        adc     hl, bc
        ld      (uwGnDateHigh), hl
        exx
        jp      pmt_5                           ; set system time
        ret                                     ; !! unnecessary

;       ----

;       set current machine time
;
;IN:    HL=source, ABC=time (ih HL=2), E=low byte of assumed date (optional)
;OUT:   Fz=1 if time is consistent with date
;
;CHG:   .F....../..

.GNPmt
        ld      (iy+OSFrame_F), Z80F_Z
        ld      a, 11                           ; AH_AINC
        OZ      Os_Alm

        xor     a                               ; HL > 255? read BHL from memory
        or      h
        jr      nz, pmt_1
        ld      b, (iy+OSFrame_A)               ; else use ABC(in)
        ld      h, (iy+OSFrame_B)
        ld      l, (iy+OSFrame_C)
        jr      pmt_2
.pmt_1
        call    ReadHL                          ; !! more efficient with Read_ABC_HL
        push    af
        call    ReadHL
        push    af
        call    ReadHL
        ld      b, a
        pop     af
        ld      h, a
        pop     af
        ld      l, a                            ; time in BHL
.pmt_2
        ld      c, 0
        ld      de, 100
        call    Divu24                          ; into seconds
        push    hl                              ; save result BHL
        push    bc

        call    GetSysDateTime                  ; BHL=date
        ld      a, (iy+OSFrame_E)               ; Fz=0 if time inconsistent
        cp      l
        jr      z, pmt_3
        res     Z80F_B_Z, (iy+OSFrame_F)

.pmt_3
        ld      c, 0                            ; !! (675*BHL) << 7 would be faster
        ld      de, 5400                        ; !! (<<8)>>1 even faster
        call    Mulu40                          ; hlBHL = 5400 * BHL

        ld      a, b
        exx
        ld      d, 0                            ; dehl=hlB
        ld      e, h
        ld      h, l
        ld      l, a

        ld      b, 4                            ; *16, total 86 400, sec/day
.pmt_4
        exx                                     ; dehlHL<<1
        sla     l
        rl      h
        exx
        rl      l
        rl      h
        rl      e
        rl      d
        djnz    pmt_4

        exx                                     ; GnDate = dehlHL time(in)/100
        pop     af
        pop     bc
        add     hl, bc
        ld      (uwGnDateLow), hl
        exx
        ld      b, 0
        ld      c, a
        adc     hl, bc
        ld      (uwGnDateMid), hl
        ld      c, 0
        ex      de, hl
        adc     hl, bc
        ld      (uwGnDateHigh), hl
        exx
.pmt_5
        call    SetSysTime
        ld      a, 1                            ; HT_RES
        OZ      Os_Ht
        ld      a, 12                           ; AH_ADEC
        OZ      Os_Alm
        ret

;       ----

;       send date and time to standard output
;IN:    HL=time[3] and date[3]
;OUT:   -
;
;CHG:   -

.GNSdo
        push    ix
        ld      hl, -3                          ; !! use 2* push to make space
        add     hl, sp
        ld      sp, hl
        ex      de, hl
        OZ      GN_Gmd                          ; read machine date into stack buffer

;       check for today/yesteday

;       !!      get OZ date into CDE and date(in) into BHL to make
;               compares easier
;               compare - 'ld a, d;or e;dec de;jr nz,*+3;dec c' - compare

        dec     de                              ; last byte of stack buffer
        call    GetOsf_HL                       ; !! S2 and S3 unavailable!
        ld      bc, 5                           ; point to last byte of date(in)
        add     hl, bc

        ld      b, 3
.sdo_1
        ld      a, (de)                         ; compare date
        cp      (hl)
        jr      nz, sdo_2                       ; not today, check for yesterday
        dec     de
        dec     hl
        djnz    sdo_1                           ; more to do
        ld      hl, Today_txt
        jr      sdo_4

.sdo_2
        ld      hl, 0                           ; AHL=date(in)
        add     hl, sp
        ld      c, (hl)
        inc     hl
        ld      b, (hl)
        inc     hl
        ld      a, (hl)
        ld      h, b
        ld      l, c

        ld      bc, 1                           ; AHL--
        or      a
        sbc     hl, bc
        sbc     a, 0

        pop     bc                              ; change stack date
        push    hl
        ld      hl, 2
        add     hl, sp
        ld      (hl), a

        ex      de, hl                          ; DE = last byte of stack buffer
        call    GetOsf_HL
        ld      bc, 5
        add     hl, bc                          ; point to last byte of date

        ld      b, 3
.sdo_3
        ld      a, (de)
        cp      (hl)
        jr      nz, sdo_4
        dec     de
        dec     hl
        djnz    sdo_3
        ld      hl, Yesterday_txt               ; " Yesterday "

.sdo_4
        ex      af, af'                         ; remember Fz
        ex      de, hl
        ld      hl, 3                           ; restore stack
        add     hl, sp
        ld      sp, hl

        ex      de, hl
        ex      af, af'
        jr      nz, sdo_5                       ; print date instead of string
        call    PrintStr
        jr      sdo_6

.sdo_5
        call    GetOsf_HL
        ld      bc, 3                           ; date start !! 3* 'inc hl'
        add     hl, bc
        ld      bc, NQ_Out                      ; !! do this above to avoid repetition
        OZ      OS_Nq                           ; get outstream
        ld      de, 0                           ; output to stream
        ld      a, $A1                          ; output century, use C, disable leading zeroes
        ld      bc, 1<<8|'-'                    ; text month, delimeter '-'
        OZ      GN_Pdt                          ; print it

.sdo_6
        ld      a, ' '                          ; delimeter
        OZ      OS_Out

        call    GetOsf_HL
        ld      bc, NQ_Out
        OZ      OS_Nq
        ld      de, 0                           ; output to stream
        ld      a, $21                          ; leading zeroes, seconds
        OZ      GN_Ptm                          ; print time
        pop     ix
        ret

.Today_txt
        defm    "   Today   ",0
.Yesterday_txt
        defm    " Yesterday ",0

;       ----

;       miscellaeneous time operations, convert real time to time to elapse
;
;IN:    A=0, convert source to time to elapse
;            BHL = source time days
;            CDE = source time centiseconds/ticks
;        
;       A=1, update base time (used over reset)
;            BHL = Additional offset in minutes.
;            C = offset in seconds
;
;OUT;   A(in)=0
;            BHL=minutes to elapse, C=seconds to elapse, A=centiseconds to elapse
;       A(in)=1
;            -

.GNMsc
        or      a
        jp      nz, msc_update

.msc_elapse
        ld      de, 2                           ; OZ date into BHL
        OZ      GN_Gmd
        ld      h, b
        ld      l, c
        ld      b, a
        push    bc

        OZ      GN_Gmt                          ; oz time into ADE
        ld      d, b
        ld      e, c

        pop     bc
        ld      c, a                            ; BHL:date, CDE=time
        jr      nz, msc_elapse                  ; time not consistent, try again

        push    hl

        ld      a, (iy+OSFrame_C)               ; CDE = source time - OZ time
        ld      h, (iy+OSFrame_D)
        ld      l, (iy+OSFrame_E)
        or      a
        sbc     hl, de
        sbc     a, c
        ld      c, a
        ex      de, hl
        jr      nc, msc_elp2                    ; no underflow? skip

        ld      hl, 8640000%65536               ; else normalize to 24h
        ld      a, 8640000/65536
        add     hl, de
        adc     a, c
        ld      c, a
        ex      de, hl
        scf                                     ; Fc=1, decrement day elapse
.msc_elp2
        pop     hl
        push    de

        ld      d, (iy+OSFrame_H)               ; BHL = source date - OZ date - Fc
        ld      e, (iy+OSFrame_L)
        ld      a, (iy+OSFrame_B)
        ex      de, hl
        sbc     hl, de
        sbc     a, b
        ld      b, a
        pop     de
        jr      c, msc_fail                     ; time elapsed? error

        ld      a, c                            ; days into minutes
        push    af                              ; !! optimize push/pop
        push    de
        ld      c, 0
        ld      de, 24*60
        call    Mulu24                          ; BHL *= 24*60
        pop     de
        pop     af
        ld      c, a
        call    PutOsf_BHL                      ; minutes to elapse (date part)

        ld      b, c                            ; centiseconds into minutes
        ex      de, hl
        ld      c, 0
        ld      de, 6000
        call    Divu24                          ; CDE /= 6000
        push    de                              ; remainder

        ld      a, (iy+OSFrame_B)               ; add minutes to elapse (time part)
        ld      d, (iy+OSFrame_H)
        ld      e, (iy+OSFrame_L)
        add     hl, de
        adc     a, b
        pop     de
        ld      (iy+OSFrame_B), a               ; !! 'ld b,a; call PutOsf_BHL'
        call    PutOsf_HL

        or      h
        or      l
        push    af                              ; BHL = 0? Fz=1

        ld      b, c                            ; BHL= csecs below minute, max 5999
        ex      de, hl                          ; into seconds
        ld      c, 0
        ld      de, 100
        call    Divu24                          ; !! Divu16 would do

        inc     e                               ; add one second if centisecs
        dec     e
        jr      z, msc_elp_3
        inc     l

.msc_elp_3
        ld      a, (GnHwTimeBuf+1)              ; ?
        add     a, 28
        cp      60                              ; normalize seconds 0..59
        jr      c, msc_elp4
        sub     60
.msc_elp4
        add     a, l
        pop     bc
        inc     b
        dec     b
        jr      nz, msc_elp5                    ; minutes to elapse not zero? seconds ok

        cp      60                              ; <60? use seconds from reminder
        jr      nc, msc_elp5                    ; !! branch into 'sub 60'
        ld      a, l
.msc_elp5
        cp      60                              ; add one minute if seconds > 60
        jr      c, msc_elp6
        sub     60
        inc     (iy+OSFrame_L)
        jr      nz, msc_elp6
        inc     (iy+OSFrame_H)
        jr      nz, msc_elp6
        inc     (iy+OSFrame_B)

.msc_elp6
        ld      (iy+OSFrame_C), a               ; seconds to elapse
        ld      (iy+OSFrame_A), e               ; csec to elapse
        jr      msc_x

.msc_fail
        ld      (iy+OSFrame_A), RC_Fail
        set     Z80F_B_C, (iy+OSFrame_F)
.msc_x
        ret

.msc_update
        ld      a, HT_RES
        OZ      Os_Ht
        ld      e, b                            ; DEBC=BHL
        ld      d, 0
        ld      b, h
        ld      c, l
        call    DEBCx60                         ; into seconds
        ld      h, 0
        ld      l, (iy+OSFrame_C)               ; + seconds(in)
        add     hl, bc
        jr      nc, msc_upd2
        inc     de

.msc_upd2
        ld      b, h                            ; !! just push HL instead of BC
        ld      c, l
        push    bc
        push    de
        call    GetSysTime
        pop     de
        pop     bc

        ld      hl, uwGnDateLow                 ; GnDate += DEBC
        ld      a, (hl)
        add     a, c
        ld      (hl), a
        inc     hl
        ld      a, (hl)
        adc     a, b
        ld      (hl), a
        inc     hl
        ld      a, (hl)
        adc     a, e
        ld      (hl), a
        inc     hl
        ld      a, (hl)
        adc     a, d
        ld      (hl), a
        inc     hl
        ld      a, (hl)
        adc     a, 0
        ld      (hl), a
        inc     hl
        ld      a, (hl)
        adc     a, 0
        ld      (hl), a

        call    SetSysTime
        jr      msc_x


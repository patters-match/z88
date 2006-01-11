; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $0c108
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNAConv

        org $c108                               ; 1929 bytes

        include "error.def"
        include "filter.def"
        include "integer.def"
        include "memory.def"
        include "syspar.def"
        include "time.def"
        include "sysvar.def"
        include "gndef.def"

;       ----

xdef    GNGdn
xdef    GNGdt
xdef    GNGtm
xdef    GNPdn
xdef    GNPdt
xdef    GNPtm

;       ----

xref    Divu16
xref    Divu24
xref    Divu48
xref    GetOsf_BHL
xref    GetOsf_DE
xref    GetOsf_HL
xref    GNDeiMain
xref    GNDieMain
xref    Mulu16
xref    Mulu24
xref    Mulu40
xref    PutOsf_ABC
xref    PutOsf_BC
xref    PutOsf_BHL
xref    PutOsf_DE
xref    PutOsf_Err
xref    PutOsf_HL
xref    ReadHL
xref    ReadOsfHL
xref    UngetOsfHL
xref    Wr_ABC_OsfDE
xref    WriteDE
xref    WriteOsfDE

;       ----

;       convert ASCII string to internal date
;
;IN:    HL=source, DE=destination, IX=source handle (if HL<2)
;       A=format, B=max chars in, C=delimter (if A5=1)
;OUT:   ABC=date, HL=input index/ptr
;       Fc=1, A=error

.GNGdt
        push    ix
        xor     a                               ; check we have 1-128 chars
        or      b
        jr      z, gdt_1
        cp      129
        jr      c, gdt_2
.gdt_1
        ld      a, RC_Bad
        jr      gdt_Err1
.gdt_2
        ld      b, (iy+OSFrame_B)
        ex      de, hl
        ld      hl, DateFilter                  ; open standard date filter
        ld      a, 5                            ; case eq, buf size max B bytes
        OZ      GN_Flo
        jr      nc, gdt_4
.gdt_Err1
        call    PutOsf_Err
        pop     ix
        ret

.gdt_4
        ex      (sp), ix                        ; move bytes from instream to date filter
        call    ReadOsfHL
        ex      (sp), ix
.gdt_5
        jr      nc, gdt_6
        cp      RC_Eof
        jr      z, gdt_7                        ; EOF is ok
        jr      gdt_Err2
.gdt_6
        OZ      GN_Flw
        jr      c, gdt_Err2
        djnz    gdt_4

.gdt_7
        ld      (iy+OSFrame_H), d
        ld      (iy+OSFrame_L), e
                                                ; b=month  !! bug! if EOF it is not 0
        ld      d, b                            ; d=flags
        ld      c, b                            ; c=day
.gdt_loop
        push    bc
        push    hl
        push    de
        exx
        ld      d, 0                            ; 0002 - return in BC !! use ld rr, nn
        ld      e, 2
        ld      h, d                            ; 0001 - read from filter
        ld      l, 1
        ld      b, 5                            ; #chars
        OZ      GN_Gdn                          ; get number
        exx                                     ; save result to bc'
        pop     de
        pop     hl
        pop     bc
        jr      nc, gdt_18
        cp      RC_Eof                          ; EOF ok
        jr      nz, gdt_Err2

.gdt_10
        bit     IDF_B_MONTHALPHA, d             ; did we get month?
        jr      nz, gdt_11
        bit     IDF_B_MONTHNUM, d
        jr      z, gdt_Sntx
.gdt_11
        bit     IDF_B_MONTHDAY, d               ; did we get day and year?
        jr      z, gdt_Sntx
        bit     IDF_B_YEAR, d
        jr      z, gdt_Sntx

        ex      de, hl                          ; DE=year, B=month, C=monthday
        call    GNDeiMain                       ; internal format
        jr      c, gdt_Sntx
        call    Wr_ABC_OsfDE                    ; write to DE(in)
        jr      gdt_14

.gdt_Sntx
        ld      a, RC_Sntx                      ; Syntax Error
.gdt_Err2
        call    PutOsf_Err

.gdt_14
        OZ      GN_Flc                          ; close date filter
        ld      a, b                            ; decrement count if it's not 0
        or      c
        jr      z, gdt_15
        dec     bc
.gdt_15
        call    GetOsf_HL                       ; HL<256? HL=0 (return index instead of pointer)
        ld      a, h
        or      a
        jr      nz, gdt_16
        ld      l, a
.gdt_16
        add     hl, bc
.gdt_17
        call    PutOsf_HL                       ; return read pos/index
        pop     ix
        ret

.gdt_18
        ld      e, a                            ; remember end char
        jp      nz, gdt_30                      ; not a number

        bit     IDF_B_MONTHALPHA, d
        jr      z, gdt_19
        bit     IDF_B_MONTHDAY, d
        jr      nz, gdt_year                    ; got month & day, get year
        jp      gdt_29

.gdt_19
        ld      a, d
        and     6                               ; MONTHDAY|MONTHNUM
        xor     6
        jr      nz, gdt_24                      ; either is missing

;       get year

.gdt_year
        exx
        push    bc
        ld      a, l
        exx
        pop     hl                              ; HL=year, A=terminator index
        cp      3
        jr      nc, gdt_y3                      ; >99, isn't current century

        bit     7, h
        jp      nz, gdt_Sntx                    ; negative year isn't valid

        push    bc
        push    de
        push    hl
        ld      de, 2                           ; current date into ABC
        OZ      GN_Gmd
        call    GNDieMain                       ; then into zoned format

        ld      h, d                            ; year to HL
        ld      l, e
        bit     7, h                            ; BC? make HL positive
        jr      z, gdt_y1
        xor     a
        ld      d, a                            ; !! HL=DE, so 'ld h,a; ld l,a; sbc...'
        ld      e, a
        ex      de, hl
        sbc     hl, de

.gdt_y1
        push    de
        ld      de, 100                         ; get century
        call    Divu16
        ld      de, 100
        call    Mulu16
        pop     de
        ex      (sp), hl                        ; ex (sp), de - original year
        ex      de, hl
        ex      (sp), hl
        add     hl, de                          ; two-digit year + century
        pop     de

        bit     7, d                            ; current date BC? make HL negative
        jr      z, gdt_y2
        xor     a
        ld      d, a
        ld      e, a
        ex      de, hl
        sbc     hl, de
.gdt_y2
        pop     de
        pop     bc

.gdt_y3
        bit     IDF_B_YEAR, d
        jp      nz, gdt_Sntx                    ; got year already
        set     IDF_B_YEAR, d
        jr      gdt_30

.gdt_24
        xor     6                               ; MONTHDAY | MONTHNUM
        jr      nz, gdt_27                      ; we have one of them

        ld      a, (iy+OSFrame_A)
        and     $18
        jr      nz, gdt_26                      ; forced A/E format

        exx                                     ; else use OZ setting
        push    bc
        exx
        push    hl
        push    bc
        push    de

        dec     sp                              ; !! 'push af; ld hl,1' then 'pop af' below
        ld      hl, 0
        add     hl, sp
        ld      d, h
        ld      e, l
        ld      a, 1
        ld      bc, PA_Dat
        OZ      OS_Nq                           ; get date format
        ld      hl, 0
        add     hl, sp
        ld      a, (hl)
        inc     sp

        pop     de
        pop     bc
        pop     hl

        cp      'A'                             ; !! 'and 4; rlca; rlca' is enough to get 'E' flag
        ld      a, 8                            ; American
        jr      z, gdt_25
        ld      a, $10                          ; European
.gdt_25
        exx                                     ; !! pop this above for symmetry
        pop     bc
        exx
.gdt_26
        bit     4, a
        jr      nz, gdt_29                      ; European, get day first
        jr      gdt_28                          ; else get month first
                                                ; !! (IDF_B_MONTHDAY&$18)=8, could drop thru

;       we have one, get another

.gdt_27
        bit     IDF_B_MONTHDAY, a
        jr      z, gdt_29

;       get month

.gdt_28
        exx
        ld      a, c
        exx
        ld      b, a                            ; B=month
        set     IDF_B_MONTHNUM, d
        jr      gdt_30

;       get day

.gdt_29
        bit     IDF_B_MONTHDAY, d
        jp      nz, gdt_Sntx                    ; already have day

        exx
        ld      a, c
        exx
        or      c
        ld      c, a                            ; C=month_alpha|month
        set     IDF_B_MONTHDAY, d

.gdt_30
        ld      a, e                            ; get end char
        or      a
        jp      m, gdt_filter                   ; filter code

        bit     5, (iy+OSFrame_A)               ; C delimeter?
        jr      z, gdt_31                       ; no, try standard delimeters
        cp      (iy+OSFrame_C)
        jr      gdt_32
.gdt_31
        cp      ' '                             ; !! put these in descending order, use 'jr nc'
        jr      z, gdt_32
        cp      '/'
        jr      z, gdt_32
        cp      '-'
        jr      z, gdt_32
        cp      9
        jr      z, gdt_32
        cp      '.'
.gdt_32
        jp      nz, gdt_10                      ; bad delimeter, we're done

;       skip delimeter and loop

.gdt_33
        push    hl
        ld      hl, 1                           ; read from filter
        call    ReadHL                          ; skip delimeter
        pop     hl
        jp      nc, gdt_loop                    ; ok, loop
        jp      gdt_Err2

;       filter code

.gdt_filter
        and     $5F                             ; $80-$FF -> $00-$1F, $40-$5F
        bit     6, a
        jr      z, gdt_36                       ; not month

;       month name

        bit     IDF_B_MONTHALPHA, d
        jp      nz, gdt_Sntx                    ; got alpha month already
        bit     IDF_B_MONTHNUM, d
        jr      z, gdt_35                       ; no month, it's ok
        bit     IDF_B_MONTHDAY, d
        jp      nz, gdt_Sntx                    ; have month & day already

        push    af                              ; move month -> monthday
        ld      a, c
        and     $E0                             ; keep weekday
        or      b                               ; insert monthday
        ld      c, a
        pop     af
        res     IDF_B_MONTHNUM, d
        set     IDF_B_MONTHDAY, d

.gdt_35
        and     $0F
        ld      b, a                            ; B=month
        set     IDF_B_MONTHALPHA, d
        jr      gdt_44

;       weekday, ordinal, AD/BC

.gdt_36
        cp      8
        jr      c, gdt_weekday                  ; weekday

        cp      12
        jr      nc, gdt_adbc                    ; not ordinal, must be AD/BC

        bit     IDF_B_ORDINAL, d
        jp      nz, gdt_Sntx                    ; already have ordinal
        bit     IDF_B_MONTHDAY, d
        jr      nz, gdt_37                      ; have day, it's ok

        bit     IDF_B_MONTHNUM, d
        jp      z, gdt_Sntx                     ; don't have month

        push    af                              ; move month -> monthday
        ld      a, c
        and     $E0                             ; keep weekday
        or      b                               ; insert monthday
        ld      c, a
        pop     af
        res     IDF_B_MONTHNUM, d
        set     IDF_B_MONTHDAY, d

;       ordinal

.gdt_37
        sub     7                               ; 1-4
        ld      e, a
        ld      a, c
        and     $1F                             ; monthday
        cp      31
        jr      nz, gdt_38
        sub     30                              ; 31->1st
        jr      gdt_39
.gdt_38
        cp      21
        jr      c, gdt_39
        cp      24
        jr      nc, gdt_39
        sub     20                              ; 21-24 -> 1st - 4th
.gdt_39
        cp      4
        jr      c, gdt_40
        ld      a, 4                            ; 4- -> th
.gdt_40
        cp      e                               ; does suffix match number?
        jp      nz, gdt_Sntx

        set     IDF_B_ORDINAL, d
        jr      gdt_44

;       AD/BC flag

.gdt_adbc
        bit     IDF_B_ADBC, d
        jp      nz, gdt_Sntx                    ; already have AC/BC

        sub     $0C                             ; negate HL if "BC"
        jr      z, gdt_42                       ; !! use RRA; jr nc
        push    de
        xor     a
        ld      d, a
        ld      e, a
        ex      de, hl
        sbc     hl, de
        pop     de
.gdt_42
        set     IDF_B_ADBC, d
        jr      gdt_44

;       weekday

.gdt_weekday
        bit     IDF_B_WEEKDAY, d
        jp      nz, gdt_Sntx                    ; already have weekday

        and     7                               ; store in C7-C5
        rrca
        rrca
        rrca
        or      c
        ld      c, a
        set     IDF_B_WEEKDAY, d

.gdt_44
        jp      gdt_33                          ; skip delimeter, loop

;       ----

;       convert internal date to ASCII string
;
;IN:    HL=source, DE=destination, IX=dest handle (if DE<2)
;       A=format, B=format, C=delimeter (if A5=1)
;OUT:   DE=output index/ptr
;       Fc=1, A=error

.GNPdt
        push    ix
        ld      a, 6                            ; reverse mode, max buffer size B bytes
        ld      hl, DateFilter                  ; standard date filter
        ld      b, 20
        OZ      GN_Flo                          ; open it
        jr      nc, pdt_1
        call    PutOsf_Err
        pop     ix
        ret

.pdt_1
        bit     1, (iy+OSFrame_A)               ; leading space?
        call    nz, pdtFlw_spc

        call    GetOsf_HL                       ; Read ABC from HL
        call    ReadHL                          ; !! more efficient with Read_ABC_HL
        ld      c, a
        call    ReadHL
        ld      b, a
        call    ReadHL
        call    GNDieMain                       ; convert ABC to zoned
        jr      nc, pdt_weekday
        ld      a, RC_Sntx                      ; Syntax Error
        jp      pdt_Err

.pdt_weekday
        bit     3, (iy+OSFrame_B)               ; output day?
        jr      z, pdt_date

        ld      a, c
        and     $E0                             ; day of week
        rla                                     ; !! rlca would be better
        rla
        rla
        rla
        or      $A0                             ; compressed weekday
        bit     1, (iy+OSFrame_B)               ; expanded day?
        jr      z, pdt_3
        res     5, a                            ; expanded weekday
.pdt_3
        call    pdtFlw
        call    pdtDelimeter

.pdt_date
        ld      a, (iy+OSFrame_A)
        bit     4, a                            ; European format
        jr      nz, pdt_Eur
        bit     3, a                            ; American format
        jr      nz, pdt_Am

        push    hl                              ; use OZ setting
        push    bc
        push    de
        dec     sp                              ; !! 'push af; ld hl,1' then 'pop af' below
        ld      hl, 0
        add     hl, sp
        ld      d, h
        ld      e, l
        ld      a, 1
        ld      bc, PA_Dat
        OZ      OS_Nq                           ; get date format
        ld      hl, 0
        add     hl, sp
        ld      a, (hl)
        inc     sp
        pop     de
        pop     bc
        pop     hl
        cp      'A'
        jr      z, pdt_Am
.pdt_Eur
        call    pdtPutDoM                       ; day.month
        call    pdtPutMon
        jr      pdt_year
.pdt_Am
        call    pdtPutMon                       ; month.day
        call    pdtPutDoM

.pdt_year
        ld      h, d                            ; make year positive
        ld      l, e
        bit     7, d
        jr      z, pdt_8
        xor     a
        ld      h, a
        ld      l, a
        sbc     hl, de
.pdt_8
        ld      b, h
        ld      c, l
        push    de
        ld      a, $21                          ; output 2 digits, leading zeroes
        bit     7, (iy+OSFrame_A)               ; output century?
        jr      z, pdt_9
        ld      h, b                            ; !! unnecessary, HL=BC already
        ld      l, c
        ld      de, 1000
        xor     a
        sbc     hl, de
        jr      nc, pdt_9                       ; year>=1000, no formatting
        ld      a, $41                          ; output 4 digits, leading zeroes
.pdt_9
        ld      hl, 2                           ; convert BC
        ld      de, 1                           ; write to filter
        OZ      GN_Pdn
        pop     de
        jr      nc, pdt_adbc
        cp      RC_Ovf                          ; overflow is ok
        jr      nz, pdt_Err

.pdt_adbc
        bit     4, (iy+OSFrame_B)               ; print AD/BC?  !! undocumented
        jr      nz, pdt_11
        bit     7, d                            ; print "BC" if negative
        jr      z, pdt_13
.pdt_11
        call    pdtFlw_spc
        ld      a, $8C                          ; "AD"
        bit     7, d
        jr      z, pdt_12
        inc     a                               ; "BC"
.pdt_12
        call    pdtFlw

.pdt_13
        bit     2, (iy+OSFrame_A)               ; trailing space?
        call    nz, pdtFlw_spc

;       move data from filter to DE(in)

.pdt_14
        OZ      GN_Flr                          ; get char
        jr      nc, pdt_15
        OZ      GN_Flf                          ; flush and exit
        jr      c, pdt_17
.pdt_15
        ex      (sp), ix
        call    WriteOsfDE
        ex      (sp), ix
        jr      nc, pdt_14

.pdt_Err
        call    PutOsf_Err

.pdt_17
        OZ      GN_Flc                          ; close filter

        bit     Z80F_B_C, (iy+OSFrame_F)
        jr      nz, pdt_18                      ; error, dont modify DE

        ld      a, (iy+OSFrame_D)               ; DE>255? update it
        or      a
        call    z, PutOsf_DE

.pdt_18
        pop     ix
        ret

;       support routines

.pdtFlw_spc
        ld      a, ' '
.pdtFlw
        OZ      GN_Flw
        ret     nc

.pdtSubErr                                      ; discard one call level and exit
        inc     sp
        inc     sp
        jr      pdt_Err

.pdtDelimeter
        bit     5, (iy+OSFrame_A)               ; use C as delimeter?
        jr      z, pdtFlw_spc
        ld      a, (iy+OSFrame_C)
        jr      pdtFlw

;       output day of month

.pdtPutDoM
        push    bc
        ld      a, c
        and     $1F                             ; day of month
        ld      c, a
        call    pdtNumC
        pop     bc
        jr      c, pdtSubErr

        bit     6, (iy+OSFrame_A)               ; date suffix?
        jr      z, pdtDelimeter

        ld      a, c
        and     $1F
        cp      31
        jr      nz, pdtdom_1
        sub     30                              ; 31st
        jr      pdtdom_2
.pdtdom_1
        cp      21
        jr      c, pdtdom_2
        cp      24
        jr      nc, pdtdom_2
        sub     20                              ; 21st-24th
.pdtdom_2
        cp      4
        jr      c, pdtdom_3
        ld      a, 4                            ; 4th-
.pdtdom_3
        add     a, $87                          ; "st" -1
        jr      pdtpm_2

;       output month

.pdtPutMon
        bit     0, (iy+OSFrame_B)               ; text month?
        jr      nz, pdtpm_1

        push    bc
        ld      c, b
        call    pdtNumC
        pop     bc
        jr      c, pdtSubErr
        jr      pdtDelimeter

.pdtpm_1
        ld      a, b
        or      $E0                             ; compressed month
        bit     2, (iy+OSFrame_B)               ; expanded month?
        jr      z, pdtpm_2
        res     5, a
.pdtpm_2
        call    pdtFlw
        jr      pdtDelimeter

;       ouput number in C

.pdtNumC
        push    de
        ld      b, 0
        ld      h, b                            ; convert BC
        ld      l, 2
        ld      de, 1
        ld      a, (iy+OSFrame_A)               ; zero blanking?
        and     1
        jr      z, pdtnumc_1
        or      $20                             ; $21 - 2 chars, leading zero  ! ld $21
.pdtnumc_1
        OZ      GN_Pdn                          ; Integer to ASCII conversion
        pop     de
        ret

;       ----

;       convert ASCII string to internal time
;IN:    HL=source, DE=destination, IX=source handle (if HL<2)
;OUT:   ABC=time (if DE=2), HL=input pointer


.GNGtm
        push    ix                              ; !! could create stack frame with push
        pop     de
        ld      ix, -6
        add     ix, sp
        ld      sp, ix
        ld      (ix+GTM_IX), e
        ld      (ix+GTM_IX+1), d
        xor     a
        ld      (ix+GTM_minute), a
        ld      (ix+GTM_second), a
        ld      (ix+GTM_centisec), a

        or      (iy+OSFrame_H)                  ; read data from memory?
        jr      z, gtm_hr
        ld      b, 0
        OZ      OS_Bix                          ; Bind in extended address
        push    de
        push    hl

.gtm_hr
        ld      a, 23                           ; 00-23
        call    gtmGetNum
        jp      c, gtm_Err
        jp      nz, gtm_Sntx                    ; bad number
        ld      (ix+GTM_hour), c

.gtm_min
        call    ReadHL
        ld      a, 59                           ; 00-59
        call    gtmGetNum
        jp      c, gtm_Err
        jr      z, gtm_3                        ; valid number
        cp      ':'                             ; !! this allows multiple ':'
        jr      z, gtm_min
        jp      gtm_Sntx
.gtm_3
        ld      (ix+GTM_minute), c
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1 if valid time ?

.gtm_sec
        call    ReadHL
        ld      a, 59                           ; 00-59
        call    gtmGetNum
        jp      c, gtm_11
        jr      z, gtm_5                        ; valid number
        cp      ':'                             ; !! this allows multiple ':'
        jr      z, gtm_sec
        jr      gtm_8                           ; no seconds
.gtm_5
        ld      (ix+GTM_second), c

.gtm_csec
        call    ReadHL
        ld      a, 99                           ; 00-99
        call    gtmGetNum
        jr      c, gtm_11
        jr      z, gtm_7                        ; valid number
        cp      ':'                             ; !! this allows multiple ':'
        jr      z, gtm_csec
        jr      gtm_8                           ; no centiseconds
.gtm_7
        ld      (ix+GTM_centisec), c

.gtm_8
        push    hl

        ld      b, 0
        ld      h, b
        ld      l, (ix+GTM_hour)
        ld      c, 360000/65536                 ; 1 hour = 360 000 csec
        ld      de, 360000%65536
        call    Mulu24                          ; hours to csecs
        push    bc
        push    hl

        ld      b, 0
        ld      h, b
        ld      l, (ix+GTM_minute)
        ld      c, b                            ; 1 minute = 6000 csec
        ld      de, 6000
        call    Mulu24                          ; minutes to csecs
        push    bc
        push    hl

        ld      b, 0
        ld      h, b
        ld      l, (ix+GTM_second)
        ld      c, b                            ; 1 second = 100 csec
        ld      de, 100
        call    Mulu24                          ; seconds to csecs
        push    bc
        push    hl

        xor     a                               ; add them all together into AHL
        ld      h, a
        ld      l, (ix+GTM_centisec)
        pop     de
        pop     bc
        add     hl, de
        adc     a, b

        pop     de
        pop     bc
        add     hl, de
        adc     a, b

        pop     de
        pop     bc
        add     hl, de
        adc     a, b

        ld      b, h                            ; store into a'BC
        ld      c, l
        ex      af, af'

        pop     hl

        ld      a, (iy+OSFrame_H)               ; OS_Box if needed
        or      a
        jr      z, gtm_9
        ex      af, af'
        exx
        pop     bc                              ; Os_Bix return to bcde'
        pop     de
        exx
        push    af                              ; ABC to stack
        push    bc
        exx                                     ; OS_Bix data from bcde' to BCDE
        push    de
        push    bc
        exx
        pop     bc
        pop     de
        call    gtmBox
        pop     bc                              ; restore a'BC
        pop     af
        ex      af, af'
.gtm_9
        ex      af, af'
        call    Wr_ABC_OsfDE                    ; return value
        jr      gtm_13

.gtm_Sntx
        ld      a, RC_Sntx
        jr      gtm_Err

.gtm_11
        cp      RC_Eof
        jr      z, gtm_8                        ; EOF is ok end mark

.gtm_Err
        call    PutOsf_Err
        ld      a, (iy+OSFrame_H)               ; OS_Box if needed
        or      a
        jr      z, gtm_13
        pop     bc
        pop     de
        call    gtmBox

.gtm_13
        ld      e, (ix+GTM_IX)
        ld      d, (ix+GTM_IX+1)
        call    PutOsf_HL
        ld      ix, 6                           ; !! 3*pop HL
        add     ix, sp
        ld      sp, ix
        push    de
        pop     ix
        ret

.gtmBox
        sbc     hl, bc                          ; output length
        ld      b, (iy+OSFrame_H)
        ld      c, (iy+OSFrame_L)
        add     hl, bc                          ; + original address
        OZ      OS_Box
        ret

;       support routines

.gtmGetNum
        ld      de, 2                           ; return in BC
        push    af
        ld      c, (ix+GTM_IX)
        ld      b, (ix+GTM_IX+1)
        push    bc
        ld      b, e                            ; #chars
        ex      (sp), ix
        OZ      GN_Gdn                          ; ASCII to integer conversion
        ld      e, a                            ; endchar
        pop     ix
        jr      c, gtm_SubErr                   ; Fc=1, error
        jr      nz, gtm_SubErr                  ; Fz=0, bad num
        ld      a, b
        or      a
        jr      nz, gtm_SubErr                  ; high byte not zero, bad num
        pop     af
        push    af                              ; keep two bytes extra in stack for clean exit
        cp      c
        jr      nc, gtmgn_ok
        or      a                               ; Fz=0, bad num
        jr      gtm_SubErr

.gtmgn_ok
        cp      a                               ; Fc=0, Fz=1, good num
.gtm_SubErr
        inc     sp
        inc     sp
        ld      a, e
        ret

;       ----

;       convert internal time to ASCII string
;
;IN:    HL=source, DE=destination, IX=destination handle (if DE<2)
;       A=format
;OUT:   DE=output pointer (if DE>255)

.GNPtm
        call    ReadHL                          ; !! more efficient with Read_ABC_HL
        ld      e, a
        call    ReadHL
        ld      d, a
        call    ReadHL
        ld      b, a
        ld      h, d
        ld      l, e                            ; time in BHL

        ld      a, b
        cp      8640000/65536                   ; 8640 000, centisecs/day
        jr      c, ptm_2                        ; less than 24h
        jr      nz, ptm_1
        push    hl
        ld      de, 8640000%65536
        sbc     hl, de
        pop     hl
        jr      c, ptm_2                        ; less than 24h
.ptm_1
        ld      de, 8640000%65536               ; normalize to 24h !! could we use code above?
        ld      a, b
        or      a
        sbc     hl, de
        sbc     a, 8640000/65536
        ld      b, a                            ; no loop, 48h would overflow
.ptm_2
        ld      c, 360000/65536                 ; 360 000, centisecs/hour
        ld      de, 360000%65536
        call    Divu24
        push    hl                              ; integer result
        ld      a, c
        push    af                              ; remainder
        push    de

        ld      a, ' '
        bit     1, (iy+OSFrame_A)               ; leading spaces?
        call    nz, ptmWrChar

        ld      a, l
        cp      13
        jr      c, ptm_3
        bit     7, (iy+OSFrame_A)               ; AM/PM display?
        jr      z, ptm_3
        sub     12                              ; 1-12
        ld      l, a
.ptm_3
        ld      c, l
        call    ptmWrNum

        ld      a, ':'                          ; !! this code is repeated, make sub ahead of WrChar: ... ret nz
        bit     6, (iy+OSFrame_A)               ; no delimeters?
        call    z, ptmWrChar
        pop     hl
        pop     af
        ld      b, a                            ; hour remainder in BHL
        ld      c, 0                            ; 6000, centisecs/minute
        ld      de, 6000
        call    Divu24
        ld      a, c
        push    af                              ; remainder
        push    de
        ld      c, l
        call    ptmWrNum

        bit     5, (iy+OSFrame_A)               ; display seconds?
        jr      z, ptm_4

        ld      a, ':'
        bit     6, (iy+OSFrame_A)               ; no delimeters?
        call    z, ptmWrChar
        pop     hl                              ; minute remainder
        pop     af
        ld      b, a
        ld      c, 0                            ; 100, centisecs in second
        ld      de, 100
        call    Divu24
        ld      a, c
        push    af                              ; remainder
        push    de
        ld      c, l
        call    ptmWrNum

        bit     4, (iy+OSFrame_A)               ; display centisecs?
        jr      z, ptm_4

        ld      a, ':'
        bit     6, (iy+OSFrame_A)               ; no delimeters?
        call    z, ptmWrChar
        pop     bc
        push    bc
        call    ptmWrNum

.ptm_4
        pop     af
        pop     af
        pop     bc
        push    af
        push    af
        push    af

        bit     7, (iy+OSFrame_A)               ; AM/PM?
        jr      z, ptm_6
        ld      hl, 'A'<<8|'M'                  ; AM
        ld      a, c
        cp      12
        jr      c, ptm_5
        ld      h, 'P'                          ; PM
.ptm_5
        ld      a, ' '
        call    ptmWrChar
        ld      a, h
        call    ptmWrChar
        ld      a, l
        call    ptmWrChar

.ptm_6
        ld      a, ' '
        bit     2, (iy+OSFrame_A)               ; trailing space?
        call    nz, ptmWrChar

.ptm_7
        pop     af
        pop     af
        pop     af
        ret

;       support routines

.ptmWrNum
        ld      b, 0
        ld      hl, 2                           ; convert BC
        call    GetOsf_DE
        ld      a, (iy+OSFrame_A)               ; leading zeroes?
        and     1
        or      $20                             ; 2 digits
        OZ      GN_Pdn                          ; put number
        jr      c, ptmSubErr

        ld      a, d                            ; update mem ptr if used
        or      a
        call    nz, PutOsf_DE
        ret

.ptmWrChar
        call    WriteOsfDE
        ret     nc
.ptmSubErr
        inc     sp
        inc     sp
        call    PutOsf_Err
        jr      ptm_7

;       ----

;       convert ASCII string to integer
;
;IN:    HL=source, DE=destination, IX=source handle (if HL<2)
;       B=max chars input
;OUT:   BC=integer (if DE<256), HL=source index/pointer, DE=destination pointer

.GNGdn
        xor     a
        ld      c, b
        push    bc
        ld      b, a                            ; debc'=0
        ld      c, a
        ld      d, a
        ld      e, a
        exx
        pop     bc

.gdn_1
        push    bc
        exx
        call    ReadOsfHL
        exx
        pop     bc
        exx
        jr      nc, gdn_2
        cp      RC_Eof                          ; EOF is ok if we already got number
        jp      nz, gdn_Err
        bit     Z80F_B_Z, (iy+OSFrame_F)
        jp      z, gdn_Err
        xor     a

.gdn_2
        ld      (iy+OSFrame_A), a               ; store last char

        sub     '0'                             ; char to digit, check for validity
        jr      c, gdn_4
        cp      10
        jr      nc, gdn_4

        call    gdnSlaDEBC                      ; *2
        push    de
        push    bc
        call    gdnSlaDEBC
        call    gdnSlaDEBC                      ; *8
        pop     hl
        add     hl, bc
        ld      b, h
        ld      c, l
        pop     hl
        adc     hl, de
        ex      de, hl                          ; *10
        jr      c, gdn_3                        ; overflow

        ld      l, a                            ; add in new digit
        ld      h, 0
        add     hl, bc
        ld      b, h
        ld      c, l
        ld      hl, 0
        adc     hl, de
        ld      d, h
        ld      e, l

.gdn_3
        ld      a, RC_Ovf
        jr      c, gdn_Err
        set     Z80F_B_Z, (iy+OSFrame_F)        ; got number
        exx
        djnz    gdn_1                           ; loop back for more
        exx
.gdn_4
        exx
        push    bc
        exx
        call    UngetOsfHL                      ; discard last char
        exx
        pop     bc
        exx
        bit     Z80F_B_Z, (iy+OSFrame_F)        ; got number?
        jr      z, gdn_8

        ld      a, (iy+OSFrame_H)               ; return index if HL<255
        or      a
        jr      nz, gdn_5
        exx
        ld      a, c
        sub     b
        exx
        ld      (iy+OSFrame_L), a               ; put index
.gdn_5
        ld      h, (iy+OSFrame_D)
        ld      l, (iy+OSFrame_E)
        ld      a, h
        or      a
        jr      z, gdn_retBC

        ex      de, hl                          ; write DEBC to DE(in)
        ld      a, c
        call    WriteDE
        ld      a, b
        call    WriteDE
        ld      a, l
        call    WriteDE
        ld      a, h
        call    WriteDE
        jr      gdn_8

.gdn_retBC
        call    PutOsf_BC
        ld      a, d                            ; overflow if >65535
        or      e
        ld      a, RC_Ovf
        jr      z, gdn_8

.gdn_Err
        call    PutOsf_Err

.gdn_8
        ret

;       multiple DEBC by two
.gdnSlaDEBC
        sla     c
        rl      b
        rl      e
        rl      d
        ret

;       ----

;       write integer as ASCII
;
;IN:    HL=source, DE=destination, IX=destination handle (if DE<2)
;       A=format
;OUT:   HL=source pointer, DE=destination index/pointer

.GNPdn
        ld      de, 0
        ld      a, h                            ; HL<255? use value BC
        or      a
        jr      z, pdn_1

        call    ReadHL                          ; !! more efficient with Read_ABC_HL + ReadHL
        ld      c, a
        call    ReadHL
        ld      b, a
        call    ReadHL
        ld      e, a
        call    ReadHL
        ld      d, a                            ; interger in DEBC

.pdn_1
        ld      hl, TenPower
        exx
        ld      hl, -10
        add     hl, sp
        ld      sp, hl
        ld      b, 9
        push    hl

.pdn_2
        push    bc
        push    hl
        exx                                     ; hl' - >HL, 10^x
        push    hl
        exx
        pop     hl
        ld      c, (hl)
        inc     hl
        ld      b, (hl)
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        push    hl                              ; HL -> hl'
        exx
        pop     hl

;       substract 10^x until underflow

        xor     a                               ; digit
.pdn_3
        push    de                              ; push 10^x
        push    bc
        exx
        or      a
        pop     hl
        sbc     hl, bc
        ex      (sp), hl
        sbc     hl, de
        push    hl
        jr      c, pdn_4                        ; no more
        exx
        pop     de
        pop     bc
        inc     a                               ; increment digit
        jr      pdn_3

.pdn_4
        inc     sp                              ; fix stack
        inc     sp
        inc     sp
        inc     sp
        pop     hl                              ; stack buffer
        pop     bc                              ; power count
        call    pdn_BufNChar                    ; remember digit
        djnz    pdn_2                           ; and loop

        exx
        ld      a, c                            ; output remainder
        exx
        add     a, '0'                          ; this forces '0' in case of zero
        ld      (hl), a

        exx
        ld      (iy+OSFrame_F), 0               ; no flags
        pop     hl

        ld      a, ' '
        bit     1, (iy+OSFrame_A)               ; output leading space?
        call    nz, pdn_WrChar

        ld      e, 0                            ; output counter
        ld      a, (iy+OSFrame_A)               ; number width
        and     $F0
        rra
        rra
        rra
        rra
        or      a
        ld      b, a
        jr      z, pdn_6                        ; zero width? use as much as needed

.pdn_5
        ld      a, b                            ; output space/zero until 10 chars left
        cp      11
        jr      c, pdn_6
        sub     a
        call    pdnGetNChar
        call    pdn_WrChar
        djnz    pdn_5                           ; decrement b and unconditional loop

.pdn_6
        ld      c, b
        ld      b, 10
.pdn_7
        ld      a, (hl)                         ; get next char
        inc     hl
        cp      ' '                             ; Fz=1 id space/zero
        jr      z, pdn_8
        cp      '0'
.pdn_8
        ex      af, af'
        ld      a, b
        dec     a
        jr      z, pdn_10                       ; B=1? output last digit

        bit     Z80F_B_Z, (iy+OSFrame_F)
        jr      nz, pdn_10                      ; already printing? output digit

        ld      a, c
        or      a
        jr      nz, pdn_9

        ex      af, af'                         ; max width unspecified
        jr      nz, pdn_11                      ; output if not space/zero
        jr      pdn_12                          ; else skip

.pdn_9
        cp      b
        jr      nc, pdn_10                      ; fits in buffer? output
        ex      af, af'
        jr      z, pdn_12                       ; space/zero? skip

        set     Z80F_B_C, (iy+OSFrame_F)        ; else overflow and skip
        ld      (iy+OSFrame_A), RC_Ovf
        jr      pdn_12

.pdn_10
        ex      af, af'
.pdn_11
        set     Z80F_B_Z, (iy+OSFrame_F)        ;  got number
        call    pdn_WrChar
.pdn_12
        djnz    pdn_7

        ld      a, ' '
        bit     2, (iy+OSFrame_A)               ; trailing space
        call    nz, pdn_WrChar

        ld      a, (iy+OSFrame_D)               ; output index if DE<256
        or      a
        jr      nz, pdn_x
        ld      (iy+OSFrame_E), e
        jr      pdn_x

;       write n in A to (HL) as char

.pdn_BufNChar
        call    pdnGetNChar
        ld      (hl), a
        inc     hl
        ret

;       write char A to DE(in)

.pdn_WrChar
        call    WriteOsfDE
        jr      c, pdn_15
        inc     e                               ; bump counter
        ret
.pdn_15
        inc     sp                              ; discard one call level
        inc     sp
        call    PutOsf_Err

;       restore stack and exit

.pdn_x
        ld      hl, 10
        add     hl, sp
        ld      sp, hl
        ret

;       convert n in A to ASCII char

.pdnGetNChar
        bit     Z80F_B_Z, (iy+OSFrame_F)        ; got number?
        jr      nz, pdnpn_2                     ; yes, return digit
        or      a
        jr      nz, pdnpn_1                     ; not zero, return digit

        bit     0, (iy+OSFrame_A)               ; no zero blanking?
        jr      nz, pdnpn_1                     ; return digit
        ld      a, ' '                          ; else space
        jr      pdnpn_3
.pdnpn_1
        set     Z80F_B_Z, (iy+OSFrame_F)        ; got number
.pdnpn_2
        add     a, '0'
.pdnpn_3
        ret

.TenPower
        defb    1000000000%256,1000000000/2**8%256,1000000000/2**16%256,1000000000/2**24%256
        defb     100000000%256, 100000000/2**8%256, 100000000/2**16%256, 100000000/2**24%256
        defb      10000000%256,  10000000/2**8%256,  10000000/2**16%256,  10000000/2**24%256
        defb       1000000%256,   1000000/2**8%256,   1000000/2**16%256,   1000000/2**24%256
        defb        100000%256,    100000/2**8%256,    100000/2**16%256,    100000/2**24%256
        defb         10000%256,     10000/2**8%256,     10000/2**16%256,     10000/2**24%256
        defb          1000%256,      1000/2**8%256,      1000/2**16%256,      1000/2**24%256
        defb           100%256,       100/2**8%256,       100/2**16%256,       100/2**24%256
        defb            10%256,        10/2**8%256,        10/2**16%256,        10/2**24%256

; OZ Standard Date Filter for GN_Gdt & GN_Pdt
.DateFilter
if KBDK
        defw    end_DateFilter-DateFilter
        defb    128+32+16,$80                   ; Left side contains ISO chars, Alpha & punctuation
        defm    7,"Mandag",           2,$81
        defm    4,"Man",              2,$A1
        defm    8,"Tirsdag",          2,$82
        defm    4,"Tir",              2,$A2
        defm    7,"Onsdag",           2,$83
        defm    4,"Ons",              2,$A3
        defm    8,"Torsdag",          2,$84
        defm    4,"Tor",              2,$A4
        defm    7,"Fredag",           2,$85
        defm    4,"Fre",              2,$A5
        defm    7,"L",$f8,"rdag",     2,$86     ; Lørdag (Saturday)
        defm    4,"L",$f8,"r",        2,$A6     ; Lør (Sat)
        defm    7,"S",$f8,"ndag",     2,$87     ; Søndag (Sunday)
        defm    4,"S",$f8,"n",        2,$A7     ; Søn (Sun)
        defm    2,".",                2,$88     ; (danish don't use 'first', but '.')
        defm    2,".",                2,$89     ; (danish don't use '2nd', but '.')
        defm    2,".",                2,$8A     ; (danish don't use '3rd', but '.')
        defm    2,".",                2,$8B     ; (danish don't use 'th', but '.')
        defm    4,"eKr",              2,$8C     ; (danish version of 'AD')
        defm    4,"fKr",              2,$8D     ; (danish version of 'BC')
        defm    7,"Januar",           2,$C1
        defm    4,"Jan",              2,$E1
        defm    8,"Februar",          2,$C2
        defm    4,"Feb",              2,$E2
        defm    6,"Marts",            2,$C3
        defm    4,"Mar",              2,$E3
        defm    6,"April",            2,$C4
        defm    4,"Apr",              2,$E4
        defm    4,"Maj",              2,$C5
        defm    4,"Maj",              2,$E5
        defm    5,"Juni",             2,$C6
        defm    4,"Jun",              2,$E6
        defm    5,"Juli",             2,$C7
        defm    4,"Jul",              2,$E7
        defm    7,"August",           2,$C8
        defm    4,"Aug",              2,$E8
        defm    10,"September",       2,$C9
        defm    4,"Sep",              2,$E9
        defm    8,"Oktober",          2,$CA
        defm    4,"Okt",              2,$EA
        defm    9,"November",         2,$CB
        defm    4,"Nov",              2,$EB
        defm    9,"December",         2,$CC
        defm    4,"Dec",              2,$EC
ENDIF

if KBSE
        defw    end_DateFilter-DateFilter
        defb    128+32+16,$80                   ; Left side contains ISO chars, Alpha & punctuation
        defm    7,"M",$E5,"ndag",     2,$81     ; Måndag
        defm    4,"M",$E5,"n",        2,$A1     ; Mån
        defm    7,"Tisdag",           2,$82
        defm    4,"Tis",              2,$A2
        defm    7,"Onsdag",           2,$83
        defm    4,"Ons",              2,$A3
        defm    8,"Torsdag",          2,$84
        defm    4,"Tor",              2,$A4
        defm    7,"Fredag",           2,$85
        defm    4,"Fre",              2,$A5
        defm    7,"L",$f6,"rdag",     2,$86     ; Lördag (Saturday)
        defm    4,"L",$f6,"r",        2,$A6     ; Lör (Sat)
        defm    7,"S",$f6,"ndag",     2,$87     ; Söndag (Sunday)
        defm    4,"S",$f6,"n",        2,$A7     ; Sön (Sun)
        defm    2,".",                2,$88     ; (swedish don't use 'first', but '.')
        defm    2,".",                2,$89     ; (swedish don't use '2nd', but '.')
        defm    2,".",                2,$8A     ; (swedish don't use '3rd', but '.')
        defm    2,".",                2,$8B     ; (swedish don't use 'th', but '.')
        defm    4,"eKr",              2,$8C     ; (swedish version of 'AD')
        defm    4,"fKr",              2,$8D     ; (swedish version of 'BC')
        defm    8,"Januari",          2,$C1
        defm    4,"Jan",              2,$E1
        defm    9,"Februari",         2,$C2
        defm    4,"Feb",              2,$E2
        defm    5,"Mars",             2,$C3
        defm    4,"Mar",              2,$E3
        defm    6,"April",            2,$C4
        defm    4,"Apr",              2,$E4
        defm    4,"Maj",              2,$C5
        defm    4,"Maj",              2,$E5
        defm    5,"Juni",             2,$C6
        defm    4,"Jun",              2,$E6
        defm    5,"Juli",             2,$C7
        defm    4,"Jul",              2,$E7
        defm    8,"Augusti",          2,$C8
        defm    4,"Aug",              2,$E8
        defm    10,"September",       2,$C9
        defm    4,"Sep",              2,$E9
        defm    8,"October",          2,$CA
        defm    4,"Oct",              2,$EA
        defm    9,"November",         2,$CB
        defm    4,"Nov",              2,$EB
        defm    9,"December",         2,$CC
        defm    4,"Dec",              2,$EC
ENDIF

if KBFI
        defw    end_DateFilter-DateFilter
        defb    128+64+32+16,$80                 ; Left side contains ISO, Numeric, Alpha & punctuation
        defm    10,"Maanantai",       2,$81
        defm    3,"Ma",               2,$A1
        defm    8,"Tiistai",          2,$82
        defm    3,"Ti",               2,$A2
        defm    12,"Keskiviikko",     2,$83
        defm    3,"Ke",               2,$A3
        defm    8,"Torstai",          2,$84
        defm    3,"To",               2,$A4
        defm    10,"Perjantai",       2,$85
        defm    3,"Pe",               2,$A5
        defm    9,"Lauantai",         2,$86
        defm    3,"La",               2,$A6
        defm    10,"Sunnuntai",       2,$87
        defm    3,"Su",               2,$A7
        defm    2,".",                2,$88     ; (finnish don't use 'first', but '.')
        defm    2,".",                2,$89     ; (finnish don't use '2nd', but '.')
        defm    2,".",                2,$8A     ; (finnish don't use '3rd', but '.')
        defm    2,".",                2,$8B     ; (finnish don't use 'th', but '.')
        defm    4,"eKr",              2,$8C
        defm    4,"jKr",              2,$8D
        defm    9,"Tammikuu",         2,$C1
        defm    3,"1.",               2,$E1
        defm    9,"Helmikuu",         2,$C2
        defm    3,"2.",               2,$E2
        defm    10,"Maaliskuu",       2,$C3
        defm    3,"3.",               2,$E3
        defm    9,"Huhtikuu",         2,$C4
        defm    3,"4.",               2,$E4
        defm    9,"Toukokuu",         2,$C5
        defm    3,"5.",               2,$E5
        defm    8,"Kes",$e4,"kuu",    2,$C6
        defm    3,"6.",               2,$E6
        defm    9,"Hein",$e4,"kuu",   2,$C7
        defm    3,"7.",               2,$E7
        defm    7,"Elokuu",           2,$C8
        defm    3,"8.",               2,$E8
        defm    8,"Syyskuu",          2,$C9
        defm    3,"9.",               2,$E9
        defm    8,"Lokakuu",          2,$CA
        defm    4,"10.",              2,$EA
        defm    10,"Marraskuu",       2,$CB
        defm    4,"11.",              2,$EB
        defm    9,"Joulukuu",         2,$CC
        defm    4,"12.",              2,$EC
ENDIF

if KBFR
        defw    end_DateFilter-DateFilter
        defb    128+32+16,$80                   ; Left side contains ISO chars, Alpha & punctuation
        defm    6,"Lundi",            2,$81
        defm    4,"Lun",              2,$A1
        defm    6,"Mardi",            2,$82
        defm    4,"Mar",              2,$A2
        defm    9,"Mercredi",         2,$83
        defm    4,"Mer",              2,$A3
        defm    6,"Jeudi",            2,$84
        defm    4,"Jeu",              2,$A4
        defm    9,"Vendredi",         2,$85
        defm    4,"Ven",              2,$A5
        defm    7,"Samedi",           2,$86
        defm    4,"Sam",              2,$A6
        defm    9,"Dimanche",         2,$87
        defm    4,"Dim",              2,$A7
        defm    2,".",                2,$88     ; 'st'
        defm    2,".",                2,$89     ; 'nd'
        defm    2,".",                2,$8A     ; 'rd'
        defm    2,".",                2,$8B     ; 'th'
        defm    5,"avJC",             2,$8C     ; 'AD'
        defm    5,"apJC",             2,$8D     ; 'BC'
        defm    8,"Janvier",          2,$C1
        defm    5,"Janv",             2,$E1
        defm    8,"F",$e9,"vrier",    2,$C2
        defm    4,"F",$e9,"v",        2,$E2
        defm    5,"Mars",             2,$C3
        defm    5,"Mars",             2,$E3
        defm    6,"Avril",            2,$C4
        defm    4,"Avr",              2,$E4
        defm    4,"Mai",              2,$C5
        defm    4,"Mai",              2,$E5
        defm    5,"Juin",             2,$C6
        defm    5,"Juin",             2,$E6
        defm    8,"Juillet",          2,$C7
        defm    5,"Juil",             2,$E7
        defm    5,"Ao",$FB,"t",       2,$C8
        defm    5,"Ao",$FB,"t",       2,$E8
        defm    10,"Septembre",       2,$C9
        defm    5,"Sept",             2,$E9
        defm    8,"Octobre",          2,$CA
        defm    4,"Oct",              2,$EA
        defm    9,"Novembre",         2,$CB
        defm    4,"Nov",              2,$EB
        defm    9,"D",$e9,"cembre",   2,$CC
        defm    4,"D",$e9,"c",        2,$EC
ENDIF

if !KBFI & !KBSE & !KBFR & !KBDK
        defw    end_DateFilter-DateFilter
        defb    $20,$80
        defm    7,"Monday",           2,$81
        defm    4,"Mon",              2,$A1
        defm    8,"Tuesday",          2,$82
        defm    4,"Tue",              2,$A2
        defm    10,"Wednesday",       2,$83
        defm    4,"Wed",              2,$A3
        defm    9,"Thursday",         2,$84
        defm    4,"Thu",              2,$A4
        defm    7,"Friday",           2,$85
        defm    4,"Fri",              2,$A5
        defm    9,"Saturday",         2,$86
        defm    4,"Sat",              2,$A6
        defm    7,"Sunday",           2,$87
        defm    4,"Sun",              2,$A7
        defm    3,"st",               2,$88
        defm    3,"nd",               2,$89
        defm    3,"rd",               2,$8A
        defm    3,"th",               2,$8B
        defm    3,"AD",               2,$8C
        defm    3,"BC",               2,$8D
        defm    8,"January",          2,$C1
        defm    4,"Jan",              2,$E1
        defm    9,"February",         2,$C2
        defm    4,"Feb",              2,$E2
        defm    6,"March",            2,$C3
        defm    4,"Mar",              2,$E3
        defm    6,"April",            2,$C4
        defm    4,"Apr",              2,$E4
        defm    4,"May",              2,$C5
        defm    4,"May",              2,$E5
        defm    5,"June",             2,$C6
        defm    4,"Jun",              2,$E6
        defm    5,"July",             2,$C7
        defm    4,"Jul",              2,$E7
        defm    7,"August",           2,$C8
        defm    4,"Aug",              2,$E8
        defm    10,"September",       2,$C9
        defm    4,"Sep",              2,$E9
        defm    8,"October",          2,$CA
        defm    4,"Oct",              2,$EA
        defm    9,"November",         2,$CB
        defm    4,"Nov",              2,$EB
        defm    9,"December",         2,$CC
        defm    4,"Dec",              2,$EC
ENDIF
.end_DateFilter

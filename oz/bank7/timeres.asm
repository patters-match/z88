; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d564
;
; $Id$
; -----------------------------------------------------------------------------

        Module TimeRes

        include "time.def"
        include "sysvar.def"

xdef    TimeReset                               ; bank7/reset.asm

xref    IntSecond                               ; bank0/int.asm
xref    MS1BankA                                ; bank0/misc5.asm

;       ----

.TimeReset
        ld      a, (ubResetType)
        or      a
        jr      z, SetInitialTime               ; hard reset, init system clock
        ld      hl, ubTIM1_A                    ; use timer @ A2 or A7
        ld      a, (ubTimeBufferSelect)         ; depending of bit 0 od A0
        rrca
        jr      nc, tr_1
        ld      l, <ubTIM1_B                    ; $A7
.tr_1
        ld      c, (hl)                         ; ld bhlc, (hl)
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        ex      de, hl

        ld      a, 1                            ; update base time
        OZ      GN_Msc
.tr_2
        jp      IntSecond


.SetInitialTime
        ld      de, $year
        ld      bc, $month<<8 | $day
        OZ      GN_Dei                          ; convert to internal format
        ld      hl, 2                           ; date in ABC
        OZ      GN_Pmd                          ; set machine date according to current date of compilation

        defc elapsedtime_centisecs = $hour*60*60*100 + $minute*60*100 + $second*100

        ld      a, elapsedtime_centisecs/65536
        ld      b, [elapsedtime_centisecs - ((elapsedtime_centisecs/65536) * 65536)] / 256
        ld      c, [elapsedtime_centisecs - ((elapsedtime_centisecs/65536) * 65536)] % 256
        OZ      GN_Pmt                          ; set clock according to current time of compilation
        jr      tr_2

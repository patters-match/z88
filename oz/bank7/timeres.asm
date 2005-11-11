; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d564
;
; $Id$
; -----------------------------------------------------------------------------

        Module TimeRes

        include "time.def"
        include "sysvar.def"

xdef    TimeReset                               ; Reset5

;       bank 0

xref    IntSecond
xref    MS1BankA

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
        ld      de, 2005
        ld      bc, 11<<8|10                    ; November, 10th (my anniversary!)
        OZ      GN_Dei                          ; convert to internal format
        ld      hl, 2                           ; date in ABC
        OZ      GN_Pmd                          ; set machine date
        xor     a
        ld      b, a
        ld      c, a
        OZ      GN_Pmt                          ; set clock to midnight
        jr      tr_2

; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d564
;
; $Id$
; -----------------------------------------------------------------------------

        Module TimeRes

        org $9564                               ; 65 bytes

        include "time.def"
        include "sysvar.def"

xdef    TimeReset                               ; Reset5

;       bank 0

xref    IntSecond
xref    MS1BankA

;       ----

.TimeReset
        ld      a, $21                          ; bind in b21

        call    MS1BankA
        ld      a, (ubResetType)
        or      a
        call    z, SetInitialTime               ; hard reset, init system clock
        jr      z, tr_2                         ; hard reset? skip

        ld      hl, $4000+$A2                   ; use timer @ A2 or A7
        ld      a, ($4000+$A0)                  ; depending of bit 0 od A0
        rrca
        jr      nc, tr_1
        ld      l, $A7

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
        push    af
        ld      de, 1992
 IF     OZ40001=0
        ld      bc, 8<<8|3                      ; August 3rd
 ELSE
        ld      bc, 3<<8|15                     ; March 15th
 ENDIF
        OZ      GN_Dei                          ; convert to internal format
        ld      hl, 2                           ; date in ABC
        OZ      GN_Pmd                          ; set machine date
        xor     a
        ld      b, a
        ld      c, a
        OZ      GN_Pmt                          ; set clock to midnight
        pop     af
        ret

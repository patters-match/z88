; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $39a5
;
; $Id$
; -----------------------------------------------------------------------------

        module  PFilter

        include "all.def"
        include "sysvar.def"
        include "bank7.def"

        org     $f9a5                           ; 45 bytes

xdef    PrFilterCall
xdef    TogglePrFilter

xref    MS2BankA

; Call printer filter in bank 3
; 
; A=C0/C3/C6

.PrFilterCall

        ld      h, a                            ; remember A
        ld      a, (BLSC_SR2)                   ; remember S2
        push    af
        ld      a, OZBANK_PRFILTER              ; bind code in S2
        call    MS2BankA
        ld      a, h

        ld      h, >PrntChar
        push    ix
        call    $00df                           ; jp (hl)
        pop     ix

        ex      af, af'
        pop     af                              ; restore S1
        call    MS2BankA
        ex      af, af'
        ret

;       ----

; printer filter enable/disable

.TogglePrFilter 
        push    hl
        ld      a, (ubScreenBase)               ; screen base bank
        ld      b, a
        ld      hl, sbf_VDU1&$3fff
        ld      a, (sbf_PrefixSeq)
        dec     a                               ; -1 for '.'
        ld      c, a                            ; length
        OZ      DC_Gen
        pop     hl
        ret


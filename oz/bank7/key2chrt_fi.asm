; FI/SE
;
; This table is used by ScrDrv1.asm for keyboard / screen conversion
; It is the bridge between key / char code / font for localised versions of OZ.
;
; structure : internal key code / iso latin 1 code / order in the lores1 font low bute, high byte
; order in the lores1 font range : 000-1BF (NB: 1C0-1FF are the 64 UGD chars)
; this table must be in K1 (b07) and shouldn't cross $3300 (start of the keymap)

.Key2Chr_tbl
        defb    $A3                             ; £ internal code
.Chr2VDU_tbl
        defb    $A3                             ; £ char code
.VDU2Chr_tbl
        defb    $1F,0                           ; VDU low byte, high byte in the font
        defb    $A4,$80,$20,$00                 ; €
        defb    $A5,$F6,$18,$00                 ; ö
        defb    $A6,$E4,$1A,$00                 ; ä
        defb    $A7,$E5,$1C,$00                 ; å
        defb    $AB,$D6,$19,$00                 ; Ö
        defb    $AC,$C4,$1B,$00                 ; Ä
        defb    $AD,$C5,$1D,$00                 ; Å
        defb    0,0,0,0                         ; table terminator

        defs    $2D ($ff)

; UK
;
; this table is used by ScrDrv1.asm for keyboard / screen conversion
; it is the bridge between key / char code / font for localised versions of OZ.
;
; structure : internal key code / iso latin 1 code / order in the lores1 font low bute, high byte
; order in the lores1 font range : 000-1BF (NB: 1C0-1FF are the 64 UGD chars)
; this table must be in K1 (b07) and shouldn't cross $3300 (start of the keymap)

xdef    Key2Chr_tbl
xdef    Chr2VDU_tbl
xdef    VDU2Chr_tbl

.Key2Chr_tbl
        defb    $A3                             ; £ internal code
.Chr2VDU_tbl
        defb    $A3                             ; £ char code
.VDU2Chr_tbl
        defb    $1F,0                           ; VDU low byte, high byte in the font
        defb    0,0,0,0                         ; table terminator

        defs    $49 ($ff)

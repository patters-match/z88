;        Module Key2Char_FR


; FRENCH version
;
; this table is used by ScrDrv1.asm for keyboard / screen conversion
; it is the bridge between key / char code / font for localised versions of OZ.
;
; structure : internal key code / iso latin 1 code / order in the lores1 font low bute, high byte
; order in the lores1 font range : 000-1BF (NB: 1C0-1FF are the 64 UGD chars)
; this table must be in K1 (b07) and shouldn't cross $3300 (start of the keymap)

.Key2Chr_tbl
        defb    $A3                             ; � internal code
.Chr2VDU_tbl
        defb    $A3                             ; � char code
.VDU2Chr_tbl
        defb    $1F,0                           ; VDU low byte, high byte in the font
        defb    $A1,$A7,$19,$01                 ; �
        defb    $A2,$B0,$1A,$01                 ; �
        defb    $A4,$80,$20,$00                 ; �
        defb    $B9,$E0,$1B,$00                 ; �
        defb    $BA,$E2,$19,$00                 ; �
        defb    $DF,$E7,$1E,$00                 ; �
        defb    $BB,$E8,$1C,$00                 ; �
        defb    $BC,$E9,$1D,$00                 ; �
        defb    $BD,$EA,$1A,$00                 ; �
        defb    $BE,$EE,$98,$00                 ; �
        defb    $BF,$EF,$18,$01                 ; �
        defb    $C9,$F4,$99,$00                 ; �
        defb    $CA,$F9,$18,$00                 ; �
        defb    $CB,$FB,$9A,$00                 ; �
        defb    0,0,0,0                         ; table terminator

        defs    $11 ($ff)


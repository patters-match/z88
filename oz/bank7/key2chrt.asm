;        Module Key2Char_FR


module Key2Char_Table

; INTERNATIONAL version
;
; this table is used by ScrDrv1.asm for keyboard / screen conversion
; it is the bridge between key / char code / lores font.
;
; structure : internal key code / iso latin 1 code / lores1 bitmap low byte, high byte
;
; order in the lores1 font bitmap range : 000-1BF (NB: 1C0-1FF are the 64 UGD chars)
;

xdef    Key2Chr_tbl
xdef    Chr2VDU_tbl
xdef    VDU2Chr_tbl

.Key2Chr_tbl
        defb    $A3                             ; £ internal code
.Chr2VDU_tbl
        defb        $A3                         ; £ char code
.VDU2Chr_tbl
        defb            $1F,$00                 ; Lores low byte, high byte in the font
        defb    $91,$A1,$86,$00                 ; ¡
        defb    $92,$BF,$87,$00                 ; ¿
        defb    $A1,$A7,$01,$00                 ; §
        defb    $A2,$B0,$02,$00                 ; °
        defb    $A4,$80,$7F,$00                 ; € 
        defb    $A5,$F6,$1A,$00                 ; ö
        defb    $A6,$E4,$0F,$00                 ; ä
        defb    $AB,$D6,$0B,$00                 ; Ö
        defb    $AC,$C4,$08,$00                 ; Ä
        defb    $AD,$E1,$80,$00                 ; á
        defb    $AE,$ED,$81,$00                 ; í
        defb    $AF,$F3,$82,$00                 ; ó
        defb    $B9,$E0,$0D,$00                 ; à
        defb    $BA,$E2,$0E,$00                 ; â
        defb    $BB,$E8,$13,$00                 ; è
        defb    $BC,$E9,$14,$00                 ; é
        defb    $BD,$EA,$15,$00                 ; ê
        defb    $BE,$EE,$17,$00                 ; î
        defb    $BF,$EF,$18,$00                 ; ï
        defb    $C9,$F4,$19,$00                 ; ô
        defb    $CA,$F9,$1C,$00                 ; ù
        defb    $CB,$FB,$1D,$00                 ; û
        defb    $CC,$DF,$06,$00                 ; ß
        defb    $CD,$EC,$00,$01                 ; ì
        defb    $CE,$F2,$01,$01                 ; ò
        defb    $CF,$FA,$83,$00                 ; ú
        defb    $D9,$EB,$16,$00                 ; ë
        defb    $DA,$E5,$10,$00                 ; å
        defb    $DB,$E6,$11,$00                 ; æ
        defb    $DC,$FC,$1E,$00                 ; ü
        defb    $DD,$F8,$1B,$00                 ; ø
        defb    $DE,$F1,$84,$00                 ; ñ
        defb    $DF,$E7,$12,$00                 ; ç
        defb    $E9,$CB,$04,$00                 ; Ë
        defb    $EA,$C5,$09,$00                 ; Å
        defb    $EB,$C6,$0A,$00                 ; Æ
        defb    $EC,$DC,$05,$00                 ; Ü
        defb    $ED,$D8,$0C,$00                 ; Ø
        defb    $EE,$D1,$85,$00                 ; Ñ
        defb    $EF,$C7,$03,$00                 ; Ç
        defb    $00,$00,$00,$00                 ; table terminator
        

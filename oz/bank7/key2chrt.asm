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
        defb    $A3                             ; � internal code
.Chr2VDU_tbl
        defb        $A3                         ; � char code
.VDU2Chr_tbl
        defb            $1F,$00                 ; Lores low byte, high byte in the font
        defb    $A1,$A7,$01,$00                 ; �
        defb    $A2,$B0,$02,$00                 ; �
        defb    $A4,$80,$7F,$00                 ; � 
        defb    $A5,$F6,$1A,$00                 ; �
        defb    $A6,$E4,$0F,$00                 ; �
        defb    $A7,$EB,$16,$00                 ; �
;        defb    $A8,$FC,$1E,$00                 ; �
        defb    $AB,$D6,$0B,$00                 ; �
        defb    $AC,$C4,$08,$00                 ; �
        defb    $B9,$E0,$0D,$00                 ; �
        defb    $BA,$E2,$0E,$00                 ; �
        defb    $BB,$E8,$13,$00                 ; �
        defb    $BC,$E9,$14,$00                 ; �
        defb    $BD,$EA,$15,$00                 ; �
        defb    $BE,$EE,$17,$00                 ; �
        defb    $BF,$EF,$18,$00                 ; �
        defb    $C9,$F4,$19,$00                 ; �
        defb    $CA,$F9,$1C,$00                 ; �
        defb    $CB,$FB,$1D,$00                 ; �
        defb    $DA,$E5,$10,$00                 ; �
        defb    $DB,$E6,$11,$00                 ; �
        defb    $DD,$F8,$1B,$00                 ; �
        defb    $DF,$E7,$12,$00                 ; �
        defb    $ED,$D8,$0C,$00                 ; �
        defb    $EB,$C6,$0A,$00                 ; �
        defb    $EA,$C5,$09,$00                 ; �
        defb    $00,$00,$00,$00                 ; table terminator
        

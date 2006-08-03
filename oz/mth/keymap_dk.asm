MODULE  Keymap_DK

ORG     $0300
xdef    Keymap_DK

; all keymap tables in one page

; structure of shift, square, and diamond tables:

;       dc.b n                    number of character pairs in table
;       dc.b inchar,outchar       translates inchar into outchar
;       dc.b inchar,outchar,...   entries are ordered in ascending inchar order

; structure of deadkey table:

;       dc.b n                    number of deadkeys in table
;       dc.b keycode,offset       keycode of deadkey, offset into subtable for that key
;       dc.b keycode,offset,...   offset is table address low byte
;                                 entries are ordered in ascending keycode order
;
;       dc.b char                 deadkey subtables start with extra byte - 8x8 char code for OZ window
;       dc.b n                    after that they follow standard table format of num + n*(in,out)
;       dc.b inchar, outchar,...

;*UDRL  cursor keys             ff fe fd fc
;*S     space                   20
;^MTDE  enter tab del esc       e1 e2 e3 e4
;#MIH   menu index help         e5 e6 e7
;!DSLRC <> [] ls rs cl          c8 b8 aa a9 a8

.Keymap_DK
        defb    $38,$37,$6e,$68,$79,$36,$e1,$e3         ; 8  7  n  h  y  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$ff,$2f         ; i  u  b  g  t  5  *U /
        defb    $6f,$6a,$76,$66,$72,$34,$fe,$2b         ; o  j  v  f  r  4  *D +
        defb    $39,$6b,$63,$64,$65,$33,$fd,$3d         ; 9  k  c  d  e  3  *R =
        defb    $70,$6d,$78,$73,$77,$32,$fc,$27         ; p  m  x  s  w  2  *L '
        defb    $30,$6c,$7a,$61,$71,$31,$20,$da         ; 0  l  z  a  q  1  *S å
        defb    $dd,$db,$2c,$e5,$c8,$e2,$aa,$e7         ; ø  æ  ,  #M !D ^T !L  #H
        defb    $a3,$2d,$2e,$e8,$e6,$1b,$b8,$a9         ; £  -  .  !C #I ^E !S !R

.ShiftTable
        defb    (DmndTable - ShiftTable - 1)/2
        defb    $1b,$d4                                 ; esc   d4
        defb    $20,$d0                                 ; space d0
        defb    $27,$22, $2b,$3e, $2c,$3b, $2d,$5f      ; ' "   + >   , ;   - _
        defb    $2e,$3a, $2f,$3f, $30,$29, $31,$21      ; . :   / ?   0 )   1 !
        defb    $32,$40, $33,$23, $34,$24, $35,$25      ; 2 @   3 #   4 $   5 %
        defb    $36,$5e, $37,$26, $38,$2a, $39,$28      ; 6 ^   7 &   8 *   9 (
        defb    $3d,$3c, $a3,$7e                        ; = <   £ ~
        defb    $DA,$EA                                 ; å Å
        defb    $DB,$EB                                 ; æ Æ
        defb    $DD,$ED                                 ; ø Ø

.DmndTable
        defb    (SqrTable - DmndTable - 1)/2
        defb    $1b,$c4         ; esc   c4
        defb    $20,$a0         ; spc   a0
        defb    $27,$60         ; '     `
        defb    $2b,$00         ; +     00
        defb    $2c,$1b         ; ,     1b
        defb    $2d,$1f         ; -     1f
        defb    $2e,$1d         ; .     1d
        defb    $2f,$1c         ; /     1c
        defb    $3d,$00         ; =     00
        defb    $5f,$1f         ; 5f    1f
        defb    $a3,$a4         ; £     €
        defb    $da,$7d         ; å     }
        defb    $db,$7b         ; æ     {
        defb    $dd,$7c         ; ø     |


.SqrTable
        defb    (DeadTable - SqrTable - 1)/2
        defb    $1B,$B4         ; esc   b4
        defb    $20,$B0         ; spc   b0
        defb    $2B,$80         ; +     80
        defb    $2C,$9B         ; ,     9b
        defb    $2D,$9F         ; -     9f
        defb    $2E,$9D         ; .     9d
        defb    $2F,$9C         ; /     9c
        defb    $3D,$80         ; =     80
        defb    $5F,$9F         ; 5f    9f
        defb    $A3,$9E         ; £     9e
        defb    $da,$5d         ; å     ]
        defb    $db,$5b         ; æ     [
        defb    $dd,$5c         ; ø     \

.DeadTable
        defb    0


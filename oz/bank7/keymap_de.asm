; Bank 7 @ S2           ROM offset $1d300

; all keymap tables in one page

; structure of shift, square, and diamond tables:

;       dc.b n                    number of character pairs in table
;       dc.b inchar,outchar       translates inchar into outchar
;       dc.b inchar,outchar,...   entries are ordered in ascending inchar order

; capsable table:

;       dc.b n                    number of character pairs in table
;       dc.b lcase,ucase          translates lcase into ucase and vice versa
;       dc.b lcase,ucase,...      entries can be unsorted, but why not sort them?

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

.KeyMatrix
        defb    $38,$37,$6e,$68,$7a,$36,$e1,$e3         ; 8  7  n  h  z  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$ff,$3c         ; i  u  b  g  t  5  *U <
        defb    $6f,$6a,$76,$66,$72,$34,$fe,$27         ; o  j  v  f  r  4  *D '
        defb    $39,$6b,$63,$64,$65,$33,$fd,$cc         ; 9  k  c  d  e  3  *R ss
        defb    $70,$6d,$78,$73,$77,$32,$fc,$2b         ; p  m  x  s  w  2  *L +
        defb    $30,$6c,$79,$61,$71,$31,$20,$dd         ; 0  l  y  a  q  1  *S ü
        defb    $d9,$dc,$2c,$e5,$c8,$e2,$00,$e7         ; ä  ö  ,  #M !D ^T !L #H
        defb    $23,$2d,$2e,$e8,$e6,$1b,$b8,$00         ; #  -  .  !C #I ^E !S !R

.ShiftTable
        defb    (CapsTable - ShiftTable - 1)/2
        defb    $1b,$d4                                 ; esc   d4
        defb    $20,$d0                                 ; space d0
        defb    $23,$5e, $27,$60, $2b,$2a, $2c,$3b      ; # ^   ' `   + *   , ;
        defb    $2d,$5f, $2e,$3a, $30,$3d, $31,$21      ; - _   . :   0 =   1 !
        defb    $32,$22, $33,$a1, $34,$24, $35,$25      ; 2 "   3 §   4 $   5 %
        defb    $36,$26, $37,$2f, $38,$28, $39,$29      ; 6 &   7 /   8 (   9 )
        defb    $3c,$3e, $cc,$3f                        ; < >   ss?

.CapsTable
        defb    (DmndTable - CapsTable - 1)/2
        defb    $a3,$a3, $dc,$ec, $df,$ef               ; £ £

.DmndTable
        defb    (SqrTable - DmndTable - 1)/2
        defb    $1b,$c4         ; esc   c4
        defb    $20,$a0         ; spc   a0
        defb    $27,$1c         ; '     1c
        defb    $2b,$00         ; +     00
        defb    $2c,$1b         ; ,     1b
        defb    $2d,$1f         ; -     1f
        defb    $2e,$1d         ; .     1d
        defb    $30,$5d         ; 0     ]
        defb    $31,$5c         ; 1     \
        defb    $32,$40         ; 2     @
        defb    $33,$a3         ; 3     £
        defb    $34,$7c         ; 4     |
        defb    $35,$7e         ; 5     ~
        defb    $36,$a2         ; 6     º
        defb    $37,$7b         ; 7     {
        defb    $38,$7d         ; 8     }
        defb    $39,$5b         ; 9     [
        defb    $3c,$1e         ; <     1e
        defb    $3d,$00         ; =     00
        defb    $5b,$1b         ; [     1b
        defb    $5c,$1c         ; \     1c
        defb    $5d,$1d         ; ]     1d
        defb    $5f,$1f         ; _     1f
        defb    $a3,$1e         ; £     1e      is this needed?

.SqrTable       ; 22 keys
        defb    (DeadTable - SqrTable - 1)/2
        defb    $1b,$b4         ; esc   b4
        defb    $20,$b0         ; spc   b0
        defb    $27,$9c         ; '     9c
        defb    $2b,$80         ; +     80
        defb    $2c,$9b         ; ,     9b
        defb    $2d,$9f         ; -     9f
        defb    $2e,$9d         ; .     9d
        defb    $3c,$9e         ; <     9e
        defb    $3d,$80         ; =     80
        defb    $5b,$9b         ; [     9b
        defb    $5c,$9c         ; \     9c
        defb    $5d,$9d         ; ]     9d
        defb    $5f,$9f         ; _     9f
        defb    $a3,$9e         ; £     9e      is this needed?

.DeadTable
        defb    0

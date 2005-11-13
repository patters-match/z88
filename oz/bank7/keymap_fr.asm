; Bank 7 @ S2       ROM offset $1d300

; all keymap tables in one page

; structure of shift, square, and diamond tables:

;   dc.b n            number of character pairs in table
;   dc.b inchar,outchar   translates inchar into outchar
;   dc.b inchar,outchar,...   entries are ordered in ascending inchar order

; structure of deadkey table:

;   dc.b n            number of deadkeys in table
;   dc.b keycode,offset   keycode of deadkey, offset into subtable for that key
;   dc.b keycode,offset,...   offset is table address low byte
;                 entries are ordered in ascending keycode order
;
;   dc.b char         deadkey subtables start with extra byte - 8x8 char code for OZ window
;   dc.b n            after that they follow standard table format of num + n*(in,out)
;   dc.b inchar, outchar,...


;*UDRL  cursor keys     ff fe fd fc
;*S space           20
;^MTDE  enter tab del esc   e1 e2 e3 e4
;#MIH   menu index help     e5 e6 e7
;!DSLRC <> [] ls rs cl      c8 b8 aa a9 a8


.KeyMatrix
    defb    $21,$BB,$6E,$68,$79,$A1,$E1,$E3     ; !  è  n  h  y  §  ^M ^D
    defb    $69,$75,$62,$67,$74,$28,$FF,$3C     ; i  u  b  g  t  (  *U <
    defb    $6F,$6A,$76,$66,$72,$27,$FE,$2D     ; o  j  v  f  r  '  *D -
    defb    $DF,$6B,$63,$64,$65,$22,$FD,$29     ; ç  k  c  d  e  "  *R )
    defb    $70,$2C,$78,$73,$7A,$BC,$FC,$3D     ; p  ,  x  s  z  é  *L =
    defb    $B9,$6C,$77,$71,$61,$26,$20,$2A     ; à  l  w  q  a  &  *S *
    defb    $CA,$6D,$3B,$E5,$C8,$E2,$aa,$E7     ; ù  m  ;  #M !D ^T !L #H
    defb    $AE,$24,$3A,$E8,$E6,$1B,$B8,$a9     ; ^  $  :  e8 #I ^E !S !R


.ShiftTable
    defb    (DmndTable - ShiftTable - 1)/2      ;
    defb    $1b,$d4                             ;^E d4
    defb    $20,$d0                             ;*S d0
    defb    $21,$38                             ;! 8
    defb    $22,$33                             ;" 3
    defb    $24,$A3                             ;$ £
    defb    $26,$31                             ;& 1
    defb    $27,$34                             ;' 4
    defb    $28,$35                             ;( 5
    defb    $29,$A2                             ;) °
    defb    $2A,$BF                             ;* ï
    defb    $2C,$3F                             ;, ?
    defb    $2D,$5F                             ;- _
    defb    $3A,$2F                             ;: /
    defb    $3B,$2E                             ;; .
    defb    $3C,$3E                             ;< >
    defb    $3D,$2B                             ;= +
    defb    $A1,$36                             ;§ 6
    defb    $B9,$30                             ;à 0
    defb    $BB,$37                             ;è 7
    defb    $BC,$32                             ;é 2
    defb    $CA,$25                             ;ù %
    defb    $DF,$39                             ;ç 9

.DmndTable
    defb    (SqrTable - DmndTable - 1)/2

    defb    $1b,$c4                 ; esc   c4
    defb    $20,$a0                 ; spc   a0
    defb    $21,$7D                 ; ! }
    defb    $22,$23                 ; " #
    defb    $24,$A4                 ; $ €
    defb    $26,$5C                 ; & \
    defb    $27,$7C                 ; ' |
    defb    $28,$7E                 ; ( ~
    defb    $29,$60                 ; ) `
    defb    $2B,$00                 ; + 00
    defb    $2C,$1B                 ; , 1b
    defb    $2D,$1F                 ; - 1f
    defb    $3A,$1D                 ; : 1d
    defb    $3B,$1C                 ; ; 1c
    defb    $3D,$00                 ; < 00
    defb    $5B,$1B                 ; [ 1b
    defb    $5C,$1C                 ; \ 1c
    defb    $5D,$1D                 ; ] 1d
    defb    $A1,$5E                 ; § ^
    defb    $B9,$5D                 ; à ]
    defb    $BB,$7B                 ; è {
    defb    $BC,$40                 ; é @
    defb    $DF,$5B                 ; ç [

.SqrTable
    defb    (DeadTable - SqrTable - 1)/2
    defb    $1B,$B4                 ; esc   b4
    defb    $20,$B0                 ; spc   b0
    defb    $24,$9E                 ; $ 9e
    defb    $2B,$80                 ; + 80
    defb    $2C,$9B                 ; , 9b
    defb    $2D,$9F                 ; - 9f
    defb    $3A,$9D                 ; : 9d
    defb    $3B,$9C                 ; ; 9c
    defb    $3D,$80                 ; = 80
    defb    $5B,$9B                 ; [ 9b
    defb    $5C,$9C                 ; \ 9c
    defb    $5D,$9D                 ; ] 9d
    defb    $5F,$9F                 ; _ 9f
    defb    $A3,$9E                 ; £ 9e

.DeadTable
    defb    (dk1 - DeadTable - 1)/2
    defb    $AE,dk1&255                            ; lowbyte offset of dk1
.dk1    defb    $de                                ; ^ in hires font
    defb    5                                      ; 5 keys in ascending order
    defb    $61,$BA                            ; a â
    defb    $65,$BD                            ; e ê
    defb    $69,$BE                            ; i î
    defb    $6F,$C9                            ; o ô
    defb    $75,$CB                            ; u û

    defs    $37 ($ff)


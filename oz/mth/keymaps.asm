; **************************************************************************************************
; Keymaps for UK, FR, SP, DK, DE & SE/FI.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; Implementation, comments and definitions by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; $Id$
;***************************************************************************************************

MODULE  Keymaps

ORG     $0000

xdef    Keymap_UK
xdef    Keymap_FR
xdef    Keymap_DK
xdef    Keymap_FI
xdef    Keymap_DE
xdef    Keymap_SP

; ------------------------------------------------------------------------------------------------------
; Every keymap is located at at page boundary.

; all keymap tables in one page
;
; structure of shift, square, and diamond tables:
;
;       dc.b n                    number of character pairs in table
;       dc.b inchar,outchar       translates inchar into outchar
;       dc.b inchar,outchar,...   entries are ordered in ascending inchar order
;
; capsable table:
;
;       dc.b n                    number of character pairs in table
;       dc.b lcase,ucase          translates lcase into ucase and vice versa
;       dc.b lcase,ucase,...      entries can be unsorted, but why not sort them?
;
; structure of deadkey table:
;
;       dc.b n                    number of deadkeys in table
;       dc.b keycode,offset       keycode of deadkey, offset into subtable for that key
;       dc.b keycode,offset,...   offset is table address low byte
;                                 entries are ordered in ascending keycode order
;
;       dc.b char                 deadkey subtables start with extra byte - 8x8 char code for OZ window
;       dc.b n                    after that they follow standard table format of num + n*(in,out)
;       dc.b inchar, outchar,...
;
;
;*UDRL  cursor keys             ff fe fd fc
;*S     space                   20
;^MTDE  enter tab del esc       e1 e2 e3 e4
;#MIH   menu index help         e5 e6 e7
;!DSLRC <> [] ls rs cl          c8 b8 aa a9 a8
;deadk  ^  ¨  '  `   			ae af ac ad
; ------------------------------------------------------------------------------------------------------



; ------------------------------------------------------------------------------------------------------
; British keymap
;
.KeyMap_UK

IF (<$linkaddr(KeyMap_UK)) <> 0
        ERROR "UK Keymap table must start a page at $00!"
ENDIF

        defb    $38,$37,$6E,$68,$79,$36,$E1,$E3     ; 8  7  n  h  y  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$FF,$5C     ; i  u  b  g  t  5  *U \
        defb    $6F,$6A,$76,$66,$72,$34,$FE,$3D     ; o  j  v  f  r  4  *D =
        defb    $39,$6B,$63,$64,$65,$33,$FD,$2D     ; 9  k  c  d  e  3  *R -
        defb    $70,$6D,$78,$73,$77,$32,$FC,$5D     ; p  m  x  s  w  2  *L ]
        defb    $30,$6C,$7A,$61,$71,$31,$20,$5B     ; 0  l  z  a  q  1  *S [
        defb    $27,$3B,$2C,$E5,$C8,$E2,$aa,$E7     ; '  ;  ,  #M !D ^T !L #H
        defb    $A3,$2F,$2E,$E8,$E6,$1B,$B8,$a9     ; £  /  .  !C #I ^E !S !R

.ShiftTable_UK
        defb    (CapsTable_UK - ShiftTable_UK - 1)/2
        defb    $1b,$d4                                 ; ^E d4
        defb    $20,$d0                                 ; *S d0
        defb    $27,$22                                 ; '  "
        defb    $2c,$3c                                 ; ,  <
        defb    $2d,$5f                                 ; -  _
        defb    $2e,$3e                                 ; .  >
        defb    $2f,$3f                                 ; /  ?
        defb    $30,$29                                 ; 0  )
        defb    $31,$21                                 ; 1  !
        defb    $32,$40                                 ; 2 @
        defb    $33,$23                                 ; 3 #
        defb    $34,$24                                 ; 4 $
        defb    $35,$25                                 ; 5 %
        defb    $36,$5e                                 ; 6 ^
        defb    $37,$26                                 ; 7 &
        defb    $38,$2a                                 ; 8 *
        defb    $39,$28                                 ; 9 (
        defb    $3b,$3a                                 ; ;  :
        defb    $3d,$2b                                 ; =  +
        defb    $5b,$7b                                 ; [  {
        defb    $5c,$7c                                 ; \  |
        defb    $5d,$7d                                 ; ]  }
        defb    $a3,$7e                                 ; £  ~

.CapsTable_UK
        defb    0

.DmndTable_UK
        defb    (SqrTable_UK - DmndTable_UK - 1)/2
        defb    $1b,$c4                                 ; ^E    c4
        defb    $20,$a0                                 ; *S    a0
        defb    $27,$60                                 ; '     `
        defb    $2b,$00                                 ; +     00
        defb    $2c,$1b                                 ; ,     1b
        defb    $2d,$1f                                 ; -     1f
        defb    $2e,$1d                                 ; .     1d
        defb    $2f,$1c                                 ; /     1c
        defb    $3d,$00                                 ; =     00
        defb    $a3,$a4                                 ; £     €

.SqrTable_UK
        defb    (DeadTable_UK - SqrTable_UK - 1)/2
        defb    $1B,$B4
        defb    $20,$B0
        defb    $2B,$80                                 ; special []+ command
        defb    $2D,$9F                                 ; special []- command
        defb    $3D,$80                                 ; special []+ command
        defb    $5B,$1B
        defb    $5C,$1C
        defb    $5D,$1D
        defb    $A3,$1E

.DeadTable_UK
        defb    0
; ------------------------------------------------------------------------------------------------------

        defs ($100-$PC) ($ff)                           ; make sure that next keymap is on page boundary.



; ------------------------------------------------------------------------------------------------------
; French keymap
;
.KeyMap_FR
        defb    $21,$BB,$6E,$68,$79,$A1,$E1,$E3 ; !  è  n  h  y  §  ^M ^D
        defb    $69,$75,$62,$67,$74,$28,$FF,$3C ; i  u  b  g  t  (  *U <
        defb    $6F,$6A,$76,$66,$72,$27,$FE,$2D ; o  j  v  f  r  '  *D -
        defb    $DF,$6B,$63,$64,$65,$22,$FD,$29 ; ç  k  c  d  e  "  *R )
        defb    $70,$2C,$78,$73,$7A,$BC,$FC,$3D ; p  ,  x  s  z  é  *L =
        defb    $B9,$6C,$77,$71,$61,$26,$20,$2A ; à  l  w  q  a  &  *S *
        defb    $CA,$6D,$3B,$E5,$C8,$E2,$aa,$E7 ; ù  m  ;  #M !D ^T !L #H
        defb    $AE,$24,$3A,$E8,$E6,$1B,$B8,$a9 ; ^  $  :  !C #I ^E !S !R


.ShiftTable_FR
        defb    (CapsTable_FR - ShiftTable_FR - 1)/2
        defb    $1b,$d4                         ;^E d4
        defb    $20,$d0                         ;*S d0
        defb    $21,$38                         ;! 8
        defb    $22,$33                         ;" 3
        defb    $24,$A3                         ;$ £
        defb    $26,$31                         ;& 1
        defb    $27,$34                         ;' 4
        defb    $28,$35                         ;( 5
        defb    $29,$A2                         ;) °
        defb    $2A,$BF                         ;* ï
        defb    $2C,$3F                         ;, ?
        defb    $2D,$5F                         ;- _
        defb    $3A,$2F                         ;: /
        defb    $3B,$2E                         ;; .
        defb    $3C,$3E                         ;< >
        defb    $3D,$2B                         ;= +
        defb    $A1,$36                         ;§ 6
        defb    $AE,$AF                         ;^ ¨ deadkeys
        defb    $B9,$30                         ;à 0
        defb    $BB,$37                         ;è 7
        defb    $BC,$32                         ;é 2
        defb    $CA,$25                         ;ù %
        defb    $DF,$39                         ;ç 9

.CapsTable_FR
        defb    (DmndTable_FR - CapsTable_FR - 1)/2
        defb    $21,$38                         ;! 8
        defb    $22,$33                         ;" 3
        defb    $24,$A3                         ;$ £
        defb    $26,$31                         ;& 1
        defb    $27,$34                         ;' 4
        defb    $28,$35                         ;( 5
        defb    $29,$A2                         ;) º
        defb    $2A,$BF                         ;* ï
        defb    $2C,$3F                         ;, ?
        defb    $2D,$5F                         ;- _
        defb    $3A,$2F                         ;: /
        defb    $3B,$2E                         ;; .
        defb    $3C,$3E                         ;< >
        defb    $3D,$2B                         ;= +
        defb    $A1,$36                         ;§ 6
        defb    $AE,$AF                         ;^ ¨ deadkeys
        defb    $B9,$30                         ;à 0
        defb    $BB,$37                         ;è 7
        defb    $BC,$32                         ;é 2
        defb    $CA,$25                         ;ù %
        defb    $DF,$39                         ;ç 9

.DmndTable_FR
        defb    (SqrTable_FR - DmndTable_FR - 1)/2
        defb    $1b,$c4                         ; esc   c4
        defb    $20,$a0                         ; spc   a0
        defb    $21,$7D                         ; ! }
        defb    $22,$23                         ; " #
        defb    $24,$A4                         ; $ €
        defb    $26,$5C                         ; & \
        defb    $27,$7C                         ; ' |
        defb    $28,$7E                         ; ( ~
        defb    $29,$60                         ; ) `
        defb    $2B,$00                         ; + 00
        defb    $2C,$1B                         ; , 1b
        defb    $2D,$1F                         ; - 1f
        defb    $3A,$1D                         ; : 1d
        defb    $3B,$1C                         ; ; 1c
        defb    $3D,$00                         ; < 00
        defb    $5B,$1B                         ; [ 1b
        defb    $5C,$1C                         ; \ 1c
        defb    $5D,$1D                         ; ] 1d
        defb    $A1,$5E                         ; § ^
        defb    $B9,$5D                         ; à ]
        defb    $BB,$7B                         ; è {
        defb    $BC,$40                         ; é @
        defb    $DF,$5B                         ; ç [

.SqrTable_FR
        ; 22 keys
        defb    (DeadTable_FR - SqrTable_FR - 1)/2
        defb    $1B,$B4                         ; esc   b4
        defb    $20,$B0                         ; spc   b0
        defb    $24,$9E                         ; $ 9e
        defb    $2B,$80                         ; + 80
        defb    $2C,$9B                         ; , 9b
        defb    $2D,$9F                         ; - 9f
        defb    $3A,$9D                         ; : 9d
        defb    $3B,$9C                         ; ; 9c
        defb    $3D,$80                         ; = 80
        defb    $5B,$9B                         ; [ 9b
        defb    $5C,$9C                         ; \ 9c
        defb    $5D,$9D                         ; ] 9d
        defb    $5F,$9F                         ; _ 9f
        defb    $A3,$9E                         ; £ 9e

.DeadTable_FR
        defb    (deadkey1 - DeadTable_FR - 1)/2
        defb    $AE,deadkey1 & 255
        defb    $AF,deadkey2 & 255
.deadkey1
        defb    $de                             ; ^ (hires)
        defb    5
        defb    $61,$BA                         ; a â
        defb    $65,$BD                         ; e ê
        defb    $69,$BE                         ; i î
        defb    $6F,$C9                         ; o ô
        defb    $75,$CB                         ; u û
.deadkey2
        defb    $A2                             ; ¨ (hires)
        defb    9
        defb    $41,$a8                         ; A Ä
        defb    $45,$E9                         ; E Ë
        defb    $4F,$a7                         ; O Ö
        defb    $55,$EC                         ; U Ü
        defb    $61,$A6                         ; a ä
        defb    $65,$D9                         ; e ë
        defb    $69,$BF                         ; i ï
        defb    $6F,$A5                         ; o ö
        defb    $75,$DC                         ; u ü
; ------------------------------------------------------------------------------------------------------

        defs ($300-$PC) ($ff)                           ; make sure that next keymap is on page boundary.


; ------------------------------------------------------------------------------------------------------
; Danish keymap
;
.KeyMap_DK
        defb    $38,$37,$6e,$68,$79,$36,$e1,$e3         ; 8  7  n  h  y  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$ff,$2f         ; i  u  b  g  t  5  *U /
        defb    $6f,$6a,$76,$66,$72,$34,$fe,$2b         ; o  j  v  f  r  4  *D +
        defb    $39,$6b,$63,$64,$65,$33,$fd,$3d         ; 9  k  c  d  e  3  *R =
        defb    $70,$6d,$78,$73,$77,$32,$fc,$27         ; p  m  x  s  w  2  *L '
        defb    $30,$6c,$7a,$61,$71,$31,$20,$da         ; 0  l  z  a  q  1  *S å
        defb    $dd,$db,$2c,$e5,$c8,$e2,$aa,$e7         ; ø  æ  ,  #M !D ^T !L  #H
        defb    $a3,$2d,$2e,$e8,$e6,$1b,$b8,$a9         ; £  -  .  !C #I ^E !S !R

.ShiftTable_DK
        defb    (CapsTable_DK - ShiftTable_DK - 1)/2
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

.CapsTable_DK
        defb    (DmndTable_DK - CapsTable_DK - 1)/2
        defb    $DA,$EA                                 ; å Å
        defb    $DB,$EB                                 ; æ Æ
        defb    $DD,$ED                                 ; ø Ø

.DmndTable_DK
        defb    (SqrTable_DK - DmndTable_DK - 1)/2
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

.SqrTable_DK
        ; 22 keys
        defb    (DeadTable_DK - SqrTable_DK - 1)/2
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

.DeadTable_DK
        defb    0
; ------------------------------------------------------------------------------------------------------

        defs ($400-$PC) ($ff)                           ; make sure that next keymap is on page boundary.


; ------------------------------------------------------------------------------------------------------
; Finnish/Swedish keymap
;
.KeyMap_FI
        defb    $38,$37,$6e,$68,$79,$36,$e1,$e3         ; 8  7  n  h  y  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$ff,$2f         ; i  u  b  g  t  5  *U /
        defb    $6f,$6a,$76,$66,$72,$34,$fe,$2b         ; o  j  v  f  r  4  *D +
        defb    $39,$6b,$63,$64,$65,$33,$fd,$3d         ; 9  k  c  d  e  3  *R =
        defb    $70,$6d,$78,$73,$77,$32,$fc,$27         ; p  m  x  s  w  2  *L '
        defb    $30,$6c,$7a,$61,$71,$31,$20,$da         ; 0  l  z  a  q  1  *S å
        defb    $a6,$a5,$2c,$e5,$c8,$e2,$aa,$e7         ; ä  ö  ,  #M !D ^T !L #H
        defb    $a3,$2d,$2e,$e8,$e6,$1b,$b8,$a9         ; £  -  .  !C #I ^E !S !R


.ShiftTable_FI
        defb    (CapsTable_FI - ShiftTable_FI - 1)/2
        defb    $1b,$d4                                 ; esc   d4
        defb    $20,$d0                                 ; space d0
        defb    $27,$22, $2b,$3e, $2c,$3b, $2d,$5f      ; ' "   + >   , ;   - _
        defb    $2e,$3a, $2f,$3f, $30,$29, $31,$21      ; . :   / ?   0 )   1 !
        defb    $32,$40, $33,$23, $34,$24, $35,$25      ; 2 @   3 #   4 $   5 %
        defb    $36,$5e, $37,$26, $38,$2a, $39,$28      ; 6 ^   7 &   8 *   9 (
        defb    $3d,$3c, $a3,$7e                        ; = <   £ ~
        defb    $a5,$a7         ; ö Ö
        defb    $a6,$a8         ; ä Ä
        defb    $da,$ea         ; å Å

.CapsTable_FI
        defb    (DmndTable_FI - CapsTable_FI - 1)/2
        defb    $a5,$a7         ; ö Ö
        defb    $a6,$a8         ; ä Ä
        defb    $da,$ea         ; å Å

.DmndTable_FI
        defb    (SqrTable_FI - DmndTable_FI - 1)/2
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
        defb    $a5,$7b         ; ö     {
        defb    $a6,$7d         ; ä     }
        defb    $da,$5c         ; å     \

.SqrTable_FI
        ; 22 keys
        defb    (DeadTable_FI - SqrTable_FI - 1)/2
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
        defb    $A5,$5B         ; ö     [
        defb    $A6,$5D         ; ä     ]
        defb    $DA,$7C         ; å     |

.DeadTable_FI
        defb    0
; ------------------------------------------------------------------------------------------------------

        defs ($500-$PC) ($ff)                           ; make sure that next keymap is on page boundary.


; ------------------------------------------------------------------------------------------------------
; German keymap
;
.KeyMap_DE
        defb    $38,$37,$6e,$68,$7a,$36,$e1,$e3         ; 8  7  n  h  z  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$ff,$3c         ; i  u  b  g  t  5  *U <
        defb    $6f,$6a,$76,$66,$72,$34,$fe,$27         ; o  j  v  f  r  4  *D '
        defb    $39,$6b,$63,$64,$65,$33,$fd,$cc         ; 9  k  c  d  e  3  *R ss
        defb    $70,$6d,$78,$73,$77,$32,$fc,$2b         ; p  m  x  s  w  2  *L +
        defb    $30,$6c,$79,$61,$71,$31,$20,$dc         ; 0  l  y  a  q  1  *S ü
        defb    $a6,$a5,$2c,$e5,$c8,$e2,$A8,$e7         ; ä  ö  ,  #M !D ^T !L #H
        defb    $23,$2d,$2e,$e8,$e6,$1b,$b8,$A9         ; #  -  .  !C #I ^E !S !R


.ShiftTable_DE
        defb    (CapsTable_DE - ShiftTable_DE - 1)/2
        defb    $1b,$d4                                 ; esc   d4
        defb    $20,$d0                                 ; space d0
        defb    $23,$5e, $27,$60, $2b,$2a, $2c,$3b      ; # ^   ' `   + *   , ;
        defb    $2d,$5f, $2e,$3a, $30,$3d, $31,$21      ; - _   . :   0 =   1 !
        defb    $32,$22, $33,$a1, $34,$24, $35,$25      ; 2 "   3 §   4 $   5 %
        defb    $36,$26, $37,$2f, $38,$28, $39,$29      ; 6 &   7 /   8 (   9 )
        defb    $3c,$3e                                 ; < >
        defb    $a5,$a7                                 ; ö Ö
        defb    $a6,$a8                                 ; ä Ä
        defb    $cc,$3f                                 ; ss ?
        defb    $dc,$ec                                 ; ü Ü

.CapsTable_DE
        defb    (DmndTable_DE - CapsTable_DE - 1)/2
        defb    $a5,$a7                                 ; ö Ö
        defb    $a6,$a8                                 ; ä Ä
        defb    $dc,$ec                                 ; ü Ü

.DmndTable_DE
        defb    (SqrTable_DE - DmndTable_DE - 1)/2
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
        defb    $cc,$a4         ; ss    €

.SqrTable_DE
        ; 22 keys
        defb    (DeadTable_DE - SqrTable_DE - 1)/2
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

.DeadTable_DE
        defb    0

        defs ($600-$PC) ($ff)                           ; make sure that next keymap is on page boundary.


; ------------------------------------------------------------------------------------------------------
; Spanish keymap
;
.KeyMap_SP

IF (<$linkaddr(KeyMap_SP)) <> 0
        ERROR "SP Keymap table must start a page at $00!"
ENDIF

        defb    $38,$37,$6E,$68,$79,$36,$E1,$E3     ; 8  7  n  h  y  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$FF,$df     ; i  u  b  g  t  5  *U ç
        defb    $6F,$6A,$76,$66,$72,$34,$FE,$3D     ; o  j  v  f  r  4  *D =
        defb    $39,$6B,$63,$64,$65,$33,$FD,$2D     ; 9  k  c  d  e  3  *R -
        defb    $70,$6D,$78,$73,$77,$32,$FC,$ad     ; p  m  x  s  w  2  *L `
        defb    $30,$6C,$7A,$61,$71,$31,$20,$ac     ; 0  l  z  a  q  1  *S '
        defb    $3b,$de,$2C,$E5,$C8,$E2,$aa,$E7     ; ;  n  ,  #M !D ^T !L #H
        defb    $3c,$27,$2E,$E8,$E6,$1B,$B8,$a9     ; <  '  .  !C #I ^E !S !R

.ShiftTable_SP
        defb    (CapsTable_SP - ShiftTable_SP - 1)/2
        defb    $1b,$d4                                 ; ^E d4
        defb    $20,$d0                                 ; *S d0
        defb    $27,$22                                 ; '  "
        defb    $2c,$3f                                 ; ,  ?
        defb    $2d,$5f                                 ; -  _
        defb    $2e,$21                                 ; .  !
        defb    $2f,$3f                                 ; /  ?
        defb    $30,$29                                 ; 0  )
        defb    $31,$ab                                 ; 1  !!
        defb    $32,$9b                                 ; 2  ??
        defb    $33,$23                                 ; 3 #
        defb    $34,$24                                 ; 4 $
        defb    $35,$25                                 ; 5 %
        defb    $36,$2f                                 ; 6 /
        defb    $37,$26                                 ; 7 &
        defb    $38,$2a                                 ; 8 *
        defb    $39,$28                                 ; 9 (
        defb    $3b,$3a                                 ; ;  :
        defb    $3c,$3e                                 ; <  >
        defb    $3d,$2b                                 ; =  +
        defb    $a3,$ae                                 ; £  ~
        defb    $ac,$af                                 ; '  ¨ deadkeys
        defb    $ad,$ae                                 ; `  ^ deadkeys
        defb    $de,$ee                                 ; n  N
        defb    $df,$ef                                 ; ç  C


.CapsTable_SP
        defb    0

.DmndTable_SP
        defb    (SqrTable_SP - DmndTable_SP - 1)/2
        defb    $1b,$c4                                 ; ^E    c4
        defb    $20,$a0                                 ; *S    a0
        defb    $2b,$00                                 ; +     00
        defb    $2c,$1b                                 ; ,     1b
        defb    $2d,$1f                                 ; -     1f
        defb    $2e,$1d                                 ; .     1d
        defb    $2f,$1c                                 ; /     1c
        defb    $30,$5d                                 ; 0  ]
        defb    $31,$5c                                 ; 1  \
        defb    $32,$40                                 ; 2  @
        defb    $33,$a3                                 ; 3  £
        defb    $34,$7c                                 ; 4  |
        defb    $35,$7e                                 ; 5  ~
        defb    $36,$5e                                 ; 6  ^
        defb    $37,$7b                                 ; 7  {
        defb    $38,$7d                                 ; 8  }
        defb    $39,$5b                                 ; 9  [
        defb    $3d,$a4                                 ; =  €

.SqrTable_SP
        defb    (DeadTable_SP - SqrTable_SP - 1)/2
        defb    $1B,$B4                                 ; special []ESC
        defb    $20,$B0                                 ; special []SPC
        defb    $2B,$80                                 ; special []+ command
        defb    $2D,$9F                                 ; special []- command
        defb    $3D,$80                                 ; special []= command (equivalent to []+)
        defb    $5B,$1B                                 ; [  ESC
        defb    $5C,$1C                                 ; \
        defb    $5D,$1D                                 ; ]
        defb    $5F,$9F                                 ; special []_ command (equivalent to []-)
        defb    $A3,$1E                                 ; £

.DeadTable_SP
        defb    (deadkeysp1 - DeadTable_SP - 1)/2
        defb    $AC,deadkeysp1 & 255            ; '
        defb    $AD,deadkeysp2 & 255            ; `
        defb    $AE,deadkeysp3 & 255            ; ^
        defb    $AF,deadkeysp4 & 255            ; ¨
.deadkeysp1
        defb    $a7                             ; ' (hires)
        defb    5
        defb    $61,$9c                         ; a
        defb    $65,$bc                         ; e é
        defb    $69,$9d                         ; i
        defb    $6F,$9e                         ; o
        defb    $75,$cf                         ; u
.deadkeysp2
        defb    $9d                             ; ` (hires)
        defb    5
        defb    $61,$b9                         ; a à
        defb    $65,$bb                         ; e è
        defb    $69,$cd                         ; i
        defb    $6F,$ce                         ; o
        defb    $75,$ca                         ; u ù
.deadkeysp3
        defb    $de                             ; ^ (hires)
        defb    5
        defb    $61,$BA                         ; a â
        defb    $65,$BD                         ; e ê
        defb    $69,$BE                         ; i î
        defb    $6F,$C9                         ; o ô
        defb    $75,$CB                         ; u û
.deadkeysp4
        defb    $A2                             ; ¨ (hires)
        defb    9
        defb    $41,$a8                         ; A Ä
        defb    $45,$E9                         ; E Ë
        defb    $4F,$a7                         ; O Ö
        defb    $55,$EC                         ; U Ü
        defb    $61,$A6                         ; a ä
        defb    $65,$D9                         ; e ë
        defb    $69,$BF                         ; i ï
        defb    $6F,$A5                         ; o ö
        defb    $75,$DC                         ; u ü
; ------------------------------------------------------------------------------------------------------

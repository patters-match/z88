; **************************************************************************************************
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
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
;***************************************************************************************************
;
; all keymap tables in one page
;
; structure of shift, square, and diamond tables:
;
;	dc.b n			  number of character pairs in table
;	dc.b inchar,outchar	  translates inchar into outchar
;	dc.b inchar,outchar,...   entries are ordered in ascending inchar order
;
; capsable table:
;
;	dc.b n			  number of character pairs in table
;	dc.b lcase,ucase	  translates lcase into ucase and vice versa
;	dc.b lcase,ucase,...	  entries can be unsorted, but why not sort them?
;
; structure of deadkey table:
;
;	dc.b n			  number of deadkeys in table
;	dc.b keycode,offset	  keycode of deadkey, offset into subtable for that key
;	dc.b keycode,offset,...   offset is table address low byte
;				  entries are ordered in ascending keycode order
;
;	dc.b char		  deadkey subtables start with extra byte - 8x8 char code for OZ window
;	dc.b n			  after that they follow standard table format of num + n*(in,out)
;	dc.b inchar, outchar,...
;
;
;*UDRL	cursor keys		ff fe fd fc
;*S	space			20
;^MTDE	enter tab del esc	e1 e2 e3 e4
;#MIH	menu index help 	e5 e6 e7
;!DSLRC <> [] ls rs cl		c8 b8 aa a9 a8
;
MODULE  Keymap_FR

ORG     $0100
xdef    Keymap_FR

.KeyMap_FR
        defb    $21,$BB,$6E,$68,$79,$A1,$E1,$E3 ; !  è  n  h  y  §  ^M ^D
        defb    $69,$75,$62,$67,$74,$28,$FF,$3C ; i  u  b  g  t  (  *U <
        defb    $6F,$6A,$76,$66,$72,$27,$FE,$2D ; o  j  v  f  r  '  *D -
        defb    $DF,$6B,$63,$64,$65,$22,$FD,$29 ; ç  k  c  d  e  "  *R )
        defb    $70,$2C,$78,$73,$7A,$BC,$FC,$3D ; p  ,  x  s  z  é  *L =
        defb    $B9,$6C,$77,$71,$61,$26,$20,$2A ; à  l  w  q  a  &  *S *
        defb    $CA,$6D,$3B,$E5,$C8,$E2,$aa,$E7 ; ù  m  ;  #M !D ^T !L #H
        defb    $AE,$24,$3A,$E8,$E6,$1B,$B8,$a9 ; ^  $  :  !C #I ^E !S !R


.ShiftTable
	defb	(CapsTable - ShiftTable - 1)/2
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

.CapsTable
	defb	(DmndTable - CapsTable - 1)/2
	defb	$21,$38                         ;! 8
        defb    $22,$33                         ;" 3
        defb    $24,$A3                         ;$ £        
        defb    $26,$31	                        ;& 1
	defb	$27,$34                         ;' 4
        defb    $28,$35                         ;( 5
        defb    $29,$A2                         ;) º
        defb    $2A,$BF	                        ;* ï
	defb	$2C,$3F                         ;, ?
        defb    $2D,$5F                         ;- _
        defb    $3A,$2F                         ;: /
        defb    $3B,$2E	                        ;; .
	defb	$3C,$3E                         ;< >
        defb    $3D,$2B                         ;= +
        defb    $A1,$36                         ;§ 6
        defb    $AE,$AF                         ;^ ¨ deadkeys
        defb    $B9,$30	                        ;à 0
	defb	$BB,$37                         ;è 7
        defb    $BC,$32                         ;é 2
        defb    $CA,$25                         ;ù %
        defb    $DF,$39	                        ;ç 9

.DmndTable
	defb	(SqrTable - DmndTable - 1)/2
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

.SqrTable	; 22 keys
	defb	(DeadTable - SqrTable - 1)/2
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

.DeadTable
        defb    (dk1 - DeadTable - 1)/2
        defb    $AE,dk1&255
        defb    $AF,dk2&255
.dk1
        defb    $de		                ; ^ (hires)
        defb    5
        defb    $61,$BA 	                ; a â
        defb    $65,$BD 	                ; e ê
        defb    $69,$BE 	                ; i î
        defb    $6F,$C9 	                ; o ô
        defb    $75,$CB 	                ; u û
.dk2
        defb    $A2                             ; ¨ (hires)
        defb    9
        defb    $41,$AC                         ; A Ä
        defb    $45,$E9                         ; E Ë
        defb    $4F,$A5                         ; O Ö
        defb    $45,$EC                         ; U Ü
        defb    $61,$A6                         ; a ä
        defb    $65,$D9                         ; e ë
        defb    $69,$BF                         ; i ï
        defb    $6F,$A5                         ; o ö
        defb    $75,$DC                         ; u ü
        
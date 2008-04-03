; **************************************************************************************************
; Key Code Mapping Table, used by screen driver for keyboard -> screen conversion.
; The table is located in Kernel 1, bound with the keyboard and screen driver functionality.
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
; ***************************************************************************************************

module Key2Char_Table


; INTERNATIONAL version
;
; This table is used by ScrDrv1.asm for keyboard / screen conversion
; It is the bridge between key / char code / lores font.
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
        defb    $A3                             ; � char code
.VDU2Chr_tbl
        defb            $1F,$00                 ; Lores low byte, high byte in the font
        defb    $91,$A1,$86,$00                 ; �
        defb    $92,$BF,$87,$00                 ; �
        defb    $93,$E1,$80,$00                 ; �
        defb    $94,$ED,$81,$00                 ; �
        defb    $95,$F3,$82,$00                 ; �
        defb    $A1,$A7,$01,$00                 ; �
        defb    $A2,$B0,$02,$00                 ; �
        defb    $A4,$80,$7F,$00                 ; �
        defb    $A5,$F6,$1A,$00                 ; �
        defb    $A6,$E4,$0F,$00                 ; �
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
        defb    $CC,$DF,$06,$00                 ; �
        defb    $CD,$EC,$00,$01                 ; �
        defb    $CE,$F2,$01,$01                 ; �
        defb    $CF,$FA,$83,$00                 ; �
        defb    $D9,$EB,$16,$00                 ; �
        defb    $DA,$E5,$10,$00                 ; �
        defb    $DB,$E6,$11,$00                 ; �
        defb    $DC,$FC,$1E,$00                 ; �
        defb    $DD,$F8,$1B,$00                 ; �
        defb    $DE,$F1,$84,$00                 ; �
        defb    $DF,$E7,$12,$00                 ; �
        defb    $E9,$CB,$04,$00                 ; �
        defb    $EA,$C5,$09,$00                 ; �
        defb    $EB,$C6,$0A,$00                 ; �
        defb    $EC,$DC,$05,$00                 ; �
        defb    $ED,$D8,$0C,$00                 ; �
        defb    $EE,$D1,$85,$00                 ; �
        defb    $EF,$C7,$03,$00                 ; �
        defb    $00,$00,$00,$00                 ; table terminator

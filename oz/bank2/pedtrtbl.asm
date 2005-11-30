; **************************************************************************************************
; PrinterEd Translation Table (Bank 2, addressed for segment 3).
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
; (C) Jorma Oksanen (jorma.oksanen@aini.fi), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module  Table_E998

xdef    PrEdTransTbl

;       PrinterEd uses this

        org     $e998                           ; 281 bytes
.PrEdTransTbl
        defb    $3C, $20, $05, $80, $80
        defb    $3C, $21, $08, $90, $81
        defb    $3C, $22, $05, $80, $8E
        defb    $3C, $23, $08, $90, $8F
        defb    $3C, $24, $05, $80, $9C
        defb    $3C, $25, $08, $90, $9D
        defb    $3C, $26, $05, $80, $AA
        defb    $3C, $27, $08, $90, $AB
        defb    $45, $20, $05, $80, $82
        defb    $45, $21, $08, $90, $83
        defb    $45, $22, $05, $80, $90
        defb    $45, $23, $08, $90, $91
        defb    $45, $24, $05, $80, $9E
        defb    $45, $25, $08, $90, $9F
        defb    $45, $26, $05, $80, $AC
        defb    $45, $27, $08, $90, $AD
        defb    $4E, $20, $05, $80, $84
        defb    $4E, $21, $08, $90, $85
        defb    $4E, $22, $05, $80, $92
        defb    $4E, $23, $08, $90, $93
        defb    $4E, $24, $05, $80, $A0
        defb    $4E, $25, $08, $90, $A1
        defb    $4E, $26, $05, $80, $AE
        defb    $4E, $27, $08, $90, $AF
        defb    $57, $20, $05, $80, $86
        defb    $57, $21, $08, $90, $87
        defb    $57, $22, $05, $80, $94
        defb    $57, $23, $08, $90, $95
        defb    $57, $24, $05, $80, $A2
        defb    $57, $25, $08, $90, $A3
        defb    $57, $26, $05, $80, $B0
        defb    $57, $27, $08, $90, $B1
        defb    $60, $20, $05, $80, $88
        defb    $60, $21, $08, $90, $89
        defb    $60, $22, $05, $80, $96
        defb    $60, $23, $08, $90, $97
        defb    $60, $24, $05, $80, $A4
        defb    $60, $25, $08, $90, $A5
        defb    $60, $26, $05, $80, $B2
        defb    $60, $27, $08, $90, $B3
        defb    $69, $20, $05, $80, $8A
        defb    $69, $21, $08, $90, $8B
        defb    $69, $22, $05, $80, $98
        defb    $69, $23, $08, $90, $99
        defb    $69, $24, $05, $80, $A6
        defb    $69, $25, $08, $90, $A7
        defb    $69, $26, $05, $80, $B4
        defb    $69, $27, $08, $90, $B5
        defb    $72, $20, $05, $80, $8C
        defb    $72, $21, $08, $90, $8D
        defb    $72, $22, $05, $80, $9A
        defb    $72, $23, $08, $90, $9B
        defb    $72, $24, $05, $80, $A8
        defb    $72, $25, $08, $90, $A9
        defb    $72, $26, $05, $80, $B6
        defb    $72, $27, $08, $90, $B7
        defb    $ff

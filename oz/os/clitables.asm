; **************************************************************************************************
; CLI File Key conversion tables
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
; (C) Thierry Peycru (pek@users.sf.net), 2005-2008
; (C) Gunther Strube (gbs@users.sf.net), 2005-2008
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; ***************************************************************************************************


module CLITables

include "keyboard.def"

xdef    Key2MetaTable                           ; this one must be in the same page
xdef    CLI2KeyTable

;       entries in descending order
;       low limit, meta key, key table

.Key2MetaTable
        defb    $FC, QUAL_SPECIAL, <crsr
        defb    $F8, QUAL_SPECIAL|QUAL_SHIFT, <crsr
        defb    $F4, QUAL_SPECIAL|QUAL_CTRL, <crsr
        defb    $F0, QUAL_SPECIAL|QUAL_ALT, <crsr
        defb    $E9, 0, 0
        defb    $E0, QUAL_SPECIAL, <spec
        defb    $D9, 0, 0
        defb    $D0, QUAL_SPECIAL|QUAL_SHIFT, <spec
        defb    $C9, 0, 0
        defb    $C8, QUAL_SPECIAL, <c
        defb    $C0, QUAL_SPECIAL|QUAL_CTRL, <spec
        defb    $B9, 0, 0
        defb    $B8, QUAL_SPECIAL, <a
        defb    $B0, QUAL_SPECIAL|QUAL_ALT, <spec
        defb    $A0, 0, 0
        defb    $80, QUAL_ALT, <ctrl
        defb    $20, 0, 0
        defb    $00, QUAL_CTRL, <ctrl

;       length mask, character codes
;       Careful - can't cross page boundary

.crsr   defb    3                               ; cursor keys
        defm    "LRDU"

.spec   defb    7                               ; enter tab del (esc) menu index help
        defm    " ETX?MIH"

.ctrl   defb    $1F                             ; control chars
        defm    "=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        defb    $5B,$5C,$5D,$A3,$2D             ; [\]�-

.c      defb    0                               ; ctrl
        defm    "C"

.a      defb    0                               ; alt
        defm    "A"
.Key2MetaTable_end

IF (>$linkaddr(Key2MetaTable)) <> (>$linkaddr(Key2MetaTable_end))
        ERROR "OS_CLI key to meta conversion table crosses address page boundary!"
ENDIF

.CLI2keyTable
        defb    2*12                            ; table length
        defb    'D',$FE                         ; D down
        defb    'E',$E1                         ; E enter
        defb    'H',$E7                         ; H help
        defb    'I',$E6                         ; I index
        defb    'L',$FC                         ; L left
        defb    'M',$E5                         ; M menu
        defb    'R',$FD                         ; R right
        defb    'T',$E2                         ; T tab
        defb    'U',$FF                         ; U up
        defb    'X',$E3                         ; X del
        defb    'C',$C8                         ; C ctrl
        defb    'A',$B8                         ; A alt

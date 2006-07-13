; **************************************************************************************************
; The main help page which is the copyright text displayed when pressing HELP,
; then using the Left Cursor
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
; $Id$
; ***************************************************************************************************

.CopyrightMsg
        defm    "Th",$82,"C",$ED,"bri"
        defm    "dg",$82,$AB,"mput"
        defm    $EF,"Z88 P",$8F,"t"
        defm    "abl",$82,"V",$86,"si"
        defm    $BC," ", (OZVERSION>>4)+48, '.', (OZVERSION&$0f)+48, ".dev "

if KBDK
        defm    "(DK)"
endif

if KBFR
        defm    "(FR)"
endif

if KBFI
        defm    "(FI)"
endif

if KBSE
        defm    "(SE)"
endif

if !KBDK & !KBFR & !KBFI & !KBSE
        defm    "(UK)"
endif

        defm    $7F,$7F,$DE,"r"
        defm    $CC,$84,"(C) Tr"
        defm    $85,$FC,$D6,$AB,"n",$C9,"pt"
        defm    $94,"Pro",$AF,$B4,"ni"
        defm    "c ",$AB,"mput",$86
        defm    $94,$BF,$86,$91,$C0,"Sys"
        defm    $AF,"m",$94,$C4,$B2,"198"
        defm    "7,88",$7F,"Pip"
        defm    "eD",$8D,$ED,$B7,"a t"
        defm    $E2,$E4,"m",$8C,"k ",$89,$C4
        defm    "d",0

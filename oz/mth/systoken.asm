; **************************************************************************************************
; OZ System token table, used by MTH static structures in most standard OZ applications and popdowns.
;
; This table was extracted out of Font bitmap from original V4.0 ROM,
; using FontBitMap tool that auto-generated the token table sources.
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

module SystemToken

xdef    SysTokenBase


.SysTokenBase
        defb $80                                ; recursive token boundary
        defb $80                                ; number of tokens
        defw token80-SysTokenBase
        defw token81-SysTokenBase
        defw token82-SysTokenBase
        defw token83-SysTokenBase
        defw token84-SysTokenBase
        defw token85-SysTokenBase
        defw token86-SysTokenBase
        defw token87-SysTokenBase
        defw token88-SysTokenBase
        defw token89-SysTokenBase
        defw token8A-SysTokenBase
        defw token8B-SysTokenBase
        defw token8C-SysTokenBase
        defw token8D-SysTokenBase
        defw token8E-SysTokenBase
        defw token8F-SysTokenBase
        defw token90-SysTokenBase
        defw token91-SysTokenBase
        defw token92-SysTokenBase
        defw token93-SysTokenBase
        defw token94-SysTokenBase
        defw token95-SysTokenBase
        defw token96-SysTokenBase
        defw token97-SysTokenBase
        defw token98-SysTokenBase
        defw token99-SysTokenBase
        defw token9A-SysTokenBase
        defw token9B-SysTokenBase
        defw token9C-SysTokenBase
        defw token9D-SysTokenBase
        defw token9E-SysTokenBase
        defw token9F-SysTokenBase
        defw tokenA0-SysTokenBase
        defw tokenA1-SysTokenBase
        defw tokenA2-SysTokenBase
        defw tokenA3-SysTokenBase
        defw tokenA4-SysTokenBase
        defw tokenA5-SysTokenBase
        defw tokenA6-SysTokenBase
        defw tokenA7-SysTokenBase
        defw tokenA8-SysTokenBase
        defw tokenA9-SysTokenBase
        defw tokenAA-SysTokenBase
        defw tokenAB-SysTokenBase
        defw tokenAC-SysTokenBase
        defw tokenAD-SysTokenBase
        defw tokenAE-SysTokenBase
        defw tokenAF-SysTokenBase
        defw tokenB0-SysTokenBase
        defw tokenB1-SysTokenBase
        defw tokenB2-SysTokenBase
        defw tokenB3-SysTokenBase
        defw tokenB4-SysTokenBase
        defw tokenB5-SysTokenBase
        defw tokenB6-SysTokenBase
        defw tokenB7-SysTokenBase
        defw tokenB8-SysTokenBase
        defw tokenB9-SysTokenBase
        defw tokenBA-SysTokenBase
        defw tokenBB-SysTokenBase
        defw tokenBC-SysTokenBase
        defw tokenBD-SysTokenBase
        defw tokenBE-SysTokenBase
        defw tokenBF-SysTokenBase
        defw tokenC0-SysTokenBase
        defw tokenC1-SysTokenBase
        defw tokenC2-SysTokenBase
        defw tokenC3-SysTokenBase
        defw tokenC4-SysTokenBase
        defw tokenC5-SysTokenBase
        defw tokenC6-SysTokenBase
        defw tokenC7-SysTokenBase
        defw tokenC8-SysTokenBase
        defw tokenC9-SysTokenBase
        defw tokenCA-SysTokenBase
        defw tokenCB-SysTokenBase
        defw tokenCC-SysTokenBase
        defw tokenCD-SysTokenBase
        defw tokenCE-SysTokenBase
        defw tokenCF-SysTokenBase
        defw tokenD0-SysTokenBase
        defw tokenD1-SysTokenBase
        defw tokenD2-SysTokenBase
        defw tokenD3-SysTokenBase
        defw tokenD4-SysTokenBase
        defw tokenD5-SysTokenBase
        defw tokenD6-SysTokenBase
        defw tokenD7-SysTokenBase
        defw tokenD8-SysTokenBase
        defw tokenD9-SysTokenBase
        defw tokenDA-SysTokenBase
        defw tokenDB-SysTokenBase
        defw tokenDC-SysTokenBase
        defw tokenDD-SysTokenBase
        defw tokenDE-SysTokenBase
        defw tokenDF-SysTokenBase
        defw tokenE0-SysTokenBase
        defw tokenE1-SysTokenBase
        defw tokenE2-SysTokenBase
        defw tokenE3-SysTokenBase
        defw tokenE4-SysTokenBase
        defw tokenE5-SysTokenBase
        defw tokenE6-SysTokenBase
        defw tokenE7-SysTokenBase
        defw tokenE8-SysTokenBase
        defw tokenE9-SysTokenBase
        defw tokenEA-SysTokenBase
        defw tokenEB-SysTokenBase
        defw tokenEC-SysTokenBase
        defw tokenED-SysTokenBase
        defw tokenEE-SysTokenBase
        defw tokenEF-SysTokenBase
        defw tokenF0-SysTokenBase
        defw tokenF1-SysTokenBase
        defw tokenF2-SysTokenBase
        defw tokenF3-SysTokenBase
        defw tokenF4-SysTokenBase
        defw tokenF5-SysTokenBase
        defw tokenF6-SysTokenBase
        defw tokenF7-SysTokenBase
        defw tokenF8-SysTokenBase
        defw tokenF9-SysTokenBase
        defw tokenFA-SysTokenBase
        defw tokenFB-SysTokenBase
        defw tokenFC-SysTokenBase
        defw tokenFD-SysTokenBase
        defw tokenFE-SysTokenBase
        defw tokenFF-SysTokenBase
        defw end_tokens-SysTokenBase
.token80
        defm $01, "T"
.token81
        defm $DC, " "                           ; "Cursor "
.token82
        defm "e "
.token83
        defm " returns "
.token84
        defm "t "
.token85
        defm "in"
.token86
        defm "er"
.token87
        defm "ti",$BC                           ; "tion"  
.token88
        defm "th"
.token89
        defm "of "
.token8A
        defm "olumn"
.token8B
        defm "le"
.token8C
        defm "ar"
.token8D
        defm "re"
.token8E
        defm "s "
.token8F
        defm "or"
.token90
        defm "ig"
.token91
        defm "at"
.token92
        defm $88, $82                           ; "the "
.token93
        defm "an"                               ; "and " = $93 + $B2
.token94
        defm $8E, "Limited 1987,88", $7F, "Copyr", $90, "h", $84, "(C) "
.token95
        defm "al"
.token96
        defm "De", $8B, "t", $82                ; "Delete "
.token97
        defm "Nex", $84                         ; "Next "
.token98
        defm "P", $8D, "viou", $8E              ; "Previous "
.token99
        defm "h", $8C, "act", $86               ; "haracter"
.token9A
        defm ".", $7F
.token9B
        defm "Ins", $86                         ; "Inser"
.token9C
        defm "Func", $87                        ; "Function"
.token9D
        defm "ow"
.token9E
        defm "to"
.token9F
        defm "radi", $93, "s"                   ; "radians"
.tokenA0
        defm "list"
.tokenA1
        defm "numb", $86, " "                   ; "number "
.tokenA2
        defm "en"
.tokenA3
        defm $85, " "                           ; "in "
.tokenA4
        defm ", "
.tokenA5
        defm "lo"
.tokenA6
        defm "Fi"
.tokenA7
        defm $81, "R", $90, "ht"                ; "Cursor Right"
.tokenA8
        defm $81, "Left"                        ; "Cursor Left"
.tokenA9
        defm "L", $85, "e"                      ; "Line"
.tokenAA
        defm ": "
.tokenAB
        defm "Co"
.tokenAC
        defm "D", $9D, "n"                      ; "Down"
.tokenAD
        defm "Activ", $82, "D",$FB              ; "Active Day"
.tokenAE
        defm ")", $83, $92
.tokenAF
        defm "te"
.tokenB0
        defm '"', $9A
.tokenB1
        defm "ESCAPE"
.tokenB2
        defm "d "
.tokenB3
        defm "v", $95, "u"                      ; "valu"
.tokenB4
        defm "ch"
.tokenB5
        defm "C", $8A                           ; "Column"
.tokenB6
        defm "Di", $8D, "ct", $8F, "y"          ; "Directory"
.tokenB7
        defm " i", $8E                          ; " is "
.tokenB8
        defm "Logic", $95, " "                  ; "Logical "
.tokenB9
        defm "Up"
.tokenBA
        defm $A6, $8B                           ; "File"
.tokenBB
        defm $9E, " "                           ; "to "
.tokenBC
        defm "on"
.tokenBD
        defm "Sav"                              ; "Save " = $BD + $82
.tokenBE
        defm $82, "Posi", $87                   ; "e Position"
.tokenBF
        defm "Op"
.tokenC0
        defm $85, "g "                          ; "ing "
.tokenC1
        defm "(n"
.tokenC2
        defm $89, '"', "n"
.tokenC3
        defm $91, "e"                           ; "ate"
.tokenC4
        defm $AB, "l", $9E, "n Softw", $8C, $82, "Limi", $AF
.tokenC5
        defm "B", $A5, "ck"                     ; "Block"
.tokenC6
        defm "ur"
.tokenC7
        defm "e", $8B                           ; "ele"
.tokenC8
        defm "Re"
.tokenC9
        defm "ce"
.tokenCA
        defm "s", $84                           ; "st "
.tokenCB
        defm $9B, $84                           ; "Insert "
.tokenCC
        defm $90, "h"                           ; "igh"
.tokenCD
        defm "cos", $85, "e", $A4, "s", $85, $82, $8F, " t", $93, "g", $A2, $84
.tokenCE
        defm ". "
.tokenCF
        defm "s", $A5, "t", $8E, $A3, '"', $A0, $B0
.tokenD0
        defm " ", $A1, $A3, "whi", $B4, " i", $84, "i", $8E, "e", $B3, $C3, "d"
.tokenD1
        defm "Al", $90, "n"                     ; "Align"
.tokenD2
        defm "ENTER"
.tokenD3
        defm "W", $8F, "d"                      ; "Word"
.tokenD4
        defm "Sc", $8D, $A2, " "                ; "Screen "
.tokenD5
        defm "qu", $95, " ", $9E                ; "qual to"
.tokenD6
        defm "y "
.tokenD7
        defm "m "
.tokenD8
        defm "comm", $93, "ds"                  ; "commands"
.tokenD9
        defm "pl"
.tokenDA
        defm $81, $B9                           ; "Cursor Up"
.tokenDB
        defm $81, $AC                           ; "Cursor Down"
.tokenDC
        defm "C", $C6, "s", $8F                 ; "Cursor"
.tokenDD
        defm "M", $8C                           ; "Mar"
.tokenDE
        defm $AB, "py"                          ; "Copy"
.tokenDF
        defm "En", $B2, $89                     ; "End of "
.tokenE0
        defm "Rubout"
.tokenE1
        defm "Load"
.tokenE2
        defm "ra"
.tokenE3
        defm "S", $C7, "c", $84                 ; "Select "
.tokenE4
        defm "de"
.tokenE5
        defm "(", $A0, ")"
.tokenE6
        defm $B3, $82                           ; "value "
.tokenE7
        defm "r", $93, "ge"                     ; "range"
.tokenE8
        defm "Ex"
.tokenE9
        defm "C", $99                           ; "Character"
.tokenEA
        defm $9B, "t/Ov", $86, "type"           ; "Insert/Overtype"
.tokenEB
        defm "se"
.tokenEC
        defm $BF, $87                           ; "Option"
.tokenED
        defm "am"
.tokenEE
        defm $BA, " C", $8C, "d"                ; "File Card"
.tokenEF
        defm $86, " "                           ; "er "
.tokenF0
        defm $7F, $8D, "t", $C6, "n"            ; "return"
.tokenF1
        defm $E4, "g", $8D, "es"                ; "degrees"
.tokenF2
        defm '"', " c", $BC, "v", $86, $AF, $B2, $85, $BB
.tokenF3
        defm $E5, $B7, "i", $AF, $D7, "wi", $88, " m"
.tokenF4
        defm $A3, '"'
.tokenF5
        defm "d", $C3                           ; "date"
.tokenF6
        defm $BF, $86, $91, $8F, "s"            ; "Operators"
.tokenF7
        defm "M", $91, $B4                      ; "March"
.tokenF8
        defm $A6, "r", $CA                      ; "First "
.tokenF9
        defm "(", $9F, ")"                      ; "(radians)"
.tokenFA
        defm "S", $A5, "t"                      ; "Slot"
.tokenFB
        defm "ay"
.tokenFC
        defm "it"
.tokenFD
        defm $BA, "s"                           ; "Files"
.tokenFE
        defm "Pr", $85, "t"                     ; "Print"
.tokenFF
        defm "Swap Ca", $EB                     ; "Swap Case"
.end_tokens

; **************************************************************************************************
;
; OZ v4.7+ System token table, used by MTH static structures in most standard OZ applications and popdowns.
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
; compile this source code using
; Mpm Assembler (https://sourceforge.net/projects/z88/files/Z88%20Assembler%20Workbench/):
;
;       mpm -b -nMap systokens.asm
;
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
        defm $01,"T"
.token81
        defm "ou"
.token82
        defm "e "
.token83
        defm " ",$8D,"turn",$8E                 ; " returns " (19)
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
        defm $88,$82                            ; "the "
.token93
        defm "an"                               ; ("and " = $93 + $B2)
.token94
        defm $DE,"r",$CC,$84,"(C) "             ; "Copyright (C) " (3)
.token95
        defm "al"
.token96
        defm "De",$8B,"t",$82                   ; "Delete "
.token97
        defm "Nex",$84                          ; "Next "
.token98
        defm "P",$8D,"vi",$81,$8E               ; "Previous "
.token99
        defm "h",$8C,"act",$86                  ; "haracter"
.token9A
        defm ".",$7F
.token9B
        defm "mo"
.token9C
        defm "F",$D0,"c",$87                    ; "Function"
.token9D
        defm "ow"
.token9E
        defm "to"
.token9F
        defm $E2,"di",$93,"s"                   ; "radians" (7)
.tokenA0
        defm "l",$F4,"t"                        ; "list"
.tokenA1
        defm "numb",$86," "                     ; "number "
.tokenA2
        defm "en"
.tokenA3
        defm $85," "                            ; "in " (18)
.tokenA4
        defm ", "
.tokenA5
        defm "lo"
.tokenA6
        defm "Fi"                               ; "Fi" (5)
.tokenA7
        defm $DC," ","R",$90,"ht"               ; "Cursor Right"
.tokenA8
        defm $DC," ","Left"                     ; "Cursor Left"
.tokenA9
        defm "L",$85,"e"                        ; "Line"
.tokenAA
        defm ": "
.tokenAB
        defm "Co"                               ; "Co" (9)
.tokenAC
        defm "D",$9D,"n"                        ; "Down"
.tokenAD
        defm "Activ",$82,"D",$FB                ; "Active Day" (4)
.tokenAE
        defm "il"
.tokenAF
        defm "te"
.tokenB0
        defm '"',$9A                            ; ""." + $7F (14)
.tokenB1
        defm "ESCAPE"                           ; "ESCAPE" (5)
.tokenB2
        defm "d "
.tokenB3
        defm "ke"
.tokenB4
        defm "ch"
.tokenB5
        defm "C",$8A                            ; "Column"
.tokenB6
        defm "Di",$8D,"ct",$8F,"y"              ; "Directory" (4)
.tokenB7
        defm " i",$8E                           ; " is "
.tokenB8
        defm "Logic",$95," "                    ; "Logical " (4)
.tokenB9
        defm "Up"
.tokenBA
        defm $A6,$8B                            ; "File"
.tokenBB
        defm $9E," "                            ; "to "
.tokenBC
        defm "on"
.tokenBD
        defm "S",$F9                            ; "Sav" ("Save " = $BD + $82)
.tokenBE
        defm $82,"Po",$F3,$87                   ; "e Position" (4)
.tokenBF
        defm "p",$D9,"ica",$87                  ; "pplication"
.tokenC0
        defm $85,"g "                           ; "ing "
.tokenC1
        defm "(n)"                              ; "(n)" (9)
.tokenC2
        defm ".",$00                            ; ".",$00 (39)
.tokenC3
        defm $91, "e"                           ; "ate"
.tokenC4
        defm "devi",$c9                         ; "device" (10)
.tokenC5
        defm "B",$A5,"ck"                       ; "Block"
.tokenC6
        defm "ur"
.tokenC7
        defm "e",$8B                            ; "ele"
.tokenC8
        defm "Re"
.tokenC9
        defm "ce"
.tokenCA
        defm "s",$84                            ; "st "
.tokenCB
        defm "Ins",$86,$84                      ; "Insert "  (9)
.tokenCC
        defm $90, "h"                           ; "igh"
.tokenCD
        defm "ma"
.tokenCE
        defm ". "
.tokenCF
        defm "la"
.tokenD0
        defm "un"
.tokenD1
        defm "Al",$90,"n"                       ; "Align"
.tokenD2
        defm "ENTER"
.tokenD3
        defm "W",$8F,"d"                        ; "Word"
.tokenD4
        defm "Sc",$8D,$A2," "                   ; "Screen "
.tokenD5
        defm "qu",$95," ",$9E                   ; "qual to" (4)
.tokenD6
        defm "y "
.tokenD7
        defm "m "
.tokenD8
        defm "c",$E9,"m",$93,"ds"               ; "commands"
.tokenD9
        defm "pl"
.tokenDA
        defm $DC," ",$B9                        ; "Cursor Up"
.tokenDB
        defm $DC," ",$AC                        ; "Cursor Down"
.tokenDC
        defm "C",$C6,"s",$8F                    ; "Cursor"
.tokenDD
        defm "M",$8C                            ; "Mar" (7)
.tokenDE
        defm $AB,"py"                           ; "Copy"
.tokenDF
        defm "En",$B2,$89                       ; "End of "
.tokenE0
        defm "Rub",$81,"t"                      ; "Rubout"
.tokenE1
        defm "Load"
.tokenE2
        defm "ra"
.tokenE3
        defm "S",$C7,"c",$84                    ; "Select "
.tokenE4
        defm "de"
.tokenE5
        defm "hi"
.tokenE6
        defm "v",$95,"u",$82                    ; "value "
.tokenE7
        defm "r",$93,"ge"                       ; "range"
.tokenE8
        defm "Ex"
.tokenE9
        defm "om"
.tokenEA
        defm "Ins",$86,"t/Ov",$86,"type"        ; "Insert/Overtype" (2)
.tokenEB
        defm "se"
.tokenEC
        defm "Op",$87                           ; "Option"
.tokenED
        defm "am"
.tokenEE
        defm $BA," C",$8C,"d"                   ; "File Card" (14)
.tokenEF
        defm $86," "                            ; "er "
.tokenF0
        defm "st"
.tokenF1
        defm "pr"
.tokenF2
        defm " c"
.tokenF3
        defm "si"
.tokenF4
        defm "is"
.tokenF5
        defm "d",$C3                            ; "date"
.tokenF6
        defm "Op",$86,$91,$8F,"s"               ; "Operators" (3)
.tokenF7
        defm "M",$91,$B4                        ; "Match" (3)
.tokenF8
        defm $A6,"r",$CA                        ; "First "
.tokenF9
        defm "av"
.tokenFA
        defm "S",$A5,"t"                        ; "Slot"
.tokenFB
        defm "ay"
.tokenFC
        defm "it"
.tokenFD
        defm $BA,"s"                            ; "Files"
.tokenFE
        defm "Pr",$85,"t"                       ; "Print"
.tokenFF
        defm "Swap Ca",$EB                      ; "Swap Case" (2)
.end_tokens

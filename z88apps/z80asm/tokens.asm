; ********************************************************************************************************************
;
;     ZZZZZZZZZZZZZZZZZZZZ    8888888888888       00000000000
;   ZZZZZZZZZZZZZZZZZZZZ    88888888888888888    0000000000000
;                ZZZZZ      888           888  0000         0000
;              ZZZZZ        88888888888888888  0000         0000
;            ZZZZZ            8888888888888    0000         0000       AAAAAA         SSSSSSSSSSS   MMMM       MMMM
;          ZZZZZ            88888888888888888  0000         0000      AAAAAAAA      SSSS            MMMMMM   MMMMMM
;        ZZZZZ              8888         8888  0000         0000     AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
;      ZZZZZ                8888         8888  0000         0000    AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
;    ZZZZZZZZZZZZZZZZZZZZZ  88888888888888888    0000000000000     AAAA      AAAA           SSSSS   MMMM       MMMM
;  ZZZZZZZZZZZZZZZZZZZZZ      8888888888888       00000000000     AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM
;
; Copyright (C) Gunther Strube, 1995-2006
;
; Z80asm is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Z80asm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Z80asm;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; ********************************************************************************************************************

     MODULE tokens

     INCLUDE "applic.def"
     INCLUDE "stdio.def"

     ORG token_base

; 'Z80asm' command, topic, help, token definitions:

; ******************************************************************************************************************
.tokens_base        DEFB $8C-$80+1                      ; recursive token boundary
                    DEFB $FF-$80+1                      ; number of tokens

                    DEFW tok80def - tokens_base         ; relative pointer to token
                    DEFW tok81def - tokens_base
                    DEFW tok82def - tokens_base
                    DEFW tok83def - tokens_base
                    DEFW tok84def - tokens_base
                    DEFW tok85def - tokens_base
                    DEFW tok86def - tokens_base
                    DEFW tok87def - tokens_base
                    DEFW tok88def - tokens_base
                    DEFW tok89def - tokens_base
                    DEFW tok8Adef - tokens_base
                    DEFW tok8Bdef - tokens_base
                    DEFW tok8Cdef - tokens_base
                    DEFW tok8Ddef - tokens_base
                    DEFW tok8Edef - tokens_base
                    DEFW tok8Fdef - tokens_base
                    DEFW tok90def - tokens_base
                    DEFW tok91def - tokens_base
                    DEFW tok92def - tokens_base
                    DEFW tok93def - tokens_base
                    DEFW tok94def - tokens_base
                    DEFW tok95def - tokens_base
                    DEFW tok96def - tokens_base
                    DEFW tok97def - tokens_base
                    DEFW tok98def - tokens_base
                    DEFW tok99def - tokens_base
                    DEFW tok9Adef - tokens_base
                    DEFW tok9Bdef - tokens_base
                    DEFW tok9Cdef - tokens_base
                    DEFW tok9Ddef - tokens_base
                    DEFW tok9Edef - tokens_base
                    DEFW tok9Fdef - tokens_base
                    DEFW tokA0def - tokens_base
                    DEFW tokA1def - tokens_base
                    DEFW tokA2def - tokens_base
                    DEFW tokA3def - tokens_base
                    DEFW tokA4def - tokens_base
                    DEFW tokA5def - tokens_base
                    DEFW tokA6def - tokens_base
                    DEFW tokA7def - tokens_base
                    DEFW tokA8def - tokens_base
                    DEFW tokA9def - tokens_base
                    DEFW tokAAdef - tokens_base
                    DEFW tokABdef - tokens_base
                    DEFW tokACdef - tokens_base
                    DEFW tokADdef - tokens_base
                    DEFW tokAEdef - tokens_base
                    DEFW tokAFdef - tokens_base
                    DEFW tokB0def - tokens_base
                    DEFW tokB1def - tokens_base
                    DEFW tokB2def - tokens_base
                    DEFW tokB3def - tokens_base
                    DEFW tokB4def - tokens_base
                    DEFW tokB5def - tokens_base
                    DEFW tokB6def - tokens_base
                    DEFW tokB7def - tokens_base
                    DEFW tokB8def - tokens_base
                    DEFW tokB9def - tokens_base
                    DEFW tokBAdef - tokens_base
                    DEFW tokBBdef - tokens_base
                    DEFW tokBCdef - tokens_base
                    DEFW tokBDdef - tokens_base
                    DEFW tokBEdef - tokens_base
                    DEFW tokBFdef - tokens_base
                    DEFW tokC0def - tokens_base
                    DEFW tokC1def - tokens_base
                    DEFW tokC2def - tokens_base
                    DEFW tokC3def - tokens_base
                    DEFW tokC4def - tokens_base
                    DEFW tokC5def - tokens_base
                    DEFW tokC6def - tokens_base
                    DEFW tokC7def - tokens_base
                    DEFW tokC8def - tokens_base
                    DEFW tokC9def - tokens_base
                    DEFW tokCAdef - tokens_base
                    DEFW tokCBdef - tokens_base
                    DEFW tokCCdef - tokens_base
                    DEFW tokCDdef - tokens_base
                    DEFW tokCEdef - tokens_base
                    DEFW tokCFdef - tokens_base
                    DEFW tokD0def - tokens_base
                    DEFW tokD1def - tokens_base
                    DEFW tokD2def - tokens_base
                    DEFW tokD3def - tokens_base
                    DEFW tokD4def - tokens_base
                    DEFW tokD5def - tokens_base
                    DEFW tokD6def - tokens_base
                    DEFW tokD7def - tokens_base
                    DEFW tokD8def - tokens_base
                    DEFW tokD9def - tokens_base
                    DEFW tokDAdef - tokens_base
                    DEFW tokDBdef - tokens_base
                    DEFW tokDCdef - tokens_base
                    DEFW tokDDdef - tokens_base
                    DEFW tokDEdef - tokens_base
                    DEFW tokDFdef - tokens_base
                    DEFW tokE0def - tokens_base
                    DEFW tokE1def - tokens_base
                    DEFW tokE2def - tokens_base
                    DEFW tokE3def - tokens_base
                    DEFW tokE4def - tokens_base
                    DEFW tokE5def - tokens_base
                    DEFW tokE6def - tokens_base
                    DEFW tokE7def - tokens_base
                    DEFW tokE8def - tokens_base
                    DEFW tokE9def - tokens_base
                    DEFW tokEAdef - tokens_base
                    DEFW tokEBdef - tokens_base
                    DEFW tokECdef - tokens_base
                    DEFW tokEDdef - tokens_base
                    DEFW tokEEdef - tokens_base
                    DEFW tokEFdef - tokens_base
                    DEFW tokF0def - tokens_base
                    DEFW tokF1def - tokens_base
                    DEFW tokF2def - tokens_base
                    DEFW tokF3def - tokens_base
                    DEFW tokF4def - tokens_base
                    DEFW tokF5def - tokens_base
                    DEFW tokF6def - tokens_base
                    DEFW tokF7def - tokens_base
                    DEFW tokF8def - tokens_base
                    DEFW tokF9def - tokens_base
                    DEFW tokFAdef - tokens_base
                    DEFW tokFBdef - tokens_base
                    DEFW tokFCdef - tokens_base
                    DEFW tokFDdef - tokens_base
                    DEFW tokFEdef - tokens_base
                    DEFW tokFFdef - tokens_base
                    DEFW end_tokens - tokens_base                                ; rel. ptr to end of tokens

.tok80def           DEFM 1, "T"                        ; VDU tiny
.tok81def           DEFM 1, "B"                        ; VDU bold
.tok82def           DEFM 1, "G"                        ; VDU grey
.tok83def           DEFM 1, MU_TAB                     ; VDU <TAB>
.tok84def           DEFM 1, SD_ODWN                    ; VDU Outline Down Arrow
.tok85def           DEFM 1, SD_OUP                     ; VDU Outline Up Arrow
.tok86def           DEFM 1, SD_SHFT                    ; VDU <SHIFT> symbol
.tok87def           DEFM 1, SD_DIAM                    ; VDU <DIAMOND> symbol
.tok88def           DEFM 1, SD_ENT                     ; VDU <ENTER> symbol
.tok89def           DEFM 1, SD_BLFT                    ; VDU Bullet Arrow Left
.tok8Adef           DEFM 1, SD_BRGT                    ; VDU Bullet Arrow Right
.tok8Bdef           DEFM 1, SD_ESC                     ; VDU ESC symbol
.tok8Cdef           DEFM 1, SD_INX                     ; VDU INDEX symbol
.tok8Ddef           DEFM "ddress"
.tok8Edef           DEFM "uffer"
.tok8Fdef           DEFM "Eprom"
.tok90def           DEFM "Z88"
.tok91def           DEFM "0000h"
.tok92def           DEFM "he"
.tok93def           DEFM "earch"
.tok94def           DEFM "Hex"
.tok95def           DEFM "oad"
.tok96def           DEFM "yte"
.tok97def           DEFM "ursor"
.tok98def           DEFM "rogram"
.tok99def           DEFM "ef", $CF, "e"              ; 'efine'
.tok9Adef           DEFM $CF, $FA, "ma", $CD        ; 'information'
.tok9Bdef           DEFM "contents"
.tok9Cdef           DEFM $FD, "ge"                    ; 'ange'
.tok9Ddef           DEFM "Ascii"
.tok9Edef           DEFM "View"
.tok9Fdef           DEFM "3FFFh"

.tokA0def           DEFM "Us", $DA, "only ", $CF, " ", $9E, "/", $A7, " ", $A9, "/", $8F, " ", $BA, "s.", $7F
.tokA1def           DEFM "T", $92                     ; 'The'
.tokA2def           DEFM "t", $92                     ; 'the'
.tokA3def           DEFM "C", $97                     ; 'Cursor'
.tokA4def           DEFM "c", $97                     ; 'cursor'
.tokA5def           DEFM "D", $99                     ; 'Define'
.tokA6def           DEFM "d", $99                     ; 'define'
.tokA7def           DEFM "E", $C6                     ; 'Edit'
.tokA8def           DEFM "e", $C6                     ; 'edit'
.tokA9def           DEFM "M", $E4                     ; 'Memory'
.tokAAdef           DEFM "m", $E4                     ; 'memory'
.tokABdef           DEFM "R", $9C                     ; 'Range'
.tokACdef           DEFM "r", $9C                     ; 'range'
.tokADdef           DEFM "B", $8E                     ; 'Buffer'
.tokAEdef           DEFM "b", $8E                     ; 'buffer'
.tokAFdef           DEFM $81, "Zprom", $81
.tokB0def           DEFM "ump"
.tokB1def           DEFM "D", $B0                     ; 'Dump'
.tokB2def           DEFM "d", $B0                     ; 'dump'
.tokB3def           DEFM " ", $A2, " "               ; ' the '
.tokB4def           DEFM "P", $98                     ; 'Program'
.tokB5def           DEFM "p", $98                     ; 'program'
.tokB6def           DEFM "Design, ", $B4, "m", $CE, " by Gunther Strube"
.tokB7def           DEFM "Copyright (C) Int", $FE, "Logic 1995-2006"
.tokB8def           DEFM "pplica", $CD                ; 'pplication'
.tokB9def           DEFM "C", $E0                     ; 'Command'
.tokBAdef           DEFM "c", $E0                     ; 'command'
.tokBBdef           DEFM "B", $E3                     ; 'Bank'
.tokBCdef           DEFM "b", $E3                     ; 'bank'
.tokBDdef           DEFM "L", $95                     ; 'Load'
.tokBEdef           DEFM "l", $95                     ; 'load'
.tokBFdef           DEFM "S", $93                     ; 'Search'
.tokC0def           DEFM "s", $93                     ; 'search'
.tokC1def           DEFM "A", $8D                     ; 'Address'
.tokC2def           DEFM "a", $8D                     ; 'address'
.tokC3def           DEFM "B", $96                     ; 'Byte'
.tokC4def           DEFM "b", $96                     ; 'byte'
.tokC5def           DEFM 1, $2A                       ; VDU Square symbol
.tokC6def           DEFM "dit"
.tokC7def           DEFM "Protect", $DA, "- c", $FD, " only", $F1, "activat", $DA, "by ", $BA, " sequense."
.tokC8def           DEFM "A", $B8                     ; 'Application'
.tokC9def           DEFM "a", $B8                     ; 'application'
.tokCAdef           DEFM "ile"
.tokCBdef           DEFM "F", $CA                     ; 'File'
.tokCCdef           DEFM "f", $CA                     ; 'file'
.tokCDdef           DEFM "tion"
.tokCEdef           DEFM $CF, "g"                     ; 'ing'
.tokCFdef           DEFM "in"
.tokD0def           DEFM $FD, "d"                     ; 'and'
.tokD1def           DEFM " ", $D0, " "               ; ' and '
.tokD2def           DEFM "wi", $D6                    ; 'with'
.tokD3def           DEFM " ", $D2, " "               ; ' with '
.tokD4def           DEFM "is"                          ; 'is'
.tokD5def           DEFM " ", $D4, " "               ; ' is '
.tokD6def           DEFM "th"
.tokD7def           DEFM "ROM"
.tokD8def           DEFM "Card"
.tokD9def           DEFM "Head", $FE                  ; 'Header'
.tokDAdef           DEFM "ed "
.tokDBdef           DEFM " will "
.tokDCdef           DEFM "are"
.tokDDdef           DEFM " ", $DC, " "               ; ' are '
.tokDEdef           DEFM "to"
.tokDFdef           DEFM " ", $DE, " "               ; ' to '
.tokE0def           DEFM "omm", $D0
.tokE1def           DEFM "current"
.tokE2def           DEFM 1, "2JN"
.tokE3def           DEFM $FD, "k"                     ; 'ank'
.tokE4def           DEFM "emory"
.tokE5def           DEFM "[+|-]"
.tokE6def           DEFM "<nn>"
.tokE7def           DEFM " [", $E6, "]"
.tokE8def           DEFM " [<n>]"
.tokE9def           DEFM $81, "Intui", $CD, $81     ; 'Intuition'
.tokEAdef           DEFM "regist", $FE                ; 'register'
.tokEBdef           DEFM " Display "
.tokECdef           DEFM "flag"
.tokEDdef           DEFM "execu"
.tokEEdef           DEFM $ED, $CD                     ; 'execution'
.tokEFdef           DEFM "specif"
.tokF0def           DEFM "identi"
.tokF1def           DEFM " be "
.tokF2def           DEFM "not"
.tokF3def           DEFM "window"
.tokF4def           DEFM "default"
.tokF5def           DEFM "const", $FD, "t"           ; 'constant'
.tokF6def           DEFM "paramet", $FE
.tokF7def           DEFM "decimal"
.tokF8def           DEFM "c", $FD                     ; 'can'
.tokF9def           DEFM "bit"
.tokFAdef           DEFM "for"
.tokFBdef           DEFM "be", $FA, "e"              ; 'before'
.tokFCdef           DEFM " ", $FD, " "               ; ' an '
.tokFDdef           DEFM "an"
.tokFEdef           DEFM "er"
.tokFFdef           DEFM " of "
.end_tokens

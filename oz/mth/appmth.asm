; **************************************************************************************************
; OZ Application/Popdown MTH definitions (top bank of ROM).
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
; (C) Thierry Peycru (pek@users.sf.net), 2005,2006
; (C) Gunther Strube (gbs@users.sf.net), 2005,2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module AppMth

        include "stdio.def"

        include "mth-flashstore.def"

xdef    IndexTopics, IndexCommands, IndexHelp
xdef    DiaryTopics, DiaryCommands, DiaryHelp
xdef    PipeDreamTopics, PipeDreamCommands, PipeDreamHelp
xdef    FilerTopics, FilerCommands, FilerHelp
xdef    BasicHelp
xdef    PrinterEdTopics, PrinterEdCommands, PrinterEdHelp
xdef    PanelTopics, PanelCommands, PanelHelp
xdef    CalculatorHelp
xdef    CalendarHelp
xdef    ClockHelp
xdef    AlarmHelp
xdef    TerminalTopics, TerminalCommands, TerminalHelp
xdef    ImpExpHelp
xdef    EazyLinkHelp
xdef    FlashStoreTopics, FlashStoreCommands, FlashStoreHelp


; ********************************************************************************************************************
; MTH for Index popdown...
;
; "Commands"
.IndexTopics

        defb    0	; Start topic marker
.Index_tpc1
        defb    Index_tpc1_end-Index_tpc1+1	; Length of topic
        defm    $d8
        defb    $00	; Topic attribute
.Index_tpc1_end
        defb    Index_tpc1_end-Index_tpc1+1
        defb    0	; End topic marker

.IndexCommands
        defb    0	; Start command marker
.Index_cmd1
        defb    Index_cmd1_end-Index_cmd1+1	; Length of command
        defb    $05	; command code
        defm    $e1, $00
        defm    $e8, "ecu", $af
        defb    $00	; Command attribute
.Index_cmd1_end
        defb    Index_cmd1_end-Index_cmd1+1

.Index_cmd2
        defb    Index_cmd2_end-Index_cmd2+1	; Length of command
        defb    $06	; command code
        defm    $1b, $00
        defm    $b1
        defb    $00	; Command attribute
.Index_cmd2_end
        defb    Index_cmd2_end-Index_cmd2+1

.Index_cmd3
        defb    Index_cmd3_end-Index_cmd3+1	; Length of command
        defb    $08	; command code
        defm    "CARD", $00
        defm    "C", $8c, $b2, "Dis", $d9, $fb
        defb    $00	; Command attribute
.Index_cmd3_end
        defb    Index_cmd3_end-Index_cmd3+1

.Index_cmd4
        defb    Index_cmd4_end-Index_cmd4+1	; Length of command
        defb    $01	; command code
        defm    $fd, $00
        defm    $a7
        defb    $01	; Command attribute
.Index_cmd4_end
        defb    Index_cmd4_end-Index_cmd4+1

.Index_cmd5
        defb    Index_cmd5_end-Index_cmd5+1	; Length of command
        defb    $02	; command code
        defm    $fc, $00
        defm    $a8
        defb    $00	; Command attribute
.Index_cmd5_end
        defb    Index_cmd5_end-Index_cmd5+1

.Index_cmd6
        defb    Index_cmd6_end-Index_cmd6+1	; Length of command
        defb    $03	; command code
        defm    $ff, $00
        defm    $da
        defb    $00	; Command attribute
.Index_cmd6_end
        defb    Index_cmd6_end-Index_cmd6+1

.Index_cmd7
        defb    Index_cmd7_end-Index_cmd7+1	; Length of command
        defb    $04	; command code
        defm    $fe, $00
        defm    $db
        defb    $00	; Command attribute
.Index_cmd7_end
        defb    Index_cmd7_end-Index_cmd7+1

.Index_cmd8
        defb    Index_cmd8_end-Index_cmd8+1	; Length of command
        defb    $07	; command code
        defm    "KILL", $00
        defm    $80, "KILL ACTIVITY"
        defb    $09	; Command attribute
.Index_cmd8_end
        defb    Index_cmd8_end-Index_cmd8+1

.Index_cmd9
        defb    Index_cmd9_end-Index_cmd9+1	; Length of command
        defb    $09	; command code
        defm    "PURGE", $00
        defm    $80, "PURGE SYSTEM"
        defb    $08	; Command attribute
.Index_cmd9_end
        defb    Index_cmd9_end-Index_cmd9+1
        defb    0	; End command marker



; ********************************************************************************************************************
; MTH for PipeDream application...
;
.PipeDreamTopics
        defb    0	; Start topic marker

; "Blocks"
.PipeDream_tpc1
        defb    PipeDream_tpc1_end-PipeDream_tpc1+1	; Length of topic
        defm    $c5, "s"
        defb    $00	; Topic attribute
.PipeDream_tpc1_end
        defb    PipeDream_tpc1_end-PipeDream_tpc1+1

; "Cursor"
.PipeDream_tpc2
        defb    PipeDream_tpc2_end-PipeDream_tpc2+1	; Length of topic
        defm    $dc
        defb    $00	; Topic attribute
.PipeDream_tpc2_end
        defb    PipeDream_tpc2_end-PipeDream_tpc2+1

; "Edit"
.PipeDream_tpc3
        defb    PipeDream_tpc3_end-PipeDream_tpc3+1	; Length of topic
        defm    "Ed", $fc
        defb    $01	; Topic attribute
.PipeDream_tpc3_end
        defb    PipeDream_tpc3_end-PipeDream_tpc3+1

; "Files"
.PipeDream_tpc4
        defb    PipeDream_tpc4_end-PipeDream_tpc4+1	; Length of topic
        defm    $fd
        defb    $00	; Topic attribute
.PipeDream_tpc4_end
        defb    PipeDream_tpc4_end-PipeDream_tpc4+1

; "Layout"
.PipeDream_tpc5
        defb    PipeDream_tpc5_end-PipeDream_tpc5+1	; Length of topic
        defm    "L", $fb, "out"
        defb    $00	; Topic attribute
.PipeDream_tpc5_end
        defb    PipeDream_tpc5_end-PipeDream_tpc5+1

; "Options"
.PipeDream_tpc6
        defb    PipeDream_tpc6_end-PipeDream_tpc6+1	; Length of topic
        defm    $ec, "s"
        defb    $00	; Topic attribute
.PipeDream_tpc6_end
        defb    PipeDream_tpc6_end-PipeDream_tpc6+1

; "Print"
.PipeDream_tpc7
        defb    PipeDream_tpc7_end-PipeDream_tpc7+1	; Length of topic
        defm    $fe
        defb    $00	; Topic attribute
.PipeDream_tpc7_end
        defb    PipeDream_tpc7_end-PipeDream_tpc7+1
        defb    0	; End topic marker


.PipeDreamCommands
        defb    0

.PipeDream_cmd1
        defb    PipeDream_cmd1_end-PipeDream_cmd1+1	; Length of command
        defb    $01	; command code
        defm    "Z", $00
        defm    $dd, "k ", $c5
        defb    $00	; Command attribute
.PipeDream_cmd1_end
        defb    PipeDream_cmd1_end-PipeDream_cmd1+1

.PipeDream_cmd2
        defb    PipeDream_cmd2_end-PipeDream_cmd2+1	; Length of command
        defb    $02	; command code
        defm    "Q", $00
        defm    "C", $8b, $8c, " ", $dd, "k"
        defb    $00	; Command attribute
.PipeDream_cmd2_end
        defb    PipeDream_cmd2_end-PipeDream_cmd2+1

.PipeDream_cmd3
        defb    PipeDream_cmd3_end-PipeDream_cmd3+1	; Length of command
        defb    $04	; command code
        defm    "BC", $00
        defm    $de
        defb    $00	; Command attribute
.PipeDream_cmd3_end
        defb    PipeDream_cmd3_end-PipeDream_cmd3+1

.PipeDream_cmd4
        defb    PipeDream_cmd4_end-PipeDream_cmd4+1	; Length of command
        defb    $05	; command code
        defm    "BM", $00
        defm    "Move"
        defb    $00	; Command attribute
.PipeDream_cmd4_end
        defb    PipeDream_cmd4_end-PipeDream_cmd4+1

.PipeDream_cmd5
        defb    PipeDream_cmd5_end-PipeDream_cmd5+1	; Length of command
        defb    $06	; command code
        defm    "BD", $00
        defm    "D", $c7, $af
        defb    $00	; Command attribute
.PipeDream_cmd5_end
        defb    PipeDream_cmd5_end-PipeDream_cmd5+1

.PipeDream_cmd6
        defb    PipeDream_cmd6_end-PipeDream_cmd6+1	; Length of command
        defb    $07	; command code
        defm    "BSO", $00
        defm    "S", $8f, "t"
        defb    $00	; Command attribute
.PipeDream_cmd6_end
        defb    PipeDream_cmd6_end-PipeDream_cmd6+1

.PipeDream_cmd7
        defb    PipeDream_cmd7_end-PipeDream_cmd7+1	; Length of command
        defb    $03	; command code
        defm    "BRE", $00
        defm    $c8, $d9, "ic", $c3
        defb    $00	; Command attribute
.PipeDream_cmd7_end
        defb    PipeDream_cmd7_end-PipeDream_cmd7+1

.PipeDream_cmd8
        defb    PipeDream_cmd8_end-PipeDream_cmd8+1	; Length of command
        defb    $08	; command code
        defm    "BSE", $00
        defm    "Se", $8c, $b4
        defb    $01	; Command attribute
.PipeDream_cmd8_end
        defb    PipeDream_cmd8_end-PipeDream_cmd8+1

.PipeDream_cmd9
        defb    PipeDream_cmd9_end-PipeDream_cmd9+1	; Length of command
        defb    $0a	; command code
        defm    "BRP", $00
        defm    $c8, $d9, "a", $c9
        defb    $00	; Command attribute
.PipeDream_cmd9_end
        defb    PipeDream_cmd9_end-PipeDream_cmd9+1

.PipeDream_cmd10
        defb    PipeDream_cmd10_end-PipeDream_cmd10+1	; Length of command
        defb    $09	; command code
        defm    "BNM", $00
        defm    $97, $f7
        defb    $00	; Command attribute
.PipeDream_cmd10_end
        defb    PipeDream_cmd10_end-PipeDream_cmd10+1

.PipeDream_cmd11
        defb    PipeDream_cmd11_end-PipeDream_cmd11+1	; Length of command
        defb    $0b	; command code
        defm    "BWC", $00
        defm    "W", $8f, $b2, $ab, "unt"
        defb    $01	; Command attribute
.PipeDream_cmd11_end
        defb    PipeDream_cmd11_end-PipeDream_cmd11+1

.PipeDream_cmd12
        defb    PipeDream_cmd12_end-PipeDream_cmd12+1	; Length of command
        defb    $0c	; command code
        defm    "BNEW", $00
        defm    "New"
        defb    $00	; Command attribute
.PipeDream_cmd12_end
        defb    PipeDream_cmd12_end-PipeDream_cmd12+1

.PipeDream_cmd13
        defb    PipeDream_cmd13_end-PipeDream_cmd13+1	; Length of command
        defb    $0d	; command code
        defm    "A", $00
        defm    $c8, "c", $95, "cul", $c3
        defb    $00	; Command attribute
.PipeDream_cmd13_end
        defb    PipeDream_cmd13_end-PipeDream_cmd13+1

        defb    1	; Command topic separator

.PipeDream_cmd14
        defb    PipeDream_cmd14_end-PipeDream_cmd14+1	; Length of command
        defb    $10	; command code
        defm    $f5, $00
        defm    $df, $fa
        defb    $00	; Command attribute
.PipeDream_cmd14_end
        defb    PipeDream_cmd14_end-PipeDream_cmd14+1

.PipeDream_cmd15
        defb    PipeDream_cmd15_end-PipeDream_cmd15+1	; Length of command
        defb    $0f	; command code
        defm    $f4, $00
        defm    "St", $8c, $84, $89, $fa
        defb    $00	; Command attribute
.PipeDream_cmd15_end
        defb    PipeDream_cmd15_end-PipeDream_cmd15+1

.PipeDream_cmd16
        defb    PipeDream_cmd16_end-PipeDream_cmd16+1	; Length of command
        defb    $20	; command code
        defm    $f7, $00
        defm    "Top ", $89, $b5
        defb    $00	; Command attribute
.PipeDream_cmd16_end
        defb    PipeDream_cmd16_end-PipeDream_cmd16+1

.PipeDream_cmd17
        defb    PipeDream_cmd17_end-PipeDream_cmd17+1	; Length of command
        defb    $21	; command code
        defm    "COBRA", $00
        defb    $04	; Command attribute
.PipeDream_cmd17_end
        defb    PipeDream_cmd17_end-PipeDream_cmd17+1

.PipeDream_cmd18
        defb    PipeDream_cmd18_end-PipeDream_cmd18+1	; Length of command
        defb    $22	; command code
        defm    $f6, $00
        defm    "Bot", $9e, $d7, $89, $b5
        defb    $00	; Command attribute
.PipeDream_cmd18_end
        defb    PipeDream_cmd18_end-PipeDream_cmd18+1

.PipeDream_cmd19
        defb    PipeDream_cmd19_end-PipeDream_cmd19+1	; Length of command
        defb    $14	; command code
        defm    "CSP", $00
        defm    $bd, $be
        defb    $00	; Command attribute
.PipeDream_cmd19_end
        defb    PipeDream_cmd19_end-PipeDream_cmd19+1

.PipeDream_cmd20
        defb    PipeDream_cmd20_end-PipeDream_cmd20+1	; Length of command
        defb    $15	; command code
        defm    "CRP", $00
        defm    $c8, "st", $8f, $be
        defb    $00	; Command attribute
.PipeDream_cmd20_end
        defb    PipeDream_cmd20_end-PipeDream_cmd20+1

.PipeDream_cmd21
        defb    PipeDream_cmd21_end-PipeDream_cmd21+1	; Length of command
        defb    $0e	; command code
        defm    "CGS", $00
        defm    "Go ", $bb, $fa
        defb    $00	; Command attribute
.PipeDream_cmd21_end
        defb    PipeDream_cmd21_end-PipeDream_cmd21+1

.PipeDream_cmd22
        defb    PipeDream_cmd22_end-PipeDream_cmd22+1	; Length of command
        defb    $13	; command code
        defm    $e1, $00
        defm    $d2
        defb    $00	; Command attribute
.PipeDream_cmd22_end
        defb    PipeDream_cmd22_end-PipeDream_cmd22+1

.PipeDream_cmd23
        defb    PipeDream_cmd23_end-PipeDream_cmd23+1	; Length of command
        defb    $1a	; command code
        defm    $f9, $00
        defm    $97, $d3
        defb    $01	; Command attribute
.PipeDream_cmd23_end
        defb    PipeDream_cmd23_end-PipeDream_cmd23+1

.PipeDream_cmd24
        defb    PipeDream_cmd24_end-PipeDream_cmd24+1	; Length of command
        defb    $1b	; command code
        defm    $f8, $00
        defm    $98, $d3
        defb    $00	; Command attribute
.PipeDream_cmd24_end
        defb    PipeDream_cmd24_end-PipeDream_cmd24+1

.PipeDream_cmd25
        defb    PipeDream_cmd25_end-PipeDream_cmd25+1	; Length of command
        defb    $1c	; command code
        defm    $fb, $00
        defm    $d4, $b9
        defb    $00	; Command attribute
.PipeDream_cmd25_end
        defb    PipeDream_cmd25_end-PipeDream_cmd25+1

.PipeDream_cmd26
        defb    PipeDream_cmd26_end-PipeDream_cmd26+1	; Length of command
        defb    $1d	; command code
        defm    $fa, $00
        defm    $d4, $ac
        defb    $00	; Command attribute
.PipeDream_cmd26_end
        defb    PipeDream_cmd26_end-PipeDream_cmd26+1

.PipeDream_cmd27
        defb    PipeDream_cmd27_end-PipeDream_cmd27+1	; Length of command
        defb    $16	; command code
        defm    $fd, $00
        defm    $a7
        defb    $00	; Command attribute
.PipeDream_cmd27_end
        defb    PipeDream_cmd27_end-PipeDream_cmd27+1

.PipeDream_cmd28
        defb    PipeDream_cmd28_end-PipeDream_cmd28+1	; Length of command
        defb    $17	; command code
        defm    $fc, $00
        defm    $a8
        defb    $00	; Command attribute
.PipeDream_cmd28_end
        defb    PipeDream_cmd28_end-PipeDream_cmd28+1

.PipeDream_cmd29
        defb    PipeDream_cmd29_end-PipeDream_cmd29+1	; Length of command
        defb    $19	; command code
        defm    $ff, $00
        defm    $da
        defb    $00	; Command attribute
.PipeDream_cmd29_end
        defb    PipeDream_cmd29_end-PipeDream_cmd29+1

.PipeDream_cmd30
        defb    PipeDream_cmd30_end-PipeDream_cmd30+1	; Length of command
        defb    $18	; command code
        defm    $fe, $00
        defm    $db
        defb    $00	; Command attribute
.PipeDream_cmd30_end
        defb    PipeDream_cmd30_end-PipeDream_cmd30+1

.PipeDream_cmd31
        defb    PipeDream_cmd31_end-PipeDream_cmd31+1	; Length of command
        defb    $1f	; command code
        defm    $e2, $00
        defm    $97, $b5
        defb    $01	; Command attribute
.PipeDream_cmd31_end
        defb    PipeDream_cmd31_end-PipeDream_cmd31+1

.PipeDream_cmd32
        defb    PipeDream_cmd32_end-PipeDream_cmd32+1	; Length of command
        defb    $1e	; command code
        defm    $d2, $00
        defm    $98, $b5
        defb    $00	; Command attribute
.PipeDream_cmd32_end
        defb    PipeDream_cmd32_end-PipeDream_cmd32+1

.PipeDream_cmd33
        defb    PipeDream_cmd33_end-PipeDream_cmd33+1	; Length of command
        defb    $11	; command code
        defm    "CFC", $00
        defm    $f8, $b5
        defb    $00	; Command attribute
.PipeDream_cmd33_end
        defb    PipeDream_cmd33_end-PipeDream_cmd33+1

.PipeDream_cmd34
        defb    PipeDream_cmd34_end-PipeDream_cmd34+1	; Length of command
        defb    $11	; command code
        defm    $c2, $00
        defb    $04	; Command attribute
.PipeDream_cmd34_end
        defb    PipeDream_cmd34_end-PipeDream_cmd34+1

.PipeDream_cmd35
        defb    PipeDream_cmd35_end-PipeDream_cmd35+1	; Length of command
        defb    $12	; command code
        defm    "CLC", $00
        defm    "La", $ca, $b5
        defb    $00	; Command attribute
.PipeDream_cmd35_end
        defb    PipeDream_cmd35_end-PipeDream_cmd35+1

        defb    1 ; Command topic separator

.PipeDream_cmd36
        defb    PipeDream_cmd36_end-PipeDream_cmd36+1	; Length of command
        defb    $23	; command code
        defm    $e3, $00
        defm    $e0
        defb    $00	; Command attribute
.PipeDream_cmd36_end
        defb    PipeDream_cmd36_end-PipeDream_cmd36+1

.PipeDream_cmd37
        defb    PipeDream_cmd37_end-PipeDream_cmd37+1	; Length of command
        defb    $24	; command code
        defm    "G", $00
        defm    $96, $e9
        defb    $00	; Command attribute
.PipeDream_cmd37_end
        defb    PipeDream_cmd37_end-PipeDream_cmd37+1

.PipeDream_cmd38
        defb    PipeDream_cmd38_end-PipeDream_cmd38+1	; Length of command
        defb    $24	; command code
        defm    $d3, $00
        defb    $04	; Command attribute
.PipeDream_cmd38_end
        defb    PipeDream_cmd38_end-PipeDream_cmd38+1

.PipeDream_cmd39
        defb    PipeDream_cmd39_end-PipeDream_cmd39+1	; Length of command
        defb    $25	; command code
        defm    "U", $00
        defm    $cb, $e9
        defb    $00	; Command attribute
.PipeDream_cmd39_end
        defb    PipeDream_cmd39_end-PipeDream_cmd39+1

.PipeDream_cmd40
        defb    PipeDream_cmd40_end-PipeDream_cmd40+1	; Length of command
        defb    $26	; command code
        defm    "T", $00
        defm    $96, $d3
        defb    $00	; Command attribute
.PipeDream_cmd40_end
        defb    PipeDream_cmd40_end-PipeDream_cmd40+1

.PipeDream_cmd41
        defb    PipeDream_cmd41_end-PipeDream_cmd41+1	; Length of command
        defb    $27	; command code
        defm    "D", $00
        defm    $96, $bb, $df, $fa
        defb    $00	; Command attribute
.PipeDream_cmd41_end
        defb    PipeDream_cmd41_end-PipeDream_cmd41+1

.PipeDream_cmd42
        defb    PipeDream_cmd42_end-PipeDream_cmd42+1	; Length of command
        defb    $29	; command code
        defm    "Y", $00
        defm    $96, "R", $9d
        defb    $00	; Command attribute
.PipeDream_cmd42_end
        defb    PipeDream_cmd42_end-PipeDream_cmd42+1

.PipeDream_cmd43
        defb    PipeDream_cmd43_end-PipeDream_cmd43+1	; Length of command
        defb    $29	; command code
        defm    $c3, $00
        defb    $04	; Command attribute
.PipeDream_cmd43_end
        defb    PipeDream_cmd43_end-PipeDream_cmd43+1

.PipeDream_cmd44
        defb    PipeDream_cmd44_end-PipeDream_cmd44+1	; Length of command
        defb    $2f	; command code
        defm    "N", $00
        defm    $cb, "R", $9d
        defb    $00	; Command attribute
.PipeDream_cmd44_end
        defb    PipeDream_cmd44_end-PipeDream_cmd44+1

.PipeDream_cmd45
        defb    PipeDream_cmd45_end-PipeDream_cmd45+1	; Length of command
        defb    $36	; command code
        defm    $1b, $00
        defm    $b1
        defb    $00	; Command attribute
.PipeDream_cmd45_end
        defb    PipeDream_cmd45_end-PipeDream_cmd45+1

.PipeDream_cmd46
        defb    PipeDream_cmd46_end-PipeDream_cmd46+1	; Length of command
        defb    $38	; command code
        defm    "V", $00
        defm    $ea
        defb    $01	; Command attribute
.PipeDream_cmd46_end
        defb    PipeDream_cmd46_end-PipeDream_cmd46+1

.PipeDream_cmd47
        defb    PipeDream_cmd47_end-PipeDream_cmd47+1	; Length of command
        defb    $35	; command code
        defm    "S", $00
        defm    $ff
        defb    $00	; Command attribute
.PipeDream_cmd47_end
        defb    PipeDream_cmd47_end-PipeDream_cmd47+1

.PipeDream_cmd48
        defb    PipeDream_cmd48_end-PipeDream_cmd48+1	; Length of command
        defb    $37	; command code
        defm    "J", $00
        defm    $97, $ec
        defb    $00	; Command attribute
.PipeDream_cmd48_end
        defb    PipeDream_cmd48_end-PipeDream_cmd48+1

.PipeDream_cmd49
        defb    PipeDream_cmd49_end-PipeDream_cmd49+1	; Length of command
        defb    $34	; command code
        defm    "X", $00
        defm    "Edi", $84, $e8, "p", $8d, "ssi", $bc
        defb    $00	; Command attribute
.PipeDream_cmd49_end
        defb    PipeDream_cmd49_end-PipeDream_cmd49+1

.PipeDream_cmd50
        defb    PipeDream_cmd50_end-PipeDream_cmd50+1	; Length of command
        defb    $2c	; command code
        defm    "K", $00
        defm    $cb, $c8, "f", $86, $a2, $c9
        defb    $00	; Command attribute
.PipeDream_cmd50_end
        defb    PipeDream_cmd50_end-PipeDream_cmd50+1

.PipeDream_cmd51
        defb    PipeDream_cmd51_end-PipeDream_cmd51+1	; Length of command
        defb    $39	; command code
        defm    "ENT", $00
        defm    "Numb", $86, "<>Text"
        defb    $00	; Command attribute
.PipeDream_cmd51_end
        defb    PipeDream_cmd51_end-PipeDream_cmd51+1

.PipeDream_cmd52
        defb    PipeDream_cmd52_end-PipeDream_cmd52+1	; Length of command
        defb    $33	; command code
        defm    "R", $00
        defm    "F", $8f, "ma", $84, "P", $8c, "ag", $e2, "ph"
        defb    $00	; Command attribute
.PipeDream_cmd52_end
        defb    PipeDream_cmd52_end-PipeDream_cmd52+1

.PipeDream_cmd53
        defb    PipeDream_cmd53_end-PipeDream_cmd53+1	; Length of command
        defb    $31	; command code
        defm    "ESL", $00
        defm    "S", $d9, "i", $84, $a9
        defb    $01	; Command attribute
.PipeDream_cmd53_end
        defb    PipeDream_cmd53_end-PipeDream_cmd53+1

.PipeDream_cmd54
        defb    PipeDream_cmd54_end-PipeDream_cmd54+1	; Length of command
        defb    $2b	; command code
        defm    "EJL", $00
        defm    "Jo", $a3, $a9, "s"
        defb    $00	; Command attribute
.PipeDream_cmd54_end
        defb    PipeDream_cmd54_end-PipeDream_cmd54+1

.PipeDream_cmd55
        defb    PipeDream_cmd55_end-PipeDream_cmd55+1	; Length of command
        defb    $28	; command code
        defm    "EDRC", $00
        defm    $96, "R", $9d, " ", $a3, $b5
        defb    $00	; Command attribute
.PipeDream_cmd55_end
        defb    PipeDream_cmd55_end-PipeDream_cmd55+1

.PipeDream_cmd56
        defb    PipeDream_cmd56_end-PipeDream_cmd56+1	; Length of command
        defb    $2e	; command code
        defm    "EIRC", $00
        defm    $cb, "R", $9d, " ", $a3, $b5
        defb    $00	; Command attribute
.PipeDream_cmd56_end
        defb    PipeDream_cmd56_end-PipeDream_cmd56+1

.PipeDream_cmd57
        defb    PipeDream_cmd57_end-PipeDream_cmd57+1	; Length of command
        defb    $2a	; command code
        defm    "EDC", $00
        defm    $96, $b5
        defb    $00	; Command attribute
.PipeDream_cmd57_end
        defb    PipeDream_cmd57_end-PipeDream_cmd57+1

.PipeDream_cmd58
        defb    PipeDream_cmd58_end-PipeDream_cmd58+1	; Length of command
        defb    $30	; command code
        defm    "EIC", $00
        defm    $cb, $b5
        defb    $00	; Command attribute
.PipeDream_cmd58_end
        defb    PipeDream_cmd58_end-PipeDream_cmd58+1

.PipeDream_cmd59
        defb    PipeDream_cmd59_end-PipeDream_cmd59+1	; Length of command
        defb    $32	; command code
        defm    "EAC", $00
        defm    "Ad", $b2, $b5
        defb    $00	; Command attribute
.PipeDream_cmd59_end
        defb    PipeDream_cmd59_end-PipeDream_cmd59+1

.PipeDream_cmd60
        defb    PipeDream_cmd60_end-PipeDream_cmd60+1	; Length of command
        defb    $2d	; command code
        defm    "EIP", $00
        defm    $cb, "Page"
        defb    $00	; Command attribute
.PipeDream_cmd60_end
        defb    PipeDream_cmd60_end-PipeDream_cmd60+1

        defb    1

.PipeDream_cmd61
        defb    PipeDream_cmd61_end-PipeDream_cmd61+1	; Length of command
        defb    $3a	; command code
        defm    "FL", $00
        defm    $e1
        defb    $00	; Command attribute
.PipeDream_cmd61_end
        defb    PipeDream_cmd61_end-PipeDream_cmd61+1

.PipeDream_cmd62
        defb    PipeDream_cmd62_end-PipeDream_cmd62+1	; Length of command
        defb    $3b	; command code
        defm    "FS", $00
        defm    $bd, "e"
        defb    $00	; Command attribute
.PipeDream_cmd62_end
        defb    PipeDream_cmd62_end-PipeDream_cmd62+1

.PipeDream_cmd63
        defb    PipeDream_cmd63_end-PipeDream_cmd63+1	; Length of command
        defb    $3c	; command code
        defm    "FC", $00
        defm    "N", $ed, "e"
        defb    $00	; Command attribute
.PipeDream_cmd63_end
        defb    PipeDream_cmd63_end-PipeDream_cmd63+1

.PipeDream_cmd64
        defb    PipeDream_cmd64_end-PipeDream_cmd64+1	; Length of command
        defb    $3d	; command code
        defm    "FN", $00
        defm    $97, $ba
        defb    $01	; Command attribute
.PipeDream_cmd64_end
        defb    PipeDream_cmd64_end-PipeDream_cmd64+1

.PipeDream_cmd65
        defb    PipeDream_cmd65_end-PipeDream_cmd65+1	; Length of command
        defb    $3e	; command code
        defm    "FP", $00
        defm    $98, $ba
        defb    $00	; Command attribute
.PipeDream_cmd65_end
        defb    PipeDream_cmd65_end-PipeDream_cmd65+1

.PipeDream_cmd66
        defb    PipeDream_cmd66_end-PipeDream_cmd66+1	; Length of command
        defb    $3f	; command code
        defm    "FT", $00
        defm    "Top ", $ba
        defb    $00	; Command attribute
.PipeDream_cmd66_end
        defb    PipeDream_cmd66_end-PipeDream_cmd66+1

.PipeDream_cmd67
        defb    PipeDream_cmd67_end-PipeDream_cmd67+1	; Length of command
        defb    $40	; command code
        defm    "FB", $00
        defm    "Bot", $9e, $d7, $ba
        defb    $00	; Command attribute
.PipeDream_cmd67_end
        defb    PipeDream_cmd67_end-PipeDream_cmd67+1

        defb    1

.PipeDream_cmd68
        defb    PipeDream_cmd68_end-PipeDream_cmd68+1	; Length of command
        defb    $41	; command code
        defm    "W", $00
        defm    "Wid", $88
        defb    $00	; Command attribute
.PipeDream_cmd68_end
        defb    PipeDream_cmd68_end-PipeDream_cmd68+1

.PipeDream_cmd69
        defb    PipeDream_cmd69_end-PipeDream_cmd69+1	; Length of command
        defb    $42	; command code
        defm    "H", $00
        defm    "Se", $84, $dd, "g", $85
        defb    $00	; Command attribute
.PipeDream_cmd69_end
        defb    PipeDream_cmd69_end-PipeDream_cmd69+1

.PipeDream_cmd70
        defb    PipeDream_cmd70_end-PipeDream_cmd70+1	; Length of command
        defb    $43	; command code
        defm    "LFR", $00
        defm    $a6, "x R", $9d
        defb    $00	; Command attribute
.PipeDream_cmd70_end
        defb    PipeDream_cmd70_end-PipeDream_cmd70+1

.PipeDream_cmd71
        defb    PipeDream_cmd71_end-PipeDream_cmd71+1	; Length of command
        defb    $44	; command code
        defm    "LFC", $00
        defm    $a6, "x ", $b5
        defb    $00	; Command attribute
.PipeDream_cmd71_end
        defb    PipeDream_cmd71_end-PipeDream_cmd71+1

.PipeDream_cmd72
        defb    PipeDream_cmd72_end-PipeDream_cmd72+1	; Length of command
        defb    $46	; command code
        defm    $f1, $00
        defm    $dd, "g", $a3, "R", $cc, "t"
        defb    $00	; Command attribute
.PipeDream_cmd72_end
        defb    PipeDream_cmd72_end-PipeDream_cmd72+1

.PipeDream_cmd73
        defb    PipeDream_cmd73_end-PipeDream_cmd73+1	; Length of command
        defb    $45	; command code
        defm    $f0, $00
        defm    $dd, "g", $a3, "Left"
        defb    $00	; Command attribute
.PipeDream_cmd73_end
        defb    PipeDream_cmd73_end-PipeDream_cmd73+1

.PipeDream_cmd74
        defb    PipeDream_cmd74_end-PipeDream_cmd74+1	; Length of command
        defb    $47	; command code
        defm    "LAR", $00
        defm    "R", $cc, $84, $d1
        defb    $01	; Command attribute
.PipeDream_cmd74_end
        defb    PipeDream_cmd74_end-PipeDream_cmd74+1

.PipeDream_cmd75
        defb    PipeDream_cmd75_end-PipeDream_cmd75+1	; Length of command
        defb    $48	; command code
        defm    "LAL", $00
        defm    "Lef", $84, $d1
        defb    $00	; Command attribute
.PipeDream_cmd75_end
        defb    PipeDream_cmd75_end-PipeDream_cmd75+1

.PipeDream_cmd76
        defb    PipeDream_cmd76_end-PipeDream_cmd76+1	; Length of command
        defb    $49	; command code
        defm    "LAC", $00
        defm    "C", $a2, "tr", $82, $d1
        defb    $00	; Command attribute
.PipeDream_cmd76_end
        defb    PipeDream_cmd76_end-PipeDream_cmd76+1

.PipeDream_cmd77
        defb    PipeDream_cmd77_end-PipeDream_cmd77+1	; Length of command
        defb    $4a	; command code
        defm    "LLCR", $00
        defm    "LCR ", $d1
        defb    $00	; Command attribute
.PipeDream_cmd77_end
        defb    PipeDream_cmd77_end-PipeDream_cmd77+1

.PipeDream_cmd78
        defb    PipeDream_cmd78_end-PipeDream_cmd78+1	; Length of command
        defb    $4b	; command code
        defm    "LAF", $00
        defm    "F", $8d, $82, $d1
        defb    $00	; Command attribute
.PipeDream_cmd78_end
        defb    PipeDream_cmd78_end-PipeDream_cmd78+1

.PipeDream_cmd79
        defb    PipeDream_cmd79_end-PipeDream_cmd79+1	; Length of command
        defb    $4c	; command code
        defm    "LDP", $00
        defm    "Decim", $95, " Pla", $c9, "s"
        defb    $01	; Command attribute
.PipeDream_cmd79_end
        defb    PipeDream_cmd79_end-PipeDream_cmd79+1

.PipeDream_cmd80
        defb    PipeDream_cmd80_end-PipeDream_cmd80+1	; Length of command
        defb    $4d	; command code
        defm    "LSB", $00
        defm    "S", $90, "n B", $e2, "ckets"
        defb    $00	; Command attribute
.PipeDream_cmd80_end
        defb    PipeDream_cmd80_end-PipeDream_cmd80+1

.PipeDream_cmd81
        defb    PipeDream_cmd81_end-PipeDream_cmd81+1	; Length of command
        defb    $4e	; command code
        defm    "LSM", $00
        defm    "S", $90, "n M", $85, "us"
        defb    $00	; Command attribute
.PipeDream_cmd81_end
        defb    PipeDream_cmd81_end-PipeDream_cmd81+1

.PipeDream_cmd82
        defb    PipeDream_cmd82_end-PipeDream_cmd82+1	; Length of command
        defb    $4f	; command code
        defm    "LCL", $00
        defm    "Lead", $c0, $e9, "s"
        defb    $00	; Command attribute
.PipeDream_cmd82_end
        defb    PipeDream_cmd82_end-PipeDream_cmd82+1

.PipeDream_cmd83
        defb    PipeDream_cmd83_end-PipeDream_cmd83+1	; Length of command
        defb    $50	; command code
        defm    "LCT", $00
        defm    "T", $e2, "il", $c0, $e9, "s"
        defb    $00	; Command attribute
.PipeDream_cmd83_end
        defb    PipeDream_cmd83_end-PipeDream_cmd83+1

.PipeDream_cmd84
        defb    PipeDream_cmd84_end-PipeDream_cmd84+1	; Length of command
        defb    $51	; command code
        defm    "LDF", $00
        defm    "Defaul", $84, "F", $8f, "m", $91
        defb    $00	; Command attribute
.PipeDream_cmd84_end
        defb    PipeDream_cmd84_end-PipeDream_cmd84+1

        defb    1

.PipeDream_cmd85
        defb    PipeDream_cmd85_end-PipeDream_cmd85+1	; Length of command
        defb    $52	; command code
        defm    "O", $00
        defm    $ec, $8e, "Page"
        defb    $00	; Command attribute
.PipeDream_cmd85_end
        defb    PipeDream_cmd85_end-PipeDream_cmd85+1

        defb    1

.PipeDream_cmd86
        defb    PipeDream_cmd86_end-PipeDream_cmd86+1	; Length of command
        defb    $53	; command code
        defm    "PO", $00
        defm    $fe
        defb    $00	; Command attribute
.PipeDream_cmd86_end
        defb    PipeDream_cmd86_end-PipeDream_cmd86+1

.PipeDream_cmd87
        defb    PipeDream_cmd87_end-PipeDream_cmd87+1	; Length of command
        defb    $54	; command code
        defm    "PM", $00
        defm    "Microspac", $82, "P", $fc, $b4
        defb    $00	; Command attribute
.PipeDream_cmd87_end
        defb    PipeDream_cmd87_end-PipeDream_cmd87+1

.PipeDream_cmd88
        defb    PipeDream_cmd88_end-PipeDream_cmd88+1	; Length of command
        defb    $55	; command code
        defm    "PU", $00
        defm    "Und", $86, "l", $85, "e"
        defb    $01	; Command attribute
.PipeDream_cmd88_end
        defb    PipeDream_cmd88_end-PipeDream_cmd88+1

.PipeDream_cmd89
        defb    PipeDream_cmd89_end-PipeDream_cmd89+1	; Length of command
        defb    $56	; command code
        defm    "PB", $00
        defm    "Bold"
        defb    $00	; Command attribute
.PipeDream_cmd89_end
        defb    PipeDream_cmd89_end-PipeDream_cmd89+1

.PipeDream_cmd90
        defb    PipeDream_cmd90_end-PipeDream_cmd90+1	; Length of command
        defb    $57	; command code
        defm    "PX", $00
        defm    $e8, "t", $ce, "Sequ", $a2, $c9
        defb    $00	; Command attribute
.PipeDream_cmd90_end
        defb    PipeDream_cmd90_end-PipeDream_cmd90+1

.PipeDream_cmd91
        defb    PipeDream_cmd91_end-PipeDream_cmd91+1	; Length of command
        defb    $58	; command code
        defm    "PI", $00
        defm    "It", $95, "ic"
        defb    $00	; Command attribute
.PipeDream_cmd91_end
        defb    PipeDream_cmd91_end-PipeDream_cmd91+1

.PipeDream_cmd92
        defb    PipeDream_cmd92_end-PipeDream_cmd92+1	; Length of command
        defb    $59	; command code
        defm    "PL", $00
        defm    "Subscript"
        defb    $00	; Command attribute
.PipeDream_cmd92_end
        defb    PipeDream_cmd92_end-PipeDream_cmd92+1

.PipeDream_cmd93
        defb    PipeDream_cmd93_end-PipeDream_cmd93+1	; Length of command
        defb    $5a	; command code
        defm    "PR", $00
        defm    "Sup", $86, "script"
        defb    $00	; Command attribute
.PipeDream_cmd93_end
        defb    PipeDream_cmd93_end-PipeDream_cmd93+1

.PipeDream_cmd94
        defb    PipeDream_cmd94_end-PipeDream_cmd94+1	; Length of command
        defb    $5b	; command code
        defm    "PA", $00
        defm    "Alt", $ce, "F", $bc, "t"
        defb    $00	; Command attribute
.PipeDream_cmd94_end
        defb    PipeDream_cmd94_end-PipeDream_cmd94+1

.PipeDream_cmd95
        defb    PipeDream_cmd95_end-PipeDream_cmd95+1	; Length of command
        defb    $5c	; command code
        defm    "PE", $00
        defm    "Us", $ef, "Def", $85, "ed"
        defb    $00	; Command attribute
.PipeDream_cmd95_end
        defb    PipeDream_cmd95_end-PipeDream_cmd95+1

.PipeDream_cmd96
        defb    PipeDream_cmd96_end-PipeDream_cmd96+1	; Length of command
        defb    $5d	; command code
        defm    "PHI", $00
        defm    $cb, "H", $cc, "l", $cc, "ts"
        defb    $01	; Command attribute
.PipeDream_cmd96_end
        defb    PipeDream_cmd96_end-PipeDream_cmd96+1

.PipeDream_cmd97
        defb    PipeDream_cmd97_end-PipeDream_cmd97+1	; Length of command
        defb    $5e	; command code
        defm    "PHR", $00
        defm    $c8, "mov", $82, "H", $cc, "l", $cc, "ts"
        defb    $00	; Command attribute
.PipeDream_cmd97_end
        defb    PipeDream_cmd97_end-PipeDream_cmd97+1

.PipeDream_cmd98
        defb    PipeDream_cmd98_end-PipeDream_cmd98+1	; Length of command
        defb    $5f	; command code
        defm    "PHB", $00
        defm    "H", $cc, "l", $cc, $84, $c5
        defb    $00	; Command attribute
.PipeDream_cmd98_end
        defb    PipeDream_cmd98_end-PipeDream_cmd98+1

        defb    0


; ********************************************************************************************************************
; MTH for Diary application...
;
.DiaryTopics
        defb    0	; Start topic marker

.Diary_tpc1
        defb    Diary_tpc1_end-Diary_tpc1+1	; Length of topic
        defm    $c5, "s"
        defb    $00	; Topic attribute
.Diary_tpc1_end
        defb    Diary_tpc1_end-Diary_tpc1+1

.Diary_tpc2
        defb    Diary_tpc2_end-Diary_tpc2+1	; Length of topic
        defm    $dc
        defb    $00	; Topic attribute
.Diary_tpc2_end
        defb    Diary_tpc2_end-Diary_tpc2+1

.Diary_tpc3
        defb    Diary_tpc3_end-Diary_tpc3+1	; Length of topic
        defm    "Ed", $fc
        defb    $01	; Topic attribute
.Diary_tpc3_end
        defb    Diary_tpc3_end-Diary_tpc3+1

.Diary_tpc4
        defb    Diary_tpc4_end-Diary_tpc4+1	; Length of topic
        defm    $fd
        defb    $00	; Topic attribute
.Diary_tpc4_end
        defb    Diary_tpc4_end-Diary_tpc4+1

        defb    0	; End topic marker

.DiaryCommands
        defb    0	; Start command marker

; Mark Block
.Diary_cmd1
        defb    Diary_cmd1_end-Diary_cmd1+1	; Length of command
        defb    $20	; command code
        defm    "Z", $00
        defm    $dd, "k ", $c5
        defb    $00	; Command attribute
.Diary_cmd1_end
        defb    Diary_cmd1_end-Diary_cmd1+1

; Clear Mark
.Diary_cmd2
        defb    Diary_cmd2_end-Diary_cmd2+1	; Length of command
        defb    $21	; command code
        defm    "Q", $00
        defm    "C", $8b, $8c, " ", $dd, "k"
        defb    $00	; Command attribute
.Diary_cmd2_end
        defb    Diary_cmd2_end-Diary_cmd2+1

; Copy
.Diary_cmd3
        defb    Diary_cmd3_end-Diary_cmd3+1	; Length of command
        defb    $22	; command code
        defm    "BC", $00
        defm    $de
        defb    $00	; Command attribute
.Diary_cmd3_end
        defb    Diary_cmd3_end-Diary_cmd3+1

; Move
.Diary_cmd4
        defb    Diary_cmd4_end-Diary_cmd4+1	; Length of command
        defb    $23	; command code
        defm    "BM", $00
        defm    "Move"
        defb    $00	; Command attribute
.Diary_cmd4_end
        defb    Diary_cmd4_end-Diary_cmd4+1

; Delete
.Diary_cmd5
        defb    Diary_cmd5_end-Diary_cmd5+1	; Length of command
        defb    $24	; command code
        defm    "BD", $00
        defm    "D", $c7, $af
        defb    $00	; Command attribute
.Diary_cmd5_end
        defb    Diary_cmd5_end-Diary_cmd5+1

; List/Print
.Diary_cmd6
        defb    Diary_cmd6_end-Diary_cmd6+1	; Length of command
        defb    $25	; command code
        defm    "BL", $00
        defm    "List/", $fe
        defb    $00	; Command attribute
.Diary_cmd6_end
        defb    Diary_cmd6_end-Diary_cmd6+1

; Search
.Diary_cmd7
        defb    Diary_cmd7_end-Diary_cmd7+1	; Length of command
        defb    $26	; command code
        defm    "BSE", $00
        defm    "Se", $8c, $b4
        defb    $01	; Command attribute
.Diary_cmd7_end
        defb    Diary_cmd7_end-Diary_cmd7+1

; Replace
.Diary_cmd8
        defb    Diary_cmd8_end-Diary_cmd8+1	; Length of command
        defb    $29	; command code
        defm    "BRP", $00
        defm    $c8, $d9, "a", $c9
        defb    $00	; Command attribute
.Diary_cmd8_end
        defb    Diary_cmd8_end-Diary_cmd8+1

; Next Match
.Diary_cmd9
        defb    Diary_cmd9_end-Diary_cmd9+1	; Length of command
        defb    $27	; command code
        defm    "BNM", $00
        defm    $97, $f7
        defb    $00	; Command attribute
.Diary_cmd9_end
        defb    Diary_cmd9_end-Diary_cmd9+1

; Previous Match
.Diary_cmd10
        defb    Diary_cmd10_end-Diary_cmd10+1	; Length of command
        defb    $28	; command code
        defm    "BPM", $00
        defm    $98, $f7
        defb    $00	; Command attribute
.Diary_cmd10_end
        defb    Diary_cmd10_end-Diary_cmd10+1

        defb    1	; Command topic separator

; End of Line
.Diary_cmd11
        defb    Diary_cmd11_end-Diary_cmd11+1	; Length of command
        defb    $f5	; command code
        defm    $f5, $00
        defm    $df, $a9
        defb    $00	; Command attribute
.Diary_cmd11_end
        defb    Diary_cmd11_end-Diary_cmd11+1

; Start of Line
.Diary_cmd12
        defb    Diary_cmd12_end-Diary_cmd12+1	; Length of command
        defb    $f4	; command code
        defm    $f4, $00
        defm    "St", $8c, $84, $89, $a9
        defb    $00	; Command attribute
.Diary_cmd12_end
        defb    Diary_cmd12_end-Diary_cmd12+1

; First Line
.Diary_cmd13
        defb    Diary_cmd13_end-Diary_cmd13+1	; Length of command
        defb    $30	; command code
        defm    $f7, $00
        defm    $f8, $a9
        defb    $00	; Command attribute
.Diary_cmd13_end
        defb    Diary_cmd13_end-Diary_cmd13+1

; Last Line
.Diary_cmd14
        defb    Diary_cmd14_end-Diary_cmd14+1	; Length of command
        defb    $2f	; command code
        defm    $f6, $00
        defm    "La", $ca, $a9
        defb    $00	; Command attribute
.Diary_cmd14_end
        defb    Diary_cmd14_end-Diary_cmd14+1

; Save position
.Diary_cmd15
        defb    Diary_cmd15_end-Diary_cmd15+1	; Length of command
        defb    $2b	; command code
        defm    "CSP", $00
        defm    $bd, $be
        defb    $00	; Command attribute
.Diary_cmd15_end
        defb    Diary_cmd15_end-Diary_cmd15+1

; Restore position
.Diary_cmd16
        defb    Diary_cmd16_end-Diary_cmd16+1	; Length of command
        defb    $2c	; command code
        defm    "CRP", $00
        defm    $c8, "st", $8f, $be
        defb    $00	; Command attribute
.Diary_cmd16_end
        defb    Diary_cmd16_end-Diary_cmd16+1

; ENTER
.Diary_cmd17
        defb    Diary_cmd17_end-Diary_cmd17+1	; Length of command
        defb    $0d	; command code
        defm    $e1, $00
        defm    $d2
        defb    $00	; Command attribute
.Diary_cmd17_end
        defb    Diary_cmd17_end-Diary_cmd17+1

; Next Word
.Diary_cmd18
        defb    Diary_cmd18_end-Diary_cmd18+1	; Length of command
        defb    $f9	; command code
        defm    $f9, $00
        defm    $97, $d3
        defb    $01	; Command attribute
.Diary_cmd18_end
        defb    Diary_cmd18_end-Diary_cmd18+1

; Previous Word
.Diary_cmd19
        defb    Diary_cmd19_end-Diary_cmd19+1	; Length of command
        defb    $f8	; command code
        defm    $f8, $00
        defm    $98, $d3
        defb    $00	; Command attribute
.Diary_cmd19_end
        defb    Diary_cmd19_end-Diary_cmd19+1

; Screen Up
.Diary_cmd20
        defb    Diary_cmd20_end-Diary_cmd20+1	; Length of command
        defb    $32	; command code
        defm    $fb, $00
        defm    $d4, $b9
        defb    $00	; Command attribute
.Diary_cmd20_end
        defb    Diary_cmd20_end-Diary_cmd20+1

; Screen Down
.Diary_cmd21
        defb    Diary_cmd21_end-Diary_cmd21+1	; Length of command
        defb    $31	; command code
        defm    $fa, $00
        defm    $d4, $ac
        defb    $00	; Command attribute
.Diary_cmd21_end
        defb    Diary_cmd21_end-Diary_cmd21+1

; Cursor Right
.Diary_cmd22
        defb    Diary_cmd22_end-Diary_cmd22+1	; Length of command
        defb    $fd	; command code
        defm    $fd, $00
        defm    $a7
        defb    $00	; Command attribute
.Diary_cmd22_end
        defb    Diary_cmd22_end-Diary_cmd22+1

; Cursor Left
.Diary_cmd23
        defb    Diary_cmd23_end-Diary_cmd23+1	; Length of command
        defb    $fc	; command code
        defm    $fc, $00
        defm    $a8
        defb    $00	; Command attribute
.Diary_cmd23_end
        defb    Diary_cmd23_end-Diary_cmd23+1

; Cursor Up
.Diary_cmd24
        defb    Diary_cmd24_end-Diary_cmd24+1	; Length of command
        defb    $2e	; command code
        defm    $ff, $00
        defm    $da
        defb    $00	; Command attribute
.Diary_cmd24_end
        defb    Diary_cmd24_end-Diary_cmd24+1

; Cursor Down
.Diary_cmd25
        defb    Diary_cmd25_end-Diary_cmd25+1	; Length of command
        defb    $2d	; command code
        defm    $fe, $00
        defm    $db
        defb    $00	; Command attribute
.Diary_cmd25_end
        defb    Diary_cmd25_end-Diary_cmd25+1

; Tab
.Diary_cmd26
        defb    Diary_cmd26_end-Diary_cmd26+1	; Length of command
        defb    $2a	; command code
        defm    $e2, $00
        defm    "TAB"
        defb    $01	; Command attribute
.Diary_cmd26_end
        defb    Diary_cmd26_end-Diary_cmd26+1

; Today
.Diary_cmd27
        defb    Diary_cmd27_end-Diary_cmd27+1	; Length of command
        defb    $33	; command code
        defm    "CT", $00
        defm    "Tod", $fb
        defb    $00	; Command attribute
.Diary_cmd27_end
        defb    Diary_cmd27_end-Diary_cmd27+1

; First Active Day
.Diary_cmd28
        defb    Diary_cmd28_end-Diary_cmd28+1	; Length of command
        defb    $39	; command code
        defm    "CFAD", $00
        defm    $f8, $ad
        defb    $00	; Command attribute
.Diary_cmd28_end
        defb    Diary_cmd28_end-Diary_cmd28+1

; Last Active Day
.Diary_cmd29
        defb    Diary_cmd29_end-Diary_cmd29+1	; Length of command
        defb    $38	; command code
        defm    "CLAD", $00
        defm    "La", $ca, $ad
        defb    $00	; Command attribute
.Diary_cmd29_end
        defb    Diary_cmd29_end-Diary_cmd29+1

; Next Active Day
.Diary_cmd30
        defb    Diary_cmd30_end-Diary_cmd30+1	; Length of command
        defb    $36	; command code
        defm    $f1, $00
        defm    $97, $ad
        defb    $00	; Command attribute
.Diary_cmd30_end
        defb    Diary_cmd30_end-Diary_cmd30+1

; Previous Active Day
.Diary_cmd31
        defb    Diary_cmd31_end-Diary_cmd31+1	; Length of command
        defb    $37	; command code
        defm    $f0, $00
        defm    $98, $ad
        defb    $00	; Command attribute
.Diary_cmd31_end
        defb    Diary_cmd31_end-Diary_cmd31+1

; Previous Day
.Diary_cmd32
        defb    Diary_cmd32_end-Diary_cmd32+1	; Length of command
        defb    $35	; command code
        defm    $f3, $00
        defm    $98, "D", $fb
        defb    $00	; Command attribute
.Diary_cmd32_end
        defb    Diary_cmd32_end-Diary_cmd32+1

; Next Day
.Diary_cmd33
        defb    Diary_cmd33_end-Diary_cmd33+1	; Length of command
        defb    $34	; command code
        defm    $f2, $00
        defm    $97, "D", $fb
        defb    $00	; Command attribute
.Diary_cmd33_end
        defb    Diary_cmd33_end-Diary_cmd33+1

        defb    1	; Command topic separator

; Rubout
.Diary_cmd34
        defb    Diary_cmd34_end-Diary_cmd34+1	; Length of command
        defb    $7f	; command code
        defm    $e3, $00
        defm    $e0
        defb    $00	; Command attribute
.Diary_cmd34_end
        defb    Diary_cmd34_end-Diary_cmd34+1

; Delete Character
.Diary_cmd35
        defb    Diary_cmd35_end-Diary_cmd35+1	; Length of command
        defb    $07	; command code
        defm    "G", $00
        defm    $96, $e9
        defb    $00	; Command attribute
.Diary_cmd35_end
        defb    Diary_cmd35_end-Diary_cmd35+1

; Insert Character
.Diary_cmd36
        defb    Diary_cmd36_end-Diary_cmd36+1	; Length of command
        defb    $07	; command code
        defm    $d3, $00
        defm    $04
        defb    $04	; Command attribute
.Diary_cmd36_end
        defb    Diary_cmd36_end-Diary_cmd36+1

.Diary_cmd37
        defb    Diary_cmd37_end-Diary_cmd37+1	; Length of command
        defb    $15	; command code
        defm    "U", $00
        defm    $cb, $e9
        defb    $00	; Command attribute
.Diary_cmd37_end
        defb    Diary_cmd37_end-Diary_cmd37+1

; Delete Word
.Diary_cmd38
        defb    Diary_cmd38_end-Diary_cmd38+1	; Length of command
        defb    $14	; command code
        defm    "T", $00
        defm    $96, $d3
        defb    $00	; Command attribute
.Diary_cmd38_end
        defb    Diary_cmd38_end-Diary_cmd38+1

; Delete to End of Line
.Diary_cmd39
        defb    Diary_cmd39_end-Diary_cmd39+1	; Length of command
        defb    $04	; command code
        defm    "D", $00
        defm    $96, $bb, $df, $a9
        defb    $00	; Command attribute
.Diary_cmd39_end
        defb    Diary_cmd39_end-Diary_cmd39+1

; Delete Line
.Diary_cmd40
        defb    Diary_cmd40_end-Diary_cmd40+1	; Length of command
        defb    $3a	; command code
        defm    "Y", $00
        defm    $96, $a9
        defb    $00	; Command attribute
.Diary_cmd40_end
        defb    Diary_cmd40_end-Diary_cmd40+1

.Diary_cmd41
        defb    Diary_cmd41_end-Diary_cmd41+1	; Length of command
        defb    $3a	; command code
        defm    $c3, $00
        defm    $04
        defb    $04	; Command attribute
.Diary_cmd41_end
        defb    Diary_cmd41_end-Diary_cmd41+1

.Diary_cmd42
        defb    Diary_cmd42_end-Diary_cmd42+1	; Length of command
        defb    $3c	; command code
        defm    "N", $00
        defm    $cb, $a9
        defb    $00	; Command attribute
.Diary_cmd42_end
        defb    Diary_cmd42_end-Diary_cmd42+1

; Insert/Overtype
.Diary_cmd43
        defb    Diary_cmd43_end-Diary_cmd43+1	; Length of command
        defb    $16	; command code
        defm    "V", $00
        defm    $ea
        defb    $01	; Command attribute
.Diary_cmd43_end
        defb    Diary_cmd43_end-Diary_cmd43+1

; Swap Case
.Diary_cmd44
        defb    Diary_cmd44_end-Diary_cmd44+1	; Length of command
        defb    $13	; command code
        defm    "S", $00
        defm    $ff
        defb    $00	; Command attribute
.Diary_cmd44_end
        defb    Diary_cmd44_end-Diary_cmd44+1

; Next Option
.Diary_cmd45
        defb    Diary_cmd45_end-Diary_cmd45+1	; Length of command
        defb    $3f	; command code
        defm    "J", $00
        defm    $97, $ec
        defb    $00	; Command attribute
.Diary_cmd45_end
        defb    Diary_cmd45_end-Diary_cmd45+1

; Memory Free
.Diary_cmd46
        defb    Diary_cmd46_end-Diary_cmd46+1	; Length of command
        defb    $3e	; command code
        defm    "EMF", $00
        defm    "Mem", $8f, $d6, "F", $8d, "e"
        defb    $00	; Command attribute
.Diary_cmd46_end
        defb    Diary_cmd46_end-Diary_cmd46+1

; Split Line
.Diary_cmd47
        defb    Diary_cmd47_end-Diary_cmd47+1	; Length of command
        defb    $3d	; command code
        defm    "ESL", $00
        defm    "S", $d9, "i", $84, $a9
        defb    $01	; Command attribute
.Diary_cmd47_end
        defb    Diary_cmd47_end-Diary_cmd47+1

; Join Lines
.Diary_cmd48
        defb    Diary_cmd48_end-Diary_cmd48+1	; Length of command
        defb    $3b	; command code
        defm    "EJL", $00
        defm    "Jo", $a3, $a9, "s"
        defb    $00	; Command attribute
.Diary_cmd48_end
        defb    Diary_cmd48_end-Diary_cmd48+1

        defb    1	; Command topic separator

; Load
.Diary_cmd49
        defb    Diary_cmd49_end-Diary_cmd49+1	; Length of command
        defb    $40	; command code
        defm    "FL", $00
        defm    $e1
        defb    $00	; Command attribute
.Diary_cmd49_end
        defb    Diary_cmd49_end-Diary_cmd49+1

; Save
.Diary_cmd50
        defb    Diary_cmd50_end-Diary_cmd50+1	; Length of command
        defb    $41	; command code
        defm    "FS", $00
        defm    $bd, "e"
        defb    $00	; Command attribute
.Diary_cmd50_end
        defb    Diary_cmd50_end-Diary_cmd50+1

        defb    0	; End command marker



; ********************************************************************************************************************
; MTH for PrinterEd application...
;
.PrinterEdTopics
        defb    0
        defb    4,$DC,0,4
        defb    4,$FD,0,4
        defb    0
.PrinterEdCommands
        defm    0
        defm    8,$26,$4A,0,$97,$EC,0,8                                 ; Next Option
        defm    7,$0D,$E1,0,$D2,0,7                                     ; ENTER
        defm    7,$1B,$1B,0,$B1,0,7                                     ; ESCAPE
        defm    7,$FD,$FD,0,$A7,1,7                                     ; Cursor LRUD
        defm    7,$FC,$FC,0,$A8,0,7
        defm    7,$24,$FF,0,$DA,0,7
        defm    7,$25,$FE,0,$DB,0,7
        defm    14,$27,$FB,0,"Page 1/2",1,14                            ; Page 1/2
        defm    14,$28,$FA,0,"Page 2/2",0,14                            ; Page 2/2
        defm    24,$2E,$49,$53,$4F,0,"ISO Translations",0,24            ; ISO Translations
        defm    1
        defm    8,$29,$46,$4C,0,$E1,0,8
        defm    9,$2A,$46,$53,0,$BD,$65,0,9
        defm    10,$2B,$46,$43,0,$4E,$ED,$65,0,10
        defm    12,$2C,$46,"NEW",0,"New",0,12
        defm    16,$2D,$46,$55,0,$B9,$64,$91,$82,$44,$72,$69,$76,$86,0,16
        defb    0

; ********************************************************************************************************************
; MTH for Panel popdown...
;
.PanelTopics
        defb    0
        defb    4,$DC,0,4
        defb    4,$FD,0,4
        defb    0
.PanelCommands
        defb    0
        defb    8,$26,$4A,0,$97,$EC,0,8                                 ; <>J Next Option
        defb    7,$0D,$E1,0,$D2,0,7                                     ; ENTER
        defb    7,$1B,$1B,0,$B1,0,7                                     ; ESC
        defb    7,$FD,$FD,0,$A7,1,7                                     ; Cursor LRUD
        defb    7,$FC,$FC,0,$A8,0,7
        defb    7,$24,$FF,0,$DA,0,7
        defb    7,$25,$FE,0,$DB,0,7
        defb    1
        defb    8,$29,$46,$4C,0,$E1,0,8                                 ; <>FL
        defb    9,$2A,$46,$53,0,$BD,$65,0,9                             ; <>FS
        defb    12,$2C,$46,$4E,$45,$57,0,$4E,$65,$77,0,12               ; <>FNEW
        defb    0

; ********************************************************************************************************************
; MTH for Filer popdown...
;
.FilerTopics
        defb    0
        defb    4,$D8,0,4
        defb    0
.FilerCommands
        defb    0
        defb    15,$21,$43,$46,0,$43,$91,$95,$6F,$67,$75,$82,$FD,0,15   ; Catalogue Files
        defb    8,$25,$43,$4F,0,$DE,0,8                                 ; Copy
        defb    11,$26,$52,$45,0,$52,$A2,$ED,$65,0,11                   ; Rename
        defb    10,$27,$45,$52,0,$45,$E2,$EB,0,10                       ; Erase
        defb    12,$2A,$45,$58,0,$E8,$65,$63,$75,$AF,0,12               ; Execute
        defb    9,$0D,$E1,0,$E3,$F8,$BA,0,9                             ; Select First File
        defb    12,$20,$D1,0,$E3,$E8,$74,$E2,$20,$BA,0,12               ; Select Extra File
        defb    6,$20,$E2,0,4,6                                         ; ???
        defb    12,$2B,$43,$44,0,$43,$8D,$91,$82,$B6,1,12               ; Create Directory
        defb    9,$28,$53,$49,0,$E3,$B6,0,9                             ; Select Directory
        defb    9,$2E,$FB,0,$B9,$20,$B6,0,9                             ; Up Directory
        defb    9,$2F,$FA,0,$AC,$20,$B6,0,9                             ; Down Directory
        defb    7,$FD,$FD,0,$A7,0,7                                     ; Cursor Right
        defb    7,$FC,$FC,0,$A8,0,7                                     ; Cursor Left
        defb    7,$FF,$FF,0,$DA,0,7                                     ; Cursor Up
        defb    7,$FE,$FE,0,$DB,0,7                                     ; Cursor Down
        defb    15,$22,$43,$45,0,$43,$91,$95,$6F,$67,$75,$82,$EE,1,15   ; Catalogue EPROM
        defb    11,$23,$45,$53,0,$BD,$82,$BB,$EE,0,11                   ; Save to EPROM
        defb    17,$24,$45,$46,0,$46,$65,$74,$B4,$20,$66,$72,$6F,$D7,$EE,0,17   ; Fetch from EPROM
        defb    13,$29,$53,$56,0,$E3,$44,$65,$76,$69,$C9,0,13           ; Select Device
        defb    11,$2C,$54,$43,0,$54,$8D,$82,$DE,0,11                   ; Tree Copy
        defb    11,$2D,$4E,$4D,0,$4E,$ED,$82,$F7,0,11                   ; Name Match
        defb    0

; ********************************************************************************************************************
; MTH for Terminal popdown...
;
.TerminalTopics
        defb    0
        defb    4,$D8,0,4
        defb    0
.TerminalCommands
        defb    0
        defb    7,2,$E3,0,$E0,0,7                               ; Rubout
        defb    14,3,$D3,0,$42,$61,$63,$6B,$73,$70,$61,$C9,0,14 ; Backspace
        defb    8,1,$D1,0,$E8,$FC,0,8                           ; Exit
        defb    7,6,$FD,0,$A7,1,7                               ; Cursor Right
        defb    7,7,$FC,0,$A8,0,7                               ; Cursor Left
        defb    7,4,$FF,0,$DA,0,7                               ; Cursor Up
        defb    7,5,$FE,0,$DB,0,7                               ; Cursor Down
        defb    9,8,$F8,0,$9C,$20,$30,1,9                       ; Function 0
        defb    9,9,$F9,0,$9C,$20,$31,0,9                       ; Function 1
        defb    9,$0A,$FA,0,$9C,$20,$32,0,9                     ; Function 2
        defb    9,$0B,$FB,0,$9C,$20,$33,0,9                     ; Function 3
        defb    0


; ********************************************************************************************************************
; MTH for FlashStore popdown...
;
.FlashStoreTopics   DEFB 0                                                      ; start marker of topics

; 'COMMANDS' topic
.topic_cmds         DEFB topic_cmds_end - topic_cmds                            ; length of topic definition
                    DEFM $D8, 0                                                 ; "Commands", name terminated by high byte
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000000
                    DEFB topic_cmds_end - topic_cmds
.topic_cmds_end
                    DEFB 0


; *****************************************************************************************************************************
;
.FlashStoreCommands DEFB 0                                                      ; start of commands

; <>SC Select Card
.cmd_sc             DEFB cmd_sc_end - cmd_sc                                    ; length of command definition
                    DEFB FlashStore_CC_sc                                       ; command code
                    DEFM "SC", 0                                                ; keyboard sequence
                    DEFM $E3, "Card", 0                                         ; "Select Card"
                    DEFB (cmd_sc_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_sc_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_sc_end - cmd_sc                                    ; length of command definition
.cmd_sc_end

; <>CF Catalogue Files
.cmd_cf             DEFB cmd_cf_end - cmd_cf                                    ; length of command definition
                    DEFB FlashStore_CC_cf                                       ; command code
                    DEFM "CF", 0                                                ; keyboard sequence
                    DEFM "Catalogue Card ", $FD, 0                              ; "Catalogue Card Files"
                    DEFB (cmd_cf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_cf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_cf_end - cmd_cf                                    ; length of command definition
.cmd_cf_end

; <>CE Catalogue Files (hidden)
.cmd_ce             DEFB cmd_ce_end - cmd_ce                                    ; length of command definition
                    DEFB FlashStore_CC_cf                                       ; command code
                    DEFM "CE", 0                                                ; keyboard sequence
                    DEFM 0
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000100                                              ; command is hidden (no help)
                    DEFB cmd_ce_end - cmd_ce                                    ; length of command definition
.cmd_ce_end

; <>SV Select RAM Device
.cmd_sv             DEFB cmd_sv_end - cmd_sv                                    ; length of command definition
                    DEFB FlashStore_CC_sv                                       ; command code
                    DEFM "SV", 0                                                ; keyboard sequence
                    DEFM $E3, "RAM Device", 0                                   ; "Select RAM Device"
                    DEFB (cmd_sv_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_sv_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_sv_end - cmd_sv                                    ; length of command definition
.cmd_sv_end

; <>FE File Erase
.cmd_fe             DEFB cmd_fe_end - cmd_fe                                    ; length of command definition
                    DEFB FlashStore_CC_fe                                       ; command code
                    DEFM "FE", 0                                                ; keyboard sequence
                    DEFM "Erase ", $BA, " from Card", 0                         ; "Erase File from Card", 0
                    DEFB (cmd_fe_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fe_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page
                    DEFB cmd_fe_end - cmd_fe                                    ; length of command definition
.cmd_fe_end

; <>ER File Erase (Hidden)
.cmd_er             DEFB cmd_er_end - cmd_er                                    ; length of command definition
                    DEFB FlashStore_CC_fe                                       ; command code
                    DEFM "ER", 0                                                ; keyboard sequence
                    DEFM 0
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000100                                              ; hidden command
                    DEFB cmd_er_end - cmd_er                                    ; length of command definition
.cmd_er_end

; <>FS File Save
.cmd_fs             DEFB cmd_fs_end - cmd_fs                                    ; length of command definition
                    DEFB FlashStore_CC_fs                                       ; command code
                    DEFM "FS", 0                                                ; keyboard sequence
                    DEFM $BD, $82, $FD, " to Card", 0                           ; "Save Files to Card"
                    DEFB (cmd_fs_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fs_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_fs_end - cmd_fs                                    ; length of command definition
.cmd_fs_end

; <>FL File Load
.cmd_fl             DEFB cmd_fl_end - cmd_fl                                    ; length of command definition
                    DEFB FlashStore_CC_fl                                       ; command code
                    DEFM "FL", 0                                                ; keyboard sequence
                    DEFM "Fetch ", $BA, " from Card", 0                         ; "Fetch file from Card"
                    DEFB (cmd_fl_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fl_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_fl_end - cmd_fl                                    ; length of command definition
.cmd_fl_end

; <>EF File Load (Hidden)
.cmd_ef             DEFB cmd_ef_end - cmd_ef                                    ; length of command definition
                    DEFB FlashStore_CC_fl                                       ; command code
                    DEFM "EF", 0                                                ; keyboard sequence
                    DEFM 0
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000100                                              ; hidden command
                    DEFB cmd_ef_end - cmd_ef                                    ; length of command definition
.cmd_ef_end

; <>BF Backup RAM Files
.cmd_bf             DEFB cmd_bf_end - cmd_bf                                    ; length of command definition
                    DEFB FlashStore_CC_bf                                       ; command code
                    DEFM "BF", 0                                                ; keyboard sequence
                    DEFM "Backup ", $FD, " from RAM", 0                         ; "Backup files from RAM"
                    DEFB (cmd_bf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_bf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_bf_end - cmd_bf                                    ; length of command definition
.cmd_bf_end

; <>RF Restore RAM Files
.cmd_rf             DEFB cmd_rf_end - cmd_rf                                    ; length of command definition
                    DEFB FlashStore_CC_rf                                       ; command code
                    DEFM "RF", 0                                                ; keyboard sequence
                    DEFM "Restore ", $FD, " to RAM", 0                          ; "Restore files to RAM"
                    DEFB (cmd_rf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_rf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_rf_end - cmd_rf                                    ; length of command definition
.cmd_rf_end


; <>FC Copy all files to Card
.cmd_fc             DEFB cmd_fc_end - cmd_fc                                    ; length of command definition
                    DEFB FlashStore_CC_fc                                       ; command code
                    DEFM "FC", 0                                                ; keyboard sequence
                    DEFM $DE, " all ", $FD, " to Card", 0                       ; "Copy all files to Card"
                    DEFB (cmd_fc_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fc_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_fc_end - cmd_fc                                    ; length of command definition
.cmd_fc_end

; <>FFA Format File Area
.cmd_ffa            DEFB cmd_ffa_end - cmd_ffa                                  ; length of command definition
                    DEFB FlashStore_CC_ffa                                      ; command code
                    DEFM "FFA", 0                                               ; keyboard sequence
                    DEFM "Format ", $BA, " Area", 0                             ; "Format File Area"
                    DEFB (cmd_ffa_help - FlashStoreHelp) / 256                  ; high byte of rel. pointer
                    DEFB (cmd_ffa_help - FlashStoreHelp) % 256                  ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_ffa_end - cmd_ffa                                  ; length of command definition
.cmd_ffa_end

; <>TFV Change File View
.cmd_tfv            DEFB cmd_tfv_end - cmd_tfv                                  ; length of command definition
                    DEFB FlashStore_CC_tfv                                      ; command code
                    DEFM "TFV", 0                                               ; keyboard sequence
                    DEFM "Toggle ", $BA, " View", 0                             ; "Toggle File View"
                    DEFB (cmd_tfv_help - FlashStoreHelp) / 256                  ; high byte of rel. pointer
                    DEFB (cmd_tfv_help - FlashStoreHelp) % 256                  ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page, new column, safe
                    DEFB cmd_tfv_end - cmd_tfv                                  ; length of command definition
.cmd_tfv_end

; ENTER Fetch file at cursor
.cmd_fetch          DEFB cmd_fetch_end - cmd_fetch                              ; length of command definition
                    DEFB 13                                                     ; command code
                    DEFM MU_ENT, 0                                              ; keyboard sequence
                    DEFM "Fetch ", $BA, " at ", $DC, 0                          ; "Fetch File at Cursor"
                    DEFB 0                                                      ; no help
                    DEFB 0                                                      ;
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_fetch_end - cmd_fetch                              ; length of command definition
.cmd_fetch_end

; DEL Delete file at cursor
.cmd_delete         DEFB cmd_delete_end - cmd_delete                            ; length of command definition
                    DEFB IN_DEL                                                 ; command code
                    DEFM MU_DEL, 0                                              ; keyboard sequence
                    DEFM $96, $BA, " at ", $DC, 0                               ; "Delete File at Cursor"
                    DEFB 0                                                      ; no help
                    DEFB 0                                                      ;
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_delete_end - cmd_delete                            ; length of command definition
.cmd_delete_end

                    DEFB 0                                                      ; end of commands


; *******************************************************************************************************************
.IndexHelp
        defm    $7F, "All insertion and removal of cards must be done from", $7F
        defm    $92, "INDEX. Do not remove any RAM card, or a ROM card", $7F
        defm    "which is in use. A continuous tone asks for a ROM", $7F
        defm    "card to be reinserted into its original ", $FA, ".", $7F
        defm    "A ", 1,"TFAIL", 1, "T message requires ", $92, "machine to be reset.", 0

; *******************************************************************************************************************
.PipeDreamHelp
        defm    $7F
        defm    "PipeDream is a combined ", $D3, "-processor, Spreadsheet", $7F
        defm    "and Database application. Use ", $92, "HELP key and browse the", $7F
        defm    "INFO topics to view PipeDreams mathematical functions.", 0

; *******************************************************************************************************************
.DiaryHelp
        defm    $7F
        defm    "This is a 'Page a Day' diary. Multiple diary", $7F
        defm    "applications may be used for example for work and home.", $7F
        defm    "The Calendar popdown when selected from ", $92, "Diary", $7F
        defm    "can be used to view active days and navigate around.", 0

; *******************************************************************************************************************
.BasicHelp
        defm    $7F
        defm    "Develop your own BBC BASIC programs, store them in ", $92, "RAM", $7F
        defm    "filing system as files and RUN them inside one or several", $7F
        defm    "BBC BASIC applications. A built-in Z80 assembler enables", $7F
        defm    "you to compile and embed machine code inside your programs", $7F
        defm    "that may access advanced features of ", $92, "operating system.",0

; *******************************************************************************************************************
.CalculatorHelp
        defm    $7F
        defm    "A simple pocket calculator with some useful", $7F
        defm    "Imperial to Metric conversion functions.", 0

; *******************************************************************************************************************
.CalendarHelp
        defm    $7F
        defm    "This 'Julian proleptic' calendar starts from 4712 BC and is", $7F
        defm    "year 2000 compliant. To manually jump to a date, press the", $7F
        defm    $D2," key and edit ", $92, "'Look for' date. Use ", $92, $DC, " keys", $7F
        defm    "together with ", $92, "shift and diamond keys to navigate through", $7F
        defm    "days months and years. A mark on a day indicates an entry is", $7F
        defm    "made on that date in ", $92, "Diary.", 0

; *******************************************************************************************************************
.AlarmHelp
        defm    $7F
        defm    "Set either single or repeating alarm events", $7F
        defm    "to sound ", $92, "bell or execute commands to launch", $7F
        defm    "system applications or resources.", 0

; *******************************************************************************************************************
.FilerHelp
        defm    $7F
        defm    "The Filer is used to manage stored files generated from", $7F
        defm    "Applications in RAM, EPROM or FLASH cards.", $7F
        defm    "When ", $92, "Filer is selected from inside an application", $7F
        defm    $BA, " Load command, a file can be marked with ", $92, $D2, " key", $7F
        defm    "followed by ", $92, $B1, " key to save typing in ", $92, "file name", $7F
        defm    "to be loaded in ", $92, "application.", 0

; *******************************************************************************************************************
.PrinterEdHelp
        defm    $7F
        defm    "The Printer Editor allows different printer commands to", $7F
        defm    "be defined, saved, loaded and used. The default printer", $7F
        defm    "commands are ", $92, "Epson FX80 or FX (ESC/P) or ESC/P2.", $7F
        defm    "Remember to use ", $92, $BA, " Update command to update the", $7F
        defm    "settings after loading or changing ", $92, "definitions.", 0

; *******************************************************************************************************************
.PanelHelp
        defm    $7F
        defm    "Use ", $92, "Panel for start up settings that Applications use.", $7F
        defm    "Keyboard settings & country layout selection, Serial Port", $7F
        defm    "speed for printing and file transfer, User preferences,", $7F
        defm    "Default Devices and Directories settings are here.", 0

; *******************************************************************************************************************
.ClockHelp
        defm    $7F
        defm    "Displays ", $92, "current Day, Date and Time.", $7F
        defm    "Set ", $92, "current Date and Time here to ensure that alarm", $7F
        defm    "events execute on time and applications use correct data.", 0

; *******************************************************************************************************************
.TerminalHelp
        defm    $7F
        defm    "The Terminal allows simple VT-52 communication", $7F
        defm    "to another computer using ", $92, "Serial Port.", 0

; *******************************************************************************************************************
.ImpExpHelp
        defm    $7F
        defm    "This ", $BA, " Transfer Program allows files to be shared with", $7F
        defm    "other computers. Serial port speed is set in ", $92, "Panel.", 0

; *******************************************************************************************************************
.EazyLinkHelp
        DEFB    12
        DEFM    "EazyLink", $7F
        DEFB    $7F
        DEFM    "Fast Client/Server Remote ", $BA, " Management,", $7F
        DEFM    "including support for PC-LINK II clients."
        DEFB    0


; *******************************************************************************************************************
.FlashStoreHelp
                    DEFM 12, "FlashStore", $7F, $7F
                    DEFM "Manage ", $FD, " on Rakewell Flash Cards and RAM.", 0
.cmd_sc_help
                    DEFM $7F
                    DEFM "Selects which ", $BA, " Card to use when you have more than one."
                    DEFB 0
.cmd_cf_help
                    DEFM $7F
                    DEFM "Lists filenames on ", $BA, " Card area to PipeDream file."
                    DEFB 0
.cmd_sv_help
                    DEFM $7F
                    DEFM "Changes default RAM device for this session."
                    DEFB 0
.cmd_fs_help
                    DEFM $7F
                    DEFM "Saves files from RAM device to ", $BA, " Card Area."
                    DEFB 0
.cmd_fl_help
                    DEFM $7F
                    DEFM "Fetches a ", $BA, " from ", $BA, " Card Area to RAM device."
                    DEFB 0
.cmd_fe_help
                    DEFM $7F
                    DEFM "Marks a ", $BA, " in ", $BA, " Card Area as deleted."
                    DEFB 0
.cmd_bf_help
                    DEFM $7F
                    DEFM "Saves all files from RAM device to ", $BA, " Card Area."
                    DEFB 0
.cmd_rf_help
                    DEFM $7F
                    DEFM "Fetches all files from ", $BA, " Card Area to RAM device."
                    DEFB 0
.cmd_ffa_help
                    DEFM $7F
                    DEFM "Formats and erases complete ", $BA, " Card Area."
                    DEFB 0
.cmd_tfv_help
                    DEFM $7F
                    DEFM "Changes between browsing only saved files or", $7F
                    DEFM "also files marked as deleted."
                    DEFB 0
.cmd_fc_help
                    DEFM $7F
                    DEFM "Copy saved files in current ", $BA, " Card Area to", $7F
                    DEFM "another flash card in a different ", $FA, "."
                    DEFB 0


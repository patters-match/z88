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
        defb    (IndexCardHelp - IndexHelp)/256                 ; high byte of rel. pointer
        defb    (IndexCardHelp - IndexHelp)%256                 ; low byte of rel. pointer
        defb    @00010000                                       ; command has help page
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

; "Info"
.PipeDream_tpc0
        defb    PipeDream_tpc0_end-PipeDream_tpc0+1	; Length of topic
        defm    "Info"
        defw    0	; No help page
        defb    $13	; Topic attribute
.PipeDream_tpc0_end
        defb    PipeDream_tpc0_end-PipeDream_tpc0+1

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

.PipeDream_itpc1
        defb    PipeDream_itpc1_end-PipeDream_itpc1+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    "Tr", $90, $ce, $9c, "s"
        defb    (PipeDream_help_itpc1-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc1-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc1_end
        defb    PipeDream_itpc1_end-PipeDream_itpc1+1
.PipeDream_itpc2
        defb    PipeDream_itpc2_end-PipeDream_itpc2+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    "Log", $ce, $9c, "s"
        defb    (PipeDream_help_itpc2-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc2-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc2_end
        defb    PipeDream_itpc2_end-PipeDream_itpc2+1
.PipeDream_itpc3
        defb    PipeDream_itpc3_end-PipeDream_itpc3+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    "Li", $ca, $9c, "s"
        defb    (PipeDream_help_itpc3-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc3-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc3_end
        defb    PipeDream_itpc3_end-PipeDream_itpc3+1
.PipeDream_itpc4
        defb    PipeDream_itpc4_end-PipeDream_itpc4+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    "S", $a5, $84, $9c, "s"
        defb    (PipeDream_help_itpc4-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc4-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc4_end
        defb    PipeDream_itpc4_end-PipeDream_itpc4+1
.PipeDream_itpc5
        defb    PipeDream_itpc5_end-PipeDream_itpc5+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    "In", $af, "g", $ef, "& D", $91, $82, $9c, "s"
        defb    (PipeDream_help_itpc5-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc5-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc5_end
        defb    PipeDream_itpc5_end-PipeDream_itpc5+1
.PipeDream_itpc6
        defb    PipeDream_itpc6_end-PipeDream_itpc6+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    $ab, "ndi", $87, $95, "s"
        defb    (PipeDream_help_itpc6-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc6-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc6_end
        defb    PipeDream_itpc6_end-PipeDream_itpc6+1
.PipeDream_itpc7
        defb    PipeDream_itpc7_end-PipeDream_itpc7+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    $f6
        defb    (PipeDream_help_itpc7-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc7-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc7_end
        defb    PipeDream_itpc7_end-PipeDream_itpc7+1
.PipeDream_itpc8
        defb    PipeDream_itpc8_end-PipeDream_itpc8+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    $b8, $f6
        defb    (PipeDream_help_itpc8-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc8-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc8_end
        defb    PipeDream_itpc8_end-PipeDream_itpc8+1
.PipeDream_itpc9
        defb    PipeDream_itpc9_end-PipeDream_itpc9+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    $c8, "la", $87, $95, " ", $f6
        defb    (PipeDream_help_itpc9-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc9-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc9_end
        defb    PipeDream_itpc9_end-PipeDream_itpc9+1
.PipeDream_itpc10
        defb    PipeDream_itpc10_end-PipeDream_itpc10+1	; Length of command
        defb    $00	; command code
        defm    $00

        defm    "Wildc", $8c, "ds"
        defb    (PipeDream_help_itpc10-PipeDreamHelp) / 256	; high byte of help offset
        defb    (PipeDream_help_itpc10-PipeDreamHelp) % 256	; low byte of help offset
        defb    $10	; Command attribute
.PipeDream_itpc10_end
        defb    PipeDream_itpc10_end-PipeDream_itpc10+1
        defb    1	; Command topic separator

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
        defb    0	; Start topic marker

.PrinterEd_tpc1
        defb    PrinterEd_tpc1_end-PrinterEd_tpc1+1	; Length of topic
        defm    $dc
        defb    $00	; Topic attribute
.PrinterEd_tpc1_end
        defb    PrinterEd_tpc1_end-PrinterEd_tpc1+1

.PrinterEd_tpc2
        defb    PrinterEd_tpc2_end-PrinterEd_tpc2+1	; Length of topic
        defm    $fd
        defb    $00	; Topic attribute
.PrinterEd_tpc2_end
        defb    PrinterEd_tpc2_end-PrinterEd_tpc2+1

        defb    0	; End topic marker

.PrinterEdCommands
        defb    0	; Start command marker

.PrinterEd_cmd1
        defb    PrinterEd_cmd1_end-PrinterEd_cmd1+1	; Length of command
        defb    $26	; command code
        defm    "J", $00
        defm    $97, $ec
        defb    $00	; Command attribute
.PrinterEd_cmd1_end
        defb    PrinterEd_cmd1_end-PrinterEd_cmd1+1

.PrinterEd_cmd2
        defb    PrinterEd_cmd2_end-PrinterEd_cmd2+1	; Length of command
        defb    $0d	; command code
        defm    $e1, $00
        defm    $d2
        defb    $00	; Command attribute
.PrinterEd_cmd2_end
        defb    PrinterEd_cmd2_end-PrinterEd_cmd2+1

.PrinterEd_cmd3
        defb    PrinterEd_cmd3_end-PrinterEd_cmd3+1	; Length of command
        defb    $1b	; command code
        defm    $1b, $00
        defm    $b1
        defb    $00	; Command attribute
.PrinterEd_cmd3_end
        defb    PrinterEd_cmd3_end-PrinterEd_cmd3+1

.PrinterEd_cmd4
        defb    PrinterEd_cmd4_end-PrinterEd_cmd4+1	; Length of command
        defb    $fd	; command code
        defm    $fd, $00
        defm    $a7
        defb    $01	; Command attribute
.PrinterEd_cmd4_end
        defb    PrinterEd_cmd4_end-PrinterEd_cmd4+1

.PrinterEd_cmd5
        defb    PrinterEd_cmd5_end-PrinterEd_cmd5+1	; Length of command
        defb    $fc	; command code
        defm    $fc, $00
        defm    $a8
        defb    $00	; Command attribute
.PrinterEd_cmd5_end
        defb    PrinterEd_cmd5_end-PrinterEd_cmd5+1

.PrinterEd_cmd6
        defb    PrinterEd_cmd6_end-PrinterEd_cmd6+1	; Length of command
        defb    $24	; command code
        defm    $ff, $00
        defm    $da
        defb    $00	; Command attribute
.PrinterEd_cmd6_end
        defb    PrinterEd_cmd6_end-PrinterEd_cmd6+1

.PrinterEd_cmd7
        defb    PrinterEd_cmd7_end-PrinterEd_cmd7+1	; Length of command
        defb    $25	; command code
        defm    $fe, $00
        defm    $db
        defb    $00	; Command attribute
.PrinterEd_cmd7_end
        defb    PrinterEd_cmd7_end-PrinterEd_cmd7+1

.PrinterEd_cmd8
        defb    PrinterEd_cmd8_end-PrinterEd_cmd8+1	; Length of command
        defb    $27	; command code
        defm    $fb, $00
        defm    "Page 1/2"
        defb    $01	; Command attribute
.PrinterEd_cmd8_end
        defb    PrinterEd_cmd8_end-PrinterEd_cmd8+1

.PrinterEd_cmd9
        defb    PrinterEd_cmd9_end-PrinterEd_cmd9+1	; Length of command
        defb    $28	; command code
        defm    $fa, $00
        defm    "Page 2/2"
        defb    $00	; Command attribute
.PrinterEd_cmd9_end
        defb    PrinterEd_cmd9_end-PrinterEd_cmd9+1

.PrinterEd_cmd10
        defb    PrinterEd_cmd10_end-PrinterEd_cmd10+1	; Length of command
        defb    $2e	; command code
        defm    "ISO", $00
        defm    "ISO Transla",$87,"s"
        defb    $00	; Command attribute
.PrinterEd_cmd10_end
        defb    PrinterEd_cmd10_end-PrinterEd_cmd10+1

        defb    1	; Command topic separator

.PrinterEd_cmd11
        defb    PrinterEd_cmd11_end-PrinterEd_cmd11+1	; Length of command
        defb    $29	; command code
        defm    "FL", $00
        defm    $e1
        defb    $00	; Command attribute
.PrinterEd_cmd11_end
        defb    PrinterEd_cmd11_end-PrinterEd_cmd11+1

.PrinterEd_cmd12
        defb    PrinterEd_cmd12_end-PrinterEd_cmd12+1	; Length of command
        defb    $2a	; command code
        defm    "FS", $00
        defm    $bd, "e"
        defb    $00	; Command attribute
.PrinterEd_cmd12_end
        defb    PrinterEd_cmd12_end-PrinterEd_cmd12+1

.PrinterEd_cmd13
        defb    PrinterEd_cmd13_end-PrinterEd_cmd13+1	; Length of command
        defb    $2b	; command code
        defm    "FC", $00
        defm    "N", $ed, "e"
        defb    $00	; Command attribute
.PrinterEd_cmd13_end
        defb    PrinterEd_cmd13_end-PrinterEd_cmd13+1

.PrinterEd_cmd14
        defb    PrinterEd_cmd14_end-PrinterEd_cmd14+1	; Length of command
        defb    $2c	; command code
        defm    "FNEW", $00
        defm    "New"
        defb    $00	; Command attribute
.PrinterEd_cmd14_end
        defb    PrinterEd_cmd14_end-PrinterEd_cmd14+1

.PrinterEd_cmd15
        defb    PrinterEd_cmd15_end-PrinterEd_cmd15+1	; Length of command
        defb    $2d	; command code
        defm    "FU", $00
        defm    $b9, "d", $91, $82, "Driv", $86
        defb    $00	; Command attribute
.PrinterEd_cmd15_end
        defb    PrinterEd_cmd15_end-PrinterEd_cmd15+1

        defb    0	; End command marker


; ********************************************************************************************************************
; MTH for Panel popdown...
;

.PanelTopics
        defb    0	; Start topic marker

.Panel_tpc1
        defb    Panel_tpc1_end-Panel_tpc1+1	; Length of topic
        defm    $dc
        defb    $00	; Topic attribute
.Panel_tpc1_end
        defb    Panel_tpc1_end-Panel_tpc1+1

.Panel_tpc2
        defb    Panel_tpc2_end-Panel_tpc2+1	; Length of topic
        defm    $fd
        defb    $00	; Topic attribute
.Panel_tpc2_end
        defb    Panel_tpc2_end-Panel_tpc2+1

        defb    0	; End topic marker

.PanelCommands
        defb    0	; Start command marker
.Panel_cmd1
        defb    Panel_cmd1_end-Panel_cmd1+1	; Length of command
        defb    $26	; command code
        defm    "J", $00
        defm    $97, $ec
        defb    $00	; Command attribute
.Panel_cmd1_end
        defb    Panel_cmd1_end-Panel_cmd1+1

.Panel_cmd2
        defb    Panel_cmd2_end-Panel_cmd2+1	; Length of command
        defb    $0d	; command code
        defm    $e1, $00
        defm    $d2
        defb    $00	; Command attribute
.Panel_cmd2_end
        defb    Panel_cmd2_end-Panel_cmd2+1

.Panel_cmd3
        defb    Panel_cmd3_end-Panel_cmd3+1	; Length of command
        defb    $1b	; command code
        defm    $1b, $00
        defm    $b1
        defb    $00	; Command attribute
.Panel_cmd3_end
        defb    Panel_cmd3_end-Panel_cmd3+1

.Panel_cmd4
        defb    Panel_cmd4_end-Panel_cmd4+1	; Length of command
        defb    $fd	; command code
        defm    $fd, $00
        defm    $a7
        defb    $01	; Command attribute
.Panel_cmd4_end
        defb    Panel_cmd4_end-Panel_cmd4+1

.Panel_cmd5
        defb    Panel_cmd5_end-Panel_cmd5+1	; Length of command
        defb    $fc	; command code
        defm    $fc, $00
        defm    $a8
        defb    $00	; Command attribute
.Panel_cmd5_end
        defb    Panel_cmd5_end-Panel_cmd5+1

.Panel_cmd6
        defb    Panel_cmd6_end-Panel_cmd6+1	; Length of command
        defb    $24	; command code
        defm    $ff, $00
        defm    $da
        defb    $00	; Command attribute
.Panel_cmd6_end
        defb    Panel_cmd6_end-Panel_cmd6+1

.Panel_cmd7
        defb    Panel_cmd7_end-Panel_cmd7+1	; Length of command
        defb    $25	; command code
        defm    $fe, $00
        defm    $db
        defb    $00	; Command attribute
.Panel_cmd7_end
        defb    Panel_cmd7_end-Panel_cmd7+1

        defb    1	; Command topic separator

.Panel_cmd8
        defb    Panel_cmd8_end-Panel_cmd8+1	; Length of command
        defb    $29	; command code
        defm    "FL", $00
        defm    $e1
        defb    $00	; Command attribute
.Panel_cmd8_end
        defb    Panel_cmd8_end-Panel_cmd8+1

.Panel_cmd9
        defb    Panel_cmd9_end-Panel_cmd9+1	; Length of command
        defb    $2a	; command code
        defm    "FS", $00
        defm    $bd, "e"
        defb    $00	; Command attribute
.Panel_cmd9_end
        defb    Panel_cmd9_end-Panel_cmd9+1

.Panel_cmd10
        defb    Panel_cmd10_end-Panel_cmd10+1	; Length of command
        defb    $2c	; command code
        defm    "FNEW", $00
        defm    "New"
        defb    $00	; Command attribute
.Panel_cmd10_end
        defb    Panel_cmd10_end-Panel_cmd10+1

        defb    0	; End command marker


; ********************************************************************************************************************
; MTH for Filer popdown...
;
.FilerTopics
        defb    0	; Start topic marker

.Filer_tpc1
        defb    Filer_tpc1_end-Filer_tpc1+1	    ; Length of topic
        defm    $d8                             ; "Commands"
        defb    $00	; Topic attribute
.Filer_tpc1_end
        defb    Filer_tpc1_end-Filer_tpc1+1

        defb    0	; End topic marker

.FilerCommands
        defb    0	; Start command marker

.Filer_cmd1
        defb    Filer_cmd1_end-Filer_cmd1+1	    ; Length of command
        defb    $21	; command code
        defm    "CF", $00                       ; <>CF, Catalogue Files
        defm    "C", $91, $95, "ogu", $82, $fd
        defb    $00	; Command attribute
.Filer_cmd1_end
        defb    Filer_cmd1_end-Filer_cmd1+1

.Filer_cmd2
        defb    Filer_cmd2_end-Filer_cmd2+1	    ; Length of command
        defb    $25	; command code
        defm    "CO", $00                       ; <>CO, Copy
        defm    $de
        defb    $00	; Command attribute
.Filer_cmd2_end
        defb    Filer_cmd2_end-Filer_cmd2+1

.Filer_cmd3
        defb    Filer_cmd3_end-Filer_cmd3+1	    ; Length of command
        defb    $26	; command code
        defm    "RE", $00                       ; <>RE, Rename
        defm    "R", $a2, $ed, "e"
        defb    $00	; Command attribute
.Filer_cmd3_end
        defb    Filer_cmd3_end-Filer_cmd3+1

.Filer_cmd4
        defb    Filer_cmd4_end-Filer_cmd4+1	    ; Length of command
        defb    $27	; command code
        defm    "ER", $00                       ; <>ER, Erase
        defm    "E", $e2, $eb
        defb    $00	; Command attribute
.Filer_cmd4_end
        defb    Filer_cmd4_end-Filer_cmd4+1

.Filer_cmd5
        defb    Filer_cmd5_end-Filer_cmd5+1	    ; Length of command
        defb    $2c	; command code
        defm    "EX", $00                       ; <>EX, Execute
        defm    $e8, "ecu", $af
        defb    $00	; Command attribute
.Filer_cmd5_end
        defb    Filer_cmd5_end-Filer_cmd5+1

.Filer_cmd6
        defb    Filer_cmd6_end-Filer_cmd6+1	    ; Length of command
        defb    $0d	; command code
        defm    $e1, $00                        ; ENTER, Select first file
        defm    $e3, $f8, $ba
        defb    $00	; Command attribute
.Filer_cmd6_end
        defb    Filer_cmd6_end-Filer_cmd6+1

.Filer_cmd7
        defb    Filer_cmd7_end-Filer_cmd7+1	    ; Length of command
        defb    $20	; command code
        defm    $d1, $00                        ; SHIFT ENTER, Select Extra File
        defm    $e3, $e8, "t", $e2, " ", $ba
        defb    $00	; Command attribute
.Filer_cmd7_end
        defb    Filer_cmd7_end-Filer_cmd7+1

.Filer_cmd25
        defb    Filer_cmd25_end-Filer_cmd25+1	; Length of command
        defb    $28	; command code
        defm    "VF", $00                       ; <>VF, View File
        defm    "View ", $ba       ; "View File"
        defb    $00	; Command attribute
.Filer_cmd25_end
        defb    Filer_cmd25_end-Filer_cmd25+1

.Filer_cmd8
        defb    Filer_cmd8_end-Filer_cmd8+1	    ; Length of command
        defb    $20	; command code
        defm    $e2, $00                        ; TAB, Select Extra File
        defm    $04                             ; hidden entry..
        defb    $04	; Command attribute
.Filer_cmd8_end
        defb    Filer_cmd8_end-Filer_cmd8+1

.Filer_cmd9
        defb    Filer_cmd9_end-Filer_cmd9+1	    ; Length of command
        defb    $2d	; command code
        defm    "CD", $00                       ; <>CD, Create Directory
        defm    "C", $8d, $91, $82, $b6
        defb    $01	; Command attribute         ; (new column)
.Filer_cmd9_end
        defb    Filer_cmd9_end-Filer_cmd9+1

.Filer_cmd10
        defb    Filer_cmd10_end-Filer_cmd10+1	; Length of command
        defb    $29	; command code
        defm    "SI", $00                       ; <>SI, Select Directory
        defm    $e3, $b6
        defb    $00	; Command attribute
.Filer_cmd10_end
        defb    Filer_cmd10_end-Filer_cmd10+1

.Filer_cmd11
        defb    Filer_cmd11_end-Filer_cmd11+1	; Length of command
        defb    $31	; command code
        defm    $fb, $00                        ; SHIFT UP, Up Directory
        defm    $b9, " ", $b6
        defb    $00	; Command attribute
.Filer_cmd11_end
        defb    Filer_cmd11_end-Filer_cmd11+1

.Filer_cmd12
        defb    Filer_cmd12_end-Filer_cmd12+1	; Length of command
        defb    $32	; command code
        defm    $fa, $00                        ; SHIFT DOWN, Down Directory
        defm    $ac, " ", $b6
        defb    $00	; Command attribute
.Filer_cmd12_end
        defb    Filer_cmd12_end-Filer_cmd12+1
.Filer_cmd13
        defb    Filer_cmd13_end-Filer_cmd13+1	; Length of command
        defb    $fd	; command code
        defm    $fd, $00                        ; Cursor Right
        defm    $a7
        defb    $00	; Command attribute
.Filer_cmd13_end
        defb    Filer_cmd13_end-Filer_cmd13+1

.Filer_cmd14
        defb    Filer_cmd14_end-Filer_cmd14+1	; Length of command
        defb    $fc	; command code
        defm    $fc, $00                        ; Cursor Left
        defm    $a8
        defb    $00	; Command attribute
.Filer_cmd14_end
        defb    Filer_cmd14_end-Filer_cmd14+1

.Filer_cmd15
        defb    Filer_cmd15_end-Filer_cmd15+1	; Length of command
        defb    $ff	; command code
        defm    $ff, $00                        ; Cursor Up
        defm    $da
        defb    $00	; Command attribute
.Filer_cmd15_end
        defb    Filer_cmd15_end-Filer_cmd15+1

.Filer_cmd16
        defb    Filer_cmd16_end-Filer_cmd16+1	; Length of command
        defb    $fe	; command code
        defm    $fe, $00                        ; Cursor Down
        defm    $db
        defb    $00	; Command attribute
.Filer_cmd16_end
        defb    Filer_cmd16_end-Filer_cmd16+1

.Filer_cmd17
        defb    Filer_cmd17_end-Filer_cmd17+1	; Length of command
        defb    $22	; command code
        defm    "CE", $00                       ; <>CE, Catalogue File Card
        defm    "C", $91, $95, "ogu", $82, $ee
        defb    $01	; Command attribute         ; (New Column)
.Filer_cmd17_end
        defb    Filer_cmd17_end-Filer_cmd17+1

.Filer_cmd18
        defb    Filer_cmd18_end-Filer_cmd18+1	; Length of command
        defb    $23	; command code
        defm    "ES", $00                       ; <>ES, Save to File Card
        defm    $bd, $82, $bb, $ee
        defb    $00	; Command attribute
.Filer_cmd18_end
        defb    Filer_cmd18_end-Filer_cmd18+1

.Filer_cmd19
        defb    Filer_cmd19_end-Filer_cmd19+1	; Length of command
        defb    $24	; command code
        defm    "EF", $00                       ; <>EF, Fetch from File Card
        defm    "Fet", $b4, " fro", $d7, $ee
        defb    $00	; Command attribute
.Filer_cmd19_end
        defb    Filer_cmd19_end-Filer_cmd19+1

.Filer_cmd20
        defb    Filer_cmd20_end-Filer_cmd20+1	; Length of command
        defb    $2a	; command code
        defm    "SV", $00                       ; <>SV, Select Device
        defm    $e3, "Devi", $c9
        defb    $00	; Command attribute
.Filer_cmd20_end
        defb    Filer_cmd20_end-Filer_cmd20+1

.Filer_cmd23
        defb    Filer_cmd23_end-Filer_cmd23+1	; Length of command
        defb    $2b	; command code
        defm    "SE", $00                       ; <>SE, Select File Card
        defm    $e3, $ee
        defb    $00	; Command attribute
.Filer_cmd23_end
        defb    Filer_cmd23_end-Filer_cmd23+1

.Filer_cmd24
        defb    Filer_cmd24_end-Filer_cmd24+1	; Length of command
        defb    $2e	; command code
        defm    "EC", $00                       ; <>EC, Create File Card
        defm    "C", $8d, $91, $82, $ee
        defb    $00	; Command attribute
.Filer_cmd24_end
        defb    Filer_cmd24_end-Filer_cmd24+1

.Filer_cmd21
        defb    Filer_cmd21_end-Filer_cmd21+1	; Length of command
        defb    $2f	; command code
        defm    "TC", $00                       ; <>TC, Tree Copy
        defm    "T", $8d, $82, $de
        defb    $00	; Command attribute
.Filer_cmd21_end
        defb    Filer_cmd21_end-Filer_cmd21+1

.Filer_cmd22
        defb    Filer_cmd22_end-Filer_cmd22+1	; Length of command
        defb    $30	; command code
        defm    "NM", $00                       ; <>NM, Name Match
        defm    "N", $ed, $82, $f7
        defb    $00	; Command attribute
.Filer_cmd22_end
        defb    Filer_cmd22_end-Filer_cmd22+1

        defb    0	; End command marker


; ********************************************************************************************************************
; MTH for Terminal popdown...
;
.TerminalTopics
        defb    0	; Start topic marker

.Terminal_tpc1
        defb    Terminal_tpc1_end-Terminal_tpc1+1	; Length of topic
        defm    $d8
        defb    $00	; Topic attribute
.Terminal_tpc1_end
        defb    Terminal_tpc1_end-Terminal_tpc1+1

        defb    0	; End topic marker

.TerminalCommands
        defb    0	; Start command marker

.Terminal_cmd1
        defb    Terminal_cmd1_end-Terminal_cmd1+1	; Length of command
        defb    $02	; command code
        defm    $e3, $00
        defm    $e0
        defb    $00	; Command attribute
.Terminal_cmd1_end
        defb    Terminal_cmd1_end-Terminal_cmd1+1

.Terminal_cmd2
        defb    Terminal_cmd2_end-Terminal_cmd2+1	; Length of command
        defb    $03	; command code
        defm    $d3, $00
        defm    "Backspa", $c9
        defb    $00	; Command attribute
.Terminal_cmd2_end
        defb    Terminal_cmd2_end-Terminal_cmd2+1

.Terminal_cmd3
        defb    Terminal_cmd3_end-Terminal_cmd3+1	; Length of command
        defb    $01	; command code
        defm    $d1, $00
        defm    $e8, $fc
        defb    $00	; Command attribute
.Terminal_cmd3_end
        defb    Terminal_cmd3_end-Terminal_cmd3+1

.Terminal_cmd4
        defb    Terminal_cmd4_end-Terminal_cmd4+1	; Length of command
        defb    $06	; command code
        defm    $fd, $00
        defm    $a7
        defb    $01	; Command attribute
.Terminal_cmd4_end
        defb    Terminal_cmd4_end-Terminal_cmd4+1

.Terminal_cmd5
        defb    Terminal_cmd5_end-Terminal_cmd5+1	; Length of command
        defb    $07	; command code
        defm    $fc, $00
        defm    $a8
        defb    $00	; Command attribute
.Terminal_cmd5_end
        defb    Terminal_cmd5_end-Terminal_cmd5+1

.Terminal_cmd6
        defb    Terminal_cmd6_end-Terminal_cmd6+1	; Length of command
        defb    $04	; command code
        defm    $ff, $00
        defm    $da
        defb    $00	; Command attribute
.Terminal_cmd6_end
        defb    Terminal_cmd6_end-Terminal_cmd6+1

.Terminal_cmd7
        defb    Terminal_cmd7_end-Terminal_cmd7+1	; Length of command
        defb    $05	; command code
        defm    $fe, $00
        defm    $db
        defb    $00	; Command attribute
.Terminal_cmd7_end
        defb    Terminal_cmd7_end-Terminal_cmd7+1

.Terminal_cmd8
        defb    Terminal_cmd8_end-Terminal_cmd8+1	; Length of command
        defb    $08	; command code
        defm    $f8, $00
        defm    $9c, " 0"
        defb    $01	; Command attribute
.Terminal_cmd8_end
        defb    Terminal_cmd8_end-Terminal_cmd8+1

.Terminal_cmd9
        defb    Terminal_cmd9_end-Terminal_cmd9+1	; Length of command
        defb    $09	; command code
        defm    $f9, $00
        defm    $9c, " 1"
        defb    $00	; Command attribute
.Terminal_cmd9_end
        defb    Terminal_cmd9_end-Terminal_cmd9+1

.Terminal_cmd10
        defb    Terminal_cmd10_end-Terminal_cmd10+1	; Length of command
        defb    $0a	; command code
        defm    $fa, $00
        defm    $9c, " 2"
        defb    $00	; Command attribute
.Terminal_cmd10_end
        defb    Terminal_cmd10_end-Terminal_cmd10+1

.Terminal_cmd11
        defb    Terminal_cmd11_end-Terminal_cmd11+1	; Length of command
        defb    $0b	; command code
        defm    $fb, $00
        defm    $9c, " 3"
        defb    $00	; Command attribute
.Terminal_cmd11_end
        defb    Terminal_cmd11_end-Terminal_cmd11+1

        defb    0	; End command marker



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
                    DEFM $E3, "C",$8C,"d", 0                                         ; "Select Card"
                    DEFB (cmd_sc_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_sc_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_sc_end - cmd_sc                                    ; length of command definition
.cmd_sc_end

; <>CF Catalogue Files
.cmd_cf             DEFB cmd_cf_end - cmd_cf                                    ; length of command definition
                    DEFB FlashStore_CC_cf                                       ; command code
                    DEFM "CF", 0                                                ; keyboard sequence
                    DEFM "C",$91,$95,"ogue C",$8C,"d ", $FD, 0                              ; "Catalogue Card Files"
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
                    DEFM $E3, "R",$ED," Device", 0                                   ; "Select RAM Device"
                    DEFB (cmd_sv_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_sv_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_sv_end - cmd_sv                                    ; length of command definition
.cmd_sv_end

; <>FE File Erase
.cmd_fe             DEFB cmd_fe_end - cmd_fe                                    ; length of command definition
                    DEFB FlashStore_CC_fe                                       ; command code
                    DEFM "FE", 0                                                ; keyboard sequence
                    DEFM "Era",$EB," ", $BA, " from C",$8C,"d", 0                         ; "Erase File from Card", 0
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
                    DEFM $BD, $82, $FD, " ",$9E," C",$8C,"d", 0                           ; "Save Files to Card"
                    DEFB (cmd_fs_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fs_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_fs_end - cmd_fs                                    ; length of command definition
.cmd_fs_end

; <>FL File Load
.cmd_fl             DEFB cmd_fl_end - cmd_fl                                    ; length of command definition
                    DEFB FlashStore_CC_fl                                       ; command code
                    DEFM "FL", 0                                                ; keyboard sequence
                    DEFM "Fet",$B4," ", $BA, " from C",$8C,"d", 0                         ; "Fetch file from Card"
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
                    DEFM "Backup ", $FD, " from R",$ED,0                         ; "Backup files from RAM"
                    DEFB (cmd_bf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_bf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_bf_end - cmd_bf                                    ; length of command definition
.cmd_bf_end

; <>RF Restore RAM Files
.cmd_rf             DEFB cmd_rf_end - cmd_rf                                    ; length of command definition
                    DEFB FlashStore_CC_rf                                       ; command code
                    DEFM "RF", 0                                                ; keyboard sequence
                    DEFM "Res",$9E,"re ", $FD, " ",$9E," R",$ED,0                          ; "Restore files to RAM"
                    DEFB (cmd_rf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_rf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_rf_end - cmd_rf                                    ; length of command definition
.cmd_rf_end


; <>FC Copy all files to Card
.cmd_fc             DEFB cmd_fc_end - cmd_fc                                    ; length of command definition
                    DEFB FlashStore_CC_fc                                       ; command code
                    DEFM "FC", 0                                                ; keyboard sequence
                    DEFM $DE, " ",$95,"l ", $FD, " ",$9E," C",$8C,"d", 0                       ; "Copy all files to Card"
                    DEFB (cmd_fc_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fc_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_fc_end - cmd_fc                                    ; length of command definition
.cmd_fc_end

; <>FFA Format File Area
.cmd_ffa            DEFB cmd_ffa_end - cmd_ffa                                  ; length of command definition
                    DEFB FlashStore_CC_ffa                                      ; command code
                    DEFM "FFA", 0                                               ; keyboard sequence
                    DEFM "Form",$91," ", $BA, " A",$8D,"a", 0                             ; "Format File Area"
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
                    DEFM "Fet",$B4," ", $BA, " a",$84,$DC, 0                          ; "Fetch File at Cursor"
                    DEFB 0                                                      ; no help
                    DEFB 0                                                      ;
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_fetch_end - cmd_fetch                              ; length of command definition
.cmd_fetch_end

; DEL Delete file at cursor
.cmd_delete         DEFB cmd_delete_end - cmd_delete                            ; length of command definition
                    DEFB IN_DEL                                                 ; command code
                    DEFM MU_DEL, 0                                              ; keyboard sequence
                    DEFM $96, $BA, " a",$84,$DC, 0                               ; "Delete File at Cursor"
                    DEFB 0                                                      ; no help
                    DEFB 0                                                      ;
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_delete_end - cmd_delete                            ; length of command definition
.cmd_delete_end

                    DEFB 0                                                      ; end of commands


; *******************************************************************************************************************
.IndexHelp
        defm    $7F, "All ",$85,$EB,"r",$87," ",$93,$B2,$8D,"mov",$95," ",$89,"c",$8C,"ds mus",$84,"be done from", $7F
        defm    $92, "INDEX. Do no",$84,$8D,"move ",$93,"y R",$ED," c",$8C,"d",$A4,$8F," a ROM c",$8C,"d", $7F
        defm    "whi",$B4,$B7,$85," u",$EB,". A cont",$85,"uous ",$9E,"ne ask",$8E,"f",$8F," a ROM", $7F
        defm    "c",$8C,$B2,$9E," be ",$8D,"-",$85,$EB,"r",$AF,$B2,$85,$9E," it",$8E,$8F,$90,$85,$95," ", $FA, ".", $7F
        defm    "A ", 1,"TFAIL", 1, "T message ",$8D,"qui",$8D,$8E,$92, "ma",$B4,$85,"e ",$9E," be ",$8D,$EB,"t.", 0

.IndexCardHelp
        defb $7F
        defm "Sh",$9D,$8E,"available ",$8D,"sso",$C6,"ce",$8E,$89,$85,$EB,"r",$AF,$B2,"c",$8C,"d",$8E,$93,$B2,"f",$8D,"e space", $7F
        defm "available on ",$93,"y ",$EB,"lec",$AF,$B2,"R",$ED," device. F",$C6,$88,$86,$A4,"i",$84,"displays", $7F
        defm "a graphic",$95," map ",$89,$92,"u",$EB,$B2,$93,$B2,"f",$8D,"e mem",$8F,"y ",$89,$92,"R",$ED," c",$8C,"d.", $7F
        defm "An enable",$B2,"pixel (d",$8C,"k) identifie",$8E,"u",$EB,$B2,"space (u",$EB,$B2,"by files", $7F
        defm $8F," sys",$AF,"m). Voi",$B2,"pixel",$8E,$8C,"e f",$8D,"e space.", 0

; *******************************************************************************************************************
.PipeDreamHelp
        defm    $7F
        defm    "PipeD",$8D,$ED,$B7,"a comb",$85,"e",$B2, $D3, "-process",$8F,$A4,"Sp",$8D,"adsheet", $7F
        defm    $93,$B2,"D",$91,"aba",$EB," applica",$87,". U",$EB," ", $92, "HELP key ",$93,$B2,"br",$9D,$EB," ",$92,$7F
        defm    "INFO ",$9E,"pic",$8E,$9E," view PipeD",$8D,$ED,$8E,"ma",$88,"em",$91,"ic",$95," func",$87,"s.", 0

.PipeDream_help_itpc1
        defb    $43,$4f,$53,$f9,$a4,$53,$49,$4e,$f9,$a4,$54,$41,$4e,$f9,$f0,$20	; COS..SIN..TAN.. 
        defb    $92,$cd,$89,$92,$8c,$67,$75,$6d,$a2,$74,$9a,$41,$43,$53,$c1,$29	; .....gum.t.ACS.)
        defb    $a4,$41,$53,$4e,$c1,$29,$a4,$41,$54,$4e,$c1,$29,$f0,$20,$92,$8c	; .ASN.).ATN.). ..
        defb    $63,$20,$cd,$c2,$22,$7f,$28,$a3,$9f,$29,$9a,$52,$41,$44,$28,$f1	; c .."(..).RAD(.
        defb    $29,$83,$22,$f1,$f2,$9f,$9a,$44,$45,$47,$f9,$83,$22,$9f,$f2,$f1	; )."....DEG.."...
        defb    $2e,$00	; ..LN..n... .g.i
.PipeDream_help_itpc2
        defb    $7f,$4c,$4e,$c1,$ae,$6e,$91,$c6,$95,$20,$a5,$67,$8c,$69,$88,$6d	; LN..n... .g.i.m
        defb    $a4,$28,$a5,$67,$20,$65,$29,$20,$c2,$b0,$4c,$4f,$47,$c1,$ae,$a5	; .(.g e) ..LOG...
        defb    $67,$8c,$69,$88,$d7,$bb,$62,$61,$73,$82,$31,$30,$20,$c2,$b0,$45	; g.i...bas.10 ..E
        defb    $58,$50,$c1,$ae,$63,$bc,$73,$74,$93,$84,$65,$a4,$bb,$92,$70,$9d	; XP..c.st..e...p.
        defb    $ef,$c2,$22,$2e,$00	; .."..CHOOSE... .
.PipeDream_help_itpc3
        defb    $43,$48,$4f,$4f,$53,$45,$e5,$83,$93,$20,$c7,$6d,$a2,$84,$66	; CHOOSE... .m..fr
        defb    $72	; ro.".".us..efir
        defb    $6f,$d7,$22,$a0,$22,$a4,$75,$73,$c0	; o.".".us..efir.
        defb    $88,$65,$7f,$66,$69,$72,$ca,$c7,$6d,$a2,$84,$61,$8e,$93,$20,$85	; .efir..m..a.. .
        defb    $e4,$78,$20,$85,$bb,$92,$8d,$6d,$61,$85,$c0,$c7,$6d,$a2,$74,$73	; .x ....ma...m.ts
        defb    $9a	; .eg.CHOOSE(3.4.5
        defb    $65,$67,$ce,$43,$48,$4f,$4f,$53	; eg.CHOOSE(3.4.5.
        defb    $45	; E(3.4.5.6).6.COU
        defb    $28,$33,$a4	; (3.4.5.6).6.COUN
        defb    $34,$a4	; 4.5.6).6.COUNT..
        defb    $35	; 5.6).6.COUNT....
        defb    $a4,$36,$29,$b7,$36,$9a,$43,$4f,$55	; .6).6.COUNT.....
        defb    $4e,$54,$e5,$b7,$92,$a1,$89,$6e,$bc,$2d,$62,$6c,$93,$6b,$20,$cf	; NT.....n.-bl.k .
        defb    $4d,$41,$58,$f3	; MAX.ax....MIN...
        defb    $61	; ax....MIN......S
        defb    $78,$ce,$e6,$89,$cf,$4d,$49,$4e,$f3,$85,$ce,$e6,$89,$cf,$53,$55	; x....MIN......SU
        defb    $4d,$e5,$b7,$92,$92,$73,$75,$d7,$89,$92,$69,$af,$6d,$8e,$f4,$a0	; M....su...i.m...
        defb    $22,$2e,$00	; "..COL..c...INDE
.PipeDream_help_itpc4
        defb    $43,$4f,$4c,$83,$92,$63,$8a,$d0,$9a,$49,$4e,$44,$45,$58,$28,$63	; COL..c...INDEX(c
        defb    $8a,$2c,$72,$9d,$ae,$e6,$89,$92,$73,$a5,$74,$7f,$8d,$66,$86,$a2	; .,r.....s.t.f..
        defb    $c9,$b2,$62,$d6,$22,$63,$8a,$22,$20,$93,$b2,$22,$72,$9d,$b0,$4c	; ..b."c." .."r..L
        defb    $4f,$4f,$4b,$55,$50,$28,$6b,$65,$79,$2c,$e7,$31,$2c,$e7,$32,$ae	; OOKUP(key,.1,.2.
        defb    $e6,$f4,$e7,$32,$22,$7f,$63,$8f,$8d,$73,$70,$bc,$64,$c0,$bb,$92	; ...2"c..sp.d...
        defb    $70,$6f,$73,$69,$87,$20,$92,$6b,$65,$d6,$6f,$63,$63,$c6,$8e,$f4	; posi. .ke.occ...
        defb    $e7,$31,$b0,$57,$69,$6c,$64,$63,$8c,$64,$8e,$6d,$61,$d6,$62,$82	; .1.Wildc.d.ma.b.
        defb    $75,$eb,$b2,$f4,$6b,$65,$79,$22,$ce,$49,$66,$20,$6e,$6f,$20,$6d	; u...key".If no m
        defb    $91,$b4,$20,$3d,$20,$22,$4c,$6f,$6f,$6b,$75,$70,$b0,$52,$4f,$57	; .. = "Lookup.ROW
        defb    $83,$92,$72,$9d,$d0,$2e,$00	; ..r....ABS..abso
.PipeDream_help_itpc5
        defb    $41,$42,$53,$c1,$ae,$61,$62,$73,$6f,$6c,$75,$74,$82,$e6,$c2,$b0	; ABS..absolut....
        defb    $44,$41,$59,$28,$f5,$ae,$64,$61,$d6,$a1,$f4,$f5,$b0,$4d,$4f,$4e	; DAY(..da.....MON
        defb    $54,$48,$28,$f5,$ae,$6d,$bc,$88,$20,$a1,$f4,$f5,$b0,$50,$49,$83	; TH(..m.. ....PI.
        defb    $92,$e6,$33,$2e,$31,$34,$31,$35,$39,$32,$36,$35,$33,$9a,$53,$47	; ..3.141592653.SG
        defb    $4e,$c1,$29,$83,$2d,$31,$a4,$30,$a4,$31,$20,$e4,$70,$a2,$64,$c0	; N.).-1.0.1 .p.d.
        defb    $bc,$20,$92,$73,$90,$6e,$20,$c2,$b0,$53,$51,$52,$c1,$ae,$73,$71	; . .s.n ..SQR..sq
        defb    $75,$8c,$82,$72,$6f,$6f,$84,$c2,$b0,$59,$45,$41,$52,$28,$f5,$ae	; u..roo...YEAR(..
        defb    $79,$65,$8c,$20,$a1,$89,$22,$f5,$22,$2e,$00	; ye. .."."..IF(b
.PipeDream_help_itpc6
        defb    $7f,$49,$46,$28,$62,$6f,$6f,$8b,$93,$2c,$88,$a2,$2c,$65,$6c,$eb	; IF(boo..,..,el.
        defb    $29,$9a,$7f,$49,$66,$20,$92,$e6,$89,$92,$22,$62,$6f,$6f,$8b,$93	; ).If ...."boo..
        defb    $22,$b7,$54,$52,$55,$45,$20,$c1,$bc,$2d,$7a,$86,$6f,$29,$a4,$49	; ".TRUE ..-z.o).I
        defb    $46,$f0,$8e,$22,$88,$a2,$22,$a4,$6f,$88,$86,$77,$69,$73,$82,$49	; F.."..".o..wis.I
        defb    $46,$83,$22,$65,$6c,$eb,$b0,$7f,$65,$67,$ce,$49,$46,$28,$35,$3e	; F."el..eg.IF(5>
        defb    $31,$a4,$22,$6d,$6f,$8d,$22,$a4,$22,$8b,$73,$73,$22,$29,$b7,$22	; 1."mo.".".ss")."
        defb    $6d,$6f,$8d,$22,$2e,$00	; mo."..Add.+Sub
.PipeDream_help_itpc7
        defb    $7f,$41,$64,$64,$aa,$2b,$7f,$53,$75,$62,$74,$e2,$63,$74,$aa,$2d	; Add.+Subt.ct.-
        defb    $7f,$4d,$75,$6c,$74,$69,$d9,$79,$aa,$2a,$7f,$44,$69,$76,$69,$e4	; Multi.y.*Divi.
        defb    $aa,$2f,$7f,$52,$61,$69,$73,$82,$bb,$70,$9d,$86,$aa,$5e,$00	; ./Rais..p...^.
.PipeDream_help_itpc8
        defb    $7f,$7f,$b8,$41,$4e,$44,$aa,$26,$7f,$b8,$4f,$52,$aa,$7c,$7f,$b8	; .AND.&.OR.|.
        defb    $4e,$4f,$54,$aa,$21,$00	; NOT.!.Les....<
.PipeDream_help_itpc9
        defb    $7f,$4c,$65,$73,$8e,$88,$93,$aa,$3c,$7f,$4c,$65,$73,$8e,$88,$93	; Les....<Les...
        defb    $20,$8f,$20,$65,$d5,$aa,$3c,$3d,$7f,$4e,$6f,$84,$65,$d5,$aa,$3c	;  . e..<=No.e..<
        defb    $3e,$7f,$45,$d5,$aa,$3d,$7f,$47,$8d,$91,$ef,$88,$93,$aa,$3e,$7f	; >E..=G......>
        defb    $47,$8d,$91,$ef,$88,$93,$20,$8f,$20,$65,$d5,$3a,$20,$3e,$3d,$00	; G..... . e.: >=.
.PipeDream_help_itpc10
        defb    $7f,$7f,$41,$6e,$d6,$73,$85,$67,$6c,$82,$63,$99,$aa,$5e,$3f,$7f	; An.s.gl.c..^?
        defb    $41,$6e,$d6,$a1,$89,$63,$99,$73,$aa,$5e,$23,$00	; An...c.s.^#.....


; *******************************************************************************************************************
.DiaryHelp
        defm    $7F
        defm    "This",$B7,"a 'Page a Day' di",$8C,"y. Multiple di",$8C,"y", $7F
        defm    "applica",$87,$8E,"may be u",$EB,$B2,"f",$8F," ex",$ED,"ple f",$8F," w",$8F,"k ",$93,$B2,"home.", $7F
        defm    "The C",$95,"end",$8C," popd",$9D,"n when ",$EB,"lec",$AF,$B2,"from ", $92, "Di",$8C,"y", $7F
        defm    "c",$93," be u",$EB,$B2,$9E," view active day",$8E,$93,$B2,"nav",$90,$C3," ",$8C,"ound.", 0

; *******************************************************************************************************************
.BasicHelp
        defm    $7F
        defm    "Develop yo",$C6," ",$9D,"n BBC BASIC progr",$ED,"s",$A4,"s",$9E,$8D," ",$88,"em ",$85," ", $92, "R",$ED,$7F
        defm    "fil",$C0,"sys",$AF,"m a",$8E,$BA,$8E,$93,$B2,"RUN ",$88,"em ",$85,"side one ",$8F," ",$EB,"v",$86,$95,$7F
        defm    "BBC BASIC applica",$87,"s. A built-",$85," Z80 as",$EB,"mbl",$86," enables", $7F
        defm    "you ",$9E," compile ",$93,$B2,"embe",$B2,"ma",$B4,$85,"e code ",$85,"side yo",$C6," progr",$ED,"s", $7F
        defm    $88,"a",$84,"may acces",$8E,"adv",$93,"ce",$B2,"fe",$91,"u",$8D,$8E,$89,$92, "op",$86,$91,$C0,"sys",$AF,"m.",0

; *******************************************************************************************************************
.CalculatorHelp
        defm    $7F
        defm    "A simple pocke",$84,"c",$95,"cul",$91,$8F," wi",$88," some u",$EB,"ful", $7F
        defm    "Imp",$86,"i",$95," ",$9E," Metric conv",$86,"sion func",$87,"s.", 0

; *******************************************************************************************************************
.CalendarHelp
        defm    $7F
        defm    "Thi",$8E,"'Juli",$93," proleptic' c",$95,"end",$8C," st",$8C,"t",$8E,"from 4712 BC ",$93,$B2,"is", $7F
        defm    "ye",$8C," 2000 compli",$93,"t. To m",$93,"u",$95,"ly jump ",$9E," a ",$F5,$A4,"p",$8D,"s",$8E,$92,$7F
        defm    $D2," key ",$93,$B2,"edi",$84,$92, "'Look f",$8F,"' ",$F5,". U",$EB," ", $92, $DC, " keys", $7F
        defm    $9E,"ge",$88,$86," wi",$88," ", $92, "shif",$84,$93,$B2,"di",$ED,"on",$B2,"key",$8E,$9E," nav",$90,$C3," ",$88,"rough", $7F
        defm    "day",$8E,"mon",$88,$8E,$93,$B2,"ye",$8C,"s. A m",$8C,"k on a day ",$85,"dic",$C3,$8E,$93," entry is", $7F
        defm    "made on ",$88,"a",$84,$F5," ",$85," ", $92, "Di",$8C,"y.", 0

; *******************************************************************************************************************
.AlarmHelp
        defm    $7F
        defm    "Se",$84,"ei",$88,$86," s",$85,"gle ",$8F," ",$8D,"pe",$91,$C0,$95,$8C,"m events", $7F
        defm    $9E," soun",$B2, $92, "bell ",$8F," execu",$AF," ",$D8," ",$9E," laun",$B4,$7F
        defm    "sys",$AF,"m applica",$87,$8E,$8F," ",$8D,"so",$C6,"ces.", 0

; *******************************************************************************************************************
.FilerHelp
        defm    $7F
        defm    "The ",$BA,"r",$B7,"u",$EB,$B2,$9E," m",$93,"age s",$9E,$8D,$B2,$BA,$8E,"gen",$86,$C3,$B2,"from", $7F
        defm    "Applica",$87,$8E,$85," R",$ED,$A4,"Eprom ",$8F," Flash c",$8C,"ds.", $7F
        defm    "When ", $92, $BA,"r",$B7,$EB,"lec",$AF,$B2,"from ",$85,"side ",$93," applica",$87,$7F
        defm    $BA, " ",$E1," comm",$93,"d",$A4,"a ",$BA," c",$93," be m",$8C,"ke",$B2,"wi",$88," ", $92, $D2, " key", $7F
        defm    "foll",$9D,"e",$B2,"by ", $92, $B1, " key ",$9E," save typ",$C0,$85," ", $92, $BA," n",$ED,"e", $7F
        defm    $9E," be loade",$B2,$85," ", $92, "applica",$87,".", 0

; *******************************************************************************************************************
.PrinterEdHelp
        defm    $7F
        defm    "The ",$FE,$86," Edit",$8F," ",$95,"l",$9D,$8E,"diffe",$8D,"n",$84,"print",$86," ",$D8," ",$9E, $7F
        defm    "be def",$85,"ed",$A4,"saved",$A4,"loade",$B2,$93,$B2,"u",$EB,"d. The defaul",$84,"print",$86,$7F
        defm    $D8," ",$8C,"e ", $92, "Epson FX80 ",$8F," FX (ESC/P) ",$8F," ESC/P2.", $7F
        defm    "Rememb",$86," ",$9E," u",$EB," ", $92, $BA, " ",$B9,$F5," comm",$93,$B2,$9E," up",$F5," ",$92,$7F
        defm    $EB,"tt",$85,"g",$8E,"aft",$86," load",$C0,$8F," ",$B4,$93,"g",$C0,$92, "def",$85,"i",$87,"s.", 0

; *******************************************************************************************************************
.PanelHelp
        defm    $7F
        defm    "U",$EB," ", $92, "P",$93,"el f",$8F," st",$8C,$84,"up ",$EB,"tt",$85,"g",$8E,$88,"a",$84,"Applica",$87,$8E,"u",$EB,".", $7F
        defm    "Keybo",$8C,$B2,$EB,"tt",$85,"g",$8E,"& country layou",$84,$EB,"lec",$87,$A4,"S",$86,"i",$95," P",$8F,"t", $7F
        defm    "spee",$B2,"f",$8F," pr",$85,"t",$C0,$93,$B2,$BA," tr",$93,"sf",$86,$A4,"U",$EB,"r p",$8D,"fe",$8D,"nces,", $7F
        defm    "Defaul",$84,"Device",$8E,$93,$B2,"Di",$8D,"ct",$8F,"ie",$8E,$EB,"tt",$85,"g",$8E,$8C,"e he",$8D,".", 0

; *******************************************************************************************************************
.ClockHelp
        defm    $7F
        defm    "Display",$8E,$92, "c",$C6,$8D,"n",$84,"day",$A4,$F5," ",$93,$B2,"Time.", $7F
        defm    "Se",$84,$92, "c",$C6,$8D,"n",$84,$F5," ",$93,$B2,"Time he",$8D," ",$9E," ensu",$8D," ",$88,"a",$84,$95,$8C,"m", $7F
        defm    "event",$8E,"execu",$AF," on time ",$93,$B2,"applica",$87,$8E,"u",$EB," c",$8F,$8D,"c",$84,"d",$91,"a.", 0

; *******************************************************************************************************************
.TerminalHelp
        defm    $7F
        defm    "The T",$86,"min",$95," ",$95,"l",$9D,$8E,"simple VT-52 communica",$87,$7F
        defm    $9E," ",$93,"o",$88,$86," comput",$86," us",$C0,$92, "S",$86,"i",$95," P",$8F,"t.", 0

; *******************************************************************************************************************
.ImpExpHelp
        defm    $7F
        defm    "Thi",$8E,$BA, " Tr",$93,"sf",$86," Progr",$ED," ",$95,"l",$9D,$8E,$BA,$8E,$9E," be sh",$8C,"e",$B2,"wi",$88,$7F
        defm    "o",$88,$86," comput",$86,"s. S",$86,"i",$95," p",$8F,$84,"speed",$B7,$EB,$84,$85," ", $92, "P",$93,"el.", 0

; *******************************************************************************************************************
.EazyLinkHelp
        DEFB    12
        DEFM    "EazyL",$85,"k", $7F
        DEFB    $7F
        DEFM    "Fas",$84,"Client/S",$86,"v",$86," Remo",$AF," ", $BA, " M",$93,"agement,", $7F
        DEFM    $85,"clud",$C0,"supp",$8F,$84,"f",$8F," PC-LINK II clients."
        DEFB    0


; *******************************************************************************************************************
.FlashStoreHelp
                    DEFM 12, "FlashS",$9E,$8D,$7F, $7F
                    DEFM "M",$93,"age ", $FD, " on Rakewell Flash C",$8C,"d",$8E,$93,$B2,"R",$ED,".", 0
.cmd_sc_help
                    DEFM $7F
                    DEFM "Select",$8E,"whi",$B4," ", $EE, " ",$9E," u",$EB," when you have mo",$8D," ",$88,$93," one."
                    DEFB 0
.cmd_cf_help
                    DEFM $7F
                    DEFM "List",$8E,$BA,"n",$ED,"e",$8E,"on ", $EE, " A",$8D,"a ",$9E," PipeD",$8D,$ED," ",$BA,"."
                    DEFB 0
.cmd_sv_help
                    DEFM $7F
                    DEFM "Ch",$93,"ge",$8E,"defaul",$84,"R",$ED," device f",$8F," ",$88,"i",$8E,$EB,"ssion."
                    DEFB 0
.cmd_fs_help
                    DEFM $7F
                    DEFM $BD,"e",$8E,$BA,$8E,"from R",$ED," device ",$9E," ", $EE, " A",$8D,"a."
                    DEFB 0
.cmd_fl_help
                    DEFM $7F
                    DEFM "Fet",$B4,"e",$8E,"a ", $BA, " from ", $EE, " A",$8D,"a ",$9E," R",$ED," device."
                    DEFB 0
.cmd_fe_help
                    DEFM $7F
                    DEFM "M",$8C,"k",$8E,"a ", $BA, " ",$85," ", $EE, " A",$8D,"a a",$8E,"dele",$AF,"d."
                    DEFB 0
.cmd_bf_help
                    DEFM $7F
                    DEFM $BD,"e",$8E,$95,"l ",$BA,$8E,"from R",$ED," device ",$9E," ", $EE, " A",$8D,"a."
                    DEFB 0
.cmd_rf_help
                    DEFM $7F
                    DEFM "Fet",$B4,"e",$8E,$95,"l ",$BA,$8E,"from ", $EE, " A",$8D,"a ",$9E," R",$ED," device."
                    DEFB 0
.cmd_ffa_help
                    DEFM $7F
                    DEFM "F",$8F,"m",$91,$8E,$93,$B2,$86,"a",$EB,$8E,"comple",$AF," ", $EE, " A",$8D,"a."
                    DEFB 0
.cmd_tfv_help
                    DEFM $7F
                    DEFM "Ch",$93,"ge",$8E,"between br",$9D,"s",$C0,"only save",$B2,$BA,$8E,$8F,$7F
                    DEFM $95,"so ",$BA,$8E,"m",$8C,"ke",$B2,"a",$8E,"dele",$AF,"d."
                    DEFB 0
.cmd_fc_help
                    DEFM $7F
                    DEFM $DE," save",$B2,$BA,$8E,$85," c",$C6,$8D,"n",$84,$EE, " A",$8D,"a ",$9E, $7F
                    DEFM $93,"o",$88,$86," flash c",$8C,$B2,$85," a diffe",$8D,"n",$84,$FA, "."
                    DEFB 0


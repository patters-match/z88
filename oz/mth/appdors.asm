; **************************************************************************************************
; OZ Application/Popdown DOR definitions (top bank of ROM).
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

        Module AppDOR

        include "dor.def"
        include "sysvar.def"
        include "sysapps.def"

        include "../dc/dc.def"
        include "../apps/impexport/impexp.inc"
        include "../apps/clock/clcalalm.def"
        include "../apps/eazylink/rtmvars.def"
        include "mth-flashstore.def"

xdef    IndexDOR, DiaryDOR, PipeDreamDOR, BasicDOR, CalculatorDOR, AlarmDOR, CalendarDOR
xdef    ClockDOR, FilerDOR, TerminalDOR, PrEdDOR, PanelDOR, ImpExpDOR, EasyLinkDOR, FlashstoreDOR

xref    SysTokenBase
xref    IndexTopics, IndexCommands, IndexHelp
xref    DiaryTopics, DiaryCommands, DiaryHelp
xref    PipeDreamTopics, PipeDreamCommands, PipeDreamHelp
xref    FilerTopics, FilerCommands, FilerHelp
xref    BasicHelp
xref    PrinterEdTopics, PrinterEdCommands, PrinterEdHelp
xref    PanelTopics, PanelCommands, PanelHelp
xref    CalculatorHelp
xref    CalendarHelp
xref    ClockHelp
xref    AlarmHelp
xref    TerminalTopics, TerminalCommands, TerminalHelp
xref    ImpExpHelp
xref    EazyLinkHelp
xref    FlashStoreTopics, FlashStoreCommands, FlashStoreHelp


; ********************************************************************************************************************
.IndexDOR
        defp    0,0                             ; parent
        defp    DiaryDOR,OZBANK_MTH & $3F       ; brother
        defp    0,0                             ; son
        defb    DM_ROM,IndexDORe-$PC            ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'I',0                           ; application key letter, bad app RAM
        defw    0,INDEX_UNSAFE_WS,0             ; env. size, unsafe and safe workspace
        defw    ORG_INDEX                       ; entry point
        defb    0,0,0,OZBANK_INDEX & $3F        ; bind bank of Index popdown to segment 3
        defb    AT_Good|AT_Popd|AT_Ones         ; appl type
        defb    0                               ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    IndexTopics,OZBANK_MTH & $3F    ; topics
        defp    IndexCommands,OZBANK_MTH & $3F  ; commands
        defp    IndexHelp,OZBANK_MTH & $3F      ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; token base

        defb    'N',IndexDORe-$PC-1             ; name, length
        defm    "Index",0
.IndexDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.DiaryDOR
        defp    0,0                             ; parent
        defp    PipeDreamDOR,OZBANK_MTH & $3F   ; brother
        defp    0,0                             ; son
        defb    $83,DiaryDORe-$PC               ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'D',0                           ; application key letter, bad app RAM
        defw    $26C,0,$20                      ; env. size, unsafe and safe workspace
        defw    ORG_DIARY                       ; entry point
        defb    0,0,0,OZBANK_DIARY & $3F        ; bind bank of Diary application to segment 3
        defb    AT_Good                         ; appl type mutiple diaries (was AT_Good|AT_Ones)
        defb    0                               ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    DiaryTopics,OZBANK_MTH & $3F    ; topics
        defp    DiaryCommands,OZBANK_MTH & $3F  ; commands
        defp    DiaryHelp,OZBANK_MTH & $3F      ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; token base

        defb    'N',DiaryDORe-$PC-1             ; name, length
        defm    "Diary",0
.DiaryDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.PipeDreamDOR
        defp    0,0                             ; parent
        defp    BasicDOR,OZBANK_MTH & $3F       ; brother
        defp    0,0                             ; son
        defb    $83,PipeDreamDORe-$PC           ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'P',0                           ; application key letter, bad app RAM
        defw    $4D8,$268,$60                   ; env. size, unsafe and safe workspace
        defw    ORG_PIPEDREAM                   ; entry point
        defb    0,0
        defb    OZBANK_PIPEDREAM & $3F
        defb    (OZBANK_PIPEDREAM+1) & $3F        ; bind banks of PipeDream to segment 2 & 3
        defb    AT_Good                         ; appl type
        defb    0                               ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    PipeDreamTopics,OZBANK_MTH & $3F      ; topics
        defp    PipeDreamCommands,OZBANK_MTH & $3F    ; commands
        defp    PipeDreamHelp,OZBANK_MTH & $3F        ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F         ; token base

        defb    'N',PipeDreamDORe-$PC-1         ; name, length
        defm    "PipeDream",0
.PipeDreamDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.BasicDOR
        defp    0,0                             ; parent
        defp    CalculatorDOR,OZBANK_MTH & $3F  ; brother
        defp    0,0                             ; son
        defb    $83,BasicDORe-$PC               ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'B',0                           ; application key letter, bad app RAM
        defw    $9B0,$3E,$C0                    ; env. size, unsafe and safe workspace
        defw    ORG_BBCBASIC                    ; entry point
        defb    0,0,0,OZBANK_BBCBASIC & $3F     ; bind bank of BBC Basic application to segment 3
        defb    AT_Bad|AT_Draw                  ; appl type
        defb    AT2_Cl                          ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    BasicDOR,OZBANK_MTH & $3F       ; no topics
        defp    BasicDOR,OZBANK_MTH & $3F       ; no commands
        defp    BasicHelp,OZBANK_MTH & $3F      ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; use system token table

        defb    'N',BasicDORe-$PC-1             ; name, length
        defm    "BBC Basic",0
.BasicDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.CalculatorDOR
        defp    0,0                             ; parent
        defp    CalendarDOR,OZBANK_MTH & $3F    ; brother
        defp    0,0                             ; son
        defb    $83,CalculatorDORe-$PC          ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'R',0                           ; application key letter, bad app RAM
        defw    0,$80,0                         ; env. size, unsafe and safe workspace
        defw    ORG_CALCULATOR                  ; entry point
        defb    0,0,0,OZBANK_CALCULATOR & $3F   ; bind bank of Calculator popdown to segment 3
        defb    AT_Good|AT_Popd                 ; appl type
        defb    0                               ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    CalculatorDOR,OZBANK_MTH & $3F  ; no topics
        defp    CalculatorDOR,OZBANK_MTH & $3F  ; no commands
        defp    CalculatorHelp,OZBANK_MTH & $3F ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; use system token table

        defb    'N',CalculatorDORe-$PC-1        ; name, length
        defm    "Calculator",0
.CalculatorDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.CalendarDOR
        defp    0,0                             ; parent
        defp    ClockDOR,OZBANK_MTH & $3F       ; brother
        defp    0,0                             ; son
        defb    $83, CalendarDORe-$PC           ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'C',0                           ; application key letter, bad app RAM
        defw    0,40,0                          ; env. size, unsafe and safe workspace
        defw    ORG_CALENDAR                    ; entry point
        defb    0,0,0,OZBANK_CALENDAR & $3F     ; bind bank of Calendar popdown to segment 3
        defb    AT_Good|AT_Popd                 ; appl type
        defb    AT2_Ie                          ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    CalendarDOR,OZBANK_MTH & $3F    ; no topics
        defp    CalendarDOR,OZBANK_MTH & $3F    ; no commands
        defp    CalendarHelp,OZBANK_MTH & $3F   ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; use system token table

        defb    'N',CalendarDORe-$PC-1          ; name, length
        defm    "Calendar",0
.CalendarDORe
        defb    $ff


; ********************************************************************************************************************
.ClockDOR
        defp    0,0                             ; parent
        defp    AlarmDOR,OZBANK_MTH & $3F       ; brother
        defp    0,0                             ; son
        defb    $83, ClockDORe-$PC              ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'T',0                           ; application key letter, bad app RAM
        defw    0,0,0                           ; env. size, unsafe and safe workspace
        defw    ORG_CLOCK                       ; entry point
        defb    0,0,0,OZBANK_CLOCK & $3F        ; bind bank of Clock popdown to segment 3
        defb    AT_Good|AT_Popd                 ; appl type
        defb    AT2_Ie                          ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    ClockDOR,OZBANK_MTH & $3F       ; no topics
        defp    ClockDOR,OZBANK_MTH & $3F       ; no commands
        defp    ClockHelp,OZBANK_MTH & $3F      ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; use system token table

        defb    'N',ClockDORe-$PC-1             ; name, length
        defm    "Clock",0
.ClockDORe
        defb    $ff


; ********************************************************************************************************************
.AlarmDOR
        defp    0,0                             ; parent
        defp    FilerDor,OZBANK_MTH & $3F       ; brother
        defp    0,0                             ; son
        defb    $83,AlarmDORe-$PC               ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'A',0                           ; application key letter, bad app RAM
        defw    0,$10,0                         ; env. size, unsafe and safe workspace
        defw    ORG_ALARM                       ; entry point
        defb    0,0,0,OZBANK_ALARM & $3F        ; bind bank of Alarm popdown to segment 3
        defb    AT_Good|AT_Popd                 ; appl type
        defb    AT2_Ie                          ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    AlarmDOR,OZBANK_MTH & $3F       ; topics
        defp    AlarmDOR,OZBANK_MTH & $3F       ; commands
        defp    AlarmHelp,OZBANK_MTH & $3F      ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; token base

        defb    'N',AlarmDORe-$PC-1             ; name, length
        defm    "Alarm",0
.AlarmDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.FilerDOR
        defp    0,0                             ; parent
        defp    PrEdDOR,OZBANK_MTH & $3F        ; brother
        defp    0,0                             ; son
        defb    $83,FilerDORe-$PC               ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'F',0                           ; application key letter, bad app RAM
        defw    0,FILER_UNSAFE_WS,0             ; env. size, unsafe and safe workspace
        defw    ORG_FILER                       ; entry point
        defb    0,0,0,OZBANK_FILER & $3F        ; bind bank of Filer popdown to segment 3
        defb    AT_Good|AT_Popd|AT_Film         ; appl type
        defb    0                               ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    FilerTopics,OZBANK_MTH & $3F    ; topics
        defp    FilerCommands,OZBANK_MTH & $3F  ; commands
        defp    FilerHelp,OZBANK_MTH & $3F      ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; token base
        defb    'N',FilerDORe-$PC-1             ; name, length
        defm    "Filer",0
.FilerDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.PrEdDOR
        defp    0,0                             ; parent
        defp    PanelDOR,OZBANK_MTH & $3F       ; brother
        defp    0,0                             ; son
        defb    DM_ROM, PrEdDORe-$PC            ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'E',0                           ; application key letter, bad app RAM
        defw    $26c,0,$20                      ; env. size, unsafe and safe workspace
        defw    ORG_PRINTERED                   ; entry point
        defb    0,0,0,OZBANK_PRINTERED & $3F    ; bind bank of Printered application to segment 3
        defb    AT_Good|AT_Ones                 ; appl type
        defb    0                               ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    PrinterEdTopics,OZBANK_MTH & $3F      ; topics
        defp    PrinterEdCommands,OZBANK_MTH & $3F    ; commands
        defp    PrinterEdHelp,OZBANK_MTH & $3F        ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F         ; token base

        defb    'N',PrEdDORe-$PC-1              ; name, length
        defm    "PrinterEd",0
.PrEdDORe
        defb    $ff


; ********************************************************************************************************************
.PanelDOR
        defp    0,0                             ; parent
        defp    TerminalDOR,OZBANK_MTH & $3F    ; brother
        defp    0,0                             ; son
        defb    $83, PanelDORe-$PC              ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'S',0                           ; application key letter, bad app RAM
        defw    0,0,$20                         ; env. size, unsafe and safe workspace
        defw    ORG_PANEL                       ; entry point !! absolute
        defb    0,0,0,OZBANK_PANEL & $3F        ; bind bank of Panel popdown to segment 3
        defb    AT_Good|AT_Popd                 ; appl type
        defb    0                               ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    PanelTopics,OZBANK_MTH & $3F    ; topics
        defp    PanelCommands,OZBANK_MTH & $3F  ; commands
        defp    PanelHelp,OZBANK_MTH & $3F      ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; token base

        defb    'N',PanelDORe-$PC-1             ; name, length
        defm    "Panel",0
.PanelDORe
        defb    $ff


; ********************************************************************************************************************
.TerminalDOR
        defp    0,0                             ; parent
        defp    ImpExpDOR,OZBANK_MTH & $3F      ; brother
        defp    0,0                             ; son
        defb    $83,TerminalDORe-$PC            ; DOR type, sizeof

        defb    '@',18,0,0                      ; info, info sizeof, 2xreserved
        defb    'V',0                           ; application key letter, bad app RAM
        defw    $744,0,$A                       ; env. size, unsafe and safe workspace
        defw    ORG_TERMINAL                    ; entry point
        defb    0,0,0,OZBANK_TERMINAL & $3F     ; bind bank of Terminal application to segment 3
        defb    AT_Good|AT_Ones|AT_Draw         ; appl type
        defb    AT2_Ie                          ; appl type 2

        defb    'H',12                          ; help, sizeof
        defp    TerminalTopics,OZBANK_MTH & $3F       ; topics
        defp    TerminalCommands,OZBANK_MTH & $3F     ; commands
        defp    TerminalHelp,OZBANK_MTH & $3F         ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F         ; token base

        defb    'N',TerminalDORe-$PC-1          ; name, length
        defm    "Terminal",0
.TerminalDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.ImpExpDOR
        defp    0,0                             ; parent
        defp    EasyLinkDOR,OZBANK_MTH & $3F    ; brother, EazyLink
        defp    0,0                             ; son
        defb    DM_ROM, ImpExpDORe-$PC          ; DOR type, sizeof
        defb    DT_INF, 18
        defb    0,0                             ; info, info sizeof, 2xreserved
        defb    'X'                             ; application key letter, bad app RAM
        defb    0
        defw    0,0,SAFESIZE                    ; env. size, unsafe and safe workspace
        defw    ORG_IMPEXPORT                   ; entry point
        defb    0,0,0,OZBANK_IMPEXPORT & $3F    ; bind bank of Imp/Export popdown to segment 3
        defb    AT_Good|AT_Popd,0               ; appl type
        defb    DT_HLP,12                       ; help, sizeof
        defp    ImpExpDOR,OZBANK_MTH & $3F      ; no topics
        defp    ImpExpDOR,OZBANK_MTH & $3F      ; no commands
        defp    ImpExpHelp,OZBANK_MTH & $3F     ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; use system token table

        defb    DT_NAM, ImpExpDORe-$PC-1
        defm    "Imp-Export",0                  ; name, length
.ImpExpDORe
        defb    $FF                             ; terminate


; ********************************************************************************************************************
.EasyLinkDOR
        defp    0, 0                            ; parent
        defp    FlashstoreDOR,OZBANK_MTH & $3F  ; brother, EazyLink
        defp    0, 0                            ; son
        defb    DM_ROM                          ; DOR type - application ROM
        defb    EasyLinkDORe-$PC                ; total length of DOR
        defb    DT_INF, 18                      ; Key, length to info section
        defw    0                               ; reserved...
        defb    'L'                             ; application key letter
        defb    EasyLinkRamPages                ; contiguous RAM for EazyLink
        defw    0                               ;
        defw    0                               ; Unsafe workspace
        defw    0                               ; Safe workspace
        defw    ORG_EAZYLINK                    ; Entry point of code in start of segment 2
        defb    0                               ; no bank binding to segment 0
        defb    0                               ; no bank binding to segment 1
        defb    OZBANK_EAZYLINK & $3F           ; bind bank of EazyLink popdown to segment 2
        defb    0                               ; no bank binding to segment 3
        defb    AT_Ugly | AT_Popd               ; Ugly popdown
        defb    0                               ; no caps lock
        defb    DT_HLP,12                       ; Help section, length
        defp    EasyLinkDOR,OZBANK_MTH & $3F    ; no topics
        defp    EasyLinkDOR,OZBANK_MTH & $3F    ; no commands
        defp    EazyLinkHelp,OZBANK_MTH & $3F   ; introductory help page
        defp    SysTokenBase,OZBANK_MTH & $3F   ; use System token base
        defb    DT_NAM, EasyLinkDORe-$PC-1      ; Name section, length
        defm    "EazyLink", 0
        defb    $FF
.EasyLinkDORe


; ********************************************************************************************************************
.FlashstoreDOR
                    DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0        ; total length of DOR
.DORStart0          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd0-InfoStart0      ; length of info section
.InfoStart0         DEFW 0                        ; reserved...
                    DEFB 'J'                      ; application key letter
                    DEFB RAM_pages                ; I/O buffer / vars for FlashStore
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW 0                        ; Safe workspace
                    DEFW ORG_FLASHSTORE           ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB OZBANK_FLASHSTORE        ; bind bank of FlashStore popdown to segment 3
                    DEFB AT_Ugly | AT_Popd        ; Ugly popdown
                    DEFB 0                        ; no caps lock on activation
.InfoEnd0           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFP FlashStoreTopics, OZBANK_MTH   ; point to topics
                    DEFP FlashStoreCommands, OZBANK_MTH ; point to commands
                    DEFP FlashStoreHelp, OZBANK_MTH     ; point to help
                    DEFP SysTokenBase, OZBANK_MTH       ; point to token base
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd0-NameStart0      ; length of name
.NameStart0         DEFM "FlashStore",0
.NameEnd0           DEFB $FF
.DOREnd0

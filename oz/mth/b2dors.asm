; **************************************************************************************************
; PrinterEd and Panel DORs,
;
; This file is part of the Z88 operating system, OZ      0000000000000000      ZZZZZZZZZZZZZZZZZZZ
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
;***************************************************************************************************

xdef    PrEdDOR
xdef    PanelDOR


.PrEdDOR
        defp    0,0                     ; parent
        defp    PanelDOR,BANK_MTH        ; brother
        defp    0,0                     ; son
        defb    $83, PrEdDORe-$PC       ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'E',0                   ; application key letter, bad app RAM
        defw    $26c,0,$20              ; env. size, unsafe and safe workspace
        defw    $c000                   ; entry point !! absolute
        defb    3,0,0,6                 ; bindings
        defb    AT_Good|AT_Ones         ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    PrinterEdTopics,BANK_MTH ; topics
        defp    PrinterEdCommands,BANK_MTH ; commands
        defp    PrEdDOR,BANK_MTH         ; no help
        defp    SysTokenBase,BANK_MTH         ; token base

        defb    'N',PrEdDORe-$PC-1      ; name, length
        defm    "PrinterEd",0
.PrEdDORe
        defb    $ff

.PanelDOR
        defp    0,0                     ; parent
        defp    TerminalDOR,BANK_MTH     ; brother
        defp    0,0                     ; son
        defb    $83, PanelDORe-$PC      ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'S',0                   ; application key letter, bad app RAM
        defw    0,0,$20                 ; env. size, unsafe and safe workspace
        defw    $c00a                   ; entry point !! absolute
        defb    0,0,0,6                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    0                       ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    PanelTopics,BANK_MTH     ; topics
        defp    PanelCommands,BANK_MTH   ; commands
        defp    PanelDOR,BANK_MTH               ; no help
        defp    SysTokenBase,BANK_MTH           ; token base

        defb    'N',PanelDORe-$PC-1             ; name, length
        defm    "Panel",0
.PanelDORe
        defb    $ff

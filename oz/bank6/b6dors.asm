; **************************************************************************************************
; Calendar & Clock DOR's (Bank 6, addressed for segment 3).
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

        Module B6DORs

        include "director.def"
        include "../bank7/appdors.def"

        org     $ff90

        defb    $ff

.CalendarDOR
        defp    0,0                     ; parent
        defp    ClockDOR,6              ; brother
.CalendarTopics
.CalendarCommands
.CalendarHelp
        defp    0,0                     ; son
        defb    $83, CalendarDORe-$PC   ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'C',0                   ; application key letter, bad app RAM
        defw    0,40,0                  ; env. size, unsafe and safe workspace
        defw    $e7f1                   ; entry point !! absolute
        defb    0,0,0,1                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    AT2_Ie                  ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    CalendarTopics,6 ; topics
        defp    CalendarCommands,6      ; commands
        defp    CalendarHelp,6          ; help
        defp    $8000,7                 ; token base

        defb    'N',CalendarDORe-$PC-1  ; name, length
        defm    "Calendar",0
.CalendarDORe
        defb    $ff

.ClockDOR
        defp    0,0                     ; parent
        defp    AlarmDOR,7              ; brother
.ClockTopics
.ClockCommands
.ClockHelp
        defp    0,0                     ; son
        defb    $83, ClockDORe-$PC      ; DOR type, sizeof

        defb    '@',18,0,0              ; info, info sizeof, 2xreserved
        defb    'T',0                   ; application key letter, bad app RAM
        defw    0,0,0                   ; env. size, unsafe and safe workspace
        defw    $e7ee                   ; entry point !! absolute
        defb    0,0,0,1                 ; bindings
        defb    AT_Good|AT_Popd         ; appl type
        defb    AT2_Ie                  ; appl type 2

        defb    'H',12                  ; help, sizeof
        defp    ClockTopics,6   ; topics
        defp    ClockCommands,6   ; commands
        defp    ClockHelp,6     ; help
        defp    $8000,7                 ; token base

        defb    'N',ClockDORe-$PC-1  ; name, length
        defm    "Clock",0
.ClockDORe
        defb    $ff


; **************************************************************************************************
; Imp/export popdown DOR 
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
; (C) Thierry Peycru (pek@users.sf.net), 2005,2006
; (C) Gunther Strube (gbs@users.sf.net), 2005,2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

.ImpExpDOR
        defp    0,0
        defp    0,0
        defp    0,0
        defb    DM_ROM, ImpExpDORe-$PC
        defb    DT_INF, 18
        defb    0,0
        defb    'X'
        defb    0
        defw    0,0,SAFESIZE
        defw    Imp_Export
        defb    0,0,0,1
        defb    AT_Good|AT_Popd,0
        defb    DT_HLP,12
        defp    ImpExpDOR,mthbank
        defp    ImpExpDOR,mthbank
        defp    ImpExpDOR,mthbank
        defp    0,0

        defb    DT_NAM, ImpExpDORe-$PC-1
        defm    "Imp-Export",0
.ImpExpDORe
        defb    $FF

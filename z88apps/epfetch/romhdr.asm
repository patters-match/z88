; *************************************************************************************
; EP-Fetch2
; (C) Garry Lancaster / Jorma Oksanen, 1993-2005
;
; EP-Fetch2 is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EP-Fetch2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EP-Fetch2;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

        Module  ep3_romhdr

        org $3fC0

include "epfetch2.def"

                defp    0,0
                defp    0,0
                defw    EPFetchDOR
                defb    $3F
                defb    $13,8
                defb    'N',5
                defm    "APPL",0
                defb    -1

                defs    $3ff8-$3fc0-19

; $fff6
                defw    0               ; card ID, to be filled in by loadmap
                defb    5               ; country (se)
                defb    $80             ; app
                defb    1               ; 16KB Popdown
                defb    0               ; subtype
                defm    "OZ"

; *************************************************************************************
; Installer/Bootstrap/Packages (c) Garry Lancaster 1998-2011
;
; Installer/Bootstrap/Packages is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2, or (at your option) any later version.
; Installer/Bootstrap/Packages is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with
; Installer/Bootstrap/Packages; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************


        module  romheader

        org     $3fc0

.front_dor
        defb    0,0,0           ; link to parent
        defb    0,0,0           ; no help DOR
        defw    $c000           ; first application DOR
        defb    $3f             ; in top bank of eprom
        defb    $13             ; ROM front DOR
        defb    8               ; length
        defb    'N'
        defb    5
        defm    "APPL", 0
        defb    $ff

        defs    37

.eprom_header
        defw    0               ; card ID, to be filled in by loadmap
        defb    @00000011       ; UK country code
        defb    $80             ; external application
        defb    $01             ; size of EPROM (16K)
        defb    0
        defm    "OZ"

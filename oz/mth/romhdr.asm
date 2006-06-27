; **************************************************************************************************
; OZ Rom Header, placed at top bank of Rom, offset $3fc0 - $3fff.
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
; $Id$
; ***************************************************************************************************

    MODULE RomHeader

    ORG $3FC0

; Application front DOR, in top bank of ROM, starting at $3FC0
     
     include "appdors.def"
     include "../banks.def"

.appl_front_dor                                 ; $3FC0
        defp 0, 0                               ; no link to parent ...
        defp 0, 0                               ; no help DOR
        defp IndexDor,mthbank                   ; link to first application DOR
        defb $13                                ; DOR type - ROM front DOR
        defb 8                                  ; length of DOR
        defb 'N'                                
        defb 5                                  ; length of name and terminator
        defm "APPL", 0                          
        defb $FF                                ; end of application front DOR
                                                
        defs 37                                 ; blanks to fill-out space.
                                                
.eprom_header                                   
        defb $54,$43,$4C                        ; $3FF8, card ID "TCL"
        defb $81                                ; $3FFB, external app would be $80
        defb romsize                            ; $3FFC, size of ROM in banks
        defb 0                                  ; $3FFD, subtype        
.oz_watermark                                   
        defm "OZ"                               ; $3FFE card is an application EPROM
.RomTop                                         

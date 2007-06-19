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

        module RomHeader

; Application front DOR, in top bank of ROM, starting at $3FC0

        org $3FC0

        include "mth.def"
        include "sysvar.def"

IF !OZ_SLOT1
; ---------------------------------------------------------------------------------------------------
; ROM header for slot 0

.appl_front_dor                                 ; $3FC0
        defp    0, 0                            ; no link to parent ...
        defp    0, 0                            ; no help DOR
        defp    IndexDor,OZBANK_MTH             ; link to first application DOR
        defb    $13                             ; DOR type - ROM front DOR
        defb    8                               ; length of DOR
        defb    'N'
        defb    5                               ; length of name and terminator
        defm    "APPL", 0
        defb    $FF                             ; end of application front DOR
        defs    25                              ; blanks to fill-out space.

        defb    FILEAREASIZE, $00               ; $3FEC, file area size in 16K banks, reclaim sector (0=not used)
        defm    "oz"                            ; $3FEE, 'oz' file area watermark.

        defs    8                               ; blanks to fill-out space.
.eprom_header
        defb    $54,$43,$4C                     ; $3FF8, card ID "TCL"
        defb    $81                             ; $3FFB, external app would be $80
        defb    ROMSIZE                         ; $3FFC, size of ROM in banks
        defb    0                               ; $3FFD, subtype
.oz_watermark
        defm    "OZ"                            ; $3FFE card is an application EPROM

ELSE
; ---------------------------------------------------------------------------------------------------
; ROM header for slot 1
        include "kernel.def"                    ; get bank number of KERNEL0
        include "../kernel0.def"                ; get kernel 0 kernel address references

.appl_front_dor                                 ; $3FC0
        defp    0, 0                            ; no link to parent ...
        defp    0, 0                            ; no help DOR
        defp    IndexDor,OZBANK_MTH             ; link to first application DOR
        defb    $13                             ; DOR type - ROM front DOR
        defb    8                               ; length of DOR
        defb    'N'
        defb    5                               ; length of name and terminator
        defm    "APPL", 0
        defb    $FF                             ; end of application front DOR
        defs    29                              ; blanks to fill-out space.

.boot_slot1_kernel
        ld      a, OZBANK_KNL0
        out     (BL_SR3), a                     ; map KERNEL0 to segment 3
        jp      Boot_reset                      ; and continue reset in new kernel
        defb    0

.eprom_header
        jr      boot_slot1_kernel               ; $3FF8, Hook jump address from bank 0 OZ ROM (this gets executed in segment 2 at $BFF8)

        defb    0
        defb    $81                             ; $3FFB, external app would be $80
        defb    ROMSIZE                         ; $3FFC, size of ROM in banks
        defb    'Z'                             ; $3FFD, indicate external OZ in slot 1
.oz_watermark
        defm    "OZ"                            ; $3FFE card contains OZ with applications
ENDIF

.RomTop

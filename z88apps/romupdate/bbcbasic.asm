; *************************************************************************************
; RomUpdate BBC BASIC program
; (C) Gunther Strube (gbs@users.sf.net) 2005
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

module RomUpdate

xdef crctable
xref app_main, CrcBuffer

org $2300

include "stdio.def"
include "director.def"


; -----------------------------------------------------------------------------
; BBC BASIC program loaded at $2300 (PAGE) executes CRC check routine before calling machine code at $25C0
binary "boot.bas"
; -----------------------------------------------------------------------------

defs $2C0 - $PC                              ; fill space until we reach the executable code at $25C0...

; *****************************************************************************
;
; Code begins at $25C0
;
.app_start
                    ld   sp,($1ffe)          ; install safe application stack permanently
                                             ; RomUpdate will not return to BBC BASIC...
                    call app_main
                    jr   app_start           ; paranoia... (this shouldn't get executed anyway...)


; *****************************************************************************
; CRC check of complete BBC BASIC RomUpdate program.
; Register parameters are supplied by USR routine from BBC BASIC
;
; IN:
;    BC = size of code to CRC check
;    HL = start of code to CRC check
;
; OUT:
;    HL H'L' = CRC of RomUpdate code (HL is most significant word)
;
.CrcCheckRomUpdate
                    call CrcBuffer
                    ex   de,hl
                    push de
                    exx
                    pop  hl
                    exx
                    ret                      ; return CRC value in HL H'L' (which is assigned to int variable in BBC BASIC from USR() function)

include "crctable.asm"

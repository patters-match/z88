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
     xref app_main

     ORG $2300

     include "stdio.def"
     include "director.def"


; -----------------------------------------------------------------------------
; Start of BBC BASIC program (PAGE)
; The complete program is resident in segment 0 ($2000 - $3FFF).
; 0000 *NAME FlashStore
; 0000 LOMEM=&3F00            ; LOMEM just below start of segment 1...
; 0000 CALL &2330

; <length byte> <line number> <token> <line> <end line delimiter>
.NameLine           DEFM NameLineEnd - $PC, 0, 0, $2A, "NAME RomUpdate", $0D
.NameLineEnd
.LoMemLine          DEFM LoMemLineEnd - $PC, 0, 0, $D2, "=&3F00", $0D
.LoMemLineEnd
.CallLine           DEFM CallLineEnd - $PC, 0, 0, $D6, " &2330", $0D
.CallLineEnd
; -----------------------------------------------------------------------------


                    ; fill space until we reach the executable code...
                    DEFS $30 - $PC


; *****************************************************************************
;
; Code begins at $2330
;
.app_start
                    LD   SP,($1ffe)          ; install safe application stack permanently
                                             ; FlashStore will not return to BBC BASIC...
                    call app_main

                    xor  a
                    oz   os_bye              ; perform suicide, focus to Index...

include "crctable.asm"

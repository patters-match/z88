; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

     MODULE Memory_range

     XREF Display_char, IntHexDisp_H, Display_string, Write_CRLF
     XDEF Memory_Range

     INCLUDE "defs.h"

; **********************************************************************************
.Memory_range     LD   HL, range_msg
                  CALL Display_string
                  LD   HL, $2000
                  SCF
                  CALL IntHexDisp_H         ; display address
                  LD   A, '-'
                  CALL Display_Char
                  LD   L,0
                  LD   H,(IY + RamTopPage)  ; RAM top  (start addr of memory back to OZ)
                  DEC  HL
                  SCF
                  CALL IntHexDisp_H         ; display end of variable area
                  CALL Write_CRLF           ; New Line.
                  RET

.range_Msg        DEFM "Memory Range: ",0

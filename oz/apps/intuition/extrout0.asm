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

     MODULE ExtRoutine_uppersegment0

     LIB ExtCall

     XDEF ExtRoutine_s00


; ******************************************************************************
;
;
.ExtRoutine_s00   PUSH IX
                  EXX
                  LD   HL,$04D0
                  LD   B,(HL)
                  RES  0,B                  ; bind in lower half of bank
                  LD   C,0                  ; into upper half of segment 0
                  POP  HL
                  EXX
                  CALL ExtCall
                  RET


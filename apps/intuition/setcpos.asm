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

     MODULE Set_CursorPosition

     XREF Display_string
     XDEF Set_CurPos

     INCLUDE "defs.h"


; *************************************************************************************
;
; Set cursor at X,Y position in current window          V0.18
;
; IN:
;         C,B  =  (X,Y)
;
; Register status after return:
;
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.Set_CurPos       PUSH HL
                  PUSH BC
                  LD   BC,24
                  PUSH IY
                  POP  HL
                  ADD  HL,BC
                  POP  BC
                  PUSH HL
                  LD   (HL),1               ; VDU 1,'3','@',32+C,32+B
                  INC  HL
                  LD   (HL),'3'
                  INC  HL
                  LD   (HL),'@'
                  INC  HL
                  LD   A,C
                  ADD  A,32
                  LD   (HL),A               ; X coordinate
                  INC  HL
                  LD   A,B
                  ADD  A,32
                  LD   (HL),A               ; Y coordinate
                  INC  HL
                  LD   (HL),0               ; null terminate VDU string
                  POP  HL
                  CALL Display_String       ; execute VDU
                  POP  HL
                  RET

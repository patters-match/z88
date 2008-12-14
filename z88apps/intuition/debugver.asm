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

     MODULE Debugger_version

     XREF Write_Msg, Display_char, IntHexDisp, IntHexDisp_H, Display_string, Write_CRLF
     XDEF Debugger_version

     INCLUDE "defs.h"


; **********************************************************************************
.Debugger_version LD   HL, Version          ; display Intuition release version
                  CALL Write_Msg
                  LD   HL, OZ_Version
                  CALL Display_String
                  LD   L,(IY + OzReleaseVer)
                  CP   A
                  CALL IntHexDisp           ; display version byte from OZ
                  CALL Write_CRLF
                  LD   HL, Base_Msg
                  CALL Display_String
                  PUSH IY
                  PUSH IY
                  POP  HL                   ; Get base of variable area in HL
                  SCF
                  CALL IntHexDisp_H         ; display address
                  POP  HL                   ; fetch the copy
                  LD   BC,Int_Worksp-1      ; size of monitor area (0 incl.)
                  ADD  HL,BC
                  LD   A, '-'
                  CALL Display_Char
                  SCF
                  CALL IntHexDisp_H         ; display end of variable area
                  JP   Write_CRLF           ; New Line.

.Base_Msg         DEFM "Buffer:",0
.OZ_version       DEFM "OZ: V",0
.Version          DEFM "V1.2.dev",0         ; see 'history.txt' for development history

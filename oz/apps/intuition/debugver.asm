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
                  LD   HL, Oldbnk_msg
                  CALL Display_String
                  LD   L,(IY + OZBankBinding+1)
                  CP   A
                  CALL IntHexDisp_H         ; display old S0 bank binding (before Intuition)
                  JP   Write_CRLF

.OZ_version       DEFM "OZ: V",0
.Version          DEFM "V1.2.dev",0         ; see 'history.txt' for development history
.Oldbnk_msg       DEFM "Old S0 binding: ",0

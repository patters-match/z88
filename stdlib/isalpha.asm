     XLIB IsAlpha

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************


; ******************************************************************************
;
; IsAlpha - check whether the ASCII byte is an alphabetic character or not.
; The underscore character is defined as an alphabetic character.
;
;  IN:    A = ASCII byte
; OUT:    Fz = 1, if byte was alphabetic, otherwise Fz = 0
;
; Registers changed after return:
;
;    A.BCDEHL/IXIY  same
;    .F....../....  different
;
; ---------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ---------------------------------------------------------------------
;
.IsAlpha            CP   'z'
                    RET  NC                  ; byte >= 'z'
                    CP   'a'
                    JR   C, test_underscore
                    CP   A                   ; 'a' <= byte < 'z'
                    RET
.test_underscore    CP   '_'
                    RET  NC                  ; '_' <= byte < 'a'
                    CP   'Z'
                    RET  NC                  ; 'Z' <= byte < '_'
                    CP   'A'
                    RET  C                   ; byte < 'A', not alphabetic
                    CP   A                   ; 'A' <= byte < 'Z', alphabtic found
                    RET

     XLIB InvCase

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
; Invert character case to either upper or lower case.
;
;  IN:    A = ASCII byte
; OUT:    A = converted ASCII byte
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.InvCase            CP   '['       ; if A <= 'Z'  &&
                    JR   NC, check_lowercase
                    CP   'A'       ; if A >= 'A'
                    RET  C
                    XOR  32        ; inverse case...
                    RET
.check_lowercase    CP   '{'       ; if A <= 'z'  &&
                    JR   NC, check_latin1
                    CP   'a'       ; if A >= 'a'
                    RET  C
                    XOR  32        ; inverse case
                    RET
.check_latin1       CP   $FF       ; if A <= $FE  &&
                    RET  Z
                    CP   $C0       ; if A >= $C0
                    RET  C
                    XOR  32        ; then inverse case
                    RET

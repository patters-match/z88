     XLIB ToUpper

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************


; ******************************************************************************
;
; ToUpper - convert character to upper case if possible.
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
.ToUpper            CP   '{'       ; if A <= 'z'  &&
                    JR   NC, check_latin1
                    CP   'a'       ; if A >= 'a'
                    RET  C
                    SUB  32        ; then A = A - 32
                    RET
.check_latin1       CP   $FF       ; if A <= $FE  &&
                    RET  Z
                    CP   $E1       ; if A >= $E1
                    RET  C
                    SUB  32        ; then A = A - 32
                    RET

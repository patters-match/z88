     XLIB Bind_bank_s1

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
;    Bind bank, defined in A, into segment 1. Return old bank binding in A.
;    This is the functional equivalent of OS_MPB, but much faster.
;
;    Register affected on return:
;         ..BCDEHL/IXIY
;         AF....../.... af
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Bind_bank_s1       PUSH BC
                    LD   B,A
                    EX   AF,AF'
                    LD   A,($04D1)
                    CP   B
                    POP  BC
                    RET  Z                   ; bank already bound into segment
                    PUSH AF
                    EX   AF,AF'
                    LD   ($04D1),A
                    OUT  ($D1),A
                    POP  AF
                    RET

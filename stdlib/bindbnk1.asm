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
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; ***************************************************************************************************


; ***************************************************************************************************
;
;    Bind bank, defined in A, into segment 1. Return old bank binding in A, Fz = ?, Fc = 0
;    This is the functional equivalent of OS_MPB, but much faster.
;
;    Register affected on return:
;         ..BCDEHL/IXIY
;         AF....../.... af
;
; ----------------------------------------------------------------------
; Design & programming by Copyright (C) Gunther Strube 1995,2017
; ----------------------------------------------------------------------
;
.Bind_bank_s1       EX   AF,AF'
                    LD   A,($04D1)           ; get old binding in A'
                    EX   AF,AF'
                    LD   ($04D1),A
                    OUT  ($D1),A             ; new binding with Bank A(IN)
                    EX   AF,AF'              ; return old binding
                    OR   A                   ; always return Fc = 0
                    RET

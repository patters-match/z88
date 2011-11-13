     XLIB MemGetCurrentSlot

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

    LIB ApplSegmentMask, MemGetBank

; ***************************************************************************************************
;
; Get current slot number of this executing library routine, returned in C.
; This routine is used by an application to determine in which slot it is running.
;
;    Register affected on return:
;         AFB.DEHL/IXIY same
;         ...C..../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, September 2005
; ----------------------------------------------------------------------
;
.MemGetCurrentSlot  push af

                    call ApplSegmentMask     ; get MM_Sx of this executing code
                    rlca
                    rlca
                    ld   c,a                 ; convert to segment specifier (0-3)
                    push bc                  ; preserve B (from application caller)
                    call MemGetBank
                    ld   a,b
                    and  @11000000           ; preserve only slot mask of bank number
                    rlca
                    rlca                     ; slot mask -> slot number
                    pop  bc
                    ld   c,a                 ; return slot number of executing code

                    pop  af
                    ret

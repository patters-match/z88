     XLIB pointxy

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

     LIB pixeladdress

; ******************************************************************
;
; Check if pixel at (x,y) coordinate is set or not.
;
; (0,0) origin is defined as the bottom left corner.
;
;  in:    hl = (x,y) coordinate of pixel to test
; out:    Fz = 0, if pixel is set, otherwise Fz = 1.
;
; registers changed after return:
;  ..bcdehl/ixiy same
;  af....../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.pointxy            push bc
                    push de
                    push hl
                    ld   a,l
                    xor  @00111111           ; (0,0) is hardware (0,63)
                    ld   l,a

                    call pixeladdress
                    ld   b,a
                    ld   a,1
                    jr   z, test_pixel       ; pixel is at bit 0...
.pixel_position     rlca
                    djnz pixel_position
.test_pixel         ex   de,hl
                    and  (hl)
                    pop  hl
                    pop  de
                    pop  bc
                    ret

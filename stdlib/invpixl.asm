     XLIB invpixel

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

     LIB pixeladdress
     XREF COORDS

; ******************************************************************
;
; Inverse pixel at (x,y) coordinate
;
; in:  hl = (x,y) coordinate of pixel (h,l)
;
; registers changed after return:
;  ..bc..../ixiy same
;  af..dehl/.... different
;
; ---------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ---------------------------------------------------------------------
;
.invpixel           ld   a,l
                    cp   64
                    ret  nc                  ; y0 out of range...

                    push bc
                    ld   (COORDS),hl         ; save new plot coordinate
                    ld   a,l
                    xor  @00111111           ; (0,0) is hardware (0,63)
                    ld   l,a
                    call pixeladdress
                    ld   b,a
                    ld   a,1
                    jr   z, xor_pixel
.inv_position       rlca
                    djnz inv_position
.xor_pixel          ex   de,hl
                    xor  (hl)
                    ld   (hl),a
                    pop  bc
                    ret

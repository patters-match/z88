     XLIB pixeladdress

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

     XREF base_graphics


; ******************************************************************
;
; Get absolute pixel address in map of virtual (x,y) coordinate.
;
; in:  hl = (x,y) coordinate of pixel (h,l)
;
; out: de = address of pixel byte
;       a = bit number of byte where pixel is to be placed
;      fz = 1 if bit number is 0 of pixel position
;
; registers changed after return:
;  ......hl/ixiy same
;  afbcde../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.pixeladdress       ld   b,l
                    srl  b
                    srl  b
                    srl  b                   ; linedist = y div 8 * 256
                    ld   a,h
                    and  @11111000           ; rowdist = x div 8 * 8
                    ld   c,a                 ; bc = linedist + rowdist
                    ld   a,l
                    and  @00000111           ; coldist = y mod 8
                    ld   de,(base_graphics)  ; pointer to base of graphics area
                    ld   e,a                 ; coldist = graphicsarea + coldist
                    ld   a,h
                    ex   de,hl
                    add  hl,bc               ; bytepos = linedist + rowdist + coldist
                    ex   de,hl
                    and  @00000111           ; a = x mod 8
                    xor  @00000111           ; a = 7 - a
                    ret

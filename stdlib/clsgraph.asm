     XLIB cleargraphics

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

     XREF base_graphics


; ******************************************************************
;
; Clear graphics area, i.e. reset all bits in graphics (map)
; window of width L x 64 pixels.
;
; IN:
;    L = width of map area (modulus 8).
;
; OUT:
;    None.
;
;    Registers changed after return:
;         a.bcdehl/ixiy  same
;         .f....../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995-98
; ----------------------------------------------------------------------
;
.cleargraphics      push bc
                    push de
                    push hl

                    push af
                    ld   h,0
                    ld   a,@11111000         ; only width of modulus 8
                    and  l
                    ld   l,a
                    pop  af

                    add  hl,hl
                    add  hl,hl
                    add  hl,hl
                    dec  hl                  ; <width> * 64 / 8 - 1 bytes to clear..
                    ld   b,h
                    ld   c,l                 ; total of bytes to reset...

                    ld   hl,(base_graphics)  ; base of graphics area
                    ld   (hl),0
                    ld   d,h
                    ld   e,1                 ; de = base_graphics+1
                    ldir                     ; reset graphics window (2K)
                    pop  hl
                    pop  de
                    pop  bc
                    ret

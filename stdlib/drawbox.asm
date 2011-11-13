     xlib drawbox

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
;***************************************************************************************************

     lib  setxy, line_r

     
; ******************************************************************
;
; Draw box in graphics window. The box is only drawn inside the
; boundaries of the graphics area.
;
;    In:  hl = (x,y)
;         bc = width, height
;         ix = pointer to plot routine
;
;    Out: None.
;
;    Registers changed after return:
;         afbcdehl/ixiy  same
;         ......../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.drawbox            push af
                    push de
                    push hl
                    call setxy          ; set graphics coordinate

                    ld   h,0
                    ld   l,b
                    dec  hl             ; first plot after (x,y), width-1
                    ld   de,0           ; drawline(width-1, 0)
                    call line_r
                    ld   hl,0
                    ld   d,0
                    ld   e,c
                    cp   a
                    sbc  hl,de
                    ex   de,hl
                    inc  de
                    ld   hl,0           ; drawline(0, -heigth+1)
                    call line_r
                    ld   hl,0
                    ld   d,0
                    ld   e,b
                    cp   a
                    sbc  hl,de
                    inc  hl             ; -width-1
                    ld   de,0
                    call line_r         ; drawline(-width+1, 0)
                    ld   hl,0
                    ld   d,0
                    ld   e,c
                    dec  de
                    call line_r         ; drawline(0, height-1)

                    pop  hl
                    pop  de
                    pop  af
                    ret

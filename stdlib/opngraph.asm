     XLIB opengraphics

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

     include "memory.def"
     include "map.def"
     include "screen.def"


; *****************************************************************************
;
;    Open graphics window, static size of <Width> x 64 pixels, and bind graphics
;    memory into specified address space segment.
;
;    The Width specifier defines the map width in modulus 8 pixels, 
;    ie. 8, 16, 24, 32, 40, 48, 56, 64 ...
;
;    This routine must be called before using any library graphics routines,
;    since they expect the graphics memory to be available through the
;    <base_graphics> pointer.
;
;    Using this routine in combination width the std. graphics routines, the
;    map width must be defines as 256.
;
;    in:  A = window ID ('1' to '6')
;         L = width of map (modulus 8)
;         B = MM_Sx mask (for segment 0, 1, 2 or 3)
;
;    out: (base_graphics) contains pointer to base of graphics area.
;         Further, the graphics area is bound into the segment specified
;         by the input B register.
;
;    registers changed after return:
;         afbcdehl/ixiy  same
;         ......../....  different
;
; -------------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995-98
; -------------------------------------------------------------------------
;
.opengraphics       push hl
                    push de
                    push bc
                    push af

                    push bc
                    ld   bc, mp_gra
                    push af
                    ld   h,0
                    ld   a,l
                    and  @11111000      ; width always in 8 bit size...
                    dec  a              ; always one less than actual width...
                    ld   l,a            ; HL now the map width...
                    pop  af
                    call_oz(os_map)          ; create map width of 256 pixels
                    ld   b,0
                    ld   hl,0                ; dummy address
                    ld   a,sc_hr0
                    call_oz(os_sci)          ; get base address of map area (hires0)
                    push bc
                    push hl
                    call_oz(os_sci)          ; (and re-write original address)
                    pop  hl
                    pop  bc
                    pop  de
                    ld   c,d
                    rlc  c
                    rlc  c                   ; convert MM_Sx to MS_Sx segment specifier
                    call_oz(os_mpb)          ; bind hires0 memory into specified segment
                    ld   a,h
                    and  @00111111
                    or   d
                    ld   h,a                 ; base of graphics points at segment
                    ld   (base_graphics),hl  ; initialize base address of hires0

                    pop  af
                    pop  bc
                    pop  de
                    pop  hl
                    ret

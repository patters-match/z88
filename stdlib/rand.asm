     xlib randomize

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

     xref SEED

     include "fpp.def"


; *****************************************************************
;
; Initiate randomize sequense
;
; IN:  BC = seed
; OUT: None.
;
; If <seed> is 0, then a seed is created from the Z88 clock.
;
; Registers changed after return:
;   AF..DEHL/IXIY same
;   ..BC..../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Randomize          push af
                    ld   a,b
                    or   c
                    jr   z, get_seed
                    ld   (SEED),bc
                    pop  af
                    ret
.get_seed           ld   c,$d0
                    in   a,(c)               ; low byte of seed is 1/1000 sec.
                    inc  c
                    in   b,(c)               ; high byte of seed is 1/60 min.
                    ld   c,a
                    ld   (SEED),bc           ; new seed
                    pop  af
                    ret

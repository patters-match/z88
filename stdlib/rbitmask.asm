     xlib rightbitmask

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


; ************************************************************************
;
; Get right bitmask for rigth side of byte to preserve during clear
;
; IN: A = bitposition
;
; OUT: A = bitmask at right side of bit position of byte
;
;    Example:
;              IN:  A = 6
;              OUT: A = @00111111  (bit 5 - 0 as mask)
;
;    registers chnaged after return:
;         ..bcdehl/ixiy  same
;         af....../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.rightbitmask       cp  0               ; 7-bitpos
                    ret  z              ; no bitmask to preserve...
                    push bc
                    ld   b,a
                    xor  a
.right_bitmask_loop scf
                    rla                 ; create right bitmask
                    djnz right_bitmask_loop
                    pop  bc
                    ret

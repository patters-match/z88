     xlib memcpy

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

     lib read_byte, set_byte


; *******************************************************************************
;
;    Copy memory block from extended address to extended address.
;
;    Both pointers must be resident in a segment 1 bank (from an OS_MAL).
;
;    IN:  A = total of bytes to copy
;         BHL = pointer to source string
;         CDE = pointer to destination
;
;    OUT: None.
;
;    Registers changed after return:
;         AFBCDEHL/IXIY  same
;         ......../....  different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ------------------------------------------------------------------------
;
.memcpy             exx
                    push bc
                    push de
                    push hl                  ; preserve alternate registers
                    exx

                    push af
                    push bc
                    push de
                    push hl
                    push bc
                    push de
                    exx
                    pop  hl
                    pop  bc
                    ld   b,c                 ; destination pointer in alternate BHL
                    exx

.memcpy_loop        push af                  ; preserve length counter
                    xor  a
                    call read_byte           ; get byte from source
                    inc  hl
                    exx
                    ld   c,a
                    xor  a
                    call set_byte            ; and put byte to destination
                    inc  hl
                    exx
                    pop  af
                    dec  a                   ; block copied?
                    jr   nz, memcpy_loop     ; no, continue with next byte from source...

                    pop  hl
                    pop  de                  ; destination pointer restored
                    pop  bc                  ; source pointer restored
                    pop  af
                    exx
                    pop  hl
                    pop  de
                    pop  bc                  ; alternate registers restored
                    exx
                    ret

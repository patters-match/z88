     xlib rnd

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

     xref seed

     include "fpp.def"

; *****************************************************************
;
; Get a random number [0; 1]. Algorithm based on ZX SPECTRUM code!
;
; IN:  None.
; OUT: HLhlC = random number
;
; Registers changed after return:
;   AF....../IXIY ........ same
;   ..BCDEHL/.... afbcdehl different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.rnd                push af
                    ld   bc,0
                    ld   de,0
                    ld   hl,0
                    exx
                    ld   hl,(SEED)
                    inc  hl                                 ; SEED+1
                    ld   de,75
                    exx
                    fpp(FP_MUL)                             ; (SEED+1)*75
                    ld   b,0
                    ld   de,1
                    exx
                    ld   de,1                               ; DEdeB = 65537
                    exx
                    fpp(FP_MOD)                             ; ((SEED+1)*75) MOD 65537
                    exx
                    dec  hl
                    ld   (SEED),hl                          ; SEED = (((SEED+1)*75) MOD 65537)-1
                    ld   de,0
                    exx                                     ; HLhlC = SEED
                    ld   b,0
                    ld   de,1                               ; DEdeB = 65536
                    fpp(FP_DIV)
                    pop  af                                 ; HLhlC = SEED/65536
                    ret

     xlib turnto

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

     xref HEADING

     include "fpp.def"


; ****************************************************************************
;
; Move turtle heading in absolute degrees.
;
; IN:     HL = absolute heading in degrees
; OUT:    None.
;
;    Registers affected after return:
;         AFBCDEHL/IXIY  same
;         ......../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.turnto             push af
                    push bc
                    push de
                    push hl

                    exx
                    ld   c,0
                    ld   hl,0
                    fpp(FP_ABS)              ; absolute heading always positive
                    ld   b,0
                    ld   de,0
                    exx
                    ld   de,360
                    exx
                    fpp(FP_MOD)              ; degrees always modululus 360...
                    exx
                    ld   (HEADING),hl        ; new heading in absolute degrees...
                    exx

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret

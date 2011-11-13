     XLIB EnableBlinkInt

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

     INCLUDE "blink.def"


; ***************************************************************************
;
; Enable interrupts getting out of Blink
;
; IN:
;    -
;
; OUT:
;    -
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.EnableBlinkInt     push af
                    push bc
                    ld   bc,BLSC_INT
                    ld   a,(bc)
                    set  BB_INTGINT,a
                    ld   (bc),a                   ; (update soft copy first)
                    out  (c),a                    ; interrupts allowed to get out of blink (GINT = 1)
                    pop  bc
                    pop  af
                    ret

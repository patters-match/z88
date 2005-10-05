     XLIB DisableBlinkInt

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

     INCLUDE "blink.def"


; ***************************************************************************
;
; Disable Interrupts getting out of Blink
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
.DisableBlinkInt    push af
                    push hl
                    ld   hl,BLSC_INT
                    res  BB_INTGINT,(hl)          ; (update soft copy first)
                    ld   a,(hl)
                    out  (BL_INT),a               ; no interrupts get out of blink (GINT = 0)
                    pop  hl
                    pop  af
                    RET

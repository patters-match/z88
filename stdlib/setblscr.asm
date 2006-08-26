     XLIB SetBlinkScreen

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
; ***************************************************************************************************

     INCLUDE "blink.def"

     XDEF SetBlinkScreenOn

; ***************************************************************************************************
; Switch Z88 LCD Screen On or Off.
;
; In:
;    Fz = 1, Turn LCD screen On
;    Fz = 0, Turn LCD screen Off
;
; Out:
;    None
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Aug 2006
; ------------------------------------------------------------------------
;
.SetBlinkScreen     PUSH AF
                    PUSH BC
                    LD   BC,BLSC_COM         ; Address of soft copy of COM register
                    LD   A,(BC)
                    RES  BB_COMLCDON,A       ; Screen LCD Off by default
                    CALL Z, lcdon            ; but caller wants to switch On...
                    LD   (BC),A
                    OUT  (C),A               ; signal to Blink COM register to do the LCD...
                    POP  BC
                    POP  AF
                    RET
.lcdon              SET  BB_COMLCDON,A       ; Screen LCD On
                    RET

.SetBlinkScreenOn                            ; Public routine to enable LCD without specifying parameters.
                    PUSH AF
                    CP   A
                    CALL SetBlinkScreen
                    POP  AF
                    RET
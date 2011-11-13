     XLIB GetBlinkScreen

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
; ***************************************************************************************************

     INCLUDE "blink.def"

; ***************************************************************************************************
; Get Display status of Z88 screen.
;
; In:
;    None.
; Out:
;    Fz = 1, LCD screen turned Off
;    Fz = 0, LCD screen turned On
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Aug 2006
; ------------------------------------------------------------------------
;
.GetBlinkScreen     PUSH HL
                    LD   HL,BLSC_COM         ; Address of soft copy of COM register
                    BIT  BB_COMLCDON,(HL)
                    POP  HL
                    RET

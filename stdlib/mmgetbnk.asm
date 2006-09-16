     XLIB MemGetBank

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

; ***************************************************************************************************
;
; Get current Bank binding for specified segment, defined in C.
; This is the functional equivalent of OS_MGB, but much faster.
;
;    Register affected on return:
;         AF.CDEHL/IXIY same
;         ..B...../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1997, 2006
; ----------------------------------------------------------------------
;
.MemGetBank         PUSH AF
                    PUSH HL

                    LD   HL,BLSC_SR0         ; base of SR0 - SR3 soft copies
                    LD   A,C                 ; get segment specifier (MS_Sx)
                    AND  @00000011           ; preserve only segment specifier...
                    OR   L
                    LD   L,A                 ; HL points at Blink soft copy of current binding in segment C
                    LD   B,(HL)              ; get current bank binding

                    POP  HL
                    POP  AF
                    RET

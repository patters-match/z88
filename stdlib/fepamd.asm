     XLIB AM29Fx_InitCmdMode

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

; AM29Fx_InitCmdMode
;     from the OZ 5.0 code (in os/kn1/osfep/osfep.asm)
;
; ***************************************************************************************************
; Prepare AMD 29F/39F Command Mode sequence addresses.
;
; In:
;       HL points into bound bank of Flash Memory
; Out:
;       BC = bank select sw copy address
;       DE = address $2AAA + segment  (derived from HL)
;       HL = address $1555 + segment  (derived from HL)
;
; Registers changed on return:
;    AF....../IXIY same
;    ..BCDEHL/.... different
;
.AM29Fx_InitCmdMode
                    PUSH AF
                    LD   A,H
                    AND  @11000000
                    LD   D,A
                    LD   BC,BLSC_SR0
                    RLCA
                    RLCA
                    OR   C
                    LD   C,A                             ; BC = bank select sw copy address
                    LD   A,D
                    OR   $15
                    LD   H,A
                    LD   L,$55                           ; HL = address $1555 + segment
                    LD   A,D
                    OR   $2A
                    LD   D,A
                    LD   E,$AA                           ; DE = address $2AAA + segment
                    POP  AF
                    RET
                    ; end AM29Fx_InitCmdMode

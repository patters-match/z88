     XLIB AddPointerDistance

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB ConvPtrToAddr, ConvAddrToPtr


; **************************************************************************
;
; Add distance CDE (24bit integer) to current pointer address BHL
;
; A new pointer is returned in BHL, preserving original
; slot mask and segment mask.
;
; This routine is primarily used for File Eprom management.
;
; Registers changed after return:
;    AF.CDE../IXIY same
;    ..B...HL/.... different
;
; --------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997
; --------------------------------------------------------------------------
;
.AddPointerDistance
                    PUSH AF
                    PUSH DE

                    LD   A,C
                    PUSH AF                  ; preserve C register

                    LD   A,H
                    AND  @11000000
                    PUSH AF                  ; preserve segment mask
                    RES  7,H
                    RES  6,H

                    LD   A,B
                    AND  @11000000
                    PUSH AF                  ; preserve slot mask
                    RES  7,B
                    RES  6,B

                    LD   A,C
                    PUSH DE                  ; preserve distance in ADE

                    CALL ConvPtrToAddr       ; BHL -> DEBC address

                    POP  HL
                    ADD  HL,BC
                    LD   B,H
                    LD   C,L
                    ADC  A,E                 ; distance added to DEBC,
                    LD   E,A                 ; result in DEBC, new abs. address

                    CALL ConvAddrToPtr       ; new abs. address to BHL logic...

                    POP  AF
                    OR   B
                    LD   B,A                 ; slot mask restored in bank number

                    POP  AF
                    OR   H
                    LD   H,A                 ; segment mask restored in offset

                    POP  AF
                    LD   C,A                 ; C register restored

                    POP  DE
                    POP  AF
                    RET

     XLIB PointerNextByte

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


; ****************************************************************************
;
; Update extended address to point at next physical address on Eprom (or RAM)
; If the offset address crosses a bank boundary, the bank number is
; increased to use the next, adjacent bank, and the offset is positioned
; at the start of the bank.
;
; This routine is primarily used for File Eprom management.
;
; IN:
;    BHL = ext. address
;
; OUT:
;    BHL++
;
; Registers changed after return:
;    AF.CDE../IXIY same
;    ..B...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997
; ------------------------------------------------------------------------
;
.PointerNextByte
                    PUSH AF
                    LD   A,H
                    AND  @11000000
                    PUSH AF                  ; preserve segment mask of offset

                    RES  7,H
                    RES  6,H
                    INC  HL                  ; ptr++
                    BIT  6,H                 ; crossed bank boundary?
                    JR   Z, not_crossed      ; no, offset still in current bank
                    INC  B
                    RES  6,H                 ; yes, HL = 0, B++
.not_crossed
                    POP  AF
                    OR   H
                    LD   H,A
                    POP  AF
                    RET

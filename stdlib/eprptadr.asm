     XLIB ConvPtrToAddr

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


; ***************************************************************************
;
; Convert relative pointer BHL (B = 00h - 3Fh, HL = 0000h - 3FFFh)
; to absolute 20bit 1MB address.
;
; This routine primarily used for File Eprom Management.
;
; IN:
;    BHL = pointer
;
; OUT:
;    DEBC = 32bit integer (actually 24bit)
;
; Registers changed after return:
;    AF....HL/IXIY same
;    ..BCDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997
; ------------------------------------------------------------------------
;
.ConvPtrToAddr      PUSH AF
                    PUSH HL
                    LD   D,0
                    LD   E,B
                    LD   BC,0
                    SRA  E
                    RR   B
                    SRA  E
                    RR   B
                    ADD  HL,BC               ; DEBC = <BankNumber> * 16K + offset
                    LD   B,H
                    LD   C,L                 ; DEBC = BHL changed to absolute address in Eprom
                    POP  HL
                    POP  AF
                    RET

     XLIB ConvAddrToPtr

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


; ***************************************************************************
;
; Convert 1MB 20bit address to relative pointer in BHL
; (B = 00h - 3Fh, HL = 0000h - 3FFFh).
;
; This routine is primarily used File Eprom management
;
; IN:
;    EBC = 24bit integer (actually 20bit 1MB address)
;
; OUT:
;    BHL = pointer
;
; Registers changed after return:
;    AF.CDE../IXIY same
;    ..B...HL/.... different
;
; --------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997
; --------------------------------------------------------------------------
;
.ConvAddrToPtr
                    PUSH AF
                    LD   A,B
                    AND  @11000000
                    LD   H,B
                    RES  7,H
                    RES  6,H
                    LD   L,C                 ; OFFSET READY...

                    LD   B,E                 ; now divide top 6 address bit with 16K
                    SLA  A                   ; and place it into B (bank) register
                    RL   B
                    SLA  A
                    RL   B
                    POP  AF
                    RET                      ; BHL now (relative) ext. address

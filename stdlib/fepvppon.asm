     XLIB FlashEprVppOn

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

     LIB SafeSegmentMask, MemWriteByte

     DEFC VppBit = 1

     include "interrpt.def"
     include "flashepr.def"

; ***************************************************************************
;
; Set Flash Eprom chip in programming mode
;
; 1) set Vpp (12V) on
; 2) clear the chip status register
;
; IN:
;         -
; OUT:
;         -
;
; Registers changed on return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
; --------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997
;    Thierry Peycru, Zlab, Dec 1997
; --------------------------------------------------------------------------
;
.FlashEprVppOn      PUSH AF
                    PUSH BC
                    PUSH HL

                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  VppBit,A            ; Vpp On
                    LD   (BC),A
                    OUT  (C),A               ; Enable Vpp in slot 3

                    CALL SafeSegmentMask     ; Get a safe segment address mask
                    LD   H, A
                    LD   L, 0                ; Pointer at beginning of segment
                    LD   B, $C0              ; A bank of slot 3...

                    LD   C, FE_CSR
                    XOR  A
                    CALL MemWriteByte        ; Clear Chip Status register

                    POP  HL
                    POP  BC
                    POP  AF
                    RET

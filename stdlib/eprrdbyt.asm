     XLIB FileEprReadByte

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

     LIB MemReadByte
     LIB PointerNextByte


; ****************************************************************************
;
; Read byte at BHL Eprom address, returned in A.
; Increment pointer to next Eprom address
;
; This is used as internal support routine for high level library functions.
;
; IN:
;    BHL = pointer, B = absolute bank number
;
; OUT:
;         A = byte at old (BHL)
;         BHL points at next byte in Eprom
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
.FileEprReadByte    XOR  A
                    CALL MemReadByte
                    CALL PointerNextByte
                    RET

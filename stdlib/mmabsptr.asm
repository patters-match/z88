     XLIB MemAbsPtr

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

     LIB SafeSegmentMask

; ************************************************************************
;
; Convert relative BHL pointer for slot number A (0 to 3) to absolute
; pointer, addressed for safe bank binding segment.
;
; Internal Support Library Routine.
;
; IN:
;    A = slot number (0 to 3)
;    BHL = relative pointer 
;
; OUT:
;    BHL pointer, absolute addressed for physical slot C, and specific segment.
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, April 1998
; ----------------------------------------------------------------------
;
.MemAbsPtr
                    AND  @00000011                ; only 0 - 3 allowed...
                    RRCA                          ;
                    RRCA                          ; Slot number A converted to slot mask
                    RES  7,B
                    RES  6,B                      ; clear before masking to assure proper effect...
                    OR   B
                    LD   B,A                      ; B = converted to physical bank of slot A
                    CALL SafeSegmentMask          ; Get a safe segment address mask
                    RES  7,H
                    RES  6,H
                    OR   H                        ; for bank I/O (outside this executing code)
                    LD   H,A                      ; offset mapped for specific segment
                    RET

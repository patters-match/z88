     XLIB SafeSegmentMask

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

     LIB ApplSegmentMask

     include "memory.def"

; ********************************************************************
;
; This library routine returns a complement segment mask
; that's outside the scope of the executing code (in a bound bank).
;
; The sole purpose of this is for the application to
; determine another segment than which the application executes in
; at this point of call (the current segment of the PC), to be
; used for reading extended pointer information without swapping
; out the executing program, resided in a potential identical segment.
;
;    In:
;         None
;    Out:
;         A = Safe MM_Sx, but never in segment 0.
;
;    Registers changed after return:
;         ..BCDEHL/IXIY same
;         AF....../...  different
;
.SafeSegmentMask    CALL ApplSegmentMask     ; get MM_Sx of this executing code
                    CPL
                    AND  @11000000           ; preserve only segment mask
                    OR   MM_S1               ; never to segment 0...
                    RET                      ; return safe MM_Sx segment mask

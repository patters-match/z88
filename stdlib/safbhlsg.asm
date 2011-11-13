     XLIB SafeBHLSegment

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

     LIB SafeSegmentMask

;***************************************************************************************************
;
; Prepare BHL extended pointer to be bound into a safe segment, when later using a OS_MPB
; system call or the faster MemDefBank library to bind the bank of the BHL pointer.
;
; This call is used just before binding a bank into the "free" segment.
;
; The sole purpose of this libarary is for the application to use another 
; segment than which the application executes in (at this point of call the 
; current segment of the PC), to be used for reading extended pointer 
; information without swapping out the executing program, resided in a 
; potential identical segment.
;
;    In:
;         -
;    Out:
;         C = Safe MS_Sx segment specifier, but never in segment 0.
;         H = Safe MM_Sx segment masked into HL bank offset pointer
;
;    Register affected on return:
;         AFB.DE.L/IXIY same
;         ...C..H./.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Sept. 2004
; ----------------------------------------------------------------------
;
.SafeBHLSegment
                    PUSH AF
                    CALL SafeSegmentMask          ; get a safe segment (not this executing segment!)
                    LD   C,A
                    RLC  C
                    RLC  C                        ; C = Safe MS_Sx segment for Bank B
                    RES  7,H
                    RES  6,H
                    OR   H
                    LD   H,A                      ; HL points into segment C
                    POP  AF
                    RET

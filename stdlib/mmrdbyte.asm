     XLIB MemReadByte

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

     LIB SafeBHLSegment, MemDefBank


; ******************************************************************************
;
; Read byte at pointer in BHL, offset A, returned in A.
;
;    Register affected on return:
;         ..BCDEHL/IXIY same
;         AF....../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1997, Sept. 2004
; ----------------------------------------------------------------------
;
.MemReadByte        PUSH HL
                    PUSH DE
                    PUSH BC

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; add offset to pointer

                    CALL SafeBHLSegment           ; get a safe segment (not this executing segment!)
                                                  ; C = Safe MS_Sx segment
                                                  ; HL points into segment C
                    CALL MemDefBank               ; page in bank B temporarily into segment C
                    LD   A,(HL)                   ; read byte at extended address
                    CALL MemDefBank               ; restore prev. binding

                    POP  BC
                    POP  DE
                    POP  HL
                    RET

     XLIB MemWriteLong

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
; Set long integer in debc (alternate), at pointer in BHL,A.
;
;    Register affected on return:
;         A.BCDEHL/IXIY same
;         .F....../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1995-98, Sept. 2004
; ----------------------------------------------------------------------
;
.MemWriteLong       
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; add offset to pointer

                    CALL SafeBHLSegment           ; get a safe segment (not this executing segment!)
                                                  ; C = Safe MS_Sx segment
                                                  ; HL points into segment C
                    CALL MemDefBank               ; page in bank temporarily
                    PUSH HL
                    EXX
                    POP  HL
                    LD   (HL),C                   ; write long at extended address
                    INC  HL
                    LD   (HL),B
                    INC  HL
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    EXX
                    CALL MemDefBank               ; restore prev. binding (original B register)

                    POP  HL
                    POP  DE
                    POP  BC
                    RET

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


;***************************************************************************************************
;
; Set long integer in de'bc' at base record pointer in BHL, offset A.
;
; If B<>0, the long integer is written to extended address.
; If B=0, the long integer is written to local address space.
;
;    Register affected on return:
;         A.BCDEHL/IXIY same
;         .F....../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1995-98, Sep 2004, Oct 2005
; ----------------------------------------------------------------------
;
.MemWriteLong
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; add offset to pointer

                    INC  B
                    DEC  B                        ; B<>0, then bind ext. address into local address space
                    CALL NZ,SafeBHLSegment        ; get a safe non-executing segment
                    CALL NZ,MemDefBank            ; page in bank at C = Safe MS_Sx segment,

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

                    CALL NZ,MemDefBank            ; restore previous bank binding

                    POP  HL
                    POP  DE
                    POP  BC
                    RET

     XLIB MemReadPointer

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
; Read pointer at record defined as (base) address in BHL, offset A.
; If B<>0, the (pointer) data is fetched at extended address.
; If B=0, the (pointer) data is fetched in local address space.
;
; Return (extended) pointer in BHL (bank,offset).
;
;    Register affected on return:
;         AF.CDE../IXIY same
;         ..B...HL/.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1997, Sept. 2004, Okt 2005
; ----------------------------------------------------------------------
;
.MemReadPointer     PUSH DE
                    PUSH AF
                    PUSH BC

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE               ; add offset to pointer
                    INC  B
                    DEC  B                   ; B<>0, then bind ext. address into local address space
                    CALL NZ,SafeBHLSegment   ; get a safe non-executing segment
                    CALL NZ,MemDefBank       ; page in bank at C = Safe MS_Sx segment,
                    LD   E,(HL)              ; HL points into segment C
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    LD   A,(HL)
                    EX   DE,HL               ; extended pointer in AHL
                    CALL NZ,MemDefBank       ; restore previous bank binding

                    POP  BC
                    LD   B,A                 ; return fetched BHL pointer
                    POP  AF
                    POP  DE
                    RET

     XLIB MemWritePointer

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

     LIB SafeBHLSegment, MemDefBank


;***************************************************************************************************
;
; Set pointer in CDE, at record base pointer BHL, offset A.
;
; If B<>0, the (pointer) data is written at extended address.
; If B=0, the (pointer) data is written in local address space.
;
;    Register affected on return:
;         A.BCDEHL/IXIY same
;         .F....../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1995-98, Sep 2004, Oct 2005
; ----------------------------------------------------------------------
;
.MemWritePointer    PUSH HL
                    PUSH DE
                    PUSH BC

                    PUSH DE
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; add offset to pointer
                    POP  DE

                    INC  B
                    DEC  B                        ; B<>0, then bind ext. address into local address space
                    CALL NZ,SafeBHLSegment        ; get a safe non-executing segment
                    CALL NZ,MemDefBank            ; page in bank at C = Safe MS_Sx segment,

                    LD   (HL),E                   ; write word at extended address
                    INC  HL
                    LD   (HL),D
                    INC  HL
                    POP  DE
                    LD   (HL),E                   ; C (write bank specifier of pointer CDE)

                    CALL NZ,MemDefBank            ; restore previous bank binding

                    LD   C,E                      ; original BC restored
                    POP  DE
                    POP  HL
                    RET

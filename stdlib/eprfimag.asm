     XLIB FileEprFileImage

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
     
     LIB FileEprRequest
     LIB FileEprFileEntryInfo
     LIB AddPointerDistance

     INCLUDE "error.def"
     INCLUDE "memory.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to start of file image of File Entry at BHL, slot C
; (B=00h-3Fh, HL=0000h-3FFFh)
;
; IN:
;    C = slot number containing File Eprom Area
;    BHL = pointer to Eprom File Entry
;
; OUT:
;    Fc = 0, File Eprom available, File Entry available
;         BHL = pointer to start of file image (relative bank, offset)
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot C, or File Entry not available
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
.FileEprFileImage   PUSH DE
                    PUSH AF
                    PUSH BC

                    PUSH BC
                    PUSH HL                       ; preserve ptr to File Entry
                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    LD   D,L
                    POP  HL
                    POP  BC
                    JR   C,no_entry
                    JR   NZ,no_entry              ; File Eprom not available in slot...

                    LD   A,E
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    LD   B,A                      ; bank in slot C...
                    RES  7,H
                    SET  6,H                      ; (offset bound into segment 1 temporarily)

                    PUSH BC
                    PUSH HL                       ; preserve pointer to File Entry
                    CALL FileEprFileEntryInfo
                    POP  HL
                    POP  BC

                    JR   C, no_entry              ; No files are present on File Eprom...

                    INC  A                        ; length of filename + length byte
                    ADD  A,4                      ; + 4 bytes (32bit integer containing file size)

                    LD   C,0
                    LD   D,C
                    LD   E,A
                    CALL AddPointerDistance       ; BHL = start of file image...

                    RES  7,B
                    RES  6,B
                    RES  7,H
                    RES  6,H                      ; return relative pointer...

                    POP  DE
                    LD   C,E                      ; original C register restored
                    POP  DE
                    LD   A,D                      ; original A restored...
                    POP  DE                       ; original DE restored
                    RET

.no_entry           POP  DE
                    LD   C,E                      ; original C register restored
                    POP  DE                       ; old AF...
                    SCF
                    LD   A, RC_Onf                ; return error code "Object not found"
                    POP  DE
                    RET

     XLIB FileEprNextFile

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

     LIB FileEprFileEntryInfo

     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return next file entry pointer on Standard File Eprom, inserted in slot C
; (B=00h-3Fh, HL=0000h-3FFFh).
;
; IN:
;    C = slot number containing File Eprom
;    BHL = pointer to File Entry
;
; OUT:
;    Fc = 0, File Eprom available
;         BHL = pointer to next file entry (B=00h-3Fh, HL=0000h-3FFFh).
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot C, or File Entry not available
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; -----------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; -----------------------------------------------------------------------
;
.FileEprNextFile    PUSH DE
                    PUSH AF

                    LD   A,C
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B                        ; bank in slot C
                    LD   B,A
                    RES  7,H
                    SET  6,H                      ; BHL adjusted for slot C and segment 1

                    PUSH BC
                    CALL FileEprFileEntryInfo
                    LD   A,B

                    POP  BC                       ; original C register restored
                    LD   B,A
                    JR   C, no_entry              ; No files are present on File Eprom...

                    RES  7,B
                    RES  6,B
                    RES  7,H
                    RES  6,H                      ; pointer to next file entry (standard notation)

                    POP  DE
                    LD   A,D                      ; original A restored...
                    POP  DE                       ; original DE register restored
                    RET
.no_entry           
                    SCF
                    LD   A, RC_Onf
                    POP  DE                       ; ignore old AF
                    POP  DE                       ; original DE register restored
                    RET

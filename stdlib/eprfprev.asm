     XLIB FileEprPrevFile

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

     LIB FileEprFirstFile, FileEprNextFile
     LIB FileEprFileEntryInfo

     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to previous file entry on Standard File Area.
;
; IN:
;    BHL = pointer to current file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry is active.
;         BHL = pointer to previous file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or current File entry was the first
;         File Entry (an attempt was made to go beyond the bottom of the file area)
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 2004
; ------------------------------------------------------------------------
;
.FileEprPrevFile    PUSH DE
                    PUSH AF
                    PUSH BC                     ; preserve A & CDE

                    PUSH HL
                    LD   A,B
                    AND  @11000000              ; slots (0), 1, 2 or 3 possible
                    RLCA
                    RLCA                        ; Bank number of BHL converted to slot number 0-3.
                    LD   C,A                    ; C = slot number
                    CALL FileEprFirstFile       ; Get first file entry in File Area
                    JR   C, no_entry            ; no File Area!

                    POP  DE
                    LD   A,B
                    POP  BC
                    PUSH BC
                    LD   C,B                    ; first file entry in BHL,
                    LD   B,A                    ; current file entry (lib routine argument) in CDE

                    CP   C
                    JR   NZ, scan_filearea
                    PUSH HL
                    SBC  HL,DE
                    POP  HL
                    JR   Z, no_entry            ; BHL lib routine argument was the first file entry!
                    JR   scan_filearea
.get_next_entry
                    POP  AF
                    POP  AF                     ; get rid of old file entry
.scan_filearea
                    PUSH BC
                    PUSH HL                     ; preserve current File Entry
                    CALL FileEprNextFile        ; get next file entry in BHL
                    JR   C, invalid_entry

                    LD   A,B
                    CP   C
                    JR   NZ, get_next_entry
                    PUSH HL
                    SBC  HL,DE
                    POP  HL
                    JR   NZ, get_next_entry

                    POP  HL                     ; scanning found current File Entry (lib routine argument)
                    POP  BC                     ; get 'previous' entry in BHL and return that to caller
                    PUSH BC
                    PUSH HL
                    CALL FileEprFileEntryInfo   ; get File Status of Previous File Entry...
                    POP  HL
                    POP  BC

                    POP  DE                     ; BHL = pointer to previous File Entry, Fz = file status
                    LD   C,E                    ; original C restored
                    POP  DE                     ; original DE restored
                    LD   A,D                    ; original A restored
                    POP  DE
                    RET
.invalid_entry
                    POP  AF
                    POP  AF
.no_entry
                    SCF
                    LD   A, RC_Onf                ; "Object not found"
                    POP  DE
                    LD   C,E                      ; original C register restored
                    POP  DE                       ; ignore original AF...
                    POP  DE
                    RET

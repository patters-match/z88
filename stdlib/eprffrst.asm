     XLIB FileEprFirstFile

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

     LIB FileEprRequest
     LIB FileEprNextFile
     LIB FileEprFileEntryInfo

     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return first file entry pointer on Standard File Eprom, inserted in slot C.
;
; If the NULL file is identified as the first file, it is skipped and the next
; file entry pointer is automatically returned.
;
; IN:
;    C = slot number containing File Eprom
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry is active.
;         BHL = pointer to first file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
;         (NULL file skipped if found on Intel Flash Card)
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004, July 2005
; ------------------------------------------------------------------------
;
.FileEprFirstFile   PUSH DE
                    PUSH AF
                    PUSH BC                       ; preserve CDE

                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    JR   C,no_entry
                    JR   NZ,no_entry              ; File Eprom not available in slot...

                    LD   A,B
                    SUB  C                        ; C = total banks of File Eprom Area
                    INC  A
                    LD   B,A                      ; B is now bottom bank of File Eprom in slot C
                    LD   HL,$0000                 ; BHL points at first File Entry...
                    PUSH BC
                    PUSH HL
                    CALL FileEprFileEntryInfo
                    LD   A,C                      ; CDE = length of file entry
                    POP  HL
                    POP  BC
                    JR   C, no_entry              ; Ups - no File Entry found...
                    JR   NZ, end_FeFirstFile      ; first file is an active file...
                    OR   D
                    OR   E                        ; CDE = 0 means that NULL file is present.
                    JR   NZ, no_null_file
                    CALL FileEprNextFile          ; ignore NULL file, get pointer to next file (entry)
                    JR   end_FeFirstFile          ; get pointer to next file entry and return Fz status
.no_null_file
                    CP   A                        ; return Fz = 1, deleted file was not a Null file...
.end_FeFirstFile
                    POP  DE                       ; BHL = pointer to first File Entry
                    LD   C,E                      ; original C restored
                    POP  DE
                    LD   A,D                      ; original A restored
                    POP  DE
                    RET

.no_entry           SCF
                    LD   A, RC_Onf                ; "Object not found"
                    POP  DE
                    LD   C,E                      ; original C register restored
                    POP  DE                       ; ignore original AF...
                    POP  DE
                    RET

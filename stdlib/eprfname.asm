     XLIB FileEprFileName

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

     LIB FileEprRequest, FileEprFileEntryInfo
     LIB PointerNextByte, MemReadByte, FileEprReadByte

     INCLUDE "error.def"
     INCLUDE "memory.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return file name of File Entry at BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset) 
;
; IN:
;    DE = buffer to hold returned filename
;    BHL = pointer to Eprom File Entry in card at slot 
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry marked as active
;         A = length of filename
;         (DE) contains a copy of filename, null-terminated.
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF...../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004
; ------------------------------------------------------------------------
;
.FileEprFileName    PUSH DE
                    PUSH HL
                    PUSH BC                       ; preserve pointer

                    PUSH BC
                    PUSH DE                       ; preserve "to" pointer
                    PUSH HL                       ; preserve pointer to File Entry
                    CALL FileEprFileEntryInfo
                    POP  HL
                    POP  DE
                    POP  BC
                    JR   C, no_entry              ; No files are present on File Eprom...

                    CALL FetchFilename            ; copy filename into local buffer, null-terminated

                    POP  BC
                    POP  HL                       ; original pointer restored
                    POP  DE                       ; original buffer pointer restored
                    RET

.no_entry           LD   A, RC_Onf
                    POP  BC
                    POP  HL                       ; original pointer restored
                    POP  DE                       ; original buffer pointer restored
                    RET


; ************************************************************************
;
; Fetch filename at BHL, length C characters.
;
; IN:
;    A = length of filename
;    DE = buffer to hold returned filename
;    BHL = pointer to length byte of filename (start of File Entry)
;
; OUT:
;    Fc = 0, always.
;    (DE) contains a copy of filename, null-terminated, DE points at null.
;    BHL points at byte beyond filename (start of file length 32bit integer)
;    First char of filename always set to "/" (due to deleted filenames)
;
; Registers changed after return:
;    AF....../IXIY same
;    ..BCDEHL/.... different
;
.FetchFilename      PUSH AF

                    LD   C,A
                    LD   A,'/'
                    LD   (DE),A                   ; first character always "/"
                    INC  DE
                    DEC  C
                    CALL PointerNextByte          ; point at start of filename (of C length)
                    CALL PointerNextByte          ; point at first real character of filename

.flnm_loop          CALL FileEprReadByte          ; BHL++
                    LD   (DE),A
                    INC  DE                       ; bufptr++
                    DEC  C                        ; flnmlength--
                    JR   NZ,flnm_loop
                    XOR  A
                    LD   (DE),A                   ; null-terminate filename

                    POP  AF
                    RET

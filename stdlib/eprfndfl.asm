     XLIB FileEprFindFile

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
     LIB MemReadByte, FileEprReadByte
     LIB PointerNextByte
     LIB FileEprNextFile
     LIB ToUpper

     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Find active File(name) on Standard File Eprom in slot C.
;
; IN:
;    C = slot number of File Eprom (Area)
;    DE = pointer to null-terminated filename to be searched for.
;         The filename is excl. device name and must begin with '/'.
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry found.
;              BHL = pointer to File Entry in card at slot
;         Fz = 0, No file were found on the File Eprom.
;              BHL = pointer to free byte on File Eprom in slot
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found at slot C
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; -----------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004
; -----------------------------------------------------------------------
;
.FileEprFindFile    PUSH DE
                    PUSH AF
                    PUSH BC

                    PUSH DE                       ; preserve ptr to filename 
                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    LD   C,L
                    POP  HL
                    JR   C,no_eprom
                    JR   NZ,no_eprom              ; File Eprom not available in slot...

                    LD   C,E                 
                    LD   A,C
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    SUB  C                        ; C = total banks of File Eprom Area
                    INC  A
                    LD   B,A                      ; B is now bottom bank of File Eprom Area
                    EX   DE,HL                    ; DE points at local null-terminated filename
                    LD   HL, $0000                ; BHL points at first File Entry

.find_file          XOR  A
                    CALL MemReadByte
                    CP   $FF
                    JR   Z, finished              ; last File Entry was searched in File Eprom
                    CP   $00
                    JR   Z, finished              ; pointing at start of ROM header!
                    PUSH BC
                    PUSH HL
                    CALL PointerNextByte          ; BHL = beginning of filename
                    CALL CompareFilenames         ; found file in File Eprom?
                    POP  HL
                    POP  BC
                    JR   Z, file_found            ; Yes, return ptr. to current File Entry...

                    CALL FileEprNextFile          ; get pointer to next File Entry in slot C...
                    JR   find_file

.finished           OR   B                        ; Fc = 0, Fz = 0, File not found.
.file_found         
                    POP  DE
                    LD   C,E                      ; original C restored
                    POP  DE
                    LD   A,D                      ; original A restored
                    POP  DE
                    RET

.no_eprom           SCF
                    LD   A,RC_ONF
                    POP  BC
                    POP  BC                       ; ignore old AF...
                    POP  DE
                    RET


; ************************************************************************
;
; Compare filename (BHL) with (DE).
;
; IN:
;    A = length of filename at (BHL)
;    DE = local pointer to null-terminated filename
;
; OUT:
;    Fz = 1, filenames match (case independent comparison)
;    Fz = 0, filenames do not match
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.CompareFilenames   PUSH BC
                    PUSH AF
                    PUSH DE
                    PUSH HL

                    LD   C,A                      ; length of filename on Eprom...
.cmp_strings
                    CALL FileEprReadByte          ; get char from string <b>, BHL++
                    PUSH BC
                    CALL ToUpper                  ; Convert to Upper Case
                    LD   C,A                      ;
                    LD   A,(DE)
                    INC  DE                       ; DE++
                    CALL ToUpper
                    CP   C
                    POP  BC
                    JR   NZ, exit_strcompare      ; strings do not match...

                    DEC  C
                    JR   NZ, cmp_strings          ; continue until end of Eprom filename

                    LD   A,(DE)                   ; both string match so far...
                    OR   A                        ; string <a> must end now to match with string <b>...

.exit_strcompare    POP  HL                       ; original HL restored
                    POP  DE                       ; original DE restored
                    POP  BC
                    LD   A,B                      ; original A restored
                    POP  BC                       ; original BC restored
                    RET

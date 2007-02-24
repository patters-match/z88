        module FileEprNewFileEntry

; **************************************************************************************************
; File Area functionality.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; $Id$
;
; ***************************************************************************************************

     xdef FileEprNewFileEntry
     xref FileEprRequest, FileEprFileEntryInfo

     lib ConvPtrToAddr, ConvAddrToPtr



; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return BHL pointer to free space in File Eprom Area, inserted in slot C.
; (B=00h-FFh, HL=0000h-3FFFh).
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         BHL = pointer to first byte of free space
;         (B = absolute bank of slot C)
;
;    Fc = 1, File Area was not found in slot C
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
.FileEprNewFileEntry
                    PUSH BC
                    PUSH DE

                    LD   E,C                           ; preserve slot number
                    CALL FileEprRequest                ; check for presence of "oz" File Eprom Area in slot
                    JR   C,err_FileEprNewFileEntry
                    JR   NZ,err_FileEprNewFileEntry    ; File Area not available in slot...

                    LD   A,E
                    AND  @00000011                     ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                               ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    SUB  C                             ; C = total banks of File Eprom Area
                    INC  A
                    LD   B,A                           ; B is now bottom bank of File Eprom
                    LD   HL,$0000                      ; BHL points at first File Entry...
.scan_eprom
                    CALL FileEprFileEntryInfo          ; scan all file entries, to point at first free byte
                    JR   NC, scan_eprom
                    CP   A                             ; reached pointer to new file entry, don't return Fc = 1
                    JR   exit_FileEprNewFileEntry
.err_FileEprNewFileEntry
                    SCF
.exit_FileEprNewFileEntry
                    POP  DE
                    LD   A,B
                    POP  BC
                    LD   B,A                           ; BHL points at first free byte...

                    RES  7,H
                    RES  6,H                           ; strip segment attributes of bank offset, if any...
                    RET

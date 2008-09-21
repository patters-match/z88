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

        module FileEprNewFileEntry

        xdef FileEprNewFileEntry
        xref FileEprRequest, FileEprFileEntryInfo

        lib ConvPtrToAddr, ConvAddrToPtr

        include "error.def"

; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return BHL pointer to new file entry (also first byte of free space in File
; Eprom Area, inserted in slot C).
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         BHL = pointer to first byte of free space (B = absolute bank of slot C)
;
;    Fc = 1,
;         A = RC_Onf
;         File Area was not found in slot C
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
        push    bc
        push    de

        ld      e,c                             ; preserve slot number
        call    FileEprRequest                  ; check for presence of "oz" File Eprom Area in slot
        jr      c,err_FileEprNewFileEntry
        jr      nz,err_FileEprNewFileEntry      ; File Area not available in slot...

        ld      a,e
        and     @00000011                       ; slots (0), 1, 2 or 3 possible
        rrca
        rrca                                    ; converted to Slot mask $40, $80 or $C0
        or      b
        sub     c                               ; C = total banks of File Eprom Area
        inc     a
        ld      b,a                             ; B is now bottom bank of File Eprom
        ld      hl,$0000                        ; BHL points at first File Entry...
.scan_eprom
        call    FileEprFileEntryInfo            ; scan all file entries, to point at first free byte
        jr      nc, scan_eprom
        cp      a                               ; reached pointer to new file entry, don't return Fc = 1
        jr      exit_FileEprNewFileEntry
.err_FileEprNewFileEntry
        scf
        ld      a,RC_Onf                        ; return A = RC_Onf (File Area not found)
        pop     de
        pop     bc
        ret
.exit_FileEprNewFileEntry
        pop     de
        ld      a,b
        pop     bc
        ld      b,a                             ; BHL points at first free byte...

        res     7,h
        res     6,h                             ; strip segment attributes of bank offset, if any...
        ret

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

        module FileEprCntFiles

        xdef FileEprCntFiles
        xref FileEprRequest, FileEprFileEntryInfo

        include "error.def"

; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Count total of active and deleted files on File Eprom in slot C
; (excl. NULL file on Intel Flash card)
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         HL = total of active (visible) files
;         DE = total of (marked as) deleted files
;         (HL + DE are total files in the file area)
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found at slot C
;
; Registers changed after return:
;    ..BC..../IXIY same
;    AF..DEHL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997-Aug 1998, July 2005
; ------------------------------------------------------------------------
;
.FileEprCntFiles
        push    bc

        ld      e,c                             ; preserve slot number
        call    FileEprRequest                  ; check for presence of "oz" File Eprom in slot C
        jr      c, err_count_files
        jr      nz, err_count_files             ; File Eprom (Area) not available in slot...

        ld      a,e
        and     @00000011                       ; slots (0), 1, 2 or 3 possible
        rrca
        rrca                                    ; converted to Slot mask $40, $80 or $C0
        or      b
        sub     c                               ; C = total banks of File Eprom Area
        inc     a
        ld      b,a                             ; B is now bottom bank of File Eprom
        ld      hl,$0000                        ; BHL points at first File Entry...
        push    hl
        push    hl
        exx
        pop     hl                              ; reset "deleted" files counter
        pop     de                              ; reset active files counter
        exx

        ; scan all file entries, and count
.scan_eprom
        call    FileEprFileEntryInfo
        jr      c, finished                     ; No File Entry was available in File Eprom
        exx
        call    z,DeletedFile
        call    nz, ActiveFile
        exx
        jr      scan_eprom
.err_count_files
        ld      a, RC_Onf
        scf
        jr      exit_count_files2
.finished
        cp      a                               ; Fc = 0, File Eprom parsed.
.exit_count_files
        exx
.exit_count_files2
        pop     bc
        ret

.DeletedFile
        exx
        ex      af,af'                          ; preserve file status of entry
        ld      a,c
        or      d
        or      e
        exx
        jr      z, ignore_nullfile              ; ignore NULL file on Intel flash cards
        inc     de
.ignore_nullfile
        ex      af,af'
        ret
.ActiveFile
        inc     hl
        ret

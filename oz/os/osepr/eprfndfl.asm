     module FileEprFindFile

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

        xdef FileEprFindFile
        xref FileEprRequest, FileEprNextFile
        xref IncBHL

        lib MemReadByte, FileEprReadByte
        lib ToUpper

        include "error.def"


; ***************************************************************************************************
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
.FileEprFindFile
        push    de
        push    af
        push    bc

        push    de                              ; preserve ptr to filename
        ld      e,c                             ; preserve slot number
        call    FileEprRequest                  ; check for presence of "oz" File Eprom in slot C
        pop     hl
        jr      c,no_eprom
        jr      nz,no_eprom                     ; File Eprom not available in slot...

        ld      a,e
        and     @00000011                       ; slots (0), 1, 2 or 3 possible
        rrca
        rrca                                    ; converted to Slot mask $40, $80 or $C0
        or      b
        sub     c                               ; C = total banks of File Eprom Area
        inc     a
        ld      b,a                             ; B is now bottom bank of File Eprom Area
        ex      de,hl                           ; DE points at local null-terminated filename
        ld      hl, $0000                       ; BHL points at first File Entry

.find_file
        xor     a
        call    MemReadByte
        cp      $ff
        jr      z, finished                     ; last File Entry was searched in File Eprom
        cp      $00
        jr      z, finished                     ; pointing at start of ROM header!
        push    bc
        push    hl
        call    IncBHL                          ; BHL = beginning of filename
        call    CompareFilenames                ; found file in File Eprom?
        pop     hl
        pop     bc
        jr      z, file_found                   ; Yes, return ptr. to current File Entry...

        call    FileEprNextFile                 ; get pointer to next File Entry in slot C...
        jr      find_file

.finished
        or      b                               ; Fc = 0, Fz = 0, File not found.
.file_found
        pop     de
        ld      c,e                             ; original C restored
        pop     de
        ld      a,d                             ; original A restored
        pop     de
        ret
.no_eprom
        scf
        ld      a,RC_ONF
        pop     bc
        pop     bc                              ; ignore old AF...
        pop     de
        ret


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
.CompareFilenames
        push    bc
        push    af
        push    de
        push    hl

        ld      c,a                             ; length of filename on Eprom...
.cmp_strings
        call    FileEprReadByte                 ; get char from string <b>, BHL++
        push    bc
        call    ToUpper                         ; Convert to Upper Case
        ld      c,a                             ;
        ld      a,(de)
        inc     de                              ; DE++
        call    ToUpper
        cp      c
        pop     bc
        jr      nz, exit_strcompare             ; strings do not match...

        dec     c
        jr      nz, cmp_strings                 ; continue until end of Eprom filename

        ld      a,(de)                          ; both string match so far...
        or      a                               ; string <a> must end now to match with string <b>...

.exit_strcompare
        pop     hl                              ; original HL restored
        pop     de                              ; original DE restored
        pop     bc
        ld      a,b                             ; original A restored
        pop     bc                              ; original BC restored
        ret

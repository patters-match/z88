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
;
; ***************************************************************************************************

        module FileEprPrevFile

        xdef FileEprPrevFile
        xref FileEprFirstFile, FileEprNextFile, FileEprFileStatus

        include "error.def"


; ***************************************************************************************************
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
.FileEprPrevFile
        push    de
        push    af
        push    bc                              ; preserve A & CDE

        push    hl
        ld      a,b
        and     @11000000                       ; slots (0), 1, 2 or 3 possible
        rlca
        rlca                                    ; Bank number of BHL converted to slot number 0-3.
        ld      c,a                             ; C = slot number
        call    FileEprFirstFile                ; Get first file entry in File Area
        jr      c, no_entry                     ; no File Area!

        pop     de
        ld      a,b
        pop     bc
        push    bc
        ld      c,b                             ; first file entry in BHL,
        ld      b,a                             ; current file entry (lib routine argument) in CDE

        cp      c
        jr      nz, scan_filearea
        push    hl
        sbc     hl,de
        pop     hl
        jr      z, no_entry                     ; BHL lib routine argument was the first file entry!
        jr      scan_filearea
.get_next_entry
        inc     sp
        inc     sp
        inc     sp
        inc     sp                              ; get rid of old file entry
.scan_filearea
        push    bc
        push    hl                              ; preserve current File Entry
        call    FileEprNextFile                 ; get next file entry in BHL
        jr      c, invalid_entry

        ld      a,b
        cp      c
        jr      nz, get_next_entry
        push    hl
        sbc     hl,de
        pop     hl
        jr      nz, get_next_entry

        pop     hl                              ; scanning found current File Entry (lib routine argument)
        pop     bc                              ; get 'previous' entry in BHL and return that to caller
        call    FileEprFileStatus               ; get File Status of Previous File Entry...

        pop     de                              ; BHL = pointer to previous File Entry, Fz = file status
        ld      c,e                             ; original C restored
        pop     de                              ; original DE restored
        ld      a,d                             ; original A restored
        pop     de
        ret
.invalid_entry
        pop     af
        pop     af
.no_entry
        scf
        ld      a, RC_Onf                       ; "Object not found"
        pop     de
        ld      c,e                             ; original C register restored
        pop     de                              ; ignore original AF...
        pop     de
        ret

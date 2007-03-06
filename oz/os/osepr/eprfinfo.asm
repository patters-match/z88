     module FileEprFileEntryInfo

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

        xdef FileEprFileEntryInfo
        xref IncBHL

        lib MemReadByte
        lib FileEprReadByte
        lib AddPointerDistance

        include "error.def"

; ***************************************************************************************************
;
; Standard Z88 File Eprom Format.
;
; Read File Entry information, if available.
;
; NB:     This routine might be used by applications, but is primarily called by
;         File Eprom library routines
;
; IN:
;    BHL = pointer to start of file entry
;         The Bank specifier contains the slot mask, ie. defines which slot
;         is being read. HL is the traditional bank offset.
;
; OUT:
;    Fc = 0, File Entry available
;         Fz = 1, deleted file
;         Fz = 0, active file
;         A = length of filename
;         BHL = pointer to next File Entry (or free space)
;         CDE = length of file
;
;    Fc = 1, File Entry not available ($FF was first byte of entry)
;         A = RC_Onf (Object not found)
;         BHL unchanged.
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
; --------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997
; --------------------------------------------------------------------------
;
.FileEprFileEntryInfo
        xor     a
        call    MemReadByte                     ; Read first byte of File Entry
        cp      $FF
        jr      z, exit_eprfile                 ; previous File Entry was last in File Eprom
        cp      $00
        jr      z, exit_eprfile                 ; pointing at start of ROM header!
        call    IncBHL
        ld      c,a                             ; preserve length of string
        xor     a
        call    MemReadByte                     ; get first char of filename
        or      a                               ; Fc = 0, Fz = 1, if file marked as "deleted" (0)
        ld      a,c                             ; Fz = 0, if '/' character...
        push    af                              ; preserve length of filename, status

        ld      c,0
        ld      d,c
        ld      e,a
        call    AddPointerDistance              ; skip filename, point at length of file...

        call    FileEprReadByte
        ld      e,a
        call    FileEprReadByte
        ld      d,a
        call    FileEprReadByte
        ld      c,a                             ; CDE is length of file
        call    IncBHL                          ; point at beginning of file image
        call    AddPointerDistance              ; BHL points at next File Entry (or none)

        pop     af
        ret                                     ; return length of filename, deleted status

.exit_eprfile
        ld   a, RC_Onf
        scf
        ret

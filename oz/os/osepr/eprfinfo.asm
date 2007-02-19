     module FileEprFileEntryInfo

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

        xdef FileEprFileEntryInfo

        lib MemReadByte
        lib FileEprReadByte
        lib PointerNextByte
        lib AddPointerDistance

        include "error.def"

; ****************************************************************************
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
        call    PointerNextByte
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
        call    PointerNextByte                 ; point at beginning of file image
        call    AddPointerDistance              ; BHL points at next File Entry (or none)

        pop     af
        ret                                     ; return length of filename, deleted status

.exit_eprfile
        ld   a, RC_Onf
        scf
        ret

     module FileEprNextFile

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

        xdef FileEprNextFile
        xref FileEprFileEntryInfo, FileEprFileStatus

        include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return next file entry pointer on Standard File Eprom, inserted in slot
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset)
;
; IN:
;    BHL = pointer to File Entry
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry is active.
;         BHL = pointer to next file entry on File Eprom in slot
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; -----------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004
; -----------------------------------------------------------------------
;
.FileEprNextFile
        push    de
        push    af
        push    bc

        call    FileEprFileEntryInfo
        jr      c, no_entry                     ; No files are present on File Eprom...

        call    FileEprFileStatus               ; check file status of next file

        ld      a,b                             ; returned BHL is next file entry...
        pop     bc                              ; original C register restored
        ld      b,a
        pop     de
        ld      a,d                             ; original A restored...
        pop     de                              ; original DE register restored
        ret
.no_entry
        scf
        ld      a, RC_Onf
        pop     de
        pop     de                              ; ignore old AF
        pop     de                              ; original DE register restored
        ret

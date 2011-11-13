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

        module FileEprLastFile

        xdef FileEprLastFile
        xref FileEprFirstFile, FileEprNextFile, FileEprFileStatus


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to last file entry on Standard File Eprom, inserted in slot C
;
; IN:
;    C = slot number containing File Eprom
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry is active.
;         BHL = pointer to last file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 2004
; ------------------------------------------------------------------------
;
.FileEprLastFile
        push    de
        push    bc                              ; preserve CDE

        call    FileEprFirstFile                ; Get first file entry in File Area
        jr      c,exit_FileEprLastFile          ; no file area found...
.scan_filearea                                  ; scan the File Area until last File Entry found...
        ld      c,b
        ld      d,h
        ld      e,l
        push    af                              ; preserve current File Entry in CDE,F
        call    FileEprNextFile                 ; get next file entry in BHL
        call    FileEprFileStatus               ; validate status of next file entry.
        ex      af,af'
        pop     af
        ex      af,af'
        jr      nc, scan_filearea
                                                ; next file entry was pointing to empty space
        ex      af,af'                          ; file status of last file entry restored.
        ld      b,c
        ex      de,hl                           ; BHL = pointer to last File Entry
.exit_FileEprLastFile
        pop     de
        ld      c,e                             ; original C restored
        pop     de                              ; original DE restored
        ret

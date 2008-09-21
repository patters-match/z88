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

        module FileEprFileImage

        xdef FileEprFileImage

        xref FileEprRequest, FileEprFileEntryInfo
        lib AddPointerDistance


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to start of file image of File Entry at BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset)
;
; IN:
;    BHL = pointer to Eprom File Entry in card at slot
;
; OUT:
;    Fc = 0, File Eprom available, File Entry available
;         BHL = pointer to start of file image
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
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998, Mar 2007
; ------------------------------------------------------------------------
;
.FileEprFileImage
        push    de
        push    bc

        push    bc
        push    hl                              ; preserve pointer to File Entry
        call    FileEprFileEntryInfo
        pop     hl
        pop     bc
        jr      c, exit_FileEprFileImage        ; No files are present on File Eprom...

        inc     a                               ; length of filename + length byte
        add     a,4                             ; + 4 bytes (32bit integer containing file size)

        ld      c,0
        ld      d,c
        ld      e,a
        CALL    AddPointerDistance              ; BHL = start of file image...

.exit_FileEprFileImage
        pop     de
        ld      c,e                             ; original C register restored
        pop     de                              ; original DE restored
        ret

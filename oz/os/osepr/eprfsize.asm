     module FileEprFileSize

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

        xdef FileEprFileSize
        xref FileEprFileEntryInfo


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return file size of File Entry at pointer BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset)
;
; IN:
;    BHL = Pointer to File Entry in card at slot
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry active
;              CDE = size of file (24bit integer, C = high byte)
;
;    Fc = 1,
;         A = RC_ONF
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    ..B...HL/IXIY same
;    AF.CDE../.... different
;
; ----------------------------------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004, Feb 2007
; ----------------------------------------------------------------------------------------------------
;
.FileEprFileSize
        push    hl
        push    bc                              ; preserve pointer

        call    FileEprFileEntryInfo            ; filename size in A, file status (Fz)
                                                ; if Fc = 1, then A = RC_Onf (and CDE will be random)
        pop     hl                              ; if Fc = 0, length of file in CDE
        ld      b,h
        pop     hl                              ; BHL restored
        ret                                     ; return filestatus (Fz) or error status (Fc)

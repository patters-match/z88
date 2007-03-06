        module FileEprActiveSpace

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

        xdef FileEprActiveSpace
        xref FileEprTotalSpace


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return amount of active (visible) file space in File Eprom Area, inserted in slot C.
; (API wrapper of FileEprTotalSpace)
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         DEBC = Active space (amount of visible files) in bytes
;                (DE = high 16bit, BC = low 16bit)
;
;    Fc = 1,
;         A = RC_ONF
;         File Eprom was not found in slot C.
;
; Registers changed after (succesful) return:
;    A.....HL/IXIY same
;    .FBCDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, July 2005
; ------------------------------------------------------------------------
;
.FileEprActiveSpace
        push    hl
        push    af

        call    FileEprTotalSpace
        jr      c,err_FileEprActiveSpace        ; File Area not available
        push    hl
        ld      d,0                             ; BHL = Amount of active file space in bytes
        ld      e,b
        pop     bc                              ; BHL -> DEBC

        pop     hl
        ld      a,h                             ; original A restored
        pop     hl                              ; original HL restored
        ret
.err_FileEprActiveSpace
        pop     hl                              ; discard old AF...
        pop     hl                              ; original HL restored
        ret

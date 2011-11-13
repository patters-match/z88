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

        module FileEprFreeSpace

        xdef FileEprFreeSpace

        xref FileEprRequest, FileEprTotalSpace
        lib ConvPtrToAddr

        include "error.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return free space in Standard File Eprom Area, inserted in slot C
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Area available
;         DEBC = Free space available
;
;    Fc = 1, File Area was not found in slot C
;         A = RC_ONF
;
; Registers changed after (successful) return:
;    ......HL/IXIY same
;    AFBCDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec '97-Aug '98, July '05, Feb '07
; -----------------------------------------------------------------------
;
.FileEprFreeSpace
        push    hl

        ld      e,c                             ; preserve slot number
        call    FileEprRequest                  ; check for presence of "oz" File Eprom in slot
        jr      c, err_FileEprFreeSpace
        jr      nz, err_FileEprFreeSpace        ; File Eprom not available in slot...

        ld      a,e                             ; preserve slot number in A
        ld      b,c
        dec     b
        ld      hl,$3fc0                        ; File Header at relative BHL (seen from bottom of bank)
        call    ConvPtrToAddr                   ; File header -> DEBC (total bytes in file area)
        push    de
        push    bc

        ld      c,a                             ; slot number.
        call    FileEprTotalSpace
        add     hl,de
        ld      a,b
        adc     a,c
        ld      d,0
        ld      e,a
        push    hl
        pop     bc                              ; used file space in file area, BHL + CDE -> DEBC

        pop     hl
        sbc     hl,bc                           ; <Capacity> - <UsedSpace> = Free Space
        ld      b,h
        ld      c,l
        pop     hl
        sbc     hl,de
        ex      de,hl                           ; return free space of File Eprom in DEBC
.exit_freespace
        pop     hl                              ; restored original HL
        ret
.err_FileEprFreeSpace
        scf
        ld      a, RC_ONF
        pop     hl                              ; restored original HL
        ret

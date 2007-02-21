        module FileEprTotalSpace

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

        xdef FileEprTotalSpace
        xref FileEprRequest, FileEprFileEntryInfo

        include "error.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return amount of active and deleted file space (in bytes) in File Eprom Area,
; inserted in slot C.
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         BHL = Amount of active file space in bytes (24bit integer, B = MSB)
;         CDE = Amount of deleted file space in bytes (24bit integer, C = MSB)
;
;    Fc = 1,
;         A = RC_ONF
;         File Eprom was not found in slot C.
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, July 2005
; ------------------------------------------------------------------------
;
.FileEprTotalSpace
        ld      e,c                             ; preserve slot number
        call    FileEprRequest                  ; check for presence of "oz" File Eprom in slot
        jr      c, no_fileepr
        jr      nz, no_fileepr                  ; File Eprom not available in slot...

        ld      a,e
        and     @00000011                       ; slots (0), 1, 2 or 3 possible
        rrca
        rrca                                    ; converted to Slot mask $40, $80 or $C0
        or      b
        sub     c                               ; C = total banks of File Eprom Area
        inc     a
        ld      b,a                             ; B is now bottom bank of File Eprom
        ld      hl,$0000                        ; BHL points at first File Entry...
        push    hl
        push    hl
        push    hl
        exx
        pop     hl
        pop     de
        pop     bc                              ; BC', DE' & HL' = 0
        exx
.scan_eprom
        call    FileEprFileEntryInfo            ; scan all file entries...
        call    CalcFileSpace                   ; summarize file space (active/deleted file entry)
        jr      nc, scan_eprom                  ; look in next File Entry...

        exx                                     ; return BHL, CDE (amount of active/deleted file space)
        cp      a                               ; Fc = 0, File Eprom parsed...
        ret
.no_fileepr
        scf
        ld      a,RC_ONF
        ret


; ************************************************************************
;
; Add file space to current sum of active or deleted file space.
;
; IN:
;    Fz = File status (active or deleted)
;      A = length of filename
;    CDE = length of file
;
; OUT:
;    (Amount of active/deleted file space updated)
;
.CalcFileSpace
        ret     c                               ; not a valid File Entry
        push    af                              ; preserve Z80 status flags
        add     a,4+1                           ; header size = length of filename + 1 + 4
        push    hl
        ld      h,0
        ld      l,a
        add     hl,de
        ld      a,0
        adc     a,c
        ld      c,a
        ex      de,hl                           ; CDE = total size of file (hdr + file image)
        pop     hl
        pop     af
        push    ix                              ; use IX temporarily as 16bit accumulator...
        call    nz, sum_actfile
        call    z, sum_delfile
        pop     ix
        ret
.sum_actfile                                    ; add current file size to sum of active files
        push af                                 ; preserve Z80 status flags
        ld      a,c
        push    de                              ; add file size (in CDE) to BHL'...
        exx
        push    hl
        pop     ix
        ex      de,hl
        pop     de
        add     ix,de
        ex      de,hl                           ; original DE restored (of deleted file space)
        push    ix
        pop     hl                              ; HL += active file size (low 16bit of 24bit)
        adc     a,b
        ld      b,a                             ; B += active files size (high 8 bit of 24bit)
        exx
        pop     af
        ret
.sum_delfile
        push    af                              ; preserve Z80 status flags
        ld      a,c
        push    de                              ; add file size (in CDE) to CDE'...
        exx
        push    de
        pop     ix
        pop     de
        add     ix,de
        push    ix
        pop     de                              ; DE += deleted file size (low 16bit of 24bit)
        adc     a,c
        ld      c,a                             ; C += deleted files size (high 8 bit of 24bit)
        exx
        pop     af
        ret

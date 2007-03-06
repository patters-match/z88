        module FileEprFileName

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

        xdef FileEprFileName

        xref FileEprRequest, FileEprFileEntryInfo
        xref IncBHL, PokeBHL

        lib  MemReadByte, FileEprReadByte


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return file name of File Entry at BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset)
;
; IN:
;    CDE = buffer to hold returned filename, (C = 0, local pointer)
;    BHL = pointer to Eprom File Entry in card at slot
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry marked as active
;         A = length of filename
;         (CDE) contains a copy of filename, null-terminated.
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF...../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004, Feb 2007
; ------------------------------------------------------------------------
;
.FileEprFileName
        push    de
        push    hl
        push    bc                              ; preserve pointer

        push    bc
        push    de                              ; preserve "to" pointer
        push    hl                              ; preserve pointer to File Entry
        call    FileEprFileEntryInfo
        pop     hl
        pop     de
        pop     bc
        jr      c, exit_FileEprFileName         ; file entry not found...

        call    FetchFilename                   ; copy filename into local buffer, null-terminated

.exit_FileEprFileName
        pop     bc
        pop     hl                              ; original pointer restored
        pop     de                              ; original buffer pointer restored
        ret


; ************************************************************************
;
; Fetch filename at BHL, length C characters.
;
; IN:
;    A = length of filename
;    CDE = buffer to hold returned filename
;    BHL = pointer to length byte of filename (start of File Entry)
;
; OUT:
;    Fc = 0, always.
;    (DE) contains a copy of filename, null-terminated, DE points at null.
;    BHL points at byte beyond filename (start of file length 32bit integer)
;    First char of filename always set to "/" (due to deleted filenames)
;
; Registers changed after return:
;    AF....../IXIY same
;    ..BCDEHL/.... different
;
.FetchFilename
        push    af

        dec     a
        push    af
        ld      a,'/'
        call    copy_flnm                       ; begin filename with '/'
        pop     af
        call    IncBHL                          ; point at start of filename (of A length)
        call    IncBHL                          ; point at first real character of filename

.flnm_loop
        push    af
        call    FileEprReadByte                 ; BHL++
        call    copy_flnm
        pop     af
        dec     a                               ; flnmlength--
        jr      nz,flnm_loop
        xor     a
        call    copy_flnm                       ; null-terminate filename

        pop     af
        ret
.copy_flnm                                      ; A -> (CDE)
        push    bc
        ld      b,c
        ex      de,hl
        call    PokeBHL
        inc     hl
        ex      de,hl
        pop     bc
        ret

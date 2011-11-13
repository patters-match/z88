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

        module FileEprFetchFile

        xdef FileEprFetchFile

        xref FileEprFileSize, FileEprFileImage
        lib FileEprTransferBlockSize

        include "fileio.def"
        include "error.def"
        include "memory.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Fetch file (image) from File Eprom Card, identified by File Entry at BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset) and store it into
; an open file (enabled for writing) in the RAM file system (using the IX handle).
;
; The application is responsible for opening/creating a RAM file, then using
; this library routine to transfer the contents from the File Eprom to the
; RAM file system, and then finally close the new RAM file.
;
; IN:
;    IX = handle of file stream (opened previously with GN_Opf, A=OP_OUT)
;    BHL = pointer to Eprom File Entry (bits 7,6 of B is the slot mask)
;
; OUT:
;    Fc = 0,
;         File Image transferred successfully to RAM file.
;
;    Fc = 1,
;         A = RC_ONF, File Eprom or File Entry was not found in slot
;         A = RC_xxx, I/O error during saving process.
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
; ------------------------------------------------------------------------
; Design & programming:
;       Gunther Strube, Dec 1997-Aug 1998, Sep 2004, Oct 2006, Feb 2007
; ------------------------------------------------------------------------
;
.FileEprFetchFile

        push    bc
        push    de
        push    hl

        call    FileEprFileSize                 ; get size of file in CDE, of entry BHL
        jr      c, no_entry                     ; there was no File Eprom Entry at BHL!

        push    bc
        push    de                              ; preserve size of file (in CDE)
        call    FileEprFileImage                ; get pointer to file image in BHL
        exx
        pop     de
        pop     bc                              ; file size in CDE'
        exx
        jr      c, no_entry
.write_loop
        exx                                     ; file size = 0 ?
        ld      a,d
        or      e
        exx
        jr      nz, get_block                   ; No, bytes still left to transfer to RAM...
        exx
        xor     a
        or      c                               ;
        exx
        jr      z, exit_fetch                   ; Yes, completed Eprom Image transfer to RAM file!

.get_block
        call    FileEprTransferBlockSize        ; get size of block to transfer in HL'
        call    TransferFileBlock               ; then transfer block at BHL to RAM file...
        jr      c,exit_fetch                    ; File I/O error occurred, abort...
        jr      write_loop
.no_entry
        scf
        ld      a, RC_ONF                       ; return Fc = 1, error code "Object not found"
.exit_fetch
        pop     hl
        pop     de
        pop     bc
        ret


; ************************************************************************
;
; Transfer File Block, at (BHL), size hl to file (IX)
;
; IN:
;    BHL = pointer to file block
;    hl' = size of block to transfer
;
; OUT:
;    Fc = ?, file I/O status
;    A = RC_xxx, if I/O error occurred
;    BHL = updated to point at first byte of next block to save (or EOF)
;
.TransferFileBlock
        push    bc                              ; preserve bank number of ext. address

        res     7,h
        set     6,h
        ld      c, MS_S1
        rst     OZ_MPB                          ; Bind Bank into segment 1 address space
        push    bc                              ; preserve original bank binding of segment

        exx
        push    bc
        push    de                              ; preserve remaining file size...
        push    hl
        exx                                     ; HL = source (inside current bank B)
        pop     bc                              ; BC = length of block to transfer to RAM file
        ld      de,0
        oz      Os_Mv                           ; move memory to file (IX)...
        exx
        pop     de
        pop     bc                              ; restore remaining file size...
        exx

        pop     bc
        rst     OZ_MPB                          ; restore previous segment bank binding...
        jr      c, err_TransferFileBlock        ; writing current block to file failed, exit...

        pop     bc
        ld      a,h
        and     @00111111
        ld      h,a
        or      l
        ret     nz                              ; we're still inside the current bank after block save...
        inc     b                               ; set offset at start of new bank
        ret
.err_TransferFileBlock
        pop     bc
        ret

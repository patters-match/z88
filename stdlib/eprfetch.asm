     XLIB FileEprFetchFile

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

     LIB FileEprRequest, FileEprFileImage, FileEprFileSize, FileEprTransferBlockSize
     LIB SafeBHLSegment, MemDefBank

     INCLUDE "fileio.def"
     INCLUDE "error.def"


; ************************************************************************
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
;       Gunther Strube, Dec 1997-Aug 1998, Sep 2004, Oct 2006
; ------------------------------------------------------------------------
;
.FileEprFetchFile   PUSH BC
                    PUSH DE
                    PUSH HL

                    CALL FileEprFileSize          ; get size of file in CDE, of entry BHL
                    JR   C, no_entry              ; there was no File Eprom Entry at BHL!

                    PUSH BC
                    PUSH DE                       ; preserve size of file (in CDE)
                    CALL FileEprFileImage         ; get pointer to file image in BHL
                    EXX
                    POP  DE
                    POP  BC                       ; file size in CDE'
                    EXX
                    JR   C, no_entry
.write_loop
                    EXX                           ; file size = 0 ?
                    LD   A,D
                    OR   E
                    EXX
                    JR   NZ, get_block            ; No, bytes still left to transfer to RAM...
                    EXX
                    XOR  A
                    OR   C                        ;
                    EXX
                    JR   Z, exit_fetch            ; Yes, completed Eprom Image transfer to RAM file!

.get_block          CALL FileEprTransferBlockSize ; get size of block to transfer in HL'
                    CALL TransferFileBlock        ; then transfer block at BHL to RAM file...
                    JR   C,exit_fetch             ; File I/O error occurred, abort...
                    JR   write_loop
.no_entry
                    SCF
                    LD   A, RC_ONF                ; return Fc = 1, error code "Object not found"
.exit_fetch
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


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
                    PUSH BC                       ; preserve bank number of ext. address

                    CALL SafeBHLSegment           ; get a safe segment in C (not this executing segment!) to transfer byte
                    CALL MemDefBank               ; Bind Bank into segment 1 address space
                    PUSH BC                       ; preserve original bank binding of segment

                    EXX
                    PUSH BC
                    PUSH DE                       ; preserve remaining file size...
                    PUSH HL
                    EXX                           ; HL = source (inside current bank B)
                    POP  BC                       ; BC = length of block to transfer to RAM file
                    LD   DE,0
                    CALL_OZ(Os_Mv)                ; move memory to file (IX)...
                    EXX
                    POP  DE
                    POP  BC                       ; restore remaining file size...
                    EXX

                    POP  BC
                    CALL MemDefBank               ; restore previous segment bank binding...
                    JR   C, err_TransferFileBlock ; writing current block to file failed, exit...

                    POP  BC
                    LD   A,H
                    AND  @00111111
                    LD   H,A
                    OR   L
                    RET  NZ                       ; we're still inside the current bank after block save...
                    INC  B                        ; set offset at start of new bank
                    RET
.err_TransferFileBlock
                    POP  BC
                    RET

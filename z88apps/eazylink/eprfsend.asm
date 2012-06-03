; *************************************************************************************
; EazyLink - Fast Client/Server File Management, including support for PCLINK II protocol
; (C) Gunther Strube (gstrube@gmail.com) 1990-2012
;
; EazyLink is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EazyLink;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id: fileio.asm 2639 2006-09-19 22:30:36Z gbs $
;
; *************************************************************************************

        module FileEprSendFile

        lib FileEprFileImage,FileEprFileSize,FileEprTransferBlockSize
        lib SafeBHLSegment,MemDefBank

        xdef FileEprSendFile
        xref SendBuffer

        include "error.def"


; ************************************************************************
;
; Transmit file (image) from File Eprom Card, identified by File Entry at BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset) to serial port.
;
; IN:
;    BHL = pointer to Eprom File Entry (bits 7,6 of B is the slot mask)
;
; OUT:
;    Fc = 0, Fz = 0
;         File Image transferred successfully to serial port.
;
;    Fc = 1,
;         A = RC_ONF, File Eprom or File Entry was not found in slot
;         A = RC_xxx, I/O error during saving process.
;    Fz = 1, Time out on serial port
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
; ------------------------------------------------------------------------
; Design & programming (based on original FileEprFetchFile):
;       Gunther Strube, March 2011
; ------------------------------------------------------------------------
;
.FileEprSendFile    PUSH BC
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
                    OR   C
                    EXX
                    JR   Z, fetch_completed       ; Yes, completed Eprom Image transfer to serial port!

.get_block          CALL FileEprTransferBlockSize ; get size of block to transfer in HL'
                    CALL TransferFileBlock        ; then transfer block at BHL to RAM file...
                    JR   C,exit_fetch             ; Serial port I/O error occurred, abort...
                    JR   Z,exit_fetch
                    JR   write_loop
.fetch_completed
                    SCF
                    CCF
                    SET 0,A
                    OR  A
                    JR  exit_fetch                ; Fc = 0, Fz = 0, indeicate successful file image transfer..
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
; Transfer File Block, at (BHL), size hl to serial port
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
                    POP  BC                       ; BC = length of block to transfer to serial port
                    CALL SendBuffer
                    EXX
                    POP  DE
                    POP  BC                       ; restore remaining file size...
                    EXX

                    POP  BC
                    CALL MemDefBank               ; restore previous segment bank binding...
                    JR   C, err_TransferFileBlock ; transmitting current block failed, exit...
                    JR   Z, err_TransferFileBlock ; transmitting current block failed, exit...

                    POP  BC
                    LD   A,H
                    AND  @00111111
                    LD   H,A
                    OR   L
                    RET  NZ                       ; we're still inside the current bank after block save...
                    INC  B                        ; set offset at start of new bank
                    RET                           ; always returns Fc = 0, Fz = 0
.err_TransferFileBlock
                    POP  BC
                    RET

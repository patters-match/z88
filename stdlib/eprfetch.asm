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

     LIB FileEprRequest
     LIB FileEprFileImage
     LIB FileEprFileSize
     LIB MemDefBank

     INCLUDE "fileio.def"
     INCLUDE "integer.def"
     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Fetch file (image) from File Eprom, identified by File Entry at BHL, slot C
; (B=00h-3Fh, HL=0000h-3FFFh)
;
; IN:
;    C = slot number containing File Eprom (1, 2 or 3)
;    IX = handle of file stream (opened as OP_OUT)
;    BHL = pointer to Eprom File Entry
;
; OUT:
;    Fc = 0,
;         File Image transferred successfully to RAM file.
;
;    Fc = 1,
;         A = RC_ONF, File Eprom or File Entry was not found in slot C
;         A = RC_xxx, I/O error during saving process.
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
.FileEprFetchFile   PUSH BC
                    PUSH DE
                    PUSH HL

                    PUSH BC
                    PUSH HL
                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    LD   D,L
                    POP  HL
                    POP  BC
                    JR   C,no_entry
                    JR   NZ,no_entry              ; File Eprom not available in slot...
                    
                    LD   C,E
                    LD   A,E                      ; preserve slot number in A
                    CALL FileEprFileSize          ; get size of file in CDE, of entry BHL, slot C
                    JR   C, no_entry

                    PUSH BC
                    PUSH DE                       ; preserve size of file (in CDE)
                    LD   C,A
                    CALL FileEprFileImage         ; get pointer to file image in BHL, slot C
                    EXX
                    POP  DE
                    POP  BC                       ; file size in CDE'
                    EXX
                    JR   C, no_entry

                    LD   A,C
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    LD   B,A                      ; bank in slot C...
                    RES  7,H                      ; (offset bound into segment 1)
                    SET  6,H                      ; physical ptr. to file image ready...
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

.get_block          CALL GetBlockSize             ; get size of block to transfer in HL'
                    CALL TransferFileBlock        ; then transfer block at BHL to RAM file...
                    JR   C,exit_fetch             ; File I/O error occurred, abort...

                    BIT  7,H
                    JR   Z, write_loop            ; offset still with bank boundary
                    LD   H,$40                    ; reached boundary...
                    INC  B                        ; set offset at start of new bank
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
; Define a block size to transfer to RAM file.
;
; IN:
;    HL = offset pointer in bank (linked to segment 1)
;
; OUT:
;    hl = size of block in File Eprom to transfer to RAM file
;
; Registers changed after return:
;    ..BC..HL/IXIY same
;    AF..DE../.... different
;
;
.GetBlockSize       PUSH BC
                    PUSH HL                       ; preserve BHL pointer...

                    EX   DE,HL
                    LD   HL,$8000                 ; bank boundary...
                    CP   A                        ; Fc = 0
                    SBC  HL,DE                    ; HL = <BankSpace>

                    EXX
                    PUSH DE
                    PUSH BC                       ; get a copy of current file size (CDE)
                    PUSH DE
                    PUSH BC                       ; and preserve a copy...
                    EXX
                    POP  BC
                    POP  DE                       ; divisor in CDE (current size of file)
                    LD   B,0                      ; dividend in BHL (remaining bytes of bank)
                    CALL_OZ(Gn_D24)               ; <blocksize> = <FileSize> MOD <BankSpace>
                    EXX
                    POP  BC
                    POP  DE                       ; (restore current file size)
                    EXX

                    LD   A,D
                    OR   E                        ; <blocksize> = 0 ?
                    CALL NZ, fsize_larger         ; no, FileSize > BankSpace
                    CALL Z, fsize_smaller         ; Yes, FileSize <= BankSpace

                    POP  HL
                    POP  BC
                    RET

.fsize_smaller      EXX                           ; remaining file image to be copied is
                    EX   DE,HL                    ; smaller than <BankSpace>, therefore
                    LD   DE,0                     ; the last image block is resident in the
                    EXX                           ; current bank...
                    RET                           ; HL' = FileSize (max. 16K)

.fsize_larger       PUSH AF                       ; size of remaining file image crosses current
                    PUSH DE                       ; bank boundary...
                    EXX                           ; define block size only of <BankSpace> size.
                    POP  HL
                    PUSH HL
                    EX   DE,HL
                    SBC  HL,DE
                    LD   D,H
                    LD   E,L
                    LD   A,C
                    SBC  A,0
                    LD   C,A                      ; FileSize = FileSize - BankSpace
                    POP  HL                       ; HL' = BankSpace ...
                    EXX
                    POP  AF
                    RET




; ************************************************************************
;
; Transfer File Block, at (BHL), size hl to file (IX)
;
; IN:
;    BHL = pointer to file block
;    hl = size of block to transfer
;
; OUT:
;    Fc = ?, file I/O status
;    A = RC_xxx, if I/O error occurred
;    HL = points at end of block (or first byte of next block to save)
;
.TransferFileBlock
                    PUSH BC                       ; preserve bank number of ext. address

                    LD   C,1
                    CALL MemDefBank               ; Bind Bank into segment 1 address space
                    PUSH BC                       ; original bank binding in B

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
                    CALL MemDefBank               ; restore previous bank binding...

                    POP  BC
                    RET

     XLIB FileEprTransferBlockSize

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
; ***************************************************************************************************


; ***************************************************************************************************
; File Entry Management:
;       Internal support library routine for FileEprFetchFile & FlashEprCopyFileEntry.
;
; Define a block size to transfer, which is from the current bank offset and within 16K bank boundary,
; considering the remaining file size to copy.
;
; IN:
;    BHL = current pointer to file block data
;    cde' = current file size
;
; OUT:
;    hl' = size of block in File Area to transfer
;    cde' = updated according to adjusted block size (that can be transferred within the bank boundary)
;
; Registers changed after return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
.FileEprTransferBlockSize
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    EX   DE,HL
                    LD   HL,$4000                 ; 16K bank boundary...
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
                    call Divu24                   ; <blocksize> = <FileSize> MOD <BankSpace>
                    EXX
                    POP  BC
                    POP  DE                       ; (restore current file size)
                    EXX

                    LD   A,H
                    OR   L
                    JR   Z, last_block
                    EXX
                    PUSH DE
                    EXX
                    POP  DE
                    CALL fsize_larger             ; copy remaining bank space from file inside current bank
                    JR   exit_TransferBlockSize
.last_block
                    LD   A,D
                    OR   E                        ; <blocksize> = 0 ?
                    CALL NZ, fsize_larger         ; no, FileSize > BankSpace
                    CALL Z, fsize_smaller         ; Yes, FileSize <= BankSpace
.exit_TransferBlockSize
                    POP  HL
                    POP  DE
                    POP  BC
                    RET
.fsize_smaller
                    EXX                           ; remaining file image to be copied is
                    EX   DE,HL                    ; smaller than <BankSpace>, therefore
                    LD   DE,0                     ; the last image block is resident in the
                    EXX                           ; current bank...
                    RET                           ; HL' = FileSize (max. 16K)
.fsize_larger
                    PUSH AF                       ; size of remaining file image crosses current
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

;       BHL/CDE -> BHL=quotient, CDE=remainder
.Divu24
                    push    hl
                    xor     a
                    ld      hl, 0
                    exx                                     ;       alt
                    pop     hl
                    ld      b, 24
.d24_2
                    rl      l
                    rl      h
                    exx                                     ;       main
                    rl      b
                    rl      l
                    rl      h
                    rl      a
                    push    af
                    push    hl
                    sbc     hl, de
                    sbc     a, c
                    ccf
                    jr      c, d24_3
                    pop     hl
                    pop     af
                    or      a
                    jr      d24_4
.d24_3
                    inc     sp
                    inc     sp
                    inc     sp
                    inc     sp
.d24_4
                    exx                                     ;       alt
                    djnz    d24_2

                    rl      l
                    rl      h
                    push    hl
                    exx                                     ;       main
                    rl      b
                    ex      de, hl
                    ld      c, a
                    pop     hl
                    or      a
.d24_5
                    ret

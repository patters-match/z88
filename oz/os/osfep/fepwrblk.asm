     MODULE FlashEprWriteBlock

; **************************************************************************************************
; OZ Flash Memory Management.
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
; ***************************************************************************************************

        xdef FlashEprWriteBlock

        xref FlashEprCardId                     ; Identify Flash Memory Chip in slot C
        xref FEP_WriteError
        xref FEP_ExecBlowbyte_29F

        include "flashepr.def"
        include "memory.def"
        include "blink.def"
        include "error.def"
        include "lowram.def"



; ***************************************************************************
;
; Write a block of bytes to the Flash Eprom Card, from address
; DE to BHL of block size IX. If a block will cross a bank boundary, it is
; automatically continued on the next adjacent bank of the card.
; On return, BHL points at the byte after the last written byte.
;
; -------------------------------------------------------------------------
; The routine is used by the File Eprom Management libraries, but is well
; suited for other application purposes.
; -------------------------------------------------------------------------
;
; The routine can be told which programming algorithm to use (by specifying
; the FE_28F or FE_29F mnemonic in C); these parameters can be fetched when
; investigating which Flash Memory chip is available in the slot, using the
; FlashEprCardId routine that reports these constants.
;
; However, if neither of the constants are provided in A, the routine can
; be specified with C = 0 which internally polls the Flash Memory for
; identification and intelligently use the correct programming algorithm.
; The identified FE_28F or FE_29F constant is returned to the caller in C
; for future reference (when the block was successfully programmed to the card).
;
; Uses the segment mask of HL(where BHL memory will be bound into the Z80
; address space to blow the block of bytes (MM_S0 - MM_S3), which has to be
; in a different segment than DE is referring.
;
; BHL points to an absolute bank (which is part of the slot that the Flash
; Memory Card have been inserted into).
;
; Further, the local buffer must be available in local address space and not
; part of the segment used for blowing bytes.
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3
; to successfully blow data to the memory chip. If the Flash Eprom card
; is inserted in slot 1 or 2, this routine will report a programming failure.
;
; It is the responsibility of the application (before using this call) to
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; In :
;         C = FE_28F, FE_29F or 0 (poll card for blowing algorithm)
;         DE = local pointer to start of block (located in current address space)
;         BHL = extended address to start of destination (pointer into card)
;              (bits 7,6 of B is the slot mask)
;              (bits 7,6 of H = MM_Sx segment mask for BHL)
;         IX = size of block (at DE) to blow
; Out:
;         Success:
;              Fc = 0
;              C = FE_28F or FE_29F (depending on found card)
;              BHL updated
;         Failure:
;              Fc = 1
;              A = RC_BWR (block not blown properly)
;              A = RC_NFE (not a recognized Flash Memory Chip)
;              A = RC_UNK (chip type is unknown: use only FE_28F, FE_29F or 0)
;
; Registers changed on return:
;    ....DE../IXIY ........ same
;    AFBC..HL/.... afbcdehl different
;
; --------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Dec 97, Jan-Apr 98, Aug '04, Oct '05, Aug-Nov '06, Feb '07
;    Thierry Peycru, Zlab, Dec 1997
; --------------------------------------------------------------------------
;
.FlashEprWriteBlock
        push    de                            ; preserve DE
        push    bc                            ; preserve C
        ld      a,c
        ex      af,af'                        ; preserve FE Programming type in A'

        ld      a,b
        exx
        and     @11000000
        rlca
        rlca                                  ; A = slot number of BHL
        ld      c,a                           ; remember Flash Memory slot (of BHL pointer) number in C'
        exx

        ld      a,h
        rlca
        rlca
        and     @00000011
        ld      c,a                           ; C = MS_Sx
        ld      a,b
        rst     OZ_MPB                        ; Bind slot x bank into segment C
        push    bc                            ; preserve old bank binding of segment C
        ld      b,a                           ; but use current bank as reference...

        di                                    ; no maskable interrupts allowed while doing flash hardware commands...
        call    FEP_WriteBlock
        ei                                    ; maskable interrupts allowed again

        ld      d,b                           ; preserve current Bank number of pointer...
        pop     bc
        rst     OZ_MPB                        ; restore old segment C bank binding
        ld      b,d
        ld      c,a                           ; return updated FEP_xxx type, if C(in) were 0...

        pop     de
        ld      c,e                           ; original C register restored...
        pop     de
        ret


; ***************************************************************
;
; Write Block to BHL already bound, in slot x, of IX length.
; This routine will clone itself on the stack and execute there.
;
; In:
;         A' = FE_28F, FE_29F or 0
;         C' = slot number of BHL pointer
;         C  = MS_Sx segment specifier
;         DE = local pointer to start of block (available in current address space)
;         BHL = extended address to start of destination (pointer into card)
;         IX = size of block to blow
; Out:
;    Fc = 0, block blown successfully to the Flash Card
;         A = FE_28F or FE_29F, depending on found chip type
;         BHL = points at next free byte on Flash Eprom
;         DE = points beyond last byte of buffer
;    Fc = 1,
;         A = RC_BWR  (block not blown properly)
;         A = RC_UNK (pre-specified chip type is unknown: use only FE_28F, FE_29F or 0)
;         DE,BHL points at byte not blown properly (A = RC_BWR)
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FEP_WriteBlock
        ex      af,af'                          ; FE Programming type in A
        cp      FE_28F
        jr      z, check_slot3                  ; make sure that pre-selected INTEL flash is located in slot 3
        cp      FE_29F
        jr      z, write_29F_block
        or      a
        jr      z, poll_chip_programming        ; chip type = 0 indicates to get chip type to program it...
        scf
        ld      a, RC_Unk                       ; unknown chip type specified!
        ret
.poll_chip_programming
        push    bc
        push    de
        push    hl
        exx
        call    FlashEprCardId                  ; Flash in slot C?
        exx
        pop     hl
        pop     de
        pop     bc
        ret     c                               ; Fc = 1, A = RC error code (Flash Memory not found)

        cp      FE_28F                          ; now, we've got the chip type
        jr      nz, write_29F_block             ; and this one may be programmed in any slot...
.check_slot3
        push    af                              ; remember FE_28F chip type
        ld      a,3
        exx
        cp      c                               ; when chip is FE_28F series, we need to be in slot 3
        jr      z,write_28F_block               ; to make a successful "write" of the byte...
        exx
        pop     af
        jp      FEP_WriteError                  ; Ups, not in slot 3, signal write error!
.write_29F_block
        push    af                              ; remember FE_29F chip type
        push    ix
        call    FEP_ExecWriteBlock_29F
        pop     ix
        jr      exit_blowblock
.write_28F_block
        call    FEP_ExecWriteBlock_28F
.exit_blowblock
        ex      af,af'
        pop     af                              ; get chip type
        ex      af,af'
        ret     c                               ; ignore chip type and return error code
        ex      af,af'                          ; Block was successfully blown, return chip type in A
        or      a                               ; Fc = 0 (signal successfull operation)
        ret



; ***************************************************************
; Program block of data on an INTEL I28Fxxxx Flash Memory.
; (this routine is copied on the stack and executed there)
;
; IN:
;       BHL = pointer to blow data
;       C = MS_Sx segment specifier
;       DE = pointer to source data
;       IX = size of data
;
.FEP_ExecWriteBlock_28F
        exx
        ld      bc,BLSC_COM                     ; Address of soft copy of COM register
        ld      a,(BC)
        set     BB_COMVPPON,A                   ; VPP On
        set     BB_COMLCDON,A                   ; Force Screen enabled...
        ld      (bc),a
        out     (c),a                           ; signal to HW

        push    ix
        pop     hl                              ; use HL as 16bit decrement counter
        exx

.WriteBlockLoop
        exx
        ld      a,h
        or      l
        dec     hl
        exx
        jr      z, exit_write_block             ; block written successfully (Fc = 0)
        push    bc

        ld      a,(de)
        ld      b,a                             ; preserve to blown in B...
        call    I28Fx_BlowByte
        bit     4,A
        jr      nz,write_error                  ; Error: byte wasn't blown properly

        ld      a,(hl)                          ; read byte at (HL) just blown
        cp      b                               ; equal to original byte?
        jr      z, exit_write_byte              ; byte blown successfully!
.write_error
        ld      a, RC_BWR
        scf
.exit_write_byte
        pop     bc
        jr      c, exit_write_block

        inc     de                              ; buffer++
        ld      a,b
        push    af

        ld      a,h                             ; BHL++
        and     @11000000                       ; preserve segment mask

        res     7,h
        res     6,h                             ; strip segment mask to determine bank boundary crossing
        inc     hl                              ; ptr++
        bit     6,h                             ; crossed bank boundary?
        jr      z, not_crossed                  ; no, offset still in current bank
        inc     b
        res     6,h                             ; yes, HL = 0, B++
.not_crossed
        or      h                               ; re-establish original segment mask for bank offset
        ld      h,a

        pop     af
        cp      b                               ; was a new bank crossed?
        jr      z,WriteBlockLoop                ; no...

        push    bc                              ; pointer crossed a new bank
        rst     OZ_MPB                          ; bind it in for next byte...
        pop     bc
        jr      WriteBlockLoop
.exit_write_block
        push    af
        exx
        ld      a,(bc)
        res     BB_COMVPPON,a                   ; VPP Off
        ld      (bc),a
        out     (c),a                           ; Signal to HW
        exx
        pop     af
        ret


; ***************************************************************
; Program block of data on an AMD/STM Flash Memory
; (this routine is optionally copied on the stack and executed there)
;
; IN:
;       BHL = pointer to blow data
;       C = MS_Sx segment specifier
;       DE = pointer to source data
;       IX = size of data
;
.FEP_ExecWriteBlock_29F
.WriteBlockLoop_29F
        exx
        push    ix
        pop     bc                              ; install block size.
        ld      a,b
        or      c
        dec     ix
        exx
        ret     z                               ; block written successfully (Fc = 0)

        push    bc                              ; preserve bank and MS_Sx while programming byte to card
        ld      a,(de)                          ; get byte to blow from source block
        push    de
        call    FEP_ExecBlowbyte_29F
        pop     de
        pop     bc                              ; get current bank and segment for block data
        ret     c

        inc     de                              ; buffer++
        ld      a,b
        push    af

        ld      a,h                             ; BHL++
        and     @11000000                       ; preserve segment mask

        res     7,h
        res     6,h                             ; strip segment mask to determine bank boundary crossing
        inc     hl                              ; ptr++
        bit     6,h                             ; crossed bank boundary?
        jr      z, not_crossed_29F              ; no, offset still in current bank
        inc     b
        res     6,h                             ; yes, HL = 0, B++
.not_crossed_29F
        or      h                               ; re-establish original segment mask for bank offset
        ld      h,a

        pop     af
        cp      b                               ; was a new bank crossed?
        jr      z,WriteBlockLoop_29F            ; no...

        push    bc                              ; pointer crossed a new bank
        rst     OZ_MPB                          ; bind new bank into segment C...
        pop     bc
        jr      WriteBlockLoop_29F

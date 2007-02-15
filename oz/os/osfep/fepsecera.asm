        module FlashEprSectorErase

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

        xdef FlashEprSectorErase

        xref FlashEprCardId                     ; Identify Flash Memory Chip in slot C
        xref FlashEprPollSectorSize             ; Poll for Flash chip sector size.
        xref FEP_VppError, FEP_EraseError       ; Fc = 1, A = Error Code
        xref AM29Fx_InitCmdMode                 ; prepare for AMD Chip command mode

        include "flashepr.def"
        include "error.def"
        include "blink.def"
        include "memory.def"
        include "lowram.def"



;***************************************************************************************************
;
; Erase sector defined in B (00h-0Fh), on Flash Memory Card inserted in slot C.
;
; The routine will internally ask the Flash Memory for identification and intelligently
; use the correct erasing algorithm. All known Flash Memory chips from INTEL, AMD & STM
; (see flashepr.def) uses 64K sectors, except the AM29F010B/ST29F010B 128K chip, which uses 16K sectors.
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 to successfully erase
; a block/sector on the memory chip. If the Flash Eprom card is inserted in slot 1 or 2, this
; routine will automatically report a sector erase failure error.
;
; It is the responsibility of the application (before using this call) to evaluate the Flash
; Memory (using the FlashEprCardId routine) and warn the user that an INTEL Flash Memory Card
; requires the Z88 slot 3 hardware, so this type of unnecessary error can be avoided.
;
; IN:
;         B = block/sector number on chip to be erased (00h - 0Fh)
;             (available sector size and count depend on chip type)
;         C = slot number (0, 1, 2 or 3) of Flash Memory Card
; OUT:
;         Success:
;              Fc = 0
;         Failure:
;              Fc = 1
;              A = RC_NFE (not a recognized Flash Memory Chip)
;              A = RC_BER (error occurred when erasing block/sector)
;              A = RC_VPL (Vpp Low Error)
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; ------------------------------------------------------------------------------------------
; Design & programming by:
;    Gunther Strube, Dec 97-Apr 98, Aug '04, Aug '06, Oct-Nov '06, Feb '07
;    Thierry Peycru, Zlab, Dec 1997
; ------------------------------------------------------------------------------------------
;
.FlashEprSectorErase
        push    bc
        push    de
        push    hl

        ld      a,b
        and     @00001111                       ; sector number range is only 0 - 15...
        ld      d,a                             ; preserve sector in D (not destroyed by FlashEprCardId)
        ld      e,c                             ; preserve slot no in E (not destroyed by FlashEprCardId)
        call    FlashEprCardId                  ; poll for card information in slot C (returns B = total banks of card)
        jr      c, exit_FlashEprBlockErase
        ex      af,af'                          ; preserve FE Programming type in A'
        call    FlashEprPollSectorSize
        jr      z, _16K_block_fe                ; yes, it's a 16K sector architecture (same as Z88 bank architecture!)
        ld      a,d                             ; no, it's a 64K sector architecture
        add     a,a                             ; sector number * 4 (16K * 4 = 64K!)
        add     a,a                             ; (convert to first bank no of sector)
        ld      d,a
._16K_block_fe
        ld      a,c
        and     @00000011                       ; only slots 0, 1, 2 or 3 possible
        rrca
        rrca                                    ; Converted to Slot mask $40, $80 or $C0
        or      d                               ; the absolute bank which is the bottom of the sector
        ld      d,a                             ; preserve a copy of bank number in D

        and     @00111111
        inc     a                               ; this is the X'th bank of the card..
        ld      c,a
        ld      a,b                             ; make sure that the Flash Memory Card (B = total 16K banks on Card)
        sub     c                               ; contains the sector (to be erased)
        jr      nc, sector_exists               ; (total_banks_on_card - sector_bank < 0) ...
        ld      a,RC_BER                        ; Fc = 1, sector not available (could not erase block/sector)
        jr      exit_FlashEprBlockErase
.sector_exists
        ld      b,d                             ; bind sector to
        ld      c, MS_S1                        ; segment 1 (segment 2 & 3 contains OZ kernel banks)
        ld      hl,MM_S1 << 8                   ; HL points into segment
        rst     OZ_MPB
        push    bc                              ; preserve old bank binding

        ex      af,af'                          ; FE Programming type in A
        di                                      ; no maskable interrupts allowed while doing flash hardware commands...
        call    FEP_EraseBlock                  ; erase sector in slot C
        ei                                      ; maskable interrupts allowed again
                                                ; return AF error status of sector erasing...
        pop     bc
        rst     OZ_MPB                          ; Restore previous Bank bindings

.exit_FlashEprBlockErase
        pop     hl
        pop     de
        pop     bc
        RET


; ***************************************************************
;
; Erase block, identified by bank A, using segment x, which
; HL points into.
;
; In:
;    A = FE_28F or FE_29F (depending on Flash Memory type in slot)
;    E = slot number (1, 2 or 3) of Flash Memory Card
;    HL = points into bound bank of Flash Memory
;
; Out:
;    Success:
;        Fc = 0
;    Failure:
;        Fc = 1
;        A = RC_BER (error occurred when erasing block/sector)
;        A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FEP_EraseBlock
        cp      FE_29F
        jr      z, FEP_EraseBlock_29F           ; execute AMD/STM sector erasure in LOWRAM, return error in AF...
        ld      a,3
        cp      e                               ; when chip is FE_28F series, we need to be in slot 3
        jp      nz, FEP_EraseError              ; Ups, not in slot 3, signal error!


; ***************************************************************
;
; Erase block on an INTEL 28Fxxxx Flash Memory, which is bound
; into segment x that HL points into.
;
; In:
;    HL = points into bound Flash Memory sector
; Out:
;    Success:
;        Fc = 0
;        A = undefined
;    Failure:
;        Fc = 1
;        A = RC_BER (error occurred when erasing block/sector)
;        A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
.FEP_EraseBlock_28F
        ld      bc,BLSC_COM                     ; Address of soft copy of COM register
        ld      a,(bc)
        set     BB_COMVPPON,a                   ; Vpp On
        set     BB_COMLCDON,a                   ; Force Screen enabled (don't push 21V to Intel flash!)...
        ld      (bc),a
        out     (c),a                           ; signal to HW
        cp      a                               ; Fc = 0
        call    I28Fx_EraseSector               ; execute Erasure of sector in LOWRAM...
        bit     3,a
        call    nz, FEP_VppError                ; chip didn't detect VPP pin ...
        jr      c, exit_EraseBlock_28F
        bit     5,a
        call    nz, FEP_EraseError              ; chip could erase sector...
.exit_EraseBlock_28F
        ex      af,af'
        ld      a,(bc)
        res     BB_COMVPPON,a                   ; Vpp Off
        ld      (bc),a
        out     (c),a                           ; Signal to HW
        ex      af,af'                          ; return error status from chip sector erasure
        ret


; ***************************************************************
;
; Erase block on an AMD 29Fxxxx Flash Memory, which is bound
; into segment x that HL points into.
;
; In:
;    HL = points into bound Flash Memory sector
; Out:
;    Success:
;        Fc = 0
;        A = undefined
;    Failure:
;        Fc = 1
;        A = RC_BER (error occurred when erasing block/sector)
;        A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FEP_EraseBlock_29F
        call    AM29Fx_InitCmdMode
        jp      AM29Fx_EraseSector              ; Erase sector in LOWRAM, then use RET in LOWRAM to get back to caller
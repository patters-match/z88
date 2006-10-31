     MODULE FlashEprSectorErase

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

        lib SafeBHLSegment                      ; Prepare BHL pointer to be bound into a safe segment outside this executing bank
        lib ExecRoutineOnStack                  ; Clone small subroutine on system stack and execute it
        lib DisableBlinkInt                     ; No interrupts get out of Blink
        lib EnableBlinkInt                      ; Allow interrupts to get out of Blink

        xref FlashEprCardId                     ; Identify Flash Memory Chip in slot C
        xref FlashEprPollSectorSize             ; Poll for Flash chip sector size.

        include "flashepr.def"
        include "blink.def"
        include "memory.def"
        include "lowram.def"


; =================================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_ERA = $20           ; erase sector (64Kb) command
DEFC FE_CON = $D0           ; confirm erasure
; =================================================================================================


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
; ---------------------------------------------------------------
; Design & programming by:
;    Gunther Strube, Dec 1997-Apr 1998, Aug 2004, Aug 2006, Oct-Nov 2006
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
.FlashEprSectorErase
        push    bc
        push    de
        push    hl
        push    ix

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
        ld      b,d                             ; bind sector to segment x
        ld      hl,0
        call    SafeBHLSegment                  ; get a safe segment in C, HL points into segment (not this executing segment!)
        rst     OZ_MPB
        push    bc                              ; preserve old bank binding

        ex      af,af'                          ; FE Programming type in A
        call    DisableBlinkInt                 ; no interrupts get out of Blink
        call    FEP_EraseBlock                  ; erase sector in slot C
        call    EnableBlinkInt                  ; interrupts are again allowed to get out of Blink
                                                ; return AF error status of sector erasing...
        pop     bc
        rst     OZ_MPB                          ; Restore previous Bank bindings

.exit_FlashEprBlockErase
        pop     ix
        pop     hl
        pop     de
        pop     bc
        RET


; ***************************************************************
;
; Erase block, identified by bank A, using segment x, which
; HL points into.
; This routine will clone itself on the stack and execute there.
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
        cp      FE_28F
        jr      z, erase_28F_block
.erase_29F_block
        ld      ix, FEP_EraseBlock_29F
        exx
        ld      bc, end_FEP_EraseBlock_29F - FEP_EraseBlock_29F
        exx
        jp      ExecRoutineOnStack
.erase_28F_block
        ld      a,3
        cp      e                               ; when chip is FE_28F series, we need to be in slot 3
        jr      z,_erase_28F_block              ; to make a successful sector erase
        scf
        ld      a, RC_BER                       ; Ups, not in slot 3, signal error!
        ret
._erase_28F_block
        ld      ix, FEP_EraseBlock_28F
        exx
        ld      bc, end_FEP_EraseBlock_28F - FEP_EraseBlock_28F
        exx
        jp      ExecRoutineOnStack


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

        ld      (hl), FE_ERA
        ld      (hl), FE_CON
.erase_28f_busy_loop
        ld      (hl), FE_RSR                    ; (R)equest for (S)tatus (R)egister
        ld      a,(hl)
        bit     7,a
        jr      z,erase_28f_busy_loop           ; Chip still erasing the sector...

        bit     3,a
        jr      nz,vpp_error
        bit     5,a
        jr      nz,erase_error
        cp      a                               ; Sector successfully erased, Fc = 0

        ld      (hl), FE_CSR                    ; Clear Status Register
        ld      (hl), FE_RST                    ; Reset Flash Memory to Read Array Mode
.exit_FEP_EraseBlock_28F
        ex      af,af'
        ld      a,(bc)
        res     BB_COMVPPON,a                   ; Vpp Off
        ld      (bc),a
        out     (c),a                           ; Signal to hw
        ex      af,af'
        ret
.vpp_error
        ld      a, RC_VPL
        scf
        jr      exit_FEP_EraseBlock_28F
.erase_error
        ld      a, RC_BER
        scf
        jr      exit_FEP_EraseBlock_28F
.end_FEP_EraseBlock_28F


; ***************************************************************
;
; Erase block on an AMD 29Fxxxx (or compatible) Flash Memory,
; which is bound into segment x that HL points into.
;
; In:
;    HL = points into bound Flash Memory sector
; Out:
;    Success:
;        Fc = 0
;        A = undefined
;    Failure:
;        Fc = 1
;        A = RC_BER (block/sector was not erased)
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FEP_EraseBlock_29F
        ld      bc,$aa55                        ; B = Unlock cycle #1, C = Unlock cycle #2
        ld      a,h
        and     @11000000
        ld      d,a
        or      $05
        ld      h,a
        ld      l,c                             ; HL = address $x555
        set     1,d
        ld      e,b                             ; DE = address $x2AA

        ld      a,c
        ld      (hl),b                          ; AA -> (XX555), First Unlock Cycle
        ld      (de),a                          ; 55 -> (XX2AA), Second Unlock Cycle
        ld      (hl),$80                        ; 80 -> (XX555), Erase Mode
                                                ; sub command...
        ld      (hl),b                          ; AA -> (XX555), First Unlock Cycle
        ld      (de),a                          ; 55 -> (XX2AA), Second Unlock Cycle
        ld      (hl),$30                        ; 30 -> (XXXXX), begin format of sector...
.toggle_wait_loop
        ld      a,(hl)                          ; get first DQ6 programming status
        ld      c,a                             ; get a copy programming status (that is not XOR'ed)...
        xor     (hl)                            ; get second DQ6 programming status
        bit     6,a                             ; toggling?
        ret     z                               ; no, erasing the sector completed successfully (also back in Read Array Mode)!
        bit     5,c                             ;
        jr      z, toggle_wait_loop             ; we're toggling with no error signal and waiting to complete...

        ld      a,(hl)                          ; DQ5 went high, we need to get two successive status
        xor     (hl)                            ; toggling reads to determine if we're still toggling
        bit     6,a                             ; which then indicates a sector erase error...
        ret     z                               ; we're back in Read Array Mode, sector successfully erased!
.erase_err_29f                                           ; damn, sector was NOT erased!
        ld      (hl),$f0                        ; F0 -> (XXXXX), force Flash Memory to Read Array Mode
        scf
        ld      a, RC_BER                       ; signal sector erase error to application
        ret
.end_FEP_EraseBlock_29F
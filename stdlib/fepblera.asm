     XLIB FlashEprBlockErase

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

     LIB SafeBHLSegment       ; Prepare BHL pointer to be bound into a safe segment outside this executing bank
     LIB MemDefBank           ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB ExecRoutineOnStack   ; Clone small subroutine on system stack and execute it
     LIB DisableBlinkInt      ; No interrupts get out of Blink
     LIB EnableBlinkInt       ; Allow interrupts to get out of Blink
     LIB FlashEprCardId       ; Identify Flash Memory Chip in slot C
     LIB FlashEprPollSectorSize ; Poll for Flash chip sector size.

     INCLUDE "flashepr.def"
     INCLUDE "blink.def"
     INCLUDE "memory.def"


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
; Erase sector (block) defined in B (00h-0Fh), on Flash
; Memory Card inserted in slot C.
;
; The routine will internally ask the Flash Memory for identification
; and intelligently use the correct erasing algorithm. All known
; Flash Memory chips from Intel and Amd (see flashepr.def) uses 64K
; sectors, except the AM29F010B 128K chip, which uses 16K sectors.
;
; -------------------------------------------------------------------------
; AMD/STM flash memory:
; The screen is turned off while block is being erased for three reasons:
; 1) While a sector is erased, no interference should happen from Blink:
;    When sector is part of OZ ROM, the font bitmaps are suddenly unavailable
;    which creates violent screen flickering during chip command mode.
;    Further, and most importantly, avoid Blink doing read-cycles while
;    chip is in command mode.
; 2) Preserve battery power. The screen is the no. 1 consumer of power!
; 3) End-user familiarity; the screen goes off while doing 'Eprom' files.
; -------------------------------------------------------------------------
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3
; to successfully erase a block/sector on the memory chip. If the
; Flash Eprom card is inserted in slot 1 or 2, this routine will
; automatically report a sector erase failure error.
;
; It is the responsibility of the application (before using this call)
; to evaluate the Flash Memory (using the FlashEprCardId routine) and
; warn the user that an INTEL Flash Memory Card requires the Z88
; slot 3 hardware, so this type of unnecessary error can be avoided.
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
;    Gunther Strube, Dec 1997-Apr 1998, Aug 2004, Aug 2006
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
.FlashEprBlockErase
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   A,B
                    AND  @00001111           ; sector number range is only 0 - 15...
                    LD   D,A                 ; preserve sector in D (not destroyed by FlashEprCardId)
                    LD   E,C                 ; preserve slot no in E (not destroyed by FlashEprCardId)
                    CALL FlashEprCardId      ; poll for card information in slot C (returns B = total banks of card)
                    JR   C, exit_FlashEprBlockErase
                    EX   AF,AF'              ; preserve FE Programming type in A'
                    CALL FlashEprPollSectorSize
                    JR   Z, _16K_block_fe    ; yes, it's a 16K sector architecture (same as Z88 bank architecture!)
                    LD   A,D                 ; no, it's a 64K sector architecture
                    ADD  A,A                 ; sector number * 4 (16K * 4 = 64K!)
                    ADD  A,A                 ; (convert to first bank no of sector)
                    LD   D,A
._16K_block_fe
                    LD   A,C
                    AND  @00000011           ; only slots 0, 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    OR   D                   ; the absolute bank which is the bottom of the sector
                    LD   D,A                 ; preserve a copy of bank number in D

                    AND  @00111111
                    INC  A                   ; this is the X'th bank of the card..
                    LD   C,A
                    LD   A,B                 ; make sure that the Flash Memory Card (B = total 16K banks on Card)
                    SUB  C                   ; contains the sector (to be erased)
                    JR   NC, sector_exists   ; (total_banks_on_card - sector_bank < 0) ...
                    LD   A,RC_BER            ; Fc = 1, sector not available (could not erase block/sector)
                    JR   exit_FlashEprBlockErase
.sector_exists
                    LD   B,D                 ; bind sector to segment x
                    LD   HL,0
                    CALL SafeBHLSegment      ; get a safe segment in C, HL points into segment (not this executing segment!)
                    CALL MemDefBank
                    PUSH BC                  ; preserve old bank binding

                    EX   AF,AF'              ; FE Programming type in A
                    CALL DisableBlinkInt     ; no interrupts get out of Blink
                    CALL FEP_EraseBlock      ; erase sector in slot C
                    CALL EnableBlinkInt      ; interrupts are again allowed to get out of Blink
                                             ; return AF error status of sector erasing...
                    POP  BC
                    CALL MemDefBank          ; Restore previous Bank bindings

.exit_FlashEprBlockErase
                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
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
                    CP   FE_28F
                    JR   Z, erase_28F_block
.erase_29F_block
                    LD   IX, FEP_EraseBlock_29F
                    EXX
                    LD   BC, end_FEP_EraseBlock_29F - FEP_EraseBlock_29F
                    EXX
                    JP   ExecRoutineOnStack
.erase_28F_block
                    LD   A,3
                    CP   E                   ; when chip is FE_28F series, we need to be in slot 3
                    JR   Z,_erase_28F_block  ; to make a successful sector erase
                    SCF
                    LD   A, RC_BER           ; Ups, not in slot 3, signal error!
                    RET
._erase_28F_block
                    LD   IX, FEP_EraseBlock_28F
                    EXX
                    LD   BC, end_FEP_EraseBlock_28F - FEP_EraseBlock_28F
                    EXX
                    JP   ExecRoutineOnStack


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
                    LD   BC,BLSC_COM         ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  BB_COMVPPON,A       ; Vpp On
                    LD   (BC),A
                    OUT  (C),A               ; signal to HW

                    LD   (HL), FE_ERA
                    LD   (HL), FE_CON
.erase_28f_busy_loop
                    LD   (HL), FE_RSR        ; (R)equest for (S)tatus (R)egister
                    LD   A,(HL)
                    BIT  7,A
                    JR   Z,erase_28f_busy_loop ; Chip still erasing the sector...

                    BIT  3,A
                    JR   NZ,vpp_error
                    BIT  5,A
                    JR   NZ,erase_error
                    CP   A                   ; Sector successfully erased, Fc = 0

                    LD   (HL), FE_CSR        ; Clear Status Register
                    LD   (HL), FE_RST        ; Reset Flash Memory to Read Array Mode
.exit_FEP_EraseBlock_28F
                    EX   AF,AF'
                    LD   A,(BC)
                    RES  BB_COMVPPON,A       ; Vpp Off
                    LD   (BC),A
                    OUT  (C),A               ; Signal to hw
                    EX   AF,AF'
                    RET
.vpp_error
                    LD   A, RC_VPL
                    SCF
                    JR   exit_FEP_EraseBlock_28F
.erase_error
                    LD   A, RC_BER
                    SCF
                    JR   exit_FEP_EraseBlock_28F
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
                    LD   BC,BLSC_COM         ; Address of soft copy & COM register
                    PUSH BC
                    LD   A,(BC)
                    RES  BB_COMLCDON,A       ; Screen Off
                    LD   (BC),A
                    OUT  (C),A               ; signal to hw

                    LD   BC,$AA55            ; B = Unlock cycle #1, C = Unlock cycle #2
                    LD   A,H
                    AND  @11000000
                    LD   H,A
                    LD   D,A
                    OR   $05
                    LD   H,A
                    LD   L,C                 ; HL = address $x555
                    LD   A,D
                    OR   $02
                    LD   D,A
                    LD   E,B                 ; DE = address $x2AA

                    LD   A,C
                    LD   (HL),B              ; AA -> (XX555), First Unlock Cycle
                    LD   (DE),A              ; 55 -> (XX2AA), Second Unlock Cycle
                    LD   (HL),$80            ; 80 -> (XX555), Erase Mode
                                             ; sub command...
                    LD   (HL),B              ; AA -> (XX555), First Unlock Cycle
                    LD   (DE),A              ; 55 -> (XX2AA), Second Unlock Cycle

                    LD   (HL),$30            ; 30 -> (XXXXX), begin format of sector...
.toggle_wait_loop
                    LD   A,(HL)              ; get first DQ6 programming status
                    LD   C,A                 ; get a copy programming status (that is not XOR'ed)...
                    XOR  (HL)                ; get second DQ6 programming status
                    BIT  6,A                 ; toggling?
                    JR   Z,exit_era_29f      ; no, erasing the sector completed successfully (also back in Read Array Mode)!
                    BIT  5,C                 ;
                    JR   Z, toggle_wait_loop ; we're toggling with no error signal and waiting to complete...

                    LD   A,(HL)              ; DQ5 went high, we need to get two successive status
                    XOR  (HL)                ; toggling reads to determine if we're still toggling
                    BIT  6,A                 ; which then indicates a sector erase error...
                    JR   Z,exit_era_29f      ; we're back in Read Array Mode, sector successfully erased!
.erase_err_29f                               ; damn, sector was NOT erased!
                    LD   (HL),$F0            ; F0 -> (XXXXX), force Flash Memory to Read Array Mode
                    SCF
                    LD   A, RC_BER           ; signal sector erase error to application
.exit_era_29f
                    POP  BC
                    EX   AF,AF'
                    LD   A,(BC)
                    SET  BB_COMLCDON,A       ; Screen On
                    LD   (BC),A
                    OUT  (C),A               ; Signal to HW
                    EX   AF,AF'
                    RET
.end_FEP_EraseBlock_29F

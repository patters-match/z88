     XLIB FlashEprCardErase

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

     LIB FlashEprCardId, FlashEprBlockErase, MemDefBank, ExecRoutineOnStack

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"
     INCLUDE "interrpt.def"


; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_ERA = $20           ; erase sector (64Kb) command
DEFC FE_CON = $D0           ; confirm erasure
DEFC VppBit = 1
; ==========================================================================================


; ***************************************************************
;
; Erase Flash Memory Card inserted in slot C. 
;
; The routine will internally ask the Flash Memory for identification 
; and intelligently use the correct erasing algorithm. 
;
; Important: 
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 
; to successfully erase the memory chip. If the Flash Memory card is 
; inserted in slot 1 or 2, this routine will automatically report a
; sector erase failure error.
;
; It is the responsibility of the application (before using this call)
; to evaluate the Flash Memory (using the FlashEprCardId routine) and 
; warn the user that an INTEL Flash Memory Card requires the Z88 
; slot 3 hardware, so this type of unnecessary error can be avoided.
;
; IN:
;         C = slot number (1, 2 or 3) of Flash Memory Card
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
;    Gunther Strube, InterLogic, Dec 1997-Apr 1998, Aug 2004
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
.FlashEprCardErase
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    CALL FlashEprCardId      ; poll for card information in slot C (returns B = total banks of card)
                    JR   C, exit_FlashEprCardErase

                    CP   FE_28F
                    JR   Z, erase_28F_card
                    CP   FE_29F
                    JR   Z, erase_29F_card
                    RET
.erase_28F_card
                    LD   A,3
                    CP   C                   ; when chip is FE_28F series, we need to be in slot 3
                    JR   Z,_erase_28F_card   ; to make a successful card erase
                    SCF
                    LD   A, RC_BER           ; Ups, not in slot 3, signal error!
                    RET                      
._erase_28F_card                             ; The Intel 28Fxxxx chip can only erase individual sectors...
                    RRC  B                   ; so we need to erase the sectors, one at a time
                    RRC  B                   ; total of banks on card -> total of sectors on card.
                    DEC  B                   ; sectors, from 00 to (total sectors-1)
.erase_28F_card_blocks
                    CALL FlashEprBlockErase  ; erase top sector of card, and downwards...
                    JR   C, exit_FlashEprCardErase
                    DEC  B
                    LD   A,B
                    CP   -1
                    JR   NZ, erase_28F_card_blocks
                    JR   exit_FlashEprCardErase

.erase_29F_card
                    LD   A,C
                    AND  @00000011           ; only slots 0, 1, 2 or 3 possible
                    LD   C,A
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    LD   B,A                 ; bottom bank of slot C
                    LD   C,MS_S1             ; that are specified to be erased
                    CALL MemDefBank
                    PUSH BC                  ; preserve old bank binding

                    CALL OZ_DI               ; disable IM 1 interrupts
                    EX   AF,AF'              ; old interrupt status in AF'

                    PUSH IX                    
                    LD   IX, FEP_EraseCard_29F
                    LD   BC, end_FEP_EraseCard_29F - FEP_EraseCard_29F
                    CALL ExecRoutineOnStack
                    POP  IX

                    EX   AF,AF'              ; get old interrupt status in AF
                    CALL OZ_EI               ; enable IM 1 interrupts...
                    EX   AF,AF'              ; return AF error status of sector erasing...

                    POP  BC
                    CALL MemDefBank          ; Restore previous Bank bindings
                    
.exit_FlashEprCardErase
                    POP  HL
                    POP  DE
                    POP  BC
                    RET
                    

; ***************************************************************
;
; Erase an AMD 29Fxxxx Flash Memory Card, which is bound
; into segment 1 ($4000 - $7FFF).
;
; In:
;    -
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
.FEP_EraseCard_29F
                    LD   HL, $4555
                    LD   DE, $42AA

                    LD   (HL),$AA            ; AA -> (XX555), First Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$55            ; 55 -> (XX2AA), Second Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$80            ; 80 -> (XX555), Erase Mode
                                             ; sub command...
                    LD   (HL),$AA            ; AA -> (XX555), First Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$55            ; 55 -> (XX2AA), Second Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$10            ; 10 -> (XX555), Begin erasing card...
.toggle_wait_loop
                    LD   A,(HL)              ; get first DQ6 programming status
                    LD   C,A                 ; get a copy programming status (that is not XOR'ed)...
                    XOR  (HL)                ; get second DQ6 programming status
                    BIT  6,A                 ; toggling? 
                    RET  Z                   ; no, we're back in Read Array Mode and card was successfully erased!
                    BIT  5,C                 ; 
                    JR   Z, toggle_wait_loop ; we're toggling with no error signal and waiting to complete...
                    
                    LD   A,(HL)              ; DQ5 went high, we need to get two successive status
                    XOR  (HL)                ; toggling reads to determine if we're still toggling 
                    BIT  6,A                 ; which then indicates a card erase error...
                    JR   NZ,erase_err_29f    ; damn, card was NOT erased!
                    RET                      ; card was successfully erased, and we're back in Read Array Mode!
.erase_err_29f
                    LD   (HL),$F0            ; F0 -> (XXXXX), force Flash Memory to Read Array Mode
                    SCF
                    LD   A, RC_BER           ; signal sector erase error to application
                    RET
.end_FEP_EraseCard_29F

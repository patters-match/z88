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
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB MemDefBank

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"
     INCLUDE "interrpt.def"

     DEFC VppBit = 1

; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)
DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_ERA = $20           ; erase block (64Kb) command
DEFC FE_CON = $D0           ; confirm erasure
; ==========================================================================================

; ***************************************************************
;
; Erase Flash Eprom 64K Block number, defined in A (0 - xx)
; (16 blocks in total define the 1MB chip size)
;
; This routine will temporarily set the Vpp pin while the block is 
; being erased.
;
; IN:
;         A = 64K Block number on chip to be erased (0 - xx)
;              (available block numbers depend on chip size)
;
; OUT:
;         Success:
;              Fc = 0
;              A = 0
;         Failure:
;              Fc = 1
;              A = RC_BER
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; ---------------------------------------------------------------
; Design & programming by:
;    Gunther Strube, InterLogic, Dec 1997 - Apr 1998
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
.FlashEprBlockErase
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    AND  @00001111           ; number range is only 0 - 15...
                    ADD  A,A                 ; block number * 4
                    ADD  A,A                 ; (convert to first bank no of block)
                    OR   $C0                 ; bank located in slot 3...
                    LD   B,A

                    LD   HL,$4000
                    LD   C,MS_S1             ; use segment 1 for block erasing
                    CALL MemDefBank          ; bind bank...
                    CALL DisableInt

                    CALL FEP_EraseBlock

                    CALL EnableInt
                    CALL MemDefBank          ; Restore previous Bank bindings

                    CP   A                   ; Preset Fc = 0 (success)
                    LD   B,0                 ; No error code
                    BIT  3,A
                    CALL NZ,vpp_error
                    BIT  5,A
                    CALL NZ,erase_error
                    LD   A,B                 ; return error code

                    POP  HL
                    POP  DE
                    POP  BC
                    RET

.vpp_error          LD   B, RC_VPL
                    SCF
                    RET
.erase_error        LD   B, RC_BER
                    SCF
                    RET


; ***************************************************************
;
; Erase block, identified by bank B, using segment 1, at slot 3.
; This routine will clone itself on the stack and execute there.
;
; In:
;    B = first bank of block in Flash Eprom
;    HL = pointer to first memory location in block
; Out:
;    A = Intel Chip Status Register flags
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.FEP_EraseBlock
                    PUSH BC
                    EXX
                    LD   HL,0
                    ADD  HL,SP
                    EX   DE,HL
                    LD   HL, -(RAM_code_end - RAM_code_start)
                    ADD  HL,SP
                    LD   SP,HL               ; buffer for routine ready...
                    PUSH DE                  ; preserve original SP
                    
                    PUSH HL
                    EX   DE,HL               ; DE points at <RAM_code_start>
                    LD   HL, RAM_code_start
                    LD   BC, RAM_code_end - RAM_code_start
                    LDIR                     ; copy RAM routine...
                    LD   HL,exit_eraseblock
                    EX   (SP),HL
                    PUSH HL
                    EXX
                    RET                      ; CALL RAM_code_start
.exit_eraseblock
                    EXX
                    POP  HL                  ; original SP
                    LD   SP,HL
                    EXX
                    POP  BC
                    RET            
          
; 38 bytes on stack to be executed... 
.RAM_code_start     
                    PUSH AF
                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  VppBit,A            ; Vpp On
                    LD   (BC),A
                    OUT  (C),A               ; Enable Vpp in slot 3
                    POP  AF

                    LD   (HL), FE_ERA
                    LD   (HL), FE_CON
.erase_busy_loop
                    LD   (HL), FE_RSR        ; (R)equest for (S)tatus (R)egister
                    LD   A,(HL)
                    BIT  7,A
                    JR   Z,erase_busy_loop   ; Chip still erasing the block...

                    LD   (HL), FE_CSR        ; Clear Flash Eprom Status Register
                    LD   (HL), FE_RST        ; Reset Flash Eprom to Read Array Mode

                    PUSH AF
                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    RES  VppBit,A            ; Vpp Off
                    LD   (BC),A
                    OUT  (C),A               ; Disable Vpp in slot 3
                    POP  AF
                    RET
.RAM_code_end

.DisableInt         PUSH AF
                    CALL OZ_DI
                    PUSH AF
                    POP  DE                  ; preserve Interrupt status in DE...
                    POP  AF
                    RET

.EnableInt          PUSH AF
                    PUSH DE
                    POP  AF                  ; get old interrupt status
                    CALL OZ_EI               ; restore interrupts...
                    POP  AF
                    RET

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
;
;***************************************************************************************************

     LIB SafeBHLSegment         ; Prepare BHL pointer to be bound into a safe segment outside this executing bank
     LIB MemDefBank             ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB ExecRoutineOnStack     ; Clone small subroutine on system stack and execute it
     LIB FlashEprCardId         ; Identify Flash Memory Chip in slot C
     LIB FlashEprPollSectorSize ; Poll for Flash chip sector size.
     LIB AM29Fx_InitCmdMode     ; Prepare AMD 29F/39F Flash Memory Command Mode sequence addresses

     INCLUDE "flashepr.def"
     INCLUDE "error.def"
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
; Erase sector (block) defined in B (00h-1Fh), on Flash Memory Card inserted in slot C.
;
; The routine will internally ask the Flash Memory for identification and intelligently
; use the correct erasing algorithm. All known Flash Memory chips from Intel and Amd
; (see flashepr.def) uses 64K sectors, except the AM29F010B 128K chip, which uses 16K sectors.
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
;         B = block/sector number on chip to be erased (00h - 1Fh)
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
; --------------------------------------------------------------------------------------------
; Design & programming by:
;    Gunther Strube, Dec 1997-Apr 1998, Aug 2004, Aug 2006, Oct 2007
;    Thierry Peycru, Zlab, Dec 1997
;    Patrick Moore backported improvements from OZ 5.0 to standard library, July 2022
; --------------------------------------------------------------------------------------------
;
; now allows sectors in range 00-1F for 512K device with 32 16K sectors

.FlashEprBlockErase
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   A,B
                    AND  @00011111                          ; sector number range is only 0 - 31...
                    LD   D,A                                ; preserve sector in D (not destroyed by FlashEprCardId)
                    LD   E,C                                ; preserve slot no in E (not destroyed by FlashEprCardId)
                    CALL FlashEprCardId                     ; poll for card information in slot C (returns B = total banks of card)
                    JR   C, exit_FlashEprBlockErase
                    EX   AF,AF'                             ; preserve FE Programming type in A'
                    LD   A,H                                ; get manufacturer ID
                    CP   FE_SST_MFCD                        ; test for SST device
                    JR   NZ,poll_sector_size
                    LD   A,FE_39F                           ; change FE programming type
                    EX   AF,AF'                             ; overwrite FE Programming type in A'
.poll_sector_size
                    CALL FlashEprPollSectorSize
                    JR   Z, _16K_block_fe                   ; yes, it's a 16K sector architecture (same as Z88 bank architecture!)
                    LD   A,D                                ; no, it's a 64K sector architecture
                    ADD  A,A                                ; sector number * 4 (16K * 4 = 64K!)
                    ADD  A,A                                ; (convert to first bank no of sector)
                    LD   D,A
._16K_block_fe
                    DEC  B                                  ; B = size of card, decrease 1 to get relative top bank number..
                    LD   A,C
                    AND  @00000011                          ; only slots 0, 1, 2 or 3 possible
                    JR   Z, calc_bankno                     ; we're in slot 0, so flash chip can only be in lower 512K of slot 0
                    BIT  5,B
                    JR   NZ,calc_bankno                     ; bank no of sector is on lower 512K address (128K or 512K chip), 
                    SET  5,D                                ; then use upper 512K address lines (to be compatible with hybrid card)
.calc_bankno
                    RRCA
                    RRCA                                    ; Converted to Slot mask $40, $80 or $C0
                    OR   D                                  ; the absolute bank which is the bottom of the sector
                    LD   D,A                                ; preserve a copy of bank number in D
                    AND  @00111111
                    LD   C,A
                    BIT  5,B    
                    JR   NZ,check_size
                    RES  5,C                                ; Card < 1Mb: for calculation, adjust bank number within size of card...
.check_size                    
                    INC  C                                  ; this is the X'th bank of the card..
                    LD   A,B                 
                    INC  A                                  ; make sure that the Flash Memory Card (A = total 16K banks on Card)
                    SUB  C                                  ; contains the sector (to be erased)
                    JR   NC, sector_exists                  ; (total_banks_on_card - sector_bank < 0) ...
                    LD   A,RC_BER                           ; Fc = 1, sector not available (could not erase block/sector)
                    JR   exit_FlashEprBlockErase
.sector_exists
                    LD   B,D                                ; bind sector to segment x
                    LD   HL,0
                    CALL SafeBHLSegment                     ; get a safe segment in C, HL points into segment (not this executing segment!)
                    CALL MemDefBank
                    PUSH BC                                 ; preserve old bank binding

                    EX   AF,AF'                             ; FE Programming type in A
                    DI                                      ; no maskable interrupts allowed while doing flash hardware commands...
                    CALL FEP_EraseBlock                     ; erase sector in slot C
                    EI                                      ; maskable interrupts allowed again
                                                            ; return AF error status of sector erasing...
                    POP  BC
                    CALL MemDefBank                         ; Restore previous Bank bindings

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
;    A = FE_28F or FE_29F or FE_39F (depending on Flash Memory type in slot)
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
                    JR   Z, erase_28F_block                 ; execute Intel sector erasure on stack, return error in AF...

.erase_29F_block                                            ; use this routine for both 29F & 39F chip types to reduce size
                    CALL AM29Fx_InitCmdMode                 ; prepare AMD 29F/39F Command Mode sequence addresses - doesn't need to run from RAM
                    LD   IX, FEP_EraseBlock_29F
                    EXX
                    LD   BC, end_FEP_EraseBlock_29F - FEP_EraseBlock_29F
                    EXX
                    JP   ExecRoutineOnStack
.erase_28F_block
                    LD   A,3
                    CP   E                                  ; when chip is FE_28F series, we need to be in slot 3
                    JR   Z,_erase_28F_block                 ; to make a successful sector erase
                    SCF
                    LD   A, RC_BER                          ; Oops, not in slot 3, signal error!
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
                    LD   BC,BLSC_COM                        ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  BB_COMVPPON,A                      ; Vpp On
                    SET  BB_COMLCDON,A                      ; Force Screen enabled (don't push 21V to Intel flash!)...
                    LD   (BC),A
                    OUT  (C),A                              ; signal to HW

                    LD   (HL), FE_ERA
                    LD   (HL), FE_CON
.erase_28f_busy_loop
                    LD   (HL), FE_RSR                       ; (R)equest for (S)tatus (R)egister
                    LD   A,(HL)
                    BIT  7,A
                    JR   Z,erase_28f_busy_loop              ; Chip still erasing the sector...

                    BIT  3,A
                    JR   NZ,vpp_error
                    BIT  5,A
                    JR   NZ,erase_error
                    CP   A                                  ; Sector successfully erased, Fc = 0

                    LD   (HL), FE_CSR                       ; Clear Status Register
                    LD   (HL), FE_RST                       ; Reset Flash Memory to Read Array Mode
.exit_FEP_EraseBlock_28F
                    EX   AF,AF'
                    LD   A,(BC)
                    RES  BB_COMVPPON,A                      ; Vpp Off
                    LD   (BC),A
                    OUT  (C),A                              ; Signal to hw
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


; ***********************************************************************************************
;
; Erases a 16K block on an AMD 29F/39F (or compatible) Flash Memory, which is bound
; into segment x that HL points into.
;
; erases in 4 x 4K sectors for 39Fxxxx
; or a single 16K/64K sector for 29Fxxxx
;
; In:
;    A = AMD chip type (FE_29F or FE_39F)
;    HL = points into bound Flash Memory sector
; Out:
;    Success:
;        Fc = 0
;        A = undefined
;    Failure:
;        Fc = 1
;        A = RC_BER (error occurred when erasing block/sector)
;
; -----------------------------------------------------------------------------------------------
; Design & programming by:
;       (C) Martin Roberts (mailmartinroberts@yahoo.co.uk), Jan 2018
;       Patrick Moore backported improvements from OZ 5.0 to standard library,  July 2022
;     & modularised AM29Fx_InitCmdMode and unified this routine for both 29F and 39F flash types
; -----------------------------------------------------------------------------------------------
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FEP_EraseBlock_29F                                  
                    EX   AF,AF'                             ; FE Programming type in A'
                    XOR  A                                  ; start with sector 0

.erase_block_29f_loop
                    PUSH AF                                 ; preserve sector

                    ; AM29Fx_EraseSector
                    ;     from the OZ 5.0 code (in os/lowram/flash.asm)
                    ;     we can't use a CALL to another function since .FEP_EraseBlock_29F to .end_FEP_EraseBlock_29F
                    ;     will be copied to the stack for execution, so the whole routine has been inserted
                    ;
                    ; ***************************************************************************************************
                    ; Erase block on an AMD 29F/39F (or compatible) Flash Memory, which is bound into segment x
                    ; that HL points into.
                    ;
                    ; In:
                    ;        A = sector address upper byte (for devices with 4K sectors, don't care for 64K sectors)
                    ;       BC = bank select sw copy address
                    ;       DE = address $2AAA + segment  (points into bound Flash Memory sector)
                    ;       HL = address $1555 + segment
                    ; Out:
                    ;    Success:
                    ;        Fz = 1
                    ;        A = undefined
                    ;    Failure:
                    ;        Fz = 0 (sector not erased)
                    ;
                    ; Registers changed after return:
                    ;    ......../IXIY same
                    ;    AFBCDEHL/.... different
                    ;
                    PUSH HL                                 ; preserve address $1555 + segment
                    PUSH AF                                 ; preserve sector again since we'll need to retrieve it twice
                    LD   A,$80                              ; Execute main Erase Mode

                    ; AM29Fx_CmdMode
                    ;     from the OZ 5.0 code (in os/lowram/flash.asm)
                    ;     we can't use a CALL to another function since .FEP_EraseBlock_29F to .end_FEP_EraseBlock_29F
                    ;     will be copied to the stack for execution, so the whole routine has been inserted
                    ;
                    ; ***************************************************************************************************
                    ; Execute AMD 29F/39F (or compatible) Flash Memory Chip Command
                    ; Maskable interrupts are disabled while chip is in command mode.
                    ;
                    ; In:
                    ;       A = AMD Command code, if A=0 command is not sent
                    ;       BC = bank select sw copy address
                    ;       DE = address $2AAA + segment
                    ;       HL = address $1555 + segment
                    ; Out:
                    ;       -
                    ;
                    ; Registers changed on return:
                    ;    ..BCDEHL/IXIY same
                    ;    AF....../.... different
                    ;
                    ;DI                                     ; not needed here because interrupts are disabled for the whole FEP_EraseBlock call                                                                                               
                    PUSH AF
                    LD   A,(BC)                             ; get current bank
                    OR   $01                                ; A14=1 for 5555 address
                    OUT  (C),A                              ; select it
                    LD   (HL),E                             ; AA -> (5555), First Unlock Cycle
                    EX   DE,HL
                    AND  $FE                                ; A14=0
                    OUT  (C),A                              ; select it
                    LD   (HL),E                             ; 55 -> (2AAA), Second Unlock Cycle
                    EX   DE,HL
                    OR   $01                                ; A14=1
                    OUT  (C),A                              ; select it
                    POP  AF                                 ; get command
                    OR   A                                  ; is it 0?
                    JR   Z,cmdmode1_exit                    ; don't write it if it is
                    LD   (HL),A                             ; A -> (5555), send command
.cmdmode1_exit
                    LD   A,(BC)                             ; restore original bank
                    OUT  (C),A                              ; select it
                    ; end AM29Fx_CmdMode


                    XOR  A                                  ; A=0, just write unlock sequence

                    ; AM29Fx_CmdMode
                    ;     from the OZ 5.0 code (in os/lowram/flash.asm)
                    ;     we can't use a CALL to another function since .FEP_EraseBlock_29F to .end_FEP_EraseBlock_29F
                    ;     will be copied to the stack for execution, so the whole routine has been inserted
                    ;
                    ; ***************************************************************************************************
                    ; Execute AMD 29F/39F (or compatible) Flash Memory Chip Command
                    ; Maskable interrupts are disabled while chip is in command mode.
                    ;
                    ; In:
                    ;       A = AMD Command code, if A=0 command is not sent
                    ;       BC = bank select sw copy address
                    ;       DE = address $2AAA + segment
                    ;       HL = address $1555 + segment
                    ; Out:
                    ;       -
                    ;
                    ; Registers changed on return:
                    ;    ..BCDEHL/IXIY same
                    ;    AF....../.... different
                    ;
                    ;DI                                     ; not needed here because interrupts are disabled for the whole FEP_EraseBlock call
                    PUSH AF
                    LD   A,(BC)                             ; get current bank
                    OR   $01                                ; A14=1 for 5555 address
                    OUT  (C),A                              ; select it
                    LD   (HL),E                             ; AA -> (5555), First Unlock Cycle
                    EX   DE,HL
                    AND  $FE                                ; A14=0
                    OUT  (C),A                              ; select it
                    LD   (HL),E                             ; 55 -> (2AAA), Second Unlock Cycle
                    EX   DE,HL
                    OR   $01                                ; A14=1
                    OUT  (C),A                              ; select it
                    POP  AF                                 ; get command
                    OR   A                                  ; is it 0?
                    JR   Z,cmdmode2_exit                    ; don't write it if it is
                    LD   (HL),A                             ; A -> (5555), send command
.cmdmode2_exit
                    LD   A,(BC)                             ; restore original bank
                    OUT  (C),A                              ; select it
                    ; end AM29Fx_CmdMode


                    RES  4,H                                ; HL -> 4K sector 0
                    POP  AF                                 ; retrieve sector address upper byte
                    AND  $30                                ; isolate 4K sector (don't care for 16/64K sector)
                    OR   H
                    LD   H,A                                ; HL -> required 4K sector
                    LD   (HL),$30                           ; write sub command (Block Erase)
                    POP  HL                                 ; retrieve address $1555 + segment
                    ; end AM29Fx_EraseSector


                    ; AM29Fx_ExeCommand, follows AM29Fx_EraseSector
                    ;     in the OZ 5.0 code (in os/lowram/flash.asm)
                    ;     we can't use a CALL to another function since .FEP_EraseBlock_29F to .end_FEP_EraseBlock_29F
                    ;     will be copied to the stack for execution, so the whole routine has been inserted
                    ; 
                    ; ***************************************************************************************************
                    ; Wait for AMD 29F/39F (or compatible) Flash Memory command to finish.
                    ;
                    ; In:
                    ;       HL points into bound bank of potential Flash Memory
                    ; Out:
                    ;       A = undefined
                    ;       Fz = 1, Command has been executed successfully
                    ;       Fz = 0, Command execution failed
                    ;
                    ; Registers changed on return:
                    ;    ..BCDEHL/IXIY same
                    ;    AF....../.... different
                    ;
                    PUSH BC
.exe_command_loop
                    LD   A,(HL)                             ; get first DQ6 programming status                                                                                                                        
                    LD   C,A                                ; get a copy programming status (that is not XOR'ed)...
                    XOR  (HL)                               ; get second DQ6 programming status
                    BIT  6,A                                ; toggling?
                    JR   Z,exe_command_ret                  ; no, command completed successfully (Read Array Mode active)!
                    BIT  5,C                                ;
                    JR   Z, exe_command_loop                ; we're toggling with no error signal and waiting to complete...
                    LD   A,(HL)                             ; DQ5 went high, we need to get two successive status
                    XOR  (HL)                               ; toggling reads to determine if we're still toggling
                    BIT  6,A                                ; which then indicates a command error...
                    JR   Z,exe_command_ret                  ; we're back in Read Array Mode, command completed successfully!
                    LD   (HL),$F0                           ; command failed! F0 -> (XXXXX), force Flash Memory to Read Array Mode

.erase_err_29f      ; changed this part to better match the original stdlib code
                    SCF
                    LD   A, RC_BER                          ; signal sector erase error to application
                    ; end change
.exe_command_ret
                    POP  BC
                    ;EI                                     ; not needed here because interrupts are disabled for the whole FEP_EraseBlock call
                    ; end AM29Fx_ExeCommand


                    JR   C,erase_block_29f_exit             ; exit on failure
                    EX   AF,AF'                             ; retrieve chip type (29F/39F)
                    CP   FE_29F                             ; is it a 29F chip?
                    JR   Z,erase_block_29f_exit             ; if so - finished, single 16K/64K sector has been erased
                    EX   AF,AF'                             ; preserve chip type for next erase_block_29f_loop
                    POP  AF                                 ; retrieve sector
                    ADD  A,$10                              ; next 4K sector for 39F chip
                    BIT  6,A
                    JR   Z,erase_block_29f_loop
                    RET                                     ; carry flag is 0
.erase_block_29f_exit
                    POP  HL                                 ; remove AF from stack without changes to flags
                    RET
.end_FEP_EraseBlock_29F
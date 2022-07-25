     XLIB FlashEprCardId

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

     LIB SafeBHLSegment       ; Prepare BHL pointer to be bound into a safe segment outside this executing bank
     LIB MemDefBank           ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB MemGetCurrentSlot    ; Get current slot number of this executing library routine in C
     LIB ExecRoutineOnStack   ; Clone small subroutine on system stack and execute it
     LIB FlashEprCardData     ; get data about Flash type & size

     INCLUDE "flashepr.def"
     INCLUDE "error.def"
     INCLUDE "memory.def"
     INCLUDE "blink.def"

; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_IID = $90           ; get INTELligent identification code (manufacturer and device)
; ==========================================================================================



; ******************************************************************************************
;
; Identify Flash Memory Chip in slot C.
;
; In:
;         C = slot number (0, 1, 2 or 3)
; Out:
;         Success:
;              Fc = 0, Fz = 1
;              A = FE_28F or FE_29F, defining the Flash Memory chip generation
;              HL = Flash Memory ID
;                   H = Manufacturer Code (FE_INTEL_MFCD, FE_AMD_MFCD)
;                   L = Device Code (refer to flashepr.def)
;              B = total of 16K banks on Flash Memory Chip.
;
;         Failure:
;              Fc = 1
;              A = RC_NFE (not a recognized Flash Memory Chip)
;
; Registers changed on return:
;    ...CDE../IXIY af...... same
;    AFB...HL/.... ..bcdehl different
;
; --------------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Dec 1997-Apr 1998, Jul-Sep 2004, Sep 2005, Aug 2006, Oct 2007
;    Thierry Peycru, Zlab, Dec 1997
;    patters backported improvements from OZ 4.7.1RC and OZ 5.0 to standard library, July 2022
; --------------------------------------------------------------------------------------------
;
.FlashEprCardId
                    PUSH IY
                    PUSH DE
                    PUSH BC

                    LD   A,C
                    AND  @00000011           ; only slots 0, 1, 2 or 3 possible
                    LD   E,A                 ; preserve a copy of slot argument in E
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    LD   B,A
                    LD   HL,0
                    CALL SafeBHLSegment      ; get a safe segment in C, HL points into segment (not this executing segment!)

                    INC  E
                    DEC  E
                    JR   Z, check_flashchip  ; skip RAM check for upper 512K in slot 0 (always available!)

                    PUSH BC                  ; check for hybrid hardware; 512K RAM (bottom) and 512K Flash (top)
                    LD   A,B
                    OR   $3F
                    LD   B,A                 ; point at top of bank of slot

                    CALL CheckRam
                    LD   A,B
                    POP  BC
                    JR   C, unknown_flashmem ; abort, if RAM card was found in top of slot C...
.check_flashchip
                    PUSH BC
                    LD   B,A
                    CALL NC,FetchCardID      ; if not RAM, get info of AMD Flash Memory chip in top of slot (if avail in slot C)...
                    POP  BC
                    JR   C,check_bottom_slot
                    PUSH BC
                    CALL FlashEprCardData    ; AMD flash might have been found, try to get card ID data...
                    LD   D,B
                    POP  BC
                    JR   C,check_bottom_slot
                    LD   B,D                 ; return B = total banks of card
                    JR   got_cardid
.check_bottom_slot                           ; top bank in slot revealed no AMD/AMIC, now try poll bottom bank of slot..
                    LD   HL,0
                    CALL SafeBHLSegment      ; get a safe segment in C, HL points into segment (not this executing segment!)
                    CALL CheckRam
                    JR   C, unknown_flashmem ; abort, if RAM card was found in bottom of slot C...
                                        
                    CALL FetchCardID         ; get info of intel Flash Memory at bottom of chip in HL (if avail in slot C)...
                    JR   C, unknown_flashmem ; no ID's were polled from a (potential FE card)
.get_crddata
                    CALL FlashEprCardData    ; verify Flash Memory ID with known Manufacturer & Device Codes
                    JR   C, unknown_flashmem
.got_cardid                                  ; H = Manufacturer Code, L = Device Code
                    POP  DE                  ; B = banks on card, A = chip series (28F or 29F)
                    LD   C,E                 ; original C restored
.end_FlashEprCardId
                    POP  DE                  ; original DE restored
                    POP  IY
                    RET                      ; Fc = 0, Fz = 1
.unknown_flashmem
                    LD   A, RC_NFE
                    SCF                      ; signal error...
                    POP  BC
                    JR   end_FlashEprCardId


; ***************************************************************
;
; Get the Manufacturer and Device Code from a Flash Eprom Chip
; inserted in slot C (Bottom bank of slot C has already been
; bound into segment 1; address $0000 - $3FFF is bound at
; $4000 - $7FFF)
;
; This routine will poll for known Intel I28Fxxxx and AMD AM29Fxxx
; Flash Memory chips and return the appropriate ID, if a card
; is recognized.
;
; The core polling routines are cloned on the stack and
; executed there, which allowes this library routine to be
; executed on the card itself that are being polled.
;
; In:
;    HL = points into bound bank of potential Flash Memory
;     E = API slot number
;
; Out:
;    Fc = 0 (FE was recognized in slot C)
;         H = manufacturer code (at $00 0000 on chip)
;         L = device code (at $00 0001 on chip)
;    Fc = 1 (FE was NOT recognized in slot C)
;
; Registers changed on return:
;    A...DE../IX.. af...... same
;    .FBC..HL/..IY ..bcdehl different
;
.FetchCardID
                    PUSH AF
                    PUSH DE
                    PUSH IX

                    LD   A,E                 ; slot number supplied to this library from outside caller...

                    CALL MemDefBank          ; Get bottom Bank of slot C into segment 1
                    PUSH BC                  ; old bank binding in BC...

                    PUSH HL
                    POP  IY                  ; preserve pointer to Flash Memory segment

                    LD   D,(HL)
                    INC  HL                  ; get a copy into DE of the slot contents at the location
                    LD   E,(HL)              ; where the ID is fetched (through the FE command interface)
                    DEC  HL                  ; back at $00 0000

                    CALL MemGetCurrentSlot        ; get specified slot number in C for this executing library routine
                    CP   C                        ; and compare it with the slot number of this executing library
                    CALL Z,I28Fx_PollChipId_RAM ; this code runs on same Flash chip to be polled, run INTEL card ID routine in RAM...
                    CALL NZ,I28Fx_PollChipId    ; this code runs in another slot, just execute card ID poll normally...

                    PUSH HL
                    CP   A                        ; Fc = 0
                    SBC  HL,DE                    ; Assume that no INTEL Flash Memory ID is stored at that location!
                    POP  HL                       ; if the ID in HL is different from DE
                    JR   NZ, found_FetchCardID    ; then an ID was fetched from an INTEL FlashFile Memory...

                    PUSH IY
                    POP  HL                       ; pointer to Flash Memory segment
                    CP   C
                    CALL Z,AM29Fx_PollChipId_RAM ; this code runs on same Flash chip to be polled, run AMD card ID routine in RAM...
                    CALL NZ,AM29Fx_PollChipId    ; this code runs in another slot, just execute card ID poll normally...

                    PUSH HL
                    CP   A                        ; Fc = 0
                    SBC  HL,DE
                    POP  HL
                    JR   NZ, found_FetchCardID    ; if the ID in HL is equal to DE
                    SCF                           ; then no AMD Flash Memory responded to the ID request...
                    JR   exit_FetchCardID
.found_FetchCardID
                    CP   A
.exit_FetchCardID
                    POP  BC
                    CALL MemDefBank            ; restore original bank in segment 1 (defined in BC)

                    POP  IX
                    POP  DE
                    POP  BC                    ; get preserved AF
                    LD   A,B                   ; restore original A
                    RET


; ***************************************************************
; Execute Card ID polling for Intel Flash on system stack
;
.I28Fx_PollChipId_RAM
                    LD   IX, I28Fx_PollChipId
                    EXX
                    LD   BC, end_I28Fx_PollChipId - I28Fx_PollChipId
                    EXX
                    JP   ExecRoutineOnStack    ; run card ID routine in RAM...

; ***************************************************************
;
; Polling code for I28F0xxxx (INTEL) FlashFile Memory Chip ID
;
; In:
;    HL points into bound bank of potential Flash Memory
;
; Out:
;    H = manufacturer code (at $00 0000 on chip)
;    L = device code (at $00 0001 on chip)
;
; Registers changed on return:
;    AFBCDE../IXIY same
;    ......HL/.... different
;
.I28Fx_PollChipId
                    PUSH DE
                    DI                       ; no maskable interrupts allowed while doing flash hardware commands

                    LD   (HL), FE_IID        ; FlashFile Memory Card ID command
                    LD   D,(HL)              ; D = Manufacturer Code (at $00 0000)
                    INC  HL
                    LD   E,(HL)              ; E = Device Code (at $00 0001)
                    LD   (HL), FE_RST        ; Reset Flash Memory Chip to read array mode
                    EX   DE,HL

                    EI                       ; allow Blink interrupts, Intel chip is in Read Array Mode again
                    POP  DE
                    RET
.end_I28Fx_PollChipId


; ***************************************************************
; Execute Card ID polling for AMD Flash on system stack
;
.AM29Fx_PollChipId_RAM
                    LD   IX, AM29Fx_PollChipId
                    EXX
                    LD   BC, end_AM29Fx_PollChipId - AM29Fx_PollChipId
                    EXX
                    JP   ExecRoutineOnStack  ; run card ID routine in RAM...

; ***************************************************************
;
; Polling code for AM29F0xxx / ST29F0xxx (AMD/STM) Flash Memory Chip ID
; adapted from the OZ 4.7.1 code (os/lowram/flash.asm)
; In:
;    HL = points into bound bank of potential Flash Memory
;
; Out:
;    H = manufacturer code (at $00 0000 on chip)
;    L = device code (at $00 0001 on chip)
;
; Registers changed on return:
;    AF..DE../IXIY same
;    ..BC..HL/.... different
;
.AM29Fx_PollChipId
                    PUSH AF
                    PUSH DE

                    ; AM29Fx_InitCmdMode
                    ;     from the OZ 4.7.1 code (in os/osfep/osfep.asm)
                    ;     we can't use a CALL to another function since .AM29Fx_PollChipId to .end_AM29Fx_PollChipId
                    ;     will be copied to the stack for execution, so the whole routine has been inserted in full

                    ; ***************************************************************************************************
                    ; Prepare AMD Command Mode sequence addresses.
                    ;
                    ; In:
                    ;       HL points into bound bank of Flash Memory
                    ; Out:
                    ;       BC = bank select sw copy address
                    ;       DE = address $2AAA + segment  (derived from HL)
                    ;       HL = address $1555 + segment  (derived from HL)
                    ;
                    ; Registers changed on return:
                    ;    AF....../IXIY same
                    ;    ..BCDEHL/.... different
                    ;
                    ;PUSH AF
                    LD   A,H
                    AND  @11000000
                    LD   D,A
                    LD   BC,BLSC_SR0
                    RLCA
                    RLCA
                    OR   C
                    LD   C,A                             ; BC = bank select sw copy address
                    LD   A,D
                    OR   $15
                    LD   H,A
                    LD   L,$55                           ; HL = address $1555 + segment
                    LD   A,D
                    OR   $2A
                    LD   D,A
                    LD   E,$AA                           ; DE = address $2AAA + segment
                    ;POP  AF
                    ; end AM29Fx_InitCmdMode

                    LD   A,$90                           ; autoselect mode (to get ID)
                    DI                                   ; no maskable interrupts allowed while doing flash hardware commands                          

                    ; AM29Fx_CmdMode
                    ;     from the OZ 4.7.1 code (in os/lowram/flash.asm)
                    ;     we can't use a CALL to another function since .AM29Fx_PollChipId to .end_AM29Fx_PollChipId
                    ;     will be copied to the stack for execution, so the whole routine has been inserted in full

                    ; ***************************************************************************************************
                    ; Execute AM29F0xxx / ST29F0xxx (AMD/STM) Flash Memory Chip Command
                    ; Maskable interrupts should be disabled while chip is in command mode.
                    ;
                    ; In:
                    ;       A = AMD/STM Command code, if A=0 command is not sent
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
                          PUSH AF
                          LD   A,(BC)                          ; get current bank
                          OR   $01                             ; A14=1 for 5555 address
                          OUT  (C),A                           ; select it
                          LD   (HL),E                          ; AA -> (5555), First Unlock Cycle
                          EX   DE,HL
                          AND  $FE                             ; A14=0
                          OUT  (C),A                           ; select it
                          LD   (HL),E                          ; 55 -> (2AAA), Second Unlock Cycle
                          EX   DE,HL
                          OR   $01                             ; A14=1
                          OUT  (C),A                           ; select it
                          POP  AF                              ; get command
                          OR   A                               ; is it 0?
                          JR   Z,cmdmode_exit                  ; don't write it if it is
                          LD   (HL),A                          ; A -> (5555), send command
                    .cmdmode_exit
                          LD   A,(BC)                          ; restore original bank
                          OUT  (C),A                           ; select it
                    ; end AM29Fx_CmdMode

                    LD   L,0
                    LD   A,H
                    AND  @11000000
                    LD   H,A
                    LD   D,(HL)                          ; get Manufacturer Code (at X000)
                    INC  HL
                    LD   E,(HL)                          ; get Device Code (at X001)
                    LD   (HL),$F0                        ; F0 -> (XXXXX), set Flash Memory to Read Array Mode
                    EX   DE,HL                           ; H = Manufacturer Code, L = Device Code
                    POP  DE
                    POP  AF
                    EI                                   ; allow Blink interrupts again
                    RET
.end_AM29Fx_PollChipId
                    
; ***************************************************************
;
; Investigate if a RAM card is inserted in slot C
; (by trying to write a byte to address $00 0000 and
; verify that it was properly written)
;
; IN:
;    HL points into bank of potential Flash Memory or RAM
;
; OUT:
;    Fc = 0, empty slot or EPROM/FLASH Card in slot C
;    Fc = 1, RAM card found in slot C
;
; Registers changed on return:
;   A.BCDEHL/IXIY same
;   .F....../.... different
;
.CheckRam
                    PUSH BC
                    CALL MemDefBank          ; Get bottom Bank of slot C into segment 1
                    PUSH BC                  ; old bank binding in BC...
                    PUSH AF

                    LD   B,(HL)              ; preserve the original byte (needs to be restored)
                    LD   A,1                 ; initial test bit pattern (bit 0 set)
.test_ram_loop
                    LD   (HL),A              ; write bit pattern to card at bottom location
                    CP   (HL)                ; and check whether it was written
                    JR   NZ, not_written     ; bit pattern wasn't written...
                    RLCA                     ; check that all bits are written properly
                    JR   NC, test_ram_loop
.exit_CheckRam                               ; this is a RAM card!  (Fc = 1)
                    LD   (HL),B              ; restore original byte at RAM location
                    POP  BC
                    LD   A,B                 ; restore original A
                    POP  BC
                    CALL MemDefBank          ; restore original bank in segment 1 (defined in BC)

                    POP  BC
                    RET
.not_written
                    CP   A                   ; Fc = 0, this is not a RAM card
                    JR   exit_CheckRam

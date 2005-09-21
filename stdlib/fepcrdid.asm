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
; $Id$
;
;***************************************************************************************************

     LIB SafeBHLSegment, MemDefBank, MemGetCurrentSlot, ExecRoutineOnStack

     INCLUDE "interrpt.def"
     INCLUDE "flashepr.def"
     INCLUDE "memory.def"

; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_IID = $90           ; get INTELligent identification code (manufacturer and device)
; ==========================================================================================



; ***************************************************************************************
;
; Identify Flash Memory Chip in slot C.
;
; In:
;         C = slot number (1, 2 or 3)
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
;    ...CDE../IXIY ........ same
;    AFB...HL/.... afbcdehl different
;
; ---------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997-Apr 1998, Jul-Sep 2004, Sep 2005
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------------------------------
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

                    CALL CheckRam
                    JR   C, unknown_flashmem ; abort, if RAM card was found in slot C...

                    CALL FetchCardID         ; get info of Flash Memory chip in HL (if avail in slot C)...
                    JR   C, unknown_flashmem ; no ID's were polled from a (potential FE card)

                    CALL VerifyCardID        ; verify Flash Memory ID with known Manufacturer & Device Codes
                    JR   C, unknown_flashmem
                                             ; H = Manufacturer Code, L = Device Code
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
;    A.BCDE../IX.. af...... same
;    .F....HL/..IY ..bcdehl different
;
.FetchCardID
                    PUSH BC
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
                    CALL Z,Fetch_I28F0xxxx_ID_RAM ; this code runs on same Flash chip to be polled, run INTEL card ID routine in RAM...
                    CALL NZ,Fetch_I28F0xxxx_ID    ; this code runs in another slot, just execute card ID poll normally...

                    PUSH HL
                    CP   A                        ; Fc = 0
                    SBC  HL,DE                    ; Assume that no INTEL Flash Memory ID is stored at that location!
                    POP  HL                       ; if the ID in HL is different from DE
                    JR   NZ, found_FetchCardID    ; then an ID was fetched from an INTEL FlashFile Memory...

                    PUSH IY
                    POP  HL                       ; pointer to Flash Memory segment
                    CP   C
                    CALL Z,Fetch_AM29F0xxx_ID_RAM ; this code runs on same Flash chip to be polled, run AMD card ID routine in RAM...
                    CALL NZ,Fetch_AM29F0xxx_ID    ; this code runs in another slot, just execute card ID poll normally...

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
                    POP  BC
                    RET


; ***************************************************************
; Execute Card ID polling for Intel Flash on system stack
;
.Fetch_I28F0xxxx_ID_RAM
                    LD   IX, Fetch_I28F0xxxx_ID
                    EXX
                    LD   BC, end_Fetch_I28F0xxxx_ID - Fetch_I28F0xxxx_ID
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
.Fetch_I28F0xxxx_ID
                    PUSH AF
                    CALL OZ_DI               ; no IM 1 interrupts while we poll for Flash Memory stuff...
                    PUSH AF                  ; preserve interupt status

                    PUSH DE
                    LD   (HL), FE_IID        ; FlashFile Memory Card ID command
                    LD   D,(HL)              ; D = Manufacturer Code (at $00 0000)
                    INC  HL
                    LD   E,(HL)              ; E = Device Code (at $00 0001)
                    LD   (HL), FE_RST        ; Reset Flash Memory Chip to read array mode
                    EX   DE,HL
                    POP  DE

                    POP  AF                  ; get old interupt status
                    CALL OZ_EI               ; enable IM 1 interrupts again...
                    POP  AF
                    RET
.end_Fetch_I28F0xxxx_ID


; ***************************************************************
; Execute Card ID polling for AMD Flash on system stack
;
.Fetch_AM29F0xxx_ID_RAM
                    LD   IX, Fetch_AM29F0xxx_ID
                    EXX
                    LD   BC, end_Fetch_AM29F0xxx_ID - Fetch_AM29F0xxx_ID
                    EXX
                    JP   ExecRoutineOnStack  ; run card ID routine in RAM...

; ***************************************************************
;
; Polling code for AM29F0xxx (AMD) Flash Memory Chip ID
;
; In:
;    HL = points into bound bank of potential Flash Memory
;
; Out:
;    H = manufacturer code (at $00 0000 on chip)
;    L = device code (at $00 0001 on chip)
;
; Registers changed on return:
;    AFBCDE../IXIY same
;    ......HL/.... different
;
.Fetch_AM29F0xxx_ID
                    PUSH AF
                    CALL OZ_DI               ; no IM 1 interrupts while we poll for Flash Memory stuff...
                    PUSH AF                  ; preserve interupt status

                    PUSH BC
                    PUSH DE

                    PUSH HL
                    LD   A,H
                    AND  @11000000
                    LD   H,A
                    LD   D,A
                    OR   $05
                    LD   H,A
                    LD   L,$55               ; HL = $x555
                    LD   A,D
                    OR   $02
                    LD   D,A
                    LD   E,$AA               ; DE = $x2AA

                    LD   (HL),$AA            ; AA -> (XX555), first unlock cycle
                    EX   DE,HL
                    LD   (HL),$55            ; 55 -> (XX2AA), second unlock cycle
                    EX   DE,HL
                    LD   (HL),$90            ; 90 -> (XX555), autoselect mode
                    POP  HL

                    LD   D,(HL)
                    INC  HL
                    LD   E,(HL)
                    LD   (HL),$F0            ; F0 -> (XXXXX), set Flash Memory to Read Array Mode
                    EX   DE,HL               ; H = Manufacturer Code (at $00 XX00)
                                             ; L = Device Code (at $00 XX01)
                    POP  DE
                    POP  BC

                    POP  AF                  ; old interrupt status
                    CALL OZ_EI               ; enable IM 1 interrupts again...
                    POP  AF
                    RET
.end_Fetch_AM29F0xxx_ID


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
;   ..BCDEHL/IXIY same
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


; ***************************************************************
;
; IN:
;    HL = Polled from potential Flash Memory Chip:
;         Manufacturer & Device Code
;
; OUT:
;    Fc = 0
;       ID was found (verified):
;       A = chip generation (FE_28F or FE_29F)
;       B = total of 16K banks on Flash Memory
;    Fc = 1
;      ID was not found (not verified)
;
; Registers changed on return:
;   ...CDEHL/IXIY same
;   AFB...../.... different
;
.VerifyCardID       PUSH HL
                    PUSH DE
                    PUSH BC
                    PUSH AF

                    EX   DE,HL
                    LD   HL, DeviceCodeTable
                    LD   B,(HL)                   ; no. of Flash Memory ID's in table
                    INC  HL
                    LD   A,E
.find_loop          CP   (HL)                     ; Device Code found?
                    INC  HL                       ; points at Manufacturer Code
                    JR   NZ, get_next0
                         LD   A,D
                         CP   (HL)                     ; Manufacturer Code found?
                         INC  HL                       ; points at no of banks of Flash Memory
                         JR   NZ, get_next1
                         LD   B,(HL)                   ; B = total of 16K banks on Flash Eprom
                         INC  HL
                         LD   A,(HL)                   ; A = chip generation
                         JR   verified_id              ; Fc = 0, Flash Eprom data returned...
.get_next0          INC  HL                       ; points at no of banks
.get_next1          INC  HL                       ; points at chip generation
                    INC  HL                       ; point at next entry...
                    DJNZ find_loop                ; and check for new Device Code

                    POP  AF                       ; Ups, Manufacturer and Device Code wasn't verified
                    SCF                           ; indicate error
                    POP  BC                       ; restore original BC on error
                    POP  DE
                    POP  HL
                    RET
.verified_id
                    POP  DE                       ; ignore old AF, return FE_28F or FE29F in A
                    POP  DE
                    LD   C,E                      ; restore original C (B hold total banks of card
                    POP  DE
                    POP  HL
                    RET
.DeviceCodeTable
                    DEFB 7

                    DEFW FE_I28F004S5
                    DEFB 32, FE_28F               ; 8 x 64K sectors / 32 x 16K banks (512Kb)

                    DEFW FE_I28F008SA
                    DEFB 64, FE_28F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)

                    DEFW FE_I28F008S5
                    DEFB 64, FE_28F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)

                    DEFW FE_I28F016S5
                    DEFB 64, FE_28F               ; 32 x 64K sectors / 128 x 16K banks (2048Kb) (appears like FE_I28F008S5)

                    DEFW FE_AM29F010B
                    DEFB 8, FE_29F                ; 8 x 16K sectors / 8 x 16K banks (128Kb)

                    DEFW FE_AM29F040B
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512Kb)

                    DEFW FE_AM29F080B
                    DEFB 64, FE_29F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)

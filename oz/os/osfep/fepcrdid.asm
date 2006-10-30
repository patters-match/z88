     MODULE FlashEprCardId

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

     XDEF FlashEprCardId

     LIB DisableBlinkInt      ; No interrupts get out of Blink
     LIB EnableBlinkInt       ; Allow interrupts to get out of Blink

     XREF FlashEprCardData    ; get data about Flash type & size

     INCLUDE "flashepr.def"
     INCLUDE "lowram.def"
     INCLUDE "memory.def"


; ***************************************************************************************
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
; ---------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Dec 1997-Apr 1998, Jul-Sep 2004, Sep 2005, Aug 2006, Oct-Nov 2006
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------------------------------
;
.FlashEprCardId
                    PUSH IY
                    PUSH DE
                    PUSH BC
                    CALL DisableBlinkInt     ; no interrupts get out of Blink...

                    LD   A,C
                    AND  @00000011           ; only slots 0, 1, 2 or 3 possible
                    LD   E,A                 ; preserve a copy of slot argument in E
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    LD   B,A
                    LD   C,MS_S1        
                    LD   HL,$4000            ; use segment 1 (not this executing segment which is MS_S2)

                    CALL CheckRam
                    JR   C, unknown_flashmem ; abort, if RAM card was found in slot C...

                    CALL FetchCardID         ; get info of Flash Memory chip in HL (if avail in slot C)...
                    JR   C, unknown_flashmem ; no ID's were polled from a (potential FE card)

                    CALL FlashEprCardData    ; verify Flash Memory ID with known Manufacturer & Device Codes
                    JR   C, unknown_flashmem
                                             ; H = Manufacturer Code, L = Device Code
                    POP  DE                  ; B = banks on card, A = chip series (28F or 29F)
                    LD   C,E                 ; original C restored
.end_FlashEprCardId
                    CALL EnableBlinkInt      ; interrupts are again allowed to get out of Blink
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
; The core polling routines are available in OZ LOWRAM.
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
                    RST  OZ_MPB              ; Get bottom Bank of slot C into segment 1
                    PUSH BC                  ; old bank binding in BC...

                    PUSH HL
                    POP  IY                  ; preserve pointer to Flash Memory segment

                    LD   D,(HL)
                    INC  HL                  ; get a copy into DE of the slot contents at the location
                    LD   E,(HL)              ; where the ID is fetched (through the FE command interface)
                    DEC  HL                  ; back at $00 0000

                    CALL Poll_I28Fx_ChipId   ; run INTEL card ID routine in LOWRAM
                    PUSH HL
                    CP   A                   ; Fc = 0
                    SBC  HL,DE               ; Assume that no INTEL Flash Memory ID is stored at that location!
                    POP  HL                  ; if the ID in HL is different from DE
                    JR   NZ, found_CrdID     ; then an ID was fetched from an INTEL FlashFile Memory...

                    PUSH IY
                    POP  HL                  ; pointer to Flash Memory segment
                    CALL Poll_AM29Fx_ChipId  ; run AMD/STM card ID routine in LOWRAM

                    PUSH HL
                    CP   A                   ; Fc = 0
                    SBC  HL,DE
                    POP  HL
                    JR   NZ, found_CrdID     ; if the ID in HL is equal to DE
                    SCF                      ; then no AMD/STM Flash Memory responded to the ID request...
                    JR   exit_FetchCardID
.found_CrdID
                    CP   A
.exit_FetchCardID
                    POP  BC
                    RST  OZ_MPB              ; restore original bank in segment 1 (defined in BC)

                    POP  IX
                    POP  DE
                    POP  BC                  ; get preserved AF
                    LD   A,B                 ; restore original A
                    RET


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
                    RST  OZ_MPB              ; Get bottom Bank of slot C into segment 1
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
                    RST  OZ_MPB              ; restore original bank in segment 1 (defined in BC)

                    POP  BC
                    RET
.not_written
                    CP   A                   ; Fc = 0, this is not a RAM card
                    JR   exit_CheckRam

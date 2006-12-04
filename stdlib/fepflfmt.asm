     XLIB FlashEprFileFormat

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

     LIB FlashEprCardId
     LIB FlashEprBlockErase
     LIB FlashEprStdFileHeader
     LIB FlashEprWriteBlock
     LIB FileEprRequest
     LIB SafeBHLSegment
     LIB FlashEprPollSectorSize
     LIB OZSlotPoll, SetBlinkScreen

     XREF SetBlinkScreenOn

     include "memory.def"
     include "flashepr.def"
     include "error.def"

;***************************************************************************************************
;
; Flash Eprom File Area Formatting.
;
; Create/reformat an "oz" File Area below application Rom Area, or on empty
; Flash Cards to create a normal "oz" File Eprom that is also recognized by
; Filer popdown in slot 3.
; Reformat file areas that are embedded as part of application cards, located
; at top of card above the application area (automatically preserving 'OZ'
; header during reformat of file area).
;
; An 'oz' file card header or 'OZ' application card header with embedded 'oz'
; file area watermark is 64 bytes large, and is located at the top (last bank)
; of the file area at offset $3FC0.
;
; Defining 8 banks in the ROM Front DOR for applications will leave 58
; banks for file storage in a 1Mb Flash Card. This scheme is however always
; performed with only formatting the Flash Eprom in free modulus 64K blocks,
; ie. having defined 5 banks for ROM would "waste" three banks for applications.
;
; Hence, ROM Front DOR definitions should always define bank reserved for
; applications in modulus 64K, eg. 4 banks, 8, 12, etc...
;
; -------------------------------------------------------------------------
; The screen is turned off while formatting a file area when we're in the
; same slot as the OZ ROM. During formatting, no interference should happen
; from Blink, because the Blink reads the font bitmaps each 1/100 second:
;    When formatting is part of OZ ROM chip, the font bitmaps are suddenly
;    unavailable which creates violent screen flickering during chip command mode.
;    Further, and most importantly, avoid Blink doing read-cycles while
;    chip is in command mode.
; By switching off the screen, the Blink doesn't read the font bit maps in
; OZ ROM, and the Flash chip can be in command mode without being disturbed
; by the Blink.
; -------------------------------------------------------------------------
;
; Important:
; Third generation AMD Flash Memory chips may be erased/programmed in all
; available slots (1-3). Only INTEL I28Fxxxx series Flash chips require
; the 12V VPP pin in slot 3 to successfully erase or blow data on the
; memory chip. If the Flash Eprom card is inserted in slot 1 or 2,
; this routine will report a programming failure.
;
; It is the responsibility of the application (before using this call) to
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; ------------------------------------------------------------------------
; Due to a strange side effect with Intel Flash Chips, a special "NULL" file
; is saved as the first file to the Card. These bytes occupies the first
; bytes that otherwise could be interpreted as a random boot command for the
; Intel chip - the behaviour is an Intel chip suddenly gone into command
; mode for no particular reason.
;
; The NULL file prevents this behaviour by saving a file that avoids any
; kind of boot commands which sends the chip into command mode when the card
; has been inserted into a Z88 slot.
; ------------------------------------------------------------------------
;
; IN:
;    C = slot number (0, 1, 2 or 3) of Flash Memory Card
;
; OUT:
;    Success:
;         Fc = 0,
;         BHL = absolute pointer to "oz" header in card
;         C = Number of 16K banks of File Eprom Area
;
;         All sectors erased and a new header blown.
;
;    Failure:
;         Fc = 1
;             A = RC_ONF (File Eprom Card / Area not available; possibly no card in slot)
;             A = RC_ROOM (No room for File Area; all banks used for applications)
;             A = RC_NFE (not a recognized Flash Memory Chip)
;             A = RC_BER (error occurred when erasing block/sector)
;             A = RC_BWR (couldn't write header to Flash Memory)
;             A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
; --------------------------------------------------------------------------------------------------
; Design & programming by Gunther Strube,
;       Dec 1997-Apr 1998, Aug 2004, July 2005, July 2006, Aug-Oct 2006
; --------------------------------------------------------------------------------------------------
;
.FlashEprFileFormat
                    PUSH DE
                    PUSH BC
                    PUSH HL
                    CALL FlashEprCardId
                    JR   C, format_error

                    CALL OZSlotPoll               ; is OZ running in slot C?
                    CALL NZ,SetBlinkScreen        ; yes, (re)formatting file area in OZ ROM (slot 0 or 1) requires LCD turned off

                    LD   D,A                      ; preserve FE_28F / FE_29F programming algorithm
                    LD   E,B                      ; preserve no. of 16K banks on FC
                    PUSH DE
                    PUSH HL
                    CALL FileEprRequest           ; get pointer to File Eprom Header (or potential) in slot C
                    CALL C, no_filearea           ; no file area found, setup parameters to format complete card
                    POP  HL                       ; Flash Card ID
                    POP  DE
                    CALL EraseBlocks              ; erase all sectors of file area, then (re)create file area header
                    JR   C,format_error
                    CALL SaveNullFile             ; blow a NULL file (6 bytes long), but only on Intel Flash Cards...
                    JR   C,format_error           ; NULL file wasn't created!
.exit_feformat
                    CALL SetBlinkScreenOn         ; always turn on screen after format operation
                    LD   HL,$3FC0                 ; BHL = absolute pointer to "oz" header in slot
                    CP   A                        ; Fc = 0, C = Number of 16K banks of File Area
                    POP  DE                       ; ignore old HL
                    POP  DE                       ; ignore old BC
                    POP  DE                       ; original DE restored
                    RET
.format_error
                    CALL SetBlinkScreenOn
                    POP  HL
                    POP  BC
                    POP  DE
                    RET
; when no file area was found, we format the complete card as a file area
.no_filearea
                    PUSH AF
                    LD   B,E                      ; no. of 16K banks on Flash Card
                    DEC  B                        ; no. of banks on Flash Card --> relative top bank of card
                    LD   A,C                      ; slot number
                    OR   A
                    JR   Z, preserve_oz_rom       ; slot 0!
                    RRCA
                    RRCA
                    OR   B
                    LD   B,A                      ; B = top Bank of slot to erased
                    LD   C,E                      ; C = total banks to be erased on card.
                    POP  AF
                    RET
.preserve_oz_rom
                    POP  AF                       ; (get rid of REturn address)
                    LD   A,RC_NOZ                 ; it is not permitted to erase complete OZ ROM
                    SCF                           ; to create a file area!
                    JR   format_error


; ************************************************************************
;
; Erase / format sectors, based on information from FileEprRequest lib.
;
; Erase all sectors in Flash File Eprom, from the top (that includes
; the File Eprom Header) and downwards to the bottom of the card if no
; OZ header information was found, otherwise format only sectors below
; the application area.
;
; IN:
;    B = Top bank of File Eprom (absolute bank with embedded slot mask) (if Fc = 0)
;    C = Number of 16K banks in File Eprom Area
;    D = FE_28F / FE_29F programming algorithm
;    E = Total of 16K banks on Flash Card
;    HL = Card ID
;    Fc/Fz status flags, identifying whether a file area header exists or not...
;
; OUT:
;    Fc = 0,
;         File area on Flash card erased successfully (contains FF's).
;         Header has also been created (or restored).
;    Fc = 1,
;         A = RC_NFE (not a recognized Flash Memory Chip)
;         A = RC_BER (error occurred when erasing block/sector)
;         A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.EraseBlocks
                    PUSH IX
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   IX,0                     ; default to no file header copy...
                    JR   C, init_eraseblocks      ; (create a complete file card)
                    JR   NZ, init_eraseblocks     ; (app card, create file area below)
                    EXX
                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-66
                    ADD  IX,SP                    ; IX points at start of buffer for copy of file header
                    LD   SP,IX                    ; 64 byte buffer created...
                    PUSH HL                       ; preserve original SP
                    EXX
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   HL,$3FC0                 ; header at B $3FC0
                    PUSH IX
                    POP  DE
                    LD   C,64
                    OZ   OS_Bhl                   ; copy original header of file area, to be
                    POP  HL                       ; restored after file area formatting...
                    POP  DE
                    POP  BC
.init_eraseblocks
                    PUSH DE
                    PUSH BC                       ; use Top Bank & total banks as quick fetch stack fetch
                    LD   D,C                      ; D = banks of file area

                    LD   A,B
                    AND  @11000000
                    RLCA
                    RLCA
                    LD   C,A                      ; slot C (of bank B)
                    LD   A,B
                    DEC  E
                    AND  E
                    LD   B,A                      ; Bank number of header only within range of physical card

                    CALL FlashEprPollSectorSize   ; AM29F010B/ST29F010B Flash Memory in slot C?
                    JR   Z, erase_sector_loop     ; yes, it's a 16K sector architecture Flash Memory
._64K_block_fe
                    SRL  D
                    SRL  D                        ; D = total of 64K sectors (banks/4) to be erased...
                    SRL  B
                    SRL  B                        ; begin to erase top sector (bank of header/4), then downwards..
.erase_sector_loop
                    CALL FlashEprBlockErase       ; format sector B of partition in slot C
                    JR   C, exit_ErasePtBlocks    ; get out if an error occurred...
                    DEC  B                        ; next (lower) sector to erase
                    DEC  D
                    JR   NZ, erase_sector_loop    ; erase total of E sectors...
.exit_ErasePtBlocks
                    POP  BC                       ; top bank for header in formatted file area...
                    POP  DE
                    LD   A,D                      ; A = FE_28F / FE_29F
                    LD   C,E                      ; C = Total of 16K banks on Flash Card
                    PUSH IX
                    POP  HL                       ; create a new file header, or use header at (HL)
                    JR   C, restore_regs0         ; error occurred during erase, skip create header...
                    CALL FlashEprStdFileHeader    ; Create "oz" File Area Header in absolute bank B
.restore_regs0
                    EX   AF,AF'                   ; preserve return status
                    LD   A,H
                    OR   L
                    JR   Z,restore_regs1          ; no stack buffer allocated for original header..
                    POP  HL
                    LD   SP,HL                    ; restore original stack (remove allocated stack buffer)
.restore_regs1
                    EX   AF,AF'
                    POP  HL
                    POP  DE
                    POP  BC

                    POP  IX
                    RET


; *************************************************************************************
; Save special "NULL" file at bottom of card (the first file) on Intel Flash chips.
;
; IN:
;    HL = Card ID
;
.SaveNullFile
                    LD   A,$89               ; Check for Intel Manufacturer code
                    CP   H
                    RET  NZ                  ; it was not an Intel chip - the null file is not necessary...

                    PUSH BC                  ; preserve top of file area bank in B
                    PUSH IY

                    LD   B,$C0               ; file area was just formatted successfully, so the Intel
                    LD   HL,0                ; chip is located in slot 3 - blow null file at bottom of card
                    LD   DE, nullfile
                    CALL SafeBHLSegment      ; use a safe segment outside this bank to blow the bytes...
                    LD   IY,6                ; Initial File Entry is 6 bytes long...
                    LD   A,FE_28F            ; use Intel flash chip type...
                    CALL FlashEprWriteBlock

                    POP  IY
                    POP  BC                  ; restored Bank number...
                    RET
.nullfile
                    defb 1, 0, 0, 0, 0, 0
; *************************************************************************************

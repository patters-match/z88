        module FlashEprFileFormat

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

        xdef FlashEprFileFormat

        lib OZSlotPoll, SetBlinkScreen

        xref FlashEprCardId
        xref FlashEprSectorErase
        xref FlashEprStdFileHeader
        xref FlashEprWriteBlock
        xref FlashEprPollSectorSize
        xref FileEprRequest
        xref SetBlinkScreenOn
        xref GetSlotNo

        include "memory.def"
        include "error.def"
        include "flashepr.def"

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
;              BHL = pointer to File Header for slot C (B = absolute bank of slot).
;                    (or pointer to free space in potential new File Area).
;                C = size of File Eprom Area in 16K banks
;              Fz = 1, File Header available
;                   A = "oz" File Eprom sub type
;                   D = size of card in 16K banks (0 - 64)
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
;    ......../IXIY same
;    AFBCDEHL/.... different
;
; --------------------------------------------------------------------------------------------------
; Design & programming by Gunther Strube,
;       Dec 1997-Apr 1998, Aug 2004, July 2005, July 2006, Aug-Oct-Nov 2006, Mar 2007
; --------------------------------------------------------------------------------------------------
;
.FlashEprFileFormat
        call    FlashEprCardId
        jr      c, format_error

        call    OZSlotPoll                      ; is OZ running in slot C?
        call    nz,SetBlinkScreen               ; yes, (re)formatting file area in OZ ROM (slot 0 or 1) requires LCD turned off

        ld      d,a                             ; preserve FE_28F / FE_29F programming algorithm
        ld      e,b                             ; preserve no. of 16K banks on FC
        push    de
        push    hl
        call    FileEprRequest                  ; get pointer to File Eprom Header (or potential) in slot C
        call    c, no_filearea                  ; no file area found, setup parameters to format complete card
        pop     hl                              ; Flash Card ID
        pop     de
        call    EraseBlocks                     ; erase all sectors of file area, then (re)create file area header
        jr      c,format_error
        call    SaveNullFile                    ; blow a NULL file (6 bytes long), but only on Intel Flash Cards...
        jr      c,format_error                  ; NULL file wasn't created!
        call    SetBlinkScreenOn                ; always turn on screen after format operation
        call    GetSlotNo                       ; get slot number in C from bank B
        jp      FileEprRequest                  ; return "oz" header information
.format_error
        call    SetBlinkScreenOn
        ret
; when no file area was found, we format the complete card as a file area
.no_filearea
        push    af
        ld      b,e                             ; no. of 16K banks on Flash Card
        dec     b                               ; no. of banks on Flash Card --> relative top bank of card
        ld      a,c                             ; slot number
        or      a
        jr      z, preserve_oz_rom              ; slot 0!
        rrca
        rrca
        or      b
        ld      b,a                             ; B = top Bank of slot to erased
        ld      c,e                             ; C = total banks to be erased on card.
        pop     af
        ret
.preserve_oz_rom
        pop     af                              ; (get rid of REturn address)
        ld      a,RC_NOZ                        ; it is not permitted to erase complete OZ ROM
        scf                                     ; to create a file area!
        jr      format_error


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
        push    ix
        push    bc
        push    de
        push    hl

        ld      ix,0                            ; default to no file header copy...
        jr      c, init_eraseblocks             ; (create a complete file card)
        jr      nz, init_eraseblocks            ; (app card, create file area below)
        exx
        ld      hl,0
        add     hl,sp
        ld      ix,-66
        add     ix,sp                           ; IX points at start of buffer for copy of file header
        ld      sp,ix                           ; 64 byte buffer created...
        push    hl                              ; preserve original SP
        exx
        push    bc
        push    de
        push    hl
        ld      hl,$3fc0                        ; header at B $3FC0
        push    ix
        pop     de
        ld      c,64
        oz      OS_Bhl                          ; copy original header of file area, to be
        pop     hl                              ; restored after file area formatting...
        pop     de
        pop     bc
.init_eraseblocks
        push    de
        push    bc                              ; use Top Bank & total banks as quick fetch stack fetch
        ld      d,c                             ; D = banks of file area

        call    GetSlotNo                       ; slot C (of bank B)
        ld      a,b
        dec     e
        and     e
        ld      b,a                             ; Bank number of header only within range of physical card

        call    FlashEprPollSectorSize          ; AM29F010B/ST29F010B Flash Memory in slot C?
        jr      z, erase_sector_loop            ; yes, it's a 16K sector architecture Flash Memory
._64K_block_fe
        srl     d
        srl     d                               ; D = total of 64K sectors (banks/4) to be erased...
        srl     b
        srl     b                               ; begin to erase top sector (bank of header/4), then downwards..
.erase_sector_loop
        call    FlashEprSectorErase             ; format sector B of partition in slot C
        jr      c, exit_ErasePtBlocks           ; get out if an error occurred...
        dec     b                               ; next (lower) sector to erase
        dec     d
        jr      nz, erase_sector_loop           ; erase total of E sectors...
.exit_ErasePtBlocks
        ex      af,af'
        ld      a,c                             ; get internal slot status
        or      a
        ex      af,af'                          ; Fz = 1 if slot 0...

        pop     bc                              ; top bank for header in formatted file area...
        pop     de
        ld      a,d                             ; A = FE_28F / FE_29F
        ld      c,e                             ; C = Total of 16K banks on Flash Card
        push    ix
        pop     hl                              ; create a new file header, or use header at (HL)
        jr      c, restore_regs0                ; error occurred during erase, skip create header...
        ex      af,af'
        jr      z, blow_hdr                     ; for slot 0, just blow header at top ROM bank (hybrid card logic only for external slots)
        dec     e
        bit     5,e                             ; how big is flash chip in external slot?
        jr      nz,blow_hdr                     ; adjust Bank No to upper 512K address space if chip is < 1Mb
        set     5,b                             ; (because hybrid card have flash in upper 512k of address space)
.blow_hdr
        ex      af,af'                          ; restore FE_xxx type...
        call    FlashEprStdFileHeader           ; Create "oz" File Area Header in absolute bank B
.restore_regs0
        ex      af,af'                          ; preserve return status
        ld      a,h
        or      l
        jr      z,restore_regs1                 ; no stack buffer allocated for original header..
        pop     hl
        ld      sp,hl                           ; restore original stack (remove allocated stack buffer)
.restore_regs1
        ex      af,af'
        pop     hl
        pop     de
        pop     bc

        pop     ix
        ret


; *************************************************************************************
; Save special "NULL" file at bottom of card (the first file) on Intel Flash chips.
;
; IN:
;    HL = Card ID
;
.SaveNullFile
        ld      a,FE_INTEL_MFCD                 ; Check for Intel Manufacturer code
        cp      h
        ret     nz                              ; it was not an Intel chip - the null file is not necessary...

        push    bc                              ; preserve top of file area bank in B
        push    ix

        ld      b,$c0                           ; file area was just formatted successfully, so the Intel
        ld      hl, MM_S1 << 8                  ; chip is in slot 3 - blow file at bottom of card (using segment 1)
        ld      de, nullfile
        ld      ix,6                            ; Initial File Entry is 6 bytes long...
        ld      c,FE_28F                        ; use Intel flash chip type...
        call    FlashEprWriteBlock

        pop     ix
        pop     bc                              ; restored Bank number...
        ret
.nullfile
        defb    1, 0, 0, 0, 0, 0
; *************************************************************************************

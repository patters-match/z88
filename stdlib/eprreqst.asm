     XLIB FileEprRequest

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

     LIB FlashEprCardId, ApplEprType
     LIB MemReadByte, MemWriteByte, MemReadWord, MemWriteWord
     LIB MemAbsPtr

     include "error.def"
     include "memory.def"
     include "flashepr.def"


;***************************************************************************************************
;
; Check for "oz" File Eprom (on a conventional Eprom or on a Flash Memory)
;
; 1) Check for a standard "oz" File Eprom, if that fails -
; 2) Check if that slot contains an Application ROM, then check for the  Header Identifier below
;    the application bank area. For Flash Cards, the File Header might be on first top bank of a
;    free 64K sector. For Eproms, the File Header might be on the first top bank below the
;    application bank area.
; 3) If a Rom Front Dor is located in a RAM Card, then this slot is regarded as a non-valid card as
;    a File Eprom, ie. not present.
; 4) Check for embedded 'oz' watermark inside an 'OZ' application header. If found, then this
;    indicates that a file area is located at the top of a card above an application area or at the
;    top of an OZ ROM.
;
; A) A standard 'oz' header is recognized by the top two watermark bytes in the top bank of the
;    file area (either typically at the top of the card, in modulus 64K sectors in Flash Cards or
;    modulus 16K banks on traditional EPROM's. The complete header has the following format:
;    ------------------------------------------------------------------------------
;    $3FC0       $00's until
;    $3FF7       $01
;    $3FF8       4 byte random id
;    $3FFC       size of card in banks (2=32K, 8=128K, 16=256K, 64=1Mb)
;    $3FFD       sub-type: $7E, $7C, $7A for UV 32K, 128K & 256K cards. $77, $6F for Intel and Amd Flash
;    $3FFE       'o'
;    $3FFF       'z' (file eprom identifier, lower case 'oz')
;    ------------------------------------------------------------------------------
;    in hex dump (example):
;    00003fc0h: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ; ................
;    00003fd0h: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ; ................
;    00003fe0h: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ; ................
;    00003ff0h: 00 00 00 00 00 00 00 01 73 D1 4B 3C 02 7E 6F 7A ; ........s?<.~oz
;    ------------------------------------------------------------------------------
;
; B) A sub-standard 'oz' header is recognized at offset $3FEE inside an application 'OZ' header that
;    always placed at the top of the card, with the following format:
;    ------------------------------------------------------------------------------
;    Application Front DOR:
;    $3FC0         0 0 0           Link to parent
;    $3FC3         0 0 0           Link to brother - this may point to the HELP front DOR
;    $3FC6         x x x           Link to son - this points to the first application DOR
;    $3FC9         $13             DOR type, ROM Front DOR
;    $3FCA         8               DOR length
;    $3FCB         'N'             Key for name field (DT_NAM)
;    $3FCC         5               Length of name and terminator
;    $3FCD         'APPL', 0       NULL-terminated name
;    $3FD2         $FF             DOR terminator
;
;    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;    Optional file area at top card, above application area:
;    $3FEC         x               Size of file areain banks, eg. $02 for a 32K size
;    $3FED         $00             64K Reclaim Sector (0=not used)
;    $3FEE         'oz'            Application/ROM Card holds file area
;    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
;    $3FF8         @0xxxxxxx       Low byte of card ID
;    $3FF9         @0xxxxxxx       High byte of card ID
;    $3FFA         @0000xxxx       4 bit country code
;    $3FFB         $80             Marks external application
;    $3FFC         x               Size of card in banks, eg. $02 for a 32K card
;    $3FFD         $00             Subtype of card - future expansion
;    $3FFE         'OZ'            Card holds applications
;    ------------------------------------------------------------------------------
;    in hex dump (example):
;    00003fc0h: 00 00 00 00 00 00 48 25 08 13 08 4E 05 41 50 50 ; ......H%...N.APP
;    00003fd0h: 4C 00 FF 00 00 00 00 00 00 00 00 00 00 00 00 00 ; L.ÿ.............
;    00003fe0h: 00 00 00 00 00 00 00 00 00 00 00 00 14 00 6F 7A ; ..............oz
;    00003ff0h: 00 00 00 00 00 00 00 00 54 43 4C 81 20 00 4F 5A ; ........TCL .OZ
;    ------------------------------------------------------------------------------
;
; On partial success, if a Header is not found, Fz = 0 and the returned BHL pointer indicates
; that the card might hold a file area, beginning at this location.
;
; If the routine returns Fz = 1, it's an identified File Area Header (pointing to 64 byte header
; in the top of bank B).
;
;
; Register parameters:
;
; In:
;         C = slot number (0, 1, 2 or 3)
;
; Out:
;    Success, File Area (or potential) available:
;         Fc = 0,
;              BHL = pointer to File Header for slot C (B = absolute bank of slot).
;                    (or pointer to free space in potential new File Area).
;                C = size of File Eprom Area in 16K banks
;              Fz = 1, File Header found
;                   A = "oz" File Eprom sub type
;                   D = size of card in 16K banks (0 - 64)
;              Fz = 0, File Header not found
;                   A undefined
;                   D undefined
;    Failure:
;         Fc = 1,
;              C = C(in)
;              A = RC_ONF (File Eprom Card/Area not available; possibly no card in slot)
;              A = RC_ROOM (No room for File Area; all banks used for applications)
;
; Registers changed after return:
;    .....E../IXIY same
;    AFBCD.HL/.... different
;
; --------------------------------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, July-Sept 2004, July 2006
; --------------------------------------------------------------------------------------------------
;
.FileEprRequest
                    PUSH DE

                    LD   B,$3F
                    CALL CheckFileEprHeader  ; check for standard "oz" File Eprom in top bank of slot C...
                    JR   C, eval_applrom
                         POP  DE             ; found "oz" header at top of card...
                         LD   D,C            ; return C = D = number of 16K banks of card
                         LD   HL, $3FC0      ; offset pointer to "oz" header at top of card...
                         CP   A              ; indicate "Header found" (Fz = 1)
                         RET
.eval_applrom
                    LD   D,C                 ; copy of slot number
                    CALL ApplEprType
                    JR   C,no_fstepr         ; Application ROM Header not present either...
                    CP   $82                 ; Front Dor located in RAM Card?
                    JR   Z,no_fstepr         ; Yes - indicate Card Not Available...
                                             ; B = app card banks, C = total size of card in banks
                    LD   E,C                 ; preserve card size in E
                    LD   C,D                 ; C = slot number
                    CALL DefHeaderPosition   ; locate and validate File Eprom Header
                    JR   C, no_filespace     ; whole card used for Applications...
                    POP  HL                  ; old DE
                    LD   D,E                 ; D = size of card in 16K banks, C = size of File Area in banks
                    LD   E,L                 ; restore original E
                    LD   HL,$3FC0            ; BHL = absolute pointer to "oz" File Header below applications in slot
                    RET                      ; A = File Eprom sub type, Fc = 0, Fz = indicated by DefHeaderPosition
.no_filespace
                    LD   C,D                 ; restore original C (slot number)
                    POP  DE
                    SCF
                    LD   A,RC_ROOM
                    RET
.no_fstepr                                   ; the slot cannot hold a File Area, or card is empty.
                    LD   C,D                 ; restore original C (slot number)
                    POP  DE
                    SCF
                    LD   A,RC_ONF
                    RET



; ************************************************************************
;
; Define the position of the Header, starting from top bank
; of free card space area, calculated by number of reserved banks for
; application usage, then
; For Flash Cards:
;    Check the top bank of the first free 64K block below the last used
;    64K block containg application code, for a File Header.
; For Eprom's:
;    Check the top bank below the last application bank for a File Header.
;
; If no space is left for a file area (all banks used for applications),
; then Fc = 1 is returned.
;
; IN:
;         E = total of physical 16K banks on application card
;         B = number of banks reserved (used) for ROM applications
;         C = slot number
; OUT:
;         Fc = 0 (success),
;              Fz = 1, Header found
;                   A = sub type of File Eprom or File Flash Card
;                   C = size of File Eprom Area in 16K banks
;              Fz = 0, Header not found
;                   A undefined
;                   C undefined
;              B  = absolute bank of "oz" header (or potential)
;         Fc = 1 (failure),
;              A = RC_ROOM (No room for File Eprom Area)
;
; Registers changed after return:
;    ....DEHL/IXIY same
;    AFBC..../.... different
;
.DefHeaderPosition
                    PUSH DE
                    PUSH BC
                    PUSH HL
                    CALL FlashEprCardId      ; poll for known flash card types
                    ld   d,a                 ; preserve chip type (FE_28F or FE_29F)...
                    LD   A,B                 ; if flash card was found, then B contains physical size in 16K banks
                    POP  HL                  ; (this overrules the card size supplied to this routine)
                    POP  BC
                    JR   C, epr_filearea     ; there's no Flash Card, so check top bank below app area
                    ld   e,a                 ; E = the physical size of the flash
                    SUB  B                   ; <Total banks> - <ROM banks> = lowest bank of ROM area
                    CP   3                   ;
                    call z, appcard_no_room  ; Application card uses banks
                    call c, appcard_no_room  ; in lowest 64K block of card...
                    jr   c, exit_DefHeaderPosition
                    AND  @11111100           ; File area are only found in Flash Card sector (64K) boundaries
                    call checkfhdr
                    jr   c,exit_DefHeaderPosition
                    jr   nz,exit_DefHeaderPosition
                    ld   a,d
                    pop  de
                    cp   FE_28F
                    ld   a,$77               ; if Intel Flash was found then the sub type is always $77
                    ret  z
                    ld   a,$6F               ; if Amd/Stm Flash was found then the sub type is always $6F
                    cp   a
                    ret
.epr_filearea                                ; normal UV Eprom found
                    ld   a,e                 ; use supplied card size in E
                    SUB  B                   ; <Total banks> - <ROM banks> = lowest bank of ROM area
                    call checkfhdr
.exit_DefHeaderPosition
                    pop  de
                    ret
.checkfhdr
                    DEC  A                   ; A = Top Bank of File Area
                    bit  5,e                 ; is physical size of Flash / Epr $20 banks? (usually is $40)
                    ld   e,a                 ; relative top bank is size of file area + 1 (returned in C later)
                    jr   z,check_bigcard_fa
                    set  5,a                 ; for 512K Flash or Epr redefine bank location in upper 512K address map
.check_bigcard_fa
                    LD   B,A                 ; B = relative bank number of "oz" header (or potential), C = slot number
                    CALL CheckFileEprHeader
                    ret  nc                  ; header found, at absolute bank B, C = File Area in banks
                    EX   AF,AF'
                    LD   A,C
                    ld   c,e
                    INC  C                   ; C = potential size of file area in banks
                    RRCA
                    RRCA
                    OR   B
                    LD   B,A                 ; relative bank B --> absolute bank B
                    EX   AF,AF'
                    JR   C, new_filearea     ; "oz" File Eprom Header not found, but potential area...
                    CP   A                   ; B = absolute bank of "oz" Header, C = size of File Area in banks
                    RET                      ; return flag status = found!
.new_filearea
                    OR   B                   ; Fc = 0, Fz = 0, indicate potential file area
                    ret
.appcard_no_room
                    LD   A,RC_ROOM
                    SCF
                    ret


; ************************************************************************
;
; Return File Eprom Area status in slot x (0, 1, 2 or 3),
; with top of area at bank B (00h - 3Fh).
;
; The routine automatically adjusts for slot 0 bank range; $00 - $1F, and
; also recognizes the new sub-file area watermark in an application 'OZ'
; header when located at top of card (or top of ROM at bank $1F in slot 0).
;
; In:
;         C = slot number (0, 1, 2 or 3)
;         B = bank of "oz" header (slot relative, 00 - $3F)
;
; Out:
;    Success:
;         Fc = 0, Fz = 0
;              File Eprom found
;              A = Sub type of Eprom
;         B = absolute bank (embedded slot mask) of File Eprom Header
;         C = size of File Eprom Area in 16K banks
;
;    Failure:
;         Fc = 1,
;         A = RC_ONF ("oz" File Eprom not found)
;         C = slot number (0, 1, 2 or 3)
;         B = bank of "oz" header (slot relative, 00 - $3F)
;
; Registers changed after return:
;    ....DEHL/IXIY same
;    AFBC..../.... different
;
.CheckFileEprHeader
                    PUSH DE
                    PUSH BC
                    PUSH HL

                    LD   A,C
                    LD   HL, $3FFC           ; look for official 'oz' file area header in top of bank BHL
                    CALL MemAbsPtr           ; BHL points to slot C

                    CALL ValidateOzWaterMark
                    JR   z, fileeprom_found
                    LD   A,B
                    AND  @00011111
                    CP   $1F                 ; are we at top of ROM/FLASH in current slot?
                    JR   NZ, no_fileeprom    ; no, then certainly, no File Header was recognized
                    LD   L,$EC               ; $3FEC
                    CALL ValidateOzWaterMark ; check for embedded 'oz' watermark in App/Rom header in top of slot
                    JR   NZ, no_fileeprom    ; (this sub-watermark indicates a file area above an application area)
.fileeprom_found
                    LD   A,C                 ; A = sub type of File Eprom, B = absolute bank no of hdr,
                    CP   A                   ; return Fc = 0
                    LD   C,D                 ; C = size of File Area in banks

                    POP  HL                  ; original HL restored
                    POP  DE                  ; ignore old BC -> new values are returned...
                    POP  DE                  ; original DE restored
                    RET
.no_fileeprom
                    LD   A,RC_ONF
                    SCF
                    POP HL
                    POP BC
                    POP DE                   ; original BC, DE & HL restored
                    RET
.ValidateOzWaterMark
                    XOR  A
                    CALL MemReadByte
                    PUSH AF                  ; $3FxC, get size of File Eprom in Banks
                    LD   A,$01
                    CALL MemReadByte         ; $3FxD, get sub type of File Eprom
                    LD   C,A
                    LD   A,$02
                    CALL MemReadWord         ; $3FxE, D <-- 'z', E <-- 'o'

                    PUSH BC
                    PUSH DE
                    LD   DE,0
                    LD   A,$02               ; 0 --> ($3FxE)
                    CALL MemWriteWord        ; 0 --> ($3FxF)
                    CALL MemReadWord         ; D <-- 'z', E <-- 'o'

                    CP   A
                    PUSH HL                  ; preserve bank offset to 'oz' header...
                    LD   HL,$7A6F
                    SBC  HL,DE               ; $(3FxE) = 'oz' ?
                    POP  HL
                    POP  DE
                    POP  BC
                    JR   Z,exit_valozwtmrk   ; 0 was written at $(3FFE) and 'oz' was still returned!

                    LD   A,$FE               ; we might have written to a RAM card,
                    CALL MemWriteWord        ; restore original values to ($3FxE)
.exit_valozwtmrk
                    POP  DE                  ; return D = size of area (if file area found)
                    RET

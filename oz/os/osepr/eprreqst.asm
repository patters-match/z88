     module FileEprRequest

; **************************************************************************************************
; File Area functionality.
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
;
; ***************************************************************************************************

        xdef FileEprRequest

        xref FlashEprCardId

        lib ApplEprType
        lib MemReadByte, MemWriteByte, MemReadWord, MemWriteWord
        lib MemAbsPtr

        include "error.def"
        include "memory.def"
        include "flashepr.def"


; ***************************************************************************************************
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
;    00003ff0h: 00 00 00 00 00 00 00 01 73 D1 4B 3C 02 7E 6F 7A ; ........s�<.~oz
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
;    $3FEC         x               Size of file area in banks, eg. $02 for a 32K size
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
;    00003fd0h: 4C 00 FF 00 00 00 00 00 00 00 00 00 00 00 00 00 ; L..............
;    00003fe0h: 00 00 00 00 00 00 00 00 00 00 00 00 14 00 6F 7A ; ..............oz
;    00003ff0h: 00 00 00 00 00 00 00 00 54 43 4C 81 20 00 4F 5A ; ........TCL .OZ
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
        push    de

        ld      b,$3F
        call    CheckFileEprHeader              ; check for standard "oz" File Eprom in top bank of slot C...
        jr      c, eval_applrom
        pop     de                              ; found "oz" header at top of card...
        ld      d,c                             ; return C = D = number of 16K banks of card
        ld      hl, $3FC0                       ; offset pointer to "oz" header at top of card...
        cp      a                               ; indicate "Header found" (Fz = 1)
        ret
.eval_applrom
        ld      d,c                             ; copy of slot number
        call    ApplEprType
        jr      c,no_fstepr                     ; Application ROM Header not present either...
        cp      $82                             ; Front Dor located in RAM Card?
        jr      z,no_fstepr                     ; Yes - indicate Card Not Available...
                                                ; B = app card banks, C = total size of card in banks
        ld      e,c                             ; preserve card size in E
        ld      c,d                             ; C = slot number

        call    DefHeaderPosition               ; locate and validate File Eprom Header
        jr      c, no_filespace                 ; whole card used for Applications...
        pop     hl                              ; old DE
        ld      d,e                             ; D = size of card in 16K banks, C = size of File Area in banks
        ld      e,l                             ; restore original E
        ld      hl,$3FC0                        ; BHL = absolute pointer to "oz" File Header below applications in slot
        ret                                     ; A = File Eprom sub type, Fc = 0, Fz = indicated by DefHeaderPosition
.no_filespace
        ld      c,d                             ; restore original C (slot number)
        pop     de
        scf
        ld      a,RC_ROOM
        ret
.no_fstepr                                      ; the slot cannot hold a File Area, or card is empty.
        ld      c,d                             ; restore original C (slot number)
        pop     de
        scf
        ld      a,RC_ONF
        ret



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
        push    de
        push    bc
        push    hl
        call    FlashEprCardId                  ; poll for known flash card types
        ld      d,a                             ; preserve chip type (FE_28F or FE_29F)...
        ld      a,b                             ; if flash card was found, then B contains physical size in 16K banks
        pop     hl                              ; (this overrules the card size supplied to this routine)
        pop     bc
        jr      c, epr_filearea                 ; there's no Flash Card, so check top bank below app area
        sub     b                               ; <Total banks> - <ROM banks> = lowest bank of ROM area
        cp      3                               ;
        call    z, appcard_no_room              ; Application card uses banks
        call    c, appcard_no_room              ; in lowest 64K block of card...
        jr      c, exit_DefHeaderPosition
        and     @11111100                       ; File area are only found in Flash Card sector (64K) boundaries
        call    checkfhdr
        jr      c,exit_DefHeaderPosition
        jr      nz,exit_DefHeaderPosition
        ld      a,d
        pop     de
        cp      FE_28F
        ld      a,$77                           ; if Intel Flash was found then the sub type is always $77
        ret     z
        ld      a,$6F                           ; if Amd/Stm Flash was found then the sub type is always $6F
        cp      a
        ret
.epr_filearea                                   ; normal UV Eprom found
        ld      a,e                             ; use supplied card size in E
        sub     b                               ; <Total banks> - <ROM banks> = lowest bank of ROM area
        call    checkfhdr
.exit_DefHeaderPosition
        pop     de
        ret
.checkfhdr
        dec     a                               ; A = Top Bank of File Area
        ld      b,a                             ; B = relative bank number of "oz" header (or potential), C = slot number
        call    CheckFileEprHeader
        ret     nc                              ; header found, at absolute bank B, C = File Area in banks
        ex      af,af'
        ld      a,c
        ld      c,b
        inc     c                               ; C = potential size of file area in banks
        rrca
        rrca
        or      b
        ld      b,a                             ; relative bank B --> absolute bank B
        ex      af,af'
        jr      c, new_filearea                 ; "oz" File Eprom Header not found, but potential area...
        cp      a                               ; B = absolute bank of "oz" Header, C = size of File Area in banks
        ret                                     ; return flag status = found!
.new_filearea
        or      b                               ; Fc = 0, Fz = 0, indicate potential file area
        ret
.appcard_no_room
        ld      a,RC_ROOM
        scf
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
        push    de
        push    bc
        push    hl

        ld      a,c
        ld      hl, $3FFC                       ; look for official 'oz' file area header in top of bank BHL
        call    MemAbsPtr                       ; BHL points to slot C

        call    ValidateOzWaterMark
        jr      z, fileeprom_found
        ld      a,b
        and     @00011111
        cp      $1f                             ; are we at top of ROM/FLASH in current slot?
        jr      nz, no_fileeprom                ; no, then certainly, no File Header was recognized
        ld      l,$EC                           ; $3FEC
        call    ValidateOzWaterMark             ; check for embedded 'oz' watermark in App/Rom header in top of slot
        jr      nz, no_fileeprom                ; (this sub-watermark indicates a file area above an application area)
.fileeprom_found
        ld      a,c                             ; A = sub type of File Eprom, B = absolute bank no of hdr,
        cp      a                               ; return Fc = 0
        ld      c,d                             ; C = size of File Area in banks

        pop     hl                              ; original HL restored
        pop     de                              ; ignore old BC -> new values are returned...
        pop     de                              ; original DE restored
        ret
.no_fileeprom
        ld      a,RC_ONF
        scf
        pop     hl
        pop     bc
        pop     de                               ; original BC, DE & HL restored
        ret
.ValidateOzWaterMark
        xor     a
        call    MemReadByte
        push    af                              ; $3FxC, get size of File Eprom in Banks
        ld      a,$01
        call    MemReadByte                     ; $3FxD, get sub type of File Eprom
        ld      c,a
        ld      a,$02
        call    MemReadWord                     ; $3FxE, D <-- 'z', E <-- 'o'

        push    bc
        push    de
        ld      de,0
        ld      a,$02                           ; 0 --> ($3FxE)
        call    MemWriteWord                    ; 0 --> ($3FxF)
        call    MemReadWord                     ; D <-- 'z', E <-- 'o'

        cp      a
        push    hl                              ; preserve bank offset to 'oz' header...
        ld      hl,$7A6F
        sbc     hl,de                           ; $(3FxE) = 'oz' ?
        pop     hl
        pop     de
        pop     bc
        jr      z,exit_valozwtmrk               ; 0 was written at $(3FFE) and 'oz' was still returned!

        ld      a,$fe                           ; we might have written to a RAM card,
        call    MemWriteWord                    ; restore original values to ($3FxE)
.exit_valozwtmrk
        pop     de                              ; return D = size of area (if file area found)
        ret

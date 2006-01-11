; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2006
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     MODULE Main

     xdef app_main

     include "error.def"
     include "director.def"
     include "stdio.def"
     include "memory.def"
     include "fileio.def"
     include "dor.def"
     include "romupdate.def"

     LIB MemDefBank, SafeBHLSegment
     LIB FlashEprBlockErase, FlashEprWriteBlock, FlashEprCardId

     XREF ApplRomFindDOR, ApplRomFirstDOR, ApplRomNextDOR, ApplRomReadDorPtr
     XREF ApplRomCopyDor
     XREF CrcFile, CrcBuffer


; *************************************************************************************
;
; RomUpdate Error Handler
;
.ErrHandler
                    ret  z
                    cp   rc_susp
                    jr   z,dontworry
                    cp   rc_esc
                    jr   z,akn_esc
                    cp   rc_quit
                    jr   z,suicide
                    cp   a
                    ret
.akn_esc
                    ld   a,1                            ; acknowledge esc detection
                    oz   os_esc
.dontworry
                    cp   a                              ; all other RC errors are returned to caller
                    ret
.suicide            xor  a
                    oz   os_bye                         ; perform suicide, focus to Index...
.void               jr   void
; *************************************************************************************


; *************************************************************************************
.app_main
                    ld   a, sc_ena
                    call_oz(os_esc)                     ; enable ESC detection

                    xor  a
                    ld   b,a
                    ld   hl,Errhandler
                    oz   os_erh                         ; then install Error Handler...

                    call ReadConfigFile                 ; load parameters from 'romupdate.cfg' file
                    jp   c,suicide                      ; not available!

                    ld   c,3                            ; check slot for an application card
                    ld   de, appName                    ; and return pointer DOR for application name (pointed to by DE)
.findappslot_loop
                    call ApplRomFindDOR
                    jr   nc,check_write_support         ; DOR was found in slot, but can Flash Card be updated in slot?
                    inc  c
                    dec  c                              ; application DOR not found or no application ROM available,
                    jr   z, suicide                     ; all slots scanned and no DOR was found
                    dec  c
                    jr   findappslot_loop               ; poll next slot for DOR...
.check_write_support
                    ld   a,b
                    ld   (dorbank),a                    ; preserve the pointer to found DOR in slot C
                    ld   (doroffset),hl

                    push bc
                    call FlashWriteSupport              ; is flash card updateable in slot?
                    pop  bc                             ; (restore bank no of pointer to DOR)
                    jp   c,suicide                      ; no write/erase support in slot!

                    call RegisterPreservedSectorBanks   ; Flash Card may be updated,
                                                        ; - register the banks to be preserved in the sector of the found DOR

                    ; --------------------------------------------------------------------------------------------------------
                    ; check CRC of bank file to be updated on card (replacing bank of found DOR)
                    ld   bc,128
                    ld   hl,bankfilename                ; (local) filename to card image
                    ld   de,filename                    ; output buffer for expanded filename (max 128 byte)...
                    ld   a, op_in
                    oz   GN_Opf
                    jp   c,suicide                      ; couldn't open file (in use / not found?)...

                    ld   de,buffer
                    ld   bc,16384                       ; 16K buffer
                    call CrcFile                        ; calculate CRC-32 of file, returned in DEHL
                    oz   GN_Cl                          ; close file again (we got the expanded filename)
                    call CheckBankFileCrc               ; check the CRC of the bank file with the CRC of the config file
                    jp   nz,suicide                     ; CRC didn't match: the file is corrupt and cannot be updated!
                    ; --------------------------------------------------------------------------------------------------------

                    call PreserveSectorBanks            ; preserve the sector banks to RAM filing system that are not being updated
                    call c,DeletePreservedSectorBanks   ; no room in filing system, delete any bank files already preserved....
                    jp   c,suicide                      ; then leave popdown...

                    ; --------------------------------------------------------------------------------------------------------
                    ; erase sector of bank (to be updated with new version of application)
                    ld   a,(dorbank)
                    ld   b,a
                    rlca
                    rlca
                    and  @00000011
                    ld   c,a                            ; slot of sector
                    ld   a,b
                    rrca
                    rrca                                ; bankNo/4
                    and  @00001111                      ; sector number containing bank
                    ld   b,a
                    call FlashEprBlockErase
                    jp   c, suicide                     ; fatal error -  this only happens if there is a bad slot connection
                    ; --------------------------------------------------------------------------------------------------------

                    call RestoreSectorBanks             ; blow the three 'passive' banks back to the sector

                    jp   suicide                        ; leave popdown...
                    ; --------------------------------------------------------------------------------------------------------
; *************************************************************************************


; *************************************************************************************
; Register the banks of the 64K sector that is not part of the DOR of the found
; application in the [presvdbanks] array. Empty (containing FF's) banks are marked as 0.
;
; The array will contain the numbers of the absolute banks that are going to be
; preserved as ":RAM.-/bank.<bankno>" files. The array contains four items, where a
; single item is 0, which is the bank of the application to be updated (hence
; not preserved as a bank file).
;
; IN:
;       BHL = pointer to application DOR to be updated
; OUT:
;       [presvdbanks] array updated with bank numbers.
;
; Registers changed after return:
;    ..B...HL/IXIY same
;    AF.CDE../.... different
;
.RegisterPreservedSectorBanks
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   c,3
.preserve_loop
                    ld   a,b
                    and  @11111100
                    or   c
                    cp   b
                    call z,notpreserved                 ; don't register the bank which is to be updated
                    call nz,preservebank                ; this bank is to be preserved (not part of DOR)
                    inc  c
                    dec  c
                    ret  z                              ; sector is scanned for banks to be preserved
                    dec  c
                    dec  de
                    jr   preserve_loop
.notpreserved       ld   a,0                            ; indicate bank not to be preserved as 0
.preserve           ld   (de),a
                    ret
.preservebank       call IsBankUsed                     ; only preserve bank if it contains data...
                    jr   nz, preserve
                    jr   notpreserved                   ; bank contained only FF's, not necessary to preserve...
; *************************************************************************************


; *************************************************************************************
; Check the calculated CRC in DEHL with the CRC of the config file to validate that
; the binary bank file is not corrupted during transfer (or was corrupted in the
; RAM filing system).
;
; IN:
;       DEHL = calculated CRC
; OUT:
;       Fz = 1, CRC is valid
;       Fz = 0, CRC does not match the CRC from the Config file
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.CheckBankFileCrc
                    push bc
                    ld   bc,bankfilecrc
                    call CheckCrc
.exit_checkcrc
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Compare CRC in DEHL with (BC).
;
; IN:
;       DEHL = calculated CRC
;       BC = pointer to start of CRC in memory
; OUT:
;       Fc = 0 (always)
;       Fz = 1, CRC is valid
;       Fz = 0, CRC does not match the CRC supplied in DEHL
;       BC points at byte after CRC in memory
;
; Registers changed after return:
;    ....DEHL/IXIY same
;    AFBC..../.... different
;
.CheckCrc
                    ld   a,(bc)
                    inc  bc
                    cp   l
                    jr   nz, return_crc_status
                    ld   a,(bc)
                    inc  bc
                    cp   h
                    jr   nz, return_crc_status
                    ld   a,(bc)
                    inc  bc
                    cp   e
                    jr   nz, return_crc_status
                    ld   a,(bc)
                    inc  bc
                    cp   d
.return_crc_status
                    scf
                    ccf                                 ; return Fc = 0 always
                    ret                                 ; Fz indicates CRC status
; *************************************************************************************


; *************************************************************************************
; Save the banks to RAM filing system to be preserved (before sector erase) as
; ":RAM.-/bank.<bankno>" files. Three out of the four banks in the 64K sector is
; preserved. The remaining bank is handled separately which contains the code to be
; updated.
;
; Before the bank is preserved to a RAM file, a CRC is made of the bank and
; stored at [presvdbankcrcs]. The CRC is checked before the bank is later restored to
; ensure that the RAM file is an exact match of the original bank contents on the card.
;
; IN:
;       None.
; OUT:
;       Fc = 1, No room, file I/O error or CRC mismatch when preserving banks to RAM filing system
;       Fc = 0, banks were successfully preserved to RAM filing system and CRC checked.
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.PreserveSectorBanks
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.presrvbank_loop
                    ld   a,(de)
                    or   a
                    call nz,preservesectorbank          ; this bank is to be preserved as a file
                    ret  c                              ; an error occurred while preserving a bank...

                    inc  b
                    dec  b
                    ret  z                              ; sector banks have been preserved
                    dec  b
                    dec  de
                    jr   presrvbank_loop
.preservesectorbank
                    push bc
                    push de
                    ld   b,a
                    ld   a, OP_OUT
                    call GetBankFileHandle
                    jr   c, exit_preservebank           ; couldn't create file (in use?)...

                    ld   hl,0
                    call SafeBHLSegment                 ; HL points at start of 'free' segment in Z80 address space
                                                        ; (C = Segment specifier of free segment)
                    pop  de
                    push de
                    ld   a,(de)                         ; get bank (number) to be preserved
                    ld   b,a
                    call MemDefBank                     ; bind bank into Z80 address space
                    push bc                             ; (preserve old bank binding)
                    call CrcSectorBank                  ; make a CRC (of bank to be preserved) and store it at presvdbankcrcs[bankNo]
                    ld   bc, 16384
                    ld   de,0
                    oz   OS_MV                          ; copy bank contents to file...
                    pop  bc
                    call MemDefBank                     ; restore old bank binding
                    push af
                    oz   GN_Cl                          ; close file (copy of bank)
                    pop  af                             ; return OS_MV status (RC_ROOM error, or bank successfully copied to file)
.exit_preservebank
                    pop  de
                    pop  bc
                    ret
.CrcSectorBank
                    push bc
                    push de
                    push hl
                    push af                             ; the (absolute) bank number

                    ld   bc,16384                       ; CRC of complete bank...
                    call CrcBuffer                      ; calculate CRC-32 of bank at (HL)
                    pop  af
                    push af
                    and  @11111100                      ; bank no within sector
                    add  a,a
                    add  a,a                            ; index offset for CRC array
                    push hl
                    ld   hl,presvdbankcrcs              ; base pointer of array of bank CRC's
                    ld   b,0
                    ld   c,a
                    add  hl,bc                          ; offset pointer to this bank CRC
                    push hl
                    pop  bc
                    pop  hl
                    ld   a,l
                    ld   (bc),a                         ; presvdbankcrcs[bankNo] = CRC
                    inc  bc
                    ld   a,h
                    ld   (bc),a
                    inc  bc
                    ld   a,e
                    ld   (bc),a
                    inc  bc
                    ld   a,d
                    ld   (bc),a                         ; CRC registered for bankNo

                    pop  af
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; CRC check the sector banks of the 64K sector that was preserved in RAM
; filing system as ":RAM.-/bank.<bankno>" files.
;
; IN:
;       None.
; OUT:
;       Fc = 1,
;         File I/O error (A = RC_xx reason code)
;       Fc = 0,
;         Fz = 1, all (preserved file) banks were successfully CRC checked
;         Fz = 0, a preserved bank didn't match original CRC from card
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.CheckPreservedSectorBanks
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.checkcrc_loop
                    ld   a,(de)
                    or   a
                    call nz,checkcrcbank                ; compare CRC of bank file with CRC from card
                    ret  c                              ; an I/O error occurred before CRC checking the bank...
                    ret  nz                             ; CRC error!

                    inc  b
                    dec  b
                    ret  z                              ; all sector banks have been successfully CRC checked
                    dec  b
                    dec  de
                    jr   checkcrc_loop
.checkcrcbank
                    push bc
                    push de
                    ld   b,a
                    ld   a, OP_IN
                    call GetBankFileHandle
                    jr   c, exit_checkcrcbank           ; couldn't open file ...

                    ld   bc, 16384
                    push bc
                    ld   de,buffer
                    push de
                    ld   hl,0
                    oz   OS_MV                          ; copy bank file contents into buffer...
                    pop  hl
                    pop  bc
                    push af
                    oz   GN_Cl                          ; close file
                    pop  af
                    jr   c, exit_checkcrcbank           ; I/O error when filling buffer!
                                                        ; HL = start of buffer, BC = length of buffer
                    call CrcBuffer                      ; return CRC of buffer digest in DEHL

                    pop  bc
                    push bc
                    ld   a,(bc)
                    and  @11111100                      ; get bank (number) within sector...
                    ld   bc,presvdbankcrcs              ; base pointer to array of preserved bank CRC's
                    add  a,a
                    add  a,a                            ; sector bank no * 4 = pointer to array offset
                    add  a,c
                    ld   c,a
                    ld   a,0
                    adc  a,b
                    ld   b,a                            ; pointer to stored CRC of preserved bank within array
                    call CheckCrc                       ; is the CRC of buffer contents the same as CRC from original bank?
.exit_checkcrcbank
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Restore the banks into the 64K sector that was previously preserved in RAM filing
; system as ":RAM.-/bank.<bankno>" files. The banks to be restored are registered in
; the [presvdbanks] array.
;
; Restoring the banks has only meaning if the sector has been erased.
;
; IN:
;       None.
; OUT:
;       Fc = 1, file I/O or a bank was not successfully restored to sector (likely a blow error).
;       Fc = 0, all banks were successfully restored to sector on Flash Card.
;
; Registers changed after return:
;    ......../.... same
;    AFBCDEHL/IXIY different
;
.RestoreSectorBanks
                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.restorebank_loop
                    ld   a,(de)
                    or   a
                    call nz,restorebank                 ; this bank is to be restored from file
                    ret  c                              ; an error occurred while restoring a bank...

                    inc  b
                    dec  b
                    ret  z                              ; sector banks have been restored
                    dec  b
                    dec  de
                    jr   restorebank_loop
.restorebank
                    push bc
                    push de
                    ld   b,a
                    ld   a, OP_IN
                    call GetBankFileHandle
                    jr   c, exit_restorebanks           ; couldn't open file ...

                    ld   bc, 16384
                    push bc
                    ld   de,buffer
                    push de
                    ld   hl,0
                    oz   OS_MV                          ; copy bank file contents into buffer...
                    pop  hl
                    pop  bc
                    jr   c, exit_restorebanks           ; I/O error!

                    pop  de
                    push de
                    ld   a,(de)                         ; get bank (number) to be restored

                    ld   b,a
                    ld   hl,0                           ; blow from start of bank...
                    ld   de,buffer                      ; blow contents of buffer to bank
                    ld   iy, 16384
if POPDOWN
                    ld   c, MS_S2                       ; use segment 2 to blow bank
else
                    ld   c, MS_S3                       ; BBC BASIC: use segment 3 to blow bank
endif
                    xor  a                              ; Flash blowing algorithm is found dynamically
                    call FlashEprWriteBlock
                    push af
                    oz   GN_Cl                          ; close file
                    pop  af                             ; report back if a Flash programming error occurred
.exit_restorebanks
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Generate preserved bank filename ":RAM.-/bank.<bankno>" and return HL to start
; of filename (built in filename buffer). Bank numbers are truncated to 0-3 range.
;
; IN:
;       B = bank number
; OUT:
;       (filename) = complete bank filename added with bank number extension
;       HL = points to start of filename
;
; Registers changed after return:
;    ..BCDE../IXIY same
;    AF....HL/.... different
;
.GetBankFilename
                    push de
                    call CpyBaseBankFile
                    ld   a,b
                    and  @11111100                      ; preserve only bank number within sector
                    or   48                             ; make bank number an ascii number...
                    ld   (de),a                         ; and append it as the filename extension
                    inc  de
                    xor  a
                    ld   (de),a                         ; null terminate filename
                    pop  de
                    ld   hl, filename                   ; return pointer to start of filename
                    ret
; *************************************************************************************


; *************************************************************************************
; Get file handle for temporary bank file ":RAM.-/bank.<bankno>".
;
; IN:
;    A = OP_xx reason code for GN_Opf
;    B = Bank number
; OUT:
;    Fc = 0
;         IX = file handle
;    Fc = 1
;         file open error (A = reason code)
;
; Registers changed after return:
;    ..BCDEHL/..IY same
;    AF....../IX.. different
;
.GetBankFileHandle
                    call GetBankFilename                ; filename based on bank number in B
                    ld   d,h
                    ld   e,l
                    ld   bc,128                         ; local filename
                    oz   GN_Opf                         ; return file handle in IX (if successfull)
                    ret
; *************************************************************************************


; *************************************************************************************
; Validate bank contents to be 'empty' or containing data; an empty bank only
; contains FFh bytes.
;
; IN:
;       A = Bank number (absolute)
; OUT:
;       Fz = 1, Bank was empty
;       Fz = 0, Bank contains data / code
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.IsBankUsed
                    push bc
                    push af
                    push hl

                    ld   hl,0
                    call SafeBHLSegment                 ; HL points at start of 'free' segment in Z80 address space
                                                        ; (C = Segment specifier of free segment)
                    ld   b,a
                    call MemDefBank                     ; bind bank into Z80 address space
                    push bc                             ; (preserve old bank binding)
                    ld   bc, 16384
.check_empty_bank
                    ld   a,(hl)
                    inc  hl
                    cp   $ff
                    jr   nz, bank_not_empty             ; a non-empty byte was found in the bank...
                    dec  bc
                    ld   a,b
                    or   c                              ; return Fz = 1, if last byte of bank was checked
                    jr   nz, check_empty_bank
.bank_not_empty
                    pop  bc
                    call MemDefBank                     ; restore old bank binding

                    pop  hl
                    pop  bc
                    ld   a,b                            ; original A restored
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Delete the preserved bank files from RAM filing system (named as ":RAM.-/bank.<bankno>").
; No error status is returned. This is a 'cleanup' function.
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.DeletePreservedSectorBanks
                    push af
                    push bc
                    push de
                    push hl

                    ld   de,presvdbanks+3               ; point at end of array
                    ld   b,3
.delbankfile_loop
                    ld   a,(de)
                    or   a
                    call nz,delbankfile                 ; this bank file is to be deleted

                    inc  b
                    dec  b
                    jr   z, exit_delpresrvbfiles        ; sector banks have been preserved
                    dec  b
                    dec  de
                    jr   delbankfile_loop
.delbankfile
                    push bc
                    push de
                    ld   b,a
                    call GetBankFilename                ; filename based on bank number in B,
                    ld   b,0                            ; HL points at filename...
                    oz   GN_Del                         ; delete temporary preserved bank file
                    pop  de
                    pop  bc
                    ret
.exit_delpresrvbfiles
                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; Copy base filename ":RAM.-/bank." to (filename), and return DE to point at first
; character after filename (so that en extension and null-terminator might be added).
;
; IN:
;       None.
; OUT:
;       (filename) = contains ":RAM.-/bank."
;
; Registers changed after return:
;    A.BC..HL/IXIY same
;    .F..DE../.... different
;
.CpyBaseBankFile
                    push bc
                    push hl
                    ld   bc, 12
                    ld   hl, presvbankflnm
                    ld   de, filename
                    ldir
                    pop  hl
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Validate the Flash Card erase/write functionality in the specified slot.
; If the Flash Card in the specified slot contains an Intel chip, the slot
; must be 3 for erase and write functionality.
; Report an error to the caller with Fc = 1, if an Intel Flash chip was recognized
; in all slots except 3.
;
; IN:
;    C = slot number
;
; OUT:
;    Fz = 1, if a Flash Card is available in the current slot (Fz = 0, no Flash Card available!)
;         B = size of card in 16K banks
;    Fc = 1, if no erase/write support is available for current slot.
;
; Registers changed after return:
;    A..CDEHL/IXIY same
;    .FB...../.... different
;
.FlashWriteSupport
                    push hl
                    push de
                    push bc
                    push af
                    call FlashEprCardId
                    jr   nc, flashcard_found
                    or   c                   ; Fz = 0, indicate no Flash Card available in slot
                    scf                      ; Fc = 1, indicate no erase/write support either...
                    jr   exit_chckflsupp
.flashcard_found
                    ld   a,c
                    cp   3
                    jr   z, end_chckflsupp   ; erase/write works for all flash cards in slot 3 (Fc=0, Fz=1)
                    ld   a,$01
                    cp   h                   ; Intel flash chip in slot 0,1 or 2?
                    jr   z, end_chckflsupp   ; No, we wound an AMD Flash chip (erase/write allowed, Fc=0, Fz=1)
                    cp   a                   ; (Fz=1, indicate that Flash is available..)
                    scf                      ; no erase/write support in slot 0,1 or 2 with Intel Flash...
.end_chckflsupp
                    pop  de
                    ld   a,d                 ; A restored (f changed)
                    pop  de
                    ld   c,e                 ; C restored (B = total of 16K banks on card)
                    pop  de                  ; DE restored
                    pop  hl                  ; HL restored
                    ret
.exit_chckflsupp
                    pop  de
                    ld   a,d                 ; A restored (f changed)
                    pop  bc
                    pop  de
                    pop  hl
                    ret
; *************************************************************************************


; *************************************************************************************
; TODO: Load parameters from 'romupdate.cfg' file.
;
.ReadConfigFile
                    ld   bc,15
                    ld   hl,flnm
                    ld   de,bankfilename
                    ldir                                ; define config bank filename

                    ld   hl,$aaaa
                    ld   (bankfilecrc),hl
                    ld   hl,$bbbb
                    ld   (bankfilecrc+2),hl             ; define config bank file CRC
                    ret
; *************************************************************************************

.presvbankflnm      defm ":RAM.-/bank."                 ; base filename for preserved bank in sector
.appName            defm "FlashStore", 0                ; application (DOR) name to search for in slot.
.flnm               defm "flashstore.epr", 0            ; 16K card image
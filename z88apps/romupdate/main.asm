; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005
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

     LIB MemDefBank, SafeBHLSegment, FlashEprWriteBlock

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
                    call ApplRomFindDOR
                    jp   c,suicide                      ; application DOR not found or no application ROM available.
                    call RegisterPreservedSectorBanks   ; register the banks to be preserved in the sector of the found DOR

                    ld   bc,128                         ; local filename (pointer)..
                    ld   hl,bankfilename                ; filename to card image
                    ld   de,filename                    ; output buffer for expanded filename (max 128 byte)...
                    ld   a, op_in
                    oz   GN_Opf
                    jp   c,suicide                      ; couldn't open file (in use / not found?)...

                    ld   de,buffer
                    ld   bc,16384                       ; 16K buffer
                    call CrcFile                        ; calculate CRC-32 of file, returned in DEHL
                    oz   GN_Cl                          ; close file again (we got the expanded filename)
                    call CheckBankFileCrc               ; check the CRC of the bank file with the CRC of the config file
                    jp   nz,suicide                     ; CRC didn't match: the file is corrupt and cannot be updated

                    call PreserveSectorBanks            ; preserve the sector banks to RAM filing system that are not being updated
                    call c,DeletePreservedSectorBanks   ; no room in filing system, delete any bank files already preserved....
                    jp   c,suicide                      ; then leave popdown...

                    ld   hl,buffer
                    ld   bc,16384                       ; 16K buffer
                    call CrcBuffer                      ; calculate CRC-32 of buffer (should be the same as above)

                    jp   suicide                        ; leave popdown...
; *************************************************************************************


; *************************************************************************************
; Register the banks of the 64K sector that is not part of the DOR of the found
; application in the [presvdbanks] array.
; The array will contain the numbers of the absolute banks that are going to be
; preserved as :RAM.-/bank.<bankno> files. The array contains four items, where a
; single item is 0, which is the bank of the application to be updated (hence
; not preserved as a bank file).
;
; IN:
;       BHL = pointer to application DOR to be updated
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
                    call nz,preserve                    ; this bank is to be preserved (not part of DOR)
                    inc  c
                    dec  c
                    ret  z                              ; sector is scanned for banks to be preserved
                    dec  c
                    dec  de
                    jr   preserve_loop
.notpreserved       ld   a,0                            ; indicate bank not to be preserved as 0
.preserve           ld   (de),a
                    ret
; *************************************************************************************


; *************************************************************************************
; Check the calculated CRC in DEHL with the CRC of the config file to validate that
; the binary bank file is not corrupted during transfer (or was corrupted in the
; RAM filing system).
;
; IN:
;       DEHL = calculated CRC
;
; OUT:
;       Fz = 1, CRC is valid
;       Fz = 0, CRC does not match the CRC from the Config file
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.CheckBankFileCrc
                    push bc
                    push de
                    push hl
                    cp   a
                    ld   bc,(bankfilecrc)
                    sbc  hl,bc
                    jr   nz, exit_checkcrc
                    ex   de,hl
                    ld   bc,(bankfilecrc+2)
                    sbc  hl,bc
.exit_checkcrc
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Save the banks to RAM filing system to be preserved (before sector erase) as
; ":RAM.-/bank.<bankno>" files. Three out of the four banks in the 64K sector is
; preserved. The remaining bank is handled separately which contains the code to be
; updated.
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
                    call nz,preservebank                ; this bank is to be preserved as a file
                    ret  c                              ; an error occurred while preserving a bank...

                    inc  b
                    dec  b
                    ret  z                              ; sector banks have been preserved
                    dec  b
                    dec  de
                    jr   presrvbank_loop
.preservebank
                    push bc
                    push de
                    ld   b,a
                    call GetBankFilename                ; filename based on bank number in B
                    ld   d,h
                    ld   e,l
                    ld   bc,128                         ; local filename
                    ld   a, OP_OUT
                    oz   GN_Opf
                    jr   c, exit_preservebank           ; couldn't create file (in use?)...

                    ld   hl,0
                    call SafeBHLSegment                 ; HL points at start of 'free' segment in Z80 address space

                    pop  de
                    push de
                    ld   a,(de)                         ; get bank (number) to be preserved
                    ld   b,a
                    call MemDefBank                     ; bind bank into Z80 address space
                    push bc                             ; (preserve old bank binding)
                    ld   bc, 16384
                    ld   de,0
                    oz   OS_MV                          ; copy bank contents to file...
                    pop  bc
                    call MemDefBank                     ; restore old bank binding
                    oz   GN_Cl                          ; close file (copy of bank)
.exit_preservebank
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Restore the banks into the 64K sector that was previously preserved in RAM filing
; system as ":RAM.-/bank.<bankno>" files. The banks to be restored are registered in
; the [presvdbanks] array.
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
                    call GetBankFilename                ; filename based on bank number in B
                    ld   d,h
                    ld   e,l
                    ld   bc,128                         ; local filename
                    ld   a, OP_IN
                    oz   GN_Opf
                    jr   c, exit_restorebanks           ; couldn't open file ...

                    ld   bc, 16384
                    ld   de,buffer
                    ld   hl,0
                    oz   OS_MV                          ; copy bank file contents into buffer...
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
;       (filename) = filename added with bank number extension
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
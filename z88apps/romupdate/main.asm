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

     include "error.def"
     include "director.def"
     include "stdio.def"
     include "memory.def"
     include "fileio.def"
     include "romupdate.def"

     lib MemDefBank, SafeBHLSegment
     lib FlashEprBlockErase, FlashEprWriteBlock, FlashEprCardId
     lib CreateWindow, FileEprRequest, ApplEprType

     xdef app_main
     xdef suicide
     xdef CheckCrc, BlowBufferToBank

     xref ReadConfigFile
     xref ApplRomFindDOR, ApplRomFirstDOR, ApplRomNextDOR, ApplRomReadDorPtr
     xref ApplRomCopyDor, ApplRomDorName, ApplRomSetNextDor, ApplRomCopyCardHdr
     xref CrcFile, CrcBuffer, IsBankUsed
     xref RegisterPreservedSectorBanks, PreserveSectorBanks, CheckPreservedSectorBanks
     xref RestoreSectorBanks, DeletePreservedSectorBanks
     xref ApplSegmentBinding, ApplSetSegmentBinding
     xref ApplTopicsPtr, ApplCommandsPtr, ApplHelpPtr, ApplTokenbasePtr
     xref ApplSetTopicsPtr, ApplSetCommandsPtr, ApplSetHelpPtr, ApplSetTokenbasePtr
     xref ErrMsgNoFlash, ErrMsgIntelFlash, ErrMsgBankFile, ErrMsgCrcFailBankFile, ErrMsgPresvBanks
     xref ErrMsgCrcCheckPresvBanks, ErrMsgSectorErase, ErrMsgBlowBank, ErrMsgNoRoom, ErrMsgAppDorNotFound
     xref ErrMsgActiveApps, ErrMsgNoFlashSupport
     xref MsgCompleted, MsgCrcCheckBankFile
     xref MsgUpdateBankFile
     xref CheckBankFreeSpace


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
.suicide
                    call DeletePreservedSectorBanks     ; clean up any temp bank files before leaving...
                    xor  a
                    oz   os_bye                         ; perform suicide, focus to Index...
.void               jr   void
; *************************************************************************************


; *************************************************************************************
; Main program entry
;
.app_main
                    ld   a, sc_ena
                    call_oz(os_esc)                     ; enable ESC detection

                    xor  a
                    ld   b,a
                    ld   hl,Errhandler
                    oz   os_erh                         ; then install Error Handler...
if POPDOWN
                    ld   a,'1' | 128
                    ld   bc,$0004
                    ld   de,$0854
                    ld   hl, progversion_banner
                    call CreateWindow                   ; the popdown needs to create it's own window (BBC BASIC has a window established)
else
                    ld   hl, bbcbas_progversion
                    oz   GN_Sop                         ; just display the program version in BBC BASIC
                    oz   GN_Nln
endif
                    ld   a,3                            ; make sure that no active application exists before running RomUpdate
.poll_slot_apps
                    or   a
                    jr   z, read_cfgfile                ; all external slots scanned with no active applications
                    oz   DC_Pol
                    jp   nz, ErrMsgActiveApps           ; active applications were found in external slot, RomUpdate will exit...
                    dec  a
                    jr   poll_slot_apps

.read_cfgfile
                    call ReadConfigFile                 ; load parameters from 'romupdate.cfg' file (exit app if failure...)

                    ; --------------------------------------------------------------------------------------------------------
                    ; check CRC of bank file to be updated on card (replacing bank of found DOR)
                    call MsgCrcCheckBankFile            ; display progress message for CRC check of bank file
                    call LoadBankFile
                    jp   c,ErrMsgBankFile               ; couldn't open file (in use / not found?)...

                    ld   hl,buffer
                    ld   bc,16384                       ; 16K buffer
                    call CrcBuffer                      ; calculate CRC-32 of bank file, returned in DEHL
                    call CheckBankFileCrc               ; check the CRC-32 of the bank file with the CRC of the config file
                    jp   nz,ErrMsgCrcFailBankFile       ; CRC didn't match: the file is corrupt and cannot be updated!
                    ; --------------------------------------------------------------------------------------------------------

                    ld   hl,buffer
                    ld   bc,(bankfiledor)
                    add  hl,bc                          ; the pointer to the DOR inside bank image file
                    ld   b,0                            ; (local pointer)
                    ld   de,dorcpy
                    call ApplRomCopyDor                 ; make a copy of DOR from bank image file
                    call ApplRomDorName
                    ex   de,hl
                    add  hl,bc                          ; HL points at first char of app name in DOR copy...
                    ld   (appname),hl                   ; Application DOR name search key established...

                    ld   c,3                            ; check external slots for an application card (from 3 downwards)
                    ld   de,(appname)                   ; search for appname in DOR's...
.findappslot_loop
                    call ApplRomFindDOR                 ; return pointer to found application DOR
                    jr   nc, try_upd_app                ; DOR was found in slot C, but can (possible) Flash Card be updated in slot?
                    inc  c
                    dec  c                              ; application DOR not found or no application ROM available,
                    jr   z, try_add_app                 ; all slots scanned and no DOR was found, try to add application to card...
                    dec  c
                    jr   findappslot_loop               ; poll next slot for DOR...
.try_add_app
                    ; --------------------------------------------------------------------------------------------------------
                    ; Application was not found in any of the external slots, try to add it to an available Flash Card
                    call ErrMsgAppDorNotFound
                    ld   c,3                            ; check external slots for a Flash Card (from 3 downwards)
.findflash_loop
                    call FlashWriteSupport
                    jr   nz, check_next_flash           ; no Flash Card recognized in slot C
                    jr   c, check_next_flash            ; Flash Card cannot be updated in slot C (Intel Flash not in slot 3)!

                    ; current slot has Flash Card write support, try to add application...
                    push bc
                    call FileEprRequest                 ; check if File Area (and application area) is available in slot C
                    pop  bc                             ; (preserve slot no. in C)
                    jr   z, check_filearea              ; file area exists, check if it can be shrinked to make room for new application
                    jr   c, check_freeappbank           ; either flash card is empty or there is no room for file area below apps area

                    ld   a,b                            ; BHL points at sector for a new (to be) file area, which means there's
                    and  @11000000                      ; room below current application area for new application...
                    ld   d,a                            ; (preserve slot mask)
                    call ApplEprType                    ; get exact size of application area in B
                    ld   a,$3f
                    sub  b
                    or   d
                    ld   (dorbank),a                    ; absolute (empty) bank no. for new application, just below application area
                    call IsBankUsed
                    ;jp   nz, ErrMsgNewBankNotEmpty

.check_freeappbank

.check_filearea
                    jp   suicide                        ; (REMOVE THIS WHEN IMPLEMENTED)
.check_next_flash
                    inc  c                              ; this slot didn't contain a Flash Card,
                    dec  c                              ; all slots done?
                    jp   z, ErrMsgNoFlashSupport        ; all slots scanned and no Flash Card was found (add not possible)...
                    dec  c
                    jr   findflash_loop                 ; poll next slot for Flash Card...
                    ; --------------------------------------------------------------------------------------------------------

.try_upd_app
                    ; --------------------------------------------------------------------------------------------------------
                    ; Application was found in slot C, try to update it..
                    call StoreDorInfo                   ; save found DOR information in memory variables
                    call CheckFlashWriteSupport         ; update application only if flash card in slot C has write/erase support
                    call MsgUpdateBankFile              ; display progress message for updating the new version of the application bank
                    call RegisterPreservedSectorBanks   ; Flash Card may be updated - register banks in the sector to be preserved
                    call CheckBankFreeSpace             ; enough space in RAM filing system for preserved banks?
                    jp   c,ErrMsgNoRoom                 ; No, report to user how much file space needs to be reclaimed..


                    ; --------------------------------------------------------------------------------------------------------
                    ; preserve passive banks to RAM filing system, including CRC check to ensure safe restore later...
                    call PreserveSectorBanks            ; preserve the sector banks to RAM filing system that are not being updated
                    jp   c,ErrMsgPresvBanks             ; insufficient room for passive sector banks or other I/O error, leave popdown...
                    call CheckPreservedSectorBanks      ; CRC validate the preserved passive bank files
                    jp   nz,ErrMsgCrcCheckPresvBanks    ; CRC check failed for passive sector banks, leave popdown...
                    ; --------------------------------------------------------------------------------------------------------


                    ; --------------------------------------------------------------------------------------------------------
                    ; update bank file DOR with brother link of DOR from old application, and update all old relative banks
                    ; with new bank number location in sector. Finally, blow bank with updated DOR back to card
                    call LoadBankFile                   ; get bank to be updated into buffer...
                    ld   hl,buffer                      ; bank file is loaded in (buffer)
                    ld   bc,(bankfiledor)
                    add  hl,bc
                    ld   b,0                            ; BHL = (local) pointer to base of bank file DOR
                    call AdjustDorBank

                    ; --------------------------------------------------------------------------------------------------------
                    ; if bank file to be updated is located at top of card, then use the application header from card!
                    ld   a,(dorbank)
                    ld   c,a
                    and  @00111111
                    cp   $3f                            ; is bank to be updated located at top of card?
                    jr   nz, erase_sector
                    ld   a,c                            ; yes, overwrite header in bank buffer with a copy from top of card
                    rlca
                    rlca
                    ld   hl,buffer                      ; start of bank (file)
                    ld   bc,$3fc0
                    add  hl,bc
                    ex   de,hl                          ; DE points to header in bank buffer
                    ld   c,a                            ; copy card header from slot C (derived from DOR bank no)
                    call ApplRomCopyCardHdr
                    ; --------------------------------------------------------------------------------------------------------
.erase_sector
                    ; --------------------------------------------------------------------------------------------------------
                    ; erase sector of bank (to be updated with new version of application)
                    ld   a,5
                    ld   (retry),a                      ; retry max 5 times to erase a block when the Flash Card Hardware reports error..
                    ld   a,(dorbank)
                    ld   b,a
                    rlca
                    rlca
                    and  @00000011
                    ld   c,a                            ; slot derived from absolute bank number
                    ld   a,b
                    rrca
                    rrca                                ; bankNo/4
                    and  @00001111                      ; sector number containing bank
                    ld   b,a
.retry_erase_sector
                    call FlashEprBlockErase
                    jr   nc, sector_erased
                    ld   hl,retry                       ; sector was not erased properly, try 5 more times...
                    dec  (hl)
                    jr   nz,retry_erase_sector
                    jp   ErrMsgSectorErase              ; fatal error - sector was not erased after 5 retries (battery low or bad slot connection)
                    ; --------------------------------------------------------------------------------------------------------

.sector_erased
                    ; --------------------------------------------------------------------------------------------------------
                    ; finally, updated bank (file) with adjusted DOR bank numbers back to card (replacing old copy of application bank
                    ld   a,(dorbank)
                    ld   b,a
                    call BlowBufferToBank               ; old application updated with new application!
                    ld   hl, bankfilename               ; name of application bank file (specified in config file)
                    jp   c,ErrMsgBlowBank               ; fatal error -  this only happens if there is a bad slot connection

                    call RestoreSectorBanks             ; blow the three 'passive' banks back to the sector
                    ld   hl,filename                    ; name of current passive filename being restored
                    jp   c, ErrMsgBlowBank
                    jp   MsgCompleted                   ; display completed messagem then leave by KILL request...
                    ; --------------------------------------------------------------------------------------------------------
; *************************************************************************************


; *************************************************************************************
; Load config specified bank file into 16K buffer
;
; Registers changed after return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
.LoadBankFile
                    ld   bc,128
                    ld   hl,bankfilename                ; (local) filename to card image
                    ld   de,filename                    ; output buffer for expanded filename (max 128 byte)...
                    ld   a, op_in
                    oz   GN_Opf
                    ret  c
                    ld   bc,16384
                    ld   de,buffer
                    ld   hl,0
                    oz   OS_MV                          ; copy bank file contents into buffer...
                    push af
                    oz   GN_Cl                          ; close file
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; Store the found DOR (in BHL) to variables (dorbank) & (doroffset), and the
; brother link (next DOR in list) to (nextdorbank) & (nextdoroffset)
;
; Registers changed after return:
;    AFBBCDEHL/IXIY same
;    ......../.... different
;
.StoreDorInfo
                    push af
                    ld   a,b
                    ld   (dorbank),a                    ; preserve the pointer to found DOR in slot C
                    ld   (doroffset),hl
                    push bc
                    push hl
                    call ApplRomNextDor                 ; get brother link to next application DOR in list
                    ld   a,b
                    ld   (nextdorbank),a                ; and preserve it to be patched into DOR in bank file to be updated
                    ld   (nextdoroffset),hl
                    pop  hl
                    pop  bc
                    pop  af
                    ret
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
; Update the specified DOR with correct bank reference for the location, where
; the bank file is going to be updated in the slot.
;
; (dorbank) contains the bank number to be updated in pointer references of the DOR.
; The DOR originally contains the bank references that point to the same location as the
; bank file.
;
; The following pointers are updated in the DOR:
;   Brother DOR (next app in list)
;   The application segment bindings (0-3)
;   Topic, Command, Help & Token base pointers.
;
; IN:
;       BHL = pointer to base of DOR record (B typically 0 for local addr space buffer)
; OUT:
;       DOR pointers adjusted to use relative bank reference in slot.
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.AdjustDorBank
                    ld   a,(nextdorbank)
                    ld   c,a
                    ld   de,(nextdoroffset)             ; CDE = brother link from original application DOR in card
                    call ApplRomSetNextDor

                    ld   bc,3                           ; Start to get DOR segment 3 bank binding (DOR is available in local address space, B=0)...
.updsegments_loop   call ApplSegmentBinding             ; get current segment C bank binding
                    or   a
                    jr   z, no_segm_binding             ; 0 indicates no bank binding
                    ld   a,(dorbank)
                    call ApplSetSegmentBinding          ; update default bank segment C binding for new location in sector
.no_segm_binding    inc  c
                    dec  c
                    jr   z, update_mth                  ; all DOR bank segment bindings updated
                    dec  c
                    jr   updsegments_loop
.update_mth
                    call ApplTopicsPtr                  ; get pointer to MTH Topics in CDE
                    ld   a,(dorbank)
                    push af
                    ld   c,a
                    call ApplSetTopicsPtr               ; update MTH Topics pointer with new bank
                    call ApplCommandsPtr
                    pop  af
                    push af
                    ld   c,a
                    call ApplSetCommandsPtr             ; update MTH Commands pointer with new bank
                    call ApplHelpPtr
                    pop  af
                    push af
                    ld   c,a
                    call ApplSetHelpPtr                 ; update MTH Help pointer with new bank
                    call ApplTokenbasePtr
                    pop  af
                    ld   c,a
                    call ApplSetTokenbasePtr            ; update MTH Help pointer with new bank
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
; Blow contents of 16K buffer to bank B in Flash Card
;
; IN:
;       B = Bank number (absolute)
; OUT:
;       Fc = 1, bank was not blown properly to Flash Card.
;              A = RC_ error code
;       Fc = 0, bank were successfully blown to Flash Card.
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.BlowBufferToBank
                    push bc
                    push de
                    push hl
                    push iy

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
                    pop  iy
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Check if current slot supports Flash Write/erase operations.
; Return only if write/erase support is available for slot. In error situation,
; display error message and exit RomUpdate program.
;
; IN:
;    C = slot Number
;
; OUT:
;    Only returns with Fz = 1, Fc = 0 (Flash Card available in slot, write/erase support)
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.CheckFlashWriteSupport
                    push bc
                    call FlashWriteSupport              ; is flash card updateable in slot C?
                    pop  bc                             ; (restore bank no of pointer to DOR)
                    jp   nz,ErrMsgNoFlash               ; Display error to user that app. can only be updated on Flash Card (not Eprom)
                    jp   c,ErrMsgIntelFlash             ; no write/erase support for Intel Flash Card other than in slot 3
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


.bbcbas_progversion defm 12                             ; clear window before displaying program version (BBC BASIC only)
.progversion_banner defm 1, "BRomUpdate V0.6.3", 1,"B", 0


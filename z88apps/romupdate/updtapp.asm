; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2008
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

     MODULE UpdateApplication

     include "error.def"
     include "director.def"
     include "stdio.def"
     include "memory.def"
     include "fileio.def"
     include "romupdate.def"

     lib FlashEprBlockErase, FlashEprReduceFileArea
     lib FileEprRequest, FileEprFreeSpace, ApplEprType

     xdef Update_16k_application

     xref BlowBufferToBank, CopyBank
     xref ApplRomFindDOR, ApplRomNextDOR
     xref ApplRomCopyDor, ApplRomDorName, ApplRomSetNextDor, ApplRomCopyCardHdr
     xref IsBankUsed
     xref RegisterPreservedSectorBanks, PreserveSectorBanks, CheckPreservedSectorBanks
     xref RestoreSectorBanks
     xref ApplSegmentBinding, ApplSetSegmentBinding
     xref ApplTopicsPtr, ApplCommandsPtr, ApplHelpPtr, ApplTokenbasePtr
     xref ApplSetTopicsPtr, ApplSetCommandsPtr, ApplSetHelpPtr, ApplSetTokenbasePtr
     xref ErrMsgPresvBanks
     xref ErrMsgCrcCheckPresvBanks, ErrMsgSectorErase, ErrMsgBlowBank, ErrMsgNoRoom, ErrMsgAppDorNotFound
     xref ErrMsgActiveApps, ErrMsgNoFlashSupport, ErrMsgNewBankNotEmpty, ErrMsgReduceFileArea
     xref MsgUpdateCompleted, MsgAddCompleted
     xref MsgUpdateBankFile, MsgAddBankFile, ApplRomLastDor
     xref CheckBankFreeSpace
     xref CheckFlashWriteSupport, FlashWriteSupport
     xref GetSlotNo, GetSectorNo
     xref GetTotalFreeRam
     xref LoadRamBankFile


; --------------------------------------------------------------------------------------------------------
; Update 16K application bank on a found card in slots 1-3
;
.Update_16k_application
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
                    jp   nc, try_upd_app                ; DOR was found in slot C, but can (possible) Flash Card be updated in slot?
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
                    jp   nz, check_next_flash           ; no Flash Card recognized in slot C
                    jp   c, check_next_flash            ; Flash Card cannot be updated in slot C (Intel Flash not in slot 3)!

                    ld   a,c
                    oz   DC_Pol                         ; check that no applications are running on the flash card, before updating it
                    jp   nz, ErrMsgActiveApps           ; active apps were found - RomUpdate will exit...

                    ; current slot has Flash Card write support, try to add application...
                    ld   a,c
                    rrca
                    rrca
                    and  @11000000
                    ld   e,a                            ; slot mask in E for absolute bank no. calculation
                    push bc
                    call FileEprRequest                 ; check if File Area (and application area) is available in slot C
                    jr   z, check_filearea              ; file area exists, check if it is is necessary to be shrinked to make room for new app
                    jr   c, check_freeappbank           ; either flash card is empty or there is no room for file area below apps area
                    pop  bc
                    jr   add_new_app                    ; if there's room for a new file area, then we can add an app bank too..
.check_filearea
                    ld   a,b
                    pop  bc                             ; (slot no. restored in C)
                    ld   (dorbank),a                    ; register bank for found file header (used for ErrMsgReduceFileArea)...
                    ld   d,a                            ; are there free banks between app area and the file ara?
                    ld   l,c
                    call ApplEprType
                    jr   c, check_fa_free_space         ; file card only, try to shrink...
                    ld   c,l                            ; restore slot no. in C
                    ld   a,$3f
                    sub  b                              ; a = new relative (possible) empty bank
                    res  7,d
                    res  6,d                            ; relative bank of top of file area
                    cp   d
                    jr   nz, exec_add_appbank           ; empty bank above file area... application bank can be added...
.check_fa_free_space
                    ; --------------------------------------------------------------------------------------------------------
                    ; no empty banks between app area and file area (or file card only). Shrink file area (if possible), then add app...
                    push de                             ; (preserve slot mask)
                    push bc
                    call FileEprFreeSpace               ; return free space of file area in DEBC (DE = most significant word..)
                    pop  bc
                    ld   hl,1                           ; the file area must have more than 64K (65536 bytes free), to be shrinked
                    sbc  hl,de                          ; (64K = $10000)
                    pop  de                             ; (slot mask restored)
                    jr   c, shrink_fa                   ; free space > 64K in file area, it's shrinkable..
                    jp   nz, try_next_slot              ; free space < 64K, poll next slot...
.shrink_fa
                    ld   b,1
                    ld   d,c                            ; (preserve slot no)
                    call FlashEprReduceFileArea         ; try shrink file area by one sector (64K) to make room for new app bank
                    jp   c,ErrMsgReduceFileArea
                    ld   c,d                            ; (C = slot no)
                    call ApplEprType                    ; get exact size of application area in B, card size in C
                    jr   c, file_card                   ; there was no "OZ" application card header, it was a file card only...
                    jr   check_newbankroom              ; file area reduced, insert application bank (file) between file & app area in slot C
.file_card          ld   c,d                            ; (restore slot no in C)
                    jp   newapp_empty_card              ; add application at top of card (in top sector, just above shrinked file area)

.check_freeappbank
                    pop  bc                             ; (restore slot no. in C)
                    cp   RC_ONF
                    jp   z, newapp_empty_card           ; slot contains an 'empty' card, ie. with no Card header, nor File Area header
.add_new_app                                            ; (RC_ROOM was returned...)
                    call ApplEprType                    ; get exact size of application area in B, card size in C
.check_newbankroom  ld   a,c                            ; there was no room for a file area, maybe there's
                    sub  b                              ; room for an application bank appended to application area?
                    jr   z, try_next_slot               ; no, complete card is filled with applications, try next slot...
.exec_add_appbank
                    ; --------------------------------------------------------------------------------------------------------
                    ; append bank to bottom of application area (file area not available, or free banks between app & file area)
                    call GetTotalFreeRam
                    push de                             ; preserve slot mask (in E)
                    ld   de,67*3
                    sbc  hl,de                          ; make sure that Z88 has 3 * 16K bank file space for temp files in RAM
                    pop  de
                    jp   c,ErrMsgNoRoom                 ; No, report to user how much file space needs to be reclaimed..

                    call GetFreeAppBankNo               ; get free bank no. below app area (using slot mask in E, and app area size in B)
                    call IsBankUsed                     ; is bank really empty on card?
                    jp   nz, ErrMsgNewBankNotEmpty

                    ld   (dorbank),a
                    call MsgAddBankFile                 ; "Adding <Appnam> (from file <filename>) to slot x"

                    ld   b,0                            ; (local pointer)
                    ld   hl,(bankfiledor)
                    ld   de,buffer
                    add  hl,de                          ; BHL = base pointer to DOR in Bank file (currently loaded in buffer)
                    ld   c,b
                    ld   d,b
                    ld   e,b                            ; CDE = 0 (this is going to be last DOR in application list...)
                    call AdjustDorBank                  ; adjust DOR pointers in bank file to new location in card
                    ld   a,(dorbank)
                    ld   b,a                            ; blow bank file in buffer to slot C
                    xor  a                              ; poll for flash programming algorithm...
                    call BlowBufferToBank               ; add new application to card
                    ld   hl, bankfilename               ; name of application bank file (specified in config file)
                    jp   c, ErrMsgBlowBank              ; fatal error -  this only happens if there is a bad slot connection
                    ld   a,b
                    call GetSlotNo                      ; bank no -> slot no in C
                    call ApplRomLastDor                 ; point to last DOR in BHL of slot C (that's going to point to new app)
                    call CopyBank                       ; copy contents of bank B containing DOR into buffer
                    push bc
                    ld   bc,buffer
                    res  7,h
                    res  6,h                            ; pointer to DOR is offset within bank...
                    add  hl,bc
                    ld   b,0                            ; BHL pointer to last DOR now within buffer (in RAM)
                    ld   a,(dorbank)
                    ld   c,a
                    ld   de,(bankfiledor)               ; CDE = pointer to new (added) application code & DOR in slot C
                    call ApplRomSetNextDor              ; set link to added application DOR (now the last DOR in the list)
                    pop  bc
                    push bc
                    ld   a,b
                    ld   (dorbank),a                    ; register DOR bank to be updated...
                    ld   hl, upddorlist_msg             ; sub message if update fails...
                    call UpdateSector
                    pop  bc
                    ld   a,b
                    or   $3f
                    ld   (dorbank),a                    ; register top bank to be updated (containing card header)
                    ld   b,a
                    call CopyBank                       ; copy bank containing card header
                    ld   hl,buffer+$3ffc
                    inc  (hl)                           ; total of banks in application area adjusted for new application bank
                    ld   hl,cardheader_msg              ; sub message for card header failure...
                    call UpdateSector                   ; update top bank of card with updated application card header
                    jp   MsgAddCompleted                ; App added! Display completed message, then by soft reset to refresh Index apps...
                    ; --------------------------------------------------------------------------------------------------------
.try_next_slot
                    ld   c,e
                    rlc  c
                    rlc  c                              ; convert slot mask back to a slot number...
.check_next_flash
                    inc  c                              ; this slot didn't contain a Flash Card,
                    dec  c                              ; all slots done?
                    jp   z, ErrMsgNoFlashSupport        ; all slots scanned and no Flash Card was found (add not possible)...
                    dec  c
                    jp   findflash_loop                 ; poll next slot for Flash Card...
                    ; --------------------------------------------------------------------------------------------------------
.newapp_empty_card
                    ; --------------------------------------------------------------------------------------------------------
                    ; blow 16K bank image to top of slot C (the bank is already in buffer). The 16K bank is already configured
                    ; to be a stand-alone application, using $3F bank references...
                    ld   b,15                           ; top sector of 1MB Flash card
                    call EraseSector                    ; erase top sector in slot C
                    ld   a,c
                    rrca
                    rrca
                    or   $3f
                    ld   (dorbank),a                    ; register the bank to be added...
                    ld   b,a                            ; blow bank file in buffer to top of slot C
                    xor  a                              ; poll for flash programming algorithm...
                    call BlowBufferToBank               ; old application updated with new application!
                    ld   hl, bankfilename               ; name of application bank file (specified in config file)
                    jp   c, ErrMsgBlowBank              ; fatal error -  this only happens if there is a bad slot connection
                    jp   MsgAddCompleted                ; display completed message, then leave by soft reset (to refresh Index app list)...
                    ; --------------------------------------------------------------------------------------------------------
.try_upd_app
                    ; --------------------------------------------------------------------------------------------------------
                    ; Application was found in slot C, try to update it..
                    call StoreDorInfo                   ; save found DOR information in memory variables

                    call CheckFlashWriteSupport         ; update application only if flash card in slot C has write/erase support

                    ld   a,c
                    oz   DC_Pol                         ; check that no applications are running on the flash card, before updating it
                    jp   nz, ErrMsgActiveApps           ; active apps were found - RomUpdate will exit...

                    call MsgUpdateBankFile              ; display progress message for updating the new version of the application bank

                    ; --------------------------------------------------------------------------------------------------------
                    ; update bank file DOR with brother link of DOR from old application, and update all old relative banks
                    ; with new bank number location in sector. Finally, blow bank with updated DOR back to card
                    call LoadRamBankFile                ; get bank to be updated into buffer...
                    ld   hl,buffer                      ; bank file is loaded in (buffer)
                    ld   bc,(bankfiledor)
                    add  hl,bc
                    ld   b,0                            ; BHL = (local) pointer to base of bank file DOR
                    ld   a,(nextdorbank)
                    ld   c,a
                    ld   de,(nextdoroffset)             ; CDE = brother link from original application DOR in card
                    call AdjustDorBank

                    ; --------------------------------------------------------------------------------------------------------
                    ; if bank file to be updated is located at top of card, then use the application header from card!
                    ld   a,(dorbank)
                    ld   c,a
                    and  @00111111
                    cp   $3f                            ; is bank to be updated located at top of card?
                    jr   nz, update_bankfile
                    ld   a,c                            ; yes, overwrite header in bank buffer with a copy from top of card
                    rlca
                    rlca
                    ld   c,a                            ; copy card header from slot C (derived from DOR bank no)
                    ld   de,buffer+$3fc0                ; destination pointer to card header in buffer (of bank file)
                    call ApplRomCopyCardHdr
                    ; --------------------------------------------------------------------------------------------------------
.update_bankfile
                    ld   a,(dorbank)
                    ld   b,a
                    ld   hl,bankfilename
                    call UpdateSector
                    jp   MsgUpdateCompleted             ; display completed message then leave by KILL request...
; *************************************************************************************



; *************************************************************************************
; Return free application (absolute) bank no. below application area in current slot.
;
; IN:
;    B = size of application area in 16K banks
;    E = slot mask ($40 for slot 1, $80 for slot 2, $C0 for slot 3)
;
; OUT:
;    (dorbank),A = absolute bank no. of position in card to blow bank file
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.GetFreeAppBankNo
                    ld   a,$3f                          ; top of card (relative)
                    sub  b                              ; size of application area
                    or   e                              ; mask with slot to get absolute bank number
                    ld   (dorbank),a                    ; (empty) bank for new application bank file, below application area
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
;       CDE = pointer to next DOR (that this DOR will point to...)
; OUT:
;       DOR pointers adjusted to use relative bank reference in slot.
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.AdjustDorBank
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
; Erase sector B of flash card in slot C.
; Abort RomUpdate if erase has been retried 5 times unsuccessfully
;
; IN:
;    B = sector number
;    C = slot Number
;
; OUT:
;    Only returns with Fc = 0 (sector erased in Flash Card)
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.EraseSector
                    push hl
                    ld   hl,retry                       ; sector was not erased properly, try 5 more times...
                    ld   a,5
                    ld   (hl),a                         ; retry max 5 times to erase a block when the Flash Card Hardware reports error..
.retry_erase_sector
                    call FlashEprBlockErase
                    jr   nc, sector_erased
                    dec  (hl)
                    jr   nz,retry_erase_sector
                    jp   ErrMsgSectorErase              ; fatal error - sector was not erased after 5 retries - abort RomUpdate
.sector_erased                                          ; (battery low or bad slot connection)
                    pop  hl
                    ret
; *************************************************************************************



; *************************************************************************************
; Update bank, currently stored in 16K buffer, to bank B on card.
; (preserve passive banks, erase sector, update bank from buffer, restore passive banks)
;
; If update fails, an error message is displayed and RomUpdate exits...
; This routine only returns if sector was updated successfully.
;
; IN:
;   B = bank no (absolute) to update with 16K buffer
;   HL = sub error message string if update fails for bank (string will be part of ErrMsgBlowBank)
; OUT:
;   Fc = 0
;       Update succeeded.
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.UpdateSector
                    push hl
                    push bc
                    call RegisterPreservedSectorBanks   ; register bank B to be updated (rest of sector to be preserved)...
                    call CheckBankFreeSpace             ; enough space in RAM filing system for preserved banks?
                    jp   c,ErrMsgNoRoom                 ; No, report to user how much file space needs to be reclaimed..

                    ; --------------------------------------------------------------------------------------------------------
                    ; preserve passive banks to RAM filing system, including CRC check to ensure a safe restore later...
                    call PreserveSectorBanks            ; preserve the sector banks to RAM filing system
                    jp   c,ErrMsgPresvBanks             ; insufficient room for passive sector banks or other I/O error, leave popdown...
                    call CheckPreservedSectorBanks      ; CRC validate the preserved passive bank files
                    jp   nz,ErrMsgCrcCheckPresvBanks    ; CRC check failed for passive sector banks, leave popdown...
                    ; --------------------------------------------------------------------------------------------------------

                    ; --------------------------------------------------------------------------------------------------------
                    pop  bc
                    push bc
                    ld   a,b
                    call GetSlotNo                      ; C = slot number from absolute bank number
                    ld   a,b
                    call GetSectorNo
                    ld   b,a                            ; B = sector number derived from absolute bank number
                    call EraseSector                    ; erase sector B in slot C (abort RomUpdate after 5 failed retries)
                    ; --------------------------------------------------------------------------------------------------------

                    pop  bc
                    xor  a                              ; poll for flash programming algorithm...
                    call BlowBufferToBank               ; blow updated bank back to card.
                    pop  hl                             ; display sub-message (explaining what went wrong)
                    jp   c,ErrMsgBlowBank               ; fatal error!

                    call RestoreSectorBanks             ; blow the three (or less) 'passive' banks back to the sector
                    ld   hl,filename                    ; name of current passive filename being restored
                    jp   c, ErrMsgBlowBank
                    ret
; *************************************************************************************


.upddorlist_msg     defm "with updated DOR List", 0
.cardheader_msg     defm "with card header", 0

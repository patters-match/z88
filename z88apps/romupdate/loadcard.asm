; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gstrube@gmail.com) 2005-2011
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
; *************************************************************************************

     MODULE LoadCard

     ; OZ system defintions
     include "stdio.def"
     include "flashepr.def"
     include "memory.def"
     include "director.def"
     include "blink.def"
     include "card.def"
     include "error.def"

     ; RomUpdate runtime variables
     include "romupdate.def"

     lib OZSlotPoll

     xdef LoadCard

     xref FlashWriteSupport, EraseFlashCard, ErrMsgCard, ErrMsgSlotActive
     xref BlowBufferToBank, MsgUpdCard, SopNln
     xref MsgCardUpdated, ErrMsgBlowBankNo, ErrMsgEraseCardFiles
     xref GetOZSlotNo, rdch
     xref selectslot_prompt
     xref CheckConfigLocation


; *************************************************************************************
; Load / blow card to slot X.
;
.LoadCard
                    ld   hl, selectslot_prompt          ; convey to end-user to select destination slot number
                    oz   Gn_Sop
.inp03_loop
                    ld   a,(crd_slot)
                    or   48
                    oz   OS_Out                         ; display current select device number
                    ld   a,8
                    oz   OS_Out                         ; BACKSPACE (cursor on top of number)

                    call rdch
                    jr   c,inp03_loop                   ; if BBC BASIC was pre-empted, just continue to wait for slot number

                    cp   in_ent
                    jr   z,slot_selected
                    cp   '1'
                    jr   c, inp03_loop
                    cp   '4'
                    jr   nc, inp03_loop
                    
                    sub  48
                    ld   (crd_slot),a
                    jr   inp03_loop
.slot_selected
                    oz   GN_Nln

                    call GetOZSlotNo                    ; slot no in C
                    call FlashWriteSupport              ; make sure that we have an AMD/STM 512K flash chip in slot X
                    jr   nc, flash_found
                    jp   ErrMsgCard                     ; "Card banks cannot be updated. Flash device was not found in slot X"
.flash_found
                    call OZSlotPoll
                    jr   z, no_oz_running
                    jp   ErrMsgSlotActive               ; OZ is running in selected slot! Abort.
.no_oz_running
                    ld   a,c
                    oz   DC_Pol
                    jp   nz,ErrMsgSlotActive            ; active applications are running in selected slot!  Abort.

                    ld   iy,crdbanks                    ; get ready for first bank entry of [total_banks]

                    call CheckConfigLocation            ; Are bank files located in File Card?
                    jr   z, InstallCard
                    ld   a,(iy+2)                       ; B = Bank of first file pointer to File Area entry 
                    AND  @11000000
                    rlca
                    rlca                                ; converted slot mask to slot number
                    cp   c
                    jr   nz,InstallCard
                    jp   ErrMsgEraseCardFiles           ; end user selected target slot of File Card with bank files!

; ----------------------------------------------------------------------------------------------------------------------
; Install Card banks on Card, identified by crdbanks[] array.
;
.InstallCard
                    call MsgUpdCard                     ; "Updating Card banks in slot X - please wait..." (flashing)
                    call EraseFlashCard                 ; erase card

                    ld   hl,total_banks
                    ld   b,(hl)                         ; total of banks to update to slot X...
.update_card_loop
                    push bc
                    ld   hl, bank_loader_ret
                    push hl                             ; RET from bank file loader routine
                    ld   hl,(bank_loader)
                    jp   (hl)                           ; copy bank file contents (IY points to bank file entry) to 16K RomUpdate buffer...
.bank_loader_ret
                    ld   b,(iy+3)                       ; bank data in buffer to be blown to bank no. in slot X
                    res  7,b
                    res  6,b                            ; remove slot mask of original destination bank number for bank file
                    ld   a,(crd_slot)
                    rrca
                    rrca                                ; slot number -> slot mask
                    or   b
                    ld   b,a                            ; bank number in romupdate.cfg converted to specified slot "OZ.x" number
                    ld   (dorbank),a
                    ld   a,(flash_algorithm)            ; use programming algorithm to blow bank to slot X
                    call BlowBufferToBank
                    jr   c,err_blowbank

                    inc  iy
                    inc  iy
                    inc  iy
                    inc  iy                             ; point at next bank data entry
                    pop  bc
                    djnz update_card_loop               ; blow banks to slot X...
                    jp   MsgCardUpdated                 ; Card banks done
.err_blowbank
                    pop  bc
                    ld   a,(dorbank)
                    ld   b,0
                    ld   c,a
                    jp   ErrMsgBlowBankNo

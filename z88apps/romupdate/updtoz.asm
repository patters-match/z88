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

     MODULE UpdateOZrom

     ; OZ system defintions
     include "stdio.def"
     include "flashepr.def"
     include "memory.def"
     include "screen.def"
     include "blink.def"

     ; RomUpdate runtime variables
     include "romupdate.def"

     lib DisableBlinkInt                                ; No interrupts get out of Blink
     lib EnableBlinkInt                                 ; Allow interrupts to get out of Blink again
     lib FlashEprCardErase                              ; erase complete Flash chip to FFs
     lib FlashEprBlockErase                             ; erase specified block on Flash chip
     lib MemDefBank                                     ; Bind bank, defined in B, into segment C. Return old bank binding in B
     lib MemGetBank                                     ; Return bank binding in B of segment C
     lib ApplEprType                                    ; poll slot for application card type

     xdef Update_OzRom
     xref suicide, FlashWriteSupport, ErrMsgOzRom
     xref BlowBufferToBank, MsgUpdOzRom
     xref LoadEprFile
     xref hrdreset_msg, MsgOZUpdated
     xref SopNln

     xdef CopyRamFile2Buffer, CopyEprFile2Buffer



; *************************************************************************************
; Update OZ ROM to slot X
; The system will be hard reset for slot 0 and 1,
; for slots 2 and 3, the card will just be updated without affecting the system
;
.Update_OzRom
                    ld   a,(oz_slot)
                    ld   c,a                            ; make sure that we have an AMD/STM 512K flash chip in slot X
                    call FlashWriteSupport
                    jr   nc, flash_found
                    jp   ErrMsgOzRom                    ; "OZ ROM cannot be updated. Flash device was not found in slot X"

.flash_found
                    or   a
                    jr   z, upd_slot01                  ; update OZ to slot 0
                    cp   1
                    jr   z, upd_slot01                  ; when updating slot 0 or 1, the complete machine needs to be hard reset after update

                    call MsgUpdOzRom                    ; "Updating OZ ROM in slot X - please wait..." (flashing)
                    call EraseOzFlashCard               ; erase card
                    call InstallOZ                      ; then blow OZ banks on it.
                    jp   MsgOZUpdated                   ; OZ done, instruct user to insert card in slot 1 and hard reset..

; ----------------------------------------------------------------------------------------------------------------------
; Core routine to update OZ in slot 0 or 1 (where OZ is possibly already running)
.upd_slot01
                    call MsgUpdOzRom                    ; "Updating OZ ROM in slot X - please wait..." (flashing)
                    ld   hl, hrdreset_msg               ; "Z88 will automatically hard reset when updating has completed."
                    call SopNln

; ----------------------------------------------------------------------------------------------------------------------
; before erasing slot X (wiping out the current OZ ROM code) and programming the bank files to slot X, patch the
; RST 38H and RST 66H interrupt vectors in lower 8K RAM to return immediately (executing no functionality).
; This prevents any accidental interrupt being executed into a non-existing OZ ROM - or even worse - Flash memory
; that is not in Read Array Mode!
; ----------------------------------------------------------------------------------------------------------------------
                    call DisableBlinkInt                ; don't let any interrupts out of Blink while we patch...
                    ld   hl, 0038H
                    ld   (hl),$C9                       ; patch RST 38H maskable interrupt vector with an immediate RET instruction
                    ld   hl, 0066H
                    ld   (hl),$C9                       ; patch RST 66H non-maskable interrupt vector with an immediate RET instruction
                    call EnableBlinkInt                 ; the low ram interrupt vector code from OZ is automatically restored during reset...

; ----------------------------------------------------------------------------------------------------------------------
; just before we wipe out the OZ rom, move the font bitmaps to RAM
; copy the LORES1 font bitmaps to RAM to use the new location
                    ld   sp,ozstack                     ; move system stack just below segment 2 (moved from $1FFE area)
                    ld   a,SC_LR1
                    ld   b,0
                    oz   Os_Sci                         ; get BHL address of LORES1 font bitmaps
                    ld   c,MS_S3                        ; Use segment 3 to bind in bank of LORES1 (RomUpdate BBC BASIC is running in segment 0 & 1)
                    call MemDefBank
                    set  7,h                            ; Use segment 3 to bind in bank of sector (RomUpdate BBC BASIC is running in segment 0 & 1)
                    set  6,h                            ; (16K buffer is in segment 2)
                    ld   bc,$1000                       ; copy 4K of LORES1 bitmaps...
                    push bc
                    push bc
                    pop  de
                    ldir                                ; copy LORES1 font bitmap to $20 1000 ($20 already bound in as LOWRAM)
                    ld   a,SC_LR1
                    ld   b,$20
                    pop  hl
                    oz   Os_Sci                         ; set new BHL address of LORES1 font bitmap that is now available at $20 1000

; ----------------------------------------------------------------------------------------------------------------------
; copy the HIRES1 font bitmap to RAM (in HIRES0) and re-assign to use as new HIRES1 font
; (HIRES0 is not used at this point, and we need to re-locate the HIRES1 to a 2K RAM buffer - HIRES0 is 2K...)
                    ld   a,SC_HR1
                    ld   b,0
                    oz   Os_Sci                         ; get HIRES1 font bitmap address in BHL inside current OZ ROM
                    ld   c,MS_S3                        ; Use segment 3 to bind in bank of HIRES1 (RomUpdate BBC BASIC is running in segment 0 & 1)
                    call MemDefBank
                    set  7,h
                    set  6,h
                    ld   de,$8000                       ; (16K buffer is in segment 2)
                    push de
                    ld   bc,1024*2
                    ldir                                ; copy HIRES1 to buffer
                    ld   a,SC_HR0
                    ld   b,0
                    oz   Os_Sci                         ; get address of HIRES0 graphics (UDG)
                    pop  de
                    push bc
                    push hl
                    ld   c,MS_S3                        ; Use segment 3 to bind in bank of HIRES0
                    call MemDefBank
                    set  7,h
                    set  6,h
                    ex   de,hl
                    ld   bc,1024*2
                    ldir                                ; copy 2K HIRES1 font (from buffer) to HIRES0 in RAM

                    ld   a,SC_HR1
                    pop  hl
                    pop  bc
                    oz   Os_Sci                         ; re-assign HIRES1 base address to point in RAM

                    call EraseOzFlashCard               ; Prepare FlashCard for OZ
                    call InstallOZ

; ----------------------------------------------------------------------------------------------------------------------
; OZ ROM banks have been programmed successfully to slot 0 or 1.
; Finally, it's time to issue a hard reset to start up a clean machine with the updated OZ ROM.
; ----------------------------------------------------------------------------------------------------------------------
                    ld   a, $21                         ; RAM bank $21 (:RAM.0 filing system)
                    out  (BL_SR2), a                    ; b21 into Segment 2 (which has no executing code by RomUpdate popdown nor BBC BASIC)
                    ld   hl,0
                    ld   ($8000),hl                     ; remove RAM filing system tag $A55A in start of bank $21 that forces OZ to HARD RESET
                    jp   (hl)                           ; execute the hard reset..


; ----------------------------------------------------------------------------------------------------------------------
; Erase flash card (or part of card) to prepare for new OZ code.
;   Complete chip is erased in slot 0 (file area between header and OZ), or any other card in external slot X without OZ ROM
;   - If an OZ ROM is recognized in external slot X, then only the OZ area (top of card) is erased.
;     This allows any file area below the OZ ROM area to be preserved during update.
;
;   TODO: Move File area downwards if possible, when new OZ binary update is bigger than OZ on card in slot X
;
.EraseOzFlashCard
                    ld   a,(oz_slot)
                    ld   c,a
                    push bc
                    or   a
                    jr   z, erase_chip
                    call ApplEprType
                    cp   $81
                    jr   nz,erase_chip                   ; erase complete card for everything except for OZ ROM

                    srl  b
                    srl  b
                    ld   d,b                             ; D = number of blocks to erase
                    srl  c
                    srl  c
                    dec  c                               ; converted total size of card to top block number to erase
                    ld   a,c
                    pop  bc                              ; erase blocks in slot C
                    ld   b,a                             ; begin with top block on card
.erase_ozarea
                    call FlashEprBlockErase
                    dec  b                               ; next block number is below the block just erased...
                    dec  d
                    jr   nz, erase_ozarea                ; erase top area of card for OZ
                    ret
.erase_chip
                    pop  bc                              ; erase entire card in slot C
                    call FlashEprCardErase
                    ret


; ----------------------------------------------------------------------------------------------------------------------
; Install OZ banks on Card, identified by ozbanks[] array.
;
.InstallOZ
                    ld   iy,ozbanks                     ; get ready for first oz bank entry of [total_ozbanks]
                    ld   b,(iy-1)                       ; total of banks to update to slot X...
.update_ozrom_loop
                    push bc
                    ld   hl, ozbank_loader_ret
                    push hl                             ; RET from OZ bank file loader routine
                    ld   hl,(ozbank_loader)
                    jp  (hl)                            ; copy bank file contents (IY points to bank file entry) to 16K RomUpdate buffer...
.ozbank_loader_ret
                    ld   b,(iy+3)                       ; bank data in buffer to be blown to bank no. in slot X
                    res  7,b
                    res  6,b                            ; remove slot mask of original destination bank number for bank file
                    ld   a,(oz_slot)
                    rrca
                    rrca                                ; slot number -> slot mask
                    or   b
                    ld   b,a                            ; bank number in romupdate.cfg converted to specified slot "OZ.x" number
                    ld   a,(flash_algorithm)            ; use programming algorithm to blow bank to slot X
                    call BlowBufferToBank               ; action! NB: error trapping makes no sense, because the OZ ROM has been wiped out!

                    inc  iy
                    inc  iy
                    inc  iy
                    inc  iy                             ; point at next bank data entry
                    pop  bc
                    djnz update_ozrom_loop              ; blow bank to slot 0...
                    ret


; *************************************************************************************
; Copy the bank file contents located in EPROM/FLASH File area to RomUpdate 16K buffer.
;
; IN:
;       IY points a three byte data block that points to file entry in file area
;
;       -----------------------------------------------------------------------------------
;       byte 0:               byte 1:                byte 2:
;       [low byte offset]     [high byte offset]     [bank no. in file area]
;
.CopyEprFile2Buffer
                    ld   l,(iy+0)
                    ld   h,(iy+1)
                    ld   b,(iy+2)                       ; BHL = pointer to File Area entry
                    call LoadEprFile                    ; to be copied into (buffer)
                    ret


; *************************************************************************************
; Copy the RAM bank file contents to RomUpdate 16K buffer.
;
; IY points to a two byte data block that contains pointers to start of the file:
; -----------------------------------------------------------------------------------
; byte 0:                        byte 1:
; [first 64 byte sector of file] [bank of first sector]
; -----------------------------------------------------------------------------------
;
.CopyRamFile2Buffer
                    ld   hl,buffer
                    ld   (bufferend),hl                 ; set the current pointer to copied buffer contents to start of buffer
                    ld   e,(iy+0)                       ; get first sector number
                    ld   d,(iy+1)                       ; get bank number of first sector
.copysector_loop
                    ld   b,d                            ; bank (of sector) to bind into segment...
if POPDOWN
                    ld   c,MS_S2                        ; Use segment 2 to bind in bank of sector (RomUpdate popdown is running in segment 3)
                                                        ; (16K buffer is in segment 0 & 1)
else
                    ld   c,MS_S3                        ; Use segment 3 to bind in bank of sector (RomUpdate BBC BASIC is running in segment 0 & 1)
                                                        ; (16K buffer is in segment 2)
endif
                    call MemDefBank                     ; current sector bound into segment...
                    call Sector2MemPtr                  ; BHL points to start of current sector
if POPDOWN
                    set  7,h                            ; Use segment 2 to bind in bank of sector (RomUpdate popdown is running in segment 3)
                    res  6,h                            ; (16K buffer is in segment 0 & 1)
else
                    set  7,h                            ; Use segment 3 to bind in bank of sector (RomUpdate BBC BASIC is running in segment 0 & 1)
                    set  6,h                            ; (16K buffer is in segment 2)
endif
                    ld   c,(hl)                         ; get next file sector number
                    inc  hl
                    ld   a,(hl)                         ; get bank of next file sector number
                    inc  hl                             ; point at start of current file sector contents
                    or   a
                    push bc
                    jr   z, copysector                  ; bank number = 0: then this is the last sector (c = length of sector)
                    ld   c,62                           ; if bank number <> 0, then (complete) sector contents is 62 bytes...
.copysector
                    call CopySector2Buffer              ; (BHL) -> (buffer)
                    pop  bc
                    ret  z                              ; 16K bank file successfully copied to buffer

                    ld   e,c                            ; next sector number
                    ld   d,a                            ; bank of next sector number
                    jr   copysector_loop
; *************************************************************************************


; *************************************************************************************
; Copy 62 bytes (or less) buffer contents from BHL to current RomUpdate 16K buffer pointer.
;
; IN:
;       C = no of bytes to copy
;       HL = pointer to start of current RAM file sector
;       (bufferend) = pointer to destination (current pointer in 16K bank buffer)
;
.CopySector2Buffer
                    push af
                    push bc
                    push de

                    ld   b,0                            ; only C number of bytes to copy
                    ld   de,(bufferend)                 ; start of destination
                    ldir                                ; (HL) -> (DE)
                    ld   (bufferend),de                 ; pointer ready for next sector copy...

                    pop  de
                    pop  bc
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; Convert [File Sector Number, Bank] to extended memory pointer.
; Bank number = 0 evaluation (the last sector in the file) is not handled.
;
; IN:
;    D = Bank number  (of sector)
;    E = Sector number (64 byte file sector)
;
; OUT:
;    BHL = pointer to start of 64 byte sector (HL = without segment specifier)
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
.Sector2MemPtr
                    ld   b, d                            ; bank
                    ld   h, e
                    ld   l, 0
                    srl  h
                    rr   l
                    rr   h                               ; 00eeeeee
                    rr   l                               ; ee000000
                    ret
; *************************************************************************************

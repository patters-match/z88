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
     lib MemDefBank                                     ; Bind bank, defined in B, into segment C. Return old bank binding in B

     xdef Update_OzRom
     xref suicide, FlashWriteSupport, ErrMsgOzRom
     xref BlowBufferToBank


; *************************************************************************************
; Update OZ ROM to slot 0
;
.Update_OzRom
                    ld   c,0                            ; make sure that we have an AMD/STM 512K flash chip in slot 0
                    call FlashWriteSupport
                    jr   nc, flash_found
                    xor  a
                    ld   (dorbank),a
                    jp   ErrMsgOzRom                    ; "OZ ROM cannot be updated. 512K Flash was not found in slot 0"

.flash_found
                    ld   hl, updoz_msg                  ; "Updating OZ ROM - please wait..." (flashing)
                    oz   GN_Sop                         ; "Z88 will automatically hard reset when updating has completed."
                    ; ----------------------------------------------------------------------------------------------------------------------
                    ; before erasing slot 0 (wiping out the current OZ ROM code) and programming the bank files to slot 0, patch the
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
IF BBCBASIC
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
                    ; ----------------------------------------------------------------------------------------------------------------------
ENDIF
                    ld   c,0
                    call FlashEprCardErase              ; bye, bye OZ!

                    ld   iy,ozbanks                     ; get ready for first oz bank entry of [total_ozbanks]
                    ld   b,(iy-1)                       ; total of banks to update to slot 0...
.update_ozrom_loop
                    push bc

                    call CopyRamFile2Buffer             ; copy RAM bank file contents (IY points to bank file entry) to 16K RomUpdate buffer...
                    ld   b,(iy+2)                       ; destination bank number to slot 0
                    ld   a,FE_29F                       ; use AMD/STM programming algorithm to blow bank to slot 0
                    call BlowBufferToBank               ; action! NB: error trapping makes no sense, because the OZ ROM has been wiped out!

                    inc  iy
                    inc  iy
                    inc  iy                             ; point at next bank data entry
                    pop  bc
                    djnz update_ozrom_loop              ; blow bank to slot 0...

                    ; ----------------------------------------------------------------------------------------------------------------------
                    ; OZ ROM banks have been programmed successfully to slot 0.
                    ; Finally, it's time to issue a hard reset to start up a clean machine with the updated OZ ROM.
                    ; ----------------------------------------------------------------------------------------------------------------------
                    ld   a, $21                         ; RAM bank $21 (:RAM.0 filing system)
                    out  (BL_SR2), a                    ; b21 into Segment 2 (which has no executing code by RomUpdate popdown nor BBC BASIC)
                    ld   hl,0
                    ld   ($8000),hl                     ; remove RAM filing system tag $A55A in start of bank $21 that forces OZ to HARD RESET
                    jp   (hl)                           ; execute the hard reset..
                    ; ----------------------------------------------------------------------------------------------------------------------
; *************************************************************************************


; *************************************************************************************
; Copy the RAM bank file contents to RomUpdate 16K buffer.
;
; IY points a three byte data block that contains pointers to start of the file:
; -----------------------------------------------------------------------------------
; byte 0:                        byte 1:                byte 2:
; [first 64 byte sector of file] [bank of first sector] [destination bank in slot]
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

.updoz_msg          defm 1, "FUpdating OZ ROM - please wait...", 1, "F", 13, 10
                    defm "Z88 will automatically HARD RESET when updating has been completed", 0

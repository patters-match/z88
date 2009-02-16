     XLIB FlashEprReduceFileArea

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

     LIB FlashEprCardId
     LIB FlashEprBlockErase
     LIB FlashEprStdFileHeader
     LIB FileEprFreeSpace, FileEprRequest
     LIB OZSlotPoll, SetBlinkScreen

     XREF SetBlinkScreenOn

     include "flashepr.def"
     include "error.def"

; ************************************************************************
;
; Flash Eprom File Area Shrinking.
;
; Reduce an existing "oz" File Area below application Rom Area, or on sole
; Flash Card by one or several 64K sectors.
;
; -------------------------------------------------------------------------
; This routine will signal failure ("file area not found") if an
; application wants to reduce a file area that is part of the OZ ROM in slot 0
; -------------------------------------------------------------------------

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
;
; IN:
;    B = total sectors to reduce file area
;    C = slot number (1, 2 or 3) of Flash Memory Card
;
; OUT:
;    Success:
;         Fc = 0,
;         BHL = absolute pointer to new "oz" header in card
;         C = Number of 16K banks of File Eprom Area
;
;         Current files in file area are intact.
;         New header blown (for reduced file area) and old header sector erased.
;
;    Failure:
;         Fc = 1
;             A = RC_ONF (File Eprom Card / Area not available; possibly no card in slot)
;             A = RC_ROOM (File area cannot be reduced - files are located inside reducing sector)
;             A = RC_NFE (not a recognized Flash Memory Chip)
;             A = RC_BER (error occurred when erasing block/sector)
;             A = RC_BWR (couldn't write header to Flash Memory)
;             A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Feb 2006, July-Aug 2006, Feb 2009
; ----------------------------------------------------------------------
;
.FlashEprReduceFileArea
                    PUSH DE
                    PUSH BC
                    PUSH HL

                    INC  C
                    DEC  C
                    JR   NZ, check_oz_slotX
                    SCF
                    LD   A,RC_ONF
                    JR   exit_ReduceFileArea      ; file area cannot be shrinked in slot 0...
.check_oz_slotX
                    CALL OZSlotPoll               ; is OZ running in slot C?
                    CALL NZ,SetBlinkScreen

                    LD   E,B                      ; (preserve sector number)
                    CALL FlashEprCardId           ; Flash Card available in slot C?
                    JR   C, reduce_fa_error       ; apparently not...
                    PUSH BC                       ; preserve total size of card (in B)

                    LD   H,0
                    LD   L,E                      ; total no. of sectors to reduce file area..
                    LD   B,E
                    PUSH BC
                    CALL FileEprFreeSpace         ; return free space of file area in DEBC (DE = most significant word..)
                    POP  BC                       ; restore slot no. in C (less significant word of free space is not used here)
                    JR   C, reduce_fa_error       ; unable to get file area info...
                    SBC  HL,DE                    ; the file area must have more than L * 64K (65536 bytes free), to be reduced
                    JR   C, reduce_fa             ; free space > 64K in file area, it's shrinkable..
                    JR   NZ, reduce_no_room       ; free space < 64K...
.reduce_fa
                    PUSH BC                       ; preserve B (no. of sectors to reduce file area)
                    LD   E,C
                    CALL FileEprRequest           ; get bank B(HL) of current "oz" file header in slot C
                    LD   C,E                      ; (slot no. in C restored)
                    PUSH BC                       ; (remember bank no of. file header)
                    LD   A,B
                    RRCA
                    RRCA                          ; bankNo/4
                    AND  @00001111
                    LD   B,A                      ; (bank no. -> sector no.)
                    CALL FlashEprBlockErase       ; erase sector B in slot C (containg the file area header)
                    POP  BC                       ; (restore bank no. of old header, and slot no. in C)
                    POP  HL                       ; total no. of sectors to shrink in H
                    JR   C, reduce_fa_error       ; Ouch, problems with erasing sector!

                    SLA  H
                    SLA  H                        ; total sectors to shrink -> banks
                    LD   A,B
                    SUB  H                        ; (old bank of file header) - (reduced file area in banks) = new bank of header
                    LD   B,A                      ; Absolute bank of new file area header
                    POP  AF
                    LD   C,A                      ; C = total size of flash card in 16K banks.
                    XOR  A                        ; poll for programming algorithm..
                    LD   HL,0                     ; signal to create a new file header...
                    CALL FlashEprStdFileHeader    ; Create "oz" File Eprom Header in absolute bank B
                    JR   C, exit_ReduceFileArea

                    CALL SetBlinkScreenOn         ; always turn on screen after format operation
                    LD   HL,$3FC0                 ; return BHL = absolute pointer to new "oz" header in slot C
                    CP   A                        ; Fc = 0, C = Number of 16K banks of File Area
                    POP  DE                       ; ignore old HL
                    POP  DE                       ; ignore old BC
                    POP  DE                       ; original DE restored
                    RET
.reduce_no_room
                    LD   A, RC_ROOM               ; Files are occupying the sector(s) that could have reduced the file area
.reduce_fa_error
                    SCF
                    POP  BC
.exit_ReduceFileArea
                    CALL SetBlinkScreenOn

                    POP  HL
                    POP  BC
                    POP  DE
                    RET

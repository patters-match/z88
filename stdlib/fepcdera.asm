     XLIB FlashEprCardErase

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

     LIB FlashEprCardId         ; Identify Flash Memory Chip in slot C
     LIB FlashEprBlockErase     ; Erase sector defined in B (00h-0Fh), on Flash Card inserted in slot C
     LIB OZSlotPoll             ; Poll for OZ ROM availabílity in slot C

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"


; ***************************************************************
;
; Erase Flash Memory Card inserted in slot C.
;
; The routine will internally ask the Flash Memory for identification
; and intelligently use the correct erasing algorithm.
;
; -------------------------------------------------------------------------
; This routine will signal failure ("flash card not found") if an
; application wants to erase a card that contains the OZ ROM.
; -------------------------------------------------------------------------
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3
; to successfully erase the memory chip. If the Flash Memory card is
; inserted in slot 1 or 2, this routine will automatically report a
; sector erase failure error.
;
; It is the responsibility of the application (before using this call)
; to evaluate the Flash Memory (using the FlashEprCardId routine) and
; warn the user that an INTEL Flash Memory Card requires the Z88
; slot 3 hardware, so this type of unnecessary error can be avoided.
;
; IN:
;         C = slot number (0, 1, 2 or 3) of Flash Memory
; OUT:
;         Success:
;              Fc = 0
;         Failure:
;              Fc = 1
;              A = RC_NFE (not a recognized Flash Memory Chip)
;              A = RC_BER (error occurred when erasing block/sector)
;              A = RC_VPL (Vpp Low Error)
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; ---------------------------------------------------------------
; Design & programming by:
;    Gunther Strube, Dec 1997-Apr 1998, Aug 2004, Aug 2006
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
.FlashEprCardErase
                    PUSH BC
                    PUSH HL

                    CALL OZSlotPoll                     ; is OZ running in slot C?
                    JR   Z, no_oz
                    LD   A, RC_NFE
                    SCF
                    JR   exit_FlashEprCardErase         ; Yes, don't erase chip running OZ ROM!
.no_oz
                    CALL FlashEprCardId                 ; poll for card information in slot C (returns B = total banks of card)
                    JR   C, exit_FlashEprCardErase

                    RRC  B                              ; Erase the individual sectors, one at a time
                    RRC  B                              ; total of 16K banks on card -> total of 64K sectors on card.
                    DEC  B                              ; sectors, from (total sectors-1) downwards and including 0
.erase_2xF_card_blocks
                    CALL FlashEprBlockErase             ; erase top sector of card, and downwards...
                    JR   C, exit_FlashEprCardErase
                    DEC  B
                    LD   A,B
                    CP   -1
                    JR   NZ, erase_2xF_card_blocks

.exit_FlashEprCardErase
                    POP  HL
                    POP  BC
                    RET

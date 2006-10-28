     MODULE FlashEprFileDelete

; **************************************************************************************************
; OZ Flash Memory Management.
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
; ***************************************************************************************************

     XDEF FlashEprFileDelete

     LIB ApplEprType
     LIB FileEprFileEntryInfo
     LIB PointerNextByte
     LIB OZSlotPoll, SetBlinkScreen

     XREF FlashEprCardId
     XREF FlashEprWriteByte
     XREF SetBlinkScreenOn

; **************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Mark File Entry as deleted on File Eprom Card, identified by
; BHL pointer, B=00h-FFh (bits 7,6 is the slot mask), HL=0000h-3FFFh is
; the bank offset.
;
; -------------------------------------------------------------------------
; The screen is turned off while byte is being written when we're in the
; same slot as the OZ ROM. During writing, no interference should happen
; from Blink, because the Blink reads the font bitmaps each 1/100 second:
;    When written byte is part of OZ ROM chip, the font bitmaps are suddenly
;    unavailable which creates violent screen flickering during chip command mode.
;    Further, and most importantly, avoid Blink doing read-cycles while
;    chip is in command mode.
; By switching off the screen, the Blink doesn't read the font bit maps in
; OZ ROM, and the Flash chip can be in command mode without being disturbed
; by the Blink.
; -------------------------------------------------------------------------
;
; Important:
; Third generation AMD Flash Memory chips may be programmed in all
; available slots (1-3). Only INTEL I28Fxxxx series Flash chips require
; the 12V VPP pin in slot 3 to successfully mark the File Entry as deleted
; on the memory chip. If the Flash Eprom card is inserted in slot 1 or 2,
; this routine will report a programming failure.
;
; It is the responsibility of the application (before using this call) to
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; IN:
;         BHL = pointer to File Entry (B=00h-FFh, HL=0000h-3FFFh bank offset)
;               (bits 7,6 of B is the slot mask)
; OUT:
;         Fc = 0,
;              Marked as deleted.
;
;         Fc = 1,
;              A = RC_Onf, File (Flash) Eprom or File Entry not found in slot
;              A = RC_VPL, RC_BWR, Flash Eprom Write Error
;
; Registers changed on return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
; --------------------------------------------------------------------------
; Design & Programming, Gunther Strube, Dec 1997-Apr 1998, Sept 2004
; --------------------------------------------------------------------------
;
.FlashEprFileDelete
                    PUSH HL
                    PUSH DE
                    PUSH BC                       ; preserve CDE
                    PUSH AF                       ; preserve AF, if possible

                    PUSH BC
                    PUSH HL                       ; preserve File Entry pointer...
                    CALL FileEprFileEntryInfo
                    POP  HL
                    POP  BC
                    JR   C, err_delfile           ; File Entry was not found...
                    CALL PointerNextByte          ; point at start of filename, "/"

                    LD   A,B
                    RLCA
                    RLCA
                    LD   C,A                      ; BHL pointer is in slot C
                    CALL OZSlotPoll               ; is OZ running in slot of BHL?
                    CALL NZ,SetBlinkScreen        ; yes, blowing byte in OZ ROM (slot 0 or 1) requires LCD turned off
.blow_zero_byte
                    XOR  A
                    EX   AF,AF'                   ; A' = 0, blow byte to either INTEL or AMD chip
                    XOR  A                        ; indicate file deleted (0)
                    CALL FlashEprWriteByte        ; mark file as deleted with 0 byte
                    JR   C, err_delfile

                    POP  AF
                    CP   A                        ; Fc = 0, Fz = 1
.exit_delfile
                    CALL SetBlinkScreenOn         ; always turn on screen after FlashEprWriteByte
                    POP  BC                       ; (turning screen on, with screen already on has no effect...)
                    POP  DE
                    POP  HL
                    RET
.err_delfile        POP  BC                       ; remove old AF, use new AF (error code and Fc = 1)
                    JR   exit_delfile

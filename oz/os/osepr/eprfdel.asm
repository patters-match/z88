; **************************************************************************************************
; File Area functionality.
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
; ***************************************************************************************************

        module FileEprDeleteFile

        xdef FileEprDeleteFile

        lib  SetBlinkScreen

        xref FlashEprCardId, FlashEprWriteByte
        xref FileEprFileStatus
        xref SetBlinkScreenOn
        xref GetSlotNo
        xref IncBHL
        xref GetUvProgMode, BlowByte

        include "director.def"
        include "error.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Mark File Entry as deleted in file area located on Flash or UV Eprom Card, identified by BHL pointer,
; B=00h-FFh (bits 7,6 is the slot mask), HL=0000h-3FFFh is the bank offset.
;
; --------------------------------------------------------------------------------------------------
; The screen is turned off while byte is being written when we're in the same slot as the OZ ROM.
; During writing, no interference should happen from Blink, because the Blink reads the font
; bitmaps each 1/100 second:
;    When written byte is part of OZ ROM chip, the font bitmaps are suddenly unavailable which
;    creates violent screen flickering during chip command mode. Further, and most importantly,
;    avoid Blink doing read-cycles while chip is in command mode.
; By switching off the screen, the Blink doesn't read the font bit maps in OZ ROM, and the Flash
; chip can be in command mode without being disturbed by the Blink.
; --------------------------------------------------------------------------------------------------
;
; Important:
; Third generation AMD Flash Memory chips may be programmed in all available slots (1-3). Only INTEL
; I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 to successfully mark the File Entry
; as deleted on the memory chip. If the Flash Eprom card is inserted in slot 1 or 2, this routine
; will report a programming failure.
;
; It is the responsibility of the application (before using this call) to evaluate the Flash Memory
; (using the FlashEprCardId routine) and warn the user that an INTEL Flash Memory Card requires the
; Z88 slot 3 hardware, so this type of unnecessary error can be avoided.
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
;              A = RC_VPL, RC_BWR, Flash/UV Eprom  Write Error
;
; Registers changed on return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
; ----------------------------------------------------------------------------------------------
; Design & Programming:
;   Gunther Strube, Dec 1997-Apr 1998, Sept 2004, Nov 2006, Mar 2007, Feb 2009
; ----------------------------------------------------------------------------------------------
;
.FileEprDeleteFile
        push    ix
        push    hl
        push    de
        push    bc                              ; preserve CDE
        push    af                              ; preserve AF, if possible

        call    FileEprFileStatus
        jr      c, err_delfile                  ; File Entry was not found...
        call    IncBHL                          ; point at start of filename, "/"

        call    GetSlotNo                       ; get slot C derived from BHL pointer
        push    bc
        push    hl                              ; preserve BHL entry pointer while polling for flash hardware...
        call    FlashEprCardId                  ; is file entry located on a flash card?
        pop     hl
        pop     bc
        jr      c, uveprom                      ; no Flash, but an UV Eprom...

        ld      e,a                             ; blow byte to specified chip type (argument for FlashEprWriteByte)
        ld      a,c
        oz      OS_Ploz                         ; is OZ running in slot C of BHL?
        call    NZ,SetBlinkScreen               ; yes, blowing byte in OZ ROM (slot 0 or 1) requires LCD turned off
.blow_zero_byte
        ld      c,0                             ; indicate file deleted (0)
        call    FlashEprWriteByte               ; mark file as deleted with 0 byte
        jr      c, err_delfile
.blown_successfully
        pop     af
        cp      a                               ; Fc = 0, Fz = 1
.exit_delfile
        call    SetBlinkScreenOn                ; always turn on screen after FlashEprWriteByte
        pop     bc                              ; (turning screen on, with screen already on has no effect...)
        pop     de
        pop     hl
        pop     ix
        ret
.err_delfile
        pop     bc                              ; remove old AF, use new AF (error code and Fc = 1)
        jr      exit_delfile
.uveprom                                        ; try to mark file as deleted on an UV Eprom, but only if
        ld      a,3
        cp      c                               ; file entry is in slot 3?
        jr      z, mark_uvepr_file
.blow_failed
        ld      a, RC_BWR                       ; No, file entry can only be marked as deleted in slot 3
        scf                                     ; hardware for UV Eproms
        jr      err_delfile
.mark_uvepr_file
        call    GetUvProgMode                   ; return IX handle to UV program settings for current EPROM in slot 3
        jr      c, err_delfile                  ; no "oz" header found
        xor     a
        call    BlowByte                        ; mark file as deleted in UV Eprom.
        jr      c, blow_failed
        jr      blown_successfully

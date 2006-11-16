        module FlashEprReduceFileArea

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

        xdef FlashEprReduceFileArea

        lib FileEprFreeSpace, FileEprRequest
        lib OZSlotPoll

        xref FlashEprCardId
        xref FlashEprSectorErase
        xref FlashEprStdFileHeader

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
; application wants to reduce a file area that is part of the OZ ROM
; -------------------------------------------------------------------------
;
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
; Design & programming by Gunther Strube, Feb 2006, July-Aug 2006
; ----------------------------------------------------------------------
;
.FlashEprReduceFileArea
        push    de
        push    bc
        push    hl

        call    OZSlotPoll                      ; is OZ running in slot C?
        jr      z, no_oz
        ld      a,RC_ONF
        jr      reduce_fa_error                 ; Yes, file area cannot be shrinked in OZ ROM...
.no_oz
        ld      e,b                             ; (preserve sector number)
        call    FlashEprCardId                  ; Flash Card available in slot C?
        jr      c, reduce_fa_error              ; apparently not...
        push    bc                              ; preserve total size of card (in B)

        ld      h,0
        ld      l,e                             ; total no. of sectors to reduce file area..
        ld      b,e
        push    bc
        call    FileEprFreeSpace                ; return free space of file area in DEBC (DE = most significant word..)
        pop     bc                              ; restore slot no. in C (less significant word of free space is not used here)
        jr      c, reduce_fa_error              ; unable to get file area info...
        sbc     hl,de                           ; the file area must have more than L * 64K (65536 bytes free), to be reduced
        jr      c, reduce_fa                    ; free space > 64K in file area, it's shrinkable..
        jr      nz, reduce_no_room              ; free space < 64K...
.reduce_fa
        push    bc                              ; preserve B (no. of sectors to reduce file area)
        ld      e,c
        call    FileEprRequest                  ; get bank B(HL) of current "oz" file header in slot C
        ld      c,e                             ; (slot no. in C restored)
        push    bc                              ; (remember bank no of. file header)
        ld      a,b
        rrca
        rrca                                    ; bankNo/4
        and     @00001111
        ld      b,a                             ; (bank no. -> sector no.)
        call    FlashEprSectorErase             ; erase sector B in slot C (containg the file area header)
        pop     bc                              ; (restore bank no. of old header, and slot no. in C)
        pop     hl                              ; total no. of sectors to shrink in H
        jr      c, reduce_fa_error              ; Ouch, problems with erasing sector!

        sla     h
        sla     h                               ; total sectors to shrink -> banks
        ld      a,b
        sub     h                               ; (old bank of file header) - (reduced file area in banks) = new bank of header
        ld      b,a                             ; Absolute bank of new file area header
        pop     af
        ld      c,a                             ; C = total size of flash card in 16K banks.
        xor     a                               ; poll for programming algorithm..
        ld      hl,0                            ; signal to create a new file header...
        call    FlashEprStdFileHeader           ; Create "oz" File Eprom Header in absolute bank B
        jr      c, exit_ReduceFileArea

        ld      hl,$3fc0                        ; return BHL = absolute pointer to new "oz" header in slot C
        cp      a                               ; Fc = 0, C = Number of 16K banks of File Area
        pop     de                              ; ignore old HL
        pop     de                              ; ignore old BC
        pop     de                              ; original DE restored
        ret
.reduce_no_room
        ld      a, RC_ROOM                      ; Files are occupying the sector(s) that could have reduced the file area
.reduce_fa_error
        scf
        pop     bc
.exit_ReduceFileArea
        pop     hl
        pop     bc
        pop     de
        ret

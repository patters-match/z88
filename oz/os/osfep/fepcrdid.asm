     MODULE FlashEprCardId

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

     xdef FlashEprCardId

     xref FlashEprCardData    ; get data about Flash type & size
     xref AM29Fx_InitCmdMode  ; prepare for AMD Chip command mode

     include "flashepr.def"
     include "error.def"
     include "memory.def"

     include "lowram.def"


; ***************************************************************************************
; Identify Flash Memory Chip in slot C.
;
; In:
;         C = slot number (0, 1, 2 or 3)
; Out:
;         Success:
;              Fc = 0, Fz = 1
;              A = FE_28F or FE_29F, defining the Flash Memory chip generation
;              HL = Flash Memory ID
;                   H = Manufacturer Code (FE_INTEL_MFCD, FE_AMD_MFCD)
;                   L = Device Code (refer to flashepr.def)
;              B = total of 16K banks on Flash Memory Chip.
;
;         Failure:
;              Fc = 1
;              A = RC_NFE (not a recognized Flash Memory Chip)
;
; Registers changed on return:
;    ...CDE../IXIY af...... same
;    AFB...HL/.... ..bcdehl different
;
; ---------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Dec '97-Apr '98, Jul-Sep '04, Sep '05, Aug-Oct-Nov 06, Feb 07, Oct 07
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------------------------------
;
.FlashEprCardId
        push    iy
        push    de
        push    bc
        di                                      ; no maskable interrupts allowed while doing flash hardware commands...

        ld      a,c
        and     @00000011                       ; only slots 0, 1, 2 or 3 possible
        ld      e,a                             ; preserve a copy of slot argument in E
        rrca
        rrca                                    ; Converted to Slot mask $40, $80 or $C0
        ld      b,a
        ld      c,MS_S1
        ld      hl,MM_S1 << 8                   ; use segment 1 (not this executing segment which is MS_S2)

        push    bc                              ; check for hybrid hardware; 512K RAM (bottom) and 512K Flash (top)
        ld      a,b                             
        or      $3f                             
        ld      b,a                             ; point at top of bank of slot

        call    CheckRam
        ld      a,b
        pop     bc
        jr      c, unknown_flashmem             ; abort, if RAM card was found in slot C...

        push    bc
        ld      b,a
        CALL    NC,FetchCardID                  ; if not RAM, get info of AMD Flash Memory chip in top of slot (if avail in slot C)...
        pop     bc
        jr      nc, get_crddata                 ; AMD flash found, get card ID data...

        ld      hl,MM_S1 << 8                   ; use segment 1 (not this executing segment which is MS_S2)
        call    CheckRam
        jr      c, unknown_flashmem             ; abort, if RAM card was found in bottom of slot C...
                            
        call    FetchCardID                     ; get info of intel Flash Memory at bottom of chip in HL (if avail in slot C)...
        jr      c, unknown_flashmem             ; no ID's were polled from a (potential FE card)
.get_crddata
        call    FlashEprCardData                ; verify Flash Memory ID with known Manufacturer & Device Codes
        jr      c, unknown_flashmem
                                                ; H = Manufacturer Code, L = Device Code
        pop     de                              ; B = banks on card, A = chip series (28F or 29F)
        ld      c,e                             ; original C restored
.end_FlashEprCardId
        ei                                      ; maskable interrupts allowed again
        pop     de                              ; original DE restored
        pop     iy
        ret                                     ; Fc = 0, Fz = 1
.unknown_flashmem
        ld      a, RC_NFE
        scf                                     ; signal error...
        pop     bc
        jr      end_FlashEprCardId


; ***************************************************************
;
; Get the Manufacturer and Device Code from a Flash Eprom Chip
; inserted in slot C (Bottom bank of slot C has already been
; bound into segment 1; address $0000 - $3FFF is bound at
; $4000 - $7FFF)
;
; This routine will poll for known Intel I28Fxxxx and AMD AM29Fxxx
; Flash Memory chips and return the appropriate ID, if a card
; is recognized.
;
; The core polling routines are available in OZ lowram.def.
;
; In:
;     B = lowest Bank (number) of slot where to poll for Card ID
;     C = MS_S1 (segment 1 specifier)
;    HL = points into bound bank of potential Flash Memory
;     E = API slot number
;
; Out:
;    Fc = 0 (FE was recognized in slot C)
;         H = manufacturer code (at $00 0000 on chip)
;         L = device code (at $00 0001 on chip)
;    Fc = 1 (FE was NOT recognized in slot C)
;
; Registers changed on return:
;    A...DE../IX.. af...... same
;    .FBC..HL/..IY ..bcdehl different
;
.FetchCardID
        push    af
        push    de
        push    ix

        ld      a,e                             ; slot number supplied to this library from outside caller...
        rst     OZ_MPB                          ; Get bottom Bank of slot C into segment 1
        push    bc                              ; old bank binding in BC...

        push    hl
        pop     iy                              ; preserve pointer to Flash Memory segment

        ld      d,(hl)
        inc     hl                              ; get a copy into DE of the slot contents at the location
        ld      e,(hl)                          ; where the ID is fetched (through the FE command interface)
        dec     hl                              ; back at $00 0000

        push    de
        call    I28Fx_PollChipId                ; run INTEL card ID routine in lowram.def
        pop     de
        push    hl
        cp      a                               ; Fc = 0
        sbc     hl,de                           ; Assume that no INTEL Flash Memory ID is stored at that location!
        pop     hl                              ; if the ID in HL is different from DE
        jr      nz, found_CrdID                 ; then an ID was fetched from an INTEL FlashFile Memory...

        push    iy
        pop     hl                              ; pointer to Flash Memory segment
        push    de
        call    AM29Fx_InitCmdMode
        call    AM29Fx_PollChipId               ; run AMD/STM card ID routine in lowram.def
        ex      de,hl                           ; H = Manufacturer Code, L = Device Code
        pop     de

        push    hl
        cp      a                               ; Fc = 0
        sbc     hl,de
        pop     hl
        jr      nz, found_CrdID                 ; if the ID in HL is equal to DE
        scf                                     ; then no AMD/STM Flash Memory responded to the ID request...
        jr      exit_FetchCardID
.found_CrdID
        cp      a
.exit_FetchCardID
        pop     bc
        rst     OZ_MPB                          ; restore original bank in segment 1 (defined in BC)

        pop     ix
        pop     de
        pop     bc                              ; get preserved AF
        ld      a,b                             ; restore original A
        ret


; ***************************************************************
;
; Investigate if a RAM card is inserted in slot C
; (by trying to write a byte to address $00 0000 and
; verify that it was properly written)
;
; IN:
;     B = lowest Bank (number) of slot where to poll for Card ID
;     C = MS_S1 (segment 1 specifier)
;    HL points into bank of potential Flash Memory or RAM
;
; OUT:
;    Fc = 0, empty slot or EPROM/FLASH Card in slot C
;    Fc = 1, RAM card found in slot C
;
; Registers changed on return:
;   A.BCDEHL/IXIY same
;   .F....../.... different
;
.CheckRam
        push    bc
        rst     OZ_MPB                          ; Get bottom Bank of slot C into segment 1
        push    bc                              ; old bank binding in BC...
        push    af

        ld      b,(hl)                          ; preserve the original byte (needs to be restored)
        ld      a,1                             ; initial test bit pattern (bit 0 set)
.test_ram_loop
        ld      (hl),a                          ; write bit pattern to card at bottom location
        cp      (hl)                            ; and check whether it was written
        jr      nz, not_written                 ; bit pattern wasn't written...
        rlca                                    ; check that all bits are written properly
        jr      nc, test_ram_loop
.exit_CheckRam                                  ; this is a RAM card!  (Fc = 1)
        ld      (hl),b                          ; restore original byte at RAM location
        pop     bc
        ld      a,b                             ; restore original A
        pop     bc
        rst     OZ_MPB                          ; restore original bank in segment 1 (defined in BC)

        pop     bc
        ret
.not_written
        cp      a                               ; Fc = 0, this is not a RAM card
        jr      exit_checkram

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

        module FlashEprCardData

        xdef    FlashEprCardData

        include "oz.def"
        include "flashepr.def"

; ***************************************************************************************************
; Get Flash Card Data.
;
; IN:
;    HL = Polled from Flash Memory Chip (see FlashEprCardId):
;         Manufacturer & Device Code
;
; OUT:
;    Fc = 0
;       ID was found (verified):
;       A = chip generation (FE_28F or FE_29F)
;       B = total of 16K banks on Flash Memory
;       CDE = extended pointer to null-terminated string description of chip
;    Fc = 1
;      ID was not found
;
; Registers changed on return:
;   ......HL/IXIY same
;   AFBCDE../.... different
;
; ---------------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Aug 2006, Nov 2006
; ---------------------------------------------------------------------------------------------
;
.FlashEprCardData
        push    hl

        ex      de,hl
        ld      hl, DeviceCodeTable
        ld      b,(hl)                          ; no. of Flash Memory ID's in table
        inc     hl
        ld      a,e
.find_loop
        cp      (hl)                            ; Device Code found?
        inc     hl                              ; points at Manufacturer Code
        jr      nz, get_next0

        ld      a,d
        cp      (hl)                            ; Manufacturer Code found?
        inc     hl                              ; points at no of banks of Flash Memory
        jr      nz, get_next1
        ld      b,(hl)                          ; B = total of 16K banks on Flash Eprom
        inc     hl
        ld      a,(hl)                          ; A = chip generation
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                          ; DE points at chip description string
        ld      c,OZBANK_KNL1                   ; C = bank that contains this string
        jr      verified_id                     ; Fc = 0, Flash Eprom data returned...
.get_next0
        inc     hl                              ; points at no of banks
.get_next1
        inc     hl                              ; points at chip generation
        inc     hl                              ; point mnemonic low byte
        inc     hl                              ; point mnemonic high byte
        inc     hl                              ; point at next entry
        djnz    find_loop                       ; and check for new Device Code

        scf                                     ; Manufacturer and Device Code wasn't verified, indicate error
.verified_id
        pop     hl                              ; return FE_28F or FE29F in A (if device was successfully verified)
        ret

.DeviceCodeTable
                defb 6

                defw FE_I28F004S5               ; Intel flash
                defb 32, FE_28F                 ; 8 x 64K sectors / 32 x 16K banks (512Kb)
                defw mnem_i004

                defw FE_I28F008SA               ; Intel flash
                defb 64, FE_28F                 ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                defw mnem_i8s5                  ; appears like I28F008S5

                defw FE_I28F008S5               ; Intel flash
                defb 64, FE_28F                 ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                defw mnem_i8s5

                defw FE_AM29F010B               ; Amd flash
                defb 8, FE_29F                  ; 8 x 16K sectors / 8 x 16K banks (128Kb)
                defw mnem_am010b

                defw FE_AM29F040B               ; Amd flash
                defb 32, FE_29F                 ; 8 x 64K sectors / 32 x 16K banks (512Kb)
                defw mnem_am040b

                defw FE_AM29F080B               ; Amd flash
                defb 64, FE_29F                 ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                defw mnem_am080b

.mnem_i004      defm "I28F004S5 (512K)", 0
.mnem_i8S5      defm "I28F008S5 (1Mb)", 0
.mnem_am010b    defm "AM29F010B (128K)", 0
.mnem_am040b    defm "AM29F040B (512K)", 0
.mnem_am080b    defm "AM29F080B (1Mb)", 0

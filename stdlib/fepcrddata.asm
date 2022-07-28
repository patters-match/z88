     XLIB FlashEprCardData

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
;
;***************************************************************************************************

     INCLUDE "flashepr.def"

;***************************************************************************************************
; Get Flash Card Data.
;
; IN:
;    HL = Polled from potential Flash Memory Chip (see FlashEprCardId):
;         Manufacturer & Device Code
;
; OUT:
;    Fc = 0
;       ID was found (verified):
;       A = chip generation (FE_28F or FE_29F)
;       B = total of 16K banks on Flash Memory
;       DE = pointer to null-terminated string description of chip
;    Fc = 1
;      ID was not found
;
; Registers changed on return:
;   ...C..HL/IXIY same
;   AFB.DE../.... different
;
; ---------------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Aug 2006, Nov 2006
; New flash chips added (Macronix, SST & STM)
;    Paul Roberts (paul.m.roberts@gmail.com), Jan 2018
;    Martin Roberts (mailmartinroberts@yahoo.co.uk), Jan 2018
;    patters backported improvements from OZ 5.0 to standard library, July 2022
; ---------------------------------------------------------------------------------------------

.FlashEprCardData   PUSH HL

                    EX   DE,HL
                    LD   HL, DeviceCodeTable
                    LD   B,(HL)                   ; no. of Flash Memory ID's in table
                    INC  HL
.find_loop                    
                    LD   A,E
                    CP   (HL)                     ; Device Code found?
                    INC  HL                       ; points at Manufacturer Code
                    JR   NZ, get_next0
                    LD   A,D
                    CP   (HL)                     ; Manufacturer Code found?
                    INC  HL                       ; points at no of banks of Flash Memory
                    JR   NZ, get_next1
                    LD   B,(HL)                   ; B = total of 16K banks on Flash Eprom
                    INC  HL
                    LD   A,(HL)                   ; A = chip generation
                    INC  HL
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                   ; DE points at chip description string
                    JR   verified_id              ; Fc = 0, Flash Eprom data returned...
.get_next0          INC  HL                       ; points at no of banks
.get_next1          INC  HL                       ; points at chip generation
                    INC  HL                       ; point mnemonic low byte
                    INC  HL                       ; point mnemonic high byte
                    INC  HL                       ; point at next entry
                    DJNZ find_loop                ; and check for new Device Code

                    SCF                           ; Manufacturer and Device Code wasn't verified, indicate error
.verified_id        POP  HL                       ; return FE_28F or FE29F in A (if device was successfully verified)
                    RET

.DeviceCodeTable
                    DEFB 12

                    DEFW FE_I28F004S5             ; Intel flash
                    DEFB 32, FE_28F               ; 8 x 64K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_i004

                    DEFW FE_I28F008SA             ; Intel flash
                    DEFB 64, FE_28F               ; 16 x 64K sectors / 64 x 16K banks (1024KB)
                    DEFW mnem_i8sa

                    DEFW FE_I28F008S5             ; Intel flash
                    DEFB 64, FE_28F               ; 16 x 64K sectors / 64 x 16K banks (1024KB)
                    DEFW mnem_i8s5

                    DEFW FE_AM29F040B             ; AMD flash
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_am040b

                    DEFW FE_AM29F080B             ; AMD flash
                    DEFB 64, FE_29F               ; 16 x 64K sectors / 64 x 16K banks (1024KB)
                    DEFW mnem_am080b

                    DEFW FE_AMIC29F040B           ; AMIC flash
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_amc040b

                    DEFW FE_AMIC29L040            ; AMIC flash
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_amc040l

                    DEFW FE_ST29F040B             ; STMicroelectronics flash (AMD compatible)
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_st040b

                    DEFW FE_ST29F080D             ; STMicroelectronics flash (AMD compatible)
                    DEFB 64, FE_29F               ; 16 x 64K sectors / 64 x 16K banks (1024KB)
                    DEFW mnem_st080d

                    DEFW FE_MX29F040C             ; Macronix flash
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_mx040c

                    DEFW FE_SST39SF040            ; SST flash
                    DEFB 32, FE_29F               ; 128 x 4K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_sst040b

                    DEFW FE_EN29LV040A            ; EON flash
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512KB)
                    DEFW mnem_en29l


.mnem_i004          DEFM "I28F004S5 (512K)", 0
.mnem_i8sa          DEFM "I28F008SA (1MB)", 0
.mnem_i8S5          DEFM "I28F008S5 (1MB)", 0
.mnem_am040b        DEFM "AM29F040B (512K)", 0
.mnem_am080b        DEFM "AM29F080B (1MB)", 0
.mnem_amc040b       DEFM "AMIC29F040B (512K)", 0
.mnem_amc040l       DEFM "AMIC29L040 (512K)", 0
.mnem_st040b        DEFM "ST29F040B (512K)", 0
.mnem_st080d        DEFM "ST29F080D (1MB)", 0
.mnem_mx040c        DEFM "MX29F040C (512K)", 0
.mnem_sst040b       DEFM "SST39SF040 (512K)", 0
.mnem_en29l         DEFM "EN29LV040A (512K)", 0

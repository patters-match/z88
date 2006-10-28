     MODULE FlashEprCardData

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

     XDEF FlashEprCardData

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
;    Gunther Strube, Aug 2006
; ---------------------------------------------------------------------------------------------
;
.FlashEprCardData   PUSH HL

                    EX   DE,HL
                    LD   HL, DeviceCodeTable
                    LD   B,(HL)                   ; no. of Flash Memory ID's in table
                    INC  HL
                    LD   A,E
.find_loop          CP   (HL)                     ; Device Code found?
                    INC  HL                       ; points at Manufacturer Code
                    JR   NZ, get_next0
                         LD   A,D
                         CP   (HL)                ; Manufacturer Code found?
                         INC  HL                  ; points at no of banks of Flash Memory
                         JR   NZ, get_next1
                         LD   B,(HL)              ; B = total of 16K banks on Flash Eprom
                         INC  HL
                         LD   A,(HL)              ; A = chip generation
                         INC  HL
                         LD   E,(HL)
                         INC  HL
                         LD   D,(HL)              ; DE points at chip description string
                         JR   verified_id         ; Fc = 0, Flash Eprom data returned...
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
                    DEFB 9

                    DEFW FE_I28F004S5             ; Intel flash
                    DEFB 32, FE_28F               ; 8 x 64K sectors / 32 x 16K banks (512Kb)
                    DEFW mnem_i004

                    DEFW FE_I28F008SA             ; Intel flash
                    DEFB 64, FE_28F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                    DEFW mnem_i8s5                ; appear like I28F008S5

                    DEFW FE_I28F008S5             ; Intel flash
                    DEFB 64, FE_28F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                    DEFW mnem_i8s5

                    DEFW FE_AM29F010B             ; Amd flash
                    DEFB 8, FE_29F                ; 8 x 16K sectors / 8 x 16K banks (128Kb)
                    DEFW mnem_am010b

                    DEFW FE_ST29F010B             ; STMicroelectronics flash (Amd compatible)
                    DEFB 8, FE_29F                ; 8 x 16K sectors / 8 x 16K banks (128Kb)
                    DEFW mnem_st010b

                    DEFW FE_AM29F040B             ; Amd flash
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512Kb)
                    DEFW mnem_am040b

                    DEFW FE_ST29F040B             ; STMicroelectronics flash (Amd compatible)
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512Kb)
                    DEFW mnem_st040b

                    DEFW FE_AM29F080B             ; Amd flash
                    DEFB 64, FE_29F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                    DEFW mnem_am080b

                    DEFW FE_ST29F080D             ; STMicroelectronics flash (Amd compatible)
                    DEFB 64, FE_29F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                    DEFW mnem_st080d

.mnem_i004          DEFM "I28F004S5 (512K)", 0
.mnem_i8S5          DEFM "I28F008S5 (1Mb)", 0
.mnem_am010b        DEFM "AM29F010B (128K)", 0
.mnem_am040b        DEFM "AM29F040B (512K)", 0
.mnem_am080b        DEFM "AM29F080B (1Mb)", 0
.mnem_st010b        DEFM "ST29F010B (128K)", 0
.mnem_st040b        DEFM "ST29F040B (512K)", 0
.mnem_st080d        DEFM "ST29F080D (1Mb)", 0

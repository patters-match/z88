        MODULE FlashCardData


        INCLUDE "flashepr.def"

        DEFC FE_AM29F032B = $0141                  ; Rakewell 2M/4M uses this chip as flash memory

        XDEF FlashCardData


;***************************************************************************************************
; Get Flash Card Data.
;
; IN:
;    HL = Polled from potential Flash Memory Chip (see FlashCardId):
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
.FlashCardData      PUSH HL

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
                    DEFB 7

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

                    DEFW FE_AM29F040B             ; Amd flash
                    DEFB 32, FE_29F               ; 8 x 64K sectors / 32 x 16K banks (512Kb)
                    DEFW mnem_am040b

                    DEFW FE_AM29F080B             ; Amd flash
                    DEFB 64, FE_29F               ; 16 x 64K sectors / 64 x 16K banks (1024Kb)
                    DEFW mnem_am080b

                    DEFW FE_AM29F032B             ; Amd flash
                    DEFB 32, FE_29F               ; 64 x 64K sectors / 256 x 16K banks (4096Kb)
                    DEFW mnem_am032b              ; (fake the size only to be 512K for exisiting algorithms)

.mnem_i004          DEFM "INTEL 28F004S5 (512Kb, 8 x 64Kb sectors)", 0
.mnem_i8S5          DEFM "INTEL 28F008S5 (1024Kb, 16 x 64Kb sectors)", 0
.mnem_am010b        DEFM "AMD AM29F010B (128Kb, 8 x 16K sectors)", 0
.mnem_am040b        DEFM "AMD AM29F040B (512Kb, 8 x 64K sectors)", 0
.mnem_am080b        DEFM "AMD AM29F080B (1024Kb, 16 x 64K sectors)", 0
.mnem_am032b        DEFM "AMD AM29F032B (4096Kb, 64 x 64K sectors)", 0

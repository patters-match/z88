     XLIB FlashEprType

     LIB SafeSegmentMask
     LIB MemReadByte
     LIB FlashEprCardId

     include "flashepr.def"
     include "error.def"
     include "memory.def"


; ************************************************************************
;
; Return (Flash) File Eprom Area status in slot x (1, 2 or 3), 
; with top of area at bank B (00h - 3Fh).
;
; ---------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997 - Aug 1998, July 2004
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
; In:
;         C = slot number (1, 2 or 3)
;         B = bank of "oz" header (slot relative, 00 - $3F)
;
; Out:
;    Success:
;         Fc = 0,
;         Fz = 1, Flash Eprom Card recognized
;              A = Intel Device Code
;                   fe_i016 ($AA), an INTEL 28F016S5 (2048K)
;                   fe_i008 ($A2), an INTEL 28F008SA (1024K)
;                   fe_i8s5 ($A6), an INTEL 28F008S5 (1024K)
;                   fe_i004 ($A7), an INTEL 28F004S5 (512K)
;                   fe_i020 ($BD), an INTEL 28F020 (256K)
;         Fz = 0, Standard 32K, 128K, 256K Eprom or 1MB Eprom
;              A = Sub type of Eprom
;         B = size of File Eprom Area in 16K banks
;
;    Failure:
;         Fc = 1, RC_ONF, "oz" File Eprom not found
;
; Registers changed after return:
;    ...CDEHL/IXIY same
;    AFB...../.... different
;
.FlashEprType
                    PUSH DE
                    PUSH HL
                    PUSH BC

                    LD   A,C
                    AND  @00000011           ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    OR   B                   
                    LD   B,A                 ; bank B of slot C...

                    CALL SafeSegmentMask     ; Get a safe segment address mask
                    OR   $3F                 ; address $3Fxx in bank B
                    LD   H,A
                    LD   L,0                 ; address $3F00 in bank B of slot C

                    LD   A,$FC
                    CALL MemReadByte
                    PUSH AF                  ; get size of File Eprom in Banks, $3FFC
                    LD   A,$FD
                    CALL MemReadByte
                    LD   C,A                 ; get sub type of File Eprom
                    LD   A,$FE
                    CALL MemReadByte
                    LD   D,A                 ; 'o'
                    LD   A,$FF
                    CALL MemReadByte
                    LD   E,A                 ; 'z'

                    CP   A
                    LD   HL,$6F7A
                    SBC  HL,DE               ; 'oz' ?
                    JR   NZ,no_fileeprom

                    LD   E,B
                    LD   A,C                 ; File Eprom found...
                    POP  BC                  ; B = size of Eprom Card in banks
                    LD   C,A                 ; C = sub type of File Eprom

                    LD   A,E
                    AND  @11000000           ; convert bottom bank
                    RLCA
                    RLCA                     ; into slot C
.eval_flashepr                
                    PUSH BC
                    LD   C,A
                    CALL FlashEprCardId      ; Flash Device in slot C?
                    POP  BC
                    CALL C, no_flash
                    CALL NC, yes_flash
.exit_FlashEprType
                    POP  HL                  ; B = size of Card in banks
                    LD   C,L                 ; original C restored
                    POP  HL                  ; original HL restored
                    POP  DE                  ; original DE restored
                    RET

.no_flash           LD   A,C                 ; A = sub type of std. Eprom
                    OR   A
                    RET
.yes_flash          CP   A                   ; Yes, Fz = 1, A = Device code
                    RET

.no_fileeprom       POP  AF
                    LD   A,RC_ONF
                    SCF
                    POP BC
                    POP HL
                    POP DE
                    RET

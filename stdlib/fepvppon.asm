
     XLIB FlashEprVppOn

     LIB SafeSegmentMask, MemWriteByte

     DEFC VppBit = 1

     include "interrpt.def"
     include "flashepr.def"

; ***************************************************************************
;
; Set Flash Eprom chip in programming mode
;
; 1) set Vpp (12V) on
; 2) clear the chip status register
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: FepVppOn.asm $
; 
; *****************  Version 2  *****************
; User: Gbs          Date: 24-01-98   Time: 20:41
; Updated in $/Z88/StdLib/FlashEprom
; INCLUDE directives optimized (if any)
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 20-01-98   Time: 8:58
; Created in $/Z88/StdLib/FlashEprom
; Added to SourceSafe
;
; --------------------------------------------------------------------------
;
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997
;    Thierry Peycru, Zlab, Dec 1997
;
; --------------------------------------------------------------------------
;
; IN:
;         -
; OUT:
;         -
;
; Registers changed on return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.FlashEprVppOn      PUSH AF
                    PUSH BC
                    PUSH HL

                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  VppBit,A            ; Vpp On
                    LD   (BC),A
                    OUT  (C),A               ; Enable Vpp in slot 3

                    CALL SafeSegmentMask     ; Get a safe segment address mask
                    LD   H, A
                    LD   L, 0                ; Pointer at beginning of segment
                    LD   B, $C0              ; A bank of slot 3...

                    LD   C, FE_CSR
                    XOR  A
                    CALL MemWriteByte        ; Clear Chip Status register

                    POP  HL
                    POP  BC
                    POP  AF
                    RET

     XLIB FlashEprVppOff

     LIB SafeSegmentMask, MemWriteByte

     DEFC VppBit = 1

     include "interrpt.def"
     include "flashepr.def"

; ***************************************************************************
;
; Disable VPP and reset Flash Eprom chip in read array mode (like a
; standard eprom chip)
;
; 1) Set Vpp (12V) off
; 2) Reset Flash Eprom Chip
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: FepVppOf.asm $
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
; In:
;         -
; Out:
;         -
;
; Registers changed on return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.FlashEprVppOff     PUSH AF
                    PUSH BC
                    PUSH HL

                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    RES  VppBit,A            ; Vpp Off
                    LD   (BC),A
                    OUT  (C),A               ; Disable Vpp in slot 3

                    CALL SafeSegmentMask     ; Get a safe segment address mask
                    LD   H, A
                    LD   L, 0                ; Pointer at beginning of segment
                    LD   B, $C0              ; A bank of slot 3...

                    LD   C, FE_RST
                    XOR  A                   ; Reset Flash Eprom Chip
                    CALL MemWriteByte        ; to read array mode

                    POP  HL
                    POP  BC
                    POP  AF
                    RET

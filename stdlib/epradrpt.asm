
     XLIB ConvAddrToPtr

; ***************************************************************************
;
; Convert 1MB 20bit address to relative pointer in BHL
; (B = 00h - 3Fh, HL = 0000h - 3FFFh).
;
; This routine is primarily used File Eprom management
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: EprAdrPt.asm $
; 
; *****************  Version 2  *****************
; User: Gbs          Date: 24-01-98   Time: 20:41
; Updated in $/Z88/StdLib/FileEprom
; INCLUDE directives optimized (if any)
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 20-01-98   Time: 8:54
; Created in $/Z88/StdLib/FileEprom
; Added to SourceSafe
;
; --------------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, Dec 1997
;
; --------------------------------------------------------------------------
;
; IN:
;    EBC = 24bit integer (actually 20bit 1MB address)
;
; OUT:
;    BHL = pointer
;
; Registers changed after return:
;    AF.CDE../IXIY same
;    ..B...HL/.... different
;
.ConvAddrToPtr
                    PUSH AF
                    LD   A,B
                    AND  @11000000
                    LD   H,B
                    RES  7,H
                    RES  6,H
                    LD   L,C                 ; OFFSET READY...

                    LD   B,E                 ; now divide top 6 address bit with 16K
                    SLA  A                   ; and place it into B (bank) register
                    RL   B
                    SLA  A
                    RL   B
                    POP  AF
                    RET                      ; BHL now (relative) ext. address

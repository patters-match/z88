
     XLIB ConvPtrToAddr

; ***************************************************************************
;
; Convert relative pointer BHL (B = 00h - 3Fh, HL = 0000h - 3FFFh)
; to absolute 20bit 1MB address.
;
; This routine primarily used for File Eprom Management.
;
; ------------------------------------------------------------------------
;
; $Header$
;
; $History: EprPtAdr.asm $
; 
; *****************  Version 2  *****************
; User: Gbs          Date: 24-01-98   Time: 20:41
; Updated in $/Z88/StdLib/FileEprom
; INCLUDE directives optimized (if any)
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 20-01-98   Time: 8:55
; Created in $/Z88/StdLib/FileEprom
; Added to SourceSafe
;
; ------------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, Dec 1997
;
; ------------------------------------------------------------------------
;
; IN:
;    BHL = pointer
;
; OUT:
;    DEBC = 32bit integer (actually 24bit)
;
; Registers changed after return:
;    AF....HL/IXIY same
;    ..BCDE../.... different
;
.ConvPtrToAddr      PUSH AF
                    PUSH HL
                    LD   D,0
                    LD   E,B
                    LD   BC,0
                    SRA  E
                    RR   B
                    SRA  E
                    RR   B
                    ADD  HL,BC               ; DEBC = <BankNumber> * 16K + offset
                    LD   B,H
                    LD   C,L                 ; DEBC = BHL changed to absolute address in Eprom
                    POP  HL
                    POP  AF
                    RET

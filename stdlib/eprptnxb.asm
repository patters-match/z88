     XLIB PointerNextByte


; ****************************************************************************
;
; Update extended address to point at next physical address on Eprom (or RAM)
; If the offset address crosses a bank boundary, the bank number is
; increased to use the next, adjacent bank, and the offset is positioned
; at the start of the bank.
;
; This routine is primarily used for File Eprom management.
;
; ------------------------------------------------------------------------
;
; $Header$
;
; $History: EprPtNxB.asm $
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
;    BHL = ext. address
;
; OUT:
;    BHL++
;
; Registers changed after return:
;    AF.CDE../IXIY same
;    ..B...HL/.... different
;
.PointerNextByte
                    PUSH AF
                    LD   A,H
                    AND  @11000000
                    PUSH AF                  ; preserve segment mask of offset

                    RES  7,H
                    RES  6,H
                    INC  HL                  ; ptr++
                    BIT  6,H                 ; crossed bank boundary?
                    JR   Z, not_crossed      ; no, offset still in current bank
                    INC  B
                    RES  6,H                 ; yes, HL = 0, B++
.not_crossed
                    POP  AF
                    OR   H
                    LD   H,A
                    POP  AF
                    RET

     XLIB AddPointerDistance

     LIB ConvPtrToAddr, ConvAddrToPtr


; **************************************************************************
;
; Add distance CDE (24bit integer) to current pointer address BHL
;
; A new pointer is returned in BHL, preserving original
; slot mask and segment mask.
;
; This routine is primarily used for File Eprom management.
;
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: EprPdist.asm $
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
; --------------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, Dec 1997
;
; --------------------------------------------------------------------------
;
; Registers changed after return:
;    AF.CDE../IXIY same
;    ..B...HL/.... different
;
.AddPointerDistance
                    PUSH AF
                    PUSH DE

                    LD   A,C
                    PUSH AF                  ; preserve C register

                    LD   A,H
                    AND  @11000000
                    PUSH AF                  ; preserve segment mask
                    RES  7,H
                    RES  6,H

                    LD   A,B
                    AND  @11000000
                    PUSH AF                  ; preserve slot mask
                    RES  7,B
                    RES  6,B

                    LD   A,C
                    PUSH DE                  ; preserve distance in ADE

                    CALL ConvPtrToAddr       ; BHL -> DEBC address

                    POP  HL
                    ADD  HL,BC
                    LD   B,H
                    LD   C,L
                    ADC  A,E                 ; distance added to DEBC,
                    LD   E,A                 ; result in DEBC, new abs. address

                    CALL ConvAddrToPtr       ; new abs. address to BHL logic...

                    POP  AF
                    OR   B
                    LD   B,A                 ; slot mask restored in bank number

                    POP  AF
                    OR   H
                    LD   H,A                 ; segment mask restored in offset

                    POP  AF
                    LD   C,A                 ; C register restored

                    POP  DE
                    POP  AF
                    RET

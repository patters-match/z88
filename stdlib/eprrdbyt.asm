     XLIB FileEprReadByte

     LIB MemReadByte
     LIB PointerNextByte


; ****************************************************************************
;
; Read byte at BHL Eprom address, returned in A.
; Increment pointer to next Eprom address
;
; This is used as internal support routine for high level library functions.
;
; ------------------------------------------------------------------------
;
; $Header$
;
; $History: EprRdByt.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 28-02-99   Time: 12:13
; Created in $/Z88/StdLib/FileEprom
;
; ------------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
;
; ------------------------------------------------------------------------
;
; IN:
;    BHL = pointer, B = absolute bank number
;
; OUT:
;         A = byte at old (BHL)
;         BHL points at next byte in Eprom
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.FileEprReadByte    XOR  A
                    CALL MemReadByte
                    CALL PointerNextByte
                    RET

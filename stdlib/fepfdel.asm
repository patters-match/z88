     XLIB FlashEprFileDelete

     LIB FlashEprCardId
     LIB FlashEprWriteByte
     LIB FileEprFileEntryInfo
     LIB PointerNextByte

     INCLUDE "flashepr.def"
     INCLUDE "error.def"


; **************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Mark File Entry as deleted on File Eprom (in slot 3), identified
; by BHL pointer (B=00h-3Fh, HL=0000h-3FFFh).
;
; This routine will temporarily set the Vpp pin while marking the
; file as deleted.
;
; --------------------------------------------------------------------------
;
; Design & Programming, Gunther Strube, InterLogic, Dec 1997 - Apr 1998
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: FepFdel.asm $
; 
; *****************  Version 4  *****************
; User: Gbs          Date: 8-08-98    Time: 16:56
; Updated in $/Z88/StdLib/FlashEprom
; Flash Eprom identification now through <FlashEprCardId> call.
; 
; *****************  Version 3  *****************
; User: Gbs          Date: 26-04-98   Time: 16:07
; Updated in $/Z88/StdLib/FlashEprom
; Vpp is now handled by FlashEprWriteByte routine which also
; automatically executes in RAM during Vpp/Write operations on the Flash
; Eprom.
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
; IN:
;         BHL = pointer to File Entry
;
; OUT:
;         Fc = 0,
;              Marked as deleted.
;
;         Fc = 1,
;              A = RC_Onf, File (Flash) Eprom or File Entry not found in slot 3
;              A = RC_VPL, RC_BWR, Flash Eprom Write Error
;
; Registers changed on return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.FlashEprFileDelete
                    PUSH HL
                    PUSH DE
                    PUSH BC                       ; preserve CDE
                    PUSH AF                       ; preserve AF, if possible

                    PUSH BC
                    LD   C,3                      
                    CALL FlashEprCardId           ; check FE in slot 3
                    POP  BC
                    JR   C, err_delfile           ; Flash Eprom not identified!

                    SET  7,B                      ; slot 3 mask
                    SET  6,B                      ; bank in slot 3
                    RES  7,H
                    SET  6,H                      ; (offset bound into segment 1 temporarily)

                    PUSH BC
                    PUSH HL
                    CALL FileEprFileEntryInfo
                    POP  HL
                    POP  BC
                    JR   C, err_delfile           ; File Entry was not found...
                    CALL PointerNextByte          ; point at start of filename, "/"

                    XOR  A
                    CALL FlashEprWriteByte        ; mark file as deleted with 0 byte
                    JR   C, err_delfile

                    POP  AF
                    CP   A                        ; Fc = 0, Fz = 1
.exit_delfile
                    POP  BC
                    POP  DE
                    POP  HL
                    RET
.err_delfile        POP  BC                       ; remove old AF, use new AF (error code and Fc = 1)
                    JR   exit_delfile

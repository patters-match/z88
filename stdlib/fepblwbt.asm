     XLIB FlashEprBlowByte

     INCLUDE "#flashepr.def"


; ***************************************************************************
;
; Write a byte to the Flash Eprom Card (in slot 3), at (local) address HL.
;
; This Routine is absolutely low level, and is called by high level routines.
; ( Currently <FlashEprWriteByte> and <FlashEprWriteBlock> )
;
; This routine also assumes that Vpp is enabled (CALL'ed FlashEprVppOn
; routine), and that the corresponding bank of the Flash Eprom is bound into
; the segment that HL points into.
;
; Warning:
; This routine cannot be executed on the Flash Eprom Card
; (in slot 3), since the Flash Eprom is not in Read Array Mode
; while the byte is being blown.
;
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: FepBlwBt.asm $
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
;    Gunther Strube, InterLogic, Dec 1997, Jan '98
;    Thierry Peycru, Zlab, Dec 1997, Jan '98
;
; --------------------------------------------------------------------------
;
; IN:
;    A = byte
;    HL = pointer to physical address in segment (of bound bank).
;
; OUT:
;    Fc = 0, byte blown successfully to the Flash Card
;    Fc = 1, A = RC_ error code, byte not blown
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.FlashEprBlowByte   CP   $FF                           ; if byte is $FF, then no need to
                    RET  Z                             ; blow - already $FF in Flash Eprom!

                    PUSH DE
                    LD   D,A                           ; preserve to blown in D...
                    LD   (HL),FE_WRI
                    LD   (HL),A                        ; blow the byte...

.write_busy_loop    LD   (HL),FE_RSR                   ; Flash Eprom (R)equest for (S)tatus (R)egister
                    LD   A,(HL)                        ; returned in A
                    BIT  7,A
                    JR   Z,write_busy_loop             ; still blowing...

                    BIT  4,A
                    JR   NZ,write_error                ; Error: byte wasn't blown properly
                    BIT  3,A
                    JR   NZ,vpp_error                  ; Error: Vpp was not enabled...

                    CALL CheckByte                     ; verify byte manually (and return error status)
                    POP  DE
                    RET

.write_error        CALL ClearStatReg
                    LD   A, RC_BWR
                    SCF
                    POP  DE
                    RET
.vpp_error          CALL ClearStatReg
                    LD   A, RC_VPL
                    SCF
                    POP  DE
                    RET


; ***************************************************************************
;
.CheckByte          CALL ClearStatReg
                    LD   A,(HL)         ; read byte at (HL) just blown
                    CP   D              ; equal to original byte?
                    RET  Z              ; byte blown successfully!
                    LD   A, RC_BWR
                    SCF
                    RET


; ***************************************************************************
;
.ClearStatReg
                    LD   (HL), FE_CSR   ; Clear Flash Eprom Status Register
                    LD   (HL), FE_RST   ; Reset Flash Eprom to Read Array Mode
                    RET

     XLIB FlashEprStdFileHeader

     LIB FlashEprCardId, FlashEprWriteBlock

     INCLUDE "saverst.def"
     INCLUDE "memory.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Blow File Eprom "oz" header on Flash Eprom, in specified bank.
; Traditional File Eprom's use the whole card with header in bank $3F.
;
; Pseudo File Eproms might be part of Application cards below the 
; reserved application area (as specified by the ROM Front DOR).
;
; This routine will temporarily set the Vpp pin while the "oz" header
; is being blown to the Flash Eprom.
;
; ------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997 - Aug 1998
;    Thierry Peycru, Zlab, Dec 1997
; ------------------------------------------------------------------------
;
;
; In:
;    B = Bank (slot relative) where to blow header (at offset $3FC0)
;
; Out:
;    Success:
;         Fc = 0, File Eprom Header successfully blown to Flash Eprom
;
;    Failure:
;         Fc = 1,
;              A = RC_BWR
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.FlashEprStdFileHeader

                    PUSH BC
                    PUSH AF
                    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-66
                    ADD  IX,SP                    ; IX points at start of buffer
                    LD   SP,IX                    ; 64 byte buffer created...
                    PUSH HL                       ; preserve original SP

                    PUSH BC                       ; preserve bank number for header

                    PUSH IX
                    POP  HL
                    LD   B,$37                    ; 55 bytes of $00 from $3FC0
                    XOR  A
.wri0_loop          LD   (HL),A
                    INC  HL
                    DJNZ wri0_loop

                    LD   (HL),1
                    INC  HL

                    PUSH HL
                    LD   A,sr_rnd
                    call_oz os_sr
                    POP  HL
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D                   ; low word random ID...
                    INC  HL

                    LD   BC,6
                    EX   DE,HL
                    LD   HL, stdromhdr
                    LDIR

                    LD   C,3                      ; check presence of FE in slot 3
                    CALL FlashEprCardId
                    POP  BC                       ; blow header at bank B (slot relative)
                    JR   C, exit_romheader        ; Ups - Flash Eprom not available

                    RES  7,B
                    RES  6,B                      ; ensure slot relative...
                    INC  B
                    LD   (IX + $3C),B             ; total of banks on File Eprom = Bank+1
                    DEC  B

                    PUSH IX
                    POP  DE                       ; start of File Eprom Header
                    LD   C, MS_S1                 ; use segment 1 to blow bytes
                    LD   HL, $3FC0                ; blown at address $3FC0 in bank B
                    LD   IX, 64                   ; of size

                    CALL FlashEprWriteBlock       ; blow header...

.exit_romheader     POP  HL
                    LD   SP,HL                    ; restore original Stack Pointer

                    POP  IX                       ; restore registers...
                    POP  HL
                    POP  DE
                    POP  BC
                    LD   A,B                      ; A restored
                    POP  BC
                    RET

.stdromhdr          DEFB $01, $80, $40, $7C, $6F, $7A

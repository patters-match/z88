     XLIB FlashEprWriteBlock

     LIB MemDefBank
     LIB DisableInt, EnableInt
     LIB PointerNextByte


     INCLUDE "flashepr.def"
     INCLUDE "memory.def"

     DEFC VppBit = 1

; ***************************************************************************
;
; Write a block of bytes to the Flash Eprom Card (in slot 3), from address
; DE to BHL of block size IX.
;
; This routine is primarily used for File Eprom management, but is well
; suited for other purposes.
;
; Use segment specifier C to blow the bytes (MS_S0 - MS_S3)
;
; BHL pointer is assumed relative, ie. B = 00h - 3Fh, HL = 0000h - 3FFFh.
;
; This routine enables Vpp temporarily while the block is being blown.
;
; Further, the local buffer must be available in local address space and not
; part of the segment used for blowing bytes.
;
; The routine writes across bank boundaries.
;
; On return, BHL points at the byte after the last written byte.
; (BHL returned relative to slot 3, B=00h-3Fh, HL=0000h-3FFFh)
;
; --------------------------------------------------------------------------
;
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997, Jan - Apr 1998
;    Thierry Peycru, Zlab, Dec 1997
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: FepWrBlk.asm $
; 
; *****************  Version 4  *****************
; User: Gbs          Date: 27-04-98   Time: 10:29
; Updated in $/Z88/StdLib/FlashEprom
; Bug fix in FEP_Writeblock: 
; Block size parameter was smashed by RAM copy routine.
; Small change in .WriteBlockLoop: 
; $FF byte now being blown by the Flash Eprom processor, since the byte
; is verifed anyway (manually) by this routine. This makes sure to report
; an error back to the caller, if $FF was tried to be blown on a byte
; already changed on the Eprom.
; 
; *****************  Version 3  *****************
; User: Gbs          Date: 26-04-98   Time: 16:10
; Updated in $/Z88/StdLib/FlashEprom
; Now clones it's core writing routine to the stack (in RAM) and executes
; there during Vpp/Write operations on the Flash Eprom.
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
; In :
;         DE = local pointer to start of block (located in available segment)
;         C = MS_Sx segment specifier
;         BHL = extended address to start of destination
;         IX = size of block to blow
; Out:
;         Success:
;              Fc = 0
;              BHL updated
;         Failure:
;              Fc = 1
;              A = RC_BWR
;
; Registers changed on return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
.FlashEprWriteBlock PUSH IX
                    PUSH DE                            ; preserve DE
                    PUSH BC                            ; preserve C
                    PUSH AF                            ; preserve A, if no errors occur...

                    LD   A,C
                    RRCA
                    RRCA                               ; MS_Sx -> MM_Sx
                    RES  7,H
                    RES  6,H
                    OR   H
                    LD   H,A                           ; Offset will be working in segment C

                    SET  7,B
                    SET  6,B                           ; bank located in slot 3

                    LD   A,B
                    CALL MemDefBank                    ; Bind slot 3 bank into segment C
                    PUSH BC                            ; preserve old bank segment 1 binding
                    LD   B,A                           ; but use current bank as reference...
                    
                    EXX
                    PUSH IX
                    POP  BC                            ; block size counter in BC'
                    EXX

                    CALL DisableInt                    ; disable maskable interrupts (status preserved in IX)
                    CALL FEP_WriteBlock
                    CALL EnableInt                     ; restore old interrupt status...

                    LD   D,B                           ; preserve current Bank number of pointer...
                    POP  BC
                    CALL MemDefBank                    ; restore old segment C bank binding
                    LD   B,D
                    JR   C, ret_errcode

                    POP  AF                            ; restore original A
                    CP   A                             ; signal success (Fc = 0)
.return
                    RES  7,B
                    RES  6,B                           ; return relative bank in slot
                    RES  7,H
                    RES  6,H                           ; return offset in range 0000h - 3fffh only

                    POP  DE
                    LD   C,E                           ; original C register restored...
                    POP  DE
                    POP  IX
                    RET
.ret_errcode        POP  DE                            ; ignore old AF...
                    JR   return                        ; (use current A = error code, Fc = 1)


; ***************************************************************
;
; Write Block from BHL, segment C, in slot 3, of BC' length.
; This routine will clone itself on the stack and execute there.
;
; In:
;    BHL = pointer to start memory location in Flash Eprom
;    C = segment C (MS_Sx)
; Out:
;    Fc = 0, block blown successfully to the Flash Card
;         BHL = points at next free byte on Flash Eprom
;         DE = points beyond last byte of buffer
;    Fc = 1, 
;         A = RC_ error code, block not blown properly
;         DE,BHL points at byte not blown properly
;
; Registers changed after return:
;    A..C..../IXIY same
;    .FB.DEHL/.... different
;
.FEP_WriteBlock     EXX
                    LD   HL,0
                    ADD  HL,SP
                    EX   DE,HL
                    LD   HL, -(RAM_code_end - RAM_code_start)
                    ADD  HL,SP
                    LD   SP,HL               ; buffer for routine ready...
                    PUSH DE                  ; preserve original SP
                    
                    PUSH HL
                    PUSH BC                  
                    EX   DE,HL               ; DE points at <RAM_code_start>
                    LD   HL, RAM_code_start
                    LD   BC, RAM_code_end - RAM_code_start
                    LDIR                     ; copy RAM routine...

                    POP  BC                  ; size of block to blow on Eprom...
                    LD   HL,exit_blowblock
                    EX   (SP),HL
                    PUSH HL
                    EXX
                    RET                      ; CALL RAM_code_start
.exit_blowblock
                    EXX
                    POP  HL                  ; original SP
                    LD   SP,HL
                    EXX
                    RET            
          
; 110 bytes on stack to be executed... 
.RAM_code_start     
                    PUSH AF
                    PUSH BC
                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  VppBit,A            ; Vpp On
                    LD   (BC),A
                    OUT  (C),A               ; Enable Vpp in slot 3
                    POP  BC
                    POP  AF

.WriteBlockLoop     EXX
                    LD   A,B
                    OR   C
                    DEC  BC
                    EXX
                    JR   Z, exit_write_block ; block written successfully (Fc = 0)

                    LD   A,(DE)
                    PUSH BC

                    LD   B,A                 ; preserve to blown in B...
                    LD   (HL),FE_WRI
                    LD   (HL),A              ; blow the byte...

.write_busy_loop    LD   (HL),FE_RSR         ; Flash Eprom (R)equest for (S)tatus (R)egister
                    LD   A,(HL)              ; returned in A
                    BIT  7,A
                    JR   Z,write_busy_loop   ; still blowing...

                    LD   (HL), FE_CSR        ; Clear Flash Eprom Status Register
                    LD   (HL), FE_RST        ; Reset Flash Eprom to Read Array Mode

                    BIT  4,A
                    JR   NZ,write_error      ; Error: byte wasn't blown properly

                    LD   A,(HL)              ; read byte at (HL) just blown
                    CP   B                   ; equal to original byte?
                    JR   Z, exit_write_byte  ; byte blown successfully!
.write_error        
                    LD   A, RC_BWR
                    SCF
.exit_write_byte
                    POP  BC
                    JR   C, exit_write_block

                    INC  DE                  ; buffer++
                    LD   A,B
                    PUSH AF

                    LD   A,H                 ; BHL++
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
                    CP   B                   ; was a new bank crossed?
                    JR   Z,WriteBlockLoop    ; no...

                    PUSH BC                  ; pointer crossed a new bank
                    PUSH HL
                    LD   A,C                 ; bind new bank into segment C...
                    OR   $D0
                    LD   H,$04
                    LD   L,A                 ; BC points at soft copy of cur. binding in segment C
                    LD   (HL),B              ; A contains "old" bank number
                    LD   C,L
                    OUT  (C),B               ; bind...
                    POP  HL
                    POP  BC
                    JR   WriteBlockLoop
.exit_write_block
                    PUSH AF
                    PUSH BC
                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    RES  VppBit,A            ; Vpp Off
                    LD   (BC),A
                    OUT  (C),A               ; Disable Vpp in slot 3
                    POP  BC
                    POP  AF
                    RET
.RAM_code_end

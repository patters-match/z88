     XLIB FlashEprWriteBlock

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB MemDefBank, FlashEprCardId, ExecRoutineOnStack

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"
     INCLUDE "interrpt.def"


; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_WRI = $40           ; byte write command
DEFC VppBit = 1
; ==========================================================================================


; ***************************************************************************
;
; Write a block of bytes to the Flash Eprom Card, from address
; DE to BHL of block size IX. If a block will cross a bank boundary, it is 
; automatically continued on the next adjacent bank of the card.
; On return, BHL points at the byte after the last written byte.
;
; The routine will internally ask the Flash Memory for identification and 
; intelligently use the correct programming algorithm for the appropriate
; chip.
;
; The routine is used by the File Eprom Management libraries, but is well
; suited for other application purposes.
;
; Use segment specifier C (where BHL memory will be bound into the Z80 
; address space) to blow the block of bytes (MS_S0 - MS_S3), which has to be 
; in a different segment than DE is referring.
;
; BHL points to an absolute bank (which is part of the slot that the Flash 
; Memory Card have been inserted into).
;
; Further, the local buffer must be available in local address space and not
; part of the segment used for blowing bytes.
;
; Important: 
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 
; to successfully blow data to the memory chip. If the Flash Eprom card 
; is inserted in slot 1 or 2, this routine will report a programming failure. 
;
; It is the responsibility of the application (before using this call) to 
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the 
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; In :
;         DE = local pointer to start of block (located in available segment)
;         C = MS_Sx segment specifier for BHL
;         BHL = extended address to start of destination (pointer into card)
;              (bits 7,6 of B is the slot mask)
;         IY = size of block (at DE) to blow
; Out:
;         Success:
;              Fc = 0
;              BHL updated
;         Failure:
;              Fc = 1
;              A = RC_BWR (block not blown properly)
;              A = RC_NFE (not a recognized Flash Memory Chip)
;
; Registers changed on return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; --------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997, Jan-Apr 1998, Aug 2004
;    Thierry Peycru, Zlab, Dec 1997
; --------------------------------------------------------------------------
;
.FlashEprWriteBlock PUSH IX
                    PUSH DE                            ; preserve DE
                    PUSH BC                            ; preserve C
                    PUSH AF                            ; preserve A, if no errors occur...

                    PUSH BC
                    PUSH HL
                    LD   A,B                 
                    AND  @11000000
                    RLCA
                    RLCA                     
                    LD   C,A                           ; poll slot C for Flash Memory                                         
                    CALL FlashEprCardId                ; poll for card information in slot C
                    POP  HL
                    POP  BC                            ; we only need FE Programming type 28F or 29F...
                    JR   C, ret_errcode
                    EX   AF,AF'                        ; preserve FE Programming type in A'

                    LD   A,C
                    RRCA
                    RRCA                               ; MS_Sx -> MM_Sx
                    RES  7,H
                    RES  6,H
                    OR   H
                    LD   H,A                           ; HL Bank Offset will be working in segment C

                    LD   A,B
                    CALL MemDefBank                    ; Bind slot x bank into segment C
                    PUSH BC                            ; preserve old bank segment C binding
                    LD   B,A                           ; but use current bank as reference...
                    
                    CALL OZ_DI                         ; disable IM 1 interrupts
                    EX   AF,AF'                        ; FE Programming type in A, old interrupt status in AF'
                    CALL FEP_WriteBlock
                    EX   AF,AF'                        ; get old interrupt status in AF
                    CALL OZ_EI                         ; enable IM 1 interrupts...
                    EX   AF,AF'                        ; return AF error status of sector erasing...

                    LD   D,B                           ; preserve current Bank number of pointer...
                    POP  BC
                    CALL MemDefBank                    ; restore old segment C bank binding
                    LD   B,D
                    JR   C, ret_errcode

                    POP  AF                            ; restore original A
                    CP   A                             ; signal success (Fc = 0)
.return
                    RES  7,H
                    RES  6,H                           ; return pure bank offset (0000h - 3fffh) only

                    POP  DE
                    LD   C,E                           ; original C register restored...
                    POP  DE
                    POP  IX
                    RET
.ret_errcode        POP  DE                            ; ignore old AF...
                    JR   return                        ; (use current A = error code, Fc = 1)


; ***************************************************************
;
; Write Block to BHL (bound into segment C), in slot x, of BC' length.
; This routine will clone itself on the stack and execute there.
;
; In:
;         A = FE_28F or FE_29F (depending on Flash Memory type in slot)
;         DE = local pointer to start of block (located in available segment)
;         C = MS_Sx segment specifier
;         BHL = extended address to start of destination (pointer into card)
;         IY = size of block to blow
; Out:
;    Fc = 0, block blown successfully to the Flash Card
;         BHL = points at next free byte on Flash Eprom
;         DE = points beyond last byte of buffer
;    Fc = 1, 
;         A = RC_BWR  (block not blown properly)
;         DE,BHL points at byte not blown properly
;
; Registers changed after return:
;    A..C..../IXIY same
;    .FB.DEHL/.... different
;
.FEP_WriteBlock     
                    CP   FE_28F
                    JR   Z, write_28F_block
                    CP   FE_29F
                    JR   Z, write_29F_block
                    RET
.write_28F_block
                    LD   A,B                 
                    AND  @11000000
                    RLCA
                    RLCA                     
                    CP   3                   ; when chip is FE_28F series, we need to be in slot 3
                    JR   Z,_write_28F_block  ; to write bytes successfully to card
                    LD   A, RC_BWR           ; Ups, not in slot 3, signal error!
                    SCF
                    RET                      
._write_28F_block
                    PUSH IX
                    LD   IX, FEP_ExecWriteBlock_28F
                    EXX
                    LD   BC, end_FEP_ExecWriteBlock_28F - FEP_ExecWriteBlock_28F
                    EXX                    
                    CALL ExecRoutineOnStack
                    POP  IX
                    RET            
.write_29F_block
                    PUSH IX
                    LD   IX, FEP_ExecWriteBlock_29F
                    EXX
                    LD   BC, end_FEP_ExecWriteBlock_29F - FEP_ExecWriteBlock_29F
                    EXX
                    CALL ExecRoutineOnStack
                    POP  IX
                    RET            

          
; ***************************************************************
; Program block of data on an INTEL I28Fxxxx Flash Memory.
; (this routine is copied on the stack and executed there)
;
.FEP_ExecWriteBlock_28F
                    EXX
                    PUSH IY
                    POP  BC                  ; install block size.
                    EXX
                    
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
.end_FEP_ExecWriteBlock_28F


; ***************************************************************
; Program block of data on an AMD AM29Fxxxx Flash Memory
; (this routine is copied on the stack and executed there)
;
.FEP_ExecWriteBlock_29F
                    EXX
                    PUSH IY
                    POP  BC                  ; install block size.
                    EXX
                    PUSH AF
                    PUSH BC
                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  VppBit,A            ; Vpp On
                    LD   (BC),A
                    OUT  (C),A               ; Enable Vpp in slot 3
                    POP  BC
                    POP  AF

.WriteBlockLoop_29F EXX
                    LD   A,B
                    OR   C
                    DEC  BC
                    EXX
                    JR   Z, exit_write_block_29F ; block written successfully (Fc = 0)

                    LD   A,(DE)
                    PUSH BC                  ; preserve bank and MS_Sx while programming byte to card

                    LD   B,A                 ; preserve a copy of byte for later verification
                    LD   A,H
                    AND  @11000000
                    EXX                      ; 
                    LD   H,A                 ; 
                    LD   D,A
                    OR   $05
                    LD   H,A
                    LD   L,$55               ; HL = $x555
                    LD   A,D
                    OR   $02
                    LD   D,A
                    LD   E,$AA               ; DE = $x2AA
                    LD   (HL),$AA            ; AA -> (XX555), First Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$55            ; 55 -> (XX2AA), Second Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$A0            ; A0 -> (XX555), Byte Program Mode
                    EXX
                    LD   (HL),B              ; program byte to Flash Memory Address
.toggle_wait_loop
                    LD   A,(HL)              ; get first DQ6 programming status
                    LD   C,A                 ; get a copy programming status (that is not XOR'ed)...
                    XOR  (HL)                ; get second DQ6 programming status
                    BIT  6,A                 ; toggling? 
                    JR   Z,toggling_done     ; no, programming completed successfully!
                    BIT  5,C                 ; 
                    JR   Z, toggle_wait_loop ; we're toggling with no error signal and waiting to complete...
                    
                    LD   A,(HL)              ; DQ5 went high, we need to get two successive status
                    XOR  (HL)                ; toggling reads to determine if we're still toggling 
                    BIT  6,A                 ; which then indicates a programming error...
                    JR   NZ,program_err_29f  ; damn, byte NOT programmed successfully!
.toggling_done                    
                    LD   A,(HL)              ; we're back in Read Array Mode
                    CP   B                   ; verify programmed byte (just in case!)
                    JR   Z,exit_write_byte_29F ; byte was successfully programmed!
.program_err_29f
                    LD   (HL),$F0            ; F0 -> (XXXXX), force Flash Memory to Read Array Mode
                    LD   A, RC_BWR
                    SCF
.exit_write_byte_29F
                    POP  BC
                    JR   C, exit_write_block_29F

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
                    JR   Z, not_crossed_29F  ; no, offset still in current bank
                    INC  B
                    RES  6,H                 ; yes, HL = 0, B++
.not_crossed_29F
                    POP  AF
                    OR   H
                    LD   H,A

                    POP  AF
                    CP   B                   ; was a new bank crossed?
                    JR   Z,WriteBlockLoop_29F ; no...

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
                    JR   WriteBlockLoop_29F
.exit_write_block_29F
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
.end_FEP_ExecWriteBlock_29F

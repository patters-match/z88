     XLIB FlashEprWriteByte

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

     LIB MemDefBank
     LIB EnableInt, DisableInt
     LIB FlashEprCardId, ExecRoutineOnStack

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"


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
; -----------------------------------------------------------------------
; Write a byte (in A) to the Flash Memory Card in slot x, at address BHL.
; -----------------------------------------------------------------------
;
; BHL points to a bank, offset (which is part of the slot that the Flash 
; Memory Card have been inserted into).
;
; The routine can OPTIONALLY be told which programming algorithm to use 
; (by specifying the FE_28F or FE_29F mnemonic in A'); these parameters
; can be fetched when investigated which Flash Memory chip is available 
; in the slot, using the FlashEprCardId routine that reports these constants 
; back to the caller.
;
; However, if neither of the constants are provided in A', the routine will 
; internally ask the Flash Memory for identification and intelligently use 
; the correct programming algorithm. The identified FE_28F or FE_29F constant
; is returned to the caller in A' for future reference (when the byte was
; successfully programmed to the card).
;
; Important: 
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 
; to successfully blow the byte on the memory chip. If the Flash Eprom card 
; is inserted in slot 1 or 2, this routine will report a programming failure. 
;
; It is the responsibility of the application (before using this call) to 
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the 
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; In:
;         A = byte
;         A' = FE_28F or FE_29F (optional)
;         BHL = pointer to Flash Memory address (B=00h-FFh, HL=0000h-3FFFh)
; Out:
;         Success:
;              Fc = 0
;              A' = FE_28F or FE_29F (depending on Flash Memory type in slot)
;         Failure:
;              Fc = 1
;              A = RC_BWR (programming of byte failed)
;              A = RC_NFE (not a recognized Flash Memory Chip)
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; --------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997, Jan '98-Apr '98, Aug 2004
;    Thierry Peycru, Zlab, Dec 1997
; --------------------------------------------------------------------------
;
.FlashEprWriteByte
                    PUSH BC
                    PUSH DE
                    PUSH HL                  ; preserve original pointer
                    PUSH IX

                    RES  7,H
                    SET  6,H                 ; HL will be working in segment 1...
                    LD   D,B                 ; copy of bank number
                    
                    LD   C,MS_S1
                    CALL MemDefBank          ; bind bank B into segment...
                    PUSH BC
                    CALL FEP_BlowByte        ; blow byte in A to (BHL) address
                    POP  BC
                    CALL MemDefBank          ; restore original bank binding

                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; ***************************************************************
;
; Blow byte in Flash Eprom at (HL), segment 1, slot x
; This routine will clone itself on the stack and execute there.
;
; In:
;    A = byte to blow
;    D = bank of pointer
;    HL = pointer to memory location in Flash Memory
; Out:
;    Fc = 0, 
;        byte blown successfully to the Flash Memory
;    Fc = 1, 
;        A = RC_ error code, byte not blown
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.FEP_Blowbyte       
                    EX   AF,AF'              ; check for pre-defined Flash Memory programming...
                    CP   FE_28F
                    JR   Z, use_28F_programming
                    CP   FE_29F
                    JR   Z, use_29F_programming
                                             
                    LD   A,D                 ; no predefined programming was specified, let's find out...
                    AND  @11000000
                    RLCA
                    RLCA                     
                    LD   C,A                 ; poll slot C for Flash Memory                     
                    EX   DE,HL               ; preserve HL (pointer to write byte)
                    CALL FlashEprCardId
                    EX   DE,HL               
                    RET  C                   ; Fc = 1, A = RC error code (Flash Memory not found)
                    
                    CP   FE_28F              ; now, we've got the chip series
                    JR   NZ, use_29F_programming ; and this one may be programmed in any slot...
                    LD   A,3
                    CP   C                   ; when chip is FE_28F series, we need to be in slot 3
                    LD   A,FE_28F            ; restore fetched constant that is returned to the caller..
                    JR   Z,use_28F_programming ; to make a successful "write" of the byte...
                    SCF
                    LD   A, RC_BWR           ; Ups, not in slot 3, signal error!
                    RET                      
                                        
.use_28F_programming
                    CALL DisableInt          ; disable maskable IM 1 interrupts (status preserved in IX)
                    PUSH IX
                    EX   AF,AF'              ; byte to be blown...
                    LD   IX, FEP_ExecBlowbyte_28F
                    EXX
                    LD   BC, end_FEP_ExecBlowbyte_28F - FEP_ExecBlowbyte_28F
                    EXX
                    CALL ExecRoutineOnStack
                    POP  IX
                    CALL EnableInt           ; enable maskable interrupts
                    RET
.use_29F_programming
                    CALL DisableInt          ; disable maskable IM 1 interrupts (status preserved in IX)
                    PUSH IX
                    EX   AF,AF'              ; byte to be blown...
                    LD   IX, FEP_ExecBlowbyte_29F
                    EXX
                    LD   BC, end_FEP_ExecBlowbyte_29F - FEP_ExecBlowbyte_29F
                    EXX
                    CALL ExecRoutineOnStack
                    POP  IX
                    CALL EnableInt           ; enable maskable interrupts
                    RET
                                        
          
; ***************************************************************
; Program byte in A at (HL) on an INTEL I28Fxxxx Flash Memory
;
; In:
;    A = byte to blow
;    HL = pointer to memory location in Flash Memory
; Out:
;    Fc = 0 & Fz = 0, 
;        byte successfully blown to Flash Memory
;    Fc = 1, 
;        A = RC_BWR, byte not blown
;
.FEP_ExecBlowbyte_28F
                    PUSH AF
                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  VppBit,A            ; Vpp On
                    LD   (BC),A
                    OUT  (C),A               ; Enable Vpp in slot 3
                    POP  AF

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
                    JR   Z, exit_write       ; byte blown successfully!
.write_error        
                    LD   A, RC_BWR
                    SCF
.exit_write
                    PUSH AF
                    LD   BC,$04B0            ; Address of soft copy of COM register
                    LD   A,(BC)
                    RES  VppBit,A            ; Vpp Off
                    LD   (BC),A
                    OUT  (C),A               ; Disable Vpp in slot 3
                    POP  AF
                    RET
.end_FEP_ExecBlowbyte_28F


; ***************************************************************
; Program byte in A at (HL) on an AMD AM29Fxxxx Flash Memory
;
; In:
;    A = byte to blow
;    HL = pointer to memory location in Flash Memory
; Out:
;    Fc = 0 & Fz = 0, 
;        byte successfully blown to Flash Memory
;    Fc = 1, 
;        A = RC_BWR, byte not blown
;
.FEP_ExecBlowbyte_29F
                    PUSH HL                  ; preserve byte program address
                    LD   HL, $4555
                    LD   DE, $42AA

                    LD   (HL),$AA            ; AA -> (XX555), First Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$55            ; 55 -> (XX2AA), Second Unlock Cycle
                    EX   DE,HL
                    LD   (HL),$A0            ; A0 -> (XX555), Byte Program Mode
                    POP  HL
                    LD   (HL),A              ; program byte to Flash Memory Address
                    LD   B,A                 ; preserve a copy of byte for later verification
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
                    RET  Z                   ; byte was successfully programmed!
.program_err_29f
                    LD   (HL),$F0            ; F0 -> (XXXXX), force Flash Memory to Read Array Mode
                    SCF
                    LD   A, RC_BWR           ; signal byte write error to application
                    RET
.end_FEP_ExecBlowbyte_29F

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
; BHL points to an absolute bank (which is part of the slot that the Flash 
; Memory Card have been inserted into).
;
; The routine can OPTIONALLY be told which programming algorithm to use 
; (by specifying the FE_28F or FE_29F mnemonic in A'); these parameters
; can be fetched when investigated which Flash Memory chip is available 
; in the slot, using the FlashEprCardId routine that reports these constant 
; back to the caller.
;
; However, if neither of the constants are provided in A', the routine will 
; internally ask the Flash Memory for identification and intelligently use 
; the correct programming algorithm.
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
;              A = A(in)
;              Fc = 0
;         Failure:
;              Fc = 1
;              A = RC_BWR
;
; Registers changed on return:
;    A.BCDEHL/IXIY ........ same
;    .F....../.... afbcdehl different
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

                    LD   C,MS_S1
                    CALL MemDefBank          ; bind bank B into segment...

                    CALL DisableInt          ; disable maskable IM 1 interrupts (status preserved in IX)
                    CALL FEP_BlowByte        ; blow byte in A to (BHL) address
                    CALL EnableInt           ; enable maskable interrupts

                    CALL MemDefBank          ; restore original bank binding

                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; ***************************************************************
;
; Blow byte in Flash Eprom at (HL), segment 1, slot 3.
; This routine will clone itself on the stack and execute there.
;
; In:
;    A = byte to blow
;    HL = pointer to memory location in Flash Eprom
; Out:
;    Fc = 0, byte blown successfully to the Flash Card
;    Fc = 1, A = RC_ error code, byte not blown
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.FEP_Blowbyte       
                    LD   IX, FEP_ExecBlowbyte
                    LD   BC, end_FEP_ExecBlowbyte - FEP_ExecBlowbyte
                    CALL ExecRoutineOnStack
                    RET
                                        
          
; ***************************************************************
;
.FEP_ExecBlowbyte
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
.end_FEP_ExecBlowbyte

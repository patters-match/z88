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

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"

     DEFC VppBit = 1

; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_WRI = $40           ; byte write command
; ==========================================================================================


; ***************************************************************************
;
; Write a byte to the Flash Eprom Card (in slot 3), at address BHL
;
; BHL pointer is assumed relative, ie. B = 00h - 3Fh, HL = 0000h - 3FFFh.
;
; This routine will temporarily set Vpp while blowing the byte.
;
; In:
;         A = byte
;         BHL = pointer to Flash Eprom address (B=00h-3Fh, HL=0000h-3FFFh)
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
;    Gunther Strube, InterLogic, Dec 1997, Jan '98 - Apr '98
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
                    SET  7,B
                    SET  6,B                 ; bank located in slot 3...

                    LD   C,MS_S1
                    CALL MemDefBank          ; bind bank B into segment...
                    CALL DisableInt          ; disable maskable interrupts (status preserved in IX)

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
.FEP_Blowbyte       PUSH BC
                    EXX
                    LD   HL,0
                    ADD  HL,SP
                    EX   DE,HL
                    LD   HL, -(RAM_code_end - RAM_code_start)
                    ADD  HL,SP
                    LD   SP,HL               ; buffer for routine ready...
                    PUSH DE                  ; preserve original SP
                    
                    PUSH HL
                    EX   DE,HL               ; DE points at <RAM_code_start>
                    LD   HL, RAM_code_start
                    LD   BC, RAM_code_end - RAM_code_start
                    LDIR                     ; copy RAM routine...
                    LD   HL,exit_blowbyte
                    EX   (SP),HL
                    PUSH HL
                    EXX
                    RET                      ; CALL RAM_code_start
.exit_blowbyte
                    EXX
                    POP  HL                  ; original SP
                    LD   SP,HL
                    EXX
                    POP  BC
                    RET            
          
; 63 bytes on stack to be executed... 
.RAM_code_start     
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
.RAM_code_end

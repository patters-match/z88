     XLIB FlashEprCardId

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"


; ***************************************************************
;
; Identify Flash Memory Chip in slot C.
;
; In:
;         C = slot number (1, 2 or 3)
;
; Out:
;         Success:
;              Fc = 0
;              Fz = 1
;              A = Flash Memory Device Code
;                   fe_i016 ($AA), an INTEL 28F016S5 (2048Kb)
;                   fe_i008 ($A2), an INTEL 28F008SA (1024Kb)
;                   fe_i8s5 ($A6), an INTEL 28F008S5 (1024Kb)
;                   fe_i004 ($A7), an INTEL 28F004S5 (512Kb)
;                   fe_i020 ($BD), an INTEL 28F020 (256Kb)
;              B = total of 16K banks on Flash Memory Chip.
;
;         Failure:
;              Fc = 1
;              Fz = 0
;              A = RC_NFE (not a recognised Flash Memory Chip)
;
; Registers changed on return:
;    ...CDEHL/IXIY ........ same
;    AFB...../.... afbcdehl different
;
; ---------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997 - Apr 1998
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
.FlashEprCardId
                    PUSH HL
                    PUSH BC

                    CALL FetchCardID         ; get info of Intel chip in HL...
                    LD   A, FE_INT           ; Intel FlashFile Memory?
                    CP   H
                    JR   NZ, unknown_device  ; not an Intel Chip...

                    LD   A,L                 ; Fc = 0, Fz = 1, A = Device Code
                    CALL GetTotalBlocks      ; return no. of blocks in B
                    POP  HL
                    LD   C,L                 ; original C restored
                    POP  HL                  ; original HL restored
                    RET
.unknown_device     
                    LD   A, RC_NFE
                    SCF
                    POP  BC
                    POP  HL
                    RET


; ***************************************************************
;
; Get the Manufacturer and Device Code from the Intel chip.
; This routine will clone itself on the stack and execute there.
;
; In:
;    C = slot number (1, 2 or 3)
; 
; Out:
;    H = manufacturer code (at $00 0000 on chip)
;    L = device code (at $00 0001 on chip)
;
; Registers changed on return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
.FetchCardID        EXX
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
                    LD   HL,exit_fetchid
                    EX   (SP),HL
                    PUSH HL
                    EXX
                    RET                      ; CALL RAM_code_start
.exit_fetchid                 
                    EXX
                    POP  HL                  ; original SP
                    LD   SP,HL
                    EXX
                    RET                      ; return HL = Intel info...

; 40 bytes of code to be executed on stack...
.RAM_code_start
                    LD   A,C
                    AND  @00000011           ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    LD   B,A
                    LD   C, MS_S1           
                    CALL MemDefBank          ; Get bottom Bank of slot 3 into segment 1
                    PUSH BC                  ; preserve old bank binding

                    LD   HL, $4000           ; Pointer at beginning of segment 1 ($0000)
                    LD   (HL), FE_IID        ; Flash Memory Card ID command
                    LD   B,(HL)              ; B = manufacturer code (at $00 0000)
                    INC  HL
                    LD   C,(HL)              ; C = device code (at $00 0001)
                    LD   (HL), FE_RST        ; Reset Flash Memory Chip to read array mode
                    PUSH BC
                    POP  HL
                    POP  BC
                    CALL MemDefBank          ; restore original bank in segment 1
                    RET
.RAM_code_end


; ***************************************************************
;
; IN:
;    A = Flash Memory Device code
;
; OUT:
;    B = total of 16K banks on Flash Memory
;
; Registers changed on return:
;   AF.CDE../IXIY same
;    .B...HL/.... different
;
.GetTotalBlocks     PUSH AF

                    LD   HL, DeviceCodeTable
                    LD   B,(HL)                   ; no. of Flash Memory Types in table
                    INC  HL
.find_loop          CP   (HL)                     ; device code found?
                    INC  HL
                    JR   NZ, get_next
                         LD   B,(HL)              ; B = total of block on Flash Eprom
                         JR   exit_getblocks      ; Fc = 0, Flash Eprom data returned...
.get_next           INC  HL
                    DJNZ find_loop                ; point at next entry...
.exit_getblocks
                    POP  AF
                    RET
.DeviceCodeTable
                    DEFB 5
                    DEFB fe_i020, 16               ; 4 x 64K blocks or 16 x 16K banks (256Kb)
                    DEFB fe_i004, 32               ; 8 x 64K blocks or 32 x 16K banks (512Kb)
                    DEFB fe_i008, 64               ; 16 x 64K blocks or 64 x 16K banks (1024Kb)
                    DEFB fe_i8s5, 64               ; 16 x 64K blocks or 64 x 16K banks (1024Kb)
                    DEFB fe_i016, 128              ; 32 x 64K blocks or 128 x 16K banks (2048Kb)

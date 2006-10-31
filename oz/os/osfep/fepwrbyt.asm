     MODULE FlashEprWriteByte

; **************************************************************************************************
; OZ Flash Memory Management.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; $Id$
; ***************************************************************************************************

     XDEF FlashEprWriteByte

     LIB SafeBHLSegment       ; Prepare BHL pointer to be bound into a safe segment outside this executing bank
     LIB MemDefBank           ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB MemGetCurrentSlot    ; Get current slot number of this executing library routine in C
     LIB ExecRoutineOnStack   ; Clone small subroutine on system stack and execute it
     LIB DisableBlinkInt      ; No interrupts get out of Blink
     LIB EnableBlinkInt       ; Allow interrupts to get out of Blink
     XREF FlashEprCardId      ; Identify Flash Memory Chip in slot C

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"
     INCLUDE "blink.def"
     INCLUDE "error.def"


; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_WRI = $40           ; byte write command
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
; The routine can be told which programming algorithm to use (by specifying
; the FE_28F or FE_29F mnemonic in A'); these parameters can be fetched when
; investigated which Flash Memory chip is available in the slot, using the
; FlashEprCardId routine that reports these constants back to the caller.
;
; However, if neither of the constants are provided in A', the routine can
; be specified with A' = 0 which internally polls the Flash Memory for
; identification and intelligently use the correct programming algorithm.
; The identified FE_28F or FE_29F constant is returned to the caller in A'
; for future reference (when the byte was successfully programmed to the card).
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
;         A = byte to blow at address
;         A' = FE_28F, FE_29F or 0 (poll card for blowing algorithm)
;         BHL = pointer to Flash Memory address (B=00h-FFh, HL=0000h-3FFFh)
;               (bits 7,6 of B is the slot mask)
; Out:
;         Success:
;              Fc = 0
;              A' = FE_28F or FE_29F (depending on Flash Memory type in slot)
;         Failure:
;              Fc = 1
;              A = RC_BWR (programming of byte failed)
;              A = RC_NFE (not a recognized Flash Memory Chip)
;              A = RC_UNK (chip type is unknown: use only FE_28F, FE_29F or 0)
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; --------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Dec 1997, Jan-Apr 98, Aug 2004, Sep 2005, Aug 2006
;    Thierry Peycru, Zlab, Dec 1997
; --------------------------------------------------------------------------
;
.FlashEprWriteByte
                    PUSH BC
                    PUSH DE
                    PUSH HL                  ; preserve original pointer
                    PUSH IX

                    CALL SafeBHLSegment      ; get a safe segment (not this executing segment!)
                                             ; C = Safe MS_Sx segment, HL points into segment C
                    LD   D,B                 ; copy of bank number
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
;    A = byte to blow, A' = chip type
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
                    PUSH AF
                    LD   A,D                 ; no predefined programming was specified, let's find out...
                    AND  @11000000
                    RLCA
                    RLCA
                    LD   C,A                 ; Flash Memory is in slot C (derived from original bank B)
                    POP  AF

                    EX   AF,AF'              ; check for pre-defined Flash Memory programming (type in A')...
                    CP   FE_28F
                    JR   Z, check_slot3      ; Intel flash programming specified, are we in slot3?
                    CP   FE_29F
                    JR   Z, use_29F_programming
                    OR   A
                    JR   Z, poll_chip_programming ; chip type = 0 indicates to get chip type to program it...
                    SCF
                    LD   A, RC_Unk           ; unknown chip type specified!
                    RET

.poll_chip_programming
                    EX   DE,HL               ; preserve HL (pointer to write byte)
                    CALL FlashEprCardId
                    EX   DE,HL
                    RET  C                   ; Fc = 1, A = RC error code (Flash Memory not found)

                    LD   DE, EnableBlinkInt
                    PUSH DE                  ; enable Blink Int's after blowing byte to 28F or 29F Flash and RETurn
                    CALL DisableBlinkInt     ; no interrupts get out of Blink (while blowing to flash chip)...

                    CP   FE_28F              ; now, we've got the chip series
                    JR   NZ, use_29F_programming ; and this one may be programmed in any slot...
.check_slot3
                    LD   A,3
                    CP   C                   ; when chip is FE_28F series, we need to be in slot 3
                    LD   A,FE_28F            ; restore fetched constant that is returned to the caller..
                    JR   Z,use_28F_programming ; to make a successful "write" of the byte...
                    SCF
                    LD   A, RC_BWR           ; Ups, not in slot 3, signal error!
                    RET

.use_28F_programming
                    EX   AF,AF'              ; byte to be blown...
                    LD   B,A
                    LD   A,C
                    CALL MemGetCurrentSlot   ; get current slot (in C) of this executing library
                    CP   C                   ; library executing in same slot as byte to be blown?
                    LD   A,B                 ; A = byte to blow...
                    JR   NZ, FEP_ExecBlowbyte_28F ; byte to be programmed in another slot than this library

                    LD   IX, FEP_ExecBlowbyte_28F
                    EXX
                    LD   BC, end_FEP_ExecBlowbyte_28F - FEP_ExecBlowbyte_28F
                    EXX
                    JP   ExecRoutineOnStack  ; execute the blow routine in System Stack RAM...

.use_29F_programming
                    EX   AF,AF'              ; byte to be blown...
                    LD   B,A
                    LD   A,C
                    CALL MemGetCurrentSlot   ; get current slot (in C) of this executing library
                    CP   C                   ; library executing in same slot as byte to be blown?
                    LD   A,B                 ; A = byte to blow...
                    JR   NZ, FEP_ExecBlowbyte_29F ; byte to be programmed in another slot than this library

                    LD   IX, FEP_ExecBlowbyte_29F ; executing library in same slot as byte to be blown..
                    EXX
                    LD   BC, end_FEP_ExecBlowbyte_29F - FEP_ExecBlowbyte_29F
                    EXX
                    JP   ExecRoutineOnStack  ; execute the blow routine in System Stack RAM...

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
                    LD   BC,BLSC_COM         ; Address of soft copy of COM register
                    LD   A,(BC)
                    SET  BB_COMVPPON,A       ; VPP On
                    SET  BB_COMLCDON,A       ; Force Screen enabled...
                    LD   (BC),A
                    OUT  (C),A               ; signal to HW
                    POP  AF
                    PUSH BC                  ; preserve COM Blink register soft copy address

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
                    JR   Z, exit_write       ; Fc = 0, byte blown successfully!
.write_error
                    LD   A, RC_BWR
                    SCF
.exit_write
                    POP  BC                  ; get address of soft copy of COM register
                    PUSH AF
                    LD   A,(BC)
                    RES  BB_COMVPPON,A       ; VPP Off
                    LD   (BC),A
                    OUT  (C),A               ; Signal to HW
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
                    PUSH AF
                    PUSH HL                  ; preserve byte program address

                    LD   BC,$AA55            ; B = Unlock cycle #1 code, C = Unlock cycle #2 code
                    LD   A,H
                    AND  @11000000
                    LD   D,A
                    OR   $05
                    LD   H,A
                    LD   L,C                 ; HL = address $x555
                    SET  1,D
                    LD   E,B                 ; DE = address $x2AA

                    LD   A,C
                    LD   (HL),B              ; AA -> (XX555), First Unlock Cycle
                    LD   (DE),A              ; 55 -> (XX2AA), Second Unlock Cycle
                    LD   (HL),$A0            ; A0 -> (XX555), Byte Program Mode
                    POP  HL
                    POP  AF
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
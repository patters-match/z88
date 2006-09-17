; **************************************************************************************************
; Lowram routines that resides in RAM at lower segment 0 of the Z80 address space ($0000 - $01DF).
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
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
;***************************************************************************************************

        Module LowRAM

        org $0000

        include "blink.def"
        include "error.def"
        include "sysvar.def"

IF COMPILE_BINARY
        include "../bank0/kernel0.def"          ; get bank 0 kernel address references
        include "../bank0/ostables.def"         ; get bank 0 kernel OS systm base lookup table address
ELSE
        xref    INTEntry                        ; pretend references to be external for pre-compile...
        xref    NMIEntry
        xref    CallErrorHandler
        xref    OZBuffCallTable
        xref    OZCallTable
ENDIF


xdef    DefErrHandler
xdef    FPP_RET
xdef    INTReturn
xdef    JpAHL
xdef    JpHL
xdef    OZ_RET1
xdef    OZ_RET0
xdef    OZ_DI
xdef    OZ_EI
xdef    OZCallJump
xdef    OZCallReturn1
xdef    OZCallReturn2
xdef    OZCallReturn3
xdef    ExtCall
xdef    MemDefBank, MemGetBank


;       ----
;       RESTARTS
.rst00                                          ; RESET
        di
        xor     a
        out     (BL_COM), a                     ; bind b00 into low 2KB
        ; code continues to execute in bank 0 in ROM (see bank0/boot.asm)...
        defs    $0008-$PC   ($ff)               ; address align for RST 08H

.rst08                                          ; FREE
        scf
        ret
        defs    $0010-$PC  ($ff)                ; address align for RST 10H

.rst10                                          ; EXTCALL
        jp      ExtCall                         ; OZ V4.1: EXTCALL interface

        defs    $0018-$PC  ($ff)                ; address align for RST 18H (OZ Floating Point Package)
.rst18                                          ; FPP
        jp      FPPmain
        defb    0,0
.FPP_RET
        jp      OZCallReturnFP                  ; 001d, called from FPP
        defs    $0020-$PC  ($ff)                ; address align for RST 20H (OZ System Call Interface)

.rst20                                          ; OZ call
        jp      CallOZMain                      ; 0020
        defs    $0028-$PC  ($ff)                ; address align for RST 28H

.rst28                                          ; FREE
        scf
        ret
        defs    $0030-$PC  ($ff)                ; address align for RST 30H

.rst30                                          ; OZ_MPB
.OZ_MPB
        jp      MemDefBank                      ; OZ V4.1: Fast Bank switching (OS_MPB functionality with RST 30H)
        defs    $0038-$PC  ($ff)                ; address align for RST 38H, Blink INT entry point

.OZ_INT                                         ; OZ_INT
        push    af
        ld      a, (BLSC_SR3)                   ; remember S3 and bind in b00
        push    af
        call    MS3Kernel0
        jp      INTEntry
                                                ; IMPORTANT NOTE :
                                                ; a DI is not necessary at the start of OZ_INT
                                                ; since IFF1 and IFF2 are automaticly cleared
                                                ; when accepting an INT
                                                
        defs    $0048-$PC  ($ff)                ; address align

;       ----
;       OZ low level jump table
.OZ_RET1
        jp      OZCallReturn1                   ; 0048
.OZ_RET0
        jp      OZCallReturn0                   ; 004B
;FREE
        defs     3 ($ff)                        ; 004E
.OZ_DI
        jp      OZDImain                        ; 0051
.OZ_EI
        jp      OZEImain                        ; 0054
.OZ_MGB
        jp      MemGetBank                      ; 0057 (V4.1) Fast Bank binding status (OS_MGB functionality)
;FREE
        defs    3 ($ff)                         ; 005A
.INTReturn
        pop     af                              ; 005D return after OZ_INT
        call    MS3BankA                        ; restore S3
        pop     af                              ; restore AF
        ei
        ret                                     ; RETI is not necessary since there is no Z80 PIO
                                                ; RET is faster (10T vs 14T)
                                                
        defs     $0066-$PC  ($ff)               ; address align for RST 66H, Blink NMI entry point

;       ----
;       Non Maskable interrupt entry
.OZNMI
        push    af
        ld      a, BM_COMRAMS                   ; bind bank $20 into lowest 8KB of segment 0
        out     (BL_COM), a

        push    hl                              ; if SP in lowest page we must
        ld      hl, 0                           ; be in init code - reset
        add     hl, sp
        inc     h
        dec     h
        pop     hl
        jr      z, rst00

        ld      a, i                            ; store int status
        push    af

        di                                      ; nested NMIs won't enable interrupts
        ld      a, (BLSC_SR3)                   ; remember S3 and bind in b00
        push    af
        call    MS3Kernel0
        call    NMIEntry                        ; call NMI handler in kernel bank 0

        pop     af                              ; restore S3
        call    MS3BankA
        pop     af                              ; !! can't use 'retn' because of 'di' above
        jp      po, noEI                        ; ints were disabled
        pop     af
        ei
        ret

.OZCallJump                                     ; called from misc2.asm
        pop     af                              ; restore S3
        call    MS3BankA
.noEI
        pop     af                              ; restore AF
        ret

.OZCallReturn0                                  ; ret with AFBCDEHL
        ex      af, af'
        pop     af
        or      a
        jr      OZCallReturnCommon

.OZCallReturn1                                  ; ret with AFBCDEHL
        exx                                     ; called from buffer.asm, memory.asm, misc4.asm, ossi.asm

.OZCallReturn2                                  ; ret with AFbcdehl
        ex      af, af'                         ; called from buffer.asm, error.asm, esc.asm, memory.asm, misc2.asm, oscli0.asm

.OZCallReturn3                                  ; ret with afbcdehl
        exx                                     ; called from buffer.asm

.OZCallReturnFP                                 ; ret with afBCDEHL
        pop     af
        scf

.OZCallReturnCommon
        call    MS3BankA                        ; set S3
        push    hl                              ; decrement call level
        ld      hl, ubAppCallLevel
        dec     (hl)
        pop     hl
        ex      af, af'
        ret     nc                              ; no error, return

        ex      af, af'
        call    z, error
        ex      af, af'
        ret

.error
        ret     nc
        push    af
        call    MS3Kernel0
        pop     af
        push    af
        call    CallErrorHandler
        pop     af                              ; restore S3

.MS3BankA
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        ret

.JpAHL                                          ; called from error.asm, process3.asm
        call    MS3BankA
        ex      af, af'
        call    JpHL
        ex      af, af'

.MS3Kernel0
        ld      a, OZBANK_KNL0
        jr      MS3BankA

.DefErrHandler                                  ; referenced from error.asm, process3.asm
        ret     z
        cp      a
        ret

.CallOZMain
        ex      af, af'
        exx
        ld      hl, ubAppCallLevel              ; increment call level
        inc     (hl)
        pop     hl                              ; caller PC
        ld      e, (hl)                         ; get opByte
        inc     hl
        push    hl
        ld      l,(hl)                          ; get it in case of 2 bytes call
        ld      bc, (BLSC_SR2)                  ; remember S2/S3
        push    bc
        ld      a, OZBANK_KNL0                  ; bind kernel0 bank into S3
        call    MS3BankA

        ld      d, >OZCallTable                 ; function jumper in DE
        ex      de, hl
.JpHL                                           ; called from pfilter0.asm (could use elsewhere as well)
        jp      (hl)                            ; $FFnn, nn=opByte

.FPPmain
        ex      af, af'
        exx
        pop     bc                              ; caller PC
        ld      a, (bc)                         ; get opByte
        inc     bc
        push    bc
        ld      bc, (BLSC_SR2)                  ; remember S2/S3
        push    bc
        push    iy
        ld      iy, ubAppCallLevel              ; increment call level
        inc     (iy+0)
        ld      iy, 0
        add     iy, sp                          ; IY=SP
        push    ix
        ld      bc, FPPCALLTBL                  ; FPP return $d800
        push    bc
        ld      c, a
        push    bc                              ; call function at $d8nn, nn=opByte

        ld      a, OZBANK_FPP                   ; bind b02 into S3
        call    MS3BankA
        ex      af, af'
        exx
        ret

.OZDImain
        xor     a                               ; A=0, Fc=0
        push    af                              ; store A to clear byte in stack
        pop     af                              ;
        ld      a, i                            ; A=snooze/coma flag, IFF2 -> Fp
        di
        ret     pe                              ; interrupts enabled? exit Fc=0

;       we have three possible cases here:
;
;       a)  we got interrupt during 'ld a, i' so interrupts were on
;       b1) interrupts were disabled all the time
;       b2) interrupts were disabled, but somewhere here NMI happens
;
;       in cases (a) and (b2) zero in stack was overwritten with PC high byte,
;       in case (b1) we read back zero.  !! (b2) isn't handled

        dec     sp                              ; read back A
        dec     sp
        pop     af

;       !! if we assert 'DI' above is at odd address, Fc is correct without compare
;       !! another way to get Fc=1 into F: 'dec sp; pop af; dec sp' - uses PC hi

        cp      1                               ; Fc=0 if we were interrupted
        ld      a, i                            ; reload A for NMI routine
        ret

.OZEImain
        ret     c                               ; ints were disabled? exit
        ei
        ret


; ***************************************************************************************************
;
; Bind bank, defined in B, into segment C (MS_Sx). Return old bank binding in B.
; This is the functional equivalent of original OS_MPB, but much faster.
;
;    Register affected on return:
;         AF.CDEHL/IXIY same
;         ..B...../.... different
;
.MemDefBank
        push    hl
        push    af

        ld      hl,BLSC_SR0                     ; base of SR0 - SR3 soft copies
        ld      a,c                             ; get segment specifier (MS_Sx)
        and     @00000011                       ; preserve only segment specifier range...
        or      l
        ld      l,a                             ; HL points at Blink soft copy of current binding in segment C

        ld      a,(hl)                          ; get bound bank number in current segment
        cp      b
        jr      z, already_bound                ; bank B already bound into segment

        ld      (hl),b                          ; A contains "old" bank number
        ld      h,c                             ; preserve original MS_Sx
        ld      c,l
        out     (c),b                           ; bind...

        ld      b,a                             ; return previous bank binding
        ld      c,h                             ; of segment MS_Sx
.already_bound
        pop     af
        pop     hl
        ret
; ***************************************************************************************************



; ***************************************************************************************************
; Get current Bank binding for specified segment MS_Sx, defined in C.
; This is the functional equivalent of OS_MGB, but much faster.
;
;    Register affected on return:
;         AF.CDEHL/IXIY same
;         ..B...../.... different
;
.MemGetBank
        push    af
        push    hl

        ld      hl,BLSC_SR0                     ; base of SR0 - SR3 soft copies
        ld      a,c                             ; get segment specifier (MS_Sx)
        and     @00000011                       ; preserve only segment specifier...
        or      l
        ld      l,a                             ; HL points at Blink soft copy of current binding in segment C
        ld      b,(hl)                          ; get current bank binding

        pop     hl
        pop     af
        ret
; ***************************************************************************************************



; ***************************************************************************************************
; EXTCALL - 24bit Call Subroutine in external bank
;
; This routine is executed by the RST 10H vector. Both RST 10H and this routine is located
; in LOWRAM. The 24bit address is available in low byte - high byte order following the RST 10H
; instruction opcode. The segment specifier (bits 15,14) of the lower 16bit address automatically
; identifies where the bank will be bound into the Z80 address space. The bank number of the 24bit
; address may be specified as absolute or as slot relative ($00 - $3F).
;
; -----------------------------------------------------------------------------------------------
; The ExtCall does not destroy any register call arguments or return values.
; ExtCall is to be regarded as a normal CALL instruction, but for 24bit address range.
; -----------------------------------------------------------------------------------------------
;
; Example in Z80 assembler, Mpm notation: EXTCALL $C000,$FE (a RST 10H followed by 24bit address)
; Execute code in bank $FE at address $C000 bound into segment 3 (the instruction opcode sequence
; in memory is $D7, $00, $C0, $FE). This call instruction uses an absolute bank (located in slot 3)
; in the 24bit address, ie. a piece of code in slot 2 might want to execute a subroutine in slot 3.
;
; Slot relative subroutine calls defines the bank number in the range $00 - $3F (same principle
; as for DOR pointers in application cards). A instantiated large application using more than
; 32K code space (that typically needs the remaining free segments in the Z80 address space for
; dynamic data structure management) would use the 24bit slot relative call to execute subroutines
; in banks that are not bound in the Z80 address by default as defined by the Application DOR).
;
.ExtCall
        push    af                              ; this space will be updated with current bank bindings
        push    af                              ; this space will be updated with [restore_bank_binding] routine address
        push    hl
        push    iy
        push    de
        push    bc
        push    af
        ld      iy,0
        add     iy,sp                           ; IY points at base of register push frame

        ld      l,(iy+14)
        ld      h,(iy+15)                       ; HL points at low byte of 24bit address argument of EXTCALL

        ld      e,(hl)                          ; get low byte of call address
        inc     hl
        ld      d,(hl)                          ; get high byte of call address
        inc     hl                              ; point to bank number of 24bit address
        ld      a,(hl)                          ; get bank number of call address
        and     @11000000
        call    z,get_slotrelative_bank         ; if bank number is slot relative, then get slot mask of executing code
        or      (hl)                            ; and merge with relative bank number
        inc     hl
        ld      (iy+14),l
        ld      (iy+15),h                       ; updated RETurn address on stack (first instruction opcode after EXTCALL 24 bit address argument)
        ex      de,hl                           ; HL = address of sub-routine to execute in bank...
        ld      b,a                             ; the bank number to bind into segment of CALL address
        ld      c,h                             ; bits 15,14 of Z80 CALL address in HL contains segment mask...
        rlc     c
        rlc     c                               ; prepare segment specifier in bits 0,1 (remaining bits are stripped by RST 30H)
        call    MemDefBank                      ; bind in bank of 24bit address (returned B = old bank binding)
        ld      (iy+10),restore_bnk_binding%256
        ld      (iy+11),restore_bnk_binding/256 ; call'ed subroutine RETurns to restore the old bank binding before
        ld      (iy+12),C                       ; returning to instruction after EXTCALL instruction
        ld      (iy+13),B                       ; preserve old bank binding of destination CALL segment

        pop     af
        pop     bc
        pop     de
        pop     iy
        ex      (sp),hl                         ; restored original AF, BC, DE, HL & IY registers
        ret                                     ; execute subroutine in bound bank
.restore_bnk_binding                            ; when subroutine executes it's RET instruction, it is returned here...
        ex      (sp),hl
        push    bc
        ld      b,h
        ld      c,l                             ; old bank binding...
        call    MemDefBank                      ; restore previous bank binding
        pop     bc
        pop     hl                              ; restored original returned BC, HL registers from EXTCALL'ed sub-routine.
        ret                                     ; execute instruction that follows the EXTCALL instruction
.get_slotrelative_bank
        ld      bc,BLSC_SR0                     ; base of SR0 - SR3 soft copies
        ld      a,h                             ; bits 15,14 of executing code define the segment mask
        and     @11000000
        rlca
        rlca                                    ; convert to segment specifier (0-3), then
        or      c                               ; get Blink soft copy bank bindings from address $04D0 - $04D3
        ld      c,a                             ; BC points at Blink soft copy of current binding in segment C
        ld      a,(bc)                          ; get current bank binding of executing code
        and     @11000000                       ; and return only the slot mask
        ret
;***************************************************************************************************

; **************************************************************************************************
; LOWRAM RST vector entries.
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


;       ----
;       RESTARTS
.rst00                                          ; RESET
        di
        xor     a
        out     (BL_COM), a                     ; bind b00 into low 8K of segment 0
        ; code continues to execute in bank 0 in ROM (see [kernel0]/boot.asm)...

        defs    $0008-$PC   ($ff)               ; address align for RST 08H

.rst08                                          ; FREE
        scf
        ret
        defs    $0010-$PC  ($ff)                ; address align for RST 10H

.rst10                                          ; EXTCALL
        jp      ExtCall                         ; OZ V4.1 (and newer): EXTCALL interface
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
        ld      a, (BLSC_SR3)                   ; remember S3
        push    af
        call    MS3Kernel0                      ; and bind in KERNEL0
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
.OZ_INT_DI
        jp      OZDImain                        ; 0051
.OZ_INT_EI
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
        ld      a, (BLSC_SR3)                   ; remember S3
        push    af
        call    MS3Kernel0                      ; and bind in KERNEL0
        call    NMIEntry                        ; call NMI handler in KERNEL0

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


; **************************************************************************************************
; ROM Boot sequence, executed when reset button pressed or first cold start of machine.
; Code resides at start of Kernel 0.
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
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************


        Module  Boot

        include "blink.def"
        include "sysvar.def"
        include "memory.def"

        org     $c000

xdef    Halt
xdef    Boot_reset
xdef    Delay300Kclocks
xdef    HW_INT, HW_NMI

xref    nmi_5                                   ; [Kernel0]/nmi.asm
xref    HW_NMI2                                 ; [Kernel0]/nmi.asm
xref    VerifySlotType                          ; [Kernel0]/memory.asm

xref    Reset                                   ; [Kernel1]/reset.asm


; reset code at $0000

.Reset0
        ld      sp, ROMstack & $3fff            ; read return PC from ROM - Reset1
        di
        ld      sp, ROMstack & $3fff            ; read return PC from ROM - Reset1
        xor     a
        ld      i, a                            ; I=0, reset ID
        im      1
        in      a, (BL_STA)                     ; remember interrupt status
        ex      af, af'
        ld      hl, [BM_INTTIME|BM_INTGINT]<<8 | BM_TMKTICK
        xor     a
        out     (BL_COM), a                     ; reset command register

; snooze on coma and wait for interrupt
;
; IN : H = interrupt mask  L = RTC mask

.Halt
        di
        ld      a, OZBANK_KNL0
        out     (BL_SR2), a
        out     (BL_SR3), a                     ; preset kernel banks
        ld      a, l                            ; enable and ack RTC interrupts
        out     (BL_TMK), a
        out     (BL_TACK), a
        ld      a, h                            ; enable and ack interrupts
        out     (BL_INT), a
        out     (BL_ACK), a

.halt_1
        ei                                      ; wait until interrupt
        halt
        jr      halt_1

.rint_0
        di
        ld      sp, ROMstack & $3fff            ; read return PC from ROM
        call    Delay300Kclocks                 ; ret to Reset1

; for the ret in ROM
        defw    Reset1
.ROMstack
IF OZ_SLOT1
        defw     Boot_reset                     ; OZ ROM in slot 1 just continues the reset
ELSE
        defw     Bootstrap2                     ; if OZ ROM is in slot 0, then poll for OZ in slot 1,,,
ENDIF
        defs    ($0038-$PC) ($ff)               ; pad FFh's until 0038H (Z80 INT vector)


; hardware IM1 INT at $0038

.HW_INT
        ld      a, OZBANK_KNL0
        out     (BL_SR3), a                     ; MS3b00
        ld      a, i
        jr      z, rint_0                       ; I=0? from reset
        scf
        jp      nmi_5
.Reset1
        ld      de, 1<<8 | $3f                  ; check slot 1, max size 63 banks
        jp      VerifySlotType                  ; ret at ROMstack

IF !OZ_SLOT1
.Bootstrap2
        bit     BU_B_ROM, d                     ; check for bootable ROM in slot 1
        jr      z, Boot_reset                   ; not application ROM? skip
        ld      a, ($bffd)                      ; subtype
        cp      'Z'
        jr      nz, Boot_reset

        ld      bc, $7FB2                       ; OZ ROM exists in slot 1, poll fro ESC to boot from ROM.0 instead...
        in      a, (c)
        cp      @11011111                       ; Escape key is pressed?
        jp      nz,$bff8                        ; ESC not pressed, boot ROM.1
ENDIF                                           ; else fall through and boot ROM.0

.Boot_reset
        ld      a, OZBANK_KNL1
        out     (BL_SR2), a                     ; get kernel 1 into segment 2
        jp      Reset                           ; init internal RAM, blink and low-ram code and set SP

        defs    ($0066-$PC) ($ff)               ; pad FFh's until 0066H (Z80 NMI vector)

; hardware non maskable interrupt at $0066

.HW_NMI
        xor     a                               ; reset command register
        out     (BL_COM), a
        ld      h, a                            ; if stack points to $00xx we go back to reset
        ld      l, a                            ;
        add     hl, sp
        inc     h
        dec     h
        jr      z, Reset0                       ; reset if SP=$00xx
        ld      a, OZBANK_KNL0
        out     (BL_SR3), a                     ; MS3b00
        jp      HW_NMI2                         ; into ROM code


;       delay ~300 000 clock cycles

.Delay300Kclocks
        ld      hl, 10000                       ; 10 000*30 cycles
        ld      b, $ff
.dlay_1
        ld      c, $ff                          ; 7+11+12 cycles
        add     hl, bc
        jr      c, dlay_1
        ret


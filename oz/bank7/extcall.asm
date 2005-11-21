        Module ExtCall

; **************************************************************************************************
; EXTCALL - 24bit Call Subroutine in external bank, implemented for OZ V4.1.
; (C) Gunther Strube (gbs@users.sf.net), 1997-2005
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
;***************************************************************************************************

     include "memory.def"                       ; definitions for memory management & system calls

xdef ExtCall

xref regs                                       ; storage space for original BC & DE registers


;***************************************************************************************************
; EXTCALL - 24bit Call Subroutine in external bank
;
; This routine is executed by the RST 10H vector. Both RST 10H and this routine is located
; in LOWRAM. The 24bit address is available in low byte - high byte order following the RST 10H
; instruction opcode.
;
; Example in Z80 assembler: RST 10H, $FEC000, execute code in bank $FE at address $C000.
; (the instruction opcode sequence in memory is $D7, $00, $C0, $FE)
;
; The ExtCall does not destroy any register call arguments or return values. ExtCall
; is to be regarded as a normal CALL instruction, but for 24bit address range.
;
; RESTRICTION:
; This routine cannot be used in Blink NMI or INT service routines because it would corrupt
; the static storage variables at (regs) while ExtCall is being executed by the normal processor.
;
.ExtCall
        ex      (sp),hl                         ; HL points at 24bit address argument (original HL on stack)
        call    PreserveBCDE                    ; temporarily preserve original BC, DE registers
        ld      e,(hl)                          ; low byte of call address
        inc     hl
        ld      d,(hl)                          ; high byte of call address
        inc     hl
        ld      b,(hl)                          ; bank number of 24bit address
        inc     hl                              ; correct RETurn address
        ld      c,d
        push    af                              ; preserve flags...
        rlc     c
        rlc     c                               ; prepare segment specifier in bits 0,1 (remaining bits are stripped by RST 30H)
        pop     af
        rst     OZ_MPB                          ; bind in bank of 24bit address (returned B = old bank binding)

        ex      (sp),hl                         ; new RETurn address points at instruction after 24bit call address
        push    bc                              ; preserve bank bindings that are restored after subroutine completes.
        ld      bc,restore_bank_binding         ; (HL now restored with original caller value)
        push    bc                              ; call'ed subroutine RETurns to restore the old bank binding before
        push    de                              ; actually returning from ExtCall...
        call    RestoreBCDE
        ret                                     ; CALL address to subroutine in bound bank

.restore_bank_binding                           ; when subroutine executes RET, it is returned here...
        call    PreserveBC
        pop     bc                              ; old bank binding...
        rst     OZ_MPB                          ; restore previous bank binding
        call    RestoreBC
        ret

.PreserveBCDE
        ld      (regs+2),de
.PreserveBC
        ld      (regs),bc
        ret
.RestoreBCDE
        ld      de,(regs+2)
.RestoreBC
        ld      bc,(regs)
        ret

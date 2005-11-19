
; **************************************************************************************************
; This file is part of the Z88 operating system, OZ
;
; OZ is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; OZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************


;***************************************************************************************************
; EXTCALL - 24bit Call Subroutine in external bank
;
; This routine is executed by the RST 10H vector. Both RST 10H and this routine is located
; in LOWRAM. The 24bit address is available in low byte - high byte order following the RST 10H
; instruction.
;
; Example in Z80 assembler: RST 10H, $FEC000, execute code in bank $FE at address $C000.
; (the instruction opcode sequence in memory is $D7, $00, $C0, $FE)
;
; The ExtCall does not destroy any registers call arguments or return values. ExtCall
; is to be regarded as a normal CALL instruction, but for 24bit address range.
;
; RESTRICTION:
; This routine cannot be used in Blink NMI or INT service routines because it would corrupt
; the static storage variables at (regs) while ExtCall is being executed by normal processor.
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 2005
; ----------------------------------------------------------------------
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

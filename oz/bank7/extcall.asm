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

        xref regs                                  ; storage space for original BC & DE registers
        xref MemGetBank


;***************************************************************************************************
; EXTCALL - 24bit Call Subroutine in external bank
;
; This routine is executed by the RST 10H vector. Both RST 10H and this routine is located
; in LOWRAM. The 24bit address is available in low byte - high byte order following the RST 10H
; instruction opcode. The segment specifier (bits 15,14) of the lower 16bit address automatically
; identifies where the bank will be bound into the Z80 address space. The bank number of the 24bit
; address may be specified as absolute or as slot relative ($00 - $3F).
;
; The ExtCall does not destroy any register call arguments or return values. ExtCall is to be
; regarded as a normal CALL instruction, but for 24bit address range.
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
; RESTRICTION:
; This routine cannot be used in Blink NMI or INT service routines because it would corrupt
; the static storage variables at (regs) while ExtCall is being executed by the normal processor.
;
.ExtCall
        ex      (sp),hl                         ; HL points at 24bit address argument (original HL on stack)
        call    PreserveBCDE                    ; temporarily preserve original BC, DE registers
        ld      e,(hl)                          ; get low byte of call address
        inc     hl
        ld      d,(hl)                          ; get high byte of call address
        inc     hl                              ; point to bank number of 24bit address
        push    af                              ; preserve Accumulator and flags of subroutine that executed EXTCALL ...
        ld      a,(hl)                          ; get bank number of call address
        and     @11000000
        call    z,get_slotrelative_bank         ; if bank number is slot relative, then get slot mask of executing code
        or      (hl)                            ; and merge with relative bank number
        inc     hl                              ; correct RETurn address (first instruction opcode after 24 bit address)
        ld      b,a                             ; the final bank number to bind into segment of CALL address
        ld      c,d                             ; bits 15,14 of Z80 CALL address in DE contains segment mask...
        rlc     c
        rlc     c                               ; prepare segment specifier in bits 0,1 (remaining bits are stripped by RST 30H)
        pop     af
        rst     OZ_MPB                          ; bind in bank of 24bit address (returned B = old bank binding)

        ex      (sp),hl                         ; updated RETurn address on stack (first instruction opcode after 24 bit address argument)
        push    bc                              ; preserve bank bindings that are restored after subroutine completes.
        ld      bc,restore_bank_binding         ; (HL now restored with original caller value)
        push    bc                              ; call'ed subroutine RETurns to restore the old bank binding before
        push    de                              ; actually returning from ExtCall...
        call    RestoreBCDE
        ret                                     ; CALL address to subroutine in bound bank
.get_slotrelative_bank
        ld      a,h                             ; bits 15,14 of executing code define the segment mask
        and     @11000000
        rlca
        rlca                                    ; convert to segment specifier (0-3), then
        or      $d0                             ; get Blink soft copy bank bindings from address $04D0 - $04D3
        ld      b,$04
        ld      c,a                             ; BC points at Blink soft copy of current binding in segment C
        ld      a,(bc)                          ; get current bank binding of executing code
        and     @11000000                       ; and return only the slot mask
        ret

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

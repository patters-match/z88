; **************************************************************************************************
; LOWRAM fast memory bank switching and extended call routines.
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
; ***************************************************************************************************

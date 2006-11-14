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

        xdef FlashEprWriteByte, FEP_ExecBlowbyte_29F

        lib DisableBlinkInt                     ; No interrupts get out of Blink
        lib EnableBlinkInt                      ; Allow interrupts to get out of Blink

        xref FlashEprCardId                     ; Identify Flash Memory Chip in slot C
        xref AM29Fx_InitCmdMode                 ; prepare for AMD Chip command mode
        xref FEP_WriteError                     ; Error: byte wasn't blown properly

        include "flashepr.def"
        include "lowram.def"
        include "memory.def"
        include "blink.def"
        include "error.def"



; ***************************************************************************
;
; -----------------------------------------------------------------------
; Write a byte (in C) to the Flash Memory Card in slot x, at address BHL.
; -----------------------------------------------------------------------
;
; BHL points to a bank, offset (which is part of the slot that the Flash
; Memory Card have been inserted into).
;
; The routine can be told which programming algorithm to use (by specifying
; the FE_28F or FE_29F mnemonic in E); these parameters can be fetched when
; investigated which Flash Memory chip is available in the slot, using the
; FlashEprCardId routine that reports these constants back to the caller.
;
; However, if neither of the constants are provided in E, the routine can
; be specified with E = 0 which internally polls the Flash Memory for
; identification and intelligently use the correct programming algorithm.
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
;         C = byte to blow at address
;         E = FE_28F, FE_29F or 0 (poll card for blowing algorithm)
;         BHL = pointer to Flash Memory address (B=00h-FFh, HL=0000h-3FFFh)
;               (bits 7,6 of B is the slot mask)
; Out:
;         Success:
;              Fc = 0
;              A = byte successfully blown to Flash Memory
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
;    Gunther Strube, Dec 1997, Jan-Apr 98, Aug 2004, Sep 2005, Aug, Nov 2006
;    Thierry Peycru, Zlab, Dec 1997
; --------------------------------------------------------------------------
;
.FlashEprWriteByte
        push    bc
        push    de
        push    hl                              ; preserve original pointer
        push    ix

        ld      a,c
        ld      c, MS_S1
        res     7,h
        set     6,h                             ; use segment 1 to write byte to flash..

        ld      d,b                             ; copy of bank number
        rst     OZ_MPB                          ; bind bank B into segment...
        push    bc
        call    FEP_BlowByte                    ; blow byte in A to (BHL) address
        pop     bc
        rst     OZ_MPB                          ; restore original bank binding

        pop     ix
        pop     hl
        pop     de
        pop     bc
        ret


; ***************************************************************
;
; Blow byte in Flash Eprom at (HL), segment 1, slot x
; This routine will clone itself on the stack and execute there.
;
; In:
;    A = byte to blow
;    D = bank of pointer
;    E = chip type FE_28F, FE_29F or 0
;    HL = pointer to memory location in Flash Memory
; Out:
;    Fc = 0,
;        A = byte blown successfully to the Flash Memory
;    Fc = 1,
;        A = RC_ error code, byte not blown
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.FEP_Blowbyte
        ex      af,af'
        ld      a,d                             ; no predefined programming was specified, let's find out...
        and     @11000000
        rlca
        rlca
        ld      c,a                             ; Flash Memory is in slot C (derived from original bank B)

        ld      a,e                             ; check for pre-defined Flash Memory programming
        cp      FE_28F
        jr      z, check_slot3                  ; Intel flash programming specified, are we in slot3?
        cp      FE_29F
        jr      z, use_29F_programming
        or      a
        jr      z, poll_chip_programming        ; chip type = 0 indicates to get chip type to program it...
        scf
        ld      a, RC_Unk                       ; unknown chip type specified!
        ret

.poll_chip_programming
        ex      de,hl                           ; preserve HL (pointer to write byte)
        call    FlashEprCardId                  ; return chip ID in HL, FE_x programming type in A
        ex      de,hl
        ret     c                               ; Fc = 1, A = RC error code (Flash Memory not found)

        ld      de, EnableBlinkInt
        push    de                              ; enable Blink Int's after blowing byte to 28F or 29F Flash and RETurn
        call    DisableBlinkInt                 ; no interrupts get out of Blink (while blowing to flash chip)...

        cp      FE_28F                          ; now, we've got the chip series
        jr      nz, use_29F_programming         ; and this one may be programmed in any slot...
.check_slot3
        ld      a,3
        cp      c                               ; when chip is FE_28F series, we need to be in slot 3
        ld      a,FE_28F                        ; restore fetched constant that is returned to the caller..
        jr      z,use_28F_programming           ; to make a successful "write" of the byte...
        jp      FEP_WriteError                  ; Ups, not in slot 3, signal error!
.use_29F_programming
        ex      af,af'
        jr      FEP_ExecBlowbyte_29F            ; blow byte on AMD/STM Flash
.use_28F_programming
        ex      af,af'                          ; blow byte on INTEL Flash

; ***************************************************************
; Program byte in A at (HL) on an INTEL I28Fxxxx Flash Memory
;
; In:
;    A = byte to blow
;    HL = pointer to memory location in Flash Memory
; Out:
;    Fc = 0 & Fz = 0,
;        A = byte successfully blown to Flash Memory
;    Fc = 1,
;        A = RC_BWR, byte not blown
;
.FEP_ExecBlowbyte_28F
        push    af
        ld      bc,BLSC_COM                     ; Address of soft copy of COM register
        ld      a,(bc)
        set     BB_COMVPPON,a                   ; VPP On
        set     BB_COMLCDON,a                   ; Force Screen enabled...
        ld      (bc),a
        out     (c),a                           ; signal to HW
        pop     af
        push    bc                              ; preserve COM Blink register soft copy address

        ld      b,a                             ; preserve byte to be blown...
        cp      a                               ; Fc = 0
        call    I28Fx_BlowByte
        bit     4,a
        call    nz,FEP_WriteError               ; Error: byte wasn't blown properly
        jr      c,exit_write

        ld      a,(hl)                          ; read byte at (HL) just blown
        cp      b                               ; equal to original byte?
        call    nz,FEP_WriteError               ; Error: byte wasn't blown properly
.exit_write
        pop     bc                              ; get address of soft copy of COM register
        push    af
        ld      a,(bc)
        res     BB_COMVPPON,A                   ; VPP Off
        ld      (bc),a
        out     (c),a                           ; Signal to HW
        pop     af
        ret


; ***************************************************************
; Program byte in A at (HL) on an AMD AM29Fxxxx Flash Memory
;
; In:
;    A = byte to blow
;    HL = pointer to memory location in Flash Memory
; Out:
;    B = A(in)
;
;    Fc = 0 & Fz = 0,
;        A = byte successfully blown to Flash Memory
;    Fc = 1,
;        A = RC_BWR, byte not blown
;
.FEP_ExecBlowbyte_29F
        push    hl
        call    AM29Fx_InitCmdMode
        exx
        pop     hl
        exx
        call    AM29Fx_BlowByte
        jp      nz, FEP_WriteError
        ld      a,(hl)                          ; we're back in Read Array Mode
        cp      b                               ; verify programmed byte (just in case!)
        ret     z                               ; byte was successfully programmed!
        jp      FEP_WriteError

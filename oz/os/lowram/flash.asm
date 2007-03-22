; **************************************************************************************************
; Lowram routines for OS_Fep API.
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
; Poll for I28F0xxxx (INTEL) Flash Memory Chip ID.
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       HL points into bound bank of potential Flash Memory
; Out:
;       H = manufacturer code (at $00 0000 on chip)
;       L = device code (at $00 0001 on chip)
;
; Registers changed on return:
;    AFBC..../IXIY same
;    ....DEHL/.... different
;
.I28Fx_PollChipId
        ld      (hl), $90                       ; get INTELligent identification code (manufacturer and device)
        ld      d,(hl)                          ; D = Manufacturer Code (at $00 0000)
        inc     hl
        ld      e,(hl)                          ; E = Device Code (at $00 0001)
        ld      (hl), $ff                       ; Reset Flash Memory Chip to read array mode
        ex      de,hl
        ret
; ***************************************************************************************************



; ***************************************************************************************************
; Erase sector in I28F0xxxx (INTEL) Flash Memory Chip, identified by executing chip command
; in bank of sector to be erased.
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       HL points into bound bank of Flash Memory sector to be erased
; Out:
;       A = Chip Status Register
;               (bit 3 enabled indicates missing VPP pin during erase)
;               (bit 5 enabled indicates erase sector failure)
;
; Registers changed on return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.I28Fx_EraseSector
        ld      (hl), $20                       ; erase sector command
        ld      (hl), $D0                       ; confirm erasure
        call    I28Fx_ExeCommand
.I28Fx_ReadArrayMode
        ld      (hl), $50                       ; Clear Status Register
        ld      (hl), $ff                       ; Reset Flash Memory to Read Array Mode
        ret
; ***************************************************************************************************



; ***************************************************************************************************
; Blow byte in I28F0xxxx (INTEL) Flash Memory Chip, identified by executing chip command
; at (HL) in bound bank.
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       HL points into bound bank of Flash Memory sector of byte to be blown
; Out:
;       A = Chip Status Register
;               (bit 3 enabled indicates missing VPP pin)
;               (bit 4 enabled indicates blow byte failure)
;
; Registers changed on return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.I28Fx_BlowByte
        ld   (hl),$40                           ; Byte Write Command
        ld   (hl),a                             ; to blow the byte at address...
        call I28Fx_ExeCommand
        jr   I28Fx_ReadArrayMode                ; get back to Read Array Mode and return Status Register
; ***************************************************************************************************



; ***************************************************************************************************
; Wait for I28F0xxxx (INTEL) Flash Memory Chip command to finish.
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       HL points into bound bank of potential Flash Memory
; Out:
;       A = Chip Status Register
;       Fz = 0, Command has been executed
;
; Registers changed on return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.I28Fx_ExeCommand
        ld      (hl), $70                       ; Read Status Register
        ld      a,(hl)
        bit     7,a
        ret     nz
        jr      I28Fx_ExeCommand                ; Chip still executing command...
; ***************************************************************************************************



; ***************************************************************************************************
; Polling code for AM29F0xxx / ST29F0xxx (AMD/STM) Flash Memory Chip ID
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       HL = points into bound bank of potential Flash Memory (defined by OS_Fep sub function)
; Out:
;       D = manufacturer code (at $00 xxx0 on chip)
;       E = device code (at $00 xxx1 on chip)
;
; Registers changed on return:
;    AF....../IXIY same
;    ..BCDEHL/.... different
;
.AM29Fx_PollChipId
        push    af

        ld      a,$90                           ; autoselect mode (to get ID)
        call    AM29Fx_CmdMode

        ld      l,0
        ld      d,(hl)                          ; get Manufacturer Code (at XX00)
        inc     hl
        ld      e,(hl)                          ; get Device Code (at XX01)
        ld      (hl),$f0                        ; F0 -> (XXXXX), set Flash Memory to Read Array Mode

        pop     af                              ; D = Manufacturer Code, E = Device Code
        ret
; ***************************************************************************************************



; ***************************************************************************************************
; Erase block on an AMD 29Fxxxx (or compatible) Flash Memory, which is bound into segment x
; that HL points into.
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       BC = $aa55
;       DE = address $x2AA  (points into bound Flash Memory sector)
;       HL = address $x555
; Out:
;    Success:
;        Fz = 1
;        A = undefined
;    Failure:
;        Fz = 0 (sector not erased)
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.AM29Fx_EraseSector
        ld      a,$80                           ; Execute main Erase Mode
        call    AM29Fx_CmdMode
        ld      a,$30                           ; then sub command...
        call    AM29Fx_CmdMode


; ***************************************************************************************************
; Wait for AM29F0xxx (AMD) Flash Memory Chip command to finish.
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       HL points into bound bank of potential Flash Memory
; Out:
;       A = undefined
;       Fz = 1, Command has been executed successfully
;       Fz = 0, Command execution failed
;
; Registers changed on return:
;    ..B.DEHL/IXIY same
;    AF.C..../.... different
;
.AM29Fx_ExeCommand
        ld      a,(hl)                          ; get first DQ6 programming status
        ld      c,a                             ; get a copy programming status (that is not XOR'ed)...
        xor     (hl)                            ; get second DQ6 programming status
        bit     6,a                             ; toggling?
        ret     z                               ; no, command completed successfully (Read Array Mode active)!
        bit     5,c                             ;
        jr      z, AM29Fx_ExeCommand            ; we're toggling with no error signal and waiting to complete...

        ld      a,(hl)                          ; DQ5 went high, we need to get two successive status
        xor     (hl)                            ; toggling reads to determine if we're still toggling
        bit     6,a                             ; which then indicates a command error...
        ret     z                               ; we're back in Read Array Mode, command completed successfully!
        ld      (hl),$f0                        ; command failed! F0 -> (XXXXX), force Flash Memory to Read Array Mode
        ret
; ***************************************************************************************************



; ***************************************************************************************************
; Blow byte in AM29F0xxx / ST29F0xxx (AMD/STM) Flash Memory Chip, identified by executing chip
; command at (HL) in bound bank.
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       A = byte to blow
;       BC = $aa55
;       DE = address $x2AA
;       HL = address $x555
;       hl' = points into bound bank of Flash Memory sector to blow byte
; Out:
;       A = Chip Status Register
;
; Registers changed on return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.AM29Fx_BlowByte
        push    af
        ld      a,$A0                           ; Byte Program Mode
        call    AM29Fx_CmdMode
        pop     af
        exx
        ld      (hl),a                          ; program byte to flash memory address
        jr      AM29Fx_ExeCommand
; ***************************************************************************************************



; ***************************************************************************************************
; Execute AM29F0xxx / ST29F0xxx (AMD/STM) Flash Memory Chip Command
; (Internal service routine in LOWRAM for OS_Fep system call)
;
; In:
;       A = AMD/STM Command code
;       BC = $aa55
;       DE = address $x2AA
;       HL = address $x555
; Out:
;       -
;
; Registers changed on return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.AM29Fx_CmdMode
        ld      (hl),b                          ; AA -> (X555), First Unlock Cycle
        ex      de,hl
        ld      (hl),c                          ; 55 -> (X2AA), Second Unlock Cycle
        ex      de,hl
        ld      (hl),a                          ; A -> (X555), send command
        ret

; **************************************************************************************************
; OZ calls 2 bytes routines : OS2, DC and GN jumpers
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

        Module  OZ2call

        include "error.def"
        include "director.def"
        include "memory.def"
        include "sysvar.def"

        include "lowram.def"

xdef    CallDC
xdef    CallGN
xdef    CallOS2byte

xdef    OzCallInvalid

xref    MS2BankA                                ; [Kernel0]/memmisc.asm
xref    MS2BankK1                               ; [Kernel0]/memmisc.asm
xref    OSFramePushMain                         ; [Kernel0]/stkframe.asm

xref    OSPrtPrint                              ; [Kernel1]/printer.asm

;       all 2-byte calls use OSframe

.CallDC
        ld      a, OZBANK_DC                    ; Bank 2, $80xx
        ld      d, >DCCALLTBL
        jr      ozc
.CallGN
        ld      a, OZBANK_GN                    ; Bank 3, $80xx
        ld      d, >GNCALLTBL
        jr      ozc

.CallOS2byte
        ld      a, OZBANK_KNL0                  ; Kernel0 bank, $FFxx
        ld      d, >OZCALLTBL

.ozc                                            ; e contains 2nd opcode
        pop     bc                              ; S2/S3
        pop     hl                              ; caller PC
        inc     hl
        push    hl                              ; caller PC
        ld      hl, ozc_ret                     ; return here
        jp      OSFramePushMain                 ; OSPUSH and ret below

.ozc_ret
        cp      a                               ; Fz=1, Fc=0
        ex      af, af'                         ; alt register
        call    MS2BankA                        ; bind code in
        exx                                     ; alt registers

        ex      de, hl                          ; function address into DE
        ld      e, (hl)
        inc     l
        ld      d, (hl)

        set     6, h                            ; or $4000 - return into S3
        ld      l, 3                            ; return call always at $xx03
        push    hl                              ; return address
        push    de                              ; function address
        ex      af, af'
        push    af                              ; caller A
        ex      af, af'
        push    af                              ; code bank
        call    MS2BankK1                       ; S2 is always kernel 1 with 2 bytes calls
        exx                                     ; main registers
        jp      OZCallJump                      ; bind code into S3 and ret to it

.OzCallInvalid
        ld      a, RC_OK
        scf
        jp      OZCallReturn2



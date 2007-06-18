; **************************************************************************************************
; Lowram routines that resides in RAM at lower segment 0 of the Z80 address space.
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
        include "flashepr.def"
        include "interrpt.def"
        include "buffer.def"
        include "serintfc.def"
        include "stdio.def"

IF COMPILE_BINARY
        include "../kernel0.def"                ; get kernel 0 kernel address references
        include "../ostables.def"               ; get kernel 0 OS system base lookup table address
ELSE
        xref    INTEntry                        ; pretend references to be external for pre-compile...
        xref    NMIEntry
        xref    CallErrorHandler
        xref    OZBuffCallTable
        xref    OZCallTable
ENDIF


xdef    LowRAMcode, LowRAMcode_end
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
xdef    I28Fx_PollChipId, I28Fx_BlowByte, I28Fx_EraseSector
xdef    AM29Fx_PollChipId, AM29Fx_BlowByte, AM29Fx_EraseSector
xdef    BfSta, BfPb, BfGb

.LowRAMcode

include "rst.asm"
include "memfunc.asm"
include "flash.asm"
include "buffer.asm"
include "intuart.asm"

.LowRAMcode_end
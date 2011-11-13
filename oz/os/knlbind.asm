; **************************************************************************************************
; Kernel binding internal calls
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
; ***************************************************************************************************

        module  knlbind

        include "blink.def"
        include "oz.def"
        include "lowram.def"

xdef    OSBix, OSBox
xdef    OSBixS1, OSBoxS1
xdef    MS12BankCB
xdef    MS1BankA
xdef    MS1BankB
xdef    MS2BankA
xdef    MS2BankB
xdef    MS2BankK1
xdef    FPtr2MemPtrBindS2
xdef    S2VerifySlotType

xref    FilePtr2MemPtr                          ; [Kernel0]/filesys3.asm
xref    VerifySlotType                          ; [Kernel0]/memory.asm


; -----------------------------------------------------------------------------
;       restore bindings after OS_Bix
.OSBox
        exx
        ld      (BLSC_SR1), de
        jr      bix_3


; -----------------------------------------------------------------------------
; bind in extended address
.OSBix
        exx
        ld      de, (BLSC_SR1)                  ; remember S2S1 in de'
        push    bc
        inc     b
        dec     b
        jr      nz, bix_far                     ; bind in BHL

        ld      b, (iy+OSFrame_S3)
        ld      c, (iy+OSFrame_S2)
        bit     7, h
        jr      z, bix_4                        ; not kernel space, no bankswitching

        bit     6, h
        jr      z, bix_S2                       ; HL in S2 - S1=caller S2, S2=caller S3

;       HL in S3

        ld      c, b                            ; S1=caller S3
        ld      b, d                            ; S2=caller S2
        jr      bix_S2

.bix_far
        ld      c, b                            ; S1=B
        inc     b                               ; S2=B+1
.bix_S2
        ld      (BLSC_SR1), bc                  ; store pointers
        pop     bc

        ld      b, 0                            ; HL=local
        res     7, h                            ; S1 fix
        set     6, h
.bix_3
        push    bc
        ld      bc, (BLSC_SR1)
        call    MS12BankCB

.bix_4
        pop     bc
        ex      af, af'
        or      a
        jp      OZCallReturn1


; -----------------------------------------------------------------------------
;
;       OSBixS1 Replacement of OSBix for the kernel
;               can be called from S2 and faster
;       IN : BHL
;       OUT: D previous S1 binding, H is fixed to S1
;
;       ....D.H./....  different
; -----------------------------------------------------------------------------
.OSBixS1
        res     7, h                            ; S1 fix
        set     6, h                            ; could handle b=0 local by inc b, dec b, ret z
        ex      af, af'
        ld      a, (BLSC_SR1)
        ld      d, a                            ; previous S1 binding in D
        ld      a, b
        call    MS1BankA
        ex      af, af'
        ret

; -----------------------------------------------------------------------------
;
;       OSBoxS1 Replacement of OSBox for the kernel
;               can be called from S2 and faster
;       IN : D previous binding returned by OSBixS1
;       OUT: -
;
;       ......../....  different
; -----------------------------------------------------------------------------
.OSBoxS1
        ex      af,af'
        ld      a, d
        ld      (BLSC_SR1), a                   ; restore previous binding
        call    MS1BankA
        ex      af, af'
        ret
;       ----

.MS12BankCB
        ld      (BLSC_SR1), bc
        ld      a, c
        out     (BL_SR1), a
        ld      a, b
        out     (BL_SR2), a
        ret


.MS1BankB
        ld      a, b

.MS1BankA
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ret


;       ----

;       translate file pointer into memory pointer, bind memory in

.FPtr2MemPtrBindS2
        call    FilePtr2MemPtr

.MS2BankB
        ld      a, b
        jr      MS2BankA

;       ----

;       call VerifySlotType(), then restore b07 into S2
;       !! all calls come from b07 in S2 - move code in b00 to avoid this

.S2VerifySlotType
        call    VerifySlotType

;       bind in other half of kernel

.MS2BankK1
        ld      a, OZBANK_KNL1

.MS2BankA
        ld      (BLSC_SR2), a
        out     (BL_SR2), a
        ret
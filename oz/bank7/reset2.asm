; **************************************************************************************************
; Reset functionality; Displays 'soft/hard reset', copies restart vectors into LOWRAM.
; The routines are located in Bank 7.
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
;***************************************************************************************************


        Module Reset2

        include "blink.def"
        include "memory.def"
        include "screen.def"
        include "sysvar.def"

xdef    Reset2

xref    InitBufKBD_RX_TX                        ; bank0/buffer.asm
xref    KPrint                                  ; bank0/misc5.asm
xref    Reset3                                  ; bank0/reset13.asm
xref    ResetHandles                            ; bank0/handle.asm
xref    ResetTimeout                            ; bank0/nmi.asm

xref    InitData                                ; bank7/initdata.asm
xref    LowRAMcode                              ; bank7/lowram0.asm
xref    LowRAMcode_e                            ; bank7/lowram0.asm

;       ----

.Reset2
        xor     a
        ex      af, af'                         ; interrupt status
        bit     BB_STAFLAPOPEN, a
        ld      a, $21
        jr      nz, b20_hard_reset              ; flap? hard reset

        out     (BL_SR1), a                     ; b21 into S1
        ld      hl, ($4000)
        ld      bc, $A55A                       ; RAM tag
        or      a
        sbc     hl, bc
        jr      nz, b20_hard_reset              ; not tagged? hard reset

        ex      af, af'                         ; soft reset - a' = $FF, fc'=1
        cpl
        scf
        ex      af, af'

        dec     a                               ; only clear b20
        ld      bc, $3DFF                       ; from 0200-3FFF
        ld      de, $4201                       ; 0000-01DF is overwritten by lowram.bin
        ld      hl, $4200                       ; 01E0-01FF is preserved area
        jr      b20_reset
.b20_hard_reset
        ld      bc, $3FFF                       ; fill bank with 00
        ld      de, $4001
        ld      hl, $4000
.b20_reset
        out     (BL_SR1), a                     ; bind A into S1
        ld      (hl), 0
        ldir
        dec     a
        cp      $20
        jr      z, b20_hard_reset               ; loop if hard reset

        ex      af, af'
        ld      ($4000+ubResetType), a

;       init BLINK

        ld      hl, InitData
.rst2_2
        ld      c, (hl)                         ; port
        inc     hl
        inc     c
        dec     c
        jr      z, rst2_3                       ; end of init data
        ld      a, (hl)                         ; data byte
        inc     hl
        ld      b, 0
        out     (c), a                          ; write blink
        ld      b, $40+BLSC_PAGE                ; softcopy in S1
        ld      (bc), a
        jr      rst2_2

;       copy low RAM code

.rst2_3
        ld      bc, #LowRAMcode_e-LowRAMcode
        ld      de, $4000                       ; destination b20 in S1
        ldir
        ld      a, 1
        ld      ($4000+ubAppCallLevel), a
        ld      a, BM_COMRAMS|BM_COMLCDON
        ld      ($4000+BLSC_COM), a
        out     (BL_COM), a
        ld      sp, $2000                       ; init stack
        ld      b, NUMHANDLES                   ; !! move this ld into ResetHandles
        call    ResetHandles

;       init screen file for unexpanded machine

        ld      b, LORES0_BANK_UNEXP
        ld      h, LORES0_PAGE_UNEXP
        ld      a, SC_LR0
        OZ      OS_Sci                          ; LORES0 at 21:2200-22FF
        ld      b, LORES1_BANK
        ld      h, LORES1_PAGE
        inc     a
        OZ      OS_Sci                          ; LORES1 at 1F:0000-0DFF
        ld      b, HIRES0_BANK_UNEXP
        ld      h, HIRES0_PAGE_UNEXP
        inc     a
        OZ      OS_Sci                          ; HIRES0 at 21:2200-23FF
        ld      b, HIRES1_BANK
        ld      h, HIRES1_PAGE
        inc     a
        OZ      OS_Sci                          ; HIRES1
        ld      b, SBF_BANK
        ld      h, SBF_PAGE
        inc     a
        OZ      OS_Sci                          ; SBF at 20:7800-7FFF - this inits memory

        call    ResetTimeout
        call    InitBufKBD_RX_TX

        ld      a, (ubResetType)                ; print reset string
        or      a
        jr      nz, rst2_4

        call    KPrint
        defm    1,"B"
        defm    "HARD",0
        jr      rst2_5

.rst2_4
        call    KPrint
        defm    1,"T"
        defm    "SOFT",0

.rst2_5
        call    KPrint
        defm    " RESET ...",0

        ld      a, MM_S2|MM_MUL|MM_FIX
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
.rst2_6
        jr      c, rst2_6                       ; crash if no memory

        ld      (pFsMemPool), ix                ; filesystem pool
        jp      Reset3

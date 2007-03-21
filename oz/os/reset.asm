; **************************************************************************************************
; Reset routines, prepare OZ launching after boot.
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

        Module Reset

        include "blink.def"
        include "memory.def"
        include "screen.def"
        include "sysvar.def"
        include "director.def"
        include "serintfc.def"
        include "syspar.def"
        include "time.def"
        include "lowram.def"

xdef    Reset                                   ; bank0/boot.asm
xdef    ExpandMachine                           ; bank0/cardmgr.asm

xref    InitBufKBD_RX_TX                        ; bank0/buffer.asm
xref    MS1BankA                                ; bank0/misc5.asm
xref    KPrint                                  ; bank0/misc5.asm
xref    ResetHandles                            ; bank0/handle.asm
xref    ResetTimeout                            ; bank0/nmi.asm
xref    InitRAM                                 ; bank0/memory.asm
xref    MarkSwapRAM                             ; bank0/memory.asm
xref    MarkSystemRAM                           ; bank0/memory.asm
xref    MountAllRAM                             ; bank0/memory.asm
xref    Chk128KB                                ; bank0/memory.asm
xref    FirstFreeRAM                            ; bank0/memory.asm
xref    OSSp_PAGfi                              ; bank0/pagfi.asm
xref    IntSecond                               ; bank0/int.asm

xref    RAMxDOR                                 ; bank7/misc1.asm
xref    RstRdPanelAttrs                         ; bank7/spnq1.asm
xref    InitKbdPtrs                             ; bank7/spnq1.asm
xref    InitData                                ; bank7/initdata.asm
xref    TimeReset                               ; bank7/timeres.asm

;       ----

.Reset                                          ; called by boot.asm
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

.soft_reset                                     ; On soft reset, only reset B20
        dec     a
        out     (BL_SR1), a
        ld      bc, [sysvar_area_presv-1]
        ld      de, $4001                       ; [0000-sysvar_area] is overwritten by lowram.bin
        ld      hl, $4000
        ld      (hl), 0
        ldir
        ld      bc, [$3FFF-sysvar_area_presv_end]
        ld      de, $4000 | sysvar_area_presv_end+1
        ld      hl, $4000 | sysvar_area_presv_end
        ld      (hl), 0
        ldir
        jr      continue_reset

.b20_hard_reset
        ld      bc, $3FFF                       ; fill bank with 00
        ld      de, $4001
        ld      hl, $4000
        out     (BL_SR1), a                     ; bind A into S1
        ld      (hl), 0
        ldir
        dec     a
        cp      $20
        jr      z, b20_hard_reset               ; loop if hard reset
.continue_reset
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

;       copy low RAM code and install it in lower 8K of segment 0
.rst2_3
        ld      a, OZBANK_MTH
        out     (BL_SR3), a                     ; bind MTH bank into S3
        ld      bc, #LowRAMcode_end - LowRAMcode
        ld      hl, LOWRAM_CODE                 ; and copy LOWRAM code into
        ld      de, $4000                       ; destination b20 in S1
        ldir
        ld      a, OZBANK_KNL0
        out     (BL_SR3), a                     ; restore KNL0 bank

        ld      a, 1
        ld      ($4000+ubAppCallLevel), a
        ld      a, BM_COMRAMS|BM_COMLCDON
        ld      ($4000+BLSC_COM), a
        out     (BL_COM), a                     ; install LOWRAM in lower 8K of segment 0
        ld      sp, $2000                       ; init stack
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
        call    InitRAM
        ld      d, $20
        ld      bc, $10
        call    MarkSystemRAM                   ; b20, 0000-0fff - system variables
        ld      d, $20
        ld      bc, $1008
        call    MarkSwapRAM                     ; b20, 1000-17ff - swap RAM
        ld      d, $20
        ld      bc, $1808
        call    MarkSystemRAM                   ; b20, 1800-1fff - stack
        ld      d, $20
        ld      bc, $2020
        call    MarkSwapRAM                     ; b20, 2000-3fff - 8KB for bad apps
        ld      d, $21
        ld      bc, $3808
        call    MarkSystemRAM                   ; b21, 3800-3fff - SBF
        ld      d, $21
        ld      bc, $2003
        call    MarkSystemRAM                   ; b21, 2000-22ff - Hires0+Lores0

        call    ExpandMachine                   ; move Lores0/Hires0 and mark more swap RAM if expanded

        ld      a,(ubResetType)
        or      a
        call    nz, PreserveSystemPanel         ; restore preserved system panel values
        call    TimeReset
        call    MountAllRAM

        ld      b, $21
        ld      h, SBF_PAGE
        ld      a, SC_SBR
        OZ      OS_Sci                          ; SBF at 21:7800-7FFF

        ld      l, SI_HRD
        OZ      OS_Si                           ; hard reset serial interface

        call    OSSp_PAGfi                      ; initialize panel values and keymap then serial port
        ei

.infinity
        ld      b, 0                            ; time to enter new Index process!
        ld      ix, 1                           ; first handle
        OZ      OS_Ent                          ; enter an application
        jr      infinity

; *** Reset subroutines ***

.ExpandMachine
        call    Chk128KB
        ret     c                               ; not expanded? exit

        call    FirstFreeRAM                    ; b21/b40 for un-/expanded machine
        add     a, 3                            ; b24/b43
        ld      d,a
        push    de
        ld      bc, $0A
        call    MarkSystemRAM                   ; b24/b43, 0000-09ff - Hires0+Lores0

        pop     bc                              ; B=bank, use C to keep bank through Os_Sci
        ld      c,b

        ld      h, LORES0_PAGE_EXP              ; 8
        ld      a, SC_LR0
        OZ      OS_Sci                          ; LORES0 at $xx 0800

        ld      b,c
        ld      h, HIRES0_PAGE_EXP              ; 0
        ld      a, SC_HR0
        OZ      OS_Sci                          ; HIRES0 at $xx 0000

        ld      d,c
        dec     d
        dec     d
        ld      bc, $80
        jp      MarkSwapRAM                     ; b22/b41, 0000-7fff - 32KB more for bad apps

;       ----

.PreserveSystemPanel
        push    bc
        ld      bc, PA_Loc
        ld      hl, cCountry

.psp_1                                          ; start with PA_Loc ($06) then downward
        ld      a, 1                            ; length is 1 byte for each value
        OZ      OS_Sp                           ; specify parameter
        dec     hl
        dec     c
        jr      nz, psp_1
        pop     bc
        ret

;       ----

.TimeReset
        ld      a, (ubResetType)
        or      a
        jr      z, SetInitialTime               ; hard reset, init system clock
        ld      hl, ubTIM1_A                    ; use timer @ A2 or A7
        ld      a, (ubTimeBufferSelect)         ; depending of bit 0 od A0
        rrca
        jr      nc, tr_1
        ld      l, <ubTIM1_B                    ; $A7
.tr_1
        ld      c, (hl)                         ; ld bhlc, (hl)
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        ex      de, hl

        ld      a, 1                            ; update base time
        OZ      GN_Msc
.tr_2
        jp      IntSecond


.SetInitialTime
        ld      de, $year
        ld      bc, $month<<8 | $day
        OZ      GN_Dei                          ; convert to internal format
        ld      hl, 2                           ; date in ABC
        OZ      GN_Pmd                          ; set machine date according to current date of compilation

        defc elapsedtime_centisecs = $hour*60*60*100 + $minute*60*100 + $second*100

        ld      a, elapsedtime_centisecs/65536
        ld      b, [elapsedtime_centisecs - ((elapsedtime_centisecs/65536) * 65536)] / 256
        ld      c, [elapsedtime_centisecs - ((elapsedtime_centisecs/65536) * 65536)] % 256
        OZ      GN_Pmt                          ; set clock according to current time of compilation
        jr      tr_2

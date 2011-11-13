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
; ***************************************************************************************************

        Module Reset

        include "blink.def"
        include "memory.def"
        include "stdio.def"
        include "screen.def"
        include "sysvar.def"
        include "oz.def"
        include "director.def"
        include "serintfc.def"
        include "syspar.def"
        include "time.def"

        include "lowram.def"

xdef    Reset
xdef    ExpandMachine

xref    InitBufKBD_RX_TX                        ; [K0]/buffer.asm
xref    MS1BankA                                ; [K0]/memmisc.asm
xref    ResetHandles                            ; [K0]/handle.asm
xref    ResetTimeout                            ; [K0]/nmi.asm
xref    InitRAM                                 ; [K0]/memory.asm
xref    MarkSwapRAM                             ; [K0]/memory.asm
xref    MarkSystemRAM                           ; [K0]/memory.asm
xref    MountAllRAM                             ; [K0]/memory.asm
xref    Chk128KB                                ; [K0]/memory.asm
xref    FirstFreeRAM                            ; [K0]/memory.asm
xref    IntSecond                               ; [K0]/int.asm

xref    TimeReset                               ; [K1]/timeres.asm
xref    defDev                                  ; [K1]/spnq1.asm

;       ----

.Reset                                          ; called by boot.asm
        xor     a
        ex      af, af'                         ; interrupt status
        bit     BB_STAFLAPOPEN, a
        ld      a, $21
        jr      nz, b20_hard_reset              ; flap open during reset? Reset bank $21 and $20 during hard reset

        out     (BL_SR1), a                     ; flap not open,
        ld      hl, (MM_S1 << 8)
        ld      bc, $A55A                       ; check RAM tag in bank $21
        or      a
        sbc     hl, bc
        jr      nz, b20_hard_reset              ; not tagged? hard reset if memory is not partitioned

        ex      af, af'                         ; soft reset - a' = $FF, fc'=1
        cpl
        scf
        ex      af, af'

.soft_reset                                     ; On soft reset, only reset B20
        dec     a
        out     (BL_SR1), a
        ld      bc, [sysvar_area_presv-1]
        ld      de, MM_S1 << 8 | $01            ; [0000-sysvar_area] is overwritten by lowram.bin
        ld      hl, MM_S1 << 8
        ld      (hl), 0
        ldir
        ld      bc, [$3FFF-sysvar_area_presv_end]
        ld      de, MM_S1 << 8 | sysvar_area_presv_end+1
        ld      hl, MM_S1 << 8 | sysvar_area_presv_end
        ld      (hl), 0
        ldir
        jr      continue_reset

.b20_hard_reset
        ld      bc, $3FFF                       ; fill banks $21 and $20 with 00
        ld      de, MM_S1 << 8 | $01
        ld      hl, MM_S1 << 8
        out     (BL_SR1), a                     ; bind A into S1
        ld      (hl), 0
        ldir
        dec     a
        cp      $20
        jr      z, b20_hard_reset               ; loop if hard reset
.continue_reset
        ex      af, af'
        ld      (MM_S1 << 8 + ubResetType), a

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
        ld      a, OZBANK_LOWRAM
        out     (BL_SR3), a                     ; bind MTH bank into S3
        ld      bc, #LowRAMcode_end - LowRAMcode
        ld      hl, LOWRAM_CODE                 ; and copy LOWRAM code into
        ld      de, MM_S1 << 8                  ; destination b20 in S1
        ldir
        ld      a, OZBANK_KNL0
        out     (BL_SR3), a                     ; restore KNL0 bank

        ld      a, 1
        ld      ($4000+ubAppCallLevel), a
        ld      a, BM_COMRAMS|BM_COMLCDON
        ld      (MM_S1 << 8 + BLSC_COM), a
        out     (BL_COM), a                     ; install LOWRAM in lower 8K of segment 0
        ld      sp, $2000                       ; init stack

        ld      bc, OZBANK_KNL0<<8 | OZBANK_KNL1; define soft copy of current kernel bank bindings
        ld      (BLSC_SR2),bc                   ; because they are used by OZ call interface..

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

        OZ      OS_Pout
        defm    1,"B"
        defm    "HARD",0
        jr      rst2_5

.rst2_4
        OZ      OS_Pout
        defm    1,"T"
        defm    "SOFT",0

.rst2_5
        OZ      OS_Pout
        defm    " RESET ...",0

        ld      a, MM_S2 | MM_MUL | MM_FIX
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
        ld      bc, SV_SWAP_RAM | SV_SWAP_RAM_PAGES
        call    MarkSwapRAM                     ; b20, 1000-17ff - swap RAM
        ld      d, $20
        ld      bc, SV_PROCESS_RAM | SV_PROCESS_RAM_PAGES
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

        ld      hl,defDev
        ld      de,$1800                        ; use bottom of stack for temp. work space...
        push    de
        ld      bc,6
        ldir
        dec     de                              ; point at device number

        call    Chk128KB                        ; get bottom bank of expanded RAM card..
        pop     hl
        jr      c, install_panel_defaults       ; no expanded RAM were found
        and     $c0
        rlca
        rlca
        or      $30
        ld      (de),a                          ; define default expanded RAM card slot number

        ld      a,6
        ld      bc,PA_Dev
        oz      os_sp                           ; install new default RAM device

.install_panel_defaults
        ld      bc, PA_Gfi
        OZ      OS_Sp                           ; initialize panel, serial port and printer

        ei

.infinity
        ld      b, 0                            ; time to enter new application
IF !OZ_SLOT1
        ld      ix, $01                         ; first handle (in slot 0, identified with slot mask $00)
ELSE
        ld      ix, $41                         ; first handle (in slot 1, identified with slot mask $40)
ENDIF
        OZ      OS_Ent                          ; enter new Index process!
        jr      infinity

; *** Reset subroutines ***

.ExpandMachine
        call    Chk128KB
        ret     c                               ; not expanded? exit
        add     a, 3                            ; b24/b43/b83
        ld      d,a
        push    de
        ld      bc, $0A
        call    MarkSystemRAM                   ; b24/b43/b83, 0000-09ff - Hires0+Lores0

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
        ld      hl, ubTIM1_A                    ; use primary HW clock
        ld      a, (ubTimeBufferSelect)         ; if bit 7 reset
        rrca
        jr      nc, tr_1
        ld      l, <ubTIM1_B                    ; else use secundary HW clock
.tr_1
        ld      c, (hl)                         ; seconds
        inc     hl
        ld      e, (hl)                         ; minutes
        inc     hl
        ld      d, (hl)                         ; minutes * 256
        inc     hl
        ld      b, (hl)                         ; minutes * 65536
        ex      de, hl

        ld      a, MT_UBT                       ; update base time
        OZ      GN_Msc                          ; maintain time over a soft reset
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

.InitData
        defb    BL_SR2, OZBANK_KNL1                ; SR2 = kernel bank 1
        defb    BL_TMK, BM_TACKTICK|BM_TACKSEC|BM_TACKMIN
        defb    BL_INT, BM_INTFLAP|BM_INTBTL|BM_INTTIME|BM_INTGINT
        defb    BL_TACK, BM_TMKTICK|BM_TMKSEC|BM_TMKMIN
        defb    BL_ACK, BM_ACKA19|BM_ACKFLAP|BM_ACKBTL|BM_ACKKEY
        defb    BL_EPR, 0                       ; reset EPROM port
        defb    0
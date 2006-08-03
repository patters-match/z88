; **************************************************************************************************
; External Card Management (in slots 1-3).
; The routines are located in Bank 0.
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

        Module CardMgr

        include "blink.def"
        include "sysvar.def"

xdef    AddRAMCard
xdef    IntFlap

xref    Delay300Kclocks                         ; bank0/misc3.asm
xref    ExpandMachine                           ; bank0/reset13.asm
xref    InitSlotRAM                             ; bank0/memory.asm
xref    MountAllRAM                             ; bank0/resetx.asm
xref    MS12BankCB                              ; bank0/misc5.asm
xref    MS2BankK1                               ; bank0/misc5.asm
xref    NMIMain                                 ; bank0/nmi.asm

xref    ChkCardChange                           ; bank7/card1.asm
xref    StoreCardIDs                            ; bank7/card1.asm


.IntFlap
        ld      bc, (BLSC_SR1)                  ; remember S1/S2
        push    bc
        exx
        push    bc
        push    de
        push    hl
        call    MS2BankK1
        call    StoreCardIDs

        ld      a, (BLSC_COM)                   ; beep
        or      BM_COMSRUN
        out     (BL_COM), a

.intf_1
        push    af
        call    Delay300Kclocks
        ld      a, BM_INTFLAP                   ; ack flap
        out     (BL_ACK), a
        in      a, (BL_STA)
        bit     BB_STAFLAPOPEN, a               ; !! add a; call c,...
        call    nz, NMIMain                     ; halt until flap closed?

        pop     af
        jr      nc, intf_2

        ld      a, (BLSC_COM)                   ; beep
        or      BM_COMSRUN
        out     (BL_COM), a
.intf_2
        call    ChkCardChange
        jr      c, intf_1                       ; go back

        ld      a, (BLSC_COM)                   ; restore BL_COM
        out     (BL_COM), a
        pop     hl
        pop     de
        pop     bc
        exx
        pop     bc                              ; restore S1/S2
        jp      MS12BankCB

;       ----

.AddRAMCard
        call    InitSlotRAM
        push    af
        call    MS2BankK1
        pop     af
        cp      $40
        call    z, ExpandMachine                ; slot1? expand if 128KB or more
        call    MountAllRAM
        jp      MS2BankK1                       ; restore S2 before returning there

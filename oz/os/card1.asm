; **************************************************************************************************
; External Card Management (in slots 1-3).
; The routines are located in Kernel 1.
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
; ***************************************************************************************************

        Module Card1

        include "director.def"
        include "memory.def"
        include "sysvar.def"

xdef    StoreCardIDs
xdef    ChkCardChange

xref    AddRAMCard                              ; [Kernel0]/cardmgr.asm
xref    MS1BankA                                ; [Kernel0]/misc5.asm
xref    S2VerifySlotType                        ; [Kernel0]/misc5.asm
xref    DrawOZwd                                ; [Kernel0]/ozwindow.asm
xref    OZwd__fail                              ; [Kernel0]/ozwindow.asm
xref    OZwd_card                               ; [Kernel0]/ozwindow.asm
xref    OZwd_index                              ; [Kernel0]/ozwindow.asm


;       ----

;       read application card IDs into RAM

.StoreCardIDs
        call    CardSub

.scid_1
        push    de
        ld      a, d                            ; map in last bank in slot D
        rrca
        rrca
        or      $3F
        call    MS1BankA
        exx                                     ; clear ID
        xor     a
        ld      b, a
        ld      c, a
        ld      d, a
        ld      e, a
        exx
        call    S2VerifySlotType
        bit     BU_B_ROM, d                     ; application rom flag
        exx
        jr      z, scid_2                       ; not application rom? skip

        ld      bc, ($7FF8)                     ; read card ID into debc'
        ld      de, ($7FFA)

.scid_2
        dec     hl                              ; store ID
        ld      (hl), d
        dec     hl
        ld      (hl), e
        dec     hl
        ld      (hl), b
        dec     hl
        ld      (hl), c
        exx

        pop     de
        dec     d
        jr      nz, scid_1
        ret

;       ----

;       check if cards were changed, act accordingly

.ChkCardChange
        call    CardSub

.ccc_1
        push    de
        ld      a, d                            ; bind in last bank in slot D
        rrca
        rrca
        or      $3F
        call    MS1BankA
        exx                                     ; read previous slotID into debc'
        dec     hl
        ld      d, (hl)
        dec     hl
        ld      e, (hl)
        dec     hl
        ld      b, (hl)
        dec     hl
        ld      c, (hl)
        push    hl
        exx
        call    S2VerifySlotType
        bit     BU_B_ROM, d
        jr      z, ccc_8                        ; not appl card? skip

        exx                                     ; compare IDs
        ld      hl, ($7FF8)
        or      a
        sbc     hl, bc
        exx
        jr      nz, ccc_diff                    ; not same card
        exx
        ld      hl, ($7FFA)
        sbc     hl, de
        exx
        jr      z, ccc_same                     ; same card

.ccc_diff
        exx
        ld      a, d
        or      e
        or      b
        or      c
        exx
        jr      z, ccc_insert                   ; previously empty, just signal Index

.ccc_3
        ld      hl, ubIdxPubFlags
        bit     IDXF1_B_INSIDEOZ, (hl)
        jr      nz, ccc_4                       ; we can handle it now
        call    OZwd_index                      ; otherwise show "index" in OZ window
        jr      ccc_6

.ccc_4
        pop     hl
        pop     de
        push    de
        push    hl
        ld      a, d                            ; slot
        rrca
        rrca
        and     $C0
        ld      c, a                            ; slot base
        ld      a, d
        exx
        push    bc                              ; remember ID
        push    de
        push    hl                              ; !! is this necessary?
        exx
        OZ      DC_Pol                          ; Poll for card usage
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        jr      nz, ccc_5                       ; card was active? show "card"

        ld      a, (pMTHHelpHandle+1)
        or      a
        jr      z, ccc_insert
        ld      ix, (pMTHHelpHandle)
        ld      a, (ix+$0D)                     ; check if slot matches
        and     $C0
        cp      c
        jr      nz, ccc_insert

.ccc_5
        call    OZwd_card                       ; show "card" in OZ window

.ccc_6
        pop     hl
        pop     hl
        scf
        ret

.ccc_insert
        ld      hl, ubIdxPubFlags               ; tell Index to re-read application letters
        set     IDXF1_B_INIT, (hl)
        jr      ccc_same

.ccc_8
        exx                                     ; if we had card earlier see if it was in use
        ld      a, d
        or      e
        or      b
        or      c
        exx
        jr      nz, ccc_3

.ccc_same
        pop     hl
        pop     de
        push    de
        push    hl
        ld      a, d                            ; bind first bank in S1
        rrca
        rrca
        and     $C0
        call    MS1BankA
        ld      hl, $4000                       ; test for RAM
        ld      c, (hl)
        ld      a, c
        cpl
        ld      (hl), a
        xor     (hl)                            ; Fz=1 if RAM
        ld      (hl), c
        inc     hl
        ld      b, (hl)
        jr      z, ccc_ram                      ; RAM? verify it's tagged
        pop     hl
        pop     de
        push    de
        push    hl
        ld      c, d                            ; check there was no RAM earlier
        ld      b, 0
        ld      hl, ubSlotRamSize
        add     hl, bc
        ld      a, (hl)
        or      a
        jr      nz, ccc_fail                    ; RAM card removed? fail
        jr      ccc_next

.ccc_ram
        ld      hl, $A55A
        sbc     hl, bc
        jr      z, ccc_next                     ; tagged? skip

        pop     hl
        pop     de
        push    de
        push    hl
        ld      c, d
        ld      b, 0
        ld      hl, ubSlotRamSize
        add     hl, bc
        ld      a, (hl)
        or      a
        jr      nz, ccc_fail                    ; RAM card replaced? fail
        pop     hl
        pop     de
        push    de
        push    hl
        ld      a, d                            ; go add RAM in slot D
        rrca
        rrca
        and     $C0
        call    AddRAMCard

.ccc_next
        exx
        pop     hl
        exx
        pop     de
        dec     d
        jp      nz, ccc_1
        call    DrawOZwd
        or      a
        ret

.ccc_fail
        ei
        jp      OZwd__fail

;       ----

.CardSub
        ld      de, 3<<8|$3F                    ; 3 loops, max card size
        exx
        ld      hl, ulSlot3ID+4
        exx
        ret

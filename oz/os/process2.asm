; **************************************************************************************************
; OZ Process functionality. The routines are located in Kernel 0.
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


        Module  Process2

        include "director.def"
        include "dor.def"
        include "error.def"
        include "memory.def"
        include "sysvar.def"
        include "oz.def"

;       mostly bad application memory routines

xdef    AllocBadRAM1
xdef    BadAllocAndSwap
xdef    BadSwapAndFree
xdef    FreeBadRAM
xdef    IsBadUgly
xdef    NQAin
xdef    OSDom
xdef    sub_C2F3
xdef    sub_C39F

xref    Chk128KB                                ; [Kernel0]/memory.asm
xref    Chk128KBslot0                           ; [Kernel0]/memory.asm
xref    FollowPageN                             ; [Kernel0]/memory.asm
xref    MarkPageAsAllocated                     ; [Kernel0]/memory.asm
xref    MATPtrToPagePtr                         ; [Kernel0]/memory.asm
xref    PageNToPagePtr                          ; [Kernel0]/memory.asm
xref    fsMS2BankB                              ; [Kernel0]/filesys3.asm
xref    fsRestoreS2                             ; [Kernel0]/filesys3.asm
xref    GetAppDOR                               ; [Kernel0]/mth0.asm
xref    OSBixS1                                 ; [Kernel0]/stkframe.asm
xref    OSBoxS1                                 ; [Kernel0]/stkframe.asm
xref    MS1BankA                                ; [Kernel0]/memmisc.asm
xref    MS2BankA                                ; [Kernel0]/memmisc.asm
xref    PutOSFrame_BHL                          ; [Kernel0]/memmisc.asm
xref    PutOSFrame_DE                           ; [Kernel0]/memmisc.asm

xref    CopyMTHApp_Help                         ; [Kernel1]/mth1.asm

defc    FREE_THIS       =7

;       ----

;IN:    IX=application ID
;OUT:   application data: A=flags, C=key, BHL=name, BDE=DOR

.NQAin
        push    ix
        pop     bc
        ld      a, c                            ; <IX
        call    GetAppDOR
        ld      a, RC_Hand
        jr      c, nqain_x                      ; not found? exit

        ex      de, hl
        call    PutOSFrame_DE                   ; appl DOR
        ld      hl, ADOR_NAME
        add     hl, de
        call    PutOSFrame_BHL                  ; application name

        ex      de, hl                          ; bind in BHL
        call    OSBixS1

        push    ix
        push    hl                              ; IX=HL
        pop     ix
        ld      a, (ix+ADOR_FLAGS)
        ld      (iy+OSFrame_A), a               ; flags1 - good, bad, ugly etc
        ld      a, (ix+ADOR_APPKEY)
        ld      (iy+OSFrame_C), a               ; code letter
        pop     ix

        call    OSBoxS1
        or      a
.nqain_x
        jp      CopyMTHApp_Help                 ; copy app pointers over help pointers

;       ----

.OSDom
        ld      a, MM_S1|MM_MUL|MM_FIX
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
        ret

;       ----

.AllocBadRAM1
        call    IsBadUgly
        ret     z                               ; nice? exit with Fc=0
        ld      a, (ubAppContRAM)
        or      a
        jr      nz, acr_1

        ld      a, (ubBadSize)                  ; default bad process size in kb
        add     a, a                            ; translate into pages, max 160 pages
        jr      c, acr_2
        add     a, a
        jr      c, acr_2
.acr_1
        cp      40*4                            ; max 160 pages, 40 KB
        jr      c, acr_3
.acr_2
        ld      a, 40*4

.acr_3
        ld      b, a                            ; remember size
        call    Chk128KB
        ld      c, a                            ; remember bank

        call    Chk128KB                        ; limit size to 32 pages on unexpanded machine
        ld      a, b
        jr      nc, acr_4
        cp      8*4
        jr      c, acr_4
        ld      a, 8*4
.acr_4
        ld      (ubAppContRAM), a
        add     a, 8*4                          ; 8K more
        ld      (ubBadInfoEndPage), a

;       set bindings as needed

        ld      hl, ubAppBindings
        ld      (hl), $21                       ; S0 b20 upper half - first 8KB of bad app RAM
        cp      16*4
        jr      c, acr_5                        ; less than 16KB? done
        inc     hl
        inc     c
        ld      (hl), c                         ; 16KB more in seg1
        cp      32*4
        jr      c, acr_5                        ; less than 32KB? done
        inc     hl
        inc     c
        ld      (hl), c                         ; total 40KB

.acr_5
        push    ix
        ld      a, MM_S1|MM_MUL|MM_FIX
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool
        jr      c, acr_x                        ; error? exit
        ld      (pAppBadMemHandle), ix

        call    AllocBadRAM2
        call    c, FreeBadRAM                   ; didn't get all RAM needed? free what we got

.acr_x
        pop     ix
        ret

;       ----

.FreeBadRAM
        push    af
        call    IsBadUgly
        jr      z, fcr_x                        ; nice? exit

        push    ix
        ld      ix, (pAppBadMemHandle)          ; free all bad app memory
        OZ      OS_Mcl
        pop     ix

.fcr_x
        pop     af
        ret

;       ----

.BadAllocAndSwap
        call    IsBadUgly
        ret     z                               ; nice? exit
        call    AllocBadRAM2

;       swap all memory between swap banks and IY table

.BadSwapAll
        push    af
        call    BadSetup

;       do until b=0

.bsa_1
        push    bc
        push    hl

        call    sub_C3F8                        ; ld a,bank; cp 1
        jr      c, bsa_3                        ; bank zero? skip
        jr      z, bsa_3                        ; bank 1? skip
        call    FollowPageN
        jr      nz, bsa_2                       ; part of chain, don't tag

        call    MarkPageAsAllocated
        set     FREE_THIS, (iy+0)

;       swap memory between AHL=MATPtr and page pointed by IY

.bsa_2
        call    MATPtrToPagePtr
        call    CopyPageFromAH0                 ; copy into stack buffer
        push    af
        push    hl
        call    GetPageAndBank
        or      a                               ; Fc=0, copy HL -> DE
        call    CopyPage                        ; copy after first page
        call    CopyPageToAH0                   ; then copy first over the second
        pop     hl
        pop     af
        scf                                     ; Fc=1, copy DE -> HL
        call    CopyPage                        ; copy second page over the first one

.bsa_3
        call    BadAdvance
        jr      nz, bsa_1                       ; not done? loop

        call    BadRestore
        pop     af
        ret

;       ----

.sub_C2F3
        xor     a
        ld      b, a
        ld      c, a
        ld      d, a
        ld      e, a

;       ----

.BadSwapAndFree
        call    IsBadUgly
        ret     z
        push    bc
        push    de
        call    BadSwapAll
        pop     af
        pop     bc
        ld      hl, $FF
        add     hl, bc
        ld      e, h

.bsf_1
        sub     e
        ret     z
        ret     c
        call    BadSetup
        ld      c, a
        add     a, e
        sub     l
        ld      b, a

.bsf_2
        push    bc
        push    hl

        ld      a, c
        cp      b
        jr      c, bsf_4
        call    sub_C3F8                        ; ld a,bank; cp 1
        jr      c, bsf_4                        ; bank 0? don't free

        call    nz, GetPageAndBank              ; bank>1? get page too
        call    z, PageNToPagePtr               ; bank=1? convert HL into ptr
        ld      bc, $100
        ld      l, c                            ; L=0
        OZ      OS_Mfr                          ; Free page AH0
        jr      c, $PC                          ; error? crash
        ld      (iy+1), c                       ; clear bank

.bsf_4
        call    BadAdvance
        jr      nz, bsf_2                       ; not done? loop
        call    BadRestore
        ret

;       ----

.AllocBadRAM2
        call    BadSetup
.abr2_1
        push    bc
        push    hl

        call    sub_C3F8
        jr      nc, abr2_6

        call    FollowPageN
        jr      nz, abr2_2                      ; part of chain? skip

        call    MarkPageAsAllocated
        ld      h, 0                            ; page=0
        ld      a, 1                            ; bank=1
        jr      abr2_3

.abr2_2
        xor     a                               ; allocate new page
        ld      bc, $100
        OZ      OS_Mal
        jr      c, abr2_7                       ; error? exit
        ld      a, b                            ; bank

.abr2_3
        pop     de
        pop     bc
        inc     c
        dec     c
        jr      nz, abr2_5                      ; not zero? skip

        push    af
        ld      a, (ubAppContRAM)
        sub     b
        cp      8*4                             ; below 8KB of bad app RAM
        call    nc, Chk128KBslot0               ; yes? Fc=0 if slot 0 expanded
        ld      a, e
        jr      c, abr2_4                       ; <8KB or slot 1 expanded
        sub     $40                             ; skip b21
.abr2_4
        ld      c, a
        pop     af
.abr2_5
        push    bc
        push    de
        ld      (iy+0), h                       ; remember page
        ld      (iy+1), a                       ; and bank

.abr2_6
        call    BadAdvance
        jr      nz, abr2_1                      ; not done yet? loop

        or      a                               ; Fc=0
        jr      abr2_8

.abr2_7
        pop     hl
        pop     de

        push    af
        ld      a, (ubAppContRAM)
        sub     d
        add     a, $20
        inc     e
        dec     e
        call    nz, bsf_1                       ; free all allocated blocks
        pop     af

;       clear all flags in table

.abr2_8
        ld      bc, (ubAppContRAM-1)            ; ld b,(ubAppContRAM)
        ld      hl, (pAppBadMemTable)
.abr2_9
        res     FREE_THIS, (hl)
        inc     hl
        inc     hl
        djnz    abr2_9

        call    BadRestore
        ret

;       ----

;       E=0 - free each page from table

.sub_C39F
        call    IsBadUgly
        ret     z
        call    BadSetup
        ld      c, e
.u1_1
        push    bc
        push    hl

        bit     FREE_THIS, (iy+0)
        jr      z, u1_3                         ; flag=0? skip

        call    PageNToPagePtr
        inc     c
        dec     c
        call    z, GetPageAndBank               ; free each page
        ld      bc, $100
        ld      l, c
        OZ      OS_Mfr                          ; free page AH0
        jr      c, $PC                          ; crash

        ld      (iy+0), c                       ; 0
        ld      (iy+1), 1

.u1_3
        call    BadAdvance
        jr      nz, u1_1
        call    BadRestore
        ret

;       ----

.CopyPageFromAH0
        or      a
        jr      copy

.CopyPageToAH0
        scf
.copy   ld      de, (pStkTempStkTop)

; copy 256 bytes
;
; IN: A=MS1 bank
; Fc=0 - copy HL -> DE
; Fc=1 - copy DE -> HL
;
; OUT: DE advanced by 256 bytes

.CopyPage
        call    MS1BankA
        ld      bc, $100
        ld      l, c
        push    af
        push    bc
        push    hl

        jr      nc, cpg_1                       ; Fc=1? copy DE->HL
        ex      de, hl
.cpg_1
        ldir
        jr      nc, cpg_2
        ex      de, hl

.cpg_2
        pop     hl
        pop     bc
        pop     af
        ret

;       ----

.IsBadUgly
        ld      a, (ubAppDORFlags)
        and     AT_BAD|AT_UGLY
        ret

;       ----
.GetPageAndBank
        ld      h, (iy+0)                       ; page
        res     FREE_THIS, h

.sub_C3F8
        ld      a, (iy+1)                       ; bank
        cp      1                               ; Fc=1 if A=0
        ret

;       ----

;       push ix-iy-S1/S2, bind b21 into S2, return with HL=$20

.BadSetup
        pop     hl                              ; return address
        push    ix
        push    iy
        ld      bc, (ubSlotRAMoffset-1)         ; ld b,(ubSlotRAMoffset)
        inc     b                               ; $21 always?
        call    fsMS2BankB                      ; remember S1/S2 and do MS2BankB
        ld      bc, (ubAppContRAM-1)            ; ld b,(ubAppContRAM)
        ld      c, 0
        ld      ix, (pAppBadMemHandle)
        ld      iy, (pAppBadMemTable)
        jr      loc_C423

;       undo previous

.BadRestore
        pop     hl                              ; return address
        call    fsRestoreS2
        pop     iy
        pop     ix

.loc_C423
        push    hl                              ; return address
        ld      hl, $20
        ret

;       ----

.BadAdvance
        pop     de                              ; return address

        inc     iy                              ; next entry in table
        inc     iy

        pop     hl                              ; PageN
        pop     bc
        inc     hl
        ld      a, l
        cp      $40
        jr      c, badv_1                       ; still in b20 SWAP area? skip

        call    Chk128KB
        call    MS2BankA                        ; bind first RAM bank in S2
        cp      $40
        jr      z, badv_1                       ; slot 1
        ld      a, l
        cp      $40
        jr      nz, badv_1
        ld      l, $80                          ; skip b21
.badv_1
        dec     b                               ; decrement page count
        push    de                              ; return address
        ret

;       ----



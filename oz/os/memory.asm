; **************************************************************************************************
; Memory Management Interface.
; The routines are located in Kernel 0.
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

        Module Memory


        include "blink.def"
        include "dor.def"
        include "error.def"
        include "memory.def"
        include "stdio.def"
        include "handle.def"
        include "sysvar.def"
        include "card.def"

        include "lowram.def"

xdef    FollowPageN
xdef    InitRAM
xdef    InitSlotRAM
xdef    MarkPageAsAllocated
xdef    MarkSwapRAM
xdef    MarkSystemRAM
xdef    MATPtrToPagePtr
xdef    OSAxp
xdef    OSFc
xdef    OSMal
xdef    OSMalMain
xdef    OsMcl
xdef    OSMclMain
xdef    OSMfr
xdef    OSMfrMain
xdef    OSMgb
xdef    OSMop
xdef    OSMopMain
xdef    OSMpb
xdef    OSSp_89
xdef    PageNToPagePtr
xdef    VerifySlotType
xdef    Chk128KB
xdef    Chk128KBslot0
xdef    MountAllRAM                             ; [Kernel0]/cardmgr.asm, [Kernel1]/misc1.asm

xref    MS2BankK1                               ; [Kernel0]/misc5.asm
xref    MS1BankA                                ; [Kernel0]/misc5.asm
xref    MS2BankA                                ; [Kernel0]/misc5.asm
xref    PutOSFrame_BHL                          ; [Kernel0]/misc5.asm
xref    PutOSFrame_DE                           ; [Kernel0]/misc5.asm
xref    OSFramePop                              ; [Kernel0]/misc4.asm
xref    OSFramePush                             ; [Kernel0]/misc4.asm
xref    AllocHandle                             ; [Kernel0]/handle.asm
xref    FreeHandle                              ; [Kernel0]/handle.asm
xref    VerifyHandle                            ; [Kernel0]/handle.asm
xref    AddAvailableFsBlock                     ; [Kernel0]/filesys3.asm
xref    FilePtr2MemPtr                          ; [Kernel0]/filesys3.asm
xref    MemPtr2FilePtr                          ; [Kernel0]/filesys3.asm
xref    OZwd__fail                              ; [Kernel0]/ozwindow.asm

xref    MemCallAttrVerify                       ; [Kernel1]/memory1.asm
xref    RAMxDOR                                 ; [Kernel1]/misc1.asm

defc    DM_RAM                  =$81

;       ----

;IN:    A=flags, C=slot/bank (if MM_B_SLT set in A)
;OUT:   IX=MemHandle

.OSMopMain
        ld      a, HND_MEM
        call    AllocHandle
        ret     c                               ; no handle? exit

        ld      a, (iy+OSFrame_A)
        ld      (ix+mhnd_AllocFlags), a

;       set ExlusiveBank range if required !! not documented

        bit     MM_B_SLT, a
        jr      z, osmop_1
        ld      (ix+mhnd_ExclusiveBank), c

;       set ExlusiveBank unless multiple banks required

.osmop_1
        bit     MM_B_MUL, (ix+mhnd_AllocFlags)  ; use multiple banks  !! bit n,A
        call    z, SetExlusiveBank

        cp      a                               ; Fc=0
        ret

;       ----

.OSMclFail
        jr      MemFail1                        ; !! remove this, use direct jp

;IN:    IX=MemHandle
;OUT:   Fc=0 if no error

.OSMclMain
        ld      a, HND_MEM
        call    VerifyHandle
        ret     c                               ; bad handle? exit


        ld      a, 4                            ; do slots 3-0
.osmcl_1
        dec     a                               ; decrement slot
        push    af                              ; and remember it

        push    iy
        call    MS2SlotMAT                      ; bind slot MAT in S2
        pop     iy
        jr      c, osmcl_3                      ; no RAM? skip slot

        call    GetMhndSlotAlloc                ; get allocation chain for this slot
        jr      z, osmcl_3                      ; no mem from this slot? skip it

;       free all memory allocated from this slot

.osmcl_2
        ex      de, hl                          ; HL=MAT entry
        call    PageNToMATPtr                   ; point HL to allocation MAT entry

        ld      e, (hl)                         ; DE=next entry
        inc     l
        ld      a, (hl)
        dec     l
        bit     MAT_B_LAST, a                   ; remember last_flag
        push    af
        and     $0f                             ; remove flags
        ld      d, a

        call    MarkPageFreeMATptr              ; mark page HL as free

        pop     af                              ; restore last_flag
        jr      z, osmcl_2                      ; not last? free next

        ex      de, hl                          ; next*16 should be MemHandle
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        push    ix                              ; does it match?
        pop     de
        or      a
        sbc     hl, de
        jr      nz, OSMclFail                   ; nope? fail as we just freed unknown memory

.osmcl_3
        pop     af                              ; restore slot
        jr      nz, osmcl_1                     ; was not 0? loop

        ld      a, HND_MEM
        jp      FreeHandle

;       ----

.MemFail1
        jp      OZwd__fail

;       ----

;IN:    A=slot, 1-3
;       BC=allocation size, max. 256 bytes
;       IX=MemHandle
;OUT:   Fc=0 - BHL=memory, C=segment
;       Fc=1, A=error if failed

.OSMalMain
        call    MemCallAttrVerify
        ret     c                               ; bad size? exit
        jr      z, osmal_page                   ; size=256? allocate whole page


;       allocate partial page
;       first   we check previously allocated pages for big enough chunk

        ld      a, 3                            ; slot 3-2-1-0

.osmal_chk1
        push    af

        push    iy
        call    MS2SlotMAT                      ; bind slot MAT in S2
        pop     iy
        jr      c, osmal_chk4                   ; no RAM in slot? skip slot

        call    GetMhndSlotAlloc                ; MATentry in DE
        jr      z, osmal_chk4                   ; no allocations from this slot? skip slot

        ex      de, hl                          ; HL=MatEntry, DE=ptr to it
.osmal_chk2
        call    PageNToMATPtr

        inc     l
        bit     MAT_B_FULL, (hl)
        dec     hl                              ; !! dec l
        jr      nz, osmal_chk3                  ; non-splitted? skip page

        call    MATPtrToPagePtr         ; point HL to this page
        call    MS1BankA                        ; and bind it in

;       !! validate page inside AllocChunk - full chunk list traversing can be put
;       !! into good use by allocating from smallest possible chunk inside page
;       !! to   reduce fragmentation. Post-allocation validate is unnecessary.

        call    ValidatePage
        jr      c, MemFail1                     ; invalid? crash

        ld      c, (iy+OSFrame_C)               ; size, possibly fixed in MemCallAttrVerify
        push    de                              ; ptr to MATentry
        call    AllocChunk                      ; HL=memory if succesfull
        push    af

        push    hl
        call    ValidatePage                    ; !! unnecessary
        pop     hl
        jr      c, MemFail1

        pop     af
        pop     de
        jr      nc, osmal_chkok                 ; got chunk

        ex      de, hl                          ; HL=MATptr
.osmal_chk3
        call    FollowMATPtr                    ; get pointer to next
        jp      z, OZwd__fail

        ld      a, d                            ; HL=MAToffset(DE)
        and     $0F                             ; remove flags
        ld      h, a
        ld      l, e

        bit     MAT_B_LAST, d
        jr      z, osmal_chk2                   ; not last? try next page

.osmal_chk4
        pop     af                              ; try previous slot
        dec     a
        jp      p, osmal_chk1

;       ok, we couldn't allocate chunk from previously allocated pages.
;       allocate new page and allocate from it.

        call    osmal_AllocPage                 ; allocate new page - HL=MATEntryPtr
        ret     c                               ; no mem? exit

        inc     l                               ; mark page as splitted
        res     MAT_B_FULL, (hl)
        dec     l

        call    MATPtrToPagePtr         ; point HL to page
        call    MS1BankA                        ; and bind it in

        ld      (hl), 1                         ; first chunk at H01
        inc     l
        ld      (hl), $FF                       ; chunk size, 255 bytes
        inc     l
        ld      (hl), 0                         ; no more chunks
        dec     l
        dec     l

        call    ValidatePage                    ; !! unnecessary, can't fail
        jr      c, MemFail1

        ld      c, (iy+OSFrame_C)
        call    AllocChunk                      ; !! could do first allocation here, it's simple
        jr      c, MemFail1                     ; !! unnecessary, can't fail

        push    bc                              ; !! defb OP_LDAn

.osmal_chkok
        pop     bc                              ; fix stack
        ld      a, (BLSC_SR1)                   ; get bank
        jr      osmal_ok                        ; and return

;       allocate a whole page

.osmal_page
        call    osmal_AllocPage                 ; allocate new page - HL=MATEntryPtr, A=bank
        ret     c                               ; no mem? exit
        call    MATPtrToPagePtr         ; point HL to it

;       got mem, return it

.osmal_ok
        ld      b, a                            ; bank

        ld      a, (ix+mhnd_AllocFlags)
        and     $C0                             ; segment
        jr      nz, osmal_8                     ; not S0? ok
        bit     5, h                            ; address memory at $2000
        set     5, h                            ; if address was already there then address the upper half of bank
        jr      z, osmal_8
        set     0, b                            ; odd bank

.osmal_8
        bit     MM_B_MUL, (ix+mhnd_AllocFlags)  ; set ExclusiveBank if not multiple banks
        jr      nz, osmal_9
        ld      (ix+mhnd_ExclusiveBank), b

.osmal_9
        res     6, h                            ; fix segment
        or      h                               ; segment specifier
        ld      h, a
        call    PutOSFrame_BHL

        rlca                                    ; return segment in C
        rlca
        and     3
        ld      (iy+OSFrame_C), a
        or      a                               ; Fc=0
        ret

.osmal_AllocPage
        ld      e, (ix+mhnd_AllocFlags)
        ld      d, (ix+mhnd_ExclusiveBank)

        ld      a, (iy+OSFrame_A)               ; set ExclusiveBank if it's zero and A=$01-$1F
        or      a                               ; !! check D before A, saves time
        jr      z, osmal_11                     ; !! dec a; cp $1f; jr nc,...; inc a
        cp      $20
        jr      nc, osmal_11

        inc     d
        dec     d
        jr      nz, osmal_11
        ld      d, a                            ; !! undocumented - slot A

.osmal_11
        call    osmal_AllocPage2
        ret     c                               ; error? exit
                                                ; otherwise drop thru
;       ----

; in: IX=memhandle
;     HL=MAT entry

.MarkPageAsAllocated

        call    DecFreeRAM                      ; one page less

        call    GetMhndSlotAlloc                ; get first allocation from this slot
        jr      nz, mpaa_2                      ; already had mem from this slot

        push    ix                              ; IX>>4 as next pointer
        pop     de
        ld      b, 4
.mpaa_1
        srl     d
        rr      e
        djnz    mpaa_1
        set     MAT_B_LAST, d                   ; mark as last in chain

;       set next_pointer for new page

.mpaa_2
        ld      (hl), e                         ; <next
        inc     l
        ld      a, (hl)                         ; keep SWAP bit
        and     MAT_SWAP
        or      MAT_FULL                        ; no partial allocation possible
        or      d                               ; >next + possibly last flag
        bit     MM_B_FIX, (ix+mhnd_AllocFlags)
        jr      nz, mpaa_3
        set     MAT_B_ALLOCFIXED, a             ; !! use 'or'
.mpaa_3
        ld      (hl), a                         ; >next
        dec     l

;       set new page as first in chain

        ld      d, h                            ; DE=MAToffset(HL) - return it in HL
        ld      e, l
        call    MATPtrToPageN
        ex      de, hl                          ; drop thru

;       ----

;       IN: DE=MAT entry to put in MemHandle IX
;       slot selection is based on bank in S2

.SetMhndSlotAlloc

        push    hl
        call    GetMhndSlotAllocPtr
        ld      (hl), e
        inc     l
        ld      (hl), d
        pop     hl
        or      a                               ; Fc=0
        ret

;       ----

;       DE=first allocation in slot bound in S2

.GetMhndSlotAlloc

        push    hl
        call    GetMhndSlotAllocPtr
        ld      e, (hl)                         ; low byte
        inc     l
        ld      a, (hl)                         ; high byte
        and     $0f                             ; remove flags
        ld      d, a
        or      e                               ; Fz=1 if no allocations
        pop     hl
        ret

;       ----

;       HL=ptr to first allocation entry num

.GetMhndSlotAllocPtr

        ld      a, (BLSC_SR2)                   ; get bank
        rlca
        rlca
        and     3                               ; slot
        rlca                                    ; *2 for word table
        add     a, mhnd_Slot0
        push    ix                              ; HL+=A
        pop     hl
        add     a, l                            ; doesn't overflow - could use 'or' as well
        ld      l, a
        ret

;       ----

.MemFail2
        jp      OZwd__fail

;       ----

;IN:    IX=MemHandle
;       BC=deallocation size
;       AHL=memory to free
;OUT:   Fc=0, ok
;       Fc=1, A=error if fail

.mfr_err
        ld      a, RC_Fail
        scf
        ret

;       entrypoint here!

.OSMfrMain

        call    MemCallAttrVerify
        jr      c, mfr_err                      ; bad size? exit
        jr      z, mfr_page                     ; size=256? free whole page

        ld      a, (iy+OSFrame_A)               ; bank
        bit     7, h                            ; skip if not segment 0
        jr      nz, mfrchk_1
        bit     6, h
        jr      nz, mfrchk_1

        bit     0, a                            ; clear lower/upper half selector bit,
        res     0, a                            ; address memory at $0000 if bank was even
        jr      nz, mfrchk_1
        res     5, h

.mfrchk_1
        call    MS1BankA

        res     7, h                            ; S1 fix
        set     6, h

; !! validate and unfrag page inside FreeChunk - almost zero overhead
; !! compared to current method

        push    af                              ; !! unnecessary
        push    hl
        call    ValidatePage
        pop     hl
        jr      c, MemFail2
        pop     af

        call    FreeChunk
        call    DefragmentPage                  ; join chunks if possible

        push    af                              ; !! unnecessary
        call    ValidatePage
        jr      c, MemFail2
        pop     af

        ld      l, 0                            ; check if page is completely free
        ld      a, (hl)                         ; first chunk at 01, size=255?
        xor     1                               ; Fc=0
        ret     nz
        inc     l
        ld      a, (hl)
        inc     a
        ret     nz

;       free whole page

.mfr_page
        ld      d, (iy+OSFrame_A)               ; bank
        ld      e, (ix+mhnd_AllocFlags)
        call    GetPageMAT
        jr      c, MemFail2                     ; invalid bank? fail

        call    GetMhndSlotAlloc                ; DE=first allocation MATPageN
        jr      z, MemFail2                     ; no mem allocated from this slot? fail

        ld      c, (hl)                         ; BC=next + MAT_LAST
        inc     l
        ld      a, (hl)
        and     MAT_LAST|$0f
        ld      b, a
        dec     l

        call    MATPtrToPageN                   ; translate HL into MATPageN
        ex      de, hl                          ; compare to see if this=first
        or      a
        sbc     hl, de
        add     hl, de
        jr      nz, mfrpage_2                   ; not first? find it in list

        ld      d, b                            ; DE=next
        ld      e, c
        bit     MAT_B_LAST, b
        jr      z, mfrpage_1                    ; not last? skip
        ld      de, 0                           ; this was last, clear ptr
.mfrpage_1
        call    SetMhndSlotAlloc                ; set new pointer into MemHandle
        jp      MarkPageFreePageN               ; mark it free in MAT

;       find page in linked list

.mfrpage_2
        call    PageNToMATPtr

        ld      a, (hl)                         ; <next
        ex      af, af'
        inc     l
        ld      a, (hl)                         ; a'=next bits8-15
        dec     l
        bit     MAT_B_LAST, a
        jp      nz, MemFail2                    ; this was last? fail
        and     $0f                             ; >next

        cp      d                               ; see if Aa=this
        jr      nz, mfrpage_3
        ex      af, af'
        cp      e
        jr      z, mfrpage_4                    ; Aa=DE? remove from list

        ex      af, af'
.mfrpage_3
        ld      h, a                            ; follow link to next
        ex      af, af'
        ld      l, a
        jr      mfrpage_2

;       remove page from list - HL=previous entry, BC=next entry

.mfrpage_4
        ld      (hl), c                         ; <next
        inc     l
        ld      a, (hl)                         ; >next, keep flags
        and     MAT_LAST|MAT_FULL|MAT_ALLOCFIXED|MAT_SWAP
        or      b
        ld      (hl), a

        ex      de, hl                          ; HL=PageN
        jp      MarkPageFreePageN

;       ----

;IN:    IX=MemHandle  !! not verified
;       B=bank
;       H=page address high byte

.OSAxp

        ld      d, b                            ; bank
        ld      e, MM_S1                        ; allocation flags: segment 1
        call    GetPageMAT
        ld      a, RC_Fail
        ret     c                               ; no RAM in bank? exit

        call    FollowMATPtr                    ; DE=next
        ld      a, RC_Fail
        scf
        ret     nz                              ; already allocated? error
        jp      MarkPageAsAllocated

;       ----

;IN:    D=bank
;       OSFrame_H=address high byte
;OUT:   HL points to MAT entry for this page

.GetPageMAT

        call    GetBankMAT                      ; point HL to first MAT entry in bank D
        ret     c                               ; invalid bank? error

        ld      a, (iy+OSFrame_H)               ; check memory address
        cp      $20
        ret     c                               ; below $2000? error
        cp      $40
        jr      nc, gpm_1                       ; not segment 0

        bit     0, d                            ; use lower half if bank is even
        jr      nz, gpm_1
        sub     $20

.gpm_1
        and     $3F                             ; page
        ld      c, a
        ld      b, 0
        add     hl, bc                          ; HL points to page MAT entry
        add     hl, bc
        ret

;       ----

;       init all RAM, called from Reset

.InitRAM
        ld      c, 2
        call    OZ_MGB
        push    bc                              ; remember current S2 binding
        ld      a, $21                          ; start with first RAM bank (skip system bank)
.ir_1
        call    InitSlotRAM                     ; init one slot
        and     $c0
        add     a, $40                          ; advance to next
        jr      nz, ir_1                        ; and init if not done yet
        pop     bc
        rst     OZ_MPB                          ; restore S2 binding
        ret

;       ----

;IN:    A=first bank to init
;OUT:   A=A(in)

.InitSlotRAM

        cp      $21
        push    af                              ; remember bank, b21 flag

        rlca                                    ; point IX to slot data
        rlca
        and     3
        ld      c, a
        ld      b, 0
        ld      ix, ubSlotRAMoffset
        add     ix, bc

        pop     af                              ; get bank
        push    af
        ld      (ix+0), 0                       ; RAM bank offset  !! ld (ix+n),b
        ld      (ix+4), 0                       ; RAM size
        ld      hl, (ubResetType)               ; ld l, (ubResetType)
        inc     l
        dec     l
        jr      z, initsl_1                     ; hard reset, force init

        call    MS2BankA                        ; bank into S2
        ld      hl, (MM_S2 << 8)                ; if tagged as RAM, leave alone
        ld      bc, $A55A
        or      a
        sbc     hl, bc
        jr      z, initsl_2

.initsl_1
        call    SlotRAMSize                     ; find out RAM size
        or      a
        jr      z, initsl_5                     ; no RAM

        ex      af, af'
        pop     af                              ; bind first bank into S2
        push    af
        call    MS2BankA
        ex      af, af'
        ld      (MM_S2 << 8 | $02), a           ; store size

.initsl_2
        ld      a, (MM_S2 << 8 | $02)
        ld      (ix+4), a                       ; RAM size
        inc     a                               ; A=(A*PAGES_PER_BANK*2)/256 - MAT size in pages
        srl     a
        push    af
        ld      b, a                            ; clear MAT
        ld      c, 0
        ld      de, MM_S2 << 8 | $101
        ld      hl, MM_S2 << 8 | $100
        ld      (hl), c
        dec     bc
        ldir

        ld      hl, MM_S2 << 8
        ld      a, (ubResetType)
        and     (hl)                            ; Fz=1 if hard reset or non-tagged RAM
        pop     hl                              ; H=MAT size in pages
        pop     de                              ; D=bank
        push    de
        ld      e, 1                            ; start from first device
        call    nz, MarkAllFsBlocks             ; soft reset? mark all filesystem blocks
        call    nz, AllocFsBlocks               ; soft reset? allocate all filesystem blocks

        ld      c, h                            ; C=MAT size in pages+1
        inc     c

        pop     af                              ; bank
        push    af
        and     $FE
        ld      (ix+0), a                       ; RAM bank offset
        cp      $40                             ; increment internal RAM size
        jr      nc, initsl_3
        inc     (ix+4)

.initsl_3
        ld      a, (ix+4)                       ; RAM size
        neg                                     ; clear out_of_memory flags
        ld      l, a
        ld      h, MM_S2                        ; end of first page
        xor     a
.initsl_4
        ld      (hl), a
        inc     l
        jr      nz, initsl_4

        ld      l, (ix+4)                       ; RAM size
        pop     af                              ; bank
        push    af
        add     a, l
        dec     a
        ld      d, a                            ; last RAM bank in slot

        pop     af                              ; bank, b21 flag
        push    af
        push    bc
        push    hl
        ld      bc, $3F01                       ; last block
        call    nz, MarkSystemRAM               ; reserve for system
        pop     hl
        pop     bc

        ld      h, 0                            ; HL=RAM size*$40 - number of pages
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      de, (uwFreeRAMPages)            ; add them in
        add     hl, de
        ld      (uwFreeRAMPages), hl

        pop     de                              ; bank
        push    de

        ld      b, 0                            ; first page
        call    MarkSystemRAM                   ; reserve first page and MAT for system

.initsl_5
        pop     af                              ; AF(in)
        ret

;       ----

;       Find RAM size in slot
;
;IN:    A=first bank
;OUT:   A=number of RAM banks

.SlotRAMSize

        push    hl
        ld      b, a                            ; bank
        ld      c, 0                            ; size
        call    InitRAMBank                     ; clear RAM
        jr      c, srsz_2                       ; wasn't RAM

        ld      d, b                            ; remember first bank
        ld      a, $CA
        ld      (MM_S2 << 8), a                 ; mark with $CA

.srsz_1
        inc     c                               ; bump size
        inc     b                               ; bump bank
        ld      a, b                            ; exit if slot done
        and     $3F
        jr      z, srsz_2

        ld      a, b                            ; check for RAM
        call    InitRAMBank
        jr      c, srsz_2                       ; no RAM, exit

        ld      a, d                            ; see if first bank was overwritten
        call    MS2BankA
        ld      a, (MM_S2 << 8)
        sub     $CA
        jr      z, srsz_1                       ; no, loop back

.srsz_2
        ld      a, c                            ; return size
        pop     hl
        ret

;       ----

;       Fill RAM bank with zeroes
;
;IN:    A=bank
;OUT:   Fc=0 if ok, Fc=1 if not RAM

.InitRAMBank

        push    bc
        push    de
        push    hl
        call    CheckRAMBank                    ; check if bank is RAM
        jr      c, zram_0                       ; not, exit

; this check only necessary for internal RAM

        ld      a, ($0000)                      ; remember byte at $0000
        ld      hl, MM_S2 << 8
        ld      (hl), 0                         ; reset byte at $8000
        ld      bc, ($0000)                     ; read back from $0000
        ld      ($0000), a                      ; restore $0000
        inc     c
        dec     c
        scf
        jr      z, zram_0                       ; mirrored, not RAM

        ld      bc, $3FFF                       ; clear bank by copying 0 from
        ld      de, MM_S2 << 8 | $01            ; the first byte onward
        ldir

        or      a                               ; bank OK
.zram_0
        pop     hl
        pop     de
        pop     bc
        ret

;       ----

;       Check if bank is RAM
;
;IN:  A=bank
;OUT: Fc=0 if RAM

.CheckRAMBank

        call    MS2BankA

        ld      hl, MM_S2 << 8
        ld      a, (hl)                         ; get byte and save it
        ld      e, a
        cpl
        ld      (hl), a
        cpl
        xor     (hl)
        ld      (hl), e                         ; restore byte
        cp      $FF
        ret

;       ----

.osmal_AllocPage2

        ld      a, d
        or      a
        jp      z, FindFreePageAnySlot          ; no exlusive bank

        cp      $20
        jr      c, FindFreePageSlotD            ; it's not bank, it's slot

;       ----

;       Find free page from bank D
;
;IN:    D=bank
;       E=allocation flags

.FindFreePage

        call    GetBankMAT
        jr      c, ffp_3                        ; no RAM in bank? error

        push    hl
        call    PrepareOutOfMem
        or      OOM_NORMAL                      ; always test bit 0, normal mem
        and     (hl)
        pop     hl
        jr      nz, ffp_3                       ; bank full? error

        ld      bc, 64                          ; scan 64 pages, 32 if segment 0
        ld      a, e
        and     $C0                             ; segment
        jr      nz, ffp_1
        ld      bc, 32                          ; !! ld c,20

        bit     0, d                            ; use upper half of bank if odd bank
        jr      z, ffp_1
        set     6, l

.ffp_1
        call    FindFreePage0
        ret     nc                              ; found free page? exit

        ld      a, e
        and     $C0
        jr      z, ffp_3                        ; segment 0? don't set error flags

        call    PrepareOutOfMem
        jr      nz, ffp_2                       ; fixed? set OOM_B_FIXED
        inc     a                               ; set OOM_B_NORMAL
.ffp_2
        or      (hl)
        ld      (hl), a

.ffp_3
        ld      a, RC_Room                      ; no empty page found
        scf
        ret

;       ----

; Prepare for out_of_memory flag read/set
;
; IN:  D=slot&bank, E=alloc flags
; OUT:(HL)=outOfMemFlags, A=fixedFlag
;
; !! Could change 'and $1f' into 'or $20' and 'cpl' into 'or $c0' to put flags in natural order

.PrepareOutOfMem
        ld      a, d                            ; limit slot 0 bank to 00-1F
        and     $C0
        ld      a, d
        jr      nz, poom_1
        and     $1F

.poom_1
        and     $3F                             ; bank
        cpl                                     ; from top of page - E0-FF or C0-FF
        ld      l, a
        ld      h, $80                          ; top of first page, at S2
        ld      a, e                            ; A=fixed flag
        and     OOM_FIXED
        ret

;       ----

; point HL into MAT of bank D, handle slot 0

.GetBankMAT
        push    de
        ld      a, e
        and     $C0                             ; dest segment
        jr      nz, gbm_1                       ; not seg0? ok
        res     0, d                            ; only use even banks
.gbm_1
        call    GetBankMAT0
        pop     de
        ret

;       ----

;       find free page in slot D

.FindFreePageSlotD
        push    iy
        ld      a, d                            ; slot in bits0-1
        call    MS2SlotMAT
        jr      c, apsd_3                       ; no RAM  !! 'ld b,(iy+4); pop iy' before this to 'ret c'

        ld      b, (iy+4)                       ; RAM size
        ld      d, a                            ; RAM base

        ld      a, e                            ; if segment 0 use forward allocation
        and     $C0
        jr      z, apsd_1

        ld      a, d                            ; D=last bank
        add     a, b
        dec     a
        ld      d, a

.apsd_1
        push    bc
        push    de
        call    FindFreePage
        pop     de
        pop     bc
        jr      nc, apsd_4                      ; found empty page mem

        inc     d                               ; increment bank
        ld      a, e                            ; backward allocation if not segment 0
        and     $C0
        jr      z, apsd_2
        dec     d
        dec     d

.apsd_2
        djnz    apsd_1                          ; try all banks

        scf
.apsd_3
        ld      a, RC_Room

.apsd_4
        pop     iy
        ret

;       ----

;       find free page in any slot

.FindFreePageAnySlot

        xor     a
.apas_1
        inc     a                               ; next slot, 1-2-3-0
        and     3
        ld      d, a
        push    de
        call    FindFreePageSlotD
        pop     de
        jr      nc, apas_2                      ; found free page? exit

        ld      a, d
        or      a
        jr      nz, apas_1                      ; not slot 0? try next slot

        ld      a, RC_Room
        scf
.apas_2
        ret

;       ----

;       find free page in bank D
;
;IN:    HL=MAT start
;OUT:   Fc=0, HL=MatEntry of free page
;       Fc=1 if no page free

.ffp0_0
        inc     hl
        cpi
        scf
        ret     po                              ; BC overflow, Fc=1

;       entry point here

.FindFreePage0
        inc     l
        ld      a, (hl)                         ; MAT bits
        dec     l

        bit     MM_B_FIX, e                     ; if we want fixed workspace we
        jr      z, ffp0_1                       ; skip swap memory
        bit     MAT_B_SWAP, a
        jr      nz, ffp0_0

.ffp0_1
        push    de
        call    FollowMATPtr
        pop     de
        jr      nz, ffp0_0                      ; allocated, try next

        or      a                               ;Fc=0
        ret

;       ----

;       convert PageN into MAT pointer

.PageNToMATPtr
        add     hl, hl                          ; entry*WORD_SIZEOF
        set     7, h                            ; S2 fix
        inc     h                               ; skip first page
        ret

;       ----

;       convert MAT pointer into PageN

.MATPtrToPageN
        res     7, h                            ; S2 unfix
        dec     h                               ; unskip first page
        srl     h                               ; offset/WORD_SIZEOF
        rr      l
        ret

;       ----

;       convert PageN into page pointer

.PageNToPagePtr
        call    PageNToMATPtr

;       ----

;       convert MAT pointer into page pointer

; IN:  HL=MATptr - $010 hhhl llll lll0
; OUT: DE=MATptr, AHL=page

.MATPtrToPagePtr

        push    hl
        res     7, h                            ; remove S2 bit
        dec     h                               ; unskip ? page
        ld      a, (BLSC_SR2)                   ; MAT bank
        and     $FE                             ; slot RAM base
        add     hl, hl                          ; 00hh hhll llll ll00, Fc=0
        add     a, h                            ; bank
        ld      h, l                            ; llll ll00
        scf
        rr      h                               ; 1lll lll0
        srl     h                               ; 01ll llll, S1
        ld      l, 0                            ; HL points to page
        pop     de
        ret

;       ----

;       convert PageN into MAT pointer and get next PageN into DE

.FollowPageN

        call    PageNToMATPtr

;       get next PageN into DE
;
;       Fz=1 if next=NULL

.FollowMATPtr

        ld      e, (hl)
        inc     l
        ld      d, (hl)
        dec     l
        ld      a, d
        and     $0f                             ; remove flags
        or      e
        ret

;       ----

;       bind in MAT for slot specified by address high byte in A

.MS2SlotMAT67

        rlca                                    ; high bits into low bits
        rlca

;       bind in MAT for slot A
;
; IN:  A=slot
; OUT: A=base bank, IY points to SlotRAMoffset for this slot
;
; !! could exit before bankswitch if no RAM

.MS2SlotMAT

        and     3
        ld      iy, ubSlotRAMoffset             ; RAM bank offset
        ld      c, a
        ld      b, 0
        add     iy, bc

        ld      a, (iy+0)
        cp      $40                             ; use b21 if internal RAM
        jr      nc, slctr_1
        inc     a
.slctr_1
        call    MS2BankA                        ; bind MAT in

        and     $FE                             ; slot RAM base
        ret     nz                              ; Fc=0
        scf                                     ; no RAM
        ret     z                               ; unconditional ret !! change

;       ----

; bind in MAT for bank D and point HL to the start of bank entries
;

.GetBankMAT0

        push    iy
        ld      a, d                            ; bank
        call    MS2SlotMAT67                    ; bind MAT in S2
        jr      c, gbm0_1                       ; no RAM? exit

        sub     d
        neg                                     ; bank(in)-base bank
        cp      (iy+4)                          ; RAM size
        ccf
        jr      c, gbm0_1                       ; larger than slot RAM size? exit

        ld      l, a                            ; HL=bank_offset*PAGES_PER_BANK*WORD_SIZEOF
        ld      h, 0
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        set     7, h                            ; S2 fix
        inc     h                               ; skip first page

.gbm0_1
        pop     iy
        ret

;       ----

;IN:    D=bank
;       B=first page to mark
;       C=number of pages to mark

;       mark RAM reserved for bad apps

.MarkSwapRAM
        ld      hl, MAT_SWAP<<8
        jr      msr_1

;       mark RAM reserved for system

.MarkSystemRAM
        ld      hl, MAT_SYSTEM

.msr_1
        push    bc
        ld      c, 2                            ; preserve S2, it will be destroyed
        call    OZ_MGB                          ; get binding
        push    bc                              ; ex bc,af
        pop     af
        pop     bc                              ; restore bc on entry
        push    af                              ; save S2 binding

        push    bc
        push    hl
        call    GetBankMAT0                     ; bind in bank D
        pop     de                              ; mask
        pop     bc                              ; skip/mark count
        jr      c, msr_6                        ; no RAM? exit  !! ret c

        inc     b                               ; skip B entries
        jr      msr_3
.msr_2
        inc     hl                              ; skip one page MAT entry
        inc     hl
.msr_3
        djnz    msr_2

        ld      b, c                            ; mark C entries
        inc     b
        jr      msr_5
.msr_4
        ld      a, (hl)                         ; word |= in(HL)
        or      e
        ld      (hl), a
        inc     hl
        ld      a, (hl)
        or      d
        ld      (hl), a
        inc     hl
        call    z, DecFreeRAM                   ; if marking system RAM
.msr_5
        djnz    msr_4

        or      a                               ; Fc=0
.msr_6
        pop     bc                              ; restore S2 binding
        push    af                              ; preserve Fc
        rst     OZ_MPB
        pop     af
        ret

;       ----

;IN:    HL=PageN of page to free

.MarkPageFreePageN

        call    PageNToMATPtr


;IN:    HL=MAT pointer of page to free

.MarkPageFreeMATptr

        ld      (hl), 0                         ; keep SWAP flag, clear others
        inc     l
        ld      a, (hl)
        and     MAT_SWAP
        ld      (hl), a
        dec     l

        call    MATPtrToPageN                   ; into PageN  !! 'ret 7,h; dec h' here, eliminates one 'add hl,hl'
        add     hl, hl
        add     hl, hl
        ld      a, h                            ; 00hhhhll, bank & $3f
        cpl                                     ; from top of first page
        ld      l, a
        ld      h, MM_S2

        ld      a, (hl)                         ; clear out-of-memory flags !! ld (hl),0
        and     ~(OOM_NORMAL|OOM_FIXED)
        ld      (hl), a

        push    hl                              ; increment free pages
        ld      hl, (uwFreeRAMPages)
        inc     hl
        ld      (uwFreeRAMPages), hl
        pop     hl
        ret

;       ----

.DecFreeRAM
        push    hl
        ld      hl, (uwFreeRAMPages)
        dec     hl
        ld      (uwFreeRAMPages), hl
        pop     hl
        ret

;       ----


.RebuildMAT
        ld      a, (BLSC_SR1)                   ; remember S1
        push    af
        push    hl

.rbmat_1
        call    MarkFsBlock
        jr      c, rbmat_6                      ; error? exit
        jr      z, rbmat_7                      ; done? exit

        pop     hl
        pop     af
        call    MS1BankA                        ; restore S1

;       here is the entry point
;
;       DE=root filepointer

.MarkAllFsBlocks
        ld      a, (BLSC_SR1)                   ; remember S1
        push    af
        push    hl
        call    BindFilePtr

        ld      de, DOR_TYPE                    ; get DOR type
        add     hl, de
        ld      a, (hl)
        call    DORPtr2FilePtr                  ; son

        cp      DN_FIL
        jr      nz, rbmat_3

        ld      d, b                            ; DE=BC, son
        ld      e, c
        call    MarkFileBlocks                  ; mark blocks of this file
        jr      rbmat_5                         ; continue to brother

.rbmat_3
        cp      DN_DIR                          ; dir and device share same code
        jr      z, rbmat_4
        cp      DM_RAM
        jr      nz, rbmat_6                     ; bad type? exit
.rbmat_4
        call    RebuildMAT                      ; recursive call

.rbmat_5
        call    DORPtr2FilePtr                  ; brother
        jr      rbmat_1


.rbmat_6
        call    RebuildFsError                  ; print "Error U"
        defb    'U'

.rbmat_7
        pop     hl
        pop     af                              ; restore S1
        jp      MS1BankA

;       ----

;       get DOR pointer just before HL and convert it into FilePtr in DE

.DORPtr2FilePtr

        dec     hl
        ld      b, (hl)
        dec     hl
        ld      d, (hl)
        dec     hl
        ld      e, (hl)
        push    de
        ex      de, hl
        push    de
        call    MemPtr2FilePtr                  ; DE=fileptr(BHL)
        pop     hl                              ; original HL-3
        pop     bc                              ; ptr from DOR, no bank
        ret

;       ----

;       bind in bank specified by FilePtr in DE, BHL=memptr

.BindFilePtr

        call    FilePtr2MemPtr
        ld      a, b
        call    MS1BankA

        res     7, h                            ; S1 fix
        set     6, h
        ret

;       ----

.RebuildFsError

        OZ      OS_Pout
        defb    13, 10, 7
        defm    "Error ",0
        pop     hl
        ld      a, (hl)                         ; get byte from caller PC
        OZ      OS_Out
        inc     hl
        jp      (hl)                            ; return

;       ----

;       mark file blocks as used
;       uses bits 0-3 of MAT temporarily

.MarkFileBlocks

        ld      a, (BLSC_SR1)                   ; remember S1
        push    af
        push    hl
.mfb_1
        call    MarkFsBlock
        jr      c, mfb_2                        ; error? exit
        jr      z, mfb_2                        ; done? exit

        call    BindFilePtr
        ld      e, (hl)                         ; get next fs block
        inc     hl
        ld      d, (hl)
        inc     d
        dec     d
        jr      nz, mfb_1                       ; not end? mark it too

.mfb_2
        jr      rbmat_7                         ; !! 'pop hl; pop af; jp MS1BankA'

;       ----

;       mark single filesystem block
;
;IN:    DE=FilePtr
;OUT:   Fz=1 if DE=0
;       Fc=0 if successfull
;       Fc=1 if block already marked

.MarkFsBlock

        ld      a, d
        or      e
        ret     z                               ; file pointer 0, exit
        push    de
        ex      de, hl                          ; HL=D

        ld      a, (BLSC_SR2)                   ; A=base bank - 20/40/80/C0
        and     $FE
        sub     h
        neg
        ld      h, a                            ; H=bank-base = bank offset
        xor     a                               ; A=L&3 - filesystem block, HL=HL>>2, filesystem page
        srl     h
        rr      l
        rra
        srl     h
        rr      l
        rra
        rlca
        rlca
        call    PageNToMATPtr                   ; point HL to MAT entry

        ld      b, a                            ; A=1<<A
        inc     b
        xor     a
        scf
.mfsb_1
        rla
        djnz    mfsb_1

        ld      b, a                            ; remember mask
        and     (hl)
        scf
        ret     nz                              ; error if already set
        ld      a, b                            ; otherwise set it
        or      (hl)
        ld      (hl), a
        pop     de
        or      a                               ; Fc=0, unnecessary
        ret

;       ----

;       allocate all pages with filesystem blocks, add unused blocks
;       into filesystem chain

.AllocFsBlocks

        push    hl
        ld      b, h                            ; MAT size in pages
        ld      c, 0
        ld      a, (BLSC_SR2)
        and     $FE
        ld      d, a                            ; DE=FsPtr
        ld      e, c
        ld      hl, MM_S2 << 8 | $100           ; MAT start

.afsb_1
        ld      a, (hl)
        or      a
        jr      z, afsb_4                       ; no fs blocks? skip

        push    bc
        push    de
        push    hl

        ld      b, 4                            ; check 4 blocks
.afsb_2
        srl     (hl)
        jr      c, afsb_3                       ; fs block used? skip
        push    bc                              ; make block available to file system
        push    de
        call    AddAvailableFsBlock
        pop     de
        pop     bc
.afsb_3
        inc     de
        djnz    afsb_2

        pop     hl
        push    ix                              ; allocate page for file system
        ld      ix, (pFsMemPool)
        call    MarkPageAsAllocated
        pop     ix

        pop     de
        pop     bc
.afsb_4
        inc     de                              ; HL+=2, DE+=4, BC-=2
        inc     de
        inc     de
        inc     de
        inc     hl
        dec     bc
        cpi
        jp      pe, afsb_1                      ; no BC underflow? loop

        pop     hl
        ret

;       ----

;       allocate chunk from page
;       !! should validate here for smaller overhead
;
;IN:    H=page to allocate memory from
;       C=bytes to allocate
;OUT:   Fc=0, HL=memory ptr
;       Fc=1, error

.AllocChunk

        ld      d, h
        ld      l, 0                            ; start from pointer to first chunk

.ac_1
        ld      e, l                            ; DE=HL
        ld      a, (hl)                         ; pointer to next chunk
        or      a
        ccf
        ret     z                               ; no more? ret, Fc=1
        cp      l
        jr      z, ac_fail                      ; link to itself? fail
        jr      c, ac_fail                      ; link backwards? fail

        ld      l, a                            ; follow link
        ld      a, (hl)                         ; size of chunk
        sub     c
        jr      z, ac_match                     ; exact match
        jr      c, ac_next                      ; doesn't fit

        dec     a                               ; only one byte extra? doesn't fit
        jr      z, ac_next

        inc     a                               ; store new size of current chunk
        ld      (hl), a
        add     a, l                            ; and point HL to allocated chunk
        ld      l, a
        ret

.ac_next
        inc     l                               ; get link to next and jump there
        jr      ac_1

.ac_match
        inc     l                               ; copy link to next to previous chunk
        ldd                                     ; HL--, start of allocated memory
        ret

.ac_fail
        jp      OZwd__fail

;       ----

; IN: HL=memory to free, C=size
;
; !! should validate and degragment here, less overhead

.FreeChunk
        ld      (hl), c                         ; set size
        ld      e, l                            ; remember chunk start
        xor     a
        inc     l
        ld      (hl), a                         ; set next=0
.fc_1
        ld      l, a
        ld      a, (hl)                         ; next
        or      a
        jr      z, fc_2                         ; no more chunks, link freed to this

        cp      e
        inc     a                               ; ptr to link
        jr      c, fc_1                         ; next<freed, loop

        dec     a                               ; next
        ld      (hl), e                         ; link freed to this
        ld      l, e                            ; this=freed
        inc     l                               ; ptr to next
        ld      e, a                            ; freed=next
.fc_2
        ld      (hl), e
        ret

;       ----

.DefragmentPage

        ld      d, h
        ld      l, 0                            ; start from link to first

.defrag_1
        ld      a, (hl)                         ; next chunk
        or      a
        ret     z                               ; no more chunks? exit

.defrag_2
        ld      l, a                            ; move to chunk
        add     a, (hl)                         ; pos+size
        ret     z                               ; till the end of page? exit
        cp      l
        ret     z                               ; link to self? exit !! should fail
        inc     l
        cp      (hl)                            ; compare with next chunk pos
        jr      nz, defrag_1                    ; not same? check next chunk

;       join chunks

        ld      e, a                            ; next pos
        ld      a, (de)                         ; next size
        dec     l
        add     a, (hl)                         ; this size
        ld      (hl), a                         ; remember
        inc     e
        ld      a, (de)                         ; chunk after next
        inc     l
        ld      (hl), a                         ; is chunk after this
        dec     l
        ld      a, l
        jr      defrag_2                        ; try to join with next chunk

;       ----

;       Validate page H00 !! fail here to save bytes elsewhere
;
;OUT:   Fc=0 if page OK, Fc=1 if invalid

.ValidatePage

        ld      l, 0
.vp_1
        ld      a, (hl)                         ; pointer to next chunk
        or      a
        ret     z                               ; no more chunks, Fc=0

        ld      l, a
        ld      a, (hl)                         ; size
        cp      2
        ret     c                               ; <2? fail

        add     a, l                            ; size+start
        jr      z, vp_2                         ; end of page is ok
        ret     c                               ; otherwise overflow means error
.vp_2
        or      a                               ; Fc=0
        inc     l
        inc     (hl)
        dec     (hl)
        ret     z                               ; no more chunks? page ok, Fc=0
        inc     a
        dec     a
        scf
        ret     z                               ; more pages and size+start=256? Fc=1
        cp      (hl)
        jr      c, vp_1                         ; start+size<next? ok, check next

        scf
        ret                                     ; Fc=1

;       ----

; open memory (allocate memory pool)

.OSMop
        call    OSFramePush
        call    OSMopMain
        jp      OSFramePop

;       ----

; close memory (free memory pool)

.OsMcl
        call    OSFramePush
        call    OSMclMain
        jp      OSFramePop

;       ----

; allocate memory

.OSMal
        call    OSFramePush
        ex      af, af'                         ; remember S1
        ld      a, (BLSC_SR1)
        push    af
        ex      af, af'
        call    OSMalMain
        ex      af, af'                         ; restore S1
        pop     af
        call    MS1BankA
        ex      af, af'
        jp      OSFramePop

;       ----

; free memory

.OSMfr
        call    OSFramePush
        ex      af, af'                         ; remember S1
        ld      a, (BLSC_SR1)
        push    af
        ex      af, af'
        call    OSMfrMain
        ex      af, af'                         ; restore S1
        pop     af
        call    MS1BankA
        ex      af, af'
        jp      OSFramePop



; ********************************************************************************************
; Get current bank binding in segment
;
; IN:
;      C = memory segment specifier (MS_S0, MS_S1, MS_S2 & MS_S3)
;
; OUT, if call successful:
;      Fc = 0
;      B = bank number currently bound to that segment
;      C = C(in)
;
; OUT, if call failed:
;      Fc = 1
;      A = error code:
;           RC_ERR ($0F), C was not valid
;
; Registers changed after return:
;      ...CDEHL/IXIY same
;      AFB...../.... different
;
.OSMgb
        exx
        ld      a, c                            ; segment
        pop     bc                              ; pop S3 bank into B
        push    bc
        ld      c, a
        cp      3
        jr      z, ret_bank_binding             ; seg 3? we're done
        jr      nc, illg_MS_Sx                  ; seg >3? error

        call    OZ_MGB                          ; OZ V4.1: get bank binding status in B for C = MS_Sx
        jr      ret_bank_binding                ; return current bank binding for MS_Sx




; ********************************************************************************************
; Set new bank binding in segment.
;
; Important:
;       For OZ V4.1 and higher this call is redundant and available for application
;       backward compatibility with older ROM versions.
;       RST 30H with same B, C arguments are used internally by newer OZ versions for faster
;       bank switching.
;
; IN:
;      C = memory segment specifier (MS_S0, MS_S1, MS_S2 & MS_S3)
;      B = bank number to bind into this segment ($00 - $FF)
;
; OUT, if call successful:
;      Fc = 0
;      B = bank number previously bound to that segment
;
; OUT, if call failed:
;      Fc = 1
;      A = error code:
;           RC_Ms ($0F), C was not valid
;
; Registers changed after return:
;      ...CDEHL/IXIY same
;      AFB...../.... different
;
.OSMpb
        exx
        ld      a, c                            ; segment
        cp      3
        jr      z, mpb_1                        ; segment 3? handle separately
        jr      nc, illg_MS_Sx                  ; segment >3? error

        rst     OZ_MPB                          ; OZ V4.1: execute bank binding, B = bank number, C = MS_Sx
        jr      ret_bank_binding                ; return old bank binding in B
.mpb_1
        pop     af                              ; pop S3 into A
        push    bc                              ; push new bank
        ld      b, a                            ; return old bank in B
.ret_bank_binding
        ex      af, af'
        or      a
        jp      OZCallReturn1
.illg_MS_Sx
        ld      a, RC_Ms
        scf
        jp      OZCallReturn1


;       ----
; select fast code (fast bank switching)

.OSFc
        push    ix
        ex      af, af'
        dec     a
        scf
        ld      a, RC_Unk
        jr      nz, osfc_1                      ; reason not 1? exit

        exx                                     ; copy pointers from alternate registers
        push    hl                              ; and translate slot number into blink port
        push    de
        ld      a, c
        add     a, BL_SR0
        exx
        pop     de                              ; DE=destination
        push    de                              ; IX=DE
        pop     ix
        ld      bc, 6                           ; copy 6 bytes
        ld      hl, osfc_2                      ; from here
        ldir

        ld      (ix+1), a                       ; set softcopy low byte
        ld      (ix+4), a                       ; set output port

        dec     de                              ; point HL to 'ret'
        ex      de, hl

        pop     de                              ; DE=jump address
        ld      a, d
        or      e
        jr      z, osfc_1                       ; no jump, we're done

        ld      (hl), $C3                       ; jp opcode
        inc     hl
        ld      (hl), e
        inc     hl
        ld      (hl), d

.osfc_1
        ld      a, 8                            ; return code size  !! bug - overrides error code
        pop     ix
        jp      OZCallReturn2

.osfc_2
        ld      (BLSC_PAGE<<8), a
        out     (0), a
        ret

;       ----

.SetExlusiveBank
        exx
        ld      de, 0                           ; reset max_unused_pages variables
        exx

        ld      d, (ix+mhnd_ExclusiveBank)      ; get slot/bank limit
        ld      e, (ix+mhnd_AllocFlags)

        ld      a, d
        or      a
        jr      nz, seb_1
        call    FindUnusedBankAnySlot           ; any slot
        jr      seb_3
.seb_1
        cp      $20                             ; if it is RAM allocate from single bank
        jr      nc, seb_2                       ;
        call    FindUnusedBank                  ; otherwise allocate from slot D
        jr      seb_3
.seb_2
        call    CountUnusedPages                ; just bank D

.seb_3
        exx
        ld      a, d                            ; bank with most unused pages
        exx
        or      a
        ret     z                               ; no free pages found? exit
        ld      (ix+mhnd_ExclusiveBank), a
        ret

;       ----

; Count unused pages in bank
;
;IN:    D=bank
;       E=segment
;OUT:   A=c'=unused pages in bank
;       d'=bank with most (c') pages
;       Fc=0 if totally free

.CountUnusedPages

        call    GetBankMAT
        jr      c, cup_err                      ; no RAM?

        push    hl
        call    PrepareOutOfMem
        or      OOM_NORMAL
        and     (hl)                            ; check if bank full
        pop     hl
        jr      nz, cup_err                     ; out of memory? exit

        ld      bc, 64                          ; 64 pages, 32 if segment 0
        ld      a, e
        and     $C0
        jr      nz, cup_1
        ld      bc, 32                          ; !! ld c,32
        bit     0, d                            ; use upper half of bank if bank LSB=1
        jr      z, cup_1
        set     6, l

.cup_1
        exx                                     ; !! could zero c' in CountUnusedPages2
        ld      c, 0
        exx
        call    CountUnusedPages2               ; c'=unused_count

        ld      a, e                            ; 64 pages, 32 if segment 0
        and     $C0                             ; !! push it above, pop here
        ld      a, 64
        jr      nz, cup_2
        ld      a, 32
.cup_2
        exx
        cp      c
        jr      z, cup_3                        ; all free, Fc=0 - all other returns with Fc=1

        ld      a, c                            ; compare with most_free
        cp      e
        jr      c, cup_4                        ; smaller or same
        scf
        jr      z, cup_4
.cup_3
        exx                                     ; d'=bank, e'=max most_free
        ld      a, d
        exx
        ld      d, a
        ld      e, c
.cup_4
        exx
        ret     nc                              ; !! just ret
.cup_err
        scf
        ret

;       ----

; check one slot for completely free bank

;IN:    D=slot
;OUT:   Fc=0 if empty bank found
;       c'=max_free, d'=bank

.FindUnusedBank
        push    iy
        ld      a, d
        call    MS2SlotMAT
        jr      c, fub_2                        ; no RAM? skip  !! ld b/pop iy above to optimize exits

        ld      b, (iy+4)                       ; SlotRAMSize
        ld      d, a                            ; slot
.fub_1
        push    bc                              ; remember count
        push    de                              ; and bank
        call    CountUnusedPages
        pop     de
        pop     bc
        jr      nc, fub_3                       ; totally empty? exit

        inc     d                               ; try next bank
        djnz    fub_1                           ; as long as RAM left
.fub_2
        scf                                     ; !! unnecessary
.fub_3
        pop     iy
        ret

;       ----

;       try to find totally unused bank in any slot
;
;IN:    -
;OUT:   'c incremented for each free page
;       Fc=0 if completely free bank found


.FindUnusedBankAnySlot
        xor     a                               ; !! not necessary, A=0 on entry

.fubas_1
        inc     a                               ; next slot, 1-2-3-0
        and     3
        ld      d, a
        push    de
        call    FindUnusedBank

        pop     de
        jr      nc, fubas_2                     ; got totally free bank? exit  !! ret nc

        ld      a, d
        or      a
        jr      nz, fubas_1                     ; slots left? loop

        scf                                     ; Fc=1, no free bank found

.fubas_2
        ret

;       ----

;       count unused pages in bank
;
;IN:    BC=number of pages
;       HL=MATptr of first page
;OUT:   c' incremented for each free page


.cup2_1
        inc     hl
        cpi                                     ; HL++, BC--
        scf                                     ; !! not necessary (cut&paste code)
        ret     po                              ; BC underflow? return

.CountUnusedPages2
        inc     l                               ; get page attributes
        ld      a, (hl)
        dec     l

        bit     MM_B_FIX, e                     ; want fixed mem?
        jr      z, cup2_2                       ; no? check this
        bit     MAT_B_SWAP, a                   ; verify page is fixed
        jr      nz, cup2_1                      ; no? skip this

.cup2_2
        push    de
        call    FollowMATPtr                    ;Fz=1 if next=NULL
        pop     de
        jr      nz, cup2_1                      ; in use? check next

        exx                                     ; increment unused_count
        inc     c
        exx
        jr      cup2_1                          ; and check next

;       ----

;       nop OZ entry  !! get rid of all calls to this

.OSSp_89
        cp      3
        ccf
        ld      a, RC_Unk
        ret     c                               ; !! just ret, Fc set correctly
        ld      hl, ossp89_1
        add     hl, bc
        jp      (hl)

.ossp89_1
        jp      ossp89_2
.ossp89_2
        or      a                               ; Fc=0
        ret


; ******************************************************************************************************
; Verify ROM/EPROMcard
;
;IN:    D=slot in low bits
;       E=bank to test
;OUT:   D=card type
;
; *** IMPORTANT NOTE ***
; This call must not use any stack related instruction
; It is also called on boot when there is still no stack set
;
.VerifySlotType
        ld      a, d                            ; get last bank in slot
        rrca
        rrca
        or      $3f
        ld      (BLSC_SR2), a                   ; and bind into S2
        out     (BL_SR2), a                     ; WE CANT USE MS2BankA (no stack when called from boot)
        ld      hl, ($bffe)                     ; last word

        ld      d, BU_EPR                       ;
        ld      bc, CT_EPR
        sbc     hl, bc
        add     hl, bc
        jr      z, vst_1                        ; "oz" found

        inc     d                               ; BU_ROM
        ld      bc, CT_ROM
        or      a
        sbc     hl, bc
        jr      nz, vst_2                       ; "OZ" not found
.vst_1
        ld      hl, ($bffe)                     ; verify read
        sbc     hl, bc
        jr      nz, vst_2

        ld      a, ($bffc)                      ; card size
        cp     $40                              ; handle this case (else is zero)
        ret     z
        cpl
        and     $3F                             ; a is last unused bank in slot
        cp      e                               ; bank to test
        ret     c                               ; size ok? ret

.vst_2
        ld      d, BU_NOT                       ; nothing inthe bank
        ret


.MountAllRAM
        call    MS2BankK1
        ld      hl, RAMDORtable
.maram_1
        ld      a, (hl)                         ; 21 21 40 80 c0  bank
        inc     hl
        or      a
        jr      z, maram_5
        call    MS1BankA
        ld      d, $40                          ; address high byte
        ld      e, (hl)                         ; 80 40 40 40 40  address low byte
        inc     hl
        ld      c, (hl)                         ;  -  0  1  2  3  RAM number
        inc     hl
        ld      a, c
        cp      '-'
        jr      z, maram_2
        ld      a, (de)                         ; skip if no RAM
        or      a
        jr      nz, maram_1
.maram_2
        push    hl
        ld      a, c
        cp      '-'                             ; !! combine with above check
        jr      z, maram_3
        ex      af, af'
        ld      hl, $4000
        ld      a, (ubResetType)                ; 0 = hard reset
        and     (hl)
        jr      nz, maram_4                     ; soft reset & already tagged, skip
        ex      af, af'
.maram_3
        ld      hl, RAMxDOR                     ; !! could be smaller without table
        ld      bc, 17
        ldir
        ld      (de), a
        inc     de
        ld      bc, 2                           ; just copy 00 FF
        ldir
        cp      '-'                             ; tag RAM if not RAM.-
        jr      z, maram_4
        ld      bc, CT_RAM
        ld      ($4000), bc
.maram_4
        pop     hl
        jr      maram_1
.maram_5
        ret

;       ----

;               bank, DOR address low byte, char

.RAMDORtable
        defb    $21,$80,'-'
        defb    $21,$40,'0'
        defb    $40,$40,'1'
        defb    $80,$40,'2'
        defb    $C0,$40,'3'
        defb    0


; *****************************************************************************************************
; Return Fc = 1, if less than 128K RAM was found in slot 0, 1 or 2.
; If expanded RAM was found (>=128K), then return Fc = 0, A = bottom bank of found RAM card.
;
.Chk128KB
        ld      a, (ubSlotRamSize+2)            ; RAM in slot 2
        cp      128/16
        ld      a, $80
        ret     nc

        ld      a, (ubSlotRamSize+1)            ; RAM in slot 1
        cp      128/16
        ld      a, $40
        ret     nc

.Chk128KBslot0
        ld      a, (ubSlotRamSize)              ; RAM in slot 0
        cp      128/16
        ld      a, $21
        ret

; **************************************************************************************************
; OS_Poll and OS_Nq process handle interface. The routines are located in Kernel 0.
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
; ***************************************************************************************************

        Module Process1

        include "error.def"
        include "saverst.def"
        include "sysvar.def"
        include "handle.def"
        include "z80.def"
        include "oz.def"

xdef    OSPoll, OSPloz
xdef    ClearUnsafeArea
xdef    ClearMemDE_HL
xdef    ChkStkLimits
xdef    Mailbox2Stack
xdef    OSNqProcess

xref    GetAppDOR                               ; [Kernel0]/mth0.asm
xref    NQAin                                   ; [Kernel0]/process2.asm
xref    PutOSFrame_BC                           ; [Kernel0]/memmisc.asm
xref    CopyMemBHL_DE                           ; [Kernel0]/memmisc.asm


;       ----

;       poll for an application
;IN:    IX=current application, 0 for start of list
;OUT:   IX=next application
;       Fc=0 if ok
;       Fc=1, A=error if fail

.OSPoll
        push    ix
        pop     bc
        call    getAppHandle
        ret     c
        push    bc
        pop     ix
        ret
.getAppHandle
        ld      a, c
IF OZ_SLOT1
        or      b
        ld      a, c
        jr      nz,next_app_id
        or      $40                             ; first app is in slot 1...
.next_app_id
ENDIF
        inc     a                               ; next application
        call    GetAppDOR                       ; go find it
        ld      c, a
        ld      b, 0
        ld      a, RC_Eof
        ret

;       ----

;       Poll for OZ usage in slot
;IN:    a=slot number (0-3)
;OUT:   Fz=0, if OZ is running in slot, otherwise Fz = 1
;       No registers changed except Fz
;
.OSPloz
        ld      c,a
        push    bc
        call    getAppHandle
        pop     hl                              ; L = slot number
        ret     c
        ld      a,c                             ; the low byte of the handle reveals the slot mask...
        and     @11000000                       ; keep only slot mask
        rlca
        rlca                                    ; slot mask -> slot number
        cp      l
        jr      nz, no_oz
        ret                                     ; OZ found, return Fz = 0 (preset on OZ entry)
.no_oz
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1, OZ not found
        ret


;       clear unsafe stack area

.ClearUnsafeArea
        ld      hl, $1FFE                       ; stack top
        ld      de, (pAppUnSafeArea)            ; unsafe area start

;       clear memory from DE (inclusive) to HL (exclusive)

.ClearMemDE_HL
        xor     a                               ; A=0, Fc=0
        sbc     hl, de
        ret     z                               ; HL=DE? exit
        add     hl, de                          ; restore HL
        ld      (de), a                         ; clear first byte
        inc     de
        sbc     hl, de
        ret     z                               ; HL=DE? exit
        ld      b, h                            ; BC=end-start
        ld      c, l
        ld      h, d                            ; HL=start
        ld      l, e
        dec     hl                              ; over zero byte
        ldir                                    ; copy forward, ie. zero fill
        ret

;       ----

;       check that stack pointer and unsafe area are within stack limits
;       freeze if either outside limits

.ChkStkLimits
        ld      hl, $1FFE                       ; upper limit
        ld      bc, $1820                       ; lower limit
        ld      de, (pAppStackPtr)
        call    ChkLimits
        jr      c, chkstk_1
        ld      de, (pAppUnSafeArea)
        call    ChkLimits
        ret     nc
.chkstk_1
        xor     a                               ; freeze
        jr      chkstk_1


.ChkLimits
        push    bc
        push    de                              ; !! can do without pushing DE
        push    hl
        or      a
        sbc     hl, de
        jr      c, chklm_1                      ; HL<DE? Fc=1
        ex      de, hl
        sbc     hl, bc                          ; DE<BC? Fc=1
.chklm_1
        pop     hl
        pop     de
        pop     bc
        ret

;       ----

;       copy mailbox data into low stack area
;       if $1852 contains $aa then $1811 is length of data starting at $1812
;       data length can't exceed 64 bytes

;
.Mailbox2Stack
        ld      hl, (pMailbox)
        ld      bc, (ubMailboxSize)             ; B=ubMailboxBank
        ld      a, c
        or      a                               ; !! 'dec a; cp 64; ld a,0; jr nc'
        jr      z, mb2s_1
        cp      MAILBOXMAXLEN+1
        ld      a, 0
        jr      nc, mb2s_1                      ; >64? exit
        ld      (ubMailboxLength), bc
        ld      de, MailboxData
        call    CopyMemBHL_DE
        ld      a, MAILBOXID                    ; mark as valid

.mb2s_1
        ld      (ubMailBoxID), a                ; store identifier
        ret

;       ----

.OSNqProcess
        cp      $1E                             ; range check
        ccf
        ld      a, RC_Unk
        ret     c

        ld      hl, OSNqPrcssTable
        add     hl, bc
        jp      (hl)

.OSNqPrcssTable
        jp      NQAin
        jp      NQKhn
        jp      NQShn
        jp      NQPhn
        jp      NQNhn
        jp      NQWai
        jp      NQCom
        jp      NQIhn
        jp      NQOhn
        jp      NQRhn

;       read keyboard handle
.NQKhn
        ld      ix, phnd_Khn
        ret

;       read screen handle
.NQShn
        ld      ix, phnd_Shn
        ret

;       read printer indirected handle
.NQPhn
        ld      ix, phnd_Phn
        ret

;       read null handle
.NQNhn
        ld      ix, phnd_Nhn
        ret

;       read comms handle
.NQCom
        ld      ix, phnd_Com
        ret

;       read IN handle
.NQIhn
        ld      ix, phnd_Ihn
        ret

;       read OUT handle
.NQOhn
        ld      ix, phnd_Ohn
        ret

;       read direct printer handle
.NQRhn
        ld      ix, phnd_Rhn
        ret

;       Who am I?
.NQWai
        ld      ix, (uwAppStaticHnd)
        ld      bc, (ubAppDynID)                ; !! just for C
        ld      b, 0
        jp      PutOSFrame_BC

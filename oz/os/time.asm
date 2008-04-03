; **************************************************************************************************
; OS_Ht & OS_Ust interfaces (hardware time handling)
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

        Module Time

        include "blink.def"
        include "error.def"
        include "sysvar.def"
        include "interrpt.def"
        ;include "z80.def"

xdef    OSHt
xdef    ReadRTC
xdef    OSUst

xref    OSFramePush                             ; [Kernel0]/stkframe.asm
xref    OSFramePop                              ; [Kernel0]/stkframe.asm
xref    PutOSFrame_BC                           ; [Kernel0]/memmisc.asm
xref    GetOSFrame_HL                           ; [Kernel0]/memmisc.asm
xref    PutOSFrame_HL                           ; [Kernel0]/memmisc.asm
xref    PokeHLinc                               ; [Kernel0]/memmisc.asm



.OSHt
        ld      b, a
        djnz    osht_rd

;       HT_RES, reset hardware timer
;chg:   AF....../....

.osht_res
        in      a, (BL_TIM0)                    ; wait until TIM0=0
        call    NormalizeTIM0
        jr      nz, osht_res

        ld      a, (BLSC_COM)                   ; reset timer
        or      BM_COMRESTIM
        out     (BL_COM), a
        and     ~BM_COMRESTIM
        out     (BL_COM), a
        ret

.osht_rd
        djnz    osht_mdt

;       HT_RD, read hardware timer
;IN:    HL=buffer, 5 bytes
;chg:   AF....../....

        push    hl                              ; copy hardware clock to stack buffer
        push    hl
        push    hl
        ld      hl, 0                           ; !! ld h,b; ld l,b
        add     hl, sp
        call    ReadRTC

        ld      c, 5                            ;  copy into caller buffer
        ex      de, hl
        call    GetOSFrame_HL
.htrd_1
        ld      a, (de)
        inc     de
        call    PokeHLinc
        dec     c
        jr      nz, htrd_1
        pop     hl                              ; purge stack
        pop     hl
        pop     hl
        or      a
        ret

.osht_mdt
        djnz    osht_x

;       HT_MDT, read month/date/time address in S2
;       OUT:   BHL points to MDT (11 bytes)
;       NB : it is always $2001EB (and was$2180AB in OZ4)

        or      a                               ; at $2001EB (was $2180AB)
        ld      (iy+OSFrame_B), $20             ; to define correctly (OSRAM_BANK) ?
        ld      hl, uwSysDateLow                ; was $80AB
        jp      PutOSFrame_HL

.osht_x
        ld      a, RC_Unk
        scf
        ret

;       ----

;IN:    HL=buffer[5]
;chg:   ABCD..../....

.ReadRTC
        ld      bc, 5<<8|BL_TIM0
        ld      d, -1                           ; check for same value
        push    hl
.rrtc_1
        in      a, (c)
        cp      (hl)
        ld      (hl), a
        jr      z, rrtc_2
        inc     d                               ; mark as different
.rrtc_2
        inc     hl                              ; inc pointer
        inc     c                               ; inc port
        djnz    rrtc_1
        pop     hl
        inc     d
        jr      nz, ReadRTC                     ; loop until changed

        ld      a, (hl)
        call    NormalizeTIM0
        ld      (hl), a
        ret

;       ----

;IN:    A=TICK value
;OUT:   A=0.01 sec value
;chg:   AF....../....

.NormalizeTIM0
        xor     $80                             ; -128
        jp      p, ntim0_1                      ; no underflow, skip
        add     a, 200                          ; make positive
.ntim0_1
        srl     a                               ; /2 to make it 0.01s clock
        ret


;       -------------------------------------------------------------------
;       update small timer
;
;       old timer(BC)=new timer(BC)
;       Fz according to old time, A=EC_Time if Fz=1

.OSUst
        call    OSFramePush
        ld      hl, 0
        ld      de, (uwSmallTimer)              ; small  timer
        ld      (uwSmallTimer), hl              ; reset
        ld      hl, ubIntTaskToDo
        res     ITSK_B_TIMER, (hl)
        ld      (uwSmallTimer), bc              ; set new time
        ld      b, d                            ; restore old value
        ld      c, e
        call    PutOSFrame_BC

        ld      a, b
        or      c
        jr      nz, osust_1
        ld      (iy+OSFrame_A), RC_Time         ; Timeout
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1
.osust_1
        jp      OSFramePop
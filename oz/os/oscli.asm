; **************************************************************************************************
; OS_Cli interface (kernel 1)
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

        Module OSCli

        include "error.def"
        include "sysvar.def"
        include "oz.def"
        include "z80.def"
        include "interrpt.def"
        include "keyboard.def"

        include "lowram.def"

xdef    OSCli

xref    OSFramePop                              ; [Kernel0]/stkframe.asm
xref    OSFramePush                             ; [Kernel0]/stkframe.asm
xref    AtoN_upper                              ; [Kernel0]/memmisc.asm
xref    PutOSFrame_BC                           ; [Kernel0]/memmisc.asm
xref    PutOSFrame_DE                           ; [Kernel0]/memmisc.asm
xref    SetPendingOZwd                          ; [Kernel0]/misc3.asm
xref    RdKbBuffer                              ; [Kernel0]/osin.asm
xref    ExtQualifiers                           ; [Kernel0]/kbd.asm

xref    CLI2KeyTable                            ; [Kernel1]/clitables.asm
xref    Key2MetaTable                           ; [Kernel1]/clitables.asm

.OSCli
        ex      af, af'
        or      a
        jr      z, oscli_0                      ; !! undocumented reason 0
        ex      af, af'
        call    OSFramePush
        ld      h, b                            ; exchange A and B
        ld      b, a
        ld      a, h
        call    OSCliMain
        jp      OSFramePop

;       A=0 - return CLIActiveCnt and KbdData

.oscli_0
        ld      a, (ubCLIActiveCnt)
        ld      ix, KbdData
        jp      OZCallReturn2                   ; ret with AFbcdehl

.OSCliMain
        ld      hl, ubCLIActiveCnt
        or      a                               ; Fc=0

.oscli_rim
        djnz    oscli_mbc
        ld      b, a
        call    RdKbBuffer                      ; get raw input
        call    PutOSFrame_BC                   ; return timeout
        jr      climbc_1

.oscli_mbc
        djnz    oscli_cmb
        ld      a, e                            ; meta/base to character conversion
        cp      $20                             ; if ctlr char, translate to keycode
        call    c, CLIchar2key                  ; !! nop, all inchars alphabetic
        bit     QUAL_B_SPECIAL, d
        call    nz, CLIchar2key                 ; special key? translate to keycode
        ld      b, -1                           ; external call identifier
        call    ExtQualifiers                   ; translate A with qualifiers D

.climbc_1
        ld      d, 0                            ; clear qualifiers
.climbc_2
        ret     c                               ; return error
        ld      e, a                            ; else char just read/translated
        jp      PutOSFrame_DE

.oscli_cmb
        djnz    oscli_inc
        ld      a, e                            ; character to meta/base conversion
        call    Key2Meta
        jr      climbc_2                        ; return key and qualifiers

.oscli_inc
        djnz    oscli_dec
        ld      a, (hl)                         ; increment CLI use count
        or      a
        jr      nz, cliinc_1

        push    hl                              ; first active CLI, reset flags
        ld      hl, ubIntStatus
        res     IST_B_CLISHIFT, (hl)
        res     IST_B_CLIDMND, (hl)
        pop     hl

.cliinc_1
        inc     (hl)
        jr      clires_1

.oscli_dec
        djnz    oscli_res
        dec     (hl)                            ; decrement CLI use count
        jr      clires_1

.oscli_res
        djnz    oscli_ack
        ld      (hl), 0                         ; reset CLI use count !! ld (hl), b

.clires_1
        jp      SetPendingOZwd

.oscli_ack
        djnz    oscli_x
        ld      hl, ubIntStatus                 ; acknowledge CLI/Escape
        bit     QUAL_B_CTRL, d                  ; !! bits match, use ld a,d; and 3; cpl; and (hl); ld (hl),a
        jr      z, cliack_1
        res     IST_B_CLIDMND, (hl)
.cliack_1
        bit     QUAL_B_SHIFT, d
        jr      z, cliack_2
        res     IST_B_CLISHIFT, (hl)
.cliack_2
        ld      a, (hl)                         ; return A=resulting shift/ctrl status, Fz=1 if neither active
        and     IST_CLISHIFT|IST_CLIDMND
        ld      (iy+OSFrame_D), a
        ret     nz
        set     Z80F_B_Z, (iy+OSFrame_F)
        ret

.oscli_x
        ld      a, RC_Unk
        scf
        ret

;       ----

;       this is branched into from below

.cc2k_1
        ld      a, (hl)
        or      a
        ret

;       translate char after '~' into keycode
;       A=translate(A)

.CLIchar2key
        call    AtoN_upper
        ld      bc, (CLI2KeyTable)
        ld      b,0
        ld      hl, CLI2KeyTable+1
.cc2k_2
        cpir
        ret     nz
        bit     0, c
        jr      nz, cc2k_1                      ; found at even offset, return byte
        jp      pe, cc2k_2                      ; loop if not end
        ret


;       translate keyboard code into meta char
;       A,D=translate(A)

.Key2Meta
        ld      hl, Key2MetaTable               ; !! ld hl,tbl-2; inc hl; inc hl
.k2m_1
        cp      (hl)
        inc     hl
        jr      nc, k2m_2                       ; found key area, translate
        inc     hl                              ; try next
        inc     hl
        jr      k2m_1
.k2m_2
        ld      d, (hl)                         ; qualifier
        inc     hl
        ld      l, (hl)                         ; address low byte
        ld      h, >Key2MetaTable               ; address high byte (was crsr)
        inc     l
        dec     l
        ret     z                               ; return if no table
        and     (hl)                            ; mask to range
        add     a, l                            ; and point to char
        ld      l, a
        inc     hl                              ; skip mask byte
        ld      a, (hl)                         ; return meta char
        ret

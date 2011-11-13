; **************************************************************************************************
; Handle functions in kernel 1
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

        Module Handle1

        include "dor.def"
        include "error.def"
        include "memory.def"
        include "sysvar.def"
        include "oz.def"
        include "handle.def"

xdef    OSFnMain
xdef    InitHandle
xdef    RAMxDOR                                 ; MountAllRAM

xref    AllocHandle                             ; [Kernel0]/handle0.asm
xref    VerifyHandle                            ; [Kernel0]/handle0.asm
xref    FreeHandle                              ; [Kernel0]/handle0.asm
xref    GetDORType                              ; [Kernel0]/dor.asm
xref    S2VerifySlotType                        ; [Kernel0]/memmisc.asm


.OSFnMain
        ld      h, b                            ; exg a,b
        ld      b, a
        ld      a, h

        djnz    osfn_vh

;       FN_AH, allocate handle

;IN:    B=type
;OUT:   Fc=0, IX=handle
;       Fc=1, A=error

        jp      AllocHandle

.osfn_vh
        djnz    osfn_fh

;       FN_VH, verify handle
;IN:    IX=handle, B=type
;OUT:   Fc=0 if OK
;       Fc=1, A=error

        jp      VerifyHandle

.osfn_fh
        djnz    osfn_unk

;       FN_FH, free handle
;IN:    IX=handle, B=type
;OUT:   Fc=0 if OK
;       Fc=1, A=error

        jp      FreeHandle

.osfn_unk
        ld      a, RC_Unk
        scf
        ret

;       ----

.InitHandle
        call    FindHandleDOR
        ret     c                               ; error? exit

        ld      (ix+dhnd_DeviceID), a
        bit     7, a
        jr      z, inh_1                        ; not ROM? skip

        push    af                              ; low 2 bits to top
        dec     a
        rrca
        rrca
        and     $C0
        ld      (ix+dhnd_AppSlot), a            ; application handle start
        pop     af

.inh_1
        ld      (ix+dhnd_DORBank), b
        ld      (ix+dhnd_DORH), h
        ld      (ix+dhnd_DOR), l

        dec     a
        jr      z, inh_2                        ; RAM.-? skip !! why not longer?

        or      $10                             ; !! 'rlca; rlca; rlca; or $80' for clarity
        rlca
        rlca
        rlca

.inh_2
        and     $F8                             ; mask out low bits
        or      c                               ; low bits: RAM=01, others=11
        ld      (ix+dhnd_flags), a
        jp      GetDORType

;       ----

;       defb    ID
;       defp    DOR address in S2

.DevTable
        defb    1
        defp    $8080,$21                       ; RAM.-

        defb    2
        defp    $8040,$40                       ; RAM.1

        defb    3
        defp    $8040,$80                       ; RAM.2

        defb    4
        defp    $8040,$C0                       ; RAM.3

        defb    5
        defp    $8040,$21                       ; RAM.0

        defb    6                               ; SCR.0
        defp    Scr_dor, OZBANK_KNL1

        defb    7
        defp    Prt_dor, OZBANK_KNL1

        defb    8
        defp    Com_dor, OZBANK_KNL1

        defb    9
        defp    Nul_dor, OZBANK_KNL1

        defb    10
        defp    Inp_dor, OZBANK_KNL1

        defb    11
        defp    Out_dor, OZBANK_KNL1

IF !OZ_SLOT1
; ROM.0 application DOR's only exist when compiling OZ for slot 0
; - booting OZ in slot 1 must ignore all applications in slot 0 due conflict with same applications in slot 1

        defb    $81
        defp    Rom0_dor, OZBANK_KNL1
ENDIF

        defb    $82
        defp    Rom1_dor, OZBANK_KNL1

        defb    $83
        defp    Rom2_dor, OZBANK_KNL1

        defb    $84
        defp    Rom3_dor, OZBANK_KNL1

        defb    0

;       ----

;IN:    A=ID-1
;OUT:   Fc=0, BHL=DOR address
;       Fc=1, A=error if fail
;chg:   ABCDEHL/....

.FindHandleDOR
        inc     a
        ld      c, a

        ld      hl, DevTable-1
.fhd_1
        inc     hl
        ld      a, (hl)                         ; device ID
        or      a
        jr      z, fhd_6                        ; end? error

        inc     hl
        ld      e, (hl)                         ; DE = DOR address
        inc     hl
        ld      d, (hl)
        inc     hl

        cp      c
        jr      c, fhd_1                        ; smaller than wanted? loop

        ld      b, a
        dec     a
        jr      z, fhd_4                        ; RAM.-? C=1

        cp      5
        jr      nc, fhd_2                       ; not RAM.x? skip

        and     3                               ; RAM.0123
        exx
        add     a, <ubSlotRamSize               ; !! 'ld hl, ubSlotRamSize; add a, l; ld l, a'
        ld      l, a
        ld      h, >ubSlotRamSize
        ld      a, (hl)
        exx
        or      a
        jr      z, fhd_1                        ; no RAM? loop
        xor     a                               ; C=1
        jr      fhd_4

.fhd_2
        cp      $81
        jr      c, fhd_3                        ; SCR|PRT|COM|NUL|INP|OUT? C=3
        cp      $84
        jr      nc, fhd_3                       ; not ROM0123? C=3
        exx
        ld      d, a                            ; slot
        ld      e, $3F                          ; test last bank
        call    S2VerifySlotType
        bit     BU_B_ROM, d                     ; is application rom ?
        exx
        jr      z, fhd_1

.fhd_3
        xor     a                               ; !! C could be set much easier...
        inc     a                               ; C=3

.fhd_4
        ld      c, 1
        jr      z, fhd_5
        ld      c, 3

.fhd_5
        ld      a, b                            ; device ID
        ld      b, (hl)                         ; third attribute byte
        ex      de, hl                          ; HL=attribute word
        or      a
        ret
.fhd_6
        ld      a, RC_Fail
        scf
        ret

.Scr_dor
        defb    6,$86,0, 0,0,0, 0,0,0
        defb    DM_CHD, 9
        defb    DT_NAM, 6
        defm    "SCR.0",0
        defb    $FF

.Prt_dor
        defb    9,$86,0, 0,0,0, 0,0,0
        defb    DM_CHD, 9
        defb    DT_NAM, 6
        defm    "PRT.0",0
        defb    $FF

.Com_dor
        defb    $1E,$8C,0, 0,0,0, 0,0,0
        defb    DM_CHD, 9
        defb    DT_NAM, 6
        defm    "COM.0",0
        defb    $FF

.Nul_dor
        defb    $0C,$86,0, 0,0,0, 0,0,0
        defb    DM_CHD, 9
        defb    DT_NAM, 6
        defm    "NUL.0",0
        defb    $FF

.Inp_dor
        defb    $15,$86,0, 0,0,0, 0,0,0
        defb    DM_CHD, 9
        defb    DT_NAM, 6
        defm    "INP.0",0
        defb    $FF

.Out_dor
        defb    $18,$86,0, 0,0,0, 0,0,0
        defb    DM_CHD, 9
        defb    DT_NAM, 6
        defm    "OUT.0",0
        defb    $FF

IF !OZ_SLOT1
; ROM.0 application DOR's only exist when compiling OZ for slot 0
; - booting OZ in slot 1 must ignore all applications in slot 0 due conflict with same in slot 1

.Rom0_dor
        defp    0, 0                            ; Use last bank of slot 0 ($1F), this allow to use larger ROM than 128K
        defp    0, 0                            ; (up to 512K is allowed)
        defp    $BFC0, $1F                      ; (point at ROM Front DOR in top of bottom half of slot 0)
        defb    DM_ROM, 9
        defb    DT_NAM, 6
        defm    "ROM.0",0
        defb    $FF
ENDIF

.Rom1_dor
        defp    0, 0
        defp    0, 0
        defp    $BFC0, $7F                      ; (point at ROM Front DOR in top of slot 1)
        defb    DM_ROM, 9
        defb    DT_NAM, 6
        defm    "ROM.1",0
        defb    $FF

.Rom2_dor
        defp    0, 0
        defp    0, 0
        defp    $BFC0, $BF                      ; (point at ROM Front DOR in top of slot 2)
        defb    DM_ROM, 9
        defb    DT_NAM, 6
        defm    "ROM.2",0
        defb    $FF

.Rom3_dor
        defp    0, 0
        defp    0, 0
        defp    $BFC0, $FF                      ; (point at ROM Front DOR in top of slot 3)
        defb    DM_ROM, 9
        defb    DT_NAM, 6
        defm    "ROM.3",0
        defb    $FF

.RAMxDOR
        defb    $FF,0,0, 0,0,0, 0,0,0
        defb    DM_DEV
        defb    9
        defb    DT_NAM, 6
        defm    "RAM."
                                        ; one byte filled in
        defb 0,$FF

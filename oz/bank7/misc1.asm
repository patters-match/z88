; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d670
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc1

        include "dor.def"
        include "error.def"
        include "sysvar.def"

xdef    RAMDORtable                             ; MountAllRAM
xdef    InitHandle                              ; OSDor, E9E8+D
xdef    RAMxDOR                                 ; MountAllRAM

xref    loc_CD42                                ; bank0/dor.asm
xref    S2VerifySlotType                        ; bank0/misc5.asm

;       ----

;               bank, DOR address low byte, char

.RAMDORtable
        defb    $21,$80,'-'
        defb    $21,$40,'0'
        defb    $40,$40,'1'
        defb    $80,$40,'2'
        defb    $C0,$40,'3'
        defb    0

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
        jp      loc_CD42

;       ----

;       defb    ID
;       defp    DOR address in S2

.DevTable
        defb    1, $80,$80,$21                  ; RAM.-
        defb    2, $40,$80,$40                  ; RAM.1
        defb    3, $40,$80,$80                  ; RAM.2
        defb    4, $40,$80,$C0                  ; RAM.3
        defb    5, $40,$80,$21                  ; RAM.0

        defb    6                               ; SCR.0
        defp    Scr_dor,7

        defb    7
        defp    Prt_dor,7

        defb    8
        defp    Com_dor,7

        defb    9
        defp    Nul_dor,7

        defb    10
        defp    Inp_dor,7

        defb    11
        defp    Out_dor,7

        defb    $81
        defp    Rom0_dor,7

        defb    $82
        defp    Rom1_dor,7

        defb    $83
        defp    Rom2_dor,7

        defb    $84
        defp    Rom3_dor,7

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
        ld      d, a
        ld      e, $3F
        call    S2VerifySlotType
        bit     ST_B_APPLROM, d
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

.Rom0_dor
        defb    0,0,0, 0,0,0, $C0,$BF,$07
        defb    DM_ROM, 9
        defb    DT_NAM, 6
        defm    "ROM.0",0
        defb    $FF

.Rom1_dor
        defb    0,0,0, 0,0,0, $C0,$BF,$7F
        defb    DM_ROM, 9
        defb    DT_NAM, 6
        defm    "ROM.1",0
        defb    $FF

.Rom2_dor
        defb    0,0,0, 0,0,0, $C0,$BF,$BF
        defb    DM_ROM, 9
        defb    DT_NAM, 6
        defm    "ROM.2",0
        defb    $FF

.Rom3_dor
        defb    0,0,0, 0,0,0, $C0,$BF,$FF
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

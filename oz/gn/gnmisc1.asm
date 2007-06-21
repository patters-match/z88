; -----------------------------------------------------------------------------
; Bank 3 @ S3
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNMisc1

        include "blink.def"
        include "sysvar.def"
        include "../os/lowram/lowram.def"

;       ----

xdef    GN_ret0
xdef    GN_ret1a
xdef    GN_ret1c
xdef    Ld_A_HL
xdef    Ld_DE_A


xref    GNAab
xref    GNAlp
xref    GNCl
xref    GNCls
xref    GNCme
xref    GND16
xref    GND24
xref    GNDei
xref    GNDel
xref    GNDie
xref    GNErr
xref    GNEsa
xref    GNEsp
xref    GNFab
xref    GNFcm
xref    GNFex
xref    GNFlc
xref    GNFlf
xref    GNFlo
xref    GNFlr
xref    GNFlw
xref    GNFpb
xref    GNGdn
xref    GNGdt
xref    GNGmd
xref    GNGmt
xref    GNGtm
xref    GNLab
xref    GNM16
xref    GNM24
xref    GNMsc
xref    GNNln
xref    GNOpf
xref    GNOpw
xref    GNPdn
xref    GNPdt
xref    GNPfs
xref    GNPmd
xref    GNPmt
xref    GNPrs
xref    GNPtm
xref    GNRbe
xref    GNRen
xref    GNSdo
xref    GNSip
xref    GNSkc
xref    GNSkd
xref    GNSkt
xref    GNSoe
xref    GNSop
xref    GNUab
xref    GNWbe
xref    GNWcl
xref    GNWfn
xref    GNWsm
xref    GNXdl
xref    GNXin
xref    GNXnx

;       ----

        jp      GN_Exit
.GN_Exit
        jp      GN_ret1b

        defw    GNGdt
        defw    GNPdt
        defw    GNGtm
        defw    GNPtm

        defw    GNSdo
        defw    GNGdn
        defw    GNPdn
        defw    GNDie
        defw    GNDei
        defw    GNGmd
        defw    GNGmt
        defw    GNPmd
        defw    GNPmt
        defw    GNMsc

        defw    GNFlo
        defw    GNFlc
        defw    GNFlw
        defw    GNFlr
        defw    GNFlf
        defw    GNFpb
        defw    GNNln
        defw    GNCls
        defw    GNSkc
        defw    GNSkd
        defw    GNSkt
        defw    GNSip
        defw    GNSop
        defw    GNSoe
        defw    GNRbe
        defw    GNWbe
        defw    GNCme
        defw    GNXnx
        defw    GNXin
        defw    GNXdl
        defw    GNErr
        defw    GNEsp
        defw    GNFcm
        defw    GNFex
        defw    GNOpw
        defw    GNWcl
        defw    GNWfn
        defw    GNPrs
        defw    GNPfs
        defw    GNWsm
        defw    GNEsa
        defw    GNOpf
        defw    GNCl
        defw    GNDel
        defw    GNRen
        defw    GNAab
        defw    GNFab
        defw    GNLab
        defw    GNUab
        defw    GNAlp

        defw    GNM16
        defw    GND16
        defw    GNM24
        defw    GND24

;       ----

;IN:    HL=user space address
;OUT:   A=byte
;
;       AF....../.... af....

.Ld_A_HL
        bit     7, h
        jr      z, ldahl_2                      ; S0 or S1? just read byte

        ld      a, (BLSC_SR2)                   ; remember old S2 binding
        ex      af, af'
        bit     6, h                            ; select saved S2 or S3
        ld      a, (iy+OSFrame_S2)
        jr      z, ldahl_1
        ld      a, (iy+OSFrame_S3)
.ldahl_1
        call    BindS2_A
        push    hl
        set     7, h                            ; S2 fix
        res     6, h
        ld      a, (hl)                         ; read byte
        pop     hl
        ex      af, af'                         ; restore S2 binding
        call    BindS2_A
        ex      af, af'
        ret
.ldahl_2
        ld      a, (hl)
        ret

;       ----

;IN:    A=byte, DE=user space address
;OUT:
;
;       AF....../.... af....

.Ld_DE_A
        bit     7, d
        jr      z, lddea_2                      ; S0 or S1? just write byte

        ex      af, af'                         ; remember old S2 binding
        ld      a, (BLSC_SR2)
        push    af

        bit     6, d                            ; select saved S2 or S3
        ld      a, (iy+OSFrame_S2)
        jr      z, lddea_1
        ld      a, (iy+OSFrame_S3)
.lddea_1
        call    BindS2_A
        push    de
        set     7, d                            ; S2 fix
        res     6, d
        ex      af, af'
        ld      (de), a                         ; write byte
        ex      af, af'
        pop     de
        pop     af                              ; restore S2 binding
        call    BindS2_A
        ex      af, af'
        ret
.lddea_2
        ld      (de), a
        ret

;       ----

;       Function return routines

.GN_ret1a
        pop     hl
        pop     iy
        pop     bc
        pop     hl
        pop     hl
        jr      GN_ret1x
.GN_ret1b
        pop     iy
        pop     bc
        pop     hl
        pop     af
.GN_ret1x
        ex      af, af'
        call    BindS2_C
        ex      af, af'
        pop     bc
        pop     de
        pop     hl
        jp      OZCallReturn1

.GN_ret1c
        exx
        pop     bc
        pop     iy
        pop     bc
        ex      af, af'
        call    BindS2_C
        ex      af, af'
        pop     bc
        pop     bc
        pop     bc
        pop     bc
        pop     bc
        exx
        jp      OZCallReturn1

.GN_ret0
        pop     bc
        pop     iy
        pop     bc
        ex      af, af'
        call    BindS2_C
        ex      af, af'
        pop     bc
        pop     bc
        pop     bc
        pop     de
        pop     hl
        jp      OZCallReturn0

;       ----

;       !! inline this for speed

.BindS2_C
        ld      a, c
.BindS2_A
        ld      (BLSC_SR2), a
        out     (BL_SR2), a
        ret

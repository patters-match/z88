; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $0c000
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNMisc1

        org $c000                               ; 264 bytes

        include "all.def"
        include "sysvar.def"

defc    OZ_RET1 =$0048
defc    OZ_RET0 =$004b

defc    GNGdt   =$C108
defc    GNPdt   =$C314
defc    GNGtm   =$C490

defc    GNPtm   =$C5CD
defc    GNSdo   =$C9CB
defc    GNGdn   =$C6C1
defc    GNPdn   =$C769
defc    GNDie   =$C891
defc    GNDei   =$C899
defc    GNGmd   =$C8A3
defc    GNGmt   =$C8AD
defc    GNPmd   =$C8DD
defc    GNPmt   =$C946
defc    GNMsc   =$CA72
defc    GNFlo   =$CB95
defc    GNFlc   =$CC70
defc    GNFlw   =$CCB4
defc    GNFlr   =$CCF9
defc    GNFlf   =$CE93
defc    GNFpb   =$CF00
defc    GNNln   =$CF40
defc    GNCls   =$CF49
defc    GNSkc   =$CF4F
defc    GNSkd   =$CF62
defc    GNSkt   =$CF87
defc    GNSip   =$CFB3
defc    GNSop   =$D3C2
defc    GNSoe   =$D3D7
defc    GNRbe   =$D435
defc    GNWbe   =$D3FD
defc    GNCme   =$D46E
defc    GNXnx   =$D4BC
defc    GNXin   =$D4E4
defc    GNXdl   =$D5D3
defc    GNErr   =$D667
defc    GNEsp   =$D7D0
defc    GNFcm   =$D9FE
defc    GNFex   =$DA0B
defc    GNOpw   =$DADD
defc    GNWcl   =$DB60
defc    GNWfn   =$DBAD
defc    GNPrs   =$DED3
defc    GNPfs   =$DF38
defc    GNWsm   =$E03E
defc    GNEsa   =$E13A
defc    GNOpf   =$DD1A
defc    GNCl    =$DDE2
defc    GNDel   =$DE9D
defc    GNRen   =$DDE8
defc    GNAab   =$E4DA
defc    GNFab   =$E4F4
defc    GNLab   =$E50A
defc    GNUab   =$E62E
defc    GNAlp   =$E6DD
defc    GNM16   =$E841
defc    GND16   =$E848
defc    GNM24   =$E85E
defc    GND24   =$E865

 IF 0
xref    OZ_RET0
xref    OZ_RET1

xref    GNGdt
xref    GNPdt
xref    GNGtm
xref    GNPtm

xref    GNSdo
xref    GNGdn
xref    GNPdn
xref    GNDie
xref    GNDei
xref    GNGmd
xref    GNGmt
xref    GNPmd
xref    GNPmt
xref    GNMsc

xref    GNFlo
xref    GNFlc
xref    GNFlw
xref    GNFlr
xref    GNFlf
xref    GNFpb
xref    GNNln
xref    GNCls
xref    GNSkc
xref    GNSkd
xref    GNSkt
xref    GNSip
xref    GNSop
xref    GNSoe
xref    GNRbe
xref    GNWbe
xref    GNCme
xref    GNXnx
xref    GNXin
xref    GNXdl
xref    GNErr
xref    GNEsp
xref    GNFcm
xref    GNFex
xref    GNOpw
xref    GNWcl
xref    GNWfn
xref    GNPrs
xref    GNPfs
xref    GNWsm
xref    GNEsa
xref    GNOpf
xref    GNCl
xref    GNDel
xref    GNRen
xref    GNAab
xref    GNFab
xref    GNLab
xref    GNUab
xref    GNAlp

xref    GNM16
xref    GND16
xref    GNM24
xref    GND24
 ENDIF

xdef    Ld_A_HL
xdef    Ld_DE_A
xdef    GN_ret1a
xdef    GN_ret1c
xdef    GN_ret0

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
        jr      z, ldahl_2      ; S0 or S1? just read byte

        ld      a, (BLSC_SR2)   ; remember old S2 binding
        ex      af, af'
        bit     6, h            ; select saved S2 or S3
        ld      a, (iy+OSFrame_S2)
        jr      z, ldahl_1
        ld      a, (iy+OSFrame_S3)
.ldahl_1
        call    BindS2_A
        push    hl
        set     7, h            ; S2 fix
        res     6, h
        ld      a, (hl)         ; read byte
        pop     hl
        ex      af, af'         ; restore S2 binding
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
        jr      z, lddea_2      ; S0 or S1? just write byte

        ex      af, af'         ; remember old S2 binding
        ld      a, (BLSC_SR2)
        push    af

        bit     6, d            ; select saved S2 or S3
        ld      a, (iy+OSFrame_S2)
        jr      z, lddea_1
        ld      a, (iy+OSFrame_S3)
.lddea_1
        call    BindS2_A
        push    de
        set     7, d            ; S2 fix
        res     6, d
        ex      af, af'
        ld      (de), a         ; write byte
        ex      af, af'
        pop     de
        pop     af              ; restore S2 binding
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
        jp      OZ_RET1

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
        jp      OZ_RET1

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
        jp      OZ_RET0

;       ----

;       !! inline this for speed

.BindS2_C
        ld      a, c
.BindS2_A
        ld      (BLSC_SR2), a
        out     (BL_SR2), a
        ret

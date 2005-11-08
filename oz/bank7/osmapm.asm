; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1de03
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSMapM

        org $9e03                               ; 288 bytes

        include "blink.def"
        include "error.def"
        include "stdio.def"
        include "syspar.def"
        include "sysvar.def"

xdef    OSMapMain

;       bank 0

xref    Chk128KB
xref    GetWindowFrame
xref    KPrint
xref    PeekHLinc
xref    PokeBHL
xref    PutOSFrame_BC
xref    ScreenClose
xref    ScreenOpen

;       bank 7

xref    GetCurrentWdInfo
xref    RestoreActiveWd

;       ----

.OSMapMain
        ld      b, c
        djnz    osmap_def
        push    hl                              ; write a line to the map
        ex      af, af'
        call    ScreenOpen
        ex      af, af'
        call    GetWindowFrame
        ld      b, 0                            ; BC=(rmargin+1)&$fffe
        ld      c, (ix+wdf_rmargin)
        inc     bc
        res     0, c
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        jr      c, osmap_3                      ; GetWindowFrame failed? exit
        ld      a, e                            ; mask row to 6 bits
        and     $3F
        ld      hl, 8                           ; prepare for entry
        sbc     hl, bc
.osmap_1
        add     hl, bc
        sub     8
        jr      nc, osmap_1
        push    bc
        ld      c, a                            ; row
        ld      b, $FF
        add     hl, bc
        ld      a, (BLSC_PB2L)
        and     1
        rrca
        rrca
        rrca
        ld      d, a
        ld      e, 0
        add     hl, de
        ex      de, hl
        pop     hl                              ; BC*=32
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      b, h
        pop     hl
.osmap_2
        push    bc
        call    PeekHLinc
        ex      de, hl
        push    af
        ld      a, (BLSC_PB2H)
        rra
        ld      a, (BLSC_PB2L)
        rra
        ld      b, a
        pop     af
        call    PokeBHL
        ld      bc, 8
        add     hl, bc
        ex      de, hl
        pop     bc
        djnz    osmap_2
        or      a
        push    hl
.osmap_3
        pop     hl
        ret
.osmap_def
        djnz    osmap_gra
.osmap_5
        ex      af, af'                         ; define a map using the Panel default width
        call    ScreenOpen
        ex      af, af'
        call    GetWindowFrame
        jr      c, osmap_7
        call    sub_9EBC
        jr      c, osmap_6
        push    bc
        push    de
        call    KPrint
        defm    1,"7#",0
        ld      a, (iy+OSFrame_A) ; window A
        OZ      OS_Out
        ld      a, $7E                          ; x
        sub     c
        OZ      OS_Out
        ld      a, $20                          ; y
        OZ      OS_Out
        add     a, c                            ; width
        OZ      OS_Out
        call    GetCurrentWdInfo

        call    KPrint
        defm    "(",$60
        defm    1,"2C",0

        ld      a, (iy+OSFrame_A)
        OZ      OS_Out
        call    RestoreActiveWd
        pop     de
        pop     bc
        ld      (ix+wdf_rmargin), d
.osmap_6
        or      a
.osmap_7
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        jp      PutOSFrame_BC
.osmap_gra
        dec     b
        jr      z, osmap_5                      ; gra
        djnz    osmap_err
        or      a                               ; del
        ret
.osmap_err
        ld      a, RC_Unk                       ; Unknown request (parameter in register) *
        scf
        ret
;       ----
.sub_9EBC
        call    sub_9F0C
        ld      bc, 0
        ret     c
        ld      a, l
        cp      'Y'
        scf
        ret     nz
        call    sub_9EF6
        ld      bc, 0
        ret     c
        inc     l
        dec     l
        scf
        ret     z
        ld      a, l
        cp      $61
        jr      c, loc_9EDF
        call    Chk128KB
        jr      nc, loc_9EDF
        ld      l, $60
.loc_9EDF
        ld      a, l
        add     a, 7
        jr      nc, loc_9EE8
        ld      a, $FF
        jr      loc_9EEA
.loc_9EE8
        and     $F8
.loc_9EEA
        ld      d, a
        dec     a
        ld      c, 0
.loc_9EEE
        inc     c
        sub     6
        jr      nc, loc_9EEE
        ld      b, l
        or      a
        ret

;       ----
.sub_9EF6
        ld      l, (iy+OSFrame_L)
        ld      a, (iy+OSFrame_C)
        cp      3
        ret     z
        ld      bc, PA_Msz                      ; map size in pixels
        call    sub_9F17
        ret     c
        ld      a, h
        or      a
        ret     z
        ld      l, $FF
        ret

;       ----
.sub_9F0C
        ld      l, 'Y'
        ld      a, (iy+OSFrame_C)
        cp      3
        ret     z
        ld      bc, PA_Map                      ; PipeDream map 'Y' or 'N'

;       ----
.sub_9F17
        push    hl
        ld      hl, 0
        add     hl, sp
        ex      de, hl
        ld      a, 2
        OZ      OS_Nq
        pop     hl
        ret

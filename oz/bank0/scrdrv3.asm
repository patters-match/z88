; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $390c
;
; $Id$
; -----------------------------------------------------------------------------

        Module ScrDrv3

        include "sysvar.def"

xdef    InitApplWd
xdef    InitSBF
xdef    InitWindowFrame
xdef    ResetWdAttrs

xref    DrawOZwd                                        ; bank0/ozwindow.asm
xref    KPrint                                          ; bank0/misc5.asm

xref    Zero_ctrlprefix                                 ; bank7/scrdrv1.asm



.InitOZwd
        call    KPrint
        defm    1,"7#8",$80+104,$20+0,$20+4,$20+8,$40   ; window 8 @+104,0 4x8 $40
        defm    1,"2C8"                                 ; select & clear 8
        defm    1,"6#7",$80+0,$20+0,$20+10,$20+8        ; window 7 @+0,0 10x8
        defm    0

.InitApplWd
        call    KPrint
        defm    1,"6#1",$80+10,$20+0,$20+94,$20+8       ; window 1 @abs10,0 94x8
        defm    1,"2I1"                                 ; select & init 1
        defm    0
        ret

.InitSBF
        ld      hl, Wd1Frame
        ld      (sbf_ActiveWd), hl
        call    Zero_ctrlprefix
        call    InitOZwd
        call    KPrint
        defm    1,"3+CS"
        defm    0
        jp      DrawOZwd


;IN:    A=flagsF4, B=height, C=width, D=ypos, E=xpos

.InitWindowFrame
        ex      af, af'
        ld      a, e
        sla     a
        cp      2*108
        ccf
        ret     c                               ; x>=108? error
        ld      e, a

        ld      a, d
        cp      8
        ccf
        ret     c                               ; y>8? error
        add     a, SBF_PAGE
        ld      d, a

        dec     b                               ; lst_row=ypos+height-1
        ld      a, b                            ; !! add a,b
        add     a, d
        ret     c
        ld      b, a
        ld      a, SBF_PAGE                     ; !! ld a, SBF_PAGE+7
        add     a, 7
        cp      b
        ret     c                               ; height+y>$7f? error

        dec     c
        scf
        ret     m                               ; width<1 or width>128? error
        ld      a, c
        sla     a
        add     a, e
        ret     c
        cp      2*108
        ccf
        ret     c                               ; end>=108? error

        ld      (ix+wdf_endx), a
        ld      (ix+wdf_rmargin), a
        ld      (ix+wdf_startx), e
        ld      (ix+wdf_crsrx), e
        ld      (ix+wdf_lmargin), e
        ld      (ix+wdf_starty), d
        ld      (ix+wdf_crsry), d
        ld      (ix+wdf_endy), b
        ex      af, af'
        ld      (ix+wdf_OpenFlags), a

.ResetWdAttrs
        ld      (ix+wdf_flagsHi), 0
        ld      (ix+wdf_f2), 0
        ld      bc, 0
        ld      (ix+wdf_f6), b
        ld      (ix+wdf_flagsLo), c
        cp      a
        ret

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $31bf
;
; $Id$
; -----------------------------------------------------------------------------

        Module ScrDrv234

        org $f1bf                               ; 153 bytes


        include "blink.def"
        include "error.def"
        include "misc.def"
        include "sysvar.def"
        include "lowram.def"

xdef    InitApplWd
xdef    InitSBF
xdef    InitWindowFrame
xdef    ResetWdAttrs
xdef    WdBorders
xdef    sub_FD8B
xdef    Beep_X
xdef    CallFuncDE
xdef    ClearCarry
xdef    ClearEOL
xdef    ClearEOW
xdef    ClearScr
xdef    FindSDCmd
xdef    MoveToXY
xdef    NewXValid
xdef    NewYValid
xdef    NewXYValid
xdef    OSBlp
xdef    OSSr
xdef    PutBoxChar
xdef    ResetScrAttr
xdef    RestoreScreen
xdef    SaveScreen
xdef    ScrDrvGetAttrBits
xdef    ScreenBL
xdef    ScreenClose
xdef    ScreenCR
xdef    ScreenOpen
xdef    ScrollDown
xdef    ScrollUp
xdef    SetScrAttr
xdef    ToggleScrDrvFlags
xdef    InitOZwd

;       bank 0
xref    AtoN_upper
xref    Delay300Kclocks
xref    DrawOZwd
xref    KPrint
xref    MS1BankA
xref    OSFramePop
xref    OSFramePush
xref    RdHeaderedData
xref    WrHeaderedData

;       bank 7

xref    CursorDown
xref    CursorRight
xref    GetCrsrYX
xref    GetWdStartXY
xref    GetWindowNum
xref    OSSR_main
xref    ScrD_GetNewXY
xref    ScrD_PutChar
xref    ScrDrvAttrTable
xref    VDU2ChrCode
xref    Zero_ctrlprefix


.InitOZwd
        call    KPrint
        defm    1,"7#8",$80+104,$20+0,$20+4,$20+8,$40   ; window 8 @+104,0 4x8 $40
        defm    1,"2C8"                                 ; select & clear 8
        defm    1,"6#7",$80+0,$20+0,$20+10,$20+8        ; window 7 @+0,0 10x8
        defm    0

							; drops thru!
;       ----


.InitApplWd
        call    KPrint
        defm    1,"6#1",$80+10,$20+0,$20+94,$20+8       ; window 1 @abs10,0 94x8
        defm    1,"2I1"                                 ; select & init 1
        defm    0
        ret


; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3aea
;
; $Id$
; -----------------------------------------------------------------------------


; bind screen into S1, $7800-$7fff

.ScreenOpen
        pop     hl
        ld      a, (BLSC_SR1)
        push    af
        ld      a, (ubScreenBase)

.scr_bind
        push    hl
        jp      MS1BankA


.ScreenClose
        pop     hl
        pop     af
        jr      scr_bind






; Beep sequence (VDU)

.OSBlp
        push    hl
        ld      hl, ubSoundActive
        ex      af, af'
        call    OZ_DI

        ex      af, af'
        cp      1                               ; Fc=1 if A=0
        rl      a                               ; A=2*A, 1 if A was 0
        ld      (hl), 1
        inc     hl
        ld      (hl), a                         ; sound count
        inc     hl
        ld      (hl), b                         ; space count
        inc     hl
        ld      (hl), c                         ; mark count

        ex      af, af'
        call    OZ_EI
        pop     hl
        or      a
        ret

.Beep_X
        push    af
        push    bc
        ld      a, 2
        ld      bc, $50A
        jr      bl_1

.ScreenBL
        push    af
        push    bc
        ld      a, 1
        ld      bc, $14

.bl_1
        push    hl                              ; !! unnecessary
        CALL_OZ OS_Blp                          ; Bleep
        pop     hl
        pop     bc
        pop     af
        ret

;       ----

.OSSr
        call    OSFramePush
        push    bc
        ld      b, a
        pop     af
        call    OSSR_main
        jp      OSFramePop

;       ----

.RestoreScreen
        ld      e, 0
        jr      SrScreen

.SaveScreen
        ld      e, -1

.SrScreen
        call    ScreenOpen
        ld      h, SBF_PAGE                     ; address high byte
        ld      b, 8                            ; lines to do

.srs_1
        push    bc
        push    hl
        ld      a, $A3                          ; this type
        ld      bc, 2*114                       ; this many bytes
        ld      l, 2*10                         ; address low byte - skip 10 chars
        call    srscr_rwline
        pop     hl
        pop     bc
        jr      c, srs_2
        inc     h                               ; next line
        djnz    srs_1
        call    DrawOZwd
        or      a

.srs_2
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        ret

.srscr_rwline
        push    de
        inc     e
        jr      z, srscr_wline
        call    RdHeaderedData
        pop     de
        ret

.srscr_wline
        call    WrHeaderedData
        pop     de
        ret

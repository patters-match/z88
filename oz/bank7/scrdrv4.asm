; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3aea
;
; $Id$
; -----------------------------------------------------------------------------

        Module ScrDrv4

        org $faea                               ; 899 bytes

        include "all.def"
        include "sysvar.def"

xdef    ScreenOpen
xdef    ScreenClose
xdef    MoveToXY
xdef    ScrDrvGetAttrBits
xdef    FindSDCmd
xdef    SetScrAttr
xdef    ResetScrAttr
xdef    ToggleScrDrvFlags
xdef    CallFuncDE
xdef    PutBoxChar
xdef    ScreenCR
xdef    CursorLeft
xdef    CursorRight
xdef    CursorUp
xdef    CursorDown
xdef    ClearEOW
xdef    ClearScr
xdef    GetWdStartXY
xdef    ClearCarry
xdef    NewXValid
xdef    NewYValid
xdef    OSBlp
xdef    Beep_X
xdef    ScreenBL
xdef    OSSr
xdef    RestoreScreen
xdef    SaveScreen

defc    MS1BankA                = $d710
defc    ScrD_GetNewXY           = $aead
defc    AtoN_upper              = $d727
defc    ScrD_PutChar            = $acc3
defc    Delay2Mclocks           = $cdb8
defc    Zero_ctrlprefix         = $ade8
defc    OSFramePush             = $d555
defc    OSSR_main               = $b1a6
defc    OSFramePop              = $d582
defc    DrawOZwd                = $fa11
defc    ReadBuffer              = $f64f
defc    WrACB_buffer            = $f4e1
defc    ScrDrvAttrTable         = $b123


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

; move to x,y

.MoveToXY
        ld      c, a                            ; C=first arg, B=second arg
        ex      de, hl
        call    ScrD_GetNewXY
        call    NewXYValid
        ret     nc
        ex      de, hl
        ret

; search attribute table, return
; tHiLo in DE, ~tHiLo in BC
; chg: .FBCDE../....

.ScrDrvGetAttrBits
        call    AtoN_upper
        ld      c, a
.sdgab_1
        ld      a, (de)
        or      a
        ccf
        ret     z
        cp      c
        inc     de
        jr      z, sdgab_2
        inc     de
        inc     de
        jr      sdgab_1
.sdgab_2
        push    af
        push    hl
        ex      de, hl
        ld      a, (hl)
        ld      e, a                            ; tLo
        xor     $0FF
        ld      c, a                            ; ~tLo
        inc     hl
        ld      a, (hl)
        ld      d, a                            ; tHi
        xor     $0FF
        ld      b, a                            ; ~tHi
        pop     hl
        pop     af
        ret

;       ----
; out: Fc=0, DE=func
;  Fc=1, not found
.FindSDCmd
        ld      a, (sbf_VDUbuffer)
        call    AtoN_upper
        ld      c, a
        ld      a, (sbf_VDU1)
        call    AtoN_upper
        ld      b, a                            ; c,b = command
.sdfc_1
        ld      a, (de)
        or      a
        ccf
        ret     z                               ; not found Fc=1
        cp      c
        inc     de
        jr      nz, sdfc_next
        ld      a, (de)
        or      a
        jr      z, sdfc_match
        cp      b
        jr      z, sdfc_match
.sdfc_next
        inc     de
        inc     de
        inc     de
        jr      sdfc_1
.sdfc_match
        push    hl
        ex      de, hl
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        pop     hl
        ret


; set attributes
.SetScrAttr
        dec     e                               ; E=-1
; reset attributes
;       ----
.ResetScrAttr
        ld      bc, sbf_VDUbuffer
.attr_1
        inc     bc
        ld      a, (bc)
        or      a
        ret     z
        exx
        ld      de, ScrDrvAttrTable
        call    ScrDrvGetAttrBits
        exx                                     ; if E=0 then just mask flags
        inc     e
        dec     e
        exx
        jr      nz, attr_2
        ld      de, 0                           ; no toggle bits
.attr_2
        call    nc, ToggleScrDrvFlags
        exx
        jr      attr_1

;       ----
.ToggleScrDrvFlags
        call    AtoN_upper
        ret     c                               ; not alpha
        ld      a, (ix+wdf_flagsLo)
        and     c
        xor     e                               ; tLo
        ld      (ix+wdf_flagsLo), a
        ld      a, (ix+wdf_flagsHi)
        and     b
        xor     d                               ; tHi
        ld      (ix+wdf_flagsHi), a
        ret

;       ----
; call function with following parameters:
; A,B,C - first 3 VDU arguments-$20
; E - 0
; Fc=1
.CallFuncDE
        ld      a, (sbf_VDU3)
        sub     $20
        ld      c, a                            ; arg3
        ld      a, (sbf_VDU2)
        sub     $20
        ld      b, a                            ; arg2
        ld      a, (sbf_VDU1)
        sub     $20                             ; arg1
        push    de
        ld      e, 0
        scf
        ret

; Box Characters
.PutBoxChar
        and     $0F
        ld      bc, $0FE00                      ; VDU $000-$00F
        jp      ScrD_PutChar
.ScreenCR
        ld      l, (ix+wdf_startx)
        ret

;       ----
; cursor backwards
;
; Fc=0 if no line change
.CursorLeft
        bit     WDFH_B_HSCROLL, (ix+wdf_flagsHi)
        jr      z, bs_1
        ld      a, l
        cp      (ix+wdf_lmargin)
        ld      b, 0
        jr      z, bs_3                         ; need scrolling
.bs_1
        dec     l
        dec     l
        call    NewXValid
        jr      c, bs_2                         ; left edge? previous line
        inc     l
        ld      a, (hl)                         ; attributes
        dec     l
        and     $3C
        cp      $34
        jr      z, CursorLeft                   ; null char? backspace again
        cp      a                               ; Fc=0, Fz=1
        ret
.bs_2
        ld      l, (ix+wdf_endx)                ; end of line
        call    CursorUp                        ; previous line
        scf                                     ; Fc=1
        ret
.bs_3
        push    hl
        ld      d, h
        ld      l, (ix+wdf_lmargin)
        ld      e, (ix+wdf_rmargin)
        ld      a, e
        sub     l
        jr      z, bs_5
        ld      c, a                            ; bytes to copy
        inc     b                               ; test direction
        jr      z, bs_4
        dec     b                               ; B=0
        ld      l, e
        dec     l
        inc     e
        lddr                                    ; move chars right
        jr      bs_5
.bs_4
        ld      e, l
        inc     l
        inc     l
        ldir                                    ; move chars left
.bs_5
        pop     hl                              ; put $000, space
        xor     a
        ld      (hl), a
        inc     l
        ld      (hl), a
        dec     l
        ret

;       ----
; advance cursor
;
; Fc=0 if no line change
.CursorRight
        bit     WDFH_B_HSCROLL, (ix+wdf_flagsHi)
        jr      z, sdht_1
        ld      a, l
        cp      (ix+wdf_rmargin)
        ld      b, $0FF
        jr      z, bs_3                         ; need scrolling
.sdht_1
        call    NewXValid
        jr      c, sdht_2                       ; right edge? next line
        inc     l
        inc     l
        inc     l
        ld      a, (hl)                         ; attributes
        dec     l
        and     $3C
        cp      $34
        jr      z, CursorRight                  ; null? forward again
        call    NewXValid
        ret     nc                              ; x ok, return Fc=0
.sdht_2
        ld      l, (ix+wdf_startx)              ; start of line
        call    CursorDown                      ; next line
        scf                                     ; Fc=1
        ret

;       ----

; previous line
.CursorUp
        call    ScrollLock
        dec     h
        call    NewYValid
        jr      c, vt_1
        cp      a                               ; Fc=0, no scrolling
        ret
.vt_1
        bit     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        jr      z, vt_2
        call    ScrollDown
        scf                                     ; Fc=1, screen scrolled
        ret
.vt_2
        ld      h, (ix+wdf_endy)                ; wrap to last line
        scf                                     ; Fc=1, wrap
        ret


;       ----

.CursorDown
        call    ScrollLock
        inc     h
        call    NewYValid
        jr      c, lf_1
        cp      a                               ; Fc=0, no wrap/scroll
        ret
.lf_1
        bit     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        jr      z, lf_3
        bit     WDFH_B_DELAY, (ix+wdf_flagsHi)
        jr      z, lf_2
        ex      de, hl
        call    Delay2Mclocks
        ex      de, hl

.lf_2
        call    ScrollUp                        ; scroll up
        scf                                     ; Fc=1, scroll
        ret

.lf_3
        ld      h, (ix+wdf_starty)              ; wrap to first line
        scf                                     ; Fc=1, wrap
        ret

;       ----

; freeze output if <> and lshift down

.ScrollLock
        ld      a, $BF
        in      a, (BL_KBD)                     ; (r) keyboard
        add     a, $50                          ; check for sh-l and <> !! add a,$51
        inc     a
        jr      z, ScrollLock
        ret

;       ----

; clear to EOW

.ClearEOW
        push    hl
        call    ClearEOWm
        pop     hl
        ret
;       ----
.ClearScr
        ld      c, (ix+wdf_OpenFlags)
        bit     WDFO_B_BORDERS, c
        call    nz, WdBorders
        call    Zero_ctrlprefix
        call    GetWdStartXY

.ClearEOWm
        call    sub_FD8B
        ld      a, (ix+wdf_OpenFlags)
        bit     WDFO_B_6, a
        jr      z, ff_2
        ld      bc, $23A0                       ; B=hires underline ch8
        bit     WDFO_B_5, a
        jr      z, ff_2
        ld      bc, $1FFF                       ; B=r f g u ch8

.ff_2
        call    ceol_1
        ret     c
        call    GetWdStartX                     ; !! stupidity, ld it here
        ld      e, (ix+wdf_flagsHi)
        push    de
        res     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        call    CursorDown
        pop     de
        ld      (ix+wdf_flagsHi), e
        jr      nc, ff_2

.GetWdStartXY
        ld      h, (ix+wdf_starty)
.GetWdStartX
        ld      l, (ix+wdf_startx)
        ret

;       ----

.ClearEOL
        call    sub_FD8B

.ceol_1
        call    NewXYValid
        ret     c
        push    hl

.ceol_2
        bit     WDFO_B_6, (ix+wdf_OpenFlags)
        jr      z, ceol_4

        ld      a, l
        sub     (ix+wdf_startx)                 ; left offset
        bit     1, a                            ; check mod(xpos,4)=0
        jr      nz, ceol_3
        bit     2, a
        jr      nz, ceol_3
        ld      a, LCDA_NULLCHAR
        inc     hl
        ld      (hl), a
        jr      ceol_9

.ceol_3
        bit     WDFO_B_5, (ix+wdf_OpenFlags)
        jr      z, ceol_4
        inc     bc                              ; increment char

.ceol_4
        bit     WDFO_B_GREY, (ix+wdf_OpenFlags)
        jr      z, ceol_6

        ld      c, (hl)                         ; char
        inc     hl
        ld      a, (hl)                         ; attrs
        dec     hl

        bit     LCDA_B_GREY, a
        res     7, a                            ; soft tiny?
        jr      z, ceol_5
        or      $80                             ; soft tiny?
.ceol_5
        or      LCDA_GREY
        ld      b, a
.ceol_6
        bit     WDFO_B_UNGREY, (ix+wdf_OpenFlags)
        jr      z, ceol_8
        ld      c, (hl)                         ; char
        inc     hl
        ld      a, (hl)                         ; attr
        dec     hl
        bit     7, a                            ; soft tiny?
        res     LCDA_B_GREY, a
        jr      z, ceol_7
        or      LCDA_GREY

.ceol_7
        and     $7F
        ld      b, a

.ceol_8
        ld      (hl), c
        inc     hl
        ld      (hl), b
.ceol_9
        dec     hl
        ld      e, (ix+wdf_flagsHi)
        push    de
        res     WDFH_B_VSCROLL, (ix+wdf_flagsHi)
        inc     l
        inc     l
        call    NewXValid
        pop     de
        ld      (ix+wdf_flagsHi), e
        jr      nc, ceol_2
        pop     hl
        cp      a
        ret

;       ----

.ScrollUp
        push    hl
        ld      h, (ix+wdf_starty)

.su_1
        inc     h
        call    su_2
        jr      nc, su_1

        dec     h
        ld      l, (ix+wdf_startx)
        call    ClearEOL
        pop     hl
        dec     h
        call    NewYValid
        ret     nc
        inc     h
        cp      a
        ret

.su_2
        call    NewYValid
        ret     c
        dec     h
        call    NewYValid
        ld      d, h
        inc     h
        ret     c
        ld      l, (ix+wdf_startx)
        ld      e, l
        ld      a, (ix+wdf_endx)
        sub     l
        inc     a
        inc     a
        ld      c, a
        ld      b, 0
        ldir
        cp      a
        ret

.ScrollDown
        push    hl
        ld      h, (ix+wdf_endy)

.sd_1
        dec     h
        call    sd_2
        jr      nc, sd_1
        inc     h
        ld      l, (ix+wdf_startx)
        call    ClearEOL
        pop     hl
        inc     h
        call    NewYValid
        ret     nc
        dec     h
        cp      a
        ret

.sd_2
        call    NewYValid                       ; !! add hl,bc etc to re-use code
        ret     c
        inc     h
        call    NewYValid
        ld      d, h
        dec     h
        ret     c
        ld      l, (ix+wdf_startx)
        ld      e, l
        ld      a, (ix+wdf_endx)
        sub     l
        inc     a                               ; width
        inc     a
        ld      c, a
        ld      b, 0
        ldir
        cp      a
        ret

;       ----

.GetWdEnd
        ld      l, (ix+wdf_endx)
        ld      h, (ix+wdf_endy)
        ret

;       ----

.sub_FD8B
        ld      a, (ix+wdf_flagsLo)
        and     $1E             ; R F G U
        ld      b, a
        ld      c, 0
        ret

;       ----
.WdBorders
        ld      a, (ix+wdf_endy)
        sub     (ix+wdf_starty)
        inc     a
        ld      b, a            ; height
        push    bc

;       draw left border

        call    GetWdStartXY    ; !! stupidity, ld l,wdf_startx here
        dec     l               ; left one char
        dec     l
        ld      h, (ix+wdf_endy) ; last line

.bd_1
        ld      (hl), $0A       ; VDU $00A, vertical bar
        inc     l
        ld      (hl), 0
        dec     l
        dec     h               ; previous line
        djnz    bd_1

        bit     WDFO_B_BRACKETS, c
        jr      z, bd_2 ; no brackets
        inc     h               ; 1st line
        ld      (hl), $7F       ; VDU $07f
        inc     l
        ld      (hl), 0

.bd_2
        pop     bc

;       draw right border

        call    GetWdEnd
        inc     l                               ; right one char
        inc     l

.bd_3
        ld      (hl), $0A                       ; VDU $00A, vertical bar
        inc     l
        ld      (hl), 0
        dec     l
        dec     h                               ; previous line
        djnz    bd_3

        bit     WDFO_B_BRACKETS, c
        ret     z                               ; no brackets
        inc     h                               ; last line
        ld      (hl), $FF                       ; VDU $0FF
        inc     l
        ld      (hl), 0
        ret

;       ----

.ClearCarry
        cp      a                               ; nop routine, remove
        ret

;       ----

.NewXYValid
        call    ClearCarry
        ret     c
        call    NewYValid
        ret     c

;       Fc=0 if L inside window

.NewXValid
        ld      a, l
        cp      (ix+wdf_startx)                 ; Fc=1 if L<StartX
        ret     c
        cp      (ix+wdf_endx)
        jr      nz, nxv_1                       ; Fc=0 if L<=EndX  !! ret z; ccf; ret
        scf
.nxv_1
        ccf
        ret

;       Fc=0 if H inside window

.NewYValid
        ld      a, h
        cp      (ix+wdf_starty)                 ; Fc=1 if H<StartY
        ret     c
        cp      (ix+wdf_endy)
        jr      nz, nyv_1                       ; Fc=0 if H<=EndY  !! ret z; ccf; ret
        scf
.nyv_1
        ccf
        ret


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
        call    ReadBuffer
        pop     de
        ret

.srscr_wline
        call    WrACB_buffer
        pop     de
        ret

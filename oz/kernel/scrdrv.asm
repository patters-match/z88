; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1ec5b
;
; $Id$
; -----------------------------------------------------------------------------

        Module ScrDrv

        org $ac5b                               ; 2277 bytes

        include "blink.def"
        include "error.def"
        include "screen.def"
        include "stdio.def"
        include "sysvar.def"

;       most of these xdefs/xrefs go away if all screen code is moved to bank 7
;       second part of code is at $f90c-fdf4


xdef    Chr2ScreenCode                          ; Char2OZwdChar
xdef    CursorDown
xdef    CursorRight
xdef    GetCrsrYX                               ; NqRDS
xdef    GetWdStartXY
xdef    GetWindowNum                            ; screen driver code reference
xdef    InitUserAreaGrey                        ; MTH, OS_Ent
xdef    Key2Chr_tbl                             ; Char2OZwdChar
xdef    OSIsq                                   ; Printer driver
xdef    OSOutMain
xdef    OSWsq
xdef    ScrD_GetMargins                         ; NqSp
xdef    ScrD_GetNewXY                           ; screen driver code reference
xdef    ScrD_PutChar                            ; screen driver code reference
xdef    ScrDrvAttrTable                         ; screen driver code reference
xdef    StorePrefixed                           ; Printer driver
xdef    VDU2ChrCode                             ; NqRDS    all these are screen related code in OZBANK_HI
xdef    Zero_ctrlprefix                         ; screen driver code reference
xdef    InitSBF
xdef    GetWindowFrame
xdef    NqRDS

;       bank 0

xref    AtoN_upper
xref    CallFuncDE
xref    Chk128KB
xref    ClearCarry
xref    ClearEOL
xref    ClearEOW
xref    ClearScr
xref    CopyMemDE_BHL
xref    CursorLeft
xref    CursorUp
xref    Delay300Kclocks
xref    DrawOZwd
xref    FindSDCmd
xref    GetOSFrame_DE
xref    GetOSFrame_HL
xref    InitOZwd
xref    InitWindowFrame
xref    KPrint
xref    MoveToXY
xref    NewXValid
xref    NewXYValid
xref    NewYValid
xref    OSBlp
xref    PokeHLinc
xref    PutBoxChar
xref    ResetScrAttr
xref    ResetWdAttrs
xref    ScrDrvGetAttrBits
xref    ScreenBL
xref    ScreenClose
xref    ScreenCR
xref    ScreenOpen
xref    ScrollDown
xref    ScrollUp
xref    SetScrAttr
xref    sub_FD8B
xref    TogglePrFilter
xref    ToggleScrDrvFlags
xref    WdBorders

;       ----

.OSOutMain
        push    ix
        ex      af, af'
        call    ScreenOpen
        ld      ix, (sbf_ActiveWd)
        call    CursorOff
        ex      af, af'
        call    OSOut_Put
        call    PutCrsrPos
        call    CursorOn
        call    ScreenClose
        pop     ix
        or      a
        ret


.OSOut_Put
        ld      bc, (sbf_CtrlPrefix)            ; B=prefixseq
        inc     c
        dec     c
        jp      nz, OsOut_Prefixed
        cp      $20
        jr      nc, put_1
        call    Zero_ctrlprefix
        cp      CR
        jp      z, ScreenCR
        cp      BEL
        jp      z, ScreenBL
        cp      BS
        jp      z, CursorLeft
        cp      HT
        jp      z, CursorRight
        cp      LF
        jp      z, CursorDown
        cp      VT
        jp      z, CursorUp
        cp      FF
        jp      z, ClearScr
        cp      ESC
        ret     z
        ld      (sbf_CtrlPrefix), a
        push    hl
        ld      hl, sbf_PrefixSeq
        call    OSIsq
        pop     hl
        or      a
        ret

.put_1
        bit     WDFH_B_CAPS, (ix+wdf_flagsHi)
        call    nz, AtoN_upper

;       put character code

.ScrD_PutChar
        scf                                     ; do chr2vdu translation

;       put character (Fc=1) or VDU (Fc=0) code

.ScrD_PutByte
        push    af
        call    DoJustification                 ; handle justification
        inc     hl
        ld      a, (hl)                         ; attribute byte
        dec     hl
        and     (ix+wdf_f6)
        xor     (ix+wdf_flagsLo)
        ld      d, a
        pop     af
        call    c, Char2VDU                     ; Fc=1, translate char  to VDU
        jr      nc, sdpc_1
        ld      a, $7F                          ; display box char, VDU $17F
        ld      bc, $0001                       ; clear attributes and force ch8

.sdpc_1
        ld      (hl), a                         ; output char
        ld      a, d                            ; old flags
        and     b                               ; mask out attributes
        xor     c                               ; and toggle some
        inc     hl
        ld      (hl), a                         ; put attrs
        dec     hl
        ld      a, (ix+wdf_flagsHi)
        and     WDFH_JUSTIFICATION
        ret     nz                              ; not normal, Fc=0, Fz=0
        call    CursorRight                     ; advance cursor
        cp      a                               ; Fc=0, Fz=1
        ret

;       ----

;       display User Defined Character

.PutUsrDefChar
        call    GetUserDefinedChar
        ld      b, $FE                          ; clear ch8
        ld      c, 1                            ; and force it set
        jr      ScrD_PutByte                    ; Fc=0, it's VDU code

;       ----

.GetUserDefinedChar
        call    Chk128KB
        ld      a, (sbf_VDU1)
        jr      nc, gudc_1
        or      $20                             ; 20-3F
.gudc_1
        and     $3F                             ; 00-3F
        cpl                                     ; C0-FF, E0-FF for unexpanded
        ret


;       ----

;       define User Defined Character

.DefineUsrChar  push    hl
        ld      a, 1
        ld      b, 0
        OZ      OS_Sci                          ; get LORES0 base
        push    hl
        call    GetUserDefinedChar
        ld      l, a                            ; negative offset * 8
        ld      h, $FF
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ex      de, hl
        pop     hl                              ; LORES0+$200
        inc     h
        inc     h
        add     hl, de                          ; destination address
        ld      de, sbf_VDU2                    ; source address
        ld      c, 8                            ; copy 8 bytes
        call    CopyMemDE_BHL
        pop     hl
        ret

;       ----

.VDU2ChrCode    ld      hl, VDU2Chr_tbl

.Chr2ScreenCode
        push    de
        ld      d, a                            ; remember byte

.c2sc_1
        ld      a, (hl)
        or      a
        scf
        jr      z, c2sc_2                       ; not found, Fc=1
        inc     hl                              ; next entry
        inc     hl
        inc     hl
        inc     hl
        cp      d
        jr      nz, c2sc_1                      ; compare next

.c2sc_2
        ld      a, d                            ; restore byte
        pop     de
        dec     hl                              ; point HL to match+1
        dec     hl
        dec     hl
        ret

.Key2Chr_tbl
        defb    $A3                             ; £ internal code
.Chr2VDU_tbl
        defb    $A3                             ; £ char code
.VDU2Chr_tbl
        defb    $1F,0                           ;   VDU low byte, high byte
        defb    0,0,0,0

;       this one handles tiny/bold too

.Char2VDU
        ld      bc, $fe01                       ; clear ch8 and force it set

        cp      $20
        ret     z                               ; space - always $120

        cp      $7F
        jr      c, somc_1

;       $7f-$ff

        dec     c
        cp      $A0
        ret     z                               ; nbsp - always $0a0
        inc     c
        push    hl
        ld      hl, Chr2VDU_tbl
        call    Chr2ScreenCode
        inc     hl
        ld      a, (hl)                         ; Fz=!ch8
        inc     a
        dec     a                               ; set Fz
        dec     hl
        ld      a, (hl)                         ; screen code lo
        pop     hl
        ret     c                               ; not found, exit
        jr      z, somc_1                       ; ch8=0

        res     0, b                            ; force ch8 set !! ld bc,$fe01
        set     0, c
        ret

.somc_1
        bit     6, d
        jr      z, somc_2                       ; 00-3F

        call    IsBoldableASCII                 ; 40-7F, C0-FF
        ret     nc

.somc_2
        or      a
        dec     c
        bit     7, d
        ret     z
        call    IsBoldable
        ccf
        ret     nc
        xor     $80
        ret

;       ----

;       01-11 - linedraw chars, <> and [] are boldable but no tiny-able

.IsBoldable
        cp      1
        ret     c
        cp      $12
        ccf
        ret     nc

;       1F-7E - ascii are boldable and tiny-able
;       !! this is changed by localization

.IsBoldableASCII
        cp      $1F
        ret     c
        cp      $7F
        ccf
        ret

;       ----

;       initialize prefix sequence
;       clears buffer and sets buffer pointer
;
;IN:    HL=sequence buffer, 22 bytes
;OUT:   --
;chg:   .F....HL/....

.OSIsq
        push    hl
        ld      b, 22

.osisq_1
        ld      (hl), 0
        inc     hl
        djnz    osisq_1

        pop     hl
        inc     hl
        ld      (hl), l
        ret

;       ----

;IN:    A=char, HL=sequence buffer
;OUT:   Fc=0 always
;       A=0 if sequence completed, -1 otherwise

.OSWsq
        call    StorePrefixed
        ld      (iy+OSFrame_A), a               ; return -1 if sequence not complete yet
        or      a
        ret

;       ----
.StorePrefixed
        inc     (hl)
        dec     (hl)
        jr      nz, spfx_5                      ; length not zero, continue put
        or      a
        jp      p, spfx_1
        cp      $95                             ; $80-$94 is valid - 0-20
        jr      c, spfx_2

.spfx_1
        call    AtoN_upper
        jr      nc, spfx_4                      ; alpha
        jr      nz, spfx_4                      ; not num
        ex      af, af'
        add     a, $80                          ; 80-89

.spfx_2
        sub     $80                             ; store length
        ld      (hl), a
        or      a
        scf                                     ; not done yet, Fc=1
        ret     nz                              ; if length is zero then cancel ctrl sequence

.Zero_ctrlprefix
        push    af
        xor     a
        ld      (sbf_CtrlPrefix), a
        pop     af
        ret

.spfx_4
        inc     (hl)                            ; increase length
        inc     hl
        inc     (hl)                            ; increase pointer
        ld      l, (hl)
        ex      af, af'
        ld      (hl), a                         ; store char
        xor     a
        ret                                     ; done, Fc=0, A=0

.spfx_5
        push    hl
        inc     hl
        inc     (hl)                            ; increase pointer
        ld      l, (hl)
        ld      (hl), a                         ; store char
        pop     hl
        dec     (hl)                            ; decrease remaining length
        scf
        ld      a, -1
        ret     nz                              ; not done yet, Fc=1, A=-1
        inc     hl
        ld      a, (hl)                         ; get pointer
        sub     l                               ; - start
        dec     hl
        ld      (hl), a                         ; sequence length
        xor     a
        ret                                     ; done, Fc=0, A=0

;       ----

.OsOut_Prefixed
        push    hl
        ld      hl, sbf_PrefixSeq
        call    StorePrefixed
        pop     hl
        ret     c                               ; not done yet
        ld      a, (sbf_CtrlPrefix)
        dec     a
        jr      nz, Zero_ctrlprefix             ; not 1, cancel
        ld      a, (sbf_PrefixSeq)
        dec     a
        jr      nz, oprfx_3                     ; length not 1
        ld      a, (sbf_VDUbuffer)
        ld      de, ScrDrvAttrTable
        call    ScrDrvGetAttrBits
        jr      c, Zero_ctrlprefix              ; was not attribute char
        ld      bc, $FFFF
        call    ToggleScrDrvFlags
        jr      nc, Zero_ctrlprefix
        ld      a, d                            ; tHi
        cp      8
        jr      nc, oprfx_2
        ld      b, d
        srl     b
        inc     b                               ; 1-4
        ld      a, d
        and     1
        ld      c, a
        cp      1
        ld      a, e                            ; tLo
        jr      nc, oprfx_1
        cp      $12
.oprfx_1
        push    af
        push    bc
        ld      b, $FE                          ; clear ch8
        call    ScrD_PutByte
        pop     bc
        pop     af
        inc     a
        djnz    oprfx_1
        scf
.oprfx_2
        call    nc, CallFuncDE
        jr      Zero_ctrlprefix
.oprfx_3
        ld      a, (sbf_VDUbuffer)
        ld      de, ScrDrvCmdTable
        call    FindSDCmd                       ; find cmd in table, return func in DE
        jr      oprfx_2

;       ----

.CursorOn
        call    ClearCarry
        ret     c
        ld      a, (ix+wdf_flagsHi)
        bit     WDFH_B_CURSOR, a
        ret     z                               ; no cursor? exit
        bit     WDFH_B_CURSORON, a
        ret     nz                              ; cursor not toggled on? exit
        call    GetCrsrYX
        inc     hl
        ld      a, (hl)
        ld      (ix+wdf_crsrattr), a
        bit     LCDA_B_HIRES, a
        jr      nz, crsron_1                    ; hires? just flash
        and     LCDA_CH8                        ; keep ch8
        or      LCDA_LORESCURSOR                ; lores cursor
.crsron_1       or      LCDA_FLASH
        ld      (hl), a
        set     WDFH_B_CURSORON, (ix+wdf_flagsHi)
        ret

.CursorOff
        call    ClearCarry
        ret     c
        ld      l, (ix+wdf_crsrx)
        ld      h, (ix+wdf_crsry)
        bit     WDFH_B_CURSORON, (ix+wdf_flagsHi)
        ret     z                               ; cursor not on? exit
        inc     hl
        ld      a, (ix+wdf_crsrattr)
        ld      (hl), a
        res     WDFH_B_CURSORON, (ix+wdf_flagsHi)
        dec     hl
        ret

;       ----

;       !! make this inline

.ASCII2num
        cp      '0'
        ret     c
        cp      ':'                             ; '9'+1
        ccf
        ret     c
        sub     '0'
        ret

;       ----

.ScrD_GetNewXY
        ld      a, c                            ; L=2*C+StartX
        sla     a
        add     a, (ix+wdf_startx)
        ld      l, a
        ld      a, b                            ; H=B+StartY
        add     a, (ix+wdf_starty)
        ld      h, a
        ret

;       ----
.ScrD_GetMargins
        ld      a, l
        sub     (ix+wdf_startx)
        srl     a
        ld      c, a
        ld      a, h
        sub     (ix+wdf_starty)
        ld      b, a
        ret

.SetCenterJustify
        inc     e
.SetLeftJustify
        inc     e
.SetRightJustify
        inc     e

.SetNormalJustify
        ld      a, (ix+wdf_flagsHi)
        and     ~WDFH_JUSTIFICATION
        or      e
        ld      (ix+wdf_flagsHi), a
        ret
;       ----

;       move chars as needed for justification

.DoJustification
        push    bc
        call    ScrD_MvChars2
        pop     bc
        ret

.ScrD_MvChars2
        ld      a, (ix+wdf_flagsHi)
        and     WDFH_JUSTIFICATION
        ret     z                               ; normal
        dec     a
        jp      z, sdmc_justr                   ; right
        dec     a
        jp      z, sdmc_justl                   ; left

        ld      a, (ix+wdf_lmargin)             ; !! ld a,lmargin; add a,rmargin; rra
        srl     a                               ; into X coordinate
        ld      b, (ix+wdf_rmargin)
        srl     b                               ; into Y coordinate
        add     a, b
        ld      b, a                            ; lmargin+rmargin
        and     $FE
        ld      c, a                            ; rounded

        ld      l, c
        call    FindLeftEdge
        ex      af, af'
        ld      e, l
        ld      l, c
        call    FindRightEdge
        jr      c, sdmc_2                       ; right edge reached
        ex      af, af'
        jr      c, sdmc_2                       ; left edge reached

        ld      a, e
        cp      l
        ret     z                               ; left=right? done

        srl     e                               ; into x coordinates
        srl     l
        ld      a, e
        add     a, l
        cp      b
        jr      c, sdmc_1
        dec     l

.sdmc_1
        sla     e                               ; into pointers
        sla     l

.sdmc_2
        call    IsNull
        ret     z                               ; char is null? done

        ld      a, l
        sub     e
        ret     z                               ; left=right? done

        ld      c, a                            ; #bytes to move
        ld      b, 0
        push    hl                              ; move them from (HL+2) to (HL)
        ld      d, h
        ld      l, e
        inc     l
        inc     l
        ldir
        pop     hl
        ret

.sdmc_justl
        ld      l, (ix+wdf_lmargin)
        ld      e, l
        call    FindRightEdge
        jr      sdmc_2

.sdmc_justr
        ld      l, (ix+wdf_rmargin)
        ld      e, l
        ld      d, h
        call    FindLeftEdge
        ex      de, hl
        jr      sdmc_2

;       ----

; Fz=1 if char at (HL) is NULL

.IsNull
        inc     l
        ld      a, (hl)
        dec     l
        and     LCDA_CH8
        or      (hl)
        ret

;       ----

;       move right until edge or null char

.FindRightEdge
        call    IsNull
        ret     z                               ;  null char, exit
        ld      a, l
        cp      (ix+wdf_endx)
        ccf
        ret     z                               ; Fc=1, edge reached
        inc     l
        inc     l
        jr      FindRightEdge

;       move left  until at edge or null char

.FindLeftEdge
        call    IsNull
        ret     z                               ; null char, exit
        ld      a, l
        cp      (ix+wdf_startx)
        ccf
        ret     z                               ; Fc=1, edge reached
        dec     l
        dec     l
        jr      FindLeftEdge

;       ----

;       move to x

.MoveToX
        ld      c, a
        call    TestNewX
        ret     c                               ; out of bounds? exit
        ld      l, e
        ret

;       move to y

.MoveToY
        ld      c, a
        call    TestNewY
        ret     c                               ; out of bounds? exit
        ld      h, d
        ret

;       Set left margin

.SetLeftMargin
        ld      c, a
        call    TestNewX
        ret     c                               ; out of bounds? exit

        ld      a, e                            ; assert rmargin >= lmargin
        cp      (ix+wdf_rmargin)
        jr      c, sdl_1
        ld      (ix+wdf_rmargin), a
.sdl_1
        ld      (ix+wdf_lmargin), a
        ret

;       Set right margin

.SetRightMargin
        ld      c, a
        call    TestNewX
        ret     c                               ; out of bounds? exit

        ld      a, e                            ; assert lmargin <= rmargin
        cp      (ix+wdf_lmargin)
        jr      nc, sdr_1
        ld      (ix+wdf_lmargin), a
.sdr_1
        ld      (ix+wdf_rmargin), a
        ret

;       ----

;       check if C is valid X/Y-coordinate

.TestNewX
        ex      de, hl
        call    ScrD_GetNewXY
        ld      h, d
        call    NewXValid
        ex      de, hl
        ret

.TestNewY
        ex      de, hl
        ld      b, c
        call    ScrD_GetNewXY
        ld      l, e
        call    NewYValid
        ex      de, hl
        ret

;       ----

;       make full screen grey

.InitUserAreaGrey
        push    af

        push    bc
        push    de
        push    hl
        call    ScreenOpen
        ld      de, (sbf_ActiveWd)              ; remember active window
        push    de
        call    KPrint
        defm    1,"6#8",$20+0,$20+0,$20+94,$20+8
        defm    1,"2H8"
        defm    1,"2G",0
        ld      a, '+'
        OZ      OS_Out                          ; grey/ungrey
        pop     de
        ld      (sbf_ActiveWd), de              ; restore active window
        call    ScreenClose
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

;       ----

;       define window

.DefineWd
        call    GetWindowNum
        ret     c                               ; not valid? exit

        push    hl
        push    ix
        pop     hl
        push    hl
        ld      e, <Wd1Frame                    ; !! ld de,Wd1Frame; add a,d; ld d,a
        add     a, >Wd1Frame
        ld      d, a

        cp      h                               ; compare DE=IX  !! result not used
        ld      a, e
        cp      l

        push    de                              ; IX=DE
        pop     ix
        ld      d, c                            ; VDU3, y
        ld      a, b                            ; VDU2, x
        add     a, $A0
        jp      p, loc_AFFC                     ; 60-df -> 00-7f
        sub     $96                             ; e0-5f -> 80-ff -> ea-69

.loc_AFFC       ld      e, a

        ld      a, (sbf_VDU4)                   ; C=width
        sub     $20
        ld      c, a

        ld      a, (sbf_VDU5)                   ; B=height
        sub     $20
        ld      b, a

        ld      a, (sbf_VDU6)                   ; flags
        call    InitWindowFrame
        pop     ix
        pop     hl
        ret

;       ----

;       delete window - not implemented

.DeleteWd
        call    GetWindowNum
        ret     c
        ret

;       Select and Clear window

.SelClearWd
        call    SelHoldWd
        ret     c

.sdi_1
        call    ResetWdAttrs                    ; reset attrs
        set     WDF2_B_INITIALIZED, (ix+wdf_f2)
        jp      ClearScr

;       Select and Init window

.SelInitWd
        call    SelHoldWd
        bit     WDF2_B_INITIALIZED, (ix+wdf_f2)
        call    z, sdi_1                        ; first select? clear
        ret

;       Select and Hold window

.SelHoldWd
        call    GetWindowNum
        ret     c
        call    PutCrsrPos
        add     a, >Wd1Frame                    ; !! ld de,Wd1Frame; add a,d; ld d,a
        ld      d, a
        ld      e, <Wd1Frame
        ld      (sbf_ActiveWd), de
        push    de
        pop     ix

;       ----

.GetCrsrYX
        ld      l, (ix+wdf_crsrx)
        ld      h, (ix+wdf_crsry)
        ret

.PutCrsrPos
        ld      (ix+wdf_crsrx), l
        ld      (ix+wdf_crsry), h
        ret

;       ----

.GetWindowNum
        add     a, $20
        call    ASCII2num
        ret     c
        cp      1
        ret     c
        cp      9
        ccf
        ret     c
        dec     a
        ret

;       ----

;       Grey/Ungrey window

.GreyWindow
        push    hl
        cp      '+'-$20
        jr      nz, sdg_1

        set     WDFO_B_GREY, (ix+wdf_OpenFlags)
        call    ClearScr
        res     WDFO_B_GREY, (ix+wdf_OpenFlags)
        jr      sdg_2

.sdg_1
        cp      '-'-$20
        jr      nz, sdg_2

        set     WDFO_B_UNGREY, (ix+wdf_OpenFlags)
        call    ClearScr
        res     WDFO_B_UNGREY, (ix+wdf_OpenFlags)

.sdg_2
        pop     hl
        ret

;       ----

;       Output n copies of the code m

.MultipleOutput
        or      a
        ret     z                               ; zero copies? exit

        ld      b, a
.sdn_1
        ld      a, (sbf_VDU2)
        push    bc
        call    ScrD_PutChar
        pop     bc
        djnz    sdn_1
        ret

;       ----

;       EOR toggles

.ToggleScrAttr
        ld      b, a
        ld      a, $FF
        jr      sda_1

; apply toggles

.ApplyScrAttr
        ld      b, a
        ld      a, (ix+wdf_f6)                  ; wdf_f6 always zero?
        or      ~(WDFL_ULINE|WDFL_GREY|WDFL_FLASH|WDFL_REVERSE)

.sda_1
        ld      c, a
        inc     b
.sda_2
        dec     b
        ret     z
        push    bc
        inc     hl
        ld      a, (ix+wdf_flagsLo)
        and     WDFL_ULINE|WDFL_GREY|WDFL_FLASH|WDFL_REVERSE
        ld      e, a
        ld      a, (hl)
        and     c
        xor     e
        ld      (hl), a
        dec     hl
        call    CursorRight
        pop     bc
        jr      sda_2

;       ----

.ScrDrvCmdTable
        defb    '@',0
        defw    MoveToXY
        defb    'N',0
        defw    MultipleOutput
        defb    'C',$FD
        defw    ClearEOL
        defb    'C',$FE
        defw    ClearEOW
        defb    'A',0
        defw    ApplyScrAttr
        defb    'E',0
        defw    ToggleScrAttr
        defb    'G',0
        defw    GreyWindow
        defb    '*',0
        defw    PutBoxChar
        defb    '!',0
        defw    OSBlp
        defb    '?',0
        defw    PutUsrDefChar
        defb    '=',0
        defw    DefineUsrChar
        defb    'X',0
        defw    MoveToX
        defb    'Y',0
        defw    MoveToY
        defb    '+',0
        defw    SetScrAttr
        defb    '-',0
        defw    ResetScrAttr
        defb    '#',0
        defw    DefineWd
        defb    'I',0
        defw    SelInitWd
        defb    'H',0
        defw    SelHoldWd
        defb    'C',0
        defw    SelClearWd
        defb    'D',0
        defw    DeleteWd
        defb    'J','L'
        defw    SetLeftJustify
        defb    'J','R'
        defw    SetRightJustify
        defb    'J','C'
        defw    SetCenterJustify
        defb    'J','N'
        defw    SetNormalJustify
        defb    'L',0
        defw    SetLeftMargin
        defb    'R',0
        defw    SetRightMargin
        defb    '.',0
        defw    TogglePrFilter
        defb    0

.ScrDrvAttrTable

;       attributes

        defb    'B',WDFL_BOLD,0
        defb    'C',0,WDFH_CURSOR
        defb    'D',0,WDFH_DELAY                ; !! not delete
        defb    'F',WDFL_FLASH,0
        defb    'G',WDFL_GREY,0
        defb    'L',0,WDFH_CAPS
        defb    'N',0,0                         ; multiple output
        defb    'R',WDFL_REVERSE,0
        defb    'S',0,WDFH_VSCROLL
        defb    'T',WDFL_TINY,0
        defb    'U',WDFL_ULINE,0
        defb    'W',0,WDFH_HSCROLL

;       functions

        defb    $FF                             ; scroll up
        defw    ScrollUp
        defb    $FE                             ; scroll down
        defw    ScrollDown
        defb    $7F                             ; reset all toggles
        defw    ResetWdAttrs

;       special chars

        defb    $27,$60,0                       ; grave accent
        defb    $7C,$0A,0                       ; vertical bar
        defb    $20,$A0,0                       ; exact
        defb    $2D,$98,5                       ; shift         3*VDU $198
        defb    $2B,$10,0                       ; diamond
        defb    $2A,$11,0                       ; square
        defb    $F9,$01,0                       ; pointer right
        defb    $FA,$02,0                       ; pointer down
        defb    $F8,$04,0                       ; pointer left
        defb    $FB,$08,0                       ; pointer up
        defb    $F5,$13,0                       ; bullet right
        defb    $F6,$92,0                       ; bullet down
        defb    $F4,$12,0                       ; bullet left
        defb    $F7,$93,0                       ; bullet up
        defb    $E0,$00,5                       ; space         3*VDU $100
        defb    $E1,$03,5                       ; enter         3*VDU $103
        defb    $E2,$06,5                       ; tab           3*VDU $106
        defb    $E3,$09,5                       ; del           3*VDU $109
        defb    $E4,$0C,5                       ; esc           3*VDU $10c
        defb    $E6,$0F,5                       ; index         3*VDU $10f
        defb    $E5,$12,5                       ; menu          3*VDU $112
        defb    $E7,$15,5                       ; help          3*VDU $115
        defb    $21,$9B,5                       ; bell          3*VDU $19b
        defb    $F1,$16,2                       ; outline right 2*VDU $016
        defb    $F2,$94,2                       ; outline down  2*VDU $094
        defb    $F0,$14,2                       ; outline left  2*VDU $014
        defb    $F3,$96,2                       ; outline up    2*VDU $096
        defb    0


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
        cpl
        ld      c, a                            ; ~tLo
        inc     hl
        ld      a, (hl)
        ld      d, a                            ; tHi
        cpl
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
        and     $0f
        ld      bc, $fe00                      ; VDU $000-$00F
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
        and     LCDA_SPECMASK
        cp      LCDA_NULLCHAR
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
        ld      b, $ff
        jr      z, bs_3                         ; need scrolling
.sdht_1
        call    NewXValid
        jr      c, sdht_2                       ; right edge? next line
        inc     l
        inc     l
        inc     l
        ld      a, (hl)                         ; attributes
        dec     l
        and     LCDA_SPECMASK
        cp      LCDA_NULLCHAR
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
        call    Delay300Kclocks
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
        ld      a, $bf                          ; row6
        in      a, (BL_KBD)
        add     a, $51                          ; check for sh-l and <>
        jr      z, ScrollLock
        ret

;       ----

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
        ld      bc, [LCDA_HIRES|LCDA_UNDERLINE|LCDA_CH8]<<8|$A0
        bit     WDFO_B_5, a
        jr      z, ff_2
        ld      bc, [LCDA_REVERSE|LCDA_FLASH|LCDA_GREY|LCDA_UNDERLINE|LCDA_CH8]<<8|$FF

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
        res     LCDA_B_TINY, a
        jr      z, ceol_5
        or      LCDA_TINY
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
        bit     LCDA_B_TINY, a
        res     LCDA_B_GREY, a
        jr      z, ceol_7
        or      LCDA_GREY

.ceol_7
        and     $7f                     ; ~LCDA_TINY
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
        and     WDFL_REVERSE|WDFL_FLASH|WDFL_GREY|WDFL_ULINE
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
        add     a, b
        ret     c
        ld      b, a
        ld      a, SBF_PAGE+7
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


.GetWindowFrame
        or      a
        jr      nz, gwf_1                       ; a<>0? don't use current window
        ld      a, (sbf_ActiveWd+1)
        sub     >Wd1Frame-'1'

.gwf_1
        sub     $20
        call    GetWindowNum

        push    af
        add     a, >Wd1Frame                    ; SBF page !! ld hl,Wd1Frame; add a,h; ld h,a
        ld      h, a
        ld      l, <Wd1Frame                    ; low byte
        pop     af
        push    hl
        pop     ix                              ; window frame
        add     a, '1'
        ret     nc                              ; !! not enough to assert valid window
        ld      a, RC_Hand
        ret


; read text from the screen
;
;IN:    DE=buffer, HL=#bytes to read

.NqRDS
        call    GetOSFrame_HL                   ; BC=#bytes to read
        ld      b, h
        ld      c, l

        call    GetOSFrame_DE                   ; DE=buffer

        pop     af                              ; for ScreenClose()
        push    af
        push    ix
        ld      ix, (sbf_ActiveWd)
        push    af
        call    GetCrsrYX                       ; pointer actually

.rds_1
        ld      a, b
        or      c
        jr      z, rds_x                        ; no more chars? exit

        ld      a, (hl)                         ; char low byte
        push    hl
        call    VDU2ChrCode                     ; into ascii

        jr      c, rds_2                        ; not found in table

        dec     hl                              ; get ASCII
        dec     hl
        ld      a, (hl)

.rds_2
        pop     hl
        ex      af, af'

        exx
        call    ScreenClose                     ; restore S1
        exx

        ex      af, af'                         ; put char into buffer
        push    bc
        ex      de, hl
        call    PokeHLinc
        ex      de, hl
        pop     bc

        exx                                     ; put screen into S1
        call    ScreenOpen
        exx

        push    bc
        call    CursorRight                     ; advance pointer
        pop     bc                              ; decrement count and loop
        dec     bc
        jr      rds_1

.rds_x
        pop     af
        pop     ix
        call    ScreenClose

        or      a
        ret



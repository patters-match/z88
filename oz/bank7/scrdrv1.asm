; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1ec5b
;
; $Id$
; -----------------------------------------------------------------------------

        Module ScrDrv1

        org $ac5b                               ; 1351 bytes

        include "all.def"
        include "sysvar.def"
        include "bank0.def"

;       most of these xdefs/xrefs go away if all screen code is moved to bank 7
;       second part of code is at $f90c-fdf4

xdef    OSOutMain
xdef    Chr2ScreenCode                          ; Char2OZwdChar
xdef    Key2Chr_tbl                             ; Char2OZwdChar
xdef    sub_AD82                                ; unused
xdef    OSIsq                                   ; Printer driver
xdef    OSWsq
xdef    StorePrefixed                           ; Printer driver
xdef    InitUserAreaGrey                        ; MTH, OS_Ent
xdef	ScrD_GetMargins				; NqSp

xdef    VDU2ChrCode                             ; NqRDS    all these are screen related code in b00
xdef    GetCrsrYX                               ; NqRDS
xdef    ScrD_PutChar                            ; screen driver code reference
xdef    Zero_ctrlprefix                         ; screen driver code reference
xdef    ScrD_GetNewXY                           ; screen driver code reference
xdef    GetWindowNum                            ; screen driver code reference
xdef    ScrDrvAttrTable                         ; screen driver code reference



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
        cp      13
        jp      z, ScreenCR
        cp      7
        jp      z, ScreenBL
        cp      8
        jp      z, CursorLeft
        cp      9
        jp      z, CursorRight
        cp      $0A
        jp      z, CursorDown
        cp      $0B
        jp      z, CursorUp
        cp      $0C
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
        ld      b, 0                            ; clear attributes !! ld bc,$0001
        ld      c, 1                            ; and force ch8

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
        ld      b, $FE                          ; clear ch8 !! ld bc,$fe01
        ld      c, 1                            ; and force it set

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

;       !! unused

.sub_AD82
        bit     0, b
        jr      nz, loc_ADA1
        cp      $1F
        jr      nz, loc_AD8E
        ld      a, $A3
        jr      loc_ADA7

.loc_AD8E
        xor     $80
        ld      d, $80
        cp      $1F
        jr      nz, loc_AD99
        ld      a, $A3
        ret

.loc_AD99
        call    IsBoldable
        ret     nc
        xor     $80
        jr      loc_ADA7

.loc_ADA1
        ld      d, $40
        call    IsBoldableASCII
        ret     nc

.loc_ADA7
        ld      d, 0
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
        call    nz, Zero_ctrlprefix             ; not 1, cancel  !! jr nz
        ret     nz                              ; was not SOH
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
        call    sub_FB26                        ; find cmd in table, return func in DE
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
        and     255-WDFH_JUSTIFICATION
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
        and     1
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
        ld      a, '+'
        jr      iuag_1

        push    af                              ; !! unused
        ld      a, '-'

.iuag_1
        push    bc
        push    de
        push    hl
        ex      af, af'
        call    ScreenOpen
        ex      af, af'
        ld      de, (sbf_ActiveWd)              ; remember active window
        push    de
        call    KPrint
        defm    1,"6#8",$20+0,$20+0,$20+94,$20+8
        defm    1,"2H8"
        defm    1,"2G"
        defm    0
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
        jr      sdg_2                           ; !! cut&paste code :)

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
        ld      a, (ix+wdf_f6)
        or      $E1

.sda_1
        ld      c, a
        inc     b
.sda_2
        dec     b
        ret     z
        push    bc
        inc     hl
        ld      a, (ix+wdf_flagsLo)
        and     $1E                             ; hardware flags
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

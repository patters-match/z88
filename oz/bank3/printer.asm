; -----------------------------------------------------------------------------
; Bank 3 @ S2           ROM offset $efc0
;
; $Id$
; -----------------------------------------------------------------------------

        module  Printer

	include "fileio.def"
	include "memory.def"
	include "serintfc.def"
	include "syspar.def"

        org     $afc0

DEFVARS $0dd0
{
        StackBufPtr     ds.w    1
        CtrlBuf         ds.w    1
        CtrlLen         ds.b    1
        prtInChar       ds.b    1
        Translations    ds.b    37
        PlaceHolderChar ds.b    1
        PendingSpaces   ds.b    1
        Rows            ds.b    1
        PageLen         ds.b    1
        Flags           ds.b    1
        AttrUnderline   ds.b    1
        AttrBold        ds.b    1
        AttrExtended    ds.b    1
        AttrItalics     ds.b    1
        AttrSubscript   ds.b    1
        AttrSuperscript ds.b    1
        AttrAltfont     ds.b    1
        AttrUserdef     ds.b    1
}

;       PrinterAttrs
defc    PRA_B_ON                =0              ; state
defc    PRA_B_PENDING           =1              ; changed but not yet printed
defc    PRA_B_PLACEHOLDER       =2              ;
defc    PRA_B_RESETCR           =7              ; reset at CR?

defc    PRA_ON                  =1
defc    PRA_PENDING             =2
defc    PRA_PLACEHOLDER         =4
defc    PRA_RESETCR             =128

;       PrtFlags
defc    PRT_B_ALLOWLF   =0                      ; LF after CR?
defc    PRT_B_ENABLED   =1                      ; output enabled?

defc    PRT_ALLOWLF     =1
defc    PRT_ENABLED     =2

 IF	FINAL=0

.PrntChar
        jp      PrntCharMain                    ; func $C0, A=char

.PrntCtrlSeq
        jp      PrntCtrlSeqMain                 ; func $C3,

.PrntInit
        ld      hl, -33                         ; func $C6
        add     hl, sp
        ld      sp, hl
        ld      (StackBufPtr), hl

;       get translated chars

        ld      hl, Translations
        xor     a
.init_1
        push    af
        call    GetNq_BC
        ld      a, $20
        ld      de, (StackBufPtr)
        OZ      OS_Nq                           ; enquire TrX

        or      a                               ; store translation char or NULL
        jr      z, init_2
        ld      a, (de)
.init_2
        ld      (hl), a
        inc     hl
        pop     af
        inc     a
        cp      37                              ; 37 translations
        jr      nz, init_1

        call    InitAttrs
        xor     a
        ld      (Flags), a
        ld      (PlaceHolderChar), a

;       get attribute defaults

        ld      hl, AttrUnderline
        ld      bc, PA_On1
        ld      e, 8
.init_3
        inc     bc
        inc     bc
        push    de

        call    DoOSNq
        res     PRA_B_RESETCR, (hl)
        jr      z, init_4
        ld      a, e
        cp      'Y'
        jr      z, init_4
        set     PRA_B_RESETCR, (hl)

.init_4
        inc     bc
        ld      a, (PlaceHolderChar)
        or      a
        jr      nz, init_5

        call    DoOSNq
        res     PRA_B_PLACEHOLDER, (hl)         ; not using placeholder
        jr      z, init_5
        set     PRA_B_PLACEHOLDER, (hl)         ; uses placeholder
        ld      a, e
        ld      (PlaceHolderChar), a

.init_5
        inc     bc
        inc     hl
        pop     de
        dec     e
        jr      nz, init_3

        ld      bc, PA_Alf
        call    DoOSNq
        ld      hl, Flags
        jr      z, init_6
        ld      a, e
        cp      'Y'
        jr      z, init_6
        set     PRT_B_ALLOWLF, (hl)

.init_6
        or      a                               ;Fc=0

;       ----

.PrntExit
        ex      af, af'
        ld      hl, (StackBufPtr)
        ld      bc, 33
        add     hl, bc
        ld      sp, hl
        ex      af, af'
        ret

;       ----

.PrntCharMain
        ld      hl, -33
        add     hl, sp
        ld      sp, hl
        ld      (StackBufPtr), hl

        ld      (prtInChar), a
        call    GetCOM
        call    PrntCharMain2
        jr      PrntExit

;       ----

.PrntCharMain2
        cp      12                              ; handle FF, LF, CR
        jp      z, PrntFF
        cp      10
        jp      z, PrntLF
        cp      13
        jr      z, PrntCR

        call    ApplyAttrs
        ret     c
        ld      a, (prtInChar)

        cp      ' '                             ; delay spaces
        jr      nz, prtc_1
        ld      hl, PendingSpaces
        inc     (hl)
        ret

.prtc_1
        call    PrntSpaces                      ; print pending spaces
        ret     c

        ld      b, 8
        ld      hl, AttrUserdef
.prtc_2
        bit     PRA_B_ON, (hl)
        jr      z, prtc_3
        bit     PRA_B_PLACEHOLDER, (hl)
        jr      nz, prtc_5
.prtc_3
        dec     hl
        djnz    prtc_2

.prtc_4
        ld      a, (prtInChar)                  ; try to translate non-NULL char
        or      a
        jr      z, PutChar

        ld      bc, 37
        ld      hl, Translations
        cpir
        jr      nz, PutChar                     ; not found, print as is

        ld      a, 36                           ; print output string
        sub     c
        call    GetNq_BC
        inc     bc
        ld      de, (StackBufPtr)
        jp      PrntOSNq

.prtc_5
        ld      c, 1                            ; on
        call    GetPAtoggle
        or      a
        jr      z, prtc_4                       ; no attribute, try translating

        ex      de, hl
        ld      e, a                            ; store length

        ld      c, a                            ; find placeholder in string
        ld      b, 0
        ld      a, (PlaceHolderChar)
        cpir
        jr      nz, prtc_4                      ; not found, try translating

        dec     hl                              ; replace placeholder with current char
        ld      a, (prtInChar)
        ld      (hl), a

        ld      a, e                            ; and print
        jp      PrntStackBuffer

;       ----

.PrntCR
        xor     a                               ; forget spaces
        ld      (PendingSpaces), a
        call    ResetAttrs
        ret     c
        ld      a, 13
        ld      hl, Flags
        bit     PRT_B_ALLOWLF, (hl)             ; next line if allowed
        jr      nz, lf_1

        jr      PutChar                         ; otherwise just CR

;       ----

.PrntLF
        xor     a                               ;forget spaces
        ld      (PendingSpaces), a
        call    ResetAttrs
        ret     c
        ld      hl, Flags                       ; was LF done by CR already?
        bit     PRT_B_ALLOWLF, (hl)
        ret     nz

        ld      a, 10                           ; otherwise print LF

.lf_1
        push    af
        ld      bc, (Rows)                      ; inc row, reset if pagelen reached
        inc     c
        ld      a, c
        cp      b                               ; if row++=pagelen then reset row
        jr      c, lf_2
        ld      c, 0
.lf_2
        ld      a, c
        ld      (Rows), a
        pop     af

;       ----

.PutChar
        or      a                               ; Fc=0
        push    hl                              ; return if printing disabled
        ld      hl, Flags
        bit     PRT_B_ENABLED, (hl)
        pop     hl
        ret     z

        OZ      OS_Pb                           ; write byte to printer handle
        ret

;       ----

.PrntFF
        call    ResetAttrs
        ret     c

        ld      a, $20                          ; print Eop
        ld      de, (StackBufPtr)
        ld      bc, PA_Eop
        OZ      OS_Nq
        or      a
        jr      z, ff_1                         ; no Eop, send series of linefeeds
        call    PrntStackBuffer
        ret     c
        jr      ff_3

.ff_1
        ld      bc, (Rows)                      ; find out how many lines to print
        ld      a, b
        sub     c                               ; pagelen-rows
        jr      z, ff_3                         ; none, exit
        ld      b, a

        ld      a, 13                           ; select CR or LF
        ld      hl, Flags
        bit     PRT_B_ALLOWLF, (hl)
        jr      nz, ff_2
        ld      a, 10

.ff_2
        call    PutChar                         ; print char B times
        ret     c
        djnz    ff_2

.ff_3
        xor     a                               ; reset row/space counts
        ld      (Rows), a
        ld      (PendingSpaces), a
        ret

;       ----

.PrntCtrlSeqMain
        xor     5                               ; prefix<>5, exit
        ret     nz

        ld      a, c                            ; length=0, exit
        or      a
        ret     z

        ld      (CtrlBuf), de                   ; find char in table
        ld      (CtrlLen), a
        ld      hl, CtrlChars
        ld      b, 0
.pseq_1
        ld      a, (de)
        or      $20                             ; lower()
        cp      (hl)
        jr      z, pseq_2                       ; found
        inc     hl
        inc     b
        ld      a, (hl)
        or      a
        jr      nz, pseq_1
        ret                                     ; not found, exit

.pseq_2
        ld      a, b
        cp      8
        jr      nc, pseq_3                      ; not attribute toggle

        ld      c, b                            ; toggle ON/OFF flag
        ld      b, 0
        ld      hl, AttrUnderline
        add     hl, bc
        ld      a, (hl)
        xor     PRA_PENDING
        ld      (hl), a
        ret

.pseq_3
        ld      hl, -33
        add     hl, sp
        ld      sp, hl

        ld      (StackBufPtr), hl
        ex      de, hl
        ld      c, a

        ld      b, 0
        ld      hl, CtrlSeqFuncs-2*8
        add     hl, bc
        add     hl, bc

        ld      bc, PrntExit                    ; push return address
        push    bc

        ld      a, (hl)                         ; get func address and call it
        inc     hl
        ld      h, (hl)
        ld      l, a
        jp      (hl)

.CtrlSeqFuncs
        defw FilterOn
        defw FilterOff
        defw Microspace
        defw ResetAttrs
        defw SetPageLen
        defw SendHex

.CtrlChars
        defm "ubxilrae"
        defm $7B,$7D,"hsp$",0

;       $ - output hex char

.SendHex
        call    GetCOM
        ld      hl, (CtrlBuf)
        inc     hl                              ; skip '$'

        ld      a, (CtrlLen)                    ; length<>3, exit
        xor     3
        ret     nz

        ld      a, (hl)
        inc     hl
        call    AtoH                            ; high nybble
        ret     nc
        add     a, a                            ; *16
        add     a, a
        add     a, a
        add     a, a
        ld      c, a
        ld      a, (hl)
        call    AtoH                            ; low nybble
        ret     nc
        add     a, c
        jp      PutChar

.AtoH
        sub     '0'
        ccf
        ret     nc
        cp      10
        ret     c
        and     $DF                             ; upper()
        sub     7
        cp      10
        ccf
        ret     nc
        cp      16
        ret

;       [ - turn filter on

.FilterOn
        push    de
        ld      l, SI_SFT                       ; soft reset serial
        OZ      OS_Si
        pop     de

        call    InitAttrs                       ; enable output
        ld      hl, Flags
        set     PRT_B_ENABLED, (hl)

        ld      bc, PA_Pon                      ; print Pon
        jr      PrntOSNq

;       ] - turn filter off

.FilterOff
        ld      bc, PA_Pof                      ; print Pof
        call    PrntOSNq

        ld      hl, Flags                       ; disable output
        res     PRT_B_ENABLED, (hl)
        ret

;       h - microspace

.Microspace
        ld      a, (CtrlLen)                    ; length<>2, exit
        xor     2
        ret     nz

        call    PrntSpaces
        ld      a, $20                          ; print Mip
        ld      bc, PA_Mip
        OZ      OS_Nq
        call    PrntStackBuffer

        ld      a, $20                          ; get Mio, default to $20
        ld      bc, PA_Mio
        call    DoOSNq
        jr      z, ms_1
        ld      a, e

.ms_1
        ld      hl, (CtrlBuf)
        inc     hl                              ; skip 'h'
        add     a, (hl)                         ; print Mio+char-$20
        sub     $20
        call    PutChar
        ret     c

        ld      bc, PA_Mis                      ; print Mis
        ld      de, (StackBufPtr)

;       get parameter and print it

.PrntOSNq
        ld      a, $20
        OZ      OS_Nq

;       print stack buffer

.PrntStackBuffer
        ld      b, a
        call    GetCOM
        ld      a, b                            ; lenght=0, exit
        or      a
        ret     z

        ld      hl, (StackBufPtr)
.psb_1
        ld      a, (hl)
        inc     hl
        call    PutChar
        ret     c
        djnz    psb_1
        ret

;       reset attributes

.ResetAttrs
        ld      hl, AttrUserdef
        ld      b, 8

.ra_1
        bit     PRA_B_RESETCR, (hl)
        jr      nz, ra_2

        bit     PRA_B_ON, (hl)
        jr      z, ra_2                         ; was already off
        ld      c, 0                            ; off
        call    ToggleAttr
        ret     c

.ra_2
        dec     hl
        djnz    ra_1
        or      a
        ret

;       p - set page length

.SetPageLen
        ld      a, (CtrlLen)                    ; length<>2, exit
        xor     2
        ret     nz

        ld      (Rows), a                       ; reset row count
        ld      hl, (CtrlBuf)
        inc     hl                              ; skip 'p'
        ld      a, (hl)
        sub     $20
        ld      (PageLen), a                    ; length=char-$20
        or      a
        ret

;       ----

.ApplyAttrs
        ld      hl, AttrUserdef
        ld      b, 8

.aa_1
        ld      a, (hl)
        bit     PRA_B_PENDING, a
        jr      z, aa_2

        and     PRA_ON
        xor     PRA_ON
        ld      c, a                            ; inverse on/off
        call    PrntSpaces
        ret     c
        call    ToggleAttr
        ret     c

.aa_2
        dec     hl
        djnz    aa_1
        or      a
        ret

;       ----

.ToggleAttr
        push    bc
        push    hl
        ld      a, (hl)                         ; toggle state and mark as done
        xor     PRA_ON
        res     PRA_B_PENDING, a
        ld      (hl), a
        bit     PRA_B_PLACEHOLDER, a
        jr      nz, ta_1
        call    GetPAtoggle
        call    PrntStackBuffer
.ta_1
        pop     hl
        pop     bc
        ret


;       get PA_On (C=1) or PA_Off (C=0) for attribute B

.GetPAtoggle
        ld      a, b
        dec     a
        add     a, a
        add     a, a
        add     a, $28
        inc     a
        sub     c
        ld      c, a                            ; 25+4*B-C
        ld      b, $80                          ;  PA_OnX/PA_OffX
        ld      a, $20
        ld      de, (StackBufPtr)
        OZ      OS_Nq                           ; enquire parameter
        ret

;       ----

.PrntSpaces
        ld      a, (PendingSpaces)
        or      a
        ret     z

        push    bc
        ld      b, a
        ld      a, ' '
        call    GetCOM

.spc_1
        call    PutChar
        jr      c, spc_2
        djnz    spc_1

.spc_2
        pop     bc
        ret     c
        xor     a
        ld      (PendingSpaces), a
        ld      a, $20
        ret

;       ----

.GetCOM
        push    bc
        ld      bc, NQ_Com                      ; get COM handle
        OZ      OS_Nq
        pop     bc
        ret

;       ----

.DoOSNq
        ld      de, 2
        OZ      OS_Nq                           ; enquire (fetch) parameter
        or      a
        ret
;       ----

.GetNq_BC
        add     a, a
        cp      18
        jr      c, nqbc_1                       ; Tr1-Tr9
        add     a, $26                          ; Tr10-Tr37
.nqbc_1
        add     a, $48
        ld      c, a
        ld      b, $80
        ret

;       ----

.InitAttrs
        ld      hl, AttrUnderline
        ld      b, 8
.inita_1
        ld      a, (hl)
        and     PRA_RESETCR | PRA_PLACEHOLDER
        ld      (hl), a
        inc     hl
        djnz    inita_1

        xor     a
        ld      (PendingSpaces), a
        ld      (Rows), a
        ld      a, 66
        ld      (PageLen), a
        ret

 ELSE
	binary "printer.bin"
 ENDIF

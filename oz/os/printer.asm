; **************************************************************************************************
; Printer filter routines.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id: printer.asm 2517 2006-08-05 12:48:58Z pek $
;***************************************************************************************************

        module  Printer

        include "ctrlchar.def"
        include "printer.def"
        include "fileio.def"
        include "memory.def"
        include "serintfc.def"
        include "syspar.def"
        include "sysvar.def"

        
xdef    OSPrtInit                               ; bank0/pagfi.asm
xdef    OSPrtPrint                              ; bank0/misc2.asm

xref    ScreenOpen                              ; bank0/scrdrv4.asm
xref    ScreenClose                             ; bank0/scrdrv4.asm
xref    OSIsq                                   ; bank7/scrdrv1.asm
xref    StorePrefixed                           ; bank7/scrdrv1.asm


; -----------------------------------------------------------------------------
;       OSPrtPrint
;       print control sequence or char to printer filter
;
;       IN:     A = character to be written to printer filter
;       OUT:    success Fc = 0, failure Fc = 1 and A = RC_ESC or RC_WP
;
;       ..BCDEHL/IXIY   same
;       AF....../....   different
; -----------------------------------------------------------------------------
.OSPrtPrint
        push    bc
        ex      af, af'
        call    ScreenOpen                      ; we need screen because prt sequence buffer is in SBF
        ex      af, af'
        ld      hl, (PrtSeqPrefix)              ; ld l,(PrtSeqPrefix)
        inc     l
        dec     l
        jr      nz, prtm_2                      ; have ctrl sequence? add to it
        cp      $20
        jr      nc, prtm_3                      ; not ctrl char? print
        cp      ESC
        jr      z, prtm_3                       ; ESC? print
        cp      7                               ; 00-06, 0E-1F: ctrl sequence
        jr      c, prtm_1                       ; otherwise print
        cp      $0E
        jr      c, prtm_3

.prtm_1
        ld      (PrtSeqPrefix), a               ; store prefix char
        ld      hl, PrtSequence                 ; init sequence
        call    OSIsq
        or      a                               ; Fc=0
        jr      prtm_x2

.prtm_2
        ld      hl, PrtSequence                 ; put into buffer
        call    StorePrefixed
        ccf
        jr      nc, prtm_x2                     ; not done yet? exit, Fc=0

        ld      a, (PrtSeqPrefix)               ; ctrl char
        ld      bc, (PrtSequence)               ; c,(PrtSequence) - length
        ld      b, 0
        ld      de, PrtSeqBuf                   ; buffer

        call    OSPrtPrntCtrlSeq                ; see below
        jr      prtm_x1
.prtm_3
        call    OSPrtPrntChar                   ; see below
.prtm_x1
        ex      af, af'
        xor     a                               ; reset prefix
        ld      (PrtSeqPrefix), a
        ex      af, af'

.prtm_x2
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        pop     bc
        ret



; -----------------------------------------------------------------------------
;       Printer Filter initialisation
;       called from OSSp_Pagfi during reset or when applying new parameters
;
;       IN:     -
;       OUT:    -
;
; -----------------------------------------------------------------------------
.OSPrtInit
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


; -----------------------------------------------------------------------------
;       Printer Filter Print Char
;
;       IN:     A=char
;       OUT:    -
;
; -----------------------------------------------------------------------------
.OSPrtPrntChar
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


; -----------------------------------------------------------------------------
;       Printer Filter Print control sequence
;
;       IN:     A = control char (PrtSeqPrefix)
;               C = length (PrtSequence)
;               DE = buffer (PrtSeqBuf)
;       OUT:    -
;
; -----------------------------------------------------------------------------
.OSPrtPrntCtrlSeq
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

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0101
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Misc2

        include "ctrlchar.def"
        include "error.def"
        include "director.def"
        include "memory.def"
        include "sysvar.def"
        include "lowram.def"

        org     $c101                           ; 261 bytes

xdef    CallDC
xdef    CallGN
xdef    CallOS2byte
xdef    OsAlm
xdef    OSEpr
xdef    OSPrt
xdef    OSPrtMain
xdef    OzCallInvalid

;       bank 0

xref    GetOSFrame_BC
xref    MS2BankA
xref    MS2BankB
xref    MS2BankK1
xref    osfpop_1
xref    OSFramePop
xref    OSFramePush
xref    OSFramePushMain
xref    PrFilterCall
xref    ScreenClose
xref    ScreenOpen
xref    SetPendingOZwd

;       bank 7

xref    OSAlmMain
xref    OSEprTable
xref    OSIsq
xref    StorePrefixed

;       ----

;       all 2-byte calls use OSframe

.CallDC
        ld      a, OZBANK_DC                    ; Bank 2, $80xx
        jr      ozc_2                           ; !! defb OP_LDBCnn to skip over 'ld a'
.CallGN
        ld      a, OZBANK_GN                    ; Bank 3, $80xx
.ozc_2
        ld      d, >GNCALLTBL
        jr      ozc_3

.CallOS2byte
        ld      a, OZBANK_HI                    ; Bank 0, $FFxx
        ld      d, >OZCALLTBL

.ozc_3
        pop     bc                              ; S2/S3
        pop     hl                              ; bump caller PC
        inc     hl
        push    hl

        ld      hl, ozc_ret                     ; return here
        jp      OSFramePushMain
.ozc_ret
        cp      a                               ; Fz=1, Fc=0
        ex      af, af'                         ; alt register
        call    MS2BankA                        ; bind code in
        exx                                     ; alt registers

        ex      de, hl                          ; function address into DE
        ld      e, (hl)
        inc     l
        ld      d, (hl)

        set     6, h                            ; or $4000 - return into S3
        ld      l, 3                            ; return call always at $xx03
        push    hl                              ; return address
        push    de                              ; function address
        ex      af, af'
        push    af                              ; caller A
        ex      af, af'
        push    af                              ; code bank
        call    MS2BankK1
        exx                                     ; main registers
        jp      OZCallJump                      ; bind code into S3 and ret to it

.OzCallInvalid
        ld      a, RC_OK
        scf
        jp      OZCallReturn2
        ret                                     ; !! unused

;       ----

;       send character directly to printer filter

.OSPrt
        call    OSFramePush
        ex      af, af'                         ; we need screen because prt sequence buffer is in SBF
        call    ScreenOpen                      ; !! this is also done in OSPrtMain, unnecessary here?
        ex      af, af'

.prt_1
        ld      hl, (ubCLIActiveCnt)            ; !! just L
        inc     l
        dec     l
        jr      z, prt_2                        ; no cli, print direct

        OZ      DC_Prt                          ; otherwise use DC
        jr      nc, prt_x                       ; no error? exit
        cp      RC_Time
        jr      z, prt_1                        ; timeout? retry forever
        scf
        jr      prt_x

.prt_2
        call    OSPrtMain

.prt_x
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        jp      OSFramePop

;       ----

.OSPrtMain
        push    bc
        ex      af, af'
        call    ScreenOpen
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
        jr      prtm_x

.prtm_2
        ld      hl, PrtSequence                 ; put into buffer
        call    StorePrefixed
        ccf
        jr      nc, prtm_x                      ; not done yet? exit, Fc=0

        ld      a, (PrtSeqPrefix)               ; ctrl char
        ld      bc, (PrtSequence)               ; c,(PrtSequence) - length
        ld      b, 0
        ld      de, PrtSeqBuf                   ; buffer

        ld      l, <PrntCtrlSeq
        jr      prtm_4
.prtm_3
        ld      l, <PrntChar
.prtm_4
        call    PrFilterCall
        ex      af, af'
        xor     a                               ; reset prefix
        ld      (PrtSeqPrefix), a
        ex      af, af'

.prtm_x
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        pop     bc
        ret

;       ----

;       Eprom Interface

;       we have OSFrame so remembering S2 is unnecessary, as is remembering IY

.OSEpr
        push    hl                              ; save HL
        ld      hl, OSEprTable                  ; get function address
        ld      b, 0
        ld      c, a
        add     hl, bc
        ex      (sp), hl                        ; restore HL, push function
        jp      GetOSFrame_BC                   ; get caller BC and ret to function, then to osfpop

;       ----

;       alarm manipulation

.OSAlm
        call    OSFramePush

        ld      c, b
        ld      b, a

        call    OZ_DI
        push    af

        ld      a, c
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1
        call    OSAlmMain

        pop     af
        call    OZ_EI

        call    SetPendingOZwd                  ; request OZ window redraw
        jp      osfpop_1

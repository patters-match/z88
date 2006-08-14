; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0101
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Misc2

        include "error.def"
        include "director.def"
        include "memory.def"
        include "sysvar.def"
        include "../bank7/lowram.def"

xdef    CallDC
xdef    CallGN
xdef    CallOS2byte
xdef    OsAlm
xdef    OSEpr
xdef    OSPrt
xdef    OzCallInvalid

xref    GetOSFrame_BC                           ; bank0/misc5.asm
xref    MS2BankA                                ; bank0/misc5.asm
xref    MS2BankB                                ; bank0/misc5.asm
xref    MS2BankK1                               ; bank0/misc5.asm
xref    osfpop_1                                ; bank0/misc4.asm
xref    OSFramePop                              ; bank0/misc4.asm
xref    OSFramePush                             ; bank0/misc4.asm
xref    OSFramePushMain                         ; bank0/misc4.asm
xref    SetPendingOZwd                          ; bank0/misc3.asm

xref    OSPrtPrint                              ; bank7/printer.asm
xref    OSAlmMain                               ; bank7/osalm.asm
xref    OSEprTable                              ; bank7/eprom.asm


;       all 2-byte calls use OSframe

.CallDC
        ld      a, OZBANK_DC                    ; Bank 2, $80xx
        ld      d, >DCCALLTBL
        jr      ozc
.CallGN
        ld      a, OZBANK_GN                    ; Bank 3, $80xx
        ld      d, >GNCALLTBL
        jr      ozc

.CallOS2byte
        ld      a, OZBANK_0                     ; Bank 0, $FFxx
        ld      d, >OZCALLTBL

.ozc                                            ; e contains 2nd opcode
        pop     bc                              ; S2/S3
        pop     hl                              ; caller PC
        inc     hl
        push    hl                              ; caller PC
        ld      hl, ozc_ret                     ; return here
        jp      OSFramePushMain                 ; OSPUSH and jump to routine

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

;       ----

;       send character directly to printer filter

.OSPrt
        call    OSFramePush
;        ex      af, af'                         ; we need screen because prt sequence buffer is in SBF
;        call    ScreenOpen                      ; !! this is also done in OSPrtMain, unnecessary here?
;        ex      af, af'

        ld      hl, (ubCLIActiveCnt)            ; !! just L
        inc     l
        dec     l
        jr      z, prt_2                        ; no cli, print direct

        OZ      DC_Prt                          ; otherwise use DC
        jr      nc, prt_x                       ; no error? exit
        cp      RC_Time
        jr      z, OSPrt                        ; timeout? retry forever
        scf
        jr      prt_x

.prt_2
        extcall OSPrtPrint, OZBANK_7

.prt_x
;        ex      af, af'
;        call    ScreenClose
;        ex      af, af'
        jp      OSFramePop

;       ----

;       Eprom Interface
;       we have OSFrame so remembering S2 is unnecessary, as is remembering IY

.OSEpr
        ld      bc, 7<<8 | MS_S2
        rst     OZ_MPB                          ; MS2b07 and remember S3 !! use MS2BankK1
        push    bc                              ; !! ospop restores S2/IY
        push    iy

        ld      bc, osepr_ret                   ; push return address
        push    bc
        push    hl                              ; save HL
        ld      hl, OSEprTable                  ; get function address
        ld      b, 0
        ld      c, a
        add     hl, bc
        ex      (sp), hl                        ; restore HL, push function
        jp      GetOSFrame_BC                   ; get caller BC and ret to function, then here

.osepr_ret
        pop     iy
        pop     bc                              ; restore S2
        push    af
        rst     OZ_MPB
        pop     af
        ret                                     ; return thru ospop

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

;       ----


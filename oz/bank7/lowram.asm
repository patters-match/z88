; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1eab6
;
; $Id$
; -----------------------------------------------------------------------------

        Module LowRAM

        org $0000                               ; 421 bytes

        include "all.def"
        include "sysvar.def"

 IF     FINAL=0

defc    INTEntry                =$dead
defc    NMIEntry                =$dead
defc    CallErrorHandler        =$dead
defc    OZBuffCallTable         =$dead
defc    OZCallTable             =$dead

 ELSE
        include "kernel.def"
 ENDIF


xdef    DefErrHandler
xdef    INTReturn
xdef    JpAHL
xdef    JpHL
xdef	OZ_RET1
xdef	OZ_RET0
xdef    OZ_BUF
xdef	OZ_DI
xdef	OZ_EI
xdef    OZ_SCF
xdef    OZCallJump
xdef    OZCallReturn1
xdef    OZCallReturn2
xdef    OZCallReturn3

; this code is copied to 0000 - 01A4

.rst00
        di
        xor     a
        out     (BL_COM), a                     ; bind b00 into low 2KB
                                                ; code continues in ROM
        defb    $ff,$ff,$ff,$ff

.rst08
        scf
        ret

        defb    0,0,0,0,0,0

.rst10
        scf
        ret

        defb    0,0,0,0,0,0

.rst18
        jp      FPPmain

        defb    $ff,$ff

        jp      OZCallReturn4                   ; 001d, called from FPP

.rst20
        jp      CallOZMain                      ; 0020

        defb    $ff,$ff

        jp      CallOZret                       ; 0025

.rst28
        scf
        ret

        defb    0,0,0,0,0,0

.rst30
        jp      GhostMain                       ; 0030

        defb    $ff,$ff,$ff,$ff,$ff

.rst38
        push    af
        ld      a, (BLSC_SR3)                   ; remember S3 and bind in b00
        push    af
        xor     a
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        in      a, (BL_STA)                     ; get interrupt status and execute inthandler
        jp      INTEntry

;       OZ low level jump table

.OZ_RET1
        jp      OZCallReturn1                   ; 0048
.OZ_RET0
        jp      OZCallReturn0                   ; 004B
.OZ_BUF
        jp      OZBUFmain                       ; 004E
.OZ_DI
        jp      OZDImain                        ; 0051
.OZ_EI
        jp      OZEImain                        ; 0054
.OZ_SCF
        jp      OZSCFmain                       ; 0057

        defs    4*3 ($ff)

.OZNMI
        push    af                              ; 0066
        ld      a, BM_COMRAMS                   ; bind bank $20 into lowest 8KB of segment 0
        out     (BL_COM), a

        push    hl                              ; if SP in lowest page we must
        ld      hl, 0                           ; be in init code - reset
        add     hl, sp
        inc     h
        dec     h
        pop     hl
        jr      z, rst00

        ld      a, i                            ; store int disable count
        push    af

        di
        ld      a, (BLSC_SR3)                   ; remember S3 and bind in b00
        push    af
        xor     a
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        call    NMIEntry                        ; call nmihandler

        pop     af                              ; restore S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a

        pop     af
        jp      po, noEI                        ; ints were disabled
        pop     af
        ei
        ret

.noEI
        pop     af                              ; !! can use any 'pop af; ret' below
        ret

; 0095
.OZCallJump
        pop     af                              ; restore S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        pop     af                              ; restore AF
        ret

; 009d
.INTReturn
        pop     af                              ; restore S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        pop     af                              ; restore AF
        ei
        ret

; 00a6          ret with AFBCDEHL

.OZCallReturn0
        ex      af, af'
        pop     af
        or      a
        jr      OZCallReturnCommon

; 00ab          ret with AFBCDEHL

.OZCallReturn1
        exx

; 00ac          ret with AFbcdehl

.OZCallReturn2
        ex      af, af'

; 00ad          ret with afbcdehl

.OZCallReturn3
        exx

; 00ae          ret with afBCDEHL

.OZCallReturn4
        pop     af
        scf

; 00b0

.OZCallReturnCommon
        ld      (BLSC_SR3), a                   ; set S3
        out     (BL_SR3), a
        push    hl                              ; decrement call level
        ld      hl, ubAppCallLevel
        dec     (hl)
        pop     hl
        ex      af, af'
        ret     nc                              ; no error, return

        ex      af, af'
        call    z, error
        ex      af, af'
        ret

; 00c3

.error
        ret     nc
        push    af
        call    MS3Bank00
        pop     af
        push    af
        call    CallErrorHandler
        pop     af                              ; restore S3

; 00ce

.MS3BankA
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        ret

; 00d4
.JpAHL
        call    MS3BankA
        ex      af, af'
        call    JpHL
        ex      af, af'
; 00dc

.MS3Bank00
        xor     a
        jr      MS3BankA

; 00df

.JpHL
        jp      (hl)                            ; !! can use one in CallOZMain

; 00e0
.DefErrHandler
        ret     z
        cp      a
        ret

;00e3
.OZBUFmain
        ex      af, af'
        ld      a, (BLSC_SR3)                   ; remember S3
        push    af
        call    MS3Bank00

        ld      a, l                            ; !! ld a, l; ld hl,OZBuffCallTable; add a,l; ld l,a
        add     a, <OZBuffCallTable
        ld      l, a
        ex      af, af'
        ld      h, >OZBuffCallTable
        call    JpHL

        ex      af, af'
        pop     af                              ; restore S3
        call    MS3BankA
        ex      af, af'
        ret

; 00fc

.CallOZMain
        ex      af, af'
        exx
        ld      hl, ubAppCallLevel              ; increment call level
        inc     (hl)
        pop     hl                              ; caller PC
        ld      e, (hl)                         ; get opByte
        inc     hl
        push    hl
        ld      bc, (BLSC_SR2)                  ; remember S2/S3
        push    bc
        xor     a                               ; bind b00 into S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a

        ld      d, >OZCallTable                 ; function jumper in DE
        ex      de, hl
        jp      (hl)                            ; $FFnn, nn=opByte

; 0115

.FPPmain
        ex      af, af'
        exx
        pop     bc                              ; caller PC
        ld      a, (bc)                         ; get opByte
        inc     bc
        push    bc
        ld      bc, (BLSC_SR2)                  ; remember S2/S3
        push    bc
        push    iy
        ld      iy, ubAppCallLevel              ; increment call level
        inc     (iy+0)
        ld      iy, 0
        add     iy, sp                          ; IY=SP
        push    ix
        ld      bc, $D800                       ; FPP return $d800
        push    bc
        ld      c, a
        ld      b, $D8                          ; !! unnecessary
        push    bc                              ; call function at $d8nn, nn=opByte

        ld      a, 2                            ; bind b02 into S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        ex      af, af'
        exx
        ret

; 0143

.GhostMain
        ex      af, af'
        exx
        pop     hl                              ; caller PC
        ld      e, (hl)                         ; get opByte - function low byte
        inc     hl
        push    hl
        ld      a, (ix+2)                       ; handle? hnd_Type
        cp      6
        jr      nz, ghost_err

        ld      a, (ix+4)                       ; tri_handle? segment
        cp      4
        jr      nc, ghost_err

        add     a, BL_SR0
        ld      l, a
        ld      d, (ix+5)                       ; function page
        ld      a, (ix+6)                       ; bank
        ld      h, BLSC_PAGE
        cp      (hl)
        jp      z, ghost_1                      ; same?
        ld      b, (hl)                         ; old bank
        ld      c, l                            ; segment
        push    bc                              ; remember segment/bank
        ld      (hl), a                         ; bind A in
        out     (c), a
        ld      hl, GhostReturn                 ; return here
        push    hl
.ghost_1
        push    de                              ; function address
        exx
        ex      af, af'
        ret                                     ; call it

; 0174

.ghost_err
        exx
        ld      a, RC_HAND

; 0177

.OZSCFmain
        scf
        ret

; 0179

.GhostReturn
        ex      af, af'
        exx
        pop     bc                              ; restore Sx
        ld      a, b
        ld      b, 4
        ld      (bc), a
        out     (c), a
        exx
        ex      af, af'
        ret

; 0185

.CallOZret
        pop     bc                              ; restore bank B into segment C
        ld      a, c
        add     a, BL_SR0
        ld      c, a
        ld      a, b
        ld      b, BLSC_PAGE
        ld      (bc), a
        out     (c), a
        pop     bc
        pop     af
        ret

; 0193

.OZDImain
        xor     a                               ; A=0, Fc=0
        push    af                              ; store flags - only works because
        pop     af                              ; interrupts are disabled
        ld      a, i
        di
        ret     pe                              ; interrupts enabled? exit

        dec     sp                              ; get flags stored above
        dec     sp                              ; !! why not xor a; scf?
        pop     af
        cp      1                               ; Fc=1, ints were disabled
        ld      a, i                            ; get int disable count
        ret

; 01a2

.OZEImain
        ret     c                               ; ints were disabled? exit
        ei
        ret


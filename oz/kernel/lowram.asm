; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1eab6
;
; $Id$
; -----------------------------------------------------------------------------

        Module LowRAM

        org $0000                               ; 351 bytes

        include "blink.def"
        include "error.def"
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
xdef    FPP_RET
xdef    INTReturn
xdef    JpAHL
xdef	JpDE
xdef    JpHL
xdef    OZ_RET1
xdef    OZ_RET0
xdef    OZ_BUF
xdef    OZ_DI
xdef    OZ_EI
xdef    OZ_INT
xdef    OZCallJump
xdef    OZCallReturn1
xdef    OZCallReturn2
xdef    OZCallReturn3

; this code is copied to 0000 - 01A4

.rst00
        di
        xor     a
        out     (BL_COM), a                     ; bind ROM into low 2KB
                                                ; code continues in ROM

        defb    $ff

;	0005
.JpDE
        push    de
        ret

;	0007
.JpHL
        jp      (hl)

;	0008, used by packages
.rst08
        scf
        ret

        defb    0,0,0,0,0,0

;	0010, used by packages
.rst10
        scf
        ret

        defb    0,0,0,0,0,0

;	0018, FPP call
.rst18
        jp      FPPmain
        defb    $ff,$ff
.FPP_RET
        jp      OZCallReturnFP


;	0020, OZ call
.rst20
        jp      CallOZMain

        defb    $ff,$ff

;	0025
        jp      CallOZret

;	0028, fast memory banking

.rst28
	ld	a, b
	ex	af, af'				; new bank into a'
        ld      b, BLSC_PAGE
        ld      a, (bc)                         ; old bank
	ex	af, af'				; new into A, old into a'
	jr	fmb_2

.rst30
	scf
	ret
.fmb_2
        ld      (bc), a                         ; update softcopy
        out     (c), a                          ; bind bank in
	ex	af, af'				; old bank into A
	ld	b, a				; ready for 'push BC'
	ret

;       0038, hardware INT entry point

.OZINT
        push    af
	push	bc
	ld	bc, BLSC_SR3
        ld      a, (bc)                   ; remember S3 and bind in OZBANK_HI
        push    af
	push	bc
        ld	a, OZBANK_HI
        ld      (bc), a
        out     (c), a
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
        ret     c                               ; ints were disabled? exit
        ei
        ret
.OZ_INT
	scf					; 0057
	ret
	nop

        defs    4*3 ($ff)

;       hardware NMI entry point

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

        ld      a, i                            ; store int status
        push    af

        di                                      ; nested NMIs won't enable interrupts
        ld      a, (BLSC_SR3)                   ; remember S3 and bind in OZBANK_HI
        push    af
        ld	a, OZBANK_HI
        ld      (BLSC_SR3), a
        out     (BL_SR3), a

        call    NMIEntry                        ; call NMI handler

        pop     af                              ; restore S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a

        pop     af                              ; !! can't use 'retn' because of 'di' above
        jp      po, noEI                        ; ints were disabled
        pop     af
        ei
        ret

.noEI
        pop     af                              ; !! can use any 'pop af; ret' below
        ret

; 0095
;
;       called from misc2.asm

.OZCallJump
        pop     af                              ; restore S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        pop     af                              ; restore AF
        ret

; 009d
;
;       called from int.asm

.INTReturn
	pop	bc
        pop     af                              ; restore S3
        ld      (bc), a
        out     (c), a
	pop	bc
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
;
;       called from buffer.asm, memory.asm, misc4.asm, ossi.asm

        exx

; 00ac          ret with AFbcdehl
;
;       called from buffer.asm, error.asm, esc.asm, memory.asm, misc2.asm, oscli0.asm

.OZCallReturn2
        ex      af, af'

; 00ad          ret with afbcdehl
;
;       called from buffer.asm

.OZCallReturn3
        exx

; 00ae          ret with afBCDEHL

.OZCallReturnFP
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
;
;       called from error.asm, process3.asm

.JpAHL
        call    MS3BankA
        ex      af, af'
        call    JpHL
        ex      af, af'
; 00dc

.MS3Bank00
        xor     a
        jr      MS3BankA

;       referenced from error.asm, process3.asm

.DefErrHandler
        ret     z
        cp      a
        ret

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

.CallOZMain
        ex      af, af'
        exx
        ld      hl, ubAppCallLevel              ; increment call level
        inc     (hl)
        pop     hl                              ; caller PC
        ld      e, (hl)                         ; get opByte
        inc     hl
        push    hl
	ld	l, (hl)				; get opByte2

        ld      bc, (BLSC_SR2)                  ; remember S2/S3
        push    bc
        ld      a, OZBANK_HI
        ld      (BLSC_SR3), a
        out     (BL_SR3), a

        ld      d, >OZCallTable                 ; function jumper in DE
        ex      de, hl
        jp      (hl)                            ; $FFnn, nn=opByte

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
        ld      bc, FPPCALLTBL                  ; FPP return $d800
        push    bc
        ld      c, a
        ld      b, >FPPCALLTBL                  ; !! unnecessary
        push    bc                              ; call function at $d8nn, nn=opByte

        ld      a, OZBANK_FPP                   ; bind b02 into S3
        ld      (BLSC_SR3), a
        out     (BL_SR3), a
        ex      af, af'
        exx
        ret


;       called thru $0025, maybe unused

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

.OZDImain
        xor     a                               ; A=0, Fc=0
        push    af                              ; store A to clear byte in stack
        pop     af                              ;
        ld      a, i                            ; A=snooze/coma flag, IFF2 -> Fp
        di
        ret     pe                              ; interrupts enabled? exit Fc=0

;       we have three possible cases here:
;
;       a)  we got interrupt during 'ld a, i' so interrupts were on
;       b1) interrupts were disabled all the time
;       b2) interrupts were disabled, but somewhere here NMI happens
;
;       in cases (a) and (b2) zero in stack was overwritten with PC high byte,
;       in case (b1) we read back zero.  !! (b2) isn't handled

        dec     sp                              ; read back A
        dec     sp
        pop     af

;       !! if we assert 'DI' above is at odd address, Fc is correct without compare

        cp      1                               ; Fc=0 if we were interrupted
        ld      a, i                            ; reload A for NMI routine
        ret


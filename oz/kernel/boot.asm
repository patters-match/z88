; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0000
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Boot

        include "blink.def"
        include "sysvar.def"

        org     $c000                           ; 104 bytes

xdef    Halt

xref    Delay300Kclocks
xref    nmi_5
xref    Reset1
xref    Bootstrap2
xref    HW_NMI2

; reset code at $0000

.Reset0
        ld      sp, ROMstack&$3fff              ; read return PC from ROM - Reset1
        di
        ld      sp, ROMstack&$3fff              ; read return PC from ROM - Reset1
        xor     a
        ld      i, a                            ; I=0, reset ID
        im      1
        in      a, (BL_STA)                     ; remember interrupt status
        ex      af, af'
        ld      hl, $0301                       ;(BM_INTTIME|BM_INTGINT)<<8|BM_TMKTICK

; snooze on coma and wait for interrupt
;
; IN : H = interrupt mask  L = RTC mask

.Halt
        di
	xor	a
        out     (BL_COM), a                     ; reset command register
	ld	a, OZBANK_HI
        out     (BL_SR0), a                     ; bind OZ_HI into all segments
        out     (BL_SR1), a
        out     (BL_SR2), a
        out     (BL_SR3), a
        ld      a, l                            ; enable and ack RTC interrupts
        out     (BL_TMK), a
        out     (BL_TACK), a
        ld      a, h                            ; enable and ack interrupts
        out     (BL_INT), a
        out     (BL_ACK), a

.halt_1
        ei                                      ; wait until interrupt
        halt
        jr      halt_1

.rint_0
        di
        ld      sp, ROMstack&$3fff              ; read return PC from ROM
        call    Delay300Kclocks                 ; ret to Reset1

	defb	$ff,$ff,$ff

;       0038

.HW_INT
	ld	a, OZBANK_HI
        out     (BL_SR3), a
        ld      a, i
        jp      z, rint_0                       ; I=0? from reset
        scf
        jp      nmi_5

        defw Reset1
.ROMstack
        defw Bootstrap2

	defs	13 ($ff)

.do_nmi
        xor     a                               ; reset command register
        out     (BL_COM), a
        ld      h, a                            ; if stack points to $00xx we go back to reset
        ld      l, a
        add     hl, sp
	or	h
        jr      z, Reset0                       ; SP=$00xx - reset

	ld	a, OZBANK_HI
        out     (BL_SR3), a
        jp      HW_NMI2                         ; into ROM code


;       0066

.HW_NMI
	jr	do_nmi

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0000
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Boot

        include "all.def"
        include "sysvar.def"

        org     $c000                           ; 123 bytes

xdef    Halt

defc    Delay2Mclocks           =$cdb8
defc    nmi_5                   =$cfa7
defc    Reset1                  =$c07b
defc    Bootstrap2              =$c082
defc    HW_NMI2                 =$d00e

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
        xor     a
        out     (BL_COM), a                     ; reset command register
        out     (BL_SR0), a                     ; bind b00 into all segments
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
        call    Delay2Mclocks                   ; ret to Reset1
        defb    $FF,$FF,$FF,$FF,$FF

;       0038

.HW_INT
        ld      hl, 0                           ; if stack points to $0100-$03ff we call HW_INT in b60
        add     hl, sp
        inc     h                               ; !! ld a,h; dec a; cp 3; jr c,INT_b60
        dec     h
        jr      z, rint_1
        ld      a, h
        cp      4
        jr      c, INT_b60                      ; stack on page 1-3

.rint_1
        xor     a
        out     (BL_SR3), a                     ; MS3b00
        ld      a, i
        jp      z, rint_0                       ; I=0? from reset
        scf
        jp      nmi_5

.INT_b60
        ld      a, $60
        out     (BL_SR3), a                     ; MS3b60
        jp      HW_INT                          ; into ROM code

.NMI_b60
        ld      a, $60
        out     (BL_SR3), a                     ; MS3b60
        jp      HW_NMI                          ; into ROM code

        defw Reset1
.ROMstack
        defw Bootstrap2
        defb $FF,$FF,$FF
;       0066

.HW_NMI
        xor     a                               ; reset command register
        out     (BL_COM), a
        ld      h, a                            ; if stack points to $00xx 100-$03ff we go back to reset
        ld      l, a                            ; if stack points to $0100-$03ff we call HW_NMI in b60
        add     hl, sp
        inc     h
        dec     h
        jr      z, Reset0                       ; SP=$00xx - reset
        ld      a, h
        cp      4
        jr      c, NMI_b60                      ; SP=$01xx-$03xx - b60
        xor     a
        out     (BL_SR3), a                     ; MS3b00
        jp      HW_NMI2                         ; into ROM code

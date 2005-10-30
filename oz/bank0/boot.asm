; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0000
; -----------------------------------------------------------------------------

        Module  Boot

        include "blink.def"
        include "sysvar.def"

xdef    Halt

xref    Delay300Kclocks
xref    nmi_5
xref    Reset1
xref    Bootstrap2
xref    HW_NMI2


; reset code at $0000
; fixed ORG

.Reset0
        org     $c000                           ;
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
        call    Delay300Kclocks                 ; ret to Reset1
        defs    $05


; hardware IM1 INT at $0038
; fixed ORG

.HW_INT
        org     $C038
;        ld      hl, 0                          ; if stack points to $0100-$03ff we call HW_INT in b60
;        add     hl, sp                         ; !! remove this test
        xor     a
        out     (BL_SR3), a                     ; MS3b00
        ld      a, i
        jp      z, rint_0                       ; I=0? from reset
        scf
        jp      nmi_5

; for the ret in ROM
        defw Reset1
.ROMstack
        defw Bootstrap2
        defb $FF,$FF,$FF
        defs $17                                 ; bytes saved!
        defs 4

; hardware non maskable interrupt at $0066
; fixed ORG

.HW_NMI
        org     $C066
        xor     a                               ; reset command register
        out     (BL_COM), a
        ld      h, a                            ; if stack points to $00xx we go back to reset
        ld      l, a                            ;
        add     hl, sp
        inc     h
        dec     h
        jr      z, Reset0                       ; reset if SP=$00xx
        xor     a
        out     (BL_SR3), a                     ; MS3b00
        jp      HW_NMI2                         ; into ROM code

        defs $5                                 ; bytes saved!


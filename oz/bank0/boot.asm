; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0000
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Boot

        include "blink.def"
        include "sysvar.def"

        org     $c000

xdef    Halt

xref    Delay300Kclocks
xref    nmi_5
xref    HW_NMI2
xref    VerifySlotType
xref    Reset2

; reset code at $0000

.Reset0
        ld      sp, ROMstack & $3fff            ; read return PC from ROM - Reset1
        di
        ld      sp, ROMstack & $3fff            ; read return PC from ROM - Reset1
        xor     a
        ld      i, a                            ; I=0, reset ID
        im      1
        in      a, (BL_STA)                     ; remember interrupt status
        ex      af, af'
        ld      hl, [BM_INTTIME|BM_INTGINT]<<8 | BM_TMKTICK

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
        ld      sp, ROMstack & $3fff            ; read return PC from ROM
        call    Delay300Kclocks                 ; ret to Reset1

; for the ret in ROM
        defw    Reset1
.ROMstack
        defw     Bootstrap2
        defb    $ff


; hardware IM1 INT at $0038

.HW_INT
        xor     a
        out     (BL_SR3), a                     ; MS3b00
        ld      a, i
        jr      z, rint_0                       ; I=0? from reset (save 1 byte with jr)
        scf
        jp      nmi_5
.Reset1
        ld      de, 1<<8 | $3f                  ; check slot 1, max size 63 banks
        jp      VerifySlotType                  ; ret to Bootstrap2

.Bootstrap2
        bit     1, d                            ; check for bootable ROM in slot 1
        jr      z, rst1_2                       ; not application ROM? skip
        ld      a, ($bffd)                      ; subtype
        cp      'Z'
        jp      z, $bff8                        ; enter ROM

.rst1_2
        ld      a, OZBANK_7
        out     (BL_SR2), a                     ; MS2b07
        jp      Reset2                          ; init internal RAM, blink and low-ram code and set SP

        defs    ($0066-$PC) ($ff)               ; pad FFh's until 0066H (Z80 NMI vector)

; hardware non maskable interrupt at $0066

.HW_NMI
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

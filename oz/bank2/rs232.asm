; -----------------------------------------------------------------------------
; Bank 2 @ S2           ROM offset $A500-$A7EF
;
; $Id$
; -----------------------------------------------------------------------------

; Low level serial port interface:
;
;       DEFC    Os_Si   =       $8D                     ; serial interface (low level)
;
;               DEFC    SI_HRD  =       $00             ; Hard reset the serial port
;               DEFC    SI_SFT  =       $03             ; Soft reset the serial port
;               DEFC    SI_INT  =       $06             ; Interrupt entry point
;               DEFC    SI_GBT  =       $09             ; Get byte from serial port
;               DEFC    SI_PBT  =       $0C             ; Put byte to serial port
;               DEFC    SI_ENQ  =       $0F             ; Status enquiry
;               DEFC    SI_FTX  =       $12             ; Flush Tx (transmit) buffer
;               DEFC    SI_FRX  =       $15             ; Flush Rx (receive) buffer
;               DEFC    SI_TMO  =       $18             ; Set timeout


                Module RS232

        include "blink.def"
        include "misc.def"
        include "syspar.def"

        org     $a500                           ; $a500-$a7ef

        jp      HardReset
        jp      SoftReset
        jp      IntEntry
        jp      GetByte
        jp      PutByte
        jp      EnqStatus
        jp      FlushTx
        jp      FlushRx
        jp      SetTimeout

.HardReset
        push    bc
        push    de
        ld      a,1
        ld      b,$FB
        OZ      OS_Fn                           ; Miscellaneous OS functions
        pop     de
        pop     bc
        jr      c, hrst_1

        ld      (ix+8), c
        ld      (ix+9), b
        ld      (ix+$0A), e
        ld      (ix+$0B), d

        xor     a
        dec     a
        out     (BL_TXD), a                     ; (w) transmit data
        ld      a, $AD
        call    sub_0_A7DE
        ld      a, $15
        ld      ($4E4), a
        out     (BL_TXC), a                     ; transmit control
        xor     a
        ld      ($0FFE), a
        dec     a
        out     (BL_UAK), a                     ; (w) UART int. mask
        in      a, (BL_RXD)                     ; (r) UART receive data register
        ld      a, $40
        ld      ($4E5), a
        out     (BL_UIT), a
        ld      a, $8D
        call    sub_0_A7DE
        ld      a, 0
        ld      ($0FFC), a
        ld      a, ($4B1)
        or      $10
        ld      ($4B1), a
        out     (BL_STA), a
        or      a

.hrst_1
        ret

;--------------------------------------------------------------

.SoftReset
        ld      (ix+$0C), $60
        ld      (ix+$0D), $0EA
        call    FlushTx
        call    FlushRx
        ld      bc, PA_Rxb
        call    EnquireParam
        call    sub_0_A5E8
        ld      b, a
        ld      a, $88
        or      b
        call    sub_0_A7DE
        ld      bc, PA_Txb
        call    EnquireParam
        call    sub_0_A5E8
        ld      b, a
        ld      a, ($4E4)
        and     $0F8
        or      b
        ld      ($4E4), a
        out     (BL_TXC), a                     ; transmit control
        ld      bc, PA_Par
        call    EnquireParam
        ld      c, 3
        ld      a, e
        cp      'N'                             ; none
        jr      z, srst_1
        set     7, c
        cp      'E'                             ; even
        jr      z, srst_1
        set     5, c
        cp      'O'                             ; odd
        jr      z, srst_1
        set     6, c
        cp      'S'                             ; space
        jr      z, srst_1
        set     4, c

.srst_1
        ld      a, c
        ld      ($0FFC), a
        ld      bc, PA_Xon
        call    EnquireParam
        ld      a, ($0FFD)
        and     $0FC
        ld      c, a
        ld      a, e
        cp      $59
        jr      nz, srst_2
        set     0, c
        ld      a, $11
        ld      ($0FFE), a
        call    sub_0_A7B4

.srst_2
        ld      a, c
        ld      ($0FFD), a
        or      a
        ret

;--------------------------------------------------------------

.EnquireParam
                                                ; CODE XREF- ROM-A57Ap ROM-A58Ap ...
        ld      de, 2
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ret

;--------------------------------------------------------------


.sub_0_A5E8
                                                ; CODE XREF- ROM-A57Dp ROM-A58Dp
        ex      af, af'
        xor     a
        ex      af, af'
        ld      b, d
        ld      c, e
        ld      hl, BaudRates

.loc_0_A5F0
                                                ; CODE XREF- sub_0_A5E8+1Bj
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      a, d
        or      e
        ld      a, 5
        jr      z, loc_0_A606
        ex      de, hl
        sbc     hl, bc
        ex      de, hl
        jr      z, loc_0_A605
        ex      af, af'
        inc     a
        ex      af, af'
        jr      loc_0_A5F0
;--------

.loc_0_A605
                                                ; CODE XREF- sub_0_A5E8+16j
        ex      af, af'

.loc_0_A606
                                                ; CODE XREF- sub_0_A5E8+10j
        or      a
        ret
; End of function sub_0_A5E8

;--------
.BaudRates
        defw    75                              ; DATA XREF- sub_0_A5E8+5o
        defw    300
        defw    600
        defw    1200
        defw    2400
        defw    9600
        defw    19200
        defw    38400
        defw    0
;--------

;--------------------------------------------------------------

.IntEntry
                                                ; CODE XREF- ROM-A506j
        ld      c, BL_UMK                       ; (r) UART int. status
        in      a, (c)
        ld      c, a
        ld      a, ($4E5)
        and     c
        bit     4, a
        call    nz, sub_0_A69F
        bit     2, a
        call    nz, sub_0_A634
        bit     6, a
        call    nz, sub_0_A709
        or      a
        ret

;----   SUBROUTINE


.sub_0_A634
                                                ; CODE XREF- ROM-A62Ap
        push    af
        ld      hl, ($0FFC)
        in      a, (BL_RXE)                     ; (r) extended receiver data
        in      a, (BL_RXD)                     ; (r) UART receive data register
        bit     7, l                            ; !! originally bugged - bit 6,l
        jr      z, loc_0_A642
        and     $7F

.loc_0_A642
                                                ; CODE XREF- sub_0_A634+Aj
        bit     0, h
        jr      z, loc_0_A665
        cp      $11
        jr      nz, loc_0_A657
        ld      a, ($0FFD)
        res     1, a
        ld      ($0FFD), a
        call    sub_0_A7B4
        jr      loc_0_A69D
;--------

.loc_0_A657
                                                ; CODE XREF- sub_0_A634+14j
        cp      $13
        jr      nz, loc_0_A665
        ld      a, ($0FFD)
        set     1, a
        ld      ($0FFD), a
        jr      loc_0_A69D
;--------

.loc_0_A665
                                                ; CODE XREF- sub_0_A634+10j
                                                ; sub_0_A634+25j
        push    ix
        call    sub_0_A7D4
        ld      l, 0
        call    $4E
        pop     ix
        ld      a, h
        add     a, l
        srl     a
        srl     a
        cp      l
        jr      c, loc_0_A69D
        ld      a, ($4E2)
        bit     3, a
        jr      nz, loc_0_A689
        ld      a, $0F
        cp      l
        jr      c, loc_0_A69D
        ld      a, ($4E2)

.loc_0_A689
                                                ; CODE XREF- sub_0_A634+4Bj
        and     $0E7
        call    sub_0_A7DE
        ld      a, ($0FFD)
        bit     0, a
        jr      z, loc_0_A69D
        ld      a, $13
        ld      ($0FFE), a
        call    sub_0_A7B4

.loc_0_A69D
                                                ; CODE XREF- sub_0_A634+21j
                                                ; sub_0_A634+2Fj ...
        pop     af
        ret
; End of function sub_0_A634


;----   SUBROUTINE


.sub_0_A69F
                                                ; CODE XREF- ROM-A625p
        push    af
        ld      a, ($0FFE)
        push    af
        xor     a
        ld      ($0FFE), a
        pop     af
        or      a
        jr      nz, loc_0_A6CD
        ld      a, ($0FFD)
        bit     1, a
        jr      nz, loc_0_A6C1
        push    ix
        call    sub_0_A7CC
        ld      l, 3
        call    $4E
        pop     ix
        jr      nc, loc_0_A6CD

.loc_0_A6C1
                                                ; CODE XREF- sub_0_A69F+12j
        ld      a, ($4E5)
        and     $0EF
        ld      ($4E5), a
        out     (BL_UIT), a
        jr      loc_0_A707
;--------

.loc_0_A6CD
                                                ; CODE XREF- sub_0_A69F+Bj
                                                ; sub_0_A69F+20j
        push    af
        ld      a, ($0FFC)
        ld      c, a
        pop     af
        ld      b, $0FE
        bit     2, c
        jr      z, loc_0_A6DB
        res     1, b

.loc_0_A6DB
                                                ; CODE XREF- sub_0_A69F+38j
        bit     7, c
        jr      z, loc_0_A703
        and     $7F
        bit     6, c
        jr      z, loc_0_A6ED
        bit     4, c
        jr      z, loc_0_A703
        set     7, a
        jr      loc_0_A703
;--------

.loc_0_A6ED
                                                ; CODE XREF- sub_0_A69F+44j
        ex      af, af'
        bit     5, c
        ex      af, af'
        and     a
        jp      pe, loc_0_A6FA
        ex      af, af'
        jr      z, loc_0_A700
        jr      loc_0_A6FD
;--------

.loc_0_A6FA
                                                ; CODE XREF- sub_0_A69F+53j
        ex      af, af'
        jr      nz, loc_0_A700

.loc_0_A6FD
                                                ; CODE XREF- sub_0_A69F+59j
        ex      af, af'
        jr      loc_0_A703
;--------

.loc_0_A700
                                                ; CODE XREF- sub_0_A69F+57j
                                                ; sub_0_A69F+5Cj
        ex      af, af'
        xor     $80

.loc_0_A703
                                                ; CODE XREF- sub_0_A69F+3Ej
                                                ; sub_0_A69F+48j ...
        ld      c, BL_TXD                       ; (w) transmit data
        out     (c), a

.loc_0_A707
                                                ; CODE XREF- sub_0_A69F+2Cj
        pop     af
        ret
; End of function sub_0_A69F


;----   SUBROUTINE


.sub_0_A709
                                                ; CODE XREF- ROM-A62Fp
        push    af
        ld      a, ($4E5)
        xor     4
        ld      ($4E5), a
        out     (BL_UIT), a
        ld      a, ($4E4)
        xor     $40
        ld      ($4E4), a
        out     (BL_TXC), a                     ; transmit control
        ld      a, $40
        out     (BL_UAK), a                     ; (w) UART int. mask
        pop     af
        ret
; End of function sub_0_A709

;--------

;--------------------------------------------------------------

.PutByte
                                                ; CODE XREF- ROM-A50Cj
        push    af
        call    sub_0_A7E4
        call    sub_0_A7CC
        pop     af
        ld      l, 6
        call    $4E
        call    nc, sub_0_A7B4
        ret

;--------------------------------------------------------------

.GetByte
                                                ; CODE XREF- ROM-A509j
        call    $51
        push    af
        call    sub_0_A7D4
        ld      l, 9
        call    $4E
        jr      c, loc_0_A767
        ld      e, a
        ld      a, h
        add     a, l
        srl     a
        cp      l
        jr      nc, loc_0_A766
        ld      a, ($4E2)
        bit     3, a
        jr      nz, loc_0_A766
        or      8
        call    sub_0_A7DE
        ld      a, ($0FFD)
        bit     0, a
        jr      z, loc_0_A766
        ld      a, $11
        ld      ($0FFE), a
        call    sub_0_A7B4

.loc_0_A766
                                                ; CODE XREF- ROM-A749j ROM-A750j ...
        or      a

.loc_0_A767
                                                ; CODE XREF- ROM-A741j
        pop     hl
        push    af
        push    hl
        pop     af
        call    $54
        pop     af
        ret     c
        ld      a, e
        ret

;--------------------------------------------------------------

.EnqStatus
                                                ; CODE XREF- ROM-A50Fj
        call    $51
        push    af
        push    ix
        call    sub_0_A7CC
        ld      l, $0C
        call    $4E
        pop     ix
        push    hl
        push    ix
        call    sub_0_A7D4
        ld      l, $0C
        call    $4E
        pop     ix
        ex      de, hl
        pop     bc
        pop     af
        call    $54
        in      a, (BL_UMK)                     ; (r) UART int. status
        or      a
        ret

;--------------------------------------------------------------

.SetTimeout
                                                ; CODE XREF- ROM-A518j
        ld      (ix+$0C), c
        ld      (ix+$0D), b
        ret

;--------------------------------------------------------------

.FlushTx
                                                ; CODE XREF- ROM-A512j ROM-A571p
        push    ix
        call    sub_0_A7CC
        jr      loc_0_A7AC

;--------------------------------------------------------------

.FlushRx
                                                ; CODE XREF- ROM-A515j ROM-A574p
        push    ix
        call    sub_0_A7D4

.loc_0_A7AC
                                                ; CODE XREF- FlushTx+5j
        ld      l, $0F
        call    $4E
        pop     ix
        ret
; End of function FlushRx

;--------------------------------------------------------------

.sub_0_A7B4
                                                ; CODE XREF- ROM-A5D9p sub_0_A634+1Ep ...
        call    $51
        push    af
        ld      a, ($4E5)
        bit     4, a
        jr      nz, loc_0_A7C6
        or      $10
        ld      ($4E5), a
        out     (BL_UIT), a

.loc_0_A7C6
                                                ; CODE XREF- sub_0_A7B4+9j
        pop     af
        call    $54
        xor     a
        ret
; End of function sub_0_A7B4


;----   SUBROUTINE


.sub_0_A7CC
                                                ; CODE XREF- sub_0_A69F+16p ROM-A728p ...
        ld      l, (ix+$0A)
        ld      h, (ix+$0B)
        jr      loc_0_A7DA
; End of function sub_0_A7CC


;----   SUBROUTINE


.sub_0_A7D4
                                                ; CODE XREF- sub_0_A634+33p ROM-A739p ...
        ld      l, (ix+8)
        ld      h, (ix+9)

.loc_0_A7DA
        push    hl
        pop     ix
        ret
; End of function sub_0_A7D4


;----   SUBROUTINE


.sub_0_A7DE
        ld      ($4E2), a
        out     (BL_RXC), a                     ; (w) receiver control
        ret
; End of function sub_0_A7DE


;----   SUBROUTINE


.sub_0_A7E4
        inc     bc
        ld      a, b
        or      c
        dec     bc
        ret     nz
        ld      b, (ix+$0D)
        ld      c, (ix+$0C)
        ret
; End of function sub_0_A7E4

;--------

; **************************************************************************************************
; Lowram routines for low lever serial port interface.
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
; $Id$
;***************************************************************************************************



; -----------------------------------------------------------------------------------------
; Main Serial Interface Interrupt handler that manages bytes received and sent through
; the serial port hardware and updating of the serial receive and transmit buffers.
;
; This routine is executed from the IM 1 interrupt handler (INTEntry, int.asm), when an
; UART interrupt was recognized from the BLINK.
;
.IntUART
        ld      c, BL_UIT                       ; interrupt status
        in      a, (c)
        ld      c, a
        ld      a, (BLSC_UMK)                   ; interrupt mask
        and     c
        bit     BB_UITTDRE, a
        call    nz, TxInt
        bit     BB_UITRDRF, a
        call    nz, RxInt
        bit     BB_UITDCDI, a
        call    nz, DcdInt
        or      a
        ret

; ----------------------------------------------------------------------------------
; BLINK has received a byte from the serial port hardware; grab it and put
; it in the serial port receive buffer.
.RxInt
        push    af

;       get char from serial port

        ld      hl, (ubSerParity)               ; L=parity, H=flow control
        in      a, (BL_RXE)                     ; !! probably need to read this too
        in      a, (BL_RXD)                     ; read serial data

;       clear parity bit, check for XON/XOFF if needed

        bit     PAR_B_PARITY, l
        jr      nz, rx_parity
        bit     FLOW_B_XONXOFF, h
        jr      z, rx_BfPb                      ; no flow control? write char

        cp      XON                             ; !! 'jr z' both XON/XOFF to
        jr      z, rx_xon                       ; !! speed up normal chars
        cp      XOFF
        jr      z, rx_xoff

;       save char, block sender if buffer 75% full

.rx_BfPb
        push    ix                              ; write byte to buffer
        ld      ix, SerRXHandle
        call    BfPb2
        call    BfSta2                          ; get used/free slots in buffers
        pop     ix

        ld      a, h                            ; #chars in buffer
        add     a, l                            ; +free space = bufsize
        srl     a
        srl     a                               ; bufsize/4
        cp      l
        jr      c, rx_x                         ; more than 25% free? exit

        ld      a, (BLSC_RXC)                   ; IRTS? hold sender
        bit     BB_RXCIRTS, a
        jr      nz, rx_4

        ld      a, 15
        cp      l
        jr      c, rx_x                         ; more than 15 byte free? exit

        ld      a, (BLSC_RXC)                   ; !! use a' above
.rx_4
        and     ~(BM_RXCARTS|BM_RXCIRTS)        ; disable ARTS/IRTS
        ld      (BLSC_RXC), a
        out     (BL_RXC), a

        ld      a, (ubSerFlowControl)           ; no flow control? exit
        bit     FLOW_B_XONXOFF, a
        jr      z, rx_x

        ld      a, XOFF                         ; send XOFF
        ld      (cSerXonXoffChar), a
.rx_ei_tdre
        ld      a, (BLSC_UMK)                   ; enable TDRE int
        bit     BB_UMKTDRE, a
        jr      nz, rx_x                        ; TDRE int already enabled
        or      BM_UMKTDRE                      ; enable TDRE int
        ld      (BLSC_UMK), a
        out     (BL_UMK), a
.rx_x
        pop     af
        ret

.rx_parity                                      ; could be more serious
        and     $7f                             ; clear parity bit
        jr      rx_BfPb                         ; continue

.rx_xon
        ld      hl, ubSerFlowControl            ; allow sending
        res     FLOW_B_TXSTOP, (hl)
        jr      rx_ei_tdre

.rx_xoff
        ld      hl, ubSerFlowControl            ; disable sending
        set     FLOW_B_TXSTOP, (hl)
        pop     af
        ret

;       ----

.TxInt
        push    af

;       check if we need to send XON/XOFF

        ld      hl, cSerXonXoffChar
        ld      a, (hl)                         ; if zero, nothing to send
        ld      (hl), 0
        or      a
        jr      nz, tx_2                        ; need to send XON/XOFF

;       receiver sent XOFF?

        ld      a, (ubSerFlowControl)           ; need to stop transmitting?
        bit     FLOW_B_TXSTOP, a
        jr      nz, tx_1

;       get data from buffer, send if buffer not empty

        push    ix                              ; read byte from TxBuf
        ld      ix, SerTXHandle
        call    BfGb2
        pop     ix
        jr      nc, tx_2                        ; buffer not empty? send byte

.tx_1
        ld      a, (BLSC_UMK)                   ; disable TDRE
        and     ~BM_UMKTDRE
        ld      (BLSC_UMK), a
        out     (BL_UMK), a
        jr      tx_x                            ; and exit

;       send char in A !! rearrange parity bits and use af' for speed

.tx_2
        ld      bc, (ubSerParity)               ; parity inC
        ld      b, ~TDRH_START

        bit     PAR_B_9BIT, c                   ; nine bit data? clear 1st stop bit (bit8)
        jr      z, tx_3
        res     TDRH_B_STOP, b

.tx_3
        bit     PAR_B_PARITY, c                 ; no parity? we're done
        jr      z, tx_send

        and     $7F                             ; clear parity bit
        bit     PAR_B_STICKY, c
        jr      z, tx_4                         ; even/odd

        bit     PAR_B_MARK, c
        jr      z, tx_send                      ; space - cleared parity already

        set     7, a                            ; mark - set high bit
        jr      tx_send

;       calculate parity bit

.tx_4
        ex      af, af'                         ; !! test this bit separately
        bit     PAR_B_ODD, c                    ; !! saves several 'ex af's
        ex      af, af'
        and     a                               ; test parity
        jp      pe, tx_even

;       A has odd parity

        ex      af, af'
        jr      z, tx_7                         ; want even parity? set bit
        jr      tx_6                            ; else done

;       A has even parity

.tx_even
        ex      af, af'
        jr      nz, tx_7                        ; want odd parity? set bit
.tx_6
        ex      af, af'
        jr      tx_send

.tx_7
        ex      af, af'
        xor     $80

.tx_send
        ld      c, BL_TXD
        out     (c), a                          ; puts B into A8-A15

.tx_x
        pop     af
        ret

;       ----

.DcdInt
        ld      a, (BLSC_UMK)                   ; invert RDRF int
        xor     BM_UMKRDRF
        ld      (BLSC_UMK), a
        out     (BL_UMK), a
        ld      a, (BLSC_TXC)                   ; invert DCDI int
        xor     BM_TXCDCDI
        ld      (BLSC_TXC), a
        out     (BL_TXC), a
        ld      a, BM_UAKDCD                    ; ack DCD
        out     (BL_UAK), a
        ret


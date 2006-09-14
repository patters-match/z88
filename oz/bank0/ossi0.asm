; **************************************************************************************************
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
; $Id: ossi0.asm 2005 2005-11-23 21:31:34Z gbs $
;***************************************************************************************************

        Module OSSi0

        include "blink.def"
        include "buffer.def"
        include "ctrlchar.def"
        include "handle.def"
        include "misc.def"
        include "syspar.def"
        include "sysvar.def"
        include "serintfc.def"
        include "../bank7/lowram.def"

xdef    OSSi
xdef    OSSiInt                                 ; called by int.asm (replace IntUART)
xdef    Ld_IX_TxBuf
xdef    Ld_IX_RxBuf
xdef    WrRxC
xdef    EI_TDRE
xdef    OSSiGbt, OSSiPbt

xref    BufWrite                                ; bank0/buffer.asm
xref    BufRead                                 ; bank0/buffer.asm
xref    BfPbt                                   ; bank0/buffer.asm
xref    BfGbt                                   ; bank0/buffer.asm

xref    OSSiHrd1                                ; bank7/ossi1.asm
xref    OSSiSft1                                ; bank7/ossi1.asm
xref    OSSiEnq1                                ; bank7/ossi1.asm
xref    OSSiFtx1                                ; bank7/ossi1.asm
xref    OSSiFrx1                                ; bank7/ossi1.asm
xref    OSSiTmo1                                ; bank7/ossi1.asm

; -----------------------------------------------------------------------------
;
;       OS_SI   low level serial interface
;
;       IN :    L=reason code and A, BC, DE, IX according the reason
;       OUT:    depends on the reason called
;
;       NB : with 1 byte OS calls, all registers are exx on entry
; -----------------------------------------------------------------------------
.OSSi
        push    ix
        ld      ix, (SerRXHandle)
        ld      hl, OSSiRet
        push    hl                              ; stack the ret
        exx                                     ; restore main registers
        ld      a, l                            ; reason
        ld      hl, OSSITBL                     ; h is unused and always destroyed by OSSi
        add     a, l                            ; shouldnt cross a page
        ld      l, a
        ex      af, af'                         ; restore af (used in OSSiPbt)
        jp      (hl)                            ; jump to routine

.OSSiRet
        pop     ix
        jp      OZCallReturn1

.OSSITBL
        jp      OSSiHrd
        jp      OSSiSft
        jp      OSSiInt                         ; in K0 for speed
        jp      OSSiGbt                         ; in K0 for speed
        jp      OSSiPbt                         ; in K0 for speed
        jp      OSSiEnq
        jp      OSSiFtx
        jp      OSSiFrx
        jp      OSSiTmo

.OSSiHrd
        extcall OSSiHrd1, OZBANK_KNL1
        ret

.OSSiSft
        extcall OSSiSft1, OZBANK_KNL1
        ret

.OSSiEnq
        extcall OSSiEnq1, OZBANK_KNL1
        ret

.OSSiFtx
        extcall OSSiFtx1, OZBANK_KNL1
        ret

.OSSiFrx
        extcall OSSiFrx1, OZBANK_KNL1
        ret

.OSSiTmo
        extcall OSSiTmo1, OZBANK_KNL1
        ret

;       ----

.OSSiInt
        push    ix                              ; allows to be call directly from int
        ld      ix, (SerRXHandle)
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
        pop     ix
        ret

.RxInt
        push    af

;       get char from serial port

        ld      hl, (ubSerParity)               ; L=parity, H=flow control
        in      a, (BL_RXE)                     ; !! probably need to read this too
        in      a, (BL_RXD)                     ; read serial data

;       clear parity bit, check for XON/XOFF if needed

        bit     PAR_B_PARITY, l
        jr      z, rx_1                         ; no parity? 8-bit data
        and     $7f                             ; else clear parity bit
.rx_1
        bit     FLOW_B_XONXOFF, h
        jr      z, rx_3                         ; no flow control? write char

        cp      XON                             ; !! 'jr z' both XON/XOFF to
        jr      nz, rx_2                        ; !! speed up normal chars

        ld      a, (ubSerFlowControl)           ; allow sending
        res     FLOW_B_TXSTOP, a                ; !! 'ld a, FLOW_XONXOFF'
        ld      (ubSerFlowControl), a
        call    EI_TDRE                         ; enable TDRE int
        jr      rx_x                            ; and exit

.rx_2
        cp      XOFF
        jr      nz, rx_3

        ld      a, (ubSerFlowControl)           ; disable sending
        set     FLOW_B_TXSTOP, a                ; !! 'ld a, FLOW_XONXOFF|FLOW_TXSTOP'
        ld      (ubSerFlowControl), a
        jr      rx_x                            ; and exit

;       save char, block sender if buffer 75% full

.rx_3
        push    ix                              ; write byte to buffer
        call    Ld_IX_RxBuf
        call    BufWrite
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
        call    WrRxC
        ld      a, (ubSerFlowControl)           ; no flow control? exit
        bit     FLOW_B_XONXOFF, a
        jr      z, rx_x

        ld      a, XOFF                         ; send XOFF
        ld      (cSerXonXoffChar), a
        call    EI_TDRE                         ; enable TDRE int

.rx_x
        pop     af
        ret

;       ----

.TxInt
        push    af

;       check if we need to send XON/XOFF

;       !! 'ld hl, cSerXonXoffChar; ld a, (hl); ld (hl), 0; or a' 31 cycles

        ld      a, (cSerXonXoffChar)            ; save, clear and check Xon/Xoff
        push    af
        xor     a
        ld      (cSerXonXoffChar), a
        pop     af
        or      a
        jr      nz, tx_2                        ; need to send XON/XOFF

;       receiver sent XOFF?

        ld      a, (ubSerFlowControl)           ; need to stop transmitting?
        bit     FLOW_B_TXSTOP, a
        jr      nz, tx_1

;       get data from buffer, send if buffer not empty

        push    ix                              ; read byte from TxBuf
        call    Ld_IX_TxBuf
        call    BufRead
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
        ex      af, af'

        ld      a, (BLSC_UMK)                   ; toggle TDRE
        xor     BB_UMKTDRE
        ld      (BLSC_UMK), a
        out     (BL_UMK), a

        ld      a, (BLSC_TXC)                   ; toggle DCDI
        xor     BM_TXCDCDI
        ld      (BLSC_TXC), a
        out     (BL_TXC), a

        ld      a, BM_UAKDCD                    ; ack DCD
        out     (BL_UAK), a

        ex      af, af'
        ret

;       ----

.OSSiPbt
        push    af
        call    MayGetTimeout                   ; get default timeout if BC = -1
        call    Ld_IX_TxBuf
        pop     af
        call    BfPbt                           ; put byte with timeout
        call    nc, EI_TDRE                     ; enable TDRE if succesful
        ret

;       ----

.OSSiGbt
        call    OZ_DI
        push    af                              ; get byte with timeout
        call    Ld_IX_RxBuf
        call    BfGbt
        jr      c, gb_2                         ; error? exit
        ld      e, a

;       unblock sender if buffer less than half full

        ld      a, h                            ; #bytes in buffer
        add     a, l                            ; + free space = buf size
        srl     a                               ; /2
        cp      l
        jr      nc, gb_1                        ; less than 50% free? skip

        ld      a, (BLSC_RXC)
        bit     BB_RXCIRTS, a                   ; IRTS? skip
        jr      nz, gb_1

        or      BM_RXCIRTS                      ; set IRTS
        call    WrRxC

        ld      a, (ubSerFlowControl)           ; if Xon/Xoff send XON
        bit     FLOW_B_XONXOFF, a
        jr      z, gb_1
        ld      a, XON
        ld      (cSerXonXoffChar), a
        call    EI_TDRE

.gb_1
        or      a                               ; Fc=0

.gb_2
        pop     hl                              ; !! use separate error exit
        push    af                              ; !! for speed
        push    hl
        pop     af
        call    OZ_EI
        pop     af
        ret     c
        ld      a, e
        ret

;       ----

.EI_TDRE
        call    OZ_DI
        ex      af, af'
        ld      a, (BLSC_UMK)
        bit     BB_UMKTDRE, a
        jr      nz, eitdre_x                    ; TDRE enabled already

        or      BM_UMKTDRE
        ld      (BLSC_UMK), a
        out     (BL_UMK), a

.eitdre_x
        ex      af, af'
        call    OZ_EI
        xor     a
        ret

;       ----

.Ld_IX_TxBuf
        ld      l, (ix+shnd_TxBuf)
        ld      h, (ix+shnd_TxBuf+1)
        jr      Ld_IX_HL

.Ld_IX_RxBuf
        ld      l, (ix+shnd_RxBuf)
        ld      h, (ix+shnd_RxBuf+1)

.Ld_IX_HL
        push    hl
        pop     ix
        ret

;       ----

.WrRxC
        ld      (BLSC_RXC), a
        out     (BL_RXC), a
        ret

;       ----

;       get timeout from handle if it's -1

.MayGetTimeout
        ld      a, b
        and     c
        inc     a
        ret     nz
        ld      b, (ix+shnd_Timeout+1)          ; use this if BC(in) = -1
        ld      c, (ix+shnd_Timeout)
        ret

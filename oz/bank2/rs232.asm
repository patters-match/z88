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

        org     $a500                           ; $a500-$a7ef

        include "blink.def"
        include "buffer.def"
        include "ctrlchar.def"
        include "handle.def"
        include "misc.def"
        include "syspar.def"
        include "sysvar.def"
        include "..\bank7\lowram.def"

defc    PARITYBUG = 1

;       ubSerParity             =$0ffc

defc    PAR_B_PARITY    = 7                     ; has parity
defc    PAR_B_STICKY    = 6                     ; space or mark
defc    PAR_B_ODD       = 5                     ; odd parity
defc    PAR_B_MARK      = 4                     ; mark parity
defc    PAR_B_3         = 3                     ; not used
defc    PAR_B_9BIT      = 2                     ; never set, checked during send
defc    PAR_B_1         = 1                     ; set but not used
defc    PAR_B_0         = 0                     ; set but not used

;       !! rearrange parity bits so that we can 'add a' to check next bit
;       !! to speedup TxInt (need to combine EVEN/SPACE vs ODD/MARK)

;       PAR7    9BIT            0 - 8 bit data, 1 - 9 bit data
;       PAR6    PARITY          0 - no parity , 1 - parity
;       PAR5    STICKY          0 - EVEN/ODD,   1 - SPACE/MARK
;       PAR4    ODD_MARK        0 - EVEN/SPACE, 1 - ODD/MARK

 IF 0

        ex      af,af'                          ; save char
        ld      a, (ubSerParity)

        add     a, a                            ; take care of 9bit mode !! kludge
        jr      nc, no9bit
        res     0, b

.no9bit add     a, a                            ; skip if no parity
        jr      nc, senda

        add     a, a
        jr      nc, .cpar                       ; even/odd

        and     $80                             ; space/mark bit
        ld      c, a
        ex      af, af'                         ; merge with 7bit char
        and     $7f
        or      c
        jr      senda

.cpar   add     a,a                             ; skip if odd parity
        jr      c, odd

        ex      af, af'
        and     a
        jp      pe, senda                       ; even already
        jr      xor80

.odd    ex      af, af'
        and     a
        jp      po, senda

.xor80  xor     $80
        ex      af, af'                         ; faster than 'jp/jr'
.altaf  ex      af, af'

.senda  

 ENDIF

;       note that 9-bit mode isn't correctly implemented


;       ubSerFlowControl        =$0ffd

defc    FLOW_B_XONXOFF          =0
defc    FLOW_B_TXSTOP           =1

defc    FLOW_XONXOFF            =1
defc    FLOW_TXSTOP             =2


;       cSerXonXoffChar         =$0ffe

;       NUL, XON or XOFF

defc    TDRH_B_START            =0
defc    TDRH_B_STOP             =1
defc    TDRH_B_STOP2            =2

defc    TDRH_START              =1

 IF	FINAL=0

;       ----

        jp      HardReset
        jp      SoftReset
        jp      IntEntry
        jp      GetByte
        jp      PutByte
        jp      EnqStatus
        jp      FlushTx
        jp      FlushRx
        jp      SetTimeout

;       ----

.HardReset
        push    bc
        push    de
        ld      a,FN_AH
        ld      b,HN_SER
        OZ      OS_Fn                           ; allocate serial handle
        pop     de
        pop     bc
        jr      c, hrst_1

        ld      (ix+shnd_RxBuf), c
        ld      (ix+shnd_RxBuf+1), b
        ld      (ix+shnd_TxBuf), e
        ld      (ix+shnd_TxBuf+1), d

        xor     a                               ; !! 'ld a, $ff
        dec     a
        out     (BL_TXD), a                     ; clear TDRE int

        ld      a, BM_RXCSHTW|BM_RXCUART|BM_RXCIRTS|BR_9600
        call    WrRxC

        ld      a, BM_TXCATX|BR_9600
        ld      (BLSC_TXC), a
        out     (BL_TXC), a

        xor     a                               ; no XON/XOFF
        ld      (cSerXonXoffChar), a            ; !! clear ubSerFlowControl as well

        dec     a
        out     (BL_UAK), a                     ; clear DCD/CTS ints

        in      a, (BL_RXD)                     ; clear RDRF int
        ld      a, BM_UITDCDI
        ld      (BLSC_UIT), a
        out     (BL_UIT), a

        ld      a, BM_RXCSHTW|BM_RXCIRTS|BR_9600
        call    WrRxC

        ld      a, 0                            ; no parity
        ld      (ubSerParity), a

        ld      a, (BLSC_INT)
        or      BM_STAUART
        ld      (BLSC_INT), a
        out     (BL_INT), a

        or      a                               ; Fc=0 !! unnecessary

.hrst_1
        ret

;       ----

.SoftReset
        ld      (ix+shnd_Timeout), <60000       ; !! default timeout 600.00 seconds
        ld      (ix+shnd_Timeout+1), >60000
        call    FlushTx
        call    FlushRx

        ld      bc, PA_Rxb                      ; get receive speed
        call    EnquireParam
        call    BaudToReg
        ld      b, a                            ; !! 'or BM_RXCSHTW|BM_RXCIRTS'
        ld      a, BM_RXCSHTW|BM_RXCIRTS
        or      b
        call    WrRxC

        ld      bc, PA_Txb                      ; get transmit speed
        call    EnquireParam
        call    BaudToReg
        ld      b, a
        ld      a, (BLSC_TXC)
        and     ~7                              ; mask out baud rate
        or      b                               ; insert new speed
        ld      (BLSC_TXC), a
        out     (BL_TXC), a

        ld      bc, PA_Par                      ; get parity
        call    EnquireParam
        ld      c, 3                            ; ?? probably TDRH_START|TDRH_STOP, not used
        ld      a, e
        cp      'N'                             ; none
        jr      z, srst_1

        set     PAR_B_PARITY, c
        cp      'E'                             ; even
        jr      z, srst_1

        set     PAR_B_ODD, c
        cp      'O'                             ; odd
        jr      z, srst_1

        set     PAR_B_STICKY, c
        cp      'S'                             ; space
        jr      z, srst_1

        set     PAR_B_MARK, c

.srst_1
        ld      a, c
        ld      (ubSerParity), a

        ld      bc, PA_Xon                      ; get Xon/Xoff
        call    EnquireParam
        ld      a, (ubSerFlowControl)
        and     ~(FLOW_XONXOFF|FLOW_TXSTOP)
        ld      c, a
        ld      a, e
        cp      'Y'
        jr      nz, srst_2
        set     FLOW_B_XONXOFF, c
        ld      a, XON
        ld      (cSerXonXoffChar), a
        call    EI_TDRE

.srst_2
        ld      a, c
        ld      (ubSerFlowControl), a

        or      a                               ; Fc=0
        ret

;       ----

.EnquireParam
        ld      de, 2                           ; return parameter in DE
        OZ      OS_Nq
        ret

;       ----

.BaudToReg
        ex      af, af'                         ; !! unnecesary
        xor     a                               ; count from 0 upwards
        ex      af, af'
        ld      b, d                            ; baud rate into BC
        ld      c, e
        ld      hl, BaudRates
.b2r_1
        ld      e, (hl)                         ; de=(hl)++
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      a, d                            ; use 9600 if end of list
        or      e
        ld      a, BR_9600
        jr      z, b2r_3

        ex      de, hl
        sbc     hl, bc
        ex      de, hl
        jr      z, b2r_2                        ; found? exit

        ex      af, af'                         ; increment and loop
        inc     a
        ex      af, af'
        jr      b2r_1

.b2r_2
        ex      af, af'
.b2r_3
        or      a                               ; !! unnecessary
        ret

.BaudRates
        defw    75, 300, 600, 1200, 2400, 9600, 19200, 38400
        defw    0

;       ----

.IntEntry
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

;       ----

.RxInt
        push    af

;       get char from serial port

        ld      hl, (ubSerParity)               ; L=parity, H=flow control
        in      a, (BL_RXE)                     ; !! probably need to read this too
        in      a, (BL_RXD)                     ; read serial data

;       clear parity bit, check for XON/XOFF if needed

 IF     PARITYBUG=1
        bit     PAR_B_STICKY, l
 ELSE
        bit     PAR_B_PARITY, l
 ENDIF
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
        ld      l, BF_PB
        call    OZ_BUFF
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
        ld      l, BF_GB
        call    OZ_BUFF
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
        push    af                              ; parity into C
        ld      a, (ubSerParity)                ; !! 'ld bc, (ubSerParity)'
        ld      c, a
        pop     af
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
        push    af                              ; !! 'ex af' for speed

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

        pop     af
        ret

;       ----

.PutByte
        push    af
        call    MayGetTimeout                   ; get default timeout if BC = -1
        call    Ld_IX_TxBuf
        pop     af
        ld      l, BF_PBT                       ; put byte with timeout
        call    OZ_BUFF
        call    nc, EI_TDRE                     ; enable TDRE if succesful
        ret

;       ----

.GetByte
        call    OZ_DI
        push    af                              ; get byte with timeout
        call    Ld_IX_RxBuf
        ld      l, BF_GBT
        call    OZ_BUFF
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

.EnqStatus
        call    OZ_DI                           ; !! 'push/pop IX' at start/end to
        push    af                              ; !! eliminate one 'push/pop' pair
        push    ix
        call    Ld_IX_TxBuf                     ; get TxBuf status
        ld      l, BF_STA
        call    OZ_BUFF
        pop     ix
        push    hl

        push    ix
        call    Ld_IX_RxBuf                     ; get RxBuf status
        ld      l, BF_STA
        call    OZ_BUFF
        pop     ix

        ex      de, hl                          ; DE=RxStatus
        pop     bc                              ; BC=TxStatus
        pop     af
        call    OZ_EI
        in      a, (BL_UIT)                     ; A=int status
        or      a
        ret

;       ----

.SetTimeout
        ld      (ix+shnd_Timeout), c
        ld      (ix+shnd_Timeout+1), b
        ret

;       ----

.FlushTx
        push    ix
        call    Ld_IX_TxBuf
        jr      FlushBuf

.FlushRx
        push    ix
        call    Ld_IX_RxBuf

.FlushBuf
        ld      l, BF_PUR
        call    OZ_BUFF
        pop     ix
        ret

;       ----

.EI_TDRE
        call    OZ_DI
        push    af                              ; !! 'ex af' for speed
        ld      a, (BLSC_UMK)
        bit     BB_UMKTDRE, a
        jr      nz, eitdre_x                    ; TDRE enabled already

        or      BM_UMKTDRE
        ld      (BLSC_UMK), a
        out     (BL_UMK), a

.eitdre_x
        pop     af
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
        inc     bc                              ; !! 'ld a, b; and c; inc a; ret nz'
        ld      a, b
        or      c
        dec     bc
        ret     nz
        ld      b, (ix+shnd_Timeout+1)          ; use this if BC(in) = -1
        ld      c, (ix+shnd_Timeout)
        ret

 ELSE
	binary "rs232.bin"
 ENDIF

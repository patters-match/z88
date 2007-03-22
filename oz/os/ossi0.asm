; **************************************************************************************************
; OZ Low level serial port interface, called by INT handler and high level OS_Gbt/OS_Pbt.
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
        include "stdio.def"
        include "handle.def"
        include "syspar.def"
        include "sysvar.def"
        include "serintfc.def"
        include "interrpt.def"

        include "lowram.def"

xdef    OSSi
xdef    WrRxC
xdef    EI_TDRE
xdef    OSSiGbt, OSSiPbt

;xref    BfPb                                    ; bank0/lowram.def.asm
;xref    BfGb                                    ; bank0/lowram.def.asm
;xref    BfPb2                                   ; bank0/lowram.def.asm
;xref    BfGb2                                   ; bank0/lowram.def.asm
;xref    BfSta2                                  ; bank0/lowram.def.asm
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
        ld      hl, OSSiRet
        push    hl                              ; stack the ret
        exx                                     ; restore main registers
        ld      a, l                            ; OS_SI reason code
        add     a, OSSITBL%256
        ld      l, a
        ld      a, OSSITBL/256
        adc     a, 0                            ; take care of page address crossing...
        ld      h, a                            ; h is unused and always destroyed by OSSi
        ex      af, af'                         ; restore af (used in OSSiPbt)
        jp      (hl)                            ; jump to routine

.OSSiRet
        pop     ix
        jp      OZCallReturn1

.OSSITBL
        jp      OSSiHrd
        jp      OSSiSft
        jp      IntUART                         ; in lowram.def for speed
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

.OSSiPbt
        push    af
        ld      a, b
        and     c
        inc     a
        jr      nz, sipbt_2
        ld      bc, (uwSerTimeout)              ; get default timeout if BC = -1
.sipbt_2
        ld      ix, SerTXHandle
        pop     af
        call    BfPbt                           ; put byte with timeout
        call    nc, EI_TDRE                     ; enable TDRE if succesful
        ret

;       ----

.OSSiGbt
        call    OZ_DI
        push    af                              ; get byte with timeout
        ld      ix, SerRXHandle
        call    BfGbt
        call    BfSta2                          ; int are disabled and AF have to be preserved
        jr      c, gb_2                         ; error? exit
        ld      e, a

;       unblock sender if buffer less than half full

        ld      a, h                            ; #bytes in buffer
        add     a, l                            ; + free space = buf size
        srl     a                               ; /2
        cp      l
        jr      nc, gb_1                        ; less than 50% free? skip

        ld      a, (BLSC_RXC)
        bit     BB_RXCIRTS, a                   ; invert RTS? skip
        jr      nz, gb_1                        ; RTS inversion already done

        or      BM_RXCIRTS                      ; set IRTS (inverse RTS level)
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
        push    af
        ld      a, (BLSC_UMK)
        bit     BB_UMKTDRE, a
        jr      nz, eitdre_x                    ; TDRE int already enabled
        or      BM_UMKTDRE                      ; enable TDRE int
        ld      (BLSC_UMK), a
        out     (BL_UMK), a
.eitdre_x
        pop     af
        call    OZ_EI
        xor     a
        ret

;       ----

.WrRxC
        ld      (BLSC_RXC), a
        out     (BL_RXC), a
        ret

;       ----

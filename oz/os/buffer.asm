; **************************************************************************************************
; Low level buffer I/O used by keyboard, serial interface and interrupts.
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
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
;***************************************************************************************************

        Module Buffer

        include "buffer.def"
        include "interrpt.def"
        include "director.def"
        include "error.def"
        include "sysvar.def"
        include "keyboard.def"
        include "lowram.def"

xdef    BfSta, BfSta4I
xdef    BfPur
xdef    BufWrite, BufWrite4I
xdef    BufRead, BufRead4I
xdef    BfGbt
xdef    BfPbt
xdef    InitBufKBD_RX_TX

xref    OSWaitMain                              ; K0/nmi.asm



; ---------------------------------------------------------------------------------------------
; Get buffer status
;
;IN:    IX = buffer
;OUT:   H = number of databytes in buffer
;       A = L = number of free bytes in buffer
;       Fz = 1, buffer full
;       Fc = 0, always
;CHG:   AF....HL/....

.BfSta
        di
        call    BfSta4I
        ei
        ret

.BfSta4I                                        ; for use in interruption "4I"
        ld      l, (ix+buf_length)              ; length
        ld      a, (ix+buf_wrpos)
        sub     (ix+buf_rdpos)
        jr      nc, sta_no_wrap                 ; handle buffer wrap
        add     a, l
.sta_no_wrap
        ld      h, a                            ; used = wrpos - rdpos
        ld      a, l                            ; free=bufsize-used-1
        sub     h
        dec     a
        ld      l, a
        or      a                               ; Fc=0, Fz kept
        ret


; ---------------------------------------------------------------------------------------------
; Purge buffer
;
;IN:    IX = buffer
;OUT:   Fc=0
;CHG:   AF....../....

.BfPur
        di
        ld      a, (ix+buf_rdpos)
        ld      (ix+buf_wrpos), a
        ei
        or      a
        ret


; ---------------------------------------------------------------------------------------------
; Write byte to buffer
;
;IN :   IX = buffer
;       A = byte to be written
;OUT:   Fc=0, success
;       Fc=1, failure and A = Rc_Eof
;CHG:   AF.C..HL/....

.BufWrite
        di
        call    BufWrite4I
        ei
        ret

.BufWrite4I                                     ; 4I = for interruption routine (respect DI state)
        ld      c,a
        ld      a,(ix+buf_wrpos)
        ld      l,a
        inc     a
        and     (ix+buf_mask)
        cp      (ix+buf_rdpos)
        jr      z, eof_ret
        ld      h, (ix+buf_page)
        ld      (hl), c
        ld      (ix+buf_wrpos), a

        ld      hl, ubIntTaskToDo
        set     ITSK_B_BUFFER, (hl)             ; there is something

        ret

.eof_ret
        ld      a, RC_Eof
        scf
        ret


; ---------------------------------------------------------------------------------------------
; Read byte from buffer
;
;IN :   IX = buffer
;OUT:   Fc=0, success and A = byte read
;       Fc=1, failure and A = Rc_Eof
;CHG:   AF.C..HL/....

.BufRead
        di
        call    BufRead4I
        ei
        ret

.BufRead4I
        ld      a, (ix+buf_rdpos)
        cp      (ix+buf_wrpos)
        jr      z, eof_ret
        ld      h, (ix+buf_page)
        ld      l, a
        ld      c, (hl)

        inc     a
        and     (ix+buf_mask)
        ld      (ix+buf_rdpos), a

        ld      hl, ubIntTaskToDo
        res     ITSK_B_BUFFER, (hl)             ; data have been read

        ld      a, c
        ret


; ---------------------------------------------------------------------------------------------
; Get byte with timeout
;
;IN:    BC = timeout, $FFFF for default
;       IX = buffer
;OUT:   Fc=0, A=data, BC=remaining time if success
;       Fc=1, A=error if fail
;chg:   AFBC..HL/....

.BfGbt
        push    de

        ld      de, 0
        ld      hl, ubIntTaskToDo
        ld      (uwSmallTimer), de              ; zero timer, then disable it, then write new value
        res     ITSK_B_TIMER, (hl)
        ld      (uwSmallTimer), bc

        call    BfCheck
        jr      nc, bfgbt_get                   ; if there's data we can exit right away

        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfgbt_susp0                 ; pre-empted? exit
        bit     ITSK_B_ESC, (hl)
        jr      nz, bfgbt_esc                   ; ESC pending? exit

        ld      a, b                            ; wait if timeout not 0
        or      c
        jr      nz, bfgbt_9

.bfgbt_to
        ld      a, RC_Time
.bfgbt_err
        scf
        jr      bfgbt_x

.bfgbt_get
        call    BufRead
        jr      c, bfgbt_9                      ; error, wait for more

.bfgbt_x
        ld      hl, ubIntTaskToDo
        res     ITSK_B_BUFFER, (hl)             ; cancel buffer task
        pop     de
        ld      bc, (uwSmallTimer)
        ret

.bfgbt_esc
        ld      a, RC_Esc
        jr      bfgbt_err

.bfgbt_susp0
        res     ITSK_B_PREEMPTION, (hl)         ; cancel buffer task

.bfgbt_susp
        ld      a, RC_Susp
        jr      bfgbt_err

.bfgbt_8
        res     ITSK_B_BUFFER, (hl)             ; if there's data in buffer go and get it
        call    BfCheck
        jr      nc, bfgbt_get

.bfgbt_9
        call    OSWaitMain                      ; wait for data

        bit     ITSK_B_PREEMPTION, a
        jr      nz, bfgbt_susp0                 ; pre-empted? cancel buffer task and exit
        bit     ITSK_B_ESC, a
        jr      nz, bfgbt_esc                   ; ESC pending? exit
        bit     ITSK_B_BUFFER, a
        jr      nz, bfgbt_8                     ; buffer job?  check for data
        bit     ITSK_B_TIMER, a
        jr      nz, bfgbt_to                    ; timeout? exit
        jr      bfgbt_susp                      ; otherwise exit with pre-emption


; ---------------------------------------------------------------------------------------------
; Check if there's data in buffer
;
;IN:    IX = buffer
;       HL = ubIntTaskToDo
;OUT:   Fc=0 if data is ready
;       Fc=1 if buffer is empty or there's pending escape condition
;chg:   AF....../....

.BfCheck
        di
        bit     ITSK_B_ESC, (hl)                ; Fc=1 if ESC pending
        scf
        jr      nz, bfchk_x
        ld      a, (ix+buf_wrpos)               ; this is *NOT* necessarily #data bytes,
        sub     (ix+buf_rdpos)                  ; buffer wrap isn't handled
        cp      1                               ; Fc=1 if buffer empty
.bfchk_x
        ei
        ret


; ---------------------------------------------------------------------------------------------
; Put byte with timeout
;
;IN:    IX = buffer
;       A  = data
;       BC = timeout
;OUT:   Fc=0, BC=remaining time if success
;       Fc=1, A=error if fail
;cfg:   AFBC

.BfPbt
        push    de
        push    af                              ; save data

        ld      de, 0                           ; reset timer, disable it, then set new value
        ld      hl, ubIntTaskToDo
        ld      (uwSmallTimer), de
        res     ITSK_B_TIMER, (hl)
        ld      (uwSmallTimer), bc

        call    BfSta
        cp      1                               ; a=free slots, buf has room ?
        jr      nc, bfpbt_put                   ; there's room, just put byte

        ld      hl, ubIntTaskToDo
        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfpbt_susp0                 ; pre-empted? cancel buffer task and exit
        bit     ITSK_B_ESC, (hl)
        jr      nz, bfpbt_esc                   ; ESC pending? exit

        ld      a, b                            ; if timeout not zero go wait
        or      c
        jr      nz, bfpbt_9

.bfpbt_to
        ld      a, RC_Time
.bfpbt_err
        scf
        jr      bfpbt_x

.bfpbt_put
        pop     af                              ; write data into buffer
        push    af
        call    BufWrite
        jr      c, bfpbt_9                      ; error? wait more

.bfpbt_x
        pop     de                              ; was af, get rid of data in stack
        jp      bfgbt_x                         ; exit thru BfGbt code

.bfpbt_esc
        ld      a, RC_Esc
        jr      bfpbt_err

.bfpbt_susp0
        res     ITSK_B_PREEMPTION, (hl)         ; cancel buffer task

.bfpbt_susp
        ld      a, RC_Susp
        jr      bfpbt_err

.bfpbt_8
        res     ITSK_B_BUFFER, (hl)             ; cancel buffer task
        call    BfSta
        cp      1                               ; a=free slots, buf has room ?
        jr      nc, bfpbt_put                   ; try to put data if room in buffer

.bfpbt_9
        call    OSWaitMain                      ; wait for buffer task

        bit     ITSK_B_PREEMPTION, a
        jr      nz, bfpbt_susp0                 ; pre-emped? exit
        bit     ITSK_B_ESC, a
        jr      nz, bfpbt_esc                   ; ESC pending? exit
        bit     ITSK_B_BUFFER, a
        jr      nz, bfpbt_8                     ; buffer task? try to put byte
        bit     ITSK_B_TIMER, a
        jr      nz, bfpbt_to                    ; timeout? exit
        jr      bfpbt_susp                      ; otherwise exit with pre-emption


; ---------------------------------------------------------------------------------------------
; Initialize OZ buffers at reset
;
.InitBufKBD_RX_TX
        ld      ix, KbdData                     ; KBD buffer
        ld      b, kbd_SIZEOF                   ; clear kbd data
        ld      c, KB_BUF_LEN
        ld      de, KbdBuffer
        call    BufInit

        ld      ix, SerTXHandle                 ; TX buffer
        ld      c, TX_BUF_LEN
        ld      de, SerTXBuffer
        call    BufInit0

        ld      ix, SerRXHandle                 ; RX buffer
        ld      c, RX_BUF_LEN
        ld      de, SerRXBuffer
        jp      BufInit0


; ---------------------------------------------------------------------------------------------
; init buffer with no function or data area

.BufInit0
        ld      b, 0

; Initialize buffer
;
;IN:    IX = buffer
;       B  = data area to clear, starting at (IX)
;       C  = circular buffer length
;       DE = circular buffer

.BufInit
        push    ix
        ld      (ix+buf_wrpos), e
        ld      (ix+buf_rdpos), e
        ld      (ix+buf_page), d
        ld      (ix+buf_length), c
        ld      a, c
        cpl
        ld      (ix+buf_mask), a

        inc     b                               ; handle B=0
        jr      bufi_2
.bufi_1
        ld      (ix+0), 0                       ; clear data after (IX)
        inc     ix
.bufi_2
        djnz    bufi_1
        pop     ix
        ret

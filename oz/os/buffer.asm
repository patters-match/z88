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

xdef    BfGbt
xdef    BfPbt
xdef    BfPur
xdef    BfSta
xdef    BufRead
xdef    BufWrite
xdef    BfSta4I
xdef    BufRead4I
xdef    BufWrite4I
xdef    InitBufKBD_RX_TX

xref    OSWaitMain                              ; bank0/nmi.asm


; ---------------------------------------------------------------------------------------------
; Get buffer status
;
;IN:    IX = buffer
;OUT:   H = number of databytes in buffer
;       L = number of free bytes in buffer
;chg:   ......HL/....

.BfSta
        call    OZ_DI
        call    BfSta4I
        call    OZ_EI
        or      a
        ret

.BfSta4I                                        ; for use in interruption
        push    af
        ld      a, (ix+buf_wrpos)
        sub     (ix+buf_rdpos)
        jr      nc, sta_no_wrap                 ; handle buffer wrap
        neg                                     ; buffer length is a page
.sta_no_wrap        
        ld      h, a                            ; used = wrpos - rdpos
        cpl                                     ; free=bufsize-used-1 (neg + dec a = cpl !)
        ld      l, a
        pop     af
        ret


; ---------------------------------------------------------------------------------------------
; Purge buffer
;
;IN:    IX = buffer
;OUT:   Fc=0
;chg:   F

.BfPur
        call    OZ_DI
        ex      af, af'
        ld      a, (ix+buf_rdpos)
        ld      (ix+buf_wrpos), a
        ex      af, af'
        call    OZ_EI
        or      a
        ret


; ---------------------------------------------------------------------------------------------
; Write byte to buffer
;
;IN :   IX = buffer
;       A = byte to be written
;OUT:   Fc=0, success
;       Fc=1, failure and A = Rc_Eof
;CHG:   AF....HL/....

.BufWrite
        ex      af, af'
        call    OZ_DI
        ex      af, af'
        call    BufWrite4I
        ex      af, af'
        call    OZ_EI
        ex      af, af'
        ret

.BufWrite4I
        ld      h,a
        ld      a,(ix+buf_wrpos)
        ld      l,a
        inc     a
        cp      (ix+buf_rdpos)
        jr      z, eof_ret
        ld      a, h
        ld      h, (ix+buf_page)
        ld      (hl), a
        inc     (ix+buf_wrpos)
        or      a                               ; reset Fc
        ld      hl, ubIntTaskToDo
        set     ITSK_B_BUFFER, (hl)             ; buffer task
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
        call    OZ_DI
        ex      af, af'
        call    BufRead4I
        ex      af, af'
        call    OZ_EI
        ex      af, af'
        ret
        
.BufRead4I
        ld      a, (ix+buf_rdpos)
        cp      (ix+buf_wrpos)
        jr      z, eof_ret
        ld      h, (ix+buf_page)
        ld      l, a
        ld      a, (hl)
        inc     (ix+buf_rdpos)
        or      a                               ; reset Fc
        ld      hl, ubIntTaskToDo
        set     ITSK_B_BUFFER, (hl)             ; buffer task
        ret


; ---------------------------------------------------------------------------------------------
; Put byte with timeout
;
;IN:    IX = buffer
;       A  = data
;       BC = timeout
;OUT:   Fc=0, BC=remaining time if success
;       Fc=1, A=error if fail
;CHG:   AFBCDEHL/....

.BfPbt
        ex      af, af'
        call    OZ_DI                           ; save int status
        push    af
        ei                                      ; force int enabled
        ex      af, af'

        push    af                              ; save byte to put
        
        ld      hl, ubIntTaskToDo
        res     ITSK_B_TIMER, (hl)
        ld      (uwSmallTimer), bc
        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfpbt_susp0                 ; pre-empted? ack susp and exit
        bit     ITSK_B_ESC, (hl)
        jr      nz, bfpbt_esc                   ; ESC pending? exit

.bfpbt_put
        call    BufWrite
        jr      c, bfpbt_wait                   ; RC_Eof, buffer full, wait

.bfpbt_x
        ld      hl, ubIntTaskToDo
        res     ITSK_B_BUFFER, (hl)
        ex      af, af'
        pop     af                              ; was af on entry
        pop     af                              ; previous int status
        call    OZ_EI
        ex      af, af'
        ld      bc, (uwSmallTimer)
        ret

.bfpbt_to
        ld      a, RC_Time
.bfpbt_err
        scf
        jr      bfpbt_x

.bfpbt_esc
        ld      a, RC_Esc
        jr      bfpbt_err

.bfpbt_susp0
        res     ITSK_B_PREEMPTION, (hl)         ; ack preemption

.bfpbt_susp
        ld      a, RC_Susp
        jr      bfpbt_err

.bfpbt_again
        res     ITSK_B_BUFFER, (hl)             ; cancel buffer task
        pop     af                              ; restore byte to put
        push    af
        jr      bfpbt_put                       ; try to put data if room in buffer

.bfpbt_wait
        ld      bc, (uwSmallTimer)
        ld      a, b
        or      c
        jr      z, bfpbt_to

        call    OSWaitMain                      ; wait for buffer task

        bit     ITSK_B_PREEMPTION, a
        jr      nz, bfpbt_susp0                 ; pre-emped? exit
        bit     ITSK_B_ESC, a
        jr      nz, bfpbt_esc                   ; ESC pending? exit
        bit     ITSK_B_BUFFER, a
        jr      nz, bfpbt_again                 ; (was NZ) buffer task? try to put byte
        bit     ITSK_B_TIMER, a
        jr      nz, bfpbt_to                    ; timeout? exit
        jr      bfpbt_susp                      ; otherwise exit with pre-emption


; ---------------------------------------------------------------------------------------------
; Get byte with timeout
;
;IN:    BC = timeout, $FFFF for default
;       IX = buffer
;OUT:   Fc=0, A=data, BC=remaining time if success
;       Fc=1, A=error if fail
;CHG:   AFBCDEHL/....

.BfGbt
        call    OZ_DI                           ; save int status
        push    af
        ei                                      ; force int enabled
        
        ld      hl, ubIntTaskToDo
        res     ITSK_B_TIMER, (hl)              ; 
        ld      (uwSmallTimer), bc
.bfgbt_get
        call    BufRead
        jr      c, bfgbt_wait                   ; RC_Eof, buffer is empty, wait

.bfgbt_x
        ld      hl, ubIntTaskTodo
        res     ITSK_B_BUFFER, (hl)
        ex      af, af'                         ; preserve af
        pop     af
        call    OZ_EI
        ex      af, af'
        ld      bc, (uwSmallTimer)
        ret

.bfgbt_to
        ld      a, RC_Time
.bfgbt_err
        scf
        jr      bfgbt_x

.bfgbt_esc
        ld      a, RC_Esc
        jr      bfgbt_err

.bfgbt_susp0
        res     ITSK_B_PREEMPTION, (hl)         ; acknowledge preemption

.bfgbt_susp
        ld      a, RC_Susp
        jr      bfgbt_err
        
.bfgbt_again
        res     ITSK_B_BUFFER, (hl)
        jr      bfgbt_get

.bfgbt_wait
        ld      hl, ubIntTaskTodo
        bit     ITSK_B_ESC, (hl)                ; Fc=1 if ESC pending
        jr      nz, bfgbt_esc
        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfgbt_susp0                 ; pre-empted? exit

        ld      bc, (uwSmallTimer)
        ld      a, b
        or      c
        jr      z, bfgbt_to

        call    OSWaitMain                      ; wait for data

        bit     ITSK_B_PREEMPTION, a
        jr      nz, bfgbt_susp0                 ; pre-empted? cancel buffer task and exit
        bit     ITSK_B_ESC, a
        jr      nz, bfgbt_esc                   ; ESC pending? exit
        bit     ITSK_B_BUFFER, a
        jr      nz, bfgbt_again                 ; buffer job?  check for data
        bit     ITSK_B_TIMER, a
        jr      nz, bfgbt_to                    ; timeout? exit
        jr      bfgbt_susp                      ; otherwise exit with pre-emption


; ---------------------------------------------------------------------------------------------
; Initialize OZ buffers at reset
;
.InitBufKBD_RX_TX
        ld      e, 0                            ; 1 page for each buffer

        ld      ix, KbdData                     ; KBD buffer
        ld      b, kbd_SIZEOF                   ; clear kbd data
        ld      d, >KbdBuffer
        call    BufInit

        ld      ix, SerTXHandle                 ; TX buffer
        ld      d, >SerTXBuffer
        call    BufInit0

        ld      ix, SerRXHandle                 ; RX buffer
        ld      d, >SerRXBuffer
        jp      BufInit0


; ---------------------------------------------------------------------------------------------
; init buffer with no function or data area

.BufInit0
        ld      b, 0

; Initialize buffer
;
;IN:    IX = buffer
;       B  = data area to clear, starting at (IX)
;       DE = circular buffer

.BufInit
        push    ix
        ld      (ix+buf_wrpos), e
        ld      (ix+buf_rdpos), e
        ld      (ix+buf_page), d
        inc     b                               ; handle B=0
        jr      bufi_2
.bufi_1
        ld      (ix+0), 0                       ; clear data after (IX)
        inc     ix
.bufi_2
        djnz    bufi_1
        pop     ix
        ret

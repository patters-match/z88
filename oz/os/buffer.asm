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
xdef    InitBufKBD_RX_TX

;xref    BfGb
;xref    BfPb
xref    OSWaitMain                              ; [kernel0]/nmi.asm


; ---------------------------------------------------------------------------------------------
; Purge buffer
;
;IN:    IX = buffer
;OUT:   Fc=0
;chg:   F

.BfPur
        di        
        ld      a, (ix+buf_rdpos)
        ld      (ix+buf_wrpos), a
        ei
        or      a
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
        ei                                      ; force int enabled (for RTC)
        push    af                              ; save byte to put
        ld      hl, ubIntTaskToDo
        res     ITSK_B_TIMER, (hl)              ; reset timeout flag
        ld      (uwSmallTimer), bc              ; small timer counts timeout
        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfpbt_susp0                 ; pre-empted? ack susp and exit
        bit     ITSK_B_ESC, (hl)
        jr      nz, bfpbt_esc                   ; ESC pending? exit

.bfpbt_put
        di
        call    BfPb                            ; put byte in buffer
        ei        
        jr      c, bfpbt_wait                   ; RC_Eof, buffer full, wait

.bfpbt_x
        ld      hl, ubIntTaskToDo               ; buffer task done
        res     ITSK_B_BUFFER, (hl)
        pop     hl                              ; balance stack, was af on entry
        ld      bc, (uwSmallTimer)              ; time remaining
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

        call    OSWaitMain                      ; wait for event, returns ITSK in A

        bit     ITSK_B_PREEMPTION, a
        jr      nz, bfpbt_susp0                 ; pre-emped? exit
        bit     ITSK_B_ESC, a
        jr      nz, bfpbt_esc                   ; ESC pending? exit
        bit     ITSK_B_BUFFER, a
        jr      nz, bfpbt_again                 ; buffer task? try again
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
        ei                                      ; force int enabled (for RTC)
        ld      hl, ubIntTaskToDo
        res     ITSK_B_TIMER, (hl)              ; reset timeout flag
        ld      (uwSmallTimer), bc              ; small timer counts timeout
        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfgbt_susp0                 ; pre-empted? exit
        bit     ITSK_B_ESC, (hl)                ; Fc=1 if ESC pending
        jr      nz, bfgbt_esc
.bfgbt_get
        di
        call    BfGb                            ; read buffer
        ei        
        jr      c, bfgbt_wait                   ; RC_Eof, buffer is empty, wait

.bfgbt_x
        ld      hl, ubIntTaskTodo               ; buffer task done
        res     ITSK_B_BUFFER, (hl)
        ld      bc, (uwSmallTimer)              ; time remaining
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
        ld      bc, (uwSmallTimer)
        ld      a, b
        or      c
        jr      z, bfgbt_to

        call    OSWaitMain                      ; wait for event, returns ITSK in A

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

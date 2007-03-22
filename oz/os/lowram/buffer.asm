; **************************************************************************************************
; Lowram buffer routines for low serial interface and keyboard.
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


; ---------------------------------------------------------------------------------------------
; Get buffer status
;
;IN:    IX = buffer handle
;OUT:   H = number of databytes in buffer
;       L = number of free bytes in buffer
;chg:   ......HL/....

.BfSta
        call    OZDImain
        call    BfSta2
        call    OZEIMain
        or      a
        ret

.BfSta2                                         ; for use in interruption
        push    af
        ld      a, (ix+buf_wrpos)
        sub     (ix+buf_rdpos)
        ld      h, a                            ; used = wrpos - rdpos
        cpl                                     ; free=bufsize-used-1 (neg + dec a = cpl !)
        ld      l, a
        pop     af
        ret


; ---------------------------------------------------------------------------------------------
; Write byte to buffer
;
;IN :   IX = buffer handle
;       A = byte to be written
;OUT:   Fc=0, success
;       Fc=1, failure and A = Rc_Eof
;CHG:   AF....HL/....

.BfPb
        ex      af, af'
        call    OZDImain
        ex      af, af'
        call    BfPb2
        ex      af, af'
        call    OZEImain
        ex      af, af'
        ret

.BfPb2
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
;IN :   IX = buffer handle
;OUT:   Fc=0, success and A = byte read
;       Fc=1, failure and A = Rc_Eof
;CHG:   AF.C..HL/....

.BfGb
        call    OZDImain
        ex      af, af'
        call    BfGb2
        ex      af, af'
        call    OZEImain
        ex      af, af'
        ret

.BfGb2
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

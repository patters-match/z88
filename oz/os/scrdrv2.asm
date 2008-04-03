; **************************************************************************************************
; Screen driver enquiry calls. The routines are located in Kernel 0.
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
; ***************************************************************************************************

        Module ScrDrv2

        include "error.def"
        include "sysvar.def"
        include "screen.def"

xdef    GetWindowFrame
xdef    NqRDS

xref    CursorRight                             ; [Kernel0]/scrdrv4.asm
xref    ScreenClose                             ; [Kernel0]/scrdrv4.asm
xref    ScreenOpen                              ; [Kernel0]/scrdrv4.asm
xref    GetOSFrame_DE                           ; [Kernel0]/memmisc.asm
xref    GetOSFrame_HL                           ; [Kernel0]/memmisc.asm
xref    PokeHLinc                               ; [Kernel0]/memmisc.asm

xref    GetCrsrYX                               ; [Kernel1]/scrdrv1.asm
xref    GetWindowNum                            ; [Kernel1]/scrdrv1.asm
xref    VDU2ChrCode                             ; [Kernel1]/scrdrv1.asm


; -----------------------------------------------------------------------------
;
; IN : A = window number, A = 0 use current window
; OUT: Fc = 0, success and IX = frame, A = window number character '1' to '8'
;      Fc = 1, failure and A = RC_Hand
;
; -----------------------------------------------------------------------------
.GetWindowFrame
        or      a
        jr      nz, gwf_1                       ; a<>0? don't use current window
        ld      a, (sbf_ActiveWd+1)
        sub     >Wd1Frame-'1'

.gwf_1
        sub     $20
        call    GetWindowNum

        push    af
        ld      hl, Wd1Frame                    ; SBF page
        add     a, h                            ; +$100 for each window
        ld      h, a
        pop     af
        push    hl
        pop     ix                              ; window frame
        add     a, '1'
        ret     nc                              ; !! not enough to assert valid window
        ld      a, RC_Hand
        ret

; -----------------------------------------------------------------------------
;
; read text from the screen
;
;IN:    DE=buffer, HL=#bytes to read
;
; -----------------------------------------------------------------------------
.NqRDS
        call    GetOSFrame_HL                   ; BC=#bytes to read
        ld      b, h
        ld      c, l

        call    GetOSFrame_DE                   ; DE=buffer

        pop     af                              ; for ScreenClose()
        push    af
        push    ix
        ld      ix, (sbf_ActiveWd)
        push    af
        call    GetCrsrYX                       ; pointer actually

.rds_1
        ld      a, b
        or      c
        jr      z, rds_x                        ; no more chars? exit

        ld      a, (hl)                         ; char low byte
        push    hl
        call    VDU2ChrCode                     ; into ascii

        jr      c, rds_2                        ; not found in table

        dec     hl                              ; get ASCII
        dec     hl
        ld      a, (hl)

.rds_2
        pop     hl
        ex      af, af'

        exx
        call    ScreenClose                     ; restore S1
        exx

        ex      af, af'                         ; put char into buffer
        push    bc
        ex      de, hl
        call    PokeHLinc
        ex      de, hl
        pop     bc

        exx                                     ; put screen into S1
        call    ScreenOpen
        exx

        push    bc
        call    CursorRight                     ; advance pointer
        pop     bc                              ; decrement count and loop
        dec     bc
        jr      rds_1

.rds_x
        pop     af
        pop     ix
        call    ScreenClose

        or      a
        ret

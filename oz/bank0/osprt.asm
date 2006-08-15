; **************************************************************************************************
; OS_Prt entry socket (redirect calls to printer in kernel 1)
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
; $Id: osprt.asm 2490 2006-08-02 14:09:15Z gbs $
;***************************************************************************************************

        module OSPrt
        
        include "sysvar.def"
        include "director.def"
        include "error.def"

xdef    OSPrt

xref    OSFramePop                              ; bank0/misc4.asm
xref    OSFramePush                             ; bank0/misc4.asm
xref    OSPrtPrint                              ; bank7/printer.asm

;       send character directly to printer filter

.OSPrt
        call    OSFramePush
;        ex      af, af'                         ; we need screen because prt sequence buffer is in SBF
;        call    ScreenOpen                      ; !! this is also done in OSPrtMain, unnecessary here?
;        ex      af, af'

        ld      hl, (ubCLIActiveCnt)            ; !! just L
        inc     l
        dec     l
        jr      z, prt_2                        ; no cli, print direct

        OZ      DC_Prt                          ; otherwise use DC
        jr      nc, prt_x                       ; no error? exit
        cp      RC_Time
        jr      z, OSPrt                        ; timeout? retry forever
        scf
        jr      prt_x

.prt_2
        extcall OSPrtPrint, OZBANK_7

.prt_x
;        ex      af, af'
;        call    ScreenClose
;        ex      af, af'
        jp      OSFramePop

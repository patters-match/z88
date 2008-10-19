; **************************************************************************************************
; OS_Out / OS_Bout / OS_Pout interface.
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
; (C) Thierry Peycru (pek@users.sf.net), 2007
; (C) Gunther Strube (gbs@users.sf.net), 2007
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module  OsOut

        include "director.def"
        include "memory.def"
        include "sysvar.def"
        include "oz.def"

xdef    OSOut, OSBout, OSPout, OsOutKernel

xref    OSFramePush                             ; stkframe.asm
xref    OSFramePopX                             ; stkframe.asm
xref    OSBixS1, OSBoxS1                        ; stkframe.asm
xref    GetOSFrame_HL, PutOSFrame_HL, PeekHLinc ; memmisc.asm
xref    OSOutMain                               ; scrdrv1.asm


; *************************************************************************************
; OS_Out entry: write character to standard output
; IN:
;     A = character to be written
; OUT:
;     Fc = 0 always (error handler is never provoked)
;
; Registers changed after return to caller:
;     A.BCDEHL/IXIY same
;     .F....../.... different
;
.OSOut
        call    OSFramePush
        call    OsOutKernel                     ; write char to screen driver
        jp      OSFramePopX


; *************************************************************************************
; OS_Bout entry: write null-terminated string block at (B)HL to standard output
; IN:
;     BHL = extended pointer to string to be written (not crossing segments)
;           B = 0, then local address space pointer in caller bank binding
; OUT:
;     Fc = 0 always (error handler is never provoked)
;     HL points at byte after null-terminator
;
; Registers changed after return to caller:
;     A.BCDE../IXIY same
;     .F....HL/.... different
;
.OSBout
        call    OSFramePush
        call    OsBoutKernel                    ; write string at (B)HL to screen driver
        jp      OSFramePopX


; *************************************************************************************
; OS_Pout entry: write embedded null-terminated string at caller (PC) following
; this system call, to standard output.
;
; IN:
;     None
;
; OUT:
;     Fc = 0 always (error handler is never provoked)
;
; Registers changed after return to caller:
;     A.BCDEHL/IXIY same
;     .F....../.... different
;
.OSPout
        call    OSFramePush
        ld      l,(iy + OSFrame_OZPC)
        ld      h,(iy + OSFrame_OZPC+1)         ; pointer to start of string at OZ call
        call    BankDispString
                                                ; HL points at Z80 instruction after null-terminator
        res     6,h                             ; strip segment mask (if any)
        ld      a,(iy + OSFrame_OZPC+1)
        and     @11000000
        or      h
        ld      (iy + OSFrame_OZPC),l
        ld      (iy + OSFrame_OZPC+1),a         ; updated OZ caller return address to instruction following the null-terminator
        jp      OSFramePopX


; OsBoutKernel, used only within kernel that has already established the register stack frame
.OsBoutKernel
        call    GetOSFrame_HL
        ld      b, (iy+OSFrame_B)
        inc     b                               ; Extended address for OS_Bout?
        dec     b
        jr      nz,bind_bhl_str                 ; bind BHL pointer to segment 1 and send string to OS_Out
        call    BankDispString
.upd_hlptr
        dec     hl                              ; point at null-terminator
        res     6,h                             ; strip segment mask (if any)
        ld      a, (iy+OSFrame_H)
        and     @11000000
        or      h
        ld      h,a
        jp      PutOSFrame_HL                   ; return updated HL pointer to caller (points at byte after null-terminator)
.bind_bhl_str
        call    bind_strptr
        jr      upd_hlptr


.BankDispString
        bit     7, h                            ; bind source bank of HL pointer if inside current kernel bindings
        jr      z,OSOutString
.get_src_bank
        ld      b, (iy+OSFrame_S2)              ; HL pointer might be in segment 2 bank binding before OS_Bout
        bit     6, h
        jr      z, bind_strptr
        ld      b, (iy+OSFrame_S3)              ; HL pointer was in segment 3 bank binding before OS_Bout
.bind_strptr
        call    OSBixS1
        push    de
        call    OSOutString                     ; call subroutine: write string at HL to screen driver
        pop     de
        jp      OSBoxS1


.OSOutString
        call    PeekHLinc                       ; if HL is crossing from S1 to S2, then get char from pointer in bank in (OSFrame_S2)
        or      a
        ret     z                               ; null-terminator reached, string was sent to screen driver...
        push    hl
        call    OsOutKernel
        pop     hl
        jr      OSOutString


; OsOutKernel, used only within kernel that has already established the register stack frame
.OsOutKernel
        ld      c,a
        ld      a, (ubCLIActiveCnt)
        or      a
        ld      a,c
        jp      z, OSOutMain
        oz      DC_Out                          ; Write to CLI
        ret

; **************************************************************************************************
; OS_XXX 1 & 2 byte system call tables, located at $FF00 in Kernel 0.
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

        Module OSTables

        org     $FF00                           ; fixed start @ $00FF00

xdef    OZCallTable

IF COMPILE_BINARY
        include "kernel0.def"                   ; get lower kernel address references
        include "kernel1.def"                   ; get upper kernel address references
ELSE
        xref    OSDly                           ; [Kernel0]/osin.asm
        xref    OSPur                           ; [Kernel0]/osin.asm
        xref    OSXin                           ; [Kernel0]/osin.asm
        xref    CallDC                          ; [Kernel0]/misc2.asm
        xref    CallGN                          ; [Kernel0]/misc2.asm
        xref    CallOS2byte                     ; [Kernel0]/misc2.asm
        xref    OSAlm                           ; [Kernel0]/misc2.asm
        xref    OSPrt                           ; [Kernel0]/osprt.asm
        xref    OzCallInvalid                   ; [Kernel0]/misc2.asm
        xref    OSBix                           ; [Kernel0]/knlbind.asm
        xref    OSBox                           ; [Kernel0]/knlbind.asm
        xref    OSFramePop                      ; [Kernel0]/stkframe.asm
        xref    OSAxp                           ; [Kernel0]/memory.asm
        xref    OSFc                            ; [Kernel0]/memory.asm
        xref    OSMal                           ; [Kernel0]/memory.asm
        xref    OsMcl                           ; [Kernel0]/memory.asm
        xref    OSMfr                           ; [Kernel0]/memory.asm
        xref    OSMgb                           ; [Kernel0]/memory.asm
        xref    OSMop                           ; [Kernel0]/memory.asm
        xref    OSMpb                           ; [Kernel0]/memory.asm
        xref    CopyMemBHL_DE                   ; [Kernel0]/memmisc.asm
        xref    OSBde                           ; [Kernel0]/memmisc.asm
        xref    OSFn                            ; [Kernel0]/memmisc.asm
        xref    OSBlp                           ; [Kernel0]/scrdrv4.asm
        xref    OSSr                            ; [Kernel0]/scrdrv4.asm
        xref    OSDom                           ; [Kernel0]/process2.asm
        xref    OSBye                           ; [Kernel0]/process3.asm
        xref    OSEnt                           ; [Kernel0]/process3.asm
        xref    OSExit                          ; [Kernel0]/process3.asm
        xref    OSStk                           ; [Kernel0]/process3.asm
        xref    OSUse                           ; [Kernel0]/process3.asm
        xref    OSCl                            ; [Kernel0]/filesys2.asm
        xref    OSFrm                           ; [Kernel0]/filesys2.asm
        xref    OSFwm                           ; [Kernel0]/filesys2.asm
        xref    OSGb                            ; [Kernel0]/filesys2.asm
        xref    OSGbt                           ; [Kernel0]/filesys2.asm
        xref    OSMv                            ; [Kernel0]/filesys2.asm
        xref    OSOp                            ; [Kernel0]/filesys2.asm
        xref    OSPb                            ; [Kernel0]/filesys2.asm
        xref    OSPbt                           ; [Kernel0]/filesys2.asm
        xref    OSCli                           ; [Kernel0]/oscli0.asm
        xref    OSDor                           ; [Kernel0]/dor.asm
        xref    OSErc                           ; [Kernel0]/error.asm
        xref    OSErh                           ; [Kernel0]/error.asm
        xref    OSEsc                           ; [Kernel0]/esc.asm
        xref    OSFth                           ; [Kernel0]/handle.asm
        xref    OSGth                           ; [Kernel0]/handle.asm
        xref    OSVth                           ; [Kernel0]/handle.asm
        xref    OSHt                            ; [Kernel0]/time.asm
        xref    OSIn                            ; [Kernel0]/osin.asm
        xref    OSTin                           ; [Kernel0]/osin.asm
        xref    OSNq                            ; [Kernel0]/spnq0.asm
        xref    OSSp                            ; [Kernel0]/spnq0.asm
        xref    OSOff                           ; [Kernel0]/nmi.asm
        xref    OSWait                          ; [Kernel0]/nmi.asm
        xref    OSOut                           ; [Kernel0]/osout.asm
        xref    OSBout                          ; [Kernel0]/osout.asm
        xref    OSPout                          ; [Kernel0]/osout.asm
        xref    OSSi                            ; [Kernel0]/ossi.asm
        xref    OSUst                           ; [Kernel0]/osust.asm
        xref    OSWrt                           ; [Kernel0]/token.asm
        xref    OSWtb                           ; [Kernel0]/token.asm

        xref    OSEpr                           ; [Kernel1]/os/osepr/os.asm
        xref    OSFep                           ; [Kernel1]/os/osfep/osfep.asm
        xref    OSMap                           ; [Kernel1]/osmap.asm
        xref    OSDel                           ; [Kernel1]/filesys1.asm
        xref    OSRen                           ; [Kernel1]/filesys1.asm
        xref    OSIsq                           ; [Kernel1]/scrdrv1.asm
        xref    OSWsq                           ; [Kernel1]/scrdrv1.asm
        xref    OSPoll                          ; [Kernel1]/process1.asm
        xref    OSSci                           ; [Kernel1]/ossci.asm
ENDIF

.OZCallTable
        jp      OzCallInvalid
        jp      OSFramePop
        jp      CallOS2byte
        jp      CallGN
        jp      CallDC
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OSBye
        jp      OSPrt
        jp      OSOut
        jp      OSIn
        jp      OSTin
        jp      OSXin
        jp      OSPur
        jp      OzCallInvalid                   ; Os_Ugb
        jp      OSGb
        jp      OSPb
        jp      OSGbt
        jp      OSPbt
        jp      OSMv
        jp      OSFrm
        jp      OSFwm
        jp      OSMop
        jp      OsMcl
        jp      OSMal
        jp      OSMfr
        jp      OSMgb
        jp      OSMpb
        jp      OSBix
        jp      OSBox
        jp      OSNq
        jp      OSSp
        jp      OSSr
        jp      OSEsc
        jp      OSErc
        jp      OSErh
        jp      OSUst
        jp      OSFn
        jp      OSWait
        jp      OSAlm
        jp      OSCli
        jp      OSDor
        jp      OSFc                            ; $8A
        jp      OSSi                            ; $8D
        jp      OSBout                          ; $90
        jp      OSPout                          ; $93
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid                   ; end at $003F9E

; ***** FREE SPACE *****                        ; some code was here and removed for clarity

        defs    $29 ($FF)                       ; $3FC8 - $3FB1

; 2-byte calls, OSFrame set up already          ; start at $003FC8
        defw    OSFep
        defw    OSWtb
        defw    OSWrt
        defw    OSWsq
        defw    OSIsq
        defw    OSAxp
        defw    OSSci
        defw    OSDly
        defw    OSBlp
        defw    OSBde
        defw    CopyMemBHL_DE
        defw    OSFth
        defw    OSVth
        defw    OSGth
        defw    OSRen
        defw    OSDel
        defw    OSCl
        defw    OSOp
        defw    OSOff
        defw    OSUse
        defw    OSEpr
        defw    OSHt
        defw    OSMap
        defw    OSExit
        defw    OSStk
        defw    OSEnt
        defw    OSPoll
        defw    OSDom

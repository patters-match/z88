; **************************************************************************************************
; Display Token (MTH) interfaces.
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
; ***************************************************************************************************

        Module Token

        include "error.def"
        include "stdio.def"
        include "sysvar.def"

xdef    OSWtb
xdef    MayWrt
xdef    OSWrt

xref    PutOSFrame_BHL                          ; [Kernel0]/memmisc.asm
xref    FixPtr                                  ; [Kernel0]/memmisc.asm
xref    GetHlpTokens                            ; [Kernel0]/mth0.asm
xref    PrintChar                               ; [Kernel0]/mth0.asm
xref    fsMS2BankB                              ; [Kernel0]/filesys3.asm
xref    fsRestoreS2                             ; [Kernel0]/filesys3.asm



.OSWtb
        exx
        ld      bc, (eAppTokens_2+1)            ; ld b,(eAppTokens_2+2)
        ld      hl, (eAppTokens_2)              ; HL=address
        call    PutOSFrame_BHL
        exx

        ld      a, b                            ; if new base is zero then write as is
        or      h
        or      l
        jr      z, oswtb_2

        ld      a, b                            ; fix pointer if in bank 0
        or      a
        call    z, FixPtr

.oswtb_2
        ld      (eAppTokens_2+2), a             ; bank
        ld      (eAppTokens_2), hl              ; address
        cp      a
        ret

;       ----

.MayWrt
        cp      $20
        ret     c                               ; control char? return Fc=1

.OSWrt
        cp      1                               ; !! 'or a; jr z', 'scf' at EOF
        jr      c, wrt_4                        ; 0 - EOF

        push    hl
        cp      $7F
        jr      c, wrt_2                        ; 1-7e? print
        jr      nz, wrt_1                       ; 80-ff? token

        ld      a, 13                           ; 7f -> cr,lf
        OZ      OS_Out
        ld      a, 10
        jr      wrt_2

.wrt_1
        ld      e, a
        call    WrFarToken
        jr      nc, wrt_3                       ; already handled
        jr      nz, wrt_2                       ; print new char
        ld      a, e                            ; print old char
.wrt_2
        OZ      OS_Out                          ; write a byte to std. output
.wrt_3
        pop     hl
        or      a
        ret

.wrt_4
        ld      a, RC_Eof                       ; !! is this necessary?
        ret

;       ----

.WrFarToken

        call    GetHlpTokens
        ld      a, b
        or      h
        or      l
        scf
        ret     z                               ; no tokens? Fc=1, Fz=1

        set     7, h                            ; S2 fix
        call    fsMS2BankB
        call    WriteToken
        call    fsRestoreS2                     ; restore S2
        ld      a, $7F-1                        ; A=7F, Fz=0, Fc=0
        inc     a
        ret

;       ----

.WriteToken
        ld      b, h                            ; BC=token base
        ld      c, l
        push    de
        ld      hl, 0
        call    Get2TokenChars                  ; A=#tokens
        pop     de
        ld      d, e                            ; token to print
        res     7, d                            ; D=D-127
        inc     d
        cp      d
        ret     c                               ; not enough tokens in table

        push    de
        ld      l, d
        add     hl, hl
        call    Get2TokenChars                  ; DE=token start
        push    de
        call    Get2TokenChars                  ; D=token end
        ex      de, hl
        pop     de
        or      a
        sbc     hl, de
        ld      a, l                            ; token length
        ex      de, hl                          ; token start
        pop     de
        ret     z                               ; length=0? exit

        push    de
        ld      e, a                            ; length
        ld      a, (bc)                         ; recursive token boundary
        rla
        jr      c, wrto_1                       ; bit7 set, Fc=1
        rra
        cp      d                               ; Fc=1 if recursive
.wrto_1
        push    af
.wrto_2
        call    GetTokenChar
        cp      $7F                             ; 7f -> crlf
        jr      nz, wrto_3
        ld      a, 13
        OZ      OS_Out                          ; write a byte to std. output
        ld      d, 10
.wrto_3
        pop     af                              ; restore flags
        push    af
        ld      a, d                            ; restore char
        call    nc, PrintChar                   ; not recursive, print - Fc=0 on return
        push    bc
        push    de
        call    c, OSWrt                        ; recursive call
        pop     de
        pop     bc
        dec     e                               ; loop until length done
        jr      nz, wrto_2
        pop     de
        pop     af
        or      a
        ret

;       ----

.Get2TokenChars
        call    GetTokenChar
        ld      e, a

.GetTokenChar
        push    hl
        add     hl, bc
        ld      d, (hl)
        ld      a, d
        pop     hl
        inc     hl
        ret


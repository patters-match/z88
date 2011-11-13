; **************************************************************************************************
; Linked list Management API (GN_Xdl, GN_Xin, GN_Xnx)
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
; (C) Thierry Peycru (pek@users.sf.net), 2005,2006
; (C) Gunther Strube (gbs@users.sf.net), 2005,2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; ***************************************************************************************************

        Module GNList

        include "memory.def"
        include "error.def"
        include "oz.def"
        include "z80.def"

;       ----

xdef    GNXdl
xdef    GNXin
xdef    GNXnx

;       ----

xref    GN_ret1a
xref    Ld_cde_BHL
xref    PtrXOR
xref    SetListHdrs

;       ----

;       index next entry in linked list
;
;IN:    BHL=current entry, CDE=previous entry
;OUT:   BHL=next entry, CDE=new previous entry (=BHL(in)), Fz=1 if BHL=0
;       Fc=1, A=error
;
;CHG:   AFBCDEHL/....


.GNXnx
        ld      a, b
        or      h
        or      l
        ld      a, RC_Eof                       ; !! 'scf' here
        jr      z, xnx_x                        ; BHL=0? EOF
        ld      (iy+OSFrame_C), b               ; CDE(out)=BHL(in)
        ld      (iy+OSFrame_D), h
        ld      (iy+OSFrame_E), l
        call    PtrXOR
        ld      (iy+OSFrame_L), e               ; return CDE^(BHL)
        ld      (iy+OSFrame_H), d
        ld      (iy+OSFrame_B), c
        exx                                     ; main registers
        or      (iy+OSFrame_H)                  ; !! A=e' from PtrXOR so this
        or      (iy+OSFrame_L)                  ; !! doesn't work
        scf
.xnx_x
        ccf
        jp      GN_ret1a

;       ----

;       insert an entry into a linked list
;
;IN:    HL = pointer to a 9-byte parameter block
;       (HL+0)..(HL+2) entry to insert
;       (HL+3)..(HL+5) previous entry
;       (HL+6)..(HL+8) next entry

.GNXin
        push    ix
        ld      ix, -18                         ; reserve space for
        add     ix, sp                          ; three list headers
        ld      sp, ix

        ld      b, 0                            ; bind parameter block in
        OZ      OS_Bix
        push    de

;       use DE as destination pointer, 3*ldir

        ld      a, (hl)                         ; ix[new][address]=new
        ld      (ix+0), a
        inc     hl
        ld      a, (hl)
        ld      (ix+1), a
        inc     hl
        ld      a, (hl)
        ld      (ix+2), a
        inc     hl

        ld      e, (hl)                         ; ix[prev][address]=CDE=prev
        ld      (ix+6), e
        inc     hl
        ld      d, (hl)
        ld      (ix+7), d
        inc     hl
        ld      c, (hl)
        ld      (ix+8), c
        inc     hl

        ld      a, (hl)                         ; ix[next][address]=next
        ld      (ix+12), a
        inc     hl
        ld      a, (hl)
        ld      (ix+13), a
        inc     hl
        ld      a, (hl)
        ld      (ix+14), a

        ex      de, hl
        pop     de                              ; restore binding
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        ex      de, hl                          ; CDE=prev

        ld      a, (ix+0)                       ; new=0? bad args
        or      (ix+1)                          ; !! check this first
        or      (ix+2)
        jr      nz, xin_1
        set     Z80F_B_C, (iy+OSFrame_F)
        ld      (iy+OSFrame_A), RC_Bad
        jp      xin_x

.xin_1
        ld      l, (ix+12)                      ; BHL=next
        ld      h, (ix+13)
        ld      b, (ix+14)

        ld      c, (ix+8)                       ; !! unnecessary

        ld      a, e                            ; ix[new][link]=next^prev
        xor     l
        ld      (ix+3), a
        ld      a, d
        xor     h
        ld      (ix+4), a
        ld      a, c
        xor     b
        ld      (ix+5), a

        ld      a, (ix+2)                       ; ix[next][link]=new^prev
        push    af
        xor     c
        ld      (ix+17), a
        pop     af                              ; ix[prev][link]=new^next
        xor     b
        ld      (ix+11), a

        ld      a, (ix+1)
        push    af
        xor     d
        ld      (ix+16), a
        pop     af
        xor     h
        ld      (ix+10), a

        ld      a, (ix+0)
        push    af
        xor     e
        ld      (ix+15), a
        pop     af
        xor     l
        ld      (ix+9), a

        ld      a, b
        push    af
        push    hl

        ld      b, c                            ; BHL=CDE=prev
        ld      h, d
        ld      l, e
        ld      a, l
        or      h
        or      b
        jr      z, xin_2                        ; prev=0? skip

        call    Ld_cde_BHL
        ld      a, c                            ; ix[prev][link] = new^next^(prev)
        xor     (ix+11)
        ld      (ix+11), a
        ld      a, d
        xor     (ix+10)
        ld      (ix+10), a
        ld      a, e
        xor     (ix+9)
        ld      (ix+9), a
        exx
.xin_2
        pop     hl                              ; BHL=next
        pop     af
        ld      b, a
        or      h
        or      l
        jr      z, xin_3                        ; next=0? skip

        call    Ld_cde_BHL
        ld      a, c                            ; ix[next][link] = new^prev^(next)
        xor     (ix+17)
        ld      (ix+17), a
        ld      a, d
        xor     (ix+16)
        ld      (ix+16), a
        ld      a, e
        xor     (ix+15)
        ld      (ix+15), a
        exx

.xin_3
        push    ix
        pop     hl
        ld      c, 3                            ; write three list headers
        call    SetListHdrs

.xin_x
        ld      ix, 18                          ; restore stack and exit
        add     ix, sp
        ld      sp, ix
        pop     ix
        ret

;       ----

;       delete an entry from a linked list
;
;IN:    BHL=entry to delete, CDE=previous entry
;OUT:   BHL=next entry, CDE=previous entry (=BHL(in)), Fz=1 if BHL=0
;       Fc=1, A=error

.GNXdl
        ld      a, b                            ; no entry to delete? bad args
        or      h
        or      l
        jp      z, xdl_3

        call    PtrXOR                          ; prev^(this) = next
        push    ix
        ld      ix, -18                         ; reserve space for
        add     ix, sp                          ; three list headers
        ld      sp, ix

        ld      (iy+OSFrame_L), e               ; BHL(out)=next
        ld      (iy+OSFrame_H), d
        ld      (iy+OSFrame_B), c

        ld      (ix+12), e                      ; ix[next][address]=next
        ld      (ix+13), d
        ld      (ix+14), c

        ld      a, c                            ; remember next
        push    af
        push    de
        exx

        ld      a, c                            ; BHL=prev, CDE=this
        ld      c, b
        ld      b, a
        ex      de, hl
        or      h
        or      l
        jr      z, xdl_1                        ; prev=0? skip

        ld      (ix+6), l                       ; ix[prev][address]=prev
        ld      (ix+7), h
        ld      (ix+8), b
        call    PtrXOR                          ; this^(prev)
        ld      a, e                            ; ix[prev][link] = this^(prev)^next
        xor     (iy+OSFrame_L)
        ld      (ix+9), a
        ld      a, d
        xor     (iy+OSFrame_H)
        ld      (ix+10), a
        ld      a, c
        xor     (iy+OSFrame_B)
        ld      (ix+11), a

        exx
.xdl_1
        pop     hl                              ; BHL=next
        pop     af
        ld      b, a
        or      h
        or      l
        jr      z, xdl_2                        ; next=0? skip

        call    PtrXOR                          ; this^(next)
        ld      a, e                            ; ix[next][link] = this^(next)^prev
        xor     (iy+OSFrame_E)
        ld      (ix+15), a
        ld      a, d
        xor     (iy+OSFrame_D)
        ld      (ix+16), a
        ld      a, c
        xor     (iy+OSFrame_C)
        ld      (ix+17), a
        exx

.xdl_2
        push    ix
        pop     hl
        ld      de, 6
        add     hl, de
        ld      c, 2                            ; write two list headers
        call    SetListHdrs

        ld      ix, 18                          ; restore stack and exit
        add     ix, sp
        ld      sp, ix
        pop     ix
        jr      xdl_x

.xdl_3
        set     Z80F_B_C, (iy+OSFrame_F)
        ld      (iy+OSFrame_A), RC_Bad

.xdl_x
        ret

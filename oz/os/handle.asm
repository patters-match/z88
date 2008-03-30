; **************************************************************************************************
; Handle functions
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

        Module Handle

        include "error.def"
        include "handle.def"
        include "sysvar.def"

xdef    OSGth
xdef    OSFth
xdef    OSVth
xdef    OSFn
xdef    ResetHandles
xdef    FreeHandle
xdef    AllocHandle
xdef    ZeroHandleIX
xdef    FindHandle
xdef    ChgHandleType
xdef    VerifyHandle

xref    OSFramePush                             ; [Kernel0]/stkframe.asm
xref    OSFramePop                              ; [Kernel0]/stkframe.asm
xref    PutOSFrame_HL                           ; [Kernel0]/stkframe.asm

; -----------------------------------------------------------------------------
;
;       allocate tri-handle
;IN:    A=subtype, B=func bank, H=func page, L=func segment
;OUT:   Fc=0, IX=handle
;       Fc=1, A=error
;chg:   AF....../IX..
;
; -----------------------------------------------------------------------------

.OSGth
        ld      c, a
        ld      a, HND_TRHN
        call    AllocHandle
        ret     c                               ; error? exit

        ld      (ix+thnd_SubType), c
        ld      (ix+thnd_Bank), b
        ld      (ix+thnd_AddrH), h
        ld      (ix+thnd_Segment), l
        ret

; -----------------------------------------------------------------------------
;
; free tri-handle
;IN:    IX=handle, A=type
;OUT:   Fc=0
;       Fc=1, A=error
;
; -----------------------------------------------------------------------------

.OSFth
        call    OSVth                           ; verify
        ret     c                               ; error? exit
        jr      FreeHandle                      ; go free it

; -----------------------------------------------------------------------------
;
; verify tri-handle
;IN:    IX=handle, A=type
;OUT:   Fc=0, B=bank, H=page, L=segment
;       Fc=1, A=error
;
; -----------------------------------------------------------------------------

.OSVth
        cp      (ix+thnd_SubType)
        ld      a, RC_Hand
        scf
        ret     nz                              ; type mismatch? exit

        ld      a, HND_TRHN
        call    VerifyHandle
        ret     c                               ; bad handle? exit

        ld      b, (ix+thnd_Bank)               ; return BHL  !! use PutOSFrame_BHL
        ld      (iy+OSFrame_B), b
        ld      h, (ix+thnd_AddrH)
        ld      l, (ix+thnd_Segment)
        jp      PutOSFrame_HL

;       ----


.ResetHandles
        ld      ix, Handles                     ; handles in $0500-$0bff
        ld      b, NUMHANDLES                   ; 96 handles (6 pages of 16 handles)
.rsthn_1
        ld      de, (pFirstHandle)              ; get previous handle  !! use registers inside loop
        ld      (ix+hnd_Next), e                ; link this to prev
        ld      (ix+hnd_Next+1), d
        xor     a
        ld      (ix+hnd_Type), a                ; mark as free
        ld      (ix+hnd_DynID), a
        ld      (pFirstHandle), ix              ; make this previous
        ld      de, hnd_SIZEOF                  ; advance to next and loop if handles left
        add     ix, de
        djnz    rsthn_1
        ret

;       ----

;IN:    IX=handle, A=type
;OUT:   Fc=0, IX=0
;       Fc=1, A=error

.FreeHandle
        push    hl
        cp      (ix+hnd_Type)
        jr      nz, fhnd_1                      ; type mismatch? exit

        push    ix                              ; verify low 4 bits - always zero
        pop     hl
        ld      a, l
        and     $0F
.fhnd_1
        ld      a, RC_Hand
        scf
        jr      nz, fnd_2                       ; error? exit

        call    ZeroHandle
        ld      ix, 0

.fnd_2
        pop     hl
        ret

;       ----

;IN:    A=type
;OUT:   Fc=0, IX=handle
;       Fc=1, A=error
;chg:   AF....../IX..

.AllocHandle

        push    bc
        push    hl
        ld      b, a                            ; !! should verify it's non-zero

        ld      hl, (pFirstHandle)              ; first handle  !! ld hl, Firsthandle to optimize jump
.ahnd_1
        ld      a, h
        or      l
        ld      a, RC_Room
        scf
        ld      ix, 0
        jr      z, ahnd_3                       ; no more handles? exit

        push    hl                              ; !! do this before branch to remove ld ix,0
        pop     ix
        ld      a, (ix+hnd_Type)
        or      a
        jr      z, ahnd_2                       ; found free? init and return

        ld      l, (ix+hnd_Next)                ; check next
        ld      h, (ix+hnd_Next+1)
        jr      ahnd_1

.ahnd_2
        call    ZeroHandle                      ; clear all fields
        ld      (ix+hnd_Type), b                ; set type and DynID
        ld      a, (ubAppDynID)
        ld      (ix+hnd_DynID), a

.ahnd_3
        pop     hl
        pop     bc
        ret

;       ----

;       clear handle except link

;IN:    IX=HANDLE

.ZeroHandleIX
        push    ix
        pop     hl

;IN:    HL=HANDLE

.ZeroHandle
        push    bc
        inc     hl                              ; skip link, clear rest of handle
        inc     hl
        ld      bc, [16-2] << 8
        or      a                               ; Fc=0, but A unchanged
.zhnd_1
        ld      (hl), c
        inc     hl
        djnz    zhnd_1
        pop     bc
        ret

;       ----

;in:    IX=handle, if 0 then start from beginning
;       B=type, C=DynID to match - if 0 then it's not checked
;out:   IX=handle, DE incremented for each free handle

.FindHandle
        push    hl

        push    ix                              ; if IX=0 start from first
        pop     hl
        ld      a, h
        or      l
        jr      nz, fndh_6
        ld      hl, (pFirstHandle)

.fndh_1
        ld      a, h
        or      l
        ld      a, RC_Eof
        scf
        jr      z, fndh_4                       ; no more handles? EOF

        push    hl
        pop     ix
        ld      a, (ix+hnd_Type)
        or      a
        jr      z, fndh_5                       ; free? inc DE and skip

        inc     b                               ; compare B to type if not zero
        dec     b
        jr      z, fndh_2
        ld      a, (ix+hnd_Type)
        cp      b
        jr      nz, fndh_6

.fndh_2
        inc     c                               ; compare C to DynID if not zero
        dec     c
        jr      z, fndh_3
        ld      a, (ix+hnd_DynID)
        cp      c
        jr      nz, fndh_6

.fndh_3
        or      a                               ; Fc=0
.fndh_4
        pop     hl
        ret
.fndh_5
        inc     de                              ; increment free count
.fndh_6
        ld      l, (ix+hnd_Next)                ; jump to next handle
        ld      h, (ix+hnd_Next+1)
        jr      fndh_1

;       ----

;IN:    IX=handle, A=old type, B=new type
;OUT:   Fc=0 if ok
;       Fc=1, A=error

.ChgHandleType
        call    VerifyHandle
        ret     c                               ; bad handle? exit
        ld      (ix+hnd_Type), b
        ret

;       ----

;       verify handle
;IN:    IX=handle, A=type
;OUT:   Fc=0, handle ok
;       Fc=1, A=error  Fz=1 if special (<256) handle

.VerifyHandle
        push    hl
        push    ix
        pop     hl
        inc     h
        dec     h
        pop     hl
        jr      z, vfhn_1                       ; handle <256? error Fz=1
        cp      (ix+hnd_Type)
        ret     z                               ; type ok? return Fc=0
.vfhn_1
        ld      a, RC_Hand
        scf
        ret

; -----------------------------------------------------------------------------
;
;       miscellaneous OS functions
;IN:    A=reason
;
; -----------------------------------------------------------------------------

.OSFn
        call    OSFramePush
        ld      h, b                            ; exg a,b
        ld      b, a
        ld      a, h
        call    osfn_ah
        jp      OSFramePop

.osfn_ah
        djnz    osfn_vh

;       FN_AH, allocate handle

;IN:    B=type
;OUT:   Fc=0, IX=handle
;       Fc=1, A=error

        jp      AllocHandle

.osfn_vh
        djnz    osfn_fh

;       FN_VH, verify handle
;IN:    IX=handle, B=type
;OUT:   Fc=0 if OK
;       Fc=1, A=error

        jp      VerifyHandle

.osfn_fh
        djnz    osfn_unk

;       FN_FH, free handle
;IN:    IX=handle, B=type
;OUT:   Fc=0 if OK
;       Fc=1, A=error

        jp      FreeHandle

.osfn_unk
        ld      a, RC_Unk
        scf
        ret

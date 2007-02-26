; **************************************************************************************************
; DOR Interface.
; The routines are located in Bank 0.
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

        Module DOR

        include "dor.def"
        include "error.def"
        include "handle.def"
        include "sysvar.def"

xdef    DORHandleFree                           ; get rid of these two stubs
xdef    DORHandleFreeDirect
xdef    DORHandleInUse
xdef    GetHandlePtr
xdef    GetDORType
xdef    OSDor
xdef    VerifyHandleBank


xref    _MS2BankA                               ; bank0/filesys2.asm
xref    MS2HandleBank                           ; bank0/filesys2.asm
xref    AddAvailableFsBlock                     ; bank0/filesys3.asm
xref    AllocHandleBlock                        ; bank0/filesys3.asm
xref    FreeMemData                             ; bank0/filesys3.asm
xref    MemPtr2FilePtr                          ; bank0/filesys3.asm
xref    AllocHandle                             ; bank0/handle.asm
xref    FindHandle                              ; bank0/handle.asm
xref    FreeHandle                              ; bank0/handle.asm
xref    VerifyHandle                            ; bank0/handle.asm
xref    ClearMemHL_A                            ; bank0/misc5.asm
xref    CopyMemDE_HL                            ; bank0/misc5.asm
xref    CopyMemHL_DE                            ; bank0/misc5.asm
xref    GetOSFrame_DE                           ; bank0/misc5.asm
xref    MS2BankA                                ; bank0/misc5.asm
xref    MS2BankB                                ; bank0/misc5.asm
xref    PeekHL                                  ; bank0/misc5.asm
xref    PeekHLinc                               ; bank0/misc5.asm
xref    PutOSFrame_BC                           ; bank0/misc5.asm
xref    OSFramePop                              ; bank0/misc4.asm
xref    OSFramePush                             ; bank0/misc4.asm

xref    InitHandle                              ; bank7/misc1.asm



.OSDor
        call    OSFramePush
        ld      b, a                            ; reason code
        call    OSDorMain
        jp      OSFramePop

.OSDorMain
        djnz    osdor_dup

;IN:    HL=name
;OUT:   Fc=0, IX=handle, A=device DOR type
;       Fc=1, A=error

.OSDor_GET
        call    PeekHLinc
        cp      ':'
        jr      nz, dorget_err
        call    PeekHL
        or      a
        jr      nz, dorget_err                  ; name not ":",0

        ld      a, HND_DEV
        call    AllocHandle
        ret     c                               ; couldn't get handle? exit

        xor     a
.dorget_1
        call    InitHandle
        jp      c, dorfre_eof
        ld      (iy+OSFrame_A), a               ; return DOR type
        ret

.dorget_err
        ld      a, RC_Fail
        scf
        ret

.osdor_dup
        djnz    osdor_sib

;IN:    IX=handle
;OUT:   Fc=0, BC=handle
;       Fc=1, A=error

        ld      bc, 0                           ; !! ld c,b
        call    PutOSFrame_BC                   ; prepare return value
        call    VerifyHandleBank
        ret     c                               ; bad handle? exit

        push    ix                              ; remember handle
        pop     de                              ; also copies into DE

        ld      a, HND_DEV
        call    AllocHandle
        ret     c                               ; couldn't get handle? exit

        push    ix                              ; HL=newHandle
        pop     hl
        push    de                              ; restore handle
        pop     ix

        ld      b, h
        ld      c, l
        call    PutOSFrame_BC                   ; return handle in BC

        ld      bc, hnd_DynID+1                 ; skip link, type and DynID
        add     hl, bc
        ex      de, hl
        add     hl, bc
        ld      bc, hnd_SIZEOF-(hnd_DynID+1)    ; and copy rest
        ldir
        or      a                               ; Fc=0
        ret

.osdor_sib
        djnz    osdor_son

;IN:    IX=handle
;OUT:   Fc=0, IX=brother, A=DOR type
;       Fc=1, A=error

;       Fc=1, A=error

        call    VerifyHandleBank
        ret     c                               ; bad handle? exit

        bit     HND_B_DEV, (ix+hnd_Flags)     ; !! reorder code to save one jr
        jr      nz, dorsib_1                    ; device? change type

        ld      bc, DOR_BROTHER                 ; DOR_BROTHER
        jr      dorson_1                        ; go get it

.dorsib_1
        ld      a, (ix+dhnd_DeviceID)           ; incremented in InitHandle
        jr      dorget_1                        ; go change type

.osdor_son
        djnz    osdor_fre0

;IN:    IX=handle
;OUT:   Fc=0, IX=son, A=DOR type
;       Fc=1, A=error

        call    VerifyHandleBank
        ret     c                               ; bad handle? exit

        ld      bc, DOR_SON                     ; DOR_SON
.dorson_1
        call    GetHandlePtr                    ; !! already checked, call 4 bytes higher to skip check
        ret     c                               ; bad handle? exit  !! can't happen

        add     hl, bc
        ld      e, (hl)                         ; son/brother ptr into BHL
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        ex      de, hl

        inc     b
        dec     b
        jr      z, dorfre_eof                   ; bank=0? free and EOF

;       !! fix this if you want applications in slot 0

        ld      a, (ix+dhnd_AppSlot)
        or      a
        jr      z, dorson_2                     ; not application

        ld      a, b                            ; fix slot
        and     $3F
        or      (ix+dhnd_AppSlot)
        ld      b, a
.dorson_2
        call    PutHandleBHL_S2                 ; put BHL, fix for S2 addressing

        call    MS2HandleBank
        res     HND_B_DEV, (ix+hnd_Flags)      ; not device
        ld      bc, DOR_TYPE
        add     hl, bc
        ld      a, (hl)
        ld      (iy+OSFrame_A), a               ; return DOR type
        or      a                               ; Fc=0
        ret

.osdor_fre0
        djnz    osdor_cre

;IN:    IX=handle
;OUT:   Fc=0, IX=0
;       Fc=1, A=error

.OSDor_FRE
        ld      a, HND_DEV
        jp      FreeHandle

.dorfre_eof
        call    OSDor_FRE
        ret     c                               ; error? exit
        ld      a, RC_Eof                       ; else EOF
        scf
        ret

.osdor_cre
        djnz    osdor_del

;IN:    IX=parent
;OUT:   Fc=0, IX=handle
;       Fc=1, A=error

        ld      a, (ix+hnd_Flags)
        push    af
        ld      a, HND_DEV
        call    AllocHandle
        pop     hl
        ret     c                               ; couldn't get handle? exit
        ld      (ix+fhnd_attr), h               ; parent flags

        call    AllocHandleBlock
        jr      c, DORHandleFree                ; error? exit

        call    PutHandleBHL_S2                 ; set BHL, fixed for S2 addressing
        call    MS2HandleBank                   ; and bind bank in

        ld      b, 3*3                          ; clear parent/brother/son pointers
.dorcre_1
        ld      (hl), 0
        inc     hl
        djnz    dorcre_1

        ld      a, (iy+OSFrame_B)               ; put DOR type
        ld      (hl), a
        inc     hl
        ld      (hl), 64-(DOR_LENGTH+1)         ; DOR total length
        inc     hl

        ld      d, h                            ; fill next $35 bytes with FF, terminator char
        ld      e, l
        inc     de
        ld      (hl), -1
        ld      bc, 64-(DOR_LENGTH+1)-1
        ldir
        or      a                               ; Fc=0
        ret

.DORHandleFree
        push    af                              ; !! call FreeHandle directly
        call    DORHandleFreeDirect
        pop     af
        ret

.DORHandleFreeDirect
        ld      a, HND_DEV                      ; !! get rid of this completely
        jp      FreeHandle

.osdor_del
        dec     b                               ; djnz doesn't reach far enough
        jp      nz, osdor_ins

        call    GetHandlePtr                    ; !! push/pop return to avoid multiple calls
        ret     c                               ; bad handle? exit

        call    DORHandleInUse
        jr      c, DORHandleFree                ; in use? free ??

        call    GetHandlePtr
        ld      bc, DOR_TYPE
        add     hl, bc
        ld      a, (hl)                         ; DOR type
        cp      DN_DIR
        jr      nz, dordel_1                    ; not dir? skip

        dec     hl                              ; if dir has any children it's in use
        ld      a, (hl)                         ; son bank
        or      a
        ld      a, RC_Use
        scf
        jr      nz, DORHandleFree               ; free and ret RC_Use

;       scan parent's all sons to unlink this DOR

.dordel_1
        call    GetHandlePtr
        ld      e, (hl)                         ; BHL=parent
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        ex      de, hl

        ld      de, DOR_SON                     ; son ptr
        jr      dordel_3

.dordel_2                                       ; entry from below
        pop     de
        pop     de
        ld      de, DOR_BROTHER                 ; brother ptr

.dordel_3
        add     hl, de
        push    hl                              ; prev ptr
        push    bc                              ; prev bank
        call    MS2BankB                        ; bind this in

        ld      e, (hl)                         ; BHL=brother (son on first call)
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        ex      de, hl

        inc     b                               ; no more entries? crash
        dec     b
        jr      z, $PC

        ld      a, l                            ; compare brother to one in handle
        cp      (ix+hnd_L)
        jr      nz, dordel_2
        ld      a, h
        cp      (ix+hnd_H)
        jr      nz, dordel_2
        ld      a, b
        cp      (ix+hnd_Bank)
        jr      nz, dordel_2                    ; no match? get next brother

        call    MS2BankA                        ; bind brother in
        call    MemPtr2FilePtr
        push    de                              ; push BHL as fileptr

        ld      de, DOR_BROTHER
        add     hl, de

        push    hl
        exx
        pop     hl
        ld      c, (hl)                         ; bdc=next DOR
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        inc     hl

        ld      e, (hl)                         ; el=son ptr
        inc     hl
        ld      a, (hl)
        inc     hl                              ; h=type
        inc     hl
        ld      h, (hl)
        ld      l, a
        exx

        pop     de                              ; fileptr
        pop     af                              ; bind in prev bank
        call    MS2BankA
        exx
        ld      a, l
        ex      (sp), hl                        ; push son_type|son_low, pop previous

        ld      (hl), c                         ; remove - point previous to next
        inc     hl
        ld      (hl), d
        inc     hl
        ld      (hl), b

        ld      d, a                            ; son_low - for FreeMemData

        pop     af                              ; son_type
        push    af
        cp      DN_FIL                          ; file or directory? free data
        jr      z, dordel_5
        cp      DN_DIR
.dordel_5
        call    z, FreeMemData

        call    GetHandlePtr                    ; !! it would be faster to do these only for fil/dir
        ld      b, a                            ; bank
        call    MemPtr2FilePtr                  ; for AddAvailableFsBlock

        pop     af                              ; son_type
        cp      DN_FIL                          ; file or directory? make block available
        jr      z, dordel_6
        cp      DN_DIR
.dordel_6
        call    z, AddAvailableFsBlock

        ld      a, HND_DEV
        jp      FreeHandle

.osdor_ins
        djnz    osdor_rd0

; link IX as son of BC

        push    ix                              ; IX=hndS
        ld      b, (iy+OSFrame_B)               ; BC=hndP

        push    bc
        pop     ix
        call    VerifyHandleBank                ; hndP
        pop     ix
        ret     c                               ; bad handle? exit

        call    VerifyHandleBank                ; hndS
        ret     c                               ; bad handle? exit

        push    iy
        push    bc
        pop     iy                              ; IY=hndP

        ld      a, (iy+hnd_Bank)                ; bind in hndP DOR
        call    _MS2BankA                       ; !! MS2BankA
        ld      h, (iy+hnd_H)                   ; push parent's son_ptr address
        ld      l, (iy+hnd_L)
        ld      bc, DOR_SON
        add     hl, bc
        push    af                              ; bank
        push    hl                              ; ptr

        ld      e, (hl)                         ; push parent's son
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      c, (hl)
        push    bc                              ; bank
        push    de                              ; ptr

        ld      bc, -(DOR_SON+2)                ; CDE=hndP
        add     hl, bc                          ; back to DOR start
        ex      de, hl
        ld      c, a

        call    MS2HandleBank                   ; bind in hndS DOR
        ld      h, (ix+hnd_H)                   ; HL=DOR
        ld      l, (ix+hnd_L)

        ld      (hl), e                         ; hndS parent=hndP
        inc     hl
        ld      (hl), d
        inc     hl
        ld      (hl), c
        inc     hl

        pop     de                              ; pop parent's son
        pop     bc
        ld      (hl), e                         ; hndS brother=hndP son
        inc     hl
        ld      (hl), d
        inc     hl
        ld      (hl), c

        ld      de, -(DOR_BROTHER+2)            ; back to beginning
        add     hl, de
        ld      c, a                            ; CDE=hndS
        ex      de, hl

        pop     hl                              ; pop parent's son_ptr
        pop     af
        call    _MS2BankA                       ; !! MS2BankA
        ld      (hl), e                         ; hndP son=hndS
        inc     hl
        ld      (hl), d
        inc     hl
        ld      (hl), c

        pop     iy
        or      a                               ; Fc=0
        ret

.osdor_rd0
        djnz    osdor_wr

.OSDor_RD
        call    GetHandlePtr
        ret     c                               ; bad handle? exit

        ld      a, (iy+OSFrame_B)
        cp      1
        call    z, dorrd_1                      ; record 1 - son
        call    nz, FindDORRecord
        ret     c                               ; no record? exit

        ld      a, (iy+OSFrame_C)               ; get buffer size
        ld      (iy+OSFrame_C), c               ; put record length
        cp      c
        jr      nc, dorrd_2
        ld      a, RC_Eof                       ; EOF, data doesn't fit
        scf
        ret

.dorrd_1
        ld      bc, DOR_SON
        add     hl, bc                          ; son pointer
        ld      c, 2                            ; two bytes
        ret
.dorrd_2
        ex      de, hl                          ; HL=destination, DE=source
        ld      b, a                            ; don't clear if caller A=$0B
        ld      a, (iy+OSFrame_A)               ; !! is this used anywhere?
        cp      $0B
        ld      a, b
        call    nz, ClearMemHL_A
        or      a                               ; Fc=0
        jp      CopyMemDE_HL

.osdor_wr
        djnz    dorwr_4

;IN:    B=record type, C=data length, DE=data ptr

        call    GetHandlePtr
        ret     c                               ; bad handle? exit

        ld      a, (iy+OSFrame_B)
        cp      1
        jr      z, dorwr_1                      ; record 1 - son pointer

        call    FindDORRecord
        jr      c, dorwr_2                      ; no record? create it

        ld      a, (iy+OSFrame_C)               ; get data size
        ld      (iy+OSFrame_C), c               ; put old size
        cp      c
        jr      z, dorwr_3
        ld      a, RC_Fail                      ; data doesn't match in size
        scf
        ret

.dorwr_1
        ld      bc, DOR_SON+2
        add     hl, bc
        ld      (hl), 0                         ; bank 0
        dec     hl
        dec     hl                              ; son ptr
        ld      c, 2                            ; two bytes
        jr      dorwr_3                         ; copy DE->HL

.dorwr_2
        ret     nz                              ; bad DOR? exit

        push    hl                              ; end mark

        ld      h, (ix+hnd_H)
        ld      l, (ix+hnd_L)
        ld      bc, DOR_LENGTH
        add     hl, bc
        ld      c, (hl)                         ; total DOR length
        ld      b, 0
        inc     hl                              ; + one for terminator? !! remove inc/dec pair
        add     hl, bc
        dec     hl                              ; - one for record type?
        dec     hl                              ; - one for record length?
        dec     hl                              ; - one for terminator?
        pop     bc                              ; - current end
        sbc     hl, bc                          ; space left in DOR
        ld      a, RC_Fail
        ret     c                               ; bad DOR? exit  !! catch in FindDORRecord

        ld      a, l                            ; bytes left for data

        push    bc                              ; HL=current end
        pop     hl

        ld      c, (iy+OSFrame_C)               ; data length
        cp      c
        ld      a, RC_Room
        ret     c                               ; data doesn't fit? exit

        ld      a, (iy+OSFrame_B)               ; put record type and length
        ld      (hl), a
        inc     hl
        ld      (hl), c                         ; record length
        inc     hl

.dorwr_3
        ex      de, hl
        or      a
        jp      CopyMemHL_DE                    ; copy data

.dorwr_4
        djnz    osdor_err

.OSDor_RD2
        jp      OSDor_RD                        ; just use dor_rd

.osdor_err
        ld      a, RC_Unk
        scf
        ret

;       ----

;IN:    HL=DOR, callerB=type
;OUT:   Fc=0, HL=record, C=record length
;       Fc=1, no record found - also Fz=0 if DOR invalid

.FindDORRecord

        ld      bc, DOR_LENGTH
        add     hl, bc
        ld      a, (hl)                         ; total DOR length
        inc     hl                              ; first record
        ex      af, af'

.fdr_1
        ld      a, (hl)                         ; record type
        inc     hl
        ld      c, (hl)                         ; record length
        inc     hl
        cp      -1
        jr      z, fdr_2                        ; DOR terminator? exit Fc=1 Fz=1

        ex      af, af'
        sub     2                               ; 2 bytes for type/length
        jr      c, fdr_2                        ; underflow? exit Fc=1 Fz=0
        sub     c                               ; C bytes for this record
        jr      c, fdr_2                        ; underflow? exit Fc=1 Fz=0
        ex      af, af'

        cp      (iy+OSFrame_B)                  ; compare type
        jr      z, fdr_3                        ; match? return Fc=0

        ld      b, 0                            ; skip record and loop
        add     hl, bc
        jr      fdr_1

.fdr_2
        dec     hl                              ; back to terminator
        dec     hl
        ld      a, RC_Fail
        scf
.fdr_3
        ret

;       ----

.GetHandlePtr
        call    VerifyHandleBank
        ret     c                               ; bad handle? exit
        call    MS2HandleBank                   ; bind it in S2

        ld      h, (ix+hnd_H)                   ; get pointer into HL
        ld      l, (ix+hnd_L)
        set     7, h                            ; S2 fix
        res     6, h
        or      a
        jp      GetOSFrame_DE                   ; get caller DE

;       ----

;       check if another device/file has same BHL

.DORHandleInUse
        ld      bc, HND_DEV<<8|0                ; scan devices, no DynID check
        call    hiu_1
        ret     c
        ld      bc, HND_FILE<<8|0               ; scan files, no DynID check
        call    hiu_1                           ; !! just drop thru
        ret

.hiu_1
        push    iy
        push    ix
        pop     iy
        ld      ix, 0
.hiu_2
        call    FindHandle
        jr      c, hiu_3                        ; no more entries? exit Fc=0

        push    ix                              ; HL=IX, DE=IY
        pop     hl
        push    iy
        pop     de

        or      a                               ; Fc=0  !! unnecessary
        sbc     hl, de
        jr      z, hiu_2                        ; same? skip

        ld      a, (ix+hnd_L)                   ; compare handle BHLs
        cp      (iy+hnd_L)
        jr      nz, hiu_2
        ld      a, (ix+hnd_H)
        cp      (iy+hnd_H)
        jr      nz, hiu_2
        ld      a, (ix+hnd_Bank)
        cp      (iy+hnd_Bank)
        jr      nz, hiu_2

        ld      a, RC_Use                       ; two handles have same BHL

.hiu_3
        ccf
        push    iy
        pop     ix
        pop     iy
        ret

;       ----

;IN:    BHL=DOR
;OUT:   A=DOR type, Fz=1 if A=0
;chg:   AFBC..HL/....

.GetDORType
        call    MS2BankB
        ld      bc, DOR_TYPE
        add     hl, bc
        ld      a, (hl)                         ; DMDEV/ROM/RAM
        or      a
        ret
;       ----

.PutHandleBHL_S2
        set     7, h                            ; S2 fix
        res     6, h
        ld      (ix+hnd_Bank), b
        ld      (ix+hnd_H), h
        ld      (ix+hnd_L), l
        ret

;       ----

.VerifyHandleBank
        ld      a, HND_DEV
        call    VerifyHandle
        ret     c
        inc     (ix+hnd_Bank)
        dec     (ix+hnd_Bank)
        ret     nz
        jr      $PC                             ; crash if bank is zero



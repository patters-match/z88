; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $d3fd
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNMemory

        org $d3fd                               ; 191 bytes

        include "all.def"
        include "sysvar.def"

xdef    GNWbe
xdef    Ld_BDE_A
xdef    GNRbe
xdef    Ld_A_BHL
xdef    GNCme

defc    GnClsMain       =$eec1


;       !! Memory routines can be made quite a lot faster
;
;       Also worth considering are routines to write multiple bytes
;       with one call - Ld_ade_BHL, Ld_BHL_ade etc.

;       ----

;       write byte at extended address
;
;IN:    A=byte, BDE=address
;OUT:   -
;
;CHG:   .F....../....

.GNWbe
        call    Ld_BDE_A
        ret

;       ----

;IN:    A=byte, BDE=address
;OUT:   -
;CHG:   .F....../....

.Ld_BDE_A
        push    bc
        push    de
        push    af
        inc     b
        dec     b
        jr      nz, lbdea_3                     ; B>0? far pointer

        ld      a, d
        and     $C0
        cp      $C0                             ; check S3
        jr      nz, lbdea_1
        ld      b, (iy+OSFrame_S3)
        jr      lbdea_3
.lbdea_1
        cp      $80                             ; check S2
        jr      nz, lbdea_2
        ld      b, (iy+OSFrame_S2)
        jr      lbdea_3

.lbdea_2
        pop     af                              ; local pointer, just write
        push    af
        ld      (de), a
        jr      lbdea_4

.lbdea_3
        ld      c, 1                            ; bind needed bank in S1
        OZ      OS_Mpb
        ld      a, d                            ; S1 fix
        and     $3F
        or      $40
        ld      d, a
        pop     af
        push    af
        ld      (de), a                         ; store byte
        OZ      OS_Mpb                          ; restore S1
.lbdea_4
        pop     af
        pop     de
        pop     bc
        ret

;       ----

;       read byte at extended address
;
;IN:    BHL=address (B=0: local address)
;OUT:   A=byte
;
;CHG:   AF....../....


.GNRbe
        call    Ld_A_BHL
        ld      (iy+OSFrame_A), a
        ret

;       ----

;IN:    BHL=address (B=0: local address)
;OUT:   A=byte
;CHG:   AF....../....

.Ld_A_BHL
        push    bc
        inc     b                               ; B>0? far pointer
        dec     b
        jr      nz, labhl_3
        ld      a, h
        and     $C0
        cp      $C0                             ; check S3
        jr      nz, labhl_1
        ld      b, (iy+OSFrame_S3)
        jr      labhl_3
.labhl_1
        cp      $80                             ; check S2
        jr      nz, labhl_2
        ld      b, (iy+OSFrame_S2)
        jr      labhl_3

.labhl_2
        ld      a, (hl)                         ; local pointer, just read
        jr      labhl_4

.labhl_3
        ld      c, 1                            ; bind memory in S1
        OZ      OS_Mpb
        push    bc                              ; remember binding
        push    hl
        ld      a, h                            ; S1 fix
        and     $3F
        or      $40
        ld      h, a
        ld      a, (hl)                         ; read byte
        pop     hl
        pop     bc                              ; restore S1
        push    af
        OZ      OS_Mpb
        pop     af
.labhl_4
        pop     bc
        ret

;       ----

;       compare null-terminated strings, one local, one extended
;       comparison is case ignorant, "aaa" == "AAA"
;
;IN:    BHL=string1, DE=string2
;OUT:   Fz=1 if string are same
;
;CHG:   .F....../....

.GNCme
        inc     b
        dec     b
        jr      nz, cme_3                       ; BHL is not local
        ld      a, h
        and     $c0
        jr      z, cme_3                        ; S0 is ok

        cp      $40                             ; check S1
        jr      nz, cme_1
        ld      c, 1                            ; get S1 binding
        OZ      OS_Mgb
        jr      cme_3
.cme_1
        cp      $c0                             ; check S3
        jr      z, cme_2
        ld      b, (iy+OSFrame_S2)
        jr      cme_3
.cme_2
        ld      b, (iy+OSFrame_S3)
.cme_3
        push    hl                              ; remember BHL
        push    bc
        ex      de, hl                          ; bind in DE
        ld      b, 0                            ; 0DE in BHL
        OZ      OS_Bix
        pop     bc                              ; restore BHL, push binding
        ex      (sp), hl
        ex      de, hl
        ex      (sp), hl
        ex      de, hl                          ; DE=local, BHL=far
.cme_4
        call    Ld_A_BHL                        ; get far byte
        call    GnClsMain                       ; uppercase if alpha
        jr      nc, cme_5
        and     $df                             ; upper()
.cme_5
        ld      c, a                            ; remember

        ld      a, (de)                         ; get local byte
        call    GnClsMain                       ; uppercase if alpha
        jr      nc, cme_6
        and     $df                             ; upper()
.cme_6
        cp      c                               ; compare
        inc     de
        inc     hl
        jr      nz, cme_7                       ; not same? exit
        or      a
        jr      nz, cme_4                       ; not null? loop

        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1, strings are equal

.cme_7
        pop     de                              ; restore bindings
        OZ      OS_Box
        ret

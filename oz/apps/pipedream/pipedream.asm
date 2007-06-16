; **************************************************************************************************
; PipeDream application (addressed for segment 2 & 3).
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
; Source code was reverse engineered by Gunther Strube from OZ 3.21 (DK) ROM using DZasm.
; Additional development improvements, comments, definitions and new implementations by
; (C) Thierry Peycru (pek@users.sf.net), 2007
; (C) Gunther Strube (gbs@users.sf.net), 2007
;
; Copyright of original (binary) implementation, V3.21 (DK):
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        MODULE PipeDream


        ORG $8000

        include "stdio.def"
        include "fileio.def"
        include "director.def"
        include "memory.def"
        include "syspar.def"
        include "saverst.def"
        include "fpp.def"
        include "integer.def"
        include "time.def"
        include "error.def"
        include "map.def"
        include "printer.def"


        jp      main_entry

        defm    "PipeDream", $00
        defm    "Z0.4", $00
        defm    "(C)1987 Colton Software", $00

.main_entry
        ld      ($1D51),de
        ld      hl,-640
        add     hl,sp
        ld      ($1D3F),hl
        ld      sp,hl
        ld      a, SC_ENA
        oz      Os_esc
        xor     a
        ld      hl, ErrHandler
        oz      Os_erh
        call    L_D631
        call    L_D749
.L_8046
        ld      hl,L_BDD6
        ld      ($1D53),hl
        call    L_BDD6
.L_804F
        ld      (iy-86),$F3
        scf
        call    L_E02C
        jp      pe,L_808A
        res     5,(iy-68)
        jr      c,L_806D
        call    L_84AE
        call    L_E31D
        jr      nc,L_804F
        call    L_80BE
        jr      L_8070
.L_806D
        call    L_E320
.L_8070
        ld      e,(iy-72)
        ld      a,e
        and     $12
        jr      z,L_8085
        bit     4,e
        jr      nz,L_8082
        bit     3,(iy-69)
        jr      z,L_8085
.L_8082
        call    L_929B
.L_8085
        call    L_BE08
        jr      L_804F
.L_808A
        cp      $01
        jr      z,L_8046
        cp      $00
        jr      nz,L_8085
        ld      e,(iy-71)
        ld      d,(iy-72)
        push    de
        call    L_B39E
        pop     de
        ld      (iy-71),e
        ld      (iy-72),d
        jr      c,L_80B8
        call    L_B543
        or      a
        bit     5,(iy-68)
        call    z,L_E105
        jr      c,L_804F
        set     5,(iy-68)
        jr      L_804F
.L_80B8
        set     5,(iy-68)
        jr      L_8085
.L_80BE
        bit     7,(iy-69)
        ret     z
        call    L_8397
        ret     nc
        call    L_D8B5
        call    L_835B
        ret     nc
        ld      de,($1D3D)
        or      a
        sbc     hl,de
        ld      a,(iy-87)
        cp      l
        jr      c,L_80EA
        sub     l
        ld      (iy-87),a
        ld      (iy-88),$00
        call    L_D0E2
        inc     bc
        call    L_82A2
.L_80EA
        scf
        call    L_BC66
        ld      de,$1DAA
        push   ix
        pop     hl
        sbc     hl,de
        ld      c,l
        ld      b,h
        ld      hl,($1D3D)
        ex      de,hl
        ldir
        call    L_8320
.L_8101
        call    L_8355
        ld      e,(hl)
        push    de
        ld      (hl),$00
        push    hl
        ld      de,($1D3D)
        or      a
        sbc     hl,de
        inc     l
        ld      (iy-40),l
        ld      c,(iy-11)
        ld      b,(iy-10)
        call    L_D56B
        ld      a,$81
        jr      nc,L_8123
        ld      a,$80
.L_8123
        bit     6,(iy-69)
        jr      z,L_8135
        ld      e,a
        ld      a,$0E
        bit     1,(iy-71)
        jr      z,L_8134
        ld      a,$0C
.L_8134
        or      e
.L_8135
        call    L_823B
        pop     hl
        pop     de
        ld      a,e
        jp      c,L_81BE
        ex      de,hl
        ld      c,$00
        ld      hl,($1D3D)
        jr      L_814A
.L_8146
        dec     c
.L_8147
        inc     hl
        inc     de
        ld      a,(de)
.L_814A
        ld      (hl),a
        call    L_FE32
        jr      nc,L_8152
        ld      c,$04
.L_8152
        ld      a,c
        or      a
        jr      nz,L_8146
        ld      a,(hl)
        or      a
        jr      nz,L_8147
        ex      de,hl
.L_815B
        ld      l,(iy-114)
        ld      h,(iy-113)
        ld      a,(iy-112)
        push    af
        push    de
        push    hl
        call    L_82B0
        pop     hl
        pop     de
        jr      c,L_81AD
        inc     h
        dec     h
        jr      nz,L_817C
        push    bc
        call    L_B503
        pop     bc
        pop     af
        ld      a,(iy-125)
        push    af
.L_817C
        push    hl
        ld      hl,($1D3D)
        sbc     hl,de
        jr      z,L_818F
        dec     de
        ld      a,(de)
        inc     de
        cp      $20
        jr      z,L_818F
        ld      a,$20
        ld      (de),a
        inc     de
.L_818F
        pop     hl
        pop     af
        cp      (iy-111)
        call    nz,L_D887
        push    bc
        ex      (sp),hl
        pop     bc
        sbc     hl,bc
        push    bc
        ex      (sp),hl
        pop     bc
        ldir
        xor     a
        ld      (de),a
        push    de
        call    L_8355
        pop     de
        jr      nc,L_815B
        jp      L_8101
.L_81AD
        pop     af
        ld      hl,($1D3D)
        ex      de,hl
        or      a
        sbc     hl,de
        inc     l
        ld      (iy-40),l
        ld      a,$81
        call    L_823B
.L_81BE
        call    L_B411
        call    L_B3C1
        set     3,(iy-72)
        ld      a,(iy-3)
        or      a
        jr      z,L_8238
        ld      (iy-44),a
        ld      d,$80
        bit     0,(iy-69)
        jr      z,L_8216
        bit     7,(iy-44)
        jr      nz,L_81FA
        call    L_D0E2
        inc     bc
        call    L_D77E
.L_81E6
        call    L_D0E5
        ld      c,a
        xor     a
        call    L_8C7F
        jp      c,L_EB07
        dec     (iy-44)
        jr      nz,L_81E6
        ld      d,$C0
        jr      L_8216
.L_81FA
        call    L_D0E5
        ld      c,(iy-11)
        ld      b,(iy-10)
        call    L_D77E
.L_8206
        call    L_B8B6
        call    L_8CA5
        jp      c,L_EB07
        inc     (iy-44)
        jr      nz,L_8206
        jr      L_8231
.L_8216
        call    L_D0E2
        ld      (iy-57),c
        ld      (iy-56),b
        or      d
        ld      (iy-58),a
        ld      c,(iy-3)
        ld      b,$00
        bit     7,c
        jr      z,L_822D
        dec     b
.L_822D
        xor     a
        call    L_B7B9
.L_8231
        set     1,(iy-72)
        call    L_CA7C
.L_8238
        jp      L_8B80
.L_823B
        or      (iy-42)
        ld      (iy-42),a
        call    L_D0E5
        ld      c,(iy-11)
        ld      b,(iy-10)
        call    L_8CA2
        jp      c,L_EB07
        inc     (iy-3)
        inc     (iy-9)
        jr      nz,L_825B
        inc     (iy-8)
.L_825B
        inc     (iy-11)
        jr      nz,L_8263
        inc     (iy-10)
.L_8263
        ld      hl,($1D3D)
        call    L_B493
        ld      (iy-42),$00
        or      a
        ret
.L_826F
        call    L_8397
        jp      nc,L_8E62
        call    L_B398
        call    L_D7AA
        call    L_B503
        ld      c,(iy-125)
        call    L_8323
        ld      de,($1D3D)
        call    L_815B
        ld      c,(iy-9)
        ld      b,(iy-8)
        push    bc
        call    L_D0E5
        pop     bc
.L_8296
        call    L_C9F9
        jr      nc,L_82A2
        ld      c,(iy-97)
        ld      b,(iy-96)
        dec     bc
.L_82A2
        set     7,(iy-100)
.L_82A6
        ld      (iy-104),a
        ld      (iy-103),c
        ld      (iy-102),b
        ret
.L_82B0
        ld      l,(iy-114)
        ld      h,(iy-113)
        ld      a,(iy-112)
        cp      (iy-111)
        call    nz,L_D887
        inc     h
        dec     h
        jr      nz,L_8308
        call    L_834C
        call    L_D0E5
        ld      c,(iy-9)
        ld      b,(iy-8)
        call    L_8B61
        dec     (iy-3)
        call    L_D0E5
        ld      c,(iy-9)
        ld      b,(iy-8)
        call    L_D7AD
        ret     c
        call    L_B503
        ld      e,a
        bit     7,a
        scf
        ret     z
        and     $C0
        cp      $C0
        scf
        ret     z
        ld      a,e
        and     $0E
        jr      z,L_82F8
        cp      $0C
        ret     c
.L_82F8
        ld      a,(ix+4)
        or      a
        scf
        ret     z
        cp      $20
        scf
        ret     z
        ld      a,(iy-125)
        ld      (iy-112),a
.L_8308
        call    L_83C5
        ld      c,l
        ld      b,h
        jr      nc,L_8314
        ld      hl,$0000
        jr      L_8318
.L_8314
        cp      $20
        jr      z,L_8308
.L_8318
        ld      (iy-114),l
        ld      (iy-113),h
        or      a
        ret
.L_8320
        ld      hl,$0000
.L_8323
        ld      (iy-114),l
        ld      (iy-113),h
        ld      (iy-112),c
        call    L_D8B5
        ld      (iy-11),c
        ld      (iy-10),b
        ld      (iy-9),c
        ld      (iy-8),b
        xor     a
        ld      (iy-3),a
        ld      (iy-42),a
        call    L_D7AA
        ret     c
        ld      a,(ix+3)
        and     $0E
        ret     z
.L_834C
        ld      a,(iy-71)
        xor     $02
        ld      (iy-71),a
        ret
.L_8355
        ld      c,(iy-11)
        ld      b,(iy-10)
.L_835B
        ld      (iy-26),c
        ld      (iy-25),b
        call    L_D0E5
        call    L_C917
        ld      b,a
        ld      hl,($1D3D)
        ld      c,$00
        ld      d,c
        jr      L_8372
.L_8370
        ld      e,l
        ld      d,h
.L_8372
        call    L_83C5
        jr      c,L_8391
        cp      $20
        jr      nz,L_8372
        ld      a,d
        or      a
        jr      z,L_8370
        ld      a,c
        cp      b
        jr      c,L_8370
.L_8383
        ld      a,d
        or      a
        ret     z
        ld      l,e
        ld      h,d
        call    L_83C5
        cp      $20
        scf
        ret     nz
        ccf
        ret
.L_8391
        ld      a,c
        cp      b
        jr      nc,L_8383
        or      a
        ret
.L_8397
        bit     6,(iy-71)
        scf
        ccf
        ret     nz
        call    L_D249
        ccf
        ret     nc
        call    L_D7AA
        jr      c,L_83B8
        ld      a,(ix+3)
        bit     7,a
        scf
        ccf
        ret     z
        and     $0E
        jr      z,L_83B8
        cp      $0C
        ccf
        ret     nc
.L_83B8
        ld      hl,($1D3D)
.L_83BB
        ld      a,(hl)
        or      a
        ret     z
        inc     hl
        cp      $20
        jr      z,L_83BB
        scf
        ret
.L_83C5
        ld      a,(hl)
        dec     hl
        dec     c
        cp      $20
        jr      z,L_83FA
.L_83CC
        inc     hl
.L_83CD
        inc     c
        ld      a,(hl)
        or      a
        jr      z,L_8408
        call    L_CE2A
        jr      c,L_83F3
        cp      $40
        jr      nz,L_83F4
        call    L_840A
        jr      nc,L_83CD
        jr      z,L_83E9
        inc     hl
        inc     hl
        inc     hl
        set     5,(iy-42)
.L_83E9
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_8408
        inc     c
        cp      $40
        jr      z,L_83E9
.L_83F3
        dec     c
.L_83F4
        cp      $20
        jr      nz,L_83CC
.L_83F8
        or      a
        ret
.L_83FA
        inc     hl
        inc     c
        ld      a,(hl)
        or      a
        jr      z,L_8406
        cp      $20
        jr      z,L_83FA
        or      a
        ret
.L_8406
        ld      a,$20
.L_8408
        scf
        ret
.L_840A
        inc     hl
        ld      a,(hl)
        call    L_FE32
        jr      c,L_8452
        push    de
        push    hl
        push    bc
        ld      a,(iy-110)
        push    af
        ld      c,(iy-109)
        ld      b,(iy-108)
        push    bc
        call    L_BD57
        pop     bc
        ld      (iy-108),b
        ld      (iy-109),c
        pop     bc
        ld      (iy-110),b
        pop     bc
        jr      c,L_8439
        cp      $40
        jr      nz,L_8439
        ex      (sp),hl
        pop     hl
        pop     de
        jr      L_844F
.L_8439
        pop     hl
        pop     de
        ld      a,(hl)
        call    L_EE09
        cp      $54
        jr      z,L_8450
        cp      $50
        jr      z,L_8450
        cp      $44
        jr      z,L_8450
        cp      $40
        jr      nz,L_83F8
.L_844F
        dec     hl
.L_8450
        ccf
        ret
.L_8452
        inc     h
        dec     h
        ret
.L_8455
        ld      a,(iy-71)
        xor     $04
        ld      (iy-71),a
        ret
.L_845E
        bit     6,(iy-71)
        ret     z
        ld      hl,L_84AE
        ld      ($1D4B),hl
        call    L_D0E2
        jp      L_BBBF
.L_846F
        ld      a,(iy-71)
        push    af
        res     2,(iy-71)
        ld      a,$20
        call    L_84E3
        pop     af
        ld      (iy-71),a
        jp      L_8E97
.L_8483
        ld      a,$18
        jr      L_84AE
.L_8487
        ld      a,$19
        jr      L_84AE
.L_848B
        ld      a,$1A
        jr      L_84AE
.L_848F
        ld      a,$1B
        jr      L_84AE
.L_8493
        ld      a,$1C
        jr      L_84AE
.L_8497
        ld      a,$1D
        jr      L_84AE
.L_849B
        ld      a,$1E
        jr      L_84AE
.L_849F
        ld      a,$1F
        jr      L_84AE
.L_84A3
        call    L_B398
        call    L_87BE
        push    af
        call    L_B543
        pop     af
.L_84AE
        ld      (iy-34),a
        cp      $20
        jr      nc,L_84BA
        bit     6,(iy-71)
        ret     nz
.L_84BA
        call    L_D7AA
        jr      c,L_84CA
        bit     7,(ix+3)
        jr      z,L_84D0
        call    L_C9B8
        jr      nc,L_84E9
.L_84CA
        bit     5,(iy-69)
        jr      nz,L_84E9
.L_84D0
        bit     6,(iy-71)
        jr      nz,L_84E9
        ld      a,(iy-34)
        push    af
        call    L_9276
        call    L_B56E
        pop     af
        jr      L_84AE
.L_84E3
        cp      $20
        ret     c
        ld      (iy-34),a
.L_84E9
        call    L_8690
        call    L_8572
        ld      a,(iy-87)
        bit     2,(iy-71)
        jr      nz,L_84F9
        ld      a,b
.L_84F9
        cp      (iy-86)
        jp      nc,L_EFE9
        ld      a,b
        cp      (iy-87)
        jr      nc,L_8511
        ld      a,b
.L_8506
        ld      (hl),$20
        inc     hl
        inc     a
        cp      (iy-87)
        jr      c,L_8506
        ld      (hl),$00
.L_8511
        ld      a,(hl)
        or      a
        jr      z,L_851B
        bit     2,(iy-71)
        jr      nz,L_851E
.L_851B
        inc     hl
        ld      (hl),a
        dec     hl
.L_851E
        inc     b
        dec     b
        jr      z,L_852B
        dec     hl
        dec     b
        ld      a,b
        cp      (iy-87)
        jr      nc,L_8511
        inc     hl
.L_852B
        ld      a,(iy-34)
        ld      (hl),a
        call    L_8687
.L_8532
        bit     7,(iy-72)
        jr      z,L_8543
        ld      a,(iy-87)
        cp      (iy-86)
        ret     nc
        inc     (iy-87)
        ret
.L_8543
        call    L_B398
        ld      c,$03
        jp      L_8E8E
.L_854B
        call    L_B398
        call    L_D8CD
        jp      c,L_EB07
        call    L_879F
        call    L_D8B5
        ld      a,(iy-98)
        jp      L_8D30
.L_8560
        call    L_8690
        ld      (iy-87),$00
        ret
.L_8568
        call    L_8690
        call    L_8572
        ld      (iy-87),b
        ret
.L_8572
        ld      hl,($1D3D)
        dec     hl
        ld      b,$FF
.L_8578
        inc     hl
        inc     b
        ld      a,(hl)
        or      a
        jr      nz,L_8578
        ret
.L_857F
        ld      b,(iy-87)
.L_8582
        ld      hl,($1D3D)
        ld      e,b
        ld      d,$00
        add     hl,de
        ret
.L_858A
        call    L_8690
        ld      a,(iy-87)
        or      a
        ret     z
        dec     (iy-87)
        ld      (iy-88),$00
        bit     2,(iy-71)
        jr      z,L_85A7
        call    L_857F
        ld      (hl),$20
        jp      L_8687
.L_85A7
        call    L_8690
        call    L_857F
        ld      a,(hl)
        or      a
        ret     z
        call    L_8687
.L_85B3
        inc     hl
        ld      a,(hl)
        dec     hl
        ld      (hl),a
        inc     hl
        or      a
        jr      nz,L_85B3
        scf
        ret
.L_85BD
        bit     7,(iy-72)
        jr      z,L_85F1
        call    L_8572
        ld      a,b
        cp      (iy-87)
        jr      c,L_862A
        call    L_857F
        ld      a,b
        or      a
        jr      z,L_85F1
        dec     b
        jr      z,L_862A
        dec     hl
        ld      a,(hl)
        cp      $20
        jr      nz,L_85E5
.L_85DC
        dec     b
        jr      z,L_862A
        dec     hl
        ld      a,(hl)
        cp      $20
        jr      z,L_85DC
.L_85E5
        dec     hl
        ld      a,(hl)
        cp      $20
        inc     hl
        jr      z,L_862A
        dec     hl
        djnz    L_85E5
        jr      L_862A
.L_85F1
        bit     6,(iy-71)
        ret     nz
        call    L_D0E5
        ld      e,a
        call    L_D8B5
        ld      a,b
        or      c
        ret     z
        dec     bc
        ld      a,e
        call    L_D7AD
        jr      c,L_861C
        ld      a,(ix+3)
        cp      $80
        jr      nz,L_861C
        call    L_B990
        dec     b
        ld      a,b
        call    L_B53C
.L_8616
        ld      (iy-87),a
        jp      L_8E81
.L_861C
        xor     a
        jr      L_8616
.L_861F
        bit     7,(iy-72)
        jr      z,L_862E
        call    L_8697
        jr      c,L_862E
.L_862A
        ld      (iy-87),b
        ret
.L_862E
        bit     6,(iy-71)
        ret     nz
        call    L_D0E2
        call    L_CA1E
        ret     z
        call    L_8D45
        jp      L_8E62
.L_8640
        call    L_8690
        call    L_8697
        ret     c
        push    hl
        call    L_857F
        ex      de,hl
        pop     hl
.L_864D
        ld      a,(hl)
        inc     hl
        ld      (de),a
        inc     de
        or      a
        jr      nz,L_864D
        jr      L_8687
.L_8656
        call    L_8690
        call    L_857F
        ld      a,(hl)
        or      a
        ret     z
        call    L_EE1B
        jr      nc,L_866A
        xor     $20
        ld      (hl),a
        call    L_8687
.L_866A
        jp      L_8532
.L_866D
        call    L_857F
        bit     7,(iy-72)
        jr      nz,L_8685
        call    L_B569
        ld      b,$00
        call    L_8582
        call    L_8685
        call    L_B398
        ret
.L_8685
        ld      (hl),$00
.L_8687
        set     0,(iy-72)
        set     5,(iy-72)
        ret
.L_8690
        bit     7,(iy-72)
        ret     nz
        pop     de
        ret
.L_8697
        call    L_8572
        ld      a,(iy-87)
        cp      b
        ld      b,a
        ccf
        ret     c
        call    L_857F
.L_86A4
        ld      a,(hl)
        dec     b
        cp      $20
        dec     hl
        jr      z,L_86B4
.L_86AB
        inc     hl
        inc     b
        ld      a,(hl)
        or      a
        ret     z
        cp      $20
        jr      nz,L_86AB
.L_86B4
        inc     hl
        inc     b
        ld      a,(hl)
        or      a
        ret     z
        cp      $20
        jr      z,L_86B4
        or      a
        ret

.L_86BF
        defm    $01, $87, "Microspace printed output", $00
        defm    $00
        defm    $00
        defm    $FF, $00
        defm    $81, $00

.L_86E1
        call    L_B398
        ld      hl,L_86BF
        call    L_D98A
        ret     c
        res    4,(iy-70)
        and     $01
        ret     z
        set     4,(iy-70)
        ld      a,(iy+51)
        or      a
        jr      nz,L_86FE
        ld      a,$0C
.L_86FE
        ld      (iy+28),a
        ret
.L_8702
        call    L_D0E5
        ld      b,a
        call    L_D551
        cp      $03
        ret     c
        ld      c,a
        dec     c
        jr      L_871A
.L_8710
        call    L_D0E5
        ld      b,a
        call    L_D551
        ld      c,a
        inc     c
        ret     z
.L_871A
        ld      a,b
        call    L_D76C
        jp      L_CA8D

.L_8721
        defm    $02, $07, "New width", $00
        defm    $00
        defm    $00
        defm    $FF, $00
        defm    $00
        defm    $8A, "Specify column", $00
        defm    $81, $00

.L_8744
        call    L_B398
        ld      c,$01
        jr      L_8750
.L_874B
        call    L_B398
        ld      c,$00
.L_8750
        push    bc
        ld      hl,L_8721
        call    L_D98A
        pop     bc
        ret     c
        push    bc
        push    af
        call    L_D0E5
        ld      (iy-44),a
        pop     af
        and     $01
        jr      z,L_876C
        ld      a,(iy+53)
        ld      (iy-44),a
.L_876C
        pop     bc
        ld      a,(iy+51)
        push    af
        or      a
        jr      nz,L_8792
        inc     c
        dec     c
        jr      nz,L_8792
.L_8778
        cp      (iy-44)
        jr      z,L_8786
        ld      e,a
        call    L_D890
        ld      a,(hl)
        or      a
        jr      nz,L_8792
        ld      a,e
.L_8786
        inc     a
        cp      (iy-98)
        jr      c,L_8778
        pop     de
        ld      c,$22
        jp      L_EB07
.L_8792
        ld      a,(iy-44)
        call    L_D890
        pop     de
        inc     c
        dec     c
        jr      z,L_879E
        inc     hl
.L_879E
        ld      (hl),d
.L_879F
        call    L_B3C1
        jp      L_CA85

.L_87A5
        defm    $01, $07, "Highlight number", $00
        defm    $01, $00
        defm    $08, $00
        defm    $00
        defm    $00

.L_87BE
        call    L_B398
        ld      hl,L_87A5
        call    L_D98A
        jr      nc,L_87CB
        pop     de
        ret
.L_87CB
        ld      a,(iy+51)
        add     a,$17
        ret
.L_87D1
        ld      bc,$0000
        jr      L_8838
.L_87D6
        ld      bc,$C0FF
        jr      L_8838
.L_87DB
        ld      bc,$407F
        jr      L_8838
.L_87E0
        ld      bc,$10EF
        jr      L_87E8
.L_87E5
        ld      bc,$20DF
.L_87E8
        xor     a
        jr      L_8852

.L_87EB
        defm    $02, $07, "Number of decimal places", $00
        defm    $00
        defm    $00
        defm    $09, $00
        defm    $00
        defm    $84, "Floating format", $00
        defm    $81, $00

.L_881E
        call    L_B398
        ld      hl,L_87EB
        call    L_D98A
        ret     c
        ld      b,$0F
        and     $01
        jr      nz,L_8832
        ld      a,(iy+51)
        ld      b,a
.L_8832
        ld      a,b
        or      $40
        ld      b,a
        ld      c,$B0
.L_8838
        ld      a,$40
        jr      L_8852
.L_883C
        ld      b,$08
        jr      L_884E
.L_8840
        ld      b,$02
        jr      L_884E
.L_8844
        ld      b,$04
        jr      L_884E
.L_8848
        ld      b,$06
        jr      L_884E
.L_884C
        ld      b,$00
.L_884E
        ld      a,$C0
        ld      c,$F1
.L_8852
        ld      (iy-5),a
        ld      (iy-4),c
        ld      (iy-6),b
        call    L_B398
        call    L_88C6
        call    L_FBBD
.L_8864
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D797
        jr      c,L_88C0
        bit     7,(ix+3)
        jr      z,L_887E
        bit     7,(iy-5)
        jr      z,L_88C0
.L_887E
        ld      de,$0003
        bit     7,(iy-5)
        jr      nz,L_888A
        ld      de,$0009
.L_888A
        push   ix
        pop     hl
        add     hl,de
        ld      c,(hl)
        bit     7,(iy-5)
        jr      nz,L_88A6
        ld      a,c
        and     $40
        jr      nz,L_88A6
        ld      a,c
        and     $30
        ld      c,a
        ld      a,(iy-6)
        and     $40
        call    nz,L_88E3
.L_88A6
        ld      a,c
        and     (iy-4)
        or      (iy-6)
        cp      (hl)
        jr      nz,L_88B9
        bit     6,(iy-5)
        jr      nz,L_88B9
        and     (iy-4)
.L_88B9
        ld      (hl),a
        call    L_B3C1
        call    L_C9CA
.L_88C0
        call    L_FB93
        jr      c,L_8864
        ret
.L_88C6
        call    L_D014
        ret     nc
        call    L_D0E2
        ld      (iy-58),a
        ld      (iy-57),c
        ld      (iy-56),b
        ld      (iy-55),a
        ld      (iy-54),c
        ld      (iy-53),b
        ret
.L_88E0
        and     $40
        ret     nz
.L_88E3
        bit     2,(iy-69)
        jr      nz,L_88EB
        set     7,c
.L_88EB
        ld      a,c
        or      (iy+9)
        ld      c,a
        ret
.L_88F1
        call    L_B398
        xor     a
        call    L_B2CC
        call    L_FBBD
        ld      de,$0000
.L_88FE
        push    de
        call    L_8930
        pop     de
        jr      c,L_8913
        ld      a,(hl)
        or      a
        jr      z,L_8913
        dec     hl
.L_890A
        inc     hl
        inc     de
        call    L_86A4
        ld      a,(hl)
        or      a
        jr      nz,L_890A
.L_8913
        push    de
        call    L_FB93
        pop     de
        jr      c,L_88FE
        call    L_EED0
        ex      de,hl
        call    L_EE7C
        oz      Os_Pout
        defm    " words", $00

        ld      (iy-84),$0B
        ret
.L_8930
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D797
        ret     c
        ld      a,(ix+3)
        bit     7,a
        scf
        ret     z
        and     $C0
        cp      $C0
        scf
        ret     z
        call    L_B503
        or      a
        ret
.L_894F
        ld      hl,($1D5B)
        ld      b,$00
.L_8954
        call    L_D0E8
        jr      c,L_895F
        jr      z,L_895C
        inc     b
.L_895C
        inc     hl
        jr      L_8954
.L_895F
        ld      hl,($1D5B)
        ld      a,b
        or      a
        jr      z,L_8970
.L_8966
        call    L_D0E8
        ld      (hl),a
        jp      c,L_CA85
        inc     hl
        jr      L_8966
.L_8970
        call    L_D0E8
        jp      c,L_CA85
        or      $80
        ld      (hl),a
        inc     hl
        ld      bc,($1D5D)
        ld      a,h
        cp      b
        jr      c,L_8970
        jp      nz,L_CA85
        ld      a,l
        cp      c
        jr      c,L_8970
        jr      z,L_8970
        jp      L_CA85
.L_898E
        call    L_B398
        ld      hl,($1D61)
        bit     7,(hl)
        jr      z,L_89B3
        call    L_D8B8
        ld      (iy-26),c
        ld      (iy-25),b
        call    L_D3E9
        ld      hl,($1D61)
        ld      de,$0006
.L_89AA
        res     7,(hl)
        bit     6,(hl)
        jr      nz,L_89EE
        add     hl,de
        jr      L_89AA
.L_89B3
        call    L_D104
        ld      hl,($1D61)
        ld      e,l
        ld      d,h
        ld      ix,$1D63
.L_89BF
        ld      bc,$0005
        add     hl,bc
        ex      de,hl
        add     hl,bc
        ex      de,hl
.L_89C6
        dec     de
        dec     hl
        ld      a,(de)
        ld      (hl),a
        dec     c
        jr      nz,L_89C6
        bit     6,a
        jr      nz,L_89EE
        ld      bc,$0006
        set     7,(hl)
        and     $20
        jr      nz,L_89DB
        add     hl,bc
.L_89DB
        ex      de,hl
        add     hl,bc
        ex      de,hl
        ld      a,d
        cp      (ix+1)
        jr      c,L_89BF
        jr      nz,L_89EE
        ld      a,e
        cp      (ix+0)
        jr      c,L_89BF
        jr      z,L_89BF
.L_89EE
        call    L_CA8D
        set     7,(iy-23)
        jp      L_D45B
.L_89F8
        ld      a,$80
        ld      (iy-67),a
        ld      (iy-64),a
        jp      L_CA8D
.L_8A03
        call    L_D0E2
        bit     7,(iy-67)
        jr      z,L_8A18
.L_8A0C
        ld      (iy-67),a
        ld      (iy-66),c
        ld      (iy-65),b
        jp      L_CA8D
.L_8A18
        bit     7,(iy-64)
        jr      nz,L_8A24
        set     7,(iy-64)
        jr      L_8A0C
.L_8A24
        ld      (iy-64),a
        ld      (iy-63),c
        ld      (iy-62),b
        jp      L_CA8D
.L_8A30
        call    L_B394
        xor     a
.L_8A34
        push    af
        call    L_D8B5
        pop     af
        push    af
        call    L_8B61
        pop     af
        inc     a
        cp      (iy-98)
        jr      c,L_8A34
        ld      a,$C0
        jr      L_8A53
.L_8A48
        call    L_B394
        call    L_D0E2
.L_8A4E
        call    L_8B61
        ld      a,$80
.L_8A53
        call    L_B7A5
        call    L_EB49
        jp      L_A341
.L_8A5C
        call    L_B394
        call    L_D7AA
        ret     c
        bit     7,(ix+3)
        ret     z
        call    L_8AB2
        call    L_D7AD
        ret     c
        bit     7,(ix+3)
        ret     z
        call    L_8572
        ld      (iy-44),b
        ld      bc,L_8A92
        call    L_BB7E
        jp      pe,L_EB07
        set     7,(iy-72)
        call    L_8687
        call    L_B394
        call    L_8AB2
        jr      L_8A4E
.L_8A92
        push    de
        ld      d,a
        ld      a,(iy-44)
        cp      $F5
        jr      nc,L_8AA9
        ld      hl,($1D3D)
        ld      e,a
        ld      a,d
        ld      d,$00
        add     hl,de
        ld      (hl),a
        inc     (iy-44)
        pop     de
        ret
.L_8AA9
        ld      sp,($1D47)
        ld      c,$1E
        jp      L_F9B7
.L_8AB2
        call    L_D0E2
        inc     bc
        ret
.L_8AB7
        scf
        jr      L_8ABB
.L_8ABA
        or      a
.L_8ABB
        rr      (iy-6)
        call    L_B398
        call    L_9250
        call    L_87BE
        ld      (iy-46),a
        call    L_FBBD
.L_8ACE
        call    L_8930
        jr      c,L_8B43
        call    L_C9B8
        jr      c,L_8B43
        call    L_B500
        ex      de,hl
        ld      hl,$1DAA
        ld      bc,$0000
        ld      (iy-40),c
.L_8AE5
        bit     7,(iy-6)
        jr      nz,L_8B0E
        ld      a,(de)
        cp      (iy-46)
        jr      z,L_8B0E
        or      a
        jr      z,L_8B05
        cp      $20
        scf
        ccf
        jr      z,L_8B05
        bit     0,c
        set     0,c
        call    z,L_8B4E
        jr      c,L_8B43
        jr      L_8B0E
.L_8B05
        bit     0,c
        res     0,c
        call    nz,L_8B4E
        jr      c,L_8B43
.L_8B0E
        ld      a,(de)
        inc     de
        cp      (iy-46)
        scf
        ccf
        call    nz,L_8B51
        jr      c,L_8B43
        or      a
        jr      z,L_8B31
        call    L_FE32
        jr      nc,L_8B24
        ld      b,$04
.L_8B24
        inc     b
.L_8B25
        dec     b
        jr      z,L_8AE5
        ld      a,(de)
        inc     de
        call    L_8B51
        jr      nc,L_8B25
        jr      L_8B43
.L_8B31
        ld      a,(ix+3)
        ld      (iy-42),a
        call    L_B8C7
        jp      c,L_EB07
        call    L_B490
        call    L_C9CA
.L_8B43
        call    L_FB93
        jr      c,L_8ACE
        call    L_B3C1
        jp      L_CA73
.L_8B4E
        ld      a,(iy-46)
.L_8B51
        push    bc
        ld      b,a
        ld      (hl),a
        inc     hl
        inc     (iy-40)
        ld      a,(iy-40)
        cp      $F5
        ccf
        ld      a,b
        pop     bc
        ret
.L_8B61
        call    L_D797
        ret     c
        ld      a,(iy-110)
        call    L_BA24
        call    L_BB4B
        call    L_BB69
        call    L_BA44
        call    L_B9C6
        call    L_B990
        ld      c,b
        ld      b,$00
        jp      L_D95E
.L_8B80
        call    L_D1E9
        xor     a
.L_8B84
        push    af
        call    L_D7A5
        pop     af
        push    af
        call    L_D788
        pop     af
        push    af
        call    L_CA0F
        pop     af
        inc     a
        cp      (iy-98)
        jr      c,L_8B84
        ret

.L_8B9A
        defm    $01, $87, "Specify no. of unbroken lines", $00
        defm    $00
        defm    $00
        defm    $FF, $00
        defm    $81, $00

.L_8BC0
        call    L_B394
        ld      hl,L_8B9A
        call    L_D98A
        ret     c
        ld      b,$00
        and     $01
        jr      z,L_8BD3
        ld      b,(iy+51)
.L_8BD3
        push    bc
        call    L_CA7C
        ld      (iy-42),$C0
        ld      (iy-40),$02
        call    L_D8B5
        xor     a
        call    L_8CA2
        pop     de
        jp      c,L_EB07
        call    L_B518
        ld      (ix+5),d
        ld      a,$01
        jr      L_8C01
.L_8BF4
        call    L_B394
        call    L_CA7C
        call    L_D0E2
        call    L_D77E
        xor     a
.L_8C01
        ld      c,$80
        call    L_8C7F
        jp      c,L_EB07
        ld      a,$C0
        jp      L_B7B0
.L_8C0E
        call    L_B394
        call    L_CA7C
        call    L_B8B6
        call    L_D0E2
        call    L_8CA2
        jp      c,L_EB07
.L_8C20
        ld      a,$80
        jp      L_B7B0
.L_8C25
        call    L_B388
        call    L_D7AA
        ret     c
        bit     7,(ix+3)
        ret     z
        call    L_8572
        ld      a,b
        cp      (iy-87)
        call    nc,L_857F
        ld      (iy-87),b
        ld      a,(hl)
        ld      (iy-46),a
        ld      (hl),$00
        call    L_8687
        call    L_B394
        call    L_CA7C
        call    L_857F
        ld      de,($1D3D)
        ld      a,(iy-46)
        jr      L_8C5B
.L_8C59
        inc     hl
        ld      a,(hl)
.L_8C5B
        ld      (de),a
        inc     de
        or      a
        jr      nz,L_8C59
        scf
        call    L_BC66
        jp      c,L_EB07
        ld      (iy-40),b
        ld      (iy-42),$80
        call    L_8AB2
        call    L_8CA2
        jp      c,L_EB07
        call    L_B490
        call    L_B411
        jr      L_8C20
.L_8C7F
        ld      (iy-110),a
        ld      (iy-38),c
.L_8C85
        cp      (iy-98)
        ret     nc
        cp      (iy-38)
        jr      z,L_8C9A
        call    L_B8B6
        call    L_D79A
        jr      c,L_8C9A
        call    L_8CA5
        ret     c
.L_8C9A
        inc     (iy-110)
        ld      a,(iy-110)
        jr      L_8C85
.L_8CA2
        call    L_D77E
.L_8CA5
        call    L_8CAE
        ret     c
        call    L_B3C1
        or      a
        ret
.L_8CAE
        call    L_D79A
        jp      c,L_B8C7
        call    L_D920
        ret     c
        ld      a,(iy-110)
        call    L_D7A5
        ld      a,(iy-110)
        call    L_D788
        ld      a,(iy-110)
        call    L_CA0E
        ld      a,(iy-110)
        ld      c,(iy-109)
        ld      b,(iy-108)
        call    L_BA73
        call    L_BA44
        call    L_D8F2
        call    L_B9A8
        or      a
        ret
.L_8CE1
        call    L_B398
        call    L_D0E2
        ld      a,(iy-98)
        jr      L_8D30
.L_8CEC
        call    L_B398
        call    L_D0E2
        xor     a
        jr      L_8D30

.L_8CF5
        defm    $01, $02, "Go to slot", $00
        defm    $00
        defm    $00

.L_8D04
        call    L_B398
        ld      hl,L_8CF5
        call    L_D98A
        ret     c
        ld      a,(iy+56)
        ld      c,(iy+57)
        ld      b,(iy+58)
        jr      L_8D30
.L_8D19
        call    L_B398
        ld      bc,$7FFF
        jr      L_8D27
.L_8D21
        call    L_B398
        ld      bc,$0000
.L_8D27
        set     5,(iy-71)
        push    bc
        call    L_D0E5
        pop     bc
.L_8D30
        cp      (iy-98)
        jr      c,L_8D39
        ld      a,(iy-98)
        dec     a
.L_8D39
        call    L_8296
        set     2,(iy-99)
        bit     6,(iy-71)
        ret     nz
.L_8D45
        xor     a
        ld      (iy-88),a
        ld      (iy-87),a
        ret
.L_8D4D
        ld      a,(iy+99)
        or      a
        jp      z,L_EFE9
        call    L_B398
        dec     (iy+99)
        call    L_8D7B
        call    L_B4F9
        jr      L_8D30
.L_8D62
        ld      a,(iy+99)
        cp      $05
        jp      nc,L_EFE9
        call    L_8D7B
        push    hl
        call    L_D0E2
        pop     hl
        ld      (hl),a
        inc     hl
        ld      (hl),c
        inc     hl
        ld      (hl),b
        inc     (iy+99)
        ret
.L_8D7B
        ld      a,(iy+99)
        ld      c,a
        add     a,a
        add     a,c
        ld      c,a
        ld      b,$00
        push    iy
        pop     hl
        ld      de,$0054
        add     hl,de
        add     hl,bc
        ret
.L_8D8D
        call    L_B394
        ld      a,(iy-98)
        cp      $01
        ret     z
        call    L_D0E5
        cp      (iy-98)
        ret     nc
        ld      bc,$0000
        call    L_D7AD
        jr      c,L_8DAE
        call    L_D0E5
        call    L_BAC8
        call    L_90FE
.L_8DAE
        ld      a,(iy-98)
        call    L_D890
        push    hl
        dec     (iy-98)
        call    L_D88D
        pop     bc
        ld      de,$000A
.L_8DBF
        push    hl
        add     hl,de
        ld      a,(hl)
        pop     hl
        ld      (hl),a
        inc     hl
        push    hl
        or      a
        sbc     hl,bc
        pop     hl
        jr      nz,L_8DBF
        call    L_EB49
        call    L_B794
        call    L_B3C1
.L_8DD5
        call    L_8B80
        call    L_CA7C
        jp      L_CA85
.L_8DDE
        call    L_B394
        call    L_D8E9
        jp      c,L_EB07
        call    L_D0E5
        call    L_D8EC
        jp      c,L_EB07
        cp      (iy-98)
        ret     nc
        call    L_D88D
        push    hl
        ld      a,$3F
        call    L_D890
        pop     bc
        ld      de,$000A
.L_8E01
        dec     hl
        push    hl
        ld      a,(hl)
        add     hl,de
        ld      (hl),a
        pop     hl
        push    hl
        or      a
        sbc     hl,bc
        pop     hl
        jr      nz,L_8E01
        call    L_D0E5
        call    L_D8D1
        call    L_B79B
        jp      L_879F
.L_8E1A
        bit     6,(iy-71)
        jr      z,L_8E3F
        call    L_B41A
        call    c,L_EB07
        set     1,(iy-72)
.L_8E2A
        bit     6,(iy-71)
        ret     z
        res     6,(iy-71)
        call    L_B411
        call    L_CA73
        call    L_8D45
        jp      L_EFD5
.L_8E3F
        call    L_B398
        call    L_B8B6
        call    L_D0E2
        call    L_CA1E
        jr      nz,L_8E5D
        call    L_B8C4
        jp      c,L_EB07
        call    L_CA7C
        call    L_B3C1
        set     7,(iy-68)
.L_8E5D
        call    L_8D45
        jr      L_8E6D
.L_8E62
        call    L_B398
        set     4,(iy-71)
        set     7,(iy-68)
.L_8E6D
        ld      c,$01
        jr      L_8E8E
.L_8E71
        call    L_B398
        ld      c,$00
        jr      L_8E7D
.L_8E78
        call    L_B398
        ld      c,$01
.L_8E7D
        ld      b,$02
        jr      L_8E90
.L_8E81
        call    L_B398
        set     4,(iy-71)
        set     7,(iy-68)
        ld      c,$00
.L_8E8E
        ld      b,$01
.L_8E90
        ld      (iy-100),b
        ld      (iy-101),c
        ret
.L_8E97
        bit     7,(iy-72)
        jr      z,L_8EB1
        ld      a,(iy-87)
        or      a
        jr      z,L_8EA7
        dec     (iy-87)
        ret
.L_8EA7
        bit     5,(iy-70)
        ret     nz
        bit     6,(iy-71)
        ret     nz
.L_8EB1
        call    L_B398
        ld      c,$02
        jr      L_8E8E
.L_8EB8
        call    L_9209
        call    L_9224
        ld      a,(iy-58)
        push    af
.L_8EC2
        push    bc
        call    L_91B2
        pop     bc
        jr      c,L_8EFF
        push    bc
        ld      b,$06
        ld      de,$FFC6
        push    iy
        pop     hl
        add     hl,de
.L_8ED3
        ld      a,(hl)
        push    af
        inc     hl
        djnz    L_8ED3
        call    L_9050
        rr      (iy-18)
        ld      b,$06
        ld      de,$FFCC
        push    iy
        pop     hl
        add     hl,de
.L_8EE8
        pop     af
        dec     hl
        ld      (hl),a
        djnz    L_8EE8
        pop     bc
        rl      (iy-18)
        jr      c,L_8EFF
        inc     c
        dec     c
        jr      z,L_8EFF
        dec     c
        inc     b
        inc     (iy-58)
        jr      L_8EC2
.L_8EFF
        ld      bc,L_B671
        call    L_B78D
        call    L_919B
        ld      (iy-29),a
        ld      (iy-28),c
        ld      (iy-27),b
        pop     af
        ld      (iy-58),a
        set     6,(iy-55)
        call    L_9183
        push    bc
        xor     a
        call    L_B7BE
        pop     bc
        push    bc
        call    L_9161
        set     6,(iy-55)
        call    L_B785
        call    L_89F8
        pop     bc
        jr      L_8F92
.L_8F33
        call    L_9209
        call    L_9224
.L_8F39
        push    bc
        call    L_91B2
        pop     bc
        jr      c,L_8F77
        push    bc
        ld      b,$06
        ld      de,$FFC6
        push    iy
        pop     hl
        add     hl,de
.L_8F4A
        ld      a,(hl)
        push    af
        inc     hl
        djnz    L_8F4A
        call    L_8FCD
        rr      (iy-18)
        ld      b,$06
        ld      de,$FFCC
        push    iy
        pop     hl
        add     hl,de
.L_8F5F
        pop     af
        dec     hl
        ld      (hl),a
        djnz    L_8F5F
        pop     bc
        rl      (iy-18)
        jp      c,L_8FBB
        inc     c
        dec     c
        jr      z,L_8F77
        dec     c
        inc     b
        inc     (iy-58)
        jr      L_8F39
.L_8F77
        call    L_919B
        call    L_B690
        call    L_9183
        call    L_9161
        push    bc
        call    L_B62E
        ld      bc,L_B69A
        call    L_B78D
        pop     bc
        set     6,(iy-55)
.L_8F92
        call    L_9193
        xor     a
        call    L_B7BE
        jr      L_8FBB
.L_8F9B
        call    L_9209
        ld      a,(iy-58)
        ld      c,(iy-57)
        ld      b,(iy-56)
        call    L_82A2
.L_8FAA
        call    L_908D
        ld      a,(iy-58)
        inc     (iy-58)
        cp      (iy-55)
        jr      nz,L_8FAA
        call    L_89F8
.L_8FBB
        call    L_D357
.L_8FBE
        call    L_B3C1
.L_8FC1
        call    L_8DD5
.L_8FC4
        call    L_B3B8
        call    L_929B
        jp      L_929B
.L_8FCD
        call    L_91DE
        jr      c,L_9048
        call    L_9238
        res     7,(iy-44)
.L_8FD9
        call    L_9128
        call    L_BA96
        call    L_BB0F
        call    L_D920
        jr      c,L_903A
        call    L_D8F2
        bit     7,(iy-44)
        jr      nz,L_8FF8
        call    L_BA96
        call    L_BB05
        jr      L_9001
.L_8FF8
        call    L_BAA0
        call    L_BABE
        call    L_BA44
.L_9001
        call    L_BA96
        call    L_BAB4
        call    L_913E
        set     7,(iy-44)
        inc     (iy-109)
        jr      nz,L_9016
        inc     (iy-108)
.L_9016
        ld      a,(iy-108)
        cp      (iy-53)
        jr      c,L_902A
        jr      nz,L_902F
        ld      a,(iy-109)
        cp      (iy-54)
        jr      z,L_902A
        jr      nc,L_902F
.L_902A
        call    L_D79A
        jr      L_8FD9
.L_902F
        call    L_BA96
        call    L_BAFB
        call    L_90B6
        or      a
        ret
.L_903A
        push    bc
        bit     7,(iy-44)
        jr      z,L_9047
        call    L_BB41
        call    L_90FE
.L_9047
        pop     bc
.L_9048
        call    L_EB07
        call    L_D357
        scf
        ret
.L_9050
        call    L_91DE
        jr      c,L_9048
        call    L_91FD
        call    L_91F1
        call    L_90E0
        ld      a,(iy-61)
        cp      (iy-58)
        jr      nz,L_90B6
        ld      a,(iy-59)
        cp      (iy-53)
        jr      c,L_90B6
        jr      nz,L_907A
        ld      a,(iy-60)
        cp      (iy-54)
        jr      c,L_90B6
        jr      z,L_90B6
.L_907A
        call    L_9183
        ld      a,(iy-60)
        add     a,c
        ld      (iy-60),a
        ld      a,(iy-59)
        adc     a,b
        ld      (iy-59),a
        jr      L_90B6
.L_908D
        call    L_9238
        ret     c
        call    L_91F1
        call    L_9244
        call    L_91FD
        call    L_90E0
        call    L_B78A
        set     7,(iy-58)
        call    L_9183
        xor     a
        call    L_B7BE
        call    L_BB41
        call    L_90FE
        res     7,(iy-58)
        ret
.L_90B6
        call    L_BB41
        call    L_BAF1
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_BA73
        call    L_BA44
        call    L_BB41
        call    L_BB5F
        call    L_BA44
        call    L_BB4B
        call    L_BB55
        call    L_BA44
        jp      L_B9C6
.L_90E0
        call    L_BB4B
        call    L_BB69
        call    L_BA44
        call    L_BB37
        call    L_BB55
        call    L_BA44
        call    L_BB4B
        call    L_BB55
        call    L_BA44
        jp      L_B9C6
.L_90FE
        call    L_BAB4
        call    L_BAAA
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      b,(hl)
        dec     hl
        dec     hl
        call    L_BA44
        push    de
        push    bc
        call    L_B990
        ld      c,b
        ld      b,$00
        call    L_D95E
        pop     bc
        ld      c,b
        pop     hl
        ld      a,l
        or      h
        jr      nz,L_90FE
        ret
.L_9128
        call    L_B0C0
        ld      (iy-42),a
        call    L_B990
        ld      a,b
        call    L_B53C
        ld      (iy-40),a
        call    L_9148
        ldir
        ret
.L_913E
        call    L_B518
        call    L_9148
        ex      de,hl
        ldir
        ret
.L_9148
        ld      a,(iy-40)
        bit     7,(iy-42)
        jr      nz,L_9153
        add     a,$06
.L_9153
        push   ix
        pop     hl
        ld      bc,$0004
        add     hl,bc
        ld      c,a
        ld      b,$00
        ld      de,$1DAA
        ret
.L_9161
        ld      a,(iy-104)
        ld      (iy-58),a
        ld      a,(iy-61)
        ld      (iy-55),a
        ld      a,(iy-60)
        ld      (iy-57),a
        scf
        sbc     a,c
        ld      (iy-54),a
        ld      a,(iy-59)
        ld      (iy-56),a
        sbc     a,b
        ld      (iy-53),a
        ret
.L_9183
        ld      a,(iy-57)
        scf
        sbc     a,(iy-54)
        ld      c,a
        ld      a,(iy-56)
        sbc     a,(iy-53)
        ld      b,a
        ret
.L_9193
        xor     a
        sub     c
        ld      c,a
        ld      a,$00
        sbc     a,b
        ld      b,a
        ret
.L_919B
        ld      a,(iy-61)
        sub     (iy-58)
        push    af
        ld      a,(iy-60)
        sub     (iy-57)
        ld      c,a
        ld      a,(iy-59)
        sbc     a,(iy-56)
        ld      b,a
        pop     af
        ret
.L_91B2
        push    bc
        ld      e,b
        call    L_D0E2
        add     a,e
        call    L_D797
        jr      nc,L_91C3
        call    L_B8B6
        call    L_B8C7
.L_91C3
        pop     bc
        jp      c,L_EB07
        push    bc
        ld      e,b
        call    L_D0E2
        add     a,e
        ld      (iy-61),a
        ld      (iy-60),c
        ld      (iy-59),b
        inc     e
        dec     e
        call    z,L_82A2
        pop     bc
        or      a
        ret
.L_91DE
        call    L_9244
        ret     nc
        call    L_B8B6
        ld      a,(iy-58)
        ld      c,(iy-54)
        ld      b,(iy-53)
        jp      L_B8C4
.L_91F1
        ld      a,(iy-58)
        ld      c,(iy-57)
        ld      b,(iy-56)
        jp      L_BA73
.L_91FD
        ld      a,(iy-58)
        call    L_BAC8
        call    L_BAFB
        jp      L_BB19
.L_9209
        pop     de
        ld      ($1D4B),de
        call    L_B398
        call    L_9250
        call    L_B3B8
        ld      a,(iy-55)
        sub     (iy-58)
        ld      c,a
        ld      b,$00
        ld      hl,($1D4B)
.L_9223
        jp      (hl)
.L_9224
        call    L_D0E5
        cp      (iy-58)
        ret     z
        ret     c
        cp      (iy-55)
        jr      z,L_9232
        ret     nc
.L_9232
        pop     de
        ld      c,$23
        jp      L_EB07
.L_9238
        ld      a,(iy-58)
        ld      c,(iy-57)
        ld      b,(iy-56)
        jp      L_D797
.L_9244
        ld      a,(iy-58)
        ld      c,(iy-54)
        ld      b,(iy-53)
        jp      L_D7AD
.L_9250
        call    L_D014
        ret     nc
        ld      c,$09
        call    L_EB07
        pop     de
        ret
.L_925B
        call    L_B398
        bit     6,(iy-71)
        ret     nz
        call    L_B56E
        call    L_D7AA
        jr      c,L_9276
        ld      a,(ix+3)
        and     $C0
        cp      $C0
        ret     z
        call    L_BB7B
.L_9276
        call    L_D0E2
        ld      (iy-107),a
        ld      (iy-106),c
        ld      (iy-105),b
        set     6,(iy-71)
        ld      hl,($1D63)
        call    L_CA39
        call    L_8687
        call    L_B569
        call    L_EF91
        jp      L_8D45
.L_9298
        call    L_B398
.L_929B
        ld      a,$0B
        call    L_EF80
        xor     a
        ld      (iy-110),a
.L_92A4
        ld      (iy-109),a
        ld      (iy-108),a
.L_92AA
        call    L_D79A
        jr      c,L_92CD
        ld      a,(ix+3)
        bit     7,a
        jr      nz,L_92C5
        push    af
        and     $20
        jr      nz,L_92C1
        bit     4,(iy-72)
        jr      z,L_92C4
.L_92C1
        call    L_B575
.L_92C4
        pop     af
.L_92C5
        and     $20
        jr      z,L_92CC
        call    L_C9CA
.L_92CC
        or      a
.L_92CD
        bit     4,(iy-69)
        jr      z,L_92F4
        jr      c,L_92DF
        inc     (iy-109)
        jr      nz,L_92AA
        inc     (iy-108)
        jr      L_92AA
.L_92DF
        call    L_EF34
        call    L_9313
        ld      a,$00
        jr      nc,L_92A4
.L_92E9
        res     1,(iy-72)
        res    4,(iy-72)
        jp      L_EFBB
.L_92F4
        call    L_9313
        jr      nc,L_92AA
        call    L_EF34
        ld      (iy-110),$00
        ld      c,(iy-109)
        ld      b,(iy-108)
        call    L_CA1E
        jr      z,L_92E9
        ld      (iy-109),c
        ld      (iy-108),b
        jr      L_92AA
.L_9313
        inc     (iy-110)
        ld      a,(iy-110)
        cp      (iy-98)
        ccf
        ret
.L_931E
        call    L_B388
        call    L_98DC
        ret     nz
        call    L_98CD
        call    L_D749
        jp      L_CA8D

.L_932E
        defm    $01, $01, "New name of file", $00
        defm    $00
        defm    $00

.L_9343
        call    L_B398
        call    L_936E
        ld      hl,L_932E
        call    L_D98A
        ret     c
        ld      hl,$1FAA
        call    L_DFD3
        jr      z,L_9366
        call    L_ED32
        call    L_A05A
        call    L_ED3F
        set     3,(iy-71)
        ret
.L_9366
        call    L_A05A
        res     3,(iy-71)
        ret
.L_936E
        ld      hl,$1FAA
        ld      (hl),$00
        bit     3,(iy-71)
        call    nz,L_ED2A
        ret

.L_937B
        defm    $04, "AName of file to load", $00
        defm    $00
        defm    $82, "Insert at slot", $00
        defm    $81, $83, "Limit to range of rows", $00
        defm    $82, $84, "Load as plain text", $00
        defm    $84, $00

.L_93D3
        call    L_B398
        ld      hl,$1FAA
        ld      (hl),$00
        ld      hl,L_937B
        call    L_D98A
        ret     c
        ld      (iy-102),a
        bit     0,a
        jr      nz,L_9411
        bit     0,(iy-71)
        jr      z,L_93F3
        call    L_98DC
        ret     nz
.L_93F3
        call    L_ED32
        call    L_98CD
        bit     2,(iy-102)
        call    nz,L_D749
        scf
        call    L_9F34
        jp      pe,L_9416
        jr      c,L_940E
        call    L_A019
        jr      L_9411
.L_940E
        call    L_ED2A
.L_9411
        call    L_9444
        scf
        ccf
.L_9416
        call    pe,L_EB07
        call    L_CA8D
.L_941C
        push    af
        ld      a,(iy-98)
        or      a
        call    z,L_D749
        pop     af
        ret
.L_9426
        ld      a,(iy-73)
        or      a
        jp      z,L_F994
        call    L_999B
        ret     pe
        call    L_A019
.L_9434
        call    L_9CB6
.L_9437
        call    L_98D6
        call    L_D6D9
        call    L_A01D
        ld      (iy-102),$00
.L_9444
        xor     a
        ld      (iy+3),a
        ld      (iy+4),a
        ld      b,a
        ld      c,a
        bit     0,(iy-102)
        jr      z,L_945F
        ld      a,(iy+56)
        ld      c,(iy+57)
        ld      b,(iy+58)
        call    L_985D
.L_945F
        call    L_D77E
        ld      a,$00
        call    L_EF80
        ld      (iy+2),$00
        call    L_9EE7
        ld      bc,$0032
        ld      de,$1FAA
        ld      a, OP_IN
        ld      hl,$1FAA
        oz      Gn_opf
        jr      nc,L_948B
        ld      c,$14
        cp      $12
        call    L_F9B7
        call    nz,L_9FFF
        jp      L_95C4
.L_948B
        bit     0,(iy-102)
        call    z,L_ED32
        ld      ($1D57),ix
        jr      L_94BF
.L_9498
        call    L_967B
        jr      nc,L_94A3
        call    L_F9B7
        jp      L_95C4
.L_94A3
        bit     2,(iy-102)
        jr      z,L_94B7
        inc     (iy-110)
        ld      a,(iy+2)
        cp      $09
        jr      z,L_94BF
        ld      (iy-110),$00
.L_94B7
        inc     (iy-109)
        jr      nz,L_94BF
        inc     (iy-108)
.L_94BF
        call    L_EF34
        call    L_B8C0
        ld      (iy-43),b
        ld      (iy-40),c
        xor     a
        ld      (iy-44),a
        ld      (iy-4),a
        ld      (iy-3),a
        ld      (iy-52),a
        ld      (iy-9),a
        ld      hl,($1D3D)
.L_94DE
        ld      de,($1D3D)
        or      a
        sbc     hl,de
        ld      a,l
        add     hl,de
        cp      $F3
        jr      z,L_951C
.L_94EB
        push    hl
        call    L_9D78
        pop     hl
        jp      pe,L_95C4
        jp      c,L_95AC
        ld      c,(iy+2)
.L_94F9
        ld      (iy+2),a
        or      a
        jr      z,L_94EB
        call    L_FE32
        jr      c,L_94EB
        cp      $0A
        jr      z,L_9514
        cp      $0D
        jr      nz,L_951D
        ld      e,a
        ld      a,c
        cp      $0A
        ld      a,e
        jr      nz,L_951C
        ld      c,a
.L_9514
        xor     a
        ld      e,a
        ld      a,c
        cp      $0D
        ld      a,e
        jr      z,L_94F9
.L_951C
        xor     a
.L_951D
        cp      $09
        jr      nz,L_9528
        bit     2,(iy-102)
        jr      z,L_9528
        xor     a
.L_9528
        ld      (hl),a
        inc     hl
        or      a
        jp      z,L_9498
        ld      c,(iy-4)
        cp      $25
        jr      nz,L_9599
        bit     2,(iy-102)
        jr      nz,L_9599
        inc     (iy-4)
        ld      a,c
        or      a
        jr      nz,L_954C
        dec     hl
        ld      (iy-52),l
        ld      (iy-51),h
        inc     hl
        jr      L_94DE
.L_954C
        push    hl
        call    L_973C
        ex      de,hl
        pop     hl
        jr      c,L_95A4
        ld      a,(ix+1)
        bit     7,a
        jr      z,L_957C
        push    hl
        ex      de,hl
        and     $7F
        ld      e,a
        ld      d,$00
        ld      ix,L_97CE
        add     ix,de
        ld      e,(ix+0)
        ld      d,(ix+1)
        push    de
        pop     ix
        call    L_B8B4
        pop     hl
        jp      pe,L_95C4
        jr      nc,L_9591
        jr      L_95A4
.L_957C
        push    hl
        ld      de,$FFD4
        push    iy
        pop     hl
        add     hl,de
        ld      e,a
        ld      d,$00
        add     hl,de
        ld      a,(hl)
        and     (ix+2)
        or      (ix+3)
        ld      (hl),a
        pop     hl
.L_9591
        ld      l,(iy-52)
        ld      h,(iy-51)
        jr      L_95A4
.L_9599
        ld      a,c
        or      a
        jp      z,L_94DE
        inc     c
        inc     a
        cp      $0F
        jr      c,L_95A6
.L_95A4
        ld      c,$00
.L_95A6
        ld      (iy-4),c
        jp      L_94DE
.L_95AC
        ld      a,(iy+2)
        cp      $0D
        jr      z,L_95C1
        cp      $0A
        jr      z,L_95C1
        ld      (hl),$00
        call    L_967B
        call    L_F9B7
        jr      c,L_95C4
.L_95C1
        call    L_F994
.L_95C4
        push    bc
        push    af
        call    L_EFBB
        call    L_941C
        call    L_9E30
        call    L_E7CA
        call    L_8FC1
        pop     af
        pop     bc
        call    L_9FE2
        jp      po,L_95ED
        bit     0,(iy-102)
        call    L_F9B7
        ret     nz
        push    af
        push    bc
        call    L_A05A
        pop     bc
        pop     af
        ret
.L_95ED
        push    af
        ld      a,(iy-71)
        bit     0,(iy-102)
        jr      nz,L_9608
        set     3,a
        res     0,a
        push    af
        call    L_ED3F
        xor     a
        ld      c,a
        ld      b,a
        call    L_82A2
        pop     af
        jr      L_960A
.L_9608
        set     0,a
.L_960A
        ld      (iy-71),a
        pop     af
.L_960E
        ret
.L_960F
        or      a
        bit     0,(iy-102)
        ret     nz
        ld      l,(iy-10)
        ld      h,(iy-9)
        dec     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
.L_961F
        inc     hl
        ld      a,(hl)
        or      a
        jr      nz,L_961F
        dec     hl
        dec     hl
        ld      de,($1D3D)
        or      a
        sbc     hl,de
        ld      a,l
        or      a
        ret     z
        ld      hl,$1D43
        call    L_EA9C
        jr      c,L_9670
        ld      l,(iy-10)
        ld      h,(iy-9)
        inc     hl
        call    L_E775
        or      a
        ret
.L_9644
        inc     (iy+3)
        jr      nz,L_964C
        inc     (iy+4)
.L_964C
        ld      c,(iy+3)
        ld      b,(iy+4)
        ld      a,b
        cp      (iy+52)
        ccf
        ret     nc
        jr      nz,L_9660
        ld      a,c
        cp      (iy+51)
        ccf
        ret     nc
.L_9660
        ld      a,b
        cp      (iy+55)
        jr      c,L_9687
        ret     nz
        ld      a,c
        cp      (iy+54)
        jr      z,L_9687
        jr      c,L_9687
        ret
.L_9670
        ld      a,(iy-5)
        or      a
        jr      nz,L_9678
        scf
        ret
.L_9678
        call    L_9E30
.L_967B
        ld      a,(iy-9)
        or      a
        jr      nz,L_960F
        bit     1,(iy-102)
        jr      nz,L_9644
.L_9687
        ld      b,$02
        ld      d,(iy-43)
        ld      a,d
        and     $C0
        cp      $C0
        jr      z,L_96BE
        push    de
        ld      e,(iy-44)
        push    de
        scf
        bit     7,(iy-43)
        jr      nz,L_96A0
        or      a
.L_96A0
        call    L_BC66
        pop     de
        ld      (iy-44),e
        pop     de
        ld      a,d
        jr      c,L_96B6
        jp      po,L_96B1
        or      $20
        ld      d,a
.L_96B1
        ld      a,b
        cp      $01
        jr      nz,L_96BE
.L_96B6
        ld      d,$80
        ld      hl,($1D3D)
        ld      (hl),$00
        inc     hl
.L_96BE
        ld      (iy-40),b
        ld      (iy-42),d
        bit     0,(iy-102)
        jr      z,L_96D4
        call    L_8CAE
        jr      c,L_9670
        call    L_B3C1
        jr      L_96DD
.L_96D4
        dec     b
        jr      z,L_973A
        call    L_B8C7
        jp      c,L_9670
.L_96DD
        ld      a,(iy-42)
        and     $C0
        cp      $C0
        jr      nz,L_96F6
        ld      hl,($1D3D)
        inc     hl
        inc     hl
        call    L_EE29
        call    L_B518
        ld      (ix+5),c
        jr      L_96F9
.L_96F6
        call    L_B490
.L_96F9
        bit     7,(iy-42)
        jr      nz,L_9708
        call    L_B518
        ld      a,(iy-44)
        ld      (ix+9),a
.L_9708
        bit     0,(iy-102)
        jr      z,L_973A
        ld      bc,L_960E
        call    L_B78D
        ld      e,(iy-110)
        push    de
        ld      (iy-55),e
        ld      e,(iy-109)
        ld      d,(iy-108)
        push    de
        ld      (iy-54),e
        ld      (iy-53),d
        xor     a
        ld      c,$01
        ld      b,a
        call    L_B7BE
        pop     de
        ld      (iy-108),d
        ld      (iy-109),e
        pop     de
        ld      (iy-110),e
.L_973A
        or      a
        ret
.L_973C
        ld      a,(iy-4)
        cp      $03
        ret     c
        ld      ix,L_977B-1
.L_9746
        ld      l,(iy-52)
        ld      h,(iy-51)
.L_974C
        inc     hl
        inc     ix
        ld      a,(ix+0)
        and     $7F
        cp      (hl)
        jr      nz,L_9767
        bit     7,(ix+0)
        jr      z,L_974C
        inc     hl
        ld      a,(hl)
        call    L_EE1B
        ret     nc
        dec     ix
.L_9765
        inc     ix
.L_9767
        bit     7,(ix+0)
        jr      z,L_9765
        inc     ix
        inc     ix
        inc     ix
        ld      a,(ix+1)
        or      a
        jr      nz,L_9746
        scf
        ret

.L_977B
        defb    $D6,$01,$3F,$00,$4A,$CC,$01,$F1
        defb    $0C,$4A,$D2,$01,$F1,$0E,$CC,$01
        defb    $F1,$02,$D2,$01,$F1,$06,$C3,$01
        defb    $F1,$04,$4C,$43,$D2,$01,$F1,$08
        defb    $D0,$01,$31,$C0,$43,$CF,$80,$00
        defb    $00,$C8,$82,$00,$00,$C4,$84,$00
        defb    $00,$C2,$00,$7F,$80,$4C,$C3,$00
        defb    $DF,$20,$54,$C3,$00,$EF,$10,$C6
        defb    $01,$F1,$00,$4F,$D0,$86,$00,$00
        defb    $50,$C3,$88,$00,$00,$44,$C6,$00
        defb    $B0,$4F,$00
.L_97CE
        defw    L_97D8
        defw    L_9878
        defw    L_989F
        defw    L_98BC
        defw    L_9874
.L_97D8
        inc     hl
        ld      e,(iy-110)
        push    de
        call    L_BD91
        pop     de
        jr      c,L_9856
        ld      c,e
        xor     a
        ld      (iy+3),a
        ld      (iy+4),a
        bit     0,(iy-102)
        jr      nz,L_9817
        push    hl
        ld      a,(iy-110)
        call    L_D8BF
        pop     hl
        jr      c,L_9859
        inc     hl
        call    L_EE29
        jr      z,L_9812
        push    hl
        call    L_984D
        ld      (hl),c
        pop     hl
        inc     hl
        call    L_EE29
        jr      z,L_9812
        call    L_984D
        inc     hl
        ld      (hl),c
.L_9812
        ld      bc,$0000
        jr      L_9843
.L_9817
        ld      a,(iy-110)
        or      $80
        bit     7,(iy+56)
        jr      z,L_9833
        sub     (iy+56)
        add     a,c
        ld      c,a
        jr      c,L_982E
        cp      $40
        ccf
        jr      nc,L_9836
.L_982E
        ld      c,$1D
        jp      L_F9B7
.L_9833
        ld      (iy+56),a
.L_9836
        ld      (iy-110),c
        ld      a,c
        ld      c,(iy+57)
        ld      b,(iy+58)
        call    L_985D
.L_9843
        ld      (iy-109),c
        ld      (iy-108),b
        or      a
        jp      L_F994
.L_984D
        push    af
        ld      a,(iy-110)
        call    L_D890
        pop     af
        ret
.L_9856
        ld      (iy-110),e
.L_9859
        scf
        jp      L_F994
.L_985D
        ld      (iy-55),a
        ld      (iy-54),c
        ld      (iy-53),b
        or      $80
        ld      (iy-58),a
        ld      (iy-57),c
        ld      (iy-56),b
        and     $7F
        ret
.L_9874
        ld      a,$25
        jr      L_988C
.L_9878
        call    L_EE29
        jr      z,L_9859
        ld      a,b
        cp      $01
        jr      nc,L_9859
        ld      a,c
        cp      $0A
        jr      nc,L_9859
        or      a
        jr      z,L_9859
        add     a,$17
.L_988C
        ld      l,(iy-52)
        ld      h,(iy-51)
        ld      (hl),a
        inc     (iy-52)
        jr      nz,L_989B
        inc     (iy-51)
.L_989B
        or      a
        jp      L_F994
.L_989F
        call    L_EE29
        jr      z,L_9859
        ld      a,b
        cp      $01
        jr      nc,L_9859
        ld      a,c
        cp      $0B
        jr      nc,L_9859
        ld      a,(iy-44)
        and     $B0
        or      c
        or      $40
        ld      (iy-44),a
        jp      L_F994
.L_98BC
        ld      l,(iy-52)
        ld      h,(iy-51)
        inc     hl
        ld      (iy-10),l
        ld      (iy-9),h
        or      a
        jp      L_F994
.L_98CD
        call    L_A05A
        call    L_98D6
        jp      L_D6CB
.L_98D6
        call    L_A072
        jp      L_A093
.L_98DC
        call    L_B2C2
        oz      Os_Pout
        defm    "Overwrite text?", $00

        call    L_E006
        push    af
        call    L_EFD5
        pop     af
        jr      c,L_9901
        and     $DF
        cp      $59
        ret
.L_9901
        ld      a,$4D
        inc     a
        ret

.L_9905
        defm    $05, $01, "Name of file to save", $00
        defm    $00
        defm    $85, "Save only range of columns", $00
        defm    $81, $86, "Save selection of rows", $00
        defm    $82, $84, "Save marked block", $00
        defm    $88, $84, "Save plain text", $00
        defm    $84, $00

.L_997A
        bit     3,a
        ret     nz
        or      $40
        ret
.L_9980
        call    L_B398
        call    L_936E
        bit     3,(iy-70)
        call    nz,L_A01D
        ld      hl,L_9905
        call    L_D98A
        ret     c
        call    L_99AF
        jp      pe,L_EB07
        ret
.L_999B
        call    L_A01D
        bit     0,(iy-71)
        jp      z,L_F994
        ld      c,$1C
        bit     3,(iy-71)
        jp      z,L_F9B7
        xor     a
.L_99AF
        call    L_997A
        call    L_B2CC
        ld      (iy-102),a
        bit     3,a
        jr      z,L_99C5
        ld      c,$09
        bit     7,a
        and     $80
        jp      z,L_F9B7
.L_99C5
        call    L_FBBD
        call    L_9EE7
        ld      bc,$0011
        ld      de,$0003
        ld      a, OP_OUT
        ld      hl,$1FAA
        oz      Gn_opf
        jp      c,L_9FFF
        ld      ($1D57),ix
        ld      a,$04
        call    L_EF80
        ld      a,(iy-102)
        and     $84
        jr      nz,L_9A27
        ld      a,$01
        ld      (iy-42),a
.L_99F1
        call    L_E7A5
        call    L_E783
        call    L_EA7C
        jr      nc,L_9A1D
        push   ix
        ld      bc,$504F
        call    L_9CDF
        pop     hl
        jp      pe,L_9AEA
        inc     hl
        inc     hl
.L_9A0A
        inc     hl
        ld      a,(hl)
        or      a
        jr      nz,L_9A11
        ld      a,$0D
.L_9A11
        push    hl
        call    L_9CE4
        pop     hl
        jp      pe,L_9AEA
        ld      a,(hl)
        or      a
        jr      nz,L_9A0A
.L_9A1D
        inc     (iy-42)
        ld      a,(iy-42)
        cp      $17
        jr      c,L_99F1
.L_9A27
        bit     2,(iy-102)
        jr      nz,L_9A65
        ld      bc,$4F43
        call    L_9CCB
        ld      a,$3A
        call    L_EE66
        ld      c,(iy-74)
        ld      a,(iy-61)
        call    L_BC3B
        ld      a,$2C
        call    L_EE66
        ld      a,(iy-61)
        call    L_D54A
        call    L_EE82
        ld      a,$2C
        call    L_EE66
        ld      a,(iy-61)
        call    L_D890
        inc     hl
        ld      a,(hl)
        call    L_EE82
        call    L_9D00
        jp      pe,L_9AEA
.L_9A65
        call    L_EF34
        bit     1,(iy-102)
        jr      z,L_9A73
        call    L_B30E
        jr      c,L_9AB5
.L_9A73
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D7AD
        jr      c,L_9A87
        call    L_9B06
        jp      pe,L_9AEA
.L_9A87
        bit     2,(iy-102)
        jr      z,L_9AA3
        ld      a,(iy-61)
        inc     (iy-61)
        cp      (iy-55)
        jr      nc,L_9AA7
        ld      a,$09
        call    L_9D1A
        jp      pe,L_9AEA
        jp      L_9A27
.L_9AA3
        jr      c,L_9AC8
        jr      L_9AAD
.L_9AA7
        ld      a,(iy-58)
        ld      (iy-61),a
.L_9AAD
        ld      a,$0D
        call    L_9D1A
        jp      pe,L_9AEA
.L_9AB5
        inc     (iy-60)
        jr      nz,L_9ABD
        inc     (iy-59)
.L_9ABD
        call    L_FBF2
        jr      c,L_9A65
        bit     2,(iy-102)
        jr      nz,L_9AE7
.L_9AC8
        bit     1,(iy-102)
        call    nz,L_B368
        ld      a,(iy-57)
        ld      (iy-60),a
        ld      a,(iy-56)
        ld      (iy-59),a
        ld      a,(iy-61)
        inc     (iy-61)
        cp      (iy-55)
        jp      c,L_9A27
.L_9AE7
        call    L_9EC5
.L_9AEA
        push    bc
        push    af
        call    L_9E30
        call    L_EFBB
        pop     af
        pop     bc
        call    L_9FE2
        ret     pe
        ld      a,(iy-102)
        and     $83
        call    L_F994
        ret     nz
        res     0,(iy-71)
        ret
.L_9B06
        ld      a,(ix+3)
        bit     7,a
        jr      z,L_9B22
        and     $C0
        cp      $C0
        jr      nz,L_9B33
        bit     2,(iy-102)
        jp      nz,L_F994
        ld      c,(ix+5)
        ld      a,$50
        jp      L_9CF5
.L_9B22
        bit     2,(iy-102)
        jp      nz,L_9BAA
        ld      a,$56
        push   ix
        call    L_9CDC
        pop     ix
        ret     pe
.L_9B33
        bit     2,(iy-102)
        jr      nz,L_9B6E
        ld      a,(ix+3)
        and     $0E
        srl     a
        call    L_9BC7
        or      a
        jr      z,L_9B6E
        push    af
        push   ix
        call    L_9D18
        pop     ix
        pop     de
        ret     pe
        ld      a,d
.L_9B51
        push    af
        call    L_9BC7
        push    af
        and     $7F
        call    L_9D1A
        pop     de
        rl      d
        pop     de
        ld      a,d
        ret     pe
        jr      c,L_9B66
        inc     a
        jr      L_9B51
.L_9B66
        push   ix
        call    L_9D18
        pop     ix
        ret     pe
.L_9B6E
        bit     7,(ix+3)
        jr      nz,L_9BAA
        ld      a,$80
        ld      c,$42
        call    L_9BB4
        ret     pe
        ld      a,$20
        ld      c,$4C
        call    L_9BB0
        ret     pe
        ld      a,$10
        ld      c,$54
        call    L_9BB0
        ret     pe
        ld      c,(ix+9)
        ld      a,c
        and     $40
        jr      z,L_9BAA
        ld      a,c
        and     $0F
        ld      c,a
        cp      $0F
        jr      nz,L_9BA4
        ld      bc,$4644
        call    L_9CDF
        jr      L_9BA9
.L_9BA4
        ld      a,$44
        call    L_9CF5
.L_9BA9
        ret     pe
.L_9BAA
        ld      bc,L_9BE2
        jp      L_BB7E
.L_9BB0
        ld      b,$43
        jr      L_9BB6
.L_9BB4
        ld      b,$00
.L_9BB6
        call    L_9CCB
        and     (ix+9)
        jp      z,L_F994
        push   ix
        call    L_9D00
        pop     ix
        ret
.L_9BC7
        ld      e,a
        ld      d,$00
        ld      hl,L_9BD0
        add     hl,de
        ld      a,(hl)
        ret

.L_9BD0
        defb    $00,$08,$09,$0A,$0B,$00,$0E,$10
        defb    $CC,$C3,$D2,$4C,$43,$D2,$4A,$CC
        defb    $4A,$D2
.L_9BE2
        push    af
        push    bc
        push    de
        push    hl
        or      a
        jr      z,L_9C01
        cp      $25
        jr      nz,L_9BFB
        bit     2,(iy-102)
        jr      nz,L_9BFB
        ld      bc,$4350
        call    L_9CDF
        jr      L_9BFE
.L_9BFB
        call    L_9CE4
.L_9BFE
        jp      pe,L_9C08
.L_9C01
        pop     hl
        pop     de
        pop     bc
        pop     af
        jp      L_F994
.L_9C08
        ld      sp,($1D47)
        ret
.L_9C0D
        call    L_B398
        call    L_9C60
.L_9C13
        call    L_A004
        ret     nc
        call    L_9C4F
        jr      nc,L_9C13
        ret
.L_9C1D
        call    L_B398
        call    L_9C60
        call    L_A00A
        jp      nc,L_EB07
        push    af
        call    L_999B
        pop     de
        jp      pe,L_EB07
        ld      (iy-73),d
        call    L_9434
        jp      pe,L_EB07
        or      a
        ret
.L_9C3C
        call    L_B398
        call    L_9C60
        call    L_9426
        jp      pe,L_EB07
        ret
.L_9C49
        call    L_B398
        call    L_9C60
.L_9C4F
        call    L_9C6B
        jp      pe,L_EB07
        jp      c,L_EB07
        call    L_9437
        jp      pe,L_EB07
        or      a
        ret
.L_9C60
        bit     3,(iy-70)
        ret     nz
        pop     de
        ld      c,$1A
        jp      L_EB07
.L_9C6B
        call    L_A03C
        call    L_A004
        ccf
        jp      c,L_F994
        push    af
        call    L_999B
        pop     de
        scf
        ccf
        ret     pe
        ld      (iy-73),d
        call    L_D3F0
        xor     a
        ld      (iy-20),a
        ld      (iy-19),a
        ld      a,(iy-97)
        ld      (iy-26),a
        ld      a,(iy-96)
        ld      (iy-25),a
        call    L_D35D
        ld      a,(iy-94)
        jr      nc,L_9CA0
        ld      a,$00
.L_9CA0
        ld      (iy+12),a
        ld      c,(iy-93)
        ld      b,(iy-92)
        jr      nc,L_9CAC
        dec     bc
.L_9CAC
        ld      (iy+10),c
        ld      (iy+11),b
        or      a
        jp      L_F994
.L_9CB6
        call    L_A051
        call    L_EA7C
        ld      a,(hl)
        ld      (iy+12),a
        inc     hl
        ld      a,(hl)
        ld      (iy+10),a
        inc     hl
        ld      a,(hl)
        ld      (iy+11),a
        ret
.L_9CCB
        ld      (iy+35),c
        ld      c,$01
        inc     b
        dec     b
        jr      z,L_9CD8
        inc     c
        ld      (iy+36),b
.L_9CD8
        ld      (iy-74),c
        ret
.L_9CDC
        ld      c,a
        ld      b,$00
.L_9CDF
        call    L_9CCB
        jr      L_9D00
.L_9CE4
        call    L_CE2A
        jr      nc,L_9D1A
        bit     2,(iy-102)
        jp      nz,L_F994
        sub     $17
        ld      c,a
        ld      a,$48
.L_9CF5
        ld      l,c
        ld      h,$00
        ld      (iy+35),a
        ld      a,$01
        call    L_EE88
.L_9D00
        call    L_9D18
        ret     pe
        ld      de,$0022
        push    iy
        pop     hl
        add     hl,de
.L_9D0B
        inc     hl
        push    hl
        ld      a,(hl)
        call    L_9D1A
        pop     hl
        ret     pe
        dec     (iy-74)
        jr      nz,L_9D0B
.L_9D18
        ld      a,$25
.L_9D1A
        push    af
        cp      $09
        jr      nz,L_9D2C
        bit     2,(iy-102)
        jr      z,L_9D47
        inc     (iy+5)
        pop     af
        jp      L_F994
.L_9D2C
        cp      $0D
        jr      z,L_9D43
        ld      a,(iy+5)
        or      a
        jr      z,L_9D47
        ld      b,a
.L_9D37
        push    bc
        ld      a,$09
        call    L_9D48
        pop     bc
        pop     de
        ret     pe
        push    de
        djnz    L_9D37
.L_9D43
        ld      (iy+5),$00
.L_9D47
        pop     af
.L_9D48
        push    af
        ld      a,(iy-103)
        or      a
        jr      z,L_9D5F
        ld      a,(iy-8)
        or      (iy-7)
        jr      nz,L_9D6E
        call    L_9EC5
        pop     de
        ret     pe
        push    de
        jr      L_9D62
.L_9D5F
        call    L_9E84
.L_9D62
        ld      a,(iy-14)
        ld      (iy-8),a
        ld      a,(iy-13)
        ld      (iy-7),a
.L_9D6E
        pop     af
        ld      l,(iy-12)
        ld      h,(iy-11)
        ld      (hl),a
        jr      L_9D93
.L_9D78
        ld      a,(iy-103)
        or      a
        jr      z,L_9D86
        ld      a,(iy-8)
        or      (iy-7)
        jr      nz,L_9D8B
.L_9D86
        call    L_9DAB
        ret     pe
        ret     c
.L_9D8B
        ld      l,(iy-12)
        ld      h,(iy-11)
        ld      a,(hl)
        or      a
.L_9D93
        inc     (iy-12)
        jr      nz,L_9D9B
        inc     (iy-11)
.L_9D9B
        ld      e,(iy-8)
        inc     e
        dec     e
        jr      nz,L_9DA5
        dec     (iy-7)
.L_9DA5
        dec     (iy-8)
        jp      L_F994
.L_9DAB
        ld      a,(iy-103)
        or      a
        scf
        call    z,L_9E84
        call    L_9E53
        ld      ix,($1D57)
        ld      a, FA_PTR
        ld      de,0
        oz      Os_frm
        jp      c,L_9FFF
        ld      l,(iy-2)
        ld      h,(iy-1)
        sbc     hl,bc
        jr      nz,L_9DE4
        ld      l,(iy+0)
        ld      h,(iy+1)
        sbc     hl,de
        jr      nz,L_9DE4
        ld      a,$04
        bit     7,(iy-6)
        scf
        jp      nz,L_F994
        jr      L_9DF2
.L_9DE4
        ld      de,$FFFE
        push    iy
        pop     hl
        add     hl,de
        ld      a, FA_PTR
        oz      Os_fwm
        jp      c,L_9FFF
.L_9DF2
        ld      c,(iy-14)
        ld      b,(iy-13)
        ld      hl,0
        ld      e,(iy-104)
        ld      d,(iy-103)
        ld      (iy-12),e
        ld      (iy-11),d
        oz      Os_mv
        ld      l,(iy-14)
        ld      h,(iy-13)
        jr      nc,L_9E17
        cp      RC_EOF
        jp      nz,L_9FFF
        scf
.L_9E17
        rr      e
        or      a
        sbc     hl,bc
        ld      (iy-8),l
        ld      (iy-7),h
        scf
        jp      z,L_F994
        rl      e
        rr      (iy-6)
        or      a
        jp      L_F994
.L_9E30
        ld      a,(iy-5)
        or      a
        ret     z
        ld      a,(iy-103)
        or      a
        ret     z
        call    L_9E53
        ld      l,(iy-104)
        ld      h,(iy-103)
        xor     a
        ld      (iy-103),a
        ld      (iy-5),a
        ld      c,(iy-14)
        ld      b,(iy-13)
        jp      L_D976
.L_9E53
        call    L_9E75
        ld      l,(iy-2)
        ld      h,(iy-1)
        add     hl,bc
        ld      (iy-2),l
        ld      (iy-1),h
        ld      bc,$0000
        ld      l,(iy+0)
        ld      h,(iy+1)
        adc     hl,bc
        ld      (iy+0),l
        ld      (iy+1),h
        ret
.L_9E75
        ld      a,(iy-12)
        sub     (iy-104)
        ld      c,a
        ld      a,(iy-11)
        sbc     a,(iy-103)
        ld      b,a
        ret
.L_9E84
        push    af
        ld      ix,($1D39)
        ld      bc, NQ_Mfs
        oz      Os_nq
        pop     af
        jr      nc,L_9E95
        srl     d
        srl     d
.L_9E95
        ld      a,d
        or      a
        jr      z,L_9EAA
        ld      (iy-14),e
        ld      (iy-13),d
        ld      c,e
        ld      b,d
        call    L_D96E
        set     0,(iy-5)
        jr      L_9EB8
.L_9EAA
        xor     a
        ld      (iy-14),a
        ld      (iy-5),a
        ld      (iy-13),$01
        ld      hl,$1EAA
.L_9EB8
        ld      (iy-104),l
        ld      (iy-103),h
        ld      (iy-12),l
        ld      (iy-11),h
        ret
.L_9EC5
        push   ix
        call    L_9E75
        ld      ix,($1D57)
        ld      de,0
        ld      l,(iy-104)
        ld      h,(iy-103)
        ld      (iy-12),l
        ld      (iy-11),h
        oz      Os_mv
        pop     ix
        jp      c,L_9FFF
        jp      L_F994
.L_9EE7
        xor     a
        ld      (iy-6),a
        ld      (iy-5),a
        ld      (iy-2),a
        ld      (iy-1),a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      (iy-103),a
        ld      (iy+5),a
        ld      ($1D57),a
        ld      ($1D58),a
        ret
.L_9F07
        ld      hl,$1DAA
        ld      c,$00
.L_9F0C
        oz      Os_gb
        jr      nc,L_9F19
        cp      RC_EOF
        jp      nz,L_9FFF
        scf
        jp      L_F994
.L_9F19
        cp      $0D
        jr      nz,L_9F1E
        xor     a
.L_9F1E
        ld      d,a
        inc     c
        ld      a,c
        cp      $32
        jr      z,L_9F2F
        ld      (hl),d
        inc     hl
        inc     d
        dec     d
        jr      nz,L_9F0C
        or      a
        jp      L_F994
.L_9F2F
        ld      c,$18
        jp      L_F9B7
.L_9F34
        call    L_A05A
        call    L_ED2A
        ld      a,1                             ; read filename extension
        ld      hl,$1FAA
        ld      de,$1EAA
        ld      bc,L_FF32
        push    de
        oz      Gn_esa
        pop     de
        jp      c,L_9FFF
        dec     c
        dec     c
        jr      nz,L_9F5B
        ld      a,(de)
        call    L_EE09
        cp      $4C
        scf
        jp      z,L_F994
.L_9F5B
        ld      a,$81                           ; write filename extension
        ld      bc,L_FF32
        ld      de,$1FAA
        ld      hl,L_9FE0
        oz      Gn_esa
        jp      c,L_9FFF
        ld      de,$0003
        ld      bc,$0011
        ld      a, OP_IN
        ld      hl,$1FAA
        oz      Gn_opf
        jr      nc,L_9F86
        cp      RC_Onf
        scf
        jp      z,L_F994                        ; file not found...
        ccf
        jp      L_9FFF
.L_9F86
        ld      (iy+13),$00
        push   ix
.L_9F8C
        pop     ix
        push   ix
        push    de
        call    L_9F07
        pop     de
        jp      pe,L_9FDA
        jr      c,L_9FC4
        push    de
        call    L_A054
        inc     c
        inc     c
        inc     c
        ld      a,c
        ld      c,(iy+13)
        ld      b,$00
        call    L_EA9C
        pop     de
        jr      c,L_9FD1
        inc     (iy+13)
        ld      bc,$0008
        add     ix,bc
        ld      hl,$1DAA
.L_9FB8
        ld      a,(hl)
        ld      (ix+0),a
        inc     ix
        or      a
        jr      z,L_9F8C
        inc     hl
        jr      L_9FB8
.L_9FC4
        ld      de,$1DAA
        or      a
        sbc     hl,de
        call    L_F994
        jr      z,L_9FD4
        ld      c,$18
.L_9FD1
        call    L_F9B7
.L_9FD4
        push    af
        set     3,(iy-70)
        pop     af
.L_9FDA
        pop     ix
        scf
        ccf
        jr      L_9FE6

.L_9FE0
        defb    $6C,$00

.L_9FE2
        ld      ix,($1D57)
.L_9FE6
        push    af
        push    bc
        push   ix
        pop     bc
        ld      a,b
        or      c
        jr      z,L_9FF2
        oz      Gn_cl
.L_9FF2
        pop     bc
        jr      nc,L_9FFD
        call    L_9FFF
        pop     af
        call    L_F9B7
        push    af
.L_9FFD
        pop     af
        ret
.L_9FFF
        ld      c,$00
        jp      L_F9B7
.L_A004
        ld      c,(iy-73)
        inc     c
        jr      L_A012
.L_A00A
        ld      c,(iy-73)
        ld      a,c
        or      a
        jr      z,L_A038
        dec     c
.L_A012
        push    bc
        call    L_A020
        pop     de
        ld      a,e
        ret
.L_A019
        ld      (iy-73),$00
.L_A01D
        ld      c,(iy-73)
.L_A020
        call    L_A054
        call    L_EA7C
        jr      nc,L_A038
        ex      de,hl
        ld      hl,$1FAA
        inc     de
        inc     de
        inc     de
.L_A02F
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        or      a
        jr      nz,L_A02F
        scf
        ret
.L_A038
        ld      c,$1B
        or      a
        ret
.L_A03C
        call    L_A051
        call    L_EA7C
        ld      a,(iy+12)
        ld      (hl),a
        inc     hl
        ld      a,(iy+10)
        ld      (hl),a
        inc     hl
        ld      a,(iy+11)
        ld      (hl),a
        ret
.L_A051
        ld      c,(iy-73)
.L_A054
        ld      b,$00
        ld      hl,$1D41
        ret
.L_A05A
        res     3,(iy-70)
        ld      hl,$1EAA
        ld      (hl),$0D
        oz      Dc_nam
        ld      hl,($1D41)
        ld      a,h
        or      a
        ret     z
        xor     a
        ld      ($1D42),a
        jr      L_A07C
.L_A072
        ld      hl,($1D43)
        ld      a,h
        or      a
        ret     z
        xor     a
        ld      ($1D44),a
.L_A07C
        ld      (iy-117),l
        ld      (iy-116),h
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,(hl)
        push    de
        ld      b,$00
        call    L_D976
        pop     hl
        ld      a,h
        or      a
        jr      nz,L_A07C
        ret
.L_A093
        xor     a
.L_A094
        push    af
        ld      bc,$0000
        call    L_D7AD
        jr      c,L_A0A5
        pop     af
        push    af
        call    L_BAC8
        call    L_90FE
.L_A0A5
        pop     af
        inc     a
        cp      (iy-98)
        jr      c,L_A094
        ret

.L_A0AD
        defm    $06, $08, "String to search for", $00
        defm    $00
        defm    $85, "Search only range of columns", $00
        defm    $81, $84, "Equate upper and lower case", $00
        defm    $04, $84, "Search only marked block", $00
        defm    $88, $84, "Search from current file", $00
        defm    $90, $84, "Search all files in list", $00
        defm    $82, $00

.L_A154
        call    L_B398
        ld      hl,L_A0AD
        call    L_D98A
        ret     c
        call    L_A2CB
        jp      c,L_EB07
        jr      L_A189
.L_A166
        call    L_B398
        ld      c,$08
        bit     6,(iy+29)
        jp      z,L_EB07
        call    L_D7AA
        ld      c,(iy-87)
        inc     c
        jr      c,L_A183
        bit     7,(ix+3)
        jr      nz,L_A183
        ld      c,$F6
.L_A183
        ld      (iy-44),c
        call    L_D0E2
.L_A189
        call    L_A743
        jp      nc,L_A2A3
        call    L_A327
        jr      c,L_A19C
        call    L_A318
        jp      pe,L_EB07
        jr      nc,L_A189
.L_A19C
        call    L_EED0
        ld      l,(iy+30)
        ld      h,(iy+31)
        call    L_EE7C
        oz      Os_Pout
        defm    " found", $00

        ld      (iy-84),$0B
        jp      L_EFE9

.L_A1B9
        defm    $07, $08, "String to search for", $00
        defm    $00
        defm    $09, "Replace with", $00
        defm    $00
        defm    $85, "Search only range of columns", $00
        defm    $81, $84, "Equate upper and lower case", $00
        defm    $04, $84, "Ask for confirmation", $00
        defm    " ", $84, "Search only marked block", $00
        defm    $88, $84, "Search all files in list", $00
        defm    $82, $00

.L_A26B
        call    L_B398
        ld      hl,L_A1B9
        call    L_D98A
        ret     c
        call    L_A2CB
        jp      c,L_EB07
.L_A27B
        call    L_A743
        jr      c,L_A28A
        call    L_A34A
        jr      nc,L_A27B
.L_A285
        call    L_EB07
        jr      L_A29D
.L_A28A
        call    L_A327
        jr      c,L_A29A
        call    L_A33B
        call    L_A318
        jp      pe,L_A285
        jr      nc,L_A27B
.L_A29A
        call    L_A19C
.L_A29D
        call    L_A33B
        jp      L_929B
.L_A2A3
        call    L_82A6
        call    L_D7AD
        call    L_B503
        ld      e,(iy-123)
        ld      d,(iy-122)
        or      a
        ex      de,hl
        sbc     hl,de
        ld      (iy-87),l
        xor     a
        ld      (iy-88),a
        bit     7,(ix+3)
        jr      nz,L_A2C6
        ld      (iy-87),a
.L_A2C6
        set     7,(iy-100)
        ret
.L_A2CB
        call    L_997A
        call    L_B2CC
        ld      (iy+34),a
        ld      e,a
        ld      c,$17
        and     $82
        xor     $82
        scf
        ret     z
        res     0,(iy+29)
        xor     a
        ld      (iy+30),a
        ld      (iy+31),a
        ld      a,e
        and     $12
        jr      z,L_A2FE
        ld      c,$1A
        bit     3,(iy-70)
        scf
        ret     z
        bit     4,e
        jr      nz,L_A2FE
        call    L_9426
        scf
        ret     pe
.L_A2FE
        ld      a,$1B
        call    L_EF80
        ld      a,(iy+34)
        call    L_B2CC
        ld      (iy-44),$00
        ld      a,(iy-58)
        ld      c,(iy-57)
        ld      b,(iy-56)
        or      a
        ret
.L_A318
        call    L_9C6B
        ret     pe
        ret     c
        call    L_9437
        ret     pe
        call    L_A2FE
        jp      L_F994
.L_A327
        bit     3,(iy-70)
        scf
        ret     z
        ld      a,(iy+34)
        bit     7,a
        scf
        ret     nz
        and     $12
        scf
        ret     z
        jp      L_F023
.L_A33B
        call    L_CA8D
        call    L_B411
.L_A341
        call    L_B3C1
        call    L_8B80
        jp      L_CA7C
.L_A34A
        call    L_A5A2
        ld      (iy+2),a
        ld      (iy+3),c
        ld      (iy+4),b
        bit     5,(iy+34)
        jr      z,L_A3AD
        call    L_E0A7
        call    L_B2C2
        oz      Os_Pout
        defm    "Replace: N, Y?", $00

        call    L_E09F
        call    L_E006
        push    af
        call    L_EFD5
        pop     af
        ld      c,$04
        ret     c
        and     $DF
        cp      $59
        jr      z,L_A3AD
        ld      a,(iy+2)
        ld      c,(iy-60)
        ld      b,(iy-59)
        push    af
        push    bc
        call    L_D7AD
        push   ix
        pop     bc
        ld      l,(iy-120)
        ld      h,(iy-119)
        or      a
        sbc     hl,bc
        ld      a,l
        call    L_B53C
        ld      (iy-44),a
        pop     bc
        pop     af
        or      a
        ret
.L_A3AD
        ld      c,(iy-60)
        ld      b,(iy-59)
        ld      (iy-9),c
        ld      (iy-8),b
        inc     bc
        ld      (iy-11),c
        ld      (iy-10),b
        xor     a
        ld      (iy-40),a
        ld      (iy-3),a
        ld      (iy-44),a
        ld      a,(iy+2)
        ld      c,(iy+3)
        ld      b,(iy+4)
        call    L_D7AD
        call    L_B503
        ld      (iy-42),a
.L_A3DC
        ld      a,h
        cp      (iy-122)
        jr      c,L_A3EA
        jr      nz,L_A3F1
        ld      a,l
        cp      (iy-123)
        jr      nc,L_A3F1
.L_A3EA
        ld      a,(hl)
        call    L_A680
        inc     hl
        jr      L_A3DC
.L_A3F1
        ld      de,($1D6B)
.L_A3F5
        ld      (iy-13),$00
        ld      c,e
        ld      b,d
        dec     bc
.L_A3FC
        inc     bc
        ld      a,(bc)
        cp      $20
        jr      z,L_A3FC
        ld      a,b
        cp      d
        jr      nz,L_A40A
        ld      a,c
        cp      e
        jr      z,L_A421
.L_A40A
        ld      e,c
        ld      d,b
.L_A40C
        call    L_A5FB
        jr      c,L_A420
        jp      pe,L_A421
        cp      $20
        jr      nz,L_A420
        call    L_A680
        jr      nc,L_A40C
        jp      L_A4A0
.L_A420
        dec     hl
.L_A421
        push    hl
        ld      c,$00
        bit     2,(iy+34)
        jr      z,L_A44B
.L_A42A
        ld      a,(hl)
        or      a
        jr      z,L_A44B
        inc     hl
        call    L_EE1B
        jr      nc,L_A42A
        inc     (iy-13)
        and     $20
        jr      nz,L_A43C
        inc     c
.L_A43C
        ld      a,(hl)
        or      a
        jr      z,L_A44B
        call    L_EE1B
        jr      nc,L_A44B
        and     $20
        jr      nz,L_A44B
        dec     c
        dec     c
.L_A44B
        ld      (iy-12),c
        pop     hl
.L_A44F
        ld      a,(de)
        or      a
        jp      nz,L_A4DF
        inc     de
        ld      a,(de)
        push    hl
        ld      hl,L_A5D0
        ld      c,a
        ld      b,$00
        add     hl,bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        push    bc
        pop     ix
        pop     hl
        dec     de
        jp      (ix)
.L_A468
        ld      a,$04
        add     a,(iy-40)
        cp      $F5
        jr      nc,L_A49A
        inc     de
        inc     de
        ld      a,(de)
        cp      $23
        jr      z,L_A483
        ld      b,$04
.L_A47A
        ld      a,(de)
        call    L_A680
        inc     de
        djnz    L_A47A
        jr      L_A44F
.L_A483
        inc     de
        ld      a,(de)
        ld      c,$00
        call    L_A5DE
        jr      c,L_A4F1
        ld      a,$04
.L_A48E
        push    af
        ld      a,(bc)
        call    L_A680
        inc     bc
        pop     af
        dec     a
        jr      nz,L_A48E
        jr      L_A4F1
.L_A49A
        ld      c,$1E
        jr      L_A4A0
.L_A49E
        ld      c,$01
.L_A4A0
        push    bc
        call    L_A579
        pop     bc
        scf
        ret
.L_A4A7
        inc     de
        inc     de
        ld      a,(de)
        ld      c,$48
        call    L_A5DE
        jr      c,L_A4F1
.L_A4B1
        ld      a,(bc)
        or      a
        jr      z,L_A4F1
        call    L_A662
        inc     bc
        jr      L_A4B1
.L_A4BB
        inc     de
        inc     de
        ld      a,(de)
        ld      c,$33
        call    L_A5DE
        jr      c,L_A4F1
        ld      a,(bc)
        call    L_A662
        jr      L_A4F1
.L_A4CB
        inc     de
        ld      a,$20
        call    L_A680
        jr      L_A4F1
.L_A4D3
        inc     de
        inc     de
        ld      a,(de)
        call    L_A680
        jr      L_A4F1
.L_A4DB
        inc     de
        inc     de
        jr      L_A4F1
.L_A4DF
        cp      $20
        jr      nz,L_A4EE
        call    L_A63E
        jr      nc,L_A4F5
.L_A4E8
        ld      (iy-13),$00
        ld      a,$20
.L_A4EE
        call    L_A662
.L_A4F1
        inc     de
        jp      L_A44F
.L_A4F5
        call    L_A5FB
        jr      c,L_A4E8
        jp      pe,L_A3F5
        cp      $20
        jr      nz,L_A4F5
        dec     hl
        jp      L_A3F5
.L_A505
        call    L_A63E
        jr      c,L_A50F
.L_A50A
        call    L_A5FB
        jr      nc,L_A50A
.L_A50F
        ld      e,(iy-40)
        push    de
        ld      a,(iy-118)
        cp      (iy-111)
        call    nz,L_D887
        ld      l,(iy-120)
        ld      h,(iy-119)
        ld      b,$00
        dec     hl
.L_A525
        inc     hl
.L_A526
        ld      a,(hl)
        call    L_FE32
        jr      nc,L_A52E
        ld      b,$04
.L_A52E
        ld      a,(hl)
        call    L_A680
        pop     de
        jp      c,L_A4A0
        push    de
        ld      a,b
        or      a
        jr      z,L_A540
        inc     hl
        djnz    L_A52E
        jr      L_A526
.L_A540
        ld      a,(hl)
        or      a
        jr      nz,L_A525
        call    L_A6B0
        pop     de
        jp      c,L_A49E
        push    de
        ld      a,(iy+2)
        push    af
        ld      c,(iy-60)
        ld      b,(iy-59)
        push    bc
        push    de
        call    L_D7AD
        call    L_B503
        pop     de
        ld      d,$00
        add     hl,de
        ld      (iy-123),l
        ld      (iy-122),h
        call    L_A579
        call    L_B3B8
        pop     bc
        pop     af
        call    L_A5A2
        pop     de
        ld      (iy-44),e
        or      a
        ret
.L_A579
        ld      a,(iy-3)
        or      a
        ret     z
        ld      a,(iy+2)
        or      $80
        ld      (iy-58),a
        ld      a,(iy+3)
        ld      (iy-57),a
        ld      a,(iy+4)
        ld      (iy-56),a
        xor     a
        ld      b,a
        ld      c,(iy-3)
        bit     7,c
        jr      z,L_A59C
        dec     b
.L_A59C
        call    L_B7B9
        jp      L_CA8D
.L_A5A2
        call    L_A2A3
        ld      a,(iy-104)
        push    af
        ld      c,(iy-103)
        ld      b,(iy-102)
        push    bc
        ld      c,(iy-60)
        ld      b,(iy-59)
        push    bc
        call    L_B411
        bit     5,(iy+34)
        push    af
        call    nz,L_929B
        pop     af
        call    nz,L_BE08
        pop     bc
        ld      (iy-60),c
        ld      (iy-59),b
        pop     bc
        pop     af
        ret

.L_A5D0
        defw    L_A4DB
        defw    L_A468
        defw    L_A4A7
        defw    L_A4BB
        defw    L_A4CB
        defw    L_A505
        defw    L_A4D3
.L_A5DE
        push    hl
        ld      hl,$1DAA
        ld      b,$00
        add     hl,bc
        cp      (hl)
        ccf
        jr      c,L_A5F7
        inc     a
        ld      b,a
        jr      L_A5F4
.L_A5ED
        call    L_A8BB
        ld      a,(hl)
        or      a
        jr      nz,L_A5ED
.L_A5F4
        inc     hl
        djnz    L_A5ED
.L_A5F7
        ld      c,l
        ld      b,h
        pop     hl
        ret
.L_A5FB
        ld      c,(iy-44)
        ld      a,(hl)
        inc     hl
        inc     c
        dec     c
        jr      nz,L_A631
        call    L_FE32
        jr      c,L_A62D
        or      a
        jr      nz,L_A634
        call    L_A63E
        dec     hl
        jp      c,L_F994
        ld      c,a
        ld      a,(iy-40)
        or      a
        jr      z,L_A620
        ld      a,c
        call    L_A680
        jr      c,L_A63A
.L_A620
        push    de
        call    L_A6B0
        pop     de
        jr      c,L_A63A
        call    L_A63E
        jp      L_F9B7
.L_A62D
        ld      (iy-44),$04
.L_A631
        dec     (iy-44)
.L_A634
        call    L_A63E
        jp      L_F994
.L_A63A
        pop     de
        jp      L_A49E
.L_A63E
        ld      c,a
        ld      a,(iy+4)
        cp      (iy-8)
        ld      a,c
        ccf
        ret     nc
        ret     nz
        ld      a,(iy+3)
        cp      (iy-9)
        ld      a,c
        ccf
        ret     nc
        ret     nz
        ld      a,h
        cp      (iy-119)
        ld      a,c
        ccf
        ret     nc
        ret     nz
        ld      a,l
        cp      (iy-120)
        ld      a,c
        ccf
        ret
.L_A662
        push    af
        ld      a,(iy-13)
        or      a
        jr      z,L_A67F
        pop     af
        call    L_EE1B
        jr      nc,L_A67E
        or      $20
        push    af
        ld      a,(iy-12)
        or      a
        jr      z,L_A67F
        dec     (iy-12)
        pop     af
        and     $DF
.L_A67E
        push    af
.L_A67F
        pop     af
.L_A680
        push    hl
        push    de
        push    bc
        ld      e,(iy-40)
        ld      d,$00
        ld      hl,($1D3D)
        add     hl,de
.L_A68C
        ld      (hl),a
        inc     (iy-40)
        inc     e
        ld      a,e
        cp      $F5
        ccf
        jr      nc,L_A6A2
        jr      z,L_A6AC
        bit     7,(iy-42)
        jr      z,L_A6A6
        call    L_A6FB
.L_A6A2
        pop     bc
.L_A6A3
        pop     de
        pop     hl
        ret
.L_A6A6
        pop     bc
        ld      c,$15
        scf
        jr      L_A6A3
.L_A6AC
        inc     hl
        xor     a
        jr      L_A68C
.L_A6B0
        call    L_A6FB
        ret     c
        ld      a,(iy+2)
        ld      c,(iy+3)
        ld      b,(iy+4)
        call    L_8B61
        dec     (iy-3)
        ld      a,(iy-11)
        or      a
        jr      nz,L_A6CC
        dec     (iy-10)
.L_A6CC
        dec     (iy-11)
        ld      a,(iy-9)
        or      a
        jr      nz,L_A6D8
        dec     (iy-8)
.L_A6D8
        dec     (iy-9)
        ld      a,(iy-60)
        or      a
        jr      nz,L_A6E4
        dec     (iy-59)
.L_A6E4
        dec     (iy-60)
        ld      a,(iy+2)
        ld      c,(iy+3)
        ld      b,(iy+4)
        call    L_D7AD
        call    L_B503
        ld      (iy-42),a
        or      a
        ret
.L_A6FB
        ld      a,(iy-40)
        or      a
        ret     z
        ld      a,(iy-111)
        push    af
        set     0,(iy-42)
        set     3,(iy-72)
        ld      a,(iy+2)
        ld      c,(iy-11)
        ld      b,(iy-10)
        call    L_8CA2
        pop     bc
        ld      c,$01
        ret     c
        push    bc
        inc     (iy-3)
        ld      hl,($1D3D)
        call    L_B493
        ld      (iy-40),$00
        inc     (iy-11)
        jr      nz,L_A732
        inc     (iy-10)
.L_A732
        inc     (iy-60)
        jr      nz,L_A73A
        inc     (iy-59)
.L_A73A
        pop     af
        cp      (iy-111)
        call    nz,L_D887
        or      a
        ret
.L_A743
        call    L_D77E
        ld      a,(iy+34)
        call    L_B2CC
        ld      a,(iy-110)
        cp      (iy-58)
        jp      c,L_A87B
        cp      (iy-55)
        jr      z,L_A75D
        jp      nc,L_A87B
.L_A75D
        ld      c,(iy-109)
        ld      b,(iy-108)
        ld      a,b
        cp      (iy-56)
        jp      c,L_A87B
        jr      nz,L_A773
        ld      a,c
        cp      (iy-57)
        jp      c,L_A87B
.L_A773
        call    L_B0AE
        jr      z,L_A77D
        jr      c,L_A77D
        jp      L_A87B
.L_A77D
        call    L_A8A8
        ld      a,(iy-44)
        call    L_A8C5
        jp      c,L_A85C
        jr      z,L_A7B9
        push    af
        call    L_B990
        pop     af
        cp      b
        jp      nc,L_A85C
        ld      e,a
        ld      c,(iy-44)
        ld      a,c
        cp      $04
        jr      c,L_A79F
        ld      c,$04
.L_A79F
        ld      a,e
        sub     c
        ld      e,a
        ld      d,$00
        ld      l,(iy-127)
        ld      h,(iy-126)
        add     hl,de
        dec     hl
.L_A7AC
        inc     hl
        ld      a,(hl)
        call    L_FE32
        jr      c,L_A7B6
        dec     c
        jr      nz,L_A7AC
.L_A7B6
        call    L_A8BB
.L_A7B9
        ld      (iy-123),l
        ld      (iy-122),h
        ld      a,(iy-125)
        ld      (iy-121),a
        push    hl
        ld      hl,($1D69)
        ld      (iy-42),l
        ld      (iy-41),h
        ld      de,$1DAA
        xor     a
        ld      hl,$0001
        ld      (iy-9),l
        dec     hl
        add     hl,de
        ld      (hl),a
        ld      hl,$0049
        ld      (iy-7),l
        dec     hl
        add     hl,de
        ld      (hl),a
        ld      hl,$0034
        ld      (iy-8),l
        dec     hl
        add     hl,de
        ld      (hl),a
        pop     hl
.L_A7EF
        ld      e,(iy-42)
        ld      d,(iy-41)
.L_A7F5
        ld      a,(de)
        cp      $20
        jr      nz,L_A807
        inc     de
        ld      a,d
        cp      (iy+33)
        jr      nz,L_A7F5
        ld      a,e
        cp      (iy+32)
        jr      nz,L_A7F5
.L_A807
        ld      a,d
        cp      (iy-41)
        jr      nz,L_A813
        ld      a,e
        cp      (iy-42)
        jr      z,L_A81D
.L_A813
        dec     hl
.L_A814
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_A848
        cp      $20
        jr      z,L_A814
.L_A81D
        call    L_A901
        jr      nz,L_A87D
        jr      nc,L_A7F5
        set     0,(iy+29)
        inc     (iy+30)
        jr      nz,L_A830
        inc     (iy+31)
.L_A830
        dec     hl
        ld      (iy-120),l
        ld      (iy-119),h
        ld      a,(iy-125)
        ld      (iy-118),a
        ld      a,(iy-110)
        ld      c,(iy-109)
        ld      b,(iy-108)
        or      a
        ret
.L_A848
        ld      (iy-42),e
        ld      (iy-41),d
        call    L_FB93
        jr      nc,L_A87B
        call    L_A8C4
        jr      c,L_A85C
        bit     7,c
        jr      nz,L_A7EF
.L_A85C
        call    L_EF34
        call    L_A8A8
        call    L_FB93
        jr      nc,L_A87B
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D77E
        call    L_A8C4
        jr      c,L_A85C
        jp      L_A7B9
.L_A87B
        scf
        ret
.L_A87D
        call    L_A8A8
        call    L_D7AD
        ld      l,(iy-123)
        ld      h,(iy-122)
        ld      a,(hl)
        or      a
        jr      z,L_A85C
        cp      $20
        jr      nz,L_A89E
        dec     hl
.L_A892
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_A85C
        cp      $20
        jr      z,L_A892
        jp      L_A7B9
.L_A89E
        call    L_A8BB
        ld      a,(hl)
        or      a
        jr      z,L_A85C
        jp      L_A7B9
.L_A8A8
        ld      a,(iy-110)
        ld      c,(iy-109)
        ld      b,(iy-108)
        ld      (iy-61),a
        ld      (iy-60),c
        ld      (iy-59),b
        ret
.L_A8BB
        call    L_FE32
        inc     hl
        ret     nc
        inc     hl
        inc     hl
        inc     hl
        ret
.L_A8C4
        xor     a
.L_A8C5
        push    af
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D7AD
        jr      c,L_A8EE
        call    L_B503
        and     $C0
        ld      c,a
        cp      $C0
        jr      z,L_A8EE
        pop     af
        call    L_B535
        ret     c
        push   ix
        pop     hl
        ld      e,a
        ld      d,$00
        add     hl,de
        cp      b
        scf
        ccf
        ret
.L_A8EE
        pop     af
        scf
        ret
.L_A8F1
        inc     de
        call    L_AA66
        ld      a,c
        and     $7E
        ld      c,a
        set     7,c
        jr      c,L_A909
        set     0,c
        jr      L_A909
.L_A901
        ld      c,$00
        ld      (iy-36),e
        ld      (iy-35),d
.L_A909
        push    hl
        ld      a,(hl)
        call    L_A8BB
        ld      (iy-40),l
        ld      (iy-39),h
        pop     hl
        ld      (iy-42),e
        ld      (iy-41),d
.L_A91B
        ld      a,(hl)
        or      a
        jr      nz,L_A921
        ld      a,$20
.L_A921
        call    L_AAA5
        ld      (iy-34),a
        ld      a,(de)
        or      a
        jr      nz,L_A999
        inc     de
        ld      a,(de)
        push    de
        push    hl
        ld      hl,L_AA97
        ld      e,a
        ld      d,$00
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de
        pop     ix
        pop     hl
        pop     de
        jp      (ix)
.L_A940
        push    de
        push    hl
        call    L_B500
        ex      de,hl
        pop     hl
        or      a
        sbc     hl,de
        add     hl,de
        pop     de
        jr      nz,L_A98F
        jp      L_A9EE
.L_A951
        inc     de
        ld      a,(iy-34)
        call    L_FE32
        jr      nc,L_A98F
        ld      a,(de)
        cp      $23
        jr      nz,L_A97F
        call    L_AA7C
        jr      nc,L_A96A
        inc     hl
        inc     hl
        inc     hl
        jp      L_A9EB
.L_A96A
        ld      a,(iy-34)
        call    L_AA47
        ld      b,$03
.L_A972
        inc     hl
        ld      a,(hl)
        call    L_AA47
        djnz    L_A972
        xor     a
        call    L_AA47
        jr      L_A9EB
.L_A97F
        ld      b,$03
.L_A981
        inc     de
        inc     hl
        ld      a,(de)
        cp      (hl)
        jr      nz,L_A98F
        djnz    L_A981
        jr      L_A9EB
.L_A98B
        inc     de
        ld      a,(de)
        jr      L_A999
.L_A98F
        ld      a,$01
        or      a
        ret
.L_A993
        ld      a,(hl)
        or      a
        jr      z,L_A98F
        ld      a,$20
.L_A999
        call    L_AAA5
        cp      (iy-34)
        jr      z,L_A9EB
        ld      a,(iy-34)
        cp      $20
        jr      z,L_A98F
        ld      e,(iy-42)
        ld      d,(iy-41)
        ld      a,d
        cp      (iy-35)
        jr      nz,L_A9BA
        ld      a,e
        cp      (iy-36)
        jr      z,L_A98F
.L_A9BA
        ld      l,(iy-40)
        ld      h,(iy-39)
        set     1,c
        bit     0,c
        jp      z,L_A909
.L_A9C7
        ld      a,(iy-34)
        call    L_AA34
        jp      nc,L_A909
        res     0,c
        jp      L_A909
.L_A9D5
        ld      a,(iy-34)
        cp      $20
        jr      z,L_A98F
        call    L_AA71
        jr      c,L_A9EB
        ld      a,(iy-34)
        call    L_AA53
        xor     a
        call    L_AA53
.L_A9EB
        set     1,c
        inc     hl
.L_A9EE
        call    L_AA26
        ld      a,(de)
        inc     de
        cp      $20
        jp      nz,L_A91B
        bit     1,c
        jp      z,L_A98F
        dec     hl
        ld      a,(hl)
        or      a
        ret     z
        inc     hl
        xor     a
        ret
.L_AA04
        inc     hl
        bit     1,c
        jr      nz,L_AA20
        bit     7,c
        jp      z,L_A98F
        ld      a,(iy-34)
        cp      $20
        jr      z,L_AA1B
        set     2,c
        dec     de
        jp      L_A9C7
.L_AA1B
        bit     2,c
        jp      z,L_A98F
.L_AA20
        call    L_AA26
        xor     a
        scf
        ret
.L_AA26
        bit     7,c
        ret     z
        bit     0,c
        call    nz,L_AA33
        res     7,c
        res     0,c
        ret
.L_AA33
        xor     a
.L_AA34
        push    de
        push    hl
        push    bc
        ld      c,a
        ld      a,(iy-7)
        cp      $FE
        jr      c,L_AA41
        ld      c,$00
.L_AA41
        inc     (iy-7)
        ccf
        jr      L_AA5D
.L_AA47
        push    de
        push    hl
        push    bc
        ld      c,a
        ld      a,(iy-9)
        inc     (iy-9)
        jr      L_AA5D
.L_AA53
        push    de
        push    hl
        push    bc
        ld      c,a
        ld      a,(iy-8)
        inc     (iy-8)
.L_AA5D
        push    af
        call    L_AA8F
        ld      (hl),c
        pop     af
        pop     bc
        jr      L_AA8C
.L_AA66
        ld      a,(iy-7)
        cp      $FD
        ccf
        ret     c
        ld      a,$48
        jr      L_AA85
.L_AA71
        ld      a,(iy-8)
        cp      $45
        ccf
        ret     c
        ld      a,$33
        jr      L_AA85
.L_AA7C
        ld      a,(iy-9)
        cp      $2D
        ccf
        ret     c
        ld      a,$00
.L_AA85
        push    de
        push    hl
        call    L_AA8F
        inc     (hl)
        or      a
.L_AA8C
        pop     hl
        pop     de
        ret
.L_AA8F
        ld      hl,$1DAA
        ld      e,a
        ld      d,$00
        add     hl,de
        ret

.L_AA97
        defw    L_A940
        defw    L_A951
        defw    L_A8F1
        defw    L_A9D5
        defw    L_A993
        defw    L_AA04
        defw    L_A98B
.L_AAA5
        bit     2,(iy+34)
        ret     z
        jp      L_EE09

.L_AAAD
        defm    $03, $85, "Print only range of columns", $00
        defm    $81, $86, "Select rows to print", $00
        defm    $82, $84, "Wait between pages", $00
        defm    $84, $00

.L_AAF9
        call    L_B398
        ld      hl,L_AAAD
        call    L_D98A
        ret     c
        call    L_B2CC
        ld      (iy-46),a
        call    L_AB10
        jp      c,L_EB07
        ret
.L_AB10
        ld      ($1D59),sp
        set     6,(iy-70)
        set     0,(iy-70)
        call    L_ED6C
        xor     a
        ld      (iy-85),a
        ld      (iy-90),a
        inc     a
        ld      (iy-86),a
        ld      (iy-91),a
        bit     7,(iy-46)
        jr      nz,L_AB57
        ld      c,(iy+10)
        ld      b,(iy+11)
        push    bc
        bit     3,(iy-70)
        jr      z,L_AB4A
        call    L_9426
        jp      pe,L_ABA8
.L_AB46
        set     0,(iy-85)
.L_AB4A
        pop     bc
        ld      (iy-91),c
        ld      (iy-90),b
        ld      a,(iy-46)
        call    L_B2CC
.L_AB57
        call    L_FBBD
.L_AB5A
        bit     1,(iy-46)
        jr      z,L_AB65
        call    L_B30E
        jr      c,L_AB6A
.L_AB65
        call    L_ABC6
        jr      c,L_ABBB
.L_AB6A
        inc     (iy-60)
        jr      nz,L_AB72
        inc     (iy-59)
.L_AB72
        ld      a,(iy-58)
        ld      (iy-61),a
        call    L_F023
        jr      c,L_ABBB
        call    L_FBF2
        jr      z,L_AB5A
        jr      c,L_AB5A
        bit     3,(iy-70)
        jr      z,L_ABB8
        bit     7,(iy-46)
        jr      nz,L_ABB8
        ld      c,(iy-91)
        ld      b,(iy-90)
        push    bc
        call    L_9C6B
        jp      pe,L_ABA8
        jr      c,L_ABB1
        call    L_B363
        call    L_9437
        jp      po,L_AB46
.L_ABA8
        pop     de
        push    bc
        call    L_ABBB
        pop     bc
        jp      L_EB07
.L_ABB1
        pop     bc
        ld      (iy-91),c
        ld      (iy-90),b
.L_ABB8
        call    L_AD32
.L_ABBB
        call    L_E097
        call    L_ED53
        call    L_B363
        or      a
        ret
.L_ABC6
        res     6,(iy-72)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D24C
        jr      nc,L_ABEC
        ld      a,(iy-86)
        call    L_D263
        ret     nc
        bit     7,(iy-85)
        ld      c,$00
        ccf
        call    z,L_AC9D
        ret     c
        ld      c,$01
        jp      L_AC9D
.L_ABEC
        ld      c,(iy-86)
        ld      a,c
        or      a
        call    z,L_AC9D
        ret     c
        or      a
        bit     7,(iy-85)
        call    z,L_AC9D
        ret     c
        call    L_AC84
        call    L_AD28
        xor     a
        ld      (iy-82),a
        ld      (iy-112),a
        set     6,(iy-72)
.L_AC0F
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_C917
        ld      (iy-38),a
        ld      a,(iy-61)
        call    L_D54A
        or      a
        jr      z,L_AC49
        add     a,(iy-112)
        ld      (iy-112),a
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D797
        jr      c,L_AC40
        call    L_C9B8
        jr      nc,L_AC43
.L_AC40
        xor     a
        jr      L_AC49
.L_AC43
        ld      a,(iy-38)
        call    L_CB0E
.L_AC49
        ld      e,a
        add     a,(iy-82)
        ld      (iy-82),a
        call    L_EDE6
        ld      a,(iy-112)
        ld      c,a
        sub     (iy-82)
        jr      c,L_AC62
        ld      (iy-82),c
        call    L_C5EA
.L_AC62
        inc     (iy-61)
        ld      a,(iy-61)
        cp      (iy-55)
        jr      z,L_AC0F
        jr      c,L_AC0F
        ld      a,(iy+8)
        call    L_AD1B
        res     6,(iy-72)
        ld      a,(iy-86)
        call    L_D28D
        ld      (iy-86),a
        or      a
        ret
.L_AC84
        rr      (iy-85)
        push    af
        or      a
        rl      (iy-85)
        pop     af
        ret     nc
        ld      a,(iy+10)
        ld      (iy-91),a
        ld      a,(iy+11)
        ld      (iy-90),a
        ret
.L_AC9D
        ld      a,(iy+7)
        or      a
        ret     z
        bit     7,(iy-85)
        jr      z,L_ACBA
        push    bc
        call    L_AD37
        call    L_AC84
        call    L_D2BB
        call    c,L_D315
        pop     bc
        inc     c
        dec     c
        jr      nz,L_AD19
.L_ACBA
        call    L_AC84
        set     7,(iy-85)
        bit     2,(iy-46)
        jr      z,L_ACFE
        call    L_ED5B
        call    L_B2C2
        oz      Os_Pout
        defm    "Page ", $00

        ld      l,(iy-91)
        ld      h,(iy-90)
        call    L_EE7C
        oz      Os_Pout
        defm    "..", $00

        call    L_E006
        push    af
        call    L_EFD5
        pop     af
        ret     c
        call    L_EE09
        cp      $43
        jr      nz,L_ACF9
        res     2,(iy-46)
.L_ACF9
        cp      $4D
        call    nz,L_ED6C
.L_ACFE
        call    L_EDEE
        ld      a,$0F
        call    L_E790
        call    L_AD1B
        ld      a,$14
        call    L_E54F
        call    L_AD6D
        ld      a,$10
        call    L_E790
        call    L_AD1B
.L_AD19
        or      a
        ret
.L_AD1B
        ld      c,a
        ld      a,$0D
.L_AD1E
        inc     c
        dec     c
        ret     z
.L_AD21
        call    L_ED93
        dec     c
        jr      nz,L_AD21
        ret
.L_AD28
        ld      a,$13
        call    L_E790
        ld      c,a
        ld      a,$20
        jr      L_AD1E
.L_AD32
        bit     7,(iy-85)
        ret     z
.L_AD37
        ld      a,$15
        call    L_E54F
        call    L_E8C3
        jr      c,L_AD5F
        ld      a,$11
        call    L_E790
        ld      c,(iy-86)
        inc     c
        dec     c
        jr      z,L_AD54
        scf
        adc     a,(iy+7)
        sub     (iy-86)
.L_AD54
        call    L_AD1B
        ld      a,$15
        call    L_E54F
        call    L_AD6D
.L_AD5F
        ld      a,$0C
        call    L_ED93
        res     7,(iy-85)
        ld      (iy-86),$01
        ret
.L_AD6D
        push    hl
        call    L_E8C3
        pop     hl
        ret     c
        ld      c,a
        ld      a,(iy-91)
        or      (iy-90)
        jr      z,L_ADBE
        push    bc
        ld      ($1D4D),hl
        call    L_AD28
        ld      de,$0000
        ld      a,(iy-58)
.L_AD89
        ld      c,e
        push    bc
        push    af
        push    de
        call    L_D54A
        pop     de
        add     a,e
        ld      e,a
        pop     af
        pop     bc
        push    af
        push    de
        push    bc
        call    L_D551
        pop     bc
        add     a,c
        pop     de
        ld      d,a
        pop     af
        inc     a
        cp      (iy-55)
        jr      z,L_AD89
        jr      c,L_AD89
        ld      a,e
        cp      d
        jr      nc,L_ADAD
        ld      e,d
.L_ADAD
        ld      (iy-36),e
        pop     bc
        ld      b,$01
        call    L_CE31
        ld      a,$08
        call    L_CBD9
        call    L_EDE6
.L_ADBE
        ld      a,$01
        jp      L_AD1B

.L_ADC3
        defm    $03, $0A, "Sort on column", $00
        defm    $00
        defm    $84, "Sort in reverse order", $00
        defm    $82, $84, "Don't update references", $00
        defm    $81, $00

.L_AE08
        call    L_B398
        call    L_9250
        ld      a,(iy-58)
.L_AE11
        push    af
        ld      c,(iy-54)
        ld      b,(iy-53)
        call    L_D797
        jr      nc,L_AE29
        call    L_B8B6
        call    L_B8C7
        jr      nc,L_AE29
        pop     af
        jp      L_EB07
.L_AE29
        pop     af
        inc     a
        cp      (iy-55)
        jr      z,L_AE11
        jr      c,L_AE11
        ld      hl,L_ADC3
        call    L_D98A
        ret     c
        ld      (iy-44),a
        ld      a,(iy+53)
        ld      (iy-46),a
        ld      a,(iy-54)
        sub     (iy-57)
        ld      c,a
        ld      a,(iy-53)
        sbc     a,(iy-56)
        ld      b,a
        jr      nz,L_AE58
        ld      a,c
        or      a
        ret     z
        dec     a
        jr      z,L_AE59
.L_AE58
        inc     bc
.L_AE59
        push    bc
        set     1,(iy-72)
        call    L_CA8D
        call    L_B3C1
        ld      a,$07
        call    L_EF80
        pop     bc
.L_AE6A
        srl     b
        rr      c
        ld      (iy+3),c
        ld      (iy+4),b
        inc     bc
        ld      (iy-77),c
        ld      (iy-76),b
        ld      a,c
        add     a,(iy-57)
        ld      (iy-2),a
        ld      a,b
        adc     a,(iy-56)
        ld      (iy-1),a
.L_AE89
        call    L_EF34
        ld      a,(iy-2)
        ld      (iy-103),a
        ld      a,(iy-1)
        ld      (iy-102),a
.L_AE98
        ld      a,(iy-103)
        ld      (iy-28),a
        sub     (iy-77)
        ld      (iy-103),a
        ld      c,a
        ld      a,(iy-102)
        ld      (iy-27),a
        sbc     a,(iy-76)
        ld      (iy-102),a
        jr      c,L_AEC5
        cp      (iy-56)
        jr      c,L_AEC5
        jr      nz,L_AEC0
        ld      a,c
        cp      (iy-57)
        jr      c,L_AEC5
.L_AEC0
        call    L_AF08
        jr      c,L_AE98
.L_AEC5
        inc     (iy-2)
        jr      nz,L_AECD
        inc     (iy-1)
.L_AECD
        ld      c,(iy-2)
        ld      b,(iy-1)
        call    L_B0AE
        jr      c,L_AE89
        jr      z,L_AE89
        ld      c,(iy+3)
        ld      b,(iy+4)
        ld      a,c
        or      b
        jr      nz,L_AE6A
        call    L_8FC4
        jp      L_EFBB
.L_AEEA
        call    L_D24C
        jp      c,L_F9B7
        ld      a,(iy-46)
        ld      c,(iy-26)
        ld      b,(iy-25)
        call    L_FA07
        jr      nc,L_AF05
        ld      a,c
        cp      $08
        scf
        jr      nz,L_AF05
        or      a
.L_AF05
        jp      L_F994
.L_AF08
        ld      c,(iy-28)
        ld      b,(iy-27)
        call    L_AEEA
        jp      po,L_AF2B
        inc     (iy-28)
        jr      nz,L_AF1C
        inc     (iy-27)
.L_AF1C
        ld      c,(iy-28)
        ld      b,(iy-27)
        call    L_B0AE
        jr      c,L_AF08
        jr      z,L_AF08
        scf
        ret
.L_AF2B
        ld      (iy-36),c
        jr      c,L_AF3C
        call    L_FE8A
        ld      ix,$1DA5
        call    L_FEA0
        jr      L_AF45
.L_AF3C
        ld      (iy-123),l
        ld      (iy-122),h
        ld      (iy-121),b
.L_AF45
        ld      c,(iy-103)
        ld      b,(iy-102)
        call    L_AEEA
        jp      pe,L_AF95
        rr      e
        ld      a,c
        cp      (iy-36)
        jr      nz,L_AF8A
        rl      e
        jr      c,L_AF69
        call    L_FE8A
        ld      ix,$1DA5
        call    L_FEB6
        jr      L_AF72
.L_AF69
        ld      (iy-120),l
        ld      (iy-119),h
        ld      (iy-118),b
.L_AF72
        ld      a,(iy-79)
        cp      $02
        jr      z,L_AF85
        cp      $08
        jr      z,L_AF82
        call    L_F7DF
        jr      L_AF89
.L_AF82
        ld      bc,$0000
.L_AF85
        fpp     Fp_cmp
        add     a,a
        ccf
.L_AF89
        ret     z
.L_AF8A
        bit     1,(iy-44)
        jr      z,L_AF91
        ccf
.L_AF91
        ret     nc
        call    L_AF97
.L_AF95
        scf
        ret
.L_AF97
        ld      a,(iy-58)
        ld      (iy-42),a
.L_AF9D
        ld      a,(iy-42)
        ld      c,(iy-28)
        ld      b,(iy-27)
        call    L_D797
        call    L_B0B9
        ld      a,(iy-42)
        call    L_BAC8
        call    L_BB0F
        call    L_BB23
        ld      a,(iy-42)
        ld      c,(iy-103)
        ld      b,(iy-102)
        call    L_D7AD
        call    L_B0B9
        call    L_BB4B
        call    L_BB69
        call    L_BA27
        call    L_BADC
        call    L_BAA0
        call    L_BAAA
        ld      a,(iy-110)
        call    L_BAC8
        ld      a,l
        cp      (iy+71)
        jr      nz,L_B003
        ld      a,h
        cp      (iy+72)
        jr      nz,L_B003
        ld      a,c
        cp      (iy+73)
        jr      nz,L_B003
        call    L_BA2A
        ld      hl,$0000
        ld      c,l
        call    L_BB05
        call    L_BA96
        call    L_BAFB
        jr      L_B006
.L_B003
        call    L_BA27
.L_B006
        call    L_B9A8
        call    L_BADC
        call    L_BAA0
        call    L_BAAA
        call    L_B9A8
        bit     0,(iy-44)
        jr      nz,L_B042
        xor     a
.L_B01C
        ld      bc,$0000
        call    L_D77E
.L_B022
        call    L_D79A
        jr      c,L_B037
        ld      hl,L_B052
        call    L_B6FF
        inc     (iy-109)
        jr      nz,L_B022
        inc     (iy-108)
        jr      L_B022
.L_B037
        inc     (iy-110)
        ld      a,(iy-110)
        cp      (iy-98)
        jr      c,L_B01C
.L_B042
        inc     (iy-42)
        ld      a,(iy-42)
        cp      (iy-55)
        jp      z,L_AF9D
        ret     nc
        jp      L_AF9D
.L_B052
        ld      (iy-32),$00
        ld      a,(iy-42)
        cp      (hl)
        ret     nz
        push   ix
        push    hl
        pop     ix
        push    hl
        ld      a,(iy-103)
        sub     (iy-28)
        ld      e,a
        ld      a,(iy-102)
        sbc     a,(iy-27)
        ld      d,a
        push    de
        ld      de,$FFE4
        push    iy
        pop     hl
        add     hl,de
        call    L_B0A3
        jr      z,L_B091
        ld      de,L_FF99
        push    iy
        pop     hl
        add     hl,de
        call    L_B0A3
        jr      nz,L_B09E
        pop     de
        ld      hl,$0000
        or      a
        sbc     hl,de
        ex      de,hl
        push    de
.L_B091
        pop     de
        ld      (iy-31),e
        ld      (iy-30),d
        pop     hl
        pop     ix
        jp      L_B6D7
.L_B09E
        pop     de
        pop     hl
        pop     ix
        ret
.L_B0A3
        ld      a,(hl)
        cp      (ix+1)
        ret     nz
        inc     hl
        ld      a,(hl)
        cp      (ix+2)
        ret
.L_B0AE
        ld      a,b
        cp      (iy-53)
        ret     c
        ret     nz
        ld      a,c
        cp      (iy-54)
        ret
.L_B0B9
        call    L_B0C0
        ld      (ix+3),a
        ret
.L_B0C0
        call    L_B518
        ld      a,(ix+3)
        ld      c,a
        and     $C0
        cp      $40
        jr      nz,L_B0D7
        ld      a,(ix+4)
        or      a
        jr      nz,L_B0D7
        ld      a,c
        and     $BF
        ld      c,a
.L_B0D7
        ld      a,c
        ret

.L_B0D9
        defm    $02, $0B, "Range to copy from", $00
        defm    $00
        defm    $0C, "Range to copy to", $00
        defm    $00
        defm    $00

.L_B103
        call    L_B398
        ld      hl,L_B0D9
        call    L_D98A
        ret     c
        ld      de,$FFFC
        push    iy
        pop     hl
        add     hl,de
        push    hl
        ld      de,$0035
        push    iy
        pop     hl
        add     hl,de
        pop     de
        ld      bc,$0006
        ldir
        ld      de,$FFC6
        push    iy
        pop     hl
        add     hl,de
        push    hl
        ld      de,$003B
        push    iy
        pop     hl
        add     hl,de
        pop     de
        ld      bc,$0006
        ldir
        xor     a
        ld      (iy-14),a
        ld      (iy-13),a
        ld      de,$FFC3
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
        call    L_B29D
        jr      nc,L_B185
        ld      (iy-32),a
        ld      (iy-31),c
        ld      (iy-30),b
        ld      (iy-13),d
        ld      de,$FFF9
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
        call    L_B29D
        jr      nc,L_B185
        ld      (iy-29),a
        ld      (iy-28),c
        ld      (iy-27),b
        ld      (iy-14),d
        inc     d
        dec     d
        jr      z,L_B1B9
        ld      a,(iy-13)
        or      a
        jr      z,L_B18D
        xor     (iy-14)
        xor     $C0
        jr      z,L_B1B5
.L_B185
        ld      c,$0E
        call    L_EB07
        jp      L_EFD5
.L_B18D
        ld      a,(iy-29)
        add     a,(iy-58)
        ld      (iy-55),a
        bit     7,a
        jr      nz,L_B1B0
        ld      a,(iy-28)
        add     a,(iy-57)
        ld      (iy-54),a
        ld      a,(iy-27)
        adc     a,(iy-56)
        ld      (iy-53),a
        bit     7,a
        jr      z,L_B1B9
.L_B1B0
        ld      c,$1D
        jp      L_EB07
.L_B1B5
        set     0,(iy-13)
.L_B1B9
        ld      a,$13
        call    L_EF80
        call    L_FBBD
.L_B1C1
        ld      de,$FFF9
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
        call    L_FBC7
.L_B1CE
        call    L_EF34
        ld      a,(iy-7)
        ld      c,(iy-6)
        ld      b,(iy-5)
        call    L_D7AD
        jr      c,L_B220
        call    L_F023
        ld      c,$04
        jp      c,L_B28E
        call    L_9128
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_B8C4
        jp      c,L_B28E
        call    L_913E
        ld      a,(iy-61)
        sub     (iy-7)
        ld      (iy-32),a
        ld      a,(iy-60)
        sub     (iy-6)
        ld      (iy-31),a
        ld      a,(iy-59)
        sbc     a,(iy-5)
        ld      (iy-30),a
        call    L_B518
        ld      hl,L_B6D7
        call    L_B6FF
.L_B220
        ld      a,(iy-14)
        or      a
        scf
        jr      z,L_B234
        ld      de,$FFF9
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
        call    L_FB9D
.L_B234
        bit     0,(iy-13)
        jr      z,L_B286
        bit     7,(iy-14)
        jr      c,L_B272
        jr      nz,L_B25C
        ld      a,(iy-57)
        ld      (iy-60),a
        ld      a,(iy-56)
        ld      (iy-59),a
        ld      a,(iy-61)
        inc     (iy-61)
        cp      (iy-55)
        jp      c,L_B1C1
        jr      L_B291
.L_B25C
        ld      a,(iy-58)
        ld      (iy-61),a
        inc     (iy-60)
        jr      nz,L_B26A
        inc     (iy-59)
.L_B26A
        call    L_FBF2
        jp      c,L_B1C1
        jr      L_B291
.L_B272
        jr      z,L_B27A
        inc     (iy-61)
        jp      L_B1CE
.L_B27A
        inc     (iy-60)
        jp      nz,L_B1CE
        inc     (iy-59)
        jp      L_B1CE
.L_B286
        call    L_FB93
        jr      nc,L_B291
        jp      L_B1CE
.L_B28E
        call    L_EB07
.L_B291
        call    L_B411
        call    L_EFD5
        call    L_EFBB
        jp      L_8FBE
.L_B29D
        ld      d,$00
        ld      a,(ix+6)
        sub     (ix+3)
        ccf
        ret     nc
        ld      e,a
        jr      z,L_B2AC
        ld      d,$80
.L_B2AC
        ld      a,(ix+7)
        sub     (ix+4)
        ld      c,a
        ld      a,(ix+8)
        sbc     a,(ix+5)
        ld      b,a
        or      c
        jr      z,L_B2BF
        set     6,d
.L_B2BF
        ld      a,e
        ccf
        ret
.L_B2C2
        call    L_EFD5
        ld      a,$28
        ld      b,$00
        jp      L_EEE4
.L_B2CC
        push    af
        and     $40
        jr      nz,L_B2D6
        call    L_D014
        jr      nc,L_B2F5
.L_B2D6
        xor     a
        ld      (iy-58),a
        ld      (iy-57),a
        ld      (iy-56),a
        ld      a,(iy-98)
        dec     a
        ld      (iy-55),a
        ld      c,(iy-97)
        ld      b,(iy-96)
        dec     bc
        ld      (iy-54),c
        ld      (iy-53),b
        scf
.L_B2F5
        pop     de
        ld      a,d
        jr      c,L_B2FB
        or      $80
.L_B2FB
        push    af
        and     $01
        jr      z,L_B30C
        ld      a,(iy+53)
        ld      (iy-58),a
        ld      a,(iy+54)
        ld      (iy-55),a
.L_B30C
        pop     af
        ret
.L_B30E
        xor     a
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D77E
        ld      de,$FFC3
        push    iy
        pop     hl
        add     hl,de
        ld      b,$09
.L_B321
        ld      a,(hl)
        push    af
        inc     hl
        djnz    L_B321
        ld      hl,($1D73)
        ld      b,(iy-111)
        call    L_F06F
        ld      de,$FFCC
        push    iy
        pop     hl
        add     hl,de
        ld      b,$09
.L_B338
        pop     af
        dec     hl
        ld      (hl),a
        djnz    L_B338
        ld      a,(iy-79)
        cp      $02
        jr      nz,L_B34F
        fpp     Fp_one
        call    L_FEDA
        call    L_FE8A
        fpp     Fp_cmp
        add     a,a
.L_B34F
        push    af
        xor     a
        ld      (iy-32),a
        ld      (iy-30),a
        ld      (iy-31),$01
        call    L_B37E
        pop     af
        scf
        ret     nz
        or      a
        ret
.L_B363
        bit     1,(iy-46)
        ret     z
.L_B368
        ld      a,(iy-57)
        sub     (iy-60)
        ld      (iy-31),a
        ld      a,(iy-56)
        sbc     a,(iy-59)
        ld      (iy-30),a
        ld      (iy-32),$00
.L_B37E
        ld      ix,L_B6D7
        ld      hl,($1D73)
        jp      L_B708
.L_B388
        bit     6,(iy-71)
        ret     z
        ld      c,$19
        call    L_EB07
        pop     de
        ret
.L_B394
        set     1,(iy-72)
.L_B398
        call    L_B39E
        ret     nc
        pop     de
        ret
.L_B39E
        or      a
        bit     6,(iy-71)
        ret     nz
        bit     0,(iy-72)
        jr      z,L_B3AE
        set     1,(iy-72)
.L_B3AE
        call    L_B3C6
        ret     nc
        call    L_CA73
        jp      L_EB07
.L_B3B8
        set     4,(iy-72)
        set     1,(iy-72)
        ret
.L_B3C1
        set     0,(iy-71)
        ret
.L_B3C6
        bit     7,(iy-72)
        ret     z
        call    L_D249
        jr      c,L_B410
        call    L_D0E2
        call    L_D77E
.L_B3D6
        bit     0,(iy-72)
        jr      z,L_B410
        call    L_B3C1
        scf
        call    L_BC66
        ret     c
        ld      (iy-40),b
        ld      a,$80
        jp      po,L_B3EE
        or      $20
.L_B3EE
        ld      (iy-42),a
        call    L_D79A
        jr      c,L_B408
        ld      c,$0E
        ld      a,(ix+3)
        bit     7,a
        jr      nz,L_B401
        ld      c,$00
.L_B401
        and     c
        or      (iy-42)
        ld      (iy-42),a
.L_B408
        call    L_B8C7
        jr      c,L_B411
        call    L_B490
.L_B410
        or      a
.L_B411
        res     0,(iy-72)
        res     7,(iy-72)
        ret
.L_B41A
        ld      a,(iy-107)
        ld      c,(iy-106)
        ld      b,(iy-105)
        call    L_82A2
.L_B426
        call    L_D797
        rr      (iy-46)
        bit     0,(iy-72)
        jr      z,L_B410
        call    L_B3C1
        or      a
        call    L_BC66
        ret     c
        push    af
        pop     de
        ld      a,b
        cp      $01
        jr      z,L_B3D6
        ld      (iy-40),b
        ld      a,$80
        rl      (iy-46)
        jr      c,L_B453
        call    L_B518
        ld      a,(ix+3)
.L_B453
        ld      c,a
        and     $1E
        bit     2,e
        jr      z,L_B45C
        or      $20
.L_B45C
        bit     7,c
        jr      z,L_B464
        and     $F1
        or      $06
.L_B464
        ld      (iy-42),a
        ld      e,$00
        ld      a,c
        cp      $80
        jr      nc,L_B471
        ld      e,(ix+9)
.L_B471
        push    de
        ld      a,(iy-104)
        ld      c,(iy-103)
        ld      b,(iy-102)
        call    L_B8C4
        pop     de
        jr      c,L_B411
        call    L_B518
        ld      (ix+9),e
        call    L_B490
        call    L_B575
        jp      L_B410
.L_B490
        ld      hl,$1DAA
.L_B493
        push    hl
        call    L_B500
        ex      de,hl
        pop     hl
        ld      c,(iy-40)
        ld      b,$00
        dec     c
        jr      z,L_B4A3
        ldir
.L_B4A3
        xor     a
        ld      (de),a
        ret
.L_B4A6
        call    L_B388
        call    L_B398
        call    L_88C6
        call    L_FBBD
.L_B4B2
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D797
        jr      c,L_B4F1
        ld      a,(ix+3)
        and     $C0
        cp      $C0
        jr      z,L_B4F1
        push    af
        call    L_BB7B
        set     0,(iy-72)
        pop     af
        bit     7,a
        jr      nz,L_B4DB
        call    L_B3D6
        jr      L_B4EA
.L_B4DB
        ld      a,(iy-110)
        ld      c,(iy-109)
        ld      b,(iy-108)
        call    L_82A6
        call    L_B426
.L_B4EA
        set     1,(iy-72)
        call    L_C9CA
.L_B4F1
        call    L_FB93
        jr      c,L_B4B2
        jp      L_CA73
.L_B4F9
        ld      a,(hl)
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ret
.L_B500
        call    L_B518
.L_B503
        ld      a,(ix+3)
        bit     7,a
        ld      b,$04
        jr      nz,L_B50E
        ld      b,$0A
.L_B50E
        push    bc
        ld      c,b
        ld      b,$00
        push   ix
        pop     hl
        add     hl,bc
        pop     bc
        ret
.L_B518
        push    de
        ld      e,(iy-127)
        ld      d,(iy-126)
        ld      a,(iy-125)
        cp      (iy-111)
        call    nz,L_D887
        push    de
        pop     ix
        pop     de
        ret
.L_B52D
        add     a,$04
        bit     7,b
        ret     nz
        add     a,$06
        ret
.L_B535
        push    af
        call    L_B503
        pop     af
        add     a,b
        ret
.L_B53C
        push    af
        call    L_B503
        pop     af
        sub     b
        ret
.L_B543
        bit     7,(iy-72)
        ret     nz
        bit     0,(iy-72)
        ret     nz
        call    L_D249
        ret     c
        call    L_D7AA
        jr      c,L_B56E
        ld      a,(ix+3)
        bit     7,a
        ret     z
        and     $C0
        cp      $C0
        ret     z
        bit     6,(iy-71)
        ret     nz
        call    L_BB7B
.L_B569
        set     7,(iy-72)
        ret
.L_B56E
        ld      hl,($1D3D)
        ld      (hl),$00
        jr      L_B569
.L_B575
        call    L_B500
        ld      b,(iy-125)
        push   ix
        push    bc
        call    L_F06F
        ld      a,b
        pop     bc
        ld      c,a
        pop     de
        push    de
        pop     ix
        ld      a,(iy-79)
        cp      $02
        jr      z,L_B602
        cp      $00
        jr      z,L_B5F1
        cp      $05
        jr      z,L_B5DE
        cp      $08
        jr      nz,L_B5BF
        push    bc
        push   ix
        call    L_FE8A
        call    L_FEDA
        pop     ix
        pop     af
        cp      (iy-111)
        call    nz,L_D887
        exx
        ld      (ix+5),e
        ld      (ix+6),d
        exx
        ld      (ix+7),e
        ld      (ix+8),d
        ld      a,$02
        jr      L_B5EA
.L_B5BF
        push    bc
        call    L_B4F9
        push    de
        ld      hl,$0005
        add     hl,de
        pop     de
        ex      (sp),hl
        push    af
        ld      a,h
        cp      (iy-111)
        call    nz,L_D887
        pop     af
        ex      (sp),hl
        ld      (hl),a
        inc     hl
        ld      (hl),c
        inc     hl
        ld      (hl),b
        pop     bc
        ld      a,$00
        jr      L_B5EA
.L_B5DE
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        ld      (ix+5),l
        ld      a,$01
.L_B5EA
        ld      (ix+4),a
        ld      c,$40
        jr      L_B61C
.L_B5F1
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        ld      (ix+4),l
        ld      a,(ix+3)
        or      $10
        jr      L_B622
.L_B602
        push    bc
        push   ix
        call    L_FE72
        pop     hl
        pop     af
        push    hl
        cp      (iy-111)
        call    nz,L_D887
        ld      bc,$0004
        add     hl,bc
        call    L_F2DC
        pop     ix
        ld      c,$00
.L_B61C
        ld      a,(ix+3)
        and     $2F
        or      c
.L_B622
        bit     7,(iy-44)
        jr      z,L_B62A
        or      $20
.L_B62A
        ld      (ix+3),a
        ret
.L_B62E
        ld      a,(iy-58)
        and     $7F
.L_B633
        ld      c,(iy-57)
        ld      b,(iy-56)
        call    L_D77E
.L_B63C
        call    L_D79A
        jr      c,L_B663
        ld      hl,L_B6D7
        call    L_B6FF
        inc     (iy-109)
        jr      nz,L_B64F
        inc     (iy-108)
.L_B64F
        ld      a,(iy-108)
        cp      (iy-53)
        jr      c,L_B63C
        jr      nz,L_B663
        ld      a,(iy-109)
        cp      (iy-54)
        jr      c,L_B63C
        jr      z,L_B63C
.L_B663
        inc     (iy-110)
        ld      a,(iy-110)
        cp      (iy-55)
        jr      z,L_B633
        jr      c,L_B633
        ret
.L_B671
        ld      a,(iy-32)
        ld      c,(iy-31)
        ld      b,(iy-30)
        push    af
        push    bc
        ld      a,(iy-29)
        ld      c,(iy-28)
        ld      b,(iy-27)
        call    L_B690
        call    L_B6D3
        call    L_B6FB
        pop     bc
        pop     af
.L_B690
        ld      (iy-32),a
        ld      (iy-31),c
        ld      (iy-30),b
        ret
.L_B69A
        ld      a,(iy-58)
        and     $7F
        ld      e,a
        ld      a,(iy-110)
        cp      e
        jr      c,L_B6D8
        ld      e,(iy-55)
        res     6,e
        cp      e
        jr      z,L_B6B0
        jr      nc,L_B6D8
.L_B6B0
        ld      e,(iy-109)
        ld      d,(iy-108)
        ld      a,d
        cp      (iy-56)
        jr      c,L_B6D8
        jr      nz,L_B6C4
        ld      a,e
        cp      (iy-57)
        jr      c,L_B6D8
.L_B6C4
        ld      a,d
        cp      (iy-53)
        ret     c
        jr      nz,L_B6D8
        ld      a,e
        cp      (iy-54)
        ret     z
        jr      nc,L_B6D8
        ret
.L_B6D3
        ld      c,$00
        jr      L_B6D8
.L_B6D7
        ld      c,b
.L_B6D8
        bit     1,c
        jr      nz,L_B6E5
        ld      a,(hl)
        add     a,(iy-32)
        ld      (hl),a
        cp      $40
        jr      nc,L_B6F7
.L_B6E5
        bit     0,c
        ret     nz
        inc     hl
        ld      a,(hl)
        add     a,(iy-31)
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        adc     a,(iy-30)
        ld      (hl),a
        dec     hl
        dec     hl
        ret     p
.L_B6F7
        set     7,(hl)
        or      a
        ret
.L_B6FB
        set     6,(hl)
        or      a
        ret
.L_B6FF
        push    hl
        call    L_B503
        bit     5,a
        pop     ix
        ret     z
.L_B708
        ld      a,(hl)
        or      a
        ret     z
        inc     hl
        call    L_FE32
        jr      nc,L_B708
        ld      b,a
        ld      c,$00
        push    hl
        call    L_B8B4
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        jr      L_B708
.L_B71E
        xor     a
        ld      c,$80
.L_B721
        ld      b,a
        push    bc
        call    L_D0E2
        pop     de
        or      d
        ld      (iy-58),a
        ld      (iy-57),c
        ld      a,b
        or      e
        ld      (iy-56),a
        ret
.L_B734
        call    L_B690
        ld      l,a
        ld      e,$40
        ld      a,(iy-58)
        bit     7,a
        jr      nz,L_B74D
        ld      e,a
        bit     7,l
        jr      z,L_B74D
        ld      a,$FF
        sub     l
        add     a,(iy-58)
        ld      e,a
.L_B74D
        ld      (iy-55),e
        ld      (iy-54),$FF
        ld      e,$7F
        bit     7,(iy-56)
        jr      nz,L_B77B
        ld      a,(iy-57)
        ld      (iy-54),a
        ld      e,(iy-56)
        bit     7,b
        jr      z,L_B77B
        ld      hl,$FFFF
        or      a
        sbc     hl,bc
        ld      a,l
        add     a,(iy-57)
        ld      (iy-54),a
        ld      a,h
        adc     a,(iy-56)
        ld      e,a
.L_B77B
        ld      (iy-53),e
        ld      a,(iy-32)
        or      b
        jp      m,L_B78A
.L_B785
        set     7,(iy-55)
        ret
.L_B78A
        ld      bc,L_B6F7
.L_B78D
        ld      (iy-20),c
        ld      (iy-19),b
        ret
.L_B794
        call    L_B71E
        ld      a,$FF
        jr      L_B7A0
.L_B79B
        call    L_B71E
        ld      a,$01
.L_B7A0
        ld      bc,$0000
        jr      L_B7B9
.L_B7A5
        ld      c,$00
        call    L_B721
        xor     a
        ld      bc,$FFFF
        jr      L_B7B9
.L_B7B0
        ld      c,$00
        call    L_B721
        xor     a
        ld      bc,$0001
.L_B7B9
        call    L_B734
        jr      L_B7C1
.L_B7BE
        call    L_B690
.L_B7C1
        ld      a,(iy-42)
        push    af
        xor     a
.L_B7C6
        ld      bc,$0000
        call    L_D77E
.L_B7CC
        call    L_D79A
        jr      c,L_B7E1
        ld      hl,L_B8A0
        call    L_B6FF
        inc     (iy-109)
        jr      nz,L_B7CC
        inc     (iy-108)
        jr      L_B7CC
.L_B7E1
        inc     (iy-110)
        ld      a,(iy-110)
        cp      (iy-98)
        jr      c,L_B7C6
        ld      a,(iy-67)
        rla
        ld      a,(iy-64)
        rra
        push    af
        bit     7,(iy-67)
        jr      nz,L_B807
        ld      de,$FFBD
        push    iy
        pop     hl
        add     hl,de
        ld      c,$00
        call    L_B8A0
.L_B807
        bit     7,(iy-64)
        jr      nz,L_B819
        ld      de,$FFC0
        push    iy
        pop     hl
        add     hl,de
        ld      c,$00
        call    L_B8A0
.L_B819
        pop     de
        ld      a,(iy-67)
        rla
        ld      a,(iy-64)
        rra
        xor     d
        and     $C0
        call    nz,L_89F8
        pop     af
        ld      (iy-42),a
        ret
.L_B82D
        ld      b,$FE
        ld      a,(iy-58)
        bit     7,a
        jr      z,L_B845
        bit     6,a
        jr      nz,L_B863
        ld      a,(iy-58)
        and     $7F
        cp      (hl)
        scf
        ccf
        ret     nz
        jr      L_B863
.L_B845
        ld      a,(hl)
        cp      (iy-58)
        ccf
        ret     nc
        ld      e,(iy-55)
        bit     6,e
        jr      z,L_B85A
        ld      a,e
        and     $3F
        cp      (hl)
        jr      nc,L_B863
        or      a
        ret
.L_B85A
        bit     7,e
        jr      nz,L_B864
        cp      e
        jr      z,L_B863
        jr      nc,L_B864
.L_B863
        inc     b
.L_B864
        ld      e,l
        ld      d,h
        bit     7,(iy-56)
        jr      nz,L_B895
        inc     hl
        inc     hl
        ld      a,(hl)
        dec     hl
        cp      (iy-56)
        ccf
        ret     nc
        jr      nz,L_B87D
        ld      a,(hl)
        cp      (iy-57)
        ccf
        ret     nc
.L_B87D
        bit     7,(iy-55)
        jr      nz,L_B896
        inc     hl
        ld      a,(hl)
        cp      (iy-53)
        jr      c,L_B895
        jr      nz,L_B896
        dec     hl
        ld      a,(hl)
        cp      (iy-54)
        jr      z,L_B895
        jr      nc,L_B896
.L_B895
        inc     b
.L_B896
        ex      de,hl
        ld      a,b
        or      a
        scf
        ret     z
        call    L_B6D8
        or      a
        ret
.L_B8A0
        bit     6,(hl)
        jr      z,L_B8A7
        res     6,(hl)
        ret
.L_B8A7
        call    L_B82D
        ret     nc
        ld      e,(iy-20)
        ld      d,(iy-19)
        push    de
        pop     ix
.L_B8B4
        jp      (ix)
.L_B8B6
        call    L_B8C0
        ld      (iy-42),b
        ld      (iy-40),c
        ret
.L_B8C0
        ld      bc,$8001
        ret
.L_B8C4
        call    L_D77E
.L_B8C7
        call    L_D79A
        jp      nc,L_B95D
        ld      a,(iy-110)
        call    L_D8BF
        ret     c
        ld      a,(iy-110)
        call    L_D890
        inc     hl
        inc     hl
        inc     hl
        bit     7,(hl)
        jr      z,L_B903
        call    L_B8C0
        call    L_D926
        ret     c
        call    L_D8F2
        ex      de,hl
        ld      a,(iy-110)
        call    L_D890
        inc     hl
        inc     hl
        xor     a
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      a,(iy-125)
        ld      (hl),a
        jr      L_B8C7
.L_B903
        dec     hl
        ld      a,(iy-109)
        sub     (hl)
        ld      e,a
        inc     hl
        ld      a,(iy-108)
        sbc     a,(hl)
        ld      d,a
        ld      b,(hl)
        dec     hl
        ld      c,(hl)
.L_B912
        push    bc
        dec     de
        call    L_BA96
        call    L_BAB4
        ld      b,(iy-42)
        ld      c,(iy-40)
        ld      a,e
        or      d
        call    nz,L_B8C0
        push    de
        call    L_D926
        pop     de
        pop     hl
        ret     c
        push    de
        push    hl
        call    L_D8F2
        call    L_BAA0
        call    L_BABE
        call    L_BA44
        ex      (sp),hl
        inc     hl
        ld      (iy-109),l
        ld      (iy-108),h
        dec     hl
        ex      (sp),hl
        ex      de,hl
        ld      c,b
        ld      de,$0000
        ld      b,e
        call    L_B9D6
        pop     bc
        push    bc
        ld      a,(iy-110)
        call    L_CA0E
        pop     bc
        inc     bc
        pop     de
        ld      a,e
        or      d
        jr      nz,L_B912
        ret
.L_B95D
        call    L_B990
        ld      e,b
        ld      a,(iy-40)
        ld      b,(iy-42)
        call    L_B52D
        cp      e
        jr      nz,L_B975
        ld      a,(iy-42)
        ld      (ix+3),a
        or      a
        ret
.L_B975
        push    de
        call    L_D920
        pop     de
        ret     c
        push    de
        ld      a,(iy-110)
        call    L_BA24
        pop     bc
        ld      b,$00
        call    L_D95E
        call    L_D8F2
        call    L_B9A8
        or      a
        ret
.L_B990
        call    L_B500
        and     $C0
        ld      b,$06
        cp      $C0
        ret     z
        push   ix
.L_B99C
        ld      a,(hl)
        call    L_A8BB
        or      a
        jr      nz,L_B99C
        pop     de
        sbc     hl,de
        ld      b,l
        ret
.L_B9A8
        call    L_BB4B
        call    L_BABE
        call    L_BA44
        ex      de,hl
        ld      c,b
        call    L_BB69
        push    bc
        call    L_BA44
        call    L_B9D6
        pop     bc
        ld      a,c
        cp      (iy-111)
        ret     z
        jp      L_D887
.L_B9C6
        ld      a,l
        or      h
        jr      z,L_B9D6
        ld      a,(iy-109)
        or      a
        jr      nz,L_B9D3
        dec     (iy-108)
.L_B9D3
        dec     (iy-109)
.L_B9D6
        push    hl
        ld      a,h
        or      l
        jr      z,L_B9E3
        ld      l,(iy-109)
        ld      h,(iy-108)
        jr      L_BA08
.L_B9E3
        ld      a,d
        or      e
        ex      de,hl
        ld      c,b
        jr      nz,L_B9F0
        ld      de,$0000
        ld      c,l
        ld      b,l
        jr      L_BA00
.L_B9F0
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      b,(hl)
        dec     hl
        dec     hl
        xor     a
        inc     a
.L_BA00
        ex      (sp),hl
        ld      hl,$0000
        jr      nz,L_BA08
        set     7,h
.L_BA08
        ex      (sp),hl
        push    hl
        ld      a,(iy-110)
        inc     a
        call    L_D890
        dec     hl
        ld      (hl),b
        dec     hl
        ld      (hl),d
        dec     hl
        ld      (hl),e
        dec     hl
        ld      (hl),c
        dec     hl
        pop     de
        ld      (hl),d
        dec     hl
        ld      (hl),e
        dec     hl
        pop     de
        ld      (hl),d
        dec     hl
        ld      (hl),e
        ret
.L_BA24
        call    L_BAC8
.L_BA27
        call    L_BA44
.L_BA2A
        call    L_BAB4
        call    L_BB23
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)
        dec     hl
        dec     hl
        ex      de,hl
        ld      b,c
        ld      c,a
        call    L_BB0F
.L_BA44
        ld      a,l
        or      h
        ret     z
        ld      a,e
        or      d
        ret     z
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(hl)
        xor     e
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        xor     d
        ld      (hl),a
        inc     hl
        ld      a,(hl)
        xor     b
        ld      (hl),a
        dec     hl
        dec     hl
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(de)
        xor     l
        ld      (de),a
        inc     de
        ld      a,(de)
        xor     h
        ld      (de),a
        inc     de
        ld      a,(de)
        xor     c
        ld      (de),a
        dec     de
        dec     de
        ret
.L_BA73
        call    L_D77E
        ld      e,a
        ld      a,b
        or      c
        jr      z,L_BA7D
        dec     bc
        scf
.L_BA7D
        ld      a,e
        push    af
        call    L_D7AD
        pop     af
        push    af
        call    L_BAC8
        pop     af
        jr      c,L_BA90
        ex      de,hl
        ld      b,c
        ld      hl,$0000
        ld      c,l
.L_BA90
        call    L_BB0F
        jp      L_BB23
.L_BA96
        ld      l,(iy-127)
        ld      h,(iy-126)
        ld      c,(iy-125)
        ret
.L_BAA0
        ld      l,(iy-117)
        ld      h,(iy-116)
        ld      c,(iy-115)
        ret
.L_BAAA
        ld      (iy-127),l
        ld      (iy-126),h
        ld      (iy-125),c
        ret
.L_BAB4
        ld      (iy-117),l
        ld      (iy-116),h
        ld      (iy-115),c
        ret
.L_BABE
        ld      e,(iy-127)
        ld      d,(iy-126)
        ld      b,(iy-125)
        ret
.L_BAC8
        inc     a
        call    L_D890
        dec     hl
        ld      b,(hl)
        dec     hl
        ld      d,(hl)
        dec     hl
        ld      e,(hl)
        dec     hl
        ld      c,(hl)
        dec     hl
        push    de
        ld      d,(hl)
        dec     hl
        ld      e,(hl)
        ex      de,hl
        pop     de
        ret
.L_BADC
        call    L_BB4B
        call    L_BB5F
        call    L_BB2D
        call    L_BAFB
        call    L_BB41
        call    L_BB55
        call    L_BB23
.L_BAF1
        ld      (iy+74),l
        ld      (iy+75),h
        ld      (iy+76),c
        ret
.L_BAFB
        ld      (iy+71),l
        ld      (iy+72),h
        ld      (iy+73),c
        ret
.L_BB05
        ld      (iy+68),l
        ld      (iy+69),h
        ld      (iy+70),c
        ret
.L_BB0F
        ld      (iy+65),l
        ld      (iy+66),h
        ld      (iy+67),c
        ret
.L_BB19
        ld      (iy+74),e
        ld      (iy+75),d
        ld      (iy+76),b
        ret
.L_BB23
        ld      (iy+68),e
        ld      (iy+69),d
        ld      (iy+70),b
        ret
.L_BB2D
        ld      (iy+65),e
        ld      (iy+66),d
        ld      (iy+67),b
        ret
.L_BB37
        ld      l,(iy+71)
        ld      h,(iy+72)
        ld      c,(iy+73)
        ret
.L_BB41
        ld      l,(iy+68)
        ld      h,(iy+69)
        ld      c,(iy+70)
        ret
.L_BB4B
        ld      l,(iy+65)
        ld      h,(iy+66)
        ld      c,(iy+67)
        ret
.L_BB55
        ld      e,(iy+74)
        ld      d,(iy+75)
        ld      b,(iy+76)
        ret
.L_BB5F
        ld      e,(iy+71)
        ld      d,(iy+72)
        ld      b,(iy+73)
        ret
.L_BB69
        ld      e,(iy+68)
        ld      d,(iy+69)
        ld      b,(iy+70)
        ret
.L_BB73
        ld      (iy-36),a
        ld      bc,L_BC17
        jr      L_BB7E
.L_BB7B
        ld      bc,L_BC07
.L_BB7E
        ld      (iy-34),$00
        ld      ($1D4B),bc
        ld      ($1D47),sp
        call    L_B500
.L_BB8D
        ld      a,(hl)
        or      a
        jr      z,L_BBB7
        inc     hl
        cp      $14
        jr      nz,L_BB98
        ld      a,$22
.L_BB98
        call    L_FE32
        jr      nc,L_BBB2
        ld      c,$00
        bit     0,a
        jr      z,L_BBA5
        set     2,c
.L_BBA5
        bit     1,a
        jr      z,L_BBAB
        set     0,c
.L_BBAB
        push    bc
        pop     af
        call    L_BC2C
        jr      L_BB8D
.L_BBB2
        call    L_BBFC
        jr      L_BB8D
.L_BBB7
        call    L_BBFC
        ld      c,$00
        push    bc
        pop     af
        ret
.L_BBBF
        push    bc
        ld      c,$00
        ld      b,a
        push    bc
        pop     af
        pop     bc
.L_BBC6
        push    bc
        push    af
        bit     7,a
        ld      a,$25
        call    nz,L_BBFC
        pop     af
        push    af
        call    c,L_BBF6
        pop     af
        push    af
        and     $7F
        call    L_BC39
        call    L_BBE6
        pop     af
        call    pe,L_BBF6
        pop     bc
        call    L_BC60
.L_BBE6
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
.L_BBED
        call    L_BBFA
        dec     (iy-74)
        jr      nz,L_BBED
        ret
.L_BBF6
        ld      a,$24
        jr      L_BBFC
.L_BBFA
        ld      a,(hl)
        inc     hl
.L_BBFC
        push    hl
        push    af
        ld      hl,($1D4B)
        call    L_9223
        pop     af
        pop     hl
        ret
.L_BC07
        push    de
        ld      hl,($1D3D)
        ld      e,(iy-34)
        ld      d,$00
        add     hl,de
        ld      (hl),a
        inc     (iy-34)
        pop     de
        ret
.L_BC17
        push    af
        ld      a,(iy-36)
        or      a
        jr      z,L_BC2A
        pop     af
        or      a
        ret     z
        inc     (iy-34)
        dec     (iy-36)
        oz      Os_out
        ret
.L_BC2A
        pop     af
        ret
.L_BC2C
        push    af
        call    L_B4F9
        ld      e,a
        pop     af
        push    hl
        ld      a,e
        call    L_BBC6
        pop     hl
        ret
.L_BC39
        ld      c,$00
.L_BC3B
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        push    bc
        ld      b,$00
        add     hl,bc
        pop     bc
        ld      e,$FF
.L_BC49
        inc     e
        sub     $1A
        jr      nc,L_BC49
        add     a,$5B
        ld      d,a
        ld      a,e
        or      a
        jr      z,L_BC5A
        add     a,$40
        ld      (hl),a
        inc     hl
        inc     c
.L_BC5A
        ld      (hl),d
        inc     c
        ld      (iy-74),c
        ret
.L_BC60
        inc     bc
        ld      l,c
        ld      h,b
        jp      L_EE87
.L_BC66
        ld      ix,$1DAA
        ld      hl,($1D3D)
.L_BC6D
        ld      a,(iy-110)
        push    af
        ld      c,(iy-109)
        ld      b,(iy-108)
        push    bc
        ld      de,$0000
        ld      (iy-38),e
        rr      d
        srl     d
.L_BC82
        ld      a,d
        and     $C0
        jr      nz,L_BC8C
        call    L_BDBE
        dec     hl
.L_BC8B
        inc     hl
.L_BC8C
        ld      a,(hl)
        or      a
        jr      z,L_BCA4
        bit     6,d
        jr      nz,L_BCA4
        cp      $20
        jr      c,L_BC8B
        cp      $22
        jr      nz,L_BCAD
        ld      a,d
        xor     $80
        ld      d,a
        ld      a,$14
        jr      L_BCAD
.L_BCA4
        push    af
        ld      a,d
        and     $30
        cp      $20
        jr      nz,L_BCF7
        pop     af
.L_BCAD
        push    af
        ld      c,a
        ld      a,d
        and     $81
        jr      nz,L_BCF7
        ld      a,c
        cp      $24
        jr      z,L_BCBE
        call    L_EE1B
        jr      nc,L_BCF7
.L_BCBE
        push    hl
        push    de
        call    L_BD57
        pop     de
        jr      c,L_BCF6
        bit     6,d
        jr      z,L_BCCE
        cp      $40
        jr      nz,L_BCF6
.L_BCCE
        pop     af
        pop     af
        ld      a,c
        add     a,$10
        call    L_BD43
        jr      c,L_BD37
        ld      a,(iy-110)
        call    L_BD43
        jr      c,L_BD37
        ld      a,(iy-109)
        call    L_BD43
        jr      c,L_BD37
        ld      a,(iy-108)
        call    L_BD43
        jr      c,L_BD37
        res     0,d
        ld      e,$40
        jr      L_BC82
.L_BCF6
        pop     hl
.L_BCF7
        pop     af
        or      a
        jr      z,L_BD26
        rr      d
        call    L_EE17
        rl      d
        call    L_BD43
        jr      c,L_BD37
        bit     6,d
        jr      z,L_BD22
        ld      c,a
        ld      a,d
        and     $20
        srl     a
        or      $20
        ld      b,a
        ld      a,d
        and     $CF
        or      b
        ld      b,a
        ld      a,c
        cp      $40
        ld      a,b
        jr      z,L_BD21
        and     $CF
.L_BD21
        ld      d,a
.L_BD22
        inc     hl
        jp      L_BC82
.L_BD26
        call    L_BD43
        jr      c,L_BD37
        ld      b,(iy-38)
        or      a
        bit     6,e
        call    nz,L_F9B7
        call    z,L_F994
.L_BD37
        pop     de
        ld      (iy-108),d
        ld      (iy-109),e
        pop     de
        ld      (iy-110),d
        ret
.L_BD43
        ld      (ix+0),a
        inc     ix
        inc     (iy-38)
        ld      b,a
        ld      a,(iy-38)
        cp      $F5
        ccf
        ld      a,b
        ret     nc
        ld      c,$15
        ret
.L_BD57
        call    L_BDBE
        ld      c,$00
        cp      $24
        jr      nz,L_BD62
        inc     c
        inc     hl
.L_BD62
        push    bc
        call    L_BD91
        jr      c,L_BD8E
        ld      a,(hl)
        inc     hl
        cp      $24
        scf
        jr      z,L_BD71
        dec     hl
        or      a
.L_BD71
        pop     bc
        rl      c
        push    bc
        call    L_EE29
        jr      z,L_BD8E
        ld      a,c
        sub     $01
        jr      nc,L_BD80
        dec     b
.L_BD80
        bit     7,b
        jr      nz,L_BD8E
        ld      (iy-109),a
        ld      (iy-108),b
        pop     bc
        ld      a,(hl)
        or      a
        ret
.L_BD8E
        pop     bc
        scf
        ret
.L_BD91
        ld      a,(hl)
        call    L_BDC8
        jr      nc,L_BDBB
        inc     hl
        ld      (iy-110),a
        ld      a,(hl)
        call    L_BDC8
        ret     nc
        inc     hl
        push    hl
        ld      e,a
        ld      l,(iy-110)
        inc     l
        ld      h,$00
        ld      a,$1A
        call    L_F048
        ld      a,l
        pop     hl
        ret     c
        add     a,e
        ret     c
        cp      $40
        ccf
        ret     c
        ld      (iy-110),a
        ret
.L_BDBB
        xor     a
        scf
        ret
.L_BDBE
        dec     hl
.L_BDBF
        inc     hl
        ld      a,(hl)
        or      a
        ret     z
        cp      $20
        jr      z,L_BDBF
        ret
.L_BDC8
        call    L_EE1B
        ret     nc
        and     $DF
        sub     $41
        ccf
        ret
.L_BDD2
        ld      hl,($1D53)
        jp      (hl)
.L_BDD6
        xor     a
        call    L_E0B3
        set     2,(iy-99)
        set     1,(iy-99)
        res     5,(iy-70)
        call    L_D590
        ld      b,a
        call    L_EEFE
        ld      ix,($1D61)
        ld      de,$0006
.L_BDF4
        ld      (ix+5),a
        add     ix,de
        djnz    L_BDF4
        call    L_EEDD
        call    L_EFDC
        call    L_CA8D
        res     5,(iy-68)
.L_BE08
        call    L_D0E2
        ld      (iy+2),a
        ld      (iy+3),c
        ld      (iy+4),b
        bit     6,(iy-99)
        jr      z,L_BE30
        call    L_D104
        call    L_C9F9
        jr      nc,L_BE2A
        call    L_D403
        call    L_CA8D
        jr      L_BE30
.L_BE2A
        call    L_D8AB
        call    L_D452
.L_BE30
        bit     1,(iy-99)
        jr      z,L_BE42
        call    L_D0E5
        ld      (iy-38),a
        call    L_D0D0
        call    L_D198
.L_BE42
        ld      a,(iy-100)
        or      a
        jp      z,L_C1F8
        jp      m,L_C1A6
        ld      a,(iy-101)
        or      a
        jp      z,L_C018
        dec     a
        jp      z,L_BF0F
        dec     a
        jr      z,L_BEC0
        ld      hl,($1D5D)
        ld      de,($1D5F)
        ld      a,h
        cp      d
        jr      nz,L_BE69
        ld      a,l
        cp      e
        jr      z,L_BE77
.L_BE69
        inc     hl
        ld      a,h
        cp      d
        jr      nz,L_BE72
        ld      a,l
        cp      e
        jr      z,L_BE77
.L_BE72
        ld      ($1D5D),hl
        jr      L_BED3
.L_BE77
        call    L_D1F2
        jr      nc,L_BE8E
        ld      bc,($1D5D)
        ld      a,h
        cp      b
        jr      nz,L_BE89
        ld      a,l
        cp      c
        jp      z,L_C1F8
.L_BE89
        ld      ($1D5D),hl
        jr      L_BED3
.L_BE8E
        ld      (iy-38),a
        call    L_D0D0
        ld      (iy-40),a
.L_BE97
        ld      a,(iy-40)
        call    L_D198
        ld      hl,($1D5F)
        call    L_D0E8
        jr      c,L_BEB1
        cp      (iy-38)
        jr      c,L_BEBB
        jr      nz,L_BEFE
        ld      a,(iy-40)
        jr      L_BEB6
.L_BEB1
        dec     hl
        call    L_D0E8
        inc     hl
.L_BEB6
        cp      (iy-38)
        jr      nc,L_BEFE
.L_BEBB
        inc     (iy-40)
        jr      L_BE97
.L_BEC0
        ld      de,($1D5B)
        ld      hl,($1D5D)
        ld      a,h
        cp      d
        jr      nz,L_BECF
        ld      a,l
        cp      e
        jr      z,L_BEE1
.L_BECF
        dec     hl
        ld      ($1D5D),hl
.L_BED3
        set     2,(iy-99)
        bit     6,(iy-71)
        call    z,L_8D45
        jp      L_C152
.L_BEE1
        call    L_D0E8
        ld      (iy-38),$00
        call    L_D0D0
        or      a
        jr      z,L_BF05
        ld      e,a
.L_BEEF
        dec     e
        jr      z,L_BEFA
        ld      a,e
        call    L_D890
        ld      a,(hl)
        or      a
        jr      z,L_BEEF
.L_BEFA
        ld      a,e
        call    L_D198
.L_BEFE
        call    L_CA8D
        set     2,(iy-99)
.L_BF05
        bit     6,(iy-71)
        call    z,L_8D45
        jp      L_C1F8
.L_BF0F
        ld      a,(iy-100)
        dec     a
        jp      nz,L_BFCC
.L_BF16
        ld      de,($1D63)
        ld      hl,$0006
        add     hl,de
        bit     6,(hl)
        jr      z,L_BF4E
        ex      de,hl
        bit     5,(hl)
        jr      nz,L_BF30
        call    L_D8B8
        call    L_CA1E
        jp      z,L_C1F8
.L_BF30
        call    L_D590
        ld      c,a
        dec     c
        ld      de,($1D61)
        ld      hl,($1D63)
        or      a
        sbc     hl,de
        ld      de,$0006
        ld      b,$FF
        or      a
.L_BF45
        inc     b
        sbc     hl,de
        jr      nc,L_BF45
        ld      a,b
        cp      c
        jr      nc,L_BF61
.L_BF4E
        ld      hl,($1D63)
        ld      de,$0006
        add     hl,de
        ld      ($1D63),hl
        jp      L_BFBA
.L_BF5B
        call    L_C13A
        jp      L_C1F8
.L_BF61
        call    L_D8A1
        call    L_D5D1
        jr      c,L_BF6E
        ld      a,$01
        call    L_BFF6
.L_BF6E
        call    L_D104
        call    L_C129
.L_BF74
        or      a
        call    L_D2C3
        call    L_D252
        jr      c,L_BF83
        ld      a,(iy-61)
        or      a
        jr      z,L_BF8D
.L_BF83
        call    L_C9EB
        jr      z,L_BF5B
        call    L_D5D7
        jr      c,L_BF74
.L_BF8D
        call    L_D469
        ld      hl,($1D61)
        bit     7,(hl)
        jr      nz,L_BFA3
        bit     7,(iy-71)
        jr      nz,L_BFA3
        bit     6,(iy-71)
        jr      z,L_BFA8
.L_BFA3
        call    L_CA8D
        jr      L_BFBA
.L_BFA8
        ld      a,$FF
        call    L_C884
        call    L_C8D9
        ld      (ix-7),$00
        ld      hl,($1D63)
        call    L_CA39
.L_BFBA
        call    L_C14B
        ld      hl,($1D63)
        ld      de,$0006
        or      a
        sbc     hl,de
        call    L_CA39
        jp      L_BF16
.L_BFCC
        call    L_C0FB
        push    af
        call    L_D5D7
        ld      a,$00
        jr      c,L_BFDC
        pop     af
        push    af
        call    L_BFF6
.L_BFDC
        ld      (iy-34),a
        call    L_D104
        pop     af
        sub     (iy-34)
        jr      c,L_BFED
        jr      z,L_BFED
        call    L_BFFC
.L_BFED
        call    L_D452
        call    L_CA8D
        jp      L_C1F8
.L_BFF6
        call    L_BFFC
        jp      L_C0DB
.L_BFFC
        ld      c,(iy-26)
        ld      b,(iy-25)
        inc     bc
        ld      e,a
        call    L_C9F9
        ld      a,e
        ret     c
        push    de
        push    bc
        call    L_D5D1
        pop     bc
        pop     de
        ld      a,e
        jr      c,L_BFFC
        dec     a
        jr      nz,L_BFFC
        or      a
        ret
.L_C018
        ld      a,(iy-100)
        dec     a
        jp      nz,L_C0AE
.L_C01F
        ld      de,($1D61)
        ld      hl,($1D63)
        ld      a,h
        cp      d
        jr      nz,L_C02E
        ld      a,l
        cp      e
        jr      z,L_C040
.L_C02E
        ld      de,$0006
        or      a
        sbc     hl,de
        ld      ($1D63),hl
        jp      L_C096
.L_C03A
        call    L_C13A
        jp      L_C25A
.L_C040
        call    L_D8A1
        call    L_D5D1
        jr      c,L_C04D
        ld      a,$01
        call    L_C0D8
.L_C04D
        call    L_D104
        call    L_C129
.L_C053
        call    L_CA21
        jr      c,L_C03A
        scf
        call    L_D2C3
        jr      c,L_C065
        call    L_D5D7
        jr      c,L_C053
        jr      L_C068
.L_C065
        call    L_C9EB
.L_C068
        call    L_D469
        ld      hl,($1D61)
        bit     7,(hl)
        jr      nz,L_C07E
        bit     7,(iy-71)
        jr      nz,L_C07E
        bit     6,(iy-71)
        jr      z,L_C084
.L_C07E
        call    L_CA8D
        jp      L_C096
.L_C084
        ld      a,$FE
        call    L_C884
        call    L_C8F2
        ld      (ix+5),$00
        ld      hl,($1D63)
        call    L_CA39
.L_C096
        call    L_C14B
        call    L_D8B8
        ld      a,b
        or      c
        jp      z,L_BF0F
        ld      hl,($1D63)
        ld      de,$0006
        add     hl,de
        call    L_CA39
        jp      L_C01F
.L_C0AE
        call    L_C0FB
        push    af
        call    L_D5D7
        ld      a,$00
        jr      c,L_C0BE
        pop     af
        push    af
        call    L_C0D8
.L_C0BE
        ld      (iy-34),a
        call    L_D104
        pop     af
        sub     (iy-34)
        jr      c,L_C0CF
        jr      z,L_C0CF
        call    L_C0E8
.L_C0CF
        call    L_D452
        call    L_CA8D
        jp      L_C1F8
.L_C0D8
        call    L_C0E8
.L_C0DB
        ld      e,(iy-26)
        ld      (iy-24),e
        ld      e,(iy-25)
        ld      (iy-23),e
        ret
.L_C0E8
        ld      b,a
.L_C0E9
        push    bc
.L_C0EA
        call    L_CA21
        pop     bc
        ld      a,b
        ret     c
        push    bc
        call    L_D5D7
        jr      c,L_C0EA
        pop     bc
        djnz    L_C0E9
        xor     a
        ret
.L_C0FB
        call    L_D0F1
        ld      (iy-34),a
        call    L_D8A1
        call    L_D590
        ld      c,a
        sub     (iy-34)
        ld      b,a
        ld      a,(iy+7)
        or      a
        jr      z,L_C11C
        ld      a,c
        ld      c,$FF
.L_C115
        inc     c
        sub     (iy+7)
        jr      nc,L_C115
        ld      a,c
.L_C11C
        ld      e,a
        ld      a,b
        sub     e
        jr      c,L_C126
        sub     $01
        jr      z,L_C126
        ret     nc
.L_C126
        ld      a,$01
        ret
.L_C129
        push    iy
        pop     ix
        ld      b,$03
.L_C12F
        ld      a,(ix-94)
        ld      (ix-61),a
        inc     ix
        djnz    L_C12F
        ret
.L_C13A
        push    iy
        pop     ix
        ld      b,$03
.L_C140
        ld      a,(ix-61)
        ld      (ix-94),a
        inc     ix
        djnz    L_C140
        ret
.L_C14B
        ld      hl,($1D63)
        bit     5,(hl)
        ret     nz
        pop     de
.L_C152
        set     5,(iy-72)
        ld      c,(iy+3)
        ld      b,(iy+4)
        call    L_D24C
        jr      c,L_C17C
        ld      a,(iy+2)
        call    L_C989
        jr      nc,L_C170
        jr      z,L_C17C
        call    L_C9DF
        jr      L_C17C
.L_C170
        ld      c,(iy+3)
        ld      b,(iy+4)
        call    L_D56B
        call    nc,L_CA39
.L_C17C
        call    L_D8A1
        call    L_D0E5
        call    L_C989
        jr      nc,L_C192
        jr      z,L_C192
        bit     6,(iy-71)
        call    nz,L_C9DF
        jr      L_C1F8
.L_C192
        ld      hl,($1D63)
        call    L_CA39
        jr      L_C1F8
.L_C19A
        ld      a,(iy+2)
.L_C19D
        ld      c,(iy+3)
        ld      b,(iy+4)
        call    L_82A6
.L_C1A6
        ld      a,(iy-104)
        call    L_D55D
        jr      c,L_C1C1
        ld      de,($1D5F)
        ld      a,h
        cp      d
        jr      c,L_C1BC
        jr      nz,L_C1C1
        ld      a,l
        cp      e
        jr      nc,L_C1C1
.L_C1BC
        ld      ($1D5D),hl
        jr      L_C1CA
.L_C1C1
        ld      a,(iy-104)
        call    L_D128
        call    L_CA8D
.L_C1CA
        ld      c,(iy-103)
        ld      b,(iy-102)
        call    L_D5D1
        jr      nc,L_C1DB
        bit     5,(iy-71)
        jr      nz,L_C1EC
.L_C1DB
        ld      c,(iy-103)
        ld      b,(iy-102)
        call    L_D56B
        jr      c,L_C1EC
        ld      ($1D63),hl
        jp      L_C152
.L_C1EC
        ld      c,(iy-103)
        ld      b,(iy-102)
        call    L_D403
        call    L_CA8D
.L_C1F8
        ld      hl,($1D5D)
        ld      de,($1D5F)
        ld      a,h
        cp      d
        jr      c,L_C220
        jr      nz,L_C209
        ld      a,l
        cp      e
        jr      c,L_C220
.L_C209
        ex      de,hl
        call    L_D0E8
        jr      nc,L_C21D
        ld      de,($1D5B)
        ex      de,hl
        xor     a
        sbc     hl,de
        jp      z,L_C19D
        ld      l,e
        ld      h,d
        dec     hl
.L_C21D
        ld      ($1D5D),hl
.L_C220
        ld      hl,($1D61)
        bit     6,(hl)
        jp      nz,L_C19A
        ld      de,$0006
        ld      bc,($1D63)
.L_C22F
        add     hl,de
        bit     6,(hl)
        jr      nz,L_C24A
        bit     5,(hl)
        jr      z,L_C22F
        ld      a,h
        cp      b
        jr      nz,L_C22F
        ld      a,l
        cp      c
        jr      nz,L_C22F
        sbc     hl,de
        ld      ($1D63),hl
        ld      b,h
        ld      c,l
        add     hl,de
        jr      L_C22F
.L_C24A
        or      a
        sbc     hl,de
        ld      a,h
        cp      b
        jr      c,L_C257
        jr      nz,L_C25A
        ld      a,l
        cp      c
        jr      nc,L_C25A
.L_C257
        ld      ($1D63),hl
.L_C25A
        bit     3,(iy-99)
        jr      z,L_C26E
        call    L_D7AA
        jr      nc,L_C26B
        set     0,(iy-99)
        jr      L_C26E
.L_C26B
        call    L_C9DF
.L_C26E
        ld      a,(iy-99)
        and     $81
        push    af
        jr      z,L_C27A
        set     5,(iy-72)
.L_C27A
        bit     7,(iy-99)
        jr      nz,L_C28C
        bit     7,(iy-72)
        jr      z,L_C28C
        ld      a,(iy-100)
        or      a
        jr      z,L_C292
.L_C28C
        call    L_EF91
        call    L_C866
.L_C292
        call    L_B543
        call    L_D8A1
        set     7,(iy-38)
        ld      a,$28
        ld      (iy-89),a
        add     a,$28
        ld      (iy-42),a
        ld      a,$28
        ld      b,$00
        bit     6,(iy-71)
        jr      nz,L_C2DF
        call    L_D0E5
        ld      (iy-38),a
        push    af
        call    L_D54A
        ld      (iy-42),a
        pop     af
        call    L_C917
        cp      (iy-42)
        jr      nc,L_C2C9
        ld      a,(iy-42)
.L_C2C9
        ld      (iy-89),a
        ld      hl,($1D63)
        push    hl
        pop     ix
        ld      a,(ix+5)
        ld      (iy-42),a
        ld      bc,($1D5D)
        call    L_D08D
.L_C2DF
        ld      (iy-28),a
        ld      (iy-27),b
        bit     7,(iy-72)
        jr      z,L_C30B
        call    L_CA99
        ld      a,(iy-81)
        call    L_C45E
        bit     6,(iy-71)
        jr      nz,L_C30B
        jr      c,L_C30B
        add     a,(iy-28)
        cp      (iy-42)
        jr      c,L_C30B
        ld      ix,($1D63)
        ld      (ix+5),a
.L_C30B
        res     5,(iy-72)
        bit     3,(iy-72)
        jr      z,L_C364
        res     3,(iy-72)
        ld      hl,($1D61)
.L_C31C
        bit     6,(hl)
        jr      nz,L_C364
        ld      (iy-44),l
        ld      (iy-43),h
        push    hl
        bit     5,(hl)
        jr      nz,L_C35D
        ld      hl,($1D5B)
        ld      (iy-42),$00
.L_C332
        call    L_D0E8
        jr      c,L_C35D
        ex      (sp),hl
        push    af
        call    L_D8B8
        pop     af
        ex      (sp),hl
        push    hl
        call    L_D7AD
        jr      c,L_C359
        bit     0,(ix+3)
        jr      z,L_C359
        res     0,(ix+3)
        bit     7,(iy-99)
        jr      nz,L_C359
        pop     hl
        push    hl
        call    L_C612
.L_C359
        pop     hl
        inc     hl
        jr      L_C332
.L_C35D
        pop     hl
        ld      de,$0006
        add     hl,de
        jr      L_C31C
.L_C364
        ld      a,(iy-99)
        and     $B5
        ld      (iy-99),a
        pop     af
        or      a
        jp      z,L_C414
        call    m,L_C7A5
        ld      hl,($1D61)
.L_C377
        scf
        bit     7,(iy-68)
        call    z,L_E31D
        jp      nc,L_C414
        ld      a,(hl)
        bit     6,a
        jr      nz,L_C3AD
        and     $80
        jr      nz,L_C3A2
        bit     7,(iy-99)
        jr      nz,L_C3A2
        call    L_D8B8
        ld      a,b
        cp      (iy+4)
        jr      c,L_C3A7
        jr      nz,L_C3A2
        ld      a,c
        cp      (iy+3)
        jr      c,L_C3A7
.L_C3A2
        push    hl
        call    L_C4F6
        pop     hl
.L_C3A7
        ld      de,$0006
        add     hl,de
        jr      L_C377
.L_C3AD
        res     7,(iy-68)
        ld      a,(iy-99)
        and     $30
        ld      (iy-99),a
        push    hl
        call    L_D0B1
        pop     ix
        ld      c,b
.L_C3C0
        ld      a,b
        cp      (iy-80)
        jr      nc,L_C414
        xor     a
        call    L_EEE4
        ld      a,b
        cp      c
        jr      nz,L_C402
        call    L_D5A7
        ld      a,$06
        call    c,L_C5EA
        call    L_EFEF
        oz      Os_Pout
        defm    " End of text ", $00

        call    L_EFEF
        call    L_D5A7
        ld      e,$0D
        jr      nc,L_C3F6
        ld      e,$13
.L_C3F6
        ld      a,(ix+5)
        ld      (ix+5),e
        sub     e
        jr      nc,L_C409
        xor     a
        jr      L_C409
.L_C402
        ld      a,(ix+5)
        ld      (ix+5),$00
.L_C409
        ld      de,$0006
        add     ix,de
        call    L_EFDC
        inc     b
        jr      L_C3C0
.L_C414
        bit     2,(iy-99)
        call    nz,L_C7A5
        ld      a,$20
        ld      l,(iy-52)
        ld      h,(iy-51)
        call    L_C4F2
        ld      a,$10
        ld      l,(iy-50)
        ld      h,(iy-49)
        call    L_C4F2
        xor     a
        ld      (iy-100),a
        ld      (iy-101),a
        res     5,(iy-71)
.L_C43C
        bit     4,(iy-71)
        res    4,(iy-71)
        call    nz,L_EB49
        ld      a,(iy-87)
        sub     (iy-88)
        add     a,(iy-28)
        cp      (iy-81)
        jr      c,L_C458
        ld      a,(iy-81)
.L_C458
        ld      b,(iy-27)
        jp      L_EEE4
.L_C45E
        sub     (iy-28)
        ld      e,(iy-89)
        cp      e
        jr      nc,L_C468
        ld      e,a
.L_C468
        ld      c,(iy-88)
        ld      a,c
        scf
        adc     a,e
        ld      d,a
        ld      b,(iy-87)
        ld      a,b
        cp      d
        jr      nc,L_C483
        cp      (iy-88)
        jr      c,L_C493
        bit     5,(iy-72)
        jr      nz,L_C494
        jr      L_C4E7
.L_C483
        ld      a,e
        bit     7,(iy-100)
        jr      z,L_C48C
        srl     a
.L_C48C
        ld      d,a
        ld      c,$00
        ld      a,b
        sub     d
        jr      c,L_C494
.L_C493
        ld      c,a
.L_C494
        ld      a,b
        cp      e
        jr      nc,L_C49A
        ld      c,$00
.L_C49A
        ld      (iy-88),c
        ld      d,(iy-28)
        ld      a,d
        ld      b,(iy-27)
        call    L_EEE4
        push    de
        call    L_8572
        ld      a,b
        cp      (iy-88)
        jr      c,L_C4B4
        ld      b,(iy-88)
.L_C4B4
        ld      hl,($1D3D)
        ld      c,b
        ld      b,$00
        add     hl,bc
        pop     de
.L_C4BC
        ld      a,(hl)
        or      a
        jr      z,L_C4CA
        inc     hl
        cp      $20
        jr      nc,L_C4E1
        call    L_CADB
        jr      L_C4E3
.L_C4CA
        bit     7,(iy-85)
        jr      nz,L_C4DF
        ld      a,(iy-42)
        sub     d
        jr      c,L_C4E7
        cp      e
        jr      c,L_C4DA
        ld      a,e
.L_C4DA
        call    L_C5EA
        jr      L_C4E7
.L_C4DF
        ld      a,' '
.L_C4E1
        oz      Os_out
.L_C4E3
        inc     d
        dec     e
        jr      nz,L_C4BC
.L_C4E7
        call    L_CA92
        ld      a,d
        sub     (iy-28)
        ccf
        ret     z
        or      a
        ret
.L_C4F2
        and     (iy-99)
        ret     z
.L_C4F6
        ld      (iy-44),l
        ld      (iy-43),h
        ld      a,l
        cp      (iy-52)
        jr      nz,L_C50C
        ld      a,h
        cp      (iy-51)
        jr      nz,L_C50C
        res     5,(iy-99)
.L_C50C
        ld      a,l
        cp      (iy-50)
        jr      nz,L_C51C
        ld      a,h
        cp      (iy-49)
        jr      nz,L_C51C
        res    4,(iy-99)
.L_C51C
        call    L_D8B8
        ld      (iy-26),c
        ld      (iy-25),b
        bit     5,(hl)
        jr      z,L_C53B
        call    L_CB02
        ld      b,(iy-81)
        ld      a,$5E
.L_C531
        ld      c,(iy-81)
.L_C534
        oz      Os_out
        djnz    L_C534
        jp      L_C5C1
.L_C53B
        xor     a
        ld      (iy-42),a
        ld      (iy-46),a
        call    L_CB02
        call    L_D5A7
        jr      nc,L_C575
        ld      c,(iy-26)
        ld      b,(iy-25)
        call    L_BC60
        ld      a,$05
        ld      (iy-42),a
        ld      (iy-46),a
        sub     (iy-74)
        jr      z,L_C56F
        push    af
        call    L_D5D7
        ld      a,$5F
        jr      c,L_C56A
        ld      a,$20
.L_C56A
        pop     bc
.L_C56B
        oz      Os_out
        djnz    L_C56B
.L_C56F
        call    L_EE3B
        call    L_ED8A
.L_C575
        call    L_D252
        jr      nc,L_C5A6
        call    L_D59D
        ld      b,a
        call    L_D278
        jr      nc,L_C590
        call    L_B518
        ld      a,(ix+4)
        call    L_D266
        ld      a,$7E
        jr      c,L_C531
.L_C590
        call    L_EE4E
        ld      c,$06
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
.L_C59C
        ld      a,(hl)
        or      a
        jr      z,L_C5C1
        oz      Os_out
        inc     c
        inc     hl
        jr      L_C59C
.L_C5A6
        ld      hl,($1D5B)
        ld      b,(iy-42)
.L_C5AC
        call    L_D0E8
        jr      c,L_C5C7
        call    L_C612
        ret     c
        ld      a,b
        cp      (iy-46)
        jr      c,L_C5BE
        ld      (iy-46),b
.L_C5BE
        inc     hl
        jr      L_C5AC
.L_C5C1
        ld      (iy-42),c
        ld      (iy-46),c
.L_C5C7
        ld      l,(iy-44)
        ld      h,(iy-43)
        push    hl
        pop     ix
        ld      e,(ix+5)
        ld      a,(iy-42)
        ld      (ix+5),a
        ld      a,e
        sub     (iy-46)
        ret     c
        ret     z
        push    af
        call    L_D0B1
        ld      a,(iy-46)
        call    L_EEE4
        pop     af
.L_C5EA
        or      a
        ret     z
        bit     6,(iy-70)
        jr      nz,L_C609
        push    af
        ld      a,$01
        oz      Os_out
        ld      a,$33
        oz      Os_out
        ld      a,$4E
        oz      Os_out
        pop     af
        add     a,$20
        oz      Os_out
        ld      a,$20
        oz      Os_out
        ret
.L_C609
        push    bc
        ld      b,a
.L_C60B
        call    L_ED8A
        djnz    L_C60B
        pop     bc
        ret
.L_C612
        call    L_D0E8
        ld      (iy-38),a
        ld      e,a
        push    hl
        ld      l,(iy-44)
        ld      h,(iy-43)
        call    L_D8B8
        ld      a,e
        call    L_D77E
        call    L_D24C
        pop     hl
        ret     c
        push    hl
        ld      a,(iy-110)
        call    L_C917
        ld      (iy-40),a
        call    L_D79A
        call    nc,L_C9B8
        pop     bc
        push    bc
        push    af
        ld      l,(iy-44)
        ld      h,(iy-43)
        call    L_D08D
        ld      (iy-32),a
        ld      (iy-31),b
        pop     af
        pop     hl
        push    hl
        push    af
        call    L_D547
        ld      c,a
        ld      e,(iy-40)
        cp      e
        jr      nc,L_C65D
        ld      c,e
.L_C65D
        ld      a,(iy-81)
        sub     (iy-32)
        ld      d,a
        ld      a,c
        cp      d
        jr      c,L_C669
        ld      c,d
.L_C669
        ld      a,d
        cp      (iy-40)
        jr      c,L_C672
        ld      a,(iy-40)
.L_C672
        ld      (iy-40),c
        ld      (iy-36),a
        pop     af
        jr      c,L_C689
        push    af
        call    L_B518
        ld      a,(ix+3)
        and     $C0
        cp      $80
        jr      nz,L_C6D3
        pop     af
.L_C689
        pop     de
        push    de
        push    af
        ld      hl,$1D5D
        ld      a,e
        cp      (hl)
        jr      nz,L_C6D3
        inc     hl
        ld      a,d
        cp      (hl)
        jr      nz,L_C6D3
        ld      hl,$1D63
        ld      a,(iy-44)
        cp      (hl)
        jr      nz,L_C6D3
        ld      e,a
        inc     hl
        ld      a,(iy-43)
        cp      (hl)
        jr      nz,L_C6D3
        ld      d,a
        ex      de,hl
        bit     6,(iy-71)
        jr      nz,L_C6D3
        ld      a,(iy-40)
        add     a,(iy-32)
        ld      b,a
        pop     af
        ld      (iy-18),b
        ld      d,b
        push    hl
        pop     ix
        ld      a,(ix+5)
        cp      d
        jr      c,L_C6C7
        ld      a,b
.L_C6C7
        cp      (iy-42)
        jp      c,L_C78B
        ld      (iy-42),a
        jp      L_C78B
.L_C6D3
        call    L_CA99
        pop     af
        ld      a,$00
        jr      c,L_C6F6
        call    L_C78E
        ld      l,(iy-44)
        ld      h,(iy-43)
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      (iy-91),a
        inc     hl
        ld      a,(hl)
        ld      (iy-90),a
        ld      a,(iy-36)
        call    L_CB0E
.L_C6F6
        ld      l,(iy-44)
        ld      h,(iy-43)
        ld      e,a
        bit     7,(iy-85)
        jr      z,L_C70F
        call    L_C78E
        ld      a,(iy-40)
        ld      c,a
        sub     e
        ld      e,c
        call    L_C5EA
.L_C70F
        call    L_CA92
        ld      a,e
        add     a,(iy-32)
        ld      (iy-36),a
        ld      b,$00
        cp      (iy-42)
        jr      c,L_C736
        push    hl
        pop     ix
        cp      (ix+5)
        jr      c,L_C75E
        ld      d,a
        ld      a,e
        or      a
        jr      z,L_C78B
        ld      (iy-42),d
        ld      b,d
        ld      (ix+5),d
        jr      L_C78B
.L_C736
        ld      a,(iy-32)
        add     a,(iy-40)
        cp      (iy-81)
        jr      c,L_C744
        ld      a,(iy-81)
.L_C744
        ld      (iy-34),a
        cp      (iy-42)
        jr      c,L_C78B
        call    L_D0B1
        ld      a,(iy-42)
        call    L_EEE4
        ld      a,(iy-34)
        ld      b,a
        sub     (iy-42)
        jr      L_C788
.L_C75E
        ld      (iy-42),a
        ld      a,(ix+5)
        sub     (iy-36)
        ld      (iy-34),a
        ld      a,(iy-40)
        sub     e
        cp      (iy-34)
        jr      c,L_C77C
        ld      a,(iy-42)
        ld      (ix+5),a
        ld      a,(iy-34)
.L_C77C
        push    af
        add     a,(iy-36)
        ld      b,a
        pop     af
        or      a
        jr      z,L_C78B
        call    L_C78E
.L_C788
        call    L_C5EA
.L_C78B
        pop     hl
        or      a
        ret
.L_C78E
        bit     7,(iy-31)
        ret     nz
        push    af
        push    bc
        ld      a,(iy-32)
        ld      b,(iy-31)
        call    L_EEE4
        set     7,(iy-31)
        pop     bc
        pop     af
        ret
.L_C7A5
        res     2,(iy-99)
        call    L_D5A7
        ret     nc
        ld      b,$01
        call    L_EEE3
        ld      a,$06
        call    L_C5EA
        call    L_D59D
        ld      (iy-36),a
        ld      (iy-38),$00
        ld      hl,($1D5B)
.L_C7C4
        push    hl
        call    L_D0E8
        jr      c,L_C82C
        push    af
        call    L_D0E5
        ld      b,a
        pop     af
        cp      b
        jr      nz,L_C7DF
        push    af
        call    L_D551
        or      a
        jr      z,L_C7DE
        dec     a
        ld      (iy-38),a
.L_C7DE
        pop     af
.L_C7DF
        push    af
        call    L_BC39
        pop     af
        call    L_D54A
        ld      b,a
        sub     (iy-74)
        jr      c,L_C812
        jr      z,L_C812
        pop     hl
        push    hl
        push    af
        call    L_D0E8
        ld      c,$5F
        jr      nz,L_C804
        ld      c,a
        call    L_D0E5
        cp      c
        ld      c,$A0
        jr      z,L_C804
        ld      c,$2E
.L_C804
        pop     af
        ld      b,a
        ld      a,c
.L_C807
        call    L_C834
        jr      z,L_C82C
        djnz    L_C807
        xor     a
        ld      b,(iy-74)
.L_C812
        ld      e,a
        xor     a
        sub     e
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        ld      e,a
        ld      d,$00
.L_C81F
        ld      a,(hl)
        call    L_C834
        jr      z,L_C82C
        inc     hl
        djnz    L_C81F
        pop     hl
        inc     hl
        jr      L_C7C4
.L_C82C
        pop     hl
        ld      a,(iy-36)
        inc     a
        jp      L_C5EA
.L_C834
        push    af
        ld      c,(iy-38)
        inc     c
        dec     c
        jr      z,L_C84F
        dec     (iy-38)
        jr      nz,L_C84F
        cp      $A0
        jr      z,L_C849
        cp      $2E
        jr      nz,L_C853
.L_C849
        ld      a,$01
        oz      Os_out
        ld      a,$FA
.L_C84F
        oz      Os_out
        jr      L_C861
.L_C853
        push    af
        ld      e,$01
        call    L_CD74
        pop     af
        oz      Os_out
        ld      e,$01
        call    L_CD74
.L_C861
        pop     af
        dec     (iy-36)
        ret
.L_C866
        ld      a,$00
        ld      b,$00
        call    L_EEE4
        ld      de,L_BC17
        ld      ($1D4B),de
        ld      (iy-36),$07
        call    L_D0E2
        call    L_BBBF
        ld      a,(iy-36)
        jp      L_C5EA
.L_C884
        push    af
        ld      a,$00                           ; get current window information
        ld      bc,NQ_WBOX
        oz      Os_nq
        ld      b,a
        pop     af
        push    bc
        push    af
        oz      Os_Pout
        defm    $01, "6#3", $00

        call    L_D5A7
        ld      b,$21
        jr      nc,L_C8A1
        ld      b,$22
.L_C8A1
        ld      a,$20
        oz      Os_out
        ld      a,b
        oz      Os_out
        ld      a,(iy-81)
        add     a,$20
        oz      Os_out
        ld      a,(iy-80)
        sub     b
        add     a,$40
        oz      Os_out
        oz      Os_Pout
        defm    $01, "2H3", $00

        ld      a,$01
        oz      Os_out
        pop     af
        oz      Os_out
        oz      Os_Pout
        defm    $01, "2H", $00

        pop     af
        oz      Os_out
        oz      Os_Pout
        defm    $01, "2D3", $00

        ret
.L_C8D9
        call    L_D590
        ld      b,a
        ld      ix,($1D61)
        ld      de,$0006
        add     ix,de
        inc     b
.L_C8E7
        ld      a,(ix+5)
        ld      (ix-1),a
        add     ix,de
        djnz    L_C8E7
        ret
.L_C8F2
        ld      hl,($1D61)
        push    hl
        call    L_D590
        dec     a
        ld      b,a
        add     a,a
        ld      e,a
        add     a,a
        add     a,e
        ld      e,a
        ld      d,$00
        add     hl,de
        ld      de,$0006
.L_C906
        push    hl
        pop     ix
        ld      a,(ix-1)
        ld      (ix+5),a
        or      a
        sbc     hl,de
        djnz    L_C906
        pop     ix
        ret
.L_C917
        push    af
        call    L_D551
        ld      e,a
        pop     af
        push    af
        call    L_D54A
        ld      d,a
        cp      e
        jr      nc,L_C983
        bit     6,(iy-71)
        jr      z,L_C93F
        call    L_D0E2
        cp      (iy-38)
        jr      nz,L_C93F
        ld      a,c
        cp      (iy-26)
        jr      nz,L_C93F
        ld      a,b
        cp      (iy-25)
        jr      z,L_C983
.L_C93F
        pop     af
        push    af
        push    de
        call    L_D7B3
        pop     de
        jr      c,L_C94E
        bit     7,(ix+3)
        jr      z,L_C983
.L_C94E
        call    L_D0E2
        pop     hl
        inc     h
        push    hl
        bit     6,(iy-70)
        jr      nz,L_C969
        cp      h
        jr      nz,L_C969
        ld      a,c
        cp      (iy-26)
        jr      nz,L_C969
        ld      a,b
        cp      (iy-25)
        jr      z,L_C983
.L_C969
        ld      a,h
        push    de
        call    L_C989
        pop     de
        jr      c,L_C983
        pop     af
        push    af
        cp      (iy-98)
        jr      c,L_C97B
        ld      a,e
        jr      L_C97F
.L_C97B
        call    L_D54A
        add     a,d
.L_C97F
        ld      d,a
        cp      e
        jr      c,L_C94E
.L_C983
        pop     af
        ld      a,d
        cp      e
        ret     c
        ld      a,e
        ret
.L_C989
        ld      b,a
        ld      c,$00
        push    bc
        call    L_D7B3
        pop     bc
        jr      nc,L_C996
        set     6,c
        or      a
.L_C996
        push    bc
        bit     6,(iy-70)
        jr      nz,L_C9A5
        ld      a,b
        bit     7,(iy-67)
        call    z,L_CFE0
.L_C9A5
        pop     bc
        jr      c,L_C9AC
        inc     b
        dec     b
        jr      nz,L_C9AD
.L_C9AC
        inc     c
.L_C9AD
        push    bc
        pop     af
        ret     c
        ret     z
        call    L_C9B8
        ccf
        ret     c
        xor     a
        ret
.L_C9B8
        call    L_B500
        and     $C0
        cp      $C0
        ret     z
.L_C9C0
        ld      a,(hl)
        inc     hl
        cp      $20
        jr      z,L_C9C0
        or      a
        ret     nz
        scf
        ret
.L_C9CA
        call    L_D79A
        ret     c
        ld      c,(iy-109)
        ld      b,(iy-108)
        call    L_D56B
        ret     c
        ld      a,(iy-110)
        call    L_D55D
        ret     c
.L_C9DF
        call    L_B518
        set     0,(ix+3)
        set     3,(iy-72)
        ret
.L_C9EB
        inc     (iy-26)
        jr      nz,L_C9F3
        inc     (iy-25)
.L_C9F3
        ld      c,(iy-26)
        ld      b,(iy-25)
.L_C9F9
        push    bc
        ld      c,a
        ld      a,b
        cp      (iy-96)
        ld      a,c
        pop     bc
        ccf
        ret     nc
        ret     nz
        push    bc
        ld      b,a
        ld      a,c
        cp      (iy-97)
        ld      a,b
        pop     bc
        ccf
        ret
.L_CA0E
        inc     bc
.L_CA0F
        call    L_CA1E
        ret     nc
        ret     z
        ld      (iy-95),a
        ld      (iy-97),c
        ld      (iy-96),b
        ret
.L_CA1E
        inc     bc
        jr      L_C9F9
.L_CA21
        ld      a,(iy-26)
        or      (iy-25)
        scf
        ret     z
        ccf
.L_CA2A
        push    af
        ld      a,(iy-26)
        or      a
        jr      nz,L_CA34
        dec     (iy-25)
.L_CA34
        dec     (iy-26)
        pop     af
        ret
.L_CA39
        ld      c,(iy-99)
        bit     5,c
        jr      nz,L_CA4A
        ld      (iy-52),l
        ld      (iy-51),h
        set     5,c
        jr      L_CA6F
.L_CA4A
        bit     4,c
        jp      nz,L_C4F6
        ld      e,(iy-52)
        ld      d,(iy-51)
        ld      a,h
        cp      d
        jr      nz,L_CA60
        jr      nc,L_CA67
        ld      a,l
        cp      e
        ret     z
        jr      nc,L_CA67
.L_CA60
        ex      de,hl
        ld      (iy-52),e
        ld      (iy-51),d
.L_CA67
        ld      (iy-50),l
        ld      (iy-49),h
        set     4,c
.L_CA6F
        ld      (iy-99),c
        ret
.L_CA73
        set     5,(iy-72)
        set     3,(iy-99)
        ret
.L_CA7C
        set     0,(iy-99)
        set     6,(iy-99)
        ret
.L_CA85
        call    L_CA8D
        set     1,(iy-99)
        ret
.L_CA8D
        set     7,(iy-99)
        ret
.L_CA92
        bit     0,(iy-85)
        ret     z
        jr      L_CAF0
.L_CA99
        push    af
        push    bc
        push    de
        push    hl
        or      a
        ld      a,(iy-38)
        bit     7,(iy-67)
        call    z,L_CFE0
        ld      b,$81
        jr      c,L_CAAE
        ld      b,$00
.L_CAAE
        push    bc
        bit     6,(iy-71)
        jr      z,L_CACD
        call    L_D0E2
        cp      (iy-38)
        jr      nz,L_CACD
        ld      a,b
        cp      (iy-25)
        jr      nz,L_CACD
        ld      a,c
        cp      (iy-26)
        jr      nz,L_CACD
        pop     af
        xor     $81
        push    af
.L_CACD
        pop     bc
        ld      (iy-85),b
        bit     7,b
        call    nz,L_EFEF
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret
.L_CADB
        call    L_CE2A
        jr      c,L_CAE7
        call    L_CAF0
        add     a,$40
        jr      L_CAEE
.L_CAE7
        call    L_CAF0
        sub     $17
        or      $30
.L_CAEE
        oz      Os_out
.L_CAF0
        push    af
        ld      a,(iy-85)
        xor     $01
        ld      (iy-85),a
        rra
        call    nc,L_EFEF
        call    c,L_EFEF
        pop     af
        ret
.L_CB02
        ld      l,(iy-44)
        ld      h,(iy-43)
        call    L_D0B1
        jp      L_EEE3
.L_CB0E
        ld      (iy-36),a
        call    L_FAB1
        call    L_B518
        ld      a,(ix+3)
        bit     4,a
        jr      nz,L_CB76
        push    af
        bit     7,a
        jr      nz,L_CB48
        and     $C0
        jr      z,L_CB8E
        call    L_FA25
        jr      nc,L_CB8E
        ld      a,c
        cp      $00
        jr      z,L_CB70
        cp      $08
        jr      nz,L_CB3A
        call    L_D077
        jr      L_CB9A
.L_CB3A
        ld      ($1D4D),hl
        ld      c,$14
        call    L_B518
        ld      a,(ix+4)
        or      a
        jr      nz,L_CB64
.L_CB48
        pop     af
        push    af
        and     $C0
        cp      $C0
        jr      z,L_CB6B
        pop     af
        push    af
        and     $0E
        cp      $08
        jr      nz,L_CB62
        ld      c,(hl)
        ld      a,c
        cp      $40
        jr      z,L_CB62
        ld      b,$01
        jr      L_CB66
.L_CB62
        ld      c,$00
.L_CB64
        ld      b,$00
.L_CB66
        call    L_CE31
        jr      L_CBA6
.L_CB6B
        call    L_EE4E
        jr      L_CB9A
.L_CB70
        pop     af
        ld      a,($1D4D)
        jr      L_CB79
.L_CB76
        ld      a,(ix+4)
.L_CB79
        ld      c,(iy-36)
        ld      ix,L_F020
        bit     6,(iy-70)
        jp      z,L_EB4D
        ld      ix,L_ED93
        jp      L_EB4D
.L_CB8E
        call    L_FE72
        call    L_B518
        ld      a,(ix+9)
        call    L_FEF0
.L_CB9A
        call    L_FB76
        pop     af
        and     $0E
        cp      $08
        jr      nz,L_CBA5
        xor     a
.L_CBA5
        push    af
.L_CBA6
        ld      (iy-34),$00
        pop     af
        call    L_CBD9
        ld      a,(iy-34)
        ret
.L_CBB2
        ld      a,(iy-36)
        push    af
        xor     a
        ld      (iy-34),a
        call    L_CC72
        pop     af
        call    L_CFBB
        ret     c
        jr      z,L_CBCC
        push    af
        ld      a,c
        srl     a
        call    L_CBD2
        pop     af
.L_CBCC
        call    L_CFBB
        ret     c
        ret     z
        ld      a,c
.L_CBD2
        sub     (iy-34)
        ret     c
        jp      L_CC72
.L_CBD9
        ld      (iy-78),$00
        and     $0E
        jr      z,L_CC55
        cp      $08
        jr      z,L_CBB2
        jr      c,L_CC58
        ld      (iy-22),a
        call    L_CDEF
        ld      a,(iy-36)
        sub     c
        jr      c,L_CC55
        jr      z,L_CC55
        inc     b
        dec     b
        jr      z,L_CC55
        add     a,b
        ld      c,a
        ld      a,b
        neg
        ld      l,a
        ld      h,$FF
        add     hl,sp
        ld      sp,hl
        ld      (iy-78),b
        ld      (iy-30),l
        ld      (iy-29),h
        ld      a,$01
        bit     7,(iy-70)
        jr      z,L_CC1D
        bit     4,(iy-70)
        jr      z,L_CC1D
        ld      a,(iy+28)
.L_CC1D
        ld      l,c
        ld      h,$00
        call    L_F048
        ld      a,b
        call    L_F05E
        ld      d,a
        push    hl
        ld      c,$00
        ld      a,(iy-22)
        cp      $0C
        jr      z,L_CC35
        ld      a,b
        sub     d
        ld      c,a
.L_CC35
        ld      e,c
        ld      c,$00
        ld      l,(iy-30)
        ld      h,(iy-29)
.L_CC3E
        ld      a,c
        cp      e
        ccf
        jr      nc,L_CC49
        ld      a,d
        or      a
        jr      z,L_CC49
        dec     d
        scf
.L_CC49
        ex      (sp),hl
        ld      a,l
        adc     a,$00
        ex      (sp),hl
        ld      (hl),a
        inc     hl
        inc     c
        dec     b
        jr      nz,L_CC3E
        pop     bc
.L_CC55
        or      a
        jr      L_CC8D
.L_CC58
        push    af
        call    L_CDF2
        ld      a,(iy-36)
        scf
        sbc     a,c
        ld      c,$00
        jr      c,L_CC66
        ld      c,a
.L_CC66
        pop     af
        cp      $04
        jr      z,L_CC6F
        jr      nc,L_CC71
        ld      c,$00
.L_CC6F
        srl     c
.L_CC71
        ld      a,c
.L_CC72
        cp      (iy-36)
        jr      c,L_CC7A
        ld      a,(iy-36)
.L_CC7A
        ld      e,a
        call    L_C5EA
        ld      a,e
        add     a,(iy-34)
        ld      (iy-34),a
        ld      a,(iy-36)
        sub     e
        ld      (iy-36),a
        scf
.L_CC8D
        push    af
        call    L_CDCA
        ld      hl,($1D4D)
        ld      de,$0000
        set     7,b
        pop     af
        jr      nc,L_CCA8
        dec     hl
.L_CC9D
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_CD17
        cp      $20
        jr      z,L_CC9D
        dec     hl
.L_CCA7
        inc     hl
.L_CCA8
        ld      a,(hl)
        or      a
        jr      z,L_CD17
        ld      c,(iy-36)
        inc     c
        dec     c
        jr      z,L_CD11
        call    L_CE2A
        jr      c,L_CD05
        cp      $20
        jr      c,L_CCF6
        jr      z,L_CCDB
.L_CCBE
        cp      $7F
        jr      nz,L_CCC4
        ld      a,$20
.L_CCC4
        push    af
        bit     7,(iy-70)
        call    nz,L_CDCA
        pop     af
        call    L_CD9C
.L_CCD0
        or      a
.L_CCD1
        inc     (iy-34)
        dec     (iy-36)
        rr      b
        jr      L_CCA7
.L_CCDB
        ld      c,$01
        bit     7,b
        jr      nz,L_CCE5
        call    L_CDA6
        inc     e
.L_CCE5
        call    L_ED8A
        dec     c
        scf
        jr      z,L_CCD1
        inc     (iy-34)
        dec     (iy-36)
        jr      nz,L_CCE5
        jr      L_CCA7
.L_CCF6
        bit     6,(iy-70)
        jr      nz,L_CD01
        call    L_CADB
        jr      L_CCD0
.L_CD01
        ld      a,$20
        jr      L_CCBE
.L_CD05
        call    L_CE2A
        jr      nc,L_CCA7
        call    L_CD49
        jr      nc,L_CCD0
        jr      L_CCA7
.L_CD11
        bit     7,(iy-70)
        jr      nz,L_CD05
.L_CD17
        call    L_CDCA
        ld      a,(iy-78)
        or      a
        jr      z,L_CD34
        push    hl
        pop     ix
        ld      l,a
        ld      h,$00
        add     hl,sp
        ld      sp,hl
        ld      a,(iy-36)
        add     a,(iy-34)
        ld      (iy-34),a
        push   ix
        pop     hl
.L_CD34
        bit     6,(iy-70)
        ret     nz
        ld      e,$00
.L_CD3B
        rr      d
        push    de
        call    c,L_CD74
        pop     de
        inc     e
        ld      a,e
        cp      $04
        jr      nz,L_CD3B
        ret
.L_CD49
        sub     $18
        push    af
        ld      c,a
        inc     c
        ld      a,$01
.L_CD50
        dec     c
        jr      z,L_CD56
        add     a,a
        jr      L_CD50
.L_CD56
        xor     d
        ld      d,a
        pop     af
        push    hl
        push    de
        ld      e,a
        ld      hl,L_CD94
        ld      a,$05
        bit     6,(iy-70)
        jr      nz,L_CD7B
        ld      a,e
        cp      $04
        jr      c,L_CD76
        add     a,$18
        call    L_CADB
        or      a
        jr      L_CD8D
.L_CD74
        push    hl
        push    de
.L_CD76
        ld      hl,L_CD90
        ld      a,$01
.L_CD7B
        ld      d,$00
        add     hl,de
        call    L_CD9C
        cp      $01
        ld      a,$31
        call    nz,L_CD9C
        ld      a,(hl)
        call    L_CD9C
        scf
.L_CD8D
        pop     de
        pop     hl
        ret

.L_CD90
        defb    $55,$42,$47,$54
.L_CD94
        defb    $55,$42,$58,$49
        defb    $4C,$52,$41,$45

.L_CD9C
        bit     6,(iy-70)
        jp      nz,L_ED93
        oz      Os_out
        ret
.L_CDA6
        ld      a,(iy-78)
        or      a
        jr      z,L_CDEB
        ld      a,e
        cp      (iy-78)
        jr      nc,L_CDCA
        push    de
        push    hl
        ld      d,$00
        ld      l,(iy-30)
        ld      h,(iy-29)
        add     hl,de
        ld      c,(hl)
        pop     hl
        ld      e,c
        push    de
        call    L_CDCD
        pop     de
        ld      a,e
        pop     de
        ret     c
        ld      c,a
        ret
.L_CDCA
        ld      c,(iy+28)
.L_CDCD
        bit     7,(iy-70)
        jr      z,L_CDEB
        bit     4,(iy-70)
        jr      z,L_CDEB
        ld      a,c
        cp      (iy-89)
        jr      z,L_CDE7
        ld      (iy-89),a
        ld      c,$48
        call    L_EDF5
.L_CDE7
        ld      c,$01
        scf
        ret
.L_CDEB
        ld      c,$01
        or      a
        ret
.L_CDEF
        scf
        jr      L_CDF3
.L_CDF2
        or      a
.L_CDF3
        rr      e
        ld      bc,$0000
        ld      d,c
        ld      hl,($1D4D)
        dec     hl
.L_CDFD
        inc     hl
        ld      a,(hl)
        or      a
        ret     z
        bit     7,e
        jr      z,L_CE06
        inc     c
.L_CE06
        cp      $20
        jr      z,L_CDFD
        ld      e,c
.L_CE0B
        ld      a,(hl)
        or      a
        ret     z
        inc     hl
        inc     e
        cp      $20
        jr      nz,L_CE18
        set     7,d
        jr      L_CE0B
.L_CE18
        call    L_CE2A
        jr      nc,L_CE20
        dec     e
        jr      L_CE0B
.L_CE20
        ld      c,e
        bit     7,d
        jr      z,L_CE0B
        inc     b
        res     7,d
        jr      L_CE0B
.L_CE2A
        cp      $18
        ccf
        ret     nc
        cp      $20
        ret
.L_CE31
        ld      a,b
        cp      $01
        ld      e,c
        ld      ix,$1EAA
        ld      hl,($1D4D)
        ld      (iy-34),$FF
        jr      c,L_CE47
        ld      a,e
        or      a
        jr      z,L_CE47
        inc     hl
.L_CE47
        rr      d
        push    de
        call    L_CEEC
        pop     de
        jr      c,L_CE5A
        inc     b
        dec     b
        jr      z,L_CE5A
        rl      d
        jr      nc,L_CE47
        rr      d
.L_CE5A
        ld      hl,$1EAA
        ld      ($1D4D),hl
        rl      d
        ret     c
        xor     a
        call    L_CF9A
        call    nc,L_CF9A
        ret
.L_CE6B
        ld      (iy+35),$00
        jr      L_CEAA
.L_CE71
        inc     hl
        inc     hl
        ld      b,(iy-111)
        push    bc
        push    hl
        dec     hl
        push   ix
        push    de
        call    L_FA04
        jr      c,L_CE96
        ld      a,$00
        jp      pe,L_CE8C
        call    L_B518
        ld      a,(ix+9)
.L_CE8C
        push    af
        call    L_FE72
        pop     af
        call    L_FEF0
        jr      L_CEAA
.L_CE96
        ld      a,c
        cp      $00
        jr      z,L_CE6B
        cp      $06
        jr      nz,L_CEA3
        pop     de
        ld      e,$14
        push    de
.L_CEA3
        cp      $08
        jr      nz,L_CEB3
        call    L_D077
.L_CEAA
        push    de
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        pop     de
.L_CEB3
        pop     de
        pop     ix
        jr      L_CEC8
.L_CEB8
        ld      b,(iy-111)
        push    bc
        push    hl
        push    de
        push   ix
        ld      a,$16
        call    L_E54F
        pop     ix
        pop     de
.L_CEC8
        dec     hl
.L_CEC9
        inc     hl
        ld      a,(hl)
        cp      $40
        jr      nz,L_CEE4
.L_CECF
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_CEE4
        call    L_FE32
        jr      nc,L_CEDE
        inc     hl
        inc     hl
        inc     hl
        jr      L_CECF
.L_CEDE
        cp      $40
        jr      nz,L_CECF
        jr      L_CEC9
.L_CEE4
        call    L_CF9A
        jr      nz,L_CEC9
        jp      L_CF96
.L_CEEC
        ld      a,(hl)
        cp      $40
        jr      nz,L_CF15
        call    L_840A
        jr      nc,L_CF13
        jp      nz,L_CE71
        cp      $54
        jr      z,L_CEB8
        cp      $44
        jp      z,L_CF63
        cp      $40
        jr      nz,L_CF1D
.L_CF06
        inc     hl
        ld      a,(hl)
        cp      $40
        jr      nz,L_CF15
        call    L_CF9A
        jr      nz,L_CF06
        jr      L_CF1B
.L_CF13
        dec     hl
        ld      a,(hl)
.L_CF15
        inc     hl
.L_CF16
        call    L_CF9A
        jr      nz,L_CEEC
.L_CF1B
        ld      b,d
        ret
.L_CF1D
        ld      b,(iy-111)
        push    bc
        push    hl
        push   ix
        push    de
        call    L_D27D
        ld      l,(iy-91)
        ld      h,(iy-90)
        jr      c,L_CF33
        ld      hl,$0000
.L_CF33
        call    L_EE87
        ld      de,$0022
        push    iy
        pop     hl
        add     hl,de
        pop     de
        pop     ix
.L_CF40
        inc     hl
        ld      a,(hl)
        call    L_CF9A
        jr      z,L_CF4C
        dec     (iy-74)
        jr      nz,L_CF40
.L_CF4C
        pop     hl
        pop     bc
        push    af
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        pop     af
        jr      c,L_CF16
        inc     hl
.L_CF5A
        inc     hl
        ld      a,(hl)
        cp      $40
        jr      z,L_CF5A
        jp      L_CEEC
.L_CF63
        ld      b,(iy-111)
        push    bc
        push    hl
        push    de
        ld      de,$0002
        oz      Gn_gmd
        ld      hl,$FFCA
        add     hl,sp
        ld      sp,hl
        push    hl
        ld      (hl),c
        inc     hl
        ld      (hl),b
        inc     hl
        ld      (hl),a
        inc     hl
        ld      e,l
        ld      d,h
        ex      (sp),hl
        ld      a,$80
        ld      b,$0F
        oz      Gn_pdt
        xor     a
        ld      (de),a
        pop     hl
        dec     hl
.L_CF89
        inc     hl
        ld      a,(hl)
        call    L_CF9A
        jr      nz,L_CF89
        ld      hl,$0036
        add     hl,sp
        ld      sp,hl
        pop     de
.L_CF96
        dec     ix
        jr      L_CF4C
.L_CF9A
        ld      d,a
        ld      a,(iy-34)
        or      a
        scf
        ret     z
        ccf
        dec     (iy-34)
        jr      nz,L_CFAA
        ld      d,$00
        scf
.L_CFAA
        rr      c
        ld      a,d
        cp      e
        jr      nz,L_CFB1
        xor     a
.L_CFB1
        ld      (ix+0),a
        inc     ix
        rl      c
        inc     a
        dec     a
        ret
.L_CFBB
        ld      c,a
.L_CFBC
        ld      a,(hl)
        inc     hl
        or      a
        jr      nz,L_CFBC
        ld      ($1D4D),hl
        ld      a,(iy-36)
        or      a
        scf
        ret     z
        push    bc
        push    hl
        call    L_CDF2
        pop     hl
        ld      e,c
        pop     bc
        ld      a,e
        or      a
        ld      a,c
        ret     z
        push    af
        scf
        sbc     a,e
        ld      c,a
        jr      nc,L_CFDE
        ld      c,$00
.L_CFDE
        pop     af
        ret
.L_CFE0
        ld      e,a
        call    L_D014
        ccf
        ret     nc
        ld      a,(iy-58)
        cp      e
        jr      z,L_CFF3
        ret     nc
        ld      a,(iy-55)
        cp      e
        ccf
        ret     nc
.L_CFF3
        ld      c,(iy-26)
        ld      b,(iy-25)
        ld      a,b
        cp      (iy-56)
        ccf
        ret     nc
        jr      nz,L_D007
        ld      a,c
        cp      (iy-57)
        ccf
        ret     nc
.L_D007
        ld      a,b
        cp      (iy-53)
        ret     c
        ret     nz
        ld      a,c
        cp      (iy-54)
        ret     nz
        scf
        ret
.L_D014
        ld      c,(iy-67)
        bit     7,c
        scf
        ret     nz
        push    iy
        pop     ix
        ld      b,$06
.L_D021
        ld      a,(ix-67)
        ld      (ix-58),a
        inc     ix
        djnz    L_D021
        ld      a,(iy-64)
        cp      (iy-67)
        jr      nc,L_D039
        ld      (iy-55),c
        ld      (iy-58),a
.L_D039
        bit     7,(iy-64)
        jr      z,L_D051
        push    iy
        pop     ix
        ld      b,$03
.L_D045
        ld      a,(ix-67)
        ld      (ix-55),a
        inc     ix
        djnz    L_D045
        or      a
        ret
.L_D051
        ld      c,(iy-63)
        ld      b,(iy-62)
        ld      a,b
        cp      (iy-65)
        jr      c,L_D063
        ret     nz
        ld      a,c
        cp      (iy-66)
        ret     nc
.L_D063
        ld      (iy-57),c
        ld      (iy-56),b
        ld      a,(iy-66)
        ld      (iy-54),a
        ld      a,(iy-65)
        ld      (iy-53),a
        or      a
        ret
.L_D077
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        ex      de,hl
        ld      hl,($1D4D)
        ld      a,$A0
        ld      bc,$002E
        oz      Gn_pdt
        xor     a
        ld      (de),a
        ret
.L_D08D
        push    hl
        ld      hl,($1D5B)
        ld      e,c
        ld      d,b
        ld      c,$00
.L_D095
        or      a
        sbc     hl,de
        add     hl,de
        jr      z,L_D0A3
        call    L_D547
        add     a,c
        ld      c,a
        inc     hl
        jr      L_D095
.L_D0A3
        pop     hl
        push    bc
        call    L_D0B1
        call    L_D5A7
        pop     de
        ld      a,e
        ret     nc
        add     a,$06
        ret
.L_D0B1
        ld      de,($1D61)
        ld      a,$FF
        ld      bc,$0006
.L_D0BA
        inc     a
        or      a
        sbc     hl,bc
        or      a
        sbc     hl,de
        add     hl,de
        jp      p,L_D0BA
        ld      c,a
        push    bc
        call    L_D5A7
        pop     bc
        ld      a,$01
        adc     a,c
        ld      b,a
        ret
.L_D0D0
        ld      hl,($1D5B)
        dec     hl
.L_D0D4
        inc     hl
        call    L_D0E8
        jr      c,L_D0DD
        jr      nz,L_D0D4
        ret
.L_D0DD
        ld      hl,($1D5B)
        jr      L_D0E8
.L_D0E2
        call    L_D8B5
.L_D0E5
        ld      hl,($1D5D)
.L_D0E8
        ld      a,(hl)
        rla
        rla
        ld      a,(hl)
        bit     7,a
        res     7,a
        ret
.L_D0F1
        ld      hl,($1D61)
        ld      b,$00
.L_D0F6
        ld      a,(hl)
        rla
        jr      nc,L_D0FB
        inc     b
.L_D0FB
        ld      de,$0006
        add     hl,de
        rla
        jr      nc,L_D0F6
        ld      a,b
        ret
.L_D104
        call    L_D10E
        ld      (iy-26),c
        ld      (iy-25),b
        ret
.L_D10E
        ld      hl,($1D61)
        ld      c,l
        ld      b,h
.L_D113
        ld      a,(hl)
        rla
        rla
        jr      c,L_D123
        and     $81
        jp      z,L_D8B8
        ld      de,$0006
        add     hl,de
        jr      L_D113
.L_D123
        ld      l,c
        ld      h,b
        jp      L_D8B8
.L_D128
        ld      (iy-38),a
        ld      (iy-36),a
        push    af
        call    L_D0E5
        ld      (iy-34),a
        pop     af
        call    L_D5B0
        jr      c,L_D175
        ld      hl,($1D5B)
        ld      c,$00
        ld      b,(iy-98)
.L_D143
        call    L_D0E8
        jr      z,L_D14D
        call    L_D54A
        add     a,c
        ld      c,a
.L_D14D
        inc     hl
        djnz    L_D143
        call    L_D59D
        sub     c
        jr      c,L_D175
        srl     a
        jr      z,L_D175
        ld      c,a
.L_D15B
        dec     (iy-36)
        jp      m,L_D172
        ld      a,(iy-36)
        call    L_D5B0
        jr      c,L_D15B
        call    L_D54A
        ld      e,a
        ld      a,c
        sub     e
        ld      c,a
        jr      nc,L_D15B
.L_D172
        inc     (iy-36)
.L_D175
        ld      a,(iy-38)
        cp      (iy-34)
        jr      z,L_D198
        ld      a,(iy-36)
        rr      e
        cp      (iy-38)
        jr      nz,L_D198
        bit     7,e
        jr      nz,L_D194
        inc     a
        cp      (iy-98)
        jr      c,L_D198
        dec     a
        jr      L_D198
.L_D194
        or      a
        jr      z,L_D198
        dec     a
.L_D198
        ld      (iy-36),a
        call    L_D59D
        ld      (iy-34),a
        ld      hl,($1D5B)
        dec     hl
        ld      b,$FF
.L_D1A7
        inc     hl
        inc     b
        ld      ($1D5F),hl
        ld      a,b
        cp      $40
        jr      nc,L_D1E6
        ld      a,(hl)
        and     $BF
        jp      m,L_D1C7
.L_D1B7
        ld      a,(iy-36)
        cp      (iy-98)
        jr      nc,L_D1E6
        inc     (iy-36)
        call    L_D5B0
        jr      c,L_D1B7
.L_D1C7
        ld      (hl),a
        and     $7F
        cp      (iy-38)
        jr      nz,L_D1D2
        ld      ($1D5D),hl
.L_D1D2
        call    L_D54A
        ld      e,a
        or      a
        jr      z,L_D1B7
        ld      a,(iy-34)
        or      a
        jr      z,L_D1E6
        sub     e
        ld      (iy-34),a
        jr      nc,L_D1A7
        inc     hl
.L_D1E6
        set     6,(hl)
        ret
.L_D1E9
        ld      (iy-96),$00
        ld      (iy-97),$01
        ret
.L_D1F2
        ld      hl,($1D5B)
        dec     hl
        ld      c,$FF
        ld      b,c
.L_D1F9
        inc     hl
        call    L_D0E8
        jr      c,L_D210
        jr      nz,L_D20C
        bit     7,c
        jr      z,L_D206
        ld      c,a
.L_D206
        ld      b,a
        push    hl
        pop     ix
        jr      L_D1F9
.L_D20C
        push    hl
        pop     de
        jr      L_D1F9
.L_D210
        bit     7,b
        jr      nz,L_D245
        push   ix
        pop     hl
        ld      a,b
        cp      c
        jr      z,L_D22B
        ld      ix,$1D5F
        ld      a,h
        cp      (ix+1)
        jr      nz,L_D22B
        ld      a,l
        cp      (ix+0)
        jr      z,L_D232
.L_D22B
        inc     b
        ld      a,b
        cp      (iy-98)
        jr      z,L_D247
.L_D232
        ld      a,b
        call    L_D54A
        or      a
        jr      z,L_D23E
        ld      a,b
        call    L_D5B0
        ret     nc
.L_D23E
        inc     b
        ld      a,b
        cp      (iy-98)
        jr      c,L_D232
.L_D245
        push    de
        pop     hl
.L_D247
        scf
        ret
.L_D249
        call    L_D8B5
.L_D24C
        ld      (iy-26),c
        ld      (iy-25),b
.L_D252
        xor     a
        call    L_D7B3
        ccf
        ret     nc
        ld      a,(ix+3)
        and     $C0
        cp      $C0
        scf
        ret     z
        ccf
        ret
.L_D263
        ld      (ix+4),a
.L_D266
        ld      e,a
        ld      a,(ix+5)
        ld      d,a
        or      a
        scf
        ret     z
        ld      a,(iy+7)
        sub     e
        ret     c
        ld      e,a
        ld      a,d
        cp      e
        ccf
        ret
.L_D278
        ld      a,(iy+7)
        or      a
        ret     z
.L_D27D
        push    hl
        ld      hl,($1D61)
        bit     7,(hl)
        pop     hl
        scf
        ret     z
        bit     6,(iy-70)
        ret     nz
        ccf
        ret
.L_D28D
        or      a
        jr      z,L_D2AB
        add     a,(iy+8)
.L_D293
        ld      e,a
        ld      a,(iy+7)
        or      a
        jr      z,L_D2AB
        inc     a
        bit     7,e
        jr      nz,L_D2A0
        ld      a,e
.L_D2A0
        cp      (iy+7)
        ret     c
        ret     z
        call    L_D278
        ld      a,$00
        ret     c
.L_D2AB
        ld      a,$01
        ret
.L_D2AE
        ld      a,(iy-91)
        or      a
        jr      nz,L_D2B7
        dec     (iy-90)
.L_D2B7
        dec     (iy-91)
        ret
.L_D2BB
        inc     (iy-91)
        ret     nz
        inc     (iy-90)
        ret
.L_D2C3
        rr      (iy-34)
        ld      a,(iy-93)
        ld      (iy-91),a
        ld      a,(iy-92)
        ld      (iy-90),a
        call    L_D252
        jr      nc,L_D326
        call    L_B518
        bit     7,(iy-34)
        jr      nz,L_D2F9
        ld      a,(iy-94)
        or      a
        jr      nz,L_D2ED
        ld      a,(iy+7)
        add     a,(iy+8)
.L_D2ED
        call    L_D263
        jr      nc,L_D308
        call    L_D2BB
        ld      a,$01
        jr      L_D304
.L_D2F9
        ld      a,(ix+4)
        push    af
        call    L_D266
        call    c,L_D2AE
        pop     af
.L_D304
        or      a
.L_D305
        ld      (iy-94),a
.L_D308
        ld      a,(iy-91)
        ld      (iy-93),a
        ld      a,(iy-90)
        ld      (iy-92),a
        ret
.L_D315
        ld      a,(iy-94)
        or      a
        ret     nz
        ld      a,(iy-93)
        ld      (iy-91),a
        ld      a,(iy-92)
        ld      (iy-90),a
.L_D326
        ld      c,(iy-94)
        ld      a,c
        or      a
        jr      nz,L_D342
        bit     7,(iy-34)
        jr      z,L_D33B
        call    L_D2AE
        ld      a,(iy+7)
        jr      L_D34E
.L_D33B
        call    L_D2BB
        ld      a,$01
        jr      L_D34E
.L_D342
        ld      a,(iy+8)
        bit     7,(iy-34)
        jr      z,L_D34D
        neg
.L_D34D
        add     a,c
.L_D34E
        call    L_D293
        or      a
        jr      nz,L_D304
        scf
        jr      L_D305
.L_D357
        call    L_D3E9
        call    L_D104
.L_D35D
        or      a
.L_D35E
        rr      e
        ld      a,(iy-26)
        or      (iy-25)
        jp      z,L_D3F0
        call    L_D3C1
        res     7,(iy-36)
        rl      e
        jr      c,L_D380
        ld      a,(iy-94)
        or      a
        jr      nz,L_D380
        call    L_D252
        call    nc,L_D2C3
.L_D380
        ld      c,(iy-26)
        ld      b,(iy-25)
        ld      a,b
        cp      (iy-19)
        jr      c,L_D399
        jr      nz,L_D396
        ld      a,c
        cp      (iy-20)
        jr      z,L_D3C1
        jr      c,L_D399
.L_D396
        call    L_CA2A
.L_D399
        ccf
        push    af
        call    L_D2C3
        jr      nc,L_D3B7
        pop     af
        push    af
        call    L_D3DE
        call    L_D2C3
        call    L_D252
        jr      c,L_D3B6
        pop     af
        push    af
        ccf
        call    L_D3DE
        scf
        jr      L_D3B7
.L_D3B6
        or      a
.L_D3B7
        rr      (iy-36)
        pop     af
        call    nc,L_D3E1
        jr      L_D380
.L_D3C1
        ld      c,(iy-20)
        ld      b,(iy-19)
        ld      a,(iy-26)
        ld      (iy-20),a
        ld      a,(iy-25)
        ld      (iy-19),a
        ld      (iy-26),c
        ld      (iy-25),b
        rl      (iy-36)
        ret
.L_D3DE
        jp      c,L_CA2A
.L_D3E1
        inc     (iy-26)
        ret     nz
        inc     (iy-25)
        ret
.L_D3E9
        xor     a
        ld      (iy-20),a
        ld      (iy-19),a
.L_D3F0
        ld      a,(iy+12)
        ld      (iy-94),a
        ld      a,(iy+10)
        ld      (iy-93),a
        ld      a,(iy+11)
        ld      (iy-92),a
        ret
.L_D403
        call    L_C9F9
        jr      nc,L_D40F
        ld      c,(iy-97)
        ld      b,(iy-96)
        dec     bc
.L_D40F
        ld      (iy-24),c
        ld      (iy-23),b
        ld      (iy-26),c
        ld      (iy-25),b
        ld      hl,($1D61)
        call    L_D590
        ld      b,a
        ld      c,$00
        ld      de,$0006
.L_D427
        bit     7,(hl)
        jr      z,L_D42C
        inc     c
.L_D42C
        add     hl,de
        djnz    L_D427
        call    L_D590
        scf
        sbc     a,c
        jr      c,L_D452
        srl     a
        jr      z,L_D452
        ld      (iy-36),a
.L_D43D
        ld      a,(iy-26)
        or      (iy-25)
        jr      z,L_D452
        call    L_D5D7
        call    L_CA2A
        jr      c,L_D43D
        dec     (iy-36)
        jr      nz,L_D43D
.L_D452
        call    L_D10E
        ld      (iy-20),c
        ld      (iy-19),b
.L_D45B
        ld      hl,($1D61)
        ld      a,(hl)
        bit     7,a
        jr      nz,L_D469
        rla
        rla
        rla
        call    L_D35E
.L_D469
        ld      a,(iy-94)
        ld      (iy-36),a
        ld      a,(iy-93)
        ld      (iy-91),a
        ld      a,(iy-92)
        ld      (iy-90),a
        call    L_D590
        ld      (iy-38),a
        ld      hl,($1D61)
.L_D484
        push    hl
        ld      a,(hl)
        and     $9F
        jp      p,L_D49A
        ld      c,a
        push    bc
        call    L_D8B8
        call    L_C9F9
        pop     bc
        ld      a,c
        jp      nc,L_D51E
        res     7,a
.L_D49A
        ld      e,a
.L_D49B
        ld      a,(iy-25)
        cp      (iy-96)
        jr      c,L_D4AF
        jp      nz,L_D543
        ld      a,(iy-26)
        cp      (iy-97)
        jp      nc,L_D543
.L_D4AF
        push    de
        call    L_D5D7
        pop     de
        jr      nc,L_D4BB
        call    L_D3E1
        jr      L_D49B
.L_D4BB
        push    de
        ld      hl,($1D61)
        bit     7,(hl)
        jr      nz,L_D4F2
        call    L_D252
        jr      c,L_D4D9
        ld      a,(iy-36)
        or      a
        jr      nz,L_D4F2
.L_D4CE
        call    L_D278
        jr      nc,L_D4EF
        pop     de
        ld      e,$20
        push    de
        jr      L_D4EF
.L_D4D9
        ld      a,(iy-36)
        call    L_D263
        ld      a,$00
        jr      c,L_D4EA
        ld      a,(iy-36)
        or      a
        jr      z,L_D4CE
        dec     a
.L_D4EA
        ld      (iy-36),a
        jr      nc,L_D4F2
.L_D4EF
        scf
        jr      L_D4F3
.L_D4F2
        or      a
.L_D4F3
        pop     de
        pop     hl
        push    hl
        push    de
        ld      a,(iy-26)
        inc     hl
        ld      (hl),a
        ld      a,(iy-25)
        inc     hl
        ld      (hl),a
        ld      a,(iy-91)
        inc     hl
        ld      (hl),a
        ld      a,(iy-90)
        inc     hl
        ld      (hl),a
        call    c,L_D2BB
        ld      a,(iy-36)
        call    L_D28D
        ld      (iy-36),a
        pop     de
        ld      a,e
        bit     5,a
        call    z,L_D3E1
.L_D51E
        pop     hl
        ld      (hl),a
        ld      e,a
        call    L_D8B8
        ld      a,b
        cp      (iy-23)
        jr      nz,L_D537
        ld      a,c
        cp      (iy-24)
        jr      nz,L_D537
        bit     5,e
        jr      nz,L_D537
        ld      ($1D63),hl
.L_D537
        ld      de,$0006
        add     hl,de
        dec     (iy-38)
        jr      z,L_D544
        jp      L_D484
.L_D543
        pop     hl
.L_D544
        ld      (hl),$40
        ret
.L_D547
        call    L_D0E8
.L_D54A
        push    hl
        call    L_D890
.L_D54E
        ld      a,(hl)
.L_D54F
        pop     hl
        ret
.L_D551
        push    hl
        call    L_D890
        inc     hl
        ld      a,(hl)
        or      a
        jr      nz,L_D54F
        dec     hl
        jr      L_D54E
.L_D55D
        ld      hl,($1D5B)
        dec     hl
        ld      e,a
.L_D562
        inc     hl
        call    L_D0E8
        ret     c
        cp      e
        jr      nz,L_D562
        ret
.L_D56B
        ld      hl,($1D61)
        ld      de,$0006
        or      a
        sbc     hl,de
.L_D574
        ld      de,$0006
.L_D577
        add     hl,de
        bit     6,(hl)
        scf
        ret     nz
        bit     5,(hl)
        jr      nz,L_D577
        ld      e,c
        ld      d,b
        call    L_D8B8
        ld      a,b
        cp      d
        jr      nz,L_D58C
        ld      a,c
        cp      e
        ret     z
.L_D58C
        ld      c,e
        ld      b,d
        jr      L_D574
.L_D590
        ld      a,(iy-80)
        sub     $01
        ld      e,a
        call    L_D5A7
        ld      a,e
        ret     nc
        dec     a
        ret
.L_D59D
        call    L_D5A7
        ld      a,(iy-81)
        ret     nc
        sub     $06
        ret
.L_D5A7
        ld      a,(iy-69)
        and     $02
        cp      $02
        ccf
        ret
.L_D5B0
        push    hl
        push    de
        push    bc
        ld      c,a
        ld      hl,($1D5B)
        ld      d,$00
.L_D5B9
        call    L_D0E8
        jr      z,L_D5CB
        ld      e,a
        ld      a,c
        cp      e
        scf
        jr      z,L_D5CC
        inc     hl
        inc     d
        ld      a,d
        cp      $40
        jr      nz,L_D5B9
.L_D5CB
        or      a
.L_D5CC
        ld      a,c
        pop     bc
        pop     de
        pop     hl
        ret
.L_D5D1
        ld      (iy-26),c
        ld      (iy-25),b
.L_D5D7
        ld      hl,($1D61)
.L_D5DA
        ld      a,(hl)
        rla
        ret     nc
        rla
        ccf
        ret     nc
        call    L_D8B8
        ld      a,b
        cp      (iy-25)
        jr      nz,L_D5EF
        ld      a,c
        cp      (iy-26)
        scf
        ret     z
.L_D5EF
        ld      de,$0006
        add     hl,de
        jr      L_D5DA

.L_D5F5
        defb    $41,$00,$5B,$1D
        defb    $41,$00,$61,$1D
        defb    $32,$00,$75,$1D
        defb    $00,$01,$3D,$1D
        defb    $0F,$00,$65,$1D
        defb    $0F,$00,$67,$1D
        defb    $3C,$00,$69,$1D
        defb    $3C,$00,$6B,$1D
        defb    $32,$00,$6D,$1D
        defb    $32,$00,$6F,$1D
        defb    $64,$00,$71,$1D
        defb    $64,$00,$73,$1D

.L_D625
        ld      ix,($1D39)
        oz      Os_mcl
.L_D62B
        ld      a, RC_Room
        oz      Os_bye
.void1  jr      void1

.L_D631
        ld      a, MM_S0
        ld      bc,0
        oz      Os_mop
        jr      c,L_D62B
        ld      ($1D39),ix
        ld      iy,L_D5F5
        ld      b,$0C
.L_D644
        push    bc
        ld      c,(iy+0)
        ld      b,(iy+1)
        call    L_D96E
        pop     bc
        jr      c,L_D625
        ld      e,(iy+2)
        ld      d,(iy+3)
        ex      de,hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        ld      de,$0004
        add     iy,de
        djnz    L_D644

        ld      bc,$00E5
        call    L_D96E
        jr      c,L_D625
        ld      de,$007F
        add     hl,de
        push    hl
        pop     iy
        ld      c, MS_S0
        oz      Os_mpb
        xor     a
        ld      (iy-70),a
        ld      ($1D44),a
        ld      ($1D42),a
        ld      (iy-111),a
        ld      (iy-84),a
        ld      a, MM_S1 | MM_MUL
        ld      bc,0
        oz      Os_mop
        jp      c,L_D625
        ld      ($1D3B),ix
        ld      c,$01
        ld      de,$1D7F
        ld      hl,$0000
        ld      a,$01
        oz      Os_fc
        xor     a
        ld      hl,($1D5B)
        ld      b,$41
.L_D6A5
        ld      (hl),a
        inc     hl
        djnz    L_D6A5
        ld      hl,($1D61)
        ld      b,$31
.L_D6AE
        ld      (hl),a
        inc     hl
        djnz    L_D6AE
        ld      a,$01
        ld      bc,PA_Iov
        ld      de,$0002
        oz      Os_nq
        ld      c,$00
        ld      a,e
        cp      $49
        jr      z,L_D6C5
        ld      c,$04
.L_D6C5
        ld      (iy-71),c
        call    L_E0EA
.L_D6CB
        xor     a
        ld      (iy+29),a
        ld      (iy+11),a
        inc     a
        ld      (iy+10),a
        ld      (iy+12),a
.L_D6D9
        ld      a,(iy-71)
        and     $04
        ld      (iy-71),a
        xor     a
        ld      (iy-101),a
        ld      (iy-100),a
        ld      (iy-99),a
        ld      (iy-98),a
        ld      (iy-72),a
        ld      (iy-87),a
        ld      (iy-95),a
        ld      (iy+99),a
        ld      hl,($1D71)
        ld      (hl),a
        ld      hl,($1D6D)
        ld      (hl),a
        ld      hl,($1D6F)
        ld      (hl),a
        ld      hl,($1D5B)
        ld      ($1D5D),hl
        ld      ($1D5F),hl
        ld      hl,($1D61)
        ld      ($1D63),hl
        ld      (iy-67),$80
        ld      (iy-64),$80
        call    L_D1E9
        ld      de,$0280
        ld      hl,($1D3F)
.L_D726
        ld      (hl),$00
        inc     hl
        dec     de
        ld      a,d
        or      e
        jr      nz,L_D726
        xor     a
        ld      hl,($1D5B)
        ld      b,$41
.L_D734
        ld      (hl),a
        inc     hl
        djnz    L_D734
        ld      hl,($1D61)
        ld      b,$08
.L_D73D
        ld      (hl),a
        ld      de,$0006
        add     hl,de
        djnz    L_D73D
        call    L_E7CA
        jr      L_D758
.L_D749
        ld      a,$06
.L_D74B
        push    af
        call    L_D8CD
        pop     af
        dec     a
        jr      nz,L_D74B
        ld      c,$48
        call    L_D76C
.L_D758
        ld      a,$40
        ld      hl,($1D61)
        ld      (hl),a
        ld      hl,($1D5B)
        ld      (hl),a
        ld      bc,$0000
        call    L_D403
        xor     a
        jp      L_D128
.L_D76C
        ld      b,a
.L_D76D
        ld      a,b
        cp      $40
        ret     nc
        inc     b
        call    L_D890
        inc     hl
        ld      (hl),c
        dec     hl
        ld      a,c
        sub     (hl)
        ld      c,a
        jr      nc,L_D76D
        ret
.L_D77E
        ld      (iy-110),a
        ld      (iy-109),c
        ld      (iy-108),b
        ret
.L_D788
        call    L_D890
        inc     hl
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        bit     7,b
        ret     z
        ld      bc,$0000
        ret
.L_D797
        call    L_D77E
.L_D79A
        ld      a,(iy-110)
        ld      c,(iy-109)
        ld      b,(iy-108)
        jr      L_D7AD
.L_D7A5
        ld      bc,$7FFF
        jr      L_D7AD
.L_D7AA
        call    L_D0E2
.L_D7AD
        ld      (iy-26),c
        ld      (iy-25),b
.L_D7B3
        cp      (iy-98)
        ccf
        ret     c
        ld      l,a
        ld      h,$00
        add     hl,hl
        ld      c,l
        ld      b,h
        add     hl,hl
        add     hl,hl
        add     hl,bc
        ld      bc,($1D3F)
        add     hl,bc
        inc     hl
        inc     hl
        ld      a,(iy-26)
        sub     (hl)
        ld      e,a
        ld      b,a
        inc     hl
        bit     7,(hl)
        jr      nz,L_D84C
        ld      a,(iy-25)
        sbc     a,(hl)
        ld      d,a
        push    de
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,(hl)
        jr      nz,L_D7E5
        inc     b
        dec     b
        jr      z,L_D82F
.L_D7E5
        inc     hl
        push    de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      b,(hl)
        push    hl
        pop     ix
        pop     hl
        jr      nc,L_D855
.L_D7F2
        ld      a,c
        push    af
        cp      (iy-111)
        call    nz,L_D887
        push    de
        ld      a,(hl)
        xor     e
        ld      e,a
        inc     hl
        ld      a,(hl)
        xor     d
        ld      d,a
        or      e
        jr      z,L_D84E
        pop     af
        inc     hl
        ld      a,(hl)
        xor     b
        ld      c,a
        dec     hl
        dec     hl
        ex      de,hl
        pop     af
        ld      b,a
        ld      a,(ix-7)
        or      a
        jr      z,L_D846
.L_D815
        dec     (ix-7)
        ex      (sp),hl
        inc     hl
        ld      a,l
        or      h
        ex      (sp),hl
        jr      nz,L_D7F2
.L_D81F
        push    hl
        push   ix
        pop     hl
        ld      (hl),b
        dec     hl
        ld      (hl),d
        dec     hl
        ld      (hl),e
        dec     hl
        pop     de
        ld      (hl),c
        dec     hl
        ld      (hl),d
        dec     hl
        ld      (hl),e
.L_D82F
        pop     hl
        push    af
        ld      (iy-127),e
        ld      (iy-126),d
        ld      (iy-125),c
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        pop     af
        push    de
        pop     ix
        ret
.L_D846
        dec     (ix-6)
        jp      L_D815
.L_D84C
        scf
        ret
.L_D84E
        pop     de
        pop     af
        dec     hl
.L_D851
        scf
        jp      L_D81F
.L_D855
        ex      (sp),hl
.L_D856
        ld      a,l
        or      h
        ex      (sp),hl
        jr      z,L_D81F
        ld      a,e
        or      d
        jr      z,L_D851
        ld      a,b
        push    af
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(de)
        xor     l
        ld      l,a
        inc     de
        ld      a,(de)
        xor     h
        ld      h,a
        inc     de
        ld      a,(de)
        xor     c
        ld      b,a
        dec     de
        dec     de
        ex      de,hl
        pop     af
        ld      c,a
        inc     (ix-7)
        jr      z,L_D881
.L_D87C
        ex      (sp),hl
        dec     hl
        jp      L_D856
.L_D881
        inc     (ix-6)
        jp      L_D87C
.L_D887
        ld      (iy-111),a
        jp      $1D7F
.L_D88D
        call    L_D0E5
.L_D890
        push    bc
        ld      l,a
        ld      h,$00
        add     hl,hl
        ld      c,l
        ld      b,h
        add     hl,hl
        add     hl,hl
        add     hl,bc
        ld      bc,($1D3F)
        add     hl,bc
        pop     bc
        ret
.L_D8A1
        call    L_D8B5
        ld      (iy-26),c
        ld      (iy-25),b
        ret
.L_D8AB
        call    L_D8B5
        ld      (iy-24),c
        ld      (iy-23),b
        ret
.L_D8B5
        ld      hl,($1D63)
.L_D8B8
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        dec     hl
        dec     hl
        ret
.L_D8BF
        cp      (iy-98)
        ccf
        ret     nc
        push    af
        call    L_D8CD
        pop     hl
        ld      a,h
        jr      nc,L_D8BF
        ret
.L_D8CD
        call    L_D8E9
        ret     c
.L_D8D1
        call    L_D890
        ld      (hl),$0C
        push    hl
        xor     a
        ld      b,$09
.L_D8DA
        inc     hl
        ld      (hl),a
        djnz    L_D8DA
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),$80
        inc     (iy-98)
        or      a
        ret
.L_D8E9
        ld      a,(iy-98)
.L_D8EC
        cp      $40
        ccf
        ld      c,$05
        ret
.L_D8F2
        call    L_D948
        ld      a,(iy-125)
        cp      (iy-111)
        call    nz,L_D887
        ld      l,(iy-127)
        ld      h,(iy-126)
        push    hl
        ld      b,$03
.L_D907
        ld      (hl),$00
        inc     hl
        djnz    L_D907
        ld      b,$01
        ld      a,(iy-36)
        ld      (hl),a
        bit     7,a
        jr      nz,L_D918
        ld      b,$06
.L_D918
        inc     hl
        ld      (hl),$00
        djnz    L_D918
        or      a
        pop     hl
        ret
.L_D920
        ld      c,(iy-40)
        ld      b,(iy-42)
.L_D926
        ld      (iy-36),b
        ld      a,c
        call    L_B52D
        ld      b,$00
        ld      c,a
        ld      a,($1D37)
        ld      d,a
        ld      a,($1D38)
        ld      ix,($1D3B)
        oz      Os_mal
        ld      ($1D36),hl
        ld      a,b
        ld      ($1D38),a
        ret     nc
        ld      c,$01
        ret
.L_D948
        ld      hl,($1D36)
        ld      a,($1D38)
        ld      (iy-127),l
        ld      (iy-126),h
        ld      (iy-125),a
        cp      (iy-111)
        call    nz,L_D887
        ret
.L_D95E
        ld      l,(iy-117)
        ld      h,(iy-116)
        ld      a,(iy-111)
        ld      ix,($1D3B)
        oz      Os_mfr
        ret
.L_D96E
        xor     a
        ld      ix,($1D39)
        oz      Os_mal
        ret
.L_D976
        push    bc
        ld      c, MS_S0
        oz      Os_mgb
        ld      a,b
        pop     bc
        ld      l,(iy-117)
        ld      h,(iy-116)
        ld      ix,($1D39)
        oz      Os_mfr
        ret
.L_D98A
        bit     6,(iy-71)
        ld      c,$19
        jp      nz,L_EB07
        ld      c,(iy-87)
        ld      b,(iy-86)
        push    bc
        set     5,(iy-70)
        inc     hl
        ld      (iy-32),l
        ld      (iy-31),h
        ld      b,$00
.L_D9A7
        ld      c,(hl)
        call    L_DD05
        ld      e,$00
        bit     7,c
        jr      z,L_D9B9
        ld      a,(hl)
        bit     7,a
        jr      nz,L_D9B9
        ld      e,a
        res     7,e
.L_D9B9
        inc     hl
        push    hl
        call    L_DCF7
        ld      (hl),e
        pop     hl
        inc     b
        ld      a,(hl)
        or      a
        jr      nz,L_D9A7
        xor     a
        ld      hl,($1D65)
        ld      (hl),a
        ld      hl,($1D67)
        ld      (hl),a
        ld      bc,$0000
        call    L_DBC8
.L_D9D4
        push    bc
        oz      Os_Pout
        defm    $01, "7#2* ", $00

        ld      a,$5C
        oz      Os_out
        ld      a,(iy-80)
        add     a,$20
        oz      Os_out
        ld      a,$81
        oz      Os_out
        call    L_E0D8
        call    L_EFE5
        ld      l,(iy-32)
        ld      h,(iy-31)
        call    L_DC5C
        pop     bc
.L_D9FE
        call    L_8D45
.L_DA01
        call    L_DC91
        jr      c,L_DA6C
        res     0,(iy-72)
        set     7,(iy-72)
.L_DA0E
        push    bc
.L_DA0F
        call    L_E5C9
        or      a
        call    L_E02C
        pop     bc
        jp      pe,L_DA23
        jp      c,L_DAB3
        push    bc
        call    L_84E3
        jr      L_DA0F
.L_DA23
        push    af
        call    L_DBDD
        pop     af
        cp      $01
        jr      nz,L_DA01
        push    bc
        ld      l,(iy-32)
        ld      h,(iy-31)
        push    hl
        call    L_DBB4
        pop     hl
        ld      (iy-32),l
        ld      (iy-31),h
        pop     bc
        push    bc
        call    L_DC0A
        ld      d,a
        and     $0F
        cp      $01
        jr      nz,L_DA5B
        bit     6,d
        jr      z,L_DA5B
        ld      a, SR_RPD
        ld      de,L_DA64
        ld      bc,$0032
        ld      hl,$1FAA
        oz      Os_sr
.L_DA5B
        pop     bc
        jp      L_D9D4
.L_DA5F
        call    L_EFE9
        jr      L_DA0E

.L_DA64
        defm    "NAME", $00

.L_DA69
        call    L_EFE9
.L_DA6C
        call    L_DCCB
        push    bc
        or      a
        call    L_E02C
        pop     bc
        jp      pe,L_DA23
        push    af
        call    L_DC0A
        ld      d,a
        call    L_DD05
        ld      e,(hl)
        res     7,e
        pop     af
        jr      c,L_DAA7
        call    L_EE09
        cp      $59
        jr      z,L_DA93
        ld      e,$00
        cp      $4E
        jr      nz,L_DA69
.L_DA93
        call    L_DCF7
        ld      (hl),e
        inc     e
        dec     e
        jr      z,L_DA6C
        ld      a,d
        and     $0F
        cp      $04
        jr      z,L_DA6C
        call    L_DC91
        jr      L_DB11
.L_DAA7
        cp      $36
        jr      nz,L_DAB3
        call    L_DCF7
        ld      a,e
        xor     (hl)
        ld      (hl),a
        jr      L_DA6C
.L_DAB3
        cp      $35
        jp      z,L_DB3B
        cp      $18
        jr      z,L_DAE1
        cp      $17
        jr      z,L_DB11
        cp      $12
        jp      z,L_DB47
        cp      $28
        jr      nz,L_DACB
        ld      a,$26
.L_DACB
        bit     7,c
        jr      nz,L_DA69
        push    bc
        ld      hl, L_DBD1-1
        call    L_E593
        pop     bc
        jr      c,L_DA5F
        push    bc
        call    L_E320
        pop     bc
        jp      L_DA0E
.L_DAE1
        call    L_DBDD
        bit     7,c
        jr      nz,L_DAF4
        call    L_DC0A
        bit     7,a
        jr      z,L_DAF4
        set     7,c
        jp      L_D9FE
.L_DAF4
        ld      a,b
        or      a
        jp      z,L_D9FE
        dec     b
        call    L_DC0A
        bit     7,a
        jr      z,L_DB0C
        and     $0F
        cp      $04
        jr      z,L_DB0E
        call    L_DCEF
        jr      z,L_DB0E
.L_DB0C
        res     7,c
.L_DB0E
        jp      L_D9FE
.L_DB11
        call    L_DBDD
        bit     7,c
        jr      z,L_DB2B
        call    L_DCEF
        jr      z,L_DB2B
        call    L_DC0A
        and     $0F
        cp      $04
        jr      z,L_DB2B
        res     7,c
        jp      L_D9FE
.L_DB2B
        inc     b
        call    L_DC0A
        dec     b
        or      a
        jp      z,L_D9FE
        inc     b
        call    L_DBC8
        jp      L_D9FE
.L_DB3B
        call    L_DBB4
        pop     bc
        ld      (iy-87),c
        ld      (iy-86),b
        scf
        ret
.L_DB47
        bit     7,c
        call    z,L_DBDD
        ld      bc,$0000
.L_DB4F
        call    L_DC0A
        ld      e,a
        and     $0F
        jr      z,L_DBA5
        bit     7,e
        jr      z,L_DB60
        call    L_DCEF
        jr      z,L_DB8C
.L_DB60
        ld      a,(hl)
        push    af
        ex      de,hl
        call    L_DCF7
        ld      a,c
        or      (hl)
        ld      c,a
        pop     af
        and     $0F
        push    bc
        push    de
        dec     a
        add     a,a
        ld      e,a
        ld      d,$00
        ld      ix,L_DD1A
        add     ix,de
        ld      c,(ix+0)
        ld      b,(ix+1)
        push    bc
        pop     ix
        ld      hl,($1D65)
        pop     de
        call    L_B8B4
        jr      c,L_DB8F
        pop     bc
.L_DB8C
        inc     b
        jr      L_DB4F
.L_DB8F
        ld      e,c
        pop     bc
        push    bc
        push    de
        call    L_DBF7
        call    L_DFD3
        pop     bc
        jr      z,L_DB9F
        call    L_EB07
.L_DB9F
        pop     bc
        ld      c,$00
        jp      L_D9FE
.L_DBA5
        push    bc
        call    L_DBB4
        pop     bc
        pop     de
        ld      (iy-87),e
        ld      (iy-86),d
        ld      a,c
        or      a
        ret
.L_DBB4
        call    L_E0D4
        oz      Os_Pout
        defm    $01, "2D2", $00

        call    L_B411
        call    L_BDD2
        jp      L_B411
.L_DBC8
        call    L_DC0A
        bit     7,a
        ret     z
        set     7,c
        ret

.L_DBD1
        defb    $26,$15,$16,$0E,$0F,$23,$22,$25
        defb    $34,$2B,$24,$FF

.L_DBDD
        bit     0,(iy-72)
        ret     z
        res     0,(iy-72)
        push    bc
        call    L_DBF7
        pop     bc
        ld      de,($1D3D)
.L_DBEF
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        or      a
        jr      nz,L_DBEF
        ret
.L_DBF7
        call    L_DC0A
        and     $0F
        dec     a
        add     a,a
        ld      hl,L_DC1D
        ld      e,a
        ld      d,$00
        add     hl,de
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        jp      (hl)
.L_DC0A
        ld      l,(iy-32)
        ld      h,(iy-31)
        ld      e,b
        inc     e
.L_DC12
        dec     e
        jr      z,L_DC1B
        call    L_DD05
        inc     hl
        jr      L_DC12
.L_DC1B
        ld      a,(hl)
        ret

.L_DC1D
        defw    L_DC35
        defw    L_DC41
        defw    L_DC3B
        defw    L_DC59
        defw    L_DC41
        defw    L_DC47
        defw    L_DC3B
        defw    L_DC4D
        defw    L_DC53
        defw    L_DC41
        defw    L_DC41
        defw    L_DC3B
.L_DC35
        ld      hl,$1FAA
        ld      c,$32
        ret
.L_DC3B
        ld      hl,($1D67)
        ld      c,$0F
        ret
.L_DC41
        ld      hl,($1D65)
        ld      c,$0F
        ret
.L_DC47
        ld      hl,($1D71)
        ld      c,$64
        ret
.L_DC4D
        ld      hl,($1D6D)
        ld      c,$32
        ret
.L_DC53
        ld      hl,($1D6F)
        ld      c,$32
        ret
.L_DC59
        ld      c,$00
        ret
.L_DC5C
        ld      l,(iy-32)
        ld      h,(iy-31)
        ld      b,$00
.L_DC64
        ld      c,(hl)
        inc     c
        dec     c
        ret     z
        push    hl
        ld      a,$01
        inc     b
        call    L_EEE4
        dec     b
.L_DC70
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_DC79
        oz      Os_out
        jr      L_DC70
.L_DC79
        push    bc
        ld      c,$00
        call    L_DC91
        pop     bc
        push    bc
        bit     7,c
        ld      c,$80
        call    nz,L_DC91
        pop     bc
        pop     hl
        call    L_DD05
        inc     hl
        inc     b
        jr      L_DC64
.L_DC91
        push    bc
        call    L_DC0A
        bit     7,a
        ld      a,$28
        jr      z,L_DCA1
        bit     7,c
        jr      nz,L_DCA1
        ld      a,$2C
.L_DCA1
        ld      (iy-28),a
        inc     b
        ld      (iy-27),b
        call    L_EEE4
        dec     b
        bit     7,c
        jr      nz,L_DCC5
        push    bc
        call    L_DBF7
        ld      (iy-86),c
        inc     c
        dec     c
        pop     bc
        jr      z,L_DCC5
        call    L_E585
        call    L_E5C5
        or      a
        pop     bc
        ret
.L_DCC5
        call    L_DCCB
        scf
        pop     bc
        ret
.L_DCCB
        ld      a,$28
        inc     b
        call    L_EEE4
        dec     b
        call    L_DCEF
        jr      nz,L_DCE0
        oz      Os_Pout
        defm    "No ", $00

        jr      L_DCE7
.L_DCE0
        oz      Os_Pout
        defm    "Yes", $00

.L_DCE7
        ld      a,$28
        inc     b
        call    L_EEE4
        dec     b
        ret
.L_DCEF
        push    hl
        call    L_DCF7
        ld      a,(hl)
        or      a
        pop     hl
        ret
.L_DCF7
        push    de
        push    iy
        pop     hl
        ld      de,$004D
        add     hl,de
        ld      e,b
        ld      d,$00
        add     hl,de
        pop     de
        ret
.L_DD05
        push    bc
        ld      c,(hl)
.L_DD07
        inc     hl
        ld      a,(hl)
        or      a
        jr      nz,L_DD07
        ld      a,c
        and     $0F
        cp      $07
        jr      nz,L_DD17
        inc     hl
        inc     hl
        inc     hl
        inc     hl
.L_DD17
        inc     hl
        pop     bc
        ret

.L_DD1A
        defw    L_DD32
        defw    L_DDF5
        defw    L_DD3F
        defw    L_DD3D
        defw    L_DD5C
        defw    L_DD73
        defw    L_DD7E
        defw    L_DE64
        defw    L_DE96
        defw    L_DDBB
        defw    L_DDC9
        defw    L_DE1D
.L_DD32
        ld      hl,$1FAA
        ld      b,$00
        oz      Gn_prs
        ld      c,$00
        ret
.L_DD3D
        or      a
        ret
.L_DD3F
        ld      hl,($1D67)
        call    L_DFFB
        jr      c,L_DD59
        ld      (iy+51),c
        ld      (iy+52),b
        call    L_DFFB
        jr      c,L_DD59
        ld      (iy+54),c
        ld      (iy+55),b
        ret
.L_DD59
        ld      c,$0E
        ret
.L_DD5C
        call    L_DDBB
        ld      c,$21
        ret     c
        call    L_DFEA
        jr      nz,L_DD6A
        ld      a,(iy+53)
.L_DD6A
        ld      (iy+54),a
        cp      (iy+53)
        ld      c,$0E
        ret
.L_DD73
        ld      ix,($1D73)
        ld      hl,($1D71)
        or      a
        jp      L_BC6D
.L_DD7E
        inc     de
        ld      a,(de)
        or      a
        jr      nz,L_DD7E
        inc     de
        push    de
        ld      hl,($1D67)
        call    L_DFFB
        pop     hl
        jr      nc,L_DD97
        ld      bc,$0000
        jr      z,L_DD97
.L_DD93
        ld      c,$11
        scf
        ret
.L_DD97
        ld      (iy+51),c
        ld      (iy+52),b
        inc     hl
        ld      a,b
        cp      (hl)
        dec     hl
        jr      c,L_DD93
        jr      nz,L_DDA9
        ld      a,c
        cp      (hl)
        jr      c,L_DD93
.L_DDA9
        inc     hl
        inc     hl
        inc     hl
        ld      a,b
        cp      (hl)
        jr      c,L_DDB9
        jr      nz,L_DD93
        dec     hl
        ld      a,c
        cp      (hl)
        jr      z,L_DDB9
        jr      nc,L_DD93
.L_DDB9
        or      a
        ret
.L_DDBB
        call    L_DFEA
        jr      z,L_DDC5
        ld      (iy+53),a
        or      a
        ret
.L_DDC5
        ld      c,$21
        scf
        ret
.L_DDC9
        call    L_DFE0
        ld      c,$0B
        ret     c
        push    hl
        ld      de,$0035
        push    iy
        pop     hl
        add     hl,de
        call    L_DE0D
        call    L_DE0D
        pop     hl
        call    L_DFE0
        jr      z,L_DDF0
        ld      c,$0B
        ret     c
        ld      de,$0038
        push    iy
        pop     hl
        add     hl,de
        call    L_DE0D
.L_DDF0
        ld      de,$0035
        jr      L_DE4A
.L_DDF5
        call    L_DFE0
        jr      z,L_DDFF
        ld      c,$0B
        ret     c
        jr      L_DE05
.L_DDFF
        call    L_D0E2
        call    L_D77E
.L_DE05
        ld      de,$0038
        push    iy
        pop     hl
        add     hl,de
        or      a
.L_DE0D
        ld      a,(iy-110)
        ld      (hl),a
        inc     hl
        ld      a,(iy-109)
        ld      (hl),a
        inc     hl
        ld      a,(iy-108)
        ld      (hl),a
        inc     hl
        ret
.L_DE1D
        ld      hl,($1D67)
        call    L_DFE0
        ld      c,$0B
        ret     c
        push    hl
        ld      de,$003B
        push    iy
        pop     hl
        add     hl,de
        call    L_DE0D
        call    L_DE0D
        pop     hl
        call    L_DFE0
        jr      z,L_DE47
        ld      c,$0B
        ret     c
        ld      de,$003E
        push    iy
        pop     hl
        add     hl,de
        call    L_DE0D
.L_DE47
        ld      de,$003B
.L_DE4A
        push    iy
        pop     hl
        add     hl,de
        push    hl
        ld      de,$FFC6
        push    iy
        pop     hl
        add     hl,de
        pop     de
        ex      de,hl
        ld      bc,$0006
        ldir
        call    L_FBBD
        ld      c,$0E
        ccf
        ret
.L_DE64
        ld      hl,($1D6D)
        call    L_DFD3
        jr      z,L_DE92
        res     7,(iy+29)
        res     6,(iy+29)
        ld      de,($1D69)
        call    L_DEAA
        ret     c
        set     6,(iy+29)
        ld      l,(iy-36)
        ld      h,(iy-35)
        ld      (iy+32),l
        ld      (iy+33),h
        or      a
        ret     nz
        res     6,(iy+29)
.L_DE92
        ld      c,$20
        scf
        ret
.L_DE96
        ld      de,($1D6B)
        ld      hl,($1D6F)
        call    L_DEAA
        set     7,(iy+29)
        ret     nc
        res     7,(iy+29)
        ret
.L_DEAA
        ld      (iy-36),e
        ld      (iy-35),d
        ld      (iy-38),$00
        jr      L_DEBA
.L_DEB6
        call    L_DF88
.L_DEB9
        inc     hl
.L_DEBA
        push    hl
        call    L_DFD3
        pop     hl
        ld      a,(hl)
        jr      z,L_DEFB
        cp      $5E
        jr      nz,L_DEB6
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_DEF7
        call    L_EE09
        ld      c,a
        ld      de,L_DFA6
.L_DED2
        inc     de
        inc     de
        ld      a,(de)
        or      a
        jr      z,L_DEF7
        cp      c
        jr      nz,L_DED2
        inc     de
        ld      a,(de)
        bit     7,a
        jr      z,L_DEB6
        and     $7F
        ex      de,hl
        ld      hl,L_DFC7
        ld      c,a
        ld      b,$00
        add     hl,bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        push    bc
        pop     ix
        ex      de,hl
        call    L_B8B4
        jr      nc,L_DEB9
.L_DEF7
        ld      c,$1F
        scf
        ret
.L_DEFB
        xor     a
        call    L_DF88
        ld      a,$0A
        call    L_DF88
        ret     c
        ld      a,(hl)
        or      a
        jr      z,L_DF0A
        inc     hl
.L_DF0A
        ld      a,(iy-38)
        ret
.L_DF0E
        xor     a
        call    L_DF88
        ld      a,$02
        call    L_DF88
        inc     hl
        ld      a,(hl)
        or      a
        scf
        ret     z
        cp      $23
        jr      z,L_DF54
        call    L_DFE0
        ret     c
        dec     hl
        ld      a,$10
        call    L_DF88
        ld      a,(iy-110)
        call    L_DF88
        ld      a,(iy-109)
        call    L_DF88
        ld      a,(iy-108)
        call    L_DF88
        or      a
        ret
.L_DF3E
        bit     6,(iy+29)
        scf
        ret     nz
        ld      a,$00
        jr      L_DF6C
.L_DF48
        ld      a,$04
        jr      L_DF4E
.L_DF4C
        ld      a,$06
.L_DF4E
        ld      e,a
        xor     a
        call    L_DF88
        ld      a,e
.L_DF54
        call    L_DF88
        call    L_DF77
        or      a
        ret
.L_DF5C
        xor     a
        call    L_DF88
        ld      a,$0C
        call    L_DF88
        ld      a,(hl)
        sub     $19
        jr      L_DF72
.L_DF6A
        ld      a,$08
.L_DF6C
        ld      e,a
        xor     a
        call    L_DF88
        ld      a,e
.L_DF72
        call    L_DF88
        or      a
        ret
.L_DF77
        bit     6,(iy+29)
        ret     z
        inc     hl
        ld      c,$1F
        ld      a,(hl)
        sub     $31
        jr      c,L_DFA5
        cp      $09
        jr      nc,L_DFA5
.L_DF88
        push    hl
        ld      l,(iy-36)
        ld      h,(iy-35)
        ld      (hl),a
        inc     (iy-36)
        jr      nz,L_DF98
        inc     (iy-35)
.L_DF98
        inc     (iy-38)
        ld      a,(iy-38)
        cp      $3C
        pop     hl
        ccf
        ret     nc
        ld      c,$1E
.L_DFA5
        pop     de
.L_DFA6
        scf
        ret

.L_DFA8
        defm    "1", $8A, "2", $8A, "3", $8A, "4", $8A, "5", $8A, "6", $8A, "7", $8A, "8", $8A, "9"
        defm    $8A, "B", $88, "R", $80, "#", $82, "?", $84, "^^S", $86, $00

.L_DFC7
        defw    L_DF0E
        defw    L_DF48
        defw    L_DF4C
        defw    L_DF6A
        defw    L_DF3E
        defw    L_DF5C
.L_DFD3
        dec     hl
.L_DFD4
        inc     hl
        ld      a,(hl)
        or      a
        ret     z
        cp      $0D
        ret     z
        cp      $20
        jr      z,L_DFD4
        ret
.L_DFE0
        call    L_DFD3
        scf
        ret     z
        call    L_BD57
        jr      L_DFF7
.L_DFEA
        call    L_DFD3
        scf
        ret     z
        call    L_BD91
        scf
        ret     z
        ld      a,(iy-110)
.L_DFF7
        ld      e,$00
        inc     e
        ret
.L_DFFB
        call    L_DFD3
        scf
        ret     z
        call    L_EE29
        scf
        ccf
        ret
.L_E006
        call    L_EB49
        or      a
        call    L_E02C
        jp      pe,L_E01D
        ret     nc
        cp      $35
        jr      z,L_E028
        cp      $20
        ccf
        ret     nc
        ld      a,$20
        or      a
        ret
.L_E01D
        cp      $01
        scf
        ret     nz
        push    af
        call    L_BDD2
        pop     af
        scf
        ret
.L_E028
        ld      a,$1B
        scf
        ret
.L_E02C
        call    L_EFFF
        ld      bc,$FFFF
        jr      nc,L_E03D
        bit     5,(iy-68)
        jr      nz,L_E03D
        ld      bc,$002D
.L_E03D
        call    L_E090
        call    L_EFFA
        jr      c,L_E053
        or      a
        jr      z,L_E04F
        cp      $20
        jr      c,L_E02C
        jp      L_F994
.L_E04F
        oz      Os_in
        jr      nc,L_E077
.L_E053
        cp      RC_Quit
        jr      z,Exit_PipeDream
        cp      RC_Draw
        jr      z,L_E068
        cp      RC_Time
        jr      z,L_E06D
        cp      RC_Esc
        jr      z,L_E072
        ld      a,RC_Time
        jp      L_F9B7
.L_E068
        ld      a,RC_Esc
        jp      L_F9B7
.L_E06D
        ld      a,RC_OK
        jp      L_F9B7
.L_E072
        call    L_E097
        ld      a,$36
.L_E077
        or      a
        jr      z,L_E02C
        dec     a
        scf
        jp      L_F994
.Exit_PipeDream
        ld      ix,($1D39)
        oz      Os_mcl
        ld      ix,($1D3B)
        oz      Os_mcl
        xor     a
        oz      Os_bye
.void0  jr      void0

.L_E090
        oz      Os_tin
        ret     nc
        cp      $01
        scf
        ret     nz
.L_E097
        push    af
        ld      a,SC_ACK
        oz      Os_esc
        pop     af
        scf
        ret
.L_E09F
        ld      bc,($1D7D)
        ld      a,c
        jp      L_EEE4
.L_E0A7
        ld      a,$00
        ld      bc,NQ_WCUR
        oz      Os_nq
        ld      ($1D7D),bc
        ret
.L_E0B3
        or      a
        push    af
        call    nz,L_E0FC
        pop     af
        call    z,L_E0EA
        oz      Os_Pout
        defm    $01, "6#1  ", $00

        ld      a,(iy-81)
        add     a,$21
        oz      Os_out
        ld      a,(iy-80)
        add     a,$20
        oz      Os_out
.L_E0D4
        ld      c,$31
        jr      L_E0DA
.L_E0D8
        ld      c,$32
.L_E0DA
        ld      a,$01
        oz      Os_out
        ld      a,$32
        oz      Os_out
        ld      a,$48
        oz      Os_out
        ld      a,c
        oz      Os_out
        ret
.L_E0EA
        ld      a,$35
        ld      bc, MP_DEF
        oz      Os_map
        ld      (iy+100),b
        ld      (iy+101),$40
        ld      a,$5E
        sub     c
.L_E0FC
        dec     a
        ld      (iy-81),a
        ld      (iy-80),$08
        ret
.L_E105
        ld      a,(iy+100)
        or      a
        ret     z
        xor     a
        ld      ($1D77),a
        ld      ($1D78),a
        ld      ($1D7A),a
        ld      ($1D79),a
        ld      ($1D7B),a
        call    L_E309
        ld      a,(iy-94)
        push    af
        ld      c,(iy-93)
        ld      b,(iy-92)
        push    bc
        call    L_D10E
        ld      (iy-20),c
        ld      (iy-19),b
        call    L_D8B5
        ld      (iy-26),c
        ld      (iy-25),b
        call    L_D35D
        ld      b,$03
        call    L_E8CF
        add     a,$04
        push    af
        call    L_E8DE
        pop     bc
        add     a,b
        sub     (iy+101)
        neg
        ld      b,a
.L_E150
        ld      a,(iy-94)
        cp      $01
        jr      z,L_E169
        ld      a,(iy-26)
        or      (iy-25)
        jr      z,L_E169
        push    bc
        call    L_CA2A
        call    L_D35D
        pop     bc
        djnz    L_E150
.L_E169
        ld      c,(iy-26)
        ld      b,(iy-25)
        ld      a,(iy-98)
        dec     a
        ld      (iy-55),a
        ld      a,(iy-93)
        ld      (iy-91),a
        ld      a,(iy-92)
        ld      (iy-90),a
        ld      a,(iy-94)
        ld      (iy-86),a
        cp      $01
        ld      e,$00
        jr      z,L_E190
        ld      e,$80
.L_E190
        ld      (iy-85),e
        xor     a
        ld      (iy-46),a
        ld      (iy-58),a
        ld      (iy-61),a
        ld      (iy-60),c
        ld      (iy-59),b
        call    L_EFFF
        set     6,(iy-70)
        ld      hl,L_E1F9
        call    L_ED6F
.L_E1B0
        call    L_E31D
        ccf
        jr      c,L_E1E5
        call    L_ABC6
        call    L_F023
        jr      c,L_E1E5
        ld      hl,$1D79
        bit     7,(hl)
        jr      nz,L_E1E4
        inc     (iy-60)
        jr      nz,L_E1CD
        inc     (iy-59)
.L_E1CD
        xor     a
        ld      (iy-61),a
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_C9F9
        jr      nc,L_E1B0
        call    L_AD32
.L_E1DF
        call    L_E2D8
        jr      nc,L_E1DF
.L_E1E4
        or      a
.L_E1E5
        pop     bc
        ld      (iy-93),c
        ld      (iy-92),b
        pop     bc
        ld      (iy-94),b
        push    af
        call    L_EFFA
        call    L_ED53
        pop     af
        ret
.L_E1F9
        push    af
        push    bc
        push    de
        push    hl
        ld      hl,$1D79
        ld      e,a
        ld      a,($1D7A)
        or      a
        jr      z,L_E236
        cp      $FF
        jr      nz,L_E212
        set     0,(hl)
        ld      a,e
        sub     $30
        jr      L_E231
.L_E212
        bit     0,(hl)
        jr      z,L_E221
        ld      a,e
        cp      $50
        jr      nz,L_E221
        res     0,(hl)
        set     1,(hl)
        jr      L_E22D
.L_E221
        bit     1,(hl)
        jr      z,L_E22D
        ld      a,e
        sub     $20
        ld      ($1D7C),a
        res     1,(hl)
.L_E22D
        ld      a,($1D7A)
        dec     a
.L_E231
        ld      ($1D7A),a
        jr      L_E2A4
.L_E236
        bit     7,(hl)
        jr      nz,L_E2A4
        ld      a,e
        cp      $20
        jr      z,L_E256
        cp      $A0
        jr      z,L_E256
        cp      $0D
        jr      z,L_E279
        cp      $0C
        jr      z,L_E260
        cp      $05
        jr      nz,L_E25B
        ld      a,$FF
        ld      ($1D7A),a
        jr      L_E2A4
.L_E256
        call    L_E2CB
        jr      L_E2A4
.L_E25B
        call    L_E2A9
        jr      L_E2A4
.L_E260
        ld      a,($1D7B)
        or      a
        jr      nz,L_E269
        ld      a,($1D7C)
.L_E269
        push    af
        call    L_E2D8
        pop     af
        dec     a
        jr      nz,L_E269
        ld      a,($1D7C)
        ld      ($1D7B),a
        jr      L_E2A4
.L_E279
        bit     6,(iy-72)
        jr      z,L_E294
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_D56B
        jr      c,L_E294
        ld      a,(iy+100)
        dec     a
        ld      ($1D77),a
        call    L_E2A9
.L_E294
        call    L_E2D8
        ld      a,($1D7B)
        or      a
        jr      nz,L_E2A0
        ld      a,($1D7C)
.L_E2A0
        dec     a
        ld      ($1D7B),a
.L_E2A4
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret
.L_E2A9
        ld      a,($1D77)
        srl     a
        srl     a
        srl     a
        ld      hl,$1FDD
        ld      e,a
        ld      d,$00
        add     hl,de
        ld      a,($1D77)
        and     $07
        ld      e,a
        ld      a,$80
        inc     e
.L_E2C2
        dec     e
        jr      z,L_E2C9
        srl     a
        jr      L_E2C2
.L_E2C9
        or      (hl)
        ld      (hl),a
.L_E2CB
        ld      a,($1D77)
        inc     a
        cp      (iy+100)
        ccf
        ret     c
        ld      ($1D77),a
        ret
.L_E2D8
        ld      hl,$1D79
        bit     7,(hl)
        scf
        ret     nz
        ld      a,$35
        ld      bc, MP_WR
        ld      de,($1D78)
        ld      d,$00
        ld      hl,$1FDD
        oz      Os_map
        call    L_E309
        xor     a
        ld      ($1D77),a
        ld      a,($1D78)
        inc     a
        ld      ($1D78),a
        cp      (iy+101)
        ccf
        ret     nc
        ld      hl,$1D79
        set     7,(hl)
        ret
.L_E309
        ld      a,(iy+100)
        add     a,$07
        rra
        srl     a
        srl     a
        ld      b,a
        xor     a
        ld      hl,$1FDD
.L_E318
        ld      (hl),a
        inc     hl
        djnz    L_E318
        ret
.L_E31D
        oz      Os_xin
        ret
.L_E320
        cp      $5F
        ret     nc
        ld      hl,L_E330
        add     a,a
        ld      e,a
        ld      d,$00
        add     hl,de
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        jp      (hl)

.L_E330
        defw    L_8A03
        defw    L_89F8
        defw    L_B103
        defw    L_8F33
        defw    L_8EB8
        defw    L_8F9B
        defw    L_AE08
        defw    L_A154
        defw    L_A166
        defw    L_A26B
        defw    L_88F1
        defw    L_931E
        defw    L_9298
        defw    L_8D04
        defw    L_8560
        defw    L_8568
        defw    L_8CEC
        defw    L_8CE1
        defw    L_8E1A
        defw    L_8D62
        defw    L_8D4D
        defw    L_8532
        defw    L_8E97
        defw    L_8E62
        defw    L_8E81
        defw    L_861F
        defw    L_85BD
        defw    L_8E71
        defw    L_8E78
        defw    L_8EB1
        defw    L_8543
        defw    L_8D21
        defw    L_EB05
        defw    L_8D19
        defw    L_858A
        defw    L_85A7
        defw    L_846F
        defw    L_8640
        defw    L_866D
        defw    L_8A48
        defw    L_8A30
        defw    L_8D8D
        defw    L_8A5C
        defw    L_845E
        defw    L_8BC0
        defw    L_8C0E
        defw    L_8BF4
        defw    L_8DDE
        defw    L_8C25
        defw    L_854B
        defw    L_826F
        defw    L_925B
        defw    L_8656
        defw    L_8E2A
        defw    L_960E
        defw    L_8455
        defw    L_B4A6
        defw    L_93D3
        defw    L_9980
        defw    L_9343
        defw    L_9C49
        defw    L_9C1D
        defw    L_9C3C
        defw    L_9C0D
        defw    L_874B
        defw    L_8744
        defw    L_898E
        defw    L_894F
        defw    L_8702
        defw    L_8710
        defw    L_8848
        defw    L_8840
        defw    L_8844
        defw    L_883C
        defw    L_884C
        defw    L_881E
        defw    L_87D6
        defw    L_87DB
        defw    L_87E5
        defw    L_87E0
        defw    L_87D1
        defw    L_E3EE
        defw    L_AAF9
        defw    L_86E1
        defw    L_8483
        defw    L_8487
        defw    L_848B
        defw    L_848F
        defw    L_8493
        defw    L_8497
        defw    L_849B
        defw    L_849F
        defw    L_84A3
        defw    L_8AB7
        defw    L_8ABA

.L_E3EE
        call    L_B398
        call    L_CA7C
        call    L_CA85
        ld      hl,($1D53)
        push    hl
        ld      a,(iy-87)
        push    af
        set     5,(iy-70)
        ld      hl,L_E5BD
        ld      ($1D53),hl
        ld      (iy-44),$01
.L_E40D
        call    L_E614
.L_E410
        call    L_E72A
.L_E413
        call    L_8D45
.L_E416
        call    L_E5C9
.L_E419
        or      a
        call    L_E02C
        jp      pe,L_E463
        jr      c,L_E469
        bit     1,(iy-4)
        jr      nz,L_E43F
        ld      b,(iy-71)
        push    bc
        bit     0,(iy-4)
        jr      z,L_E436
        set     2,(iy-71)
.L_E436
        call    L_84E3
        pop     af
        ld      (iy-71),a
        jr      L_E416
.L_E43F
        ld      l,(iy-48)
        ld      h,(iy-47)
        inc     hl
        call    L_EE09
        ld      c,a
.L_E44A
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_E45E
        cp      c
        jr      nz,L_E44A
        ld      hl,($1D3D)
        ld      (hl),a
        inc     hl
        ld      (hl),$00
        call    L_8687
        jr      L_E416
.L_E45E
        call    L_EFE9
        jr      L_E419
.L_E463
        cp      $01
        jr      nz,L_E419
        jr      L_E4A5
.L_E469
        cp      $35
        jr      z,L_E4AB
        cp      $51
        jr      z,L_E4AB
        cp      $18
        jr      z,L_E4C6
        cp      $12
        jr      z,L_E4DC
        cp      $17
        jr      z,L_E4DC
        cp      $36
        jr      z,L_E4F7
        ld      hl,L_E5A2-1
        call    L_E593
        jr      c,L_E45E
        push    bc
        ld      a,(iy-44)
        push    af
        ld      a,b
        and     $7F
        call    L_E320
        pop     af
        ld      (iy-44),a
        pop     bc
        bit     7,b
        jp      z,L_E416
        bit     2,(iy-72)
        jp      nz,L_E410
.L_E4A5
        call    L_E747
        jp      L_E40D
.L_E4AB
        call    L_E747
        call    L_E7CA
        call    L_B411
        xor     a
        call    L_E0B3
        pop     af
        ld      (iy-87),a
        pop     hl
        ld      ($1D53),hl
        call    L_D357
        jp      L_BDD2
.L_E4C6
        call    L_E747
        call    L_E5E8
        call    L_E5C5
        dec     (iy-44)
        jp      nz,L_E410
        ld      (iy-44),$16
        jp      L_E410
.L_E4DC
        call    L_E747
        call    L_E5E8
        call    L_E5C5
        inc     (iy-44)
        ld      a,(iy-44)
        cp      $17
        jp      c,L_E410
        ld      (iy-44),$01
        jp      L_E410
.L_E4F7
        bit     1,(iy-4)
        jr      z,L_E537
        ld      c,$00
.L_E4FF
        ld      l,(iy-52)
        ld      h,(iy-51)
        ld      a,(hl)
        or      a
        jp      z,L_E410
.L_E50A
        inc     hl
        ld      (iy-52),l
        ld      (iy-51),h
        ld      a,(hl)
        or      a
        jr      nz,L_E51E
        ld      l,(iy-48)
        ld      h,(iy-47)
        inc     hl
        jr      L_E50A
.L_E51E
        ld      hl,($1D3D)
        ld      b,a
        ld      a,c
        or      a
        ld      a,b
        jr      nz,L_E531
        ld      c,a
        ld      a,(hl)
        call    L_EE09
        ld      e,a
        ld      a,c
        cp      e
        jr      z,L_E4FF
.L_E531
        ld      (hl),a
        inc     hl
        ld      (hl),$00
        jr      L_E53D
.L_E537
        call    L_E559
        call    L_E585
.L_E53D
        call    L_8687
        jp      L_E413
.L_E543
        ld      l,(iy-48)
        ld      h,(iy-47)
        dec     hl
        ld      a,(hl)
        ld      (iy-86),a
        ret
.L_E54F
        call    L_E7A5
        call    L_E783
        call    L_EA7C
        ret     c
.L_E559
        ld      de,$0022
        push    iy
        pop     hl
        add     hl,de
        ex      de,hl
        ld      l,(iy-48)
        ld      h,(iy-47)
        inc     hl
.L_E568
        inc     hl
        inc     de
        ld      a,(hl)
        ld      (de),a
        or      a
        jr      z,L_E57D
        ld      a,(iy-4)
        bit     1,a
        jr      nz,L_E57A
        bit     0,a
        jr      nz,L_E568
.L_E57A
        inc     de
        xor     a
        ld      (de),a
.L_E57D
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        ret
.L_E585
        ld      de,($1D3D)
        dec     de
        dec     hl
.L_E58B
        inc     de
        inc     hl
        ld      a,(hl)
        ld      (de),a
        or      a
        jr      nz,L_E58B
        ret
.L_E593
        ld      e,a
.L_E594
        inc     hl
        ld      a,(hl)
        cp      $FF
        scf
        ret     z
        ld      b,a
        and     $7F
        cp      e
        jr      nz,L_E594
        or      a
        ret

.L_E5A2
        defb    $26,$15,$16,$0E,$0F,$23,$24,$22
        defb    $8B,$01,$25,$BB,$BA,$34,$54,$55
        defb    $56,$57,$58,$59,$5A,$5B,$5C,$B9
        defb    $B7,$D3,$FF

.L_E5BD
        call    L_E614
        call    L_E72A
        jr      L_E5C9
.L_E5C5
        set     5,(iy-72)
.L_E5C9
        ld      a,(iy-86)
        cp      (iy-81)
        jr      nc,L_E5D4
        add     a,(iy-28)
.L_E5D4
        ld      (iy-42),a
        ld      (iy-89),a
        ld      (iy-85),$00
        call    L_EEFE
        dec     a
        call    L_C45E
        jp      L_C43C
.L_E5E8
        call    L_8D45
        ld      a,(iy-44)
        push    af
        call    L_E54F
        call    L_E585
        call    L_E543
        pop     af
        call    L_E7A5
.L_E5FC
        ex      de,hl
        ld      l,(iy-48)
        ld      h,(iy-47)
        ld      a,(de)
        or      a
        sbc     hl,de
        add     a,l
        sub     $03
        ld      (iy-28),a
        ex      de,hl
        inc     hl
        ld      b,(hl)
        ld      (iy-27),b
        ret
.L_E614
        ld      a,$5E
        call    L_E0B3
        call    L_EFE5
        ld      a,$38
        ld      b,$01
        call    L_EEE4
        oz      Os_Pout
        defm    "File ", $00

        bit     3,(iy-71)
        jr      z,L_E65E
        call    L_ED2A
        bit     3,(iy-70)
        jr      z,L_E63E
        call    L_A01D
.L_E63E
        ld      hl,$1FAA
        ld      bc,$0000
        xor     a
        cpir
        dec     hl
        inc     c
        jr      z,L_E669
        push    hl
        call    L_EEFE
        pop     hl
        sub     $39
        ld      b,a
.L_E653
        dec     hl
        inc     c
        jr      z,L_E659
        djnz    L_E653
.L_E659
        call    L_F03D
        jr      L_E669
.L_E65E
        oz      Os_Pout
        defm    "No File", $00

.L_E669
        ld      a,$45
        ld      b,$02
        call    L_EEE4
        bit     2,(iy-71)
        jr      nz,L_E682
        oz      Os_Pout
        defm    "Insert", $00

        jr      L_E68E
.L_E682
        oz      Os_Pout
        defm    "Overtype", $00

.L_E68E
        ld      a,$45
        ld      b,$03
        call    L_EEE4
        bit     4,(iy-70)
        jr      z,L_E6A9
        oz      Os_Pout
        defm    "Microspace", $00

.L_E6A9
        ld      a,$38
        ld      b,$02
        call    L_EEE4
        oz      Os_Pout
        defm    "Page ", $00

        ld      ix,($1D63)
        ld      l,(ix+3)
        ld      h,(ix+4)
        call    L_EE7C
        ld      ix,($1D3B)
        ld      bc, NQ_Mfs
        oz      Os_nq
        ld      e,a
        ld      d,$00
        push    de
        push    bc
        ld      a,$38
        ld      b,$03
        call    L_EEE4
        oz      Os_Pout
        defm    "Free ", $00

        ld      bc, NQ_Out
        oz      Os_nq
        ld      hl,$0000
        ld      e,l
        ld      d,h
        ld      a,l
        add     hl,sp
        oz      Gn_pdn
        pop     bc
        pop     bc
        call    L_8D45
        ld      a,$01
.L_E6FA
        push    af
        call    L_E7A5
        push    hl
        ld      a,(hl)
        inc     hl
        ld      b,(hl)
        call    L_EEE4
        jr      L_E709
.L_E707
        oz      Os_out
.L_E709
        inc     hl
        ld      a,(hl)
        or      a
        jp      p,L_E707
        call    L_E543
        pop     hl
        pop     af
        push    af
        push    hl
        call    L_E54F
        call    L_E585
        pop     hl
        call    L_E5FC
        call    L_E5C5
        pop     af
        inc     a
        cp      $17
        jr      nz,L_E6FA
        ret
.L_E72A
        call    L_E5E8
        call    L_EEE4
        ld      e,(iy-48)
        ld      d,(iy-47)
        inc     de
        inc     de
        ld      (iy-52),e
        ld      (iy-51),d
        res     0,(iy-72)
        set     7,(iy-72)
        ret
.L_E747
        bit     0,(iy-72)
        ret     z
        call    L_B411
        call    L_B3C1
        ld      e,(iy-28)
        ld      d,(iy-27)
        push    de
        call    L_8572
        push    bc
        ld      a,b
        call    L_E783
        call    L_EA9C
        pop     de
        pop     hl
        ld      (iy-28),l
        ld      (iy-27),h
        ld      hl,($1D3D)
        jp      c,L_EB07
        inc     d
        dec     d
        ret     z
.L_E775
        call    L_B518
.L_E778
        ld      a,(hl)
        inc     hl
        ld      (ix+5),a
        inc     ix
        or      a
        jr      nz,L_E778
        ret
.L_E783
        ld      l,(iy-48)
        ld      h,(iy-47)
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        ld      hl,$1D43
        ret
.L_E790
        call    L_E54F
        ld      a,(hl)
        or      a
        bit     0,(iy-4)
        ret     z
        call    L_EE29
        jr      z,L_E7A2
        ld      a,c
        or      a
        ret
.L_E7A2
        xor     a
        scf
        ret
.L_E7A5
        ld      c,a
        ld      hl,L_E8F4
.L_E7A9
        ld      e,l
        ld      d,h
        inc     hl
.L_E7AC
        inc     hl
        ld      a,(hl)
        bit     7,a
        jr      z,L_E7AC
        ld      (iy-4),a
        inc     hl
        inc     hl
        ld      (iy-48),l
        ld      (iy-47),h
        inc     hl
.L_E7BE
        inc     hl
        ld      a,(hl)
        or      a
        jr      nz,L_E7BE
        ex      de,hl
        dec     c
        ret     z
        ex      de,hl
        inc     hl
        jr      L_E7A9
.L_E7CA
        ld      a,$0B
        call    L_E790
        ld      c,$4F
        jr      c,L_E7D6
        or      $40
        ld      c,a
.L_E7D6
        ld      (iy+9),c
        ld      a,$06
        call    L_E790
        ld      (iy+8),a
        ld      a,$07
        call    L_E790
        jr      c,L_E7F3
        ld      (iy+10),a
        ld      (iy+11),$00
        ld      (iy+12),$01
.L_E7F3
        ld      a,$05
        call    L_E790
        push    af
        ld      b,$04
        call    L_E8CF
        ld      e,a
        pop     af
        sub     e
        jr      nc,L_E804
        xor     a
.L_E804
        push    af
        call    L_E8DE
        ld      e,a
        pop     af
        sub     e
        jr      nc,L_E80E
        xor     a
.L_E80E
        cp      (iy+8)
        jr      nc,L_E814
        xor     a
.L_E814
        ld      (iy+7),a
        ld      a,$0D
        call    L_E54F
        push    hl
        ld      de,$0015
        push    iy
        pop     hl
        add     hl,de
        ex      de,hl
        pop     hl
        call    L_E8B7
        ld      (iy+14),b
        ld      a,$0E
        call    L_E54F
        push    hl
        ld      de,$000F
        push    iy
        pop     hl
        add     hl,de
        ex      de,hl
        pop     hl
        call    L_E8B7
        ld      (iy+15),b
        ld      bc,$0154
        ld      a,$20
        call    L_E895
        ld      bc,$0A43
        ld      a,$10
        call    L_E895
        ld      bc,$0941
        ld      a,$08
        call    L_E895
        ld      bc,$0C4D
        ld      a,$04
        call    L_E895
        ld      bc,$0852
        ld      a,$01
        call    L_E895
        ld      a,(iy-69)
        push    af
        ld      b,$02
        ld      a,$02
        call    L_E893
        pop     af
        xor     (iy-69)
        jr      z,L_E888
        bit     1,(iy-69)
        jr      nz,L_E885
        call    L_C8F2
        jr      L_E888
.L_E885
        call    L_C8D9
.L_E888
        ld      b,$03
        ld      a,$40
        call    L_E893
        ld      b,$04
        ld      a,$80
.L_E893
        ld      c,$59
.L_E895
        push    af
        push    bc
        ld      a,b
        call    L_E790
        call    L_EE09
        ld      e,a
        pop     bc
        pop     af
        push    af
        xor     $FF
        and     (iy-69)
        ld      (iy-69),a
        pop     af
        ld      b,a
        ld      a,e
        cp      c
        ret     nz
        ld      a,b
        or      (iy-69)
        ld      (iy-69),a
        ret
.L_E8B7
        ld      b,$FF
        dec     hl
.L_E8BA
        inc     b
        inc     hl
        inc     de
        ld      a,(hl)
        ld      (de),a
        or      a
        jr      nz,L_E8BA
        ret
.L_E8C3
        dec     hl
.L_E8C4
        inc     hl
        ld      a,(hl)
        or      a
        scf
        ret     z
        cp      $20
        jr      z,L_E8C4
        or      a
        ret
.L_E8CF
        ld      c,$00
.L_E8D1
        push    bc
        ld      a,b
        add     a,$0E
        call    L_E790
        pop     bc
        add     a,c
        ld      c,a
        djnz    L_E8D1
        ret
.L_E8DE
        ld      b,$02
        ld      c,$00
.L_E8E2
        push    bc
        ld      a,b
        add     a,$13
        call    L_E54F
        call    L_E8C3
        pop     bc
        jr      c,L_E8F0
        inc     c
.L_E8F0
        djnz    L_E8E2
        ld      a,c
        ret

.L_E8F4
        defm    $00
        defm    $01, "Text/Numbers", $82, $01, "TNTN", $00
        defm    $05, $02, "Borders", $82, $01, "BOYN", $00
        defm    $05, $03, "Justify", $82, $01, "JUNY", $00
        defm    $08, $04, "Wrap", $82, $01, "WRYN", $00
        defm    $01, $05, "Page length", $81, $03, "PL66", $00
        defm    $00
        defm    $06, "Line spacing", $81, $03, "LS1", $00
        defm    $02, $07, "Start page", $81, $03, "PS", $00
        defm    $11, $01, "Insert on wrap"
        defm    $82, $01, "IWRC", $00
        defm    $11, $02, "Calc: Auto/Man"
        defm    $82, $01, "AMAM", $00
        defm    $13, $03, "Columns/Rows", $82, $01, "RCCR", $00
        defm    $11, $04, "Decimal places"
        defm    $83, $01, "DP23456789F01", $00
        defm    $11, $05, "Minus/Brackets"
        defm    $82, $01, "MBMB", $00
        defm    $16, $06, "Lead chs.", $80, $04, "LP", $A3, $00
        defm    $15, $07, "Trail chs.", $80, $04, "TP%", $00
        defm    "#", $01, "Margins: Top", $81, $03, "TM0", $00
        defm    ")", $02, "Header", $81, $03, "HM2", $00
        defm    ")", $03, "Footer", $81, $03, "FM2", $00
        defm    ")", $04, "Bottom", $81, $03, "BM8", $00
        defm    "+", $05, "Left", $81, $03, "LM0", $00
        defm    ")", $06, "Header", $80, $F5, "HE", $00
        defm    ")", $07, "Footer", $80, $F5, "FO", $00
        defm    "7", $05, "Title", $80, $F5, "DE", $00

.L_EA7C
        ld      e,l
        ld      d,h
        ld      a,(de)
        ld      l,a
        inc     de
        ld      a,(de)
        ld      h,a
        dec     de
        or      a
        ret     z
        push    hl
        pop     ix
        ld      a,b
        cp      (ix+4)
        jr      nz,L_EA7C
        ld      a,c
        cp      (ix+3)
        jr      nz,L_EA7C
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        scf
        ret
.L_EA9C
        ld      (iy-126),a
        or      a
        jr      z,L_EAB8
        push    hl
        push    bc
        add     a,$06
        push    af
        ld      c,a
        ld      b,$00
        call    L_D96E
        jr      c,L_EAFF
        ld      (iy-127),l
        ld      (iy-126),h
        pop     af
        pop     bc
        pop     hl
.L_EAB8
        push    af
        push    bc
        push    hl
        call    L_EA7C
        jr      nc,L_EAD6
        push   ix
        pop     hl
        ld      (iy-117),l
        ld      (iy-116),h
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        ld      a,(hl)
        ld      (de),a
        inc     hl
        ld      c,(hl)
        ld      b,$00
        call    L_D976
.L_EAD6
        pop     hl
        ld      c,$FF
        ld      b,c
        call    L_EA7C
        pop     bc
        ld      a,(iy-127)
        ld      (de),a
        inc     de
        ld      a,(iy-126)
        ld      (de),a
        or      a
        jr      z,L_EAFC
        call    L_B518
        ld      (ix+1),$00
        pop     af
        push    af
        ld      (ix+2),a
        ld      (ix+3),c
        ld      (ix+4),b
.L_EAFC
        pop     af
        or      a
        ret
.L_EAFF
        pop     hl
        pop     hl
        pop     hl
        ld      c,$01
        ret
.L_EB05
        ld      c,$25
.L_EB07
        push    bc
        call    L_EFE9
        call    L_EED0
        pop     bc
        ld      a,c
        or      a
        jr      z,L_EB32
        cp      $14
        jr      nz,L_EB3C
        ld      hl,$1FAA
        call    L_F03D
        push    bc
        oz      Os_Pout
        defm    " not found", $00

        pop     bc
        ld      a,$0A
        add     a,c
        jr      L_EB46
.L_EB32
        call    L_EBB9
        call    L_EBA4
        ld      a,c
        jp      L_EB46
.L_EB3C
        call    L_EBB9
        ld      ix,L_F020
        call    L_EB4D
.L_EB46
        ld      (iy-84),a
.L_EB49
        oz      Os_pur
        scf
        ret
.L_EB4D
        ld      hl,L_EC31
        dec     a
        ld      e,$00
        ld      b,a
        or      a
        jr      z,L_EB5E
.L_EB57
        inc     hl
        bit     7,(hl)
        jr      z,L_EB57
        djnz    L_EB57
.L_EB5E
        inc     hl
        ld      a,(hl)
        and     $7F
        cp      $20
        jr      nc,L_EB84
        push    hl
        ld      b,a
        ld      hl, L_EBDB-1
.L_EB6B
        dec     b
        jr      z,L_EB75
.L_EB6E
        inc     hl
        bit     7,(hl)
        jr      z,L_EB6E
        jr      L_EB6B
.L_EB75
        inc     hl
        ld      a,(hl)
        call    L_EB90
        jp      p,L_EB75
        pop     hl
        bit     7,(hl)
        jr      z,L_EB5E
        jr      L_EB8B
.L_EB84
        ld      a,(hl)
        call    L_EB90
        jp      p,L_EB5E
.L_EB8B
        ld      a,e
        ld      (iy-74),c
        ret
.L_EB90
        push    af
        inc     c
        dec     c
        jr      z,L_EBA1
        and     $7F
        inc     e
        dec     e
        call    z,L_EE09
        call    L_B8B4
        inc     e
        dec     c
.L_EBA1
        pop     af
        or      a
        ret
.L_EBA4
        ld      e,c
        oz      Os_erc
        oz      Gn_esp
        ld      c,$00
.L_EBAC
        oz      Gn_rbe
        or      a
        ret     z
        oz      Os_out
        inc     hl
        inc     c
        dec     e
        jr      nz,L_EBAC
        ret
.L_EBB9
        push    af
        call    L_EEFE
        ld      c,a
        pop     af
        ret

.ErrHandler
        ret     z
        cp      RC_Quit
        jp      z,Exit_PipeDream
        cp      RC_Bdn
        jr      z,L_EBD9
        cp      RC_Dvz
        jr      c,L_EBD9
        cp      $4D
        jr      nc,L_EBD9
        ld      hl,L_F3AD
        inc     h
        dec     h
        ccf
        ret
.L_EBD9
        cp      a
        ret

.L_EBDB
        defm    "bad", $A0, "fiel", $E4, "fil", $E5, "not"
        defm    $A0, "erro", $F2, "no", $A0, "too many"
        defm    $A0, "overflo", $F7, "colum", $EE, "too"
        defm    $A0, "lon", $E7, "expressio", $EE, "rang"
        defm    $E5, "lis", $F4, "mar", $EB, "argumen"
.L_EC31
        defm    $F4, "Memory ful", $EC, "FP ", $88, "Stack "
        defm    $88, "Escap", $E5, $07, $09, $F3, "Divide by "
        defm    $B0, "-ve roo", $F4, $01, $90, $06, $0F, "ed bloc"
        defm    $EB, "Typing ", $85, $01, "slo", $F4, "Loo"
        defm    $F0, "Log ", $8D, $01, $8D, "Looku", $F0, $01, "inde"
        defm    $F8, $01, "numbe", $F2, $0A, "few ", $10, $F3, "Propagate"
        defm    $E4, $03, " ", $04, "foun", $E4, "Line ", $0A, $8B
        defm    $01, "dat", $E5, $01, "optio", $EE, $01, $0E, " ", $83, "Editing "
        defm    $8C, $06, $0E, " ", $83, "End of ", $8E, $06, "name for sav"
        defm    $E5, "Edg", $E5, $0A, $8B, $01, "^ ", $82, $06, "targe"
        defm    $F4, $01, $89, "All ", $09, "s zero widt"
        defm    $E8, "Overla", $F0, "Exp rang"
        defm    $E5, $0F, " Colto", $EE
.L_ED2A
        ld      hl,($1D75)
        ld      de,$1FAA
        jr      L_ED39
.L_ED32
        ld      de,($1D75)
        ld      hl,$1FAA
.L_ED39
        ld      bc,$0033
        ldir
        ret
.L_ED3F
        ld      hl,($1D75)
        xor     a                               ; read filename
        ld      bc,L_FF32
        ld      de,$1FAA
        oz      Gn_esa
        ld      hl,$1FAA
        oz      Dc_nam
        ret
.L_ED53
        res     6,(iy-70)
        res     0,(iy-70)
.L_ED5B
        bit     7,(iy-70)
        ret     z
        res     7,(iy-70)
        call    L_EDC2
        dec     b
        ld      sp,$005D
        ret
.L_ED6C
        ld      hl,L_EDCF
.L_ED6F
        ld      ($1D49),hl
        xor     a
        ld      (iy-83),a
        ld      (iy-89),a
        bit     0,(iy-70)
        ret     z
        call    L_EDC2
        dec     b
        ld      sp,$005B
        set     7,(iy-70)
        ret
.L_ED8A
        ld      a,$20
        bit     6,(iy-70)
        jp      z,L_F015
.L_ED93
        push    af
        cp      $20
        jr      z,L_EDB7
        cp      $0D
        jr      nz,L_EDA0
        ld      (iy-83),$00
.L_EDA0
        ld      a,(iy-83)
        or      a
        jr      z,L_EDB0
        ld      a,$20
.L_EDA8
        call    L_EDB1
        dec     (iy-83)
        jr      nz,L_EDA8
.L_EDB0
        pop     af
.L_EDB1
        push    hl
        ld      hl,($1D49)
        ex      (sp),hl
        ret
.L_EDB7
        bit     4,(iy-70)
        jr      nz,L_EDB0
        pop     af
        inc     (iy-83)
        ret
.L_EDC2
        ex      (sp),hl
.L_EDC3
        ld      a,(hl)
        inc     hl
        or      a
        jr      z,L_EDCD
        call    L_EDB1
        jr      L_EDC3
.L_EDCD
        ex      (sp),hl
        ret
.L_EDCF
        oz      Os_prt
        jr      c,L_EDDB
        cp      $0D
        ret     nz
        ld      a,$0A
        oz      Os_prt
        ret     nc
.L_EDDB
        call    L_ABBB
        ld      hl,($1D59)
        ld      sp,hl
        ld      c,$00
        scf
        ret
.L_EDE6
        call    L_EDC2
        dec     b
        ld      sp,$0053
        ret
.L_EDEE
        ld      a,$05
        call    L_E790
        ld      c,$50
.L_EDF5
        push    af
        call    L_EDC2
        dec     b
        ld      ($7900),a
        call    L_EDB1
        pop     af
        add     a,$20
        call    L_EDB1
        sub     $20
        ret
.L_EE09
        call    L_EE1B
        ret     nc
        and     $DF
        ret
.L_EE10
        cp      $30
        ccf
        ret     nc
        cp      $3A
        ret
.L_EE17
        call    L_EE10
        ret     c
.L_EE1B
        cp      $41
        ccf
        ret     nc
        cp      $5B
        ret     c
        cp      $61
        ccf
        ret     nc
        cp      $7B
        ret
.L_EE29
        ld      de,$0002
        ld      b,$1E
        oz      Gn_gdn
        jr      c,L_EE39
        jr      nz,L_EE39
        ld      a,$01
        or      a
        ret
.L_EE39
        cp      a
        ret
.L_EE3B
        ld      de,$0022
        push    iy
        pop     hl
        add     hl,de
.L_EE42
        inc     hl
        ld      a,(hl)
        or      a
        ret     z
        oz      Os_out
        dec     (iy-74)
        jr      nz,L_EE42
        ret
.L_EE4E
        ld      (iy+35),$7E
        ld      (iy+36),$20
        call    L_B518
        ld      l,(ix+5)
        ld      h,$00
        ld      a,$02
        call    L_EE88
        xor     a
        jr      L_EE66
.L_EE66
        push    hl
        push    de
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        ld      e,(iy-74)
        ld      d,$00
        add     hl,de
        ld      (hl),a
        inc     (iy-74)
        pop     de
        pop     hl
        ret
.L_EE7C
        ld      ix,L_F020
        jr      L_EE8F
.L_EE82
        ld      l,a
        ld      h,$00
        jr      L_EE8B
.L_EE87
        xor     a
.L_EE88
        ld      (iy-74),a
.L_EE8B
        ld      ix,L_EE66
.L_EE8F
        push   ix
        pop     de
        ld      b,$00
        ld      ix,L_EEC6
.L_EE98
        push    bc
        ld      b,(ix+1)
        ld      c,(ix+0)
        xor     a
.L_EEA0
        inc     a
        sbc     hl,bc
        jr      nc,L_EEA0
        add     hl,bc
        dec     a
        pop     bc
        call    L_EEBA
        inc     ix
        inc     ix
        ld      a,(ix+1)
        or      (ix+0)
        jr      nz,L_EE98
        ld      a,l
        jr      L_EEC0
.L_EEBA
        or      a
        jr      nz,L_EEC0
        bit     7,b
        ret     z
.L_EEC0
        ld      b,$FF
        or      $30
        push    de
        ret


.L_EEC6
        defb    $10,$27,$E8,$03,$64,$00,$0A,$00
        defb    $00,$00
.L_EED0
        call    L_EFC4
        set     2,(iy-72)
        ld      a,$07
        ld      b,$00
        jr      L_EEE4
.L_EEDD
        ld      a,$07
        ld      b,$00
        jr      L_EEE4
.L_EEE3
        xor     a
.L_EEE4
        push    af
        ld      a,$01
        oz      Os_out
        ld      a,$33
        oz      Os_out
        ld      a,$40
        oz      Os_out
        pop     af
        add     a,$20
        oz      Os_out
        push    af
        ld      a,b
        add     a,$20
        oz      Os_out
        pop     af
        ret
.L_EEFE
        push    bc
        ld      bc, NQ_WBOX
        ld      a,$00                           ; get current window information  !! xor a
        oz      Os_nq
        ld      a,c
        pop     bc
        ret

.L_EF09
        defm    "Loa", $E4, "Sa", $F6, "Sor", $F4, "Calcula"
        defm    $F4, "Replica", $F4, "Searc", $E8
.L_EF2A
        bit     2,(iy-72)
        ret     nz
        bit     6,(iy-70)
        ret
.L_EF34
        call    L_EF2A
        ret     nz
        bit     7,(iy+6)
        ret     nz
        oz      Os_ust
        jr      nz,L_EF8E
        set     7,(iy+6)
        call    L_EEDD
        oz      Os_Pout
        defm    $01, "F", $01, "R ", $00

        ld      e,(iy+6)
        res     7,e
        ld      d,$00
        ld      hl,L_EF09
        add     hl,de
.L_EF5C
        ld      a,(hl)
        push    af
        inc     hl
        inc     d
        and     $7F
        oz      Os_out
        pop     af
        bit     7,a
        jr      z,L_EF5C
        ld      a,d
        add     a,$05
        ld      (iy-84),a
        oz      Os_Pout
        defm    "ing ", $01, "F", $01, "R", $00

.L_EF7B
        ld      bc,$0000
        jr      L_EF8E
.L_EF80
        ld      (iy+6),a
        bit     6,(iy-70)
        ret     nz
        call    L_EFBB
        ld      bc,$001E
.L_EF8E
        oz      Os_ust
        ret
.L_EF91
        bit     2,(iy-72)
        res     2,(iy-72)
        ret     nz
        call    L_D7AA
        jr      c,L_EFC4
        bit     7,(ix+3)
        jr      nz,L_EFC4
        call    L_EEDD
        ld      a,$20
        call    L_BB73
        ld      e,(iy-34)
        ld      a,(iy-84)
        ld      (iy-84),e
        sub     e
        jp      nc,L_C5EA
        ret
.L_EFBB
        call    L_EF7B
        call    L_EF2A
        jr      z,L_EFC4
        ret
.L_EFC4
        ld      a,(iy-84)
        or      a
        ret     z
        push    af
        call    L_EEDD
        ld      (iy-84),$00
        pop     af
        jp      L_C5EA
.L_EFD5
        ld      a,$28
        ld      b,$00
        call    L_EEE4
.L_EFDC
        oz      Os_Pout
        defm    $01, "2C", $FD, $00

        ret
.L_EFE5
        ld      a,$0C
        jr      L_F020
.L_EFE9
        ld      a,$07
        oz      Os_out
        scf
        ret
.L_EFEF
        push    af
        ld      a,$01
        oz      Os_out
        ld      a,$52
        oz      Os_out
        pop     af
        ret
.L_EFFA
        push    bc
        ld      c,$2D
        jr      L_F002
.L_EFFF
        push    bc
        ld      c,$2B
.L_F002
        push    af
        ld      a,$01
        oz      Os_out
        ld      a,$32
        oz      Os_out
        ld      a,c
        oz      Os_out
        ld      a,$43
        oz      Os_out
        pop     af
        pop     bc
        ret
.L_F015
        cp      $0D
        jr      nz,L_F020
        oz      GN_Nln
        ret
.L_F020
        oz      Os_out
        ret
.L_F023
        push    af
        ld      a, SC_BIT
        oz      Os_esc
        jr      c,L_F02D
        pop     af
        or      a
        ret
.L_F02D
        pop     af
        scf
        ret

.L_F03D
        ld      c,$00
.L_F03F
        ld      a,(hl)
        inc     hl
        or      a
        ret     z
        oz      Os_out
        inc     c
        jr      L_F03F
.L_F048
        push    bc
        push    de
        ld      b,$08
        ex      de,hl
        ld      hl,$0000
.L_F050
        add     hl,hl
        rla
        jr      nc,L_F055
        add     hl,de
.L_F055
        djnz    L_F050
        ld      a,h
        cp      $01
        ccf
        pop     de
        pop     bc
        ret
.L_F05E
        push    bc
        ld      b,$08
        ld      c,a
.L_F062
        add     hl,hl
        ld      a,h
        sub     c
        jr      c,L_F069
        inc     l
        ld      h,a
.L_F069
        djnz    L_F062
        ld      a,h
        ld      h,b
        pop     bc
        ret
.L_F06F
        ld      ($1D4F),hl
        ld      (iy-112),b
        ld      (iy-114),l
        ld      (iy-113),h
        set     7,(iy-77)
        res     7,(iy-44)
        ld      ($1D47),sp
        ld      hl,$1EAA
        ld      ($1D45),hl
        call    L_F0AF
        ld      a,c
        cp      $0F
        jp      nz,L_F1DB
        call    L_F309
        call    L_F9D2
.L_F09C
        ld      c,(iy-79)
        ld      hl,($1D4D)
        ld      b,(iy-124)
        ret
.L_F0A6
        call    L_F339
        ld      sp,($1D47)
        jr      L_F09C
.L_F0AF
        call    L_F0CA
.L_F0B2
        ld      a,c
        cp      $0D
        ret     nz
        ld      a,l
        cp      $2A
        ret     nz
        call    L_FD2E
        push    hl
        call    L_F0CA
        pop     hl
        call    L_F225
        call    L_FD0C
        jr      L_F0B2
.L_F0CA
        call    L_F0E5
.L_F0CD
        ld      a,c
        cp      $0D
        ret     nz
        ld      a,l
        cp      $1E
        ret     nz
        call    L_FD2E
        push    hl
        call    L_F0E5
        pop     hl
        call    L_F225
        call    L_FD0C
        jr      L_F0CD
.L_F0E5
        call    L_F103
.L_F0E8
        ld      a,c
        cp      $0D
        ret     nz
        ld      a,l
        cp      $23
        ret     c
        cp      $29
        ret     nc
        call    L_FD2E
        push    hl
        call    L_F103
        pop     hl
        call    L_F225
        call    L_FD0C
        jr      L_F0E8
.L_F103
        call    L_F122
.L_F106
        ld      a,c
        cp      $0D
        ret     nz
        ld      a,l
        cp      $20
        jr      z,L_F112
        cp      $21
        ret     nz
.L_F112
        call    L_FD2E
        push    hl
        call    L_F122
        pop     hl
        call    L_F225
        call    L_FD0C
        jr      L_F106
.L_F122
        call    L_F141
.L_F125
        ld      a,c
        cp      $0D
        ret     nz
        ld      a,l
        cp      $1F
        jr      z,L_F131
        cp      $22
        ret     nz
.L_F131
        call    L_FD2E
        push    hl
        call    L_F141
        pop     hl
        call    L_F225
        call    L_FD0C
        jr      L_F125
.L_F141
        call    L_F15F
.L_F144
        call    L_FD0C
        ld      a,c
        cp      $0D
        ret     nz
        ld      a,l
        cp      $29
        ret     nz
        call    L_FD2E
        push    hl
        call    L_F15F
        pop     hl
        call    L_F225
        call    L_FD0C
        jr      L_F144
.L_F15F
        call    L_FD0C
        ld      a,c
        cp      $0D
        jr      nz,L_F189
        ld      a,l
        cp      $20
        jr      z,L_F174
        cp      $21
        jr      z,L_F174
        cp      $1D
        jr      nz,L_F189
.L_F174
        call    L_FD2E
        push    hl
        call    L_F15F
        pop     hl
        ld      a,l
        cp      $20
        ret     z
        cp      $21
        jr      nz,L_F186
        ld      l,$2B
.L_F186
        jp      L_F225
.L_F189
        call    L_FD0C
        ld      a,c
        cp      $28
        jr      nz,L_F1A0
        call    L_FD2E
        call    L_F0AF
        call    L_FD2E
        ld      a,c
        cp      $29
        jr      nz,L_F1DB
        ret
.L_F1A0
        cp      $07
        jr      z,L_F1B4
        cp      $03
        jr      z,L_F1B4
        cp      $0E
        jr      z,L_F1B9
        cp      $08
        jr      z,L_F1B4
        cp      $05
        jr      nz,L_F1DB
.L_F1B4
        call    L_FD2E
        jr      L_F237
.L_F1B9
        call    L_FD2E
        ld      a,l
        and     $C0
        cp      $00
        jr      z,L_F221
        cp      $40
        jr      z,L_F20C
        push    hl
        call    L_FD2E
        ld      a,c
        cp      $28
        jr      nz,L_F1DB
        call    L_F1E0
        call    L_FD2E
        ld      a,c
        cp      $29
        jr      z,L_F220
.L_F1DB
        ld      a,$0A
        jp      L_F0A6
.L_F1E0
        ld      l,$00
        push    hl
.L_F1E3
        call    L_F1FE
        pop     hl
        inc     l
        push    hl
        call    L_FD0C
        ld      a,c
        cp      $2C
        jr      nz,L_F1F6
        call    L_FD2E
        jr      L_F1E3
.L_F1F6
        pop     hl
        ld      c,$01
        call    L_FD3F
        jr      L_F237
.L_F1FE
        call    L_FD0C
        ld      a,c
        cp      $04
        jp      nz,L_F0AF
        call    L_FD2E
        jr      L_F237
.L_F20C
        push    hl
        call    L_FD2E
        ld      a,c
        cp      $28
        jr      nz,L_F1DB
        call    L_F0AF
        call    L_FD2E
        ld      a,c
        cp      $29
        jr      nz,L_F1DB
.L_F220
        pop     hl
.L_F221
        ld      a,l
        and     $3F
        ld      l,a
.L_F225
        sla     l
        ld      e,l
        ld      d,$00
        ld      hl,L_F3CC
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        call    L_F3A3
        call    c,L_F339
.L_F237
        exx
        ex      de,hl
        ld      c,(iy-79)
        ld      b,$00
        ld      hl,L_F375
        add     hl,bc
        ld      a,c
        ld      c,(hl)
        ld      hl,($1D45)
        push    hl
        sbc     hl,bc
        ld      ($1D45),hl
        ld      bc,$1DAA
        sbc     hl,bc
        add     hl,bc
        jp      m,L_F27B
        jr      z,L_F27B
        ld      hl,L_F273
        ex      (sp),hl
        dec     hl
        push    hl
        ld      c,a
        ld      b,$00
        ld      hl,L_F291
        add     hl,bc
        ld      c,(hl)
        sla     c
        ld      hl,L_F281
        add     hl,bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        push    bc
        pop     hl
        ex      (sp),hl
        ret
.L_F273
        ld      hl,($1D45)
        ld      a,(iy-79)
        ld      (hl),a
        ret
.L_F27B
        pop     hl
.L_F27C
        ld      a,$03
        jp      L_F0A6

.L_F281
        defw    L_F29C
        defw    L_F2BE
        defw    L_F2C2
        defw    L_F2C6
        defw    L_F2A1
        defw    L_F2D4
        defw    L_F2F1
        defw    L_F2A5

.L_F291
        defb    $00,$00,$01,$02,$03,$00,$02,$05
        defb    $04,$06,$07
.L_F29C
        ld      a,($1D4D)
        ld      (hl),a
        ret
.L_F2A1
        ld      c,$04
        jr      L_F2C8
.L_F2A5
        ld      (iy-79),$08
        push    hl
        ex      de,hl
        exx
        fpp     Fp_int
        pop     ix
        ld      (ix-1),l
        ld      (ix+0),h
        exx
        ld      (ix-3),l
        ld      (ix-2),h
        ret
.L_F2BE
        ld      c,$05
        jr      L_F2C8
.L_F2C2
        ld      c,$03
        jr      L_F2C8
.L_F2C6
        ld      c,$07
.L_F2C8
        ld      de,($1D4D)
        ld      b,$00
        ex      de,hl
        add     hl,bc
        dec     hl
        lddr
        ret
.L_F2D4
        ld      (iy-79),$02
        dec     hl
        dec     hl
        dec     hl
        dec     hl
.L_F2DC
        ld      de,($1D96)
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      de,($1D98)
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      a,($1D9A)
        ld      (hl),a
        ret
.L_F2F1
        ld      (iy-79),$02
        push    hl
        pop     ix
        ld      (ix-4),e
        ld      (ix-3),d
        exx
        ld      (ix-2),l
        ld      (ix-1),h
        ld      (ix+0),c
        ret
.L_F309
        ld      hl,($1D45)
        call    L_F344
        ld      a,c
        ld      c,b
        ld      b,$00
        ld      hl,($1D45)
        add     hl,bc
        ld      ($1D45),hl
        ld      c,a
        ret
.L_F31C
        call    L_F325
        ret     c
        call    L_F380
        pop     de
        ret
.L_F325
        ld      e,a
        ld      hl,($1D45)
        inc     hl
        ld      a,(hl)
        cp      e
        jr      z,L_F336
        jr      c,L_F336
        sub     e
        call    L_F341
        scf
        ret
.L_F336
        or      a
        ld      a,$12
.L_F339
        ld      (iy-79),$00
        ld      ($1D4D),a
        ret
.L_F341
        call    L_F38D
.L_F344
        ld      c,(hl)
        ld      (iy-79),c
        inc     hl
        ld      ($1D4D),hl
        push    hl
        ld      e,c
        ld      d,$00
        ld      hl,L_F375
        add     hl,de
        ld      b,(hl)
        ld      hl,L_F291
        add     hl,de
        ld      e,(hl)
        sla     e
        ld      hl,L_F366
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ex      (sp),hl
        ret

.L_F366
        defw    L_F370
        defw    L_F374
        defw    L_F374
        defw    L_F374
        defw    L_F374
.L_F370
        ld      a,(hl)
        ld      ($1D4D),a
.L_F374
        ret


.L_F375
        defb    $02,$02,$06,$04,$08,$02,$04,$06
        defb    $05,$06,$05
.L_F380
        ld      hl,($1D45)
        inc     hl
        ld      a,(hl)
        inc     a
.L_F386
        call    L_F38D
        ld      ($1D45),hl
        ret
.L_F38D
        ld      b,a
        ld      hl,($1D45)
        or      a
        ret     z
        ld      d,$00
.L_F395
        ld      e,(hl)
        ld      ix,L_F375
        add     ix,de
        ld      e,(ix+0)
        add     hl,de
        djnz    L_F395
        ret
.L_F3A3
        ld      ($1D55),sp
        ex      de,hl
        call    L_9223
        or      a
        ret
.L_F3AD
        ld      sp,($1D55)
        ld      hl,L_F3C4
        ld      bc,$0004
        cpir
        ld      a,$02
        scf
        ret     nz
        ld      hl,L_F3C8
        add     hl,bc
        ld      a,(hl)
        scf
        ret


.L_F3C4
        defb    $46,$48,$49,$4B
.L_F3C8
        defb    $24,$0D,$07,$06

.L_F3CC
        defw    L_F424
        defw    L_F42A
        defw    L_F430
        defw    L_F436
        defw    L_F43C
        defw    L_F47F
        defw    L_F487
        defw    L_F48D
        defw    L_F4B0
        defw    L_F4BC
        defw    L_F4C2
        defw    L_F4C8
        defw    L_F4EA
        defw    L_F523
        defw    L_F529
        defw    L_F52F
        defw    L_F535
        defw    L_F5F7
        defw    L_F5FA
        defw    L_F64A
        defw    L_F653
        defw    L_F65A
        defw    L_F660
        defw    L_F671
        defw    L_F677
        defw    L_F67D
        defw    L_F683
        defw    L_F6B8
        defw    L_F6BE
        defw    L_F6CF
        defw    L_F6D9
        defw    L_F6F6
        defw    L_F6FC
        defw    L_F702
        defw    L_F712
        defw    L_F718
        defw    L_F71F
        defw    L_F726
        defw    L_F72D
        defw    L_F739
        defw    L_F740
        defw    L_F747
        defw    L_F74D
        defw    L_F75F
.L_F424
        call    L_FAC7
.L_F427
        fpp     Fp_abs
        ret
.L_F42A
        call    L_FAC7
        fpp     Fp_acs
        ret
.L_F430
        call    L_FAC7
        fpp     Fp_asn
        ret
.L_F436
        call    L_FAC7
        fpp     Fp_atn
        ret
.L_F43C
        xor     a
        call    L_F31C
        call    L_F9BE
        jr      c,L_F464
        call    L_FE8A
        call    L_FBFE
        jp      c,L_F380
        ld      (iy-30),c
        ld      (iy-29),b
        ld      ix,L_F46A
        ld      c,$01
        call    L_FADF
        ccf
        ret     nc
        ld      a,$12
        jp      L_F339
.L_F464
        call    L_FC14
        jp      L_F380
.L_F46A
        ld      a,(iy-30)
        or      a
        jr      nz,L_F473
        dec     (iy-29)
.L_F473
        dec     (iy-30)
        ld      a,(iy-30)
        or      (iy-29)
        ret     nz
        scf
        ret
.L_F47F
        ld      l,(iy-110)
        ld      h,$00
        jp      L_F666
.L_F487
        call    L_FAC7
        fpp     Fp_cos
        ret
.L_F48D
        xor     a
        ld      (iy-30),a
        ld      (iy-29),a
        ld      ix,L_F4A4
        call    L_FADD
        ld      l,(iy-30)
        ld      h,(iy-29)
        jp      L_F667
.L_F4A4
        ccf
        ret     nc
        ccf
        ret     pe
        inc     (iy-30)
        ret     nz
        inc     (iy-29)
        ret
.L_F4B0
        call    L_F924
        ld      a,c
        and     $1F
        ld      l,a
        ld      h,$00
        jp      L_F667
.L_F4BC
        call    L_FAC7
        fpp     Fp_deg
        ret
.L_F4C2
        call    L_FAC7
        fpp     Fp_exp
        ret
.L_F4C8
        xor     a
        call    L_F31C
        call    L_F9BE
        ld      a,$02
        jr      c,L_F4DE
        call    L_FE8A
        fpp     Fp_tst
        add     a,a
        ld      a,$01
        jr      nz,L_F4DE
        inc     a
.L_F4DE
        call    L_F31C
        call    L_F9BE
        ld      (iy-79),c
        jp      L_F380
.L_F4EA
        xor     a
        call    L_F31C
        call    L_F9BE
        jr      c,L_F51D
        call    L_FE8A
        call    L_FC0C
        jp      c,L_F380
        dec     a
        ld      (iy-42),a
        ld      a,$01
        call    L_F31C
        call    L_F9BE
        jr      c,L_F51D
        call    L_FE8A
        call    L_FBFE
        jp      c,L_F380
        dec     bc
        ld      a,(iy-42)
        call    L_FB68
        jp      L_F380
.L_F51D
        call    L_FC14
        jp      L_F380
.L_F523
        call    L_FAC7
        fpp     Fp_int
        ret
.L_F529
        call    L_FAC7
        fpp     Fp_ln
        ret
.L_F52F
        call    L_FAC7
        fpp     Fp_log
        ret
.L_F535
        xor     a
        ld      (iy-28),a
        ld      (iy-27),a
        call    L_F31C
        call    L_F9D2
        ld      (iy-42),c
        jr      nc,L_F55B
        ld      a,c
        cp      $04
        jr      z,L_F5BC
        cp      $00
        jr      z,L_F5BC
        ld      (iy-120),l
        ld      (iy-119),h
        ld      (iy-118),b
        jr      L_F565
.L_F55B
        call    L_FE8A
        ld      ix,$1DA0
        call    L_FEA0
.L_F565
        ld      a,$01
        call    L_F31C
        ld      a,c
        cp      $04
        jr      nz,L_F5BC
        call    L_FB35
        jp      c,L_F380
.L_F575
        call    L_F9D2
        ld      (iy-34),c
        jr      nc,L_F588
        ld      (iy-123),l
        ld      (iy-122),h
        ld      (iy-121),b
        jr      L_F592
.L_F588
        call    L_FE8A
        ld      ix,$1DA0
        call    L_FEB6
.L_F592
        ld      a,(iy-42)
        cp      (iy-34)
        jr      nz,L_F5AF
        cp      $02
        jr      z,L_F5AA
        cp      $08
        jr      z,L_F5A7
        call    L_F7DF
        jr      L_F5AD
.L_F5A7
        ld      bc,$0000
.L_F5AA
        fpp     Fp_cmp
        add     a,a
.L_F5AD
        jr      z,L_F5C4
.L_F5AF
        inc     (iy-28)
        jr      nz,L_F5B7
        inc     (iy-27)
.L_F5B7
        call    L_FB55
        jr      nc,L_F575
.L_F5BC
        ld      a,$0F
        call    L_F339
        jp      L_F380
.L_F5C4
        ld      a,$02
        call    L_F31C
        ld      a,c
        cp      $04
        jr      nz,L_F5BC
        call    L_FB35
        jp      c,L_F380
.L_F5D4
        ld      a,(iy-28)
        or      (iy-27)
        jr      z,L_F5EE
        ld      a,(iy-28)
        jr      nz,L_F5E4
        dec     (iy-27)
.L_F5E4
        dec     (iy-28)
        call    L_FB55
        jr      nc,L_F5D4
        jr      L_F5BC
.L_F5EE
        call    L_F9D2
        ld      (iy-79),c
        jp      L_F380
.L_F5F7
        or      a
        jr      L_F5FB
.L_F5FA
        scf
.L_F5FB
        rr      (iy-30)
        set     7,(iy-29)
        fpp     Fp_zer
        ld      ix,$1DA0
        call    L_FEA0
        ld      ix,L_F61F
        call    L_FADD
        ld      ix,$1DA0
        call    L_FE8E
        ld      (iy-79),$09
        ret
.L_F61F
        ccf
        ret     nc
        ccf
        ret     pe
        call    L_FE8A
        bit     7,(iy-29)
        jr      z,L_F632
        res     7,(iy-29)
        jr      L_F641
.L_F632
        ld      ix,$1DA0
        call    L_FEB6
        fpp     Fp_cmp
        add     a,a
        rra
        xor     (iy-30)
        ret     m
.L_F641
        ld      ix,$1DA0
        call    L_FEA0
        or      a
        ret
.L_F64A
        call    L_F924
        ld      l,b
        ld      h,$00
        jp      L_F667
.L_F653
        fpp     Fp_pi
        ld      (iy-79),$09
        ret
.L_F65A
        call    L_FAC7
        fpp     Fp_rad
        ret
.L_F660
        ld      l,(iy-109)
        ld      h,(iy-108)
.L_F666
        inc     hl
.L_F667
        exx
        ld      hl,$0000
        ld      c,l
        ld      (iy-79),$09
        ret
.L_F671
        call    L_FAC7
        fpp     Fp_sgn
        ret
.L_F677
        call    L_FAC7
        fpp     Fp_sin
        ret
.L_F67D
        call    L_FAC7
        fpp     Fp_sqr
        ret
.L_F683
        fpp     Fp_zer
        ld      ix,$1DA0
        call    L_FEA0
        ld      ix,L_F69F
        call    L_FADD
        ld      ix,$1DA0
        call    L_FE8E
        ld      (iy-79),$09
        ret
.L_F69F
        ccf
        ret     nc
        ccf
        ret     pe
        call    L_FE8A
        ld      ix,$1DA0
        call    L_FEB6
        fpp     Fp_add
        ld      ix,$1DA0
        call    L_FEA0
        or      a
        ret
.L_F6B8
        call    L_FAC7
        fpp     Fp_tan
        ret
.L_F6BE
        call    L_F924
        ld      bc,$0000
        ex      de,hl
        ld      de,$0064
        oz      Gn_d24
        ex      de,hl
        jp      L_F667
.L_F6CF
        call    L_FAC7
        call    L_F6EE
        xor     $01
        jr      L_F6E8
.L_F6D9
        call    L_F93F
        call    L_F6EE
        push    af
        call    L_FEDA
        call    L_F6EE
        pop     bc
        and     b
.L_F6E8
        ld      l,a
        ld      h,$00
        jp      L_F667
.L_F6EE
        fpp     Fp_tst
        add     a,a
        ld      a,$00
        ret     z
        inc     a
        ret
.L_F6F6
        call    L_F93F
        fpp     Fp_mul
        ret
.L_F6FC
        call    L_F93F
        fpp     Fp_add
        ret
.L_F702
        call    L_F93F
        jr      nz,L_F70F
        cp      $0A
        jr      nz,L_F70F
        ld      (iy-79),$09
.L_F70F
        fpp     Fp_sub
        ret
.L_F712
        call    L_F93F
        fpp     Fp_div
        ret
.L_F718
        call    L_F770
.L_F71B
        jr      c,L_F732
        jr      L_F769
.L_F71F
        call    L_F770
        jr      z,L_F732
        jr      L_F71B
.L_F726
        call    L_F770
        jr      z,L_F769
        jr      L_F732
.L_F72D
        call    L_F770
        jr      nz,L_F769
.L_F732
        ld      (iy-79),$09
        fpp     Fp_one
        ret
.L_F739
        call    L_F770
        jr      z,L_F769
        jr      L_F743
.L_F740
        call    L_F770
.L_F743
        jr      nc,L_F732
        jr      L_F769
.L_F747
        call    L_F93F
        fpp     Fp_pwr
        ret
.L_F74D
        call    L_F93F
        call    L_F6EE
        push    af
        call    L_FEDA
        call    L_F6EE
        pop     bc
        or      b
        jp      L_F6E8
.L_F75F
        call    L_FAC7
        fpp     Fp_neg
        ret
.L_F765
        call    L_F97A
        pop     de
.L_F769
        ld      (iy-79),$09
        fpp     Fp_zer
        ret
.L_F770
        ld      a,$01
        call    L_F97F
        jp      pe,L_F765
        call    L_F909
        jr      nc,L_F765
        ld      (iy-36),c
        ld      (iy-123),l
        ld      (iy-122),h
        ld      (iy-121),b
        ld      ix,$1DA5
        call    L_FEC8
        xor     a
        call    L_F97F
        jp      pe,L_F765
        ld      (iy-120),l
        ld      (iy-119),h
        ld      (iy-118),b
        call    L_F909
        jr      nc,L_F765
        ld      a,c
        cp      (iy-36)
        jr      z,L_F7BC
        cp      $0C
        jr      z,L_F7B9
        ld      a,(iy-36)
        cp      $0C
        jr      nz,L_F765
        ld      (iy-36),c
.L_F7B9
        ld      a,(iy-36)
.L_F7BC
        cp      $09
        jr      z,L_F7C8
        cp      $0C
        jr      z,L_F7C8
        cp      $0A
        jr      nz,L_F7DA
.L_F7C8
        exx
        push    de
        call    L_F97A
        pop     de
        exx
        ld      ix,$1DA5
        call    L_FE8E
        fpp     Fp_cmp
        add     a,a
        ret
.L_F7DA
        push    af
        call    L_F97A
        pop     af
.L_F7DF
        ld      e,(iy-123)
        ld      d,(iy-122)
        ld      b,(iy-121)
        ld      l,(iy-120)
        ld      h,(iy-119)
        ld      c,(iy-118)
        call    L_F8B4
        ld      (iy-38),l
        ld      (iy-37),h
        call    L_F8CB
        jr      L_F80A
.L_F7FF
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(hl)
        call    L_A8BB
.L_F80A
        ld      (iy-34),e
        ld      (iy-33),d
.L_F810
        ld      (iy-36),l
        ld      (iy-35),h
        push    de
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(de)
        ex      de,hl
        call    L_A8BB
        ex      de,hl
        ld      (iy-34),e
        ld      (iy-33),d
        pop     de
.L_F82B
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(de)
        call    L_EE09
        ld      (iy-18),a
        call    L_F8E8
        cp      $15
        jr      z,L_F7FF
        call    L_EE09
        ld      (iy-16),a
        cp      (iy-18)
        jr      z,L_F897
        push    de
        call    L_F8CB
        pop     de
        call    L_F8E2
        jr      z,L_F891
        ld      a,(iy-16)
        cp      $16
        jr      z,L_F897
        ld      e,(iy-34)
        ld      d,(iy-33)
        ld      l,(iy-36)
        ld      h,(iy-35)
        ld      a,h
        cp      (iy-37)
        jr      nz,L_F810
        ld      a,l
        cp      (iy-38)
        jr      nz,L_F810
.L_F874
        ld      a,(iy-18)
        push    bc
        ld      b,(iy-16)
        ld      c,a
        and     b
        cp      $C0
        ld      a,c
        jr      c,L_F88E
        res     5,a
        add     a,$3A
        push    af
        res     5,b
        ld      a,b
        add     a,$3A
        ld      b,a
        pop     af
.L_F88E
        cp      b
        pop     bc
        ret
.L_F891
        call    L_F8DD
        jr      nz,L_F874
        ret
.L_F897
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(de)
        ex      de,hl
        call    L_A8BB
        ex      de,hl
        call    L_F8DD
        push    af
        ld      a,(hl)
        call    L_A8BB
        pop     af
        jp      nz,L_F82B
        ret
.L_F8B1
        call    L_A8BB
.L_F8B4
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(hl)
        call    L_CE2A
        jr      c,L_F8B1
        cp      $20
        jr      z,L_F8B1
        ret
.L_F8C6
        ex      de,hl
        call    L_A8BB
        ex      de,hl
.L_F8CB
        ld      a,b
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(de)
        call    L_CE2A
        jr      c,L_F8C6
        cp      $20
        jr      z,L_F8C6
        ret
.L_F8DD
        push    hl
        call    L_F8B4
        pop     hl
.L_F8E2
        cp      $00
        ret     z
        cp      $14
        ret
.L_F8E8
        ld      a,c
        cp      (iy-111)
        call    nz,L_D887
        ld      a,(hl)
        cp      $5E
        ret     nz
        inc     hl
        ld      a,(hl)
        cp      $5E
        ret     z
        cp      $3F
        jr      z,L_F903
        cp      $23
        jr      z,L_F906
        dec     hl
        ld      a,(hl)
        ret
.L_F903
        ld      a,$16
        ret
.L_F906
        ld      a,$15
        ret
.L_F909
        ld      a,c
        cp      $0C
        jr      z,L_F920
        cp      $0A
        jr      z,L_F920
        cp      $09
        jr      z,L_F920
        cp      $05
        jr      z,L_F91E
        cp      $06
        jr      nz,L_F922
.L_F91E
        ld      c,$0B
.L_F920
        scf
        ret
.L_F922
        or      a
        ret
.L_F924
        call    L_F309
        call    L_F9D2
        ld      a,c
        cp      $08
        jr      nz,L_F938
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      a,(hl)
        oz      Gn_die
        ret     nc
.L_F938
        ld      a,$16
        call    L_F339
        pop     de
        ret
.L_F93F
        ld      a,$01
        call    L_F97F
        jr      c,L_F979
        push    bc
        ld      ix,$1DA5
        call    L_FEC8
        xor     a
        call    L_F97F
        pop     hl
        jr      c,L_F979
        ld      h,c
        push    hl
        exx
        push    de
        call    L_F97A
        pop     de
        exx
        pop     hl
        ld      a,l
        cp      h
        push    af
        cp      $0A
        jr      z,L_F96D
        ld      a,h
        cp      $08
        jr      z,L_F96D
        ld      a,$09
.L_F96D
        ld      (iy-79),a
        ld      ix,$1DA5
        call    L_FE8E
        pop     af
        ret
.L_F979
        pop     de
.L_F97A
        ld      a,$02
        jp      L_F386
.L_F97F
        call    L_F341
        call    L_F9D2
        jr      c,L_F9A4
        jp      pe,L_F99B
        ld      ix,($1D4D)
        call    L_FEB6
        ld      c,$09
.L_F993
        or      a
.L_F994
        push    af
        ex      (sp),hl
        res     2,l
        ex      (sp),hl
        pop     af
        ret
.L_F99B
        fpp     Fp_zer
        call    L_FEDA
        ld      c,$0C
        jr      L_F993
.L_F9A4
        ld      a,c
        cp      $08
        jr      nz,L_F9B2
        call    L_FEB2
        ld      b,$00
        ld      c,$0A
        jr      L_F993
.L_F9B2
        cp      $00
        scf
        jr      nz,L_F994
.L_F9B7
        push    af
        ex      (sp),hl
        set     2,l
        ex      (sp),hl
        pop     af
        ret
.L_F9BE
        call    L_F9D2
        ret     nc
        ld      a,c
        cp      $08
        jr      z,L_F9CB
        cp      $04
        scf
        ret     nz
.L_F9CB
        ld      a,$08
        call    L_F339
        scf
        ret
.L_F9D2
        ld      hl,($1D4D)
        ld      a,c
        cp      $03
        jr      z,L_F9FB
        cp      $02
        jr      z,L_F993
        cp      $05
        jr      z,L_F9EB
        cp      $08
        jr      nz,L_F9F7
        ld      b,(iy-124)
        jr      L_F9F7
.L_F9EB
        ld      e,(iy-114)
        ld      d,(iy-113)
        ld      h,$00
        add     hl,de
        ld      b,(iy-112)
.L_F9F7
        scf
        jp      L_F994
.L_F9FB
        ld      a,(iy-124)
        cp      (iy-111)
        call    nz,L_D887
.L_FA04
        call    L_B4F9
.L_FA07
        cp      $80
        jr      nc,L_FA81
        call    L_D7AD
        jr      c,L_FA85
        ld      a,(ix+3)
        bit     7,a
        jr      nz,L_FA6B
        bit     4,a
        jr      nz,L_FA8B
        and     $C0
        cp      $C0
        jr      z,L_FA50
        cp      $40
        jr      nz,L_FA5F
.L_FA25
        call    L_B518
        ld      a,(ix+4)
        or      a
        jr      nz,L_FA74
        push   ix
        pop     hl
        ld      bc,$0005
        add     hl,bc
        call    L_B4F9
        cp      (iy-110)
        jr      nz,L_FA07
        ld      e,a
        ld      a,c
        cp      (iy-109)
        ld      a,e
        jr      nz,L_FA07
        ld      a,b
        cp      (iy-108)
        ld      a,e
        jr      nz,L_FA07
        ld      a,$0C
        jr      L_FA94
.L_FA50
        fpp     Fp_zer
        ld      ix,$1D9B
        ld      ($1D4D),ix
        call    L_FEA0
        jr      L_FA62
.L_FA5F
        call    L_FAB1
.L_FA62
        ld      c,$02
        or      a
.L_FA65
        ld      (iy-79),c
        jp      L_F994
.L_FA6B
        call    L_C9B8
        jr      c,L_FA85
        ld      a,$04
        jr      L_FAA2
.L_FA74
        cp      $02
        jr      nz,L_FA9D
        ld      a,$05
        call    L_FAB3
        ld      c,$08
        jr      L_FAAE
.L_FA81
        ld      a,$0B
        jr      L_FA94
.L_FA85
        call    L_FA50
        jp      L_F9B7
.L_FA8B
        ld      a,(ix+4)
        cp      $0C
        jr      z,L_FA94
        ld      a,$13
.L_FA94
        ld      c,$00
        call    L_F339
        scf
        jp      L_F994
.L_FA9D
        ld      a,(ix+5)
        add     a,$0A
.L_FAA2
        push   ix
        pop     hl
        ld      e,a
        ld      d,$00
        add     hl,de
        ld      c,$06
        ld      b,(iy-125)
.L_FAAE
        scf
        jr      L_FA65
.L_FAB1
        ld      a,$04
.L_FAB3
        add     a,(iy-127)
        ld      l,a
        ld      a,(iy-126)
        adc     a,$00
        ld      h,a
        ld      ($1D4D),hl
        ld      b,(iy-125)
        ld      (iy-124),b
        ret
.L_FAC7
        call    L_F309
        call    L_F9D2
        jr      nc,L_FAD1
        pop     de
        ret
.L_FAD1
        ld      ix,($1D4D)
        call    L_FE8E
        ld      (iy-79),$09
        ret
.L_FADD
        ld      c,$00
.L_FADF
        push   ix
        ld      (iy-38),c
        set     7,(iy-40)
.L_FAE8
        ld      a,(iy-38)
        call    L_F325
.L_FAEE
        call    L_F9D2
        push    af
        ld      a,c
        cp      $04
        jr      nz,L_FB03
        pop     af
        call    L_FB35
        jr      c,L_FB2D
        res     7,(iy-40)
        jr      L_FAEE
.L_FB03
        pop     af
        pop     ix
        push   ix
        call    L_B8B4
        jr      c,L_FB2D
        bit     7,(iy-40)
        jr      nz,L_FB1C
        call    L_FB55
        jr      nc,L_FAEE
        set     7,(iy-40)
.L_FB1C
        inc     (iy-38)
        ld      hl,($1D45)
        inc     hl
        ld      a,(iy-38)
        cp      (hl)
        jr      c,L_FAE8
        ld      (iy-79),$07
.L_FB2D
        pop     ix
        push    af
        call    L_F380
        pop     af
        ret
.L_FB35
        ld      de,$FFC6
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
        ld      hl,($1D4D)
        call    L_FB87
        inc     hl
        call    L_FB87
        call    L_FBBD
        jr      c,L_FB5A
        ld      a,$0E
        call    L_F339
        scf
        ret
.L_FB55
        call    L_FB93
        ccf
        ret     c
.L_FB5A
        ld      a,(iy-61)
        ld      c,(iy-60)
        ld      b,(iy-59)
        call    L_FB68
        or      a
        ret
.L_FB68
        ld      (iy+35),a
        ld      (iy+36),c
        ld      (iy+37),b
        ld      c,$03
        ld      (iy-79),c
.L_FB76
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        ld      ($1D4D),hl
        ld      a,(iy-111)
        ld      (iy-124),a
        ret
.L_FB87
        ld      b,$03
.L_FB89
        ld      a,(hl)
        ld      (ix+0),a
        inc     ix
        inc     hl
        djnz    L_FB89
        ret
.L_FB93
        ld      de,$FFC3
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
.L_FB9D
        inc     (ix+0)
        ld      a,(ix+0)
        cp      (ix+6)
        ret     c
        scf
        ret     z
        inc     (ix+1)
        jr      nz,L_FBB1
        inc     (ix+2)
.L_FBB1
        call    L_FBE1
        ret     nc
        ld      a,(ix+3)
        ld      (ix+0),a
        scf
        ret
.L_FBBD
        ld      de,$FFC3
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
.L_FBC7
        ld      a,(ix+3)
        ld      (ix+0),a
        ld      a,(ix+4)
        ld      (ix+1),a
        ld      a,(ix+5)
        ld      (ix+2),a
        ld      a,(ix+6)
        cp      (ix+0)
        ccf
        ret     nc
.L_FBE1
        ld      a,(ix+8)
        cp      (ix+2)
        ccf
        ret     nc
        ret     nz
        ld      a,(ix+7)
        cp      (ix+1)
        ccf
        ret
.L_FBF2
        ld      de,$FFC3
        push    iy
        pop     hl
        add     hl,de
        push    hl
        pop     ix
        jr      L_FBE1
.L_FBFE
        fpp     Fp_fix
        ld      a,h
        or      l
        jr      nz,L_FC13
        exx
        ld      c,l
        ld      b,h
        ld      a,c
        or      b
        jr      z,L_FC13
        ret
.L_FC0C
        call    L_FBFE
        ret     c
        ld      a,c
        or      a
        ret     nz
.L_FC13
        scf
.L_FC14
        ld      a,$10
        jp      L_F339

.L_FC19
        defm    "@", $00
        defm    $00
        defm    "AB", $D3, "A", $0D, $01, "AC", $D3, "B", $00
        defm    $00
        defm    "AS", $CE, "C", $19, $07, "AT", $CE, $84, $00
        defm    $00
        defm    "CHOOS", $C5, $05, "B", $13, "CO", $CC, "F", $00
        defm    $00
        defm    "CO", $D3, $87, "6(COUN", $D4, "H<", $00
        defm    "DA", $D9, "I", $00
        defm    $00
        defm    "DE", $C7, "JU.EX", $D0, $8B, "M", $00
        defm    "I", $C6, $8C, $00
        defm    $00
        defm    "INDE", $D8, "M[HIN", $D4, "N", $00
        defm    $00
        defm    "L", $CE, "O", $8E, '"', "LO", $C7, $90, "o", $00
        defm    "LOOKU", $D0, $91, $00
        defm    $00
        defm    "MA", $D8, $92, $88, "fMI", $CE, "S", $00
        defm    $00
        defm    "MONT", $C8, $14, $00
        defm    "{P", $C9, "U", $00
        defm    $83, "RA", $C4, $16, $A6, "uRO", $D7, "W", $00
        defm    $00
        defm    "SG", $CE, "X", $A0, $94, "SI", $CE, "Y", $00
        defm    $00
        defm    "SQ", $D2, $9A, $AC, $9A, "SU", $CD, "[", $B2, $00
        defm    "TA", $CE, "\", $00
        defm    $00
        defm    "YEA"

.L_FCD0
        defb    $D2,$1D,$00,$00,$A1,$1E,$00,$01
        defb    $A6,$1F,$0D,$05,$AA,$20,$00,$00
        defb    $AB,$21,$15,$09,$AD,$22,$19,$00
        defb    $AF,$23,$00,$00,$BC,$24,$2F,$11
        defb    $3C,$BD,$25,$00,$00,$3C,$BE,$26
        defb    $2B,$22,$BD,$27,$00,$00,$BE,$28
        defb    $34,$27,$3E,$BD,$29,$38,$00,$DE
        defb    $2A,$00,$00,$FC
.L_FD0C
        ld      hl,$0000
        add     hl,sp
        ld      de,($1D51)
        or      a
        sbc     hl,de
        jp      c,L_F27C
        ld      c,(iy-77)
        bit     7,c
        jr      z,L_FD39
        call    L_FD2E
        ld      (iy-77),c
        ld      (iy-76),l
        ld      (iy-75),h
        ret
.L_FD2E
        ld      c,(iy-77)
        bit     7,c
        jr      nz,L_FD4C
        set     7,(iy-77)
.L_FD39
        ld      l,(iy-76)
        ld      h,(iy-75)
.L_FD3F
        ld      (iy-79),c
        ld      ($1D4D),hl
        ld      a,(iy-112)
        ld      (iy-124),a
        ret
.L_FD4C
        ld      hl,($1D4F)
        ld      a,(iy-112)
        cp      (iy-111)
        call    nz,L_D887
        call    L_FD64
        jp      c,L_F0A6
        ld      ($1D4F),de
        jr      L_FD3F
.L_FD64
        ld      a,(hl)
        or      a
        jp      z,L_FDF6
        call    L_EE1B
        jr      c,L_FD92
        call    L_EE10
        jr      c,L_FDB8
        cp      $2E
        jr      z,L_FDB8
        call    L_FE32
        jp      c,L_FDFA
        cp      $14
        jr      z,L_FDD6
        ld      de,L_FCD0
        ld      a,$1D
        call    L_FE39
        ld      c,$0D
        ret     nc
        ld      e,(hl)
        ld      c,e
        inc     hl
        ex      de,hl
        or      a
        ret
.L_FD92
        ld      de,$FC18
        ld      a,$60
        call    L_FE39
        jr      c,L_FDF2
        push    hl
        ld      a,l
        and     $3F
        ld      b,$04
        ld      hl,L_FDB5
.L_FDA5
        dec     b
        jr      z,L_FDB0
        cp      (hl)
        inc     hl
        jr      nz,L_FDA5
        set     7,(iy-44)
.L_FDB0
        pop     hl
        ld      c,$0E
        or      a
        ret


.L_FDB5
        defb    $0C,$16,$05
.L_FDB8
        push    hl
        ld      hl,$FFFE
        add     hl,sp
        ld      ($1D55),hl
        pop     hl
        push    hl
        fpp     Fp_val
        exx
        ld      ($1D96),hl
        exx
        ld      ($1D98),hl
        ld      a,c
        ld      ($1D9A),a
        pop     hl
        jr      c,L_FE10
        ld      c,$07
        ret
.L_FDD6
        ld      e,l
        ld      d,h
        inc     de
.L_FDD9
        inc     hl
        ld      a,(hl)
        or      a
        jr      z,L_FDF2
        cp      $14
        jr      nz,L_FDD9
        inc     hl
        push    hl
        ex      de,hl
        ld      e,(iy-114)
        ld      d,(iy-113)
        sbc     hl,de
        pop     de
        ld      c,$05
        or      a
        ret
.L_FDF2
        ld      a,$0A
.L_FDF4
        scf
        ret
.L_FDF6
        ld      c,$0F
        or      a
        ret
.L_FDFA
        inc     hl
        push    hl
        inc     hl
        inc     hl
        inc     hl
        ld      c,$03
        call    L_FE31
        jr      nc,L_FE0C
        ld      c,$04
        inc     hl
        inc     hl
        inc     hl
        inc     hl
.L_FE0C
        ex      de,hl
        pop     hl
        or      a
        ret
.L_FE10
        ld      (iy+38),$00
        push    hl
        ld      de,$0023
        push    iy
        pop     hl
        add     hl,de
        ex      (sp),hl
        pop     de
        push    de
        ld      a,$20
        ld      bc,$1E2E
        oz      Gn_gdt
        pop     de
        ld      a,$16
        jr      c,L_FDF4
        ex      de,hl
        ld      c,$08
        or      a
        ret
.L_FE31
        ld      a,(hl)
.L_FE32
        cp      $10
        ccf
        ret     nc
        cp      $14
        ret
.L_FE39
        push    hl
        push    de
        add     a,e
        ld      e,a
        jr      nc,L_FE40
        inc     d
.L_FE40
        push    de
        pop     ix
        inc     de
        inc     de
        inc     de
.L_FE46
        ld      a,(hl)
        or      a
        jr      z,L_FE5D
        inc     hl
        call    L_EE09
        ld      c,a
        ld      a,(de)
        and     $7F
        cp      c
        jr      z,L_FE64
        ld      a,(ix+1)
        jr      c,L_FE5D
        ld      a,(ix+2)
.L_FE5D
        pop     de
        pop     hl
        or      a
        jr      nz,L_FE39
        scf
        ret
.L_FE64
        ld      a,(de)
        inc     de
        or      a
        jp      p,L_FE46
        pop     de
        ex      (sp),hl
        pop     de
        ld      l,(ix+0)
        or      a
        ret
.L_FE72
        ld      hl,($1D4D)
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      ($1D96),de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      ($1D98),de
        ld      a,(hl)
        ld      ($1D9A),a
        ret
.L_FE8A
        ld      ix,($1D4D)
.L_FE8E
        exx
        ld      l,(ix+0)
        ld      h,(ix+1)
        exx
        ld      l,(ix+2)
        ld      h,(ix+3)
        ld      c,(ix+4)
        ret
.L_FEA0
        exx
        ld      (ix+0),l
        ld      (ix+1),h
        exx
        ld      (ix+2),l
        ld      (ix+3),h
        ld      (ix+4),c
        ret
.L_FEB2
        ld      ix,($1D4D)
.L_FEB6
        exx
        ld      e,(ix+0)
        ld      d,(ix+1)
        exx
        ld      e,(ix+2)
        ld      d,(ix+3)
        ld      b,(ix+4)
        ret
.L_FEC8
        exx
        ld      (ix+0),e
        ld      (ix+1),d
        exx
        ld      (ix+2),e
        ld      (ix+3),d
        ld      (ix+4),b
        ret
.L_FEDA
        exx
        ex      de,hl
        exx
        ex      de,hl
        ld      a,b
        ld      b,c
        ld      c,a
        ret
.L_FEE2
        pop     af
.L_FEE3
        ld      (iy+35),$25
        ld      (iy+36),$00
        ld      (iy-74),$01
        ret
.L_FEF0
        ld      c,a
        call    L_88E0
        ld      a,c
        push    iy
        pop     hl
        ld      de,$0023
        add     hl,de
        ld      d,$02
        and     $0F
        cp      $0F
        jr      nz,L_FF06
        res     1,d
.L_FF06
        ld      b,(iy-36)
        res     6,c
        bit     4,c
        jr      z,L_FF18
        ld      a,b
        sub     (iy+15)
        jr      c,L_FEE3
        jr      z,L_FEE3
        ld      b,a
.L_FF18
        bit     5,c
        jr      z,L_FF2F
        ld      a,b
        ld      e,(iy+14)
        sub     e
        jr      c,L_FEE3
        jr      z,L_FEE3
        ld      b,a
        push    de
        ld      a,e
        ld      de,$0016
        call    L_FF99
        pop     de
.L_FF2F
        ld      a,($1D99)
.L_FF32
        bit     7,a
        push    af
        bit     7,c
        jr      z,L_FF4A
        dec     b
        jr      z,L_FEE2
        bit     7,a
        res     7,a
        jr      z,L_FF4A
        dec     b
        jr      z,L_FEE2
        set     6,c
        ld      (hl),$28
        inc     hl
.L_FF4A
        bit     7,a
        jr      z,L_FF54
        dec     b
        jr      z,L_FEE2
        ld      (hl),$2D
        inc     hl
.L_FF54
        ld      a,b
        ld      e,b
        cp      $0A
        jr      c,L_FF5C
        ld      e,$0A
.L_FF5C
        bit     1,d
        jr      z,L_FF64
        ld      a,c
        and     $0F
        ld      e,a
.L_FF64
        pop     af
        push    bc
        push    hl
        ld      hl,($1D96)
        exx
        ld      hl,($1D98)
        ld      a,($1D9A)
        ld      c,a
        call    nz,L_F427
        pop     de
        fpp     Fp_str
        pop     bc
        ex      de,hl
        bit     7,c
        jr      z,L_FF8A
        ld      a,$7F
        bit     6,c
        jr      z,L_FF86
        ld      a,$29
.L_FF86
        ld      (hl),a
        inc     hl
        ld      (hl),$00
.L_FF8A
        bit     4,c
        ret     z
        ld      a,(iy+15)
        ld      de,$0010
        call    L_FF99
        ld      (hl),$00
        ret
.L_FF99
        push    iy
        pop     ix
        add     ix,de
        ld      e,a
.L_FFA0
        ld      a,(ix+0)
        ld      (hl),a
        inc     ix
        inc     hl
        dec     e
        jr      nz,L_FFA0
        ret

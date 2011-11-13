; **************************************************************************************************
; GN_Fcm, GN_Fex and miscellaneous internal filename functionality
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

        Module GNFName1

        include "fileio.def"
        include "memory.def"
        include "syspar.def"
        include "sysvar.def"
        include "oz.def"

;       ----

xdef    AddPathPart
xdef    GNFcm
xdef    GNFex

;       ----

xref    CompressFN
xref    IsSegSeparator
xref    Ld_A_BHL
xref    PutOsf_Err

;       ----

;       compress filename
;
;IN:    BHL=source, DE=destination, C=dest size, IX=destination handle (if DE<2)
;OUT:   DE=destination end (if DE>255)
;       B=#segments written, C=#chars written
;       Fc=1, A=error
;
;CHG:   AFBCDE../....

.GNFcm
        push    de
        OZ      OS_Bix                          ; bind in source
        ex      (sp), hl                        ; remember bindings, restore dest
        ex      de, hl
        ex      (sp), hl

        call    CompressFN

        pop     de                              ; restore bindings
        OZ      OS_Box
        ret

;       ----

;       expand filename
;
;IN:    BHL=source, DE=destination, C=dest size, IX=destination handle (if DE<2)
;OUT:   DE=destination end (if DE>255)
;       B=#segments written, C=#chars written, A=flags
;         A0: extension specified
;         A1: filename specified
;         A2: explicit directory specified
;         A3: current directory (".") specified
;         A4: parent directory ("..") specified
;         A5: wild directory ("//") specified
;         A6: device name specified
;         A7: wildcards were used
;       Fc=1, A=error
;
;CHG:   AFBCDE../....

.GNFex
        OZ      OS_Bix                          ; bind in source
        push    de

        ld      (iy+OSFrame_B), 0               ; # of segments
        ld      de, GnFnameBuf                   ; buffer space
        push    bc
        OZ      GN_Prs                          ; parse source
        pop     bc
        jp      c, fex_err                      ; error? exit

        ld      c, a                            ; remember flags
        and     $E7                             ; clear '.' and '..' flags
        ld      (iy+OSFrame_A), a               ; !! 'bit 6,a;set 6,a;ld osfA,a'
        and     $40                             ; device already specified?
        jr      nz, fex_1

        set     6, (iy+OSFrame_A)               ; do it now
        push    bc
        push    hl
        ld      bc, NQ_Dev                      ; get default device
        OZ      OS_Nq
        call    AddPathPart                     ; put it into buffer
        pop     hl
        pop     bc
        jr      fex_2

.fex_1
        push    hl
        push    bc
        OZ      GN_Pfs                          ; parse device
        bit     0, a                            ; extension used?
        pop     bc
        pop     hl
        push    af
        call    AddPathPart                     ; put filename into buffer
        pop     af
        jr      nz, fex_2                       ; had extension?

        ld      a, '.'                          ; no extension, add '.*'
        ld      (de), a
        inc     de
        ld      a, '*'
        ld      (de), a
        inc     de
        xor     a
        ld      (de), a

.fex_2
        ld      a, $18                          ; check for '.' or '..'
        and     c
        jr      nz, fex_3                       ; had one or another? get default dir

        ld      a, $64                          ; device or '//' or explicit dir
        and     c
        jr      nz, fex_6                       ; yes, don't add dir

        ld      a, (hl)                         ; source has dir specified?
        cp      '/'
        jr      z, fex_6
        cp      '\'
        jr      z, fex_6                        ; yes, skip

.fex_3
        push    hl
        push    bc
        ld      bc, NQ_Dir                      ; get default dir
        OZ      OS_Nq
        push    bc
        OZ      GN_Prs                          ; parse it
        ld      a, b
        pop     bc
        ld      c, a                            ; # of segments
        jr      c, fex_5                        ; bad dir? skip

        ex      (sp), hl
        bit     4, l                            ; parent dir ('..')?
        ex      (sp), hl
        jr      z, fex_4
        dec     c                               ; yes, decrement segments to copy
        jr      z, fex_5

.fex_4
        call    AddPathPart                     ; copy next pathpart
        dec     c
        jr      nz, fex_4                       ; unti all done

.fex_5
        pop     bc
        pop     hl
        ld      a, $18                          ; check for '.' or '..'
        and     c
        jr      z, fex_6

        push    de                              ; skip one part ('.' or '..')
        ld      de, 0
        call    AddPathPart
        pop     de

.fex_6
        call    AddPathPart                     ; copy rest of source
        jr      nc, fex_6

        ld      b, 0                            ; copy filename into caller buffer
        ld      hl, GnFnameBuf
        call    CompressFN
        jr      fex_8

.fex_err
        call    PutOsf_Err
.fex_8
        pop     de                              ; restore bindings
        OZ      OS_Box
        ret

;       ----

;IN:    BHL=source, DE=dest

.AddPathPart
        push    bc
        push    de
        ld      d, h
        ld      e, l

        OZ      GN_Pfs                          ; parse source segment
        jr      c, app_3                        ; bad segment? error
        sbc     hl, de
        ld      c, l                            ; segment length

        ex      de, hl                          ; restore source, dest
        pop     de

        ld      a, d
        or      e
        jr      nz, app_1                       ; dest != 0? add segment

        ld      b, 0                            ; point HL to end of part
        add     hl, bc
        jr      app_4

.app_1
        call    Ld_A_BHL                        ; copy '/' to dest if source segment
        call    IsSegSeparator                  ; doesn't start with segment separator
        jr      z, app_2
        ld      a, '/'
        ld      (de), a
        inc     de

.app_2
        call    Ld_A_BHL                        ; copy segment to dest
        ld      (de), a
        inc     hl
        inc     de
        dec     c
        jr      nz, app_2
        xor     a                               ; NULL terminate
        ld      (de), a
        jr      app_4

.app_3
        pop     de
.app_4
        pop     bc
        ret

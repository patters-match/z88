; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $ecd1
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNMisc3

        org $ecd1                               ; 707 bytes


        include "fileio.def"
        include "filter.def"
        include "memory.def"
        include "stdio.def"

        include "sysvar.def"
        include "../bank7/kernel7.def"

;       ----

xdef    DEBCx60
xdef    Divu16
xdef    Divu24
xdef    Divu48
xdef    GetOsf_BHL
xdef    GetOsf_DE
xdef    GetOsf_HL
xdef    GnClsMain
xdef    Ld_cde_BHL
xdef    Mulu16
xdef    Mulu24
xdef    Mulu40
xdef    PrintStr
xdef    PtrXOR
xdef    PutOsf_ABC
xdef    PutOsf_BC
xdef    PutOsf_BHL
xdef    PutOsf_DE
xdef    PutOsf_Err
xdef    PutOsf_HL
xdef    ReadHL
xdef    ReadOsfHL
xdef    SetListHdrs
xdef    UngetOsfHL
xdef    Upper
xdef    Wr_ABC_OsfDE
xdef    WriteDE
xdef    WriteOsfDE

;       ----

xref    Ld_A_HL
xref    Ld_BDE_A
xref    Ld_DE_A

;       ----

; !! faster: DEBC = DEBC<<6 - DBC<<2

.DEBCx60
        push    hl
        push    ix
        ld      a, 4
        ld      hl, 0
        push    hl
        pop     ix
.x60_1
        add     ix, bc                          ; HLIX += DEBC
        adc     hl, de
        sla     c                               ; DEBC *= 2
        rl      b
        rl      e
        rl      d
        dec     a
        jr      nz, x60_1                       ; result: HLIX = 15*DEBC
        push    ix                              ; DEBC = HLIX
        pop     bc
        ex      de, hl
        ld      a, 2                            ; *4
.x60_2
        sla     c                               ; DEBC *= 2
        rl      b
        rl      e
        rl      d
        dec     a
        jr      nz, x60_2
        pop     ix
        pop     hl
        ret

;       ----

;       cde'=(BHL)

;       !! should go to GNList

.Ld_cde_BHL
        push    hl
        push    bc
        push    de
        OZ      OS_Bix                          ; bind in BHL
        push    de                              ; !! unnecessary push/pop?
        push    hl
        exx                                     ; cde'=(BHL)
        pop     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      c, (hl)
        exx
        pop     de
        exx                                     ; push cde'
        push    bc
        push    de
        exx
        OZ      OS_Box                          ; restore bindings
        exx                                     ; pop cde'
        pop     de
        pop     bc
        exx
        pop     de
        pop     bc
        pop     hl
        exx                                     ; return alt registers
        ret

;       ----

; cde'=CDE^(BHL)
; returns alternate registers
;
; !! should go to GNList

.PtrXOR
        call    Ld_cde_BHL
        exx                                     ; back to main registers
        ld      a, c
        push    de
        exx                                     ; cde=CDE ^ cde
        pop     hl
        xor     c
        ld      c, a
        ld      a, h
        xor     d
        ld      d, a
        ld      a, l
        xor     e
        ld      e, a
        ret

;       ----

; IN: HL=parameter list, C=#entries
;
; !! should go to GNList

.SetListHdrs
        push    bc
        ld      e, (hl)                         ; get list node
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        inc     hl
        ld      a, b
        or      d
        or      e
        jr      nz, slh_1                       ; zero? skip

        inc     hl
        inc     hl
        inc     hl
        jr      slh_3

.slh_1
        ld      c, 3                            ; 3 bytes to write
.slh_2
        ld      a, (hl)                         ; get byte
        inc     hl                              ; bump source
        call    Ld_BDE_A                        ; write byte
        inc     de                              ; bump dest
        dec     c
        jr      nz, slh_2

.slh_3
        pop     bc
        dec     c
        jr      nz, SetListHdrs
        ret

;       ----

.Wr_ABC_OsfDE
        push    af
        ld      a, (iy+OSFrame_D)
        or      a
        jr      z, wabc_1                       ; D=0, return in registers
        ld      a, c
        call    WriteOsfDE
        ld      a, b
        call    WriteOsfDE
        pop     af
        call    WriteOsfDE
        jr      wabc_2
.wabc_1
        pop     af
        call    PutOsf_ABC
.wabc_2
        ret

;       ----

.ReadOsfHL
        push    hl
        call    GetOsf_HL
        call    ReadHL
        call    PutOsf_HL
        pop     hl
        ret

;       ----

.ReadHL
        ld      a, h
        or      l
        jr      z, rdHL_handle                  ; HL=0? handle IX
        dec     hl
        ld      a, h
        or      l
        jr      z, rdHL_filter                  ; HL=1? filter IX
        inc     hl
        call    Ld_A_HL                         ; else read memory
        inc     hl
        or      a
        ret

.rdHL_handle
        OZ      OS_Gb                           ; read from file/device
        ret
.rdHL_filter
        inc     hl                              ; read from filter
        OZ      GN_Flr
        ret

;       ----

.WriteOsfDE
        push    de
        call    GetOsf_DE
        call    WriteDE
        call    PutOsf_DE
        pop     de
        ret

;       ----

.WriteDE
        push    af
        ld      a, d
        or      e
        jr      z, wrDE_handle                  ; DE=0? handle IX
        dec     de
        ld      a, d
        or      e
        jr      z, wrDE_filter                  ; DE=1? filter IX
        dec     de
        dec     de
        ld      a, d
        or      e
        inc     de
        inc     de
        inc     de
        jr      nz, wrDE_mem
        pop     af                              ; DE=3? nop
        or      a
        ret
.wrDE_mem
        pop     af                              ; write to memory
        call    Ld_DE_A
        inc     de
        or      a
        ret
.wrDE_handle
        pop     af                              ; write to file/device
        OZ      OS_Pb
        ret
.wrDE_filter
        inc     de                              ; write to filter
        pop     af
        OZ      GN_Flw
        ret

;       ----

.UngetOsfHL
        push    af
        ld      a, (iy+OSFrame_H)
        or      a
        jr      z, ug_2
        ld      a, (iy+OSFrame_L)               ; memory - decrement HL
        sub     1
        ld      (iy+OSFrame_L), a
        jr      nc, ug_1
        dec     (iy+OSFrame_H)
.ug_1
        pop     af
        ret

.ug_2
        ld      a, (iy+OSFrame_L)
        or      a
        jr      nz, ug_3

        pop     af                              ; unget to file/device
        OZ      Os_Ugb                          ; !! not implemented
        ret

.ug_3
        pop     af                              ; 0<HL<256, push filter
        OZ      GN_Fpb
        ret

;       ----

;       HL/DE -> HL=quotient, DE=remainder

.Divu16
        push    bc
        ld      a, e
        or      d
        jr      nz, d16_1
        scf                                     ; divide by zero
        jr      d16_4

.d16_1
        ld      c, l                            ; AC=HL(in)
        ld      a, h
        ld      hl, 0                           ; HL=0
        ld      b, 16
        or      a                               ; Fc=0
.d16_2
        rl      c                               ; HLAC<<1 | Fc
        rla
        rl      l
        rl      h
        push    hl                              ; HL-DE(in)>=0? Fc = 1, HC -= DE(in)
        sbc     hl, de
        ccf
        jr      c, d16_3
        ex      (sp), hl                        ; else Fc=0
.d16_3
        inc     sp
        inc     sp
        djnz    d16_2

        ex      de, hl                          ; DE=remainder
        rl      c                               ; HL= AC<<1 | Fc
        ld      l, c
        rla
        ld      h, a
        or      a
.d16_4
        pop     bc
        ret

;       ----

;       BHL/CDE -> BHL=quotient, CDE=remainder

.Divu24
        ld      a, e
        or      d
        or      c
        jr      nz, d24_1
        scf                                     ; division by zero
        jr      d24_5

.d24_1
        push    hl
        xor     a
        ld      hl, 0
        exx                                     ;       alt
        pop     hl
        ld      b, 24
.d24_2
        rl      l
        rl      h
        exx                                     ;       main
        rl      b
        rl      l
        rl      h
        rl      a
        push    af
        push    hl
        sbc     hl, de
        sbc     a, c
        ccf
        jr      c, d24_3
        pop     hl
        pop     af
        or      a
        jr      d24_4
.d24_3
        inc     sp
        inc     sp
        inc     sp
        inc     sp
.d24_4
        exx                                     ;       alt
        djnz    d24_2

        rl      l
        rl      h
        push    hl
        exx                                     ;       main
        rl      b
        ex      de, hl
        ld      c, a
        pop     hl
        or      a
.d24_5
        ret

;       ----

;       BHLcde/CDE -> hlBHL=quotient, CDE=remainder

.Divu48
        ld      a, e
        or      d
        or      c
        jr      nz, d48_1
        scf
        jr      d48_5

.d48_1
        push    hl
        xor     a                               ; AHL=0
        ld      hl, 0
        exx                                     ;       alt
        pop     hl                              ; hl=HL(in)
        ld      b, 48
.d48_2
        rl      e                               ; AHLBhlcde << 1
        rl      d
        rl      c
        rl      l
        rl      h
        exx                                     ;       main
        rl      b
        rl      l
        rl      h
        rl      a
        push    af
        push    hl
        sbc     hl, de                          ; AHL-CDE(in)
        sbc     a, c
        ccf                                     ; AHL>=CDE(in)? Fc=1, AHL -= CDE(in)
        jr      c, d48_3
        pop     hl                              ; else Fc=0
        pop     af
        or      a
        jr      d48_4
.d48_3
        inc     sp                              ; fix stack
        inc     sp
        inc     sp
        inc     sp
.d48_4
        exx                                     ;       alt
        djnz    d48_2
        rl      e                               ; cde<<1
        rl      d
        rl      c
        ex      af, af'                         ;       alt
        ld      a, c
        push    de
        exx                                     ;       main
        ld      b, a                            ; B=c
        ex      de, hl                          ; DE=HL
        ex      af, af'                         ;       main
        ld      c, a                            ; C=A
        pop     hl                              ; HL=de
        or      a                               ; hlBHL=hlcde CDE=AHL (remainder)
.d48_5
        ret

;       ----

;       HL*DE -> HL=product

.Mulu16
        push    de
        push    bc
        ld      c, l                            ; BC=HL(in)
        ld      b, h
        ld      hl, 0                           ; HL=0
        ld      a, 15
.m16_1
        sla     e                               ; DE << 1
        rl      d
        jr      nc, m16_2
        add     hl, bc                          ; HL += HL(in)
.m16_2
        add     hl, hl                          ; HL << 1
        dec     a
        jr      nz, m16_1
        or      d
        jp      p, m16_3
        add     hl, bc                          ; HL += HL(in)
.m16_3
        pop     bc
        pop     de
        ret

;       ----

; !! should go to GNFilter

.Upper
        cp      'a'
        jr      c, up_1
        cp      '{'
        jr      nc, up_1
        and     $df
.up_1
        ret


; ----------------------------------------------------------------------------------------------------------------
; GN_Cls, classify character
;
; IN:
;      A = character to classify
;
; OUT:
;      F = flags indicate classification, as follows:
;           Fc = 0, Fz = 0: Neither alphabetic or numeric
;           Fc = 0, Fz = 1: Numeric ('0' ... '9')
;           Fc = 1, Fz = 0: Upper case letter ('A' ... 'Z')
;           Fc = 1, Fz = 1: Lower case letter ('a' ... 'z')
;
; Registers changed after return:
;      A.BCDEHL/IXIY same
;      .F....../.... different
;
.GnClsMain
        cp      '0'
        jr      c, cls_1                        ; symbols:  ' ' to '/'
        cp      ':'
        jr      c, cls_num                      ; numeric:  '0' to '9'
        cp      'A'
        jr      c, cls_1                        ; symbols:  ':' to '@'
        cp      '['
        jr      c, cls_upper                    ; alpha:    'A' to 'Z'
        cp      'a'
        jr      c, cls_1                        ; symbols:  '[' to '`'
        cp      '{'
        jr      c, cls_lower                    ; alpha:    'a' to 'z'
        cp      $C0
        jr      c, cls_1                        ; symbols:  '{' to '¿'

        call    ValidateIsoChar                 ; Validate defined ISO alpha chars in C0 - FF range
        jr      nz, cls_1                       ; ISO character not recognised, identify as neither alphabetic nor numeric...

        cp      $DF
        jr      c, cls_upper                    ; upper case alpha:    'À' to 'Þ'
        cp      $FF
        jr      c, cls_lower                    ; lower case alpha:    'à' to 'þ'
.cls_1
        or      a                               ; Fc=0
        push    af
        ex      (sp), hl
        res     Z80F_B_Z, l                     ; Fz=0
        jr      cls_x

.cls_num
        ccf                                     ; Fc=0, num
.cls_lower
        push    af
        ex      (sp), hl
        set     Z80F_B_Z, l                     ; Fz=1
.cls_x
        ex      (sp), hl
        pop     af
.cls_upper
        ret

; --------------------------------------------------------------------------------------------------------
; Verify ISO character in $C0 - $FF range against table of displayable ISO characters in screen driver
; conversion table.
; Return Fz = 1, if character in A was found in table.
; --------------------------------------------------------------------------------------------------------
.ValidateIsoChar
        push    bc
        push    de
        push    hl

        ld      bc, [OZBANK_KNL1 << 8] | MS_S1
        ld      hl, $4000 | (Chr2VDU_tbl&$3fff) ; scan table in Kernel bank 1 for printable ISO characters
        rst     OZ_MPB                          ; by binding it into local address space in segment 1

.check_iso
        cp      (hl)
        jr      z, exit_vIsoChar                ; ISO char is defined as printable character!

        ld      d,a
        xor     a
        or      (hl)                            ; end of table?
        ld      a,d
        jr      nz, next_iso
        or      a                               ; Fz = 0, ISO was not found in table...
.exit_vIsoChar
        rst     OZ_MPB                          ; restore S1 bank bindings
        pop     hl
        pop     de
        pop     bc
        ret
.next_iso
        ld      de, 4                           ; each ISO is located on the 4th entry
        add     hl,de                           ; point at next defined screen character
        jr      check_iso


;       ----



;       BHL*CDE -> BHL=product

.Mulu24
        push    de
        ex      de, hl                          ; BDE=BHL(in)
        xor     a                               ; AHL=0
        ld      h, a
        ld      l, a
        ex      af, af'                         ;       alt
        ld      a, c                            ; ade=CDE(in)
        exx                                     ;       alt
        pop     de
        ld      b, 23
.m24_1
        sla     e                               ; ade << 1
        rl      d
        rl      a
        exx                                     ;       main
        jr      nc, m24_2                       ; bit set? add total
        ex      af, af'                         ;       main
        add     hl, de                          ; AHL=AHL+BHL(in)
        adc     a, b
        ex      af, af'                         ;       alt
.m24_2
        ex      af, af'                         ;       main
        add     hl, hl                          ; AHL=AHL<<1
        adc     a, a
        exx                                     ;       alt
        ex      af, af'                         ;       alt
        djnz    m24_1
        exx                                     ;       main
        rlca                                    ; last bit
        jr      nc, m24_3
        ex      af, af'                         ;       main
        add     hl, de                          ; AHL += BHL(in)
        adc     a, b
        ex      af, af'                         ;       alt
.m24_3
        ex      af, af'                         ;       main
        ld      b, a
        ret

;       ----

;       CDE*BHL -> hlBHL=product

.Mulu40
        push    ix
        push    de
        ex      de, hl                          ; DE=HL
        xor     a                               ; AHL=0
        ld      h, a
        ld      l, a
        ex      af, af'                         ;       alt
        ld      a, c
        exx                                     ;       alt
        ld      e, a                            ; adeIX=CDE(in)
        ld      a, 0
        ld      d, 0
        ld      hl, 0                           ; hl'=0
        pop     ix
        ld      b, 39                           ; b'
.m40_1
        add     ix, ix                          ; adeIX << 1
        rl      e
        rl      d
        rl      a
        exx                                     ;       main
        jr      nc, m40_3
        ex      af, af'                         ;       main
        add     hl, de                          ; hlAHL+=BHL(in)
        adc     a, b
        jr      nc, m40_2
        exx                                     ;       alt
        inc     hl
        exx                                     ;       main
.m40_2
        ex      af, af'                         ;       alt
.m40_3
        ex      af, af'                         ;       main
        add     hl, hl                          ; hlAHL << 1
        adc     a, a
        exx                                     ;       alt
        adc     hl, hl
        ex      af, af'                         ;       alt
        djnz    m40_1
        exx                                     ;       main
        rlca                                    ; a7
        jr      nc, m40_5
        ex      af, af'                         ;       main
        add     hl, de                          ; hlAHL += BHL(in)
        adc     a, b
        jr      nc, m40_4
        exx                                     ;       alt
        inc     hl
        exx                                     ;       main
.m40_4
        ex      af, af'                         ;       alt
.m40_5
        ex      af, af'                         ;       main
        ld      b, a                            ; hlBHL
        pop     ix
        ret

;       ----

.PrintStr
        ld      a, (hl)
        or      a
        ret     z
        inc     de
        inc     hl
        OZ      OS_Out
        jr      nc, PrintStr

;       ----

.PutOsf_Err
        ld      (iy+OSFrame_A), a
        set     Z80F_B_C, (iy+OSFrame_F)
        ret

;       ----

.GetOsf_BHL
        ld      b, (iy+OSFrame_B)
.GetOsf_HL
        ld      h, (iy+OSFrame_H)
        ld      l, (iy+OSFrame_L)
        ret

;       ----

.GetOsf_DE
        ld      d, (iy+OSFrame_D)
        ld      e, (iy+OSFrame_E)
        ret

;       ----

.PutOsf_DE
        ld      (iy+OSFrame_D), d
        ld      (iy+OSFrame_E), e
        ret

;       ----

.PutOsf_BHL
        ld      (iy+OSFrame_B), b
.PutOsf_HL
        ld      (iy+OSFrame_H), h
        ld      (iy+OSFrame_L), l
        ret

;       ----

.PutOsf_ABC
        ld      (iy+OSFrame_A), a
.PutOsf_BC
        ld      (iy+OSFrame_B), b
        ld      (iy+OSFrame_C), c
        ret


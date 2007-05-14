; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $16d7
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc5

        include "blink.def"
        include "error.def"
        include "stdio.def"
        include "sysvar.def"

xdef    AtoN_upper
xdef    ClearMemHL_A
xdef    CopyMemBHL_DE
xdef    CopyMemDE_BHL
xdef    CopyMemDE_HL
xdef    CopyMemHL_DE
xdef    FPtr2MemPtrBindS2
xdef    GetOSFrame_BC
xdef    GetOSFrame_DE
xdef    GetOSFrame_HL
xdef    IncBHL
xdef    KPrint
xdef    MS12BankCB
xdef    MS1BankA
xdef    MS1BankB
xdef    MS2BankA
xdef    MS2BankB
xdef    MS2BankK1
xdef    OSBde
xdef    OSFn
xdef    PeekBHL
xdef    PeekBHLinc
xdef    PeekHL
xdef    PeekHLinc
xdef    PeekIncHL
xdef    PokeBHL
xdef    PokeBHLinc
xdef    PokeHL
xdef    PokeHLinc
xdef    PutOSFrame_BC
xdef    PutOSFrame_BHL
xdef    PutOSFrame_CDE
xdef    PutOSFrame_DE
xdef    PutOSFrame_HL
xdef    ReserveStkBuf
xdef    S2VerifySlotType
xdef    FixPtr

xref    FilePtr2MemPtr                          ; bank0/filesys3.asm
xref    VerifySlotType                          ; bank0/memory.asm
xref    OSFramePush                             ; bank0/misc4.asm
xref    OSFramePop                              ; bank0/misc4.asm
xref    AllocHandle                             ; bank0/handle.asm
xref    VerifyHandle                            ; bank0/handle.asm
xref    FreeHandle                              ; bank0/handle.asm


.GetOSFrame_BC
        ld      b, (iy+OSFrame_B)
        ld      c, (iy+OSFrame_C)
        ret


.GetOSFrame_DE
        ld      d, (iy+OSFrame_D)
        ld      e, (iy+OSFrame_E)
        ret


;       !! add GetOSFrame_BHL here
;       ld      b, (iy+OSFrame_B)

.GetOSFrame_HL
        ld      h, (iy+OSFrame_H)
        ld      l, (iy+OSFrame_L)
        ret

;       ----

.PutOSFrame_BC
        ld      (iy+OSFrame_B), b
        ld      (iy+OSFrame_C), c
        ret

.PutOSFrame_CDE
        ld      (iy+OSFrame_C), c
.PutOSFrame_DE
        ld      (iy+OSFrame_D), d
        ld      (iy+OSFrame_E), e
        ret


.PutOSFrame_BHL
        ld      (iy+OSFrame_B), b

.PutOSFrame_HL
        ld      (iy+OSFrame_H), h
        ld      (iy+OSFrame_L), l
        ret

;       ----

.MS12BankCB
        ld      (BLSC_SR1), bc
        ld      a, c
        out     (BL_SR1), a
        ld      a, b
        out     (BL_SR2), a
        ret


.MS1BankB
        ld      a, b

.MS1BankA
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ret


;       ----

;       translate file pointer into memory pointer, bind memory in

.FPtr2MemPtrBindS2
        call    FilePtr2MemPtr

.MS2BankB
        ld      a, b
        jr      MS2BankA

;       ----

;       call VerifySlotType(), then restore b07 into S2
;       !! all calls come from b07 in S2 - move code in b00 to avoid this

.S2VerifySlotType
        call    VerifySlotType

;       bind in other half of kernel

.MS2BankK1
        ld      a, OZBANK_KNL1

.MS2BankA
        ld      (BLSC_SR2), a
        out     (BL_SR2), a
        ret

;       ----

;       check A for alphanum status

; '0'-'9': a=val(A); Fz=1; Fc=1
; 'A'-'Z': a=A; Fz=0; Fc=0
; 'a'-'z': a=A; A=upper(A); Fz=0; Fc=0
; else   : a=A; Fz=0; Fc=1

.AtoN_upper
        push    af                              ; a'=A
        ex      af, af'
        pop     af
        cp      '0'
        ret     c                               ; Fc=1 Fz=0

        cp      '9'+1
        jr      nc, a2nu_1
        xor     '0'                             ; a'=val(A)
        ex      af, af'
        cp      a
        scf
        ret                                     ; Fc=1 Fz=1

.a2nu_1
        cp      'A'
        ret     c                               ; Fc=1 Fz=0
        cp      'Z'+1
        ccf
        jr      nc, a2nu_3                      ; Fc=0 Fz=0  !! ret nc
        cp      'a'
        ret     c                               ; Fc=1 Fz=0
        cp      'z'+1
        jr      c, a2nu_2
        cp      '0'
        scf
        ret                                     ; Fc=1 Fz=0
.a2nu_2
        xor     $20                             ; upper(), Fc=0, Fz=0
.a2nu_3
        ret

;       ----

;       clear A bytes at HL
;chg:   AF....../....

.ClearMemHL_A
        or      a
        ret     z                               ; no bytes to clear? exit

        inc     h
        dec     h
        ret     z                               ; HL<256? exit

        push    bc
        push    hl
        ld      c, a
.zm_1
        xor     a
        call    PokeHLinc
        dec     c
        jr      nz, zm_1
        pop     hl
        pop     bc
        ret

;       ----

;       copy C bytes from DE to HL

.CopyMemDE_HL
        ld      b, 0                            ; local ptr
        ex      de, hl

;       copy C bytes FROM HL to BDE

.OSBde
        ex      de, hl

;       copy C bytes from DE to BHL

.CopyMemDE_BHL
        inc     c
        dec     c
        ret     z                               ; no bytes to copy? exit

        push    af
.cm1_1
        ld      a, (de)
        inc     de
        call    PokeBHLinc
        dec     c
        jr      nz, cm1_1
        pop     af
        ret

;       ----

;       copy C bytes from HL to DE

.CopyMemHL_DE
        ld      b, 0                            ; local ptr

;       copy C bytes from BHL to DE

.CopyMemBHL_DE
        inc     c
        dec     c
        ret     z                               ; no bytes to copy? exit

        push    af
.cm2_1
        call    PeekBHLinc
        ld      (de), a
        inc     de
        dec     c
        jr      nz, cm2_1
        pop     af
        ret

;       ----

.ReserveStkBuf
        push    iy                              ; HL=IY
        pop     hl

        ex      (sp), hl                        ; HL=return address, stk: IY
        ld      iy, 0
        push    iy
        push    iy                              ; stk: 0000 0000 IY
        add     iy, sp                          ; IY=SP

        push    iy                              ; IX=SP+BC
        pop     ix
        add     ix, bc
        ld      sp, ix                          ; SP=IX

        push    ix                              ; BC=SP
        pop     bc
        ld      (iy+0), c                       ; orig. stk: SP 0000 IY
        ld      (iy+1), b
        jp      (hl)

;       ----

;       miscellaneous OS functions
;IN:    A=reason

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

;       ----

.PeekHLinc
        call    PeekHL
        inc     hl
        ret

.PeekIncHL
        inc     hl
        jr      PeekHL


;       ----

.PeekBHL
        inc     b
        dec     b
        jr      nz, peek_far

.PeekHL
        ld      a, (hl)                         ; read byter, hoping it's valid
        bit     7, h
        ret     z                               ; not kernel, done

        ld      a, (BLSC_SR1)                   ; remember S1
        ex      af, af'
        bit     6, h                            ; select caller S2/S3based on A14
        ld      a, (iy+OSFrame_S2)
        jr      z, peek_1
        ld      a, (iy+OSFrame_S3)
.peek_1
        ld      (BLSC_SR1), a                   ; bind in S1  !! could use S2 to avoid 'res7,h'
        out     (BL_SR1), a                     ; !! another option is to use code at peek_2
        push    hl

        res     7, h                            ; S1 fix
        set     6, h
        ld      a, (hl)                         ; peek

        pop     hl                              ; restore HL
        ex      af, af'                         ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'                         ; return byte
        ret

.peek_far
        ld      a, (BLSC_SR1)                   ; remember S1
        ex      af, af'
        ld      a, b
.peek_2
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        push    hl

        res     7, h
        set     6, h
        ld      a, (hl)

        pop     hl
        ex      af, af'
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ret

;       ----

.PeekBHLinc
        call    PeekBHL


;       increment BHL, handle bank change

;chg:   .FB...HL/.... af......

.IncBHL
        ex      af, af'
        ld      a, h                            ; remember original A14-A15

        inc     hl
        inc     b
        dec     b
        jr      z, incbhl_1                     ; local pointer, no bank bump

        xor     h                               ; get changed bits in A14-A15
        and     $c0
        jr      z, incbhl_1                     ; no segment change, exit

        xor     h                               ; change A14-A15 back
        ld      h, a
        inc     b

.incbhl_1
        ex      af, af'
        ret

;       ----

.PokeBHLinc
        call    PokeBHL
        jp      IncBHL

.PokeHLinc
        call    PokeHL
        inc     hl
        ret

.PokeHL
        ld      b, 0                            ; local ptr
        dec     hl                              ; !! these two (dec; call) unnecessary
        call    IncBHL                          ; !! most likely for unused PokeIncBHL


;chg:   .F....../.... af......


.PokeBHL

        inc     b
        dec     b
        jr      nz, poke_far                    ; far

        bit     7, h
        jr      z, poke_easy                    ; not kernel, just poke

        ex      af, af'
        ld      a, (BLSC_SR1)                   ; remember S1
        push    af
        bit     6, h                            ; select caller S2/S3 based on A14
        ld      a, (iy+OSFrame_S2)
        jr      z, poke_1
        ld      a, (iy+OSFrame_S3)
.poke_1
        ld      (BLSC_SR1), a                   ; bind in S1  !! could use S2 to avoid 'res7,h'
        out     (BL_SR1), a                     ; !! another option is to use code at poke_2
        push    hl

        res     7, h                            ; S1 fix
        set     6, h
        ex      af, af'
        ld      (hl), a                         ; poke
        ex      af, af'

        pop     hl                              ; restore HL
        pop     af                              ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'                         ; return original byte
        ret

.poke_easy
        ld      (hl), a
        ret

.poke_far
        ex      af, af'
        ld      a, (BLSC_SR1)                   ; remember S1
        push    af
        ld      a, b
.poke_2
        ld      (BLSC_SR1), a                   ; bind it in
        out     (BL_SR1), a
        push    hl

        res     7, h
        set     6, h
        ex      af, af'
        ld      (hl), a
        ex      af, af'

        pop     hl
        pop     af
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ret

;       ----

;       fix caller address HL into BHL
;chg:   AFB...H./....
.FixPtr
        bit     7, h
        jr      nz, fptr_1                      ; kernel space

        bit     6, h                            ; prepare for S1
        ld      a, (BLSC_SR1)
        jr      nz, fptr_2                      ; was S1? easy

        bit     5, h                            ; prepare for S0 $0000-$1fff
        ld      a, $20
        jr      z, fptr_2                       ; <$2000? done

        ld      a, (BLSC_SR0)                   ; prepare for S0 odd bank
        bit     0, a
        res     0, a
        jr      nz, fptr_2
        res     5, h                            ; S0 even bank
        jr      fptr_2

.fptr_1
        bit     6, h                            ; get correct bank
        ld      a, (iy+OSFrame_S2)
        jr      z, fptr_2
        ld      a, (iy+OSFrame_S3)
.fptr_2
        res     7, h                            ; S0 fix
        res     6, h
        ld      b, a                            ; set bank
        ret





; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $1555
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc4

        org     $d555                           ; 124 bytes

        include "all.def"
        include "sysvar.def"

xdef    OSFramePushMain
xdef    OSFramePop
xdef    osfpop_1
xdef    OSBox
xdef    OSBix

defc    MS2BankA                =$d721
defc    OZCallReturn1           =$00ab
defc    MS12BankCB              =$d704

.OSFramePush
        pop     hl                              ; caller PC
        pop     bc                              ; S2/S3
        ld      a, OZBANK_7                     ; bind in more kernel code !! use MS2BankK1
        call    MS2BankA

.OSFramePushMain
        push    bc                              ; 0E - S2S3
        exx
        push    hl                              ; 0C - HL
        push    de                              ; 0A - DE
        push    bc                              ; 08 - BC
        ex      af, af'
        push    af                              ; 06 - AF
        exx
        push    de                              ; 04 - OZCall
        push    bc                              ; 02 - S2S3
        push    iy                              ; 00 - IY

        ld      iy, 0
        add     iy, sp
        ld      (iy+OSFrame_F), 0               ; clear flags

        push    hl                              ; RET caller
        exx                                     ; use caller registers
        ret

.OSFramePopError
        pop     iy                              ; 00 - IY
        ex      af, af'                         ; save return value
        pop     bc                              ; 02 - S2S3
        ld      a, c
        call    MS2BankA                        ; bind out other half of kernel
        ex      af, af'                         ; back to return value
        pop     bc                              ; 04 - OZCall
        pop     bc                              ; 06 - AF
        jr      osfpop_2                        ; restore BC-HL

.OSFramePop
        jr      c, OSFramePopError

.osfpop_1
        pop     iy                              ; 00 - IY
        pop     bc                              ; 02 - S2S3
        ld      a, c
        call    MS2BankA                        ; bind out other half of kernel
        pop     af                              ; 04 - OZCall
        pop     af                              ; 06 - AF
.osfpop_2
        pop     bc                              ; 08 - BC
        pop     de                              ; 0A - DE
        pop     hl                              ; 0C - HL
        jp      OZCallReturn1                   ; restore S2S3 and return

;       ----

;       restore bindings after OS_Bix

.OSBox
        exx
        ld      (BLSC_SR1), de
        jr      bix_3

;       ----

; bind in extended address

.OSBix
        exx
        ld      de, (BLSC_SR1)                  ; remember S1S2 in de'
        push    bc
        inc     b
        dec     b
        jr      nz, bix_far                     ; bind in BHL

        ld      b, (iy+OSFrame_S2)
        ld      c, (iy+OSFrame_S3)
        bit     7, h
        jr      z, bix_4                        ; not kernel space, no bankswitching

        bit     6, h
        jr      z, bix_S2                       ; HL in S2 - S1=caller S3, S2=caller S2

;       HL in S3

        ld      c, b                            ; S1=caller S2
        ld      b, d                            ; S2 unchanged
        jr      bix_S2

.bix_far
        ld      c, b                            ; S1=B
        inc     b                               ; S2=B+1
.bix_S2
        ld      (BLSC_SR1), bc                  ; store pointers
        pop     bc

        ld      b, 0                            ; HL=local
        res     7, h                            ; S1 fix
        set     6, h
.bix_3
        push    bc
        ld      bc, (BLSC_SR1)
        call    MS12BankCB

.bix_4
        pop     bc
        ex      af, af'
        or      a
        jp      OZCallReturn1

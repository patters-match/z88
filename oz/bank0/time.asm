; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $14bb
;
; $Id$
; -----------------------------------------------------------------------------

        Module Time

        include "blink.def"
        include "error.def"
        include "sysvar.def"

xdef    OSHt
xdef    ReadRTC

xref    GetOSFrame_HL                           ; bank0/misc5.asm
xref    PutOSFrame_HL                           ; bank0/misc5.asm
xref    PokeHLinc                               ; bank0/misc5.asm



.OSHt
        ld      b, a
        djnz    osht_rd

;       HT_RES, reset hardware timer
;chg:   AF....../....

.osht_res
        in      a, (BL_TIM0)                    ; wait until TIM0=0
        call    NormalizeTIM0
        jr      nz, osht_res

        ld      a, (BLSC_COM)                   ; reset timer
        or      BM_COMRESTIM
        out     (BL_COM), a
        and     ~BM_COMRESTIM
        out     (BL_COM), a
        ret

.osht_rd
        djnz    osht_mdt

;       HT_RD, read hardware timer
;IN:    HL=buffer, 5 bytes
;chg:   AF....../....

        push    hl                              ; copy hardware clock to stack buffer
        push    hl
        push    hl
        ld      hl, 0                           ; !! ld h,b; ld l,b
        add     hl, sp
        call    ReadRTC

        ld      c, 5                            ;  copy into caller buffer
        ex      de, hl
        call    GetOSFrame_HL
.htrd_1
        ld      a, (de)
        inc     de
        call    PokeHLinc
        dec     c
        jr      nz, htrd_1
        pop     hl                              ; purge stack
        pop     hl
        pop     hl
        or      a
        ret

.osht_mdt
        djnz    osht_x

;       HT_MDT, read month/date/time address in S2
;       OUT:   BHL points to MDT (11 bytes)
;       NB : it is always $2001EB (and was$2180AB in OZ4)

        or      a                               ; at $2001EB (was $2180AB)
        ld      (iy+OSFrame_B), $20             ; to define correctly (OSRAM_BANK) ?
        ld      hl, uwSysDateLow                ; was $80AB
        jp      PutOSFrame_HL

.osht_x
        ld      a, RC_Unk
        scf
        ret

;       ----

;IN:    HL=buffer[5]
;chg:   ABCD..../....

.ReadRTC
        ld      bc, 5<<8|BL_TIM0
        ld      d, -1                           ; check for same value
        push    hl
.rrtc_1
        in      a, (c)
        cp      (hl)
        ld      (hl), a
        jr      z, rrtc_2
        inc     d                               ; mark as different
.rrtc_2
        inc     hl                              ; inc pointer
        inc     c                               ; inc port
        djnz    rrtc_1
        pop     hl
        inc     d
        jr      nz, ReadRTC                     ; loop until changed

        ld      a, (hl)
        call    NormalizeTIM0
        ld      (hl), a
        ret

;       ----

;IN:    A=TICK value
;OUT:   A=0.01 sec value
;chg:   AF....../....

.NormalizeTIM0
        xor     $80                             ; -128
        jp      p, ntim0_1                      ; no underflow, skip
        add     a, 200                          ; make positive
.ntim0_1
        srl     a                               ; /2 to make it 0.01s clock
        ret


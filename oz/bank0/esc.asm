; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $10cc
;
; $Id$
; -----------------------------------------------------------------------------

        Module Esc

        include "error.def"
        include "stdio.def"
        include "sysvar.def"
        include "../bank7/lowram.def"

xdef    OSEsc
xdef    TestEsc
xdef    MaySetEsc

xref    ResetTimeout                            ; bank0/nmi.asm


defc    AKBD_ESCENABLED         =$80
defc    AKBD_B_ESCENABLED       =7


; examine special condition
.OSEsc
        ld      hl, ubIntTaskToDo
        ex      af, af'
        ld      b, a                            ; B=reason
        or      a
        jr      z, osexc_bit

        djnz    osesc_set

.osesc_ack                                      ; ack escape, flush input buffer
        call    ResetTimeout
        bit     ITSK_B_ESC, (hl)
        jr      z, OSEsc_x
        res     ITSK_B_ESC, (hl)
        push    af
        push    ix
        exx
        ld      ix, KbdData
        OZ      OS_Pur                          ; purge keyboard buffer
        exx
        pop     ix
        pop     af
        jr      OSEsc_x

.osesc_set
        djnz    osesc_res

        set     ITSK_B_ESC, (hl)                ; set escape
        jr      OSEsc_x

.osesc_res
        djnz    osesc_tst

        res     ITSK_B_ESC, (hl)                ; reset escape
        jr      OSEsc_x

.osesc_tst
        ld      hl, ubAppKbdBits
        djnz    osesc_ena

        bit     AKBD_B_ESCENABLED, (hl)         ; test if escape detection is enabled or disabled
        ld      a, SC_ENA
        jr      nz, OSEsc_x
        inc     a                               ; DC_DIS
        jr      OSEsc_x

.osesc_ena
        djnz    osesc_dis

        set     AKBD_B_ESCENABLED, (hl)         ; enable escape detection
        jr      OSEsc_x

.osesc_dis
        djnz    osesc_unk
        res     AKBD_B_ESCENABLED, (hl)         ; disable escape detection
        ld      hl, ubIntTaskToDo
        res     ITSK_B_ESC, (hl)                ; clear any pending ESC
        jr      OSEsc_x

.osesc_unk
        ld      a, RC_Unk
        jr      osesc_err

.osexc_bit
        call    ResetTimeout                    ; test for Escape
        bit     ITSK_B_ESC, (hl)
        jp      z, OZCallReturn2                ; !! jr z,OSEsc_x

        ld      a, RC_Esc
.osesc_err
        scf
.OSEsc_x
        jp      OZCallReturn2

;       ----

.TestEsc
        or      a                               ; Fc=0
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_ESC, (hl)
        ret     z

        ld      a, RC_Esc
        scf
        ret

;       ----

.MaySetEsc
        ld      hl, ubAppKbdBits
        bit     AKBD_B_ESCENABLED, (hl)
        ret     z                               ; disabled? exit

        ld      hl, ubIntTaskToDo               ; set ESC flag
        set     ITSK_B_ESC, (hl)
        ret


; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1dd6e
;
; $Id$
; -----------------------------------------------------------------------------

        Module Deadkey

        org $9d6e                               ; 149 bytes

        include "all.def"
        include "sysvar.def"

xdef    KbdDeadKeys
xdef    Key2Code

defc    DrawOZwd                = $FA11

defc    kbd_lastkey             = 8


.KbdDeadKeys
        ld      c, a
        cp      $0AF
        jr      z, dkey_1
        cp      $0AC
        jr      z, dkey_1
        cp      $0AD
        jr      z, dkey_1
        cp      $0AE                            ; ^ on french keyboard
        jr      nz, dkey_4
.dkey_1
        cp      (ix+kbd_lastkey)
        jr      nz, dkey_3
.dkey_2
        xor     a                               ; reset dead key
.dkey_3
        ld      (ix+kbd_lastkey), a             ; store dead key
        push    bc
        call    DrawOZwd
        pop     bc
        scf
        ret
.dkey_4
        cp      $0E3                            ; DEL
        ex      af, af'
        ld      a, (ix+kbd_lastkey)
        or      a
        ret     z                               ; no dead key, return
        ex      af, af'
        jr      z, dkey_2                       ; delete dead key
        ex      af, af'
        call    KbdTranslate
        call    dkey_2                          ; reset dead key
        or      a

        ret

;       ----
.KbdTranslate
        ld      hl, Deadkey_tbl                 ; points to NULL, function is no-op
.dktr_1
        ld      b, (hl)
        inc     b
        dec     b
        ret     z
        cp      (hl)
        jr      z, dktr_3
.dktr_2
        inc     hl
        ld      b, (hl)
        inc     b
        dec     b
        jr      nz, dktr_2
        inc     hl
        jr      dktr_1
.dktr_3
        ld      a, c
        inc     hl
        ld      b, (hl)
        inc     b
        dec     b
        ret     z
        inc     hl
        cp      b
        jr      nz, dktr_3
        ld      c, (hl)
        ret

.Deadkey_tbl
        defb    0
.Key2Code
        defb $38, $37, $6E, $68, $79, $36, $E1, $E3
        defb $69, $75, $62, $67, $74, $35, $FF, $5C
        defb $6F, $6A, $76, $66, $72, $34, $FE, $3D
        defb $39, $6B, $63, $64, $65, $33, $FD, $2D
        defb $70, $6D, $78, $73, $77, $32, $FC, $5D
        defb $30, $6C, $7A, $61, $71, $31, $20, $5B
        defb $27, $3B, $2C, $E5, $C8, $E2, $00, $E7
        defb $A3, $2F, $2E, $E8, $E6, $1B, $B8, $00

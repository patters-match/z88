; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $31bf
;
; $Id$
; -----------------------------------------------------------------------------

        Module ScrDrv2

        org $f1bf                               ; 99 bytes

        include "all.def"
        include "sysvar.def"

xdef    GetWindowFrame
xdef    NqRDS

defc    GetWindowNum            = $b052
defc    GetOSFrame_HL           = $d6e5
defc    GetOSFrame_DE           = $d6de
defc    GetCrsrYX               = $b044
defc    VDU2ChrCode             = $ad28
defc    ScreenClose             = $faf6
defc    PokeHLinc               = $d84c
defc    ScreenOpen              = $faea
defc    CursorRight             = $fbf1


.GetWindowFrame
        or      a
        jr      nz, gwf_1                       ; a<>0? don't use current window
        ld      a, (sbf_ActiveWd+1)
        sub     Wd1Frame/256-'1'

.gwf_1
        sub     $20
        call    GetWindowNum

        push    af
        add     a, Wd1Frame/256                 ; SBF page !! ld hl,Wd1Frame; add a,h; ld h,a
        ld      h, a
        ld      l, Wd1Frame~255                 ; low byte
        pop     af
        push    hl
        pop     ix                              ; window frame
        add     a, '1'
        ret     nc                              ; !! not enough to assert valid window
        ld      a, RC_Hand
        ret     c                               ; !! unconditional ret


; read text from the screen
;
;IN:    DE=buffer, HL=#bytes to read

.NqRDS
        call    GetOSFrame_HL                   ; BC=#bytes to read
        ld      b, h
        ld      c, l

        call    GetOSFrame_DE                   ; DE=buffer

        pop     af                              ; for ScreenClose()
        push    af
        push    ix
        ld      ix, (sbf_ActiveWd)
        push    af
        call    GetCrsrYX                       ; pointer actually

.rds_1
        ld      a, b
        or      c
        jr      z, rds_x                        ; no more chars? exit

        ld      a, (hl)                         ; char low byte
        push    hl
        call    VDU2ChrCode                     ; into ascii

        jr      c, rds_2                        ; not found in table

        dec     hl                              ; get ASCII
        dec     hl
        ld      a, (hl)

.rds_2
        pop     hl
        ex      af, af'

        exx
        call    ScreenClose                     ; restore S1
        exx

        ex      af, af'                         ; put char into buffer
        push    bc
        ex      de, hl
        call    PokeHLinc
        ex      de, hl
        pop     bc

        exx                                     ; put screen into S1
        call    ScreenOpen
        exx

        push    bc
        call    CursorRight                     ; advance pointer
        pop     bc                              ; decrement count and loop
        dec     bc
        jr      rds_1

.rds_x
        pop     af
        pop     ix
        call    ScreenClose

        or      a
        ret

; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1df23
;
; $Id$
; -----------------------------------------------------------------------------

        Module Memory1

        org $9f23                               ; 41 bytes

        include "all.def"
        include "sysvar.def"
        include "bank0.def"

xdef    MemCallAttrVerify


;       ----
.MemCallAttrVerify
        ld      a, HND_MEM                      ; first verify handle type
        call    VerifyHandle
        ret     c
        inc     b                               ; check allocation size !! wouldn't this be easier with cp?
        dec     b
        jp      z, mcav_1                       ; 0-255, ok
        dec     b
        jr      nz, mcav_err                    ; >256, fail
        inc     c
        dec     c
        ret     z                               ; 256 - ok
        scf                                     ; ?? why like this?
.mcav_1
        inc     c
        inc     c
        jr      nz, mcav_2                      ; not FE
        dec     (iy+OSFrame_C)                  ; ?? FE->FD
        dec     c                               ; ff
        ret
.mcav_2
        dec     c
        dec     c
        dec     c
        jr      nz, mcav_3
        inc     c                               ; 1 -> 2
        inc     c
        ret
.mcav_3
        inc     c
        ret     nz                              ; not 0? ok
.mcav_err
        ld      a, RC_Fail
        scf
        ret

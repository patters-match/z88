; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $1f22
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSMap

        org     $df22                           ; 8 bytes

        include "all.def"
        include "sysvar.def"

xdef    OSMap

;       bank 7

xref    OSMapMain

;       ----

; high resolution graphics manipulation

.OSMap
        push    ix
        call    OSMapMain
        pop     ix
        ret


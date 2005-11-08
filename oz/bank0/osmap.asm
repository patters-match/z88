; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $1f22
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSMap

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


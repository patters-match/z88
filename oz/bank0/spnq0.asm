; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $31ac
;
; $Id$
; -----------------------------------------------------------------------------

        Module SpNq0

xdef    NqSp_ret
xdef    OSNq
xdef    OSSp

;       bank 0

xref    OSFramePop
xref    OSFramePush

;       bank 7

xref    OSNqMain
xref    OSSpMain

;       ----

; set Panel and PrinterEd values

.OSSp
        call    OSFramePush
        call    OSSpMain
        jp      OSFramePop

.NqSp_ret
        ret

; read Panel and PrinterEd values

.OSNq
        call    OSFramePush
        call    OSNqMain
        jp      OSFramePop

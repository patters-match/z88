; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $31ac
;
; $Id$
; -----------------------------------------------------------------------------

        Module SpNq0

        org $f1ac                               ; 19 bytes


xdef    OSSp
xdef    ret_F1B5
xdef    OSNq

defc    OSFramePush     = $d555
defc    OSFramePop      = $d582
defc    OSSpMain        = $a73e
defc    OSNqMain        = $a774


; set Panel and PrinterEd values

.OSSp
        call    OSFramePush
        call    OSSpMain
        jp      OSFramePop

.ret_F1B5
        ret

; read Panel and PrinterEd values

.OSNq
        call    OSFramePush
        call    OSNqMain
        jp      OSFramePop

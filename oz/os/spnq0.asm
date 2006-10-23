; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $31ac
;
; $Id$
; -----------------------------------------------------------------------------

        Module SpNq0

xdef    NqSp_ret
xdef    OSNq
xdef    OSSp

xref    OSFramePop                              ; bank0/misc4.asm
xref    OSFramePush                             ; bank0/misc4.asm

xref    OSNqMain                                ; bank7/nqsp.asm
xref    OSSpMain                                ; bank7/nqsp.asm



; set Panel and PrinterEd values

.OSSp
        call    OSFramePush                     ; Framepush and bind K1
        call    OSSpMain                        ; in K1
        jp      OSFramePop

.NqSp_ret
        ret

; read Panel and PrinterEd values

.OSNq
        call    OSFramePush                     ; idem
        call    OSNqMain
        jp      OSFramePop
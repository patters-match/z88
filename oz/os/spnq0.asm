; -----------------------------------------------------------------------------
; Kernel 0 @ S3
;
; $Id$
; -----------------------------------------------------------------------------

        Module SpNq0


xdef    NqSp_ret
xdef    OSNq
xdef    OSSp

xref    OSFramePop                              ; [Kernel0]/misc4.asm
xref    OSFramePush                             ; [Kernel0]/misc4.asm

xref    OSNqMain                                ; [Kernel1]/nqsp.asm
xref    OSSpMain                                ; [Kernel1]/nqsp.asm

        include "serintfc.def"
        include "kernel.def"


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


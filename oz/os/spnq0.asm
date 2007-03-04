; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $31ac
;
; $Id$
; -----------------------------------------------------------------------------

        Module SpNq0

        
xdef    NqSp_ret
xdef    OSNq
xdef    OSSp
xdef    OSSp_PAGfi

xref    OSFramePop                              ; K0/misc4.asm
xref    OSFramePush                             ; K0/misc4.asm

xref    OSNqMain                                ; K1/nqsp.asm
xref    OSSpMain                                ; K1/nqsp.asm
xref    OSPrtInit                               ; K1/printer.asm
xref    RstRdPanelAttrs                         ; K1/nqsp.asm

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


; apply panel values
        
.OSSp_PAGfi
        push    ix
        call    RstRdPanelAttrs                 ; store panel and init keymap
        ld      l, SI_SFT
        OZ      OS_Si                           ; reset serial port and apply settings
        extcall OSPrtInit, OZBANK_KNL1          ; init printer filter
        pop     ix
        or      a
        ret

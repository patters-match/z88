; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $38fa
;
; $Id$
; -----------------------------------------------------------------------------

        Module PAGfi

        org     $f8fa                           ; 18 bytes

        include "serintfc.def"
        include "kernel.def"

xdef    OSSp_PAGfi

xref    OSPrtInit                               ; bank7/printer.asm
xref    RstRdPanelAttrs                         ; bank7/nqsp.asm


.OSSp_PAGfi
        push    ix
        call    RstRdPanelAttrs                 ; store panel and init keymap
        ld      l, SI_SFT
        OZ      OS_Si                           ; reset serial port and apply settings
        extcall OSPrtInit, OZBANK_KNL1          ; init printer filter
        pop     ix
        or      a
        ret

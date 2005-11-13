; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $38fa
;
; $Id$
; -----------------------------------------------------------------------------

        Module PAGfi

        org     $f8fa                           ; 18 bytes

        include "serintfc.def"
        include "sysvar.def"

xdef    OSSp_PAGfi

xref    PrFilterCall                            ; bank0/pfilter0.asm

xref    RstRdPanelAttrs                         ; bank7/nqsp.asm


.OSSp_PAGfi
        push    ix
        call    RstRdPanelAttrs

        ld      l, SI_SFT
        OZ      OS_Si

        ld      l, <PrntInit
        call    PrFilterCall

        pop     ix
        or      a
        ret

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $38fa
;
; $Id$
; -----------------------------------------------------------------------------

        Module PAGfi

        org     $f8fa                           ; 18 bytes

        include "all.def"
        include "sysvar.def"

xdef    OSSp_PAGfi

xref    PrFilterCall
xref    RstRdPanelAttrs

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

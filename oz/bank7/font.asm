; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1c000
;
; $Id$
; -----------------------------------------------------------------------------

        Module Font

        org     $8000                           ; fixed ORG

; include font according the localisation ($0F00 length)

if KBDK
        include "bank7/font_dk.asm"
endif

if KBFI
        include "bank7/font_fi.asm"
endif

; if no country localisation is specified, use default UK/FR fonts
if !KBFI & !KBDK
        include "bank7/font_ukfr.asm"
endif
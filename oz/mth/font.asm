; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1c000
;
; $Id$
; -----------------------------------------------------------------------------

        Module Font

        org     $8000                           ; fixed ORG

.lores1

; include font according the localisation ($0F00 length)

if KBDK
        include "font_dk.asm"
endif

if KBFI | KBSE
        include "font_fi.asm"
endif

; if no country localisation is specified, use default UK/FR fonts
if !KBFI & !KBSE & !KBDK
        include "font_ukfr.asm"
endif
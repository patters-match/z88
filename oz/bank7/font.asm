; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1c000
;
; $Id$
; -----------------------------------------------------------------------------

        Module Font

        org     $8000                           ; fixed ORG

; include font according the localisation ($0F00 file length)

if KBDK
        binary "bank7/font_dk.dat"
endif

if KBFI
        binary "bank7/font_fi.dat"
endif

if !KBFI & !KBDK
; use default UK localisation
        binary "bank7/font_ukfr.dat"
endif
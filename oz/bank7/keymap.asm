module  keymap

org $B300

if KBDK
        include "bank7/keymap_dk.asm"
endif
if KBFR
        include "bank7/keymap_fr.asm"
endif
if KBFI
        include "bank7/keymap_fi.asm"
endif

if !KBFI & !KBFR & !KBDK
; use default UK localisation
        include "bank7/keymap_uk.asm"
endif
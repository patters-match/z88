module  keymap

org $B300

if KBDK
        include "keymap_dk.asm"
endif
if KBFR
        include "keymap_fr.asm"
endif
if KBFI
        include "keymap_fi.asm"
endif

if !KBFI & !KBFR & !KBDK
; use default UK localisation
        include "keymap_uk.asm"
endif
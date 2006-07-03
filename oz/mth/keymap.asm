module  keymap

org $9000

xdef    KeymapTable

.KeymapTable

if KBDK
        include "keymap_dk.asm"
endif
if KBFR
        include "keymap_fr.asm"
endif
if KBFI | KBSE
        ; Swedish/Finnish share the same keyboard layout
        include "keymap_fi.asm"
endif

if !KBFI & !KBSE & !KBFR & !KBDK
; use default UK localisation
        include "keymap_uk.asm"
endif

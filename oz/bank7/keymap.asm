module  keymap

org $B300

xdef    KeymapTable

xdef    Key2Chr_tbl
xdef    Chr2VDU_tbl
xdef    VDU2Chr_tbl


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


if KBDK
        include "key2chrt_dk.asm"
endif
if KBFR
        include "key2chrt_fr.asm"
endif
if KBFI | KBSE
        ; Swedish/Finnish share the same kbd/font data
        include "key2chrt_fi.asm"
endif

if !KBFI & !KBSE & !KBFR & !KBDK
        ; use default UK localisation
        include "key2chrt_uk.asm"
endif

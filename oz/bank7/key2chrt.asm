module Key2Char_Table

if KBDK
        include "bank7/key2chrt_dk.asm"
endif
if KBFR
        include "bank7/key2chrt_fr.asm"
endif
if KBFI
        include "bank7/key2chrt_fi.asm"
endif

if !KBFI & !KBFR & !KBDK
; use default UK localisation
        include "bank7/key2chrt_uk.asm"
endif

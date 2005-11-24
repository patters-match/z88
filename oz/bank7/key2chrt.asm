module Key2Char_Table

xdef    Key2Chr_tbl
xdef    Chr2VDU_tbl
xdef    VDU2Chr_tbl

if KBDK
        include "key2chrt_dk.asm"
endif
if KBFR
        include "key2chrt_fr.asm"
endif
if KBFI
        include "key2chrt_fi.asm"
endif

if !KBFI & !KBFR & !KBDK
; use default UK localisation
        include "key2chrt_uk.asm"
endif

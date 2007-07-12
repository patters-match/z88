module OSSciTable

xdef    OSSciTable

; granularity table used by OSSci
; must be in the same page

.OSSciTable
.OSSciTbl
        defb 0, 3, 6, 7, 5, 5                   ; #low bits ignored
.OSSciTbl_end

IF ($linkaddr(OSSciTbl) / 256) <> ($linkaddr(OSSciTbl_end) / 256)
        ERROR "OS_SCI table crosses address page boundary!"
ENDIF

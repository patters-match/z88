module OSSciTable

xdef    OSSciTable

; granularity table used by OSSci
; must be in the same page

.OSSciTable
.OSSciTbl
        defb 0, 3, 6, 7, 5, 5                   ; #low bits ignored
.OSSciTbl_end

IF (<$linkaddr(OSSciTbl)) <> 0
        ERROR "OS_SCI table must start a page at $00!"
ENDIF

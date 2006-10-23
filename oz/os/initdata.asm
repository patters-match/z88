; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1eaa9
;
; $Id$
; -----------------------------------------------------------------------------

        Module InitData

        include "blink.def"
        include "sysvar.def"

xdef    InitData

.InitData
        defb    BL_SR2, OZBANK_KNL1                ; SR2 = kernel bank 1
        defb    BL_TMK, BM_TACKTICK|BM_TACKSEC|BM_TACKMIN
        defb    BL_INT, BM_INTFLAP|BM_INTBTL|BM_INTTIME|BM_INTGINT
        defb    BL_TACK, BM_TMKTICK|BM_TMKSEC|BM_TMKMIN
        defb    BL_ACK, BM_ACKA19|BM_ACKFLAP|BM_ACKBTL|BM_ACKKEY
        defb    BL_EPR, 0                       ; reset EPROM port
        defb    0

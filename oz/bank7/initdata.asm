; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1eaa9
;
; $Id$
; -----------------------------------------------------------------------------

        Module InitData

        org $aaa9                               ; 13 bytes

        include "all.def"

.InitData
        defb    BL_SR2, 7                       ; SR2=b07
        defb    BL_TMK, 7                       ; SR2=b07, enable all timer ints
        defb    BL_INT, $2B                     ; enable flap | batlow | rtc ints outsie BLINK
        defb    BL_TACK, 7                      ; ack RTC ints
        defb    BL_ACK, $6C                     ; ack all ints
        defb    BL_EPR, 0                       ; reset EPROM port
        defb    0

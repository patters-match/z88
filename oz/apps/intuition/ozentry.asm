
include "sysvar.def"

; **************************************************************************************************
;
; Intuition routine entry from RST 08H, which has bound Intuition bank into segment 0 (upper 8K).
;
; Original values of registers and runtime data will be stored in OZ system variable area.
; On entry, BC register contains old bank binding of segment 0. remaining register are from application.
;
; Intuition will by default activate Single Step Mode and Screen Protect Mode.
;
;                             High byte, return address      -+
;     RST 08H return addres   Low  byte, return address       |
;                             B register from application     |
;     Current SP on entry:    C register from application    -+
;
;
.IntuitionEntry
        ld      (SV_INTUITION_RAM + OZBankBinding),bc   ; remember old segment 0 bank binding
        pop     bc
        ld      (SV_INTUITION_RAM + VP_BC),bc           ; get current BC register
        ld      (SV_INTUITION_RAM + VP_DE),de           ; get current DE register
        ld      (SV_INTUITION_RAM + VP_HL),hl           ; get current HL register

        ld      (SV_INTUITION_RAM + VP_IX),ix           ; get current IX register
        ld      (SV_INTUITION_RAM + VP_IY),iy           ; IY

        push    af
        pop     hl
        ld      (SV_INTUITION_RAM + VP_AF),hl           ; get current AF register
        ex      af,af'
        push    af
        pop     hl
        ld      (SV_INTUITION_RAM + VP_AFx),hl          ; get current AF' register

        exx
        ld      (SV_INTUITION_RAM + VP_BCx),bc          ; get current BC' register
        ld      (SV_INTUITION_RAM + VP_DEx),de          ; get current DE' register
        ld      (SV_INTUITION_RAM + VP_HLx),hl          ; get current HL' register
        exx
        pop     hl
        ld      (SV_INTUITION_RAM + VP_PC),hl           ; PC = instruction after RST 08H
        ld      (SV_INTUITION_RAM + VP_SP),sp           ; SP, get current Stack Pointer of caller

        ld      iy,SV_INTUITION_RAM                     ; IY = base pointer of Intuition runtime area

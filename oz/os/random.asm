; -----------------------------------------------------------------------------
; Kernel 0 @ S3
;
; $Id$
; -----------------------------------------------------------------------------

        Module Random

        include "sysvar.def"

xdef    UpdateRnd

;       update random seed at $01fc-$01ff

.UpdateRnd
        ld      hl, ubRandomPtr                 ; seed index
        inc     (hl)                            ; bump, wrap to $fc if necessary
        jp      m, updr_1
        ld      (hl), <uwRandom1
.updr_1
        ld      l, (hl)                         ; point to $01fc-$01ff
        ld      a, r
        and     $7F                             ; unnecessary?
        ld      (hl), a
        ret

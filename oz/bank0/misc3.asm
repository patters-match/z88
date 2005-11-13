; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0da5
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc3

        include "sysvar.def"

xdef    MayDrawOZwd
xdef    SetPendingOZwd
xdef    Delay300Kclocks

xref    DrawOZwd                                ; bank0/ozwindow.asm



;       draw OZ window if needed

.MayDrawOZwd
        push    bc
        push    de
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_OZWINDOW, (hl)
        call    nz, DrawOZwd
        pop     de
        pop     bc
        ret

;       ----

;       request OZ window redraw

.SetPendingOZwd
        ld      hl, ubIntTaskToDo
        set     ITSK_B_OZWINDOW, (hl)
        ret

;       ----

;       delay ~300 000 clock cycles

.Delay300Kclocks
        ld      hl, 10000                       ; 10 000*30 cycles
        ld      b, $ff
.dlay_1
        ld      c, $ff                          ; 7+11+12 cycles
        add     hl, bc
        jr      c, dlay_1
        ret


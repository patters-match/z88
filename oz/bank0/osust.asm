; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3e6d
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSUst

        org     $fe6d                           ; 42 bytes

        include "all.def"
        include "sysvar.def"
        include "bank7.def"

xdef    OSUst

xref    OSFramePush
xref    PutOSFrame_BC
xref    OSFramePop

;       update small timer
; 
;       old timer(BC)=new timer(BC)
;       Fz according to old time, A=EC_Time if Fz=1

.OSUst                                          
        call    OSFramePush
        ld      hl, 0
        ld      de, (uwSmallTimer)              ; small  timer
        ld      (uwSmallTimer), hl              ; reset
        ld      hl, ubIntTaskToDo
        res     ITSK_B_TIMER, (hl)
        ld      (uwSmallTimer), bc              ; set new time
        ld      b, d                            ; restore old value
        ld      c, e
        call    PutOSFrame_BC

        ld      a, b
        or      c
        jr      nz, osust_1
        ld      (iy+OSFrame_A), RC_Time         ; Timeout
        set     6, (iy+OSFrame_F)               ; Fz=1
.osust_1                                        
        jp      OSFramePop

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0449
;
; $Id$
; -----------------------------------------------------------------------------

        Module  OsOut

        include "director.def"
        include "sysvar.def"

xdef    OSOut

xref    OSFramePush                             ; bank0/misc4.asm
xref    osfpop_1                                ; bank0/misc4.asm

xref    OSOutMain                               ; bank7/scrdrv1.asm


;       ----

;       write   character to standard output

.OSOut
        call    OSFramePush

        ld      c,a
        ld      a, (ubCLIActiveCnt)
        or      a
        ld      a,c
        jr      z, osout_1
        OZ      DC_Out                          ; Write to CLI
        jr      osout_2
.osout_1
        call    OSOutMain
.osout_2
        jp      osfpop_1




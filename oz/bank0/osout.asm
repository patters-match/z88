; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0449
;
; $Id$
; -----------------------------------------------------------------------------

        Module  OsOut

        include "director.def"
        include "sysvar.def"

xdef    OSOut

;       bank 0

xref    OSFramePush
xref    osfpop_1

;       bank 7

xref    OSOutMain

;       ----

;       write   character to standard output

.OSOut
        call    OSFramePush

        ld      bc, (ubCLIActiveCnt)
        inc     c
        dec     c
        jr      z, osout_1
        OZ      DC_Out                          ; Write to CLI
        jr      osout_2

.osout_1
        call    OSOutMain

.osout_2
        jp      osfpop_1



; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0449
;
; $Id$
; -----------------------------------------------------------------------------

        Module  OsOut

        include "all.def"
        include "sysvar.def"

        org     $c449   ; 22 bytes

xdef    OSOut

defc    OSFramePush             =$d555
defc    OSOutMain               =$ac5b
defc    osfpop_1                =$d584


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

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $06c9
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSCli0

        org     $c6c9                           ; 27 bytes

        include "all.def"
        include "sysvar.def"

xdef    OSCli

defc    OSFramePush     =$d555
defc    OSCliMain       =$99cb
defc    OSFramePop      =$d582
defc    OZCallReturn2   =$00ac

.OSCli                                          
        ex      af, af'
        or      a
        jr      z, oscli_0                      ; !! undocumented reason 0
        ex      af, af'
        call    OSFramePush
        ld      h, b                            ; exchange A and B
        ld      b, a
        ld      a, h
        call    OSCliMain
        jp      OSFramePop

;       A=0 - return CLIActiveCnt and KbdData

.oscli_0                                        
        ld      a, (ubCLIActiveCnt)
        ld      ix, KbdData
        jp      OZCallReturn2

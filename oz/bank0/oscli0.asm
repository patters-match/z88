; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $06c9
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSCli0

        include "sysvar.def"
        include "bank7\lowram.def"

xdef    OSCli

;       bank 0

xref    OSFramePop
xref    OSFramePush

;       bank 7

xref    OSCliMain

;       ----

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

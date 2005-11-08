; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3e97
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSTables

        defs    $3b   ($ff)                     ; to be removed with makeapp
        
        org     $FF00                           ; fixed start @ $00FF00
        
xdef    OZBuffCallTable
xdef    OZCallTable
        
;       bank 0

xref    BfGbt
xref    BfPbt
xref    BfPur
xref    BfSta
xref    BufRead
xref    BufWrite
xref    CallDC
xref    CallGN
xref    CallOS2byte
xref    CopyMemBHL_DE
xref    OSAlm
xref    OSAxp
xref    OSBde
xref    OSBix
xref    OSBlp
xref    OSBox
xref    OSBye
xref    OSCl
xref    OSCli
xref    OSDly
xref    OSDom
xref    OSDor
xref    OSEnt
xref    OSEpr
xref    OSErc
xref    OSErh
xref    OSEsc
xref    OSExit
xref    OSFc
xref    OSFn
xref    OSFramePop
xref    OSFrm
xref    OSFth
xref    OSFwm
xref    OSGb
xref    OSGbt
xref    OSGth
xref    OSHt
xref    OSIn
xref    OSMal
xref    OSMap
xref    OsMcl
xref    OSMfr
xref    OSMgb
xref    OSMop
xref    OSMpb
xref    OSMv
xref    OSNq
xref    OSOff
xref    OSOp
xref    OSOut
xref    OSPb
xref    OSPbt
xref    OSPrt
xref    OSPur
xref    OSSi
xref    OSSp
xref    OSSr
xref    OSStk
xref    OSTin
xref    OSUse
xref    OSUst
xref    OSWait
xref    OSWrt
xref    OSWtb
xref    OSVth
xref    OSXin
xref    OzCallInvalid

;       bank 7

xref    OSDel
xref    OSIsq
xref    OSPoll
xref    OSRen
xref    OSSci
xref    OSWsq

.OZCallTable
        jp      OzCallInvalid
        jp      OSFramePop
        jp      CallOS2byte
        jp      CallGN
        jp      CallDC
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OSBye
        jp      OSPrt
        jp      OSOut
        jp      OSIn
        jp      OSTin
        jp      OSXin
        jp      OSPur
        jp      OzCallInvalid                   ; Os_Ugb
        jp      OSGb
        jp      OSPb
        jp      OSGbt
        jp      OSPbt
        jp      OSMv
        jp      OSFrm
        jp      OSFwm
        jp      OSMop
        jp      OsMcl
        jp      OSMal
        jp      OSMfr
        jp      OSMgb
        jp      OSMpb
        jp      OSBix
        jp      OSBox
        jp      OSNq
        jp      OSSp
        jp      OSSr
        jp      OSEsc
        jp      OSErc
        jp      OSErh
        jp      OSUst
        jp      OSFn
        jp      OSWait
        jp      OSAlm
        jp      OSCli
        jp      OSDor
        jp      OSFc
        jp      OSSi
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid                   ; end at $003F9E

.OZBuffCallTable                                ; relocated at $003F9F
        jp      BufWrite
        jp      BufRead
        jp      BfPbt
        jp      BfGbt
        jp      BfSta
        jp      BfPur                           ; end at $003FB0

; ***** FREE SPACE *****                        ; some code was here and removed for clarity

        defs    $19 ($FF)                       ; $3FCA - $3FB1

; 2-byte calls, OSFrame set up already          ; start at $003FCA

        defw    OSWtb
        defw    OSWrt
        defw    OSWsq
        defw    OSIsq
        defw    OSAxp
        defw    OSSci
        defw    OSDly
        defw    OSBlp
        defw    OSBde
        defw    CopyMemBHL_DE
        defw    OSFth
        defw    OSVth
        defw    OSGth
        defw    OSRen
        defw    OSDel
        defw    OSCl
        defw    OSOp
        defw    OSOff
        defw    OSUse
        defw    OSEpr
        defw    OSHt
        defw    OSMap
        defw    OSExit
        defw    OSStk
        defw    OSEnt
        defw    OSPoll
        defw    OSDom
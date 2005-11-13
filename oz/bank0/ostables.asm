; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3e97
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSTables

        org     $FF00                           ; fixed start @ $00FF00

xdef    OZBuffCallTable
xdef    OZCallTable


xref    BfGbt                                   ; bank0/buffer.asm
xref    BfPbt                                   ; bank0/buffer.asm
xref    BfPur                                   ; bank0/buffer.asm
xref    BfSta                                   ; bank0/buffer.asm
xref    BufRead                                 ; bank0/buffer.asm
xref    BufWrite                                ; bank0/buffer.asm
xref    OSDly                                   ; bank0/buffer.asm
xref    OSPur                                   ; bank0/buffer.asm
xref    OSXin                                   ; bank0/buffer.asm
xref    CallDC                                  ; bank0/misc2.asm
xref    CallGN                                  ; bank0/misc2.asm
xref    CallOS2byte                             ; bank0/misc2.asm
xref    OSAlm                                   ; bank0/misc2.asm
xref    OSEpr                                   ; bank0/misc2.asm
xref    OSPrt                                   ; bank0/misc2.asm
xref    OzCallInvalid                           ; bank0/misc2.asm
xref    OSBix                                   ; bank0/misc4.asm
xref    OSBox                                   ; bank0/misc4.asm
xref    OSFramePop                              ; bank0/misc4.asm
xref    OSAxp                                   ; bank0/memory.asm
xref    OSFc                                    ; bank0/memory.asm
xref    OSMal                                   ; bank0/memory.asm
xref    OsMcl                                   ; bank0/memory.asm
xref    OSMfr                                   ; bank0/memory.asm
xref    OSMgb                                   ; bank0/memory.asm
xref    OSMop                                   ; bank0/memory.asm
xref    OSMpb                                   ; bank0/memory.asm
xref    CopyMemBHL_DE                           ; bank0/misc5.asm
xref    OSBde                                   ; bank0/misc5.asm
xref    OSFn                                    ; bank0/misc5.asm
xref    OSBlp                                   ; bank0/scrdrv4.asm
xref    OSSr                                    ; bank0/scrdrv4.asm
xref    OSDom                                   ; bank0/process2.asm
xref    OSBye                                   ; bank0/process3.asm
xref    OSEnt                                   ; bank0/process3.asm
xref    OSExit                                  ; bank0/process3.asm
xref    OSStk                                   ; bank0/process3.asm
xref    OSUse                                   ; bank0/process3.asm
xref    OSCl                                    ; bank0/filesys2.asm
xref    OSFrm                                   ; bank0/filesys2.asm
xref    OSFwm                                   ; bank0/filesys2.asm
xref    OSGb                                    ; bank0/filesys2.asm
xref    OSGbt                                   ; bank0/filesys2.asm
xref    OSMv                                    ; bank0/filesys2.asm
xref    OSOp                                    ; bank0/filesys2.asm
xref    OSPb                                    ; bank0/filesys2.asm
xref    OSPbt                                   ; bank0/filesys2.asm
xref    OSCli                                   ; bank0/oscli0.asm
xref    OSDor                                   ; bank0/dor.asm
xref    OSErc                                   ; bank0/error.asm
xref    OSErh                                   ; bank0/error.asm
xref    OSEsc                                   ; bank0/esc.asm
xref    OSFth                                   ; bank0/handle.asm
xref    OSGth                                   ; bank0/handle.asm
xref    OSVth                                   ; bank0/handle.asm
xref    OSHt                                    ; bank0/time.asm
xref    OSIn                                    ; bank0/osin.asm
xref    OSTin                                   ; bank0/osin.asm
xref    OSNq                                    ; bank0/spnq0.asm
xref    OSSp                                    ; bank0/spnq0.asm
xref    OSOff                                   ; bank0/nmi.asm
xref    OSWait                                  ; bank0/nmi.asm
xref    OSOut                                   ; bank0/osout.asm
xref    OSSi                                    ; bank0/ossi.asm
xref    OSUst                                   ; bank0/osust.asm
xref    OSWrt                                   ; bank0/token.asm
xref    OSWtb                                   ; bank0/token.asm

xref    OSMap                                   ; bank7/osmap.asm
xref    OSDel                                   ; bank7/filesys1.asm
xref    OSRen                                   ; bank7/filesys1.asm
xref    OSIsq                                   ; bank7/scrdrv1.asm
xref    OSWsq                                   ; bank7/scrdrv1.asm
xref    OSPoll                                  ; bank7/process1.asm
xref    OSSci                                   ; bank7/ossci.asm


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

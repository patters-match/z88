; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3e97
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc6

        org     $fe97                           ; 361 bytes

        include "all.def"
        include "sysvar.def"
        include "bank7.def"

xdef    Reset4
xdef    MountAllRAM
xdef    OZBuffCallTable
xdef    Chk128KB
xdef    Chk128KBslot0
xdef    FirstFreeRAM


xref    MS2BankK1
xref    MS1BankA
xref    BufWrite
xref    BufRead
xref    BfPbt
xref    BfGbt
xref    BfSta
xref    BfPur
xref    OzCallInvalid
xref    OSFramePop
xref    CallOS2byte
xref    CallGN
xref    CallDC
xref    OSBye
xref    OSPrt
xref    OSOut
xref    OSIn
xref    OSTin
xref    OSXin
xref    OSPur
xref    OSGb
xref    OSPb
xref    OSGbt
xref    OSPbt
xref    OSMv
xref    OSFrm
xref    OSFwm
xref    OSMop
xref    OsMcl
xref    OSMal
xref    OSMfr
xref    OSMgb
xref    OSMpb
xref    OSBix
xref    OSBox
xref    OSNq
xref    OSSp
xref    OSSr
xref    OSEsc
xref    OSErc
xref    OSErh
xref    OSUst
xref    OSFn
xref    OSWait
xref    OSAlm
xref    OSCli
xref    OSDor
xref    OSFc
xref    OSSi
xref    OSWtb
xref    OSWrt
xref    OSAxp
xref    OSDly
xref    OSBlp
xref    OSBde
xref    CopyMemBHL_DE
xref    OSFth
xref    OSVth
xref    OSGth
xref    OSCl
xref    OSOp
xref    OSOff
xref    OSUse
xref    OSEpr
xref    OSHt
xref    OSMap
xref    OSExit
xref    OSStk
xref    OSEnt
xref    OSDom

.Reset4
        call    MS2BankK1
        jp      Reset5

;       ----

.MountAllRAM
        call    MS2BankK1
        ld      hl, RAMDORtable
.maram_1
        ld      a, (hl)                         ; 21 21 40 80 c0  bank
        inc     hl
        or      a
        jr      z, maram_5
        call    MS1BankA
        ld      d, $40                          ; address high byte
        ld      e, (hl)                         ; 80 40 40 40 40  address low byte
        inc     hl
        ld      c, (hl)                         ;  -  0  1  2  3  RAM number
        inc     hl
        ld      a, c
        cp      '-'
        jr      z, maram_2
        ld      a, (de)                         ; skip if no RAM
        or      a
        jr      nz, maram_1
.maram_2
        push    hl
        ld      a, c
        cp      '-'                             ; !! combine with above check
        jr      z, maram_3
        ex      af, af'
        ld      hl, $4000
        ld      a, (ubResetType)                ; 0 = hard reset
        and     (hl)
        jr      nz, maram_4                     ; soft reset & already tagged, skip
        ex      af, af'
.maram_3
        ld      hl, RAMxDOR                     ; !! could be smaller without table
        ld      bc, 17
        ldir
        ld      (de), a
        inc     de
        ld      bc, 2                           ; just copy 00 FF
        ldir
        cp      '-'                             ; tag RAM if not RAM.-
        jr      z, maram_4
        ld      bc, $a55a
        ld      ($4000), bc
.maram_4
        pop     hl
        jr      maram_1
.maram_5
        ret

.OZBuffCallTable
        jp      BufWrite
        jp      BufRead
        jp      BfPbt
        jp      BfGbt
        jp      BfSta
        jp      BfPur

        defs    5 ($ff)

;       org     $ff00

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
        jp      OzCallInvalid

;       ----

.Chk128KB
        ld      a, (ubSlotRamSize+1)            ; RAM in slot1
        cp      8
        ret     nc

;       ----

.Chk128KBslot0
        ld      a, (ubSlotRamSize)              ; RAM in slot0
        cp      8                               ; Fc=1 if less than 128KB
        ret

;       ----

.FirstFreeRAM
        call    Chk128KBslot0
        ld      a, $21
        jr      nc, ffr_1                       ; !! ret nc
        ld      a, $40
.ffr_1
        ret

        defs    21 ($ff)

;       org     $ffca

; 2-byte calls, OSFrame set up already

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


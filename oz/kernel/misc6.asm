; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3e97
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc6

        org     $fe97                           ; 350 bytes

        include "sysvar.def"

xdef    Chk128KB
xdef    Chk128KBslot0
xdef    FirstFreeRAM
xdef    MountAllRAM
xdef    OZBuffCallTable
xdef    OZCallTable
xdef    MayDrawOZwd
xdef    SetPendingOZwd

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
xref    DrawOZwd
xref    MS1BankA
xref    MS2BankK1
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

xref	OSBi1
xref	OSBo1

;       bank 7

xref    OSDel
xref    OSIsq
xref    OSPoll
xref    OSRen
xref    OSSci
xref    OSWsq
xref    RAMDORtable
xref    RAMxDOR

;       ----


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

; if    >($PC^OZBuffCallTable) <> 0
;       error   "OZBuffCallTable crosses page bundary"
; endif

; if    $PC <> OZCALLTBL
;       error   "OZCALL table moved"
; endif
        
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
 if 0
        jp      OzCallInvalid
        jp      OzCallInvalid
 else
	jp	OSBi1
	jp	OSBo1
 endif
        jp      OzCallInvalid
        jp      OzCallInvalid
        jp      OzCallInvalid

;       ----

.Chk128KB
        ld      a, (ubSlotRamSize+1)            ; RAM in slot1
        cp      128/16
        ret     nc

;       ----

.Chk128KBslot0
        ld      a, (ubSlotRamSize)              ; RAM in slot0
        cp      128/16                          ; Fc=1 if less than 128KB
        ret

;       ----

.FirstFreeRAM
        call    Chk128KBslot0
        ld      a, $21
        jr      nc, ffr_1                       ; !! ret nc
        ld      a, $40
.ffr_1
        ret

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


	defb	$ff,$ff

; if    $PC&255 <> OS_Wtb&255
;       error   "OZCALL2 table moved"
; endif

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


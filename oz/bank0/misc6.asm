; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3e97
;
; $Id$
; -----------------------------------------------------------------------------

        Module Misc6

        org     $fe97                           ; 361 bytes

        include "all.def"
        include "sysvar.def"

xdef    Reset4
xdef    MountAllRAM
xdef    OZBuffCallTable
xdef    Chk128KB
xdef    Chk128KBslot0
xdef    FirstFreeRAM


defc    MS2BankK1                       =$d71f
defc    Reset5                          =$9816
defc    RAMDORtable                     =$9670
defc    MS1BankA                        =$d710
defc    RAMxDOR                         =$9803

defc    BufWriteA                       =$c5fa
defc    BufRead                         =$c639
defc    BfPbt                           =$c538
defc    BfGbt                           =$c4ba
defc    BfSta                           =$c470
defc    BfPur                           =$c493

defc    OzCallInvalid                   =$c149
defc    OSFramePop                      =$d582
defc    CallOS2byte                     =$c10b
defc    CallGN                          =$c105
defc    CallDC                          =$c101
defc    OzCall_OS_Bye                   =$c95a
defc    OSPrt                           =$c150
defc    OSOut                           =$c449
defc    OzCall2A_OS_In                  =$eec2
defc    OzCall2D_OS_Tin                 =$eeb7
defc    OSXin                           =$c59c
defc    OSPur                           =$c5e2
defc    OSGb                            =$d351
defc    OSPb                            =$d384
defc    OSGbt                           =$d35c
defc    OSPbt                           =$d38f
defc    OSMv                            =$d2ec
defc    OSFrm                           =$d3ba
defc    OSFwm                           =$d476
defc    OSMop                           =$e584
defc    OsMcl                           =$e58d
defc    OSMal                           =$e596
defc    OSMfr                           =$e5ab
defc    OSMgb                           =$e5c0
defc    OSMpb                           =$e5df
defc    OSBix                           =$d59a
defc    OSBox                           =$d593
defc    OSNq                            =$f1b6
defc    OSSp                            =$f1ac
defc    OSSr                            =$fe29
defc    OSEsc                           =$d0cc
defc    OSErc                           =$d07d
defc    OSErh                           =$d05d
defc    OSUst                           =$fe6d
defc    OSFn                            =$d7c3
defc    OSWait                          =$ceed
defc    OSAlm                           =$c1eb
defc    OSCli                           =$c6c9
defc    OSDor                           =$ca25
defc    OSFc                            =$e608
defc    OSSi                            =$d526

defc    OSWtb                           =$edbd
defc    OSWrt                           =$edde
defc    OSWsq                           =$adc4
defc    OSIsq                           =$adb8
defc    OSAxp                           =$e148
defc    OSSci                           =$9506
defc    OSDly                           =$c45f
defc    OSBlp                           =$fdf5
defc    OSBde                           =$d784
defc    CopyMemBHL_DE                   =$d795
defc    OSFth                           =$d5e5
defc    OSVth                           =$d5eb
defc    OSGth                           =$d5d1
defc    OSRen                           =$9d0c
defc    OSDel                           =$9d1f
defc    OSCl                            =$d2a8
defc    OSOp                            =$d1f8
defc    OSOff                           =$ce21
defc    OSUse                           =$c9a9
defc    OSEpr                           =$c1ca
defc    OSHt                            =$d4bb
defc    OSMap                           =$df22
defc    OSExit                          =$c6e4
defc    OSStk                           =$c926
defc    OSEnt                           =$c6e8
defc    OSPoll                          =$9aeb
defc    OSDom                           =$c23a

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
        jp      BufWriteA
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
        jp      OzCall_OS_Bye
        jp      OSPrt
        jp      OSOut
        jp      OzCall2A_OS_In
        jp      OzCall2D_OS_Tin
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


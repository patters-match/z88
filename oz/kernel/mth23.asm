; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $2789
;
; $Id$
; -----------------------------------------------------------------------------

        Module MTH2

        org     $e789                           ; 598 bytes
						; 324
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "memory.def"
        include "stdio.def"
        include "sysvar.def"

;	all xdefs for mth.asm

xdef    CopyAppPointers
xdef    FilenameDOR
xdef    PrintTopic
xdef    PrntAppname
xdef	GetSlotApp
xdef	PrintActiveTopic
xdef	PrntCommand

xref    GetCmdTopicByNum
xref    GetRealCmdPosition
xref    InitHandle
xref    MayWrt
xref    MS2BankK1
xref    MTH_ToggleLT
xref    SkipNTopics
xref    ZeroHandleIX
xref	GetHlpCommands
xref	GetHlpTopics


;       ----

.PrntAppname
        ld      a, (ubHlpActiveApp)
        call    GetAppDOR
        OZ      OS_Bi1
        ld      bc, ADOR_NAME                   ; skip to DOR name
        add     hl, bc

.pan_1
        ld      a, (hl)                         ; print string
        inc     hl
        OZ      OS_Out
        or      a
        jr      nz, pan_1

        OZ      OS_Bo1
        ret


;       ----

.PrintActiveTopic
        ld      a, (ubHlpActiveTpc)

.PrintTopic
        push    af
        push    af
        call    GetHlpTopics
        OZ      OS_Bi1
        pop     af
        push    de

        call    SkipNTopics
	inc	hl				; skip length byte
        call    MTH_ToggleLT

.ptpc_1
        ld      a, (hl)                         ; print tokenized string
        inc     hl
        call    MayWrt
        jr      nc, ptpc_1

        call    MTH_ToggleLT
        pop     de
        OZ      OS_Bo1
        pop     af
        ret

;       ----

.PrntCommand
        call    GetHlpCommands
        OZ      OS_Bi1
        ld      a, (ubHlpActiveCmd)
        push    de

        push    af
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        pop     af

        call    GetRealCmdPosition
	inc	hl				; skip length/command code
	inc	hl

.prc_1
        ld      a, (hl)                         ; skip kbd sequence
        inc     hl
        or      a
        jr      nz, prc_1

.prc_2
        ld      a, (hl)                         ; print tokenized sring
        inc     hl
        call    MayWrt
        jr      nc, prc_2

        pop     de
        OZ      OS_Bo1
        ret


;       ----

; copy topic/command/help/token pointers

.CopyAppPointers
        push    af
        ld      bc, 4<<8|255                    ; 4 loops, C=255 to make sure no underflow from C to B
        ld      de, eHlpTopics
.cap_1
        ldi
        ldi
        ld      a, (hl)
        or      a
        jr      z, cap_2                        ; bank=0? leave alone
        and     $3F                             ; else fix slot
        or      (ix+dhnd_AppSlot)
.cap_2
        ld      (de), a
        inc     hl
        inc     de
        djnz    cap_1
        pop     af
        ret

;       ----

.GetSlotApp
        ld      ix, ActiveAppHandle
        call    ZeroHandleIX

        ld      (ix+hnd_Type), HND_DEV
        add     a, $80                          ; ROM.x
        call    InitHandle                      ; init handle
        ret     c

        ld      a, DR_SON                       ; return child DOR
.gsa_1
        OZ      OS_Dor
        ret     c                               ; error? exit

        cp      DN_APL
        ld      a, DR_SIB                       ; return brother DOR
        jr      nz, gsa_1                       ; not app? try brother

        ld      a, DR_SON                       ; return child DOR
        OZ      OS_Dor                          ; DOR interface
        ret

;       ----

.FilenameDOR
        push    bc
        ld      a, OP_DOR                       ; return DOR handle
        ld      bc, 0<<8|255                    ; local pointer, bufsize=255
        ld      de, 3                           ; ouput=3, NOP
        OZ      GN_Opf
        pop     bc
        ret



xref	fsMS2BankB

.SetActiveAppDOR
        ld      (ubHlpActiveApp), a

; IN: A=application ID
; OUT: BHL=DOR

.GetAppDOR
        ld      b, OZBANK_LO                    ; bind in other part of kernel
        call    fsMS2BankB                      ; remembers S2
        push    de
        push    ix

        ld      e, a                            ; remember A
        and     $3F                             ; mask out slot
        jr      nz, appdor_3                    ; #app not 0? it's ok

        dec     e                               ; last app in prev slot
.appdor_1
        ld      d, a                            ; remember #app
        inc     a
        call    GetAppDOR
        jr      c, appdor_2                     ; end of list
        cp      e
        jr      c, appdor_1                     ; loop until E passed
        jr      z, appdor_1
.appdor_2
        ld      a, d
        call    GetAppDOR
        jr      appdor_10

.appdor_3
        ld      a, e                            ; restore A
.appdor_4
        push    af
        and     $3F
        ld      c, a                            ; app#
        pop     af
	xor	c
        ld      b, a                            ; slot
        rlca
        rlca
        push    bc
        call    GetSlotApp
        pop     bc
        jr      c, appdor_5                     ; no apps in slot? skip
        ld      a, b
        xor     (ix+dhnd_AppSlot)
        and     $c0
        jr      z, appdor_7                     ; same slot
.appdor_5
        ld      a, b
        and     $c0
        add     a, $40                          ; next slot
        jr      z, appdor_8
        inc     a                               ; xx000001 - first app in this slot
        jr      appdor_4

.appdor_6
        ld      a, DR_SIB                       ; return brother DOR
        OZ      OS_Dor
        jr      c, appdor_5                     ; no brother? next slot

.appdor_7
        inc     b                               ; next app
        dec     c                               ; dec count
        jr      nz, appdor_6

        ld      a, b                            ; a=#app
        or      a                               ; Fc=0
        jr      appdor_9

.appdor_8
        xor     a
        call    GetSlotApp
        ld      a, RC_Esc
        scf

.appdor_9
        push    af
        call    GetHandlePtr
        ld      (eHlpAppDOR+2), a
        ld      (eHlpAppDOR), hl
        ld      bc, ADOR_TOPICS
        add     hl, bc
        ld      a, (pMTHHelpHandle+1)
        or      a
        call    z, CopyAppPointers
        call    MS2BankK1
        pop     af
.appdor_10
        pop     ix
        pop     de
        call    fsRestoreS2
        ld      hl, [eHlpAppDOR+2]
        jp      GetBHLBackw

xref    GetHandlePtr
xref	fsRestoreS2
xref	GetBHLBackw

xdef	SetActiveAppDOR
xdef	GetAppDOR


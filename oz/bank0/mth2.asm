; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $2789
;
; $Id$
; -----------------------------------------------------------------------------

        Module MTH2

        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "stdio.def"
        include "sysvar.def"
        include "../mth/mth.def"


xdef    aRom_Help
xdef    ChgHelpFile
xdef    CopyAppPointers
xdef    DrawCmdHelpWd
xdef    DrawMenuWd
xdef    DrawTopicHelpWd
xdef    FilenameDOR
xdef    GetAppCommands
xdef    GetAppDOR
xdef    GetAttr
xdef    GetCmdTopicByNum
xdef    GetHlp_sub
xdef    GetHlpCommands
xdef    GetHlpHelp
xdef    GetHlpTokens
xdef    GetHlpTopics
xdef    GetRealCmdPosition
xdef    InputEmpty
xdef    MayMTHPrint
xdef    MTHPrint
xdef    MTHPrintKeycode
xdef    MTHPrintTokenized
xdef    NextAppDOR
xdef    PrevAppDOR
xdef    PrintChar
xdef    PrintTopic
xdef    PrntAppname
xdef    SetActiveAppDOR
xdef    SetHlpAppChgFile
xdef    SkipNTopics

xref    OSBixS1                                 ; bank0/misc4.asm
xref    OSBoxS1                                 ; bank0/misc4.asm
xref    AtoN_upper                              ; bank0/misc5.asm
xref    KPrint                                  ; bank0/misc5.asm
xref    MS2BankK1                               ; bank0/misc5.asm
xref    MTH_ToggleLT                            ; bank0/misc5.asm
xref    ResetToggles                            ; bank0/misc5.asm
xref    ScrDrv_SOH_A                            ; bank0/misc5.asm
xref    fsMS2BankB                              ; bank0/filesys3.asm
xref    fsRestoreS2                             ; bank0/filesys3.asm
xref    Get2ndCmdHelp                           ; bank0/mth3.asm
xref    Get2ndTopicHelp                         ; bank0/mth3.asm
xref    GetFirstCmdHelp                         ; bank0/mth3.asm
xref    GetTpcAttrByNum                         ; bank0/mth3.asm
xref    GetHandlePtr                            ; bank0/dor.asm
xref    MayWrt                                  ; bank0/token.asm
xref    OSWrt                                   ; bank0/token.asm
xref    ZeroHandleIX                            ; bank0/handle.asm

xref    DrawMenuWd2                             ; bank7/mth1.asm
xref    Help2Wd_bottom                          ; bank7/mth1.asm
xref    Help2Wd_Top                             ; bank7/mth1.asm
xref    InitHelpWd                              ; bank7/mth1.asm
xref    OpenAppHelpFile                         ; bank7/mth1.asm
xref    InitHandle                              ; bank7/misc1.asm


;       print MTH string, expand $7f-codes

.mthp_0
        bit     0, c                            ; if C not xxxxxx00 then try again
        jr      z, mthp_1
        bit     1, c
        jr      z, mthp_1

        ld      e, (hl)                         ; jump to function
        inc     hl
        ld      d, (hl)
        call    Jp_DE

.MTHPrint
        ex      (sp), hl                        ; get char from caller PC
        ld      a, (hl)
        inc     hl
        ex      (sp), hl
        or      a
        ret     z                               ; null? exit
        cp      $7f
        jr      nz, mthp_2                      ; not 7F, print

        ex      (sp), hl                        ; get next byte
        ld      a, (hl)
        inc     hl
        ex      (sp), hl
        cp      $7f                             ; 7F, print as is
        jr      z, mthp_2

        and     $df                             ; upper()
        ld      bc, 32
        ld      hl, mthp_tbl                    ; command table
.mthp_1
        cpir                                    ; !! don't use cpir, use sorted table like in new kbd routines
        jr      z, mthp_0                       ; found, execute it

.mthp_2
        OZ      OS_Out                          ; print char and loop back
        jr      MTHPrint

;       char, function, pad

.mthp_tbl
        defb    'A'
        defw    PrntAppname
        defb    0

        defb    'T'
        defw    PrintActiveTopic
        defb    0

        defb    'F'
        defw    PrntCommand
        defb    0

        defb    'C'
        defw    JustifyC
        defb    0

        defb    'L'
        defw    JustifyL
        defb    0

        defb    'N'
        defw    JustifyN
        defb    0

        defb    'R'
        defw    JustifyR
        defb    0

        defb    'D'
        defw    ResetToggles
        defb    0

;       ----

.Jp_DE
        push    de
        ret

;       ----

;       !! A keeps justi char alredy, just 'ld b,a' to handle all cases

.JustifyC
        ld      b, 'C'
        jr      just_sub
.JustifyL
        ld      b, 'L'
        jr      just_sub
.JustifyR
        ld      b, 'R'
        jr      just_sub
.JustifyN
        ld      b, 'N'
.just_sub
        ld      a, '2'
        call    ScrDrv_SOH_A
        ld      a, 'J'
        OZ      OS_Out
        ld      a, b

;       ----

.PrintChar
        OZ      OS_Out
        ret

;       ----

.DrawTopicHelpWd
        call    InitHelpWd
        ret     c                               ; input pending? exit

        call    MTHPrint
        defm    "The ", $7f,"A", " ", $7f,"T", " topic",10,0

        call    GetHlpTopics
        call    OSBixS1
        push    de

        ld      a, (ubHlpActiveTpc)
        call    SkipNTopics
        call    GetHelpOffs
        ld      b, d
        ld      c, e
        pop     de
        call    OSBoxS1

        call    PrintTopicHelp
        ret     c
        call    Help2Wd_Top
        ret     c

        call    Get2ndTopicHelp
        jr      c, dth_1                        ; no more help? skip

        call    MayMTHPrint
        defm    $7f,"L"
        defm    " other ", $7f,"A", " topics"
        defm    $7f,"R"
        defm    SOH,SD_OUP,"  ",10
        defm    $7f,"R"
        defm    SOH,SD_ODWN,"  ",11,0

.dth_1
        call    MayMTHPrint
        defm    10, 10
        defm    $7f,"L"
        defm    " ", $7f,"A"
        defm    $7f,"R"
        defm    SOH,SD_OLFT,"   ",10,0

        call    GetFirstCmdHelp
        jr      c, dth_2                        ; no command help? skip

        call    MayMTHPrint
        defm    $7f,"L"
        defm    " the ", $7f,"T", " entries",0

        call    MayMTHPrint                     ; !! join this to above
        defm    $7f,"R"
        defm    SOH,SD_ORGT," ",0

.dth_2
        jp      Help2Wd_bottom

;       ----

.DrawCmdHelpWd
        call    InitHelpWd
        ret     c

        call    MTHPrint
        defm    $7f,"A", " ",SOH,SD_GRV, $7f,"F"
        defm    $7f,"D"
        defm    $7f,"C"
        defm    "'",0

        call    GetHlpCommands
        call    OSBixS1
        push    de
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        ld      a, (ubHlpActiveCmd)
        call    GetRealCmdPosition
        call    PrintCmdSequence
        call    GetHelpOffs
        ld      b, d
        ld      c, e
        pop     de
        call    OSBoxS1

        call    PrintTopicHelp
        ret     c
        call    Help2Wd_Top
        call    Get2ndCmdHelp
        jr      c, dch_1                        ; no other enties? skip

        call    MayMTHPrint
        defm    $7f,"L"
        defm    " other ", $7f,"T", " entries"
        defm    $7f,"R"
        defm    SOH,SD_OUP,"  ",10
        defm    $7f,"R"
        defm    SOH,SD_ODWN,"  ",11,0

.dch_1
        ld      a, 10
        OZ      OS_Out

        call    MayMTHPrint
        defm    10
        defm    $7f,"L"
        defm    " the ", $7f,"T", " topic"
        defm    $7f,"R"
        defm    SOH,SD_OLFT,"   ",10,0

        jp      Help2Wd_bottom

;       ----

.PrntAppname
        ld      a, (ubHlpActiveApp)
        call    GetAppDOR
        call    OSBixS1
        ld      bc, ADOR_NAME                   ; skip to DOR name
        add     hl, bc

.pan_1
        ld      a, (hl)                         ; print string
        inc     hl
        OZ      OS_Out
        or      a
        jr      nz, pan_1

        call    OSBoxS1
        ret

;       ----

.PrintActiveTopic
        ld      a, (ubHlpActiveTpc)

.PrintTopic
        push    af
        push    af
        call    GetHlpTopics
        call    OSBixS1
        pop     af
        push    de

        call    SkipNTopics
        inc     hl                              ; skip length byte
        call    MTH_ToggleLT

.ptpc_1
        ld      a, (hl)                         ; print tokenized string
        inc     hl
        call    MayWrt
        jr      nc, ptpc_1

        call    MTH_ToggleLT
        pop     de
        call    OSBoxS1
        pop     af
        ret

;       ----

.PrntCommand
        ld      a, (ubHlpActiveCmd)             ; !! get this after OS_Bix to avoid push/pop
        push    af
        call    GetHlpCommands
        call    OSBixS1
        pop     af
        push    de

        push    af
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        pop     af

        call    GetRealCmdPosition
        inc     hl                              ; skip length/command code
        inc     hl

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
        call    OSBoxS1
        ret

;       ----

.PrintTopicHelp
        call    InputEmpty
        ret     c                               ; input bending? exit
        ld      a, b
        or      c
        ret     z                               ; no help text? exit

        ld      d, b                            ; help offset into DE
        ld      e, c
        call    GetHlpHelp                      ; get help base
        add     hl, de                          ; go to help text start
        ld      a, h                            ; handle bank change
        rlca
        rlca
        and     3
        add     a, b
        ld      b, a
        res     7, h                            ; S0 fix
        res     6, h

;       ----

.MTHPrintTokenized
        call    InputEmpty
        ret     c
        call    OSBixS1
        push    de
        call    JustifyC
.mpt_1
        call    InputEmpty
        jr      c, mpt_2
        ld      a, (hl)
        inc     hl
        call    OSWrt
        jr      nc, mpt_1                       ; no error/end? print more
.mpt_2
        pop     de
        call    OSBoxS1
                                                ; drop thru

;       ----

;OUT:   Fc=1 if input bending

.InputEmpty
        OZ      OS_Xin                          ; examine input
        exx
        ld      hl, ubSysFlags1
        res     SF1_B_INPUTPENDING, (hl)
        jr      c, xin_1
        set     SF1_B_INPUTPENDING, (hl)
.xin_1
        exx
        ccf
        ret

;       ----

.MayMTHPrint
        call    InputEmpty
        jp      nc, MTHPrint                    ; only print if not pre-empted
        inc     sp                              ; double ret  !! should we get rid of this?  it's
        inc     sp                              ; !! potentially dangerous if one forgets it
        ret

;       ----

.aRom_Help
        defm    ":ROM.*/HELP/"

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

;       ----

.NextAppDOR
        ld      a, (ubHlpActiveApp)
        inc     a
        jr      AppDOR_sub

.PrevAppDOR
        ld      a, (ubHlpActiveApp)
        dec     a

.AppDOR_sub
        call    GetAppDOR
        ld      (ubHlpActiveApp), a
        ret

;       ----

.SetActiveAppDOR
        ld      (ubHlpActiveApp), a

; IN: A=application ID
; OUT: BHL=DOR

.GetAppDOR
        ld      b, OZBANK_7                     ; bind in other part of kernel, ERROR HERE but $0F hangs...
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
        and     $c0                             ; !! xor c
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
        jr      GetBHLBackw

;       ----

.GetHlpHelp
        ld      l, <(eHlpHelp+2)
        jr      GetHlp_sub

.GetHlpTokens
        ld      hl, ubSysFlags1
        bit     SF1_B_NOTOKENS, (hl)            ; no tokens?
        ld      b, OZBANK_MTH
        ld      hl, SysTokenBase
        ret     nz
        ld      l, <(eHlpTokens+2)
        jr      GetHlp_sub

.GetHlpTopics
        ld      l, <(eHlpTopics+2)
        jr      GetHlp_sub

; out: BHL=commands for suspended app
.GetAppCommands
        ld      hl, [eAppCommands_2+2]
        jr      GetBHLBackw

; out: BHL=help
.GetHlpCommands
        ld      l, <(eHlpCommands+2)

.GetHlp_sub
        ld      h, >eHlpTopics

        push    hl                              ; if help DOR matches app DOR, use app pointer
        ld      hl, (eAppDOR_2)                 ; otherwise use help pointer
        ld      bc, (eHlpAppDOR)
        or      a
        sbc     hl, bc
        pop     hl                              ; !! 'jr nz' to lower pop to save pop/push here
        jr      nz, GetBHLBackw                 ; not same, use help pointers
        push    hl
        ld      hl, [eAppDOR_2+2]
        ld      a, (eHlpAppDOR+2)
        cp      (hl)
        pop     hl
        jr      nz, GetBHLBackw

        ld      bc, eAppTopics_2-eHlpTopics
        add     hl, bc

.GetBHLBackw
        ld      b, (hl)
        dec     hl
        ld      c, (hl)
        dec     hl
        ld      l, (hl)
        ld      h, c
        res     7, h                            ; S0 fix
        res     6, h
        ret

;       ----

; IN: A=count
; OUT: Fc=1, A=0 - last command

.SkipNTopics
        push    af                              ; store count
        inc     hl                              ; skip start mark
        call    NextCommand                     ; validate pointer by going forward and back
        call    PrevCommand
        pop     bc                              ; count into B
        ld      a, 0
        ret     c                               ; only one command/topic? exit Fc=1
        ld      c, a                            ; c = 0
.gcn_1
        inc     c
        djnz    gcn_2
        ld      a, c                            ; Fc=0, A=count
        ret
.gcn_2
        call    NextCommand
        jr      nc, gcn_1                       ; not end of list? loop
        ld      a, b
        or      a
        jp      p, gcn_3
        call    PrevCommand                     ; go back to last vommand/topic
        ld      a, c                            ; return count
        scf
        ret
.gcn_3
        call    PrevCommand                     ; go back to start of topic
        jr      nc, gcn_3
        ld      a, 1
        scf
        ret

;       ----

.GetCmdTopicByNum
        inc     hl                              ; skip start mark
        ld      b, a
.sct_1
        djnz    sct_2
        or      a
        ret
.sct_2
        call    NextTopic
        jr      nc, sct_1
        ret

;       ----

.GetRealCmdPosition
        push    af
.grcp_1
        call    PrevCommand                     ; back to start of topic
        jr      nc, grcp_1
        call    NextCommand                     ; validate by going forward and backward
        call    PrevCommand
        pop     bc                              ; B=count
        ld      a, 0
        ret     c                               ; start of list? Fc=1, A=0
        scf
        ret     z                               ; start of topic? Fc=1
        ld      de, 1<<8|0                      ; column=1, row=0
        ld      c, e                            ; c = 0
.grcp_2
        inc     c                               ; bump actual position
        djnz    grcp_3                          ; not done yet? go forward
        inc     b                               ; B=1 for hidden  !! do this only if necessary
        call    GetAttr
        bit     CMDF_B_HIDDEN, a
        jr      nz, grcp_3                      ; hidden? skip
        ld      a, c                            ; return position in A, Fc=0
        or      a
        ret
.grcp_3
        call    NextCommand
        jr      c, grcp_4                       ; not end of list or topic? go back
        jr      nz, grcp_2
.grcp_4
        ld      a, b                            ; !! bit 7,b; jr z
        or      a                               ; B<0? wanted was hidden, go to previous
        jp      p, grcp_5                       ; else rewind to topic start and search for cmd 1
        call    PrevCommand
        call    GetAttr
        bit     CMDF_B_HIDDEN, a
        jr      nz, grcp_5
        ld      a, c
        scf
        ret
.grcp_5
        call    PrevCommand                     ; back to start of topic
        jr      nc, grcp_5
        ld      a, 1                            ; only way we could here is we searched with A=0, try with 1
        call    GetRealCmdPosition
        ld      de, 1<<8|0                      ; column=1, row=0
        scf
        ret

;       ----

.NextTopic
        call    NextCommand
        ret     c                               ; end mark
        jr      nz, NextTopic                   ; not end_of_topic? loop
        inc     hl                              ; skip eot mark
        ret

;       ----

; IN: HL=command/topic
; OUT: Fc=1, Fz=0 - start of list
; Fc=1, Fz=1 - start of topic
; Fc=0 - HL=command/topic

.PrevCommand
        dec     hl
        ld      a, (hl)                         ; length byte
        cp      1
        inc     hl
        ret     c                               ; 0, start of list- Fc=1, Fz=0
        scf
        ret     z                               ; 1, start of topic - Fc=1, Fz=1
        push    de                              ; HL-=A
        ld      e, a
        ld      d, 0
        or      a
        sbc     hl, de
        pop     de
        jr      c, $PC                          ; error? crash
        ret

;       ----

; IN: HL=command/topic, E=row, D=column
; OUT: Fc=1 - end of list
; Fc=0, Fz=1 - end of topic
; Fc=0, Fz=0 - HL=command/topic, E=row, D=column

.NextCommand
        push    de
        ld      e, (hl)                         ; get length
        ld      d, 0
        add     hl, de                          ; skip current command/topic
        jr      c, $PC                          ; invalid? crash
        pop     de
        ld      a, (hl)                         ; length
        cp      1
        ret     c                               ; 0=start/end mark, Fc=1
        ret     z                               ; 1=topic end, Fz=1
        push    af                              ; store Fc=0, Fz=0
        call    GetAttr                         ; command attribute
        bit     CMDF_B_HIDDEN, a                ; hidden
        jr      nz, nxc_3                       ; yes? skip
        inc     e                               ; advance row
        bit     CMDF_B_COLUMN, a                ; new column
        jr      nz, nxc_2                       ; yes? skip
        ld      a, e
        cp      8                               ; row too big?
        jr      c, nxc_3                        ; no? skip
.nxc_2
        inc     d                               ; advance column
        ld      e, 0                            ; reset row
.nxc_3
        pop     af
        ret

;       ----

.GetHelpOffs
        call    GetAttr_Help
        and     CMDF_HELP                       ; help
        ret     nz                              ; Fc=0, DE=help
        ld      d, a                            ; ld de, 0
        ld      e, a
        ret                                     ; Fc=1, DE=0

;       ----

; IN: HL=command definition
; OUT: A=attribute byte

.GetAttr
        push    de
        call    GetAttr_Help
        pop     de
        ret

;       ----

; IN: HL=command definition
; OUT: A=attribute byte, DE=help text

.GetAttr_Help
        push    bc
        push    hl
        ld      c, (hl)                         ; length byte
        ld      b, 0
        add     hl, bc
        dec     hl
        dec     hl
        ld      a, (hl)                         ; attribute byte
        dec     hl
        ld      e, (hl)                         ; help pointer
        dec     hl
        ld      d, (hl)
        pop     hl
        pop     bc
        ret

;       ----

.SetHlpAppChgFile
        ld      a, (ubHlpActiveApp)             ; !! could do these 2 instructions at caller
        call    GetAppDOR                       ; !! to reduce number of subroutines

.ChgHelpFile
        push    af
        ld      ix, (pMTHHelpHandle)
        ld      a, DR_FRE                       ; free DOR handle
        OZ      OS_Dor                          ; DOR interface
        ld      (pMTHHelpHandle), ix
        pop     af
        or      a
        ret     z
        call    OSBixS1                          ; Bind in extended address
        push    de
        ld      bc, ADOR_NAME
        add     hl, bc
        call    MS2BankK1
        call    OpenAppHelpFile
        ld      (pMTHHelpHandle), ix
        pop     de
        call    OSBoxS1
        ret

;       ----

.DrawMenuWd
        call    KPrint
        defm    1,"6#6",$20+0,$20+0,$20+94,$20+8
        defm    1, "2C6"
        defm    0

        call    GetHlpCommands
        call    OSBixS1
        push    de

        push    hl
        ld      a, (ubHlpActiveTpc)
        call    GetTpcAttrByNum
        pop     hl
        jr      nc, dmwd_1                      ; has topics? skip

        pop     de
        call    OSBoxS1

        call    InitMenuColumnDE
        call    MayMTHPrint
        defm    10,10,10
        defm    $7f,"C"
        defm    $7f,"A", " has no topics",0

        jr      dmwd_2                          ; Fc=1

.dmwd_1
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        call    InitMenuColumnDE
        ld      a, (hl)
        cp      2
        jr      nc, dmwd_3                      ; not eol/eot? skip
        pop     de
        call    OSBoxS1

        call    MayMTHPrint
        defm    10,10,10
        defm    $7f,"C"
        defm    "The ", $7f,"A", " ", $7f,"T", " topic",10
        defm    $7f,"C"
        defm    "has no functions",0

.dmwd_2
        scf
        ret

.dmwd_3
        call    InputEmpty
        jp      c, dmwd_10

        call    GetAttr
        bit     CMDF_B_HIDDEN, a
        jr      nz, dmwd_9                      ; hidden? skip
        push    hl
        inc     hl                              ; move to kbd sequence
        inc     hl

        ex      af, af'
.dmwd_4
        ld      a, (hl)                         ; skip kbd sequence to get cmd name
        inc     hl
        or      a
        jr      nz, dmwd_4
        ex      af, af'

        bit     CMDF_B_COLUMN, a
        jr      nz, dmwd_5                      ; column change? handle
        ld      a, e
        cp      8
        inc     e
        jr      c, dmwd_7                       ; not last row? skip
.dmwd_5
        call    InitMenuColumnE
.dmwd_6
        jr      c, dmwd_11
.dmwd_7
        push    de
        call    JustifyN
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
.dmwd_8
        ld      a, (hl)                         ; print command name
        inc     hl
        call    MayWrt
        jr      nc, dmwd_8
        call    ResetToggles
        pop     de
        pop     hl
        call    PrintCmdSequence
.dmwd_9
        ld      c, (hl)
        ld      b, 0
        add     hl, bc
        ld      a, (hl)
        cp      2
        jr      nc, dmwd_3
        ld      e, 8
        call    InitMenuColumn
        or      a
.dmwd_10
        pop     de
        push    af
        call    OSBoxS1
        pop     af
        call    nc, DrawMenuWd2
        ret
.dmwd_11
        pop     hl
        pop     hl
        jr      dmwd_10

;       ----

.InitMenuColumnDE
        ld      d, 1

.InitMenuColumnE
        ld      e, 27

; e=width
.InitMenuColumn
        push    hl
        ld      b, d
        ld      a, -28                          ; calculate xpos
.imc_1
        add     a, 28                           ; 0/28/56/84
        djnz    imc_1
        add     a, e
        cp      93
        jr      nc, imc_3
        sub     e
        add     a, $21
        bit     4, e
        jr      nz, imc_2
        ld      a, $75
.imc_2
        push    af
        call    KPrint
        defm    1,"7#6",0
        pop     af
        OZ      OS_Out                          ; x
        ld      a, $20
        OZ      OS_Out                          ; y
        ld      a, e
        add     a, $20
        OZ      OS_Out                          ; w

        call    KPrint
        defm    $20+8,$81
        defm    1,"2C6"
        defm    0

        inc     d
        ld      e, 0
        or      a
.imc_3
        pop     hl
        ret

;       ----

.MTHPrintKeycode
        push    de
        push    hl
        ld      c, a
        ld      hl, CmdKeycodeTbl-1
.pkc_1
        inc     hl                              ; !! use sorted table here as well
        ld      a, (hl)
        or      a
        jr      z, pkc_2
        cp      c
        inc     hl
        ld      b, (hl)
        inc     hl
        jr      nz, pkc_1
        ld      a, b
        or      a
        call    nz, ScrDrv_SOH_A
        ld      a, (hl)
        call    ScrDrv_SOH_A
.pkc_2
        pop     hl
        pop     de
        ret

;       inbyte, SOHm, SOHn

.CmdKeycodeTbl
        defb    IN_ESC,  0,       SD_ESC
        defb    IN_TAB0, 0,       SD_TAB
        defb    IN_STAB, SD_SHFT, SD_TAB
        defb    IN_DTAB, SD_DIAM, SD_TAB
        defb    IN_ATAB, SD_SQUA, SD_TAB
        defb    IN_ENTER,0,       SD_ENT
        defb    IN_SENT, SD_SHFT, SD_ENT
        defb    IN_DENT, SD_DIAM, SD_ENT
        defb    IN_AENT, SD_SQUA, SD_ENT
        defb    IN_DELX, 0,       SD_DEL
        defb    IN_SDEL, SD_SHFT, SD_DEL
        defb    IN_DDEL, SD_DIAM, SD_DEL
        defb    IN_ADEL, SD_SQUA, SD_DEL
        defb    IN_LFT,  0,       SD_OLFT
        defb    IN_SLFT, SD_SHFT, SD_OLFT
        defb    IN_DLFT, SD_DIAM, SD_OLFT
        defb    IN_ALFT, SD_SQUA, SD_OLFT
        defb    IN_RGT,  0,       SD_ORGT
        defb    IN_SRGT, SD_SHFT, SD_ORGT
        defb    IN_DRGT, SD_DIAM, SD_ORGT
        defb    IN_ARGT, SD_SQUA, SD_ORGT
        defb    IN_UP,   0,       SD_OUP
        defb    IN_SUP,  SD_SHFT, SD_OUP
        defb    IN_DUP,  SD_DIAM, SD_OUP
        defb    IN_AUP,  SD_SQUA, SD_OUP
        defb    IN_DWN,  0,       SD_ODWN
        defb    IN_SDWN, SD_SHFT, SD_ODWN
        defb    IN_DDWN, SD_DIAM, SD_ODWN
        defb    IN_ADWN, SD_SQUA, SD_ODWN
        defb    IN_MEN,  0,       SD_MNU
        defb    IN_HLP,  0,       SD_HLP
        defb    0

;       ----

.PrintCmdSequence
        push    de
        push    hl

        inc     hl                              ; skip length/code
        inc     hl
        call    ResetToggles
        call    JustifyR

        ld      a, (hl)
        call    AtoN_upper
        jr      nc, pcs_1                       ; a-z/A-Z
        call    MTHPrintKeycode
        jr      pcs_3

.pcs_1
        ld      a, SD_DIAM                      ; print <>
        call    ScrDrv_SOH_A

.pcs_2
        ld      a, (hl)                         ; print string
        inc     hl
        OZ      OS_Out
        or      a
        jr      nz, pcs_2

.pcs_3
        call    KPrint
        defm    " ",13,10,0

        pop     hl
        pop     de
        ret

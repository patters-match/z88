; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1df4c
;
; $Id$
; -----------------------------------------------------------------------------

        Module MTH1

        include "dor.def"
        include "error.def"
        include "stdio.def"
        include "saverst.def"
        include "syspar.def"
        include "sysvar.def"


xdef    DoHelp
xdef    CopyMTHApp_Help
xdef    CopyMTHHelp_App
xdef    DrawMenuWd2
xdef    OpenAppHelpFile
xdef    Help2Wd_Top
xdef    Help2Wd_bottom
xdef    GetCurrentWdInfo
xdef    RestoreActiveWd
xdef    DrawTopicWd
xdef    InitTopicWd
xdef    InitHelpWd
xdef    Get2ndCmdHelp
xdef    GetFirstCmdHelp

xref    aRom_Help                               ; bank0/mth2.asm
xref    ChgHelpFile                             ; bank0/mth2.asm
xref    CopyAppPointers                         ; bank0/mth2.asm
xref    DrawCmdHelpWd                           ; bank0/mth2.asm
xref    DrawTopicHelpWd                         ; bank0/mth2.asm
xref    FilenameDOR                             ; bank0/mth2.asm
xref    GetHlp_sub                              ; bank0/mth2.asm
xref    GetHlpHelp                              ; bank0/mth2.asm
xref    InputEmpty                              ; bank0/mth2.asm
xref    DrawMenuWd                              ; bank0/mth2.asm
xref    MayMTHPrint                             ; bank0/mth2.asm
xref    MTHPrintKeycode                         ; bank0/mth2.asm
xref    MTHPrint                                ; bank0/mth2.asm
xref    MTHPrintTokenized                       ; bank0/mth2.asm
xref    NextAppDOR                              ; bank0/mth2.asm
xref    PrevAppDOR                              ; bank0/mth2.asm
xref    PrintTopic                              ; bank0/mth2.asm
xref    PrntAppname                             ; bank0/mth2.asm
xref    SetActiveAppDOR                         ; bank0/mth2.asm
xref    SetHlpAppChgFile                        ; bank0/mth2.asm
xref    GetAttr                                 ; bank0/mth2.asm
xref    GetHlpCommands                          ; bank0/mth2.asm
xref    GetCmdTopicByNum                        ; bank0/mth2.asm
xref    GetRealCmdPosition                      ; bank0/mth2.asm

xref    Get2ndTopicHelp                         ; bank0/mth3.asm
xref    GetFirstNonInfoTopic                    ; bank0/mth3.asm
xref    GetFirstTopicHelp                       ; bank0/mth3.asm
xref    GetNextNonInfoTopic                     ; bank0/mth3.asm
xref    GetNextTopicHelp                        ; bank0/mth3.asm
xref    GetNonInfoTopicByNum                    ; bank0/mth3.asm
xref    GetTpcAttrByNum                         ; bank0/mth3.asm

xref    InitUserAreaGrey                        ; bank7/scrdrv1.asm
xref    Beep_X                                  ; bank0/scrdrv4.asm
xref    DORHandleFree                           ; bank0/dor.asm
xref    InitHlpActiveCmd                        ; bank0/process3.asm
xref    InitHlpActiveHelp                       ; bank0/process3.asm
xref    SetHlpActiveHelp                        ; bank0/process3.asm
xref    OSBixS1                                 ; bank0/misc4.asm
xref    OSBoxS1                                 ; bank0/misc4.asm
xref    KPrint                                  ; bank0/misc5.asm
xref    MTH_ToggleLT                            ; bank0/misc5.asm
xref    ReserveStkBuf                           ; bank0/misc5.asm
xref    RdStdinNoTO                             ; bank0/osin.asm
xref    sub_EF92                                ; bank0/osin.asm
xref    sub_EFBB                                ; bank0/osin.asm

;       ----

; handle menu/help/index from OSTin

.DoHelp
        ld      bc, -20
        call    ReserveStkBuf                   ; !! make this inline

        cp      IN_IDX
        jr      nz, hlp_1
        ld      a, $89
.hlp_1
        cp      $89
        jr      nz, hlp_2                       ; not index? skip
        call    sub_EFBB                        ; send fake []I
        ld      b, 0
        inc     b                               ; Fz=0
        scf                                     ; Fc=1
        jr      hlp_x

.hlp_2
        call    SaveHelpstate
        call    MTHSaveScreen
        call    InitUserAreaGrey
        cp      IN_HLP
        jr      nz, hlp_4                       ; not help? skip
        xor     a
        call    SetHlpActiveHelp
        call    GetTpcAttrByNum                 ; A=1
        jr      c, hlp_3
        bit     TPCF_B_INFO, d                  ; information topic?
        jp      nz, loc_A2AD
.hlp_3
        jp      MTH_Help

.hlp_4
        cp      IN_MEN
        jp      z, menu_entry
        cp      a                               ; not index/help/menu? Fc=1, Fz=1
        scf                                     ; !! this shouldn't happen

.ExitHelp
        call    RestoreHelpState                ; !! make this inline too
        call    MTHRestoreScreen
        push    af
        ld      ix, (pMTHScreenSave)
        ld      a, SR_FUS                       ; free user screen
        call    CallOSSr
        call    DrawTopicWd
        pop     af

.hlp_x
        ld      sp, iy
        pop     hl
        pop     hl
        pop     iy
        ret

;       ----

.sub_9FA5
        ld      h, (iy+1)                       ; HL points to saved help data
        ld      l, (iy+0)                       ; !! inline this
        ret

;       ----

.RestoreHelpState
        ld      bc, 20                          ; copy 20 bytes from ? to $0287
        ld      de, ubHlpActiveCmd
        call    sub_9FA5                        ; ld hl,(iy+0)
        ldir
        ret

;       ----

.MTHRestoreScreen
        push    ix
        push    af

        ld      ix, (pMTHScreenSave)
        ld      a, SR_RUS                       ; restore user screen
        call    CallOSSr
        jr      nc, rs_1
        pop     af                              ; couldn't restore screen?
        call    InitUserAreaGrey
        ld      a, RC_Draw-1                    ; A=RC_Draw, Fz=0, Fc=1
        inc     a                               ; !! ld a,RC_Draw; cp $ff
        scf
        push    af                              ; !! OP_LDB_IMM to hide pop
.rs_1
        pop     af
        pop     ix
        jp      CopyMTHApp_Help

;       ----

.SaveHelpstate
        ld      bc, 20                          ; store help state at IX
        push    ix
        pop     de
        ld      (iy+1), d                       ; !! unnecessary? already done in ReserveStk
        ld      (iy+0), e

        ld      hl, ubHlpActiveCmd
        ldir

.CopyMTHApp_Help
        ld      hl, eAppDOR_2                   ; copy App pointers into Help pointers
        ld      de, eHlpAppDOR
        jr      CopyMTHsub

.CopyMTHHelp_App
        ld      hl, eHlpAppDOR                  ; copy Help pointers into App pointers
        ld      de, eAppDOR_2

.CopyMTHsub
        ld      bc, 5*3                         ; 5 ePointers
        ldir
        ret

;       ----

.MTHSaveScreen
        push    ix
        push    af
        ld      a, SR_SUS                       ; save user screen
        call    CallOSSr
        pop     af
        pop     ix
        ret

;       ----

.CallOSSr
        OZ      OS_Sr
        ld      (pMTHScreenSave), ix
        ret

;       ----

.DrawMenuWd2
        call    MTHPrint
        defm    $7F,"C"                         ; center
        defm    1,"T", 0

        ld      a, (ubHlpActiveTpc)
        call    GetTpcAttrByNum
        bit     TPCF_B_INFO, d
        ld      hl, dmwd_4                      ; "advance" "action"
        jr      z, dmwd_1                       ; advance/select/action/resume
        ld      hl, dmwd_5                      ; "browse" "detail"

                                                ; else info topic: browse/select/detail/resume
.dmwd_1
        ld      a, (hl)                         ; get symbol
        call    dmwd_2                          ; 1. line - advance/browse

        call    KPrint                          ; 4. line - resume
        defm    11, 11, 11
        defm    SOH,SD_ESC,10
        defm    "RESUME",10,10,10, 0

        ld      a, (pMTHScreenSave+1)
        or      a
        jr      z, dmwd_3                       ; memory low? can't select/action

        call    KPrint                          ; 2. line - select
        defm    SOH,SD_OLFT
        defm    SOH,SD_ORGT
        defm    SOH,SD_ODWN
        defm    SOH,SD_OUP
        defm    10
        defm    "SELECT",10,0

        ld      a, IN_ENTER
.dmwd_2
        call    MTHPrintKeycode                   ; 3. line - action/detail
        inc     hl
        OZ      GN_Sop                          ; write string to std. output
        ret
.dmwd_3
        call    KPrint
        defm    10,"MEMORY",10,"LOW", 0
        ret

.dmwd_4
        defb    SD_MNU
        defm    10,"ADVANCE",0
        defm    10,"ACTION",0

.dmwd_5
        defb    SD_HLP
        defm    10,"BROWSE",0
        defm    10,"DETAIL",0

;       ----

.mnu_menu2
        call    GetFirstNonInfoTopic
        ret     c
        call    GetNextNonInfoTopic
        ret     c
        call    InitHlpActiveCmd                ; set to 1
        ld      hl, ubHlpActiveHelp
        inc     (hl)
        ld      a, (ubHlpActiveTpc)
        call    GetNextNonInfoTopic             ; and drop thru

;       ----

.SetHlpActiveTpc
        ld      (ubHlpActiveTpc), a
        jr      c, shat_1                       ;

        ld      a, (ubHlpActiveHelp)
        cp      8
        jr      c, shat_2
.shat_1
        ld      a, 1
        ld      (ubHlpActiveHelp), a
        ld      a, (ubHlpActiveTpc)
        call    GetNonInfoTopicByNum
        ld      (ubHlpActiveTpc), a
.shat_2
        or      a
        ret

;       ----

.mnu_up2
        ld      a, (ubHlpActiveCmd)
.loc_A0C8
        ld      c, 1                            ; !! ld c,a; dec c and use C directly below
        ld      b, a                            ; !! can reuse 'dec c' if it's placed last
.loc_A0CB
        push    bc
        ld      a, b
        sub     c
        call    GetCmdAttrByNum
        pop     bc
        cp      b                               ; compare real position with wanted position
        scf                                     ; !! flags never used
        ccf
        ret     nz                              ; not same? Fc=0, Fz=0
        dec     b
        scf
        ret     z                               ; wanted/got 1? Fc=1, Fz=1
        inc     b
        inc     c
        jr      loc_A0CB

;       ----

.RetryKeyJump
        push    de
        call    sub_EF92
        jr      c, MTH_KeyJump
        push    af
        ld      a, (pMTHScreenSave+1)
        or      a
        jr      nz, rkj_1                       ; mem not low? do key
        call    Beep_X
        pop     af
        jr      MTH_KeyJump
.rkj_1
        pop     af
        pop     de
        jr      z, ExitKeyJump

.ExitHelp_Susp
        ld      a, RC_Susp-1                    ; A=69=RC_Susp, Fc=1, Fz=0  !! ld a,RC_Susp; cp $ff
        inc     a
        scf

.ExitKeyJump
        push    af
        xor     a
        call    ChgHelpFile                     ; close help file
        call    MayResetAppHelpData
        pop     af
        jp      ExitHelp                        ; back to app - maybe into index/filer?

;       ----

.MayResetAppHelpData
        call    GetHlp_sub                      ; only used to compare AppDOR with HlpAppDOR
        jr      nz, mrahd_1                     ; not same, reset suspended app cmd/tpc/hlp
        ld      a, (ubHlpActiveTpc)
        call    GetTpcAttrByNum
        jr      c, mrahd_1                      ; no such topic? reset app data
        bit     TPCF_B_INFO, d
        jr      nz, mrahd_1                     ;  not info topic? reset app data
        ld      de, ubHlpActiveCmd              ; use help cmd/tpc/hlp
        jr      mrahd_2
.mrahd_1
        ld      de, dummy-256
        inc     d                               ; Fz=0
.mrahd_2
        call    sub_9FA5                        ; ld hl,(iy+0)
        ex      de, hl
        ld      bc, 3
        ldir
        ret

.dummy  defb    1, 1, 1

;       ----

.MTH_KeyJump
        pop     de
.kj_1
        OZ      OS_Xin                          ; examine input
        jr      nc, kj_2                        ; may have input
        ld      a, 1                            ; dummy value for ?
        ld      hl, ubSysFlags1
        bit     SF1_B_INPUTPENDING, (hl)
        jr      nz, kj_6
.kj_2
        push    de
        call    RdStdinNoTO
        pop     de
        jr      nc, kj_3                        ; no error? handle key
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, kj_1                         ; just retry
        cp      RC_Esc                          ; Escape condition (e.g. ESC pressed)
        scf
        jr      nz, ExitKeyJump                 ; other error? exit help
        ld      a, 1                            ; !! A=1 already
        OZ      OS_Esc                          ; ack ESC, flush buffer
        ld      a, IN_ESC                       ; and pass ESC
.kj_3
        cp      IN_IDX
        jr      nz, kj_4
        ld      a, $89                          ; force Index entry
.kj_4
        ld      b, a
        cp      IN_SQU
        jr      z, kj_5
        and     $E0
        cp      $80
.kj_5
        ld      a, b
        scf
        jr      z, ExitKeyJump                  ; [] or $80-$9F

        cp      IN_ESC
        jr      z, ExitHelp_Susp
        cp      IN_DELX                         ; non-translated DEL
        jr      z, ExitHelp_Susp
.kj_6
        push    de                              ; search key in table at caller PC
        pop     hl
.kj_7
        ld      b, (hl)                         ; !! do one 'inc hl' here
        dec     b
        inc     b
        jp      z, RetryKeyJump                 ; not found? wait more
        cp      b
        jr      z, kj_8                         ; match? call function
        inc     hl
        inc     hl
        inc     hl
        jr      kj_7
.kj_8
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl
        or      a                               ; Fc=0
        jp      (hl)

;       ----

.MTH_Copyright
        call    PrintCopyright

.cr_waitkey
        call    MTH_KeyJump
        defb    1
        defw    MTH_Copyright
        defb    IN_HLP
        defw    cr_hlp
        defb    IN_MEN                          ; !! do we really need entries going back to key wait?
        defw    cr_waitkey
        defb    IN_UP
        defw    cr_waitkey
        defb    IN_DWN
        defw    cr_waitkey
        defb    IN_LFT
        defw    cr_waitkey
        defb    IN_RGT
        defw    MTH_Help
        defb    IN_ENTER
        defw    cr_waitkey
        defb    0

; go to first app help

.cr_hlp
        call    InitHlpActiveHelp               ; hlp/tpc/cmd=1
        ld      (ubHlpActiveApp), a
        call    SetHlpAppChgFile                ; !! unnecessary, it's done below

;       ----

.MTH_Help
        call    SetHlpAppChgFile                ; go back to help we were previously
        call    InitHlpActiveHelp               ; hlp/tpc/cmd=1
        call    DrawHelpWd

.hlp_waitkey
        call    MTH_KeyJump
        defb    1
        defw    MTH_Help
        defb    IN_HLP
        defw    help_help
        defb    IN_MEN
        defw    topic_menu
        defb    IN_UP
        defw    help_up
        defb    IN_DWN
        defw    help_down
        defb    IN_LFT
        defw    MTH_Copyright
        defb    IN_RGT
        defw    help_right
        defb    IN_ENTER
        defw    hlp_waitkey
        defb    0

;       ----

.help_up
        call    PrevAppDOR
        jr      MTH_Help
.help_help
        call    GetFirstTopicHelp               ; if we have topic help we display it
        jr      nc, MTH_Topic                   ; otherwise we act like key was crsr down
.help_down
        call    NextAppDOR
        jr      MTH_Help
.help_right
        call    GetFirstTopicHelp
        jp      c, hlp_waitkey                  ; !! jr

;       ----

.MTH_Topic
        call    InitHlpActiveCmd                ; cmd=1
        call    DrawTopicHelpWd

.topic_waitkey
        call    MTH_KeyJump
        defb    1
        defw    MTH_Topic
        defb    IN_HLP
        defw    topic_help
        defb    IN_MEN
        defw    topic_menu
        defb    IN_UP
        defw    topic_up
        defb    IN_DWN
        defw    topic_down
        defb    IN_LFT
        defw    MTH_Help
        defb    IN_RGT
        defw    topic_right
        defb    IN_ENTER
        defw    topic_waitkey
        defb    0

;       ----

.topic_down
        ld      b, 1
        jr      topic_ud1
.topic_up
        ld      b, -1
.topic_ud1
        push    bc
        call    Get2ndTopicHelp
        pop     bc
        jp      c, topic_waitkey                ; only one topic? wait some other key
        ld      a, (ubHlpActiveTpc)
.topic_ud2
        add     a, b                            ; find next/prev topic with help
        push    bc
        call    GetTpcAttrByNum                 ; !! resets A if eol, so this wraps automagically
        pop     bc
        bit     CMDF_B_HELP, d
        jr      z, topic_ud2                    ; no help? search for more

;       ----

.topic_nxhelp2
        or      a                               ; Fc=0, don't reset help
        call    SetHlpActiveTpc
        jp      MTH_Topic
.topic_help
        call    GetFirstCmdHelp
        jr      nc, cmd_setcmd                  ; have command with help? print it
.topic_nxhelp
        ld      a, (ubHlpActiveTpc)
        call    GetNextTopicHelp
        jr      nc, topic_nxhelp2               ; have more topics with help? go there
        jp      help_down                       ; otherwise go to next app

.topic_right
        call    GetFirstCmdHelp
        jp      c, topic_waitkey                ; have no command help? wait more

.cmd_setcmd
        ld      (ubHlpActiveCmd), a

.MTH_Command
        call    DrawCmdHelpWd

.cmd_waitkey
        call    MTH_KeyJump

        defb    1
        defw    MTH_Command
        defb    IN_HLP
        defw    cmd_help
        defb    IN_MEN
        defw    topic_menu
        defb    IN_UP
        defw    cmd_up
        defb    IN_DWN
        defw    cmd_down
        defb    IN_LFT
        defw    cmd_left
        defb    IN_RGT
        defw    cmd_waitkey
        defb    IN_ENTER
        defw    cmd_waitkey
        defb    0

;       ----

.cmd_up
        ld      d, -1
        jr      cmd_ud1
.cmd_down
        ld      d, 1
.cmd_ud1
        ld      a, (ubHlpActiveCmd)             ; remember active command
        ld      e, a
.cmd_ud2
        add     a, d
.cmd_ud3
        cp      e
        jr      z, cmd_setcmd0                  ; we've looped thru all commands? use old one
        push    af
        push    de
        call    GetCmdAttrByNum                 ; !! resets A=0 if oel, so this wraps automagically
        pop     de
        pop     hl                              ; H=A from stack
        jr      c, cmd_ud3                      ; error? retry with A=0
        cp      h
        ld      a, h
        jr      nz, cmd_ud2                     ; not wanted one? try next/prev
        bit     CMDF_B_HELP, b
        jr      z, cmd_ud2                      ; no help? try next/prev

.cmd_setcmd0
        ld      (ubHlpActiveCmd), a             ; !! get rid of this, use cmd_setcmd
        jr      MTH_Command

;       ----

.cmd_left
        call    InitHlpActiveCmd                ; !! unnecessary, done in MTH_Topic
        jp      MTH_Topic                       ; !! so jump there directly from table

;       ----

.cmd_help
        ld      a, (ubHlpActiveCmd)
        call    GetNextCmdHelp
        jr      nc, cmd_setcmd0                 ; found command help? show it
        jp      topic_nxhelp                    ; no more commands with help?

;       ----

.topic_menu
        call    MayResetAppHelpData
        call    nz, InitHlpActiveHelp           ; app data reset? reset help data too
        ld      a, (de)                         ; suspended app
        call    SetActiveAppDOR
        call    ChgHelpFile

.menu_entry
        call    sub_A44D
        ld      a, (ubHlpActiveTpc)             ; find next command topic
        call    GetNonInfoTopicByNum
        ld      (ubHlpActiveTpc), a

.loc_A2AD
        call    sub_A517
        call    DrawMenuWd

        call    KPrint
        defm    1,"6#6",$20+1,$20+0,$20+92,$20+8, 0

        ld      a, (ubHlpActiveCmd)
        jr      loc_A2D6

.loc_A2C4
        call    GetCmdAttrByNum
        push    af
        ld      a, (ubHlpActiveCmd)
        call    sub_A3EC
        pop     bc
        jr      c, mnu_waitkey
        call    MTHHighlight
        push    bc
        pop     af

.loc_A2D6
        call    sub_A3EC
        jr      c, mnu_waitkey
        ld      (ubHlpActiveCmd), a
        call    MTHHighlight

.mnu_waitkey
        call    MTH_KeyJump

        defb    1
        defw    menu_entry
        defb    IN_HLP
        defw    mnu_help
        defb    IN_MEN
        defw    mnu_menu
        defb    IN_UP
        defw    mnu_up
        defb    IN_LFT
        defw    mnu_left
        defb    IN_DWN
        defw    mnu_down
        defb    IN_RGT
        defw    mnu_right
        defb    IN_ENTER
        defw    mnu_enter
        defb    0

;       ----

.mnu_menu
        call    mnu_menu2
        jr      c, mnu_waitkey
        jr      menu_entry
.mnu_up
        call    mnu_up2
        jr      loc_A2C4
.mnu_down
        ld      a, (ubHlpActiveCmd)
        inc     a
        jr      loc_A2C4

;       ----

.mnu_enter
        ld      a, (ubHlpActiveCmd)
        call    GetCmdAttrByNum
        jr      c, mnu_waitkey
        bit     CMDF_B_SAFE, b
        jr      nz, mnu_e2                      ; it's safe? not from enter
        inc     c
        dec     c
        jr      nz, mnu_e1                      ; non-zero command code?
        call    DrawTopicWd
        jp      MTH_Command

.mnu_e1
        ld      a, (pMTHScreenSave+1)
        or      a
        jr      nz, mnu_e3                      ; mem not low? ok
.mnu_e2
        call    Beep_X
        jr      mnu_waitkey
.mnu_e3
        cp      a                               ; Fc=0, Fz=1
        ld      a, c                            ; A=command code
        jp      ExitKeyJump

;       ----

.mnu_right
        xor     a
        call    GetCmdAttrByNum
        dec     d
        jr      z, mnu_down
        ld      a, (ubHlpActiveCmd)
        call    GetCmdAttrByNum
        jp      c, mnu_waitkey
        ld      b, d
        ld      c, e
        ld      h, a
.mnu_r1
        push    bc
        ld      a, h
        call    GetNextCmdAttr
        ld      h, a
        pop     bc
        ld      a, d
        cp      b
        ld      a, e
        jr      z, mnu_r2
        jr      nc, mnu_r3
        cp      c
        jr      z, mnu_r1
        jr      c, mnu_r1
        jr      mnu_r4
.mnu_r2
        cp      c
        jr      nz, mnu_r1
        push    bc
        ld      a, h
        call    GetNextCmdAttr
        ld      h, a
        pop     af
        cp      d
        jr      z, mnu_r4
        ld      h, 1
        jr      mnu_r4
.mnu_r3
        cp      c
        jr      c, mnu_r1
.mnu_r4
        ld      a, h
        jp      loc_A2C4

;       ----

.mnu_left
        xor     a
        call    GetCmdAttrByNum
        dec     d
        jr      z, mnu_up
        ld      a, (ubHlpActiveCmd)
        call    GetCmdAttrByNum
        jp      c, mnu_waitkey
        ld      b, d
        ld      c, e
        ld      h, a
        ld      de, 0
        push    de
.mnu_l1
        push    bc
        ld      a, h
        call    loc_A0C8
        ld      h, a
        pop     ix
        pop     bc
        ld      a, e                            ; A=8*E+D
        add     a, a
        add     a, a
        add     a, a
        add     a, d
        cp      c
        jr      c, mnu_l2
        ld      c, a
        ld      b, h
.mnu_l2
        push    bc
        push    ix
        pop     bc
        ld      a, d
        cp      b
        ld      a, e
        jr      z, mnu_l3
        jr      nc, mnu_l4
        cp      c
        jr      nz, mnu_l1
        jr      mnu_l5
.mnu_l3
        cp      c
        jr      nz, mnu_l1
        push    bc
        ld      a, h
        call    loc_A0C8
        ld      h, a
        pop     af
        cp      d
        jr      z, mnu_l5
        pop     af
        jp      loc_A2C4
.mnu_l4
        inc     a
        cp      c
        jr      nz, mnu_l1
.mnu_l5
        pop     bc
        ld      a, h
        jp      loc_A2C4

;       ----

.mnu_help
        call    DrawTopicWd
        ld      a, (ubHlpActiveTpc)
        call    GetTpcAttrByNum
        bit     TPCF_B_INFO, d                  ; information topic?
        jp      nz, MTH_Help                    ; yes? goto help
        ld      a, (ubHlpActiveCmd)
        call    GetCmdAttrByNum
        jp      nc, MTH_Command
        ld      a, (ubHlpActiveTpc)
        call    GetTpcAttrByNum
        jp      nc, MTH_Topic
        jp      MTH_Help

;       ----

.sub_A3EC
        call    GetCmdAttrByNum
        ret     c
        push    af
        push    de

        call    MTHPrint
        defm    1,"3@",0

        pop     bc
        ld      a, -28
.loc_A3FC
        add     a, 28                           ; 0/28/56
        djnz    loc_A3FC
        cp      66
        jr      nc, loc_A415                    ; >=66? Fc=1
        add     a, $20
        OZ      OS_Out                          ; put xpos
        ld      a, c
        add     a, $20
        OZ      OS_Out                          ; put ypos
        ld      a, (pMTHScreenSave+1)
        or      a
        jr      z, loc_A415                     ; no saved screen? Fc=1
        pop     af
        ret
.loc_A415
        pop     af
        scf
        ret

;       ----

.OpenAppHelpFile
        ex      de, hl
        ld      hl, -29                         ; reserve stack buffer
        add     hl, sp
        ld      sp, hl
        push    hl
        push    de
        ex      de, hl                          ; copy string to stack
        ld      hl, aRom_Help                   ; ":ROM.*/HELP/"
        ld      bc, 12
        ldir
        pop     hl                              ; append application name
        ld      bc, 17
        ldir
        pop     hl
        call    FilenameDOR
        ex      af, af'                         ; restore stack
        ld      hl, 29
        add     hl, sp
        ld      sp, hl
        ex      af, af'
        ret     c
        ld      a, $0B                          ; !! undocumented - same as DOR_RD - use DOR_RD
        ld      bc, 'H'<<8|12
        ld      de, eHlpTopics
        OZ      OS_Dor                          ; DOR interface
        ex      de, hl
        call    nc, CopyAppPointers             ; !! jp nc,
        call    c, DORHandleFree                ; !! jp
        ret

;       ----

.sub_A44D
        ld      a, (ubHlpActiveTpc)
        push    af
        xor     a
        ld      d, -1
.loc_A454
        inc     a
        inc     d
        push    de
        call    GetTpcAttrByNum
        pop     de
        jr      c, loc_A461
        bit     TPCF_B_INFO, b
        jr      nz, loc_A454                    ; info topic? skip
.loc_A461
        pop     af                              ; A=max(a-1,d)
        dec     a
        cp      d
        jr      nc, loc_A467
        ld      a, d
.loc_A467
        inc     a
        push    af
        sub     d
        cp      8
        jr      c, loc_A470
        ld      a, 7
.loc_A470
        ld      (ubHlpActiveHelp), a
        pop     af
        ld      (ubHlpActiveTpc), a
        ret

;       ----

.MTHHighlight
        call    KPrint
        defm    1,"R"
        defm    1,"2E",$20+27
        defm    1,"R",0
        ret

;       ----

.Help2Wd_Top
        call    MayMTHPrint
        defm    1,"7#6",$20+63,$20+0,$20+30,$20+8,$81
        defm    1,"2C6"                         ; select & clear
        defm    $7F,"C"                         ; center
        defm    1,"T"
        defm    "FOR MORE INFORMATION:"
        defm    1,"T"
        defm    10,0
        ret

.Help2Wd_bottom
        call    MayMTHPrint                     ; !! print all this left-justified
        defm    10,10
        defm    $7F,"C"                         ; center
        defm    SOH,SD_MNU," topic entries"
        defm    " ",SOH,SD_HLP," browse",10
        defm    $7F,"L"                         ; left
        defm    " ",SOH,SD_INX," the manager"
        defm    $7F,"R"                         ; right
        defm    SOH,SD_ESC," resume ",0
        ret

;       ----

.GetCurrentWdInfo
        ld      a, 0
        ld      bc, NQ_Wcur
        OZ      OS_Nq                           ; get cursor information
        ld      h, a                            ; H=active wd
        ex      (sp), hl                        ; push it, pop return address
        push    ix                              ; remember wd frame
        jp      (hl)                            ; return

;       ----

.RestoreActiveWd
        pop     hl                              ; pop return address
        call    KPrint
        defm    1,"2H",0                        ; select & hold, window # comes below

        pop     ix                              ; get wd frame
        ex      (sp), hl                        ; push ret PC, pop wd
        push    af
        ld      a, h
        OZ      OS_Out                          ; restore active wd
        pop     af
        ret

;       ----

        call    GetFirstNonInfoTopic            ; !! unused
        ld      (ubHlpActiveHelp), a

;       ----

.sub_A517
        call    DrawTopicWd
        push    af
        ld      a, (ubHlpActiveHelp)
        or      a
        jr      z, loc_A551                     ; no help active? exit
        call    InputEmpty
        jr      c, loc_A551                     ; input waiting? exit
        call    GetCurrentWdInfo
        call    MTHPrint                        ; move to x=0, Y=activeHelp
        defm    1,"2I7"
        defm    1,"3@",$20+0,0

        ld      a, (ubHlpActiveHelp)
        add     a, $20
        OZ      OS_Out                          ; ypos

        call    MTHPrint
        defm    1,"2-G"                         ; no grey
        defm    1,"B", 1,"L"
        defm    $7F,"T"                         ; topic name
        defm    1,"L", 1,"B", 0

        call    RestoreActiveWd
.loc_A551
        pop     af
        ret

;       ----

.DrawTopicWd
        call    InitTopicWd
        call    GetCurrentWdInfo
        ld      a, (ubHlpActiveTpc)
        sub     7
        jp      p, dtw_1
        ld      a, 0
.dtw_1
        inc     a
        ld      c, a
        ld      b, 7
.dtw_2
        push    bc
        call    MTHPrint
        defm    1,"2I7"
        defm    1,"3@",0

        ld      a, $20+0                        ; !! add x-coordinate to string
        OZ      OS_Out                          ; write a byte to std. output
        ld      a, $20+8
        sub     b
        OZ      OS_Out                          ; write a byte to std. output

        call    KPrint                          ; clear EOL
        defm    1,"2C",$FD,0

        ld      a, c
        call    GetNonInfoTopicByNum
        call    MTH_ToggleLT
        call    nc, PrintTopic                  ; found command? print it
        call    MTH_ToggleLT
        pop     bc
        jr      c, dtw_3                        ; no command? skip
        ld      c, a                            ; advance to next command
        inc     c
.dtw_3
        djnz    dtw_2
        call    RestoreActiveWd
        ret

;       ----

.InitTopicWd
        call    GetCurrentWdInfo
        call    MTHPrint
        defm    1,"2I7"
        defm    1,"2-U"
        defm    1,"3@",$20+0,$20+0
        defm    1,"2C",$FD                      ; clear EOL
        defm    1,"4+TLU"
        defm    1,"3-RG"
        defm    $7F,"A"                         ; application name
        defm    1,"U"
        defm    1,"G", 0

        call    RestoreActiveWd
        ret

;       ----

.PrintCopyright
        call    MTHPrint
        defm    1,"7#6",$20+1,$20+0,$20+92,$20+8,$81
        defm    1,"2C6"
        defm    $7F,"C", 0                      ; center

        ld      hl, ubSysFlags1
        set     SF1_B_NOTOKENS, (hl)            ; use default tokens
        push    hl
        ld      b, 7
        ld      hl, CopyrightMsg
        call    MTHPrintTokenized
        pop     hl
        res     SF1_B_NOTOKENS, (hl)            ; !! what if it didn't have tokens?
        ret

;       ----

.DrawHelpWd
        call    InitHelpWd
        ret     c
        call    PrntAppname
        ld      a, LF
        OZ      OS_Out                          ; write a byte to std. output
        call    GetHlpHelp
        call    MTHPrintTokenized
        ret     c
        call    Help2Wd_Top
        ret     c

        call    MayMTHPrint
        defm    $7F,"L"                         ; left
        defm    " other programs"
        defm    $7F,"R"                         ; right
        defm    SOH,SD_OUP,"  ",10
        defm    $7F,"R"                         ; right
        defm    SOH,SD_ODWN,"  ",10
        defm    10,0

        call    GetFirstTopicHelp
        jr      c, dhwd_1                       ; no topics having help? skip
        call    MayMTHPrint

        defm    $7F,"L"                         ; left
        defm    " about "
        defm    $7F,"A"                         ; app name
        defm    " topics"
        defm    $7F,"R"                         ; right
        defm    SOH,SD_ORGT," ", 0

.dhwd_1
        jp      Help2Wd_bottom

.InitHelpWd
        call    MayMTHPrint
        defm    1,"7#6",$20+1,$20+0,$20+61,$20+8,$81
        defm    1,"2C6"                         ; select & clear
        defm    $7F,"C", 0                              ; center
        ret

.CopyrightMsg
        defm    "Th",$82,"C",$ED,"bri"
        defm    "dg",$82,$AB,"mput"
        defm    $EF,"Z88 P",$8F,"t"
        defm    "abl",$82,"V",$86,"si"
        defm    $BC," ", (OZVERSION>>4)+48, '.', (OZVERSION&$0f)+48,".dev"
        defm    $7F,$7F,$DE,"r"
        defm    $CC,$84,"(C) Tr"
        defm    $85,$FC,$D6,$AB,"n",$C9,"pt"
        defm    $94,"Pro",$AF,$B4,"ni"
        defm    "c ",$AB,"mput",$86
        defm    $94,$BF,$86,$91,$C0,"Sys"
        defm    $AF,"m",$94,$C4,$B2,"198"
        defm    "7,88",$7F,"Pip"
        defm    "eD",$8D,$ED,$B7,"a t"
        defm    $E2,$E4,"m",$8C,"k ",$89,$C4
        defm    "d",0

; -----------------------------------------------------------------------------
; moved from K0
; -----------------------------------------------------------------------------
.Get2ndCmdHelp
        call    GetFirstCmdHelp
.GetNextCmdHelp
        inc     a
        jr      gch_1
.GetFirstCmdHelp
        ld      a, 1
.gch_1
        call    GetCmdAttrByNum
        ret     c
        bit     CMDF_B_HELP, b
        ret     nz
        inc     a
        jr      gch_1

.GetNextCmdAttr
        inc     a

.GetCmdAttrByNum
        push    af
        call    GetHlpCommands
        pop     af
        call    OSBixS1                         ; Bind in extended address
        push    de
        ld      c, a                            ; c=count
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        ld      a, 0
        jr      c, gcabn_1                      ; error? Fc=1, A=0
        ld      a, c                            ; a=count
        call    GetRealCmdPosition
        push    af
        inc     hl
        ld      c, (hl)                         ; command code
        dec     hl
        call    GetAttr
        ld      b, a                            ; attributes
        pop     af
        push    de                              ; IX=DE
        pop     ix
.gcabn_1
        pop     de
        call    OSBoxS1                         ; Restore bindings
        push    ix                              ; DE=IX
        pop     de
        ret


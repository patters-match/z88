; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1df4c
;
; $Id$
; -----------------------------------------------------------------------------

        Module MTH1

        org     $9f4c                           ; 2566 bytes

	include	"dor.def"
	include	"error.def"
	include	"stdio.def"
	include	"saverst.def"
	include	"syspar.def"
        include "sysvar.def"
	include	"lowram.def"


xdef    CopyMTHApp_Help
xdef    CopyMTHHelp_App
xdef    DoHelp
xdef    DrawTopicWd
xdef    FindCmd
xdef    GetAttr
xdef    GetCmdTopicByNum
xdef    GetCurrentWdInfo
xdef    GetHlpTokens
xdef    GetRealCmdPosition
xdef    InitTopicWd
xdef    OpenAppHelpFile
xdef    RestoreActiveWd
xdef    SkipNTopics
xdef	GetBHLBackw
xdef	GetHlpCommands
xdef	GetHlpTopics
xdef	MTHPrint
xdef	PrintChar

xref    AtoN_upper
xref    Beep_X
xref    CopyAppPointers
xref    DORHandleFree
xref    FilenameDOR
xref    InitHlpActiveCmd
xref    InitHlpActiveHelp
xref    InitUserAreaGrey
xref    KPrint
xref    MayWrt
xref    MTH_ToggleLT
xref    PrintTopic
xref    PrntAppname
xref    PutOZwdBuf
xref    RdStdinNoTO
xref    ReserveStkBuf
xref    ResetToggles
xref    SetHlpActiveHelp
xref    sub_EF92
xref    sub_EFBB
xref	GetAppDOR
xref	OSWrt
xref	PrintActiveTopic
xref	PrntCommand
xref	ScrDrv_SOH_A
xref	SetActiveAppDOR

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

.MTHSaveScreen
        push    ix
        push    af
        ld      a, SR_SUS                       ; save user screen
        call    CallOSSr
        pop     af
        pop     ix
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
        ld      a, RC_Draw                      ; A=RC_Draw, Fz=0, Fc=1
	cp	RC_Draw+1
        push    af                              ; !! OP_LDB_IMM to hide pop
.rs_1
        pop     af
        pop     ix
        jr      CopyMTHApp_Help

;	----

.CallOSSr
        OZ      OS_Sr
        ld      (pMTHScreenSave), ix
        ret

;       ----

.RestoreHelpState

        ld      bc, 20
        ld      de, ubHlpActiveCmd
        ld      h, (iy+1)
        ld      l, (iy+0)
        ldir
        ret

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
        jr      c, shat_1                       ; Fc=1? init help

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
	ld	b, a
	ld	c, a
.loc_A0CB
	dec	c
        push    bc
        ld      a, c
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
        ld      a, RC_Susp                      ; A=RC_Susp, Fc=1, Fz=0
	cp	RC_Susp+1

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
        ld      h, (iy+1)
        ld      l, (iy+0)
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
        defb    IN_MEN
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
        jr      c, hlp_waitkey

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
        jr      c, topic_waitkey                ; only one topic? wait some other key
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
        jr      help_down                       ; otherwise go to next app

.topic_right
        call    GetFirstCmdHelp
        jr      c, topic_waitkey                ; have no command help? wait more

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
        ld      a, DR_RD
        ld      bc, 'H'<<8|12
        ld      de, eHlpTopics
        OZ      OS_Dor                          ; DOR interface
        ex      de, hl
        jp      nc, CopyAppPointers
        jp	DORHandleFree

.aRom_Help
        defm    ":ROM.*/HELP/"

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


.CopyrightMsg
	defm	"Th",$82,"C",$ED,"bri"
        defm    "dg",$82,$AB,"mput"
        defm    $EF,"Z88 P",$8F,"t"
        defm    "abl",$82,"V",$86,"si"
        defm    $BC," 4.1   "
        defm    "(UK)",$7F,$7F,$DE,"r"
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


;	----

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




; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $30df
;
; $Id$
; -----------------------------------------------------------------------------

; ;OUT: Fc=1 - no command matches
; ;Fc=0, Fz=0, A=code - partial match, buffer not ready yet
; ;Fc=0, Fz=1, A=code - perfect match

.FindCmd
        call    PutOZwdBuf
        ret     c

        call    GetAppCommands
        OZ      OS_Bi1
        push    de

        inc     hl                              ; skip start mark
.fcmd_1
        ld      a, (hl)
        cp      1
        jr      c, fcmd_4                       ; end of list
        jr      z, fcmd_2                       ; end of topic? skip it
        push    hl
        inc     hl
        ld      c, (hl)                         ; command code
        inc     hl
        ld      de, OZcmdBuf
        call    CompareCmd
        pop     hl
        jr      nc, fcmd_3                      ; match? return C

.fcmd_2
        ld      e, (hl)                         ; get length
        ld      d, 0
        add     hl, de                          ; skip command
        jr      fcmd_1                          ; compare next command
.fcmd_3
        ld      a, c                            ; get command code
.fcmd_4
        pop     de
        push    af
        OZ      OS_Bo1
        pop     af
        ret

;       ----

.CompareCmd
        ld      a, (hl)
        or      a
        scf
        ret     z                               ; cmd end? Fc=1
        ld      a, (de)
        or      a
        jr      nz, cc_1                        ; buffer not end yet? skip
        ld      a, (hl)                         ; cmd char
        cp      '@'
        ret     z                               ; '@'? Fc=0, Fz=1
        scf
        ret                                     ; otherwise Fc=1
.cc_1
        push    de
        push    hl
.cc_2
        ld      a, (de)
        or      (hl)
        jr      z, cc_4                         ; end? return Fc=0, Fz=1
        ld      a, (de)
        or      a
        jr      z, cc_3                         ; buf end? Fc=0, A=1
        cp      (hl)
        inc     de
        inc     hl
        jr      z, cc_2                         ; same? continue compare
        scf                                     ; different? Fc=1
.cc_3
        inc     a
.cc_4
        pop     hl
        pop     de
        ret

;       ----

.Get2ndCmdHelp
        call    GetFirstCmdHelp
	jr	GetNextCmdHelp
.GetFirstCmdHelp
	xor	a
.GetNextCmdHelp
        inc     a
.gch_1
        call    GetCmdAttrByNum
        ret     c
        bit     CMDF_B_HELP, b
        ret     nz
        inc     a
        jr      gch_1

;       ----

.Get2ndTopicHelp
        call    GetFirstTopicHelp
.GetNextTopicHelp
        inc     a
        jr      gth_1
.GetFirstTopicHelp
        ld      a, 1
.gth_1
        call    GetTpcAttrByNum
        ret     c
        bit     CMDF_B_HELP, d
        ret     nz
        inc     a
        jr      gth_1

;       ----

.GetFirstNonInfoTopic
	xor	a
.GetNextNonInfoTopic
        inc     a
.GetNonInfoTopicByNum
        call    GetTpcAttrByNum
        ret     c
        bit     TPCF_B_INFO, d
	jr	nz, GetNextNonInfoTopic		; inc count and loop
	ret

;       ----

; IN: A=command/topic index
; OUT: Fc=0, D=attribute byte
;
;
.GetTpcAttrByNum
        push    af
        call    GetHlpTopics
        pop     af
        OZ      OS_Bi1                          ; bind in BHL
        push    de
        call    SkipNTopics
        push    af
        call    GetAttr
        ld      b, a
        pop     af
        pop     de
        push    af
        OZ      OS_Bo1                          ; restore S2/S3
        pop     af
        ld      d, b
        ret

;       ----


.GetNextCmdAttr
        inc     a

.GetCmdAttrByNum
        push    af
        call    GetHlpCommands
        pop     af
        OZ      OS_Bi1                          ; Bind in extended address
        push    de
        ld      c, a                            ; c=count
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        ld      a, 0
        jr      c, gcabn_1                      ; error? Fc=1, A=0
        ld      a, c                            ; a=count
        call    GetRealCmdPosition

	inc	hl
	ld	c, (hl)
	dec	hl

        push    af
        call    GetAttr
        ld      b, a                            ; attributes
        pop     af
        push    de                              ; IX=DE
        pop     ix
.gcabn_1
        pop     de
        push    af
        OZ      OS_Bo1                          ; Restore bindings after OS_Bi1
        pop     af
        push    ix                              ; DE=IX
        pop     de
        ret

;       ----

.DrawMenuWd
        call    KPrint
        defm    1,"6#6",$20+0,$20+0,$20+94,$20+8
        defm    1, "2C6"
        defm    0

        call    GetHlpCommands
        OZ      OS_Bi1
        push    de

        push    hl
        ld      a, (ubHlpActiveTpc)
        call    GetTpcAttrByNum
        pop     hl
        jr      nc, dmw_1                      ; has topics? skip

        pop     de
        OZ      OS_Bo1                          ; Restore bindings after OS_Bi1

        call    InitMenuColumnDE
        call    MayMTHPrint
        defm    10,10,10
        defm    $7f,"C"
        defm    $7f,"A", " has no topics",0

        jr      dmw_2                          ; Fc=1

.dmw_1
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        call    InitMenuColumnDE
        ld      a, (hl)
        cp      2
        jr      nc, dmw_3                      ; not eol/eot? skip
        pop     de
        OZ      OS_Bo1                          ; Restore bindings after OS_Bi1

        call    MayMTHPrint
        defm    10,10,10
        defm    $7f,"C"
        defm    "The ", $7f,"A", " ", $7f,"T", " topic",10
        defm    $7f,"C"
        defm    "has no functions",0

.dmw_2
        scf
        ret

.dmw_3
        call    InputEmpty
        jp      c, dmw_10

        call    GetAttr
        bit     CMDF_B_HIDDEN, a
        jr      nz, dmw_9                      ; hidden? skip
        push    hl
        inc     hl                              ; move to kbd sequence
        inc     hl

        ex      af, af'
.dmw_4
        ld      a, (hl)                         ; skip kbd sequence to get cmd name
        inc     hl
        or      a
        jr      nz, dmw_4
        ex      af, af'

        bit     CMDF_B_COLUMN, a
        jr      nz, dmw_5                      ; column change? handle
        ld      a, e
        cp      8
        inc     e
        jr      c, dmw_7                       ; not last row? skip
.dmw_5
        call    InitMenuColumnE
.dmw_6
        jr      c, dmw_11
.dmw_7
        push    de
        call    JustifyN
        ld      a, ' '
        OZ      OS_Out                          ; write a byte to std. output
.dmw_8
        ld      a, (hl)                         ; print command name
        inc     hl
        call    MayWrt
        jr      nc, dmw_8
        call    ResetToggles
        pop     de
        pop     hl
        call    PrintCmdSequence
.dmw_9
        ld      c, (hl)
        ld      b, 0
        add     hl, bc
        ld      a, (hl)
        cp      2
        jr      nc, dmw_3
        ld      e, 8
        call    InitMenuColumn
        or      a
.dmw_10
        pop     de
        push    af
        OZ      OS_Bo1                          ; Restore bindings after OS_Bi1
        pop     af
        call    nc, DrawMenuWd2
        ret
.dmw_11
        pop     hl
        pop     hl
        jr      dmw_10

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
        OZ      OS_Bi1                          ; Bind in extended address
        push    de
        ld      bc, ADOR_NAME
        add     hl, bc
        call    OpenAppHelpFile
        ld      (pMTHHelpHandle), ix
        pop     de
        OZ      OS_Bo1                          ; Restore bindings after OS_Bi1
        ret

;	----


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
        ld      c, a
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
        ld      c, e
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
	bit	7, b                            ; B<0? wanted was hidden, go to previous
        jr      z, grcp_5                       ; else rewind to topic start and search for cmd 1
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
        ret     nz                              ; DE=help
	ld	d, a
	ld	e, a
        ret                                     ; DE=0

;       ----

 
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


;       ----

.GetHlpHelp
        ld      l, <(eHlpHelp+2)
        jr      GetHlp_sub

.GetHlpTokens
        ld      hl, ubSysFlags1
        bit     SF1_B_NOTOKENS, (hl)            ; no tokens?
        ld      b, OZBANK_LO                    ; bank 7, offset 0
        ld      hl, 0
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




.PrintTopicHelp
        call    InputEmpty
        ret     c                               ; input bending? exit
        ld      a, b
        or      c
        ret     z                               ; no help text? exit

        ld      d, b                            ; help offset into DE
        ld      e, c
        call    GetHlpHelp                      ; get help base
        call    AddBHL_DE                       ; go to help text start

;       ----

.MTHPrintTokenized
        call    InputEmpty
        ret     c
        OZ      OS_Bi1
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
        OZ      OS_Bo1
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
        jr      nc, MTHPrint                    ; only print if not pre-empted
        inc     sp                              ; double ret  !! should we get rid of this?  it's
        inc     sp                              ; !! potentially dangerous if one forgets it
        ret

;       print MTH string, expand $7f-codes

.mthp_0
        call    JpDE

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
        ld      hl, mthp_tbl                    ; command table
.mthp_1
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	cp	b
	jr	z, mthp_0
	inc	b
	dec	b
	jr	nz, mthp_1

.mthp_2
        OZ      OS_Out                          ; print char and loop back
        jr      MTHPrint

;       char, function

.mthp_tbl
        defb    'A'
        defw    PrntAppname

        defb    'T'
        defw    PrintActiveTopic

        defb    'F'
        defw    PrntCommand

        defb    'C'
        defw    JustifyC

        defb    'L'
        defw    JustifyL

        defb    'N'
        defw    JustifyN

        defb    'R'
        defw    JustifyR

        defb    'D'
        defw    ResetToggles

        defb    0

;       ----

.JustifyR
	ld	b, 'R'
	jr	just_sub
.JustifyN
	ld	b, 'N'
	jr	just_sub
.JustifyC
.JustifyL
        ld      b, a
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

;       BHL+=DE
;       adjusts B to keep HL<$4000

.AddBHL_DE
        add     hl, de
        ld      a, h                            ; handle bank change
        rlca
        rlca
        and     3
        add     a, b
        ld      b, a
        res     7, h                            ; S0 fix
        res     6, h
	ret


;       ----

.DrawTopicHelpWd
        call    InitHelpWd
        ret     c                               ; input pending? exit

        call    MTHPrint
        defm    "The ", $7f,"A", " ", $7f,"T", " topic",10,0

        call    GetHlpTopics
        OZ      OS_Bi1
        push    de

        ld      a, (ubHlpActiveTpc)
        call    SkipNTopics
        call    GetHelpOffs
        ld	b, d                            ; BC=help
	ld	c, e

        pop     de
        OZ      OS_Bo1

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
        defm    " the ", $7f,"T", " entries"
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
        OZ      OS_Bi1
        push    de

        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        ld      a, (ubHlpActiveCmd)
        call    GetRealCmdPosition
        call    PrintCmdSequence
        call    GetHelpOffs
	ld	b, d
	ld	c, e

        pop     de
        OZ      OS_Bo1

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

;	----

.InitHelpWd
        call    MayMTHPrint
        defm    1,"7#6",$20+1,$20+0,$20+61,$20+8,$81
        defm    1,"2C6"                         ; select & clear
        defm    $7F,"C", 0                      ; center
        ret

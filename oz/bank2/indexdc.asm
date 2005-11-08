; -----------------------------------------------------------------------------
; Bank 2 @ S3           ROM offset $8000-$97FF
;
; $Id$
; -----------------------------------------------------------------------------

        Module Filer

        include "blink.def"
        include "char.def"
        include "director.def"
        include "error.def"
        include "fileio.def"
        include "integer.def"
        include "memory.def"
        include "misc.def"
        include "serintfc.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"
        include "sysvar.def"

        include "..\bank7\lowram.def"


; ubIdxFlags2

defc    IDXF2_B_REENTRY         =7                      ; index already run
defc    IDXF2_B_6               =6                      ; appl first run - needs further analysis
defc    IDXF2_B_KILL            =5                      ; kill application
defc    IDXF2_B_ERROR           =4                      ; error in application
defc    IDXF2_B_ALTPLUS         =3                      ; []+
defc    IDXF2_B_ALTMINUS        =2                      ; []-

defc    IDXF2_REENTRY           =128
defc    IDXF2_6                 =64
defc    IDXF2_KILL              =32
defc    IDXF2_ERROR             =16
defc    IDXF2_ALTPLUS           =8
defc    IDXF2_ALTMINUS          =4
defc    IDXF2_ZCOUNT            =3


DEFVARS 0               ; Process
{
     prc_link                ds.p    1
     prc_flags               ds.b    1
     prc_assoclen            ds.b    1
     prc_dynid               ds.b    1
     prc_stkProcEnv          ds.p    1
     prc_hndl                ds.w    1
     prc_time                ds.b    3
     prc_date                ds.b    3
     prc_assocptr            ds.p    1
     prc_dev                 ds.b    18
     prc_matchstring         ds.b    1
     prc_dir                 ds.b    16
     prc_Name                ds.b    17
     prc_SIZEOF              ds.b    1
}

;prc_flags

defc    PRCF_B_ISINDEX          =3                      ; is Index
defc    PRCF_ISINDEX            =8
defc    CLI_LINEBUFSIZE         = $CF

DEFVARS 0               ; CLI
{
     cli_link                ds.p    1
     cli_Flags               ds.b    1
     cli_StreamFlags         ds.b    1
     cli_bytesleft           ds.b    1
     cli_instream            ds.w    1
     cli_outstream           ds.w    1
     cli_prtstream           ds.w    1
     cli_instreamT           ds.w    1
     cli_outstreamT          ds.w    1
     cli_prtstreamT          ds.w    1
     cli_argC                ds.b    1
     cli_argB                ds.b    1
     cli_outprefix           ds.b    1
     cli_PrefixBuffer        ds.b    22
     cli_LineBuffer          ds.b    CLI_LINEBUFSIZE
     cli_SIZEOF              ds.b    1
}

; cli_Flags

defc    CLIF_B_FILLALL          =7                      ; fill CLI input buffer until EOL
defc    CLIF_B_DISABLEPRT       =6                      ; Dc_Gen ] - needs verification
defc    CLIF_B_IGNOREMETA       =5                      ; .J
defc    CLIF_B_NOTBOL           =4                      ; not_beginning_of_line
defc    CLIF_B_META             =3                      ; got ~ other meta keys
defc    CLIF_B_SQUARE           =2                      ; got # []
defc    CLIF_B_DIAMOND          =1                      ; got | <>
defc    CLIF_B_SHIFT            =0                      ; has shift

defc    CLIF_FILLALL            =128
defc    CLIF_DISABLEPRT         =64
defc    CLIF_IGNOREMETA         =32
defc    CLIF_NOTBOL             =16
defc    CLIF_META               =8
defc    CLIF_SQUARE             =4
defc    CLIF_DIAMOND            =2
defc    CLIF_SHIFT              =1

; cli_StreamFlags

defc    CLIS_B_PRTOPEN          =5                      ; prtstream open
defc    CLIS_B_OUTOPEN          =4                      ; outstream open
defc    CLIS_B_INOPEN           =3                      ; instream open
defc    CLIS_B_PRTTOPEN         =2                      ; prtstreamT open
defc    CLIS_B_OUTTOPEN         =1                      ; outstreamT open
defc    CLIS_B_INTOPEN          =0                      ; instreamT open

defc    CLIS_PRTOPEN            =32
defc    CLIS_OUTOPEN            =16
defc    CLIS_INOPEN             =8
defc    CLIS_PRTTOPEN           =4
defc    CLIS_OUTTOPEN           =2
defc    CLIS_INTOPEN            =1

defc    mem_1fd6                =$1fd6          ; 3*12 bytes

        org     $c000                           ; c000-d7ff, 6144 bytes

        jp      Index
        jp      DCRet
        defw Index
        defw DCBye
        defw DCEnt
        defw DCNam
        defw DCIn
        defw DCOut
        defw DCPrt
        defw DCIcl
        defw DCNq
        defw DCSp
        defw DCAlt
        defw DCRbd
        defw DCXin
        defw DCGen
        defw DCPol

.DCRet
        pop     iy
        pop     bc
        ld      a, c
        ld      (BLSC_SR2), a
        out     (BL_SR2), a
        pop     af
        pop     af
        pop     bc
        pop     de
        pop     hl
        jp      OZ_RET1

.Index
        xor     a
        ld      h, a
        ld      l, a
        OZ      OS_Erh                          ; default error handler

;       if this is first time Index is started we
;       allocate process block and run boot.cli

        ld      a, (ubIdxFlags2)
        bit     IDXF2_B_REENTRY, a
        jp      nz, loc_C0C6

        OZ      OS_Dom                          ; Allocate pIdxMemHandle - no check for errors
        ld      (pIdxMemHandle), ix
        xor     a                               ; now allocate proc struct for Index
        ld      bc, prc_SIZEOF
        OZ      OS_Mal                          ; Allocate memory
        ld      a, b
        ld      (eIdxIndexProc+2), a
        ld      (eIdxIndexProc), hl
        call    AddProc
        call    InitProc

        ld      (iy+prc_flags), PRCF_ISINDEX
        ld      bc, NQ_Wai
        OZ      OS_Nq                           ; returns static handle in IX
        call    PutProcHndl_IX                  ; also copies IX into de
        ex      de, hl
        ld      (pIdxCurrentProcHandle), hl
        ld      (pIdxMyProcHandle), hl
        call    ReadDateTime
        ld      a, IDXF2_REENTRY
        ld      (ubIdxFlags2), a                ; first run done
        call    InitKeys

;       read boot.cli and execute it

        ld      a, OP_OUT                       ; write
        call    OpenBootCli
        jr      c, loc_C0C6
        ld      a, EP_LOAD
        OZ      OS_Epr                          ; read from EPROM
        push    af
        xor     a                               ; !! why?
        OZ      GN_Cl                           ; close file/stream
        pop     af
        jr      nc, loc_C093
        OZ      GN_Del                          ; delete file
        jr      loc_C0C6

.loc_C093
        ld      a, OP_IN                        ; read
        call    OpenBootCli
        jr      c, loc_C0C6
        ld      b, 0
        ld      h, b
        ld      l, b
        OZ      DC_Icl                          ; Invoke new CLI
        jr      nc, loc_C0C6
        xor     a                               ; !! why?
        OZ      GN_Cl                           ; close file/stream
        jr      loc_C0C6

.BootCLI_txt
        defm    ":Ram.-/Boot.cli",0

.OpenBootCli
        ld      hl, BootCLI_txt
        ld      de, 3                           ; NUL, ignore name
        ld      bc, $FF
        OZ      GN_Opf                          ; open - BHL=name, A=mode, DE=exp. name buffer, C=buflen
        ret

.loc_C0C6
        ld      a, (ubIdxFlags2)
        and     IDXF2_ERROR
        jp      nz, ShowExitError
        ld      a, (ubIdxActiveWindow)
        cp      2                               ; card display
        call    z, InitIndex

;       run autobooting application, if there's one

.loc_C0D6
        ld      de, (pIdxAutoRunAppl)
        call    ldIX_DE
        jr      z, loc_C0E8

        ld      hl, 0                           ; don't run again
        ld      (pIdxAutoRunAppl), hl
        jp      enter_2

.loc_C0E8
        call    DrawWindow

;       ----

.MainLoop
        ld      hl, ubIdxPubFlags
        push    hl
        call    MayInitIndex
        pop     hl
        set     IDXF1_B_INSIDEOZ, (hl)
        OZ      OS_In                           ; read a byte from std. input
        call    MayInitIndex
        jr      nc, main_2

.main_1
        cp      RC_Quit
        jr      z, main_4
        cp      RC_Draw
        call    z, DrawWindow                   ; !! could loop to c0e8 (even better, change it
        jr      MainLoop                        ; !! into call z,... and do jr after ct RC_Draw)

.main_2
        or      a                               ; if it isn't extended we ignore it
        jr      nz, MainLoop

        ld      hl, ubIdxPubFlags
        set     IDXF1_B_INSIDEOZ, (hl)
        OZ      OS_In                           ; read a byte from std. input
        call    MayInitIndex
        jr      c, main_1

        ld      hl, main_3
        dec     a                               ; validate input
        cp      9
        jr      nc, MainLoop

        rlca                                    ; fetch command vector and execute
        ld      c, a
        ld      b, 0
        add     hl, bc
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        jp      (hl)

.main_3
        defw cmd_right
        defw cmd_left
        defw cmd_up
        defw cmd_down
        defw cmd_enter
        defw cmd_escape
        defw cmd_kill
        defw cmd_card
        defw 0                                  ; cmd_purge

.main_4
        xor     a
        OZ      OS_Bye                          ; Application exit

;       ----

.MayInitIndex
        push    af
        res     IDXF1_B_INSIDEOZ, (hl)
        bit     IDXF1_B_INIT, (hl)
        res     IDXF1_B_INIT, (hl)
        jr      z, mii_1
        call    InitIndex
        call    InitKeys
        call    DrawWindow
.mii_1
        pop     af
        ret

;       ----

;       move from process window into application window

.cmd_left
        ld      a, (ubIdxActiveWindow)
        or      a
        jr      z, GoMainLoop                   ; application window
        cp      2
        jr      z, GoMainLoop                   ; card display

        ld      a, (ubIdxNApplDisplayed)
        or      a
        jr      z, GoMainLoop                   ; no apps, exit

        call    RemoveHighlight
        xor     a
        ld      (ubIdxActiveWindow), a          ; appl window
        ld      a, (ubIdxSelectorPos)           ; pos=min(ubIdxSelectorPos,ubIdxNApplDisplayed-1)
        ld      c, a
        ld      a, (ubIdxNApplDisplayed)
        dec     a
        cp      c
        jr      nc, kl_1
        ld      (ubIdxSelectorPos), a
.kl_1
        ld      hl, Init2_txt                   ; select & init wd2
        jr      klr_2

;       ----

;       move from application window into process window

.cmd_right
        ld      a, (ubIdxActiveWindow)
        cp      2
        jr      z, GoMainLoop                   ; card  display
        dec     a
        jr      z, GoMainLoop                   ; process window

        ld      a, (ubIdxNProcDisplayed)
        or      a
        jr      z, GoMainLoop                   ; no suspended processes, exit

        call    RemoveHighlight
        ld      a, 1                            ; process wd
        ld      (ubIdxActiveWindow), a
        ld      a, (ubIdxSelectorPos)           ; pos=min(ubIdxSelectorPos,ubIdxNProcDisplayed-1)
        ld      c, a
        ld      a, (ubIdxNProcDisplayed)
        dec     a
        cp      c
        jr      nc, kr_1
        ld      (ubIdxSelectorPos), a
.kr_1
        ld      hl, Init3_txt                   ; select & init wd3

.klr_2
        OZ      GN_Sop                          ; write string to std. output
        call    DrawHighlight

.GoMainLoop
        jp      MainLoop

;       ----

;       move up in application or process window

.cmd_up
        ld      a, (ubIdxActiveWindow)
        cp      2
        jp      z, MainLoop                     ; card display

        call    RemoveHighlight
        ld      a, (ubIdxSelectorPos)
        or      a
        jr      z, up_1                         ; scroll if selector at top
        dec     a
        ld      (ubIdxSelectorPos), a           ; else just decrement position
        call    DrawHighlight
        jp      MainLoop

.up_1
        ld      a, (ubIdxActiveWindow)
        or      a
        jr      z, up_7                         ; appl window

;       process window

        ld      a, (ubIdxTopProcess)
        or      a
        jr      z, up_2                         ; do full redraw

        call    ScrollDown
        ld      a, (ubIdxTopProcess)            ; !! push/pop
        dec     a
        ld      (ubIdxTopProcess), a
        call    GetProcessByNum
        jp      c, Index                        ; error, shouldn't happen until confused!
        call    PrintProcess
        jr      up_6

.up_2
        xor     a                               ; !! unnecessary
        call    GetProcessByNum
        jp      c, Index                        ; error, confused!

        ld      a, 5                            ; !! is this necessary?
        ld      (ubIdxSelectorPos), a           ; !! ubIdxSelectorPos is updated below!

        ld      b, 1                            ; count processes
.up_3
        push    bc                              ; !! pre-increment to save 2 bytes
        call    GetNextProc
        pop     bc
        jr      c, up_4
        inc     b
        jr      up_3

.up_4
        ld      a, b
        cp      7
        jr      c, up_5

        sub     6                               ; more than one screenfull of processes
        ld      (ubIdxTopProcess), a
        call    DrawProcWindow
        ld      a, 6

.up_5
        dec     a                               ; select last process
        ld      (ubIdxSelectorPos), a

.up_6
        call    DrawHighlight
        jp      MainLoop

;       application window

.up_7
        ld      a, (ubIdxTopApplication)
        or      a
        jr      z, up_8                         ; do full redraw

        call    ScrollDown                      ; otherwise scroll and update
        ld      a, (ubIdxTopApplication)        ; !! push/pop
        dec     a
        ld      (ubIdxTopApplication), a
        call    GetAppByNum
        jp      c, Index                        ; confused

        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get static handle
        call    PrintApp
        jr      up_6

.up_8
        xor     a                               ; !! unnecessary
        call    GetAppByNum
        jp      c, Index                        ; confused

        ld      a, 5                            ; !! is this necessary ?
        ld      (ubIdxSelectorPos), a           ; !! ubIdxSelectorPos is updated below!

        ld      b, 1                            ; count applications
.up_9
        call    GetNextApp                      ; !! pre-increment
        jr      c, up_10
        inc     b
        jr      up_9

.up_10
        ld      a, b
        cp      7
        jr      c, up_11

        sub     6                               ; more than one screenfull of applications
        ld      (ubIdxTopApplication), a
        call    DrawAppWindow
        ld      a, 6

.up_11
        dec     a                               ; select last application
        ld      (ubIdxSelectorPos), a
        jr      up_6

;       ----

; Scroll window down and clear first line

.ScrollDown
        ld      hl, ScrollDown_txt
        OZ      GN_Sop
        ld      bc, 0
        call    MoveXY_BC
        ld      hl, ClrEOL_txt
        OZ      GN_Sop
        ret

;       ----

;       move down in application or process window

.cmd_down
        ld      a, (ubIdxActiveWindow)
        cp      2
        jp      z, MainLoop                     ; card display

        call    RemoveHighlight
        ld      a, (ubIdxNApplDisplayed)
        ld      c, a
        ld      a, (ubIdxActiveWindow)
        or      a
        jr      z, dn_1                         ; application window
        ld      a, (ubIdxNProcDisplayed)
        ld      c, a
.dn_1
        ld      a, (ubIdxSelectorPos)
        inc     a
        cp      c
        jr      nc, dn_2                        ; past last displayed, scroll
        ld      a, (ubIdxSelectorPos)           ; otherwise just increment pos
        inc     a                               ; !! we already have this in A
        ld      (ubIdxSelectorPos), a
        jr      dn_x

.dn_2
        ld      a, (ubIdxActiveWindow)
        or      a
        jr      z, dn_4                         ; appl wd

;       process window

        ld      a, (ubIdxTopProcess)
        ld      c, a
        ld      a, (ubIdxNProcDisplayed)
        add     a, c
        call    GetProcessByNum                 ; get next proc
        jr      c, dn_3                         ; no more, redraw from top

        ld      hl, ScrollUp_txt
        OZ      GN_Sop
        ld      a, (ubIdxTopProcess)            ; increment top process
        inc     a
        ld      (ubIdxTopProcess), a
        ld      bc, 5
        call    MoveXY_BC
        call    PrintProcess
        jr      dn_x

.dn_3
        xor     a
        ld      (ubIdxSelectorPos), a
        ld      a, (ubIdxTopProcess)
        or      a
        jr      z, dn_x                         ; we're done if no more than 6 processes
        xor     a
        ld      (ubIdxTopProcess), a
        call    DrawProcWindow
        jr      dn_x

;       application window

.dn_4
        ld      a, (ubIdxTopApplication)
        ld      c, a
        ld      a, (ubIdxNApplDisplayed)
        add     a, c
        call    GetAppByNum                     ; get next appl
        jr      c, dn_5                         ; no more, redraw from top

        ld      hl, ScrollUp_txt
        OZ      GN_Sop
        ld      a, (ubIdxTopApplication)        ; increment top application
        inc     a
        ld      (ubIdxTopApplication), a
        ld      bc, 5
        call    MoveXY_BC
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; static handle in IX
        call    PrintApp
        jr      dn_x

.dn_5
        xor     a
        ld      (ubIdxSelectorPos), a
        ld      a, (ubIdxTopApplication)
        or      a
        jr      z, dn_x                         ; we're done if no more than 6 applications
        xor     a
        ld      (ubIdxTopApplication), a
        call    DrawAppWindow

.dn_x
        call    DrawHighlight
        jp      MainLoop

;       ----

;       return to interrupted application or exit card display

.cmd_escape
        ld      a, (ubIdxActiveWindow)
        cp      2                               ; card display
        jr      nz, esc_1

        xor     a
        ld      (ubIdxActiveWindow),    a
        ld      (ubIdxSelectorPos), a
        jp      loc_C0C6

.esc_1
        push    iy
        ld      a, (eIdxProcList+2)             ; last running process at top
        ld      iy, (eIdxProcList)
        ld      b, a
        ld      c, 1
        OZ      OS_Mpb                          ; bind first proc to S1
        push    bc
        call    GetLinkBHL                      ; get second process
        ld      d, b
        pop     bc
        OZ      OS_Mpb                          ; restore S1
        pop     iy
        ld      b, d
        ld      a, b
        or      h
        or      l
        jp      z, MainLoop                     ; go back if there's only Index
        jr      ExitIndex                       ; return to appl

;       ----

;       start new or return to interrupted application

.cmd_enter
        ld      a, (ubIdxActiveWindow)
        cp      2
        jp      z, MainLoop                     ; card display
        or      a
        jr      z, enter_1

;       process window

        ld      a, (ubIdxTopProcess)
        ld      c, a
        ld      a, (ubIdxSelectorPos)
        add     a, c
        call    GetProcessByNum
        jp      c, Index                        ; confused
        ld      a, (iy+prc_flags)
        and     PRCF_ISINDEX
        jp      nz, MainLoop

        push    iy
        pop     hl
        jr      ExitIndex                       ; go restore it

;       application window

.enter_1
        ld      a, (ubIdxTopApplication)
        ld      c, a
        ld      a, (ubIdxSelectorPos)
        add     a, c
        call    GetAppByNum
        jp      c, Index                        ; confused

.enter_2
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        and     AT_Ones                         ; only one run possible?
        jr      z, enter_3
        call    GetProcByHandle
        jr      nc, ExitIndex                   ; it's running already

.enter_3
        ld      b, 0                            ; start new

.ExitIndex
        ld      (pIdxRunProcIX), ix             ; store static handle
        ld      (eIdxRunProc), hl               ; and process structure
        ld      a, b
        ld      (eIdxRunProc+2), a
        xor     a
        OZ      OS_Bye                          ; exit Index, start eIdxRunProc

.ShowExitError
        ld      hl, ubIdxFlags2
        res     IDXF2_B_ERROR, (hl)
        ld      a, (ubIdxErrorCode)
        OZ      GN_Err                          ; Display an interactive error box
        call    DrawWindow
        jp      MainLoop

;       ----

;       <>KILL selected process

.cmd_kill
        ld      a, (ubIdxActiveWindow)
        or      a
        jp      z, MainLoop                     ; application window
                                                ; !! should check for card display!
        ld      a, (ubIdxTopProcess)
        ld      c, a
        ld      a, (ubIdxSelectorPos)
        add     a, c
        call    GetProcessByNum
        jp      c, Index                        ; confused
        push    iy
        ld      hl, ubIdxFlags2
        set     IDXF2_B_KILL, (hl)
        pop     hl
        jr      ExitIndex                       ; exit Index to let process kill itself

;       ----

;       full window redraw

.DrawWindow
        ld      a, (ubIdxActiveWindow)
        cp      2
        jp      z, DrawCardWd                   ; card display

        ld      hl, ApplWD_txt
        OZ      GN_Sop                          ; init application window
        ld      hl, ActWd_txt
        OZ      GN_Sop                          ; init process window
        call    DrawAppWindow
        call    DrawProcWindow

        ld      a, (ubIdxActiveWindow)
        or      a
        jr      z, dwd_1                        ; application window

        ld      a, (ubIdxOldProcRmCount)
        ld      c, a
        ld      a, (ubIdxProcRmCount)
        cp      c
        jr      z, dwd_1

        ld      (ubIdxOldProcRmCount), a        ; if process removed reset selector position
        xor     a
        ld      (ubIdxSelectorPos), a
        ld      a, (ubIdxNProcDisplayed)
        or      a
        jr      nz, dwd_1
        ld      (ubIdxActiveWindow),    a       ; activate appl window if no processes

.dwd_1
        ld      a, (ubIdxActiveWindow)
        or      a
        jr      nz, dwd_2

        ld      hl, Init2_txt                   ; select application window
        OZ      GN_Sop

.dwd_2
        jp      DrawHighlight

;       ----

.DrawAppWindow
        ld      hl, Init2_txt                   ; select & init appl window
        OZ      GN_Sop
        ld      hl, Cls_txt
        OZ      GN_Sop

        ld      b, 6                            ; lines to print
        ld      a, (ubIdxTopApplication)
        call    GetAppByNum
        jr      nc, appw_2                      ; got top appl
        call    ldIX_00                         ; else get first application
.appw_1
        call    GetNextApp

.appw_2
        jr      c, appw_3                       ; no more appls, exit

        push    ix                              ; is this Index?
        ld      de, (pIdxMyProcHandle)
        ex      (sp), hl
        sbc     hl, de
        pop     hl
        jr      z, appw_1                       ; yes, skip

        push    bc
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        call    PrintApp
        OZ      GN_Nln                          ; newline
        pop     bc
        djnz    appw_1

.appw_3
        ld      a, 6
        sub     b
        ld      (ubIdxNApplDisplayed), a
        ret

;       ----

.DrawProcWindow
        ld      hl, Init3_txt
        OZ      GN_Sop                          ; select & init proc window
        ld      hl, Cls_txt
        OZ      GN_Sop

.actw_1
        ld      a, (ubIdxTopProcess)
        call    GetProcessByNum
        ld      b, 6                            ; lines to print
        jr      nc, actw_3                      ; got top proc

        ld      a, (ubIdxTopProcess)
        or      a
        jr      z, actw_4                       ; no procs, exit

        xor     a
        ld      (ubIdxTopProcess), a
        ld      a, (ubIdxActiveWindow)
        cp      1                               ; process wd? !! use sub
        jr      nz, actw_1
        xor     a                               ; yes, reset ubIdxSelectorPos
        ld      (ubIdxSelectorPos), a
        jr      actw_1

.actw_2
        push    bc
        call    GetNextProc
        pop     bc
        jr      c, actw_4                       ; no more procs, exit
.actw_3
        call    PrintProcess
        djnz    actw_2

.actw_4
        ld      a, 6
        sub     b
        ld      (ubIdxNProcDisplayed), a
        ret     nz

        ld      hl, None_txt                    ; no procs, display "NONE"
        OZ      GN_Sop
        ret

;       ----

;       get application number A

.GetAppByNum
        push    bc
        ld      b, a
        inc     b
        call    ldIX_00                         ; start at first appl

.gabn_1
        call    GetNextApp
        jr      c, gabn_2                       ; error, exit
        djnz    gabn_1

.gabn_2
        pop     bc
        ret

;       ----

;       follow IX to next app, ignore Index

.GetNextApp
        push    de

.gna_1
        OZ      OS_Poll                         ; get next app
        jr      c, gna_2                        ; no more, exit

        push    ix                              ; cp ix, (pIdxMyProcHandle)
        ld      de, (pIdxMyProcHandle)
        ex      (sp), hl
        sbc     hl, de
        pop     hl
        jr      z, gna_1                        ; Index, ignore

        or      a                               ; Fc=0

.gna_2
        pop     de
        ret

;       ----

;       get process number A

.GetProcessByNum
        ld      e, a
        inc     e
        ld      iy, eIdxProcList                ; start at beginning

.gpbn_1
        call    GetNextProc
        ld      a, RC_Eof
        jr      c, gpbn_2                       ; no more, exit
        dec     e
        jr      nz, gpbn_1

        or      a                               ; Fc=0 !! unnecessary

.gpbn_2
        ret

;       ----

;       follow IY to next process, ignore Index

.GetNextProc
        push    hl

.nxtact_1
        call    GetLinkBHL
        ld      a, b
        or      l
        or      h
        scf
        jr      z, nxtact_2                     ; no more, exit

        push    hl
        pop     iy
        push    bc
        ld      c, 1
        OZ      OS_Mpb                          ; bind node into S1
        pop     bc
        ld      a, (iy+prc_flags)
        and     PRCF_ISINDEX
        jr      nz, nxtact_1                    ; ignore if it's Index

.nxtact_2
        pop     hl
        ret

;       ----

.DrawHighlight
        call    prt_reverse
        call    RemoveHighlight
        jp      prt_reverse

;       ----

.RemoveHighlight
        ld      a, (ubIdxSelectorPos)
        ld      c, a
        ld      a, (ubIdxActiveWindow)
        or      a
        ld      b, 50                           ; prepare for application window
        jr      z, rh_1
        ld      b, 83                           ; process window
.rh_1
        push    bc
        ld      b, 0
        call    MoveXY_BC
        pop     bc
        ld      a, b
        jp      ApplyA

;       ----

;       print process information
;       IY=process

.PrintProcess
        push    bc
        push    ix

        push    iy
        pop     hl
        ld      bc, prc_Name                    ; process name ("YOUR REF")
        add     hl, bc
        OZ      GN_Sop                          ; write string to std. output

        ld      a, 17
        call    MoveX_A
        call    GetProcHandle
        push    de
        pop     ix
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application name
        OZ      GN_Soe                          ; print it

        ld      a, 30
        call    MoveX_A
        push    iy
        pop     hl
        ld      bc, prc_time                    ; suspension date/time
        add     hl, bc
        OZ      GN_Sdo                          ; print it

        ld      a, 51
        call    MoveX_A
        call    GetProcEnvIDHandle
        push    de
        pop     ix
        OZ      OS_Use                          ; get cards used
        jr      c, pract_4                      ; error, skip printing

        rra                                     ; ignore slot 0
        ld      c, a
        ld      b, 3                            ; 3 slots to print
        ld      d, 1                            ; slot number
        call    prt_tiny

.pract_1
        ld      a, ' '
        dec     d
        jr      z, pract_2                      ; slot 1, don't print predecing space
        OZ      OS_Out                          ; !! MoveX 50 to remove this
.pract_2
        inc     d
        rrc     c
        jr      nc, pract_3                     ; not used, print space
        ld      a, '0'                          ; could use '3'-B
        add     a, d                            ; otherwise print slot number
.pract_3
        OZ      OS_Out
        inc     d
        djnz    pract_1
        call    prt_tiny

.pract_4
        pop     ix
        pop     bc
        ret

;       ----

;       print application information
;       IX=application, BHL=name

.PrintApp
        ld      a, ' '
        OZ      OS_Out
        OZ      GN_Soe                          ; print appl name

        ld      hl, JustifyR_txt
        OZ      GN_Sop

        ld      a, c                            ; command key
        cp      'A'                             ; done if not A-Y
        jr      c, prapp_4
        cp      'Z'
        jr      nc, prapp_4

        sub     'A'
        ld      c, a                            ; find key in key tables

        ld      b, 0                            ; plain key
        ld      hl, IdxKeyTable
        call    addHL_2xA
        call    CompareIX_indHL
        jr      z, prapp_1                      ; found

        inc     b                               ; Zkey
        ld      hl, IdxZKeyTable                ; !! just add 50 to L
        ld      a, c
        call    addHL_2xA
        call    CompareIX_indHL
        jr      z, prapp_1                      ; found

        inc     b                               ; ZZkey
        ld      hl, IdxZZKeyTable               ; !! add 50
        ld      a, c
        call    addHL_2xA
        call    CompareIX_indHL
        jr      nz, prapp_4                     ; not found, exit

.prapp_1
        ld      hl, Square_txt
        OZ      GN_Sop                          ; print []

        ld      a, b                            ; check if Zs to print
        or      a                               ; !! just jr to djnz
        jr      z, prapp_3
.prapp_2
        ld      a, 'Z'
        OZ      OS_Out
        djnz    prapp_2
.prapp_3
        ld      a, c
        add     a, 'A'                          ; get command char back
        OZ      OS_Out
        ld      a, ' '
        OZ      OS_Out

.prapp_4
        call    prt_justifyN                    ; !! should this be jp?

;       ----

;       HL+=2*A, used with (ZZ)IdxKeyTable

.addHL_2xA
        add     a, a
        add     a, l
        ld      l, a
        ret     nc                              ; !! could be ret, tables don't cross page boundaries
        inc     h
        ret

;       ----

;       DE=IX, cp IX, (HL)

.CompareIX_indHL
        push    ix
        pop     de
        inc     hl
        ld      a, (hl)
        dec     hl
        cp      d
        ret     nz
        ld      a, (hl)
        cp      e
        ret

;       ----

;       scan applications to define [] keys

.InitKeys
        ld      hl, IdxKeyTable                 ; clear all tables
        ld      b, 3*2*25
        call    ZeroMem

        call    ldIX_00                         ; no autorun
        ld      (pIdxAutoRunAppl), ix

.initkeys_1
        OZ      OS_Poll                         ; get next app
        ret     c                               ; no more apps, exit

        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get app info
        bit     AT_B_Boot, a
        jr      z, initkeys_2

        ld      hl, (pIdxAutoRunAppl)
        ld      a, h
        or      l
        jr      nz, initkeys_2                  ; don't overwrite if there's one already
        ld      (pIdxAutoRunAppl), ix

.initkeys_2
        ld      a, c                            ; command key
        cp      'A'
        jr      c, initkeys_1
        cp      'Z'
        jr      nc, initkeys_1                  ; not A-X, loop

        sub     'A'
        ld      c, a

        ld      hl, IdxKeyTable
        call    addHL_2xA
        ld      a, (hl)
        inc     hl
        or      (hl)
        dec     hl
        jr      z, initkeys_3                   ; key free, insert

        ld      hl, IdxZKeyTable                ; !! just add 50 to L
        ld      a, c
        call    addHL_2xA
        ld      a, (hl)
        inc     hl
        or      (hl)
        dec     hl
        jr      z, initkeys_3                   ; key free, insert

        ld      hl, IdxZZKeyTable
        ld      a, c
        call    addHL_2xA
        ld      a, (hl)
        inc     hl
        or      (hl)
        dec     hl
        jr      nz, initkeys_1                  ; no key free, next appl

.initkeys_3
        push    ix                              ; store appl handle into key table
        pop     de
        ld      (hl), e
        inc     hl
        ld      (hl), d
        jr      initkeys_1                      ; check next app

;       ----

;       reset application and process windows

.InitIndex
        xor     a
        ld      (ubIdxActiveWindow),    a
        ld      (ubIdxSelectorPos), a
        ld      (ubIdxTopApplication), a
        ld      (ubIdxNApplDisplayed), a
        xor     a
        ld      (ubIdxTopProcess), a
        ld      (ubIdxNProcDisplayed), a
        ret

;       ----

;       ld IX, DE, check for zero

.ldIX_DE
        ld      a, d
        or      e
        push    de
        pop     ix
        ret

;       ----

.MoveXY_BC
        ld      hl, MoveXY_txt
        OZ      GN_Sop                          ; 1,"3@"
        ld      a, $20
        add     a, b
        OZ      OS_Out                          ; X pos
        ld      a, $20
        add     a, c
        OZ      OS_Out                          ; Y pos
        ret

;       ----

.MoveX_A
        push    hl
        push    af
        ld      hl, MoveX_txt                   ; 1,"2X"
        OZ      GN_Sop
        pop     af
        add     a, $20
        OZ      OS_Out
        pop     hl
        ret

        call    prt_reverse                     ; !! unused

;       ----

.prt_tiny
        ld      hl, Tiny_txt
        jr      PrntStr

.prt_reverse
        ld      hl, Reverse_txt
        jr      PrntStr

.prt_justifyN
        ld      hl, JustifyN_txt

.PrntStr
        OZ      GN_Sop
        ret

.ApplyA
        push    af
        ld      hl, Apply_txt                   ; 1,"2A"
        OZ      GN_Sop
        pop     af
        OZ      OS_Out
        ret

.ApplWD_txt
        defm    1,"7#4",$20+1,$20+0,$20+18,$20+8,$83
        defm    1,"2C4"
        defm    1,"2JC"
        defm    1,"T"
        defm    "APPLICATIONS"
        defm    1,"2JN"
        defm    1,"3@",$20+0,$20+0
        defm    1,"R"
        defm    1,"2A",$20+18
        defm    1,"R"
        defm    " NAME         KEY"
        defm    1,"3@",$20+0,$20+1
        defm    1,"U"
        defm    1,"2A",$20+18
        defm    1,"U"
        defm    1,"T"
        defm    1,"6#2",$20+1,$20+2,$20+18,$20+6
        defm    1,"2C2"
        defm    0

.ActWd_txt
        defm    1,"7#4",$20+21,$20,$20+56,$20+8,$83
        defm    1,"2C4"
        defm    1,"2JC"
        defm    1,"T"
        defm    "SUSPENDED ACTIVITIES"
        defm    1,"2JN"
        defm    1,"3@",$20+0,$20+0
        defm    1,"R"
        defm    1,"2A",$20+56
        defm    1,"R"
        defm    "YOUR REF.        APPLICATION  ---WHEN SUSPENDED--- CARDS"
        defm    1,"3@",$20+0,$20+1
        defm    1,"U"
        defm    1,"2A",$20+56
        defm    1,"U"
        defm    1,"T"
        defm    1,"6#3",$20+21,$20+2,$20+56,$20+6
        defm    1,"2C3"
        defm    0

.Init2_txt
        defm    1,"2I2",0
.Init3_txt
        defm    1,"2I3",0

.None_txt
        defm    1,"3@",$20+0,$20+2
        defm    1,"2JC"
        defm    1,"T"
        defm    "NONE"
        defm    1,"T"
        defm    1,"2JN"
        defm    0

.ScrollUp_txt
        defm    1,$FF,0
.ScrollDown_txt
        defm    1,$FE,0

.Tiny_txt
        defm    1,"T",0
.MoveXY_txt
        defm    1,"3@",0
.MoveX_txt
        defm    1,"2X",0
.ClrEOL_txt
        defm    1,"2C",$FD,0

.Cls_txt
        defm    1,"3@",$20+0,$20+0
        defm    1,"2C",$FE,0

.JustifyN_txt
        defm    1,"2JN",0
.JustifyR_txt
        defm    1,"2JR",0
        defm    1,"2JC",0
.Reverse_txt
        defm    1,"R",0
.Apply_txt
        defm    1,"2A",0
.Square_txt
        defm    1,"*",0

;       ----

;       Pass an alternative character
;       Handles keys after []
;
;       IN:     A=char

.DCAlt
        push    ix

        or      a
        jr      z, dcalt_3

;       +       set flag and exit

        cp      '+'
        jr      nz, dcalt_1
        ld      a, (ubIdxFlags2)
        and     ~IDXF2_ALTMINUS
        or      IDXF2_ALTPLUS
        jr      dcalt_5

;       -       set flag and exit

.dcalt_1
        cp      '-'
        jr      nz, dcalt_2
        ld      a, (ubIdxFlags2)
        and     ~IDXF2_ALTPLUS
        or      IDXF2_ALTMINUS
        jr      dcalt_5

.dcalt_2
        OZ      GN_Cls                          ; Classify a character
        jr      nc, dcalt_3                     ; not [a-zA-Z]

        and     $df                             ; upper
        ld      (iy+OSFrame_A), a               ; store for later use
        ld      c, a
        ld      a, (ubIdxFlags2)                ; was it prefixed by + or -
        and     IDXF2_ALTMINUS | IDXF2_ALTPLUS
        ld      a, c
        jp      nz, dcalt_18                    ; yes, go handle P/K/S

;       application key

        cp      'Z'
        jr      nz, dcalt_6                     ; not Z, find it in table
        ld      a, (ubIdxFlags2)                ; get Z count
        and     IDXF2_ZCOUNT
        cp      2
        jr      c, dcalt_4

.dcalt_3
        ld      a, (ubIdxFlags2)                ; clear DC_Alt bits
        and     ~(IDXF2_ALTMINUS|IDXF2_ALTPLUS|IDXF2_ZCOUNT)
        ld      (ubIdxFlags2), a
        jp      dcalt_err2                      ; return syntax error

.dcalt_4
        ld      a, (ubIdxFlags2)                ; add one more Z
        inc     a

.dcalt_5
        ld      (ubIdxFlags2), a                ; store flags and exit
        jp      dcalt_x

;       A-Y, find application

.dcalt_6
        ld      hl, IdxKeyTable                 ; find correct key table
        ld      a, (ubIdxFlags2)
        and     IDXF2_ZCOUNT
        jr      z, dcalt_7
        ld      hl, IdxZKeyTable
        dec     a
        jr      z, dcalt_7
        ld      hl, IdxZZKeyTable

.dcalt_7
        ld      a, (ubIdxFlags2)                ; clear DC_Alt flags
        and     ~(IDXF2_ALTMINUS | IDXF2_ALTPLUS | IDXF2_ZCOUNT)
        ld      (ubIdxFlags2), a

        ld      a, (iy+OSFrame_A)
        sub     'A'
        call    addHL_2xA
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        call    ldIX_DE
        jp      z, dcalt_err2                   ; no application, syntax error

        push    iy
        ld      iy, (eIdxProcList)
        ld      a, (eIdxProcList+2)
        ld      b, a
        ld      c, 1
        OZ      OS_Mpb                          ; remember S1
        push    bc
        call    GetProcHandle

        push    de
        ex      (sp), ix                        ; static handle
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        pop     ix

        and     AT_Popd|AT_Ones
        jr      z, dcalt_8

        push    ix                              ; popdown or only once runnable, return
        pop     de                              ; with syntax error if it's running process
        ld      a, d
        cp      (iy+prc_hndl+1)
        jr      nz, dcalt_8
        ld      a, e
        cp      (iy+prc_hndl)
        jr      z, dcalt_9

.dcalt_8
        call    GetProcByHandle                 ; get oldest running copy
        jr      c, dcalt_10                     ; none, start new one

        ld      a, (eIdxProcList+2)             ; if this is running process then
        cp      b                               ; exit with syntax error
        jr      nz, dcalt_11
        ld      a, (eIdxProcList+1)
        cp      h
        jr      nz, dcalt_11
        ld      a, (eIdxProcList)
        cp      l
        jr      nz, dcalt_11

.dcalt_9
        pop     bc
        OZ      OS_Mpb                          ; restore S1
        jr      dcalt_er3                       ; syntax error

.dcalt_10
        xor     a                               ; start new process
        ld      b, a
        ld      h, a
        ld      l, a

.dcalt_11
        ld      (pIdxRunProcIX), ix
        ld      a, b
        ld      (eIdxRunProc+2), a
        ld      (eIdxRunProc), hl

        ld      ix, (pIdxCurrentProcHandle)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        and     AT_Ugly|AT_Popd
        pop     bc
        push    af
        OZ      OS_Mpb                          ; restore S1
        pop     af
        jr      z, dcalt_12
        ld      b, 0                            ; ugly application or popdown
        OZ      OS_Exit                         ; exit current process

.dcalt_12
        OZ      OS_Stk                          ; Stack file current process
        jr      nc, dcalt_13

        call    ZeroeIdxRunProc                 ; don't run application
        ld      a, RC_Pre                       ; Cannot pre-empt, or No Room
        OZ      GN_Err
        pop     iy
        jr      dcalt_err1                      ; exit

.dcalt_13
        push    bc
        ld      iy, (eIdxProcList)
        ld      a, (eIdxProcList+2)
        ld      b, a
        ld      c, 1
        OZ      OS_Mpb                          ; bind proc in S1
        pop     bc
        ld      (iy+prc_stkProcEnv+2),  b
        ld      (iy+prc_stkProcEnv+1),  h
        ld      (iy+prc_stkProcEnv),    l
        call    ReadDateTime                    ; store suspension date

        ld      hl, (eIdxRunProc)
        ld      a, (eIdxRunProc+2)
        ld      b, a
        ld      ix, (pIdxRunProcIX)
        call    ZeroeIdxRunProc
        OZ      DC_Ent                          ; Enter new application

.dcalt_er3
        pop     iy
.dcalt_err2
        ld      a, RC_Sntx
        set     Z80F_B_Z, (iy+OSFrame_F)
.dcalt_err1
        call    SetOsfError
.dcalt_x
        pop     ix
        ret

;       []+ or []-

.dcalt_18
        push    iy
        ex      af, af'                         ; remember char
        ld      a, (ubIdxFlags2)
        and     IDXF2_ALTPLUS
        push    af                              ; store +/- status
        ex      af, af'                         ; restore char

        cp      'P'
        jr      nz, dcalt_22
        pop     af
        jr      z, dcalt_20

;       []+P

        ld      a, 5                            ; send 5,"[" to printer filter
        OZ      OS_Prt
        ld      a, '['
        OZ      OS_Prt
        call    GetFirstCli                     ; if we have running CLI rebind it's output to printer
        jr      z, dcalt_19

        ld      bc, NQ_Phn
        OZ      OS_Nq                           ; get printer indirected handle
        ld      e, RB_OPT                       ; rebind output tee into it
        jr      dcalt_29

.dcalt_19
        ld      hl, RedirOutPrt_cli             ; start new CLI
        ld      bc, 11
        jr      dcalt_26

;       []-P

.dcalt_20
        ld      a, 5
        OZ      OS_Prt                          ; send 5,"]" to printer filter
        ld      a, ']'
        OZ      OS_Prt

;       []-S

.dcalt_21
        ld      e, RB_OPT                       ; close output tee
        jr      dcalt_28


.dcalt_22
        cp      'S'
        jr      nz, dcalt_24
        pop     af
        jr      z, dcalt_21

;       []+S

        call    GetFirstCli
        jr      z, dcalt_23
        ld      hl, Ssgn_name                   ; rebind CLI's output to SS.sgn
        call    OpenWrite
        jr      c, dcalt_31
        ld      e, RB_OPT
        jr      dcalt_29

.dcalt_23
        ld      hl, RedirOutSsgn_cli            ; start new CLI
        ld      bc, 19
        jr      dcalt_26

.dcalt_24
        cp      'K'
        jr      nz, dcalt_30
        pop     af
        jr      z, dcalt_27

;       []+K

        call    GetFirstCli
        jr      z, dcalt_25
        ld      hl, Ksgn_name                   ; rebind CLI's output to K.sgn
        call    OpenWrite
        jr      c, dcalt_31
        ld      e, RB_INT
        jr      dcalt_29

.dcalt_25
        ld      hl, RedirInKsgn_cli             ; start new CLI
        ld      bc, 19

.dcalt_26
        OZ      DC_Icl                          ; Invoke new CLI
        jr      dcalt_31

;       []-K

.dcalt_27
        ld      e, RB_INT                       ; close input tee

.dcalt_28
        call    ldIX_00
        call    GetFirstCli
        jr      z, dcalt_31

.dcalt_29
        ld      a, e
        OZ      DC_Rbd                          ; Rebind streams
        jr      dcalt_31

.dcalt_30
        pop     af

.dcalt_31
        ld      a, (ubIdxFlags2)
        and     ~(IDXF2_ALTPLUS | IDXF2_ALTMINUS)
        ld      (ubIdxFlags2), a
        pop     iy
        jp      dcalt_err2                      ; syntax error

;       ----


.OpenWrite
        ld      a, OP_OUT
        jr      open_1

.OpenRead
        ld      a, OP_IN

.open_1
        push    bc
        push    af

.open_2
        ld      a, (hl)                         ; skip spaces
        cp      ' '
        jr      nz, open_3
        inc     hl
        jr      open_2

.open_3
        pop     af
        ld      de, 3                           ; NUL, ignore name
        ld      bc, $FF
        OZ      GN_Opf
        pop     bc
        ret

;       ----

.RedirOutPrt_cli
        defm    ".T>:PRT",13
        defm    ".S",0

.RedirInKsgn_cli
        defm    ".T<"
.Ksgn_name
        defm    ":Ram.-/K.sgn",13
        defm    ".S",0
.RedirOutSsgn_cli
        defm    ".T>"
.Ssgn_name
        defm    ":Ram.-/S.sgn",13
        defm    ".S",0

;       ----

;       read date and time into process structure

.ReadDateTime
        push    iy
        pop     hl
        ld      de, prc_date
        add     hl, de
        ex      de, hl
        OZ      GN_Gmd                          ; get machine date in (DE)
        push    iy
        pop     hl
        ld      de, prc_time
        add     hl, de
        ex      de, hl
        ld      c, (iy+prc_date)
        OZ      GN_Gmt                          ; get system time in (DE)
        jr      nz, ReadDateTime                ; time  not consistent
        ret

;       ----

;       exiting current application
;       IN:     A=return code

.DCBye
        push    iy
        call    FreeProc                        ; free running process

        pop     iy                              ; set error
        ld      a, (iy+OSFrame_A)
        ld      (ubIdxErrorCode), a
        or      a
        jr      z, dcbye_1

        call    ZeroeIdxRunProc
        ld      hl, ubIdxFlags2
        set     IDXF2_B_ERROR, (hl)
        jr      dcbye_2

.dcbye_1
        ld      ix, (pIdxCurrentProcHandle)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get appl data
        and     AT_Ugly|AT_Popd
        jr      nz, dcbye_3

.dcbye_2
        ld      hl, wd_8def_txt                 ; clear screen and start Index
        OZ      GN_Sop
        ld      b, 0
        ld      ix, (pIdxMyProcHandle)
        jr      dcbye_4

.dcbye_3
        ld      de, (pIdxRunProcIX)             ; ugly or popdown
        push    de
        pop     ix
        ld      a, (eIdxRunProc+2)
        ld      hl, (eIdxRunProc)
        ld      b, a
        call    ZeroeIdxRunProc
        or      d
        or      e
        jr      nz, dcbye_4                     ; enter that process

        ld      ix, (pIdxCurrentProcHandle)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get appl data
        and     AT_Popd
        jr      z, dcbye_2

        ld      a, (eIdxProcList+2)             ; return to first process
        ld      hl, (eIdxProcList)
        ld      b, a
        or      h
        or      l
        jr      z, dcbye_2

.dcbye_4
        OZ      DC_Ent                          ; Enter new application

.wd_8def_txt
        defm    1,"6#8",$20+0,$20+0,$20+94,$20+8
        defm    1,"2C8"
        defm    0

;       ----

;       enter new application
;       BHL = points to the process block
;       B = 0, start a new process
;       IX = the application handle

.DCEnt
        push    hl
        ld      hl, ubIdxFlags2
        res     IDXF2_B_6, (hl)
        pop     hl
        ld      a, b
        or      a
        jr      z, dcent_1                      ; start new

        ld      iy, eIdxProcList
        call    RemoveBHL                       ; remove from list
        jr      c, dcent_4                      ; not found
        call    AddProc                         ; and insert at top
        jr      dcent_2

.dcent_1
        push    ix                              ; is this Index?
        ld      de, (pIdxMyProcHandle)
        ex      (sp), hl
        ex      de, hl
        sbc     hl, de
        ex      de, hl
        ex      (sp), hl
        pop     ix
        jr      z, dcent_6                      ; go to Index

        push    ix                              ; allocate memory for process
        ld      ix, (pIdxMemHandle)
        ld      bc, prc_SIZEOF
        xor     a
        OZ      OS_Mal
        pop     ix
        jr      c, dcent_4
        call    AddProc
        call    InitProc
        call    PutProcHndl_IX
        ld      hl, ubIdxFlags2
        set     IDXF2_B_6, (hl)

.dcent_2
        ld      sp, $1FFE
        ld      hl, DotOpen_txt
        OZ      GN_Sop
        call    GetProcEnvIDHandle
        ld      (pIdxCurrentProcHandle), de

        ld      a, (ubIdxFlags2)                ; check if it's quitting time
        bit     IDXF2_B_KILL, a
        jr      z, dcent_3
        res     IDXF2_B_KILL, a
        ld      (ubIdxFlags2), a
        OZ      OS_Exit                         ; Quit process
        jr      dcent_5

.dcent_3
        OZ      OS_Ent                          ; Enter an application

;       program execution doesn't return here!

.dcent_4
        ld      a, RC_Pre                       ; Cannot pre-empt, or No Room

.dcent_5
        ld      (ubIdxErrorCode), a
        ld      hl, ubIdxFlags2
        set     IDXF2_B_ERROR, (hl)
        bit     IDXF2_B_6, (hl)
        call    nz, FreeProc

.dcent_6
        ld      a, (eIdxIndexProc+2)            ; enter Index
        ld      b, a
        ld      hl, (eIdxIndexProc)
        call    AddProc
        ld      ix, (pIdxMyProcHandle)
        ld      (pIdxCurrentProcHandle), ix
        ld      b, 0
        ld      c, (iy+prc_dynid)
        OZ      OS_Ent                          ; Enter an application

.dcent_7
        jr      dcent_7                         ; crash

.DotOpen_txt
        defm    1,"2.[",0

;       ----

.ZeroeIdxRunProc
        xor     a
        ld      (pIdxRunProcIX), a
        ld      (pIdxRunProcIX+1), a
        ld      (eIdxRunProc+2), a
        ret

;       ----

;       initialize new process

.InitProc
        push    bc
        push    iy
        pop     hl
        inc     hl                              ; skip link
        inc     hl
        inc     hl
        ld      b, prc_SIZEOF-3                 ; clear rest of proc struct
        call    ZeroMem

        ld      (iy+prc_matchstring), '*'

        push    iy                              ; get default device
        pop     hl
        ld      de, prc_dev
        add     hl, de
        ex      de, hl
        ld      a, 18
        ld      bc, PA_Dev
        OZ      OS_Nq

        ld      hl, -255                        ; get default dir
        add     hl, sp
        ld      sp, hl
        ex      de, hl
        xor     a
        ld      (de), a
        ld      bc, PA_Dir
        ld      a, 255
        OZ      OS_Nq
        pop     de
        push    de
        ld      a, e                            ; first byte
        cp      $21                             ; no dir, skip associate block
        jr      c, iprc_1

        call    AllocAssoc

.iprc_1
        ld      hl, 255
        add     hl, sp
        ld      sp, hl

        ld      c, 1                            ; remember S1 binding
        OZ      OS_Mgb
        push    bc

        push    iy                              ; get unique dynId in range 2-127
.iprc_2
        ld      a, (ubIdxDynamicID)
        inc     a
        jp      p, iprc_3
        xor     a
.iprc_3
        ld      (ubIdxDynamicID), a
        jr      z, iprc_2
        ld      c, a
        ld      iy, eIdxProcList
.iprc_4
        call    GetNextProc
        jr      c, iprc_5                       ; end of list
        ld      a, (iy+prc_dynid)
        cp      c
        jr      z, iprc_2                       ; id in use
        jr      iprc_4
.iprc_5
        ld      a, c
        pop     iy

        pop     bc
        push    af
        OZ      OS_Mpb                          ; restore S1

        pop     af
        ld      (iy+prc_dynid), a
        pop     bc
        ret

;       ----

; Bind process HL into S1, add it into eIdxProcList


.AddProc
        push    bc
        ld      c, 1
        OZ      OS_Mpb                          ; bind DOM in S1

        push    hl
        pop     iy
        ld      de, (eIdxProcList)
        ld      a, (eIdxProcList+2)
        ld      c, a
        call    PutLinkCDE

        pop     bc
        ld      (eIdxProcList), hl
        ld      a, b
        ld      (eIdxProcList+2), a
        ret

;       ----

;       find last process BHL with static handle IX

.GetProcByHandle
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb                          ; Get current binding
        push    bc

        ld      iy, eIdxProcList
        xor     a
        ld      c, a
        ld      h, a
        ld      l, a

.gph_1
        ld      e, c
        push    de
        call    GetNextProc
        pop     de
        ld      c, e
        jr      c, gph_2                        ; no more entries
        push    ix                              ; compare IX with process handle
        pop     de
        ld      a, (iy+prc_hndl+1)
        cp      d
        jr      nz, gph_1
        ld      a, (iy+prc_hndl)
        cp      e
        jr      nz, gph_1                       ; not same, try next
        push    iy                              ; process in CHL, then loop bak
        pop     hl
        ld      c, b
        jr      gph_1

.gph_2
        ld      b, c
        ld      a, b
        or      h
        or      l
        jr      nz, gph_3
        scf

.gph_3
        pop     de
        push    bc
        push    af
        ld      b, d
        ld      c, e
        OZ      OS_Mpb                          ; restore S1
        pop     af
        pop     bc
        ret

;       ----

; Name current application
;
; HL = pointer to a null terminated name

.DCNam
        ld      b, 0
        OZ      OS_Bix                          ; Bind in extended address
        push    de

        push    hl
        ld      hl, (eIdxProcList)              ; running proc
        ld      de, prc_Name
        add     hl, de
        ex      de, hl                          ; name buffer in DE
        pop     hl
        ld      a, (eIdxProcList+2)
        ld      b, a
        ld      c, 15                           ; copy 15 bytes until ctrl char
.dcnam_1
        ld      a, (hl)
        inc     hl
        cp      $20
        jr      nc, dcnam_2
        xor     a
.dcnam_2
        OZ      GN_Wbe                          ; write A to BDE
        inc     de
        or      a
        jr      z, dcnam_3
        dec     c
        jr      nz, dcnam_1
        xor     a                               ; !! use code above to save 2 bytes
        OZ      GN_Wbe

.dcnam_3
        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        ret

;       ----

; handle Director/CLI enquiries
;
; C = reason code, B = 0, HL=process

.DCNq
        push    hl
        pop     iy
        cp      33                              ; A=C, check reason code range
        ld      a, RC_Unk
        jp      nc, SetOsfError

        ld      hl, dcnq_table
        add     hl, bc
        jp      (hl)

.dcnq_table
        jp      dqdev
        jp      dqdir
        jp      dqfnm
        jp      dqdmh
        jp      dqinp
        jp      dqout
        jp      dqprt
        jp      dqtin
        jp      dqtot
        jp      dqtpr
        jp      dqchn

;       ----

; handle Director/CLI settings
;
; C = reason code, B = 0, HL = arg

.DCSp
        push    hl                              ; argumnet to IY
        pop     iy
        cp      9                               ; A=C, check reason code range
        ld      a, RC_Unk
        jp      nc, SetOsfError

        ld      hl, DCSpJump
        add     hl, bc
        jp      (hl)

.DCSpJump
        jp      dsdev
        jp      dsdir
        jp      dsfnm

;       ----

; Get default device

.dqdev
        push    ix
        ld      c, 1
        OZ      OS_Mgb
        push    bc                              ; remember S1

        call    GetFilerProc
        ld      de, prc_dev
        add     hl, de
        jr      retBHL

;       ----

; Get default directory

.dqdir
        push    ix
        ld      c, 1
        OZ      OS_Mgb
        push    bc                              ; remember S1

        call    GetFilerProc
        ld      de, prc_assocptr+2
        add     hl, de
        ld      b, (hl)
        dec     hl
        ld      a, (hl)
        dec     hl
        ld      l, (hl)
        ld      h, a
        or      l
        or      b
        jr      nz, retBHL

        ld      b, 2                            ; copy zero from following byte
        ld      hl, byte_CCAB
        jr      retBHL

.byte_CCAB
        defb 0

;       ----

; Get filename match string

.dqfnm
        push    ix
        ld      c, 1
        OZ      OS_Mgb
        push    bc                              ; remember S1

        call    GetFilerProc
        ld      de, prc_matchstring
        add     hl, de

;       ----

; put results in Osf and return

.retBHL
        ld      (iy+OSFrame_B), b
        ld      (iy+OSFrame_H), h
        ld      (iy+OSFrame_L), l

        pop     bc
        OZ      OS_Mpb                          ; restore S1
        pop     ix
        ret

;       ----

; get the director memory handle

.dqdmh
        ld      ix, (pIdxMemHandle)
        ret

; reset serial port and get NQ_Com

.dqchn
        ld      l, SI_SFT
        OZ      OS_Si                           ; serial soft reset
        ld      bc, NQ_Com
        OZ      OS_Nq                           ; read comms handle
        ret

; get input-T handle

.dqtin
        call    ldIX_00
        call    GetFirstCli
        jr      z, dcnq_ret                     ; !! ret z
        ld      de, cli_instreamT
        jr      ReturnCliHandle

; get output-T handle

.dqtot
        call    ldIX_00
        call    GetFirstCli
        jr      z, dcnq_ret                     ; !! ret z
        ld      de, cli_outstreamT
        jr      ReturnCliHandle

; get printer-T handle

.dqtpr
        call    ldIX_00
        call    GetFirstCli
        jr      z, dcnq_ret                     ; !! ret z
        ld      de, cli_prtstreamT
        jr      ReturnCliHandle

; get IN handle

.dqinp
        ld      bc, NQ_Ihn
        OZ      OS_Nq
        ret

; get OUT handle

.dqout
        ld      bc, NQ_Ohn
        OZ      OS_Nq
        ret
; get printer indirected handle

.dqprt
        ld      bc, NQ_Phn
        OZ      OS_Nq
        ret

.ReturnCliHandle
        ld      c, 1
        OZ      OS_Mpb                          ; bind process in S1
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        pop     ix
        OZ      OS_Mpb                          ; restore S1

.dcnq_ret
        ret

;       ----

; define default device

.dsdev
        push    ix
        ld      hl, -18
        add     hl, sp
        ld      sp, hl

        ex      de, hl
        call    GetOsfHL
        ld      b, 0
        push    de
        OZ      OS_Bix                          ; Bind in extended address

        ex      (sp), hl
        ex      de, hl
        ex      (sp), hl
        ld      b, 17
        call    CopyUntilSub21                  ; from HL to stack buffer
        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix

        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

        call    GetFilerProc
        ld      de, prc_dev
        add     hl, de
        ex      de, hl
        ld      hl, 2
        add     hl, sp

        ld      a, (hl)
        or      a
        jr      nz, dsdev_1                     ; not empty string, copy

        ld      a, 17                           ; get default device into process structire
        ld      bc, PA_Dev
        OZ      OS_Nq
        jr      dsdev_2

.dsdev_1
        ld      b, 17
        call    CopyUntilSub21                  ; from stack buffer

.dsdev_2
        pop     bc                              ; restore S1
        OZ      OS_Mpb

        ld      hl, 18
        add     hl, sp
        ld      sp, hl
        pop     ix
        ret

;       ----

; define default directory

.dsdir
        push    iy
        call    GetOsfHL                        ; caller HL
        ld      b, 0
        OZ      OS_Bix                          ; Bind in extended address
        push    de

        ex      de, hl
        ld      hl, -255
        add     hl, sp

        ld      sp, hl
        ex      de, hl
        ld      b, 255
        call    CopyUntilSub21                  ; from HL to stack buffer

        call    GetFilerProc
        push    hl
        pop     iy
        call    AllocAssoc                      ; copy argument into associate block

        ld      hl, 255
        add     hl, sp
        ld      sp, hl

        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        pop     iy
        ret

;       ----

; Allocate buffer big enough to hold string in stack and copy it

.AllocAssoc
        push    ix
        ld      ix, (pIdxMemHandle)
        ld      hl, 4                           ; skip IX and return addr
        add     hl, sp

        ld      b, 222                          ; max length of string
.alass_1
        ld      a, (hl)
        inc     hl
        cp      $21
        jr      c, alass_2
        djnz    alass_1
        jr      alass_4                         ; too big, exit

.alass_2
        ld      a, 222                          ; allocate memory for string
        sub     b
        jr      nz, alass_3
        call    FreeAssoc                       ; empty string, free assoc block and exit
        jr      alass_4

.alass_3
        inc     a                               ; allocate new buffer, then free old one
        ld      b, 0
        ld      c, a
        ld      e, a
        ld      a, b
        OZ      OS_Mal
        jr      c, alass_4
        call    FreeAssoc

        ld      (iy+prc_assocptr+2), b
        ld      (iy+prc_assocptr+1), h
        ld      (iy+prc_assocptr), l
        ld      (iy+prc_assoclen), e

        ld      c, 1
        OZ      OS_Mpb                          ; bind associate block into S1
        push    bc

        ld      b, e
        ex      de, hl
        ld      hl, 6
        add     hl, sp
        call    CopyUntilSub21                  ; copy string
        pop     bc
        OZ      OS_Mpb                          ; restore S1

.alass_4
        pop     ix
        ret

;       ----

; free process's associate block

.FreeAssoc
        push    bc
        push    hl
        push    de
        ld      a, (iy+prc_assocptr+2)
        ld      h, (iy+prc_assocptr+1)
        ld      l, (iy+prc_assocptr)
        or      h
        or      l
        jr      z, frass_1                      ; no associate, exit

        ld      a, (iy+prc_assocptr+2)
        ld      b, 0
        ld      c, (iy+prc_assoclen)
        OZ      OS_Mfr                          ; Free memory

        xor     a
        ld      (iy+prc_assocptr+2), a
        ld      (iy+prc_assocptr+1), a
        ld      (iy+prc_assocptr), a
        ld      (iy+prc_assoclen), a

.frass_1
        pop     de
        pop     hl
        pop     bc
        ret

;       ----

; define filename match string

.dsfnm
        push    ix
        ld      hl, -17
        add     hl, sp
        ld      sp, hl

        ex      de, hl
        call    GetOsfHL
        ld      b, 0
        push    de
        OZ      OS_Bix                          ; bind in extended address

        ex      (sp), hl
        ex      de, hl
        ex      (sp), hl
        ld      b, 17
        call    CopyUntilSub21                  ; from HL to stack buffer

        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix

        ld      c, 1                            ; store S1
        OZ      OS_Mgb
        push    bc

        call    GetFilerProc
        ld      de, prc_matchstring
        add     hl, de
        ex      de, hl
        ld      hl, 2
        add     hl, sp
        ld      b, 17
        call    CopyUntilSub21                  ; from stack buffer to process structure

        pop     bc                              ; restore S1
        OZ      OS_Mpb

        ld      hl, 17
        add     hl, sp
        ld      sp, hl
        pop     ix
        ret

;       ----

; copy B bytes from (HL) into (DE) until chars is <$21

.CopyUntilSub21
        ld      a, (hl)
        ld      (de), a
        inc     de
        inc     hl
        cp      $21
        jr      nc, cus21_1
        dec     b
        ret
.cus21_1
        djnz    CopyUntilSub21
        ret

;       ----

; OUT: HL=proc

.GetFilerProc
        push    ix
        push    de
        ld      ix, eIdxProcList

.gfil_1
        ld      e, b
        ld      b, (ix+2)                       ; get next in BHL, check for NULL
        ld      h, (ix+1)
        ld      l, (ix+0)
        ld      a, l
        or      h
        or      b
        jr      nz, gfil_2

        ld      hl, (eIdxIndexProc)             ; No more entries, return Index
        ld      a, (eIdxIndexProc+2)
        ld      b, a
        ld      e, a
        ld      c, 1
        OZ      OS_Mpb                          ; bind Index in S1 and return it
        ld      b, e
        jr      gfil_3

.gfil_2
        ld      e, b
        ld      c, 1
        OZ      OS_Mpb                          ; bind process in S1
        ld      b, e
        push    hl
        push    bc
        push    hl
        pop     ix
        ld      d, (ix+prc_hndl+1)
        ld      e, (ix+prc_hndl)
        push    ix
        push    de
        pop     ix
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        pop     ix
        pop     bc
        pop     hl
        and     AT_Film                         ; file manager (Filer)
        jr      nz, gfil_1

.gfil_3
        pop     de
        pop     ix
        ret

;       ----

;       free running process

.FreeProc
        push    ix
        push    bc
        push    hl
        ld      c, 1
        OZ      OS_Mgb                          ; remember S1 binding
        push    bc

        ld      a, (eIdxProcList+2)             ; active proc at top
        ld      b, a
        ld      hl, (eIdxProcList)
        ld      iy, eIdxProcList
        call    RemoveBHL
        jr      c, frp_3                        ; proc not found, exit (!!never happens)
        ld      de, (eIdxIndexProc)
        ld      a, (eIdxIndexProc+2)
        ex      de, hl
        sbc     hl, de
        ex      de, hl
        jr      nz, frp_1
        sub     b
        jr      z, frp_3                        ; don't free Index process

.frp_1
        push    bc
        push    hl
        ld      c, 1
        OZ      OS_Mpb                          ; bind proc in S1

        push    hl                              ; free associated block
        pop     iy
        ld      a, (iy+prc_assoclen)
        or      a
        jr      z, frp_2                        ; nothing to free
        ld      c, a
        ld      b, 0
        ld      a, (iy+prc_assocptr+2)
        ld      h, (iy+prc_assocptr+1)
        ld      l, (iy+prc_assocptr)
        ld      ix, (pIdxMemHandle)
        OZ      OS_Mfr

.frp_2
        pop     hl                              ; free proc itself
        pop     bc
        ld      a, b
        ld      ix, (pIdxMemHandle)
        ld      bc, prc_SIZEOF
        OZ      OS_Mfr

.frp_3
        pop     bc                              ; restore S1
        push    af
        OZ      OS_Mpb
        pop     af
        pop     hl
        pop     bc
        pop     ix
        ret

;       ----

; Remove node BHL from list IY

.RemoveBHL
        push    iy
        push    ix
        ld      a, (ubIdxProcRmCount)           ; increment counter
        inc     a
        ld      (ubIdxProcRmCount), a

.rmv_1
        call    GetLinkCDE                      ; get link to next
        ld      a, c
        or      e
        or      d
        ld      a, RC_Eof
        scf
        jr      z, rmv_4                        ; no more entries

        ld      a, b                            ; compare CDE to BHL
        cp      c
        jr      nz, rmv_2
        ld      a, h
        cp      d
        jr      nz, rmv_2
        ld      a, l
        cp      e
        jr      z, rmv_3                        ; match

.rmv_2
        push    bc                              ; follow link to next node and try again
        ld      b, c
        push    de
        pop     iy
        ld      c, 1
        OZ      OS_Mpb                          ; bind node in S1
        pop     bc
        jr      rmv_1

.rmv_3
        ld      b, c                            ; bind next into S2
        ld      c, 2
        OZ      OS_Mpb
        push    bc
        set     7, d                            ; S2 fix and copy link from next to current
        res     6, d
        ld      a, (de)
        ld      (iy+0), a
        inc     de
        ld      a, (de)
        ld      (iy+1), a
        inc     de
        ld      a, (de)
        ld      (iy+2), a
        pop     bc
        OZ      OS_Mpb                          ; restore S2

        call    GetLinkCDE                      ; get link to next

.rmv_4
        pop     ix
        pop     iy
        ret

;       ----

.GetLinkCDE
        ld      c, (iy+2)
        ld      d, (iy+1)
        ld      e, (iy+0)
        ret

;       ----

.GetLinkBHL
        ld      b, (iy+2)
        ld      h, (iy+1)
        ld      l, (iy+0)
        ret                                     ; !! could test for 0:0000 here

;       ----

.ZeroMem
        xor     a
.zm_1
        ld      (hl), a
        inc     hl
        djnz    zm_1
        ret

;       ----

.SetOsfError
        ld      (iy+OSFrame_A), a
        set     Z80F_B_C, (iy+OSFrame_F)
        ret

;       ----

.ldIX_00
        ld      ix, 0
        ret

;       ----

.GetOsfHL
        ld      h, (iy+OSFrame_H)
        ld      l, (iy+OSFrame_L)
        ret

;       ----

.GetProcEnvIDHandle
        ld      b, (iy+prc_stkProcEnv+2)
        ld      c, (iy+prc_dynid)
        ld      h, (iy+prc_stkProcEnv+1)
        ld      l, (iy+prc_stkProcEnv)

;       ----

.GetProcHandle
        ld      d, (iy+prc_hndl+1)
        ld      e, (iy+prc_hndl)
        ret

;       ----

.PutProcHndl_IX
        push    ix
        pop     de
        ld      (iy+prc_hndl+1), d
        ld      (iy+prc_hndl), e
        ret

;       ----

; Invoke new CLI
;
; HL = string, null terminated, B = 0, C = length of string

.DCIcl
        push    ix
        push    iy

        ld      a, b
        or      h
        or      l
        jr      z, dcicl_1                      ; string=NULL

        ld      a, OP_MEM
        OZ      OS_Op                           ; open memory for input
        jp      c, dcicl_7

.dcicl_1
        call    CompareIX_INP
        jp      z, dcicl_7                      ; mem = :INP

        push    ix
        ld      ix, (pIdxMemHandle)
        xor     a
        ld      bc, cli_SIZEOF
        OZ      OS_Mal                          ; Allocate memory
        pop     ix                              ; restore MEM input
        jp      c, dcicl_5

        ld      c, 1
        OZ      OS_Mpb                          ; bind mem in S1
        push    bc

        push    hl                              ; clear allocated memory
        pop     iy
        ld      b, cli_SIZEOF
        call    ZeroMem

        push    ix                              ; set default streams
        pop     bc
        ld      (iy+cli_instream+1), b
        ld      (iy+cli_instream), c

        ld      bc, NQ_Shn
        OZ      OS_Nq                           ; read screen handle
        push    ix
        pop     bc
        ld      (iy+cli_outstream+1), b
        ld      (iy+cli_outstream), c

        ld      bc, NQ_Rhn
        OZ      OS_Nq                           ; read direct printer handle
        push    ix
        pop     bc
        ld      (iy+cli_prtstream+1), b
        ld      (iy+cli_prtstream), c

        ld      de, (eIdxCliList)
        ld      a, (eIdxCliList+2)
        ld      c, a
        call    PutLinkCDE
        ld      (iy+cli_StreamFlags), CLIS_INOPEN

        call    GetFirstCli
        jr      z, dcicl_4

; copy stream pointers from existing CLI

        ld      c, 1
        OZ      OS_Mpb                          ; bind old CLI into S1

        ld      de, cli_outstream
        add     hl, de
        ld      c, 5                            ; !! this could be simplified to
.dcicl_2
        ld      e, (hl)                         ; !! 10 byte copy
        inc     hl
        ld      d, (hl)
        inc     hl
        push    de                              ; memorize stream pointer
        dec     c
        jr      nz, dcicl_2

        ld      c, 1
        OZ      OS_Mpb                          ; restore S1

        push    iy
        pop     hl
        ld      de, cli_prtstreamT+1
        add     hl, de
        ld      c, 5
.dcicl_3
        pop     de                              ; restore stream pointer
        ld      (hl), d
        dec     hl
        ld      (hl), e
        dec     hl
        dec     c
        jr      nz, dcicl_3

.dcicl_4
        pop     bc
        OZ      OS_Mpb                          ; restore S1

        push    iy
        pop     hl
        ld      (eIdxCliList), hl
        ld      a, b
        ld      (eIdxCliList+2), a

        ld      a, CL_INC                       ; increment CLI use count
        OZ      OS_Cli
        jr      dcicl_7

.dcicl_5
        push    af                              ; close MEM if it was opened
        ld      a, (iy+OSFrame_B)
        or      (iy+OSFrame_H)
        or      (iy+OSFrame_L)
        jr      z, dcicl_6
        OZ      OS_Cl
.dcicl_6
        pop     af

.dcicl_7
        pop     iy
        pop     ix
        call    c, SetOsfError
        ret

;       ----

.CompareIX_INP
        push    ix
        ld      bc, NQ_Ihn
        OZ      OS_Nq                           ; read IN handle
        ex      (sp), ix                        ; pop ix
        pop     bc                              ; handle into bc
        push    ix
        pop     hl
        or      a
        sbc     hl, bc                          ; compare ix with :INP
        ret

;       ----

; rebind streams

; A = identifier for stream to rebind

.DCRbd
        push    iy
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

        ld      c, (iy+OSFrame_A)
        call    GetCLI
        jr      c, dcrbd_8
        ld      a, c                            ; !! use djnz

        cp      RB_IN                           ; input stream
        jr      nz, dcrbd_1
        ld      bc, cli_instream
        ld      a, CLIS_INOPEN
        jr      dcrbd_7

.dcrbd_1
        cp      RB_OUT                          ; output stream
        jr      nz, dcrbd_2
        ld      bc, cli_outstream
        ld      a, CLIS_OUTOPEN
        jr      dcrbd_7

.dcrbd_2
        cp      RB_PRT                          ; printer stream
        jr      nz, dcrbd_3
        ld      bc, cli_prtstream
        ld      a, CLIS_PRTOPEN
        jr      dcrbd_7

.dcrbd_3
        cp      RB_INT                          ; input stream T
        jr      nz, dcrbd_4
        ld      bc, cli_instreamT
        ld      a, CLIS_INTOPEN
        jr      dcrbd_7

.dcrbd_4
        cp      RB_OPT                          ; output stream T
        jr      nz, dcrbd_5
        ld      bc, cli_outstreamT
        ld      a, CLIS_OUTTOPEN
        jr      dcrbd_7

.dcrbd_5
        cp      RB_PTT                          ; printer stream T
        jr      nz, dcrbd_6
        ld      bc, cli_prtstreamT
        ld      a, CLIS_PRTTOPEN
        jr      dcrbd_7

.dcrbd_6
        ld      a, RC_Bad
        scf
        jr      dcrbd_8

.dcrbd_7
        call    sub_D0D1

.dcrbd_8
        pop     bc
        push    af
        OZ      OS_Mpb                          ; restore S1
        pop     af
        pop     iy
        call    c, SetOsfError
        ret

;       ----

.sub_D0D1
        call    RebindStream
        ld      a, (iy+cli_StreamFlags)
        and     CLIS_INTOPEN | CLIS_OUTTOPEN | CLIS_PRTTOPEN | CLIS_INOPEN | CLIS_OUTOPEN | CLIS_PRTOPEN
        call    z, FreeCli                      ; call if all streams closed
        ret

;       ----

; examine CLI input

; OUT:  Fc=0 if CLI has input stream

.DCXin
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

        push    iy
        call    GetCLI
        jr      c, dcxin_1

        ld      bc, cli_instream                ; return RC_Eof if we don't have input stream
        add     iy, bc
        ld      a, (iy+0)
        or      (iy+1)
        jr      nz, dcxin_1
        ld      a, RC_Eof
        scf

.dcxin_1
        pop     iy
        call    c, SetOsfError

        pop     bc
        OZ      OS_Mpb                          ; restore S1
        ret

;       ----

; screen driver SOH call
;
; HL = buffer address in the screen base file
; B = screen base file bank ($21, always)
; C = length of data

.DCGen
        OZ      GN_Rbe                          ; Read byte at extended address

        push    af
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        pop     af
        push    bc
        push    iy

        ld      c, a
        call    GetCLI
        jr      c, dcgen_2

        ld      a, c
        cp      ']'
        jr      nz, dcgen_1
        set     CLIF_B_DISABLEPRT, (iy+cli_Flags)
        jr      dcgen_2

.dcgen_1
        cp      '['
        jr      nz, dcgen_2
        res     CLIF_B_DISABLEPRT, (iy+cli_Flags)

.dcgen_2
        pop     iy
        pop     bc
        OZ      OS_Mpb                          ; restore S1
        ret

;       ----

; poll for card usage
;
; IN:   A = card slot (0 to 3), 0 is internal
; OUT:  F<=1 if slot not in use, Fz=0 if in use

.DCPol
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc
        push    iy

        ld      a, (iy+OSFrame_A)
        and     3                               ; bank into top bits
        rrca
        rrca
        ld      c, a

        ld      iy, eIdxProcList
.dcpol_1
        call    GetNextProc
        ccf
        jr      nc, dcpol_3                     ; no more entries

        ld      a, (iy+prc_hndl)                ; !! should this be prc_assocptr+2?
        and     $C0
        cp      c
        jr      z, dcpol_2
        ld      a, (iy+prc_stkProcEnv+2)        ; stkProcEnv+2
        and     $C0
        cp      c
        jr      nz, dcpol_1

.dcpol_2
        scf

.dcpol_3
        pop     iy
        jr      c, dcpol_4
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1

.dcpol_4
        pop     bc
        OZ      OS_Mpb                          ; restore S1
        ret

;       ----

; read from CLI
;

.DCIn
        push    ix
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

        push    iy
        ld      b, (iy+OSFrame_B)
        ld      c, (iy+OSFrame_C)
        call    GetCLI
        jp      c, dcin_16

        ld      (iy+cli_argB), b
        ld      (iy+cli_argC), c
        jr      dcin_2

.dcin_1
        call    GetCLI
        jp      c, dcin_16
.dcin_2
        ld      d, (iy+cli_instream+1)
        ld      e, (iy+cli_instream)
        ld      a, e
        or      d
        jr      nz, dcin_3

        call    ldBC_CliArgBC
        ld      a, CL_RIM
        OZ      OS_Cli                          ; get raw input
        jp      nc, dcin_10
        jp      dcin_13

.dcin_3
        call    ReadCliChar
        jp      c, dcin_13

        bit     CLIF_B_IGNOREMETA, (iy+cli_Flags)       ; .J, skip meta chars
        jr      nz, dcin_9

        cp      CR
        jr      nz, dcin_4
        res     CLIF_B_NOTBOL, (iy+cli_Flags)   ; line start
        jr      dcin_3

;       check for . commands

.dcin_4
        ld      c, (iy+cli_Flags)
        bit     CLIF_B_NOTBOL, c                ; only check . at the line start
        jr      nz, dcin_5
        cp      '.'
        jr      nz, dcin_5
        call    FileControl
        jp      c, dcin_13
        jr      dcin_2

.dcin_5
        set     CLIF_B_NOTBOL, (iy+cli_Flags)   ; not BOL
        cp      '|'
        jr      nz, dcin_6
        set     CLIF_B_DIAMOND, (iy+cli_Flags)
        bit     CLIF_B_DIAMOND, c               ; check for ||
        jr      z, dcin_3
        res     CLIF_B_DIAMOND, (iy+cli_Flags)
        jr      dcin_8

.dcin_6
        cp      '#'
        jr      nz, dcin_7
        set     CLIF_B_SQUARE, (iy+cli_Flags)
        bit     CLIF_B_SQUARE, c                ; check for ##
        jr      z, dcin_3
        res     CLIF_B_SQUARE, (iy+cli_Flags)
        jr      dcin_8

.dcin_7
        cp      '~'
        jr      nz, dcin_8
        set     CLIF_B_META, (iy+cli_Flags)
        bit     CLIF_B_META, c                  ; check for ~~
        jr      z, dcin_3
        res     CLIF_B_META, (iy+cli_Flags)

.dcin_8
        bit     CLIF_B_META, (iy+cli_Flags)
        jr      z, dcin_9

;       handle ~

        OZ      GN_Cls                          ; Classify a character
        jr      nc, dcin_9                      ; not alpha
        and     $df                             ; upper

        cp      'S'                             ; ~S
        jr      nz, dcin_9
        res     CLIF_B_META, (iy+cli_Flags)
        set     CLIF_B_SHIFT, (iy+cli_Flags)
        jr      dcin_3

.dcin_9
        ld      e, a

        ld      a, (iy+cli_Flags)
        and     CLIF_SHIFT | CLIF_DIAMOND | CLIF_SQUARE | CLIF_META
        ld      d, a                            ; meta flags

        ld      a, (iy+cli_Flags)               ; clear meta flags !! xor (iy+cli_Flags)
        and     ~( CLIF_SHIFT | CLIF_DIAMOND | CLIF_SQUARE | CLIF_META )
        ld      (iy+cli_Flags), a

        ld      a, CL_MBC
        OZ      OS_Cli                          ; meta/base to character conversion
        jp      c, dcin_3

.dcin_10
        push    de
        ld      d, (iy+cli_instreamT+1)
        ld      e, (iy+cli_instreamT)
        call    ldIX_DE
        pop     de
        jr      z, dcin_12                      ; no instreamT

        call    KeyToCLI
        jr      nc, dcin_12

        call    ldIX_00
        ld      a, CLIS_INTOPEN
        ld      bc, cli_instreamT
        call    RebindStream
        ld      a, (iy+cli_StreamFlags)
        and     CLIS_INTOPEN | CLIS_OUTTOPEN | CLIS_PRTTOPEN | CLIS_INOPEN | CLIS_OUTOPEN | CLIS_PRTOPEN
        jr      z, dcin_15                      ; all streams closed

.dcin_12
        call    ldBC_CliArgBC
        pop     iy
        ld      (iy+OSFrame_B), b
        ld      (iy+OSFrame_C), c
        ld      (iy+OSFrame_D), d
        ld      (iy+OSFrame_E), e

        pop     bc
        OZ      OS_Mpb                          ; restore S1
        pop     ix
        ret

.dcin_13
        cp      RC_Eof
        jr      z, dcin_15
        cp      RC_Time                         ; Timeout
        scf
        jr      z, dcin_16
        cp      RC_Susp                         ; Suspicion of pre-emption
        scf
        jr      z, dcin_16
        cp      RC_Esc                          ; Escape condition (e.g. ESC pressed)
        scf
        jr      z, dcin_16
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Quit
        jr      z, dcin_14
        scf
        push    af
        call    FreeCli
        pop     af
        jr      dcin_16

.dcin_14
        call    FreeAllCLIs
        jr      dcin_16

.dcin_15
        call    FreeCli
        jp      dcin_1

.dcin_16
        pop     iy
        pop     bc
        push    af
        OZ      OS_Mpb                          ; restore S1
        pop     af

        pop     ix
        ld      (iy+OSFrame_A), a
        call    c, SetOsfError
        ret

;       ----

.ldBC_CliArgBC
        ld      b, (iy+cli_argB)
        ld      c, (iy+cli_argC)
        ret

;       ----

.FreeAllCLIs
        call    FreeCli
        jr      nc, FreeAllCLIs
        ccf
        ret

;       ----

; write to CLI

.DCOut
        push    ix
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

        push    iy

        ld      c, (iy+OSFrame_A)
        call    GetCLI
        jr      nc, dcout_1

        push    af                              ; no CLI, output to screen
        push    bc
        ld      bc, NQ_Shn
        OZ      OS_Nq                           ; get screen handle
        pop     bc
        ld      a, c
        OZ      OS_Pb                           ; write byte A to screen
        pop     af
        jr      dcout_7

.dcout_1
        ld      b, (iy+cli_Flags)

        ld      d, (iy+cli_outstream+1)
        ld      e, (iy+cli_outstream)
        call    ldIX_DE
        jr      z, dcout_2

        ld      a, c
        call    PutWithTimeout
        jr      nc, dcout_2
        ld      a, CLIS_OUTOPEN                 ; close output if error
        ld      bc, cli_outstream
        jr      dcout_6

.dcout_2
        ld      d, (iy+cli_outstreamT+1)
        ld      e, (iy+cli_outstreamT)
        call    ldIX_DE
        jr      z, dcout_7
        bit     CLIF_B_DISABLEPRT, b
        jr      nz, dcout_7

        ld      a, (iy+cli_outprefix)
        or      a
        jr      nz, dcout_4

        ld      a, c
        cp      ' '
        jr      nc, dcout_5
        cp      ESC
        jr      z, dcout_5
        cp      $0E
        jr      nc, dcout_3
        cp      7
        jr      nc, dcout_5                     ; 07-0D

.dcout_3
        ld      (iy+cli_outprefix), c
        call    GetCLIPrefixBuf
        OZ      OS_Isq                          ; Initialize prefix sequence
        jr      dcout_7

.dcout_4
        push    bc
        call    GetCLIPrefixBuf
        pop     bc
        ld      a, c
        OZ      OS_Wsq                          ; Write to prefix sequence
        dec     hl
        ld      (hl), a
        jr      dcout_7

.dcout_5
        ld      a, c
        call    PutWithTimeout
        jr      nc, dcout_7

        ld      a, CLIS_OUTTOPEN
        ld      bc, cli_outstreamT

.dcout_6
        call    ldIX_00                         ; close CLI stream
        call    sub_D0D1

.dcout_7
        pop     iy
        pop     bc
        OZ      OS_Mpb                          ; restore S1
        pop     ix
        ret

;       ----

.GetCLIPrefixBuf
        ld      bc, cli_PrefixBuffer
        push    iy
        pop     hl
        add     hl, bc
        ret

;       ----

; print to CLI

.DCPrt
        push    ix
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc
        push    iy

        ld      c, (iy+OSFrame_A)
        call    GetCLI
        jr      c, dcprt_3

        ld      d, (iy+cli_prtstream+1)
        ld      e, (iy+cli_prtstream)
        call    ldIX_DE
        jr      z, dcprt_1

        ld      a, c
        call    PutWithTimeout
        jr      nc, dcprt_1

        ld      a, CLIS_PRTOPEN
        push    bc
        ld      bc, cli_prtstream
        call    ldIX_00                         ; close stream after error
        call    sub_D0D1

        pop     bc
        call    GetCLI
        jr      c, dcprt_3

.dcprt_1
        ld      d, (iy+cli_prtstreamT+1)
        ld      e, (iy+cli_prtstreamT)
        call    ldIX_DE
        jr      z, dcprt_2

        ld      a, c
        call    PutWithTimeout
        jr      nc, dcprt_2

        call    ldIX_00                         ; close stream after error
        ld      a, CLIS_PRTTOPEN
        ld      bc, cli_prtstreamT
        call    sub_D0D1

.dcprt_2
        or      a                               ; Fc=0

.dcprt_3
        pop     iy
        pop     bc
        push    af
        OZ      OS_Mpb                          ; restore S1
        pop     af
        call    c, SetOsfError
        pop     ix
        ret

;       ----

;       convert input into CLI code

.KeyToCLI
        push    de
        ld      a, CL_CMB
        OZ      OS_Cli                          ; character to meta/base conversion
        ccf
        jr      nc, k2c_5

        bit     QUAL_B_SHIFT, d
        jr      z, k2c_1
        ld      a, '~'
        call    PutWithTimeout
        jr      c, k2c_5
        ld      a, 'S'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_1
        bit     QUAL_B_CTRL, d                  ; <>
        jr      z, k2c_2
        ld      a, '|'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_2
        bit     QUAL_B_ALT, d                   ; []
        jr      z, k2c_3
        ld      a, '#'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_3
        bit     QUAL_B_SPECIAL, d
        jr      z, k2c_4
        ld      a, '~'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_4
        ld      a, e
        call    PutWithTimeout

.k2c_5
        pop     de
        ret

;       ----

.PutWithTimeout
        push    bc
        call    ldBC_CliArgBC
        OZ      OS_Pbt                          ; write byte A to handle IX, BC=timeout
        pop     bc
        ret

;       ----

.FreeCli
        call    GetFirstCli
        scf
        ld      a, RC_Eof                       ; End Of File
        jr      z, locret_D456

        push    hl
        pop     iy
        ld      c, 1
        OZ      OS_Mpb                          ; bind CLI in S1

        call    ldIX_00                         ; close all streams
        ld      a, CLIS_INOPEN
        ld      bc, cli_instream
        call    RebindStream
        ld      a, CLIS_INTOPEN
        ld      bc, cli_instreamT
        call    RebindStream
        ld      a, CLIS_OUTOPEN
        ld      bc, cli_outstream
        call    RebindStream
        ld      a, CLIS_OUTTOPEN
        ld      bc, cli_outstreamT
        call    RebindStream
        ld      a, CLIS_PRTOPEN
        ld      bc, cli_prtstream
        call    RebindStream
        ld      a, CLIS_PRTTOPEN
        ld      bc, cli_prtstreamT
        call    RebindStream

        call    GetLinkCDE                      ; next CLI
        ld      iy, eIdxCliList
        push    de
        push    bc
        call    GetLinkBHL                      ; this CLI
        ld      a, b
        ld      bc, cli_SIZEOF
        ld      ix, (pIdxMemHandle)
        OZ      OS_Mfr                          ; free CLI
        pop     bc
        pop     de
        call    PutLinkCDE

        ld      a, CL_DEC
        OZ      OS_Cli                          ; decrement CLI use count

.locret_D456
        ret

;       ----

.PutLinkCDE
        ld      (iy+2), c
        ld      (iy+1), d
        ld      (iy+0), e
        ret

;       ----

; CLI . commands

.FileControl
        call    ReadCliChar
        ret     c
        OZ      GN_Cls                          ; Classify a character
        jr      nc, fc_1                        ; not alpha
        and     $df                             ; upper

.fc_1
        cp      'J'
        jr      nz, fc_2
        set     CLIF_B_IGNOREMETA, (iy+cli_Flags)
        jp      fc_15

.fc_2
        cp      '*'
        jr      nz, fc_4

        call    OpenRedirectRd                  ; open CLI file
        jp      c, fc_15
        ld      hl, 0
        ld      b, l
        OZ      DC_Icl                          ; Invoke new CLI
        jr      nc, fc_3
        push    af
        xor     a
        OZ      OS_Cl                           ; close file/stream
        pop     af
        ret
.fc_3
        call    SkipLine                        ; skip over the rest of line
        jp      GetCLI                          ; get new CLI

.fc_4
        ld      c, 0
        OZ      GN_Cls
        jr      nc, fc_5                        ; not alpha
        and     $df                             ; upper

        cp      'T'
        jr      nz, fc_5
        inc     c                               ; have T
        push    bc
        call    ReadCliChar
        pop     bc
        ret     c

.fc_5
        cp      '<'
        jr      nz, fc_7
        ld      a, c
        or      a
        jr      z, fc_6

        call    OpenRedirectWr                  ; .T< - create input file
        jp      c, fc_17
        ld      a, CLIS_INTOPEN
        ld      bc, cli_instreamT
        jr      fc_11

.fc_6
        call    OpenRedirectRd                  ; .< - open input
        jp      c, fc_17
        call    CompareIX_INP
        jp      z, fc_15
        res     CLIF_B_NOTBOL, (iy+cli_Flags)
        ld      (iy+cli_bytesleft), 0
        ld      a, CLIS_INOPEN
        ld      bc, cli_instream
        call    RebindStream
        jp      fc_16

.fc_7
        cp      '>'
        jr      nz, fc_9
        call    OpenRedirectWr
        jp      c, fc_17
        ld      a, c
        or      a
        jr      nz, fc_8

        ld      a, CLIS_OUTOPEN                 ; .>
        ld      bc, cli_outstream
        jr      fc_11

.fc_8
        ld      a, CLIS_OUTTOPEN                ; .T>
        ld      bc, cli_outstreamT
        jr      fc_11

.fc_9
        cp      '='
        jr      nz, fc_12
        call    OpenRedirectWr
        jr      c, fc_17
        ld      a, c
        or      a
        jr      nz, fc_10

        ld      a, CLIS_PRTOPEN                 ; .=
        ld      bc, cli_prtstream
        jr      fc_11

.fc_10
        ld      a, CLIS_PRTTOPEN                ; .T=
        ld      bc, cli_prtstreamT

.fc_11
        push    bc
        push    af
        call    SkipLine                        ; skip rest of line
        pop     af
        pop     bc
        call    RebindStream
        jr      fc_16

.fc_12
        cp      'S'
        jr      nz, fc_13
        call    ldIX_00                         ; .S - exit CLI
        ld      bc, cli_instream
        ld      a, CLIS_INOPEN
        jr      fc_11

.fc_13
        cp      ';'
        jr      nz, fc_14
        call    SkipLine                        ; .; - comment
        jr      fc_17

.fc_14
        cp      'D'
        jr      nz, fc_16

        set     CLIF_B_FILLALL, (iy+cli_Flags)  ; delay
        call    FillCLIBuffer
        jr      c, fc_17

        call    GetLineBuffer
        xor     a
        ld      d, h
        ld      e, l
        OZ      GN_Skd                          ; Bypass delimiters in a sequence
        jr      c, fc_16
        or      a                               ; Fc=0
        push    hl
        sbc     hl, de                          ; bytes skipped
        ld      a, (iy+cli_bytesleft)
        sub     l
        pop     hl
        jr      c, fc_16
        jr      z, fc_16
        ld      b, a
        ld      de, 2                           ; return in BC
        OZ      GN_Gdn                          ; ASCII to integer conversion
        jr      c, fc_15
        OZ      OS_Dly                          ; delay a given period

.fc_15
        call    SkipLine
.fc_16
        or      a
.fc_17
        ret

;       ----

.SkipLine
        call    ReadCliChar
        ret     c
        cp      CR
        jr      nz, SkipLine
        res     CLIF_B_NOTBOL, (iy+cli_Flags)
        ret

;       ----

.OpenRedirectRd
        call    GetRedirectName
        call    nc, OpenRead
        ret

;       ----

.OpenRedirectWr
        call    GetRedirectName
        call    nc, OpenWrite
        ret

;       ----

.GetRedirectName
        set     CLIF_B_FILLALL, (iy+cli_Flags)
        call    FillCLIBuffer
        ret     c

;       ----

.GetLineBuffer
        push    de
        push    iy
        pop     hl
        ld      de, cli_LineBuffer
        add     hl, de
        pop     de
        or      a
        ret

;       ----

; Get running CLI, check for abort
;OUT:   Fc=0, IY=CLI
;       Fc=1

.GetCLI
        push    bc
        ld      d, 0
        ld      a, CL_ACK
        OZ      OS_Cli                          ; acknowledge CLI/Escape, reset shift / <>
        jr      z, gcli_1                       ; no escape

        push    de
        ld      a, CL_ACK
        OZ      OS_Cli                          ; restore flags
        pop     de
        bit     QUAL_B_CTRL, d                  ; <>
        jr      nz, gcli_3
        call    FreeCli                         ; ESC - abort

.gcli_1
        call    GetFirstCli
        scf
        ld      a, RC_Eof
        jr      z, gcli_2
        push    hl
        pop     iy
        ld      c, 1
        OZ      OS_Mpb                          ; bind CLI into S1

.gcli_2
        pop     bc
        ret

.gcli_3
        call    FreeAllCLIs                     ; <> ESC - abort all
        jr      gcli_1

;       ----

; BC stream offset, A stream bit

.RebindStream
        push    de
        push    iy
        pop     hl
        add     hl, bc
        ld      c, a
        and     (iy+cli_StreamFlags)
        jr      z, rbds_1                       ; stream not open

        ld      e, (hl)                         ; close old stream and clear flag
        inc     hl
        ld      d, (hl)
        dec     hl
        push    de
        ex      (sp), ix
        OZ      OS_Cl                           ; close file/stream
        pop     ix
        ld      a, $FF                          ; !! 'ld a,c; cpl'
        sub     c
        and     (iy+cli_StreamFlags)
        ld      (iy+cli_StreamFlags),   a

.rbds_1
        push    ix                              ; set stream, set flag if not NULL
        pop     de
        ld      (hl), e
        inc     hl
        ld      (hl), d
        ld      a, e
        or      d
        jr      z, rbds_2
        ld      a, c
        or      (iy+cli_StreamFlags)
        ld      (iy+cli_StreamFlags),   a

.rbds_2
        pop     de
        ret

;       ----

.ReadCliChar
        push    de
        push    ix
        call    FillCLIBuffer
        jr      c, rc_2
        ld      de, cli_LineBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      c, (hl)
        push    bc
        ld      a, (iy+cli_bytesleft)
        dec     a
        ld      (iy+cli_bytesleft), a
        jr      z, rc_1
        ld      d, h                            ; move data to the beginning of buffer
        ld      e, l
        inc     hl
        ld      b, 0
        ld      c, a
        ldir

.rc_1
        pop     bc
        ld      a, c
        or      a

.rc_2
        pop     ix
        pop     de
        ret

;       ----

.FillCLIBuffer
        ld      d, (iy+cli_instream+1)
        ld      e, (iy+cli_instream)
        push    de
        pop     ix                              ; IX=instream
        ld      de, cli_LineBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      a, CLI_LINEBUFSIZE
        ld      d, 0
        ld      e, (iy+cli_bytesleft)
        sub     e
        jr      z, fcb_3
        add     hl, de
        ex      de, hl

        ld      b, 1                            ; read one byte or buffer full
        bit     CLIF_B_FILLALL, (iy+cli_Flags)
        jr      z, fcb_1
        ld      b, a
        res     CLIF_B_FILLALL, (iy+cli_Flags)

.fcb_1
        push    bc                              ; read bytes until 0D or 20-FF
        call    ldBC_CliArgBC
        OZ      OS_Gbt                          ; get byte with timeout
        pop     bc
        jr      c, fcb_3
        cp      CR
        jr      z, fcb_2
        cp      $20
        jr      c, fcb_1

.fcb_2
        ld      (de), a
        inc     de
        inc     (iy+cli_bytesleft)
        cp      CR
        jr      z, fcb_3                        ; end at CR
        djnz    fcb_1

.fcb_3
        ret     nc
        ld      c, a
        ld      a, (iy+cli_bytesleft)
        or      a
        ret     nz
        ld      a, c
        scf
        ret

;       ----

.GetFirstCli
        push    iy
        ld      iy, eIdxCliList
        call    GetLinkBHL
        ld      a, b
        or      h
        or      l
        pop     iy
        ret

;       ----

.cmd_card
        ld      hl, mem_1fd6
        ld      b, 36
        call    ZeroMem
        ld      d, 3                            ; slot #
        ld      iy, mem_1fd6+3*12

.crd_1
        ld      bc, -12
        add     iy, bc
        ld      e, 0                            ; bank

.crd_2
        ld      bc, NQ_Slt
        OZ      OS_Nq                           ; read slot type information
        jr      c, crd_7                        ; no card?
        and     ~$40
        jr      z, crd_6

        bit     7, a                            ; available RAM
        push    af

        ld      bc, 6<<8|0                      ; find lowest set bit
.crd_3
        rrca                                    ; !! pre-increment
        jr      c, crd_4
        inc     c
        djnz    crd_3

.crd_4
        sla     c                               ; lowest set bit *2
        pop     af
        jr      nz, crd_5
        inc     c                               ; inc if not available RAM

.crd_5
        ld      b, 0
        push    iy
        pop     hl
        add     hl, bc
        inc     (hl)

.crd_6
        inc     e
        bit     6, e                            ; $40
        jr      z, crd_2                        ; loop thru all banks

.crd_7
        dec     d
        jr      nz, crd_1                       ; loop thru slots 1-3

        ld      a, 2                            ; card display
        ld      (ubIdxActiveWindow),    a
        xor     a
        ld      (byte_0E1D), a                  ; !! not used
        ld      (ubIdxSelectorPos), a
        jp      loc_C0D6

;       ----

.DrawCardWd
        ld      hl, CardsWd_txt
        OZ      GN_Sop
        call    DisplayCards
        jp      MainLoop

;       ----

.DisplayCards
        ld      d, 3

.dcrds_1
        ld      a, d
        dec     a
        call    GetCardData
        call    DisplayCard
        dec     d
        jr      nz, dcrds_1
        ret

;       ----

.DisplayCard
        push    de
        ld      a, d
        add     a, 2
        ld      c, a
        ld      b, 0
        call    MoveXY_BC

        ld      c, (iy+3)
        ld      a, 15
        call    PrintCardSize                   ; ROM

        ld      c, (iy+1)
        ld      a, 25
        call    PrintCardSize                   ; EPROM

        ld      a, (iy+4)
        add     a, (iy+5)
        add     a, (iy+6)
        add     a, (iy+7)
        ld      c, a
        ld      a, 35
        call    PrintCardSize                   ; RAM

        pop     de
        ret

;       ----

.PrintCardSize
        push    de
        call    MoveX_A

        push    bc
        ld      bc, NQ_Out
        OZ      OS_Nq                           ; get stdout
        pop     bc

        ld      b, 0
        ld      h, b
        ld      l, c
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl                          ; *16
        ld      d, b
        ld      e, b
        ld      c, l
        ld      b, h
        ld      a, b
        or      c
        jr      nz, pcs_1
        ld      hl, asc_D74A                    ; "   -"
        OZ      GN_Sop
        jr      pcs_2

.pcs_1
        ld      hl, 2
        ld      a, $40
        OZ      GN_Pdn                          ; BC to ASCII, 4 chars
        ld      a, 'K'
        OZ      OS_Out

.pcs_2
        pop     de
        ret

.asc_D74A
        defm    "   -",0

;       ----

;       point IY to data of card A

.GetCardData
        ld      iy, mem_1fd6-12
        inc     a
        ld      bc, 12
        ld      d, 0
.gcd_1
        add     iy, bc
        inc     d
        dec     a
        jr      nz, gcd_1
        ret

.CardsWd_txt
        defm    1,"6#8",$20+0,$20+0,$20+94,$20+8
        defm    1,"2H8"
        defm    1,"2G+"
        defm    1,"7#4",$20+9,$20+0,$20+46,$20+8,$83
        defm    1,"2C4"
        defm    1,"2JC"
        defm    1,"T"
        defm    "CARDS"
        defm    1,"2JN"
        defm    1,"3@",$20+17,$20+1
        defm    "ROM"
        defm    1,"2X",$20+25
        defm    "EPROM"
        defm    1,"2X",$20+37
        defm    "RAM"
        defm    1,"3@",$20+0,$20+0
        defm    1,"R"
        defm    1,"2A",$20+46
        defm    1,"R"
        defm    1,"U"
        defm    1,"2A",$20+46
        defm    1,"U"
        defm    1,"3@",$20+0,$20+3
        defm    " CARD 1",13,10
        defm    " CARD 2",13,10
        defm    " CARD 3"
        defm    1,"3@",$20+0,$20+7
        defm    1,"2JC"
        defm    "PRESS "
        defm    1,"R"
        defm    " ESC "
        defm    1,"R"
        defm    " TO RESUME"
        defm    1,"2JN"
        defm    1,"T"
        defm    0

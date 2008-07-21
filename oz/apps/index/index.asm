; **************************************************************************************************
; Index popdown.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module Index

        include "director.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "eprom.def"
        include "integer.def"
        include "memory.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"
        include "sysvar.def"

        include "../os/lowram/lowram.def"
        include "dc.def"


xdef    Index
xdef    addHL_2xA
xdef    ldIX_DE

xref    InitProc, AddProc, GetNextProc, GetProcHandle, GetProcByHandle, GetProcEnvIDHandle
xref    PutProcHndl_IX
xref    ReadDateTime
xref    GetLinkBHL
xref    ZeroMem


; **************************************************************************************************
;
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

;       read boot.cli from File Eprom in slot or from Ram and execute it

        ld      a, OP_OUT                       ; write
        ld      hl, EpromBootCLI
        call    OpenBootCli
        jr      c, loc_C0C6                     ; couldn't create ":RAM.-/Boot.cli", ignore to copy from slot 3 File Eprom
        ld      a, EP_LOAD
        OZ      OS_Epr                          ; try to load "/Boot.cli" from File Eprom in slot 3
        push    af
        OZ      OS_Cl                           ; no matter if /Boot.cli was copied into ":RAM.-/Boot.cli", then close it...
        pop     af
        jr      nc, schedule_boot_cli
        OZ      GN_Del                          ; Delete ":RAM.-/Boot.cli" file, no /Boot.cli was found in slot 3!
        ld      hl, RamBootCLI                  ; Now, try to execute ":Ram.*//Boot.cli" instead...

.schedule_boot_cli
        ld      a, OP_IN                        ; schedule a "/Boot.cli" to be executed by CLI...
        call    OpenBootCli
        jr      c, loc_C0C6                     ; Ups, not possible (file not found)...
        ld      b, 0
        ld      h, b
        ld      l, b
        OZ      DC_Icl                          ; Invoke new CLI and use file as input...
        jr      nc, loc_C0C6
        OZ      OS_Cl                           ; CLI could not be scheduled, close file handle
        jr      loc_C0C6                        ; and continue Index initialisation

.EpromBootCLI
        defm    ":Ram.-/Boot.cli",0             ; The /Boot.cli copied from File Eprom in slot 3
.RamBootCLI
        defm    ":Ram.*//Boot.cli",0            ; The global RAM /Boot.cli filename (anywhere in any RAM)

.OpenBootCli
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
        call    prt_selinit_wd2                 ; select & init wd2
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
        call    prt_selinit_wd3                 ; select & init wd3
.klr_2
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

        ld      hl, ubIdxTopProcess
        inc     (hl)
        dec     (hl)
        jr      z, up_2                         ; do full redraw

        call    ScrollDown
        dec     (hl)
        ld      a,(hl)
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
        OZ      OS_Pout
        defm    1,$FE,0
        ld      bc, 0
        call    MoveXY_BC
        OZ      OS_Pout
        defm    1,"2C",$FD,0
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

        call    prt_scrollup
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

        call    prt_scrollup
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
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind first proc to S1
        push    bc
        call    GetLinkBHL                      ; get second process
        ld      d, b
        pop     bc
        rst     OZ_MPB                          ; restore S1
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

        ld      b,0                             ; draw application list window frame
        ld      hl,ApplWdBlock
        OZ      GN_Win

        OZ      OS_Pout
        defm    1,"T", 1,"U"
        defm    " NAME          KEY"
        defm    1,"6#2",$20+1,$20+2,$20+18,$20+6
        defm    1,"2C2"
        defm    0

        ld      hl,ProcWdBlock                  ; draw process window frame
        OZ      GN_Win

        OZ      OS_Pout
        defm    1,"T", 1,"U"
        defm    "YOUR REF.        APPLICATION  ---WHEN SUSPENDED--- CARDS"
        defm    1,"6#3",$20+21,$20+2,$20+56,$20+6
        defm    1,"2C3"
        defm    0

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

        call    prt_selinit_wd2                 ; select application window
.dwd_2
        jp      DrawHighlight

;       ----
.ApplWdBlock
        defb @10100000 | 2
        defw $0000
        defw $0812
        defw appl_banner
.appl_banner
        defm "APPLICATIONS",0

.ProcWdBlock
        defb @10100000 | 3
        defw $00014
        defw $0838
        defw proc_banner
.proc_banner
        defm "SUSPENDED ACTIVITIES",0


.DrawAppWindow
        call    prt_selinit_wd2                 ; select & init appl window
        call    prt_cls

        ld      b, 6                            ; lines to print
        ld      a, (ubIdxTopApplication)
        call    GetAppByNum
        jr      nc, appw_2                      ; got top appl
        ld      ix,0                            ; else get first application
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
        call    prt_selinit_wd3                 ; select & init proc window
        call    prt_cls
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

        OZ      OS_Pout                         ; no procs, display "NONE"
        defm    1,"3@",$20+0,$20+2
        defm    1,"2JC"
        defm    1,"T"
        defm    "NONE"
        defm    1,"T"
        defm    1,"2JN"
        defm    0
        ret

;       ----

;       get application number A

.GetAppByNum
        push    bc
        ld      b, a
        inc     b
        ld      ix,0                            ; start at first appl

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
        OZ      OS_Bout                         ; print it

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
        OZ      OS_Bout                         ; print appl name in BHL

        OZ      OS_Pout
        defm    1,"2JR",0

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
        OZ      OS_Pout
        defm    1,"*",0                         ; print []

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

        ld      ix,0                            ; no autorun
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
        OZ      OS_Pout
        defm    1,"3@",0
        ld      a, $20
        add     a, b
        OZ      OS_Out                          ; X pos
        ld      a, $20
        add     a, c
        OZ      OS_Out                          ; Y pos
        ret

;       ----

.MoveX_A
        push    af
        OZ      OS_Pout
        defm    1,"2X",0
        pop     af
        add     a, $20
        OZ      OS_Out
        ret

;       ----

.prt_tiny
        OZ      OS_Pout
        defm    1,"T",0
        ret

.prt_reverse
        OZ      OS_Pout
        defm    1,"R",0
        ret

.prt_justifyN
        OZ      OS_Pout
        defm    1,"2JN",0
        ret

.prt_cls
        OZ      OS_Pout
        defm    1,"3@",$20+0,$20+0
        defm    1,"2C",$FE,0
        ret

.prt_selinit_wd2
        OZ      OS_Pout
        defm    1,"2I2",0
        ret

.prt_selinit_wd3
        OZ      OS_Pout
        defm    1,"2I3",0
        ret

.prt_scrollup
        OZ      OS_Pout
        defm    1,$FF,0
        ret

.ApplyA
        push    af
        OZ      OS_Pout
        defm    1,"2A",0
        pop     af
        OZ      OS_Out
        ret


.cmd_card
        ld      hl, UNSAFE_START
        ld      b, 36
        call    ZeroMem
        ld      d, 3                            ; slot #
        ld      iy, UNSAFE_START+3*12

.crd_1                                          ; slot loop
        ld      bc, -12
        add     iy, bc
        ld      e, 0                            ; bank

.crd_2
        ld      bc, NQ_Slt
        OZ      OS_Nq                           ; read slot type information
        jr      c, crd_7                        ; no card?
        and     ~$40                            ; bit 5 unused by NQ_Slt
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
        bit     6, e                            ; $40, last bank reached ?
        jr      z, crd_2                        ; loop thru all banks

.crd_7
        dec     d
        jr      nz, crd_1                       ; loop thru slots 1-3

        ld      a, 2                            ; card display
        ld      (ubIdxActiveWindow),    a
        xor     a
        ld      (ubIdxSelectorPos), a
        jp      loc_C0D6

;       ----

.DrawCardWd
        ld      b,0
        ld      hl,CardWdBlock
        OZ      GN_Win

        OZ      OS_Pout
        defm    1,"3@",$20+17,$20
        defm    1,"T"
        defm    "APPS"
        defm    1,"2X",$20+26
        defm    "FILES"
        defm    1,"2X",$20+37
        defm    "RAM"
        defm    1,"3@",$20+0,$20+0
        defm    1,"U"
        defm    1,"2A",$20+46
        defm    1,"U"
        defm    1,"3@",$20+0,$20+2
        defm    " SLOT 1",13,10
        defm    " SLOT 2",13,10
        defm    " SLOT 3"
        defm    1,"3@",$20+0,$20+6
        defm    1,"2JC"
        defm    "PRESS ", 1, SD_ESC, " TO RESUME"
        defm    1,"2JN"
        defm    1,"T",1,"C"
        defm    0

        call    DisplayCards
        jp      MainLoop

.CardWdBlock
        defb @10110000 | 4
        defw $0009
        defw $082E
        defw cards_banner
.cards_banner
        defm "CARDS",0

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
        ld      b, 0
        ld      c, d
        inc     c
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
        OZ      OS_Pout
        defm    "   -",0
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

;       ----

;       point IY to data of card A

.GetCardData
        ld      iy, UNSAFE_START-12
        inc     a
        ld      bc, 12
        ld      d, b                            ; d = 0
.gcd_1
        add     iy, bc
        inc     d
        dec     a
        jr      nz, gcd_1
        ret


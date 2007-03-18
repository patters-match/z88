; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2007
;
; FlashStore is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     MODULE flash19

     ; public functionality & text constants
     xdef DispCmdWindow, DispMainWindow, DisplBar
     xdef GetCurrentSlot
     xdef format_default
     xdef rdch, pwait, YesNo
     xdef greyscr, ungreyscr
     xdef tinyfont, notinyfont, nocursor, greyfont, nogreyfont, centerjustify
     xdef rightjustify, leftjustify
     xdef sopnln, ResSpace, cls, wbar
     xdef VduEnableCentreJustify, VduEnableNormalJustify
     xdef yes_msg, no_msg, failed_msg
     xdef fetf_msg
     xdef CheckBarMode

     ; Library references
     lib CreateWindow              ; Create an OZ window (with options banner, title, etc)
     lib ToLower                   ; convert Ascii character to lower case

     ; external functionality in other modules
     xref CatalogCommand           ; catalog.asm
     xref PollFileCardWatermark    ; browse.asm
     xref ResetFilesWindow         ; browse.asm
     xref GetCursorFilePtr         ; browse.asm
     xref DispFiles                ; browse.asm
     xref InitFirstFileBar         ; browse.asm
     xref MoveFileBarDown          ; browse.asm
     xref MoveFileBarUp            ; browse.asm
     xref MoveFileBarPageUp        ; browse.asm
     xref MoveFileBarPageDown      ; browse.asm
     xref MoveToFirstFile          ; browse.asm
     xref MoveToLastFile           ; browse.asm
     xref DispFilesWindow          ; browse.asm
     xref DispBrowseHelp           ; browse.asm
     xref CopyFileAreaCommand      ; copyfiles.asm
     xref QuickCopyFileCommand     ; copyfiles.asm
     xref GetDefaultPanelRamDev    ; defaultram.asm
     xref DefaultRamCommand        ; defaultram.asm
     xref SelectFileArea           ; selectcard.asm
     xref SelectCardCommand        ; selectcard.asm
     xref PollSlots                ; selectcard.asm
     xref selslot_banner           ; selectcard.asm
     xref SelectDefaultSlot        ; selectcard.asm
     xref VduCursor                ; selectcard.asm
     xref FileEpromStatistics      ; filestat.asm
     xref ReportStdError           ; errmsg.asm
     xref Disp_reformat_msg        ; errmsg.asm
     xref disp_filefmt_ask_msg     ; errmsg.asm
     xref no_files                 ; errmsg.asm
     xref DispIntelSlotErr         ; errmsg.asm
     xref FormatCommand            ; format.asm
     xref execute_format           ; format.asm
     xref SlotWriteSupport        ; format.asm
     xref SaveFilesCommand         ; savefiles.asm
     xref fnam_msg, fsok_msg       ; savefiles.asm
     xref BackupRamCommand         ; savefiles.asm
     xref QuickFetchFile           ; fetchfile.asm
     xref FetchFileCommand         ; fetchfile.asm
     xref exct_msg                 ; fetchfile.asm
     xref RestoreFilesCommand      ; restorefiles.asm
     xref DeleteFileCommand        ; deletefile.asm
     xref QuickDeleteFile          ; deletefile.asm

     xref FlashStoreTopics         ; mth.asm
     xref FlashStoreCommands       ; mth.asm
     xref FlashStoreHelp           ; mth.asm

     include "error.def"
     include "syspar.def"
     include "director.def"
     include "stdio.def"
     include "saverst.def"
     include "memory.def"
     include "fileio.def"
     include "flashepr.def"
     include "dor.def"

     ; FlashStore variables
     include "fsapp.def"
     include "../../mth/mth-flashstore.def"

     ORG $C000


; *************************************************************************************
;
; Entry point for ugly popdown...
;
.FS_Entry
                    JP   app_main
                    SCF
                    RET
; *************************************************************************************



; *************************************************************************************
;
; FlashStore Error Handler
;
.ErrHandler
                    RET  Z
                    CP   rc_susp
                    JR   Z,dontworry
                    CP   rc_esc
                    JR   Z,akn_esc
                    CP   rc_quit
                    JR   Z,suicide
                    CP   A
                    RET
.akn_esc
                    LD   A,1                 ; acknowledge ESC detection
                    CALL_OZ os_esc
.dontworry
                    cp   a                   ; all other RC errors are returned to caller
                    RET
.suicide            xor  a
                    CALL_OZ(os_bye)          ; perform suicide, focus to Index...
.void               JR   void
; *************************************************************************************



; *************************************************************************************
;
.app_main
                    LD   A,(IX+$02)          ; IX points at information block
                    CP   $20+RAM_pages       ; get end page+1 of contiguous RAM
                    JR   NC, continue_fs     ; end page OK, RAM allocated...

                    LD   A,$07               ; No Room for FlashStore, return to Index
                    CALL_OZ(Os_Bye)          ; FlashStore suicide...
.continue_fs
                    ld   iy,status
                    res  dspdelfiles,(iy+0)  ; display only active files in file area (default)

                    ld   a, sc_ena
                    call_oz(os_esc)          ; enable ESC detection

                    xor  a
                    LD   B,A
                    ld   hl,Errhandler
                    CALL_OZ os_erh           ; then install Error Handler...

                    CALL GetDefaultPanelRamDev    ; Get the default RAM device slot number from the system Panel
                    CALL greyscr
                    LD   A,3
                    LD   (curslot),A         ; define default slot

                    CALL PollFileEproms      ; user selects a File Eprom Area in one of the ext. slots.
                    JP   C, suicide          ; no File Area available, or Flash didn't have write support in found slot
                    JP   NZ, suicide         ; user aborted

                    CALL PollFileCardWatermark ; get watermark of current slot
                    CALL InitFirstFileBar    ; initialize File Bar to first active file in File Area
                    CALL ClearWindowArea     ; just clear whole window area available

                    XOR  A
                    LD   (barMode),A         ; bar placed in menu bar by default

                    LD   A,1
                    LD   (MenuBarPosn),A     ; Display menu bar initially at top line of command window

                    CALL mainmenu
                    JR   suicide             ; main menu aborted, leave popdown...
; *************************************************************************************



; *************************************************************************************
;
.mainmenu
                    CALL DispCmdWindow
                    CALL DispFilesWindow
                    CALL CheckBarMode
                    PUSH AF
                    CALL Z,FileEpromStatistics         ; cursor in menu window: right hand side window displays File statistics
                    POP  AF
                    CALL NZ,DispBrowseHelp             ; cursor in file window: right hand side window displays Browse help

                    LD   HL, mainmenu
                    PUSH HL                            ; return address for functions...
.inp_main
                    CALL DisplBar
                    CALL rdch
                    CALL DisplBar
                    JR   NC,no_inp_err
                    CP   A
                    JR   inp_main
.no_inp_err
                    push af
                    call PollFileCardWatermark         ; same card still available in current slot?
                    call c,DispCmdWindow
                    call z,DispCmdWindow
                    call c,ResetFilesWindow            ; file area disappeared, redraw file window
                    call c,FileEpromStatistics
                    call z,ResetFilesWindow            ; file area changed, redraw file window
                    call z,FileEpromStatistics
                    pop  af

                    CP   IN_ESC
                    JP   Z, suicide
                    CP   FlashStore_CC_cf
                    JP   Z, CatalogCommand             ; Catalogue file (trad. listing of files)
                    CP   FlashStore_CC_fs              ; Save Files to File Card
                    JP   Z, SaveFilesCommand
                    CP   FlashStore_CC_fl              ; Fetch File from File Card
                    JP   Z, FetchFileCommand
                    CP   FlashStore_CC_bf              ; Backup RAM Card
                    JP   Z, BackupRamCommand
                    CP   FlashStore_CC_rf              ; Restore Files
                    JP   Z, RestoreFilesCommand
                    CP   FlashStore_CC_ffa             ; Format File Area
                    JP   Z, InitFormatCommand
                    CP   FlashStore_CC_sc              ; Select Card
                    JP   Z, SelectCardCommand
                    CP   FlashStore_CC_fe              ; File Erase
                    JP   Z, DeleteFileCommand
                    CP   FlashStore_CC_sv              ; Select RAM Device
                    JP   Z, DefaultRamCommand
                    CP   FlashStore_CC_tfv             ; Change File View
                    JP   Z, ToggleFileViewMode
                    CP   FlashStore_CC_fc              ; File Area Copy
                    JP   Z, CopyFileAreaCommand
                    CP   IN_DEL
                    JP   Z, delfile_command
                    CP   IN_ENT                        ; no shortcut cmd, ENTER ?
                    JP   Z, execute_command
                    CP   IN_DWN                        ; Cursor Down ?
                    JP   Z, MVbar_down
                    CP   IN_UP                         ; Cursor Up ?
                    JP   Z, MVbar_up
                    CP   IN_DUP                        ; <> Cursor Up ?
                    JR   Z, MVFirstFile
                    CP   IN_DDWN                       ; <> Cursor Down?
                    JR   Z, MVLastFile
                    CP   IN_SUP                        ; SHIFT Up?
                    JR   Z, MVPrev7Files
                    CP   IN_SDWN                       ; SHIFT Down?
                    JR   Z, MVNext7Files
                    CP   IN_LFT                        ; Cursor Left ?
                    JR   Z, MVbar_left
                    CP   IN_RGT                        ; Cursor Right ?
                    JR   Z, MVbar_right
                    CALL ToLower
                    CP   'd'                           ; press 'D' (alternative to DEL) to mark file as deleted
                    JP   Z, delfile_command
                    CP   'c'                           ; press 'C' to copy file entry to another file area
                    JP   Z, copyfile_command
                    CP   'f'                           ; press 'F' (alternative to ENTER) to fetch a file
                    JP   Z, execute_command
                    JP   inp_main                      ; ignore keypress, get another...
.MVbar_left
.MVbar_right
                    CALL CheckBarMode
                    JR   Z, selectFiles
                    XOR  A
                    LD   (barMode),A                   ; indicate that cursor has moved to menu window
                    CALL FileEpromStatistics           ; right hand side window displays File Card stats
                    JP   inp_main
.selectFiles
                    call GetCursorFilePtr              ; (A)BHL <-- (CursorFilePtr)
                    or   h
                    or   l
                    jp   z, inp_main                   ; no files to browse...
                    ld   a,-1
                    LD  (barMode),A                    ; indicate that cursor has moved to file window
                    call DispBrowseHelp                ; right hand side window displays Browse help
                    JP   inp_main
.MVFirstFile
                    CALL CheckBarMode
                    JP   Z,inp_main                    ; <>Up no effect in main menu
                    CALL MoveToFirstFile
                    JP   inp_main
.MVLastFile
                    CALL CheckBarMode
                    JP   Z,inp_main                    ; <>DWN no effect in main menu
                    CALL MoveToLastFile
                    JP   inp_main
.MVPrev7Files
                    CALL CheckBarMode
                    JP   Z,inp_main                    ; SHIFT UP no effect in main menu
                    CALL MoveFileBarPageUp
                    JP   inp_main
.MVNext7Files
                    CALL CheckBarMode
                    JP   Z,inp_main                    ; SHIFT DWN no effect in main menu
                    CALL MoveFileBarPageDown
                    JP   inp_main

.MVbar_down
                    CALL CheckBarMode
                    JR   NZ,MVbar_file_down
                    LD   A,(MenuBarPosn)               ; get Y position of menu bar
                    CP   7                             ; has m.bar already reached bottom?
                    JR   Z,Mbar_topwrap
                    INC  A
                    LD   (MenuBarPosn),A               ; update new m.bar position
                    JP   inp_main                      ; display new m.bar position
.Mbar_topwrap
                    LD   A,1
                    LD   (MenuBarPosn),A
                    JP   inp_main
.MVbar_file_down    CALL MoveFileBarDown
                    JP   inp_main

.MVbar_up           CALL CheckBarMode
                    JR   NZ,MVbar_file_up
                    LD   A,(MenuBarPosn)               ; get Y position of menu bar
                    CP   1                             ; has m.bar already reached top?
                    JR   Z,Mbar_botwrap
                    DEC  A
                    LD   (MenuBarPosn),A               ; update new m.bar position
                    JP   inp_main                      ; display new m.bar position
.Mbar_botwrap
                    LD   A,7
                    LD   (MenuBarPosn),A
                    JP   inp_main
.MVbar_file_up      CALL MoveFileBarUp
                    JP   inp_main

.copyfile_command   CALL CheckBarMode                  ; 'C' key pressed - copy file to another file area
                    JP   Z,inp_main                    ; command only works when cursor is in file area
                    CALL QuickCopyFileCommand
                    CALL DispFilesWindow               ; Refresh file area contents.
                    JP   inp_main

.delfile_command    CALL CheckBarMode                  ; DEL key pressed - mark file as deleted
                    JP   Z,inp_main                    ; delete file command only works when
                    CALL QuickDeleteFile               ; cursor is in file area
                    PUSH AF
                    CALL DispFilesWindow               ; Refresh file area contents.
                    POP  AF
                    JP   inp_main

.execute_command    CALL CheckBarMode                  ; cursor browsing files or at left side menu?
                    JR   NZ, selectFile

                    LD   A,(MenuBarPosn)               ; use menu bar position as index to command
                    CP   1
                    JP   Z, ToggleFileViewMode
                    CP   2
                    JP   Z, SelectCardCommand
                    CP   3
                    JP   Z, SaveFilesCommand
                    CP   4
                    JP   Z, FetchFileCommand
                    CP   5
                    JP   Z, BackupRamCommand
                    CP   6
                    JP   Z, RestoreFilesCommand
                    CP   7
                    JP   Z, DefaultRamCommand
                    JP   inp_main

.ToggleFileViewMode
                    bit  dspdelfiles,(iy+0)
                    jr   z, viewdelfiles               ; only active files are displayed, swap to all files...
                    res  dspdelfiles,(iy+0)
                    jr   refreshfileview
.viewdelfiles       set  dspdelfiles,(iy+0)
.refreshfileview
                    CALL DispFilesWindow               ; refresh file area contents at current file entry
                    JP   inp_main

.CheckBarMode
                    LD   A,(barMode)
                    OR   A
                    RET

.selectFile                                            ; a file was selected in file area window
                    CALL QuickFetchFile
                    CALL DispFilesWindow               ; refresh file area contents.
                    JP   inp_main

.InitFormatCommand
                    call GetCurrentSlot           ; C = (curslot)
                    CALL SlotWriteSupport
                    JP   C, DispIntelSlotErr
                    JP   Z, FormatCommand
                    JP   inp_main
.DisplBar
                    PUSH AF
                    CALL CheckBarMode
                    JR   NZ, DisplFileBar
.DisplMenuBar
                    LD   HL,SelectMenuWindow
                    CALL_OZ(Gn_Sop)
                    LD   A,(MenuBarPosn)               ; get Y position of menu bar
                    LD   B,A
                    LD   C,1
                    Call VduCursor
                    LD   HL,MenuBar                    ; now display menu bar at cursor
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    RET
.DisplFileBar
                    LD   HL,SelectFileWindow
                    CALL_OZ(Gn_Sop)
                    LD   A,(FileBarPosn)               ; get Y position of File Bar
                    LD   B,A
                    LD   C,0
                    Call VduCursor
                    LD   HL,FileBar
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    RET

.SelectMenuWindow   DEFM 1, "2H1", 0                   ; activate menu window for menu bar control
.SelectFileWindow   DEFM 1, "2H2", 1,"2-C", 1,"2-S", 0 ; activate file window for file bar control
.MenuBar            DEFM 1, "2+R"                      ; set reverse video
                    DEFM 1, "2E", 32+17                ; XOR 'display' menu bar (15 chars wide)
                    DEFM 1, "2-R", 0                   ; back to normal video
.FileBar            DEFM 1, "2+R"                      ; set reverse video
                    DEFM 1, "2E", 32+53                ; XOR 'display' file bar (53 chars wide)
                    DEFM 1, "2-R", 0                   ; back to normal video
; *************************************************************************************


; *************************************************************************************
;
.DispCmdWindow
                    push af
                    call dispcw
                    pop  af
                    ret
.dispcw
                    ld   a,'1' | 128
                    ld   bc,$0000
                    ld   de,$0811
                    ld   hl, cmds_banner
                    call CreateWindow

                    ld   hl, menu_msg
                    call_oz(Gn_Sop)

                    call GetCurrentSlot           ; C = (curslot)
                    call SlotWriteSupport
                    ret  nc                       ; flash supports write/erase in slot.

                    ld   hl, grey_wrercmds        ; grey out commands that has no effect in current slot
                    call_oz(Gn_Sop)
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Scan external slots and display available File Eprom's from which the
; user selects an item.
;
; If no File Eprom Area was found, then slots 1-3 are examined for a Flash
; Card to be created with a File Eprom Area (whole card or part).
; If found and user acknowledges, then selected slot will be created with a File
; Area and selected as default.
;
; A small array, <availslots> is used to store the size of each File Eprom
; with the first byte indicating the total of File Eproms available.
;
.PollFileEproms
                    call PollSlots
                    or   a
                    JP   Z, FormatCommand       ; no file areas found, investigate slots 1-3 for Flash Cards that can be formatted
.select_slot
                    cp   1
                    jr   nz, select_area
                    ld   c,-1
                    call SelectDefaultSlot
                    ld   (curslot),a
                    push af
                    pop  af
                    ret
.select_area
                    ld   hl, selslot_banner
                    jp   SelectFileArea          ; User selects a slot from a list...
; *************************************************************************************


; *************************************************************************************
; Get current slot in C
;
.GetCurrentSlot     push af
                    ld   a,(curslot)
                    ld   c,a
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
;
; IN:
;    HL = pointer to banner
.DispMainWindow
                    ld   a,'2' | 128
                    ld   bc,$0013
                    ld   de,$0835
                    jp   CreateWindow
; *************************************************************************************



; *************************************************************************************
;
; Display Window bar (below windows title) with caption text identified by HL pointer
;
.wbar
                    PUSH HL
                    LD   HL,bar1_sq
                    CALL_OZ gn_sop
                    POP  HL
                    CALL_OZ gn_sop
                    LD   HL,bar2_sq
                    CALL_OZ gn_sop
                    RET
; *************************************************************************************


; *************************************************************************************
;
.ClearWindowArea
                    LD   HL, winbackground
                    CALL_OZ(Gn_Sop)
                    RET
; *************************************************************************************



; *************************************************************************************
;
.sopnln
                    PUSH AF
                    CALL_OZ gn_sop
                    CALL_OZ gn_nln
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
;
.greyscr
                    PUSH HL
                    LD   HL,grey_msg
                    CALL_OZ gn_sop
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
;
.ungreyscr
                    PUSH HL
                    LD   HL,ungrey_msg
                    CALL_OZ gn_sop
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
;
.cls
                    PUSH AF
                    LD   HL, clsvdu
                    CALL_OZ Gn_Sop
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
;
.rdch
                    CALL_OZ os_in
                    JR   NC,rd2
                    CP   RC_ESC
                    JR   Z, ret_esc
                    SCF
                    RET
.ret_esc
                    LD   A, IN_ESC
                    RET
.rd2
                    CP   0
                    RET  NZ
                    CALL_OZ os_in
                    RET
; *************************************************************************************


; *************************************************************************************
;
.pwait
                    LD   A,sr_pwt
                    CALL_OZ os_sr
                    JR   NC,pw2
                    CP   rc_susp
                    JR   Z,pwait
                    SCF
                    RET
.pw2
                    CP   0
                    RET  NZ
                    CALL_OZ OS_In
                    RET
; *************************************************************************************


; *************************************************************************************
;
.yesno
                    LD   BC, yesno_loop
                    PUSH BC
                    JP   (HL)                ; call display message
.yesno_loop         LD   H,D
                    LD   L,E
                    CALL_OZ gn_sop
                    CALL_OZ(OS_Pur)          ; make sure no keys in sys. inp. buffer...
                    CALL rdch
                    JR   C,yesno_loop        ; ignore pre-emption...
                    CP   IN_ESC
                    JR   Z, abort_yesno
                    CP   13
                    JR   NZ,yn1
                    LD   HL,yes_msg
                    SBC  HL,DE               ; Yes, Fc = 0, Fz = 1
                    RET  Z
                    OR   A                   ; No, Fc = 0, Fz = 0
                    RET
.abort_yesno
                    OR   A                   ; ESC pressed
                    RET                      ; return Fc = 0, Fz = 0
.yn1
                    OR   32
                    CP   'y'
                    JR   NZ,yn2
                    LD   DE,yes_msg
                    JR   yesno_loop
.yn2                                          ; all other keypressed means 'No'...
                    LD   DE,no_msg
                    JR   yesno_loop
; *************************************************************************************


; *************************************************************************************
; User is prompted with "Press SPACE to Resume". The keyboard is then scanned
; for the SPACE or as alternative the ESC key. The routine returns when the user
; has pressed SPACE, ENTER or ESC.
;
; Registers changed after return:
;    AF changed, IN_ESC or IN_SPACE keys returned.
;
.ResSpace
                    PUSH HL
                    LD   HL,ResSpace_msg
                    CALL_OZ gn_sop
.escin
                    CALL rdch
                    JR   C,escin
                    CP   IN_ESC
                    JR   Z, exit_resSpace
                    CP   IN_ENT
                    JR   Z, exit_resSpace
                    CP   32
                    JR   NZ,escin
.exit_resSpace
                    POP  HL
                    CP   A                   ; Fc = 0
                    RET
; *************************************************************************************


; *************************************************************************************
.VduEnableCentreJustify
                    PUSH HL
                    LD   HL, centerjustify
                    CALL_OZ GN_Sop           ; enable centre justify VDU
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.VduEnableNormalJustify
                    PUSH HL
                    LD   HL, leftjustify
                    CALL_OZ GN_Sop           ; enable centre justify VDU
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
; Text & VDU constants.
;

.cmds_banner        DEFM "COMMANDS",0
.menu_msg
                    DEFM 1, "2H1"
                    DEFM 1, "2-G", 1, "2+T"
                    DEFM 1,"3@",32+1,32+0, "TOGGLE FILE VIEW"
                    DEFM 1,"3@",32+1,32+1, "SELECT CARD"
                    DEFM 1,"3@",32,32+2, " SAVE TO CARD    "
                    DEFM 1,"3@",32+1,32+3, "FETCH FROM CARD"
                    DEFM 1,"3@",32,32+4, " BACKUP FROM RAM "
                    DEFM 1,"3@",32+1,32+5, "RESTORE TO RAM"
                    DEFM 1,"3@",32+1,32+6, "DEFAULT RAM"
                    DEFM 1,"2-C"
                    DEFB 0

.grey_wrercmds      DEFM 1, "2H1"
                    DEFM 1, "2+G"
                    DEFM 1, "3@", 32+0, 32+2, 1, "2E", 32+17
                    DEFM 1, "3@", 32+0, 32+4, 1, "2E", 32+17
                    DEFM 1, "2-G", 0

.grey_msg           DEFM 1,"6#8  ",$7E,$28,1,"2H8",1,"2G+",0
.ungrey_msg         DEFM 1,"6#8  ",$7E,$28,1,"2H8",1,"2G-",0
.clsvdu             DEFM 1,"2C2", 1, 'S', 12,0
.winbackground      DEFM 1,"7#1",32,32,32+94,32+8,128
                    DEFM 1,"2C1",0

.bar1_sq            DEFM 1,"4+TUR",1,"2JC",1,"3@  ",0
.bar2_sq            DEFM 1,"3@  ",1,"2A",85,1,"4-TUR",1,"2JN",0

.failed_msg         DEFM "Last file failed.",0

.yes_msg            DEFM 13,1,"2+C Yes",8,8,8,0
.no_msg             DEFM 13,1,"2+C No ",8,8,8,0

.ResSpace_msg       DEFM 1,"2H2", 1,"2JC",1,"3+FTPRESS ",1,SD_SPC," OR ", 1,SD_ENT," TO RESUME",1,"4-FTC",1,"2JN",$0D,$0A,0

.nocursor           defm 1,"3-SC",0         ; no vertical scrolling & no blinking cursor in window
.greyfont           defm 1, "2+G", 0
.nogreyfont         defm 1, "2-G", 0
.notinyfont         defm 1, "2-T", 0
.tinyfont           defm 1, "2+T",0

.centerjustify      DEFM 1, "2JC", 0
.leftjustify        DEFM 1, "2JN", 0
.rightjustify       DEFM 1, "2JR", 0

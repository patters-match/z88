; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2004
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

     MODULE flash17

     ; public functionality & text constants
     xdef DispCmdWindow, DispCtlgWindow
     xdef format_default
     xdef rdch, pwait, YesNo
     xdef greyscr, ungreyscr
     xdef tinyfont, notinyfont, nocursor, greyfont, nogreyfont, centerjustify
     xdef rightjustify, leftjustify
     xdef sopnln, ResSpace, cls, wbar
     xdef VduEnableCentreJustify, VduEnableNormalJustify
     xdef done_msg, yes_msg, no_msg, failed_msg
     xdef fetf_msg
     xdef disp_exis_msg

     ; Library references
     lib CreateWindow              ; Create windows...

     ; external functionality in other modules
     xref SelectFileArea           ; selectcard.asm
     xref SelectCardCommand        ; selectcard.asm
     xref PollFileEproms           ; selectcard.asm
     xref FilesAvailable           ; catalog.asm
     xref VduCursor                ; selectcard.asm
     xref FileEpromStatistics      ; filestat.asm
     xref IntAscii                 ; filestat.asm
     xref DispErrMsg               ; errmsg.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref DispIntelSlotErr         ; errmsg.asm
     xref ReportStdError           ; errmsg.asm
     xref NoAppFileAreaMsg         ; errmsg.asm
     xref disp_empty_flcard_msg    ; errmsg.asm
     xref Disp_reformat_msg        ; errmsg.asm
     xref disp_filefmt_ask_msg     ; errmsg.asm
     xref no_files                 ; errmsg.asm
     xref FormatCommand            ; format.asm
     xref SaveFilesCommand         ; savefiles.asm
     xref FetchFileCommand         ; fetchfile.asm
     xref exct_msg                 ; fetchfile.asm
     xref execute_format           ; format.asm
     xref FlashWriteSupport        ; format.asm
     xref CatalogCommand           ; catalog.asm
     xref RestoreFilesCommand      ; restorefiles.asm
     xref PromptOverWrFile         ; restorefiles.asm
     xref fnam_msg, fsok_msg       ; savefiles.asm
     xref DeleteFileCommand        ; deletefile.asm

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

     include "fsapp.def"

     ORG $C000

; *************************************************************************************
;
; The Application DOR:
;
.FS_Dor
                    DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0        ; total length of DOR
.DORStart0          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd0-InfoStart0      ; length of info section
.InfoStart0         DEFW 0                        ; reserved...
                    DEFB 'J'                      ; application key letter
                    DEFB RAM_pages                ; I/O buffer for FlashStore
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW SafeWorkSpaceSize        ; Safe workspace
                    DEFW FS_Entry                 ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB $3F                      ; bank binding to segment 3
                    DEFB AT_Ugly | AT_Popd        ; Ugly popdown
                    DEFB 0                        ; no caps lock on activation
.InfoEnd0           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFW FlashStoreTopics
                    DEFB $3F                      ; point to topics (none)
                    DEFW FlashStoreCommands
                    DEFB $3F                      ; point to commands (none)
                    DEFW FlashStoreHelp
                    DEFB $3F                      ; point to help (none)
                    DEFW FS_Dor
                    DEFB $3F                      ; point to token base (none)
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd0-NameStart0      ; length of name
.NameStart0         DEFM "FlashStore",0
.NameEnd0           DEFB $FF
.DOREnd0

; *************************************************************************************


; *************************************************************************************
;
; We are somewhere in segment 3...
;
; Entry point for ugly popdown...
;
.FS_Entry
                    JP   app_main
                    SCF                           ; all RAM returned on popdown suicicide
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
                    JR   Z, continue_fs      ; end page OK, RAM allocated...

                    LD   A,$07               ; No Room for FlashStore, return to Index
                    CALL_OZ(Os_Bye)          ; FlashStore suicide...
.continue_fs
                    ld   a, sc_ena
                    call_oz(os_esc)          ; enable ESC detection

                    xor  a
                    LD   B,A
                    ld   hl,Errhandler
                    CALL_OZ os_erh           ; then install Error Handler...

                    CALL PollFileEproms      ; user selects a File Eprom Area in one of the ext. slots.
                    JP   C, suicide          ; no File Area available, or Flash didn't have write support in found slot
                    JP   NZ, suicide         ; user aborted

                    CALL ClearWindowArea     ; just clear whole window area available
                    CALL mainmenu
                    JP   suicide             ; main menu aborted, leave popdown...
; *************************************************************************************



; *************************************************************************************
;
.mainmenu
                    CALL DispCmdWindow
                    CALL DispCtlgWindow
                    CALL FileEpromStatistics      ; parse for free space and total of files...

                    LD   HL, mainmenu
                    PUSH HL                       ; return address for functions...
.inp_main
                    CALL rdch
                    JR   NC,no_inp_err
                    CP   A
                    JR   inp_main
.no_inp_err
                    CP   IN_ESC
                    JP   Z, suicide
                    OR   $20
                    CP   's'
                    JP   Z, SaveFilesCommand
                    CP   'f'
                    JP   Z, FetchFileCommand
                    CP   'r'
                    JP   Z, RestoreFilesCommand
                    CP   'c'
                    JP   Z, CatalogCommand
                    CP   '!'
                    JP   Z, FormatCommand
                    CP   'v'
                    JP   Z, SelectCardCommand
                    CP   'd'
                    JP   Z, DeleteFileCommand
                    JR   inp_main
; *************************************************************************************



; *************************************************************************************
;
.DispCmdWindow
                    ld   a,'1' | 128
                    ld   bc,$0000
                    ld   de,$080D
                    ld   hl, cmds_banner
                    call CreateWindow

                    ld   hl, menu_msg
                    call_oz(Gn_Sop)

                    ld   a,(curslot)
                    ld   c,a
                    call FlashWriteSupport
                    ret  nc                       ; flash supports write/erase in slot.

                    ld   hl, grey_wrercmds        ; grey out commands that has no effect in current slot
                    call_oz(Gn_Sop)
                    ret
; *************************************************************************************


; *************************************************************************************
;
.DispCtlgWindow
                    push af
                    push bc
                    push de
                    push hl

                    ld   a,'2' | 128
                    ld   bc,$000F
                    ld   de,$0837
                    ld   hl, catalog_banner
                    call CreateWindow

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret
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
                    PUSH HL
                    CALL_OZ gn_sop
                    CALL_OZ gn_nln
                    POP  HL
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
                    PUSH HL

                    LD   HL, clsvdu
                    CALL_OZ Gn_Sop

                    POP  HL
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
                    CALL_OZ os_in
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
                    RET  C
                    CP   IN_ESC
                    JR   Z, abort_yesno
                    CP   13
                    JR   NZ,yn1
                    LD   A,E
                    CP   yes_msg % 256        ; Yes, Fc = 0, Fz = 1
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
;
; User is prompted with "Press SPACE to Resume". The keyboard is then scanned
; for the SPACE key.
;
; The routine returns when the user has pressed ESC.
;
; Registers changed after return:
;    None.
;
.ResSpace
                    PUSH AF
                    PUSH HL
                    LD   HL,ResSpace_msg
                    CALL_OZ gn_sop
.escin
                    CALL rdch
                    JR   C,escin
                    CP   32
                    JR   NZ,escin
                    POP  HL
                    POP  AF
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
.catalog_banner     DEFM "FLASHSTORE V1.7.rc2, (C) 1997-2004 Zlab & InterLogic",0

.cmds_banner        DEFM "Commands",0
.menu_msg
                    DEFM 1, "2-G", 1,"3@",32,32
                    DEFM 1,"B C",1,"Batalogue",$0D,$0A
                    DEFM 1,"B S",1,"Bave file",$0D,$0A
                    DEFM 1,"B F",1,"Betch file",$0D,$0A
                    DEFM 1,"B R",1,"Bestore",$0D,$0A
                    DEFM " De", 1,"BV",1,"Bice",$0D,$0A
                    DEFM 1,"B D",1,"Belete file",$0D,$0A
                    DEFM 1,"B ! ",1,"BFormat"
                    DEFM 1,"2-C"
                    defb 0

.grey_wrercmds      DEFM 1, "2+G"
                    DEFM 1, "3@", 32, 32+1, 1, "2E", 32+12
                    DEFM 1, "3@", 32, 32+5, 1, "2E", 32+12
                    DEFM 1, "3@", 32, 32+6, 1, "2E", 32+12
                    DEFM 1, "2-G", 0

.grey_msg           DEFM 1,"6#8  ",$7E,$28,1,"2H8",1,"2G+",0
.ungrey_msg         DEFM 1,"6#8  ",$7E,$28,1,"2H8",1,"2G-",0
.clsvdu             DEFM 1,"2H2",12,0
.winbackground      DEFM 1,"7#1",32,32,32+94,32+8,128
                    DEFM 1,"2C1",0

.bar1_sq            DEFM 1,"4+TUR",1,"2JC",1,"3@  ",0
.bar2_sq            DEFM 1,"3@  ",1,"2A",87,1,"4-TUR",1,"2JN",0

.failed_msg         DEFM "Failed.",0

.yes_msg            DEFM 13,1,"2+C Yes",8,8,8,0
.no_msg             DEFM 13,1,"2+C No ",8,8,8,0

.ResSpace_msg       DEFM 1,"2H2", 1,"2JC",1,"3+FTPRESS ",1,SD_SPC," TO RESUME",1,"4-FTC",1,"2JN",$0D,$0A,0

.nocursor           defm 1,"3-SC",0         ; no vertical scrolling & no blinking cursor in window
.greyfont           defm 1, "2+G", 0
.nogreyfont         defm 1, "2-G", 0
.notinyfont         defm 1, "2-T", 0
.tinyfont           defm 1, "2+T",0

.centerjustify      DEFM 1, "2JC", 0
.leftjustify        DEFM 1, "2JN", 0
.rightjustify       DEFM 1, "2JR", 0

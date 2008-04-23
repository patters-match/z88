; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2007
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     Module Messages

; This module contains functionality to display various prompts, info and error messages by RomUpdate

     ; system definitions
     include "stdio.def"
     include "integer.def"
     include "syspar.def"
     include "error.def"
     include "time.def"

     ; RomUpdate runtime variables
     include "romupdate.def"

     xdef SopNln
     xdef bbcbas_progversion, progversion_banner
     xdef MsgUpdateCompleted, MsgAddCompleted, MsgAddBankFile, MsgUpdOzRom
     xdef ReportStdError, DispErrMsg, MsgOZUpdated
     xdef ErrMsgNoFlash, ErrMsgIntelFlash, ErrMsgAppDorNotFound, ErrMsgActiveApps
     xdef ErrMsgBankFile, ErrMsgCrcFailBankFile, ErrMsgPresvBanks, ErrMsgCrcCheckPresvBanks
     xdef ErrMsgSectorErase, ErrMsgBlowBank, ErrMsgNoRoom, ErrMsgNoCfgfile, ErrMsgCfgSyntax
     xdef ErrMsgNoFlashSupport, ErrMsgNewBankNotEmpty, ErrMsgReduceFileArea, ErrMsgOzRom
     xdef MsgCrcCheckBankFile, MsgUpdateBankFile
     xdef hrdreset_msg, removecrd_msg

     xref suicide, GetSlotNo, GetSectorNo



; *************************************************************************************
; Display "<AppName> was successfully updated in slot X",
; prompt for key press, then exit program by KILL request.
;
.MsgUpdateCompleted
                    call compl_init
                    ld   hl,updated_msg                 ; "updated"
                    oz   GN_Sop
                    ld   hl,inslot_msg                  ; " in slot "
                    oz   GN_Sop
                    call DispSlotNo
                    call VduEnableNormalJustify
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
.compl_init
                    ld   a,12
                    oz   OS_Out                         ; clear window...
                    oz   GN_Nln
                    call VduEnableCentreJustify
                    call DispAppName
                    ld   hl,completed_msg               ; " was successfully "
                    oz   GN_Sop
                    ret
; *************************************************************************************


; *************************************************************************************
; Display "<AppName> was successfully updated in slot X",
; prompt for key press, then exit program by KILL request.
;
.MsgOZUpdated
                    call VduEnableCentreJustify
                    ld   hl,removecrd_msg               ; "Insert flash Card with OZ in slot 1 and hard reset Z88."
                    oz   GN_Sop
                    oz   GN_nln
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; Display "<AppName> was successfully updated in slot X",
; prompt for key press, then exit program by KILL request.
;
.MsgAddCompleted
                    call compl_init
                    ld   hl,added_msg                   ; "added"
                    oz   GN_Sop
                    ld   hl,toslot_msg                  ; " to slot "
                    oz   GN_Sop
                    call DispSlotNo
                    call VduEnableNormalJustify
                    ld   hl, disp_reset_msg
                    ld   de, yes_msg
                    call YesNo
                    jp   z, 0                           ; User selected to perform a soft reset
                    call VduEnableCentreJustify
                    ld   hl, reset2_msg
                    call SopNln
                    ld   bc, 500                        ; wait 5 seconds
                    call_oz OS_Dly                      ; then
                    jp   suicide                        ; exit RomUpdate and let user re-insert card to install..
; *************************************************************************************


; *************************************************************************************
.disp_reset_msg
                    PUSH HL
                    LD   HL, resetprompt_msg
                    CALL SopNln
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
; Program Progress message "CRC Checking <BankFile> bank file."
;
.MsgCrcCheckBankFile
                    push hl
                    ld   hl,crcbankfile1_msg
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl,bankfilename
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl,crcbankfile2_msg
                    call SopNln
                    pop  hl
                    ret
; *************************************************************************************


; *************************************************************************************
; Display message about the bank (file) that contains the updated application code.
;
.MsgUpdateBankFile
                    push bc
                    push hl
                    ld   hl,updbnkfile1_msg
                    oz   GN_Sop
                    call DispAppName
                    ld   hl,updbnkfile2_msg
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl,bankfilename
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl,updbnkfile3_msg
                    oz   GN_Sop
                    ld   hl,inslot_msg
                    oz   GN_Sop
                    call DispSlotNo
                    ld   hl,flash_off
                    oz   GN_Sop
                    pop  hl
                    pop  bc
                    ret
.flash_off          defm 1,"2-F",0
; *************************************************************************************


; *************************************************************************************
; Display message about the bank (file) that will be added to a particular slot.
;
.MsgAddBankFile
                    push bc
                    push de
                    push hl
                    ld   hl,addbnkfile1_msg
                    oz   GN_Sop
                    call DispAppName
                    ld   hl,updbnkfile2_msg
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl,bankfilename
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl,updbnkfile3_msg
                    oz   GN_Sop
                    ld   hl,toslot_msg
                    oz   GN_Sop
                    call DispSlotNo
                    ld   hl,flash_off
                    oz   GN_Sop
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; The RomUpdate config file was not found, display an error message and exit.
;
.ErrMsgNoCfgFile
                    ld   hl,nocfgfile_msg
                    jp   DispErrMsg
; *************************************************************************************


; *************************************************************************************
; 'OZ ROM could not be installed. No Flash chip was recognised in slot X'
; slot number is supplied in BC register.
;
.ErrMsgOzRom
                    ld   hl,noflashforoz_msg
                    oz   GN_Sop
                    ld   hl,inslot_msg                  ; "in slot "
                    oz   GN_Sop
                    ld   a,(oz_slot)
                    ld   b,0
                    ld   c,a
                    call DispNumber
                    oz   GN_nln
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; 'Updating OZ ROM in slot X - please wait'
;
.MsgUpdOzRom
                    ld   hl,updoz1_msg
                    oz   GN_Sop
                    ld   hl,inslot_msg                  ; "in slot "
                    oz   GN_Sop
                    ld   a,(oz_slot)
                    ld   b,0
                    ld   c,a
                    call DispNumber

                    ld   hl,updoz2_msg
                    oz   GN_Sop
                    ret


; *************************************************************************************
.ErrMsgActiveApps
                    ld   hl,actvapps_msg
                    jp   DispErrMsg
; *************************************************************************************


; *************************************************************************************
; '<AppName> was not found in any slot.'
;
; IN:
;    (appname) = local pointer to null-terminated application name (from DOR)
;
.ErrMsgAppDorNotFound
                    push af
                    call DispAppName
                    ld   hl,noapp_found_msg             ; "<appname> was not found in any slot."
                    call SopNln
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; A syntax error was encountered in the configuration file
;
.ErrMsgCfgSyntax
                    ld   hl,cfgsyntax1_msg
                    oz   GN_Sop
                    ld   bc,(cfgfilelineno)
                    call DispNumber
                    ld   hl,cfgsyntax2_msg              ; "Syntax error at line X in 'romupdate.cfg' file."
                    call Sopnln
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; Display an error message to the user that there wasn't room enough for preserving
; the passive banks in the RAM filing system. The user is informed how much RAM
; is needed before RomUpdate can preserve the banks.
;
; IN:
;    DE = total pages needed to preserve banks to RAM
;    HL = total pages of free RAM in Z88.
;
.ErrMsgNoRoom
                    oz   GN_nln
                    push hl
                    ld   hl,ram_noroom1_msg
                    oz   GN_Sop
                    push de
                    pop  hl
                    call DispK                          ; total K needed to preserve banks
                    ld   hl,ram_noroom2_msg
                    oz   GN_Sop
                    pop  hl
                    push hl
                    call DispK                          ; total K needed to preserve banks
                    ld   hl,ram_noroom3_msg
                    oz   GN_Sop
                    pop  hl
                    ex   de,hl
                    sbc  hl,de                          ; <Pages needed> - <free space> = more room
                    call DispK                          ; RAM space (in K) to be freed to give more room
                    ld   hl,ram_noroom4_msg
                    call Sopnln
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
.DispK
                    srl  h
                    rr   l
                    srl  h
                    rr   l                              ; pages/4 = K
                    ld   a,l
                    or   a
                    jr   nz,dspnm
                    inc  a                              ; round up to minimum 1K, if num was < 1K..
.dspnm
                    ld   b,0
                    ld   c,a
                    jp   DispNumber
; *************************************************************************************


; *************************************************************************************
; This error message is being displayed when the found application was
; available on an Intel Flash, but not in slot 3 (cannot be updated).
;
; The user presses a key (after having moved Intel card to slot 3)
; and the slots will be scanned again...
;
.ErrMsgIntelFlash
                    ld   hl,wrongslot_msg               ; "Intel Flash Card can only be updated in slot 3"
                    jp   DispErrMsg
; *************************************************************************************


; *************************************************************************************
; Display error message when CRC check failed for Bank file and exit application.
;
.ErrMsgCrcFailBankFile
                    ld   hl,crcerr_bfile1
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl,bankfilename
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    oz   GN_nln
                    ld   hl,crcerr_bfile2
                    oz   GN_Sop
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; Display error message when specific bank memory in flash card seems to be used
; (should just contain FF's). This situation might occur when trying to add new
; application bank below current application area and a 'dirty' file area has been
; stored using RomCombiner.
;
.ErrMsgNewBankNotEmpty
                    call DispAppName
                    ld   hl,banknotempty1_msg           ; "<AppName> cannot be added to applications"
                    ld   hl,inslot_msg
                    oz   GN_Sop
                    call DispSlotNo
                    ld   hl,banknotempty2_msg           ; "Bank below application area is not empty."
                    jp   disp_error_msg
; *************************************************************************************


; *************************************************************************************
; Display error message when CRC check failed for passive Bank files and exit application.
;
.ErrMsgCrcCheckPresvBanks
                    ld   hl,crcerr_bfile1               ; "CRC check failed for "
                    oz   GN_Sop
                    ld   hl,crcerr_psvbnk_msg           ; "(temporary) passive bank files, possibly "
                    oz   GN_Sop
                    ld   hl,crcerr_bfile3               ; "because of corrupted RAM Filing System."
                    jr   disp_error_msg
; *************************************************************************************


; *************************************************************************************
; An error occurred while preserving a passive bank from a sector, possibly a RC_ROOM
; (no more file space), RC_USE (file already in use) or other I/O error.
;
; Display a meaningful error message to the user and exit RomUpdate.
;
; IN:
;    A = RC_xxx error code
;
.ErrMsgPresvBanks
                    ld   a,12
                    oz   OS_Out                         ; clear window...
                    call VduToggleBoldTypeface
                    ld   hl,filename
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl, notcreated_msg
                    cp   RC_USE                         ; file couldn't be created (in use)
                    jp   z,disp_error_msg
                    ld   hl, file_noroom_msg
                    cp   RC_ROOM                        ; no room for temp. bank files.
                    jp   z,disp_error_msg
                    ld   hl, io_error_msg               ; all other errors defined as I/O error
                    jr   disp_error_msg
; *************************************************************************************


; *************************************************************************************
; The filename as specified in the 'romupdate.cfg' file couldn't be found or a
; file I/O error occurred (possibly file corruption). Display file I/O error message.
;
; IN:
;    A = RC_xxx error code
;
.ErrMsgBankFile
                    call VduToggleBoldTypeface
                    ld   hl,bankfilename
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ld   hl, notfound_msg               ; default 'not found' error message
                    cp   RC_ONF
                    jp   z,disp_error_msg
                    ld   hl, io_error_msg
.disp_error_msg
                    call SopNln                         ; display string followed by CRLF
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; Display an error message when sector failed being erased, and exit RomUpdate application.
;
.ErrMsgSectorErase
                    ld   hl,fatal_err_msg
                    oz   GN_Sop
                    ld   hl,erasect_err_msg
                    oz   GN_Sop
                    ld   hl,flash_err_msg
                    jr   disp_error_msg
; *************************************************************************************


; *************************************************************************************
; Display an error message when updated application bank chip programming
; (of passive banks) fails on Flash Card.
;
; IN:
;    HL = pointer to filename
;
.ErrMsgBlowBank
                    push hl
                    ld   hl,fatal_err_msg
                    oz   GN_Sop
                    ld   hl,updbnk1_err_msg
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    pop  hl
                    oz   GN_Sop                         ; display filename (or other bank type)
                    call VduToggleBoldTypeface
                    ld   hl,updbnk2_err_msg
                    oz   GN_Sop
                    call DispSectorNo
                    ld   hl,flash_err_msg
                    jr   disp_error_msg
; *************************************************************************************


; *************************************************************************************
; Display error message when a fatal error occurred during shrinking of file area.
;
.ErrMsgReduceFileArea
                    ld   hl,fatal_err_msg
                    oz   GN_Sop
                    ld   hl,reduce_fa1_msg
                    oz   GN_Sop
                    ld   hl, inslot_msg
                    oz   GN_Sop
                    ld   a,(dorbank)
                    call GetSlotNo
                    ld   b,0                            ; bc = slot number
                    call DispNumber
                    ld   hl,reduce_fa2_msg
                    oz   GN_Sop
                    ld   hl,flash_err_msg
                    jr   disp_error_msg
; *************************************************************************************


; *************************************************************************************
; This error message is being displayed when the found application in a slot was
; available on an UV Eprom.
;
.ErrMsgNoFlash
                    ld   hl,noflashcard_msg             ; "No Flash Card found"
                    oz   GN_Sop
                    ld   hl,inslot_msg                  ; "in slot "
                    oz   GN_Sop
                    call DispSlotNo
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; This error message is being displayed when the found application in a slot was
; available on an UV Eprom.
;
.ErrMsgNoFlashSupport
                    ld   hl,noflashcard_msg             ; "No Flash Card found"
                    oz   GN_Sop
                    ld   hl,noflsupp_msg                ; ", or card not updateable in found slots."
                    call SopNln
                    call DispAppName
                    ld   hl, noadd_msg                  ; "<AppName> cannot be added to card."
                    call SopNln
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; Display DOR application name in bold typeface.
; Pointer to application is found in (appname) runtime variable.
;
.DispAppName
                    call VduToggleBoldTypeface
                    ld   hl, (appname)
                    oz   GN_Sop
                    call VduToggleBoldTypeface
                    ret
; *************************************************************************************


; *************************************************************************************
; Display slot number, derived from [dorbank] runtime variable.
;
.DispSlotNo
                    push bc
                    ld   b,0
                    ld   a,(dorbank)
                    call GetSlotNo
                    call DispNumber
                    ld   a,'.'
                    oz   OS_Out
                    oz   GN_nln
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Display sector number, derived from [dorbank] runtime variable.
;
.DispSectorNo
                    ld   a,(dorbank)
                    ld   b,0
                    call GetSectorNo                    ; derive sector number from bank no. in A
                    ld   c,a
                    call DispNumber
                    ld   a,'.'
                    oz   OS_Out
                    oz   GN_nln
                    ret
; *************************************************************************************


; *************************************************************************************
; Display Integer as Ascii
;
; IN:
;    BC = number to be displayed at current window position
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.DispNumber
                    push bc
                    push de
                    push hl
                    push ix

                    push bc
                    ld   bc, NQ_Shn
                    oz   OS_Nq                          ; get screen handle in IX
                    pop  bc

                    xor  a
                    ld   d,a
                    ld   e,a                            ; result to stream IX (screen)
                    ld   h,a
                    ld   l,2                            ; integer in BC to be converted to Ascii
                    ld   a,1                            ; no leading spaces
                    oz   GN_Pdn                         ; output result to current window...

                    pop  ix
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Write Error message in HL, and wait for SPACE key to be pressed,
; then exit RomUpdate application
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.DispErrMsg
                    oz   GN_Nln
                    push hl
                    call VduEnableCentreJustify
                    pop  hl
                    call SopNln
                    call VduEnableNormalJustify
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
.VduEnableCentreJustify
                    ld   hl, centerjustify
                    oz   GN_Sop                         ; enable centre justify VDU
                    ret
; *************************************************************************************


; *************************************************************************************
.VduEnableNormalJustify
                    ld   hl, leftjustify
                    oz   GN_Sop                         ; enable centre justify VDU
                    ret
; *************************************************************************************


; *************************************************************************************
.VduToggleBoldTypeface
                    ld   hl, vdubold
                    oz   GN_Sop
                    ret
; *************************************************************************************


; *************************************************************************************
.SopNln
                    oz   GN_Sop
                    oz   GN_Nln
                    ret
; *************************************************************************************


; *************************************************************************************
; User is prompted with "Press any key to exit RomUpdate".
;
.ResKey
                    push hl
                    ld   hl,ResKey_msg
                    oz   GN_sop
.escin
                    call rdch
                    jr   c,escin
                    pop  hl
                    ret
; *************************************************************************************


; *************************************************************************************
; Wait for a key press
;
.rdch
                    oz   OS_Pur
                    oz   OS_In
                    jr   nc,rd2
                    cp   RC_ESC
                    jr   z, ret_esc
                    scf
                    ret
.ret_esc
                    ld   a, IN_ESC
                    ret
.rd2
                    cp   0
                    ret  nz
                    oz   OS_In
                    ret
; *************************************************************************************


; *************************************************************************************
; Yes/No selection
; IN:
;       HL = pointer to message string display routine
;       DE = pointer to default selection: yes_msg or no_msg
; OUT;
;       Fc = 0, Fz = 1, Yes selected
;       Fc = 0, Fz = 0, No selected
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
; constants
.bbcbas_progversion defm 12                   ; clear window before displaying program version (BBC BASIC only)
.progversion_banner defm 1, "BRomUpdate V0.8.2 beta", 1,"B", 0

.centerjustify      defm 1, "2JC", 0
.leftjustify        defm 1, "2JN", 0
.vdubold            defm 1,"B",0

.ResKey_msg         defm $0D,$0A,1,"2JC",1,"3+FTPRESS ANY KEY TO EXIT ROMUPDATE",1,"4-FTC",1,"2JN",0
.inslot_msg         defm " in slot ",0
.toslot_msg         defm " to slot ",0
.completed_msg      defm " was successfully ",0
.updated_msg        defm "updated", 0
.added_msg          defm "added", 0
.nocfgfile_msg      defm '"',"romupdate.cfg", '"', " file was not found.",0
.cfgsyntax1_msg     defm "Syntax error at line ",0
.cfgsyntax2_msg     defm " in 'romupdate.cfg' file.",0
.noflashcard_msg    defm "No Flash Card found",0
.noflashforoz_msg   defm "OZ ROM cannot be updated. Flash device was not found",0
.noflsupp_msg       defm  ", or card not updateable in found slots.", 0
.noadd_msg          defm " cannot be added to card.",0
.noapp_found_msg    defm " was not found in any slot.",0
.actvapps_msg       defm 1,"+KILL running applications in external slots before running RomUpdate.",0
.wrongslot_msg      defm "Intel Flash Card can only be updated in slot 3.", $0D, $0A
                    defm "Insert Application Card in slot 3, and run RomUpdate again.", 0
.notfound_msg       defm " bank file (to be updated on card) was not found.",0
.io_error_msg       defm " bank file was not properly loaded (possibly corrupted).",0
.notcreated_msg     defm " (temporary) file could not be created (already in use or I/O error).",0
.file_noroom_msg    defm " (temporary) file creation was rejected. File system space exhausted.", 0
.crcbankfile1_msg   defm "CRC Checking ",0
.crcbankfile2_msg   defm " bank file.",0
.crcerr_bfile1      defm 12,"CRC check failed for ", 0
.crcerr_bfile2      defm "Bank file was possibly damaged by serial port transfer or", $0D, $0A
.crcerr_bfile3      defm "because of corrupted RAM Filing System!",0
.crcerr_psvbnk_msg  defm "(temporary) passive bank files, possibly ", $0D, $0A, 0
.fatal_err_msg      defm 12,"Fatal Error: ",0
.erasect_err_msg    defm "Sector could not be formatted", $0D, $0A, 0
.flash_err_msg      defm "(Battery low condition or slot connector card problem).", 0
.addbnkfile1_msg    defm 1,"FAdding ",0
.updbnkfile1_msg    defm 1,"FUpdating new version of ", 0
.updbnkfile2_msg    defm " (from ", 0
.updbnkfile3_msg    defm " file)", 0
.updbnk1_err_msg    defm "Bank (", 0
.updbnk2_err_msg    defm ") failed to be written to sector no. ", 0
.banknotempty1_msg  defm " cannot be added to applications", 0
.banknotempty2_msg  defm "Bank below application area is not empty.", 0
.reduce_fa1_msg     defm "Couldn't shrink file area", 0
.reduce_fa2_msg     defm " to make room for new application.", $0D, $0A, 0
.ram_noroom1_msg    defm 12,"RomUpdate uses approx. ", 0
.ram_noroom2_msg    defm "K of RAM file space to add/update Application Card.", $0D, $0A
                    defm "Free RAM = ", 0
.ram_noroom3_msg    defm "K. You need to release ",0
.ram_noroom4_msg    defm "K file space to perform the add/update.",0
.no_ozflashrom_msg  defm "OZ ROM could not be installed. No Flash chip was recognised in slot ", 0
.resetprompt_msg    defm $0D, $0A, " Do you want RomUpdate to ", 1, "TSOFT RESET", 1, "T the Z88 to install added application?", 0
.reset2_msg         defm $0D, $0A, $0D, $0A, "Go to Index, remove card, close flap and re-insert card to install application", 0
.yes_msg            DEFM 13,1,"2+C Yes",8,8,8,0
.no_msg             DEFM 13,1,"2+C No ",8,8,8,0

.updoz1_msg         defm 1, "FUpdating OZ ROM", 0
.updoz2_msg         defm " - please wait...", 1, "F", 13, 10, 0

.hrdreset_msg       defm "Z88 will automatically HARD RESET when updating has been completed", 0
.removecrd_msg      defm 12, "Insert flash Card with OZ in slot 1 and hard reset Z88.", 0
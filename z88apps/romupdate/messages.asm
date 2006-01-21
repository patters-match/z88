; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2006
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

     ; RomUpdate runtime variables
     include "romupdate.def"

     xdef MsgFoundAppDor
     xdef MsgCompleted
     xdef ReportStdError, DispErrMsg
     xdef ErrMsgNoFlash, ErrMsgIntelFlash
     xdef ErrMsgBankFile, ErrMsgCrcFailBankFile, ErrMsgPresvBanks, ErrMsgCrcCheckPresvBanks
     xdef ErrMsgSectorErase, ErrMsgBlowBank, ErrMsgNoRoom
     xdef MsgCrcCheckBankFile, MsgPreserveSectorBanks, MsgEraseSector, MsgUpdateBankFile
     xdef MsgRestorePassvBanks

     xref suicide



; *************************************************************************************
; Display "<AppName> was successfully updated in slot X",
; prompt for key press, then exit program by KILL request.
;
.MsgCompleted
                    call DispAppName
                    ld   hl,completed_msg               ; " was successfully completed"
                    oz   GN_Sop
                    ld   hl,slot_msg                    ; " in slot "
                    oz   GN_Sop
                    call DispSlotNo
                    call ResKey                         ; "Press any key to exit RomUpdate" ...
                    jp   suicide                        ; perform suicide with application KILL request
; *************************************************************************************


; *************************************************************************************
; 'Found <AppName> in slot X'
;
; IN:
;    (appname) = local pointer to null-terminated application name (from DOR)
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.MsgFoundAppDor
                    push af
                    push hl
                    ld   hl,found_msg
                    oz   GN_Sop
                    call DispAppName
                    ld   hl,slot_msg                    ; "Found <appname> in slot X"
                    oz   GN_Sop
                    call DispSlotNo                     ; derived from (dorbank rtm var)
                    pop  hl
                    pop  af
                    ret
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
.MsgUpdateBankFile
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
                    call DispSectorNo
                    pop  hl
                    ret

; *************************************************************************************


; *************************************************************************************
.MsgRestorePassvBanks
                    ld   hl,rest_bnkfiles_msg
                    oz   GN_Sop
                    call DispSectorNo
                    ret
; *************************************************************************************


; *************************************************************************************
; Display progress message while preserving passive bank in sector (to be erased later)
;
.MsgPreserveSectorBanks
                    ld   hl,prsvsectbanks_msg
                    oz   GN_Sop
                    jp   DispSectorNo
; *************************************************************************************


; *************************************************************************************
.MsgEraseSector
                    ld   hl,erasesector_msg
                    oz   GN_Sop
                    jp   DispSectorNo
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
.dspnm              jp   DispNumber
; *************************************************************************************


; *************************************************************************************
; This error message is being displayed when the found application was
; available on an Intel Flash, but not in slot 3 (cannot be updated).
;
.ErrMsgIntelFlash
                    oz   GN_nln
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
; Display an error message when the blowing of updated application bank
; (or passive banks) fails on Flash Card.
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
                    oz   GN_Sop                         ; display filename
                    call VduToggleBoldTypeface
                    ld   hl,updbnk2_err_msg
                    oz   GN_Sop
                    call DispSectorNo
                    ld   hl,flash_err_msg
                    jr   disp_error_msg
                    ret
; *************************************************************************************


; *************************************************************************************
; This error message is being displayed when the found application in a slot was
; available on an UV Eprom.
;
.ErrMsgNoFlash
                    ld   hl,noflashcard_msg             ; "No Flash Card found"
                    oz   GN_Sop
                    ld   hl,slot_msg                    ; "in slot "
                    oz   GN_Sop
                    call DispSlotNo                     ; then display 'not updated' message
; *************************************************************************************


; *************************************************************************************
; Display "<AppName> could not be updated", prompt for key press then exit application
;
.ErrMsgNotUpdated
                    call DispAppName                    ; "<AppName> could not be updated"
                    ld   hl,notupd_msg
                    jp   disp_error_msg
; *************************************************************************************


; *************************************************************************************
; Display DOR application name in bold typeface.
; pointer to application is found in (appname) runtime variable.
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
                    ld   a,(dorbank)
                    rlca
                    rlca
                    and  @00000011
                    call DispNumber
                    ld   a,'.'
                    oz   OS_Out
                    oz   GN_nln
                    ret
; *************************************************************************************


; *************************************************************************************
; Display sector number, derived from [dorbank] runtime variable.
;
.DispSectorNo
                    ld   a,(dorbank)
                    rrca
                    rrca                                ; bankNo/4
                    and  @00001111                      ; sector number containing bank
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
;    A = number to be displayed at current window position
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

                    ld   bc, NQ_Shn
                    oz   OS_Nq                          ; get screen handle in IX

                    ld   b,0
                    ld   c,a
                    ld   d,b
                    ld   e,b                            ; result to stream IX (screen)
                    ld   h,b
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
                    call VduEnableCentreJustify
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
; constants

.centerjustify      defm 1, "2JC", 0
.leftjustify        defm 1, "2JN", 0
.vdubold            defm 1,"B",0

.ResKey_msg         defm $0D,$0A,1,"2JC",1,"3+FTPRESS ANY KEY TO EXIT ROMUPDATE",1,"4-FTC",1,"2JN",0
.found_msg          defm "Found ", 0
.slot_msg           defm " in slot ",0
.completed_msg      defm " was successfully updated",0
.notupd_msg         defm " could not be updated.",0
.noflashcard_msg    defm "No Flash Card found.",0
.wrongslot_msg      defm "Intel Flash Card can only be updated in slot 3.", $0D, $0A
                    defm "Insert Application Card in slot 3, and run RomUpdate again.", 0
.notfound_msg       defm " bank file (to be updated on card) was not found.",0
.io_error_msg       defm " bank file was not properly loaded (possibly corrupted).",0
.notcreated_msg     defm " (temporary) file could not be created (already in use or I/O error).",0
.file_noroom_msg    defm " (temporary) file creation was rejected. File system space exhausted.", 0
.crcbankfile1_msg   defm "CRC Checking ",0
.crcbankfile2_msg   defm " bank file.",0
.crcerr_bfile1      defm "CRC check failed for ", 0
.crcerr_bfile2      defm "Bank file was possibly damaged by serial port transfer or", $0D, $0A
.crcerr_bfile3      defm "because of corrupted RAM Filing System!",0
.crcerr_psvbnk_msg  defm "(temporary) passive bank files, possibly ", $0D, $0A, 0
.prsvsectbanks_msg  defm "Preserving passive banks of sector no. ",0
.erasesector_msg    defm "Erasing 64K sector no. ",0
.fatal_err_msg      defm "Fatal Error: ",0
.erasect_err_msg    defm "Sector could not be formatted", $0D, $0A, 0
.flash_err_msg      defm "(Battery low condition or slot connector card problem).", 0
.updbnkfile1_msg    defm "Updating new version of ", 0
.updbnkfile2_msg    defm " (from ", 0
.updbnkfile3_msg    defm " file) to sector no. ", 0
.rest_bnkfiles_msg  defm "Restore remaining banks (from RAM files) to sector no. ", 0
.updbnk1_err_msg    defm "Bank (", 0
.updbnk2_err_msg    defm ") failed to be written to sector no. ", 0
.ram_noroom1_msg    defm "RomUpdate uses approx. ", 0
.ram_noroom2_msg    defm "K of RAM file space to update Application Card.", $0D, $0A
                    defm "Free RAM = ", 0
.ram_noroom3_msg    defm "K. You need to release ",0
.ram_noroom4_msg    defm "K file space to perform the update.",0
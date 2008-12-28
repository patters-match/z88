; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

lstoff

    include "sysvar.def"              ; get details of Intuition runtime area

    DEFC RST_20H = $E7                ; instruction opcode identifier

    ; Status flag1 :
    DEFC Flg_CLI        = 0           ; BIT 0:    CLI '.T>file' redirection flag (1 = active)
    DEFC Flg_IntWin     = 1           ; BIT 1:    Intuition window #1 to be used (0 = #2)
    DEFC Flg_IntScr     = 2           ; BIT 2:    Copy of Intuition screen saved successfully
    DEFC Flg_IntWinActv = 3           ; BIT 3:    Intuition window active
    DEFC Flg_AplScr     = 4           ; BIT 4:    Copy of application screen saved successfully
    DEFC Flg_HexCursor  = 5           ; BIT 5:    Hex Cursor active (only used in View/Edit Memory)
    DEFC Flg_EditMode   = 6           ; BIT 6:    Edit mode active (0 = View mode only)
    DEFC Flg_DZRegDmp   = 7           ; BIT 7:    Register Dump in Auto Disassemble

    ; Status flag2 :
    DEFC Flg_RTM_DZ     = 0           ; BIT 0:    Auto Dissassemble Mode.
    DEFC Flg_RTM_Trace  = 1           ; BIT 1:    Single stepping mode.
    DEFC Flg_RTM_BpInst = 2           ; BIT 2:    Instruction break Mode
    DEFC Flg_RTM_Kesc   = 3           ; BIT 3:    Keyboard Interrupt Mode (ESC to stop execution).
    DEFC Flg_RTM_bindout= 4           ; BIT 4:    Indicate Bind-out alert.
    DEFC Flg_RTM_error  = 5           ; BIT 5:    Virtual Processor Runtime error (also used as single stepping) ** V1.04
    DEFC Flg_RTM_RET    = 6           ; BIT 6:    RET instruction encountered
    DEFC Flg_RTM_Breakp = 7           ; BIT 7:    Breakpoints defined/not defined.

    ; Status flag 3:
    DEFC Flg_DZopcode   = 0           ; BIT 0:    Display instruction opcodes during disassembly
    DEFC Flg_CmdLine    = 1           ; BIT 1:    Active command line
    DEFC Flg_TraceCPY   = 2           ; BIT 2:    Copy of RTM trace flag status.
    DEFC Flg_TraceSubr  = 3           ; BIT 3:    Trace until subroutine
    DEFC Flg_WinMode    = 4           ; BIT 4:    Application window protection mode
    DEFC Flg_BreakDump  = 5           ; BIT 5:    Dump Registers at break point
    DEFC Flg_BreakOZ    = 6           ; BIT 6:    Break at OZ error (Fc = 1)
    DEFC Flg_DbgRunning = 7           ; BIT 7:    Set to 1 when Intuition is active


    DEFC ERR_unknown_instr = $80
    DEFC ERR_RET_unbalanced = $81
    DEFC ERR_not_found = $82
    DEFC ERR_none = $83
    DEFC ERR_KILL_request = $84
    DEFC ERR_bindout = $85

lston

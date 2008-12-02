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

; Intuition assembly directives:
;     DEFINE SEGMENT3                   ; Intuition uses segment 3 for bank switching (Intuition executed in segment 1 or segment 2)
;     DEFINE SEGMENT2                   ; Intuition uses segment 2 for bank switching (Intuition application runs in segment 3)
;     DEFINE INT_SEGM0, SEGMENT3        ; Intuition running in the upper half of segment 0 (two 8K half banks swapped)

IF SEGMENT2
     DEFC Intuition_init = $2000
     DEFC Z80dbg_MTH_bank = $3E, tokens_bank = $3E
     DEFC Z80dbg_bank = $3F, Z80dbg_DOR = $C000
     DEFC Z80dbg_workspace = 0
ENDIF


; Intuition Mnemonics, i.e. offsets from base of Runtime Area:

DEFVARS 0
{
     VP_BC                         ; Virtual Processor BC register
          VP_C      DS.B 1
          VP_B      DS.B 1
     VP_DE                         ; Virtual Processor DE register
          VP_E      DS.B 1
          VP_D      DS.B 1
     VP_HL                         ; Virtual Processor HL register
          VP_L      DS.B 1
          VP_H      DS.B 1
     VP_AF          DS.W 1         ; Virtual Processor AF register
     VP_BCx                        ; Virtual Processor alternate BC register
          VP_Cx     DS.B 1
          VP_Bx     DS.B 1
     VP_DEx                        ; Virtual Processor alternate DE register
          VP_Ex     DS.B 1
          VP_Dx     DS.B 1
     VP_HLx                        ; Virtual Processor alternate HL register
          VP_Lx     DS.B 1
          VP_Hx     DS.B 1
     VP_AFx         DS.W 1         ; Virtual Processor alternate AF register
     VP_IX                         ; Virtual Processor IX register
          VP_IXl    DS.B 1
          VP_IXh    DS.B 1
     VP_IY                         ; Virtual Processor IY register
          VP_IYl    DS.B 1
          VP_IYh    DS.B 1
     VP_SP          DS.W 1         ; Virtual Processor SP register
     VP_PC          DS.W 1         ; Virtual Processor PC register

     ExecBuffer     DS.B 6         ; 6 byte OZ execute buffer
                    DS.B 1         ; not used...
     BreakPoints    DS.B 1         ; Current number of defined breakpoints
                    DS.W 8         ; space for breakpoints
     Cmdlbuffer     DS.B 17        ; Command line buffer (17 bytes)
     ApplWinID      DS.B 1         ; Current Application Window ID
     ApplScrID      DS.W 1         ; Handle of saved application screen
     IntScrID       DS.W 1         ; Handle of saved Intuition screen
     IntWinID       DS.B 1         ; Current Intuition Window ID
     SC             DS.B 1         ; Horisontal Start Cursor Position
     CI             DS.B 1         ; Horisontal Cursor Increment
     CX             DS.B 1         ; Horisontal Cursor Movement
     CY             DS.B 1         ; Vertical Cursor Movement
     LogfileNr      DS.B 1         ; CLI log file number

     FlagStat1      DS.B 1         ; Flag Status byte 1
     FlagStat2      DS.B 1         ; Flag Status byte 2
     FlagStat3      DS.B 1         ; Flag Status byte 3

     RtmError       DS.B 1         ; Runtime Error number
     SPlevel        DS.W 1         ; Initial stack pointer level (subroutine tracing)
     InstrBreakPatt DS.B 5         ; Instruction break bit pattern (max. 4 bytes)
     ApplErhClvl    DS.B 1         ; Application Error Handler Call Level
     ApplErhAddr    DS.W 1         ; Application Error Handler Address
     RamTopPage     DS.B 1         ; Top Page of allocated application RAM (Z80debug only)
     OzReleaseVer   DS.B 1         ; Cache OZ Version number from OS_Frm, IX=-1, A=FA_PTR
     OZBankBinding  DS.W 1         ; Original bank binding of segment X before Intuition was activated
     Int_Worksp                    ; Number of bytes in Intuition Workspace (RTM)
}

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
                                      ; BIT 4:
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

    DEFC ERR_unknown_instr = $80
    DEFC ERR_RET_unbalanced = $81
    DEFC ERR_not_found = $82
    DEFC ERR_none = $83
    DEFC ERR_KILL_request = $84

lston

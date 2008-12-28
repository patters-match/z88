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

     MODULE Command_line

     XREF Save_SPAFHLPC, Restore_SPAFHLPC
     XREF Save_alternate, Restore_alternate

     XREF DisplayRegisters                   ; Routine defined in 'DispRegs_asm':
     XREF DZ_Z80pc, Display_OZ_Mnemonic      ; Routine defined in 'Disasm_asm':
     XREF Write_err_msg                      ; Routine defined in 'Errmsg_asm':
     XREF Debugger_version
     XREF GetRegister
     XREF Flagreg_changes
     XREF Hex_binary_disp, Binary_hex_disp, Ascii_hex_disp
     XREF Hex_ascii_disp, Dec_hex_disp

     ; Routine defined in 'windows.asm':
     XREF SV_appl_window, RST_appl_window
     XREF Disp_Monitor_win, Rel_appl_window, RST_INT_window
     XREF Display_string, Write_CRLF

     XREF Disp_window_ID

     ; Routines defined in 'prscmdline.asm':
     XREF InputCommand, ExecuteCommand

     XREF SkipSpaces, GetChar, UpperCase

     XREF Toggle_CLI

     XREF Mem_View, Mem_Edit, Mem_Search, ViewStack
     XREF Toggle_TraceMode, Toggle_KbIntMode, Toggle_PauseMode, Toggle_DasmMode, Toggle_RegDump
     XREF Toggle_brkpdump, Disp_toggleStat, Stack_boundary, Tracesubr_flag
     XREF ToggleBreakPoint, Breakpoint_list, Toggle_BrkOZ, Toggle_DZopc
     XREF Memory_dump, Segment_dump, Bank_dump

     XREF Memory_Load, Memory_Range, Memory_RamTop, Kill_application, Name_application

     XREF DefInstrBreak, InstrBreakList

     XREF Disasm_param
     XREF RST_ApplErrhandler, Syntax_error
     XREF GetKey
     XREF Set_Intuition_ID

     ; Routines globally defined in this module:
     XDEF Command_line
     XDEF Disp_RTM_error

     XDEF Calc_HL_ptr


     INCLUDE "defs.h"
     INCLUDE "error.def"
     INCLUDE "stdio.def"
     INCLUDE "interrpt.def"
     INCLUDE "sysvar.def"
     INCLUDE "../../os/lowram/lowram.def"         ; get address for Intuition exit in LOWRAM


; ***********************************************************************************
;
; Command line input and execution of command.
;
; Register status after return:
;
;       ......../..IY/........  same
;       AFBCDEHL/IX../afbcdehl  different
;
.Command_line     SET  Flg_CmdLine,(IY + FlagStat3)    ; activate command line interpreter
.cont_cmd_line    BIT  Flg_IntWinActv,(IY + FlagStat1) ;                                ** V0.24a
                  JR   NZ, cmd_dispreg      ; Intuition window already active           ** V0.24a
                  CALL SV_appl_window       ; save application screen window            ** V0.22
                  CALL Disp_Monitor_win     ; display Intuition window...               ** V0.22
.cmd_dispreg
                  CALL DisplayRegisters     ; then dump contents of Z80 registers
                  CALL Disp_RTM_error       ; display error or OZ mnemonic              ** V0.32
                  CALL DZ_Z80pc             ; Disassemble instruction at (PC)
                  CALL Write_CRLF           ;                                           ** V0.28
                  BIT  Flg_RTM_bindout,(IY + FlagStat2)
                  JR   Z,command_loop
                  LD   (IY + Cmdlbuffer+2),'G'
                  LD   (IY + Cmdlbuffer+3),0    ; preset with .G command for bind-alert
.command_loop     CALL InputCommand         ; wait until a key is pressed...
                  CALL ExecuteCommand
                  BIT  Flg_CmdLine,(IY + FlagStat3)    ; command line aborted?
                  JR   NZ, command_loop     ; no, continue command line...
                  LD   A,(IY + FlagStat2)   ; get runtime flags                         ** V0.28
                  BIT  Flg_RTM_Trace,A      ; Single Step Mode?                         ** V0.24a/V0.28
                  JR   NZ, restore_screen   ; Yes, restore screen                       ** V0.24a
                  BIT  Flg_RTM_DZ,A         ; else                                      ** V0.24a/V0.28
                  RET  NZ                   ; If Auto disassemble, don't restore window ** V0.24a
.restore_screen   JP   RST_appl_window      ; restore application screen window         ** V0.22


; *************************************************************************************************
;
;    Display runtime error,                                           V0.32
;     or display OZ call previously executed (Break at OZ error)
;
.Disp_RTM_error   BIT  Flg_RTM_error,(IY + FlagStat2)
                  JR   Z, terminate_line

                  RES  Flg_RTM_error,(IY + FlagStat2) ; reset flag - the error has been trapped   ** V0.26e
                  LD   A,(IY + RtmError)              ; get run time error code
                  LD   (IY + RtmError),0              ; reset runtime error                       ** V1.04
                  CP   $FF                            ; display executed OZ call mnemonic?
                  JR   Z, disp_oz_mnem
                  JP   Write_err_msg
.disp_oz_mnem
                  LD   C,ExecBuffer+1             ; point at RST instruction...
                  CALL Calc_HL_ptr
                  LD   C,(HL)                     ; get RST instruction opcode
                  INC  HL
                  LD   E,(HL)
                  INC  HL
                  LD   D,(HL)
                  EX   DE,HL
                  LD   A,C
                  LD   D,4                        ; instruction display at beginning of line...
                  CP   $DF
                  PUSH AF
                  CALL Z, Display_OZ_mnemonic     ; FPP OZ call (Fc = 0)
                  POP  AF
                  JR   Z, terminate_line
                  SCF
                  CALL Display_OZ_Mnemonic        ; RST 20H OZ call  (Fc = 1)
.terminate_line   JP   Write_CRLF


; *************************************************************************************************
;
; Parse command line to execute command.
; Entry of subroutine: HL points to start of input buffer
;
; If no command was found, or a syntax error occurred, Fc = 1 on exit.
;
; A true command must be initialized with a '.' , followed by a sequense of one or several letters
; (max 4). A command can be typed in both upper or lower case (They are actally converted to
; upper case at input).
;
; Other commands (with no dot in front) are register-related commands or number conversion ulilities.
;
; The following commands in "Intuition" are available:
;
;         .             Execute next instruction / continue breakpoint mode.
;         .G            Release Monitoring and execute program from current PC.
;         .D [nn] [b]   Dissassemble from current PC, or from address <nn> in logical         ** V0.17
;                       address space, or at bank b addressed as nn.
;         .MV [nn] [b]  View memory at bank number, address <nn>, otherwise                   ** V0.19
;                       address nn in logical address space.
;         .ME [nn] [b]  Edit memory at bank number, address <nn>, otherwise                   ** V0.19
;                       address nn in logical address space.
;         .VA [nn] [b]  View addresses at nn, default at (SP)
;         .B nn         Set / reset breakpoint at address <nn>.
;         .V            View program screen (not the Monitor windows).
;                       This command is only relevant, if screen protect mode is active.
;         .T [+|-]      Trace mode Set/Reset (single step mode).
;                       if attributes are not used, the mode will be inverted
;                       from current status, otherwise:
;                                 '+'       Set mode
;                                 '-'       Reset mode
;         .TS           Trace Subroutine.                                                    ** V0.26e
;         .K [+|-]      Keyboard interrupt mode Set/Reset
;         .Z [+|-]      Auto-dissassemble (at current PC) Mode Set / Reset
;         .DO [+|-]     Display instruction opcodes during disassembly                       ** V1.02
;         .X [+|-]      Auto Register Dump during disassemble Set / Reset                    ** V0.27b
;         .R            Display register status.
;         .S            Display a status of all current runtime flags.
;         .I            Display Intuition version and position of Runtime Area
;         .BL           List Breakpoint addresses
;         .W [n]        Set Intuition window ID (6 is default), otherwise n = 1 to 6
;         .WS           Display window ID status.
;                       The current window ID for the application and Intuition is displayed.
;         F             display flag register           - the flag commands are equal case.
;         FZ [+|-]      Set/reset Zero flag.
;         FC [+|-]      Set/reset Carry flag.
;         FV [+|-]      Set/reset Overflow flag.
;         FE [+|-]      Set/reset Parity flag (same flag as FV).
;         FP [+|-]      Set/reset Plus/Minus flag.
;         FS [+|-]      Set/reset Sign flag.
;
;         '<char>       display ASCII <char> in HEX and binary represention, i.e. :           ** V0.18
;                          'A     displays            41H,   ^01000001
;         "<hex>        display 8bit hex value in ASCII representation, i.e. :                ** V0.18
;                          "2E    displays            '.'
;         $<hex>        display 8bit hex value in decimal and binary representation
;         ~<decimal>    display 8/16bit decimal value in hex representation
;         @<binary>     display 8bit binary value in hex and decimal representation
;
;         <TAB>         toggle between Intuition window #1 and #2                    ** V0.18 / V0.20b
;                       (current command line is still active)
;
;         B  [n]        set B  register
;         C  [n]            C
;         D  [n]            D
;         E  [n]            E
;         H  [n]            H
;         L  [n]            L
;         A  [n]            A
;         b  [n]            B'
;         c  [n]            C'
;         d  [n]            D'
;         e  [n]            E'
;         h  [n]            H'
;         l  [n]            L'
;         a  [n]            A'
;         PC [nn]       set PC register
;         SP [nn]           SP
;         HL [nn]           HL
;         DE [nn]           DE
;         BC [nn]           BC
;         IX [nn]           IX
;         IY [nn]           IY
;
;                       [n] defines an 8bit integer. The following options are available:
;                                 %<binary digits>    - 8bit binary representation, i.e. %10001111
;                                 <hex byte>          - 2 char hex byte definition, i.e. FF
;                                 '<char>             - ASCII byte definition, i.e. 'A
;                                 ~<decimal>          - 8bit/16bit decimal value, e.g. ~128 or ~49152
;                                 <8bit register>     - 8bit register mnemonic, e.g. H
;
;                       [nn] defines a 16bit (hex) address. If an address is left out, it will be
;                       interpreted as displaying the register contents.
;                       Instead of defining an absolute address, it is allowed to specify a 16 bit
;                       register as parameter, otherwise a constant is of the form:
;                                 <16bit hex>
;                                 ~<16bit decimal>
;
;                       In general, all references to where an integer can be specified, it is allowed
;                       to reference a register value in stead. The size type must however match, e.g.
;                       it is illegal to specify a 16 bit register when only an 8 bit value is needed.
;
;                       Please note, that alternate registers are references by lower case letters.
;
;         <>-           Activation of CLI / Logfile to copy contents of screen into logfile '/log.x' .
;
; Register status after return:
;
;       ......../IXIY  same
;       AFBCDEHL/....  different
;
.ExecuteCommand   CALL SkipSpaces           ; point at first real character.
                  RET  C                    ; end of line reached...                    ** V0.18
                  CALL GetChar
                  CP   '.'
                  JR   Z, get_command
                  CP   'F'                  ; flag register manipilation?
                  JR   NZ, chck_convcmd
                  JP   Flagreg_changes

.chck_convcmd     DEC  HL                   ; point at conversion identifier...
                  LD   DE, ConvCommands     ; is it a conversion command?
                  CALL FindCommand
                  JR   C, parse_register
                  JP   (IX)

.parse_register   INC  HL                   ;
                  JP   GetRegister          ; try to fetch a register

.get_command      LD   A,(HL)
                  CALL UpperCase
                  OR   A
                  JR   NZ, lookup_cmd       ; .XX command
                  BIT  Flg_RTM_bindout,(IY + FlagStat2)     ; '.' command, but allowed to execute?
                  JR   Z, Exec_instruct     ; execute next instruction - only when not in bind-out alert..
                  RET                       ; ignore '.' and get back to command line..
.lookup_cmd
                  LD   DE, Commands
                  CALL FindCommand
                  JR   C, Unknown_request
                  JP   (IX)

.unknown_request  LD   A,$0E                ; 'Cannot satisfy request'
                  JP   Write_Err_Msg


; ******************************************************************************************
;
; terminate command line and execute the instruction at (PC)
; - before command line is left, then check if 'Trace Subroutine' is activated.
;   If it is, then copy the current SP into the RETurn SP (IY+82,83)
;
.Exec_instruct    RES  Flg_CmdLine,(IY + FlagStat3)    ; de-activate command line interpreter
                  BIT  Flg_TraceSubr,(IY + FlagStat3)  ; 'Trace Subroutine' activated?
                  RET  Z                               ; - no
                  LD   L,(IY + VP_SP)                  ; get a copy of SP...
                  LD   H,(IY + VP_SP+1)
                  LD   (IY + SPlevel)  ,L
                  LD   (IY + SPlevel+1),H              ; current SP saved as RETurn SP.
                  RET                                  ; run virtual processor code ...



; ********************************************************************************
;
.FindCommand      PUSH HL                   ; preserve pointer to command line
                  EX   DE,HL
                  LD   B,(HL)               ; no. of command definitions...
                  INC  HL
.findcmd_loop     LD   E,(HL)               ; get subroutine address of command
                  INC  HL
                  LD   D,(HL)
                  PUSH DE
                  POP  IX                   ; IX points at subroutine
                  INC  HL                   ; get ready for command sequense
                  EX   DE,HL                ; with pointer in DE
                  POP  HL                   ; pointer to current command line
                  PUSH HL
.cmp_command_loop LD   A,(DE)
                  INC  DE                   ; get byte from command definition
                  LD   C,A
                  OR   A                    ; null-terminator reached in definition?
                  JR   Z, check_cmdend      ; Yes - check if command also has ended...
                  LD   A,(HL)
                  INC  HL
                  CALL UpperCase
                  CP   C
                  JR   Z, cmp_command_loop  ; compare next character of command...

.next_command_def LD   A,(DE)
                  INC  DE
                  OR   A
                  JR   NZ, next_command_def ; IX must point at beginning of next command
                  JR   parse_next_cmd

.check_cmdend     OR   (HL)
                  JR   Z, command_found     ; command ended with null-terminator
                  CP   ' '
                  JR   Z, command_found     ; or separated with space

.parse_next_cmd   EX   DE,HL                ; HL is pointer to beginning of next cmd. definition
                  DJNZ findcmd_loop

                  POP  HL                   ; command wasn't found
                  LD   A,(HL)               ; get char of current command line pointer
                  SCF
                  RET

.command_found    POP  AF                   ; remove redundant cmd.line pointer
                  CP   A                    ; signal success!
                  RET                       ; HL points at next char in command line

;
; Local conversion commands:
.ConvCommands     DEFB 5

                  DEFW Hex_binary_disp
                  DEFM '$',0

                  DEFW Binary_hex_disp
                  DEFM '@',0

                  DEFW Ascii_hex_disp
                  DEFM ''',0

                  DEFW Hex_ascii_disp
                  DEFM '"',0

                  DEFW Dec_hex_disp
                  DEFM '~',0

.Commands
                  DEFB 23

                  DEFW Set_Intuition_ID
                  DEFM "W",0

                  DEFW Disp_window_ID
                  DEFM "WS",0

                  DEFW View_ApplScreen
                  DEFM "V",0

                  DEFW Release_debugger
                  DEFM "G",0

                  DEFW Debugger_version
                  DEFM "I",0

                  DEFW Toggle_KbIntMode
                  DEFM "K",0

                  DEFW Toggle_DasmMode
                  DEFM "Z",0

                  DEFW Toggle_RegDump
                  DEFM "X",0

                  DEFW DisplayRegisters
                  DEFM "R",0

                  DEFW Disasm_param
                  DEFM "D",0

                  DEFW Toggle_DZopc
                  DEFM "DO",0

                  DEFW ToggleBreakpoint
                  DEFM "B",0

                  DEFW DefInstrBreak
                  DEFM "BI",0

                  DEFW InstrBreakList
                  DEFM "BIL",0

                  DEFW Breakpoint_List
                  DEFM "BL",0

                  DEFW Toggle_Brkpdump
                  DEFM "BD",0

                  DEFW Toggle_BrkOZ
                  DEFM "BO",0

                  DEFW Disp_ToggleStat
                  DEFM "S",0

                  DEFW Toggle_TraceMode
                  DEFM "T",0

                  DEFW Tracesubr_flag
                  DEFM "TS",0

                  DEFW Mem_Edit
                  DEFM "ME",0

                  DEFW Mem_View
                  DEFM "MV",0

                  DEFW ViewStack
                  DEFM "VA",0


; **********************************************************************************
;
; Restore SP, fetch PC, and restore registers to release program from Z88 Monitor
;
.Release_debugger CALL RST_appl_window      ; restore application screen window         ** V0.22
                  CALL RST_ApplErrhandler   ; restore application error handler         ** V0.31

                  res     Flg_DbgRunning,(IY + FlagStat3)         ; indicate that Intuition is not running

                  bit     Flg_RTM_bindout,(IY + FlagStat2)
                  jr      z,cont_restore_regs
                  ld      a,(SV_INTUITION_RAM + BindOut_copy)     ; restore bank binding of bind-out alert
                  ld      (SV_INTUITION_RAM + OZBankBinding+1),a  ; (old binding of Intuition no longer important)

.cont_restore_regs
                  ld      hl,(SV_INTUITION_RAM + VP_AF)           ; install current AF register
                  push    hl
                  pop     af
                  ex      af,af'
                  ld      hl,(SV_INTUITION_RAM + VP_AFx)          ; install current AF' register
                  push    hl
                  pop     af
                  ex      af,af'

                  ld      ix,(SV_INTUITION_RAM + VP_IX)           ; install current IX register
                  ld      iy,(SV_INTUITION_RAM + VP_IY)           ; install current IY register

                  exx
                  ld      bc,(SV_INTUITION_RAM + VP_BCx)          ; install current BC' register
                  ld      de,(SV_INTUITION_RAM + VP_DEx)          ; install current DE' register
                  ld      hl,(SV_INTUITION_RAM + VP_HLx)          ; install current HL' register
                  exx

                  ld      sp,(SV_INTUITION_RAM + VP_SP)           ; install SP
                  ld      bc,(SV_INTUITION_RAM + VP_PC)           ; Z80 Program Counter of Application (code outside Intuition)
                  push    bc                                      ; (will be POP'ed... after restore bank binding)
                  ld      bc,(SV_INTUITION_RAM + VP_BC)           ; get current BC register
                  push    bc                                      ; which will be restored in LOWRAM after restore bank binding
                  ld      de,(SV_INTUITION_RAM + VP_DE)           ; get current DE register
                  ld      hl,(SV_INTUITION_RAM + VP_HL)           ; get current HL register

                  ld      bc,(SV_INTUITION_RAM + OZBankBinding)   ; get original segment 0 bank binding
                  jp      exitIntuitionLowRam                     ; restore bank binding in LOWRAM, then let Z80 run application


; ****************************************************************************************
;
; View the application screen.
; - then restore Intuition window and continue command line input...
;
.View_ApplScreen  BIT  Flg_AplScr,(IY + Flagstat1)
                  RET  Z                    ; no application window saved...
                  CALL RST_appl_window      ; restore application window
                  CALL SV_appl_window       ; immediately save it
                  CALL GetKey
.restore_window   JP   Disp_Monitor_win     ; then re-display Intuition window



; ******************************************************************************
;
; HL = IY + offset, offset = C
; This subroutine is used only by code that uses offset values less than 127 -
; no carry calculation is needed.
;
.Calc_HL_Ptr      PUSH IY
                  POP  HL
                  LD   B,0
                  ADD  HL,BC
                  RET

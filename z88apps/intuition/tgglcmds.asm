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

    MODULE Toggle_commands

    XREF SkipSpaces, GetChar
    XREF Get_constant
    XREF Write_Msg, Display_string

    XDEF Toggle_DasmMode, Toggle_TraceMode, Toggle_KbIntMode
    XDEF Toggle_RegDump, Toggle_Brkpdump, Tracesubr_flag
    XDEF Toggle_BrkOZ, Toggle_DZopc
    XDEF Switch_bitnumber, Disp_ToggleStat

    INCLUDE "defs.h"


; **********************************************************************************
;
; Toggle Trace / Breakpoint mode  (IY + FlagStat2) , Bit 1.
;
; BIT set  : Trace mode (Single step mode).
; BIT reset: Breakpoint mode.
;
.Toggle_TraceMode BIT  Flg_TraceSubr,(IY + FlagStat3)
                  RET  NZ                              ; if 'Trace until RET' is ON then ignore...
                  LD   BC, 2**Flg_RTM_Trace*256 + FlagStat2
                  SCF
                  JP   Switch_bitnumber

; '.TS' - Set Trace Subroutine flag         ;                                       ** V0.26e
.tracesubr_flag   LD   BC, 2**Flg_TraceSubr*256 + Flagstat3
                  SCF
                  CALL Switch_bitnumber
                  BIT  Flg_TraceSubr,A                 ; check the 'Trace until RET' flag
                  JR   NZ, rescpy_traceflag            ; if ON, then disable single step mode...
                  BIT  Flg_TraceCPY,(IY + FlagStat3)   ; is copy of Trace flag 0?
                  RET  Z                               ; Then don't copy
.restore_sglstep  SET  Flg_RTM_Trace,(IY + FlagStat2)
                  RES  Flg_TraceCPY,(IY + FlagStat3)   ; copy of flag cleared...
                  RET                       ; Trace until RET is OFF - normal trace/single step restored

.rescpy_traceflag BIT  Flg_RTM_Trace,(IY + FlagStat2)  ; Single Step Mode activated?
                  RET  Z                               ; no - then no need to clear flag
.reset_slgstep    RES  Flg_RTM_Trace,(IY + FlagStat2)
                  SET  Flg_TraceCPY,(IY + FlagStat3)   ; copy single step flag
                  RET



; **********************************************************************************
;
; Toggle Auto Dissassemble mode  (IY + FlagStat2) , BIT 0.
;
; BIT 0 set  : Auto Dissassemble mode ON
; BIT 0 reset:                        OFF
;
.Toggle_DasmMode  LD   BC, 2**Flg_RTM_DZ*256 + FlagStat2
                  SCF
                  JR   Switch_bitnumber


; **********************************************************************************
;
; Toggle Keyboard interrupt mode  (IY + FlagStat2)
;
; BIT set  : Keyboard interrupt mode ON.
; BIT reset:                         Off.
;
.Toggle_KbIntMode LD   BC, 2**Flg_RTM_Kesc*256 + FlagStat2
                  SCF
                  JR   Switch_bitnumber


; **********************************************************************************
;
; Toggle Auto Register Dump (IY + FlagStat1)      ** V0.27b
;
; BIT set  : Auto Register Dump ON.
; BIT reset:                    Off.
;
.Toggle_RegDump   LD   BC, 2**Flg_DZRegDmp*256 + Flagstat1
                  SCF
                  JR   Switch_bitnumber


; **********************************************************************************
;
; Toggle Breakpoint Register Dump mode  (IY + FlagStat3) ** V0.29
;
.Toggle_Brkpdump  LD   BC, 2**Flg_BreakDump*256 + Flagstat3
                  SCF
                  JR   Switch_bitnumber


; **********************************************************************************
;
; Toggle Disassemble opcode mode  (IY + FlagStat3) ** V1.02
;
.Toggle_DZopc     LD   BC, 2**Flg_DZopcode*256 + Flagstat3
                  SCF
                  JR   Switch_bitnumber


; **********************************************************************************
;
; Toggle Break at OZ error (IY + FlagStat3) ** V0.32
;
.Toggle_BrkOZ     LD   BC, 2**Flg_BreakOZ*256 + flagstat3
                  SCF
                  JR   Switch_bitnumber


; **********************************************************************************
;
;  Switch bit number (specified in D) in (IY + C)                     ** V0.16
;
;   Input:          C : pointer offset from register base (pointing at register)
;                   B : bit number, e.g. BIT 6 = @01000000 .
;                   Fc = 1, Display Status of toggle flags.
;
;   Output:         A = byte with altered bit number.
;
;  This code is used for toggling the various Z80 monitor status flags, including
;  the flag register (refer to .Execute_command) .
;  If the user has specified a '+' or a '-' the bit number will be set or reset.
;  If the parameter isn't specified, the flag (bit number) is inverted.
;
; Status of registers on return:
;
;       .....E../IXIY  same
;       AFBCD.HL/....  different
;
.Switch_bitnumber PUSH AF
                  PUSH BC
                  PUSH HL                               ; save pointer in input buffer
                  PUSH IY
                  POP  HL
                  LD   B,0
                  ADD  HL,BC
                  LD   B,H
                  LD   C,L
                  POP  HL                               ; HL = pointer in input buffer
                  CALL Switch_parameter
                  LD   H,B
                  LD   L,C                              ; HL = IY+C,
                  POP  BC
                  JR   C, invert_bitnumber              ; no parameter ('+' or '-') specified
                  JR   Z, Set_bitnumber
                  JR   Reset_bitnumber
.invert_bitnumber LD   A,(HL)                           ; fetch byte at (IY+C)
                  AND  B                                ; bit set?
                  JR   Z, Set_bitnumber                 ; No, set bit number
.Reset_bitnumber  LD   A,B
                  CPL                                   ; invert D bitpattern
                  LD   B,A
                  LD   A,(HL)
                  AND  B                                ; RES B, (IY+C)
                  LD   (HL),A
                  LD   B,A
                  POP  AF
                  LD   A,B
                  PUSH AF
                  CALL C,Disp_off_flag
                  POP  AF
                  RET
.Set_bitnumber    LD   A,(HL)
                  OR   B                                ; SET B, (IY+C)
                  LD   (HL),A
                  LD   B,A
                  POP  AF
                  LD   A,B
                  PUSH AF
                  CALL C,Disp_on_flag
                  POP  AF
                  RET


; **********************************************************************************
;
; Read a '+' or '-' switch parameter
;
; Returns:
;                   Fz = 1 if parameter flag is set to '+'
;                   Fz = 0 if parameter flag is set to '-'
;                   Fc = 1 if no parameter or illegal parameter is specified
;
; Status of registers on return:
;
;       ..BCDE../IXIY  same
;       AF....HL/....  different
;
.Switch_parameter CALL SkipSpaces
                  RET  C                                ; end of line reached
                  CALL GetChar
                  CP   '+'
                  RET  Z                                ; switch ON.
                  CP   '-'
                  JR   Z, switch_par_off
                  SCF                                   ; illegal switch parameter
                  RET
.switch_par_off   OR   A                                ; switch off, Fz = 0, Fc = 0
                  RET

.Kbint_msg        DEFM "Keyboard break",0
.dz_msg           DEFM "Run & Disassemble",0
.regdmp_msg       DEFM "Run & Dump",0
.trace_msg        DEFM "Single stepping",0
.trace_ret_msg    DEFM "Run subroutine",0
.brkpointdump_msg DEFM "Dump at break",0
.brk_ozerr_msg    DEFM "Break at OZ error",0
.flag_separator   DEFM ": ",0
.On_msg           DEFM "ON",0
.Off_msg          DEFM "OFF",0


; **********************************************************************************
;
; Display current Toggles & Base of Z80monitor variable area    ** V0.17
;
; Register status after return:
;
;       ......../IXIY  same
;       AFBCDEHL/....  different
;
.Disp_ToggleStat  LD   BC,77
                  PUSH IY
                  POP  HL
                  ADD  HL,BC
                  EX   DE,HL                ; DE = status byte 2
                  LD   B, @00000001
                  LD   HL, dz_msg
                  CALL Disp_statflag
                  BIT  0,(IY + FlagStat2)   ; Auto Disassembly ON?
                  JR   Z, cont_disp
                  DEC  DE
                  LD   B,@10000000          ; Auto Register Dump flag
                  LD   HL, regdmp_msg       ; BIT 7,(IY + FlagStat1)
                  CALL Disp_statflag
                  INC  DE
.cont_disp        LD   B,@00000010
                  BIT  3,(IY + FlagStat3)   ; Display only 'Trace until RET' if ON      ** V0.26e
                  JR   Z, disp_trace_flag   ; and ignore normal Trace message...        ** V0.26e
                  LD   HL, trace_ret_msg    ;                                           ** V0.26e
                  CALL Display_string       ;                                           ** V0.26e
                  LD   HL, On_msg           ;                                           ** V0.26e
                  CALL Write_Msg            ;                                           ** V0.26e
                  JR   disp_kbint_flag      ;                                           ** V0.26e
.disp_trace_flag  LD   HL, trace_msg
                  CALL Disp_statflag
.disp_kbint_flag  SLA  B
                  SLA  B
                  LD   HL, Kbint_msg
                  CALL Disp_statflag
                  SLA  B
                  INC  DE                   ; IY + FlagStat3
                  LD   B, @00100000         ; Bit 5
                  LD   HL, Brkpointdump_msg
                  CALL Disp_statflag
                  SLA  B
                  LD   HL, Brk_ozerr_msg

.Disp_statflag    CALL Display_String       ; first display flag identifier
                  LD   HL, flag_separator
                  CALL Display_string
                  LD   A,(DE)               ; get status flags
                  AND  B                    ; then its status...
                  JR   NZ, disp_on_flag
.disp_off_flag    LD   HL, Off_msg
                  JP   Write_Msg
.disp_on_flag     LD   HL, On_msg
.disp_flagstat    JP   Write_Msg

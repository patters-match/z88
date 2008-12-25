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

    MODULE Debugger


INCLUDE "defs.h"
INCLUDE "stdio.def"
INCLUDE "fileio.def"
IF SEGMENT2
     INCLUDE "mthdbg.def"
     INCLUDE "director.def"
ENDIF

    XREF ExtRoutine_s01
    XREF DisplayRegisters
    XREF DZ_Z80pc

    ; Routines defined in 'cmdline.asm':
    XREF Command_line, Disp_RTM_error
    XREF SV_appl_window, RST_appl_window, Disp_monitor_win
    XREF Write_CRLF

    XREF Save_SPAFHLPC, Restore_SPAFHLPC
    XREF FindBreakPoint, FindInstruction


    ; Routines defined in 'ldinstr.asm':
    XREF Opcode_1, Opcode_2, Opcode_6, Opcode_10, Opcode_14, Opcode_17, Opcode_18, Opcode_22
    XREF Opcode_26, Opcode_30, Opcode_33, Opcode_34, Opcode_38, Opcode_42, Opcode_46, Opcode_49
    XREF Opcode_50, Opcode_54, Opcode_58, Opcode_62, Opcode_65, Opcode_66, Opcode_67, Opcode_68
    XREF Opcode_69, Opcode_70, Opcode_71, Opcode_72, Opcode_74, Opcode_75, Opcode_76, Opcode_77
    XREF Opcode_78, Opcode_79, Opcode_80, Opcode_81, Opcode_83, Opcode_84, Opcode_85, Opcode_86
    XREF Opcode_87, Opcode_88, Opcode_89, Opcode_90, Opcode_92, Opcode_93, Opcode_94, Opcode_95
    XREF Opcode_96, Opcode_97, Opcode_98, Opcode_99, Opcode_101, Opcode_102, Opcode_103, Opcode_104
    XREF Opcode_105, Opcode_106, Opcode_107, Opcode_108, Opcode_110, Opcode_111, Opcode_112, Opcode_113
    XREF Opcode_114, Opcode_115, Opcode_116, Opcode_117, Opcode_119, Opcode_120, Opcode_121, Opcode_122
    XREF Opcode_123, Opcode_124, Opcode_125, Opcode_126, Opcode_249

    XREF Opcode_33_index, Opcode_34_index, Opcode_42_index, Opcode_249_index, Opcode_126_index
    XREF Opcode_54_index, Opcode_70_index, Opcode_78_index, Opcode_86_index, Opcode_94_index
    XREF Opcode_102_index, Opcode_110_index, Opcode_112_index, Opcode_113_index, Opcode_114_index
    XREF Opcode_115_index, Opcode_116_index, Opcode_117_index, Opcode_119_index


    ; Routines defined in 'stdinstr.asm':
    XREF Opcode_0, Opcode_8, Opcode_16, Opcode_24, Opcode_32, Opcode_40, Opcode_48, Opcode_56, Opcode_118
    XREF Opcode_192, Opcode_193, Opcode_194, Opcode_195, Opcode_196, Opcode_197, Opcode_200, Opcode_201, Opcode_215
    XREF Opcode_202, Opcode_204, Opcode_205, Opcode_207, Opcode_208, Opcode_209, Opcode_210, Opcode_211, Opcode_212
    XREF Opcode_213, Opcode_216, Opcode_217, Opcode_218, Opcode_219, Opcode_220, Opcode_223, Opcode_224, Opcode_247
    XREF Opcode_225, Opcode_226, Opcode_227, Opcode_228, Opcode_229, Opcode_231, Opcode_232, Opcode_233, Opcode_239
    XREF Opcode_234, Opcode_235, Opcode_236, Opcode_240, Opcode_241, Opcode_242, Opcode_244, Opcode_245
    XREF Opcode_248, Opcode_250, Opcode_251, Opcode_252, Opcode_243

    XREF Opcode_233_index, Opcode_229_index, Opcode_225_index, Opcode_227_index

    ; Routines defined in 'arithlog.asm':
    XREF Opcode_3, Opcode_4, Opcode_5, Opcode_7, Opcode_9, Opcode_11, Opcode_12, Opcode_13
    XREF Opcode_15, Opcode_19, Opcode_20, Opcode_21, Opcode_23, Opcode_25, Opcode_27, Opcode_28
    XREF Opcode_29, Opcode_31, Opcode_35, Opcode_36, Opcode_37, Opcode_39, Opcode_41, Opcode_43
    XREF Opcode_44, Opcode_45, Opcode_47, Opcode_51, Opcode_52, Opcode_53, Opcode_55, Opcode_57
    XREF Opcode_59, Opcode_60, Opcode_61, Opcode_63, Opcode_128, Opcode_129, Opcode_130, Opcode_131, Opcode_132
    XREF Opcode_133, Opcode_134, Opcode_135, Opcode_136, Opcode_137, Opcode_138, Opcode_139, Opcode_140
    XREF Opcode_141, Opcode_142, Opcode_143, Opcode_144, Opcode_145, Opcode_146, Opcode_147, Opcode_148
    XREF Opcode_149, Opcode_150, Opcode_151, Opcode_152, Opcode_153, Opcode_154, Opcode_155, Opcode_156
    XREF Opcode_157, Opcode_158, Opcode_159, Opcode_160, Opcode_161, Opcode_162, Opcode_163, Opcode_164
    XREF Opcode_165, Opcode_166, Opcode_167, Opcode_168, Opcode_169, Opcode_170, Opcode_171
    XREF Opcode_172, Opcode_173, Opcode_174, Opcode_175, Opcode_176, Opcode_177, Opcode_178, Opcode_179
    XREF Opcode_180, Opcode_181, Opcode_182, Opcode_183, Opcode_184, Opcode_185, Opcode_186, Opcode_187
    XREF Opcode_188, Opcode_189, Opcode_190, Opcode_191, Opcode_198, Opcode_206, Opcode_214, Opcode_222
    XREF Opcode_230, Opcode_238, Opcode_246, Opcode_254

    XREF Opcode_134_index, Opcode_142_index, Opcode_150_index, Opcode_158_index, Opcode_166_index
    XREF Opcode_174_index, Opcode_182_index, Opcode_190_index, Opcode_52_index, Opcode_53_index
    XREF Opcode_35_index, Opcode_43_index, Opcode_9_index, Opcode_25_index, Opcode_41_index
    XREF Opcode_57_index


    ; Routines defined in 'cbinstr.asm':
    XREF Bitcode_0, Bitcode_1, Bitcode_2, Bitcode_3, Bitcode_4, Bitcode_5, Bitcode_6, Bitcode_7
    XREF Bitcode_8, Bitcode_9, Bitcode_10, Bitcode_11, Bitcode_12, Bitcode_13, Bitcode_14, Bitcode_15
    XREF Bitcode_16, Bitcode_17, Bitcode_18, Bitcode_19, Bitcode_20, Bitcode_21, Bitcode_22, Bitcode_23
    XREF Bitcode_24, Bitcode_25, Bitcode_26, Bitcode_27, Bitcode_28, Bitcode_29, Bitcode_30, Bitcode_31
    XREF Bitcode_32, Bitcode_33, Bitcode_34, Bitcode_35, Bitcode_36, Bitcode_37, Bitcode_38, Bitcode_39
    XREF Bitcode_40, Bitcode_41, Bitcode_42, Bitcode_43, Bitcode_44, Bitcode_45, Bitcode_46, Bitcode_47
    XREF Bitcode_56, Bitcode_57, Bitcode_58, Bitcode_59, Bitcode_60, Bitcode_61, Bitcode_62, Bitcode_63
    XREF Bitcode_64, Bitcode_65, Bitcode_66, Bitcode_67, Bitcode_68, Bitcode_69, Bitcode_70, Bitcode_71
    XREF Bitcode_72, Bitcode_73, Bitcode_74, Bitcode_75, Bitcode_76, Bitcode_77, Bitcode_78, Bitcode_79
    XREF Bitcode_80, Bitcode_81, Bitcode_82, Bitcode_83, Bitcode_84, Bitcode_85, Bitcode_86, Bitcode_87
    XREF Bitcode_88, Bitcode_89, Bitcode_90, Bitcode_91, Bitcode_92, Bitcode_93, Bitcode_94, Bitcode_95
    XREF Bitcode_96, Bitcode_97, Bitcode_98, Bitcode_99, Bitcode_100, Bitcode_101, Bitcode_102, Bitcode_103
    XREF Bitcode_104, Bitcode_105, Bitcode_106, Bitcode_107, Bitcode_108, Bitcode_109, Bitcode_110, Bitcode_111
    XREF Bitcode_112, Bitcode_113, Bitcode_114, Bitcode_115, Bitcode_116, Bitcode_117, Bitcode_118, Bitcode_119
    XREF Bitcode_120, Bitcode_121, Bitcode_122, Bitcode_123, Bitcode_124, Bitcode_125, Bitcode_126, Bitcode_127
    XREF Bitcode_128, Bitcode_129, Bitcode_130, Bitcode_131, Bitcode_132, Bitcode_133, Bitcode_134, Bitcode_135
    XREF Bitcode_136, Bitcode_137, Bitcode_138, Bitcode_139, Bitcode_140, Bitcode_141, Bitcode_142, Bitcode_143
    XREF Bitcode_144, Bitcode_145, Bitcode_146, Bitcode_147, Bitcode_148, Bitcode_149, Bitcode_150, Bitcode_151
    XREF Bitcode_152, Bitcode_153, Bitcode_154, Bitcode_155, Bitcode_156, Bitcode_157, Bitcode_158, Bitcode_159
    XREF Bitcode_160, Bitcode_161, Bitcode_162, Bitcode_163, Bitcode_164, Bitcode_165, Bitcode_166, Bitcode_167
    XREF Bitcode_168, Bitcode_169, Bitcode_170, Bitcode_171, Bitcode_172, Bitcode_173, Bitcode_174, Bitcode_175
    XREF Bitcode_176, Bitcode_177, Bitcode_178, Bitcode_179, Bitcode_180, Bitcode_181, Bitcode_182, Bitcode_183
    XREF Bitcode_184, Bitcode_185, Bitcode_186, Bitcode_187, Bitcode_188, Bitcode_189, Bitcode_190, Bitcode_191
    XREF Bitcode_192, Bitcode_193, Bitcode_194, Bitcode_195, Bitcode_196, Bitcode_197, Bitcode_198, Bitcode_199
    XREF Bitcode_200, Bitcode_201, Bitcode_202, Bitcode_203, Bitcode_204, Bitcode_205, Bitcode_206, Bitcode_207
    XREF Bitcode_208, Bitcode_209, Bitcode_210, Bitcode_211, Bitcode_212, Bitcode_213, Bitcode_214, Bitcode_215
    XREF Bitcode_216, Bitcode_217, Bitcode_218, Bitcode_219, Bitcode_220, Bitcode_221, Bitcode_222, Bitcode_223
    XREF Bitcode_224, Bitcode_225, Bitcode_226, Bitcode_227, Bitcode_228, Bitcode_229, Bitcode_230, Bitcode_231
    XREF Bitcode_232, Bitcode_233, Bitcode_234, Bitcode_235, Bitcode_236, Bitcode_237, Bitcode_238, Bitcode_239
    XREF Bitcode_240, Bitcode_241, Bitcode_242, Bitcode_243, Bitcode_244, Bitcode_245, Bitcode_246, Bitcode_247
    XREF Bitcode_248, Bitcode_249, Bitcode_250, Bitcode_251, Bitcode_252, Bitcode_253, Bitcode_254, Bitcode_255

    XREF bitcode_6_index, bitcode_14_index, bitcode_22_index, bitcode_30_index, bitcode_38_index, bitcode_46_index
    XREF bitcode_62_index, bitcode_70_index, bitcode_78_index, bitcode_86_index, bitcode_94_index, bitcode_102_index
    XREF bitcode_110_index, bitcode_118_index, bitcode_126_index, bitcode_134_index, bitcode_142_index
    XREF bitcode_150_index, bitcode_158_index, bitcode_166_index, bitcode_174_index, bitcode_182_index
    XREF bitcode_190_index, bitcode_198_index, bitcode_206_index, bitcode_214_index, bitcode_222_index
    XREF bitcode_230_index, bitcode_238_index, bitcode_246_index, bitcode_254_index


    ; Routines defined in 'edinstr.asm':
    XREF EDcode_64, EDcode_65, EDcode_66, EDcode_67, EDcode_68, EDcode_69, EDcode_70, EDcode_71, EDcode_72, EDcode_73
    XREF EDcode_74, EDcode_75
    XREF EDcode_77
    XREF EDcode_79, EDcode_80, EDcode_81, EDcode_82, EDcode_83
    XREF EDcode_86, EDcode_87, EDcode_88, EDcode_89, EDcode_90, EDcode_91
    XREF EDcode_94, EDcode_95, EDcode_96, EDcode_97, EDcode_98
    XREF EDcode_103, EDcode_104, EDcode_105, EDcode_106
    XREF EDcode_111, EDcode_112
    XREF EDcode_114, EDcode_115
    XREF EDcode_120, EDcode_121, EDcode_122, EDcode_123
    XREF EDcode_160, EDcode_161, EDcode_162, EDcode_163
    XREF EDcode_168, EDcode_169, EDcode_170, EDcode_171
    XREF EDcode_176, EDcode_177, EDcode_178, EDcode_179
    XREF EDcode_184, EDcode_185, EDcode_186, EDcode_187


    ; Routines accessible from other modules, defined in this module:
    XDEF Command_mode, Breakpoint_found
    XDEF Unknown_instr, Bindout_error

IF SEGMENT2

     ORG Z80dbg_DOR

                    DEFB 0, 0, 0                        ; link to parent
                    DEFB 0, 0, 0                        ; link to brother (no app)
                    DEFB 0, 0, 0
                    DEFB $83                            ; DOR type - application ROM
                    DEFB DOREnd2-DORStart2              ; total length of DOR
.DORStart2          DEFB '@'                            ; Key to info section
                    DEFB InfoEnd2-InfoStart2            ; length of info section
.InfoStart2         DEFW 0                              ; reserved...
                    DEFB 'I'                            ; application key letter
                    DEFB 0                              ; Default contigous RAM size
                    DEFW 0                              ;
                    DEFW 0                              ; Unsafe workspace
                    DEFW Z80dbg_workspace               ; Safe workspace
                    DEFW Z80dbg_entry                   ; Entry point of code in seg. 3
                    DEFB 0                              ; bank binding to segment 0
                    DEFB 0                              ; bank binding to segment 1
                    DEFB 0                              ; bank binding to segment 2
                    DEFB Z80dbg_bank                    ; bank binding to segment 3   (Z80debug)
                    DEFB @00010010                      ; Bad application, one instantiation
                    DEFB @00000011                      ; inverted caps lock on activation
.InfoEnd2           DEFB 'H'                            ; Key to help section
                    DEFB 12                             ; total length of help
                    DEFW Z80dbg_topics
                    DEFB Z80dbg_MTH_bank                ; point to topics (info)
                    DEFW Z80dbg_commands
                    DEFB Z80dbg_MTH_bank                ; pointer to commands (info)
                    DEFW Z80dbg_help
                    DEFB Z80dbg_MTH_bank                ; point to help
                    DEFW tokens_base
                    DEFB tokens_bank                    ; point to token base
                    DEFB 'N'                            ; Key to name section
                    DEFB NameEnd2-NameStart2            ; length of name
.NameStart2         DEFM "Intuition", 0
.NameEnd2           DEFB $FF
.DOREnd2


; ****************************************************************************************************
;
; Intuition Application Entry Point ( after pressing []ZI )
;
.Z80dbg_entry     JP  Z80dbg_init           ; run Intuition application
                  SCF
                  RET                       ; continious RAM remains allocated...

.Z80dbg_init      PUSH IX                   ; preserve pointer to information block
                  LD   IX, -1               ; return system values...
                  LD   A, FA_EOF
                  LD   DE,0
                  CALL_OZ(Os_Frm)
                  LD   B,$40                ; preset top page to $40 for unexpanded Z88
                  JR   NZ, test_toppage
                  LD   B,$C0                ; expanded machine, top page is $C0 for expanded Z88
.test_toppage     POP  IX
                  LD   A,(IX+$02)           ; IX points at information block
                  CP   B                    ; get end page of continious RAM
                  JR   Z, init_Z80debug     ; end page OK, RAM allocated...
.exit_Z80debug    LD   A,$07                ; No Room for Zprom, return to Index
                  CALL_OZ(Os_Bye)           ; Z80debug suicide

.init_Z80debug    LD   HL, -Int_Worksp
                  ADD  HL,SP                ; Base of RTM area
                  LD   SP,HL
                  PUSH HL
                  POP  IY                   ; HL & IY points at base of RTM area
                  PUSH HL                   ; T.O.S. contains start address of Intuition area
ELSE

        INCLUDE "entry.asm"                 ; use normal entry, Intuition was CALL'ed.

ENDIF
                  CALL Init_Intuition
                  CALL Restore_SPAFHLPC     ; virtual AF in AF' & SP,PC in DE',HL'      ** V0.28

; ----------------------------------------   VIRTUAL PROCESSOR   ----------------------------------
; Monitor loop is entered with main set active...
.monitor_loop     LD   A,(IY + Flagstat2)         ; get RTM flags...                           ** V0.17
                  BIT  Flg_RTM_Kesc, A            ;                                            ** V0.17/V0.28
                  CALL NZ, Keyboard_interrupt     ; <LSH><DIAMOND> pressed?                    ** V0.17/V0.28

                  AND 2**Flg_RTM_Breakp | 2**Flg_RTM_error | 2**Flg_RTM_BpInst | 2**Flg_RTM_Trace | 2**Flg_RTM_DZ
                  CALL NZ, Check_RTMflags         ; An RTM flag indicates a runtime action     ** V1.04

; decode instruction at (PC). The following registers are used by the virtual processor:
;         A  :      1. Opcode of new instruction
;     BCDEHL :      Buffer / work registers.
;         IY :      Base of Intuition work area. Initialised at startup. Never changed.
;         AF':      The Virtual AF register (Accumulator and Flag register).              ** V0.23
;         BC':      The Virtual HL register                                               ** V1.1.1
;         DE':      The Virtual Stack Pointer (SP).                                       ** V0.23
;         HL':      The Virtual Program Counter (PC).                                     ** V0.16

.decode_instr     EXX                       ; Main instruction decode to be fetched at (PC)
                  LD   A,(HL)               ; get 1. opcode at (PC)
                  INC  HL                   ; point at next byte to be fetched
                  EXX                       ; Use main register set...                    ** V0.19
                  LD   H,MainInstrTable/256 ; Main v.p. instruction subroutine table      ** V0.19/V0.27e/V0.28
                  LD   L,A                  ;                                             ** V0.27e
                  LD   E,(HL)               ; get low byte of subroutine address          ** V0.24b
                  INC  H                    ; point at high byte subroutine address       ** V0.24b
                  LD   D,(HL)               ; fetch high byte subroutine address          ** V0.24b
                  EX   DE,HL                ;                                             ** V0.28
                  LD   BC, monitor_loop     ; address of return from virtual instruction
                  PUSH BC                   ; subroutine - continue in monitor loop...
                  JP   (HL)                 ; call instruction                            ** V0.28


; ------------------------------------------------------------------------------------------------
; 1. byte of instruction with $ED opcode arrive here, the $ED instruction set..
;
.ED_instr         EXX
                  LD   A,(HL)               ; extended instructions, get 2. opcode        ** V1.01
                  INC  HL                   ; PC ready for next byte fetch...             ** V1.01
                  EXX                       ; Use main register set...                    ** V1.01
                  LD   H, EDinstrTable/256  ; Extended instruction subroutine table       ** V1.01
                  LD   L,A                  ; get low byte of subroutine address          ** V1.01
                  LD   E,(HL)               ; get low byte of subroutine address          ** V1.01
                  INC  H                    ; point at high byte subroutine address       ** V1.01
                  LD   D,(HL)               ; fetch high byte subroutine address          ** V1.01
                  EX   DE,HL                ;                                             ** V1.01
                  JP   (HL)                 ; call instruction                            ** V1.01


; ------------------------------------------------------------------------------------------------
; 1. byte of instruction with $CB opcode arrive here, the bit manipulation instruction decoding
;
.CB_instr         EXX                       ;                                             ** V1.2
                  LD   A,(HL)               ; bit manipulation, get 2. opcode
                  INC  HL                   ; PC ready for next byte fetch...
                  EXX                       ; Use main register set...                    ** V0.19
                  POP  BC                   ; remove RET to monitor loop                  ** V1.2
                  LD   BC,RET_cbinstr       ;                                             ** V0.29
                  PUSH BC                   ;                                             ** V0.29
                  LD   H,BitInstrTable/256  ; Bit instruction subroutine table            ** V0.19/V0.27e
                  LD   L,A                  ; get low byte of subroutine address          ** V0.27e
                  LD   E,(HL)               ; get low byte of subroutine address          ** V0.24b
                  INC  H                    ; point at high byte subroutine address       ** V0.24b
                  LD   D,(HL)               ; fetch high byte subroutine address          ** V0.24b
                  EX   DE,HL                ; address of virtual instruction routine      ** V1.04
                  EX   AF,AF'               ; swap in virtual AF register                 ** V0.29
                  JP   (HL)                 ; call instruction                            ** V1.04
.RET_cbinstr      EX   AF,AF'               ;                                             ** V0.29
                  JR   monitor_loop         ; back to main debugger loop                  ** V0.29


; ------------------------------------------------------------------------------------------------
; 1. byte of instruction with $DD and $FD opcodes arrive here, the IX & IY instruction decoding
;
.Index_instr
                  LD   B,A                  ; remember 1. opcode (221 or 253)             ** V1.2
                  EXX                       ;                                             ** V1.2
                  LD   A,(HL)               ; get 2. opcode of index instruction
                  INC  HL                   ; PC++
                  CP   $CB                  ; IX / IY bit instruction?
                  JR   NZ, main_index_instr ; no, but standard IX / IY instruction

                  LD   A,(HL)               ; Index Bit instructions, displacement        ** V1.1.1
                  LD   (IY+ExecBuffer),A    ; store the displacement for later use (HACK!)** V1.1.1
                  INC  HL                   ; PC++
                  LD   A,(HL)               ; 2. opcode for $CB instruction (at 4. byte)  ** V0.17
                  INC  HL                   ; Index $CB instr. uses 4 byte opcode.        ** V0.17
                  EXX                       ; Use main register set...                    ** V0.19
                  LD   H, IndexBitInstrTable/256  ; Index Bit instruction subr. table     ** V1.04
                  LD   L,A                  ; get low byte of subroutine address          ** V0.27e
                  LD   A,B                  ; restore 1. opcode                           ** V1.2
                  POP  BC                   ; remove RET to monitor loop                  ** V1.2
                  LD   BC,RET_cbinstr       ;                                             ** V0.29
                  PUSH BC                   ;                                             ** V0.29
                  LD   E,(HL)               ; get low byte of subroutine address          ** V0.24b
                  INC  H                    ; point at high byte subroutine address       ** V0.24b
                  LD   D,(HL)               ; fetch high byte subroutine address          ** V0.24b
                  EX   DE,HL                ;                                             ** V0.28
                  EX   AF,AF'               ; swap in virtual AF register                 ** V0.29
                  JP   (HL)                 ; call instruction                            ** V0.28

.main_index_instr EXX                       ; Use main register set...                    ** V0.19
                  LD   H, IndexInstrTable/256  ; Main Index instruction subr. table       ** V1.04
                  LD   L,A                  ; get low byte of subroutine address          ** V0.27e
                  LD   A,B                  ; restore 1. opcode                           ** V0.23
                  LD   E,(HL)               ; get low byte of subroutine address          ** V0.24b
                  INC  H                    ; point at high byte subroutine address       ** V0.24b
                  LD   D,(HL)               ; fetch high byte subroutine address          ** V0.24b
                  EX   DE,HL                ;                                             ** V0.28
                  JP   (HL)                 ; call instruction                            ** V0.28


; *****************************************************************************
;
; Routine used in main monitor loop. The subroutine is only called if keyboard
; interrupt mode is enabled.
;
; Read the keyboard and check if <SHIFT><DIAMOND> is pressed.
; IF pressed, the execution of Z80 instructions is stopped and the command
; line is entered.
;
; Register status after return:
;
;       A......./IXIYPC  same
;       .FBCDEHL/....    different
;                                           V0.16
.Keyboard_interrupt
                  LD   H,A                   ; preserve runtime flags (status byte 2)...
                  LD   BC,$BFB2              ; port $B2, keyboard row A14                  ** V0.28
                  IN   A,(C)                 ; scan A15...                                 ** V0.17
                  AND  @01010000             ; <LSH> <DIAMOND> pressed?                    ** V0.26b
                  LD   A,H                   ; restore runtime flags                       ** V0.26b/V1.04
                  RET  NZ                    ; and continue virtual processor              ** V0.26b/V1.04
                  JP   command_mode          ; keyboard break detected, activate command line...                      ** V1.04

                  DEFS $0100 - $PC           ; adjust code to position tables at xx00 address

; *Main* instruction & main Index instruction jump address tables
include "maintable.asm"

; *ED xx* instruction jump address tables
include "edtable.asm"

; *Main index* instruction jump address tables
include "indextable.asm"

; *Bit* instruction & bit Index instruction jump address tables
include "bittable.asm"



; *******************************************************************************
;
.Check_RTMflags   BIT  Flg_RTM_Trace, A           ; Single Step Mode?                          ** V0.26e
                  JR   NZ, command_mode           ;                                            ** V0.26e
                  BIT  Flg_RTM_error, A           ; Run time error?                            ** V0.26e
                  JR   NZ, command_mode           ;                                            ** V0.26e
                  BIT  Flg_RTM_Breakp, A
                  CALL NZ, Check_breakpoint       ; breakpoint search ON                       ** V0.30
                  BIT  Flg_RTM_BpInst, (IY + FlagStat2)                                        ** V0.30
                  CALL NZ, Check_instruction      ; instruction bitpattern search ON...        ** V0.30
                  BIT  Flg_RTM_DZ,(IY + Flagstat2); Dissassemble before execution?             ** V0.17
                  CALL NZ, Disasm                 ; yes...
                  RET


; ****************************************************************************
;
; This subroutine is called an opcode if found that defines undocumented
; Z80 instructions
;
.Unknown_instr    LD   (IY + RTMerror), ERR_unknown_instr
.set_rtm_error    SET  Flg_RTM_error,(IY + FlagStat2)    ; indicate runtime error          ** V1.01
                  RET                                    ; back to monitor_loop            ** V1.01


; ****************************************************************************
;
; This subroutine is called when Intuition is about to be bound out of it's own bank
; by executing code.
;
.Bindout_error    LD   (IY + RTMerror), ERR_bindout
                  SET  Flg_RTM_bindout,(IY + FlagStat2)
                  JR   set_rtm_error


; ******************************************************************************
;
.command_mode     CALL Save_SPAFHLPC
IF INT_SEGM0
                  LD   IX, Command_line
                  CALL ExtRoutine_s01
ELSE
                  CALL Command_line
ENDIF
                  CALL Restore_SPAFHLPC     ;                                           ** V0.28
                  JP   decode_instr         ; and then continue to execute              ** V0.28


; ***********************************************************************************************
;
; Display Register Dump and instruction to be executed at (PC) = (HL')
;
.Disasm
IF !INT_SEGM0
                  CALL Save_SPAFHLPC

                  BIT  Flg_IntWinActv,(IY + FlagStat1) ; Is an Intuition window active? ** V0.24a
                  JR   NZ, continue1_DZ                ; Yes - disassemble...           ** V0.24a
                  CALL SV_appl_window                  ; No - copy application window   ** V0.24a
                  CALL Disp_Monitor_win                ; and activate Intuition window  ** V0.24a
.continue1_DZ     BIT  Flg_DZRegdmp,(IY + FlagStat1)   ; Auto Register Dump active?     ** V0.27b
                  JR   Z,continue2_DZ                  ;                                ** V0.27b
                  CALL Write_CRLF           ; separate prev. dump with a CRLF           ** V0.27b
                  CALL DisplayRegisters     ; First display Register Dump               ** V0.27b
.continue2_DZ
                  CALL DZ_Z80pc             ; Disassemble instruction at (PC)
                  CALL Write_CRLF
                  LD   L,(IY + VP_PC)
                  LD   H,(IY + VP_PC+1)
                  LD   A,(HL)               ; get 1. opcode                             ** V0.24a
                  CP   RST_20H              ; Intuition about to execute RST 20h?       ** V0.24a
                  CALL Z, RST_appl_window   ; Yes, restore application screen           ** V0.24a

                  CALL Restore_SPAFHLPC                ; restore v.p. registers and true SP
                  JP   decode_instr                    ; continue to execute Z80 instructions
ELSE
                  CALL Save_SPAFHLPC

                  BIT  Flg_IntWinActv,(IY + FlagStat1) ; Is an Intuition window active? ** V0.24a
                  JR   NZ, continue1_DZ                ; Yes - disassemble...           ** V0.24a
                  LD   IX, SV_appl_window
                  CALL ExtRoutine_s01                  ; No - copy application window   ** V0.24a
                  LD   IX, Disp_Monitor_win
                  CALL ExtRoutine_s01                  ; and activate Intuition window  ** V0.24a
.continue1_DZ     BIT  Flg_DZRegdmp,(IY + FlagStat1)   ; Auto Register Dump active?     ** V0.27b
                  JR   Z,continue2_DZ                  ;                                ** V0.27b
                  CALL_OZ(Gn_Nln)                      ; separate prev. dump with a CRLF           ** V0.27b
                  LD   IX, DisplayRegisters            ; First display Register Dump    ** V0.27b
                  CALL ExtRoutine_s01
.continue2_DZ
                  LD   IX, DZ_Z80pc                    ; Disassemble instruction at (PC)
                  CALL ExtRoutine_s01
                  CALL_OZ(Gn_Nln)
                  LD   L,(IY + VP_PC)
                  LD   H,(IY + VP_PC+1)
                  LD   A,(HL)               ; get 1. opcode                             ** V0.24a
                  CP   RST_20H              ; Intuition about to execute RST 20h?       ** V0.24a
                  LD   IX, RST_appl_window
                  CALL Z, ExtRoutine_s01    ; Yes, restore application screen           ** V0.24a

                  CALL Restore_SPAFHLPC                ; restore v.p. registers and true SP
                  JP   decode_instr                    ; continue to execute Z80 instructions
ENDIF


; ***************************************************************************************************
;
; Check instruction bit pattern at current virtual processor PC
;
.Check_Instruction
                  EXX
                  PUSH HL                   ; get v.p. PC
                  EXX
                  POP  DE
                  CALL FindInstruction
                  RET  NZ                   ; instruction not found - continue execution
                  JR   breakpoint_found     ; Yes, enter command mode or dump registers ** V0.29

; ***************************************************************************************************
;
; Check breakpoints with current virtual processor PC
;
.Check_Breakpoint EXX                       ; get alternate set with PC register -
                  PUSH HL
                  EXX
                  POP  DE                   ; and get PC into main register set...      ** V0.19
                  CALL FindBreakPoint       ; PC at breakpoint?
                  RET  NZ

; ***************************************************************************************************
;
; Found a breakpoint - either activate command line or dump registers...
;
.Breakpoint_found BIT  Flg_BreakDump,(IY + FlagStat3) ; Dump only registers?            ** V0.29
                  JP   Z, command_mode      ; No - activate command line...             ** V0.29
IF !INT_SEGM0
                  CALL Save_SPAFHLPC
                  BIT  Flg_IntWinActv,(IY + FlagStat1)  ;                               ** V0.29
                  JR   NZ, cmd_dispreg      ; Intuition window already active           ** V0.29
                  CALL SV_appl_window       ; save application screen window            ** V0.29
                  CALL Disp_Monitor_win     ; display Intuition window...               ** V0.29
.cmd_dispreg
                  CALL DisplayRegisters     ; then dump contents of Z80 registers       ** V0.29
                  CALL_OZ(Gn_Nln)
                  CALL Disp_RTM_error       ; display OZ call on Fc = 1 error           ** V0.32
                  CALL DZ_Z80pc
                  CALL_OZ(Gn_Nln)
                  LD   A,(IY + FlagStat2)   ; get runtime flags                         ** V0.29
                  BIT  Flg_RTM_Trace,A      ; Single Step Mode?                         ** V0.29
                  JR   NZ, restore_screen   ; Yes, restore screen                       ** V0.29
                  BIT  Flg_RTM_DZ,A         ; else                                      ** V0.29
                  JR   NZ, no_scr_restore   ; If Auto disassemble, don't restore window ** V0.29
.restore_screen   CALL RST_appl_window      ; restore application screen window         ** V0.29

.no_scr_restore   CALL Restore_SPAFHLPC
                  JP   decode_instr         ; decode and execute breakpoint instruction ** V1.04
ELSE
                  CALL Save_SPAFHLPC
                  BIT  Flg_IntWinActv,(IY + FlagStat1)  ;                               ** V0.29
                  JR   NZ, cmd_dispreg      ; Intuition window already active           ** V0.29
                  LD   IX, SV_appl_window
                  CALL ExtRoutine_s01       ; save application screen window            ** V0.29
                  LD   IX, Disp_Monitor_win
                  CALL ExtRoutine_s01       ; display Intuition window...               ** V0.29
.cmd_dispreg
                  LD   IX, DisplayRegisters ; then dump contents of Z80 registers       ** V0.29
                  CALL ExtRoutine_s01
                  CALL_OZ(Gn_Nln)
                  LD   IX, Disp_RTM_error
                  CALL ExtRoutine_s01       ; display OZ call on Fc = 1 error           ** V0.32
                  LD   IX,DZ_Z80pc          ; Disassemble instruction at (PC)
                  CALL ExtRoutine_s01
                  CALL_OZ(Gn_Nln)           ;                                           ** V0.29
                  LD   A,(IY + FlagStat2)   ; get runtime flags                         ** V0.29
                  BIT  Flg_RTM_Trace,A      ; Single Step Mode?                         ** V0.29
                  JR   NZ, restore_screen   ; Yes, restore screen                       ** V0.29
                  BIT  Flg_RTM_DZ,A         ; else                                      ** V0.29
                  JR   NZ, no_scr_restore   ; If Auto disassemble, don't restore window ** V0.29
.restore_screen   LD   IX, RST_appl_window
                  CALL ExtRoutine_s01       ; restore application screen window         ** V0.29

.no_scr_restore   CALL Restore_SPAFHLPC
                  JP   decode_instr         ; decode and execute breakpoint instruction ** V1.04
ENDIF


; ******************************************************************************
;
.Init_Intuition
IF SEGMENT2
                  PUSH IY
                  POP  HL
                  LD   B, VP_PC+2 - VP_BC
.clear_loop       LD   (HL),0
                  INC  HL
                  DJNZ clear_loop                 ; reset Intuition virtual processor registers

                  XOR  A
                  LD   H,(IX+2)
                  LD   L,A                        ; HL points at RAM top
                  LD   DE, $2000
                  SBC  HL,DE
                  LD   B,H
                  LD   C,L                        ; BC = number of bytes to clear
                  PUSH DE
                  POP  HL
                  LD   (HL),A
                  INC  DE
                  LDIR                            ; reset continous memory in Intuition application

                  LD   B,(IX+2)                   ; get end page of allocated application RAM ** V0.32
                  LD   (IY + RamTopPage),B        ;                                           ** V0.32
                  PUSH IY                         ;                                           ** V1.04
                  POP  HL                         ; Get current application stack pointer     ** V1.04
                  DEC  HL                         ;                                           ** V1.04
                  DEC  HL                         ;                                           ** V1.04
                  LD   (IY + VP_SP),L             ;                                           ** V0.29
                  LD   (IY + VP_SP+1),H           ; Top of Stack                              ** V0.29
                  LD   (IY + VP_PC),0
                  LD   (IY + VP_PC+1),$20         ; PC = $2000
ENDIF
                  XOR  A
                  LD   (IY + BreakPoints),A       ; initialise to no breakpoints...
                  LD   (IY + Cmdlbuffer),A        ; Initialize to no buffer contents           ** V0.31
                  LD   (IY + Cmdlbuffer+1),A      ; Initialize to no buffer contents           ** V0.31
                  LD   (IY + InstrBreakPatt),A    ; instr. bit patt. init. to zero length ** V0.19
                  LD   (IY + IntWinID),'6'        ; set Intuition window ID                   ** V0.26
                  LD   (IY + LogfileNr),255       ; initialise log file number                ** V0.19

                  ; Status byte 1:
                  LD   (IY + Flagstat1), 2**Flg_IntWin       ; Use Intuition window #1

                  ; Status byte 2:
                  LD   (IY + FlagStat2), 2**Flg_RTM_Trace    ; Single Step mode

                  ; Status byte 3:
                  LD   (IY + FlagStat3), 2**Flg_WinMode | 2**Flg_DZopcode ;                   ** V0.26e

                  LD   A, FA_PTR
                  LD   DE,0
                  LD   IX,-1
                  OZ   OS_Frm
                  LD   (IY + OzReleaseVer),C      ; Get a copy of OZ release version
                  RET

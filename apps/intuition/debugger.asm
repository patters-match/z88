
    MODULE Debugger


if MSDOS
     INCLUDE "defs.h"
     INCLUDE "stdio.def"
     IF SEGMENT2
          INCLUDE "..\applic.h"
          INCLUDE "..\MTHdbg.def"
          INCLUDE "fileio.def"
          INCLUDE "director.def"
     ENDIF
endif
if UNIX
     INCLUDE "defs.h"
     INCLUDE "stdio.def"
     IF SEGMENT2
          INCLUDE "../applic.h"
          INCLUDE "../MTHdbg.def"
          INCLUDE "fileio.def"
          INCLUDE "director.def"
     ENDIF
endif

if INT_SEGM0
    XREF ExtRoutine_s01
endif

    XREF DisplayRegisters
    XREF DZ_Z80pc

    ; Routines defined in 'Cmdline_asm':
    XREF Command_line, Disp_RTM_error
    XREF SV_appl_window, RST_appl_window, Disp_monitor_win
    XREF Write_CRLF

    XREF Save_SPAFHLPC, Restore_SPAFHLPC
    XREF FindBreakPoint, FindInstruction


    ; Routines defined in 'LDinstr_asm':
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


    ; Routines defined in 'STDinstr_asm':
    XREF Opcode_0, Opcode_8, Opcode_16, Opcode_24, Opcode_32, Opcode_40, Opcode_48, Opcode_56
    XREF Opcode_192, Opcode_193, Opcode_194, Opcode_195, Opcode_196, Opcode_197, Opcode_200, Opcode_201
    XREF Opcode_202, Opcode_204, Opcode_205, Opcode_208, Opcode_209, Opcode_210, Opcode_211, Opcode_212
    XREF Opcode_213, Opcode_216, Opcode_217, Opcode_218, Opcode_219, Opcode_220, Opcode_223, Opcode_224
    XREF Opcode_225, Opcode_226, Opcode_227, Opcode_228, Opcode_229, Opcode_231, Opcode_232, Opcode_233
    XREF Opcode_234, Opcode_235, Opcode_236, Opcode_240, Opcode_241, Opcode_242, Opcode_244, Opcode_245
    XREF Opcode_248, Opcode_250, Opcode_252

    XREF Opcode_233_index, Opcode_229_index, Opcode_225_index, Opcode_227_index

    ; Routines defined in 'arithLog.asm':
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


    ; Routines defined in 'CBinstr_asm':
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


    ; Routines defined in 'EDinstr_asm':
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
    XDEF Unknown_instr

IF SEGMENT2

     ORG Z80dbg_DOR

                    DEFB 0, 0, 0                        ; link to parent
                    DEFW EasyLink_DOR
                    DEFB EasyLink_bank
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
                    DEFW Z80debug_entry                 ; Entry point of code in seg. 3
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
                    DEFW token_base
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
.Z80debug_entry   JP  Z80debug_init         ; run Intuition application
                  SCF
                  RET                       ; continious RAM remains allocated...

.Z80debug_init    PUSH IX                   ; preserve pointer to information block
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

; **************************************************************************************************
;
; Intuition routine entry for applications that wishes to be monitored CALL here...
;
; original values of registers will be stored in allocated area within reserved
; area for the stack.
; When the Z80Monitor is first called, the Return address will be placed at (SP).
; Now, an area is allocated below the current Stack Pointer, SP.
; After having made a copy of the original registers, and defined the PC from
; the return address, SP is set 2 bytes below the beginning of the reserved area:
; The application PC (the first instruction after the Intuition CALL) is also stored
; at the new stack pointer.
;
; Please note: Z88Monitor will pr. default activate Single Step Mode and
; Screen Protect Mode.
;
;                             High byte, return address      -+
;     Current SP on entry:    Low  byte, return address       |
;                             ...                             |
;     Intuition               ...                             |
;     Reserved area           ...                             |
;                             ...                             |
;                             ...                            -+
;     New Stack Pointer:      <application PC>
;
;
.IntuitionEntry   PUSH IY                   ;                                           ** V0.28
                  PUSH IX                   ;                                           ** V0.28
                  EX   AF,AF'               ;                                           ** V0.28
                  PUSH AF                   ;                                           ** V0.28
                  EX   AF,AF'               ;                                           ** V0.28
                  EXX                       ;                                           ** V0.28
                  PUSH HL                   ;                                           ** V0.28
                  PUSH DE                   ;                                           ** V0.28
                  PUSH BC                   ;                                           ** V0.28
                  EXX                       ;                                           ** V0.28
                  PUSH AF                   ;                                           ** V0.28
                  PUSH HL                   ;                                           ** V0.28
                  PUSH DE                   ;                                           ** V0.28
                  PUSH BC                   ;                                           ** V0.28
                  LD   HL,0
                  ADD  HL,SP
                  LD   DE,20                ;                                           ** V0.28
                  ADD  HL,DE                ; HL points at return address               ** V0.28
                  LD   C,(HL)               ;                                           ** V0.28
                  INC  HL
                  LD   B,(HL)               ; BC = return address (the Intuition PC)    ** V0.28
                  LD   E, Int_Worksp+2      ; now make room for Intuition RTM area      ** V0.28/V0.29
                  SBC  HL,DE                ; and 2 bytes for current PC below RTM
                  LD   SP,HL                ; Set new Application Stack Pointer         ** V0.28
                  LD   D,H                  ;                                           ** V0.28
                  LD   E,L                  ; get a copy of new Top Of Stack (T.O.S.)   ** V0.28
                  LD   (HL),C               ; now at Top of of Stack                    ** V0.20a/V0.29
                  INC  HL                   ; (HL now the new Stack Pointer)            ** V0.20a/V0.29
                  LD   (HL),B               ; return address to application             ** V0.20a/V0.29
                  INC  HL                   ; point at beginning of RTM area            ** V0.29
                  PUSH HL                   ;                                           ** V0.29
                  POP  IY                   ; IY = Base of Intuition Runtime Area
                  LD   (IY + VP_SP),E       ;                                           ** V0.29
                  LD   (IY + VP_SP+1),D     ; New SP installed (Top of Stack)           ** V0.29
                  LD   (IY + VP_PC),C
                  LD   (IY + VP_PC+1),B     ; PC = return address
                  LD   BC,Int_Worksp-20-1
                  ADD  HL,BC                ; HL points at original BC (prev. pushed on stack)
                  LD   C,20                 ;                                           ** V0.28
                  INC  DE                   ;                                           ** V0.29
                  INC  DE                   ; Destination at beginning of RTM           ** V0.29
                  LDIR                      ; copy the registers from (HL) to (DE)...   ** V0.28
                                            ; BC,DE,HL,AF,BC',DE',HL',AF',IX,IY         ** V0.28
ENDIF
                  CALL Init_Intuition
                  CALL Restore_SPAFHLPC     ; virtual AF in AF' & SP,PC in DE',HL'      ** V0.28

; ----------------------------------------   VIRTUAL PROCESSOR   ----------------------------------
; Monitor loop is entered with main set active...
.monitor_loop     LD   A,(IY + Flagstat2)         ; get RTM flags...                           ** V0.17
                  BIT  Flg_RTM_Kesc, A            ;                                            ** V0.17/V0.28
                  CALL NZ, Keyboard_interrupt     ; <LSH><DIAMOND> pressed?                    ** V0.17/V0.28

                  AND 2^Flg_RTM_Breakp | 2^Flg_RTM_error | 2^Flg_RTM_BpInst | 2^Flg_RTM_Trace | 2^Flg_RTM_DZ
                  CALL NZ, Check_RTMflags         ; An RTM flag indicates a runtime action     ** V1.04

; decode instruction at (PC). The following registers are used by the virtual processor:
;         A  :      1. Opcode of new instruction
;     BCDEHL :      Buffer / work registers.
;         IX :      The Virtual HL register                                               ** V1.04
;         IY :      Base of Intuition work area. Initialised at startup. Never changed.
;         AF':      The Virtual AF register (Accumulator and Flag register).              ** V0.23
;         B' :      Displacement in IX/IY instructions / work register.                   ** V0.23
;         C' :      Work register.                                                        ** V0.27e
;         DE':      The Virtual Stack Pointer.                                            ** V0.23
;         HL':      The Virtual Program Counter (PC).                                     ** V0.16

.decode_instr     EXX                       ; Now decode the instruction to be fetched at (PC)
                  LD   A,(HL)               ; get 1. opcode at (PC)
                  INC  HL                   ; point at next byte to be fetched
                  CP   $DD                  ; is it an IX instruction?
                  JR   Z, Index_instr       ; Yes...
                  CP   $FD                  ; is it an IY instruction?
                  JR   Z, Index_instr       ; Yes...
                  CP   $CB                  ; is it a bit manipulation instruction?
                  JR   Z, CB_instr          ; Yes...
                  CP   $ED                  ; use lookup table for ED instruction
                  JR   Z, ED_instr          ; when Intuition resides in segment 1 or 2
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

.CB_instr         LD   A,(HL)               ; bit manipulation, get 2. opcode
                  INC  HL                   ; PC ready for next byte fetch...
                  EXX                       ; Use main register set...                    ** V0.19
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

.ED_instr         LD   A,(HL)               ; extended instructions, get 2. opcode        ** V1.01
                  INC  HL                   ; PC ready for next byte fetch...             ** V1.01
                  EXX                       ; Use main register set...                    ** V1.01
                  LD   H, EDinstrTable/256  ; Extended instruction subroutine table       ** V1.01
                  LD   L,A                  ; get low byte of subroutine address          ** V1.01
                  LD   E,(HL)               ; get low byte of subroutine address          ** V1.01
                  INC  H                    ; point at high byte subroutine address       ** V1.01
                  LD   D,(HL)               ; fetch high byte subroutine address          ** V1.01
                  EX   DE,HL                ;                                             ** V1.01
                  LD   BC, monitor_loop     ; address of return from virtual instruction
                  PUSH BC                   ; subroutine - continue in monitor loop...
                  JP   (HL)                 ; call instruction                            ** V1.01

; IX & IY variations...
.Index_instr      PUSH AF                   ; remember 1. opcode (221 or 253)
                  LD   A,(HL)               ; get 2. opcode
                  INC  HL                   ; PC++
                  CP   $CB                  ; IX / IY bit instruction?
                  JR   NZ, main_index_instr ; no, but standard IX / IY instruction
                  PUSH AF                   ;                                             ** V1.1.1
                  LD   A,(HL)               ; Index Bit instructions, displacement        ** V1.1.1
                  LD   (IY+ExecBuffer),A    ; store the displacement for later use (HACK!)** V1.1.1
                  POP  AF                   ;                                             ** V1.1.1
                  INC  HL                   ; PC++
                  LD   A,(HL)               ; 2. opcode for $CB instruction (at 4. byte)  ** V0.17
                  INC  HL                   ; Index $CB instr. uses 4 byte opcode.        ** V0.17
                  EXX                       ; Use main register set...                    ** V0.19
                  LD   H, IndexBitInstrTable/256  ; Index Bit instruction subr. table     ** V1.04
                  LD   L,A                  ; get low byte of subroutine address          ** V0.27e
                  POP  AF                   ; restore 1. opcode                           ** V0.23
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
                  POP  AF                   ; restore 1. opcode                           ** V0.23
                  LD   E,(HL)               ; get low byte of subroutine address          ** V0.24b
                  INC  H                    ; point at high byte subroutine address       ** V0.24b
                  LD   D,(HL)               ; fetch high byte subroutine address          ** V0.24b
                  EX   DE,HL                ;                                             ** V0.28
                  LD   BC, monitor_loop     ; address of return from virtual instruction
                  PUSH BC                   ; subroutine - continue in monitor loop...
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


; ******************************************************************************
;
;    Main (8080 compatible) Virtual Z80 instruction routine lookup table, low byte address
;
.MainInstrTable   DEFB Opcode_0  % 256      ; NOP
                  DEFB Opcode_1  % 256      ; LD   BC, nn
                  DEFB Opcode_2  % 256      ; LD   (BC),A
                  DEFB Opcode_3  % 256      ; INC  BC
                  DEFB Opcode_4  % 256      ; INC  B
                  DEFB Opcode_5  % 256      ; DEC  B
                  DEFB Opcode_6  % 256      ; LD   B, n
                  DEFB Opcode_7  % 256      ; RLCA
                  DEFB Opcode_8  % 256      ; EX   AF, AF'
                  DEFB Opcode_9  % 256      ; ADD  HL,BC
                  DEFB Opcode_10 % 256      ; LD   A,(BC)
                  DEFB Opcode_11 % 256      ; DEC  BC
                  DEFB Opcode_12 % 256      ; INC  C
                  DEFB Opcode_13 % 256      ; DEC  C
                  DEFB Opcode_14 % 256      ; LD   C, n
                  DEFB Opcode_15 % 256      ; RRCA
                  DEFB Opcode_16 % 256      ; DJNZ,n
                  DEFB Opcode_17 % 256      ; LD   DE, nn
                  DEFB Opcode_18 % 256      ; LD   (DE),A
                  DEFB Opcode_19 % 256      ; INC  DE
                  DEFB Opcode_20 % 256      ; INC  D
                  DEFB Opcode_21 % 256      ; DEC  D
                  DEFB Opcode_22 % 256      ; LD   D, n
                  DEFB Opcode_23 % 256      ; RLA
                  DEFB Opcode_24 % 256      ; JR   n
                  DEFB Opcode_25 % 256      ; ADD  HL, DE
                  DEFB Opcode_26 % 256      ; LD   A,(DE)
                  DEFB Opcode_27 % 256      ; DEC  DE
                  DEFB Opcode_28 % 256      ; INC  E
                  DEFB Opcode_29 % 256      ; DEC  E
                  DEFB Opcode_30 % 256      ; LD   E, n
                  DEFB Opcode_31 % 256      ; RRA
                  DEFB Opcode_32 % 256      ; JR   NZ, n
                  DEFB Opcode_33 % 256      ; LD   HL, nn
                  DEFB Opcode_34 % 256      ; LD   (nn),HL
                  DEFB Opcode_35 % 256      ; INC  HL
                  DEFB Opcode_36 % 256      ; INC  H
                  DEFB Opcode_37 % 256      ; DEC  H
                  DEFB Opcode_38 % 256      ; LD   H, n
                  DEFB Opcode_39 % 256      ; DAA
                  DEFB Opcode_40 % 256      ; JR   Z, n
                  DEFB Opcode_41 % 256      ; ADD  HL,HL
                  DEFB Opcode_42 % 256      ; LD   HL,(nn)
                  DEFB Opcode_43 % 256      ; DEC  HL
                  DEFB Opcode_44 % 256      ; INC  L
                  DEFB Opcode_45 % 256      ; DEC  L
                  DEFB Opcode_46 % 256      ; LD   L, n
                  DEFB Opcode_47 % 256      ; CPL
                  DEFB Opcode_48 % 256      ; JR   NC, n
                  DEFB Opcode_49 % 256      ; LD   SP, nn
                  DEFB Opcode_50 % 256      ; LD   (nn),A
                  DEFB Opcode_51 % 256      ; INC  SP
                  DEFB Opcode_52 % 256      ; INC  (HL)
                  DEFB Opcode_53 % 256      ; DEC  (HL)
                  DEFB Opcode_54 % 256      ; LD   (HL), n
                  DEFB Opcode_55 % 256      ; SCF
                  DEFB Opcode_56 % 256      ; JR   C, n
                  DEFB Opcode_57 % 256      ; ADD  HL,SP
                  DEFB Opcode_58 % 256      ; LD   A,(nn)
                  DEFB Opcode_59 % 256      ; DEC  SP
                  DEFB Opcode_60 % 256      ; INC  A
                  DEFB Opcode_61 % 256      ; DEC  A
                  DEFB Opcode_62 % 256      ; LD   A, n
                  DEFB Opcode_63 % 256      ; CCF
                  DEFB Opcode_0  % 256      ; LD   B,B                        ** V0.16
                  DEFB Opcode_65 % 256      ; LD   B,C
                  DEFB Opcode_66 % 256      ; LD   B,D
                  DEFB Opcode_67 % 256      ; LD   B,E
                  DEFB Opcode_68 % 256      ; LD   B,H
                  DEFB Opcode_69 % 256      ; LD   B,L
                  DEFB Opcode_70 % 256      ; LD   B,(HL)
                  DEFB Opcode_71 % 256      ; LD   B,A
                  DEFB Opcode_72 % 256      ; LD   C,B
                  DEFB Opcode_0  % 256      ; LD   C,C                        ** V0.16
                  DEFB Opcode_74 % 256      ; LD   C,D
                  DEFB Opcode_75 % 256      ; LD   C,E
                  DEFB Opcode_76 % 256      ; LD   C,H
                  DEFB Opcode_77 % 256      ; LD   C,L
                  DEFB Opcode_78 % 256      ; LD   C,(HL)
                  DEFB Opcode_79 % 256      ; LD   C,A
                  DEFB Opcode_80 % 256      ; LD   D,B
                  DEFB Opcode_81 % 256      ; LD   D,C
                  DEFB Opcode_0  % 256      ; LD   D,D                        ** V0.16
                  DEFB Opcode_83 % 256      ; LD   D,E
                  DEFB Opcode_84 % 256      ; LD   D,H
                  DEFB Opcode_85 % 256      ; LD   D,L
                  DEFB Opcode_86 % 256      ; LD   D,(HL)
                  DEFB Opcode_87 % 256      ; LD   D,A
                  DEFB Opcode_88 % 256      ; LD   E,B
                  DEFB Opcode_89 % 256      ; LD   E,C
                  DEFB Opcode_90 % 256      ; LD   E,D
                  DEFB Opcode_0  % 256      ; LD   E,E                        ** V0.16
                  DEFB Opcode_92 % 256      ; LD   E,H
                  DEFB Opcode_93 % 256      ; LD   E,L
                  DEFB Opcode_94 % 256      ; LD   E,(HL)
                  DEFB Opcode_95 % 256      ; LD   E,A
                  DEFB Opcode_96 % 256      ; LD   H,B
                  DEFB Opcode_97 % 256      ; LD   H,C
                  DEFB Opcode_98 % 256      ; LD   H,D
                  DEFB Opcode_99 % 256      ; LD   H,E
                  DEFB Opcode_0  % 256      ; LD   H,H                        ** V0.16
                  DEFB Opcode_101 % 256     ; LD   H,L
                  DEFB Opcode_102 % 256     ; LD   H,(HL)
                  DEFB Opcode_103 % 256     ; LD   H,A
                  DEFB Opcode_104 % 256     ; LD   L,B
                  DEFB Opcode_105 % 256     ; LD   L,C
                  DEFB Opcode_106 % 256     ; LD   L,D
                  DEFB Opcode_107 % 256     ; LD   L,E
                  DEFB Opcode_108 % 256     ; LD   L,H
                  DEFB Opcode_0   % 256     ; LD   L,L                        ** V0.16
                  DEFB Opcode_110 % 256     ; LD   L,(HL)
                  DEFB Opcode_111 % 256     ; LD   L,A
                  DEFB Opcode_112 % 256     ; LD   (HL),B
                  DEFB Opcode_113 % 256     ; LD   (HL),C
                  DEFB Opcode_114 % 256     ; LD   (HL),D
                  DEFB Opcode_115 % 256     ; LD   (HL),E
                  DEFB Opcode_116 % 256     ; LD   (HL),H
                  DEFB Opcode_117 % 256     ; LD   (HL),L
                  DEFB Opcode_0   % 256     ; HALT                            ** V0.18
                  DEFB Opcode_119 % 256     ; LD   (HL),A
                  DEFB Opcode_120 % 256     ; LD   A,B
                  DEFB Opcode_121 % 256     ; LD   A,C
                  DEFB Opcode_122 % 256     ; LD   A,D
                  DEFB Opcode_123 % 256     ; LD   A,E
                  DEFB Opcode_124 % 256     ; LD   A,H
                  DEFB Opcode_125 % 256     ; LD   A,L
                  DEFB Opcode_126 % 256     ; LD   A,(HL)
                  DEFB Opcode_0   % 256     ; LD   A,A                        ** V0.16
                  DEFB Opcode_128 % 256     ; ADD  A,B
                  DEFB Opcode_129 % 256     ; ADD  A,C
                  DEFB Opcode_130 % 256     ; ADD  A,D
                  DEFB Opcode_131 % 256     ; ADD  A,E
                  DEFB Opcode_132 % 256     ; ADD  A,H
                  DEFB Opcode_133 % 256     ; ADD  A,L
                  DEFB Opcode_134 % 256     ; ADD  A,(HL)
                  DEFB Opcode_135 % 256     ; ADD  A,A
                  DEFB Opcode_136 % 256     ; ADC  A,B
                  DEFB Opcode_137 % 256     ; ADC  A,C
                  DEFB Opcode_138 % 256     ; ADC  A,D
                  DEFB Opcode_139 % 256     ; ADC  A,E
                  DEFB Opcode_140 % 256     ; ADC  A,H
                  DEFB Opcode_141 % 256     ; ADC  A,L
                  DEFB Opcode_142 % 256     ; ADC  A,(HL)
                  DEFB Opcode_143 % 256     ; ADC  A,A
                  DEFB Opcode_144 % 256     ; SUB  B
                  DEFB Opcode_145 % 256     ; SUB  C
                  DEFB Opcode_146 % 256     ; SUB  D
                  DEFB Opcode_147 % 256     ; SUB  E
                  DEFB Opcode_148 % 256     ; SUB  H
                  DEFB Opcode_149 % 256     ; SUB  L
                  DEFB Opcode_150 % 256     ; SUB  (HL)
                  DEFB Opcode_151 % 256     ; SUB  A
                  DEFB Opcode_152 % 256     ; SBC  A,B
                  DEFB Opcode_153 % 256     ; SBC  A,C
                  DEFB Opcode_154 % 256     ; SBC  A,D
                  DEFB Opcode_155 % 256     ; SBC  A,E
                  DEFB Opcode_156 % 256     ; SBC  A,H
                  DEFB Opcode_157 % 256     ; SBC  A,L
                  DEFB Opcode_158 % 256     ; SBC  A,(HL)
                  DEFB Opcode_159 % 256     ; SBC  A,A
                  DEFB Opcode_160 % 256     ; AND  B
                  DEFB Opcode_161 % 256     ; AND  C
                  DEFB Opcode_162 % 256     ; AND  D
                  DEFB Opcode_163 % 256     ; AND  E
                  DEFB Opcode_164 % 256     ; AND  H
                  DEFB Opcode_165 % 256     ; AND  L
                  DEFB Opcode_166 % 256     ; AND  (HL)
                  DEFB Opcode_167 % 256     ; AND  A
                  DEFB Opcode_168 % 256     ; XOR  B
                  DEFB Opcode_169 % 256     ; XOR  C
                  DEFB Opcode_170 % 256     ; XOR  D
                  DEFB Opcode_171 % 256     ; XOR  E
                  DEFB Opcode_172 % 256     ; XOR  H
                  DEFB Opcode_173 % 256     ; XOR  L
                  DEFB Opcode_174 % 256     ; XOR  (HL)
                  DEFB Opcode_175 % 256     ; XOR  A
                  DEFB Opcode_176 % 256     ; OR   B
                  DEFB Opcode_177 % 256     ; OR   C
                  DEFB Opcode_178 % 256     ; OR   D
                  DEFB Opcode_179 % 256     ; OR   E
                  DEFB Opcode_180 % 256     ; OR   H
                  DEFB Opcode_181 % 256     ; OR   L
                  DEFB Opcode_182 % 256     ; OR   (HL)
                  DEFB Opcode_183 % 256     ; OR   A
                  DEFB Opcode_184 % 256     ; CP   B
                  DEFB Opcode_185 % 256     ; CP   C
                  DEFB Opcode_186 % 256     ; CP   D
                  DEFB Opcode_187 % 256     ; CP   E
                  DEFB Opcode_188 % 256     ; CP   H
                  DEFB Opcode_189 % 256     ; CP   L
                  DEFB Opcode_190 % 256     ; CP   (HL)
                  DEFB Opcode_191 % 256     ; CP   A
                  DEFB Opcode_192 % 256     ; RET  NZ
                  DEFB Opcode_193 % 256     ; POP  BC
                  DEFB Opcode_194 % 256     ; JP   NZ, nn
                  DEFB Opcode_195 % 256     ; JP   nn
                  DEFB Opcode_196 % 256     ; CALL NZ, nn
                  DEFB Opcode_197 % 256     ; PUSH BC
                  DEFB Opcode_198 % 256     ; ADD  A,n
                  DEFB Opcode_0   % 256     ; RST  $00                        ** V0.16
                  DEFB Opcode_200 % 256     ; RET  Z
                  DEFB Opcode_201 % 256     ; RET
                  DEFB Opcode_202 % 256     ; JP   Z, nn
                  DEFB 0                    ; Bit manipulation...
                  DEFB Opcode_204 % 256     ; CALL Z, nn
                  DEFB Opcode_205 % 256     ; CALL nn
                  DEFB Opcode_206 % 256     ; ADC  A, n
                  DEFB Opcode_0   % 256     ; RST  $08                        ** V0.16
                  DEFB Opcode_208 % 256     ; RET  NC
                  DEFB Opcode_209 % 256     ; POP  DE
                  DEFB Opcode_210 % 256     ; JP   NC, nn
                  DEFB Opcode_211 % 256     ; OUT  (n),A
                  DEFB Opcode_212 % 256     ; CALL NC, nn
                  DEFB Opcode_213 % 256     ; PUSH DE
                  DEFB Opcode_214 % 256     ; SUB  n
                  DEFB Opcode_0   % 256     ; RST  $10                        ** V0.16
                  DEFB Opcode_216 % 256     ; RET  C
                  DEFB Opcode_217 % 256     ; EXX
                  DEFB Opcode_218 % 256     ; JP   C, nn
                  DEFB Opcode_219 % 256     ; IN   A,(n)
                  DEFB Opcode_220 % 256     ; CALL C, nn
                  DEFB 0                    ; IX instructions...
                  DEFB Opcode_222 % 256     ; SBC  A, n
                  DEFB Opcode_223 % 256     ; RST  $18
                  DEFB Opcode_224 % 256     ; RET  PO
                  DEFB Opcode_225 % 256     ; POP  HL
                  DEFB Opcode_226 % 256     ; JP   PO, nn
                  DEFB Opcode_227 % 256     ; EX   (SP),HL
                  DEFB Opcode_228 % 256     ; CALL PO, nn
                  DEFB Opcode_229 % 256     ; PUSH HL
                  DEFB Opcode_230 % 256     ; AND  n
                  DEFB Opcode_231 % 256     ; RST  $20
                  DEFB Opcode_232 % 256     ; RET  PE
                  DEFB Opcode_233 % 256     ; JP   (HL)
                  DEFB Opcode_234 % 256     ; JP   PE, nn
                  DEFB Opcode_235 % 256     ; EX   DE,HL
                  DEFB Opcode_236 % 256     ; CALL PE, nn
                  DEFB 0                    ; ED extended instructions
                  DEFB Opcode_238 % 256     ; XOR  n
                  DEFB Opcode_0   % 256     ; RST  $28                        ** V0.16
                  DEFB Opcode_240 % 256     ; RET  P
                  DEFB Opcode_241 % 256     ; POP  AF
                  DEFB Opcode_242 % 256     ; JP   P, nn
                  DEFB Opcode_0   % 256     ; DI                              ** V0.16
                  DEFB Opcode_244 % 256     ; CALL P, nn
                  DEFB Opcode_245 % 256     ; PUSH AF
                  DEFB Opcode_246 % 256     ; OR   n
                  DEFB Opcode_0   % 256     ; RST  $30                        ** V0.16
                  DEFB Opcode_248 % 256     ; RET  M
                  DEFB Opcode_249 % 256     ; LD   SP,HL
                  DEFB Opcode_250 % 256     ; JP   M, nn
                  DEFB Opcode_0   % 256     ; EI                              ** V0.16
                  DEFB Opcode_252 % 256     ; CALL M, nn
                  DEFB 0                    ; IY instructions...
                  DEFB Opcode_254 % 256     ; CP   n
                  DEFB Opcode_0   % 256     ; RST  $38                        ** V0.16


; ******************************************************************************
;
;    Main (8080 compatible) Virtual Z80 instruction routine lookup table, high byte address
;
                  DEFB Opcode_0  / 256      ; NOP
                  DEFB Opcode_1  / 256      ; LD   BC, nn
                  DEFB Opcode_2  / 256      ; LD   (BC),A
                  DEFB Opcode_3  / 256      ; INC  BC
                  DEFB Opcode_4  / 256      ; INC  B
                  DEFB Opcode_5  / 256      ; DEC  B
                  DEFB Opcode_6  / 256      ; LD   B, n
                  DEFB Opcode_7  / 256      ; RLCA
                  DEFB Opcode_8  / 256      ; EX   AF, AF'
                  DEFB Opcode_9  / 256      ; ADD  HL,BC
                  DEFB Opcode_10 / 256      ; LD   A,(BC)
                  DEFB Opcode_11 / 256      ; DEC  BC
                  DEFB Opcode_12 / 256      ; INC  C
                  DEFB Opcode_13 / 256      ; DEC  C
                  DEFB Opcode_14 / 256      ; LD   C, n
                  DEFB Opcode_15 / 256      ; RRCA
                  DEFB Opcode_16 / 256      ; DJNZ,n
                  DEFB Opcode_17 / 256      ; LD   DE, nn
                  DEFB Opcode_18 / 256      ; LD   (DE),A
                  DEFB Opcode_19 / 256      ; INC  DE
                  DEFB Opcode_20 / 256      ; INC  D
                  DEFB Opcode_21 / 256      ; DEC  D
                  DEFB Opcode_22 / 256      ; LD   D, n
                  DEFB Opcode_23 / 256      ; RLA
                  DEFB Opcode_24 / 256      ; JR   n
                  DEFB Opcode_25 / 256      ; ADD  HL, DE
                  DEFB Opcode_26 / 256      ; LD   A,(DE)
                  DEFB Opcode_27 / 256      ; DEC  DE
                  DEFB Opcode_28 / 256      ; INC  E
                  DEFB Opcode_29 / 256      ; DEC  E
                  DEFB Opcode_30 / 256      ; LD   E, n
                  DEFB Opcode_31 / 256      ; RRA
                  DEFB Opcode_32 / 256      ; JR   NZ, n
                  DEFB Opcode_33 / 256      ; LD   HL, nn
                  DEFB Opcode_34 / 256      ; LD   (nn),HL
                  DEFB Opcode_35 / 256      ; INC  HL
                  DEFB Opcode_36 / 256      ; INC  H
                  DEFB Opcode_37 / 256      ; DEC  H
                  DEFB Opcode_38 / 256      ; LD   H, n
                  DEFB Opcode_39 / 256      ; DAA
                  DEFB Opcode_40 / 256      ; JR   Z, n
                  DEFB Opcode_41 / 256      ; ADD  HL,HL
                  DEFB Opcode_42 / 256      ; LD   HL,(nn)
                  DEFB Opcode_43 / 256      ; DEC  HL
                  DEFB Opcode_44 / 256      ; INC  L
                  DEFB Opcode_45 / 256      ; DEC  L
                  DEFB Opcode_46 / 256      ; LD   L, n
                  DEFB Opcode_47 / 256      ; CPL
                  DEFB Opcode_48 / 256      ; JR   NC, n
                  DEFB Opcode_49 / 256      ; LD   SP, nn
                  DEFB Opcode_50 / 256      ; LD   (nn),A
                  DEFB Opcode_51 / 256      ; INC  SP
                  DEFB Opcode_52 / 256      ; INC  (HL)
                  DEFB Opcode_53 / 256      ; DEC  (HL)
                  DEFB Opcode_54 / 256      ; LD   (HL), n
                  DEFB Opcode_55 / 256      ; SCF
                  DEFB Opcode_56 / 256      ; JR   C, n
                  DEFB Opcode_57 / 256      ; ADD  HL,SP
                  DEFB Opcode_58 / 256      ; LD   A,(nn)
                  DEFB Opcode_59 / 256      ; DEC  SP
                  DEFB Opcode_60 / 256      ; INC  A
                  DEFB Opcode_61 / 256      ; DEC  A
                  DEFB Opcode_62 / 256      ; LD   A, n
                  DEFB Opcode_63 / 256      ; CCF
                  DEFB Opcode_0  / 256      ; LD   B,B                        ** V0.16
                  DEFB Opcode_65 / 256      ; LD   B,C
                  DEFB Opcode_66 / 256      ; LD   B,D
                  DEFB Opcode_67 / 256      ; LD   B,E
                  DEFB Opcode_68 / 256      ; LD   B,H
                  DEFB Opcode_69 / 256      ; LD   B,L
                  DEFB Opcode_70 / 256      ; LD   B,(HL)
                  DEFB Opcode_71 / 256      ; LD   B,A
                  DEFB Opcode_72 / 256      ; LD   C,B
                  DEFB Opcode_0  / 256      ; LD   C,C                        ** V0.16
                  DEFB Opcode_74 / 256      ; LD   C,D
                  DEFB Opcode_75 / 256      ; LD   C,E
                  DEFB Opcode_76 / 256      ; LD   C,H
                  DEFB Opcode_77 / 256      ; LD   C,L
                  DEFB Opcode_78 / 256      ; LD   C,(HL)
                  DEFB Opcode_79 / 256      ; LD   C,A
                  DEFB Opcode_80 / 256      ; LD   D,B
                  DEFB Opcode_81 / 256      ; LD   D,C
                  DEFB Opcode_0  / 256      ; LD   D,D                        ** V0.16
                  DEFB Opcode_83 / 256      ; LD   D,E
                  DEFB Opcode_84 / 256      ; LD   D,H
                  DEFB Opcode_85 / 256      ; LD   D,L
                  DEFB Opcode_86 / 256      ; LD   D,(HL)
                  DEFB Opcode_87 / 256      ; LD   D,A
                  DEFB Opcode_88 / 256      ; LD   E,B
                  DEFB Opcode_89 / 256      ; LD   E,C
                  DEFB Opcode_90 / 256      ; LD   E,D
                  DEFB Opcode_0  / 256      ; LD   E,E                        ** V0.16
                  DEFB Opcode_92 / 256      ; LD   E,H
                  DEFB Opcode_93 / 256      ; LD   E,L
                  DEFB Opcode_94 / 256      ; LD   E,(HL)
                  DEFB Opcode_95 / 256      ; LD   E,A
                  DEFB Opcode_96 / 256      ; LD   H,B
                  DEFB Opcode_97 / 256      ; LD   H,C
                  DEFB Opcode_98 / 256      ; LD   H,D
                  DEFB Opcode_99 / 256      ; LD   H,E
                  DEFB Opcode_0  / 256      ; LD   H,H                        ** V0.16
                  DEFB Opcode_101 / 256     ; LD   H,L
                  DEFB Opcode_102 / 256     ; LD   H,(HL)
                  DEFB Opcode_103 / 256     ; LD   H,A
                  DEFB Opcode_104 / 256     ; LD   L,B
                  DEFB Opcode_105 / 256     ; LD   L,C
                  DEFB Opcode_106 / 256     ; LD   L,D
                  DEFB Opcode_107 / 256     ; LD   L,E
                  DEFB Opcode_108 / 256     ; LD   L,H
                  DEFB Opcode_0   / 256     ; LD   L,L                        ** V0.16
                  DEFB Opcode_110 / 256     ; LD   L,(HL)
                  DEFB Opcode_111 / 256     ; LD   L,A
                  DEFB Opcode_112 / 256     ; LD   (HL),B
                  DEFB Opcode_113 / 256     ; LD   (HL),C
                  DEFB Opcode_114 / 256     ; LD   (HL),D
                  DEFB Opcode_115 / 256     ; LD   (HL),E
                  DEFB Opcode_116 / 256     ; LD   (HL),H
                  DEFB Opcode_117 / 256     ; LD   (HL),L
                  DEFB Opcode_0   / 256     ; HALT                            ** V0.18
                  DEFB Opcode_119 / 256     ; LD   (HL),A
                  DEFB Opcode_120 / 256     ; LD   A,B
                  DEFB Opcode_121 / 256     ; LD   A,C
                  DEFB Opcode_122 / 256     ; LD   A,D
                  DEFB Opcode_123 / 256     ; LD   A,E
                  DEFB Opcode_124 / 256     ; LD   A,H
                  DEFB Opcode_125 / 256     ; LD   A,L
                  DEFB Opcode_126 / 256     ; LD   A,(HL)
                  DEFB Opcode_0   / 256     ; LD   A,A                        ** V0.16
                  DEFB Opcode_128 / 256     ; ADD  A,B
                  DEFB Opcode_129 / 256     ; ADD  A,C
                  DEFB Opcode_130 / 256     ; ADD  A,D
                  DEFB Opcode_131 / 256     ; ADD  A,E
                  DEFB Opcode_132 / 256     ; ADD  A,H
                  DEFB Opcode_133 / 256     ; ADD  A,L
                  DEFB Opcode_134 / 256     ; ADD  A,(HL)
                  DEFB Opcode_135 / 256     ; ADD  A,A
                  DEFB Opcode_136 / 256     ; ADC  A,B
                  DEFB Opcode_137 / 256     ; ADC  A,C
                  DEFB Opcode_138 / 256     ; ADC  A,D
                  DEFB Opcode_139 / 256     ; ADC  A,E
                  DEFB Opcode_140 / 256     ; ADC  A,H
                  DEFB Opcode_141 / 256     ; ADC  A,L
                  DEFB Opcode_142 / 256     ; ADC  A,(HL)
                  DEFB Opcode_143 / 256     ; ADC  A,A
                  DEFB Opcode_144 / 256     ; SUB  B
                  DEFB Opcode_145 / 256     ; SUB  C
                  DEFB Opcode_146 / 256     ; SUB  D
                  DEFB Opcode_147 / 256     ; SUB  E
                  DEFB Opcode_148 / 256     ; SUB  H
                  DEFB Opcode_149 / 256     ; SUB  L
                  DEFB Opcode_150 / 256     ; SUB  (HL)
                  DEFB Opcode_151 / 256     ; SUB  A
                  DEFB Opcode_152 / 256     ; SBC  A,B
                  DEFB Opcode_153 / 256     ; SBC  A,C
                  DEFB Opcode_154 / 256     ; SBC  A,D
                  DEFB Opcode_155 / 256     ; SBC  A,E
                  DEFB Opcode_156 / 256     ; SBC  A,H
                  DEFB Opcode_157 / 256     ; SBC  A,L
                  DEFB Opcode_158 / 256     ; SBC  A,(HL)
                  DEFB Opcode_159 / 256     ; SBC  A,A
                  DEFB Opcode_160 / 256     ; AND  B
                  DEFB Opcode_161 / 256     ; AND  C
                  DEFB Opcode_162 / 256     ; AND  D
                  DEFB Opcode_163 / 256     ; AND  E
                  DEFB Opcode_164 / 256     ; AND  H
                  DEFB Opcode_165 / 256     ; AND  L
                  DEFB Opcode_166 / 256     ; AND  (HL)
                  DEFB Opcode_167 / 256     ; AND  A
                  DEFB Opcode_168 / 256     ; XOR  B
                  DEFB Opcode_169 / 256     ; XOR  C
                  DEFB Opcode_170 / 256     ; XOR  D
                  DEFB Opcode_171 / 256     ; XOR  E
                  DEFB Opcode_172 / 256     ; XOR  H
                  DEFB Opcode_173 / 256     ; XOR  L
                  DEFB Opcode_174 / 256     ; XOR  (HL)
                  DEFB Opcode_175 / 256     ; XOR  A
                  DEFB Opcode_176 / 256     ; OR   B
                  DEFB Opcode_177 / 256     ; OR   C
                  DEFB Opcode_178 / 256     ; OR   D
                  DEFB Opcode_179 / 256     ; OR   E
                  DEFB Opcode_180 / 256     ; OR   H
                  DEFB Opcode_181 / 256     ; OR   L
                  DEFB Opcode_182 / 256     ; OR   (HL)
                  DEFB Opcode_183 / 256     ; OR   A
                  DEFB Opcode_184 / 256     ; CP   B
                  DEFB Opcode_185 / 256     ; CP   C
                  DEFB Opcode_186 / 256     ; CP   D
                  DEFB Opcode_187 / 256     ; CP   E
                  DEFB Opcode_188 / 256     ; CP   H
                  DEFB Opcode_189 / 256     ; CP   L
                  DEFB Opcode_190 / 256     ; CP   (HL)
                  DEFB Opcode_191 / 256     ; CP   A
                  DEFB Opcode_192 / 256     ; RET  NZ
                  DEFB Opcode_193 / 256     ; POP  BC
                  DEFB Opcode_194 / 256     ; JP   NZ, nn
                  DEFB Opcode_195 / 256     ; JP   nn
                  DEFB Opcode_196 / 256     ; CALL NZ, nn
                  DEFB Opcode_197 / 256     ; PUSH BC
                  DEFB Opcode_198 / 256     ; ADD  A,n
                  DEFB Opcode_0   / 256     ; RST  $00                        ** V0.16
                  DEFB Opcode_200 / 256     ; RET  Z
                  DEFB Opcode_201 / 256     ; RET
                  DEFB Opcode_202 / 256     ; JP   Z, nn
                  DEFB 0                    ; Bit manipulation...
                  DEFB Opcode_204 / 256     ; CALL Z, nn
                  DEFB Opcode_205 / 256     ; CALL nn
                  DEFB Opcode_206 / 256     ; ADC  A, n
                  DEFB Opcode_0   / 256     ; RST  $08                        ** V0.16
                  DEFB Opcode_208 / 256     ; RET  NC
                  DEFB Opcode_209 / 256     ; POP  DE
                  DEFB Opcode_210 / 256     ; JP   NC, nn
                  DEFB Opcode_211 / 256     ; OUT  (n),A
                  DEFB Opcode_212 / 256     ; CALL NC, nn
                  DEFB Opcode_213 / 256     ; PUSH DE
                  DEFB Opcode_214 / 256     ; SUB  n
                  DEFB Opcode_0   / 256     ; RST  $10                        ** V0.16
                  DEFB Opcode_216 / 256     ; RET  C
                  DEFB Opcode_217 / 256     ; EXX
                  DEFB Opcode_218 / 256     ; JP   C, nn
                  DEFB Opcode_219 / 256     ; IN   A,(n)
                  DEFB Opcode_220 / 256     ; CALL C, nn
                  DEFB 0                    ; IX instructions...
                  DEFB Opcode_222 / 256     ; SBC  A, n
                  DEFB Opcode_223 / 256     ; RST  $18
                  DEFB Opcode_224 / 256     ; RET  PO
                  DEFB Opcode_225 / 256     ; POP  HL
                  DEFB Opcode_226 / 256     ; JP   PO, nn
                  DEFB Opcode_227 / 256     ; EX   (SP),HL
                  DEFB Opcode_228 / 256     ; CALL PO, nn
                  DEFB Opcode_229 / 256     ; PUSH HL
                  DEFB Opcode_230 / 256     ; AND  n
                  DEFB Opcode_231 / 256     ; RST  $20
                  DEFB Opcode_232 / 256     ; RET  PE
                  DEFB Opcode_233 / 256     ; JP   (HL)
                  DEFB Opcode_234 / 256     ; JP   PE, nn
                  DEFB Opcode_235 / 256     ; EX   DE,HL
                  DEFB Opcode_236 / 256     ; CALL PE, nn
                  DEFB 0                    ; ED extended instructions
                  DEFB Opcode_238 / 256     ; XOR  n
                  DEFB Opcode_0   / 256     ; RST  $28                        ** V0.16
                  DEFB Opcode_240 / 256     ; RET  P
                  DEFB Opcode_241 / 256     ; POP  AF
                  DEFB Opcode_242 / 256     ; JP   P, nn
                  DEFB Opcode_0   / 256     ; DI                              ** V0.16
                  DEFB Opcode_244 / 256     ; CALL P, nn
                  DEFB Opcode_245 / 256     ; PUSH AF
                  DEFB Opcode_246 / 256     ; OR   n
                  DEFB Opcode_0   / 256     ; RST  $30                        ** V0.16
                  DEFB Opcode_248 / 256     ; RET  M
                  DEFB Opcode_249 / 256     ; LD   SP,HL
                  DEFB Opcode_250 / 256     ; JP   M, nn
                  DEFB Opcode_0   / 256     ; EI                              ** V0.16
                  DEFB Opcode_252 / 256     ; CALL M, nn
                  DEFB 0                    ; IY instructions...
                  DEFB Opcode_254 / 256     ; CP   n
                  DEFB Opcode_0   / 256     ; RST  $38                        ** V0.16


; ******************************************************************************
;
;    Main IX/IY Virtual Z80 instruction routine lookup table, low byte address
;
.IndexInstrTable  DEFB Unknown_instr % 256  ; NOP
                  DEFB Unknown_instr % 256  ; LD   BC, nn
                  DEFB Unknown_instr % 256  ; LD   (BC),A
                  DEFB Unknown_instr % 256  ; INC  BC
                  DEFB Unknown_instr % 256  ; INC  B
                  DEFB Unknown_instr % 256  ; DEC  B
                  DEFB Unknown_instr % 256  ; LD   B, n
                  DEFB Unknown_instr % 256  ; RLCA
                  DEFB Unknown_instr % 256  ; EX   AF, AF'
                  DEFB Opcode_9_index%256   ; ADD  IX/IY,BC
                  DEFB Unknown_instr % 256  ; LD   A,(BC)
                  DEFB Unknown_instr % 256  ; DEC  BC
                  DEFB Unknown_instr % 256  ; INC  C
                  DEFB Unknown_instr % 256  ; DEC  C
                  DEFB Unknown_instr % 256  ; LD   C, n
                  DEFB Unknown_instr % 256  ; RRCA
                  DEFB Unknown_instr % 256  ; DJNZ,n
                  DEFB Unknown_instr % 256  ; LD   DE, nn
                  DEFB Unknown_instr % 256  ; LD   (DE),A
                  DEFB Unknown_instr % 256  ; INC  DE
                  DEFB Unknown_instr % 256  ; INC  D
                  DEFB Unknown_instr % 256  ; DEC  D
                  DEFB Unknown_instr % 256  ; LD   D, n
                  DEFB Unknown_instr % 256  ; RLA
                  DEFB Unknown_instr % 256  ; JR   n
                  DEFB Opcode_25_index%256  ; ADD  IX/IY,DE
                  DEFB Unknown_instr % 256  ; LD   A,(DE)
                  DEFB Unknown_instr % 256  ; DEC  DE
                  DEFB Unknown_instr % 256  ; INC  E
                  DEFB Unknown_instr % 256  ; DEC  E
                  DEFB Unknown_instr % 256  ; LD   E, n
                  DEFB Unknown_instr % 256  ; RRA
                  DEFB Unknown_instr % 256  ; JR   NZ, n
                  DEFB Opcode_33_index%256  ; LD   IX/IY,nn
                  DEFB Opcode_34_index%256  ; LD   (nn),IX/IY
                  DEFB Opcode_35_index%256  ; INC  IX/IY
                  DEFB Unknown_instr % 256  ; INC  IXH/IYH            undocumented
                  DEFB Unknown_instr % 256  ; DEC  IXH/IYH            undocumented
                  DEFB Unknown_instr % 256  ; LD   IXH/IYH, n         undocumented
                  DEFB Unknown_instr % 256  ; DAA
                  DEFB Unknown_instr % 256  ; JR   Z, n
                  DEFB Opcode_41_index%256  ; ADD  IX,IX / IY,IY
                  DEFB Opcode_42_index%256  ; LD   IX/IY,(nn)
                  DEFB Opcode_43_index%256  ; DEC  IX/IY
                  DEFB Unknown_instr % 256  ; INC  IXL/IYL            undocumented
                  DEFB Unknown_instr % 256  ; DEC  IXL/IYL            undocumented
                  DEFB Unknown_instr % 256  ; LD   IXL/IYL, n         undocumented
                  DEFB Unknown_instr % 256  ; CPL
                  DEFB Unknown_instr % 256  ; JR   NC, n
                  DEFB Unknown_instr % 256  ; LD   SP, nn
                  DEFB Unknown_instr % 256  ; LD   (nn),A
                  DEFB Unknown_instr % 256  ; INC  SP
                  DEFB Opcode_52_index%256  ; INC  (IX/IY+d)
                  DEFB Opcode_53_index%256  ; DEC  (IX/IY+d)
                  DEFB Opcode_54_index%256  ; LD   (IX/IY+d),n
                  DEFB Unknown_instr % 256  ; SCF
                  DEFB Unknown_instr % 256  ; JR   C, n
                  DEFB Opcode_57_index%256  ; ADD  IX/IY,SP
                  DEFB Unknown_instr % 256  ; LD   A,(nn)
                  DEFB Unknown_instr % 256  ; DEC  SP
                  DEFB Unknown_instr % 256  ; INC  A
                  DEFB Unknown_instr % 256  ; DEC  A
                  DEFB Unknown_instr % 256  ; LD   A, n
                  DEFB Unknown_instr % 256  ; CCF
                  DEFB Unknown_instr % 256  ; LD   B,B
                  DEFB Unknown_instr % 256  ; LD   B,C
                  DEFB Unknown_instr % 256  ; LD   B,D
                  DEFB Unknown_instr % 256  ; LD   B,E
                  DEFB Unknown_instr % 256  ; LD   B,IXH/IYH          undocumented
                  DEFB Unknown_instr % 256  ; LD   B,IXL/IYL          undocumented
                  DEFB Opcode_70_index%256  ; LD   B,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; LD   B,A
                  DEFB Unknown_instr % 256  ; LD   C,B
                  DEFB Unknown_instr % 256  ; LD   C,C (NOP)
                  DEFB Unknown_instr % 256  ; LD   C,D
                  DEFB Unknown_instr % 256  ; LD   C,E
                  DEFB Unknown_instr % 256  ; LD   C,IXH/IYH          undocumented
                  DEFB Unknown_instr % 256  ; LD   C,IXL/IYL          undocumented
                  DEFB Opcode_78_index%256  ; LD   C,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; LD   C,A
                  DEFB Unknown_instr % 256  ; LD   D,B
                  DEFB Unknown_instr % 256  ; LD   D,C
                  DEFB Unknown_instr % 256  ; LD   D,D
                  DEFB Unknown_instr % 256  ; LD   D,E
                  DEFB Unknown_instr % 256  ; LD   D,IXH/IYH          undocumented
                  DEFB Unknown_instr % 256  ; LD   D,IXL/IYL          undocumented
                  DEFB Opcode_86_index%256  ; LD   D,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; LD   D,A
                  DEFB Unknown_instr % 256  ; LD   E,B
                  DEFB Unknown_instr % 256  ; LD   E,C
                  DEFB Unknown_instr % 256  ; LD   E,D
                  DEFB Unknown_instr % 256  ; LD   E,E (NOP)
                  DEFB Unknown_instr % 256  ; LD   E,IX/IYH           undocumented
                  DEFB Unknown_instr % 256  ; LD   E,IXL/IYL          undocumented
                  DEFB Opcode_94_index%256  ; LD   E,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; LD   E,A
                  DEFB Unknown_instr % 256  ; LD   IXH/IYH,B          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXH/IYH,C          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXH/IYH,D          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXH/IYH,E          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXH,IXH/IYH,IYH    undocumented
                  DEFB Unknown_instr % 256  ; LD   IXH/IYH,IXL/IYL    undocumented
                  DEFB Opcode_102_index%256 ; LD   H,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; LD   IXH/IYH,A          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXL/IYL,B          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXL/IYL,C          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXL/IYL,D          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXL/IYL,E          undocumented
                  DEFB Unknown_instr % 256  ; LD   IXL/IYL,IXH/IYH    undocumented
                  DEFB Unknown_instr % 256  ; LD   IXL,IXL/IYL,IYL    undocumented
                  DEFB Opcode_110_index%256 ; LD   L,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; LD   IXL/IYL,A          undocumented
                  DEFB Opcode_112_index%256 ; LD   (IX/IY+d),B
                  DEFB Opcode_113_index%256 ; LD   (IX/IY+d),C
                  DEFB Opcode_114_index%256 ; LD   (IX/IY+d),D
                  DEFB Opcode_115_index%256 ; LD   (IX/IY+d),E
                  DEFB Opcode_116_index%256 ; LD   (IX/IY+d),H
                  DEFB Opcode_117_index%256 ; LD   (IX/IY+d),L
                  DEFB Unknown_instr % 256  ; HALT
                  DEFB Opcode_119_index%256 ; LD   (IX/IY+d),A
                  DEFB Unknown_instr % 256  ; LD   A,B
                  DEFB Unknown_instr % 256  ; LD   A,C
                  DEFB Unknown_instr % 256  ; LD   A,D
                  DEFB Unknown_instr % 256  ; LD   A,E
                  DEFB Unknown_instr % 256  ; LD   A,IXH/IYH          undocumented
                  DEFB Unknown_instr % 256  ; LD   A,IXL/IYL          undocumented
                  DEFB Opcode_126_index%256 ; LD   A,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; LD   A,A
                  DEFB Unknown_instr % 256  ; ADD  A,B
                  DEFB Unknown_instr % 256  ; ADD  A,C
                  DEFB Unknown_instr % 256  ; ADD  A,D
                  DEFB Unknown_instr % 256  ; ADD  A,E
                  DEFB Unknown_instr % 256  ; ADD  A,IXH/IYH          undocumented
                  DEFB Unknown_instr % 256  ; ADD  A,IXL/IYL          undocumented
                  DEFB Opcode_134_index%256 ; ADD  A,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; ADD  A,A
                  DEFB Unknown_instr % 256  ; ADC  A,B
                  DEFB Unknown_instr % 256  ; ADC  A,C
                  DEFB Unknown_instr % 256  ; ADC  A,D
                  DEFB Unknown_instr % 256  ; ADC  A,E
                  DEFB Unknown_instr % 256  ; ADC  A,IXH/IYH          undocumented
                  DEFB Unknown_instr % 256  ; ADC  A,IXL/IYL          undocumented
                  DEFB Opcode_142_index%256 ; ADC  A,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; ADC  A,A
                  DEFB Unknown_instr % 256  ; SUB  B
                  DEFB Unknown_instr % 256  ; SUB  C
                  DEFB Unknown_instr % 256  ; SUB  D
                  DEFB Unknown_instr % 256  ; SUB  E
                  DEFB Unknown_instr % 256  ; SUB  IXH/IYH            undocumented
                  DEFB Unknown_instr % 256  ; SUB  IXL/IYL            undocumented
                  DEFB Opcode_150_index%256 ; SUB  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; SUB  A
                  DEFB Unknown_instr % 256  ; SBC  A,B
                  DEFB Unknown_instr % 256  ; SBC  A,C
                  DEFB Unknown_instr % 256  ; SBC  A,D
                  DEFB Unknown_instr % 256  ; SBC  A,E
                  DEFB Unknown_instr % 256  ; SBC  A,IXH/IYH          undocumented
                  DEFB Unknown_instr % 256  ; SBC  A,IXL/IYL          undocumented
                  DEFB Opcode_158_index%256 ; SBC  A,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SBC  A,A
                  DEFB Unknown_instr % 256  ; AND  B
                  DEFB Unknown_instr % 256  ; AND  C
                  DEFB Unknown_instr % 256  ; AND  D
                  DEFB Unknown_instr % 256  ; AND  E
                  DEFB Unknown_instr % 256  ; AND  IXH/IYH            undocumented
                  DEFB Unknown_instr % 256  ; AND  IXL/IYL            undocumented
                  DEFB Opcode_166_index%256 ; AND  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; AND  A
                  DEFB Unknown_instr % 256  ; XOR  B
                  DEFB Unknown_instr % 256  ; XOR  C
                  DEFB Unknown_instr % 256  ; XOR  D
                  DEFB Unknown_instr % 256  ; XOR  E
                  DEFB Unknown_instr % 256  ; XOR  IXH/IYH            undocumented
                  DEFB Unknown_instr % 256  ; XOR  IXL/IYL            undocumented
                  DEFB Opcode_174_index%256 ; XOR  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; XOR  A
                  DEFB Unknown_instr % 256  ; OR   B
                  DEFB Unknown_instr % 256  ; OR   C
                  DEFB Unknown_instr % 256  ; OR   D
                  DEFB Unknown_instr % 256  ; OR   E
                  DEFB Unknown_instr % 256  ; OR   IXH/IYH            undocumented
                  DEFB Unknown_instr % 256  ; OR   IXL/IYL            undocumented
                  DEFB Opcode_182_index%256 ; OR   (IX/IY+d)
                  DEFB Unknown_instr % 256  ; OR   A
                  DEFB Unknown_instr % 256  ; CP   B
                  DEFB Unknown_instr % 256  ; CP   C
                  DEFB Unknown_instr % 256  ; CP   D
                  DEFB Unknown_instr % 256  ; CP   E
                  DEFB Unknown_instr % 256  ; CP   IXH/IYH            undocumented
                  DEFB Unknown_instr % 256  ; CP   IXL/IYL            undocumented
                  DEFB Opcode_190_index%256 ; CP   (IX/IY+d)
                  DEFB Unknown_instr % 256  ; CP   A
                  DEFB Unknown_instr % 256  ; RET  NZ
                  DEFB Unknown_instr % 256  ; POP  BC
                  DEFB Unknown_instr % 256  ; JP   NZ, nn
                  DEFB Unknown_instr % 256  ; JP   nn
                  DEFB Unknown_instr % 256  ; CALL NZ, nn
                  DEFB Unknown_instr % 256  ; PUSH BC
                  DEFB Unknown_instr % 256  ; ADD  A,n
                  DEFB Unknown_instr % 256  ; RST  $00
                  DEFB Unknown_instr % 256  ; RET  Z
                  DEFB Unknown_instr % 256  ; RET
                  DEFB Unknown_instr % 256  ; JP   Z, nn
                  DEFB Unknown_instr % 256  ; Bit manipulation IX/IY instructions...
                  DEFB Unknown_instr % 256  ; CALL Z, nn
                  DEFB Unknown_instr % 256  ; CALL nn
                  DEFB Unknown_instr % 256  ; ADC  A, n
                  DEFB Unknown_instr % 256  ; RST  $08
                  DEFB Unknown_instr % 256  ; RET  NC
                  DEFB Unknown_instr % 256  ; POP  DE
                  DEFB Unknown_instr % 256  ; JP   NC, nn
                  DEFB Unknown_instr % 256  ; OUT  (n),A
                  DEFB Unknown_instr % 256  ; CALL NC, nn
                  DEFB Unknown_instr % 256  ; PUSH DE
                  DEFB Unknown_instr % 256  ; SUB  n
                  DEFB Unknown_instr % 256  ; RST  $10
                  DEFB Unknown_instr % 256  ; RET  C
                  DEFB Unknown_instr % 256  ; EXX
                  DEFB Unknown_instr % 256  ; JP   C, nn
                  DEFB Unknown_instr % 256  ; IN   A,(n)
                  DEFB Unknown_instr % 256  ; CALL C, nn
                  DEFB Unknown_instr % 256  ; ???
                  DEFB Unknown_instr % 256  ; SBC  A, n
                  DEFB Unknown_instr % 256  ; RST  $18
                  DEFB Unknown_instr % 256  ; RET  PO
                  DEFB Opcode_225_index%256 ; POP  IX/IY
                  DEFB Unknown_instr % 256  ; JP   PO, nn
                  DEFB Opcode_227_index%256 ; EX   (SP),IX/IY
                  DEFB Unknown_instr % 256  ; CALL PO, nn
                  DEFB Opcode_229_index%256 ; PUSH IX/IY
                  DEFB Unknown_instr % 256  ; AND  n
                  DEFB Unknown_instr % 256  ; RST  $20
                  DEFB Unknown_instr % 256  ; RET  PE
                  DEFB Opcode_233_index%256 ; JP   (IX/IY)
                  DEFB Unknown_instr % 256  ; JP   PE, nn
                  DEFB Unknown_instr % 256  ; EX   DE,HL
                  DEFB Unknown_instr % 256  ; CALL PE, nn
                  DEFB Unknown_instr % 256  ; ???
                  DEFB Unknown_instr % 256  ; XOR  n
                  DEFB Unknown_instr % 256  ; RST  $28
                  DEFB Unknown_instr % 256  ; RET  P
                  DEFB Unknown_instr % 256  ; POP  AF
                  DEFB Unknown_instr % 256  ; JP   P, nn
                  DEFB Unknown_instr % 256  ; DI
                  DEFB Unknown_instr % 256  ; CALL P, nn
                  DEFB Unknown_instr % 256  ; PUSH AF
                  DEFB Unknown_instr % 256  ; OR   n
                  DEFB Unknown_instr % 256  ; RST  $30
                  DEFB Unknown_instr % 256  ; RET  M
                  DEFB Opcode_249_index%256 ; LD   SP,IX/IY
                  DEFB Unknown_instr % 256  ; JP   M, nn
                  DEFB Unknown_instr % 256  ; EI
                  DEFB Unknown_instr % 256  ; CALL M, nn
                  DEFB Unknown_instr % 256  ; ???
                  DEFB Unknown_instr % 256  ; CP   n
                  DEFB Unknown_instr % 256  ; RST  $38

; ******************************************************************************
;
;    Main IX/IY Virtual Z80 instruction routine lookup table, high byte address
;
                  DEFB Unknown_instr / 256  ; NOP
                  DEFB Unknown_instr / 256  ; LD   BC, nn
                  DEFB Unknown_instr / 256  ; LD   (BC),A
                  DEFB Unknown_instr / 256  ; INC  BC
                  DEFB Unknown_instr / 256  ; INC  B
                  DEFB Unknown_instr / 256  ; DEC  B
                  DEFB Unknown_instr / 256  ; LD   B, n
                  DEFB Unknown_instr / 256  ; RLCA
                  DEFB Unknown_instr / 256  ; EX   AF, AF'
                  DEFB Opcode_9_index / 256 ; ADD  IX/IY,BC
                  DEFB Unknown_instr / 256  ; LD   A,(BC)
                  DEFB Unknown_instr / 256  ; DEC  BC
                  DEFB Unknown_instr / 256  ; INC  C
                  DEFB Unknown_instr / 256  ; DEC  C
                  DEFB Unknown_instr / 256  ; LD   C, n
                  DEFB Unknown_instr / 256  ; RRCA
                  DEFB Unknown_instr / 256  ; DJNZ,n
                  DEFB Unknown_instr / 256  ; LD   DE, nn
                  DEFB Unknown_instr / 256  ; LD   (DE),A
                  DEFB Unknown_instr / 256  ; INC  DE
                  DEFB Unknown_instr / 256  ; INC  D
                  DEFB Unknown_instr / 256  ; DEC  D
                  DEFB Unknown_instr / 256  ; LD   D, n
                  DEFB Unknown_instr / 256  ; RLA
                  DEFB Unknown_instr / 256  ; JR   n
                  DEFB Opcode_25_index / 256; ADD  IX/IY,DE
                  DEFB Unknown_instr / 256  ; LD   A,(DE)
                  DEFB Unknown_instr / 256  ; DEC  DE
                  DEFB Unknown_instr / 256  ; INC  E
                  DEFB Unknown_instr / 256  ; DEC  E
                  DEFB Unknown_instr / 256  ; LD   E, n
                  DEFB Unknown_instr / 256  ; RRA
                  DEFB Unknown_instr / 256  ; JR   NZ, n
                  DEFB Opcode_33_index / 256; LD   IX/IY,nn
                  DEFB Opcode_34_index / 256; LD   (nn),IX/IY
                  DEFB Opcode_35_index / 256; INC  IX/IY
                  DEFB Unknown_instr / 256  ; INC  IXH/IYH            undocumented
                  DEFB Unknown_instr / 256  ; DEC  IXH/IYH            undocumented
                  DEFB Unknown_instr / 256  ; LD   IXH/IYH, n         undocumented
                  DEFB Unknown_instr / 256  ; DAA
                  DEFB Unknown_instr / 256  ; JR   Z, n
                  DEFB Opcode_41_index / 256; ADD  IX,IX / IY,IY
                  DEFB Opcode_42_index / 256; LD   IX/IY,(nn)
                  DEFB Opcode_43_index/256  ; DEC  IX/IY
                  DEFB Unknown_instr / 256  ; INC  IXL/IYL            undocumented
                  DEFB Unknown_instr / 256  ; DEC  IXL/IYL            undocumented
                  DEFB Unknown_instr / 256  ; LD   IXL/IYL, n         undocumented
                  DEFB Unknown_instr / 256  ; CPL
                  DEFB Unknown_instr / 256  ; JR   NC, n
                  DEFB Unknown_instr / 256  ; LD   SP, nn
                  DEFB Unknown_instr / 256  ; LD   (nn),A
                  DEFB Unknown_instr / 256  ; INC  SP
                  DEFB Opcode_52_index/256  ; INC  (IX/IY+d)
                  DEFB Opcode_53_index/256  ; DEC  (IX/IY+d)
                  DEFB Opcode_54_index/256  ; LD   (IX/IY+d),n
                  DEFB Unknown_instr / 256  ; SCF
                  DEFB Unknown_instr / 256  ; JR   C, n
                  DEFB Opcode_57_index/256  ; ADD  IX/IY,SP
                  DEFB Unknown_instr / 256  ; LD   A,(nn)
                  DEFB Unknown_instr / 256  ; DEC  SP
                  DEFB Unknown_instr / 256  ; INC  A
                  DEFB Unknown_instr / 256  ; DEC  A
                  DEFB Unknown_instr / 256  ; LD   A, n
                  DEFB Unknown_instr / 256  ; CCF
                  DEFB Unknown_instr / 256  ; LD   B,B
                  DEFB Unknown_instr / 256  ; LD   B,C
                  DEFB Unknown_instr / 256  ; LD   B,D
                  DEFB Unknown_instr / 256  ; LD   B,E
                  DEFB Unknown_instr / 256  ; LD   B,IXH/IYH          undocumented
                  DEFB Unknown_instr / 256  ; LD   B,IXL/IYL          undocumented
                  DEFB Opcode_70_index/256  ; LD   B,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; LD   B,A
                  DEFB Unknown_instr / 256  ; LD   C,B
                  DEFB Unknown_instr / 256  ; LD   C,C (NOP)
                  DEFB Unknown_instr / 256  ; LD   C,D
                  DEFB Unknown_instr / 256  ; LD   C,E
                  DEFB Unknown_instr / 256  ; LD   C,IXH/IYH          undocumented
                  DEFB Unknown_instr / 256  ; LD   C,IXL/IYL          undocumented
                  DEFB Opcode_78_index/256  ; LD   C,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; LD   C,A
                  DEFB Unknown_instr / 256  ; LD   D,B
                  DEFB Unknown_instr / 256  ; LD   D,C
                  DEFB Unknown_instr / 256  ; LD   D,D
                  DEFB Unknown_instr / 256  ; LD   D,E
                  DEFB Unknown_instr / 256  ; LD   D,IXH/IYH          undocumented
                  DEFB Unknown_instr / 256  ; LD   D,IXL/IYL          undocumented
                  DEFB Opcode_86_index/256  ; LD   D,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; LD   D,A
                  DEFB Unknown_instr / 256  ; LD   E,B
                  DEFB Unknown_instr / 256  ; LD   E,C
                  DEFB Unknown_instr / 256  ; LD   E,D
                  DEFB Unknown_instr / 256  ; LD   E,E (NOP)
                  DEFB Unknown_instr / 256  ; LD   E,IX/IYH           undocumented
                  DEFB Unknown_instr / 256  ; LD   E,IXL/IYL          undocumented
                  DEFB Opcode_94_index/256  ; LD   E,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; LD   E,A
                  DEFB Unknown_instr / 256  ; LD   IXH/IYH,B          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXH/IYH,C          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXH/IYH,D          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXH/IYH,E          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXH,IXH/IYH,IYH    undocumented
                  DEFB Unknown_instr / 256  ; LD   IXH/IYH,IXL/IYL    undocumented
                  DEFB Opcode_102_index/256 ; LD   H,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; LD   IXH/IYH,A          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXL/IYL,B          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXL/IYL,C          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXL/IYL,D          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXL/IYL,E          undocumented
                  DEFB Unknown_instr / 256  ; LD   IXL/IYL,IXH/IYH    undocumented
                  DEFB Unknown_instr / 256  ; LD   IXL,IXL/IYL,IYL    undocumented
                  DEFB Opcode_110_index/256 ; LD   L,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; LD   IXL/IYL,A          undocumented
                  DEFB Opcode_112_index/256 ; LD   (IX/IY+d),B
                  DEFB Opcode_113_index/256 ; LD   (IX/IY+d),C
                  DEFB Opcode_114_index/256 ; LD   (IX/IY+d),D
                  DEFB Opcode_115_index/256 ; LD   (IX/IY+d),E
                  DEFB Opcode_116_index/256 ; LD   (IX/IY+d),H
                  DEFB Opcode_117_index/256 ; LD   (IX/IY+d),L
                  DEFB Unknown_instr / 256  ; HALT
                  DEFB Opcode_119_index/256 ; LD   (IX/IY+d),A
                  DEFB Unknown_instr / 256  ; LD   A,B
                  DEFB Unknown_instr / 256  ; LD   A,C
                  DEFB Unknown_instr / 256  ; LD   A,D
                  DEFB Unknown_instr / 256  ; LD   A,E
                  DEFB Unknown_instr / 256  ; LD   A,IXH/IYH          undocumented
                  DEFB Unknown_instr / 256  ; LD   A,IXL/IYL          undocumented
                  DEFB Opcode_126_index/256 ; LD   A,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; LD   A,A
                  DEFB Unknown_instr / 256  ; ADD  A,B
                  DEFB Unknown_instr / 256  ; ADD  A,C
                  DEFB Unknown_instr / 256  ; ADD  A,D
                  DEFB Unknown_instr / 256  ; ADD  A,E
                  DEFB Unknown_instr / 256  ; ADD  A,IXH/IYH          undocumented
                  DEFB Unknown_instr / 256  ; ADD  A,IXL/IYL          undocumented
                  DEFB Opcode_134_index/256 ; ADD  A,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; ADD  A,A
                  DEFB Unknown_instr / 256  ; ADC  A,B
                  DEFB Unknown_instr / 256  ; ADC  A,C
                  DEFB Unknown_instr / 256  ; ADC  A,D
                  DEFB Unknown_instr / 256  ; ADC  A,E
                  DEFB Unknown_instr / 256  ; ADC  A,IXH/IYH          undocumented
                  DEFB Unknown_instr / 256  ; ADC  A,IXL/IYL          undocumented
                  DEFB Opcode_142_index/256 ; ADC  A,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; ADC  A,A
                  DEFB Unknown_instr / 256  ; SUB  B
                  DEFB Unknown_instr / 256  ; SUB  C
                  DEFB Unknown_instr / 256  ; SUB  D
                  DEFB Unknown_instr / 256  ; SUB  E
                  DEFB Unknown_instr / 256  ; SUB  IXH/IYH            undocumented
                  DEFB Unknown_instr / 256  ; SUB  IXL/IYL            undocumented
                  DEFB Opcode_150_index/256 ; SUB  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; SUB  A
                  DEFB Unknown_instr / 256  ; SBC  A,B
                  DEFB Unknown_instr / 256  ; SBC  A,C
                  DEFB Unknown_instr / 256  ; SBC  A,D
                  DEFB Unknown_instr / 256  ; SBC  A,E
                  DEFB Unknown_instr / 256  ; SBC  A,IXH/IYH          undocumented
                  DEFB Unknown_instr / 256  ; SBC  A,IXL/IYL          undocumented
                  DEFB Opcode_158_index/256 ; SBC  A,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SBC  A,A
                  DEFB Unknown_instr / 256  ; AND  B
                  DEFB Unknown_instr / 256  ; AND  C
                  DEFB Unknown_instr / 256  ; AND  D
                  DEFB Unknown_instr / 256  ; AND  E
                  DEFB Unknown_instr / 256  ; AND  IXH/IYH            undocumented
                  DEFB Unknown_instr / 256  ; AND  IXL/IYL            undocumented
                  DEFB Opcode_166_index/256 ; AND  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; AND  A
                  DEFB Unknown_instr / 256  ; XOR  B
                  DEFB Unknown_instr / 256  ; XOR  C
                  DEFB Unknown_instr / 256  ; XOR  D
                  DEFB Unknown_instr / 256  ; XOR  E
                  DEFB Unknown_instr / 256  ; XOR  IXH/IYH            undocumented
                  DEFB Unknown_instr / 256  ; XOR  IXL/IYL            undocumented
                  DEFB Opcode_174_index/256 ; XOR  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; XOR  A
                  DEFB Unknown_instr / 256  ; OR   B
                  DEFB Unknown_instr / 256  ; OR   C
                  DEFB Unknown_instr / 256  ; OR   D
                  DEFB Unknown_instr / 256  ; OR   E
                  DEFB Unknown_instr / 256  ; OR   IXH/IYH            undocumented
                  DEFB Unknown_instr / 256  ; OR   IXL/IYL            undocumented
                  DEFB Opcode_182_index/256 ; OR   (IX/IY+d)
                  DEFB Unknown_instr / 256  ; OR   A
                  DEFB Unknown_instr / 256  ; CP   B
                  DEFB Unknown_instr / 256  ; CP   C
                  DEFB Unknown_instr / 256  ; CP   D
                  DEFB Unknown_instr / 256  ; CP   E
                  DEFB Unknown_instr / 256  ; CP   IXH/IYH            undocumented
                  DEFB Unknown_instr / 256  ; CP   IXL/IYL            undocumented
                  DEFB Opcode_190_index/256 ; CP   (IX/IY+d)
                  DEFB Unknown_instr / 256  ; CP   A
                  DEFB Unknown_instr / 256  ; RET  NZ
                  DEFB Unknown_instr / 256  ; POP  BC
                  DEFB Unknown_instr / 256  ; JP   NZ, nn
                  DEFB Unknown_instr / 256  ; JP   nn
                  DEFB Unknown_instr / 256  ; CALL NZ, nn
                  DEFB Unknown_instr / 256  ; PUSH BC
                  DEFB Unknown_instr / 256  ; ADD  A,n
                  DEFB Unknown_instr / 256  ; RST  $00
                  DEFB Unknown_instr / 256  ; RET  Z
                  DEFB Unknown_instr / 256  ; RET
                  DEFB Unknown_instr / 256  ; JP   Z, nn
                  DEFB Unknown_instr / 256  ; Bit manipulation IX/IY instructions...
                  DEFB Unknown_instr / 256  ; CALL Z, nn
                  DEFB Unknown_instr / 256  ; CALL nn
                  DEFB Unknown_instr / 256  ; ADC  A, n
                  DEFB Unknown_instr / 256  ; RST  $08
                  DEFB Unknown_instr / 256  ; RET  NC
                  DEFB Unknown_instr / 256  ; POP  DE
                  DEFB Unknown_instr / 256  ; JP   NC, nn
                  DEFB Unknown_instr / 256  ; OUT  (n),A
                  DEFB Unknown_instr / 256  ; CALL NC, nn
                  DEFB Unknown_instr / 256  ; PUSH DE
                  DEFB Unknown_instr / 256  ; SUB  n
                  DEFB Unknown_instr / 256  ; RST  $10
                  DEFB Unknown_instr / 256  ; RET  C
                  DEFB Unknown_instr / 256  ; EXX
                  DEFB Unknown_instr / 256  ; JP   C, nn
                  DEFB Unknown_instr / 256  ; IN   A,(n)
                  DEFB Unknown_instr / 256  ; CALL C, nn
                  DEFB Unknown_instr / 256  ; ???
                  DEFB Unknown_instr / 256  ; SBC  A, n
                  DEFB Unknown_instr / 256  ; RST  $18
                  DEFB Unknown_instr / 256  ; RET  PO
                  DEFB Opcode_225_index/256 ; POP  IX/IY
                  DEFB Unknown_instr / 256  ; JP   PO, nn
                  DEFB Opcode_227_index/256 ; EX   (SP),IX/IY
                  DEFB Unknown_instr / 256  ; CALL PO, nn
                  DEFB Opcode_229_index/256 ; PUSH IX/IY
                  DEFB Unknown_instr / 256  ; AND  n
                  DEFB Unknown_instr / 256  ; RST  $20
                  DEFB Unknown_instr / 256  ; RET  PE
                  DEFB Opcode_233_index/256 ; JP   (IX/IY)
                  DEFB Unknown_instr / 256  ; JP   PE, nn
                  DEFB Unknown_instr / 256  ; EX   DE,HL
                  DEFB Unknown_instr / 256  ; CALL PE, nn
                  DEFB Unknown_instr / 256  ; ???
                  DEFB Unknown_instr / 256  ; XOR  n
                  DEFB Unknown_instr / 256  ; RST  $28
                  DEFB Unknown_instr / 256  ; RET  P
                  DEFB Unknown_instr / 256  ; POP  AF
                  DEFB Unknown_instr / 256  ; JP   P, nn
                  DEFB Unknown_instr / 256  ; DI
                  DEFB Unknown_instr / 256  ; CALL P, nn
                  DEFB Unknown_instr / 256  ; PUSH AF
                  DEFB Unknown_instr / 256  ; OR   n
                  DEFB Unknown_instr / 256  ; RST  $30
                  DEFB Unknown_instr / 256  ; RET  M
                  DEFB Opcode_249_index/256 ; LD   SP,IX/IY
                  DEFB Unknown_instr / 256  ; JP   M, nn
                  DEFB Unknown_instr / 256  ; EI
                  DEFB Unknown_instr / 256  ; CALL M, nn
                  DEFB Unknown_instr / 256  ; ???
                  DEFB Unknown_instr / 256  ; CP   n
                  DEFB Unknown_instr / 256  ; RST  $38



; ******************************************************************************
;
;    $CB Virtual Z80 instruction routine lookup table, low byte address
;
.BitInstrTable    DEFB BitCode_0   % 256    ; RLC  B
                  DEFB BitCode_1   % 256    ; RLC  C
                  DEFB BitCode_2   % 256    ; RLC  D
                  DEFB BitCode_3   % 256    ; RLC  E
                  DEFB BitCode_4   % 256    ; RLC  H
                  DEFB BitCode_5   % 256    ; RLC  L
                  DEFB BitCode_6   % 256    ; RLC  (HL)
                  DEFB BitCode_7   % 256    ; RLC  A
                  DEFB BitCode_8   % 256    ; RRC  B
                  DEFB BitCode_9   % 256    ; RRC  C
                  DEFB BitCode_10  % 256    ; RRC  D
                  DEFB BitCode_11  % 256    ; RRC  E
                  DEFB BitCode_12  % 256    ; RRC  H
                  DEFB BitCode_13  % 256    ; RRC  L
                  DEFB BitCode_14  % 256    ; RRC  (HL)
                  DEFB BitCode_15  % 256    ; RRC  A
                  DEFB BitCode_16  % 256    ; RL   B
                  DEFB BitCode_17  % 256    ; RL   C
                  DEFB BitCode_18  % 256    ; RL   D
                  DEFB BitCode_19  % 256    ; RL   E
                  DEFB BitCode_20  % 256    ; RL   H
                  DEFB BitCode_21  % 256    ; RL   L
                  DEFB BitCode_22  % 256    ; RL   (HL)
                  DEFB BitCode_23  % 256    ; RL   A
                  DEFB BitCode_24  % 256    ; RR   B
                  DEFB BitCode_25  % 256    ; RR   C
                  DEFB BitCode_26  % 256    ; RR   D
                  DEFB BitCode_27  % 256    ; RR   E
                  DEFB BitCode_28  % 256    ; RR   H
                  DEFB BitCode_29  % 256    ; RR   L
                  DEFB BitCode_30  % 256    ; RR   (HL)
                  DEFB BitCode_31  % 256    ; RR   A
                  DEFB BitCode_32  % 256    ; SLA  B
                  DEFB BitCode_33  % 256    ; SLA  C
                  DEFB BitCode_34  % 256    ; SLA  D
                  DEFB BitCode_35  % 256    ; SLA  E
                  DEFB BitCode_36  % 256    ; SLA  H
                  DEFB BitCode_37  % 256    ; SLA  L
                  DEFB BitCode_38  % 256    ; SLA  (HL)
                  DEFB BitCode_39  % 256    ; SLA  A
                  DEFB BitCode_40  % 256    ; SRA  B
                  DEFB BitCode_41  % 256    ; SRA  C
                  DEFB BitCode_42  % 256    ; SRA  D
                  DEFB BitCode_43  % 256    ; SRA  E
                  DEFB BitCode_44  % 256    ; SRA  H
                  DEFB BitCode_45  % 256    ; SRA  L
                  DEFB BitCode_46  % 256    ; SRA  (HL)
                  DEFB BitCode_47  % 256    ; SRA  A
                  DEFB Unknown_instr % 256    ; 48, No instruction
                  DEFB Unknown_instr % 256    ; 49, No instruction
                  DEFB Unknown_instr % 256    ; 50, No instruction
                  DEFB Unknown_instr % 256    ; 51, No instruction
                  DEFB Unknown_instr % 256    ; 52, No instruction
                  DEFB Unknown_instr % 256    ; 53, No instruction
                  DEFB Unknown_instr % 256    ; 54, No instruction
                  DEFB Unknown_instr % 256    ; 55, No instruction
                  DEFB BitCode_56  % 256    ; SRL  B
                  DEFB BitCode_57  % 256    ; SRL  C
                  DEFB BitCode_58  % 256    ; SRL  D
                  DEFB BitCode_59  % 256    ; SRL  E
                  DEFB BitCode_60  % 256    ; SRL  H
                  DEFB BitCode_61  % 256    ; SRL  L
                  DEFB BitCode_62  % 256    ; SRL  (HL)
                  DEFB BitCode_63  % 256    ; SRL  A
                  DEFB BitCode_64  % 256    ; BIT  0,B
                  DEFB BitCode_65  % 256    ; BIT  0,C
                  DEFB BitCode_66  % 256    ; BIT  0,D
                  DEFB BitCode_67  % 256    ; BIT  0,E
                  DEFB BitCode_68  % 256    ; BIT  0,H
                  DEFB BitCode_69  % 256    ; BIT  0,L
                  DEFB BitCode_70  % 256    ; BIT  0,(HL)
                  DEFB BitCode_71  % 256    ; BIT  0,A
                  DEFB BitCode_72  % 256    ; BIT  1,B
                  DEFB BitCode_73  % 256    ; BIT  1,C
                  DEFB BitCode_74  % 256    ; BIT  1,D
                  DEFB BitCode_75  % 256    ; BIT  1,E
                  DEFB BitCode_76  % 256    ; BIT  1,H
                  DEFB BitCode_77  % 256    ; BIT  1,L
                  DEFB BitCode_78  % 256    ; BIT  1,(HL)
                  DEFB BitCode_79  % 256    ; BIT  1,A
                  DEFB BitCode_80  % 256    ; BIT  2,B
                  DEFB BitCode_81  % 256    ; BIT  2,C
                  DEFB BitCode_82  % 256    ; BIT  2,D
                  DEFB BitCode_83  % 256    ; BIT  2,E
                  DEFB BitCode_84  % 256    ; BIT  2,H
                  DEFB BitCode_85  % 256    ; BIT  2,L
                  DEFB BitCode_86  % 256    ; BIT  2,(HL)
                  DEFB BitCode_87  % 256    ; BIT  2,A
                  DEFB BitCode_88  % 256    ; BIT  3,B
                  DEFB BitCode_89  % 256    ; BIT  3,C
                  DEFB BitCode_90  % 256    ; BIT  3,D
                  DEFB BitCode_91  % 256    ; BIT  3,E
                  DEFB BitCode_92  % 256    ; BIT  3,H
                  DEFB BitCode_93  % 256    ; BIT  3,L
                  DEFB BitCode_94  % 256    ; BIT  3,(HL)
                  DEFB BitCode_95  % 256    ; BIT  3,A
                  DEFB BitCode_96  % 256    ; BIT  4,B
                  DEFB BitCode_97  % 256    ; BIT  4,C
                  DEFB BitCode_98  % 256    ; BIT  4,D
                  DEFB BitCode_99  % 256    ; BIT  4,E
                  DEFB BitCode_100 % 256    ; BIT  4,H
                  DEFB BitCode_101 % 256    ; BIT  4,L
                  DEFB BitCode_102 % 256    ; BIT  4,(HL)
                  DEFB BitCode_103 % 256    ; BIT  4,A
                  DEFB BitCode_104 % 256    ; BIT  5,B
                  DEFB BitCode_105 % 256    ; BIT  5,C
                  DEFB BitCode_106 % 256    ; BIT  5,D
                  DEFB BitCode_107 % 256    ; BIT  5,E
                  DEFB BitCode_108 % 256    ; BIT  5,H
                  DEFB BitCode_109 % 256    ; BIT  5,L
                  DEFB BitCode_110 % 256    ; BIT  5,(HL)
                  DEFB BitCode_111 % 256    ; BIT  5,A
                  DEFB BitCode_112 % 256    ; BIT  6,B
                  DEFB BitCode_113 % 256    ; BIT  6,C
                  DEFB BitCode_114 % 256    ; BIT  6,D
                  DEFB BitCode_115 % 256    ; BIT  6,E
                  DEFB BitCode_116 % 256    ; BIT  6,H
                  DEFB BitCode_117 % 256    ; BIT  6,L
                  DEFB BitCode_118 % 256    ; BIT  6,(HL)
                  DEFB BitCode_119 % 256    ; BIT  6,A
                  DEFB BitCode_120 % 256    ; BIT  7,B
                  DEFB BitCode_121 % 256    ; BIT  7,C
                  DEFB BitCode_122 % 256    ; BIT  7,D
                  DEFB BitCode_123 % 256    ; BIT  7,E
                  DEFB BitCode_124 % 256    ; BIT  7,H
                  DEFB BitCode_125 % 256    ; BIT  7,L
                  DEFB BitCode_126 % 256    ; BIT  7,(HL)
                  DEFB BitCode_127 % 256    ; BIT  7,A
                  DEFB BitCode_128 % 256    ; RES  0,B
                  DEFB BitCode_129 % 256    ; RES  0,C
                  DEFB BitCode_130 % 256    ; RES  0,D
                  DEFB BitCode_131 % 256    ; RES  0,E
                  DEFB BitCode_132 % 256    ; RES  0,H
                  DEFB BitCode_133 % 256    ; RES  0,L
                  DEFB BitCode_134 % 256    ; RES  0,(HL)
                  DEFB BitCode_135 % 256    ; RES  0,A
                  DEFB BitCode_136 % 256    ; RES  1,B
                  DEFB BitCode_137 % 256    ; RES  1,C
                  DEFB BitCode_138 % 256    ; RES  1,D
                  DEFB BitCode_139 % 256    ; RES  1,E
                  DEFB BitCode_140 % 256    ; RES  1,H
                  DEFB BitCode_141 % 256    ; RES  1,L
                  DEFB BitCode_142 % 256    ; RES  1,(HL)
                  DEFB BitCode_143 % 256    ; RES  1,A
                  DEFB BitCode_144 % 256    ; RES  2,B
                  DEFB BitCode_145 % 256    ; RES  2,C
                  DEFB BitCode_146 % 256    ; RES  2,D
                  DEFB BitCode_147 % 256    ; RES  2,E
                  DEFB BitCode_148 % 256    ; RES  2,H
                  DEFB BitCode_149 % 256    ; RES  2,L
                  DEFB BitCode_150 % 256    ; RES  2,(HL)
                  DEFB BitCode_151 % 256    ; RES  2,A
                  DEFB BitCode_152 % 256    ; RES  3,B
                  DEFB BitCode_153 % 256    ; RES  3,C
                  DEFB BitCode_154 % 256    ; RES  3,D
                  DEFB BitCode_155 % 256    ; RES  3,E
                  DEFB BitCode_156 % 256    ; RES  3,H
                  DEFB BitCode_157 % 256    ; RES  3,L
                  DEFB BitCode_158 % 256    ; RES  3,(HL)
                  DEFB BitCode_159 % 256    ; RES  3,A
                  DEFB BitCode_160 % 256    ; RES  4,B
                  DEFB BitCode_161 % 256    ; RES  4,C
                  DEFB BitCode_162 % 256    ; RES  4,D
                  DEFB BitCode_163 % 256    ; RES  4,E
                  DEFB BitCode_164 % 256    ; RES  4,H
                  DEFB BitCode_165 % 256    ; RES  4,L
                  DEFB BitCode_166 % 256    ; RES  4,(HL)
                  DEFB BitCode_167 % 256    ; RES  4,A
                  DEFB BitCode_168 % 256    ; RES  5,B
                  DEFB BitCode_169 % 256    ; RES  5,C
                  DEFB BitCode_170 % 256    ; RES  5,D
                  DEFB BitCode_171 % 256    ; RES  5,E
                  DEFB BitCode_172 % 256    ; RES  5,H
                  DEFB BitCode_173 % 256    ; RES  5,L
                  DEFB BitCode_174 % 256    ; RES  5,(HL)
                  DEFB BitCode_175 % 256    ; RES  5,A
                  DEFB BitCode_176 % 256    ; RES  6,B
                  DEFB BitCode_177 % 256    ; RES  6,C
                  DEFB BitCode_178 % 256    ; RES  6,D
                  DEFB BitCode_179 % 256    ; RES  6,E
                  DEFB BitCode_180 % 256    ; RES  6,H
                  DEFB BitCode_181 % 256    ; RES  6,L
                  DEFB BitCode_182 % 256    ; RES  6,(HL)
                  DEFB BitCode_183 % 256    ; RES  6,A
                  DEFB BitCode_184 % 256    ; RES  7,B
                  DEFB BitCode_185 % 256    ; RES  7,C
                  DEFB BitCode_186 % 256    ; RES  7,D
                  DEFB BitCode_187 % 256    ; RES  7,E
                  DEFB BitCode_188 % 256    ; RES  7,H
                  DEFB BitCode_189 % 256    ; RES  7,L
                  DEFB BitCode_190 % 256    ; RES  7,(HL)
                  DEFB BitCode_191 % 256    ; RES  7,A
                  DEFB BitCode_192 % 256    ; SET  0,B
                  DEFB BitCode_193 % 256    ; SET  0,C
                  DEFB BitCode_194 % 256    ; SET  0,D
                  DEFB BitCode_195 % 256    ; SET  0,E
                  DEFB BitCode_196 % 256    ; SET  0,H
                  DEFB BitCode_197 % 256    ; SET  0,L
                  DEFB BitCode_198 % 256    ; SET  0,(HL)
                  DEFB BitCode_199 % 256    ; SET  0,A
                  DEFB BitCode_200 % 256    ; SET  1,B
                  DEFB BitCode_201 % 256    ; SET  1,C
                  DEFB BitCode_202 % 256    ; SET  1,D
                  DEFB BitCode_203 % 256    ; SET  1,E
                  DEFB BitCode_204 % 256    ; SET  1,H
                  DEFB BitCode_205 % 256    ; SET  1,L
                  DEFB BitCode_206 % 256    ; SET  1,(HL)
                  DEFB BitCode_207 % 256    ; SET  1,A
                  DEFB BitCode_208 % 256    ; SET  2,B
                  DEFB BitCode_209 % 256    ; SET  2,C
                  DEFB BitCode_210 % 256    ; SET  2,D
                  DEFB BitCode_211 % 256    ; SET  2,E
                  DEFB BitCode_212 % 256    ; SET  2,H
                  DEFB BitCode_213 % 256    ; SET  2,L
                  DEFB BitCode_214 % 256    ; SET  2,(HL)
                  DEFB BitCode_215 % 256    ; SET  2,A
                  DEFB BitCode_216 % 256    ; SET  3,B
                  DEFB BitCode_217 % 256    ; SET  3,C
                  DEFB BitCode_218 % 256    ; SET  3,D
                  DEFB BitCode_219 % 256    ; SET  3,E
                  DEFB BitCode_220 % 256    ; SET  3,H
                  DEFB BitCode_221 % 256    ; SET  3,L
                  DEFB BitCode_222 % 256    ; SET  3,(HL)
                  DEFB BitCode_223 % 256    ; SET  3,A
                  DEFB BitCode_224 % 256    ; SET  4,B
                  DEFB BitCode_225 % 256    ; SET  4,C
                  DEFB BitCode_226 % 256    ; SET  4,D
                  DEFB BitCode_227 % 256    ; SET  4,E
                  DEFB BitCode_228 % 256    ; SET  4,H
                  DEFB BitCode_229 % 256    ; SET  4,L
                  DEFB BitCode_230 % 256    ; SET  4,(HL)
                  DEFB BitCode_231 % 256    ; SET  4,A
                  DEFB BitCode_232 % 256    ; SET  5,B
                  DEFB BitCode_233 % 256    ; SET  5,C
                  DEFB BitCode_234 % 256    ; SET  5,D
                  DEFB BitCode_235 % 256    ; SET  5,E
                  DEFB BitCode_236 % 256    ; SET  5,H
                  DEFB BitCode_237 % 256    ; SET  5,L
                  DEFB BitCode_238 % 256    ; SET  5,(HL)
                  DEFB BitCode_239 % 256    ; SET  5,A
                  DEFB BitCode_240 % 256    ; SET  6,B
                  DEFB BitCode_241 % 256    ; SET  6,C
                  DEFB BitCode_242 % 256    ; SET  6,D
                  DEFB BitCode_243 % 256    ; SET  6,E
                  DEFB BitCode_244 % 256    ; SET  6,H
                  DEFB BitCode_245 % 256    ; SET  6,L
                  DEFB BitCode_246 % 256    ; SET  6,(HL)
                  DEFB BitCode_247 % 256    ; SET  6,A
                  DEFB BitCode_248 % 256    ; SET  7,B
                  DEFB BitCode_249 % 256    ; SET  7,C
                  DEFB BitCode_250 % 256    ; SET  7,D
                  DEFB BitCode_251 % 256    ; SET  7,E
                  DEFB BitCode_252 % 256    ; SET  7,H
                  DEFB BitCode_253 % 256    ; SET  7,L
                  DEFB BitCode_254 % 256    ; SET  7,(HL)
                  DEFB BitCode_255 % 256    ; SET  7,A

; ******************************************************************************
;
;    $CB Virtual Z80 instruction routine lookup table, high byte address
;
                  DEFB BitCode_0   / 256    ; RLC  B
                  DEFB BitCode_1   / 256    ; RLC  C
                  DEFB BitCode_2   / 256    ; RLC  D
                  DEFB BitCode_3   / 256    ; RLC  E
                  DEFB BitCode_4   / 256    ; RLC  H
                  DEFB BitCode_5   / 256    ; RLC  L
                  DEFB BitCode_6   / 256    ; RLC  (HL)
                  DEFB BitCode_7   / 256    ; RLC  A
                  DEFB BitCode_8   / 256    ; RRC  B
                  DEFB BitCode_9   / 256    ; RRC  C
                  DEFB BitCode_10  / 256    ; RRC  D
                  DEFB BitCode_11  / 256    ; RRC  E
                  DEFB BitCode_12  / 256    ; RRC  H
                  DEFB BitCode_13  / 256    ; RRC  L
                  DEFB BitCode_14  / 256    ; RRC  (HL)
                  DEFB BitCode_15  / 256    ; RRC  A
                  DEFB BitCode_16  / 256    ; RL   B
                  DEFB BitCode_17  / 256    ; RL   C
                  DEFB BitCode_18  / 256    ; RL   D
                  DEFB BitCode_19  / 256    ; RL   E
                  DEFB BitCode_20  / 256    ; RL   H
                  DEFB BitCode_21  / 256    ; RL   L
                  DEFB BitCode_22  / 256    ; RL   (HL)
                  DEFB BitCode_23  / 256    ; RL   A
                  DEFB BitCode_24  / 256    ; RR   B
                  DEFB BitCode_25  / 256    ; RR   C
                  DEFB BitCode_26  / 256    ; RR   D
                  DEFB BitCode_27  / 256    ; RR   E
                  DEFB BitCode_28  / 256    ; RR   H
                  DEFB BitCode_29  / 256    ; RR   L
                  DEFB BitCode_30  / 256    ; RR   (HL)
                  DEFB BitCode_31  / 256    ; RR   A
                  DEFB BitCode_32  / 256    ; SLA  B
                  DEFB BitCode_33  / 256    ; SLA  C
                  DEFB BitCode_34  / 256    ; SLA  D
                  DEFB BitCode_35  / 256    ; SLA  E
                  DEFB BitCode_36  / 256    ; SLA  H
                  DEFB BitCode_37  / 256    ; SLA  L
                  DEFB BitCode_38  / 256    ; SLA  (HL)
                  DEFB BitCode_39  / 256    ; SLA  A
                  DEFB BitCode_40  / 256    ; SRA  B
                  DEFB BitCode_41  / 256    ; SRA  C
                  DEFB BitCode_42  / 256    ; SRA  D
                  DEFB BitCode_43  / 256    ; SRA  E
                  DEFB BitCode_44  / 256    ; SRA  H
                  DEFB BitCode_45  / 256    ; SRA  L
                  DEFB BitCode_46  / 256    ; SRA  (HL)
                  DEFB BitCode_47  / 256    ; SRA  A
                  DEFB Unknown_instr / 256    ; 48, No instruction
                  DEFB Unknown_instr / 256    ; 49, No instruction
                  DEFB Unknown_instr / 256    ; 50, No instruction
                  DEFB Unknown_instr / 256    ; 51, No instruction
                  DEFB Unknown_instr / 256    ; 52, No instruction
                  DEFB Unknown_instr / 256    ; 53, No instruction
                  DEFB Unknown_instr / 256    ; 54, No instruction
                  DEFB Unknown_instr / 256    ; 55, No instruction
                  DEFB BitCode_56  / 256    ; SRL  B
                  DEFB BitCode_57  / 256    ; SRL  C
                  DEFB BitCode_58  / 256    ; SRL  D
                  DEFB BitCode_59  / 256    ; SRL  E
                  DEFB BitCode_60  / 256    ; SRL  H
                  DEFB BitCode_61  / 256    ; SRL  L
                  DEFB BitCode_62  / 256    ; SRL  (HL)
                  DEFB BitCode_63  / 256    ; SRL  A
                  DEFB BitCode_64  / 256    ; BIT  0,B
                  DEFB BitCode_65  / 256    ; BIT  0,C
                  DEFB BitCode_66  / 256    ; BIT  0,D
                  DEFB BitCode_67  / 256    ; BIT  0,E
                  DEFB BitCode_68  / 256    ; BIT  0,H
                  DEFB BitCode_69  / 256    ; BIT  0,L
                  DEFB BitCode_70  / 256    ; BIT  0,(HL)
                  DEFB BitCode_71  / 256    ; BIT  0,A
                  DEFB BitCode_72  / 256    ; BIT  1,B
                  DEFB BitCode_73  / 256    ; BIT  1,C
                  DEFB BitCode_74  / 256    ; BIT  1,D
                  DEFB BitCode_75  / 256    ; BIT  1,E
                  DEFB BitCode_76  / 256    ; BIT  1,H
                  DEFB BitCode_77  / 256    ; BIT  1,L
                  DEFB BitCode_78  / 256    ; BIT  1,(HL)
                  DEFB BitCode_79  / 256    ; BIT  1,A
                  DEFB BitCode_80  / 256    ; BIT  2,B
                  DEFB BitCode_81  / 256    ; BIT  2,C
                  DEFB BitCode_82  / 256    ; BIT  2,D
                  DEFB BitCode_83  / 256    ; BIT  2,E
                  DEFB BitCode_84  / 256    ; BIT  2,H
                  DEFB BitCode_85  / 256    ; BIT  2,L
                  DEFB BitCode_86  / 256    ; BIT  2,(HL)
                  DEFB BitCode_87  / 256    ; BIT  2,A
                  DEFB BitCode_88  / 256    ; BIT  3,B
                  DEFB BitCode_89  / 256    ; BIT  3,C
                  DEFB BitCode_90  / 256    ; BIT  3,D
                  DEFB BitCode_91  / 256    ; BIT  3,E
                  DEFB BitCode_92  / 256    ; BIT  3,H
                  DEFB BitCode_93  / 256    ; BIT  3,L
                  DEFB BitCode_94  / 256    ; BIT  3,(HL)
                  DEFB BitCode_95  / 256    ; BIT  3,A
                  DEFB BitCode_96  / 256    ; BIT  4,B
                  DEFB BitCode_97  / 256    ; BIT  4,C
                  DEFB BitCode_98  / 256    ; BIT  4,D
                  DEFB BitCode_99  / 256    ; BIT  4,E
                  DEFB BitCode_100 / 256    ; BIT  4,H
                  DEFB BitCode_101 / 256    ; BIT  4,L
                  DEFB BitCode_102 / 256    ; BIT  4,(HL)
                  DEFB BitCode_103 / 256    ; BIT  4,A
                  DEFB BitCode_104 / 256    ; BIT  5,B
                  DEFB BitCode_105 / 256    ; BIT  5,C
                  DEFB BitCode_106 / 256    ; BIT  5,D
                  DEFB BitCode_107 / 256    ; BIT  5,E
                  DEFB BitCode_108 / 256    ; BIT  5,H
                  DEFB BitCode_109 / 256    ; BIT  5,L
                  DEFB BitCode_110 / 256    ; BIT  5,(HL)
                  DEFB BitCode_111 / 256    ; BIT  5,A
                  DEFB BitCode_112 / 256    ; BIT  6,B
                  DEFB BitCode_113 / 256    ; BIT  6,C
                  DEFB BitCode_114 / 256    ; BIT  6,D
                  DEFB BitCode_115 / 256    ; BIT  6,E
                  DEFB BitCode_116 / 256    ; BIT  6,H
                  DEFB BitCode_117 / 256    ; BIT  6,L
                  DEFB BitCode_118 / 256    ; BIT  6,(HL)
                  DEFB BitCode_119 / 256    ; BIT  6,A
                  DEFB BitCode_120 / 256    ; BIT  7,B
                  DEFB BitCode_121 / 256    ; BIT  7,C
                  DEFB BitCode_122 / 256    ; BIT  7,D
                  DEFB BitCode_123 / 256    ; BIT  7,E
                  DEFB BitCode_124 / 256    ; BIT  7,H
                  DEFB BitCode_125 / 256    ; BIT  7,L
                  DEFB BitCode_126 / 256    ; BIT  7,(HL)
                  DEFB BitCode_127 / 256    ; BIT  7,A
                  DEFB BitCode_128 / 256    ; RES  0,B
                  DEFB BitCode_129 / 256    ; RES  0,C
                  DEFB BitCode_130 / 256    ; RES  0,D
                  DEFB BitCode_131 / 256    ; RES  0,E
                  DEFB BitCode_132 / 256    ; RES  0,H
                  DEFB BitCode_133 / 256    ; RES  0,L
                  DEFB BitCode_134 / 256    ; RES  0,(HL)
                  DEFB BitCode_135 / 256    ; RES  0,A
                  DEFB BitCode_136 / 256    ; RES  1,B
                  DEFB BitCode_137 / 256    ; RES  1,C
                  DEFB BitCode_138 / 256    ; RES  1,D
                  DEFB BitCode_139 / 256    ; RES  1,E
                  DEFB BitCode_140 / 256    ; RES  1,H
                  DEFB BitCode_141 / 256    ; RES  1,L
                  DEFB BitCode_142 / 256    ; RES  1,(HL)
                  DEFB BitCode_143 / 256    ; RES  1,A
                  DEFB BitCode_144 / 256    ; RES  2,B
                  DEFB BitCode_145 / 256    ; RES  2,C
                  DEFB BitCode_146 / 256    ; RES  2,D
                  DEFB BitCode_147 / 256    ; RES  2,E
                  DEFB BitCode_148 / 256    ; RES  2,H
                  DEFB BitCode_149 / 256    ; RES  2,L
                  DEFB BitCode_150 / 256    ; RES  2,(HL)
                  DEFB BitCode_151 / 256    ; RES  2,A
                  DEFB BitCode_152 / 256    ; RES  3,B
                  DEFB BitCode_153 / 256    ; RES  3,C
                  DEFB BitCode_154 / 256    ; RES  3,D
                  DEFB BitCode_155 / 256    ; RES  3,E
                  DEFB BitCode_156 / 256    ; RES  3,H
                  DEFB BitCode_157 / 256    ; RES  3,L
                  DEFB BitCode_158 / 256    ; RES  3,(HL)
                  DEFB BitCode_159 / 256    ; RES  3,A
                  DEFB BitCode_160 / 256    ; RES  4,B
                  DEFB BitCode_161 / 256    ; RES  4,C
                  DEFB BitCode_162 / 256    ; RES  4,D
                  DEFB BitCode_163 / 256    ; RES  4,E
                  DEFB BitCode_164 / 256    ; RES  4,H
                  DEFB BitCode_165 / 256    ; RES  4,L
                  DEFB BitCode_166 / 256    ; RES  4,(HL)
                  DEFB BitCode_167 / 256    ; RES  4,A
                  DEFB BitCode_168 / 256    ; RES  5,B
                  DEFB BitCode_169 / 256    ; RES  5,C
                  DEFB BitCode_170 / 256    ; RES  5,D
                  DEFB BitCode_171 / 256    ; RES  5,E
                  DEFB BitCode_172 / 256    ; RES  5,H
                  DEFB BitCode_173 / 256    ; RES  5,L
                  DEFB BitCode_174 / 256    ; RES  5,(HL)
                  DEFB BitCode_175 / 256    ; RES  5,A
                  DEFB BitCode_176 / 256    ; RES  6,B
                  DEFB BitCode_177 / 256    ; RES  6,C
                  DEFB BitCode_178 / 256    ; RES  6,D
                  DEFB BitCode_179 / 256    ; RES  6,E
                  DEFB BitCode_180 / 256    ; RES  6,H
                  DEFB BitCode_181 / 256    ; RES  6,L
                  DEFB BitCode_182 / 256    ; RES  6,(HL)
                  DEFB BitCode_183 / 256    ; RES  6,A
                  DEFB BitCode_184 / 256    ; RES  7,B
                  DEFB BitCode_185 / 256    ; RES  7,C
                  DEFB BitCode_186 / 256    ; RES  7,D
                  DEFB BitCode_187 / 256    ; RES  7,E
                  DEFB BitCode_188 / 256    ; RES  7,H
                  DEFB BitCode_189 / 256    ; RES  7,L
                  DEFB BitCode_190 / 256    ; RES  7,(HL)
                  DEFB BitCode_191 / 256    ; RES  7,A
                  DEFB BitCode_192 / 256    ; SET  0,B
                  DEFB BitCode_193 / 256    ; SET  0,C
                  DEFB BitCode_194 / 256    ; SET  0,D
                  DEFB BitCode_195 / 256    ; SET  0,E
                  DEFB BitCode_196 / 256    ; SET  0,H
                  DEFB BitCode_197 / 256    ; SET  0,L
                  DEFB BitCode_198 / 256    ; SET  0,(HL)
                  DEFB BitCode_199 / 256    ; SET  0,A
                  DEFB BitCode_200 / 256    ; SET  1,B
                  DEFB BitCode_201 / 256    ; SET  1,C
                  DEFB BitCode_202 / 256    ; SET  1,D
                  DEFB BitCode_203 / 256    ; SET  1,E
                  DEFB BitCode_204 / 256    ; SET  1,H
                  DEFB BitCode_205 / 256    ; SET  1,L
                  DEFB BitCode_206 / 256    ; SET  1,(HL)
                  DEFB BitCode_207 / 256    ; SET  1,A
                  DEFB BitCode_208 / 256    ; SET  2,B
                  DEFB BitCode_209 / 256    ; SET  2,C
                  DEFB BitCode_210 / 256    ; SET  2,D
                  DEFB BitCode_211 / 256    ; SET  2,E
                  DEFB BitCode_212 / 256    ; SET  2,H
                  DEFB BitCode_213 / 256    ; SET  2,L
                  DEFB BitCode_214 / 256    ; SET  2,(HL)
                  DEFB BitCode_215 / 256    ; SET  2,A
                  DEFB BitCode_216 / 256    ; SET  3,B
                  DEFB BitCode_217 / 256    ; SET  3,C
                  DEFB BitCode_218 / 256    ; SET  3,D
                  DEFB BitCode_219 / 256    ; SET  3,E
                  DEFB BitCode_220 / 256    ; SET  3,H
                  DEFB BitCode_221 / 256    ; SET  3,L
                  DEFB BitCode_222 / 256    ; SET  3,(HL)
                  DEFB BitCode_223 / 256    ; SET  3,A
                  DEFB BitCode_224 / 256    ; SET  4,B
                  DEFB BitCode_225 / 256    ; SET  4,C
                  DEFB BitCode_226 / 256    ; SET  4,D
                  DEFB BitCode_227 / 256    ; SET  4,E
                  DEFB BitCode_228 / 256    ; SET  4,H
                  DEFB BitCode_229 / 256    ; SET  4,L
                  DEFB BitCode_230 / 256    ; SET  4,(HL)
                  DEFB BitCode_231 / 256    ; SET  4,A
                  DEFB BitCode_232 / 256    ; SET  5,B
                  DEFB BitCode_233 / 256    ; SET  5,C
                  DEFB BitCode_234 / 256    ; SET  5,D
                  DEFB BitCode_235 / 256    ; SET  5,E
                  DEFB BitCode_236 / 256    ; SET  5,H
                  DEFB BitCode_237 / 256    ; SET  5,L
                  DEFB BitCode_238 / 256    ; SET  5,(HL)
                  DEFB BitCode_239 / 256    ; SET  5,A
                  DEFB BitCode_240 / 256    ; SET  6,B
                  DEFB BitCode_241 / 256    ; SET  6,C
                  DEFB BitCode_242 / 256    ; SET  6,D
                  DEFB BitCode_243 / 256    ; SET  6,E
                  DEFB BitCode_244 / 256    ; SET  6,H
                  DEFB BitCode_245 / 256    ; SET  6,L
                  DEFB BitCode_246 / 256    ; SET  6,(HL)
                  DEFB BitCode_247 / 256    ; SET  6,A
                  DEFB BitCode_248 / 256    ; SET  7,B
                  DEFB BitCode_249 / 256    ; SET  7,C
                  DEFB BitCode_250 / 256    ; SET  7,D
                  DEFB BitCode_251 / 256    ; SET  7,E
                  DEFB BitCode_252 / 256    ; SET  7,H
                  DEFB BitCode_253 / 256    ; SET  7,L
                  DEFB BitCode_254 / 256    ; SET  7,(HL)
                  DEFB BitCode_255 / 256    ; SET  7,A


; ******************************************************************************
;
;    $CB IX/IY Virtual Z80 instruction routine lookup table, low byte address
;
.IndexBitInstrTable
                  DEFB Unknown_instr % 256  ; RLC  B
                  DEFB Unknown_instr % 256  ; RLC  C
                  DEFB Unknown_instr % 256  ; RLC  D
                  DEFB Unknown_instr % 256  ; RLC  E
                  DEFB Unknown_instr % 256  ; RLC  H
                  DEFB Unknown_instr % 256  ; RLC  L
                  DEFB BitCode_6_index%256  ; RLC  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; RLC  A
                  DEFB Unknown_instr % 256  ; RRC  B
                  DEFB Unknown_instr % 256  ; RRC  C
                  DEFB Unknown_instr % 256  ; RRC  D
                  DEFB Unknown_instr % 256  ; RRC  E
                  DEFB Unknown_instr % 256  ; RRC  H
                  DEFB Unknown_instr % 256  ; RRC  L
                  DEFB BitCode_14_index%256 ; RRC  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; RRC  A
                  DEFB Unknown_instr % 256  ; RL   B
                  DEFB Unknown_instr % 256  ; RL   C
                  DEFB Unknown_instr % 256  ; RL   D
                  DEFB Unknown_instr % 256  ; RL   E
                  DEFB Unknown_instr % 256  ; RL   H
                  DEFB Unknown_instr % 256  ; RL   L
                  DEFB BitCode_22_index%256 ; RL   (IX/IY+d)
                  DEFB Unknown_instr % 256  ; RL   A
                  DEFB Unknown_instr % 256  ; RR   B
                  DEFB Unknown_instr % 256  ; RR   C
                  DEFB Unknown_instr % 256  ; RR   D
                  DEFB Unknown_instr % 256  ; RR   E
                  DEFB Unknown_instr % 256  ; RR   H
                  DEFB Unknown_instr % 256  ; RR   L
                  DEFB BitCode_30_index%256 ; RR   (IX/IY+d)
                  DEFB Unknown_instr % 256  ; RR   A
                  DEFB Unknown_instr % 256  ; SLA  B
                  DEFB Unknown_instr % 256  ; SLA  C
                  DEFB Unknown_instr % 256  ; SLA  D
                  DEFB Unknown_instr % 256  ; SLA  E
                  DEFB Unknown_instr % 256  ; SLA  H
                  DEFB Unknown_instr % 256  ; SLA  L
                  DEFB BitCode_38_index%256 ; SLA  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; SLA  A
                  DEFB Unknown_instr % 256  ; SRA  B
                  DEFB Unknown_instr % 256  ; SRA  C
                  DEFB Unknown_instr % 256  ; SRA  D
                  DEFB Unknown_instr % 256  ; SRA  E
                  DEFB Unknown_instr % 256  ; SRA  H
                  DEFB Unknown_instr % 256  ; SRA  L
                  DEFB BitCode_46_index%256 ; SRA  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; SRA  A
                  DEFB Unknown_instr % 256  ; 48, Not documented
                  DEFB Unknown_instr % 256  ; 49, Not documented
                  DEFB Unknown_instr % 256  ; 50, Not documented
                  DEFB Unknown_instr % 256  ; 51, Not documented
                  DEFB Unknown_instr % 256  ; 52, Not documented
                  DEFB Unknown_instr % 256  ; 53, Not documented
                  DEFB Unknown_instr % 256  ; 54, Not documented
                  DEFB Unknown_instr % 256  ; 55, Not documented
                  DEFB Unknown_instr % 256  ; SRL  B
                  DEFB Unknown_instr % 256  ; SRL  C
                  DEFB Unknown_instr % 256  ; SRL  D
                  DEFB Unknown_instr % 256  ; SRL  E
                  DEFB Unknown_instr % 256  ; SRL  H
                  DEFB Unknown_instr % 256  ; SRL  L
                  DEFB BitCode_62_index%256 ; SRL  (IX/IY+d)
                  DEFB Unknown_instr % 256  ; SRL  A
                  DEFB Unknown_instr % 256  ; BIT  0,B
                  DEFB Unknown_instr % 256  ; BIT  0,C
                  DEFB Unknown_instr % 256  ; BIT  0,D
                  DEFB Unknown_instr % 256  ; BIT  0,E
                  DEFB Unknown_instr % 256  ; BIT  0,H
                  DEFB Unknown_instr % 256  ; BIT  0,L
                  DEFB BitCode_70_index%256 ; BIT  0,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  0,A
                  DEFB Unknown_instr % 256  ; BIT  1,B
                  DEFB Unknown_instr % 256  ; BIT  1,C
                  DEFB Unknown_instr % 256  ; BIT  1,D
                  DEFB Unknown_instr % 256  ; BIT  1,E
                  DEFB Unknown_instr % 256  ; BIT  1,H
                  DEFB Unknown_instr % 256  ; BIT  1,L
                  DEFB BitCode_78_index%256 ; BIT  1,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  1,A
                  DEFB Unknown_instr % 256  ; BIT  2,B
                  DEFB Unknown_instr % 256  ; BIT  2,C
                  DEFB Unknown_instr % 256  ; BIT  2,D
                  DEFB Unknown_instr % 256  ; BIT  2,E
                  DEFB Unknown_instr % 256  ; BIT  2,H
                  DEFB Unknown_instr % 256  ; BIT  2,L
                  DEFB BitCode_86_index%256 ; BIT  2,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  2,A
                  DEFB Unknown_instr % 256  ; BIT  3,B
                  DEFB Unknown_instr % 256  ; BIT  3,C
                  DEFB Unknown_instr % 256  ; BIT  3,D
                  DEFB Unknown_instr % 256  ; BIT  3,E
                  DEFB Unknown_instr % 256  ; BIT  3,H
                  DEFB Unknown_instr % 256  ; BIT  3,L
                  DEFB BitCode_94_index%256 ; BIT  3,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  3,A
                  DEFB Unknown_instr % 256  ; BIT  4,B
                  DEFB Unknown_instr % 256  ; BIT  4,C
                  DEFB Unknown_instr % 256  ; BIT  4,D
                  DEFB Unknown_instr % 256  ; BIT  4,E
                  DEFB Unknown_instr % 256  ; BIT  4,H
                  DEFB Unknown_instr % 256  ; BIT  4,L
                  DEFB BitCode_102_index%256; BIT  4,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  4,A
                  DEFB Unknown_instr % 256  ; BIT  5,B
                  DEFB Unknown_instr % 256  ; BIT  5,C
                  DEFB Unknown_instr % 256  ; BIT  5,D
                  DEFB Unknown_instr % 256  ; BIT  5,E
                  DEFB Unknown_instr % 256  ; BIT  5,H
                  DEFB Unknown_instr % 256  ; BIT  5,L
                  DEFB BitCode_110_index%256; BIT  5,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  5,A
                  DEFB Unknown_instr % 256  ; BIT  6,B
                  DEFB Unknown_instr % 256  ; BIT  6,C
                  DEFB Unknown_instr % 256  ; BIT  6,D
                  DEFB Unknown_instr % 256  ; BIT  6,E
                  DEFB Unknown_instr % 256  ; BIT  6,H
                  DEFB Unknown_instr % 256  ; BIT  6,L
                  DEFB BitCode_118_index%256; BIT  6,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  6,A
                  DEFB Unknown_instr % 256  ; BIT  7,B
                  DEFB Unknown_instr % 256  ; BIT  7,C
                  DEFB Unknown_instr % 256  ; BIT  7,D
                  DEFB Unknown_instr % 256  ; BIT  7,E
                  DEFB Unknown_instr % 256  ; BIT  7,H
                  DEFB Unknown_instr % 256  ; BIT  7,L
                  DEFB BitCode_126_index%256; BIT  7,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; BIT  7,A
                  DEFB Unknown_instr % 256  ; RES  0,B
                  DEFB Unknown_instr % 256  ; RES  0,C
                  DEFB Unknown_instr % 256  ; RES  0,D
                  DEFB Unknown_instr % 256  ; RES  0,E
                  DEFB Unknown_instr % 256  ; RES  0,H
                  DEFB Unknown_instr % 256  ; RES  0,L
                  DEFB BitCode_134_index%256; RES  0,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  0,A
                  DEFB Unknown_instr % 256  ; RES  1,B
                  DEFB Unknown_instr % 256  ; RES  1,C
                  DEFB Unknown_instr % 256  ; RES  1,D
                  DEFB Unknown_instr % 256  ; RES  1,E
                  DEFB Unknown_instr % 256  ; RES  1,H
                  DEFB Unknown_instr % 256  ; RES  1,L
                  DEFB BitCode_142_index%256; RES  1,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  1,A
                  DEFB Unknown_instr % 256  ; RES  2,B
                  DEFB Unknown_instr % 256  ; RES  2,C
                  DEFB Unknown_instr % 256  ; RES  2,D
                  DEFB Unknown_instr % 256  ; RES  2,E
                  DEFB Unknown_instr % 256  ; RES  2,H
                  DEFB Unknown_instr % 256  ; RES  2,L
                  DEFB BitCode_150_index%256; RES  2,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  2,A
                  DEFB Unknown_instr % 256  ; RES  3,B
                  DEFB Unknown_instr % 256  ; RES  3,C
                  DEFB Unknown_instr % 256  ; RES  3,D
                  DEFB Unknown_instr % 256  ; RES  3,E
                  DEFB Unknown_instr % 256  ; RES  3,H
                  DEFB Unknown_instr % 256  ; RES  3,L
                  DEFB BitCode_158_index%256; RES  3,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  3,A
                  DEFB Unknown_instr % 256  ; RES  4,B
                  DEFB Unknown_instr % 256  ; RES  4,C
                  DEFB Unknown_instr % 256  ; RES  4,D
                  DEFB Unknown_instr % 256  ; RES  4,E
                  DEFB Unknown_instr % 256  ; RES  4,H
                  DEFB Unknown_instr % 256  ; RES  4,L
                  DEFB BitCode_166_index%256; RES  4,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  4,A
                  DEFB Unknown_instr % 256  ; RES  5,B
                  DEFB Unknown_instr % 256  ; RES  5,C
                  DEFB Unknown_instr % 256  ; RES  5,D
                  DEFB Unknown_instr % 256  ; RES  5,E
                  DEFB Unknown_instr % 256  ; RES  5,H
                  DEFB Unknown_instr % 256  ; RES  5,L
                  DEFB BitCode_174_index%256; RES  5,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  5,A
                  DEFB Unknown_instr % 256  ; RES  6,B
                  DEFB Unknown_instr % 256  ; RES  6,C
                  DEFB Unknown_instr % 256  ; RES  6,D
                  DEFB Unknown_instr % 256  ; RES  6,E
                  DEFB Unknown_instr % 256  ; RES  6,H
                  DEFB Unknown_instr % 256  ; RES  6,L
                  DEFB BitCode_182_index%256; RES  6,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  6,A
                  DEFB Unknown_instr % 256  ; RES  7,B
                  DEFB Unknown_instr % 256  ; RES  7,C
                  DEFB Unknown_instr % 256  ; RES  7,D
                  DEFB Unknown_instr % 256  ; RES  7,E
                  DEFB Unknown_instr % 256  ; RES  7,H
                  DEFB Unknown_instr % 256  ; RES  7,L
                  DEFB BitCode_190_index%256; RES  7,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; RES  7,A
                  DEFB Unknown_instr % 256  ; SET  0,B
                  DEFB Unknown_instr % 256  ; SET  0,C
                  DEFB Unknown_instr % 256  ; SET  0,D
                  DEFB Unknown_instr % 256  ; SET  0,E
                  DEFB Unknown_instr % 256  ; SET  0,H
                  DEFB Unknown_instr % 256  ; SET  0,L
                  DEFB BitCode_198_index%256; SET  0,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  0,A
                  DEFB Unknown_instr % 256  ; SET  1,B
                  DEFB Unknown_instr % 256  ; SET  1,C
                  DEFB Unknown_instr % 256  ; SET  1,D
                  DEFB Unknown_instr % 256  ; SET  1,E
                  DEFB Unknown_instr % 256  ; SET  1,H
                  DEFB Unknown_instr % 256  ; SET  1,L
                  DEFB BitCode_206_index%256; SET  1,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  1,A
                  DEFB Unknown_instr % 256  ; SET  2,B
                  DEFB Unknown_instr % 256  ; SET  2,C
                  DEFB Unknown_instr % 256  ; SET  2,D
                  DEFB Unknown_instr % 256  ; SET  2,E
                  DEFB Unknown_instr % 256  ; SET  2,H
                  DEFB Unknown_instr % 256  ; SET  2,L
                  DEFB BitCode_214_index%256; SET  2,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  2,A
                  DEFB Unknown_instr % 256  ; SET  3,B
                  DEFB Unknown_instr % 256  ; SET  3,C
                  DEFB Unknown_instr % 256  ; SET  3,D
                  DEFB Unknown_instr % 256  ; SET  3,E
                  DEFB Unknown_instr % 256  ; SET  3,H
                  DEFB Unknown_instr % 256  ; SET  3,L
                  DEFB BitCode_222_index%256; SET  3,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  3,A
                  DEFB Unknown_instr % 256  ; SET  4,B
                  DEFB Unknown_instr % 256  ; SET  4,C
                  DEFB Unknown_instr % 256  ; SET  4,D
                  DEFB Unknown_instr % 256  ; SET  4,E
                  DEFB Unknown_instr % 256  ; SET  4,H
                  DEFB Unknown_instr % 256  ; SET  4,L
                  DEFB BitCode_230_index%256; SET  4,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  4,A
                  DEFB Unknown_instr % 256  ; SET  5,B
                  DEFB Unknown_instr % 256  ; SET  5,C
                  DEFB Unknown_instr % 256  ; SET  5,D
                  DEFB Unknown_instr % 256  ; SET  5,E
                  DEFB Unknown_instr % 256  ; SET  5,H
                  DEFB Unknown_instr % 256  ; SET  5,L
                  DEFB BitCode_238_index%256; SET  5,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  5,A
                  DEFB Unknown_instr % 256  ; SET  6,B
                  DEFB Unknown_instr % 256  ; SET  6,C
                  DEFB Unknown_instr % 256  ; SET  6,D
                  DEFB Unknown_instr % 256  ; SET  6,E
                  DEFB Unknown_instr % 256  ; SET  6,H
                  DEFB Unknown_instr % 256  ; SET  6,L
                  DEFB BitCode_246_index%256; SET  6,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  6,A
                  DEFB Unknown_instr % 256  ; SET  7,B
                  DEFB Unknown_instr % 256  ; SET  7,C
                  DEFB Unknown_instr % 256  ; SET  7,D
                  DEFB Unknown_instr % 256  ; SET  7,E
                  DEFB Unknown_instr % 256  ; SET  7,H
                  DEFB Unknown_instr % 256  ; SET  7,L
                  DEFB BitCode_254_index%256; SET  7,(IX/IY+d)
                  DEFB Unknown_instr % 256  ; SET  7,A


; ******************************************************************************
;
;    $CB IX/IY Virtual Z80 instruction routine lookup table, high byte address
;
                  DEFB Unknown_instr / 256  ; RLC  B
                  DEFB Unknown_instr / 256  ; RLC  C
                  DEFB Unknown_instr / 256  ; RLC  D
                  DEFB Unknown_instr / 256  ; RLC  E
                  DEFB Unknown_instr / 256  ; RLC  H
                  DEFB Unknown_instr / 256  ; RLC  L
                  DEFB BitCode_6_index/256  ; RLC  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; RLC  A
                  DEFB Unknown_instr / 256  ; RRC  B
                  DEFB Unknown_instr / 256  ; RRC  C
                  DEFB Unknown_instr / 256  ; RRC  D
                  DEFB Unknown_instr / 256  ; RRC  E
                  DEFB Unknown_instr / 256  ; RRC  H
                  DEFB Unknown_instr / 256  ; RRC  L
                  DEFB BitCode_14_index/256 ; RRC  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; RRC  A
                  DEFB Unknown_instr / 256  ; RL   B
                  DEFB Unknown_instr / 256  ; RL   C
                  DEFB Unknown_instr / 256  ; RL   D
                  DEFB Unknown_instr / 256  ; RL   E
                  DEFB Unknown_instr / 256  ; RL   H
                  DEFB Unknown_instr / 256  ; RL   L
                  DEFB BitCode_22_index/256 ; RL   (IX/IY+d)
                  DEFB Unknown_instr / 256  ; RL   A
                  DEFB Unknown_instr / 256  ; RR   B
                  DEFB Unknown_instr / 256  ; RR   C
                  DEFB Unknown_instr / 256  ; RR   D
                  DEFB Unknown_instr / 256  ; RR   E
                  DEFB Unknown_instr / 256  ; RR   H
                  DEFB Unknown_instr / 256  ; RR   L
                  DEFB BitCode_30_index/256 ; RR   (IX/IY+d)
                  DEFB Unknown_instr / 256  ; RR   A
                  DEFB Unknown_instr / 256  ; SLA  B
                  DEFB Unknown_instr / 256  ; SLA  C
                  DEFB Unknown_instr / 256  ; SLA  D
                  DEFB Unknown_instr / 256  ; SLA  E
                  DEFB Unknown_instr / 256  ; SLA  H
                  DEFB Unknown_instr / 256  ; SLA  L
                  DEFB BitCode_38_index/256 ; SLA  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; SLA  A
                  DEFB Unknown_instr / 256  ; SRA  B
                  DEFB Unknown_instr / 256  ; SRA  C
                  DEFB Unknown_instr / 256  ; SRA  D
                  DEFB Unknown_instr / 256  ; SRA  E
                  DEFB Unknown_instr / 256  ; SRA  H
                  DEFB Unknown_instr / 256  ; SRA  L
                  DEFB BitCode_46_index/256 ; SRA  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; SRA  A
                  DEFB Unknown_instr / 256  ; 48, Not documented
                  DEFB Unknown_instr / 256  ; 49, Not documented
                  DEFB Unknown_instr / 256  ; 50, Not documented
                  DEFB Unknown_instr / 256  ; 51, Not documented
                  DEFB Unknown_instr / 256  ; 52, Not documented
                  DEFB Unknown_instr / 256  ; 53, Not documented
                  DEFB Unknown_instr / 256  ; 54, Not documented
                  DEFB Unknown_instr / 256  ; 55, Not documented
                  DEFB Unknown_instr / 256  ; SRL  B
                  DEFB Unknown_instr / 256  ; SRL  C
                  DEFB Unknown_instr / 256  ; SRL  D
                  DEFB Unknown_instr / 256  ; SRL  E
                  DEFB Unknown_instr / 256  ; SRL  H
                  DEFB Unknown_instr / 256  ; SRL  L
                  DEFB BitCode_62_index/256 ; SRL  (IX/IY+d)
                  DEFB Unknown_instr / 256  ; SRL  A
                  DEFB Unknown_instr / 256  ; BIT  0,B
                  DEFB Unknown_instr / 256  ; BIT  0,C
                  DEFB Unknown_instr / 256  ; BIT  0,D
                  DEFB Unknown_instr / 256  ; BIT  0,E
                  DEFB Unknown_instr / 256  ; BIT  0,H
                  DEFB Unknown_instr / 256  ; BIT  0,L
                  DEFB BitCode_70_index/256 ; BIT  0,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  0,A
                  DEFB Unknown_instr / 256  ; BIT  1,B
                  DEFB Unknown_instr / 256  ; BIT  1,C
                  DEFB Unknown_instr / 256  ; BIT  1,D
                  DEFB Unknown_instr / 256  ; BIT  1,E
                  DEFB Unknown_instr / 256  ; BIT  1,H
                  DEFB Unknown_instr / 256  ; BIT  1,L
                  DEFB BitCode_78_index/256 ; BIT  1,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  1,A
                  DEFB Unknown_instr / 256  ; BIT  2,B
                  DEFB Unknown_instr / 256  ; BIT  2,C
                  DEFB Unknown_instr / 256  ; BIT  2,D
                  DEFB Unknown_instr / 256  ; BIT  2,E
                  DEFB Unknown_instr / 256  ; BIT  2,H
                  DEFB Unknown_instr / 256  ; BIT  2,L
                  DEFB BitCode_86_index/256 ; BIT  2,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  2,A
                  DEFB Unknown_instr / 256  ; BIT  3,B
                  DEFB Unknown_instr / 256  ; BIT  3,C
                  DEFB Unknown_instr / 256  ; BIT  3,D
                  DEFB Unknown_instr / 256  ; BIT  3,E
                  DEFB Unknown_instr / 256  ; BIT  3,H
                  DEFB Unknown_instr / 256  ; BIT  3,L
                  DEFB BitCode_94_index/256 ; BIT  3,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  3,A
                  DEFB Unknown_instr / 256  ; BIT  4,B
                  DEFB Unknown_instr / 256  ; BIT  4,C
                  DEFB Unknown_instr / 256  ; BIT  4,D
                  DEFB Unknown_instr / 256  ; BIT  4,E
                  DEFB Unknown_instr / 256  ; BIT  4,H
                  DEFB Unknown_instr / 256  ; BIT  4,L
                  DEFB BitCode_102_index/256; BIT  4,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  4,A
                  DEFB Unknown_instr / 256  ; BIT  5,B
                  DEFB Unknown_instr / 256  ; BIT  5,C
                  DEFB Unknown_instr / 256  ; BIT  5,D
                  DEFB Unknown_instr / 256  ; BIT  5,E
                  DEFB Unknown_instr / 256  ; BIT  5,H
                  DEFB Unknown_instr / 256  ; BIT  5,L
                  DEFB BitCode_110_index/256; BIT  5,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  5,A
                  DEFB Unknown_instr / 256  ; BIT  6,B
                  DEFB Unknown_instr / 256  ; BIT  6,C
                  DEFB Unknown_instr / 256  ; BIT  6,D
                  DEFB Unknown_instr / 256  ; BIT  6,E
                  DEFB Unknown_instr / 256  ; BIT  6,H
                  DEFB Unknown_instr / 256  ; BIT  6,L
                  DEFB BitCode_118_index/256; BIT  6,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  6,A
                  DEFB Unknown_instr / 256  ; BIT  7,B
                  DEFB Unknown_instr / 256  ; BIT  7,C
                  DEFB Unknown_instr / 256  ; BIT  7,D
                  DEFB Unknown_instr / 256  ; BIT  7,E
                  DEFB Unknown_instr / 256  ; BIT  7,H
                  DEFB Unknown_instr / 256  ; BIT  7,L
                  DEFB BitCode_126_index/256; BIT  7,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; BIT  7,A
                  DEFB Unknown_instr / 256  ; RES  0,B
                  DEFB Unknown_instr / 256  ; RES  0,C
                  DEFB Unknown_instr / 256  ; RES  0,D
                  DEFB Unknown_instr / 256  ; RES  0,E
                  DEFB Unknown_instr / 256  ; RES  0,H
                  DEFB Unknown_instr / 256  ; RES  0,L
                  DEFB BitCode_134_index/256; RES  0,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  0,A
                  DEFB Unknown_instr / 256  ; RES  1,B
                  DEFB Unknown_instr / 256  ; RES  1,C
                  DEFB Unknown_instr / 256  ; RES  1,D
                  DEFB Unknown_instr / 256  ; RES  1,E
                  DEFB Unknown_instr / 256  ; RES  1,H
                  DEFB Unknown_instr / 256  ; RES  1,L
                  DEFB BitCode_142_index/256; RES  1,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  1,A
                  DEFB Unknown_instr / 256  ; RES  2,B
                  DEFB Unknown_instr / 256  ; RES  2,C
                  DEFB Unknown_instr / 256  ; RES  2,D
                  DEFB Unknown_instr / 256  ; RES  2,E
                  DEFB Unknown_instr / 256  ; RES  2,H
                  DEFB Unknown_instr / 256  ; RES  2,L
                  DEFB BitCode_150_index/256; RES  2,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  2,A
                  DEFB Unknown_instr / 256  ; RES  3,B
                  DEFB Unknown_instr / 256  ; RES  3,C
                  DEFB Unknown_instr / 256  ; RES  3,D
                  DEFB Unknown_instr / 256  ; RES  3,E
                  DEFB Unknown_instr / 256  ; RES  3,H
                  DEFB Unknown_instr / 256  ; RES  3,L
                  DEFB BitCode_158_index/256; RES  3,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  3,A
                  DEFB Unknown_instr / 256  ; RES  4,B
                  DEFB Unknown_instr / 256  ; RES  4,C
                  DEFB Unknown_instr / 256  ; RES  4,D
                  DEFB Unknown_instr / 256  ; RES  4,E
                  DEFB Unknown_instr / 256  ; RES  4,H
                  DEFB Unknown_instr / 256  ; RES  4,L
                  DEFB BitCode_166_index/256; RES  4,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  4,A
                  DEFB Unknown_instr / 256  ; RES  5,B
                  DEFB Unknown_instr / 256  ; RES  5,C
                  DEFB Unknown_instr / 256  ; RES  5,D
                  DEFB Unknown_instr / 256  ; RES  5,E
                  DEFB Unknown_instr / 256  ; RES  5,H
                  DEFB Unknown_instr / 256  ; RES  5,L
                  DEFB BitCode_174_index/256; RES  5,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  5,A
                  DEFB Unknown_instr / 256  ; RES  6,B
                  DEFB Unknown_instr / 256  ; RES  6,C
                  DEFB Unknown_instr / 256  ; RES  6,D
                  DEFB Unknown_instr / 256  ; RES  6,E
                  DEFB Unknown_instr / 256  ; RES  6,H
                  DEFB Unknown_instr / 256  ; RES  6,L
                  DEFB BitCode_182_index/256; RES  6,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  6,A
                  DEFB Unknown_instr / 256  ; RES  7,B
                  DEFB Unknown_instr / 256  ; RES  7,C
                  DEFB Unknown_instr / 256  ; RES  7,D
                  DEFB Unknown_instr / 256  ; RES  7,E
                  DEFB Unknown_instr / 256  ; RES  7,H
                  DEFB Unknown_instr / 256  ; RES  7,L
                  DEFB BitCode_190_index/256; RES  7,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; RES  7,A
                  DEFB Unknown_instr / 256  ; SET  0,B
                  DEFB Unknown_instr / 256  ; SET  0,C
                  DEFB Unknown_instr / 256  ; SET  0,D
                  DEFB Unknown_instr / 256  ; SET  0,E
                  DEFB Unknown_instr / 256  ; SET  0,H
                  DEFB Unknown_instr / 256  ; SET  0,L
                  DEFB BitCode_198_index/256; SET  0,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  0,A
                  DEFB Unknown_instr / 256  ; SET  1,B
                  DEFB Unknown_instr / 256  ; SET  1,C
                  DEFB Unknown_instr / 256  ; SET  1,D
                  DEFB Unknown_instr / 256  ; SET  1,E
                  DEFB Unknown_instr / 256  ; SET  1,H
                  DEFB Unknown_instr / 256  ; SET  1,L
                  DEFB BitCode_206_index/256; SET  1,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  1,A
                  DEFB Unknown_instr / 256  ; SET  2,B
                  DEFB Unknown_instr / 256  ; SET  2,C
                  DEFB Unknown_instr / 256  ; SET  2,D
                  DEFB Unknown_instr / 256  ; SET  2,E
                  DEFB Unknown_instr / 256  ; SET  2,H
                  DEFB Unknown_instr / 256  ; SET  2,L
                  DEFB BitCode_214_index/256; SET  2,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  2,A
                  DEFB Unknown_instr / 256  ; SET  3,B
                  DEFB Unknown_instr / 256  ; SET  3,C
                  DEFB Unknown_instr / 256  ; SET  3,D
                  DEFB Unknown_instr / 256  ; SET  3,E
                  DEFB Unknown_instr / 256  ; SET  3,H
                  DEFB Unknown_instr / 256  ; SET  3,L
                  DEFB BitCode_222_index/256; SET  3,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  3,A
                  DEFB Unknown_instr / 256  ; SET  4,B
                  DEFB Unknown_instr / 256  ; SET  4,C
                  DEFB Unknown_instr / 256  ; SET  4,D
                  DEFB Unknown_instr / 256  ; SET  4,E
                  DEFB Unknown_instr / 256  ; SET  4,H
                  DEFB Unknown_instr / 256  ; SET  4,L
                  DEFB BitCode_230_index/256; SET  4,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  4,A
                  DEFB Unknown_instr / 256  ; SET  5,B
                  DEFB Unknown_instr / 256  ; SET  5,C
                  DEFB Unknown_instr / 256  ; SET  5,D
                  DEFB Unknown_instr / 256  ; SET  5,E
                  DEFB Unknown_instr / 256  ; SET  5,H
                  DEFB Unknown_instr / 256  ; SET  5,L
                  DEFB BitCode_238_index/256; SET  5,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  5,A
                  DEFB Unknown_instr / 256  ; SET  6,B
                  DEFB Unknown_instr / 256  ; SET  6,C
                  DEFB Unknown_instr / 256  ; SET  6,D
                  DEFB Unknown_instr / 256  ; SET  6,E
                  DEFB Unknown_instr / 256  ; SET  6,H
                  DEFB Unknown_instr / 256  ; SET  6,L
                  DEFB BitCode_246_index/256; SET  6,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  6,A
                  DEFB Unknown_instr / 256  ; SET  7,B
                  DEFB Unknown_instr / 256  ; SET  7,C
                  DEFB Unknown_instr / 256  ; SET  7,D
                  DEFB Unknown_instr / 256  ; SET  7,E
                  DEFB Unknown_instr / 256  ; SET  7,H
                  DEFB Unknown_instr / 256  ; SET  7,L
                  DEFB BitCode_254_index/256; SET  7,(IX/IY+d)
                  DEFB Unknown_instr / 256  ; SET  7,A


; ******************************************************************************
;
;    $ED Virtual Z80 instruction routine lookup table, low byte address
;
.EDInstrTable     DEFB Unknown_instr  % 256  ; 0
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256  ; 10
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256  ; 20
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256  ; 30
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256  ; 40
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256  ; 50
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256  ; 60
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB EDcode_64  % 256      ; IN   B,(C)
                  DEFB EDcode_65  % 256      ; OUT  (C),B
                  DEFB EDcode_66  % 256      ; SBC  HL,BC
                  DEFB EDcode_67  % 256      ; LD   (nn),BC
                  DEFB EDcode_68  % 256      ; NEG
                  DEFB Opcode_201 % 256      ; RETN  (interpret as RET)    (69)
                  DEFB EDcode_70  % 256      ; IM   0
                  DEFB EDcode_71  % 256      ; LD   I,A
                  DEFB EDcode_72  % 256      ; IN   C,(C)
                  DEFB EDcode_73  % 256      ; OUT  (C),C
                  DEFB EDcode_74  % 256      ; ADC  HL,BC
                  DEFB EDcode_75  % 256      ; LD   BC,(nn)
                  DEFB Unknown_instr  % 256  ; (76)
                  DEFB Opcode_201 % 256      ; RETI  (interpret as RET)    (77)
                  DEFB Unknown_instr  % 256  ; (78)
                  DEFB EDcode_79  % 256      ; LD   R,A
                  DEFB EDcode_80  % 256      ; IN   D,(C)
                  DEFB EDcode_81  % 256      ; OUT  (C),D
                  DEFB EDcode_82  % 256      ; SBC  HL,DE
                  DEFB EDcode_83  % 256      ; LD   (nn),DE
                  DEFB Unknown_instr  % 256  ; (84)
                  DEFB Unknown_instr  % 256  ; (85)
                  DEFB EDcode_86  % 256      ; IM   1
                  DEFB EDcode_87  % 256      ; LD   A,I
                  DEFB EDcode_88  % 256      ; IN   E,(C)
                  DEFB EDcode_89  % 256      ; OUT  (C),E
                  DEFB EDcode_90  % 256      ; ADC  HL,DE
                  DEFB EDcode_91  % 256      ; LD   DE,(nn)
                  DEFB Unknown_instr  % 256  ; (92)
                  DEFB Unknown_instr  % 256  ; (93)
                  DEFB EDcode_94  % 256      ; IM   2
                  DEFB EDcode_95  % 256      ; LD   A,R
                  DEFB EDcode_96  % 256      ; IN   H,(C)
                  DEFB EDcode_97  % 256      ; OUT  (C),H
                  DEFB EDcode_98  % 256      ; SBC  HL,HL
                  DEFB Opcode_34  % 256      ; LD   (nn),HL  (main)
                  DEFB Unknown_instr  % 256  ; (100)
                  DEFB Unknown_instr  % 256  ; (101)
                  DEFB Unknown_instr  % 256  ; (102)
                  DEFB EDcode_103 % 256      ; RRD
                  DEFB EDcode_104 % 256      ; IN   L,(C)
                  DEFB EDcode_105 % 256      ; OUT  (C),L
                  DEFB EDcode_106 % 256      ; ADC  HL,HL
                  DEFB Opcode_42 % 256       ; LD   HL,(nn)  (main)
                  DEFB Unknown_instr  % 256  ; (108)
                  DEFB Unknown_instr  % 256  ; (109)
                  DEFB Unknown_instr  % 256  ; (110)
                  DEFB EDcode_111 % 256      ; RLD
                  DEFB EDcode_112 % 256      ; IN   F,(C)
                  DEFB Unknown_instr  % 256  ; (113)
                  DEFB EDcode_114 % 256      ; SBC  HL,SP
                  DEFB EDcode_115 % 256      ; LD   (nn),SP
                  DEFB Unknown_instr  % 256  ; (116)
                  DEFB Unknown_instr  % 256  ; (117)
                  DEFB Unknown_instr  % 256  ; (118)
                  DEFB Unknown_instr  % 256  ; (119)
                  DEFB EDcode_120 % 256      ; IN   A,(C)
                  DEFB EDcode_121 % 256      ; OUT  (C),A
                  DEFB EDcode_122 % 256      ; ADC  HL,SP
                  DEFB EDcode_123 % 256      ; LD   SP,(nn)
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB EDcode_160 % 256      ; LDI
                  DEFB EDcode_161 % 256      ; CPI
                  DEFB EDcode_162 % 256      ; INI
                  DEFB EDcode_163 % 256      ; OUTI
                  DEFB Unknown_instr  % 256  ; (164)
                  DEFB Unknown_instr  % 256  ; (165)
                  DEFB Unknown_instr  % 256  ; (166)
                  DEFB Unknown_instr  % 256  ; (167)
                  DEFB EDcode_168 % 256      ; LDD
                  DEFB EDcode_169 % 256      ; CPD
                  DEFB EDcode_170 % 256      ; IND
                  DEFB EDcode_171 % 256      ; OUTD
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB Unknown_instr  % 256  ;
                  DEFB EDcode_176 % 256      ; LDIR
                  DEFB EDcode_177 % 256      ; CPIR
                  DEFB EDcode_178 % 256      ; INIR
                  DEFB EDcode_179 % 256      ; OTIR
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB EDcode_184 % 256     ; LDDR
                  DEFB EDcode_185 % 256     ; CPDR
                  DEFB EDcode_186 % 256     ; INDR
                  DEFB EDcode_187 % 256     ; OTDR
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 190
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 200
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 210
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 220
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 230
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 240
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 250
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256
                  DEFB Unknown_instr  % 256 ; 255

; ******************************************************************************
;
;    $ED Virtual Z80 instruction routine lookup table, high byte address
;
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_64  / 256      ; IN   B,(C)
                  DEFB EDcode_65  / 256      ; OUT  (C),B
                  DEFB EDcode_66  / 256      ; SBC  HL,BC
                  DEFB EDcode_67  / 256      ; LD   (nn),BC
                  DEFB EDcode_68  / 256      ; NEG
                  DEFB Opcode_201 / 256      ; RETN  (interpret as RET)
                  DEFB EDcode_70  / 256      ; IM   0
                  DEFB EDcode_71  / 256      ; LD   I,A
                  DEFB EDcode_72  / 256      ; IN   C,(C)
                  DEFB EDcode_73  / 256      ; OUT  (C),C
                  DEFB EDcode_74  / 256      ; ADC  HL,BC
                  DEFB EDcode_75  / 256      ; LD   BC,(nn)
                  DEFB Unknown_instr  / 256
                  DEFB Opcode_201 / 256      ; RETI  (Interpret as RET)
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_79  / 256      ; LD   R,A
                  DEFB EDcode_80  / 256      ; IN   D,(C)
                  DEFB EDcode_81  / 256      ; OUT  (C),D
                  DEFB EDcode_82  / 256      ; SBC  HL,DE
                  DEFB EDcode_83  / 256      ; LD   (nn),DE
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_86  / 256      ; IM   1
                  DEFB EDcode_87  / 256      ; LD   A,I
                  DEFB EDcode_88  / 256      ; IN   E,(C)
                  DEFB EDcode_89  / 256      ; OUT  (C),E
                  DEFB EDcode_90  / 256      ; ADC  HL,DE
                  DEFB EDcode_91  / 256      ; LD   DE,(nn)
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_94  / 256      ; IM   2
                  DEFB EDcode_95  / 256      ; LD   A,R
                  DEFB EDcode_96  / 256      ; IN   H,(C)
                  DEFB EDcode_97  / 256      ; OUT  (C),H
                  DEFB EDcode_98  / 256      ; SBC  HL,HL
                  DEFB Opcode_34  / 256      ; LD   (nn),HL  (main)
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_103 / 256     ; RRD
                  DEFB EDcode_104 / 256     ; IN   L,(C)
                  DEFB EDcode_105 / 256     ; OUT  (C),L
                  DEFB EDcode_106 / 256     ; ADC  HL,HL
                  DEFB Opcode_42 / 256      ; LD   HL,(nn)  (main)
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_111 / 256     ; RLD
                  DEFB EDcode_112 / 256     ; IN   F,(C)
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_114 / 256     ; SBC  HL,SP
                  DEFB EDcode_115 / 256     ; LD   (nn),SP
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_120 / 256     ; IN   A,(C)
                  DEFB EDcode_121 / 256     ; OUT  (C),A
                  DEFB EDcode_122 / 256     ; ADC  HL,SP
                  DEFB EDcode_123 / 256     ; LD   SP,(nn)
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_160 / 256     ; LDI
                  DEFB EDcode_161 / 256     ; CPI
                  DEFB EDcode_162 / 256     ; INI
                  DEFB EDcode_163 / 256     ; OUTI
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_168 / 256     ; LDD
                  DEFB EDcode_169 / 256     ; CPD
                  DEFB EDcode_170 / 256     ; IND
                  DEFB EDcode_171 / 256     ; OUTD
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_176 / 256     ; LDIR
                  DEFB EDcode_177 / 256     ; CPIR
                  DEFB EDcode_178 / 256     ; INIR
                  DEFB EDcode_179 / 256     ; OTIR
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB EDcode_184 / 256     ; LDDR
                  DEFB EDcode_185 / 256     ; CPDR
                  DEFB EDcode_186 / 256     ; INDR
                  DEFB EDcode_187 / 256     ; OTDR
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 190
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 200
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 210
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 220
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 230
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 240
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 250
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256
                  DEFB Unknown_instr  / 256 ; 255


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
.Unknown_instr    SET  Flg_RTM_error,(IY + FlagStat2)    ; indicate runtime error          ** V1.01
                  LD   (IY + RTMerror), ERR_unknown_instr
                  RET                                    ; back to monitor_loop            ** V1.01



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
                  LD   L,(IY+22)
                  LD   H,(IY+23)
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
                  LD   L,(IY+22)
                  LD   H,(IY+23)
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
                  LD   (IY + Flagstat1), 2^Flg_IntWin       ; Use Intuition window #1

                  ; Status byte 2:
                  LD   (IY + FlagStat2), 2^Flg_RTM_Trace    ; Single Step mode

                  ; Status byte 3:
                  LD   (IY + FlagStat3), 2^Flg_WinMode | 2^Flg_DZopcode ;                      ** V0.26e
                  RET

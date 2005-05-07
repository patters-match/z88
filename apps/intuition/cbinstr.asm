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

    MODULE Bit_instructions

    ; Global routines defined in this module:
    XDEF Bitcode_0, Bitcode_1, Bitcode_2, Bitcode_3, Bitcode_4, Bitcode_5, Bitcode_6, Bitcode_7
    XDEF Bitcode_8, Bitcode_9, Bitcode_10, Bitcode_11, Bitcode_12, Bitcode_13, Bitcode_14, Bitcode_15
    XDEF Bitcode_16, Bitcode_17, Bitcode_18, Bitcode_19, Bitcode_20, Bitcode_21, Bitcode_22, Bitcode_23
    XDEF Bitcode_24, Bitcode_25, Bitcode_26, Bitcode_27, Bitcode_28, Bitcode_29, Bitcode_30, Bitcode_31
    XDEF Bitcode_32, Bitcode_33, Bitcode_34, Bitcode_35, Bitcode_36, Bitcode_37, Bitcode_38, Bitcode_39
    XDEF Bitcode_40, Bitcode_41, Bitcode_42, Bitcode_43, Bitcode_44, Bitcode_45, Bitcode_46, Bitcode_47
    XDEF Bitcode_56, Bitcode_57, Bitcode_58, Bitcode_59, Bitcode_60, Bitcode_61, Bitcode_62, Bitcode_63
    XDEF Bitcode_64, Bitcode_65, Bitcode_66, Bitcode_67, Bitcode_68, Bitcode_69, Bitcode_70, Bitcode_71
    XDEF Bitcode_72, Bitcode_73, Bitcode_74, Bitcode_75, Bitcode_76, Bitcode_77, Bitcode_78, Bitcode_79
    XDEF Bitcode_80, Bitcode_81, Bitcode_82, Bitcode_83, Bitcode_84, Bitcode_85, Bitcode_86, Bitcode_87
    XDEF Bitcode_88, Bitcode_89, Bitcode_90, Bitcode_91, Bitcode_92, Bitcode_93, Bitcode_94, Bitcode_95
    XDEF Bitcode_96, Bitcode_97, Bitcode_98, Bitcode_99, Bitcode_100, Bitcode_101, Bitcode_102, Bitcode_103
    XDEF Bitcode_104, Bitcode_105, Bitcode_106, Bitcode_107, Bitcode_108, Bitcode_109, Bitcode_110, Bitcode_111
    XDEF Bitcode_112, Bitcode_113, Bitcode_114, Bitcode_115, Bitcode_116, Bitcode_117, Bitcode_118, Bitcode_119
    XDEF Bitcode_120, Bitcode_121, Bitcode_122, Bitcode_123, Bitcode_124, Bitcode_125, Bitcode_126, Bitcode_127
    XDEF Bitcode_128, Bitcode_129, Bitcode_130, Bitcode_131, Bitcode_132, Bitcode_133, Bitcode_134, Bitcode_135
    XDEF Bitcode_136, Bitcode_137, Bitcode_138, Bitcode_139, Bitcode_140, Bitcode_141, Bitcode_142, Bitcode_143
    XDEF Bitcode_144, Bitcode_145, Bitcode_146, Bitcode_147, Bitcode_148, Bitcode_149, Bitcode_150, Bitcode_151
    XDEF Bitcode_152, Bitcode_153, Bitcode_154, Bitcode_155, Bitcode_156, Bitcode_157, Bitcode_158, Bitcode_159
    XDEF Bitcode_160, Bitcode_161, Bitcode_162, Bitcode_163, Bitcode_164, Bitcode_165, Bitcode_166, Bitcode_167
    XDEF Bitcode_168, Bitcode_169, Bitcode_170, Bitcode_171, Bitcode_172, Bitcode_173, Bitcode_174, Bitcode_175
    XDEF Bitcode_176, Bitcode_177, Bitcode_178, Bitcode_179, Bitcode_180, Bitcode_181, Bitcode_182, Bitcode_183
    XDEF Bitcode_184, Bitcode_185, Bitcode_186, Bitcode_187, Bitcode_188, Bitcode_189, Bitcode_190, Bitcode_191
    XDEF Bitcode_192, Bitcode_193, Bitcode_194, Bitcode_195, Bitcode_196, Bitcode_197, Bitcode_198, Bitcode_199
    XDEF Bitcode_200, Bitcode_201, Bitcode_202, Bitcode_203, Bitcode_204, Bitcode_205, Bitcode_206, Bitcode_207
    XDEF Bitcode_208, Bitcode_209, Bitcode_210, Bitcode_211, Bitcode_212, Bitcode_213, Bitcode_214, Bitcode_215
    XDEF Bitcode_216, Bitcode_217, Bitcode_218, Bitcode_219, Bitcode_220, Bitcode_221, Bitcode_222, Bitcode_223
    XDEF Bitcode_224, Bitcode_225, Bitcode_226, Bitcode_227, Bitcode_228, Bitcode_229, Bitcode_230, Bitcode_231
    XDEF Bitcode_232, Bitcode_233, Bitcode_234, Bitcode_235, Bitcode_236, Bitcode_237, Bitcode_238, Bitcode_239
    XDEF Bitcode_240, Bitcode_241, Bitcode_242, Bitcode_243, Bitcode_244, Bitcode_245, Bitcode_246, Bitcode_247
    XDEF Bitcode_248, Bitcode_249, Bitcode_250, Bitcode_251, Bitcode_252, Bitcode_253, Bitcode_254, Bitcode_255

    XDEF bitcode_6_index, bitcode_14_index, bitcode_22_index, bitcode_30_index, bitcode_38_index, bitcode_46_index
    XDEF bitcode_62_index, bitcode_70_index, bitcode_78_index, bitcode_86_index, bitcode_94_index, bitcode_102_index
    XDEF bitcode_110_index, bitcode_118_index, bitcode_126_index, bitcode_134_index, bitcode_142_index
    XDEF bitcode_150_index, bitcode_158_index, bitcode_166_index, bitcode_174_index, bitcode_182_index
    XDEF bitcode_190_index, bitcode_198_index, bitcode_206_index, bitcode_214_index, bitcode_222_index
    XDEF bitcode_230_index, bitcode_238_index, bitcode_246_index, bitcode_254_index

    XREF Calc_RelAddress


    INCLUDE "defs.h"


; NB: All $CB instructions are entered with virtual AF installed


; ******************************************************************
; Global service routine for (HL) related CB instructions
; Return virtual cached HL in main register set
;
;       AFBCDE../IXIY  same
;       ......HL/....  different
;
.Get_vHL
                  EXX                       ; ** V1.1.1
                  PUSH BC                   ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  POP  HL                   ; ** V1.1.1
                  RET


; ******************************************************************
;
; RLC  B
;
.BitCode_0        RLC  (IY + VP_B)
                  RET


; ******************************************************************
;
; RLC  C
;
.BitCode_1        RLC  (IY + VP_C)
                  RET


; ******************************************************************
;
; RLC  D
;
.BitCode_2        RLC  (IY + VP_D)
                  RET


; ******************************************************************
;
; RLC  E                                    2 bytes
;
.BitCode_3        RLC  (IY + VP_E)
                  RET


; ******************************************************************
;
; RLC  H                                    2 bytes
;
.BitCode_4
                  EXX                       ; ** V1.1.1
                  RLC  B                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RLC  L                                    2 bytes
;
.BitCode_5
                  EXX                       ; ** V1.1.1
                  RLC  C                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RLC  (HL)                                 2 bytes
;
.BitCode_6        CALL Get_vHL              ; ** V1.1.1
                  RLC  (HL)                 ; ** V1.1.1
                  RET



; ******************************************************************
;
; RLC  (IX+d)                               4 bytes
; RLC  (IX+d)                               4 bytes
;
.BitCode_6_index  CALL CB_IXIY_disp         ; ** V1.04
                  RLC  (HL)
                  RET


; ******************************************************************
;
; RLC  A                                    2 bytes
;
.BitCode_7        RLCA
                  RET


; ******************************************************************
;
; RRC  B                                    2 bytes
;
.BitCode_8        RRC  (IY + VP_B)
                  RET


; ******************************************************************
;
; RRC  C                                    2 bytes
;
.BitCode_9        RRC  (IY + VP_C)
                  RET


; ******************************************************************
;
; RRC  D                                    2 bytes
;
.BitCode_10       RRC  (IY + VP_D)
                  RET


; ******************************************************************
;
; RRC  E                                    2 bytes
;
.BitCode_11       RRC  (IY + VP_E)
                  RET


; ******************************************************************
;
; RRC  H                                    2 bytes
;
.BitCode_12
                  EXX                       ; ** V1.1.1
                  RRC  B                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RRC  L                                    2 bytes
;
.BitCode_13
                  EXX                       ; ** V1.1.1
                  RRC  C                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RRC  (HL)                                 2 bytes
;
.BitCode_14
                  CALL Get_vHL              ; ** V1.1.1
                  RRC  (HL)                 ; ** V1.1.1
                  RET

; ******************************************************************
;
; RRC  (IX+d)                               4 bytes
; RRC  (IY+d)                               4 bytes
;
.BitCode_14_index CALL CB_IXIY_disp
                  RRC  (HL)
                  RET


; ******************************************************************
;
; RRC  A                                    2 bytes
;
.BitCode_15       RRCA                      ; ** V0.23
                  RET


; ******************************************************************
;
; RL   B                                    2 bytes
;
.BitCode_16       RL   (IY + VP_B)
                  RET


; ******************************************************************
;
; RL   C                                    2 bytes
;
.BitCode_17       RL   (IY + VP_C)
                  RET


; ******************************************************************
;
; RL   D                                    2 bytes
;
.BitCode_18       RL   (IY + VP_D)
                  RET


; ******************************************************************
;
; RL   E                                    2 bytes
;
.BitCode_19       RL   (IY + VP_E)
                  RET


; ******************************************************************
;
; RL   H                                    2 bytes
;
.BitCode_20
                  EXX                       ; ** V1.1.1
                  RL   B                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RL   L                                    2 bytes
;
.BitCode_21
                  EXX                       ; ** V1.1.1
                  RL   C                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RL   (HL)                                  2 bytes
;
.BitCode_22
                  CALL Get_vHL              ; ** V1.1.1
                  RL   (HL)                 ; ** V1.1.1
                  RET

; ******************************************************************
;
; RL   (IX+d)                                4 bytes
; RL   (IY+d)                                4 bytes
;
.BitCode_22_index CALL CB_IXIY_disp          ; ** V1.04
                  RL   (HL)
                  RET


; ******************************************************************
;
; RL   A                                    2 bytes
;
.BitCode_23       RLA                       ; ** V0.23
                  RET


; ******************************************************************
;
; RR   B                                    2 bytes
;
.BitCode_24       RR   (IY + VP_B)
                  RET


; ******************************************************************
;
; RR   C                                    2 bytes
;
.BitCode_25       RR   (IY + VP_C)
                  RET


; ******************************************************************
;
; RR   D                                    2 bytes
;
.BitCode_26       RR   (IY + VP_D)
                  RET


; ******************************************************************
;
; RR   E                                    2 bytes
;
.BitCode_27       RR   (IY + VP_E)
                  RET


; ******************************************************************
;
; RR   H                                    2 bytes
;
.BitCode_28
                  EXX                       ; ** V1.1.1
                  RR   B                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RR   L                                    2 bytes
;
.BitCode_29
                  EXX                       ; ** V1.1.1
                  RR   C                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; RR   (HL)                                 2 bytes
;
.BitCode_30
                  CALL Get_vHL              ; ** V1.1.1
                  RR   (HL)                 ; ** V1.1.1
                  RET


; ******************************************************************
;
; RR   (IX+d)                               4 bytes
; RR   (IY+d)                               4 bytes
;
.BitCode_30_index CALL CB_IXIY_disp         ; ** V1.04
                  RR  (HL)
                  RET


; ******************************************************************
;
; RR   A                                    2 bytes
;
.BitCode_31       RRA                       ; ** V0.23
                  RET


; ******************************************************************
;
; SLA  B                                    2 bytes
;
.BitCode_32       SLA  (IY + VP_B)
                  RET


; ******************************************************************
;
; SLA  C                                    2 bytes
;
.BitCode_33       SLA  (IY + VP_C)
                  RET


; ******************************************************************
;
; SLA  D                                    2 bytes
;
.BitCode_34       SLA  (IY + VP_D)
                  RET


; ******************************************************************
;
; SLA  E                                    2 bytes
;
.BitCode_35       SLA  (IY + VP_E)
                  RET


; ******************************************************************
;
; SLA  H                                    2 bytes
;
.BitCode_36
                  EXX                       ; ** V1.1.1
                  SLA  B                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; SLA  L                                    2 bytes
;
.BitCode_37
                  EXX                       ; ** V1.1.1
                  SLA  C                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; SLA  (HL)                                 2 bytes
;
.BitCode_38
                  CALL Get_vHL              ; ** V1.1.1
                  SLA  (HL)                 ; ** V1.1.1
                  RET

; ******************************************************************
;
; SLA  (IX+d)                               4 bytes
; SLA  (IY+d)                               4 bytes
;
.BitCode_38_index CALL CB_IXIY_disp         ; ** V1.04
                  SLA  (HL)
                  RET

; ******************************************************************
;
; SLA  A                                    2 bytes
;
.BitCode_39       SLA  A                    ; ** V0.23
                  RET


; ******************************************************************
;
; SRA  B                                    2 bytes
;
.BitCode_40       SRA  (IY + VP_B)
                  RET


; ******************************************************************
;
; SRA  C                                    2 bytes
;
.BitCode_41       SRA  (IY + VP_C)
                  RET


; ******************************************************************
;
; SRA  D                                    2 bytes
;
.BitCode_42       SRA  (IY + VP_D)
                  RET


; ******************************************************************
;
; SRA  E                                    2 bytes
;
.BitCode_43       SRA  (IY + VP_E)
                  RET


; ******************************************************************
;
; SRA  H                                    2 bytes
;
.BitCode_44
                  EXX                       ; ** V1.1.1
                  SRA  B                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; SRA  L                                    2 bytes
;
.BitCode_45
                  EXX                       ; ** V1.1.1
                  SRA  C                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; SRA  (HL)                                 2 bytes
;
.BitCode_46
                  CALL Get_vHL              ; ** V1.1.1
                  SRA  (HL)                 ; ** V1.1.1
                  RET


; ******************************************************************
;
; SRA  (IX+d)                               4 bytes
; SRA  (IY+d)                               4 bytes
;
.BitCode_46_index CALL CB_IXIY_disp
                  SRA  (HL)
                  RET


; ******************************************************************
;
; SRA  A                                    2 bytes
;
.BitCode_47       SRA  A                    ; ** V0.23
                  RET


; ******************************************************************
;
; SRL  B                                    2 bytes
;
.BitCode_56       SRL  (IY + VP_B)
                  RET


; ******************************************************************
;
; SRL  C                                    2 bytes
;
.BitCode_57       SRL  (IY + VP_C)
                  RET


; ******************************************************************
;
; SRL  D                                    2 bytes
;
.BitCode_58       SRL  (IY + VP_D)
                  RET


; ******************************************************************
;
; SRL  E                                    2 bytes
;
.BitCode_59       SRL  (IY + VP_E)
                  RET


; ******************************************************************
;
; SRL  H                                    2 bytes
;
.BitCode_60
                  EXX                       ; ** V1.1.1
                  SRL  B                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; SRL  L                                    2 bytes
;
.BitCode_61
                  EXX                       ; ** V1.1.1
                  SRL  C                    ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; SRL  (HL)                                 2 bytes
;
.BitCode_62
                  CALL Get_vHL              ; ** V1.1.1
                  SRL  (HL)                 ; ** V1.1.1
                  RET


; ******************************************************************
;
; SRL  (IX+d)                               4 bytes
; SRL  (IY+d)                               4 bytes
;
.BitCode_62_index CALL CB_IXIY_disp
                  SRL  (HL)
                  RET


; ******************************************************************
;
; SRL  A                                    2 bytes
;
.BitCode_63       SRL  A
                  RET


; ******************************************************************
;
; BIT  0,B                                  2 bytes
;
.BitCode_64       BIT  0,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  0,C                                  2 bytes
;
.BitCode_65       BIT  0,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  0,D                                  2 bytes
;
.BitCode_66       BIT  0,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  0,E                                  2 bytes
;
.BitCode_67       BIT  0,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  0,H                                  2 bytes
;
.BitCode_68
                  EXX                       ; ** V1.1.1
                  BIT  0,B                  ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; BIT  0,L                                  2 bytes
;
.BitCode_69
                  EXX                       ; ** V1.1.1
                  BIT  0,C                  ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; BIT  0,(HL)                               2 bytes
;
.BitCode_70
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  0,(HL)               ; ** V1.1.1
                  RET

; ******************************************************************
;
; BIT  0,(IX+d)                             4 bytes
; BIT  0,(IY+d)                             4 bytes
;
.BitCode_70_index CALL CB_IXIY_disp
                  BIT  0,(HL)               ;
                  RET


; ******************************************************************
;
; BIT  0,A                                  2 bytes
;
.BitCode_71       BIT  0,A                  ; A                               ** V0.23
                  RET



; ******************************************************************
;
; BIT  1,B                                  2 bytes
;
.BitCode_72       BIT  1,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  1,C                                  2 bytes
;
.BitCode_73       BIT  1,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  1,D                                  2 bytes
;
.BitCode_74       BIT  1,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  1,E                                  2 bytes
;
.BitCode_75       BIT  1,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  1,H                                  2 bytes
;
.BitCode_76       EXX                       ; ** V1.1.1
                  BIT  1,B                  ; ** V1.04
                  EXX
                  RET


; ******************************************************************
;
; BIT  1,L                                  2 bytes
;
.BitCode_77       EXX
                  BIT  1,C                  ; ** V1.1.1
                  EXX
                  RET


; ******************************************************************
;
; BIT  1,(HL)                               2 bytes
;
.BitCode_78
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  1,(HL)               ; ** V1.1.1
                  RET


; ******************************************************************
;
; BIT  1,(IX+d)                             4 bytes
; BIT  1,(IY+d)                             4 bytes
;
.BitCode_78_index CALL CB_IXIY_disp         ; ** V1.04
                  BIT  1,(HL)               ; ** V1.04
                  RET


; ******************************************************************
;
; BIT  1,A                                  2 bytes
;
.BitCode_79       BIT  1,A
                  RET



; ******************************************************************
;
; BIT  2,B                                  2 bytes
;
.BitCode_80       BIT  2,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  2,C                                  2 bytes
;
.BitCode_81       BIT  2,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  2,D                                  2 bytes
;
.BitCode_82       BIT  2,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  2,E                                  2 bytes
;
.BitCode_83       BIT  2,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  2,H                                  2 bytes
;
.BitCode_84       EXX                       ; ** V1.1.1
                  BIT  2,B                  ; ** V1.04
                  EXX
                  RET


; ******************************************************************
;
; BIT  2,L                                  2 bytes
;
.BitCode_85       EXX                       ; ** V1.1.1
                  BIT  2,C                  ; ** V1.1.1
                  EXX                       ; ** V1.1.1
                  RET


; ******************************************************************
;
; BIT  2,(HL)                               2 bytes
;
.BitCode_86
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  2,(HL)               ; ** V1.1.1
                  RET

; ******************************************************************
;
; BIT  2,(IX+d)                             4 bytes
; BIT  2,(IY+d)                             4 bytes
;
.BitCode_86_index CALL CB_IXIY_disp
                  BIT  2,(HL)               ; ** V0.23
                  RET


; ******************************************************************
;
; BIT  2,A                                  2 bytes
;
.BitCode_87       BIT  2,A
                  RET



; ******************************************************************
;
; BIT  3,B                                  2 bytes
;
.BitCode_88       BIT  3,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  3,C                                  2 bytes
;
.BitCode_89       BIT  3,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  3,D                                  2 bytes
;
.BitCode_90       BIT  3,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  3,E                                  2 bytes
;
.BitCode_91       BIT  3,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  3,H                                  2 bytes
;
.BitCode_92       EXX
                  BIT  3,B                  ; ** V1.04
                  EXX
                  RET


; ******************************************************************
;
; BIT  3,L                                  2 bytes
;
.BitCode_93       EXX
                  BIT  3,C                  ; ** V1.04
                  EXX
                  RET


; ******************************************************************
;
; BIT  3,(HL)                               2 bytes
;
.BitCode_94
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  3,(HL)               ; ** V1.1.1
                  RET


; ******************************************************************
;
; BIT  3,(IX+d)                             4 bytes
; BIT  3,(IY+d)                             4 bytes
;
.BitCode_94_index CALL CB_IXIY_disp         ; ** V0.16
                  BIT  3,(HL)               ; ** V0.23
                  RET


; ******************************************************************
;
; BIT  3,A                                  2 bytes
;
.BitCode_95       BIT  3,A
                  RET



; ******************************************************************
;
; BIT  4,B                                  2 bytes
;
.BitCode_96       BIT  4,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  4,C                                  2 bytes
;
.BitCode_97       BIT  4,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  4,D                                  2 bytes
;
.BitCode_98       BIT  4,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  4,E                                  2 bytes
;
.BitCode_99       BIT  4,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  4,H                                  2 bytes
;
.BitCode_100      EXX
                  BIT  4,B                  ; ** V1.04
                  EXX
                  RET


; ******************************************************************
;
; BIT  4,L                                  2 bytes
;
.BitCode_101      EXX
                  BIT  4,C                  ; ** V1.1.1
                  EXX
                  RET


; ******************************************************************
;
; BIT  4,(HL)                               2 bytes
;
.BitCode_102
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  4,(HL)               ; ** V1.1.1
                  RET


; ******************************************************************
;
; BIT  4,(IX+d)                             4 bytes
; BIT  4,(IY+d)                             4 bytes
;
.BitCode_102_index
                  CALL CB_IXIY_disp         ;                                 ** V0.16
                  BIT  4,(HL)               ;                                 ** V0.23
                  RET


; ******************************************************************
;
; BIT  4,A                                  2 bytes
;
.BitCode_103      BIT  4,A
                  RET


; ******************************************************************
;
; BIT  5,B                                  2 bytes
;
.BitCode_104      BIT  5,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  5,C                                  2 bytes
;
.BitCode_105      BIT  5,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  5,D                                  2 bytes
;
.BitCode_106      BIT  5,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  5,E                                  2 bytes
;
.BitCode_107      BIT  5,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  5,H                                  2 bytes
;
.BitCode_108      EXX
                  BIT  5,B
                  EXX
                  RET


; ******************************************************************
;
; BIT  5,L                                  2 bytes
;
.BitCode_109      EXX
                  BIT  5,C
                  EXX
                  RET


; ******************************************************************
;
; BIT  5,(HL)                               2 bytes
;
.BitCode_110
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  5,(HL)               ; ** V1.1.1
                  RET

; ******************************************************************
;
; BIT  5,(IX+d)                             4 bytes
; BIT  5,(IY+d)                             4 bytes
;
.BitCode_110_index
                  CALL CB_IXIY_disp         ; ** V0.16
                  BIT  5,(HL)               ; ** V0.23
                  RET


; ******************************************************************
;
; BIT  5,A                                  2 bytes
;
.BitCode_111      BIT  5,A
                  RET


; ******************************************************************
;
; BIT  6,B                                  2 bytes
;
.BitCode_112      BIT  6,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  6,C                                  2 bytes
;
.BitCode_113      BIT  6,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  6,D                                  2 bytes
;
.BitCode_114      BIT  6,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  6,E                                  2 bytes
;
.BitCode_115      BIT  6,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  6,H                                  2 bytes
;
.BitCode_116      EXX
                  BIT  6,B                  ; ** V1.04
                  EXX
                  RET


; ******************************************************************
;
; BIT  6,L                                  2 bytes
;
.BitCode_117      EXX
                  BIT  6,C                  ; ** V1.04
                  EXX
                  RET


; ******************************************************************
;
; BIT  6,(HL)                               2 bytes
;
.BitCode_118
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  6,(HL)               ; ** V1.1.1
                  RET


; ******************************************************************
;
; BIT  6,(IX+d)                             4 bytes
; BIT  6,(IY+d)                             4 bytes
;
.BitCode_118_index
                  CALL CB_IXIY_disp
                  BIT  6,(HL)               ; ** V0.23
                  RET


; ******************************************************************
;
; BIT  6,A                                  2 bytes
;
.BitCode_119      BIT  6,A
                  RET


; ******************************************************************
;
; BIT  7,B                                  2 bytes
;
.BitCode_120      BIT  7,(IY + VP_B)
                  RET


; ******************************************************************
;
; BIT  7,C                                  2 bytes
;
.BitCode_121      BIT  7,(IY + VP_C)
                  RET


; ******************************************************************
;
; BIT  7,D                                  2 bytes
;
.BitCode_122      BIT  7,(IY + VP_D)
                  RET


; ******************************************************************
;
; BIT  7,E                                  2 bytes
;
.BitCode_123      BIT  7,(IY + VP_E)
                  RET


; ******************************************************************
;
; BIT  7,H                                  2 bytes
;
.BitCode_124      EXX
                  BIT  7,B                  ; ** V1.1.1
                  EXX
                  RET


; ******************************************************************
;
; BIT  7,L                                  2 bytes
;
.BitCode_125      EXX
                  BIT  7,C                  ; ** V1.1.1
                  EXX
                  RET


; ******************************************************************
;
; BIT  7,(HL)                               2 bytes
;
.BitCode_126
                  CALL Get_vHL              ; ** V1.1.1
                  BIT  7,(HL)               ; ** V1.1.1
                  RET

; ******************************************************************
;
; BIT  7,(IX+d)                             4 bytes
; BIT  7,(IY+d)                             4 bytes
;
.BitCode_126_index
                  CALL CB_IXIY_disp         ; ** V0.16
                  BIT  7,(HL)               ; ** V0.23
                  RET


; ******************************************************************
;
; BIT  7,A                                  2 bytes
;
.BitCode_127      BIT  7,A
                  RET


; *********************************************************************************
;
; RES  0,B
;
.BitCode_128      RES  0,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  0,C
;
.BitCode_129      RES  0,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  0,D
;
.BitCode_130      RES  0,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  0,E
;
.BitCode_131      RES  0,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  0,H
;
.BitCode_132      EXX
                  RES  0,B
                  EXX
                  RET


; *********************************************************************************
;
; RES  0,L
;
.BitCode_133      EXX
                  RES  0,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  0,(HL)
;
.BitCode_134
                  CALL Get_vHL               ; ** V1.1.1
                  RES  0,(HL)                ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  0,(IX+d)                             4 bytes
; RES  0,(IY+d)                             4 bytes
;
.BitCode_134_index
                  LD   E, @11111110         ;                                 ** V0.28
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  0,A
;
.BitCode_135      RES  0,A
                  RET


; *********************************************************************************
;
; RES  1,B
;
.BitCode_136      RES  1,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  1,C
;
.BitCode_137      RES  1,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  1,D
;
.BitCode_138      RES  1,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  1,E
;
.BitCode_139      RES  1,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  1,H
;
.BitCode_140      EXX
                  RES  1,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  1,L
;
.BitCode_141      EXX
                  RES  1,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  1,(HL)
;
.BitCode_142
                  CALL Get_vHL              ; ** V1.1.1
                  RES  1,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  1,(IX+d)
; RES  1,(IY+d)
;
.BitCode_142_index
                  LD   E, @11111101         ;                                 ** V0.28
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  1,A
;
.BitCode_143      RES  1,A
                  RET


; *********************************************************************************
;
; RES  2,B
;
.BitCode_144      RES  2,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  2,C
;
.BitCode_145      RES  2,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  2,D
;
.BitCode_146      RES  2,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  2,E
;
.BitCode_147      RES  2,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  2,H
;
.BitCode_148      EXX
                  RES  2,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  2,L
;
.BitCode_149      EXX
                  RES  2,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  2,(HL)
;
.BitCode_150
                  CALL Get_vHL              ; ** V1.1.1
                  RES  2,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  2,(IX+d)
; RES  2,(IY+d)
;
.BitCode_150_index
                  LD   E, @11111011         ;                                 ** V0.16
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  2,A
;
.BitCode_151      RES  2,A
                  RET


; *********************************************************************************
;
; RES  3,B
;
.BitCode_152      RES  3,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  3,C
;
.BitCode_153      RES  3,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  3,D
;
.BitCode_154      RES  3,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  3,E
;
.BitCode_155      RES  3,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  3,H
;
.BitCode_156      EXX
                  RES  3,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  3,L
;
.BitCode_157      EXX
                  RES  3,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  3,(HL)
;
.BitCode_158
                  CALL Get_vHL              ; ** V1.1.1
                  RES  3,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  3,(IX+d)
; RES  3,(IY+d)
;
.BitCode_158_index
                  LD   E, @11110111         ;                                 ** V0.28
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  3,A
;
.BitCode_159      RES  3,A
                  RET


; *********************************************************************************
;
; RES  4,B
;
.BitCode_160      RES  4,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  4,C
;
.BitCode_161      RES  4,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  4,D
;
.BitCode_162      RES  4,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  4,E
;
.BitCode_163      RES  4,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  4,H
;
.BitCode_164      EXX
                  RES  4,B                  ; ** V1.04
                  EXX
                  RET


; *********************************************************************************
;
; RES  4,L
;
.BitCode_165      EXX
                  RES  4,C                  ; ** V1.04
                  EXX
                  RET


; *********************************************************************************
;
; RES  4,(HL)
;
.BitCode_166
                  CALL Get_vHL              ; ** V1.1.1
                  RES  4,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  4,(IX+d)
; RES  4,(IY+d)
;
.BitCode_166_index
                  LD   E, @11101111         ;                                 ** V0.28
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  4,A
;
.BitCode_167      RES  4,A
                  RET


; *********************************************************************************
;
; RES  5,B
;
.BitCode_168      RES  5,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  5,C
;
.BitCode_169      RES  5,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  5,D
;
.BitCode_170      RES  5,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  5,E
;
.BitCode_171      RES  5,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  5,H
;
.BitCode_172      EXX
                  RES  5,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  5,L
;
.BitCode_173      EXX
                  RES  5,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  5,(HL)
;
.BitCode_174
                  CALL Get_vHL              ; ** V1.1.1
                  RES  5,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  5,(IX+d)
; RES  5,(IY+d)
;
.BitCode_174_index
                  LD   E, @11011111         ;                                 ** V0.28
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  5,A
;
.BitCode_175      RES  5,A
                  RET


; *********************************************************************************
;
; RES  6,B
;
.BitCode_176      RES  6,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  6,C
;
.BitCode_177      RES  6,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  6,D
;
.BitCode_178      RES  6,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  6,E
;
.BitCode_179      RES  6,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  6,H
;
.BitCode_180      EXX
                  RES  6,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  6,L
;
.BitCode_181      EXX
                  RES  6,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  6,(HL)
;
.BitCode_182
                  CALL Get_vHL              ; ** V1.1.1
                  RES  6,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  6,(IX+d)
; RES  6,(IY+d)
;
.BitCode_182_index
                  LD   E, @10111111         ;                                 ** V0.28
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  6,A
;
.BitCode_183      RES  6,A
                  RET


; *********************************************************************************
;
; RES  7,B
;
.BitCode_184      RES  7,(IY + VP_B)
                  RET


; *********************************************************************************
;
; RES  7,C
;
.BitCode_185      RES  7,(IY + VP_C)
                  RET


; *********************************************************************************
;
; RES  7,D
;
.BitCode_186      RES  7,(IY + VP_D)
                  RET


; *********************************************************************************
;
; RES  7,E
;
.BitCode_187      RES  7,(IY + VP_E)
                  RET


; *********************************************************************************
;
; RES  7,H
;
.BitCode_188      EXX
                  RES  7,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  7,L
;
.BitCode_189      EXX
                  RES  7,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; RES  7,(HL)
;
.BitCode_190
                  CALL Get_vHL              ; ** V1.1.1
                  RES  7,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; RES  7,(IX+d)
; RES  7,(IY+d)
;
.BitCode_190_index
                  LD   E, @01111111         ;                                 ** V0.28
                  JP   Res_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; RES  7,A
;
.BitCode_191      RES  7,A
                  RET



; *********************************************************************************
;
; SET  0,B
;
.BitCode_192      SET  0,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  0,C
;
.BitCode_193      SET  0,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  0,D
;
.BitCode_194      SET  0,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  0,E
;
.BitCode_195      SET  0,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  0,H
;
.BitCode_196      EXX
                  SET  0,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  0,L
;
.BitCode_197      EXX
                  SET  0,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  0,(HL)
;
.BitCode_198
                  CALL Get_vHL              ; ** V1.1.1
                  SET  0,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  0,(IX+d)
; SET  0,(IY+d)
;
.BitCode_198_index
                  LD   E, @00000001         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  0,A
;
.BitCode_199      SET  0,A
                  RET


; *********************************************************************************
;
; SET  1,B
;
.BitCode_200      SET  1,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  1,C
;
.BitCode_201      SET  1,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  1,D
;
.BitCode_202      SET  1,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  1,E
;
.BitCode_203      SET  1,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  1,H
;
.BitCode_204      EXX
                  SET  1,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  1,L
;
.BitCode_205      EXX
                  SET  1,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  1,(HL)
;
.BitCode_206
                  CALL Get_vHL              ; ** V1.1.1
                  SET  1,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  1,(IX+d)
; SET  1,(IY+d)
;
.BitCode_206_index
                  LD   E, @00000010         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  1,A
;
.BitCode_207      SET  1,A
                  RET


; *********************************************************************************
;
; SET  2,B
;
.BitCode_208      SET  2,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  2,C
;
.BitCode_209      SET  2,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  2,D
;
.BitCode_210      SET  2,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  2,E
;
.BitCode_211      SET  2,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  2,H
;
.BitCode_212      EXX
                  SET  2,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  2,L
;
.BitCode_213      EXX
                  SET  2,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  2,(HL)
;
.BitCode_214
                  CALL Get_vHL              ; ** V1.1.1
                  SET  2,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  2,(IX+d)
; SET  2,(IY+d)
;
.BitCode_214_index
                  LD   E, @00000100         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  2,A
;
.BitCode_215      SET  2,A
                  RET


; *********************************************************************************
;
; SET  3,B
;
.BitCode_216      SET  3,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  3,C
;
.BitCode_217      SET  3,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  3,D
;
.BitCode_218      SET  3,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  3,E
;
.BitCode_219      SET  3,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  3,H
;
.BitCode_220      EXX
                  SET  3,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  3,L
;
.BitCode_221      EXX
                  SET  3,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  3,(HL)
;
.BitCode_222
                  CALL Get_vHL              ; ** V1.1.1
                  SET  3,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  3,(IX+d)
; SET  3,(IY+d)
;
.BitCode_222_index
                  LD   E, @00001000         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  3,A
;
.BitCode_223      SET  3,A
                  RET


; *********************************************************************************
;
; SET  4,B
;
.BitCode_224      SET  4,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  4,C
;
.BitCode_225      SET  4,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  4,D
;
.BitCode_226      SET  4,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  4,E
;
.BitCode_227      SET  4,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  4,H
;
.BitCode_228      EXX
                  SET  4,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  4,L
;
.BitCode_229      EXX
                  SET  4,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  4,(HL)
;
.BitCode_230
                  CALL Get_vHL              ; ** V1.1.1
                  SET  4,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  4,(IX+d)
; SET  4,(IY+d)
;
.BitCode_230_index
                  LD   E, @00010000         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  4,A
;
.BitCode_231      SET  4,A
                  RET


; *********************************************************************************
;
; SET  5,B
;
.BitCode_232      SET  5,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  5,C
;
.BitCode_233      SET  5,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  5,D
;
.BitCode_234      SET  5,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  5,E
;
.BitCode_235      SET  5,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  5,H
;
.BitCode_236      EXX
                  SET  5,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  5,L
;
.BitCode_237      EXX
                  SET  5,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  5,(HL)
;
.BitCode_238
                  CALL Get_vHL              ; ** V1.1.1
                  SET  5,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  5,(IX+d)
; SET  5,(IY+d)
;
.BitCode_238_index
                  LD   E, @00100000         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  5,A
;
.BitCode_239      SET  5,A
                  RET


; *********************************************************************************
;
; SET  6,B
;
.BitCode_240      SET  6,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  6,C
;
.BitCode_241      SET  6,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  6,D
;
.BitCode_242      SET  6,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  6,E
;
.BitCode_243      SET  6,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  6,H
;
.BitCode_244      EXX
                  SET  6,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  6,L
;
.BitCode_245      EXX
                  SET  6,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  6,(HL)
;
.BitCode_246
                  CALL Get_vHL              ; ** V1.1.1
                  SET  6,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  6,(IX+d)
; SET  6,(IY+d)
;
.BitCode_246_index
                  LD   E, @01000000         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  6,A
;
.BitCode_247      SET  6,A
                  RET


; *********************************************************************************
;
; SET  7,B
;
.BitCode_248      SET  7,(IY + VP_B)
                  RET


; *********************************************************************************
;
; SET  7,C
;
.BitCode_249      SET  7,(IY + VP_C)
                  RET


; *********************************************************************************
;
; SET  7,D
;
.BitCode_250      SET  7,(IY + VP_D)
                  RET


; *********************************************************************************
;
; SET  7,E
;
.BitCode_251      SET  7,(IY + VP_E)
                  RET


; *********************************************************************************
;
; SET  7,H
;
.BitCode_252      EXX
                  SET  7,B                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  7,L
;
.BitCode_253      EXX
                  SET  7,C                  ; ** V1.1.1
                  EXX
                  RET


; *********************************************************************************
;
; SET  7,(HL)
;
.BitCode_254
                  CALL Get_vHL              ; ** V1.1.1
                  SET  7,(HL)               ; ** V1.1.1
                  RET


; *********************************************************************************
;
; SET  7,(IX+d)
; SET  7,(IY+d)
;
.BitCode_254_index
                  LD   E, @10000000         ;                                 ** V0.28
                  JP   Set_HLBitX           ;                                 ** V0.16


; *********************************************************************************
;
; SET  7,A
;
.BitCode_255      SET  7,A
                  RET


; *******************************************************************************
;
; CB HL/Index instructions indirect pointer
; V0.27e
;
.CB_IXIY_disp     EX   AF,AF'               ; swap to instruction opcode      ** V0.29
                  CP   $FD
                  JR   Z, CB_IY_disp
                  LD   L,(IY + VP_IX)       ; get contents of IX
                  LD   H,(IY + VP_IX+1)
                  LD   A,(IY+ExecBuffer)    ; get displacement                ** V1.1.1
                  CALL Calc_RelAddress
                  EX   AF,AF'               ; swap to virtual AF              ** V0.29
                  RET                       ;                                 ** V0.29
.CB_IY_disp       LD   L,(IY + VP_IY)       ; get contents of IY
                  LD   H,(IY + VP_IY+1)
                  LD   A,(IY+ExecBuffer)    ; get displacement                ** V1.1.1
                  CALL Calc_RelAddress
                  EX   AF,AF'               ; swap to virtual AF              ** V0.29
                  RET                       ;                                 ** V0.29


; **********************************************************************************
;
; RESET bit number X (as defined in D) in memory cell pointed out HL, IX or IY.
;
;  IN: E (bit number)                       e.g. RES 6,(IX+d) = @10111111
;
; V0.16
.Res_HLBitX      CALL CB_IXIY_disp          ; get memory pointer (IX+d,IY+d)
                 EX   AF,AF'                ; swap to instruction opcode        ** V0.29
                 LD   A,(HL)                ; fetch byte
                 AND  E                     ; mask out bit number               ** V0.28
                 LD   (HL),A
                 EX   AF,AF'
                 RET                        ;                                   ** V0.29


; **********************************************************************************
;
; SET bit number X (as defined in D) in memory cell pointed out IX or IY.
;
;  IN: E (bit number)                       e.g. SET 6,(IX+d) = @01000000
;
; V0.16
.Set_HLBitX      CALL CB_IXIY_disp          ; get memory pointer (IX+d,IY+d)
                 EX   AF,AF'                ;                                   ** V0.29
                 LD   A,(HL)                ; fetch byte
                 OR   E                     ; mask out bit number               ** V0.28
                 LD   (HL),A
                 EX   AF,AF'
                 RET

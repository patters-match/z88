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
;
; ***************************************************************************************************


; ***************************************************************************************************
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

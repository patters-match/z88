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
; ***************************************************************************************************


; ***************************************************************************************************
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
                  DEFB Opcode_118 % 256     ; HALT                            ** V1.1.1
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
                  DEFB CB_instr % 256       ; Bit manipulation instruction decoding ...
                  DEFB Opcode_204 % 256     ; CALL Z, nn
                  DEFB Opcode_205 % 256     ; CALL nn
                  DEFB Opcode_206 % 256     ; ADC  A, n
                  DEFB Opcode_207 % 256     ; RST  $08                        ** V1.2
                  DEFB Opcode_208 % 256     ; RET  NC
                  DEFB Opcode_209 % 256     ; POP  DE
                  DEFB Opcode_210 % 256     ; JP   NC, nn
                  DEFB Opcode_211 % 256     ; OUT  (n),A
                  DEFB Opcode_212 % 256     ; CALL NC, nn
                  DEFB Opcode_213 % 256     ; PUSH DE
                  DEFB Opcode_214 % 256     ; SUB  n
                  DEFB Opcode_215  % 256    ; RST  $10                        ** V1.2
                  DEFB Opcode_216 % 256     ; RET  C
                  DEFB Opcode_217 % 256     ; EXX
                  DEFB Opcode_218 % 256     ; JP   C, nn
                  DEFB Opcode_219 % 256     ; IN   A,(n)
                  DEFB Opcode_220 % 256     ; CALL C, nn
                  DEFB Index_instr % 256    ; IX instruction decoding ...
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
                  DEFB ED_instr % 256       ; ED extended instruction decoding ...
                  DEFB Opcode_238 % 256     ; XOR  n
                  DEFB Opcode_239 % 256     ; RST  $28                        ** V1.2
                  DEFB Opcode_240 % 256     ; RET  P
                  DEFB Opcode_241 % 256     ; POP  AF
                  DEFB Opcode_242 % 256     ; JP   P, nn
                  DEFB Opcode_243 % 256     ; DI                              ** V1.2
                  DEFB Opcode_244 % 256     ; CALL P, nn
                  DEFB Opcode_245 % 256     ; PUSH AF
                  DEFB Opcode_246 % 256     ; OR   n
                  DEFB Opcode_247 % 256     ; RST  $30                        ** V1.2
                  DEFB Opcode_248 % 256     ; RET  M
                  DEFB Opcode_249 % 256     ; LD   SP,HL
                  DEFB Opcode_250 % 256     ; JP   M, nn
                  DEFB Opcode_251 % 256     ; EI                              ** V1.2
                  DEFB Opcode_252 % 256     ; CALL M, nn
                  DEFB Index_instr % 256    ; IY instruction decoding ...
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
                  DEFB Opcode_118 / 256     ; HALT                            ** V1.1.1
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
                  DEFB CB_instr / 256       ; Bit manipulation instruction decoding...
                  DEFB Opcode_204 / 256     ; CALL Z, nn
                  DEFB Opcode_205 / 256     ; CALL nn
                  DEFB Opcode_206 / 256     ; ADC  A, n
                  DEFB Opcode_207 / 256     ; RST  $08                        ** V1.2
                  DEFB Opcode_208 / 256     ; RET  NC
                  DEFB Opcode_209 / 256     ; POP  DE
                  DEFB Opcode_210 / 256     ; JP   NC, nn
                  DEFB Opcode_211 / 256     ; OUT  (n),A
                  DEFB Opcode_212 / 256     ; CALL NC, nn
                  DEFB Opcode_213 / 256     ; PUSH DE
                  DEFB Opcode_214 / 256     ; SUB  n
                  DEFB Opcode_215 / 256     ; RST  $10                        ** V1.2
                  DEFB Opcode_216 / 256     ; RET  C
                  DEFB Opcode_217 / 256     ; EXX
                  DEFB Opcode_218 / 256     ; JP   C, nn
                  DEFB Opcode_219 / 256     ; IN   A,(n)
                  DEFB Opcode_220 / 256     ; CALL C, nn
                  DEFB Index_instr / 256    ; IX instruction decoding ...
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
                  DEFB ED_instr / 256       ; ED extended instruction decoding ...
                  DEFB Opcode_238 / 256     ; XOR  n
                  DEFB Opcode_239 / 256     ; RST  $28                        ** V1.2
                  DEFB Opcode_240 / 256     ; RET  P
                  DEFB Opcode_241 / 256     ; POP  AF
                  DEFB Opcode_242 / 256     ; JP   P, nn
                  DEFB Opcode_243 / 256     ; DI                              ** V1.2
                  DEFB Opcode_244 / 256     ; CALL P, nn
                  DEFB Opcode_245 / 256     ; PUSH AF
                  DEFB Opcode_246 / 256     ; OR   n
                  DEFB Opcode_247 / 256     ; RST  $30                        ** V1.2
                  DEFB Opcode_248 / 256     ; RET  M
                  DEFB Opcode_249 / 256     ; LD   SP,HL
                  DEFB Opcode_250 / 256     ; JP   M, nn
                  DEFB Opcode_251 / 256     ; EI                              ** V1.2
                  DEFB Opcode_252 / 256     ; CALL M, nn
                  DEFB Index_instr / 256    ; IY instruction decoding ...
                  DEFB Opcode_254 / 256     ; CP   n
                  DEFB Opcode_0   / 256     ; RST  $38                        ** V0.16

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
;***************************************************************************************************

    MODULE Arithlog_Instructions

    ; Routines defined in 'stdinstr.asm':
    XREF Select_IXIY, Select_IXIY_disp

    ; Routines defined in 'arithlog.asm':
    XDEF Opcode_3, Opcode_4, Opcode_5, Opcode_7, Opcode_9, Opcode_11, Opcode_12, Opcode_13
    XDEF Opcode_15, Opcode_19, Opcode_20, Opcode_21, Opcode_23, Opcode_25, Opcode_27, Opcode_28
    XDEF Opcode_29, Opcode_31, Opcode_35, Opcode_36, Opcode_37, Opcode_39, Opcode_41, Opcode_43
    XDEF Opcode_44, Opcode_45, Opcode_47, Opcode_51, Opcode_52, Opcode_53, Opcode_55, Opcode_57
    XDEF Opcode_59, Opcode_60, Opcode_61, Opcode_63, Opcode_128, Opcode_129, Opcode_130
    XDEF Opcode_131, Opcode_132
    XDEF Opcode_133, Opcode_134, Opcode_135, Opcode_136, Opcode_137, Opcode_138, Opcode_139, Opcode_140
    XDEF Opcode_141, Opcode_142, Opcode_143, Opcode_144, Opcode_145, Opcode_146, Opcode_147, Opcode_148
    XDEF Opcode_149, Opcode_150, Opcode_151, Opcode_152, Opcode_153, Opcode_154, Opcode_155, Opcode_156
    XDEF Opcode_157, Opcode_158, Opcode_159, Opcode_160, Opcode_161, Opcode_162, Opcode_163, Opcode_164
    XDEF Opcode_165, Opcode_166, Opcode_167, Opcode_168, Opcode_169, Opcode_170, Opcode_171
    XDEF Opcode_172, Opcode_173, Opcode_174, Opcode_175, Opcode_176, Opcode_177, Opcode_178, Opcode_179
    XDEF Opcode_180, Opcode_181, Opcode_182, Opcode_183, Opcode_184, Opcode_185, Opcode_186, Opcode_187
    XDEF Opcode_188, Opcode_189, Opcode_190, Opcode_191, Opcode_198, Opcode_206, Opcode_214, Opcode_222
    XDEF Opcode_230, Opcode_238, Opcode_246, Opcode_254

    XDEF Opcode_134_index, Opcode_142_index, Opcode_150_index, Opcode_158_index, Opcode_166_index
    XDEF Opcode_174_index, Opcode_182_index, Opcode_190_index, Opcode_52_index, Opcode_53_index
    XDEF Opcode_35_index, Opcode_43_index, Opcode_9_index, Opcode_25_index, Opcode_41_index
    XDEF Opcode_57_index


    INCLUDE "defs.h"



; ****************************************************************************
;
; RLCA            instruction               1 byte
;
.Opcode_7         EX   AF,AF'               ; get AF register                 ** V0.23
                  RLCA
                  EX   AF,AF'
                  RET


; ****************************************************************************
;
; RRCA            instruction               1 byte
;
.Opcode_15        EX    AF,AF'              ; AF                              ** V0.23
                  RRCA
                  EX    AF,AF'              ; AF                              ** V0.23
                  RET


; ****************************************************************************
;
; RLA             instruction               1 byte
;
.Opcode_23        EX   AF,AF'               ; AF                              ** V0.23
                  RLA
                  EX   AF,AF'               ; AF                              ** V0.23
                  RET


; ****************************************************************************
;
; RRA             instruction               1 byte
;
.Opcode_31        EX   AF,AF'               ; AF                              ** V0.23
                  RRA
                  EX   AF,AF'               ; AF                              ** V0.23
                  RET


; ****************************************************************************
;
; DAA             instruction               1 byte
;
.Opcode_39        EX   AF,AF'               ; AF                              ** V0.23
                  DAA
                  EX   AF,AF'               ; AF                              ** V0.23
                  RET


; ****************************************************************************
;
; CPL             instruction               1 byte
;
.Opcode_47        EX   AF,AF'               ;                                 ** V0.23
                  CPL
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; **********************************************************************************
;
; SCF                                       1 byte
;
.Opcode_55        EX   AF,AF'               ; get F                           ** V0.23
                  SCF                       ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ****************************************************************************
;
; CCF             instruction               1 byte
;
.Opcode_63        EX   AF,AF'               ;                                 ** V0.23
                  CCF                       ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A, n       instruction               2 bytes
;
.Opcode_198       EXX                       ;                                 ** V0.28
                  EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,(HL)               ; n                               ** V0.28
                  EX   AF,AF'
                  INC  HL                   ; PC++
                  EXX                       ;                                 ** V0.28
                  RET

; ***************************************************************************
;
; ADC  A, n       instruction               2 bytes
;
.Opcode_206       EXX                       ;                                 ** V0.28
                  EX    AF,AF'              ; get AF                          ** V0.23
                  ADC   A,(HL)              ; ADC  A,n                        ** V0.23/V0.28
                  EX    AF,AF'              ;                                 ** V0.23
                  INC   HL                  ; PC++                            ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; SUB   n         instruction               2 bytes
;
.Opcode_214       EXX                       ;                                 ** V0.28
                  EX    AF,AF'              ; get AF                          ** V0.23
                  SUB   (HL)                ; SUB  n                          ** V0.23/V0.28
                  EX    AF,AF'              ;                                 ** V0.23
                  INC   HL                  ; PC++                            ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; SBC  A, n       instruction               2 bytes
;
.Opcode_222       EXX                       ;                                 ** V0.28
                  EX    AF,AF'              ; get AF                          ** V0.23
                  SBC   A,(HL)              ; SBC  A,n                        ** V0.23/V0.28
                  EX    AF,AF'              ;                                 ** V0.23
                  INC   HL                  ; PC++                            ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; AND  n          instruction               2 bytes
;
.Opcode_230       EXX                       ;                                 ** V0.28
                  EX    AF,AF'              ; get AF                          ** V0.23
                  AND   (HL)                ; AND  n                          ** V0.23/V0.28
                  EX    AF,AF'              ;                                 ** V0.23
                  INC   HL                  ; PC++                            ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; XOR  n       instruction                  2 bytes
;
.Opcode_238       EXX                       ;                                 ** V0.28
                  EX   AF,AF'               ; get AF                          ** V0.23
                  XOR  (HL)                 ; XOR  n                          ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  INC  HL                   ; PC++                            ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; OR   n          instruction                  2 bytes
;
.Opcode_246       EXX                       ;                                 ** V0.28
                  EX   AF,AF'               ; get AF                          ** V0.23
                  OR   (HL)                 ; OR   n                          ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  INC  HL                   ; PC++                            ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; CP   n          instruction               2 bytes
;
.Opcode_254       EXX                       ;                                 ** V0.28
                  EX   AF,AF'               ; get AF                          ** V0.23
                  CP   (HL)                 ; CP   n                          ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  INC  HL                   ; PC++                            ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; ADD  A,B        instruction               1 byte
;
.Opcode_128       EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,(IY + VP_B)        ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A,C        instruction               1 byte
;
.Opcode_129       EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,(IY + VP_C)        ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A,D        instruction               1 byte
;
.Opcode_130       EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,(IY + VP_D)        ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A,E        instruction               1 byte
;
.Opcode_131       EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,(IY + VP_E)        ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A,H        instruction               1 byte
;
.Opcode_132       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  ADD  A,B                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A,L        instruction               1 byte
;
.Opcode_133       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  ADD  A,C                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A,(HL)     instruction               1 byte
;
.Opcode_134
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,B                  ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; ***************************************************************************
;
; ADD  A,(IX+d)   instruction               3 byte
; ADD  A,(IY+d)   instruction               3 byte
;
.Opcode_134_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,(HL)               ;                                 ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADD  A,A        instruction               1 byte
;
.Opcode_135       EX   AF,AF'               ; get AF                          ** V0.23
                  ADD  A,A                  ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADC  A,B        instruction               1 byte
;
.Opcode_136       EX   AF,AF'               ; get AF                          ** V0.23
                  ADC  A,(IY + VP_B)        ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADC  A,C        instruction               1 byte
;
.Opcode_137       EX   AF,AF'               ; get AF                          ** V0.23
                  ADC  A,(IY + VP_C)        ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADC  A,D        instruction               1 byte
;
.Opcode_138       EX   AF,AF'               ; get AF                          ** V0.23
                  ADC  A,(IY + VP_D)        ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADC  A,E        instruction               1 byte
;
.Opcode_139       EX   AF,AF'               ; get AF                          ** V0.23
                  ADC  A,(IY + VP_E)        ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADC  A,H        instruction               1 byte
;
.Opcode_140       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  ADC  A,B                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADC  A,L        instruction               1 byte
;
.Opcode_141       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  ADC  A,C                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; ADC  A,(HL)     instruction               1 byte
;
.Opcode_142
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  ADC  A,B                  ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; ***************************************************************************
;
; ADC  A,(IX+d)   instruction               3 byte
; ADC  A,(IY+d)   instruction               3 byte
;
.Opcode_142_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  ADC  A,(HL)               ; ...
                  EX   AF,AF'
                  RET


; ***************************************************************************
;
; ADC  A,A        instruction               1 byte
;
.Opcode_143       EX   AF,AF'               ; get AF                          ** V0.23
                  ADC  A,A                  ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  B          instruction                 1 byte
;
.Opcode_144       EX   AF,AF'               ; get AF                          ** V0.23
                  SUB  (IY + VP_B)          ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  C          instruction                 1 byte
;
.Opcode_145       EX   AF,AF'               ; get AF                          ** V0.23
                  SUB  (IY + VP_C)          ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  D          instruction               1 byte
;
.Opcode_146       EX   AF,AF'               ; get AF                          ** V0.23
                  SUB  (IY + VP_D)          ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  E          instruction               1 byte
;
.Opcode_147       EX   AF,AF'               ; get AF                          ** V0.23
                  SUB  (IY + VP_E)          ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  H          instruction               1 byte
;
.Opcode_148       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  SUB  B                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  L          instruction               1 byte
;
.Opcode_149       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  SUB  C                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  (HL)        instruction              1 byte
;
.Opcode_150
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  SUB  B                    ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SUB  (IX+d)     instruction               3 byte
; SUB  (IY+d)     instruction               3 byte
;
.Opcode_150_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  SUB  (HL)
                  EX   AF,AF'
                  RET


; ***************************************************************************
;
; SUB  A          instruction               1 byte
;
.Opcode_151       EX   AF,AF'               ; get A                           ** V0.23
                  SUB  A                    ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SBC  A,B        instruction               1 byte
;
.Opcode_152       EX   AF,AF'               ; get AF                          ** V0.23
                  SBC  A,(IY + VP_B)        ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SBC  A,C        instruction               1 byte
;
.Opcode_153       EX   AF,AF'               ; get AF                          ** V0.23
                  SBC  A,(IY + VP_C)        ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SBC  A,D        instruction               1 byte
;
.Opcode_154       EX   AF,AF'               ; get AF                          ** V0.23
                  SBC  A,(IY + VP_D)        ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SBC  A,E        instruction               1 byte
;
.Opcode_155       EX   AF,AF'               ; get AF                          ** V0.23
                  SBC  A,(IY + VP_E)        ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SBC  A,H        instruction               1 byte
;
.Opcode_156       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  SBC  A,B                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SBC  A,L        instruction               1 byte
;
.Opcode_157       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  SBC  A,C                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; SBC  A,(HL)     instruction               1 byte
;
.Opcode_158
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  SBC  A,B                  ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; ***************************************************************************
;
; SBC  A,(IX+d)   instruction               3 byte
; SBC  A,(IY+d)   instruction               3 byte
;
.Opcode_158_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  SBC  A,(HL)               ; ...
                  EX   AF,AF'
                  RET


; ***************************************************************************
;
; SBC  A,A        instruction               1 byte
;
.Opcode_159       EX   AF,AF'               ; get AF                          ** V0.23
                  SBC  A,A                  ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  B          instruction                 1 byte
;
.Opcode_160       EX   AF,AF'               ; get AF                          ** V0.23
                  AND  (IY + VP_B)          ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  C          instruction                 1 byte
;
.Opcode_161       EX   AF,AF'               ; get AF                          ** V0.23
                  AND  (IY + VP_C)          ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  D          instruction               1 byte
;
.Opcode_162       EX   AF,AF'               ; get AF                          ** V0.23
                  AND  (IY + VP_D)          ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  E          instruction               1 byte
;
.Opcode_163       EX   AF,AF'               ; get AF                          ** V0.23
                  AND  (IY + VP_E)          ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  H          instruction               1 byte
;
.Opcode_164       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  AND  B                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  L          instruction               1 byte
;
.Opcode_165       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  AND  C                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  (HL)        instruction              1 byte
;
.Opcode_166
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  AND  B                    ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; AND  (IX+d)     instruction               3 byte
; AND  (IY+d)     instruction               3 byte
;
.Opcode_166_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  AND  (HL)                 ; ...
                  EX   AF,AF'
                  RET


; ***************************************************************************
;
; AND  A          instruction               1 byte
;
.Opcode_167       EX   AF,AF'               ; get AF                          ** V0.23
                  AND  A                    ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  B          instruction               1 byte
;
.Opcode_168       EX   AF,AF'               ; get AF                          ** V0.23
                  XOR  (IY + VP_B)          ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  C        instruction                 1 byte
;
.Opcode_169       EX   AF,AF'               ; get AF                          ** V0.23
                  XOR  (IY + VP_C)          ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  D          instruction               1 byte
;
.Opcode_170       EX   AF,AF'               ; get AF                          ** V0.23
                  XOR  (IY + VP_D)          ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  E          instruction               1 byte
;
.Opcode_171       EX   AF,AF'               ; get AF                          ** V0.23
                  XOR  (IY + VP_E)          ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  H          instruction               1 byte
;
.Opcode_172       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  XOR  B                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  L          instruction               1 byte
;
.Opcode_173       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  XOR  C                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  (HL)        instruction              1 byte
.Opcode_174
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  XOR  B                    ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; XOR  (IX+d)     instruction               3 byte
; XOR  (IY+d)     instruction               3 byte
;
.Opcode_174_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  XOR  (HL)                 ; ...
                  EX   AF,AF'
                  RET


; ***************************************************************************
;
; XOR  A          instruction               1 byte
;
.Opcode_175       EX   AF,AF'               ; get AF                          ** V0.23
                  XOR  A                    ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; OR   B          instruction               1 byte
;
.Opcode_176       EX   AF,AF'               ; get AF                          ** V0.23
                  OR   (IY + VP_B)          ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; OR  C           instruction               1 byte
;
.Opcode_177       EX   AF,AF'               ; get AF                          ** V0.23
                  OR   (IY + VP_C)          ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; OR  D           instruction               1 byte
;
.Opcode_178       EX   AF,AF'               ; get AF                          ** V0.23
                  OR   (IY + VP_D)          ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; OR  E           instruction               1 byte
;
.Opcode_179       EX   AF,AF'               ; get AF                          ** V0.23
                  OR   (IY + VP_E)          ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; OR  H           instruction               1 byte
;
.Opcode_180       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  OR   B                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; OR  L           instruction               1 byte
;
.Opcode_181       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  OR   C                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; OR  (HL)        instruction               1 byte
;
.Opcode_182
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  OR   B                    ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; ***************************************************************************
;
; OR  (IX+d)      instruction               3 byte
; OR  (IY+d)      instruction               3 byte
;
.Opcode_182_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  OR   (HL)                 ; ...
                  EX   AF,AF'
                  RET


; ***************************************************************************
;
; OR  A           instruction               1 byte
;
.Opcode_183       EX   AF,AF'               ;                                 ** V0.23
                  OR   A                    ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET                       ;                                 ** V0.23


; ***************************************************************************
;
; CP  A           instruction               1 byte
;
.Opcode_191       EX   AF,AF'               ; get AF                          ** V0.23
                  CP   A                    ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; CP  B           instruction               1 byte
;
.Opcode_184       EX   AF,AF'               ; get AF                          ** V0.23
                  CP   (IY + VP_B)          ; B                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; CP  C           instruction               1 byte
;
.Opcode_185       EX   AF,AF'               ; get AF                          ** V0.23
                  CP   (IY + VP_C)          ; C                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; CP  D           instruction               1 byte
;
.Opcode_186       EX   AF,AF'               ; get AF                          ** V0.23
                  CP   (IY + VP_D)          ; D                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; CP  E           instruction               1 byte
;
.Opcode_187       EX   AF,AF'               ; get AF                          ** V0.23
                  CP   (IY + VP_E)          ; E                               ** V0.23/V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; CP  H           instruction               1 byte
;
.Opcode_188       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  CP   B                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; CP  L           instruction               1 byte
;
.Opcode_189       EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  CP   C                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; CP  (HL)        instruction               1 byte
;
.Opcode_190
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  CP   B                    ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; ***************************************************************************
;
; CP  (IX+d)      instruction               3 byte
; CP  (IY+d)      instruction               3 byte
;
.Opcode_190_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  CP   (HL)                 ; ...
                  EX   AF,AF'
                  RET


; *****************************************************************************
;
; INC  (HL)       instruction               1 byte
;
.Opcode_52
                  EXX                       ;                                 ** V1.1.1
                  PUSH BC                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  POP  HL                   ;                                 ** V1.1.1
                  INC  (HL)                 ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; *****************************************************************************
;
; INC  (IX + d)   instruction               3 bytes
; INC  (IY + d)
;
.Opcode_52_index  CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  INC  (HL)                 ; ...
                  EX   AF,AF'
                  RET


; *****************************************************************************
;
; DEC  (HL)       instruction               1 byte
;
.Opcode_53
                  EXX                       ;                                 ** V1.1.1
                  PUSH BC                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ; get AF                          ** V0.23
                  POP  HL                   ;                                 ** V1.1.1
                  DEC  (HL)                 ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; *****************************************************************************
;
; DEC  (IX + d)   instruction               3 bytes
; DEC  (IY + d)
;
.Opcode_53_index  CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ; get F                           ** V0.23
                  DEC  (HL)                 ; ...
                  EX   AF,AF'
                  RET


; *****************************************************************************
;
; INC  L                                    1 byte
;
.Opcode_44        EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  INC  C                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; DEC  L          instruction               1 byte
;
.Opcode_45        EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  DEC  C                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; INC  H                                    1 byte
;
.Opcode_36        EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  INC  B                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; DEC  H          instruction               1 byte
;
.Opcode_37        EX   AF,AF'               ; get AF                          ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  DEC  B                    ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; INC  E                                    1 byte
;
.Opcode_28        EX   AF,AF'               ; AF                              ** V0.23
                  INC  (IY + VP_E)
                  EX   AF,AF'               ; AF                              ** V0.23
                  RET


; *****************************************************************************
;
; DEC  E          instruction               1 byte
;
.Opcode_29        EX   AF,AF'               ; AF                              ** V0.23
                  DEC  (IY + VP_E)
                  EX   AF,AF'               ; AF                              ** V0.23
                  RET


; *****************************************************************************
;
; INC  D                                    1 byte
;
.Opcode_20        EX    AF,AF'              ; AF                              ** V0.23
                  INC   (IY + VP_D)
                  EX    AF,AF'              ; AF                              ** V0.23
                  RET


; *****************************************************************************
;
; DEC  D                                    1 byte
;
.Opcode_21        EX    AF,AF'              ; AF                              ** V0.23
                  DEC   (IY + VP_D)
                  EX    AF,AF'              ; AF                              ** V0.23
                  RET


; *****************************************************************************
;
; INC  C                                    1 byte
;
.Opcode_12        EX    AF,AF'              ; AF                              ** V0.23
                  INC   (IY + VP_C)
                  EX    AF,AF'              ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; DEC  C                                    1 byte
;
.Opcode_13        EX    AF,AF'              ; AF                              ** V0.23
                  DEC   (IY + VP_C)
                  EX    AF,AF'              ; AF                              ** V0.23
                  RET


; *****************************************************************************
;
; INC  B                                    1 byte
;
.Opcode_4         EX   AF,AF'               ; get F register                  ** V0.23
                  INC   (IY + VP_B)
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; DEC  B                                    1 byte
;
.Opcode_5         EX   AF,AF'               ; get F register                  ** V0.23
                  DEC  (IY + VP_B)
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; INC  A                                    1 byte
;
.Opcode_60        EX   AF,AF'
                  INC  A
                  EX   AF,AF'
                  RET


; *****************************************************************************
;
; DEC  A          instruction               1 byte
;
.Opcode_61        EX   AF,AF'               ; get AF                          ** V0.23
                  DEC  A                    ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; INC  BC                                   1 byte
;
.Opcode_3         INC  (IY + VP_C)          ; first increase low byte         ** V0.29
                  RET  NZ                   ; no, finished...                 ** V0.29
                  INC  (IY + VP_B)          ; yes, also increase high byte    ** V0.29
                  RET



; *****************************************************************************
;
; DEC  BC                                   1 byte
;
.Opcode_11        LD   A,@11111111          ; set A to overflow bits          ** V0.29
                  DEC  (IY + VP_C)          ; first decrease low byte         ** V0.29
                  CP   (IY + VP_C)          ; overflow?                       ** V0.29
                  RET  NZ                   ; no, finished...                 ** V0.29
                  DEC  (IY + VP_B)          ; yes, also decrease high byte    ** V0.29
                  RET



; *****************************************************************************
;
; INC  DE                                   1 byte
;
.Opcode_19        INC  (IY + VP_E)          ; first increase low byte         ** V0.29
                  RET  NZ                   ; no, finished...                 ** V0.29
                  INC  (IY + VP_D)          ; yes, also increase high byte    ** V0.29
                  RET


; *****************************************************************************
;
; DEC  DE                                   1 byte
;
.Opcode_27        LD   A,@11111111          ; set A to overflow bits          ** V0.29
                  DEC  (IY + VP_E)          ; first decrease low byte         ** V0.29
                  CP   (IY + VP_E)          ; overflow?                       ** V0.29
                  RET  NZ                   ; no, finished...                 ** V0.29
                  DEC  (IY + VP_D)          ; yes, also decrease high byte    ** V0.29
                  RET


; *****************************************************************************
;
; INC  HL                                   1 byte
;
.Opcode_35
                  EXX                       ;                                 ** V1.1.1
                  INC  BC                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; *****************************************************************************
;
; INC  IX                                   2 bytes
; INC  IY                                   2 bytes
;
.Opcode_35_index  CP   $FD
                  JR   Z, inc_iy
.inc_ix           LD   BC, VP_IX            ;                                 ** V1.04
                  JR   inc_rr_35
.inc_iy           LD   BC, VP_IY            ;                                 ** V1.04
.inc_rr_35        PUSH IY
                  POP  HL                   ; HL points at rr                 ** V1.04
                  ADD  HL,BC                ;                                 ** V1.04
                  INC  (HL)                 ; first increase low byte         ** V1.04
                  RET  NZ                   ; no, finished...                 ** V0.29
                  INC  HL                   ;                                 ** V1.04
                  INC  (HL)                 ; yes, also decrease high byte    ** V1.04
                  RET


; *****************************************************************************
;
; DEC  HL                                   1 byte
;
.Opcode_43
                  EXX                       ;                                 ** V1.1.1
                  DEC  BC                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; *****************************************************************************
;
; DEC  IX                                   2 bytes
; DEC  IY                                   2 bytes
;
.Opcode_43_index  CP   $FD
                  JR   Z, dec_iy
                  LD   BC, VP_IX
                  JR   dec_rr_43
.dec_iy           LD   BC, VP_IY
.dec_rr_43        PUSH IY
                  POP  HL                   ; HL points at rr                 ** V1.04
                  ADD  HL,BC                ;                                 ** V1.04
                  LD   A,@11111111          ; set A to overflow bits          ** V0.29
                  DEC  (HL)                 ; first decrease low byte         ** V1.04
                  CP   (HL)                 ; overflow?                       ** V1.04
                  RET  NZ                   ; no, finished...                 ** V0.29
                  INC  HL                   ;                                 ** V1.04
                  DEC  (HL)                 ; yes, also decrease high byte    ** V1.04
                  RET


; *****************************************************************************
;
; INC  SP                                   1 byte
;
.Opcode_51        POP  HL                   ; get return address in HL        ** V0.16/V0.28
                  INC  SP
                  EXX                       ;                                 ** V0.28
                  INC  DE                   ; virtual processor SP increased  ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ;                                 ** V0.16/V0.28


; *****************************************************************************
;
; DEC  SP                                   1 byte
;
.Opcode_59        POP  HL                   ; get return address in HL        ** V0.16/V0.28
                  DEC  SP
                  EXX                       ;                                 ** V0.28
                  DEC  DE                   ; virtual processor SP decreased  ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ;                                 ** V0.16/V0.28


; ******************************************************************************
;
; ADD  HL,BC      instruction               1 byte
;
.Opcode_9
                  EXX                       ;                                 ** V1.1.1
                  PUSH HL                   ; preserve PC                     ** V1.1.1
                  LD   H,B                  ;                                 ** V1.1.1
                  LD   L,C                  ;                                 ** V1.1.1
                  LD   C,(IY + VP_C)        ;                                 ** V1.04
                  LD   B,(IY + VP_B)        ;                                 ** V1.04
                  EX   AF,AF'               ; install virtual F               ** V1.04
                  ADD  HL,BC                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  LD   B,H                  ;                                 ** V1.1.1
                  LD   C,L                  ;                                 ** V1.1.1
                  POP  HL                   ; restore PC                      ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ******************************************************************************
;
; ADD  HL,DE      instruction               1 byte
;
.Opcode_25
                  EXX                       ;                                 ** V1.1.1
                  PUSH HL                   ; preserve PC                     ** V1.1.1
                  LD   H,B                  ;                                 ** V1.1.1
                  LD   L,C                  ;                                 ** V1.1.1
                  LD   C,(IY + VP_E)        ;                                 ** V1.04
                  LD   B,(IY + VP_D)        ;                                 ** V1.04
                  EX   AF,AF'               ; install virtual F               ** V1.04
                  ADD  HL,BC                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  LD   B,H                  ;                                 ** V1.1.1
                  LD   C,L                  ;                                 ** V1.1.1
                  POP  HL                   ; restore PC                      ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ******************************************************************************
;
; ADD  HL,HL      instruction               1 byte
;
.Opcode_41
                  EXX                       ;                                 ** V1.1.1
                  PUSH HL                   ; preserve PC                     ** V1.1.1
                  LD   H,B                  ;                                 ** V1.1.1
                  LD   L,C                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; install virtual F               ** V1.04
                  ADD  HL,HL                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  LD   B,H                  ;                                 ** V1.1.1
                  LD   C,L                  ;                                 ** V1.1.1
                  POP  HL                   ; restore PC                      ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ******************************************************************************
;
; ADD  HL,SP      instruction               1 byte
;
.Opcode_57        EXX                       ;                                 ** V0.28
                  PUSH HL                   ; preserve PC                     ** V1.1.1
                  LD   H,B                  ;                                 ** V1.1.1
                  LD   L,C                  ;                                 ** V1.1.1
                  EX   AF,AF'               ; install virtual F               ** V1.04
                  ADD  HL,DE                ; ADD HL,SP                       ** V1.1.1
                  EX   AF,AF'               ;                                 ** V1.04
                  LD   B,H                  ;                                 ** V1.1.1
                  LD   C,L                  ;                                 ** V1.1.1
                  POP  HL                   ; restore PC                      ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET


; ******************************************************************************
;
; ADD  IX | IY, BC instruction              1 byte
;
.Opcode_9_index   LD   C,(IY + VP_C)        ;                                 ** V1.04
                  LD   B,(IY + VP_B)        ;                                 ** V1.04
                  JR   Add_index

; ******************************************************************************
;
; ADD  IX | IY,DE      instruction          2 bytes
;
.Opcode_25_index  LD   C,(IY + VP_E)        ;                                 ** V1.04
                  LD   B,(IY + VP_D)        ;                                 ** V1.04
                  JR   Add_index

; ******************************************************************************
;
;  ADD IX,IX or ADD IY,IY
;
.opcode_41_index  CALL Select_IXIY          ;                                 ** V1.04
                  LD   B,H
                  LD   C,L
                  JR   Add_index

; ******************************************************************************
;
; ADD  IX | IY ,SP      instruction         2 bytes
;
.Opcode_57_index  EXX                       ;                                 ** V0.28
                  PUSH DE                   ;                                 ** V1.04
                  EXX                       ;                                 ** V0.28
                  POP  BC                   ;                                 ** V1.04

; *******************************************************************************
;
;  ADD IX IY , rr
;
; IN : BC  = rr.
;
.Add_index        CP   $DD
                  JR   Z, ix_acc
                  LD   DE, VP_IY
                  JR   fetch_acc
.ix_acc           LD   DE, VP_IX
.fetch_acc        PUSH IY
                  POP  HL
                  ADD  HL,DE                ; HL points at index accumulator

                  LD   E,(HL)
                  INC  HL
                  LD   D,(HL)               ; DE = contents of accumulator (high byte)
                  EX   DE,HL                ; DE points at accumulator...
                  EX   AF,AF'
                  ADD  HL,BC                ; ADD IX|IY,rr
                  EX   AF,AF'               ; preserve virtual AF             ** V0.28
                  EX   DE,HL                ; HL points at accumulator
                  LD   (HL),D               ; store high byte of accumulator
                  DEC  HL
                  LD   (HL),E               ; low byte of...
                  RET

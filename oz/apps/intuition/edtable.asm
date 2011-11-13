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

; ***************************************************************************************************
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

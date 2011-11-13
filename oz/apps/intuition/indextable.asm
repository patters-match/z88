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


; ***************************************************************************************************
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

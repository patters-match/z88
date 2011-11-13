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

    MODULE LD_instructions


    ; Routines defined in 'stdinstr.asm':
    XREF Select_IXIY, Select_IXIY_disp

    ; Global routines defined in 'ldinstr.asm':
    XDEF Opcode_1, Opcode_2, Opcode_6, Opcode_10, Opcode_14, Opcode_17, Opcode_18, Opcode_22
    XDEF Opcode_26, Opcode_30, Opcode_33, Opcode_34, Opcode_38, Opcode_42, Opcode_46, Opcode_49
    XDEF Opcode_50, Opcode_54, Opcode_58, Opcode_62, Opcode_65, Opcode_66, Opcode_67, Opcode_68
    XDEF Opcode_69, Opcode_70, Opcode_71, Opcode_72, Opcode_74, Opcode_75, Opcode_76, Opcode_77
    XDEF Opcode_78, Opcode_79, Opcode_80, Opcode_81, Opcode_83, Opcode_84, Opcode_85, Opcode_86
    XDEF Opcode_87, Opcode_88, Opcode_89, Opcode_90, Opcode_92, Opcode_93, Opcode_94, Opcode_95
    XDEF Opcode_96, Opcode_97, Opcode_98, Opcode_99, Opcode_101, Opcode_102, Opcode_103, Opcode_104
    XDEF Opcode_105, Opcode_106, Opcode_107, Opcode_108, Opcode_110, Opcode_111, Opcode_112, Opcode_113
    XDEF Opcode_114, Opcode_115, Opcode_116, Opcode_117, Opcode_119, Opcode_120, Opcode_121, Opcode_122
    XDEF Opcode_123, Opcode_124, Opcode_125, Opcode_126
    XDEF Opcode_249

    XDEF Opcode_33_index, Opcode_34_index, Opcode_42_index, Opcode_249_index, Opcode_126_index
    XDEF Opcode_54_index, Opcode_70_index, Opcode_78_index, Opcode_86_index, Opcode_94_index
    XDEF Opcode_102_index, Opcode_110_index, Opcode_112_index, Opcode_113_index, Opcode_114_index
    XDEF Opcode_115_index, Opcode_116_index, Opcode_117_index, Opcode_119_index


    INCLUDE "defs.h"


; *****************************************************************************
;
; LD   BC, nn    instruction                3 bytes
;
.Opcode_1         EXX                       ;                                   ** V0.28
                  LD   A,(HL)               ; get low byte for C                ** V1.1.1
                  LD   (IY + VP_C),A        ; save new BC value
                  INC  HL                   ; PC = PC + 1
                  LD   A,(HL)               ; get high byte for B
                  INC  HL                   ; prepare for next instruction
                  LD   (IY + VP_B),A        ;                                   ** V1.1.1
                  EXX                       ;                                   ** V0.28
                  RET


; *****************************************************************************
;
; LD   DE, nn    instruction                3 bytes
;
.Opcode_17        EXX                       ;                                   ** V0.28
                  LD   A,(HL)               ; get low byte for E
                  LD   (IY + VP_E),A        ; save new DE value                 ** V1.1.1
                  INC  HL                   ; PC = PC + 1
                  LD   A,(HL)               ; get high byte for D
                  LD   (IY + VP_D),A        ;                                   ** V1.1.1
                  INC  HL                   ; prepare for next instruction
                  EXX                       ;                                   ** V0.28
                  RET


; *****************************************************************************
;
; LD   HL, nn    instruction                3 bytes
;
.Opcode_33        EXX                       ;                                 ** V0.28
                  LD   C,(HL)               ; get low byte of nn              ** V1.1.1
                  INC  HL                   ;                                 ** V0.27e
                  LD   B,(HL)               ;                                 ** V1.1.1
                  INC  HL                   ;                                 ** V0.27e
                  EXX                       ;                                 ** V0.28
                  RET


; *****************************************************************************
;
; LD   IX, nn    instruction                4 bytes
; LD   IY, nn    instruction                4 bytes
;
.Opcode_33_index
                  CP   $DD
                  JR   Z, operand_to_IX_33
                  EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get low byte of nn              ** V1.1.1
                  LD   (IY + VP_IY)  ,A     ;                                 ** V1.1.1
                  INC  HL                   ;                                 ** V0.27e
                  LD   A,(HL)               ;                                 ** V1.1.1
                  LD   (IY + VP_IY+1),A     ;                                 ** V1.1.1
                  INC  HL                   ;                                 ** V0.27e
                  EXX                       ;                                 ** V0.28
                  RET
.operand_to_IX_33
                  EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get low byte of nn              ** V1.1.1
                  LD   (IY + VP_IX)  ,A     ;                                 ** V1.1.1
                  INC  HL                   ;                                 ** V0.27e
                  LD   A,(HL)               ;                                 ** V1.1.1
                  LD   (IY + VP_IX+1),A     ;                                 ** V1.1.1
                  INC  HL                   ;                                 ** V0.27e
                  EXX                       ;                                 ** V0.28
                  RET


; *****************************************************************************
;
; LD   SP, nn    instruction                3 bytes
;
.Opcode_49        POP  HL                   ; get return address              ** V0.16/V0.28
                  EXX                       ;                                 ** V0.28
                  LD   E,(HL)               ; get low byte SP (DE') address   ** V0.23
                  INC  HL                   ; PC = PC + 1
                  LD   D,(HL)               ; get high byte SP address        ** V0.23
                  INC  HL                   ; prepare for next instruction
                  EX   DE,HL                ;                                 ** V0.24b
                  LD   SP,HL                ; install new Stack Pointer
                  EX   DE,HL                ;                                 ** V0.24b
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ;                                 ** V0.28


; *****************************************************************************
;
; LD   (nn),HL    instruction               3 bytes
;
.Opcode_34        EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual HL             ** V1.1.1
                  LD   C,(HL)               ; get low byte of NN              ** V0.27e
                  INC  HL                   ; PC = PC + 1                     ** V0.27e
                  LD   B,(HL)               ; get high byte of NN             ** V0.27e
                  INC  HL                   ; prepare for next instruction    ** V0.27e
                  EX   (SP),HL              ; get virtual HL (preserve PC)    ** V1.1.1
                  LD   A,L                  ;                                 ** V1.1.1
                  LD   (BC),A               ;                                 ** V1.04
                  INC  BC                   ;                                 ** V1.04
                  LD   A,H                  ;                                 ** V1.1.1
                  LD   (BC),A               ;                                 ** V1.04
                  EX   (SP),HL              ; restore virtual PC              ** V1.1.1
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX
                  RET


; *****************************************************************************
;
; LD   (nn),IX    instruction               4 bytes
; LD   (nn),IY    instruction               4 bytes
;
.Opcode_34_index  EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual HL             ** V1.1.1
                  LD   C,(HL)               ; get low byte of address         ** V0.27e
                  INC  HL                   ; PC = PC + 1                     ** V0.27e
                  LD   B,(HL)               ; get high byte of address        ** V0.27e
                  INC  HL                   ; prepare for next instruction    ** V0.27e
                  PUSH BC
                  EXX                       ; don't destroy PC - use main set
                  POP  DE                   ; nn
                  EXX                       ;                                 ** V1.1.1
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  CALL Select_IXIY          ; get contents of rr into HL (IX or IY)
                  EX   DE,HL                ; HL = nn, DE = contents of rr
                  LD   (HL),E
                  INC  HL
                  LD   (HL),D               ; LD   (nn),rr
                  RET



; *****************************************************************************
;
; LD   HL,(nn)    instruction               3 bytes
;
.Opcode_42        EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual HL             ** V1.1.1
                  LD   C,(HL)               ; get low byte of address         ** V0.27e
                  INC  HL                   ; PC = PC + 1                     ** V0.27e
                  LD   B,(HL)               ; get high byte of address        ** V0.27e
                  INC  HL                   ; prepare for next instruction    ** V0.27e
                  LD   A,(BC)               ;                                 ** V1.04
                  EX   (SP),HL              ; get virtual HL (preserve PC)    ** V1.1.1
                  LD   L,A                  ;                                 ** V1.1.1
                  INC  BC                   ;                                 ** V1.04
                  LD   A,(BC)               ;                                 ** V1.04
                  LD   H,A                  ;                                 ** V1.1.1
                  EX   (SP),HL              ; restore virtual PC              ** V1.1.1
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX
                  RET


; *****************************************************************************
;
; LD   IX,(nn)    instruction               4 bytes
; LD   IY,(nn)    instruction               4 bytes
;
.Opcode_42_index  EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual HL             ** V1.1.1
                  LD   C,(HL)               ; get low byte of address         ** V0.27e
                  INC  HL                   ; PC = PC + 1                     ** V0.27e
                  LD   B,(HL)               ; get high byte of address        ** V0.27e
                  INC  HL                   ; prepare for next instruction    ** V0.27e
                  PUSH BC
                  EXX
                  POP  HL
                  EXX                       ;                                 ** V1.1.1
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   E,(HL)               ;                                 ** V0.27e
                  INC  HL                   ;                                 ** V0.27e
                  LD   D,(HL)               ; DE = (nn)                       ** V0.27e
                  CP   $DD
                  JR   Z, save_to_IX
                  LD   (IY + VP_IY),E       ; save to IY!
                  LD   (IY + VP_IY+1),D
                  RET
.save_to_IX       LD   (IY + VP_IX),E       ; save to IX!
                  LD   (IY + VP_IX+1),D
                  RET



; ************************************************************************************
;
; LD   SP,HL      instruction               1 byte
;
.Opcode_249       POP  HL                   ; get return address              ** V0.16
                  EXX
                  LD   D,B                  ;                                 ** V1.1.1
                  LD   E,C                  ; new virtual SP                  ** V1.1.1
                  PUSH DE                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  POP  IX                   ;                                 ** V1.1.1
                  LD   SP,IX                ; install new stack pointer       ** V1.1.1
                  JP   (HL)                 ;                                 ** V0.16


; ************************************************************************************
;
; LD   SP,IX      instruction               2 byte
; LD   SP,IY
;
.Opcode_249_index POP  DE                   ; get return address              ** V1.04
                  CALL Select_IXIY
                  LD   SP,HL
                  PUSH HL                   ;                                 ** V0.23
                  EXX                       ;                                 ** V0.16
                  POP  DE                   ; new v.p. SP installed           ** V0.23
                  EXX                       ;                                 ** V0.28
                  EX   DE,HL                ;                                 ** V1.04
                  JP   (HL)                 ;                                 ** V1.04


; ********************************************************************************
;
; LD   (BC),A     instruction               1 byte
;
.Opcode_2         LD   C,(IY + VP_C)        ; get original BC
                  LD   B,(IY + VP_B)
                  EX   AF,AF'               ; get A                           ** V0.23
                  LD   (BC),A
                  EX   AF,AF'
                  RET


; *****************************************************************************************
;
; LD   A,(BC)     instruction               1 byte
;
.Opcode_10        LD   C,(IY + VP_C)
                  LD   B,(IY + VP_B)
                  EX   AF,AF'               ; get A                           ** V0.23
                  LD   A,(BC)
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ********************************************************************************
;
; LD   (DE),A                               1 byte
;
.Opcode_18        LD   C,(IY + VP_E)        ; get original DE
                  LD   B,(IY + VP_D)
                  EX   AF,AF'               ; AF                              ** V0.23
                  LD   (BC),A
                  EX   AF,AF'               ; AF                              ** V0.23
                  RET


; *****************************************************************************************
;
; LD   A,(DE)     instruction               1 byte
;
.Opcode_26        LD   C,(IY + VP_E)
                  LD   B,(IY + VP_D)
                  EX   AF,AF'               ; AF                              ** V0.23
                  LD   A,(BC)
                  EX   AF,AF'               ; AF                              ** V0.23
                  RET


; ********************************************************************************
;
; LD   (nn),A                               3 bytes
;
.Opcode_50        EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual HL             ** V1.1.1
                  LD   C,(HL)               ; get low byte of address
                  INC  HL                   ; SP = SP + 1
                  LD   B,(HL)               ; get high byte of address
                  INC  HL                   ; SP = SP + 1 , point at new instruction
                  EX   AF,AF'               ; get A                           ** V0.23
                  LD   (BC),A
                  EX   AF,AF'               ;                                 ** V0.23
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET


; *****************************************************************************
;
; LD   A,(nn)                               3 bytes
;
.Opcode_58        EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual HL             ** V1.1.1
                  LD   C,(HL)
                  INC  HL
                  LD   B,(HL)
                  INC  HL
                  EX   AF,AF'               ; get AF                          ** V0.23
                  LD   A,(BC)
                  EX   AF,AF'               ;                                 ** V0.23
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET


; ***************************************************************************
;
; LD   A,B        instruction               1 byte
;
.Opcode_120       EX   AF,AF'               ; install A                       ** V0.23
                  LD   A,(IY + VP_B)        ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   A,C        instruction               1 byte
;
.Opcode_121       EX   AF,AF'               ; install A                       ** V0.23
                  LD   A,(IY + VP_C)        ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   A,D        instruction               1 byte
;
.Opcode_122       EX   AF,AF'               ; install A                       ** V0.23
                  LD   A,(IY + VP_D)        ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   A,E        instruction               1 byte
;
.Opcode_123       EX   AF,AF'               ; install A                       ** V0.23
                  LD   A,(IY + VP_E)        ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   A,H        instruction               1 byte
;
.Opcode_124       EX   AF,AF'               ; install A                       ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  LD   A,B                  ; get H                           ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   A,L        instruction               1 byte
;
.Opcode_125       EX   AF,AF'               ; install A                       ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  LD   A,C                  ; get L                           ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   A,(HL)     instruction               1 byte
;
.Opcode_126       EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  EX   AF,AF'               ;                                 ** V0.23
                  RET

; ***************************************************************************
;
; LD   A,(IX+d)   instruction               3 byte
; LD   A,(IY+d)   instruction               3 byte
;
.Opcode_126_index CALL Select_IXIY_disp     ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V0.23
                  LD   A,(HL)
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; *****************************************************************************
;
; LD   A, n      instruction                2 bytes
;
.Opcode_62        EXX                       ;                                 ** V0.28
                  EX   AF,AF'               ;                                 ** V0.23
                  LD   A,(HL)               ; get n
                  EX   AF,AF'
                  INC  HL                   ; PC = PC + 1
                  EXX                       ;                                 ** V0.16
                  RET


; *****************************************************************************
;
; LD   B, n      instruction                2 bytes
;
.Opcode_6         EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get n
                  INC  HL                   ; PC = PC + 1
                  EXX                       ;                                 ** V0.28
                  LD   (IY + VP_B),A
                  RET


; *****************************************************************************
;
; LD   C, n      instruction                2 bytes
;
.Opcode_14        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get n
                  INC  HL                   ; PC = PC + 1
                  EXX                       ;                                 ** V0.28
                  LD   (IY + VP_C),A
                  RET


; *****************************************************************************
;
; LD   D, n      instruction                2 bytes
;
.Opcode_22        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get n
                  INC  HL                   ; PC = PC + 1
                  EXX                       ;                                 ** V0.28
                  LD   (IY + VP_D),A
                  RET


; *****************************************************************************
;
; LD   E, n       instruction               2 bytes
;
.Opcode_30        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get n
                  INC  HL                   ; PC = PC + 1
                  EXX                       ;                                 ** V0.28
                  LD   (IY + VP_E),A
                  RET


; *****************************************************************************
;
; LD   H, n      instruction                2 bytes
;
.Opcode_38        EXX                       ;                                 ** V0.28
                  LD   B,(HL)               ; H <- n                          ** V1.1.1
                  INC  HL                   ; PC = PC + 1
                  EXX                       ;                                 ** V0.28
                  RET


; *****************************************************************************
;
; LD   L, n      instruction                2 bytes
;
.Opcode_46        EXX                       ;                                 ** V0.28
                  LD   C,(HL)               ; L <- n                          ** V1.1.1
                  INC  HL                   ; PC = PC + 1
                  EXX                       ;                                 ** V0.28
                  RET


; *****************************************************************************
;
; LD   (HL), n    instruction               2 bytes
;
.Opcode_54        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get n
                  INC  HL                   ; PC++
                  LD   (BC),A               ; LD (HL),n                       ** V1.1.1
                  EXX
                  RET

; *****************************************************************************
;
; LD   (IX+d),n                             4 bytes
; LD   (IY+d),n
;
.Opcode_54_index  CALL Select_IXIY_disp     ;                                 ** V1.04
                  EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get n
                  INC  HL                   ; PC++
                  EXX
                  LD   (HL),A               ; LD (rr[+d]),n
                  RET


; ***************************************************************************
;
; LD   B,C        instruction               1 byte
;
.Opcode_65        LD   A,(IY + VP_C)
                  LD   (IY + VP_B),A
                  RET


; ***************************************************************************
;
; LD   B,D        instruction               1 byte
;
.Opcode_66        LD   A,(IY + VP_D)
                  LD   (IY + VP_B),A
                  RET


; ***************************************************************************
;
; LD   B,E        instruction               1 byte
;
.Opcode_67        LD   A,(IY + VP_E)
                  LD   (IY + VP_B),A
                  RET


; ***************************************************************************
;
; LD   B,H        instruction               1 byte
;
.Opcode_68        EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_B),B
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   B,L        instruction               1 byte
;
.Opcode_69        EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_B),C        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   B,(HL)     instruction               1 byte
;
.Opcode_70
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  LD   (IY + VP_B),A        ; B <- (HL)                       ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   B,(IX+d)   instruction               3 byte
; LD   B,(IY+d)   instruction               3 byte
;
.Opcode_70_index  CALL Select_IXIY_disp     ;                                 ** V1.04
                  LD   A,(HL)
                  LD   (IY + VP_B),A        ; save B
                  RET


; ***************************************************************************
;
; LD   B,A        instruction               1 byte
;
.Opcode_71        EX   AF,AF'               ; get A                           ** V0.23
                  LD   (IY + VP_B),A
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   C,B        instruction               1 byte
;
.Opcode_72        LD   A,(IY + VP_B)
                  LD   (IY + VP_C),A
                  RET


; ***************************************************************************
;
; LD   C,D        instruction               1 byte
;
.Opcode_74        LD   A,(IY + VP_D)
                  LD   (IY + VP_C),A
                  RET


; ***************************************************************************
;
; LD   C,E        instruction               1 byte
;
.Opcode_75        LD   A,(IY + VP_E)
                  LD   (IY + VP_C),A
                  RET


; ***************************************************************************
;
; LD   C,H        instruction               1 byte
;
.Opcode_76
                  EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_C),B        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   C,L        instruction               1 byte
;
.Opcode_77
                  EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_C),C        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   C,(HL)     instruction               1 byte
;
.Opcode_78        EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  LD   (IY + VP_C),A        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   C,(IX+d)   instruction               3 byte
; LD   C,(IY+d)   instruction               3 byte
;
.Opcode_78_index  CALL Select_IXIY_disp     ;                                 ** V1.04
                  LD   A,(HL)
                  LD   (IY + VP_C),A
                  RET

; ***************************************************************************
;
; LD   C,A        instruction               1 byte
;
.Opcode_79        EX   AF,AF'               ; get A                           ** V0.23
                  LD   (IY + VP_C),A
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ***************************************************************************
;
; LD   D,B        instruction               1 byte
;
.Opcode_80        LD   A,(IY + VP_B)
                  LD   (IY + VP_D),A
                  RET


; ***************************************************************************
;
; LD   D,C        instruction               1 byte
;
.Opcode_81        LD   A,(IY + VP_C)
                  LD   (IY + VP_D),A
                  RET


; ***************************************************************************
;
; LD   D,E        instruction               1 byte
;
.Opcode_83        LD   A,(IY + VP_E)
                  LD   (IY + VP_D),A
                  RET


; ***************************************************************************
;
; LD   D,H        instruction               1 byte
;
.Opcode_84        EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_D),B        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   D,L        instruction               1 byte
;
.Opcode_85
                  EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_D),C        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   D,(HL)     instruction               1 byte
;
.Opcode_86
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  LD   (IY + VP_D),A        ; save D
                  EXX                       ;                                 ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   D,(IX+d)   instruction               3 byte
; LD   D,(IY+d)   instruction               3 byte
;
.Opcode_86_index  CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   A,(HL)
                  LD   (IY + VP_D),A
                  RET


; ***************************************************************************
;
; LD   D,A        instruction               1 byte
;
.Opcode_87        EX   AF,AF'               ; get A                          ** V0.23
                  LD   (IY + VP_D),A
                  EX   AF,AF'               ;                                ** V0.23
                  RET


; ***************************************************************************
;
; LD   E,B        instruction               1 byte
;
.Opcode_88        LD   E,(IY + VP_B)
                  LD   (IY + VP_E),E
                  RET


; ***************************************************************************
;
; LD   E,C        instruction               1 byte
;
.Opcode_89        LD   C,(IY + VP_C)
                  LD   (IY + VP_E),C
                  RET


; ***************************************************************************
;
; LD   E,D        instruction               1 byte
;
.Opcode_90        LD   D,(IY + VP_D)
                  LD   (IY + VP_E),D
                  RET


; ***************************************************************************
;
; LD   E,H        instruction               1 byte
;
.Opcode_92
                  EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_E),B        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   E,L        instruction               1 byte
;
.Opcode_93
                  EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_E),C        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   E,(HL)     instruction               1 byte
;
.Opcode_94
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  LD   (IY + VP_E),A        ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   E,(IX+d)   instruction               3 byte
; LD   E,(IY+d)   instruction               3 byte
;
.Opcode_94_index  CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   A,(HL)
                  LD   (IY + VP_E),A
                  RET


; ***************************************************************************
;
; LD   E,A        instruction               1 byte
;
.Opcode_95        EX   AF,AF'               ; get A                          ** V0.23
                  LD   (IY + VP_E),A
                  EX   AF,AF'               ;                                ** V0.23
                  RET


; ***************************************************************************
;
; LD   H,B        instruction               1 byte
;
.Opcode_96
                  EXX                       ;                                 ** V1.1.1
                  LD   B,(IY + VP_B)
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   H,C        instruction               1 byte
;
.Opcode_97
                  EXX                       ;                                 ** V1.1.1
                  LD   B,(IY + VP_C)
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   H,D        instruction               1 byte
;
.Opcode_98
                  EXX                       ;                                 ** V1.1.1
                  LD   B,(IY + VP_D)
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   H,E        instruction               1 byte
;
.Opcode_99
                  EXX                       ;                                 ** V1.1.1
                  LD   B,(IY + VP_E)
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   H,L        instruction               1 byte
;
.Opcode_101
                  EXX                       ;                                 ** V1.1.1
                  LD   B,C                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   H,(HL)     instruction               1 byte
;
.Opcode_102
                  EXX                       ;                                 ** V1.1.1
                  LD   A,(BC)               ;                                 ** V1.1.1
                  LD   B,A                  ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   H,(IX+d)   instruction               3 byte
; LD   H,(IY+d)   instruction               3 byte
;
.Opcode_102_index CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   A,(HL)
                  EXX                       ;                                ** V1.1.1
                  LD   B,A                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   H,A        instruction               1 byte
;
.Opcode_103       EX   AF,AF'               ; get A                          ** V0.23
                  EXX                       ;                                ** V1.1.1
                  LD   B,A                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  EX   AF,AF'               ;                                ** V0.23
                  RET


; ***************************************************************************
;
; LD   L,B        instruction               1 byte
;
.Opcode_104
                  EXX                       ;                                ** V1.1.1
                  LD   C,(IY + VP_B)        ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   L,C        instruction               1 byte
;
.Opcode_105
                  EXX                       ;                                ** V1.1.1
                  LD   C,(IY + VP_C)        ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   L,D        instruction               1 byte
;
.Opcode_106
                  EXX                       ;                                ** V1.1.1
                  LD   C,(IY + VP_D)        ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   L,E        instruction               1 byte
;
.Opcode_107
                  EXX                       ;                                ** V1.1.1
                  LD   C,(IY + VP_E)        ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   L,H        instruction               1 byte
;
.Opcode_108
                  EXX                       ;                                ** V1.1.1
                  LD   C,B                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   L,(HL)     instruction               1 byte
;
.Opcode_110
                  EXX                       ;                                ** V1.1.1
                  LD   A,(BC)               ;                                ** V1.1.1
                  LD   C,A                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   L,(IX+d)   instruction               3 byte
; LD   L,(IY+d)   instruction               3 byte
;
.Opcode_110_index CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   A,(HL)
                  EXX                       ;                                ** V1.1.1
                  LD   C,A                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   L,A        instruction               1 byte
;
.Opcode_111       EX   AF,AF'               ; get A                          ** V0.23
                  EXX                       ;                                ** V1.1.1
                  LD   C,A                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  EX   AF,AF'               ;                                ** V0.23
                  RET


; ***************************************************************************
;
; LD   (HL),B     instruction               1 byte
;
.Opcode_112
                  EXX                       ;                                ** V1.1.1
                  LD   A,(IY + VP_B)        ;                                ** V1.1.1
                  LD   (BC),A               ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   (IX+d),B   instruction               3 byte
; LD   (IY+d),B   instruction               3 byte
;
.Opcode_112_index CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   B,(IY + VP_B)
                  LD   (HL),B               ;                                ** V1.04
                  RET


; ***************************************************************************
;
; LD   (HL),C     instruction               1 byte
;
.Opcode_113
                  EXX                       ;                                ** V1.1.1
                  LD   A,(IY + VP_C)        ;                                ** V1.1.1
                  LD   (BC),A               ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   (IX+d),C   instruction               3 byte
; LD   (IY+d),C   instruction               3 byte
;
.Opcode_113_index CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   C,(IY + VP_C)
                  LD   (HL),C               ;                                ** V1.04
                  RET


; ***************************************************************************
;
; LD   (HL),D     instruction               1 byte
;
.Opcode_114
                  EXX                       ;                                ** V1.1.1
                  LD   A,(IY + VP_D)        ;                                ** V1.1.1
                  LD   (BC),A               ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   (IX+d),D   instruction               3 byte
; LD   (IY+d),D   instruction               3 byte
;
.Opcode_114_index CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   D,(IY + VP_D)
                  LD   (HL),D               ;                                ** V1.04
                  RET


; ***************************************************************************
;
; LD   (HL),E     instruction               1 byte
;
.Opcode_115
                  EXX                       ;                                ** V1.1.1
                  LD   A,(IY + VP_E)        ;                                ** V1.1.1
                  LD   (BC),A               ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   (IX+d),E   instruction               3 byte
; LD   (IX+d),E   instruction               3 byte
;
.Opcode_115_index CALL Select_IXIY_disp     ;                                ** V1.04
                  LD   E,(IY + VP_E)
                  LD   (HL),E               ;                                ** V1.04
                  RET


; ***************************************************************************
;
; LD   (HL),H     instruction               1 byte
;
.Opcode_116
                  EXX                       ;                                ** V1.1.1
                  LD   A,B                  ;                                ** V1.1.1
                  LD   (BC),A               ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET


; ***************************************************************************
;
; LD   (IX+d),H   instruction               3 byte
; LD   (IY+d),H   instruction               3 byte
;
.Opcode_116_index CALL Select_IXIY_disp     ;                                ** V1.04
                  EXX                       ;                                ** V1.1.1
                  LD   A,B                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  LD   (HL),A               ;                                ** V1.04
                  RET


; ***************************************************************************
;
; LD   (HL),L     instruction               1 byte
;
.Opcode_117
                  EXX                       ;                                ** V1.1.1
                  LD   A,C                  ;                                ** V1.1.1
                  LD   (BC),A               ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  RET

; ***************************************************************************
;
; LD   (IX+d),L   instruction               3 byte
; LD   (IY+d),L   instruction               3 byte
;
.Opcode_117_index CALL Select_IXIY_disp     ;                                ** V1.04
                  EXX                       ;                                ** V1.1.1
                  LD   A,C                  ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  LD   (HL),A               ;                                ** V1.04
                  RET


; ***************************************************************************
;
; LD   (HL),A     instruction               1 byte
;
.Opcode_119       EX   AF,AF'               ; get A                          ** V0.23
                  EXX                       ;                                ** V1.1.1
                  LD   (BC),A               ;                                ** V1.1.1
                  EXX                       ;                                ** V1.1.1
                  EX   AF,AF'               ;                                ** V0.23
                  RET

; ***************************************************************************
;
; LD   (IX+d),A   instruction               3 byte
; LD   (IY+d),A   instruction               3 byte
;
.Opcode_119_index CALL Select_IXIY_disp     ;                                ** V1.04
                  EX   AF,AF'
                  LD   (HL),A               ;                                ** V1.04
                  EX   AF,AF'
                  RET

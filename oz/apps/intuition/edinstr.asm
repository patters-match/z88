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

    MODULE ED_instructions

    ; Routines defined in 'stdinstr.asm'
    XREF Opcode_201
    XREF Bindout_error

    INCLUDE "blink.def"
    INCLUDE "oz.def"
    INCLUDE "defs.h"


; ****************************************************************************
;
; Additional Z80 instructions:
;                                       r = A, B, C, D, E, H, L
; IN   r,(C)                           dd = BC, DE, HL, SP
; OUT  (C),r                           nn = 16 bit address
; SBC  HL,dd
; ADC  HL,dd
; LD   (nn),dd
; NEG
; RETN, RETI
; IM  0, IM  1, IM  2
; LD I,A  ;  LD R,A  ;  LD A,I  ;  LD A,R
; RRD, RLD
;
; LDI, LDIR, LDD, LDDR
; CPI, CPIR, CPD, CPDR
; INI, INIR, IND, INDR
; OUTI, OTIR, OUTD, OTDR
;
; ****************************************************************************


    XDEF EDcode_64, EDcode_65, EDcode_66, EDcode_67, EDcode_68, EDcode_69, EDcode_70, EDcode_71, EDcode_72, EDcode_73
    XDEF EDcode_74, EDcode_75
    XDEF EDcode_77
    XDEF EDcode_79, EDcode_80, EDcode_81, EDcode_82, EDcode_83
    XDEF EDcode_86, EDcode_87, EDcode_88, EDcode_89, EDcode_90, EDcode_91
    XDEF EDcode_94, EDcode_95, EDcode_96, EDcode_97, EDcode_98
    XDEF EDcode_103, EDcode_104, EDcode_105, EDcode_106
    XDEF EDcode_111, EDcode_112
    XDEF EDcode_114, EDcode_115
    XDEF EDcode_120, EDcode_121, EDcode_122, EDcode_123
    XDEF EDcode_160, EDcode_161, EDcode_162, EDcode_163
    XDEF EDcode_168, EDcode_169, EDcode_170, EDcode_171
    XDEF EDcode_176, EDcode_177, EDcode_178, EDcode_179
    XDEF EDcode_184, EDcode_185, EDcode_186, EDcode_187




; ****************************************************************************************
;
; ADC  HL,SP      instruction               1 byte
;
.EDcode_122       EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  ADC  HL,DE                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04


; ****************************************************************************************
;
; SBC  HL,SP      instruction               1 byte
;
.EDcode_114       EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  SBC  HL,DE                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04


; ****************************************************************************************
;
; SBC  HL,BC      instruction               1 byte
;
.EDcode_66
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  LD   C,(IY + VP_C)        ;                                 ** V1.04
                  LD   B,(IY + VP_B)        ;                                 ** V1.04
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  SBC  HL,BC                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04


; ****************************************************************************************
;
; SBC  HL,DE      instruction               1 byte
;
.EDcode_82
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  LD   C,(IY + VP_E)        ;                                 ** V1.04
                  LD   B,(IY + VP_D)        ;                                 ** V1.04
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  SBC  HL,BC                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04


; ****************************************************************************************
;
; ADC  HL,BC      instruction               1 byte
;
.EDcode_74
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  LD   C,(IY + VP_C)        ;                                 ** V1.04
                  LD   B,(IY + VP_B)        ;                                 ** V1.04
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  ADC  HL,BC                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04



; ****************************************************************************************
;
; ADC  HL,DE      instruction               1 byte
;
.EDcode_90
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  LD   C,(IY + VP_E)        ;                                 ** V1.04
                  LD   B,(IY + VP_D)        ;                                 ** V1.04
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  ADC  HL,BC                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04


; ****************************************************************************************
;
; SBC  HL,HL      instruction               1 byte
;
.EDcode_98
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  SBC  HL,HL                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04


; ****************************************************************************************
;
; ADC  HL,HL      instruction               1 byte
;
.EDcode_106
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  EX   (SP),HL              ; preserve PC, use HL as acc.     ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  ADC  HL,HL                ;                                 ** V1.04
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V1.04


; ****************************************************************************
;
; NEG
;
.EDcode_68        EX   AF,AF'               ;                                 ** V0.23
                  NEG
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ****************************************************************************
;
; OUT  (C),B
;
.EDcode_65        LD   D,(IY + VP_B)
                  JR   Out_direction


; ****************************************************************************
;
; OUT  (C),C
;
.EDcode_73        LD   D,(IY + VP_C)
                  JR   Out_direction


; ****************************************************************************
;
; OUT  (C),D
;
.EDcode_81        LD   D,(IY + VP_D)
                  JR   Out_direction


; ****************************************************************************
;
; OUT  (C),E
;
.EDcode_89        LD   D,(IY + VP_E)
                  JR   Out_direction


; ****************************************************************************
;
; OUT  (C),H
;
.EDcode_97
                  EXX                     ;                          ** V1.1.1
                  LD   A,B                ;                          ** V1.1.1
                  EXX                     ;                          ** V1.1.1
                  LD   D,A                ;                          ** V1.1.1
                  JR   Out_direction


; ****************************************************************************
;
; OUT  (C),L
;
.EDcode_105
                  EXX                     ;                          ** V1.1.1
                  LD   A,C                ;                          ** V1.1.1
                  EXX                     ;                          ** V1.1.1
                  LD   D,A                ;                          ** V1.1.1
                  JR   Out_direction


; ****************************************************************************
;
; OUT  (C),A
;
.EDcode_121       EX   AF,AF'               ;                        ** V0.27d
                  LD   D,A                  ;                        ** V0.27d
                  EX   AF,AF'               ;                        ** V0.27d

.Out_direction    LD   B,(IY + VP_B)
                  LD   C,(IY + VP_C)        ; port (C)

                  LD   A, BL_SR0
                  CP   C                    ; execution about to bind out Intuition in segment 0?
                  JR   NZ,output_byte
                  LD   A,OZBANK_INTUITION
                  CP   D
                  RET  Z                    ; executing code re-binds Intuition into same bank, ignore...
                  EXX
                  DEC  HL                   ; Danger! Intuition bank is about to be bound out...
                  DEC  HL                   ; point at Out instruction
                  EXX
                  LD   A,(BLSC_SR0)         ; cache the soft copy of the bank that the running code
                  LD   (IY + BindOut_copy),A; wants to bind (to be restored when .G command is used)
                  JP   Bindout_error        ; alert warning and stop execution
.output_byte
                  OUT  (C),D                ; no flags affected.
                  RET


; ****************************************************************************
;
.IN_r             LD   B,(IY + VP_B)        ; get A8 to A15
                  LD   C,(IY + VP_C)        ; port (C)
                  EX   AF,AF'               ;
                  IN   C,(C)                ; receive byte into C
                  EX   AF,AF'               ;
                  RET


; ****************************************************************************
;
;    IN  B,(C)
;
.EDcode_64        CALL IN_r
                  LD   (IY + VP_B),C        ; B
                  RET


; ****************************************************************************
;
;    IN  C,(C)
;
.EDcode_72        CALL IN_r
                  LD   (IY + VP_C),C        ; C
                  RET


; ****************************************************************************
;
;    IN  D,(C)
;
.EDcode_80        CALL IN_r
                  LD   (IY + VP_D),C        ; D
                  RET


; ****************************************************************************
;
;    IN  E,(C)
;
.EDcode_88        CALL IN_r
                  LD   (IY + VP_E),C        ; E
                  RET


; ****************************************************************************
;
;    IN  H,(C)
;
.EDcode_96        CALL IN_r
                  LD   A,C                ; ** V1.1.1
                  EXX                     ; ** V1.1.1
                  LD   B,A                ; ** V1.1.1
                  EXX                     ; ** V1.1.1
                  RET


; ****************************************************************************
;
;    IN  L,(C)
;
.EDcode_104       CALL IN_r
                  LD   A,C                ; ** V1.1.1
                  EXX                     ; ** V1.1.1
                  LD   C,A                ; ** V1.1.1
                  EXX                     ; ** V1.1.1
                  RET


; ****************************************************************************
;
;    IN  F,(C)
;
.EDcode_112       CALL IN_r                 ; F
                  RET


; ****************************************************************************
;
;    IN  A,(C)
;
.EDcode_120       CALL IN_r
                  EX   AF,AF'
                  LD   A,C
                  EX   AF,AF'
                  RET



; ****************************************************************************
;
.Get_address_indd EXX                       ;
                  PUSH HL                   ; get PC into main registers
                  EXX
                  POP  HL
                  LD   E,(HL)               ; nn, low byte
                  INC  HL
                  LD   D,(HL)               ; nn, high byte
                  INC  HL
                  PUSH HL
                  EXX
                  POP  HL                   ; PC updated (ready for next instr)
                  EXX
                  EX   DE,HL
                  LD   E,(HL)
                  INC  HL
                  LD   D,(HL)               ; DE = (nn), HL = nn+1
                  RET



; ****************************************************************************
;
; LD  BC,(nn)
;
.EDcode_75        CALL Get_address_indd
                  LD   (IY + VP_C),E
                  LD   (IY + VP_B),D             ; store (nn) into BC
                  RET


; ****************************************************************************
;
; LD  DE,(nn)
;
.EDcode_91        CALL Get_address_indd
                  LD   (IY + VP_E),E
                  LD   (IY + VP_D),D             ; store (nn) into DE
                  RET


; ****************************************************************************
;
; LD   SP,(nn)
;
.EDcode_123       CALL Get_address_indd     ; get (nn)
                  POP  BC                   ; get return address              ** V0.16
                  EX   DE,HL
                  LD   SP,HL                ; set new SP
                  PUSH HL
                  EXX
                  POP  DE                   ; LD  SP,(nn)
                  EXX
                  PUSH BC
                  RET                       ; fetch next Z80 instruction


; ****************************************************************************
;
.Get_nn           EXX                       ; swap to alternate registers
                  PUSH HL                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  POP  HL                   ;                                 ** V1.1.1
                  LD   E,(HL)               ; get low byte of address
                  INC  HL
                  LD   D,(HL)               ; get high byte of address
                  INC  HL
                  EX   DE,HL                ; HL = nn
                  PUSH DE
                  EXX
                  POP  HL                   ; PC updated
                  EXX
                  RET


; ****************************************************************************
;
; LD  (nn),BC
;
.EDcode_67        CALL Get_nn
                  LD   C,(IY + VP_C)
                  LD   B,(IY + VP_B)
                  LD   (HL),C
                  INC  HL
                  LD   (HL),B
                  RET


; ****************************************************************************
;
; LD  (nn),DE
;
.EDcode_83        CALL Get_nn
                  LD   C,(IY + VP_E)
                  LD   B,(IY + VP_D)
                  LD   (HL),C
                  INC  HL
                  LD   (HL),B
                  RET



; ****************************************************************************
;
; LD   (nn),SP
;
.EDcode_115       EXX
                  PUSH BC                   ; preserve virtual HL             ** V1.1.1
                  LD   B,D
                  LD   C,E                  ; virtual SP in BC
                  LD   E,(HL)
                  INC  HL
                  LD   D,(HL)               ; {DE = nn}
                  INC  HL                   ; PC += 2
                  EX   DE,HL                ; {HL = nn, DE = PC}
                  LD   (HL),C
                  INC  HL
                  LD   (HL),B               ; LD  (nn),SP
                  EX   DE,HL                ; virtual PC restored
                  LD   D,B
                  LD   E,C                  ; virtual SP restored
                  POP  BC                   ; virtual HL restored             ** V1.1.1
                  EXX
                  RET


; ****************************************************************************
;
; IM  0
;
.EDcode_70
                 IM   0                     ; no flags affected             ** V1.1.1
                 RET


; ****************************************************************************
;
; IM  1
;
.EDcode_86
                 IM   1                     ; no flags affected             ** V1.1.1
                 RET


; ****************************************************************************
;
; IM  2
;
.EDcode_94
                 IM   2                     ; no flags affected             ** V1.1.1
                 RET


; ****************************************************************************
;
; LD   I,A
;
.EDcode_71
                 EX   AF,AF'                ; ** V1.1.1
                 LD   I,A                   ;
                 EX   AF,AF'                ; ** V1.1.1
                 RET


; ****************************************************************************
;
; LD   R,A
;
.EDcode_79        EX   AF,AF'               ;                                 ** V0.23
                  LD   R,A
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ****************************************************************************
;
; LD   A,I
;
.EDcode_87        EX   AF,AF'               ;                                 ** V0.23
                  LD   A,I
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ****************************************************************************
;
; LD   A,R
;
.EDcode_95        EX   AF,AF'               ;                                 ** V0.23
                  LD   A,R
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ****************************************************************************
;
; RRD
;
.EDcode_103
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  EX   (SP),HL              ; preserve PC, install virtual HL ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  RRD
                  EX   AF,AF'               ;                                 ** V1.04
                  EX   (SP),HL              ; restore PC                      ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET


; ****************************************************************************
;
; RLD
;
.EDcode_111
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  EX   (SP),HL              ; preserve PC, install virtual HL ** V1.04
                  EX   AF,AF'               ; install virtual AF              ** V1.04
                  RLD
                  EX   AF,AF'               ; restore virtual AF              ** V1.04
                  EX   (SP),HL              ; restore virtual PC              ** V1.04
                  POP  BC                   ; restore virtual HL              ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET


; ****************************************************************************
;
; LDI
;
.EDcode_160       CALL FetchBlockRegs
                  LDI
                  JP   SaveBlockRegs


; ****************************************************************************
;
; LDIR
;
.EDcode_176       CALL FetchBlockRegs
                  LDIR
                  JP   SaveBlockRegs


; ****************************************************************************
;
; LDD
;
.EDcode_168       CALL FetchBlockRegs
                  LDD
                  JP   SaveBlockRegs


; ****************************************************************************
;
; LDDR
;
.EDcode_184       CALL FetchBlockRegs
                  LDDR
                  JP   SaveBlockRegs


; ****************************************************************************
;
; CPI
;
.EDcode_161       CALL FetchBlockRegs
                  CPI
                  JP   SaveBlockRegs


; ****************************************************************************
;
; CPIR
;
.EDcode_177       CALL FetchBlockRegs
                  CPIR
                  JP   SaveBlockRegs


; ****************************************************************************
;
; CPD
;
.EDcode_169       CALL FetchBlockRegs
                  CPD
                  JP   SaveBlockRegs


; ****************************************************************************
;
; CPDR
;
.EDcode_185       CALL FetchBlockRegs
                  CPDR
                  JP   SaveBlockRegs


; ****************************************************************************
;
; INI
;
.EDcode_162       CALL FetchBlockRegs
                  INI
                  JP   SaveBlockRegs


; ****************************************************************************
;
; INIR
;
.EDcode_178       CALL FetchBlockRegs
                  INIR
                  JP   SaveBlockRegs


; ****************************************************************************
;
; IND
;
.EDcode_170       CALL FetchBlockRegs
                  IND
                  JP   SaveBlockRegs


; ****************************************************************************
;
; INDR
;
.EDcode_186       CALL FetchBlockRegs
                  INDR
                  JP   SaveBlockRegs


; ****************************************************************************
;
; OUTI
;
.EDcode_163       CALL FetchBlockRegs
                  OUTI
                  JP   SaveBlockRegs


; ****************************************************************************
;
; OTIR
;
.EDcode_179       CALL FetchBlockRegs
                  OTIR
                  JP   SaveBlockRegs


; ****************************************************************************
;
; OUTD
;
.EDcode_171       CALL FetchBlockRegs
                  OUTD
                  JP   SaveBlockRegs


; *******************************************************************************************************
;
; Restore original values of Main Z80 registers (BC, DE, HL & IX)
;
.RestoreMainReg   EXX                       ;                                 ** V1.1.1
                  PUSH BC                   ; (get copy of virtual HL)        ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   C,(IY + VP_C)        ;                                 ** V1.1.1
                  LD   B,(IY + VP_B)        ; BC restored                     ** V1.1.1
                  LD   E,(IY + VP_E)        ;                                 ** V1.1.1
                  LD   D,(IY + VP_D)        ; DE restored                     ** V1.1.1
                  LD   L,(IY + VP_IX)       ;                                 ** V1.1.1
                  LD   H,(IY + VP_IX+1)     ;                                 ** V1.1.1
                  PUSH HL                   ;                                 ** V1.1.1
                  POP  IX                   ; IX restored                     ** V1.1.1
                  POP  HL                   ; HL restored                     ** V1.1.1
                  RET


; ****************************************************************************
;
; OTDR
;
.EDcode_187       CALL FetchBlockRegs
                  OTDR
                  JP   SaveBlockRegs

.FetchBlockRegs
                  CALL RestoreMainReg
                  EX   AF,AF'               ; AF installed
                  RET

.SaveBlockRegs    EX   AF,AF'
                  PUSH HL
                  EXX
                  POP  BC                   ;      HL
                  EXX
                  LD   (IY + VP_C),C
                  LD   (IY + VP_B),B        ;      BC
                  LD   (IY + VP_E),E
                  LD   (IY + VP_D),D        ;      DE
                  RET

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

    MODULE Std_Instructions

    ; Routines defined in 'debugger.asm':
    XREF command_mode, Breakpoint_found

    ; Global routines defined in this module:
    XDEF Opcode_0, Opcode_8, Opcode_16, Opcode_24, Opcode_32, Opcode_40, Opcode_48, Opcode_56
    XDEF Opcode_118
    XDEF Opcode_192, Opcode_193, Opcode_194, Opcode_195, Opcode_196, Opcode_197, Opcode_200, Opcode_201
    XDEF Opcode_202, Opcode_204, Opcode_205, Opcode_208, Opcode_209, Opcode_210, Opcode_211, Opcode_212
    XDEF Opcode_213, Opcode_216, Opcode_217, Opcode_218, Opcode_219, Opcode_220, Opcode_223, Opcode_224
    XDEF Opcode_225, Opcode_226, Opcode_227, Opcode_228, Opcode_229, Opcode_231, Opcode_232, Opcode_233
    XDEF Opcode_234, Opcode_235, Opcode_236, Opcode_240, Opcode_241, Opcode_242, Opcode_244, Opcode_245
    XDEF Opcode_248, Opcode_250, Opcode_252
    XDEF Select_IXIY, Select_IXIY_disp
    XDEF RestoreMainReg

    XDEF Opcode_233_index, Opcode_229_index, Opcode_225_index, Opcode_227_index
    XDEF Calc_Reladdress

    INCLUDE "defs.h"          ; assembly directives & various constants



; ****************************************************************************
;
; NOP instruction                           1 byte
;
.Opcode_0         RET                       ; continue with next instruction...


; *****************************************************************************
;
; DJNZ, e         instruction               2 bytes
;
; V0.16 optimized...
.Opcode_16        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get jump offset
                  INC  HL                   ; point at next instruction
                  DEC  (IY + VP_B)          ; decrease B register             ** V0.16
                  JR   Z,exit_djnz          ; DJNZ terminated, continue       ** V0.28
                  CALL Calc_RelAddress      ; - not terminated, get rel. address
.exit_djnz        EXX                       ;                                 ** V0.28
                  RET


; *****************************************************************************
;
; JR e            instruction               2 bytes
;
.Opcode_24        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get jump offset
                  INC  HL                   ; point at next instruction
                  CALL Calc_RelAddress      ; new PC...
                  EXX                       ;                                 ** V0.28
                  RET


; *****************************************************************************
;
; JR   NZ, n     instruction                2 bytes
;
.Opcode_32        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get jump offset
                  INC  HL                   ; PC = PC + 1, point at next instruction
                  EX   AF,AF'               ;                                 ** V0.23
                  JR   Z,exit_jr            ; Fz = 1, continue...             ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  CALL Calc_RelAddress      ; Fz = 0, jump...
                  EXX                       ;                                 ** V0.28
                  RET

.exit_jr          EX   AF,AF'               ; swap back to work registers     ** V0.29
                  EXX                       ;                                 ** V0.29
                  RET                       ;                                 ** V0.29


; *****************************************************************************
;
; JR   Z, n       instruction               2 bytes
;
.Opcode_40        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get jump offset
                  INC  HL                   ; PC++, point at next instruction
                  EX   AF,AF'               ;                                 ** V0.23
                  JR   NZ,exit_jr           ; Fz = 0, continue...             ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  CALL Calc_RelAddress      ; Fz = 1, jump...
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V0.28


; *****************************************************************************
;
; JR   NC, n     instruction                2 bytes
;
.Opcode_48        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get jump offset
                  INC  HL                   ; PC = PC + 1, point at next instruction
                  EX   AF,AF'               ;                                 ** V0.23
                  JR   C,exit_jr            ; Fc = 1, continue...             ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  CALL Calc_RelAddress      ; Fc = 0, jump...
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V0.28


; *****************************************************************************
;
; JR   C, n       instruction               2 bytes
;
.Opcode_56        EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get jump offset
                  INC  HL                   ; PC = PC + 1, point at next instruction
                  EX   AF,AF'               ;                                 ** V0.23
                  JR   NC,exit_jr           ; Fc = 0, continue...             ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  CALL Calc_RelAddress      ; C = offset, HL = PC,  Fc = 1, jump...
                  EXX                       ;                                 ** V0.28
                  RET                       ;                                 ** V0.28


; ************************************************************************************
;
; JP   NZ, nn                               3 bytes
;
.Opcode_194       EX   AF,AF'               ;                                 ** V0.23
                  JR   NZ, opcode_195x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   Z, nn                                3 bytes
;
.Opcode_202       EX   AF,AF'               ;                                 ** V0.23
                  JR   Z, opcode_195x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   NC, nn                               3 bytes
;
.Opcode_210       EX   AF,AF'               ;                                 ** V0.23
                  JR   NC, opcode_195x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   C, nn                                3 bytes
;
.Opcode_218       EX   AF,AF'               ; get AF                          ** V0.23
                  JR   C, opcode_195x       ;                                 ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   PO, nn                               3 bytes
;
.Opcode_226       EX   AF,AF'               ;                                 ** V0.23
                  JP   PO, opcode_195x      ;                                 ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   PE, nn                               3 bytes
;
.Opcode_234       EX   AF,AF'               ; get F                           ** V0.23
                  JP   PE, opcode_195x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   P, nn                                3 bytes
;
.Opcode_242       EX   AF,AF'               ;                                 ** V0.23
                  JP   P, opcode_195x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   M, nn                                3 bytes
;
.Opcode_250       EX   AF,AF'               ;                                 ** V0.23
                  JP   M, opcode_195x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; JP   nn                                   3 bytes
;
.opcode_195x      EX   AF,AF'               ; swap back to work register      ** V0.29
.Opcode_195       EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get low byte of address
                  INC  HL
                  LD   H,(HL)               ; get high byte of address        ** V0.24b
                  LD   L,A                  ; new PC                          ** V0.23
                  EXX                       ;                                 ** V0.28
                  RET


; *************************************************************************************
;
; JP   (HL)       instruction               1 byte
;
.Opcode_233       EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  POP  HL                   ; new PC                          ** V1.04
                  EXX                       ;                                 ** V0.28
                  RET

; *************************************************************************************
;
; JP   (IX)       instruction               2 byte
; JP   (IY)       instruction               2 byte
;
.Opcode_233_index EXX                       ;                                 ** V0.28
                  CALL Select_IXIY          ;                                 ** V1.04
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL NZ, nn                               3 bytes
;
.Opcode_196       EX   AF,AF'               ;                                 ** V0.23
                  JR   NZ, Opcode_205x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL Z, nn                                3 bytes
;
.Opcode_204       EX   AF,AF'               ;                                 ** V0.23
                  JR   Z, Opcode_205x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL nn                                   3 bytes
;
.opcode_205x      EX   AF,AF'               ; swap back to work register      ** V0.29
.Opcode_205       POP  HL                   ; return addr to main decode...   ** V1.04
                  EXX                       ;                                 ** V0.28
                  PUSH BC                   ;                                 ** V1.1.1
                  POP  IX                   ; preserve virtual HL register    ** V1.1.1
                  LD   C,(HL)               ; get low byte of address
                  INC  HL
                  LD   B,(HL)
                  INC  HL                   ; PC ready for next instruction
                  PUSH HL                   ; return address on stack
                  LD   H,B                  ;                                 ** V0.23
                  LD   L,C                  ; new PC                          ** V0.23
                  PUSH IX                   ;                                 ** V1.1.1
                  POP  BC                   ; virtual HL restored             ** V1.1.1
                  DEC  DE                   ;                                 ** V0.23
                  DEC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; 'simulated' return for Monitor  ** V1.04


; ************************************************************************************
;
; CALL NC, nn                               3 bytes
;
.Opcode_212       EX   AF,AF'               ;                                 ** V0.23
                  JR   NC, Opcode_205x      ; Yes...                          ** V0.16/V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL C, nn                                3 bytes
;
.Opcode_220       EX   AF,AF'               ;                                 ** V0.23
                  JR   C, Opcode_205x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL PO, nn                               3 bytes
;
.Opcode_228       EX   AF,AF'               ;                                 ** V0.23
                  JP   PO, Opcode_205x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL PE, nn                               3 bytes
;
.Opcode_236       EX   AF,AF'               ;                                 ** V0.23
                  JP   PE, Opcode_205x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL P, nn                                3 bytes
;
.Opcode_244       EX   AF,AF'               ;                                 ** V0.23
                  JP   P, Opcode_205x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET


; ************************************************************************************
;
; CALL M, nn                                3 bytes
;
.Opcode_252       EX   AF,AF'               ;                                 ** V0.23
                  JP   M, Opcode_205x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  INC  HL                   ;                                 ** V0.28
                  EXX                       ;                                 ** V0.28
                  RET



; ******************************************************************************************
;
; RET  NZ         instruction               1 byte
;
.Opcode_192       EX   AF,AF'               ;                                 ** V0.23
                  JR   NZ, Opcode_201x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ******************************************************************************************
;
; RET  Z          instruction               1 byte
;
.Opcode_200       EX   AF,AF'               ;                                 ** V0.23
                  JR   Z, Opcode_201x       ; Yes, execute RET...             ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ******************************************************************************************
;
; RET             instruction               1 byte
;
.opcode_201x      EX   AF,AF'               ; swap back to work register                  ** V0.29
.Opcode_201       POP  HL                   ; get return address for Opcode_201 CALL      ** V1.04
                  EXX                       ; select alternate registers...               ** V0.28
                  POP  HL                   ; new PC for running program RET
                  INC  DE                   ;                                             ** V0.23
                  INC  DE                   ; v.p. SP updated                             ** V0.23
                  EXX                       ;                                             ** V0.28
                  BIT  Flg_TraceSubr,(IY + FlagStat3)  ; 'Trace Subroutine' ON?           ** V0.26e
                  JR   NZ, check_RET_stack  ; Yes - test for correct RET level            ** V0.27
                  JP   (HL)                 ; 'simulated' return in Z80Monitor...         ** V1.04

.check_RET_stack  LD   A,(IY + SPlevel+1)   ; Get RETurn SP                               ** V0.27
                  EXX                       ;                                             ** V0.28
                  CP   D                    ;                                             ** V0.27
                  EXX                       ;                                             ** V0.28
                  JR   Z, check_lowb_SP     ;                                             ** V0.27
                  JR   C, unbalanced_SP     ; Ups - current SP is higher than RET SP      ** V0.27
                  JP   (HL)                 ; sub-call RET, continue V.P.                 ** V1.04

.unbalanced_SP    LD   (IY + RtmError), ERR_RET_unbalanced
                  SET  Flg_RTM_error,(IY + FlagStat2)                                     ** V0.27
                  JP   command_mode         ; activate command mode                       ** V0.28

.check_lowb_SP    LD   A,(IY + SPlevel)     ;                                             ** V0.27
                  EXX                       ;                                             ** V0.28
                  CP   E                    ;                                             ** V0.27
                  EXX                       ;                                             ** V0.28
                  JP   Z, command_mode      ; Subroutine ended - activate command mode    ** V0.28
                  JR   C, unbalanced_SP     ; Ups - current SP is higher than RET SP      ** V0.27
                  JP   (HL)                 ; sub-call RET, continue V.P.                 ** V1.04



; ******************************************************************************************
;
; RET  NC         instruction               1 byte
;
.Opcode_208       EX   AF,AF'               ;                                 ** V0.23
                  JR   NC, Opcode_201x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET                       ; No, continue at (PC)


; ******************************************************************************************
;
; RET  C          instruction               1 byte
;
.Opcode_216       EX   AF,AF'               ;                                 ** V0.23
                  JR   C, Opcode_201x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ******************************************************************************************
;
; RET  PO          instruction              1 byte
;
.Opcode_224       EX   AF,AF'               ;                                 ** V0.23
                  JP   PO, Opcode_201x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ******************************************************************************************
;
; RET  PE          instruction              1 byte
;
.Opcode_232       EX   AF,AF'               ;                                 ** V0.23
                  JP   PE, Opcode_201x      ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ******************************************************************************************
;
; RET  P          instruction               1 byte
;
.Opcode_240       EX   AF,AF'               ;                                 ** V0.23
                  JP   P, Opcode_201x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ******************************************************************************************
;
; RET  M          instruction               1 byte
;
.Opcode_248       EX   AF,AF'               ;                                 ** V0.23
                  JP   M, Opcode_201x       ; Yes...                          ** V0.29
                  EX   AF,AF'               ;                                 ** V0.23
                  RET


; ************************************************************************************************
;
; POP BC
;
.Opcode_193       POP  HL                   ; return address...               ** V1.04
                  POP  BC                   ; value to BC
                  LD   (IY + VP_C),C
                  LD   (IY + VP_B),B
                  EXX                       ;                                 ** V0.28
                  INC  DE                   ;                                 ** V0.23
                  INC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V1.04

; ************************************************************************************************
;
; POP DE
;
.Opcode_209       POP  HL                   ; return address...               ** V1.04
                  POP  DE                   ; value to DE
                  LD   (IY + VP_E),E
                  LD   (IY + VP_D),D
                  EXX                       ;                                 ** V0.28
                  INC  DE                   ;                                 ** V0.23
                  INC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V1.04

; ************************************************************************************************
;
; POP  HL
;
.Opcode_225       POP  HL                   ; return addr to v.p.             ** V1.04
                  EXX                       ;                                 ** V0.28
                  POP  BC                   ; pop into virtual HL             ** V1.1.1
                  INC  DE                   ;                                 ** V0.23
                  INC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V0.16

; ************************************************************************************************
;
; POP  IX
; POP  IY
;
.Opcode_225_index POP  HL                   ;                                 ** V1.04
                  EXX                       ;                                 ** V0.28
                  INC  DE                   ;                                 ** V0.23
                  INC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  POP  BC                   ; POP  HL
                  CP   $DD
                  JR   Z, pop_into_ix
                  LD   (IY + VP_IY),C
                  LD   (IY + VP_IY+1),B
                  JP   (HL)                 ;                                 ** V1.04
.pop_into_ix      LD   (IY + VP_IX),C
                  LD   (IY + VP_IX+1),B
                  JP   (HL)                 ;                                 ** V1.04


; ************************************************************************************************
;
; POP  AF
;
.Opcode_241       POP  HL                   ; return address...               ** V1.04
                  EX   AF,AF'               ;                                 ** V0.23
                  POP  AF                   ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  INC  DE                   ;                                 ** V0.23
                  INC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V0.16


; ************************************************************************************************
;
; PUSH BC                                   1 byte
;
.Opcode_197       POP  HL                   ;                                 ** V1.04
                  LD   C,(IY + VP_C)
                  LD   B,(IY + VP_B)
                  PUSH BC                   ; BC on stack...                  ** V0.24b
                  EXX                       ;                                 ** V0.28
                  DEC  DE                   ;                                 ** V0.23
                  DEC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V1.04

; ************************************************************************************************
;
; PUSH DE
;
.Opcode_213       POP  HL                   ;                                 ** V1.04
                  LD   C,(IY + VP_E)
                  LD   B,(IY + VP_D)
                  PUSH BC                   ; ...                             ** V0.24b
                  EXX                       ;                                 ** V0.28
                  DEC  DE                   ;                                 ** V0.23
                  DEC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V1.04

; ************************************************************************************************
;
; PUSH HL
;
.Opcode_229       POP  HL                   ; return addr to v.p.             ** V1.04
                  EXX                       ;                                 ** V0.16
                  PUSH BC                   ;                                 ** V1.1.1
                  DEC  DE                   ;                                 ** V0.23
                  DEC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V1.04

; ************************************************************************************************
;
; PUSH IX
; PUSH IY
;
.Opcode_229_index POP  DE                   ;                                 ** V1.04
                  CALL Select_IXIY
                  PUSH HL                   ;                                 ** V0.16
                  EXX                       ;                                 ** V0.16
                  DEC  DE                   ;                                 ** V0.23
                  DEC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  EX   DE,HL                ;                                 ** V1.04
                  JP   (HL)                 ; return...                       ** V1.04


; ************************************************************************************************
;
; PUSH AF
;
.Opcode_245       POP  HL                   ; get return address              ** V1.04
                  EX   AF,AF'               ;                                 ** V0.23
                  PUSH AF                   ;                                 ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  DEC  DE                   ;                                 ** V0.23
                  DEC  DE                   ; v.p. SP updated                 ** V0.23
                  EXX                       ;                                 ** V0.28
                  JP   (HL)                 ; return...                       ** V1.04


; ************************************************************************************
;
; OUT  (n),A                                2 bytes
;
.Opcode_211       EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual, HL register.. ** V1.1.1
                  LD   C,(HL)               ; get port number
                  INC  HL
                  EX   AF,AF'               ;                                 ** V0.23
                  LD   B,A                  ; get A register                  ** V0.23
                  EX   AF,AF'               ;                                 ** V0.23
                  OUT  (C),B                ; and put contents to port n
                  POP  BC                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ; - no flags affected...


; ************************************************************************************
;
; IN   A,(n)                                2 bytes
;
.Opcode_219       EXX                       ;                                 ** V0.28
                  PUSH BC                   ; preserve virtual, HL register.. ** V1.1.1
                  LD   C,(HL)               ; get port number
                  INC  HL
                  EX   AF,AF'               ; get virtual A                   ** V0.23
                  LD   B,A                  ; get A8 to A15 = A               ** V0.23
                  IN   A,(C)                ; C = n provides A0 to A7
                  EX   AF,AF'               ;                                 ** V0.23
                  POP  BC                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V0.28
                  RET                       ; with   IN   A,(n) ...


; ******************************************************************************************
;
; RST  $18        instruction               1 byte
;
; Z88 operating system call to process floating point numbers, with 1 byte parameter
;
.Opcode_223       EXX                       ;                                 ** V0.28
                  LD   A,(HL)               ; get FPP parameter
                  INC  HL                   ; ready for next instruction
                  PUSH DE                   ; save virtual SP on stack        ** V0.23
                  PUSH HL                   ; save virtual PC on stack        ** V0.24
                  EXX                       ;                                 ** V0.28
                  LD   BC,24                ; !! Mnemonic here..              ** V0.24/V0.28
                  PUSH IY                   ;                                 ** V0.24/v0.28
                  POP  HL                   ;                                 ** V0.24/V0.28
                  ADD  HL,BC                ;                                 ** V0.24/V0.28
                  LD   D,H                  ;                                 ** V0.24
                  LD   E,L                  ;                                 ** V0.24
                  LD   (HL), $E1            ; POP  HL instruction             ** V0.24
                  INC  HL                   ;                                 ** V0.24
                  LD   (HL), $DF            ; RST  $18 instruction...         ** V0.24
                  INC  HL                   ;                                 ** V0.24
                  LD   (HL), A              ; parameter installed...          ** V0.24
                  INC  HL                   ;                                 ** V0.24
                  LD   (HL), $C9            ; RET instruction...              ** V0.24
                  LD   BC, CopyRegisters    ; get values of AF,BC,DE,HL,IX,   ** V0.28
                  PUSH BC                   ; AF',BC',DE' & HL' on return     ** V0.28
                  PUSH DE                   ; ptr to buffer on stack
                  CALL RestoreMainReg       ; restore BC,DE,HL & IX           ** V0.28
                  EXX                       ;                                 ** V0.28
                  LD   E,(IY + VP_Ex)       ; DE' restored                    ** V0.28
                  LD   D,(IY + VP_Dx)       ;                                 ** V0.28
                  LD   L,(IY + VP_Lx)       ; HL' restored                    ** V0.28
                  LD   H,(IY + VP_Hx)       ; (BC' is not need as parameter)  ** V0.28
                  EXX                       ;                                 ** V0.28
                  EX   (SP),HL              ; put HL on the stack             ** V0.28
                  EX   AF,AF'               ; AF installed                    ** V0.28
                  JP  (HL)                  ; execute RST 18h call in buffer


; ***************************************************************************
;
; RST  20h        instruction               1 byte
;
; Z88 operating system call with parameters (DEFB or DEFW)
;
.Opcode_231       LD   BC,ExecBuffer        ;                                 ** V0.28
                  PUSH IY                   ;                                 ** V0.28
                  POP  HL                   ;                                 ** V0.28
                  ADD  HL,BC                ; HL points at exec buffer        ** V0.28
                  LD   B,H
                  LD   C,L                  ; save a copy of ex. buffer ptr.
                  LD   (HL), $E1            ; POP  HL instruction (to install HL from Intuition)
                  INC  HL
                  LD   (HL), $E7            ; RST  $20 instruction...
                  INC  HL
                  EXX                       ; alternate...                    ** V0.28
                  LD   A,(HL)               ; get first parameter
                  INC  HL                   ; PC ready for par./instr.
                  EXX                       ; main...
                  LD   (HL),A               ; install first parameter         ** V0.28
                  INC  HL
                  CP   $06                  ; 2 byte parameter?
                  JR   Z, fetch_second_par  ; 'OS_' 2 byte system call
                  CP   $09
                  JR   Z, fetch_second_par  ; 'GN_' system call
                  CP   $0C
                  JR   Z, fetch_second_par  ; 'DC_' 2 byte system call
                  JR   Put_RET_instr        ; 'OS_' 1 byte system call
.fetch_second_par EXX                       ; alternate...                    ** V0.28
                  LD   A,(HL)               ; get 2. byte parameter           ** V0.28
                  INC  HL                   ; PC ready for next instruction   ** V0.28
                  EXX                       ; main...                         ** V0.28
                  LD   (HL),A               ; install 2. parameter            ** V0.28
                  INC  HL                   ;                                 ** V0.28
.Put_RET_instr    LD   (HL), $C9            ; RET instruction...              ** V0.28
                  EXX
                  PUSH DE                   ; save virtual SP on stack        ** V0.28
                  PUSH HL                   ; save PC on stack                ** V0.28
                  EXX
                  LD   DE, CopyRegisters    ; get values of AF,BC,DE,HL,IX,   ** V0.28
                  PUSH DE                   ; AF',BC',DE' & HL' on return     ** V0.28
                  PUSH BC                   ; ptr to CALL buffer on stack     ** V0.28
                  CALL RestoreMainReg       ; restore BC,DE,HL & IX           ** V0.28
                  EX   (SP),HL              ; put HL on the stack             ** V0.28
                  EX   AF,AF'               ; AF installed                    ** V0.28
                  JP  (HL)                  ; execute RST 20h call in buffer


.CopyRegisters    PUSH HL
                  PUSH IY
                  POP  HL                   ; HL = base address
                  LD   (HL),C
                  INC  HL
                  LD   (HL),B               ; BC copied
                  INC  HL
                  LD   (HL),E
                  INC  HL
                  LD   (HL),D               ; DE copied
                  INC  HL
                  POP  BC                   ; HL (in BC)
                  INC  HL
                  INC  HL
                  INC  HL
                  INC  HL                   ; skip AF
                  PUSH HL
                  EXX                       ; alternate
                  EX   (SP),HL              ; HL' on stack, HL ptr. in RTM area
                  LD   (HL),C
                  INC  HL
                  LD   (HL),B               ; BC' copied
                  INC  HL
                  LD   (HL),E
                  INC  HL
                  LD   (HL),D               ; DE' copied
                  INC  HL
                  POP  DE
                  LD   (HL),E
                  INC  HL
                  LD   (HL),D               ; HL' copied
                  INC  HL
                  EX   AF,AF'               ; AF installed in AF'             ** V0.28
                  PUSH AF                   ; get AF'
                  POP  DE
                  LD   (HL),E
                  INC  HL
                  LD   (HL),D               ; AF' copied
                  INC  HL
                  PUSH IX
                  POP  DE
                  LD   (HL),E
                  INC  HL
                  LD   (HL),D               ; IX copied
                  POP  HL                   ; virtual PC installed            ** V0.28
                  POP  DE                   ; virtual SP installed            ** V0.28
                  EXX                       ; use main set                    ** V0.28
                  PUSH BC
                  EXX                       ;                                 ** V1.1.1
                  POP  BC                   ; virtual HL installed            ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  BIT  Flg_RTM_Trace,(IY + FlagStat2) ; single step mode?     ** V0.32
                  RET  NZ                   ; yes...                          ** V0.32
                  BIT  Flg_BreakOZ,(IY + FlagStat3)   ; Break at OZ error?    ** V0.32
                  RET  Z                    ; no, continue virtual processor  ** V0.32

                  EX   AF,AF'               ;                                 ** V0.32
                  PUSH AF                   ;                                 ** V0.32
                  EX   AF,AF'               ;                                 ** V0.32
                  POP  AF                   ;                                 ** V0.32
                  RET  NC                   ; continue virtual processor      ** V0.32
                  SET  Flg_RTM_error,(IY + FlagStat2) ;indicate runtime error ** V0.32
                  LD   (IY + RtmError),$FF  ; indicate display of OZ call     ** V0.32
                  JP   command_mode         ; OZ error, dump or command line  ** V0.32




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


; ************************************************************************************
;
; EX   (SP),HL                              1 byte
;
.Opcode_227       POP  HL                   ; get Intuition return address    ** V1.04
                  EXX                       ;                                 ** V1.1.1
                  PUSH BC                   ;                                 ** V1.1.1
                  POP  IX                   ; virtual HL                      ** V1.1.1
                  EX   (SP),IX              ;                                 ** V1.04
                  PUSH IX                   ;                                 ** V1.1.1
                  POP  BC                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  JP   (HL)                 ;                                 ** V1.04


; ************************************************************************************
;
; EX   (SP),IX                              2 byte
; EX   (SP),IY                              2 byte
;
.Opcode_227_index POP  DE                   ; get return address              ** V1.04
                  CALL Select_IXIY
                  EX   (SP),HL              ; swap IX or IY with stack item
                  EX   DE,HL                ;                                 ** V1.04
                  CP   $DD
                  JR   Z, swap_into_ix_227
                  LD   (IY + VP_IY),E       ;                                 ** V1.04
                  LD   (IY + VP_IY+1),D     ;                                 ** V1.04
                  JP   (HL)                 ;                                 ** V1.04
.swap_into_ix_227 LD   (IY + VP_IX),E       ;                                 ** V1.04
                  LD   (IY + VP_IX+1),D     ;                                 ** V1.04
                  JP   (HL)                 ;                                 ** V1.04


; *****************************************************************************
;
; EX   AF, AF'    instruction               1 byte
;
.Opcode_8         EX   AF,AF'
                  LD   C,(IY + VP_AFx)
                  LD   B,(IY + VP_AFx+1)
                  PUSH AF
                  POP  DE
                  LD   (IY + VP_AFx),E
                  LD   (IY + VP_AFx+1),D    ; save new AF'
                  PUSH BC
                  POP  AF
                  EX   AF,AF'               ; new AF installed
                  RET


; ************************************************************************************
;
; EX   DE,HL                                1 byte
;
.Opcode_235       LD   E,(IY + VP_E)        ;                                 ** V1.1.1
                  LD   D,(IY + VP_D)        ;                                 ** V1.1.1
                  PUSH DE                   ;                                 ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_E),C        ;                                 ** V1.1.1
                  LD   (IY + VP_D),B        ; new DE stored (current HL)      ** V1.1.1
                  POP  BC                   ; new HL stored (current DE)      ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  RET


; ************************************************************************************
;
; EXX
;
.Opcode_217
                  EXX                       ;                                 ** V1.1.1
                  LD   (IY + VP_L),C        ;                                 ** V1.1.1
                  LD   (IY + VP_H),B        ; store "fast" HL into reg-area   ** V1.1.1
                  EXX                       ;                                 ** V1.1.1
                  PUSH IY                   ; get base of registers           ** V0.27a
                  PUSH IY                   ;                                 ** V0.27a
                  POP  HL                   ;                                 ** V0.27a
                  LD   BC,8                 ;                                 ** V0.27a
                  ADD  HL,BC                ;                                 ** V0.27a
                  EX   DE,HL                ; DE is base of alternate set     ** V0.27a
                  POP  HL                   ; HL is base of main set          ** V0.27a
                  LD   B,6                  ; no. of 8bit registers to swap   ** V0.27a
.swap_reg_loop    LD   C,(HL)               ; get main register               ** V0.27a
                  LD   A,(DE)               ; get alternate register          ** V0.27a
                  LD   (HL),A               ; swap main with alternate        ** V0.27a
                  LD   A,C                  ;                                 ** V0.27a
                  LD   (DE),A               ; swap alternate with main        ** V0.27a
                  INC  HL                   ;                                 ** V0.27a
                  INC  DE                   ; point at next register...       ** V0.27a
                  DJNZ swap_reg_loop        ; swap next 8bit register         ** V0.27a
                  EXX                       ;                                 ** V1.1.1
                  LD   C,(IY + VP_L)        ;                                 ** V1.1.1
                  LD   B,(IY + VP_H)        ;                                 ** V1.1.1
                  EXX                       ;  new virtual HL installed       ** V1.1.1
                  RET


; ************************************************************************************
;
; HALT
;
.Opcode_118       HALT
                  RET



; **********************************************************************************
;
; Calculate absolute address from PC (in HL) and relative jump byte in A
; - Address will be returned in HL
;
;       ..BCDE../IXIY  same
;       AF....HL/....  different
;
.Calc_RelAddress  PUSH BC                   ;                                 ** V1.1.1
                  LD   C,A                  ; prepare for calculation         ** V1.03
                  RLA                       ; sign bit into Fc                ** V1.04
                  SBC  A,A                  ; 0 or -1 depending on Fc         ** V1.04
                  LD   B,A                  ; sign-extend offset              ** V1.04
                  ADD  HL,BC                ; relative jump calculated        ** V1.03
                  POP  BC                   ;                                 ** V1.1.1
                  RET                       ;                                 ** V1.03


; ******************************************************************************
;
; Select HL, IX or IY
; opcode in A
;
.Select_IXIY      CP   $FD
                  JR   Z, select_IY
                  LD   L,(IY + VP_IXl)        ; get contents of IX
                  LD   H,(IY + VP_IXh)
                  RET
.select_IY        LD   L,(IY + VP_IYl)        ; get contents of IY
                  LD   H,(IY + VP_IYh)
                  RET


; *******************************************************************************
;
; as above, but with displacement offset included (only IX and IY)
;
.Select_IXIY_disp
                  CP   $FD
                  JR   Z, select_IY_disp
.select_IX_disp   LD   L,(IY + VP_IXl)        ; get contents of IX
                  LD   H,(IY + VP_IXh)
                  EXX                         ; select alternate registers...   ** V0.23
                  LD   A,(HL)                 ; get displacement                ** V0.27e
                  INC  HL                     ;                                 ** V0.27e
                  EXX                         ;                                 ** V0.23
                  JP   Calc_RelAddress
.select_IY_disp   LD   L,(IY + VP_IYl)        ; get contents of IY
                  LD   H,(IY + VP_IYh)
                  EXX                         ;                                 ** V0.23
                  LD   A,(HL)                 ; get displacement                ** V0.27e
                  INC  HL                     ;                                 ** V0.27e
                  EXX                         ;                                 ** V0.23
                  JP   Calc_RelAddress

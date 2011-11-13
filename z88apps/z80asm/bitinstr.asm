; ********************************************************************************************************************
;
;     ZZZZZZZZZZZZZZZZZZZZ    8888888888888       00000000000
;   ZZZZZZZZZZZZZZZZZZZZ    88888888888888888    0000000000000
;                ZZZZZ      888           888  0000         0000
;              ZZZZZ        88888888888888888  0000         0000
;            ZZZZZ            8888888888888    0000         0000       AAAAAA         SSSSSSSSSSS   MMMM       MMMM
;          ZZZZZ            88888888888888888  0000         0000      AAAAAAAA      SSSS            MMMMMM   MMMMMM
;        ZZZZZ              8888         8888  0000         0000     AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
;      ZZZZZ                8888         8888  0000         0000    AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
;    ZZZZZZZZZZZZZZZZZZZZZ  88888888888888888    0000000000000     AAAA      AAAA           SSSSS   MMMM       MMMM
;  ZZZZZZZZZZZZZZZZZZZZZ      8888888888888       00000000000     AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM
;
; Copyright (C) Gunther Strube, 1995-2006
;
; Z80asm is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Z80asm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Z80asm;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; ********************************************************************************************************************

;
; This module generates machine code for all bit manipulation instructions:
;
;    BIT  n,r
;    BIT  n,(HL)
;    BIT  n,(IX+d)
;    BIT  n,(IY+d)
;    SET  ...
;    RES  ...
;
;    RLC  r
;    RLC  (HL)
;    RLC  (IX+d)
;    RLC  (IY+d)
;    RL   ...
;    RRC  ...
;    RR   ...
;    SLA  ...
;    SLL  ...  (undocumented)
;    SRA  ...
;    SRL  ...
;

     MODULE Bit_instructions


; external procedures:
     LIB Read_byte

     XREF Getsym, CheckRegister8, IndirectRegisters         ; prsline.asm
     XREF ReportError_STD, STDerr_syntax, STDerr_ill_ident  ; errors.asm

     XREF WriteByte, WriteWord                              ; writebytes.asm
     XREF Add16bit_1, Add16bit_2, Add16bit_4                ; z80asm.asm
     XREF Test_8bit_range                                   ;

     XREF ParseNumExpr, EvalPfixExpr, RemovePfixlist        ; exprprsr.asm
     XREF ExprSigned8                                       ;


; global procedures:
     XDEF BIT_fn, RES_fn, RL_fn, RLC_fn, RR_fn, RRC_fn
     XDEF SET_fn, SLA_fn, SLL_fn, SRA_fn, SRL_fn

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ******************************************************************************
;
.BIT_fn             LD   C,64                     ; standard instruction opcode
                    CALL BitTest_instr
                    RET


; ******************************************************************************
;
.RES_fn             LD   C,128                    ; standard instruction opcode
                    CALL BitTest_instr
                    RET


; ******************************************************************************
;
.SET_fn             LD   C,192                    ; standard instruction opcode
                    CALL BitTest_instr
                    RET


; ******************************************************************************
;
.RL_fn              LD   C,2                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; ******************************************************************************
;
.RLC_fn             LD   C,0                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; ******************************************************************************
;
.RR_fn              LD   C,3                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; ******************************************************************************
;
.RRC_fn             LD   C,1                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; ******************************************************************************
;
.SLA_fn             LD   C,4                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; ******************************************************************************
;
.SRA_fn             LD   C,5                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; ******************************************************************************
;
.SLL_fn             LD   C,6                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; ******************************************************************************
;
.SRL_fn             LD   C,7                      ; standard instruction opcode
                    CALL Rotshift_instr
                    RET


; **************************************************************************************************
;
; IN: C = Standard instruction opcode
;
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
;
.BitTest_instr      PUSH BC
                    POP  IX                                 ; {preserve standard opcode in IX}
                    CALL Getsym                             ; Getsym()
                    CALL ParseNumExpr
                    XOR  A
                    CP   B                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                    RET  Z
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, bit_evalexpr
                              LD   A, ERR_not_defined
                              CALL ReportError_STD                    ; reporterror(*, *, 2)
                              JP   bit_end                        ; else
.bit_evalexpr                 PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; bitno = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              CALL Test_8bit_range
                              JP   C, bit_range_err
                              EXX
                              PUSH HL
                              EXX
                              POP  BC
                              LD   A,C
                              CP   8
                              JP   NC, bit_range_err                  ; if ( bitno>=0 && bitno<=7 )
                                   LD   A,(sym)
                                   CP   sym_comma
                                   JP   NZ, bit_syntax_err                 ; if ( sym == comma )
                                        CALL Getsym
                                        CP   sym_lparen
                                        JR   NZ, bit_reg                        ; if ( Getsym() == lparen )
                                             CALL IndirectRegisters                  ; reg = IndirectRegister()
                                                                                     ; switch(reg)
                                             CP   2                                       ; case 2:  BIT  n,(HL)
                                             JR   NZ, bit_case_5
                                                  LD   A,C
                                                  RLCA
                                                  RLCA
                                                  RLCA                                         ; bitno * 8
                                                  ADD  A,6                                     ; + 6
                                                  PUSH IX
                                                  POP  BC                                      ; {restore standard opcode}
                                                  ADD  A,C
                                                  LD   B,A
                                                  LD   C,$CB                                   ; *codeptr++ = 203
                                                  CALL WriteWord                               ; *codeptr++ = opcode + bitno*8 + 6
                                                  LD   HL,asm_pc
                                                  CALL Add16bit_2                              ; PC += 2
                                                  JR   bit_remv_pfixexpr

               .bit_case_5                   CP   5                                       ; case 5:
                                             JR   NZ, bit_case_6
                                                  PUSH BC                                      ; {preserve bitno}
                                                  LD   BC,$CBDD                                ; *codeptr++ = 221; *codeptr++ = 203
                                                  CALL WriteWord
                                                  JR   bit_index
               .bit_case_6                   CP   6                                       ; case 6:
                                             JR   NZ,  bit_default1
                                                  PUSH BC
                                                  LD   BC,$CBFD                                ; *codeptr++ = 221; *codeptr++ = 203
                                                  CALL WriteWord
               .bit_index                         CALL ExprSigned8                             ; ExprSigned8()
                                                  POP  BC                                      ; {restore bitno}
                                                  LD   A,C
                                                  RLCA
                                                  RLCA
                                                  RLCA                                         ; bitno * 8
                                                  ADD  A,6                                     ; + 6
                                                  PUSH IX
                                                  POP  BC                                      ; {restore standard opcode}
                                                  ADD  A,C
                                                  LD   C,A
                                                  CALL WriteByte                               ; *codeptr++ = opcode + bitno*8 + 6
                                                  LD   HL, asm_pc
                                                  CALL Add16bit_4                              ; PC += 4
                                                  JR   bit_remv_pfixexpr
               .bit_default1                 CALL STDerr_syntax                           ; default:
                                             JR   bit_remv_pfixexpr                            ; reporterror(*, *, 1)
                                                                                ; else
.bit_reg                                     CALL CheckRegister8                     ; reg = CheckRegister8
                                             CP   6
                                             JR   Z, bit_ill_ident
                                             CP   8                                  ; switch(reg)
                                             JR   Z, bit_ill_ident                        ; case 8:
                                             CP   9
                                             JR   Z, bit_ill_ident                        ; case 9:
                                             CP   -1
                                             JR   NZ,bit_default2                         ; case -1:
.bit_ill_ident                                    CALL Stderr_ill_ident                              Reporterror...
                                                  JR   bit_remv_pfixexpr
.bit_default2                                LD   B,A                                ; default:
                                             LD   A,C
                                             RLCA
                                             RLCA
                                             RLCA                                         ; bitno * 8
                                             ADD  A,B                                     ; + reg
                                             PUSH IX
                                             POP  BC                                      ; {restore standard opcode}
                                             ADD  A,C
                                             LD   C,$CB
                                             LD   B,A
                                             CALL WriteWord                               ; *codeptr++ = opcode + bitno*8 + reg
                                             LD   HL, asm_pc
                                             CALL Add16bit_2                              ; PC += 2
                                             JR   bit_remv_pfixexpr
                                                                           ; else
.bit_syntax_err                    CALL STDerr_syntax
                                   JR   bit_remv_pfixexpr                       ; reporterror(*, *, 1)
                                                                      ; else
.bit_range_err                LD   A,ERR_int_range
                              CALL ReportError_STD                         ; reporterror(*, *, 4)

.bit_remv_pfixexpr       POP  HL
                         POP  BC                                 ; {restore postfixexpr pointer}
.bit_end                 CALL RemovePfixlist                     ; RemovePfixlist(postfixexpr)
                    RET



; **************************************************************************************************
;
; IN: C = Standard instruction opcode
;
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.RotShift_instr     CALL Getsym
                    CP   sym_lparen
                    JR   NZ, rot_reg                        ; if ( Getsym() == lparen )
                         CALL IndirectRegisters                  ; reg = IndirectRegister()
                                                                 ; switch(reg)
                         CP   2                                       ; case 2:  <instr>  n,(HL)
                         JR   NZ, rot_case_5
                              LD   A,C
                              RLCA
                              RLCA
                              RLCA                                         ; opcode * 8
                              ADD  A,6                                     ; + 6
                              LD   B,A
                              LD   C,$CB                                   ; *codeptr++ = 203
                              CALL WriteWord                               ; *codeptr++ = opcode * 8 + 6
                              LD   HL,asm_pc
                              CALL Add16bit_2                              ; PC += 2
                              RET

.rot_case_5              CP   5                                       ; case 5:
                         JR   NZ, rot_case_6
                              PUSH BC                                      ; {preserve rotno}
                              LD   BC,$CBDD                                ; *codeptr++ = 221; *codeptr++ = 203
                              CALL WriteWord
                              JR   rot_index
.rot_case_6              CP   6                                       ; case 6:
                         JP   NZ,  STDerr_syntax
                              PUSH BC                                      ; {preserve opcode}
                              LD   BC,$CBFD                                ; *codeptr++ = 221; *codeptr++ = 203
                              CALL WriteWord
.rot_index                    CALL ExprSigned8                             ; ExprSigned8()
                              POP  BC                                      ; {restore opcode}
                              LD   A,C
                              RLCA
                              RLCA
                              RLCA                                         ; opcode * 8
                              ADD  A,6                                     ; + 6
                              LD   C,A
                              CALL WriteByte                               ; *codeptr++ = opcode * 8 + 6
                              LD   HL, asm_pc
                              CALL Add16bit_4                              ; PC += 4
                              RET
                                                            ; else
.rot_reg                 CALL CheckRegister8                     ; reg = CheckRegister8
                         CP   6                                  ; switch(reg)
                         JP   Z, STDerr_ill_ident                     ; case 6:
                         CP   8
                         JP   Z, STDerr_ill_ident                     ; case 8:
                         CP   9
                         JP   Z, STDerr_ill_ident                     ; case 9:
                         CP   -1
                         JP   Z, STDerr_ill_ident                     ; case -1: reporterror(*, *, 11)

                         LD   B,A                                     ; default:
                         LD   A,C
                         RLCA
                         RLCA
                         RLCA                                         ; opcode * 8
                         ADD  A,B                                     ; + reg
                         LD   C,$CB
                         LD   B,A
                         CALL WriteWord                               ; *codeptr++ = opcode * 8 + reg
                         LD   HL, asm_pc
                         CALL Add16bit_2                              ; PC += 2
                         RET

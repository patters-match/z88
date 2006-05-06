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
; $Id$
;
; ********************************************************************************************************************

;
; This module generates machine code for all simple instructions needing no parsing,
; (just the identifier which has already been parsed)
;
; and various simple function instructions.
;

     MODULE z80instructions


; external procedures:
     LIB Read_byte

     XREF ReportError_STD, STDerr_syntax, STDerr_ill_ident  ; errors.asm

     XREF Getsym, CheckCondition, CheckRegister16           ; prsline.asm
     XREF CheckRegister8                                    ;

     XREF WriteByte, WriteWord                              ; writebytes.asm
     XREF Add16bit_1, Add16bit_2                            ; z80asm.asm
     XREF Test_8bit_range                                   ;

     XREF ParseNumExpr, EvalPfixExpr, RemovePfixlist        ; exprprsr.asm
     XREF ExprUnsigned8                                     ;


; global procedures:
     XDEF CCF_fn, SCF_fn
     XDEF DAA_fn, CPL_fn
     XDEF DI_fn, EI_fn
     XDEF NOP_fn, HALT_fn
     XDEF EXX_fn
     XDEF PUSH_fn, POP_fn
     XDEF RLA_fn, RRA_fn, RRCA_fn, RLCA_fn

     XDEF CPD_fn, CPDR_fn, CPIR_fn, CPI_fn
     XDEF OUTD_fn, OTDR_fn, OTIR_fn, OUTI_fn
     XDEF LDD_fn, LDDR_fn, LDIR_fn, LDI_fn
     XDEF IND_fn, INDR_fn, INIR_fn, INI_fn
     XDEF NEG_fn, RETI_fn, RETN_fn
     XDEF RLD_fn, RRD_fn

     XDEF PushPop_instr
     XDEF RET_fn, RST_fn, EX_fn, IM_fn
     XDEF OUT_fn, IN_fn
     XDEF CALLOZ_fn, FPP_fn


     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.CPL_fn             LD   C,47
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.DAA_fn             LD   C,39
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.DI_fn              LD   C,243
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.EI_fn              LD   C,251
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.EXX_fn             LD   C,217
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.HALT_fn            LD   C,118
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.NOP_fn             LD   C,0
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RLA_fn             LD   C,23
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RRA_fn             LD   C,31
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RRCA_fn            LD   C,15
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RLCA_fn            LD   C,7
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.CCF_fn             LD   C,63
                    JR   Onebyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.SCF_fn             LD   C,55

.Onebyte_instr      CALL WriteByte
                    LD   HL, asm_pc
                    CALL Add16bit_1                         ; ++asm_pc
                    RET


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.NEG_fn             LD   BC,$44ED                           ; 237, 68
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RETI_fn            LD   BC,$4DED                           ; 237, 77
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RETN_fn            LD   BC,$45ED                           ; 237, 69
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RRD_fn             LD   BC,$67ED                           ; 237, 103
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.RLD_fn             LD   BC,$6FED                           ; 237, 111
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.CPD_fn             LD   BC,$A9ED                           ; 237, 169
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.CPDR_fn            LD   BC,$B9ED                           ; 237, 185
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.CPI_fn             LD   BC,$A1ED                           ; 237, 161
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.CPIR_fn            LD   BC,$B1ED                           ; 237, 177
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.IND_fn             LD   BC,$AAED                           ; 237, 170
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.INDR_fn            LD   BC,$BAED                           ; 237, 186
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.INI_fn             LD   BC,$A2ED                           ; 237, 162
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.INIR_fn            LD   BC,$B2ED                           ; 237, 178
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.LDD_fn             LD   BC,$A8ED                           ; 237, 168
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.LDDR_fn            LD   BC,$B8ED                           ; 237, 184
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.LDI_fn             LD   BC,$A0ED                           ; 237, 160
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.LDIR_fn            LD   BC,$B0ED                           ; 237, 176
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.OUTD_fn            LD   BC,$ABED                           ; 237, 171
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.OTIR_fn            LD   BC,$B3ED                           ; 237, 179
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.OTDR_fn            LD   BC,$BBED                           ; 237, 187
                    JR   Twobyte_instr


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.OUTI_fn            LD   BC,$A3ED                           ; 237, 163

.Twobyte_instr      CALL WriteWord
                    LD   HL, asm_pc
                    CALL Add16bit_2                         ; asm_pc += 2
                    RET


; **************************************************************************************************
;
.POP_fn             LD   C,193
                    CALL PushPop_instr
                    RET


; **************************************************************************************************
;
.PUSH_fn            LD   C,197
                    CALL PushPop_instr
                    RET


; **************************************************************************************************
;
; PUSH qq, POP qq instructions
;
; IN: C = Standard opcode
;
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.PushPop_instr      PUSH BC                                 ; preserve opcode
                    CALL Getsym
                    POP  BC
                    CP   sym_name                           ; if ( Getsym() == name )
                    JP   NZ, STDerr_syntax
                         CALL CheckRegister16                    ; qq = CheckRegister16()
                         CP   0                                  ; switch(qq)
                         JR   Z, case_qq                              ; case 0:
                         CP   1
                         JR   Z, case_qq                              ; case 1:
                         CP   2
                         JR   Z, case_qq                              ; case 2:
                         CP   4
                         JR   Z, case_pushpop_4
                         CP   5
                         JR   Z, case_pushpop_5
                         CP   6
                         JR   Z, case_pushpop_6
.default_pushpop         CALL STDerr_ill_ident
                         RET

.case_qq                 RLCA                                               ; {PUSH/POP BC,DE,HL}
                         RLCA
                         RLCA
                         RLCA                                              ; qq * 16
                         ADD  A,C
                         LD   C,A
                         CALL WriteByte                                    ; *codeptr++ = opcode + qq*16
                         LD   HL, asm_pc
                         CALL Add16bit_1                                   ; ++PC
                         RET

.case_pushpop_4          LD   A,C                                          ; {PUSH/POP AF}
                         ADD  A,48
                         LD   C,A
                         CALL WriteByte                                    ; *codeptr++ = opcode + 48
                         LD   HL, asm_pc
                         CALL Add16bit_1                                   ; ++PC
                         RET

.case_pushpop_5          LD   B,C
                         LD   C,221
                         CALL WriteByte                                    ; *codeptr++ = 221
                         LD   A,B                                          ; {PUSH/POP IX}
                         ADD  A,32
                         LD   C,A
                         CALL WriteByte                                    ; *codeptr++ = opcode + 32
                         LD   HL, asm_pc
                         CALL Add16bit_2                                   ; PC += 2
                         RET

.case_pushpop_6          LD   B,C
                         LD   C,253
                         CALL WriteByte                                    ; *codeptr++ = 221
                         LD   A,B                                          ; {PUSH/POP IY}
                         ADD  A,32
                         LD   C,A
                         CALL WriteByte                                    ; *codeptr++ = opcode + 32
                         LD   HL, asm_pc
                         CALL Add16bit_2                                   ; PC += 2
                         RET



; **************************************************************************************************
;
; RET, RET cc  instructions
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.RET_fn             CALL Getsym                        ; GetSym()
                    CP   sym_name                      ; switch(sym)
                    JR   NZ, case_semicolon                 ; case name:
                         CALL CheckCondition
                         CP   -1                                 ; if ( (const = CheckCondition()) == -1 )
                         JP   Z, STDerr_ill_ident                ;    reporterror...
                                                                 ; else
                              RLCA
                              RLCA
                              RLCA
                              ADD  A,192                              ; const = 192 + const * 8   { RET cc }
                              LD   C,A
                              CALL WriteByte                          ; *codeptr++ = const
                              JR   end_ret

.case_semicolon     CP   sym_semicolon
                    JR   Z, RET_instr                       ; case semicolon:
                    CP   sym_newline
                    JP   NZ, STDerr_syntax
.RET_instr               LD   C,201
                         CALL WriteByte                          ; *codeptr++ = 201

                                                            ; default: ReportError( *, *, 1)
.end_RET            LD   HL, asm_pc
                    CALL Add16bit_1                    ; PC++
                    RET



; **************************************************************************************************
;
; EX  instructions
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.EX_fn              CALL Getsym
                    CP   sym_lparen                    ; if ( Getsym() == lparen )
                    JR   NZ, ex_check_reg
                         CALL Getsym
                         CP   sym_name                      ; if ( Getsym() == name )
                         JP   NZ, STDerr_syntax
                              CALL CheckRegister16
                              CP   3                             ; if ( CheckRegister16() == 3 )
                              JP   NZ, STDerr_ill_ident
                                   CALL Getsym
                                   CP   sym_rparen                    ; if ( Getsym() == rparen )
                                   JP   NZ, STDerr_syntax
                                        CALL Getsym
                                        CP   sym_comma                     ; if ( Getsym() == comma )
                                        JP   NZ, STDerr_syntax
                                             CALL Getsym
                                             CP   sym_name                      ; if ( Getsym() == name )
                                             JP   NZ, STDerr_syntax
                                                  CALL CheckRegister16               ; switch(CheckRegister16())
                                                  CP   2
                                                  JR   NZ, ex_check_case1_index1
                                                       LD   C, 227                        ; case 2: {EX (SP),HL}
                                                       CALL WriteByte                               ; *codeptr++ = 227
                                                       LD   HL, asm_pc
                                                       CALL Add16Bit_1                              ; ++PC
                                                       RET

.ex_check_case1_index1                            CP   5
                                                  JR   NZ, ex_check_case1_index2
                                                       LD   BC, $E3DD                     ; case 5: {EX (SP),IX}
                                                       CALL WriteWord                               ; *codeptr++ = 221;
                                                       LD   HL, asm_pc                               ; *codeptr++ = 227;
                                                       CALL Add16Bit_2                              ; PC += 2
                                                       RET

.ex_check_case1_index2                            CP   6
                                                  JP   NZ, STDerr_ill_ident
                                                       LD   BC, $E3FD                     ; case 6: {EX (SP),IY}
                                                       CALL WriteWord                               ; *codeptr++ = 253;
                                                       LD   HL, asm_pc                               ; *codeptr++ = 227;
                                                       CALL Add16Bit_2                              ; PC += 2
                                                       RET
                                                                                          ; default:
                                                                                               ; reporterror(*, *, 11)
                                                       ; else
.ex_check_reg       CP   sym_name
                    JP   NZ, STDerr_syntax                  ; if ( sym == name )
                         CALL CheckRegister16                    ; switch( CheckRegister16() )
                         CP   1
                         JR   NZ, ex_case2_af_reg                     ; case 1: {EX  DE,HL}
                              CALL Getsym
                              CP   sym_comma                                    ; if ( Getsym() == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym
                                   CP   sym_name                                     ; if ( Getsym() == name )
                                   JP   NZ, STDerr_syntax
                                        CALL CheckRegister16
                                        CP   2                                            ; if ( CheckRegister16() == 2 )
                                        JP   NZ, STDerr_ill_ident
                                             LD   C, 235
                                             CALL WriteByte                                    ; *codeptr++ = 235
                                             LD   HL, asm_pc
                                             CALL Add16Bit_1                                   ; ++PC
                                             RET
.ex_case2_af_reg         CP   4
                         JP   NZ, STDerr_ill_ident                    ; case 4:  {EX  AF,AF'}
                              CALL Getsym
                              CP   sym_comma                                    ; if ( Getsym() == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym
                                   CP   sym_name                                     ; if ( Getsym() == name )
                                   JP   NZ, STDerr_syntax
                                        CALL CheckRegister16
                                        CP   4                                            ; if ( CheckRegister16() == 4 )
                                        JP   NZ, STDerr_ill_ident
                                             LD   C, 8
                                             CALL WriteByte                                    ; *codeptr++ = 8
                                             LD   HL, asm_pc
                                             CALL Add16Bit_1                                   ; ++PC
                                             RET



; **************************************************************************************************
;
; OUT instructions
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.OUT_fn             CALL Getsym
                    CP   sym_lparen                    ; if ( Getsym() == lparen )
                    JP   NZ, STDerr_syntax
                         CALL Getsym                        ; Getsym()
                         CALL CheckRegister8
                         CP   1                             ; if ( CheckRegister8() == 1 )     {OUT  (C)}
                         JR   NZ, out_check_reg
                              CALL Getsym
                              CP   sym_rparen                    ; if ( Getsym() == rparen )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym
                                   CP   sym_comma                     ; if ( Getsym() == comma )
                                   JP   NZ, STDerr_syntax
                                        CALL Getsym
                                        CP   sym_name                      ; if ( Getsym() == name )
                                        JP   NZ, STDerr_syntax
                                             CALL CheckRegister8                ; switch(CheckRegister8())
                                             CP   -1
                                             JP   Z, STDerr_ill_ident                ; case -1:
                                             CP   6
                                             JP   Z, STDerr_ill_ident                ; case 8:
                                             CP   8
                                             JP   Z, STDerr_ill_ident                ; case 8:
                                             CP   9
                                             JP   Z, STDerr_ill_ident                ; case 9: reporterror(*, *, 11)

                                             RLCA                                    ; default:
                                             RLCA
                                             RLCA                                         ; reg * 8
                                             ADD  A,65
                                             LD   B,A
                                             LD   C, $ED                                  ; {OUT (C),r}
                                             CALL WriteWord                               ; *codeptr++ = 237
                                             LD   HL, asm_pc                               ; *codeptr++ = 65 + reg*8
                                             CALL Add16Bit_2                              ; PC += 2
                                             RET
                                                       ; else
.out_check_reg      LD   C, 211                             ; *codeptr++ = 211  {OUT (n),A}
                    CALL WriteByte
                    CALL ExprUnsigned8
                    RET  C                                  ; if ( !ExprUnsigned8(1) ) return
                         LD   HL, asm_pc
                         CALL Add16bit_2                    ; PC += 2
                         LD   A,(sym)
                         CP   sym_rparen                    ; if ( sym == rparen )
                         JP   NZ, STDerr_syntax
                              CALL Getsym
                              CP   sym_comma                     ; if ( Getsym() == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym
                                   CP   sym_name                      ; if ( Getsym() == name )
                                   JP   NZ, STDerr_syntax
                                        CALL CheckRegister8               ; if ( CheckRegister8() != 7 ) reporterror()...
                                        CP   7
                                        CALL NZ, STDerr_ill_ident
                                        RET



; **************************************************************************************************
;
; IN instructions
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.IN_fn              CALL Getsym
                    CP   sym_name                           ; if ( Getsym() == name )
                    JP   NZ, STDerr_syntax
                         CALL CheckRegister8                     ; inreg = CheckRegister8()
                                                                 ; switch(inreg)
                         CP   -1
                         JP   Z, STDerr_ill_ident                     ; case -1:
                         CP   8
                         JP   Z, STDerr_ill_ident                     ; case 8:
                         CP   9
                         JP   Z, STDerr_ill_ident                     ; case 9: reporterror(*, *, 11)
                                                                      ; default:
                         PUSH AF                                           ; {preserve inreg}
                         POP  IX
                         CALL Getsym
                         CP   sym_comma                                    ; if (Getsym() != comma)
                         JP   NZ,STDerr_syntax                                  ; reporterror(*, *, 1)
                         CALL Getsym
                         CP   sym_lparen                                   ; if (Getsym() != lparen)
                         JP   NZ,STDerr_syntax
                         CALL Getsym                                       ; Getsym()
                         CALL CheckRegister8                               ; switch(Checkregister8)
                         CP   1
                         JR   NZ, in_unknown_reg                                ; case 1: {IN r,(C)}
                              LD   C,237
                              CALL WriteByte                                         ; *codeptr++ = 237
                              PUSH IX
                              POP  AF                                                ; {restore inreg}
                              RLCA
                              RLCA
                              RLCA                                                   ; inreg * 8
                              ADD  A,64
                              LD   C,A
                              CALL WriteByte                                         ; *codeptr++ = 64 + inreg*8
                              LD   HL, asm_pc
                              CALL Add16bit_2                                        ; PC += 2
                              RET

.in_unknown_reg          CP   -1                                                ; case -1: {IN  A,(n)}
                         JP   NZ, STDerr_ill_ident
                         PUSH IX
                         POP  AF
                         CP   7                                                      ; if ( inreg == 7 )
                         JP   NZ, STDerr_ill_ident
                              LD   C, 219
                              CALL WriteByte                                              ; *codeptr++ = 219
                              CALL ExprUnsigned8                                          ; if ( ExprUnsigned8() )
                              RET  C
                                   LD   A,(sym)                                                ; if ( sym != rparen )
                                   CP   sym_rparen
                                   JP   NZ, STDerr_syntax                                           ; reporterror()
                              LD   HL, asm_pc
                              CALL Add16bit_2                                             ; PC += 2
                              RET



; **************************************************************************************************
;
; IM instructions
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.IM_fn              CALL Getsym                             ; Getsym()
                    CALL ParseNumExpr
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte                          ;
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, IM_evalexpr
                              LD   A, ERR_not_defined
                              CALL ReportError_STD                    ; reporterror(*, *, 2)
                              JR   im_end                        ; else
.im_evalexpr                  PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              EXX
                              LD   A,L                                ; switch(const)
                              EXX
                              CP   0                                       ; case 0:
                              JR   NZ, im_case_1
                                   LD   BC,$46ED                                ; *codeptr++ = 237; *codeptr++ = 70
                                   CALL WriteWord
                                   JR   im_endswitch
.im_case_1                    CP   1                                       ; case 1:
                              JR   NZ, im_case_2
                                   LD   BC,$56ED                                ; *codeptr++ = 237; *codeptr++ = 86
                                   CALL WriteWord
                                   JR   im_endswitch
.im_case_2                    CP   2                                       ; case 2:
                              JR   NZ,  im_default
                                   LD   BC,$5EED                                ; *codeptr++ = 237; *codeptr++ = 94
                                   CALL WriteWord
                                   JR   im_endswitch
.im_default                   LD   A,ERR_ill_option                        ; default:
                              CALL ReportError_STD                              ; reporterror(*, *, 9)

.im_endswitch            LD   HL, asm_pc
                         CALL Add16bit_2                         ; PC += 2
                         POP  HL
                         POP  BC                                 ; {restore postfixexpr pointer}
.im_end                  CALL RemovePfixlist                     ; RemovePfixlist(postfixexpr)
                    RET



; **************************************************************************************************
;
; RST instructions
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.RST_fn             CALL Getsym                             ; Getsym()
                    CALL ParseNumExpr
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, rst_evalexpr
                              LD   A, ERR_not_defined
                              CALL ReportError_STD                    ; reporterror(*, *, 2)
                              JR   rst_end                        ; else
.rst_evalexpr                 PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              CALL Test_8bit_range
                              JR   C, rst_range_err
                              EXX
                              LD   A,L
                              EXX
                              AND  @11000111
                              JR   NZ, rst_range_err                  ; if ( const>=0 && const<=56 && const%8 == 0 )
                                   EXX
                                   LD   A,L
                                   EXX
                                   OR   @11000111
                                   LD   C,A
                                   CALL WriteByte                          ; *codeptr++ = 199 + const
                                   LD   HL, asm_pc
                                   CALL Add16bit_1                         ; ++PC
                                   JR   rst_remv_pfixexpr             ; else
.rst_range_err                     LD   A, ERR_int_range
                                   CALL ReportError_STD                    ; reporterror(*, *, 4)
.rst_remv_pfixexpr            POP  HL
                              POP  BC                                 ; {restore postfixexpr pointer}
.rst_end                 CALL RemovePfixlist                     ; RemovePfixlist(postfixexpr)
                    RET



; **************************************************************************************************
;
; CALLOZ instruction  (OZ system interface call)
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.CALLOZ_fn          LD   C, 231
                    CALL WriteByte                          ; *codeptr++ = 231
                    LD   HL, asm_pc
                    CALL Add16bit_1                         ; ++PC
                    CALL Getsym
                    CP   sym_lparen                         ; if ( Getsym() = lparen )
                    JR   NZ, calloz_expr
                         CALL Getsym                             ; Getsym()

.calloz_expr        CALL ParseNumExpr
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, calloz_evalexpr
                              LD   A, ERR_not_defined
                              CALL ReportError_STD                    ; reporterror(*, *, 2)
                              JR   calloz_end                    ; else
.calloz_evalexpr              PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              LD   A,H
                              OR   L
                              JR   NZ, calloz_range_err               ; if ( const < 65536 )
                                   EXX
                                   PUSH HL
                                   CP   H
                                   EXX
                                   POP  BC
                                   JR   NZ, calloz_wordpar                 ; if ( const < 256 )
                                        CALL WriteByte                          ; *codeptr++ = const
                                        LD   HL, asm_pc
                                        CALL Add16bit_1                         ; ++PC
                                        JR   calloz_remv_pfixexpr          ; else
.calloz_wordpar                         CALL WriteWord                          ; *codeptr++ = const%256
                                        LD   HL, asm_pc                          ; *codeptr++ = const/256
                                        CALL Add16bit_2                         ; PC += 2
                                        JR   calloz_remv_pfixexpr
                                                                      ; else
.calloz_range_err                  LD   A, ERR_int_range
                                   CALL ReportError_STD                    ; reporterror(*, *, 4)
.calloz_remv_pfixexpr         POP  HL
                              POP  BC                                 ; {restore postfixexpr pointer}
.calloz_end              CALL RemovePfixlist                     ; RemovePfixlist(postfixexpr)
                    RET



; **************************************************************************************************
;
; FPP instruction (OZ floating point interface call)
;
; IN: none
; OUT: Appropriate opcode written to machine code buffer
; All register affected except IY.
;
.FPP_fn             LD   C, 223
                    CALL WriteByte                          ; *codeptr++ = 223
                    LD   HL, asm_pc
                    CALL Add16bit_1                         ; ++PC
                    CALL Getsym
                    CP   sym_lparen                         ; if ( Getsym() = lparen )
                    JR   NZ, FPP_expr
                         CALL Getsym                             ; Getsym()

.FPP_expr           CALL ParseNumExpr
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, FPP_evalexpr
                              LD   A, ERR_not_defined
                              CALL ReportError_STD                    ; reporterror(*, *, 2)
                              JR   FPP_end                       ; else
.FPP_evalexpr                 PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              LD   A,H
                              OR   L
                              JR   NZ, FPP_range_err
                              EXX
                              PUSH HL
                              CP   H
                              EXX
                              POP  BC
                              JR   NZ, FPP_range_err                  ; if ( const < 256 )
                                        CALL WriteByte                     ; *codeptr++ = const
                                        LD   HL, asm_pc
                                        CALL Add16bit_1                    ; ++PC
                                        JR   FPP_remv_pfixexpr
                                                                      ; else
.FPP_range_err                     LD   A, ERR_int_range
                                   CALL ReportError_STD                    ; reporterror(*, *, 4)
.FPP_remv_pfixexpr            POP  HL
                              POP  BC                                 ; {restore postfixexpr pointer}
.FPP_end                 CALL RemovePfixlist                     ; RemovePfixlist(postfixexpr)
                    RET

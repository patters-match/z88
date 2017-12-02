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
; This module generates machine code for all jump & call related instructions:
;
;    JP   nn
;    JP   cc,nn
;    JP   (HL), JP (IX), JP (IY)
;    JR   r
;    JR   cc,r
;    DJNZ r
;    CALL nn
;    CALL cc,nn
;

     MODULE Jump_instructions


; external procedures:
     LIB malloc
     LIB Read_byte, Set_word, Read_pointer, Set_pointer

     XREF Getsym, CheckCondition, CheckRegister16           ; prsline.asm
     XREF CheckRegister8                                    ;

     XREF WriteByte, WriteWord                              ; writebytes.asm

     XREF Add16bit_1, Add16bit_2, Add16bit_3                ; z80asm.asm
     XREF Test_7bit_range                                   ;

     XREF CurrentModule                                     ; module.asm

     XREF Pass2Info                                         ; z80pass.asm

     XREF ReportError_STD, STDerr_syntax, STDerr_ill_ident  ; errors.asm

     XREF ParseNumExpr, EvalPfixExpr, RemovePfixlist        ; exprprsr.asm
     XREF ExprAddress                                       ;

; global procedures:
     XDEF JP_fn, CALL_fn
     XDEF JR_fn, DJNZ_fn

     INCLUDE "fpp.def"
     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ******************************************************************************
;
.JP_fn              LD   BC,$C3C2                 ; standard instruction opcodes

; **************************************************************************************************
;
; IN:     B = opcode0 (base opcode for <instr> nn),
;         C = opcode  (opcode for <instr> cc, nn)
;
.JP_instr           LD   DE,(lineptr)                       ; startexpr = lineptr
                    CALL Getsym
                    CP   sym_lparen                         ; if ( Getsym() == lparen )
                    JR   NZ, jp_subr_nn
                         CALL Getsym                             ; Getsym()
                         CALL CheckRegister16                    ; switch( CheckRegister16() )
                         CP   2
                         JR   NZ, jp_case_5                           ; case 2: { JP (HL) }
                              LD   C,233                                        ; *codeptr++ = 233
                              CALL WriteByte
                              LD   HL,asm_pc                                     ; ++PC
                              JP   Add16bit_1

.jp_case_5               CP   5                                       ; case 5:
                         JR   NZ, jp_case_6                                     ; { JP (IX) }
                              LD   BC,$E9DD                                     ; *codeptr++ = 221
                              JR   jp_index_6                                   ; *codeptr++ = 233
                                                                                ; PC += 2
.jp_case_6               CP   6                                       ; case 6:
                         JR   NZ, jp_case_notf                                  ; { JP (IY) }
                              LD   BC,$E9FD                                     ; *codeptr++ = 253
.jp_index_6                   CALL WriteWord                                    ; *codeptr++ = 233
                              LD   HL,asm_pc                                     ; PC += 2
                              JP   Add16bit_2

.jp_case_notf            CP   -1                                      ; case -1: reporterror(1)
                         JP   Z, STDerr_syntax
                         JP   STDerr_ill_ident                        ; default: reporterror(11)
                                                            ; else
.jp_subr_nn              LD   (lineptr),DE                       ; lineptr = startexpr
                                                                 ; Subroutine(opc0, opc)


; **************************************************************************************************
;
; IN:     B = opcode0 (base opcode for <instr> nn),
;         C = opcode  (opcode for <instr> cc, nn)
;
.Subroutine_cc      CALL Getsym                             ; Getsym()
                    CALL Checkcondition
                    CP   -1                                 ; if ( (const=CheckCondition()) != -1 )
                    JR   Z, subr_address
                         RLCA                                    ; <instr> cc, nn
                         RLCA
                         RLCA                                    ; const*8
                         ADD  A,C                                ; + opcode
                         LD   C,A
                         CALL WriteByte                          ; *codeptr++ = opcode + const*8
                         CALL Getsym                             ; if ( Getsym() != comma )
                         CP   sym_comma                               ; Reporterror(*, *, 1)
                         JP   NZ, STDerr_syntax                  ; else
                              CALL Getsym                             ; Getsym()
                              JR   read_expr
.subr_address                                               ; else
                         LD   C,B                                ; <instr> nn
                         CALL WriteByte                          ; *codeptr++ = opcode0
.read_expr          CALL ExprAddress                        ; ExprAddress(1)
                    LD   HL, asm_pc
                    JP   Add16bit_3                         ; PC += 3

; ******************************************************************************
;
.CALL_fn            LD   BC,$CDC4                 ; standard instruction opcodes
                    JR   Subroutine_cc



; **************************************************************************************************
;
;
.JR_fn              CALL Getsym
                    CP   sym_name                           ; if ( Getsym() == name )
                    JR   NZ, jr_addr_expr
                         CALL CheckCondition                     ; switch( const = CheckCondition )
                         CP   0
                         JR   Z, jr_case_3                            ; case 0:
                         CP   1
                         JR   Z, jr_case_3                            ; case 1:
                         CP   2
                         JR   Z, jr_case_3                            ; case 2:
                         CP   3
                         JR   NZ, jr_case_notf                        ; case 3: { JR cc,n }
.jr_case_3                    RLCA
                              RLCA
                              RLCA
                              ADD  A,32
                              LD   C,A
                              CALL WriteByte                               ; *codeptr++ = 32 + const*8
                              CALL Getsym
                              CP   sym_comma                               ; if ( Getsym() == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym                                  ; Getsym()
                                   JR   jr_addr_expr                            ; break
                                                                           ; else reporterror(1)
.jr_case_notf            CP   -1
                         JP   NZ, STDerr_syntax                       ; case -1:
                              LD   C,24                                    ; codeptr++ = 24 { JR n }
                              CALL WriteByte                               ; break
                                                                      ; default: reporterror(1)
.jr_addr_expr       LD   HL,asm_pc
                    CALL Add16bit_2                         ; PC+=2
                    JR   djnz_continue                      ; parse JR expression...


; **************************************************************************************************
;
;
.DJNZ_fn            LD   C,16
                    CALL WriteByte                          ; *codeptr++ = 16
                    LD   HL,asm_pc
                    CALL Add16bit_2                         ; PC+=2
                    CALL Getsym
                    CP   sym_comma                          ; if ( Getsym() == comma )
                    JR   NZ, djnz_continue
                         CALL Getsym                             ; Getsym()
.djnz_continue      CALL ParseNumExpr
                    RET  C                                       ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, djnz_evalexpr
                              LD   C, RANGE_JROFFSET
                              CALL Pass2Info                          ; Pass2Info(postfixexpr, RANGE_JROFFSET, 1)
                              CALL NewJRaddr                          ; NewJRaddr()
                              LD   C,0
                              CALL WriteByte                          ; ++codeptr
                              RET                                ; else
.djnz_evalexpr                PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              EXX
                              LD   DE,(asm_pc)
                              EXX
                              LD   DE,0
                              LD   B,0                                ; {PC = DEdeB}
                              FPP  (FP_SUB)                           ; const -= PC
                              CALL Test_7bit_range                    ; if ( const>=-128 && const<=127 )
                              EXX
                              PUSH HL
                              EXX
                              POP  BC                                      ; {const}
                              JR   C, djnz_error
                                   CALL WriteByte
                                   JR   djnz_end                           ; *codeptr++ = const
                                                                      ; else
.djnz_error                        LD   A,ERR_range
                                   CALL ReportError_STD                    ; reporterror(7)
.djnz_end           POP  HL
                    POP  BC
                    JP   RemovePfixlist                          ; RemovePfixlist(postfixexpr)


; **************************************************************************************************
;
; New JR address record in list
;
.NewJRaddr          CALL AllocJrPC                          ; { allocate room rom new JRPC node }
                    JR   NC,newjr_init                      ; if ( (newJRPC=AllocJrPC()) == NULL )
                         LD   A, ERR_no_room                     ; Reporterror(3)
                         JP   ReportError_STD                    ; return
                                                            ; else
.newjr_init              LD   A, jrpc_next
                         LD   C,0
                         LD   D,C
                         LD   E,C
                         CALL Set_pointer                             ; newJRPC->nextref = NULL
                         LD   A, jrpc_PCaddr
                         LD   DE,(asm_pc)
                         CALL Set_word                                ; newJRPC->PCaddr = PC
                         LD   C,B
                         EX   DE,HL                                   ; {newJRPC in CDE}
                    CALL CurrentModule
                    LD   A, module_jraddr
                    CALL Read_pointer                       ; CURRENTMODULE->JRaddr
                    PUSH BC
                    PUSH HL                                 ; {preserve pointer}
                    LD   A, jrpcexpr_first
                    CALL Read_pointer                       ; CURRENTMODULE->JRaddr->firstref
                    XOR  A
                    CP   B                                  ; IF ( firstref == NULL )
                    JR   NZ, newjr_addlist
                         POP  HL
                         POP  BC
                         LD   A, jrpcexpr_first
                         CALL Set_pointer                        ; CURRENTMODULE->JRaddr->firstref = newJRPC
                         LD   A, jrpcexpr_last
                         JP   Set_pointer                        ; CURRENTMODULE->JRaddr->lastref = newJRPC
                                                            ; else
.newjr_addlist      POP  HL
                    POP  BC
                    PUSH HL
                    PUSH BC                                      ; {preserve CURRENTMODULE->JRaddr}
                    LD   A, jrpcexpr_last
                    CALL Read_pointer                            ; CURRENTMODULE->JRaddr->lastref
                    LD   A, jrpc_next
                    CALL Set_pointer                             ; CURRENTMODULE->JRaddr->lastref->nextref = newJRPC
                    POP  BC
                    POP  HL
                    LD   A, jrpcexpr_last                        ; CURRENTMODULE->JRaddr->lastref = newJRPC
                    JP   Set_pointer


; **************************************************************************************************
;
.AllocJrPC          LD   A,SIZEOF_JrPC
                    JP   malloc

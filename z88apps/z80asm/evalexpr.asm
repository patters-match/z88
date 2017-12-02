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

     MODULE Evaluate_expression


; external variables, constants:
     XREF separators                                                  ; consts.asm

; external procedures:
     LIB malloc, mfree
     LIB Read_long, Set_long, Read_pointer, Set_pointer
     LIB Read_byte, Set_byte

     XREF Getsym                                                      ; prsline.asm
     XREF CurrentModule                                               ; module.asm
     XREF GetSymPtr, FindSymbol                                       ; symbols.asm
     XREF GetVarPointer                                               ; z80asm.asm
     XREF ReportError_STD                                             ; errors.asm

; global procedures:
     XDEF EvalPfixExpr

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"
     INCLUDE "fpp.def"
     INCLUDE "fileio.def"


; ******************************************************************************************
;
; IN: BHL = pfixlist, pointer to header of postfix expression list
;
; OUT: Result of operation in HLhlC (signed long integer)
;
; Registers changed after return:
;
; ......../IXIY/........ same
; AFBCDEHL/..../afbcdehl different
;
.EvalPfixExpr       PUSH IY
                    PUSH IX
                    LD   IY,0
                    ADD  IY,SP               ; IY points at original registers
                    LD   IX,-9
                    ADD  IX,SP
                    LD   SP,IX               ; room on stack for local variables
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   (IX+2),B            ; remember header of postfix expression

                    LD   A,expr_rangetype
                    CALL Read_byte           ; pfixlist->rangetype
                    AND  EVALUATED
                    LD   C,A
                    LD   A,expr_rangetype
                    CALL Set_byte            ; pfixlist->rangetype &= EVALUATED
                    LD   A,expr_pfixlist_first
                    CALL Read_pointer        ; pfixexpr = pfixlist->firstnode
                    LD   C,B
                    EX   DE,HL               ; {preserve pfixexpr in CDE}
                    LD   A,SIZEOF_pointer
                    CALL malloc              ; **stackptr = malloc(SIZEOF_pointer)
                    JP   C, err_evalexpr
                    LD   (IX+6),L
                    LD   (IX+7),H
                    LD   (IX+8),B            ; **stackptr saved
                    PUSH BC
                    PUSH DE                  ; {preserve pfixexpr in CDE}
                    LD   C,0
                    LD   D,C
                    LD   E,C
                    XOR  A
                    CALL Set_pointer         ; *stackptr = NULL
                    POP  HL
                    POP  BC
                    LD   B,C                 ; {pfixexpr in BHL}

.evalexpr_loop      LD   (IX+3),L            ; do
                    LD   (IX+4),H
                    LD   (IX+5),B                 ; {preserve pfixexpr}
                         LD   A,pfixlist_oprtype
                         CALL Read_byte           ; switch(pfixexpr->operatortype)
                              CP   sym_number          ; case number:
                              JP   NZ, evalexpr_negated
                                   PUSH BC
                                   PUSH HL                  ; {preserve pfixexpr}
                                   LD   A,pfixlist_ident
                                   CALL Read_pointer        ; pfixexpr->id
                                   LD   A,B
                                   EX   DE,HL               ; {id in ADE}
                                   POP  HL
                                   POP  BC
                                   LD   C,A                 ; {BHL = pfixexpr, CDE = pfixexpr->id}
                                   CP   0                   ; if ( pfixexpr->id == NULL )  operand an identifier?
                                   JR   NZ, id_defined
                                        LD   A,pfixlist_oprconst
                                        CALL Read_long           ; pfixexpr->operandconst
                                        EXX
                                        PUSH DE
                                        LD   H,B
                                        LD   L,C
                                        EXX
                                        POP  HL                  ; operandconst
                                        LD   E,(IX+6)
                                        LD   D,(IX+7)
                                        LD   C,(IX+8)
                                        CALL PushItem            ; PushItem(operandconst, stackptr)
                                        JP   evalexpr_nextopr
.id_defined                                                 ; else
                                        LD   A,pfixlist_symtype
                                        CALL Read_byte
                                        CP   SYM_NOTDEFINED      ; if ( pfixexpr->type != SYM_NOTDEFINED )
                                        JR   Z, sym_not_defined
                                             BIT  SYMLOCAL,A
                                             JR   Z, sym_global       ; if ( pfixexpr->type & SYMLOCAL )
                                                  CALL CurrentModule
                                                  LD   A,module_localroot
                                                  CALL Read_pointer        ; {BHL=CURRENTMODULE->localroot, CDE=pfixexpr->id}
                                                  CALL FindSymbol          ; symptr = FindSymbol(pfixexpr->id, CURRENTMODULE->localroot)

.push_symvalue                                    LD   A,symtree_type
                                                  CALL Read_byte
                                                  AND  SYMTYPE
                                                  LD   C,A
                                                  PUSH BC
                                                  PUSH HL                  ; {preserve symptr}
                                                  LD   L,(IX+0)
                                                  LD   H,(IX+1)
                                                  LD   B,(IX+2)
                                                  LD   A,expr_rangetype
                                                  CALL Read_byte
                                                  OR   C
                                                  LD   C,A
                                                  LD   A,expr_rangetype
                                                  CALL Set_byte            ; pfixlist->rangetype |= symptr->type & SYMTYPE
                                                  POP  HL
                                                  POP  BC
                                                  LD   A,symtree_symvalue
                                                  CALL Read_long
                                                  EXX
                                                  PUSH DE
                                                  LD   H,B
                                                  LD   L,C
                                                  EXX
                                                  POP  HL                  ; symptr->symvalue
                                                  LD   E,(IX+6)
                                                  LD   D,(IX+7)
                                                  LD   C,(IX+8)            ; **stackptr
                                                  CALL PushItem            ; PushItem(symptr->symvalue, stackptr)
                                                  JP   evalexpr_nextopr
.sym_global                                                           ; else
                                                  LD   HL,globalroot
                                                  CALL GetVarPointer
                                                  CALL FindSymbol          ; symptr = FindSymbol(pfixexpr->id, globalroot)
                                                  LD   A,symtree_type
                                                  CALL Read_byte
                                                  BIT  SYMDEFINED,A        ; if ( symptr->type & SYMDEFINED )
                                                  JR   Z, sym_not_found         ; pfixlist->rangetype |= symptr->type & SYMTYPE
                                                       JR   push_symvalue       ; PushItem(symptr->symvalue, stackptr)
                                                                           ; else
                                                                                ; pfixlist->rangetype |= NOTEVALUABLE
                                                                                ; ClearEvalStack(stackptr)
                                                                                ; return 0
.sym_not_defined                                                 ; else
                                             CALL GetSymPtr           ; symptr = GetSymPtr(pfixexpr->id)
                                             XOR  A
                                             CP   B                   ; if ( symptr != NULL && symptr->type SYMDEFINED )
                                             JR   Z, sym_not_found
                                             LD   A,symtree_type
                                             CALL Read_byte
                                             BIT  SYMDEFINED,A
                                             JR   Z, sym_not_found
                                                                           ; pfixlist->rangetype |= symptr->type & SYMTYPE
                                                  JR   push_symvalue       ; PushItem(symptr->symvalue, stackptr)
.sym_not_found                                                        ; else
                                                  LD   L,(IX+0)
                                                  LD   H,(IX+1)
                                                  LD   B,(IX+2)
                                                  LD   A,expr_rangetype
                                                  CALL Read_byte           ; pfixlist->rangetype
                                                  OR   NOTEVALUABLE
                                                  LD   C,A
                                                  LD   A,expr_rangetype
                                                  CALL Set_byte            ; pfixlist->rangetype |= NOTEVALUABLE
                                                  LD   HL,0
                                                  PUSH HL
                                                  EXX
                                                  POP  HL
                                                  EXX
                                                  LD   E,(IX+6)
                                                  LD   D,(IX+7)
                                                  LD   C,(IX+8)
                                                  CALL PushItem            ; PushItem(0, stackptr)
                                                  JR   evalexpr_nextopr

.evalexpr_negated             CP   sym_negated         ; case negated:
                              JR   NZ, evalexpr_lognot
                                   LD   E,(IX+6)
                                   LD   D,(IX+7)
                                   LD   C,(IX+8)            ; {get **stackptr}
                                   PUSH BC
                                   PUSH DE
                                   CALL PopItem             ; const = PopItem(stackptr)
                                   LD   C,0
                                   FPP  (FP_NEG)            ; const = - const
                                   POP  DE
                                   POP  BC
                                   CALL PushItem            ; PushItem(const, stackptr)
                                   JR   evalexpr_nextopr    ; break

.evalexpr_lognot              CP   sym_not             ; case log_not:
                              JR   NZ, evalexpr_constexpr
                                   LD   E,(IX+6)
                                   LD   D,(IX+7)
                                   LD   C,(IX+8)
                                   PUSH BC
                                   PUSH DE                  ; {preserve **stackptr}
                                   CALL PopItem             ; const = PopItem(stackptr)
                                   LD   DE,0
                                   PUSH DE
                                   EXX
                                   POP  DE
                                   EXX
                                   LD   BC,0                ; {integers}
                                   FPP  (FP_EQ)             ; const = !const
                                   POP  DE
                                   POP  BC
                                   CALL PushItem            ; PushItem(const, stackptr)
                                   JR   evalexpr_nextopr    ; break;

.evalexpr_constexpr           CP   sym_constexpr       ; case constexpr:
                              JR   NZ, evalexpr_default
                                   LD   L,(IX+0)
                                   LD   H,(IX+1)
                                   LD   B,(IX+2)
                                   LD   A,expr_rangetype
                                   CALL Read_byte                ; pfixlist->rangetype
                                   RES  SYMADDR,A
                                   LD   C,A
                                   LD   A,expr_rangetype
                                   CALL Set_byte                 ; pfixlist->rangetype &= CLEAR_EXPRADDR
                                   JR   evalexpr_nextopr         ; break

.evalexpr_default             LD   E,(IX+6)            ; default:
                              LD   D,(IX+7)
                              LD   C,(IX+8)
                              LD   B,A                      ; pfixexpr->operatortype
                              CALL CalcExpression           ; CalcExpression(pfixexpr->operatortype, stackptr)

.evalexpr_nextopr        LD   L,(IX+3)
                         LD   H,(IX+4)
                         LD   B,(IX+5)            ; {pfixexpr}
                         LD   A,pfixlist_nextopr
                         CALL Read_pointer        ; pfixexpr = pfixexpr->nextoperand

.evalexpr_while     XOR  A
                    CP   B
                    JP   NZ, evalexpr_loop   ; while ( pfixexpr != NULL )

                    LD   L,(IX+6)
                    LD   H,(IX+7)
                    LD   B,(IX+8)            ; {**stackptr in BHL}
                    PUSH BC
                    PUSH HL
                    XOR  A
                    CALL Read_pointer
                    XOR  A
                    CP   B                   ; if ( *stackptr != NULL )
                    POP  DE
                    POP  BC
                    LD   C,B                      ; {CDE=**stackptr}
                    CALL NZ, PopItem              ; const = PopItem(stackptr)
                    PUSH HL                  ; else
                    EXX                           ; const = ?
                    PUSH HL
                    EXX
                    LD   B,C
                    EX   DE,HL               ; {BHL=**stackptr}
                    CALL mfree               ; free(stackptr)
                    EXX
                    POP  HL
                    EXX
                    POP  HL
                    LD   C,0                 ; {const = HLhlC}
                    JR   exit_evalexpr

.err_evalexpr       LD   A,ERR_no_room
                    CALL ReportError_STD     ; no room...

.exit_evalexpr      LD   SP,IY
                    POP  IX
                    POP  IY
                    RET



; ******************************************************************************************
;
; Calculate expression operands
;
; IN: CDE = **stackptr
;       B = operand
;
; OUT: Result of operation on evaluation stack.
;
; Registers changed after return:
;
; ..BCDE../IXIY/........ same
; AF....HL/..../afbcdehl different
;
.CalcExpression     PUSH DE                  ; {preserve original DE}
                    PUSH BC                  ; {preserve original BC}
                    CALL PopItem             ; rightop = PopItem(stackptr)
                    PUSH HL
                    EXX
                    PUSH HL                  ; {preserve rightop}
                    EXX
                    CALL PopItem             ; leftop = PopItem(stackptr)
                                             ; {leftop = HLhl}
                    EXX
                    POP  DE
                    EXX
                    POP  DE                  ; {install rightop}
                    LD   A,B
                    LD   BC,0                ; {integer arithmetic...}
                    CP   sym_and             ; switch(operand)
                    JR   NZ, calcexp_or           ; case bin_and:
                         FPP  (FP_AND)
                         JR   end_calcexpr

.calcexp_or         CP   sym_or
                    JR   NZ, calcexp_xor          ; case bin_or:
                         FPP  (FP_OR)
                         JR   end_calcexpr

.calcexp_xor        CP   sym_xor
                    JR   NZ, calcexp_add          ; case bin_xor:
                         FPP  (FP_EOR)
                         JR   end_calcexpr

.calcexp_add        CP   sym_plus
                    JR   NZ, calcexp_minus        ; case plus:
                         FPP  (FP_ADD)
                         JR   end_calcexpr

.calcexp_minus      CP   sym_minus
                    JR   NZ, calcexp_multiply     ; case minus:
                         FPP  (FP_SUB)
                         JR   end_calcexpr

.calcexp_multiply   CP   sym_multiply
                    JR   NZ, calcexp_divi         ; case multiply:
                         FPP  (FP_MUL)
                         JR   end_calcexpr

.calcexp_divi       CP   sym_divi
                    JR   NZ, calcexp_mod          ; case divi:
                         FPP  (FP_IDV)
                         JR   end_calcexpr

.calcexp_mod        CP   sym_mod
                    JR   NZ, calcexp_power        ; case mod:
                         FPP  (FP_MOD)
                         JR   end_calcexpr

.calcexp_power      CP   sym_power
                    JR   NZ, calcexp_assign       ; case power:
                         FPP  (FP_PWR)
                         JR   end_calcexpr

.calcexp_assign     CP   sym_assign
                    JR   NZ, calcexp_lessequal    ; case assign:
                         FPP  (FP_EQ)
                         JR   end_calcexpr

.calcexp_lessequal  CP   sym_lessequal
                    JR   NZ, calcexp_greatequal   ; case lessequal:
                         FPP  (FP_LEQ)
                         JR   end_calcexpr

.calcexp_greatequal CP   sym_greatequal
                    JR   NZ, calcexp_notequal     ; case greatequal:
                         FPP  (FP_GEQ)
                         JR   end_calcexpr

.calcexp_notequal   CP   sym_notequal
                    JR   NZ, calcexp_default      ; case notequal:
                         FPP  (FP_NEQ)
                         JR   end_calcexpr

.calcexp_default    FPP  (FP_ZER)                 ; default:

.end_calcexpr       CALL C,ReportError_STD
                    POP  BC
                    POP  DE
                    CALL PushItem            ; PushItem(result, stackptr)
                    RET



; **********************************************************************************
;
; Push constant on evaluation stack
;
; IN: CDE  = **stackptr
;     HLhl = constant
;
; OUT: None.
;
; Registers changed after return:
;
; ...CDE../IXIY/........ same
; AFB...HL/..../afbcdehl different
;
.PushItem           PUSH HL
                    EXX
                    PUSH HL                  ; {preserve constant}
                    EXX
                    CALL AllocStackItem      ; newitem = AllocStackItem() (in BHL)
                    XOR  A
                    CP   B                   ; if ( newitem != NULL )
                    JR   Z,push_no_room
                         EXX
                         POP  BC
                         POP  DE
                         EXX
                         LD   A, pfixstack_const  ; newitem->stackconstant = oprconst
                         CALL Set_long

                         PUSH BC
                         PUSH DE                  ; {preserve **stackptr}
                         PUSH BC
                         PUSH HL                  ; {preserve newitem}
                         LD   B,C
                         EX   DE,HL               ; {**stackptr in BHL}
                         XOR  A
                         CALL Read_pointer        ; {get *stackptr}
                         LD   A,B
                         LD   D,H
                         LD   E,L                 ; {*stackptr in ADE}
                         POP  HL
                         POP  BC
                         LD   C,A                 ; {BHL=newitem, CDE=*stackptr}
                         LD   A,pfixstack_previtem
                         CALL Set_pointer         ; newitem->prevstackitem = *stackptr
                         EX   DE,HL
                         LD   A,B                 ; {ADE=newitem}

                         POP  HL
                         POP  BC
                         LD   B,C                 ; {BHL = **stackptr}
                         LD   C,A                 ; {CDE = newitem}
                         XOR  A
                         CALL Set_pointer         ; *stackptr = newitem
                         LD   C,B
                         EX   DE,HL               ; {CDE = **stackptr}
                         RET

.push_no_room       LD   A,ERR_no_room
                    CALL ReportError_STD
                    RET



; **********************************************************************************
;
; Pop constant from evaluation stack
;
; IN:  CDE  = **stackptr
; OUT: HLhl = constant
;
; Registers changed after return:
;
; ..BCDE../IXIY/........ same
; AF....HL/..../afbcdehl different
;
.PopItem            PUSH BC
                    PUSH DE                  ; {preserve **stackpointer}
                    LD   H,D
                    LD   L,E
                    LD   B,C
                    XOR  A
                    CALL Read_pointer        ; *stackpointer

.pop_item           LD   A,pfixstack_const
                    CALL Read_long           ; const = (*stackpointer)->constant {in alternate debc}
                    EXX
                    PUSH DE
                    PUSH BC                  ; {preserve const}
                    EXX
                    PUSH HL
                    PUSH BC                  ; stackitem = *stackpointer
                    LD   A,pfixstack_previtem
                    CALL Read_pointer        ; stackptr = (*stackpointer)->previtem in BHL
                    LD   A,B
                    LD   B,C
                    LD   C,A
                    EX   DE,HL               ; {BHL=**stackpointer, CDE=stackptr}
                    XOR  A
                    CALL Set_pointer         ; *stackpointer = stackptr

.pop_topstack       POP  BC
                    POP  HL                  ; {get old stackitem}
                    CALL mfree               ; free(stackitem)

                    EXX
                    POP  HL
                    EXX
                    POP  HL                  ; return const
                    POP  DE
                    POP  BC                  ; {restore **stackpointer in CDE}
                    RET



; ******************************************************************************************
;
; Remove evaluation stack from memory
;
; IN: CDE = **stackptr, pointer to pointer to top of stack
;
; Registers changed after return:
;
; ..BCDEHL/IXIY/........ same
; AF....../..../afbcdehl different
;
.ClearEvalStack     PUSH BC
                    PUSH HL
.clearstack_loop    LD   B,C
                    LD   H,D
                    LD   L,E
                    XOR  A
                    CALL Read_pointer             ; {*stackptr}
                    INC  B
                    DEC  B
                    JR   NZ, clearstack_end       ; while ( *stackptr != NULL )
                         CALL PopItem                  ; PopItem(stackptr)
                    JR   clearstack_loop
.clearstack_end     POP  HL
                    POP  BC
                    RET



; ****************************************************************************************
;
; Allocate memory for new node of postfix expression evaluation stack
;
.AllocStackItem     LD   A,SIZEOF_pfixstack
                    CALL malloc
                    RET

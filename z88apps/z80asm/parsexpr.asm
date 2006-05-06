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

     MODULE Parse_expression


; external variables, constants:
     XREF separators                                                  ; consts.asm

; external procedures:
     LIB malloc, mfree, AllocIdentifier
     LIB Read_byte, Set_byte, Read_long, Set_word, Set_long, Read_pointer
     LIB Set_pointer, Bind_bank_s1
     LIB memcpy

     XREF NULL_pointer, GetSymPtr, ReleaseId                          ; symbols.asm
     XREF Getsym                                                      ; getsym.asm
     XREF GetConstant                                                 ; getconst.asm

     XREF WriteLong, WriteWord, WriteByte                             ; bytesio.asm
     XREF ReportError_STD                                             ; errors.asm

; global procedures:
     XDEF ParseNumExpr
     XDEF RemovePfixList

     INCLUDE "fileio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
; Parse infix expression from (lineptr) and generate postfix expression list.
; Pointer to postfix expression is returned in BHL
;
; IN: None.
;
; If syntax error occurred, Fc = 1 and BHL = NULL
;
; Registers changed after return:
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.ParseNumExpr       PUSH IX
                    PUSH BC
                    PUSH DE
                    CALL AllocExpr
                    XOR  A
                    CP   B                        ; if ( (pfixhdr = AllocExpr()) == NULL )
                    JR   NZ, init_pfixhdr
                         LD   A,ERR_no_room
                         CALL ReportError_STD          ; ReportError(3)
                         CALL NULL_pointer             ; return NULL
                         SCF
                         JP   end_parse_expr     ; else

.init_pfixhdr            LD   C,0
                         LD   D,C
                         LD   E,C                      ; {NULL pointer}
                         LD   A,expr_nextexpr          ; pfixhdr->nextexpr = NULL
                         CALL Set_pointer
                         LD   A,expr_pfixlist_first    ; pfixhdr->firstnode = NULL
                         CALL Set_pointer
                         LD   A,expr_pfixlist_curr     ; pfixhdr->currentnode = NULL
                         CALL Set_pointer
                         LD   A,expr_infixexpr         ; pfixhdr->infixexpr = NULL
                         CALL Set_pointer
                         LD   A,expr_rangetype         ; pfixhdr->rangetype = 0
                         CALL Set_byte
                         LD   A,expr_stored            ; pfixhdr->stored = OFF
                         CALL Set_byte
                         EXX
                         LD   BC,(codeptr)             ; expand patch pointer to long
                         LD   DE,0                     ; this is needed by .Z80pass2
                         EXX
                         LD   A,expr_codepos           ; pfixhdr->codepos = codeptr
                         CALL Set_long
                         PUSH BC
                         PUSH HL
                         CALL AllocInfixExpr
                         EX   DE,HL
                         POP  HL
                         LD   A,B
                         POP  BC
                         LD   C,A
                         LD   A, expr_infixexpr
                         CALL Set_pointer              ; pfixhdr->infixexpr = AllocInfixExpr()
                         XOR  A
                         CP   C
                         JR   NZ, parse_expr           ; if ( pfixhdr->infixexpr == NULL )
                              LD   A,ERR_no_room            ; Reporterror(3)
                              CALL ReportError_STD          ; free(pfixhdr)
                              CALL mfree                    ; return NULL
                              SCF
                              JR   end_parse_expr

.parse_expr         LD   A,expr_infixptr          ; pfixhdr->infixptr = pfixhdr->infixexpr
                    CALL Set_pointer

                    LD   A,(sym)
                    LD   D,A                      ; constexpr = sym
                    CP   sym_constexpr
                    JR   NZ, parse_condition      ; if ( constexpr == sym_constexpr)
                         LD   A,'#'
                         CALL Infix_operator           ; *pfixhdr->infixptr++ = '#'
                         CALL Getsym                   ; Getsym()

.parse_condition    CALL Condition
                    JR   C, error_parse_expr      ; if ( Condition(pfixhdr) )
                         LD   A, sym_constexpr
                         CP   D
                         JR   NZ, complete_expr        ; if (constexpr == sym_constexpr)
                              LD   E,A
                              LD   D,0
                              LD   C,0
                              LD   IX,0                     ; NewPfixSymbol(pfixexpr, 0, sym_constexpr, NULL, 0)
                              CALL NewPfixSymbol
.complete_expr           XOR  A
                         CALL Infix_operator           ; *pfixexpr->infixptr = '\0'
                         CP   A
                         JR   end_parse_expr           ; return pfixhdr
                                                  ; else
.error_parse_expr        CALL RemovePfixList           ; RemovePfixList(pfixhdr)
                         CALL NULL_pointer             ; return NULL
                         SCF

.end_parse_expr     POP  DE
                    LD   A,B
                    POP  BC
                    LD   B,A
                    POP  IX
                    RET



; **************************************************************************************************
;
; IN: BHL = pointer to postfix expression header
;
; OUT: Fc = 1 if syntax error, otherwise Fc = 0
;
; Registers changed after return:
;    ..B.DEHL/IXIY  same
;    AF.C..../....  different
;
.Condition          PUSH DE

.cond_continue      CALL Expression
                    JP   C, end_cond              ; if ( !Expression(pfixexpr) ) return 0

                    LD   A,(sym)
                    LD   D,A                      ; relsym = sym
                    CP   sym_less                 ; switch(sym)
                    JR   NZ, cond_sw1_assign           ; case less:
                         LD   A,'<'
                         CALL Infix_operator                          ; *pfixexpr->infixptr++ = '<'
                         CALL Getsym                                  ; Getsym()
                         CP   sym_greater                             ; switch(sym)
                         JR   NZ, cond_sw2_assign                          ; case greater: '<>'
                              LD   A,'>'
                              CALL Infix_operator                                         ; *pfixexpr->infixptr++ = '>'
                              LD   D, sym_notequal                                        ; relsym = sym_notequal
                              CALL Getsym
                              JR   cond_sw1_end                                           ; break;

.cond_sw2_assign         CP   sym_assign
                         JR   NZ,cond_sw1_end                              ; case assign: '<='
                              LD   A,'='
                              CALL Infix_operator                                         ; *pfixexpr->infixptr++ = '='
                              LD   D, sym_lessequal                                       ; relsym = sym_lessequal
                              CALL Getsym                                                 ; break
                              JR   cond_sw1_end                       ; break;

.cond_sw1_assign    CP   sym_assign                    ; case assign:
                    JR   NZ, cond_sw1_greater
                         LD   A,'='
                         CALL Infix_operator                          ; *pfixexpr->infixptr++ = '='
                         CALL Getsym                                  ; Getsym()
                         JR   cond_sw1_end                            ; break;

.cond_sw1_greater   CP   sym_greater                   ; case greater:
                    JR   NZ, cond_sw1_default
                         LD   A,'>'
                         CALL Infix_operator                          ; *pfixexpr->infixptr++ = '>'
                         CALL Getsym
                         CP   sym_assign                              ; if ( Getsym() == assign )
                         JR   NZ, cond_sw1_end
                              LD   A,'='
                              CALL Infix_operator                          ; *pfixexpr->infixptr++ = '='
                              LD   D, sym_greatequal                       ; relsym = greatequal
                              CALL Getsym                                  ; Getsym()
                              JR   cond_sw1_end
                                                       ; default:     ; { implicit left side only expression }
.cond_sw1_default   JR   end_succes_cond                              ; return 1

.cond_sw1_end       CALL Expression               ; if ( !Expression(pfixexpr) )
                    JR   C, end_cond                   ; return 0
                         LD   E,D                 ; else
                         LD   D,0
                         LD   C,0
                         LD   IX,0                     ; NewPfixSymbol(pfixexpr, 0, relsym, NULL, 0)
                         CALL NewPfixSymbol            ; return 1

.end_succes_cond    CP   A
.end_cond           POP  DE
                    RET



; **************************************************************************************************
;
; IN: BHL = pointer to postfix expression header
;
; OUT: Fc = 1 if syntax error, otherwise Fc = 0
;
; Registers changed after return:
;    ..B.DEHL/..IY  same
;    AF.C..../IX..  different
;
.Expression         PUSH DE
                    LD   A,(sym)
                    CP   sym_plus                 ; if ( sym == plus || sym == minus )
                    JR   Z, expr_init1
                    CP   sym_minus
                    JR   NZ, expr_init2
.expr_init1              CP   sym_minus
                         LD   E,A                      ; addsym = sym
                         JR   NZ, expr_init_cont       ; if ( sym == minus ) *pfixexpr->infixptr++ = separators[sym]
                              LD   A,'-'
                              CALL Infix_operator
.expr_init_cont          CALL Getsym                   ; Getsym()
                         CALL Term                     ; if ( Term(pfixexpr) )
                         JR   C, end_expression
                              LD   A,E
                              CP   sym_minus                ; if ( addsym = minus )
                              JR   NZ, expr_while_loop
                                   LD   D,0
                                   LD   E, sym_negated
                                   LD   C,0
                                   LD   IX,0
                                   CALL NewPfixSymbol            ; NewPfixSymbol(pfixexpr, 0, negated, NULL, 0)
                                   JR   expr_while_loop
                                                       ; else
                                                            ; return 0
                                                  ; else
.expr_init2              CALL Term
                         JR   C, end_expression        ; if ( !Term(pfixexpr) ) return 0

.expr_while_loop    LD   A,(sym)                  ; while ( sym==plus || sym==minus || sym==sym_and ||
                    CP   sym_plus                 ;         sym==sym_or || sym==sym_xor )
                    JR   Z, expr_while
                    CP   sym_minus
                    JR   Z, expr_while
                    CP   sym_and
                    JR   Z, expr_while
                    CP   sym_or
                    JR   Z, expr_while
                    CP   sym_xor
                    JR   NZ, expr_while_exit
.expr_while              LD   E,A                      ; addsym = sym
                         CALL Get_separator            ; A = separators[sym]
                         CALL Infix_operator           ; *pfixexpr->infixptr++ = separators[sym]
                         CALL Getsym                   ; Getsym()
                         CALL Term
                         JR   C, end_expression        ; if ( Term(pfixexpr) )
                              LD   C,0
                              LD   IX,0
                              LD   D,0
                              CALL NewPfixSymbol            ; NewPfixSymbol(pfixexpr, 0, addsym, NULL, 0)
                              JR   expr_while_loop     ; else
                                                            ; return 0

.expr_while_exit    CP   A                        ; return 1
.end_expression     POP  DE
                    RET


; **************************************************************************************************
;
; IN: BHL = pointer to postfix expression header
;
; OUT: Fc = 1 if syntax error, otherwise Fc = 0
;
; Registers changed after return:
;    ..B.DEHL/..IY  same
;    AF.C..../IX..  different
;
.PTerm              PUSH DE
                    CALL Factor
                    JR   C, pterm_end             ; if ( !Factor(pfixexpr) ) return 0

.pterm_while_loop   LD   A,(sym)                  ; while ( sym==power )
                    CP   sym_power
                    JR   NZ, pterm_while_exit
.pterm_while             LD   E,A                      ; powsym = sym
                         CALL Get_separator            ; A = separators[powsym]
                         CALL Infix_operator           ; *pfixexpr->infixptr++ = separators[powsym]
                         CALL Getsym                   ; Getsym()
                         CALL Factor
                         JR   C, pterm_end             ; if ( Factor(pfixexpr) )
                              LD   C,0
                              LD   IX,0
                              LD   D,0
                              CALL NewPfixSymbol            ; NewPfixSymbol(pfixexpr, 0, powsym, NULL, 0)
                              JR   pterm_while_loop    ; else
                                                            ; return 0
.pterm_while_exit   CP   A                        ; return 1
.pterm_end          POP  DE
                    RET



; **************************************************************************************************
;
; IN: BHL = pointer to postfix expression header
;
; OUT: Fc = 1 if syntax error, otherwise Fc = 0
;
; Registers changed after return:
;    ..B.DEHL/..IY  same
;    AF.C..../IX..  different
;
.Term               PUSH DE
                    CALL Pterm
                    JR   C, term_end              ; if ( !Pterm(pfixexpr) ) return 0

.term_while_loop    LD   A,(sym)                  ; while ( sym==multiply || sym==divi || sym==mod )
                    CP   sym_multiply
                    JR   Z, term_while
                    CP   sym_divi
                    JR   Z, term_while
                    CP   sym_mod
                    JR   NZ, term_while_exit
.term_while              LD   E,A                      ; mulsym = sym
                         CALL Get_separator            ; A = separators[sym]
                         CALL Infix_operator           ; *pfixexpr->infixptr++ = separators[sym]
                         CALL Getsym                   ; Getsym()
                         CALL Pterm
                         JR   C, term_end              ; if ( Pterm(pfixexpr) )
                              LD   C,0
                              LD   IX,0
                              LD   D,0
                              CALL NewPfixSymbol            ; NewPfixSymbol(pfixexpr, 0, mulsym, NULL, 0)
                              JR   term_while_loop     ; else
                                                            ; return 0
.term_while_exit    CP   A                        ; return 1
.term_end           POP  DE
                    RET



; **************************************************************************************************
;
; IN: BHL = pfixexpr, pointer to postfix expression header
;
; OUT: Fc = 1 if syntax error, otherwise Fc = 0
;
; Registers changed after return:
;    ..B.DEHL/..IY  same
;    AF.C..../IX..  different
;
.Factor             PUSH DE
                    LD   A,(sym)        ; switch(sym)
                    CP   sym_name            ; case name:
                    JP   NZ, fac_hexconst
                         PUSH BC
                         PUSH HL                  ; {preserve pfixexpr}
                         LD   HL,Ident
                         CALL AllocIdentifier     ; {copy ident to extended memory, BHL = ident}
                         LD   A,B                 ; if ( (identptr = AllocIdentifier(ident)) == NULL )
                         EX   DE,HL                    ; return 0
                         POP  HL                  ; else
                         POP  BC                       ; {pfixexpr = BHL, ident = CDE}
                         LD   C,A
                         JP   C, end_factor
                         CALL Infix_name               ; strcpy(pfixexpr->infixptr, ident)
                                                       ; pfixexpr->infixptr += strlen(ident)
.fac_ident                    PUSH BC
                              PUSH HL                  ; {preserve pfixexpr}
                              CALL GetSymPtr           ; symptr = GetSymPtr(ident)
                              JR   C,sym_not_found     ; if ( symptr != NULL && symptr->type & SYMDEFINED )
                              LD   A, symtree_type
                              CALL Read_byte
                              BIT  SYMDEFINED,A
                              JR   Z, sym_not_found
                                   CALL ReleaseId           ; {release tmp. string at CDE pointer}
                                   PUSH AF                  ; {preserve symptr->type}
                                   LD   A, symtree_symvalue
                                   CALL Read_long           ; symptr->symvalue
                                   POP  AF
                                   POP  HL
                                   POP  BC                  ; {restore pfixexpr}
                                   LD   C,0
                                   LD   IX,0                ; NULL
                                   LD   D, A                ; symptr->type
                                   LD   E,sym_number
                                   CALL NewPfixSymbol       ; NewPfixSymbol(pfixexpr, symptr->symvalue, number, NULL, symptr->type)
                                   LD   A,D
                                   AND  SYMTYPE
                                   LD   D,A
                                   LD   A, expr_rangetype
                                   CALL Read_byte
                                   OR   D
                                   LD   C,A
                                   LD   A, expr_rangetype
                                   CALL Set_byte            ; pfixexpr->rangetype |= symptr->type & SYMTYPE
                                   JR   fac_name_end
                                                       ; else
.sym_not_found                     XOR  A
                                   CP   B                   ; if ( symptr == NULL )
                                   JR   NZ, sym_found
                                        POP  HL
                                        POP  BC                  ; {restore pfixexpr}
                                        PUSH DE
                                        POP  IX                  ; {CIX = ident}
                                        EXX
                                        LD   DE,0
                                        LD   B,D
                                        LD   C,E                 ; const = 0
                                        EXX
                                        LD   D, SYM_NOTDEFINED
                                        LD   E,sym_number
                                        CALL NewPfixSymbol       ; NewPfixSymbol(pfixexpr, 0, number, ident, SYM_NOTDEFINED)
                                        LD   A, expr_rangetype
                                        CALL Read_byte           ; A = pfixexpr->rangetype
                                        OR   NOTEVALUABLE
                                        LD   C,A
                                        LD   A, expr_rangetype
                                        CALL Set_byte            ; pfixexpr->rangetype |= NOTEVALUABLE
                                        JR   fac_name_end
                                                            ; else
.sym_found                              LD   A, symtree_type
                                        CALL Read_byte           ; symptr->type
                                        POP  HL
                                        POP  BC                  ; {restore pfixexpr}
                                        PUSH AF                  ; {preserve symptr->type}
                                        PUSH DE
                                        POP  IX                  ; {CIX = ident}
                                        EXX
                                        LD   DE,0
                                        LD   B,D
                                        LD   C,E                 ; const = 0
                                        EXX
                                        LD   D, A                ; symptr->type
                                        LD   E,sym_number
                                        CALL NewPfixSymbol       ; NewPfixSymbol(pfixexpr, 0, number, ident, symptr->type)
                                        POP  AF                  ; {get symptr->type}
                                        AND  SYMTYPE
                                        OR   NOTEVALUABLE        ; symptr->type & SYMTYPE | NOTEVALUABLE
                                        LD   C,A
                                        LD   A, expr_rangetype
                                        CALL Read_byte           ; A = pfixexpr->rangetype
                                        OR   C
                                        LD   A, expr_rangetype
                                        CALL Set_byte            ; pfixexpr->rangetype |= symptr->type & SYMTYPE | NOTEVALUABLE

.fac_name_end            CALL Getsym              ; Getsym()
                         JP   end_success_factor  ; break

.fac_hexconst       CP   sym_hexconst        ; case hexconst:
                    JR   Z, fac_const
                    CP   sym_binconst        ; case binconst:
                    JR   Z, fac_const
                    CP   sym_decmconst       ; case decmconst:
                    JR   NZ, fac_lparen
.fac_const               PUSH BC
                         PUSH HL                  ; {preserve pfixexpr}
                         LD   HL,Ident
                         CALL AllocIdentifier     ; {copy ident to extended memory, BHL = ident}
                         LD   A,B                 ; if ( (identptr = AllocIdentifier(ident)) != NULL )
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         LD   C,A                 ; strcpy(pfixexpr->infixptr, CDE)
                         JP   C, end_factor
                         CALL Infix_name          ; pfixexpr->infixptr += strlen(ident)
                         CALL ReleaseID           ; {release redundant id}
                         PUSH BC
                         PUSH HL
                         CALL GetConstant         ; const = GetConstant(&eval_err) {in debc}
                         POP  HL
                         POP  BC
                         JP   C, fac_default      ; if ( eval_err  )
                              LD   C,0                 ; reporterror(5)
                              LD   IX,0                ; return 0
                              LD   D,0            ; else
                              LD   E,sym_number
                              CALL NewPfixSymbol       ; NewPfixSymbl(pfixexpr, const, number, NULL, 0)
                         CALL Getsym              ; Getsym()
                         JP   end_success_factor

.fac_lparen         CP   sym_lparen          ; case lparen:
                    JR   NZ, fac_lognot
                         LD   A,'('
                         CALL Infix_operator      ; *pfixexpr->infixptr++ = '('
                         CALL Getsym              ; Getsym()
                         CALL Condition           ; if ( !Condition(pfixexpr) )
                         JP   C, end_factor            ; return 0
                              LD   A,(sym)        ; else
                              CP   sym_rparen          ; if ( sym == rparen )
                              JR   NZ, rparen_missing
                                   CALL Get_separator
                                   CALL Infix_operator      ; *pfixexpr->infixptr++ = ')'
                                   CALL Getsym              ; Getsym()
                                   JR   end_success_factor  ; break

.rparen_missing               LD   A,ERR_rightbracket
                              CALL ReportError_STD
                              SCF
                              JR   end_factor

.fac_lognot         CP   sym_not             ; case lognot:
                    JR   NZ, fac_squote
                         LD   A,'!'
                         CALL Infix_operator      ; *pfixexpr->infixptr++ = '!'
                         CALL Getsym              ; Getsym()
                         CALL Factor              ; if (!Factor(pfixexpr))
                         JR   C, end_factor            ; return 0
                              LD   C,0            ; else
                              LD   IX,0
                              LD   D,0
                              LD   E, sym_not
                              CALL NewPfixSymbol        ; NewPfixSymbol(pfixexpr, 0, sym_not, NULL, 0)
                         JR   end_success_factor  ; break

.fac_squote         CP   sym_squote          ; case squote:
                    JR   NZ, fac_default
                         LD   A,'''
                         CALL Infix_operator      ; *pfixexpr->infixptr++ = '\''
                         PUSH HL                  ; {preserve pfixexpr}
                         LD   HL,(lineptr)
                         LD   A,(HL)              ;
                         INC  HL
                         LD   (lineptr),HL        ; ++lineptr
                         POP  HL
                         EXX
                         LD   DE,0
                         LD   B,0
                         LD   C,A                 ; const = *lineptr
                         EXX
                         CALL Infix_operator      ; *pfixexpr->infixptr++ = const
                         CALL Getsym
                         CP   sym_squote          ; if ( Getsym() != squote )
                         JR   NZ, fac_default          ; reporterror(5); return 0
                              CALL Get_separator  ; else
                              CALL Infix_operator      ; *pfixexpr->infixptr++ = '\''
                              LD   C,0
                              LD   IX,0
                              LD   D,0
                              LD   E,sym_number
                              CALL NewPfixSymbol       ; NewPfixSymbol(pfixexpr, const, number, NULL, 0)
                              CALL Getsym              ; Getsym
                              JR   end_success_factor  ; break

.fac_default        LD   A,ERR_expr_syntax   ; default:
                    CALL ReportError_STD          ; reporterror(5)
                    SCF                           ; return 0
                    JR   end_factor

.end_success_factor CP   A              ; return 1
.end_factor         POP  DE
                    RET



; **************************************************************************************************
;
;
; IN:     BHL  = *pfixexpr, pointer to postfix expression header
;         debc = oprconst, long integer constant of operand
;         E    = oprtype, type of operand
;         D    = symtype, type of symbol
;         CIX  = *symident, pointer to symbol identifier
;
; OUT: None.
;
; Registers changed after return:
;    ..B.DEHL/IXIY  same
;    AF.C..../....  different
;
.NewPfixSymbol      PUSH DE                       ; {preserve original DE}
                    PUSH BC
                    PUSH HL                       ; {preserve pfixexpr pointer}
                    EXX
                    PUSH BC
                    PUSH DE                       ; {preserve oprconst}
                    EXX
                    CALL AllocPfixSymbol
                    JR   C, newpfix_room_err      ; if ( (newnode = AllocPfixSymbol()) != NULL )
                         PUSH BC
                         LD   C,E
                         LD   A,pfixlist_oprtype
                         CALL Set_byte                 ; newnode->operatortype = oprtype
                         POP  BC
                         EXX
                         POP  DE
                         POP  BC                       ; {restore constant}s
                         EXX
                         LD   A,pfixlist_oprconst
                         CALL Set_long                 ; newnode->operandconst = oprconst
                         PUSH BC
                         LD   C,D
                         LD   A,pfixlist_symtype
                         CALL Set_byte                 ; newnode->type = symtype
                         POP  BC
                         PUSH IX
                         POP  DE
                         LD   A, pfixlist_ident
                         CALL Set_pointer              ; newnode->id = symident
                         LD   C,0
                         LD   D,C
                         LD   E,C
                         LD   A, pfixlist_nextopr      ; {CDE = NULL}
                         CALL Set_pointer              ; newnode->nextoperand = NULL
                         JR   newpfix_addlist
                                                  ; else
.newpfix_room_err        POP  DE
                         POP  DE                       ; {remove oprconst from stack}
                         POP  HL
                         POP  BC                       ; {restore pfixexpr pointer}
                         LD   A, ERR_no_room
                         CALL ReportError_STD          ; reporterror(3)
                         POP  DE
                         RET                           ; return

.newpfix_addlist    LD   A,B
                    EX   DE,HL
                    POP  HL
                    POP  BC
                    LD   C,A                      ; {BHL = pfixexpr, CDE = newnode}
                    PUSH BC
                    PUSH HL
                    LD   A, expr_pfixlist_first
                    CALL Read_pointer
                    XOR  A
                    CP   B                        ; if ( pfixexpr->firstnode != NULL )
                    POP  HL
                    POP  BC
                    JR   NZ, newpfix_add
                         LD   A, expr_pfixlist_first
                         CALL Set_pointer              ; pfixexpr->firstnode = newnode
                         LD   A, expr_pfixlist_curr
                         CALL Set_pointer              ; pfixexpr->currentnode = newnode
                         JR   end_newpfix         ; else
.newpfix_add             PUSH BC
                         PUSH HL                       ; {preserve pfixexpr}
                         LD   A, expr_pfixlist_curr
                         CALL Read_pointer             ; pfixexpr->currentnode
                         LD   A, pfixlist_nextopr
                         CALL Set_pointer              ; pfixexpr->currentnode->nextoperand = newnode
                         POP  HL
                         POP  BC
                         LD   A, expr_pfixlist_curr
                         CALL Set_pointer              ; pfixexpr->currentnode = newnode

.end_newpfix        POP  DE
                    RET



; **************************************************************************************************
;
; Get separator defined from symbol
;
; IN:     A = symbol identifier
; OUT:    A = ASCII symbol
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.Get_separator      PUSH HL
                    PUSH BC
                    LD   HL, separators+1
                    LD   B,0
                    LD   C,A
                    ADD  HL,BC
                    LD   A,(HL)
                    POP  BC
                    POP  HL
                    RET



; **************************************************************************************************
;
; Add operator to infix expression
;
; IN:     A   = ASCII operator ('+', '-', '*', '/', '%', '^', '|', '~')
;         BHL = pfixexpr, pointer to header of postfix expression
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.Infix_operator     PUSH DE
                    PUSH BC
                    PUSH BC
                    PUSH HL                       ; {preserve pfixexpr ptr.}
                    LD   C,A
                    LD   A, expr_infixptr
                    CALL Read_pointer             ; pfixexpr->infixptr
                    XOR  A
                    CALL Set_byte                 ; *pfixexpr->infixptr = operator
                    LD   A,B
                    INC  HL                       ; infixptr++
                    EX   DE,HL
                    POP  HL
                    POP  BC
                    LD   C,A
                    LD   A, expr_infixptr         ; {infixptr stored}
                    CALL Set_pointer
                    POP  BC
                    POP  DE
                    RET



; **************************************************************************************************
;
; Add name to infix expression
;
; IN:     BHL = pfixexpr, pointer to header of postfix expression
;         CDE = pointer to ident (length prefixed)
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.Infix_name         PUSH BC
                    PUSH DE

                    PUSH BC
                    PUSH HL                       ; preserve pfixexpr ptr.
                    LD   A, expr_infixptr
                    CALL Read_pointer             ; pfixexpr->infixptr
                    LD   A,C
                    LD   C,B
                    LD   B,A                      ; CDE = pfixexpr->infixptr
                    EX   DE,HL
                    XOR  A
                    CALL Read_byte                ; length of identptr string in A
                    INC  HL                       ; BHL = ++identptr
                    CALL memcpy                   ; memcpy(pfixexpr->infixptr, identptr, length)
                    PUSH BC
                    LD   B,0
                    LD   C,A                      ; length of name
                    EX   DE,HL
                    ADD  HL,BC
                    EX   DE,HL                    ; CDE = infixptr + strlen(identptr)
                    POP  BC
                    LD   A,C
                    POP  HL
                    POP  BC                       ; BHL = pfixexpr,
                    LD   C,A                      ; CDE = updated infixptr
                    LD   A, expr_infixptr
                    CALL Set_pointer              ; infixptr stored

                    POP  DE                       ;
                    POP  BC                       ; pfixexpr-ptr restored, ident-ptr restored
                    RET



; **************************************************************************************************
;
; Remove postfix expression list
;
; IN: BHL = pointer to header of postfix expression list
;
; OUT: None.
;
; Registers changed after return:
;    AF.CDE../IXIY  same
;    ..B...HL/....  different
;
.RemovePfixList     PUSH AF
                    XOR  A
                    CP   B
                    JR   NZ, remove_expression    ; if ( pfixexpr == NULL ) return
                         POP  AF
                         RET
.remove_expression  PUSH BC
                    PUSH DE
                    PUSH BC
                    PUSH HL                       ; {preserve pfixexpr}

                    LD   A,expr_pfixlist_first
                    CALL Read_pointer             ; node = pfixexpr->firstnode

.remv_nodes_loop    XOR  A
                    CP   B
                    JR   Z, end_remv_pfixlist     ; while ( node != NULL )
                         PUSH BC
                         PUSH HL                       ; {preserve node}
                         LD   A, pfixlist_nextopr      ; tmpnode = node->nextoperand
                         CALL Read_pointer
                         EX   DE,HL
                         POP  HL
                         LD   A,B
                         POP  BC
                         LD   C,A                      ; {BHL = node, CDE = tmpnode}
                         PUSH BC
                         PUSH HL
                         LD   A,pfixlist_ident
                         CALL Read_pointer             ; {BHL = node->id}
                         XOR  A
                         CP   B
                         CALL NZ, mfree                ; if ( node->id != NULL) free(node->id)
                         POP  HL
                         POP  BC
                         CALL mfree                    ; free(node)
                         EX   DE,HL
                         LD   B,C                      ; node = tmpnode
                         JR   remv_nodes_loop

.end_remv_pfixlist  POP  HL
                    POP  BC                       ; {restore pfixexpr}
                    PUSH BC
                    PUSH HL
                    LD   A, expr_infixexpr
                    CALL Read_pointer
                    XOR  A
                    CP   B
                    CALL NZ, mfree                ; if ( pfixexpr->infixexpr != NULL ) free(pfixexpr->infixexpr)
                    POP  HL
                    POP  BC
                    CALL mfree                    ; free(pfixexpr)
                    POP  DE
                    POP  BC
                    POP  AF
                    RET



; ****************************************************************************************
;
; Allocate memory for new node of postfix expression list
;
.AllocPfixSymbol    LD   A,SIZEOF_pfixlist
                    CALL malloc
                    RET



; ****************************************************************************************
;
; Allocate memory for header of postfix expression
;
.AllocExpr          LD   A,SIZEOF_expr
                    CALL malloc
                    RET


; ****************************************************************************************
;
; Allocate memory for new node of postfix expression evaluation stack
;
.AllocInfixExpr     LD   A, SIZEOF_infixexpr
                    CALL malloc
                    RET

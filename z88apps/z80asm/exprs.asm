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

     MODULE Expressions

; external procedures:
     LIB Read_byte, Set_byte, Read_word, Read_pointer, Bind_bank_s1

     XREF ParseNumExpr, RemovePfixList                                ; parsexpr.asm
     XREF EvalPfixExpr                                                ; evalexpr.asm
     XREF WriteLong, WriteWord, WriteByte                             ; bytesio.asm
     XREF Write_string                                                ; fileio.asm
     XREF Pass2Info                                                   ; z80pass1.asm
     XREF ReportError_STD                                             ; errors.asm
     XREF Test_7bit_range, Test_8bit_range
     XREF Test_16bit_range, Test_32bit_range

; global procedures:
     XDEF StoreExpr
     XDEF ExprLong, ExprAddress
     XDEF ExprSigned8, ExprUnsigned8
     XDEF Add16bit_1, Add16bit_2, Add16bit_3, Add16bit_4

     INCLUDE "fileio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
; Evaluate expression to a 32bit signed long constant
; (control of object file output included in logic)
;
; OUT:    Fc = 0, success, Fc = 1, failure
;
.ExprLong           CALL ParseNumExpr                       ; postfixexpr = ParseNumExpr()
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         LD   C,A
                         AND  EXPREXTERN                         ; if ( postfixexpr->rangetype & EXPREXTERN ||
                         JR   NZ, exprlong_storexpr                   ; postfixexpr->rangetype & EXPRADDR     )
                         LD   A,C
                         AND  EXPRADDR
                         JR   Z, exprlong_evalexpr
.exprlong_storexpr            LD   A,'L'                              ; range is signed long
                              CALL StoreExpr                          ; StoreExpr(postfixexpr, 'L')
                              CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                              JR   end_exprlong                  ; else
.exprlong_evalexpr            LD   A,C
                              AND  NOTEVALUABLE
                              JR   Z, exprlong_evalexpr2              ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                                   LD   C,RANGE_32SIGN
                                   CALL Pass2Info                          ; Pass2Info( postfixexpr, RANGE_32SIGN)
                                   JR   end_exprlong                  ; else
.exprlong_evalexpr2                PUSH HL
                                   PUSH BC
                                   CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                                   CALL Test_32bit_range                   ; if ( const>=LONG_MIN && const<=LONG_MAX )
                                   JR   C, exprlong_range_error
                                        EXX
                                        PUSH HL
                                        EXX
                                        POP  BC
                                        EX   DE,HL
                                        CALL WriteLong                          ; {write long integer}
                                        JR   exprlong_remvexpr
                                                                           ; else
.exprlong_range_error                   LD   A, ERR_int_range
                                        CALL ReportError_STD                    ; Reporterror(4)
.exprlong_remvexpr                 POP  BC
                                   POP  HL
                                   CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                                   CP   A
                                   RET
.end_exprlong       XOR  A
                    LD   B,A
                    LD   C,A
                    LD   D,A
                    LD   E,A
                    JP   WriteLong                          ; codeptr += 4


; **************************************************************************************************
;
; Evaluate expression to 16bit constant
; (control of object file output included in logic)
;
; OUT:    Fc = 0, success, Fc = 1, failure
;
.ExprAddress        CALL ParseNumExpr                       ; postfixexpr = ParseNumExpr()
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
.expraddr_evaluable      LD   A,expr_rangetype
                         CALL Read_byte
                         LD   C,A
                         AND  EXPREXTERN                         ; if ( postfixexpr->rangetype & EXPREXTERN ||
                         JR   NZ, expraddr_storexpr                   ; postfixexpr->rangetype & EXPRADDR     )
                         LD   A,C
                         AND  EXPRADDR
                         JR   Z, expraddr_evalexpr
.expraddr_storexpr            LD   A,'C'                              ; range is 16bit word
                              CALL StoreExpr                          ; StoreExpr(postfixexpr, 'C')
                              CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                              JR   end_expraddr                  ; else
.expraddr_evalexpr            LD   A,C
                              AND  NOTEVALUABLE
                              JR   Z, expraddr_evalexpr2              ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                                   LD   C,RANGE_16CONST
                                   CALL Pass2Info                          ; Pass2Info( postfixexpr, RANGE_32SIGN)
                                   JR   end_expraddr                  ; else
.expraddr_evalexpr2                PUSH HL
                                   PUSH BC
                                   CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                                   CALL Test_16bit_range                   ; if ( const>=-32768 && const<=65535 )
                                   JR   C, expraddr_range_error
                                        EXX
                                        PUSH HL
                                        EXX
                                        POP  BC
                                        CALL WriteWord                          ; {write word}
                                        JR   expraddr_remvexpr
                                                                           ; else
.expraddr_range_error                   LD   A, ERR_int_range
                                        CALL ReportError_STD                    ; Reporterror(4)
.expraddr_remvexpr                 POP  BC
                                   POP  HL
                                   CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                                   CP   A
                                   RET
.end_expraddr       XOR  A                                  ; Fc = 0, A = 0
                    LD   B,A
                    LD   C,A
                    JP   WriteWord                          ; codeptr += 2


; **************************************************************************************************
;
; Evaluate expression to an 8bit unsigned constant
; (control of object file output included in logic)
;
; OUT:    Fc = 0, success, Fc = 1, failure
;
.ExprUnsigned8      CALL ParseNumExpr                       ; postfixexpr = ParseNumExpr()
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
.exprusgn_evaluable      LD   A,expr_rangetype
                         CALL Read_byte
                         LD   C,A
                         AND  EXPREXTERN                         ; if ( postfixexpr->rangetype & EXPREXTERN ||
                         JR   NZ, exprusgn_storexpr                   ; postfixexpr->rangetype & EXPRADDR     )
                         LD   A,C
                         AND  EXPRADDR
                         JR   Z, exprusgn_evalexpr
.exprusgn_storexpr            LD   A,'U'                              ; range is 8bit unsigned
                              CALL StoreExpr                          ; StoreExpr(postfixexpr, 'C')
                              CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                              JR   end_exprusgn                  ; else
.exprusgn_evalexpr            LD   A,C
                              AND  NOTEVALUABLE
                              JR   Z, exprusgn_evalexpr2              ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                                   LD   C,RANGE_8UNSIGN
                                   CALL Pass2Info                          ; Pass2Info( postfixexpr, RANGE_32SIGN)
                                   JR   end_exprusgn                  ; else
.exprusgn_evalexpr2                PUSH HL
                                   PUSH BC
                                   CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                                   CALL Test_8bit_range                    ; if ( const>=-128 && const<=255 )
                                   JR   C, exprusgn_range_error
                                        EXX
                                        PUSH HL
                                        EXX
                                        POP  BC
                                        CALL WriteByte                          ; {write byte}
                                        JR   exprusgn_remvexpr
                                                                           ; else
.exprusgn_range_error                   LD   A, ERR_int_range
                                        CALL ReportError_STD                    ; Reporterror(4)
.exprusgn_remvexpr                 POP  BC
                                   POP  HL
                                   CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                                   CP   A
                                   RET
.end_exprusgn       XOR  A                                  ; Fc = 0, A = 0
                    LD   C,A
                    JP   WriteByte                          ; codeptr++


; **************************************************************************************************
;
; Evaluate expression to an 8bit signed constant
; (control of object file output included in logic)
;
; OUT:    Fc = 0, success, Fc = 1, failure
;
.ExprSigned8        CALL ParseNumExpr                       ; postfixexpr = ParseNumExpr()
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
.exprsign_evaluable      LD   A,expr_rangetype
                         CALL Read_byte
                         LD   C,A
                         AND  EXPREXTERN                         ; if ( postfixexpr->rangetype & EXPREXTERN ||
                         JR   NZ, exprsign_storexpr                   ; postfixexpr->rangetype & EXPRADDR     )
                         LD   A,C
                         AND  EXPRADDR
                         JR   Z, exprsign_evalexpr
.exprsign_storexpr            LD   A,'S'                              ; range is 8bit signed
                              CALL StoreExpr                          ; StoreExpr(postfixexpr, 'S')
                              CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                              JR   end_exprsign                  ; else
.exprsign_evalexpr            LD   A,C
                              AND  NOTEVALUABLE
                              JR   Z, exprsign_evalexpr2              ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                                   LD   C,RANGE_8SIGN
                                   CALL Pass2Info                          ; Pass2Info( postfixexpr, RANGE_32SIGN)
                                   JR   end_exprsign                  ; else
.exprsign_evalexpr2                PUSH HL
                                   PUSH BC
                                   CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                                   CALL Test_7bit_range                    ; if ( const>=-128 && const<=127 )
                                   JR   C, exprsign_range_error
                                        EXX
                                        PUSH HL
                                        EXX
                                        POP  BC
                                        CALL WriteByte                          ; {write byte}
                                        JR   exprsign_remvexpr
                                                                           ; else
.exprsign_range_error                   LD   A, ERR_int_range
                                        CALL ReportError_STD                    ; Reporterror(4)
.exprsign_remvexpr                 POP  BC
                                   POP  HL
                                   CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                                   CP   A
                                   RET
.end_exprsign       XOR  A                                  ; Fc = 0, A = 0
                    LD   C,A
                    JP   WriteByte                          ; codeptr++


; **************************************************************************************************
;
; Store infix expression to object file
;
; IN:     A   = range
;         BHL = pfixexpr pointer
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.StoreExpr          PUSH IX
                    PUSH DE
                         LD   IX,(objfilehandle)            ; {get handle for object file}
                         CALL_OZ(Os_Pb)                     ; fputc(range, objfile)
                         LD   A, expr_codepos
                         CALL Read_word                     ; pfixexpr->codepos
                         LD   A,E                           ;
                         CALL_OZ(Os_Pb)                     ; fputc(codepos%256, objfile)
                         LD   A,D
                         CALL_OZ(Os_Pb)                     ; fputc(codepos%256, objfile)

                         PUSH HL
                         PUSH BC
                         LD   C,-1
                         LD   A, expr_stored
                         CALL Set_byte                      ; pfixexpr->stored = ON
                         LD   A,expr_infixexpr
                         CALL Read_pointer                  ; pfixexpr->infixexpr
                         LD   A,B
                         CALL Bind_bank_s1                  ; make sure that expression is paged in
                         PUSH AF                            ; preserve old bank binding
                         PUSH HL
                         XOR  A
                         LD   C,SIZEOF_infixexpr            ; search max. characters for null-terminator
                         PUSH HL
                         CPIR                               ; {find null-terminator}
                         POP  DE
                         SBC  HL,DE
                         LD   A,L
                         LD   C,L                           ; b = strlen(pfixexpr->infixexpr) + 1
                         DEC  A
                         CALL_OZ(Os_Pb)                     ; fputc( strlen(pfixexpr->infixexpr), objfile)
                         LD   DE,0
                         POP  HL
                         POP  AF
                         CALL Bind_bank_s1                  ; {pfixexpr->infixexpr in BHL}
                         CALL Write_string                  ; fwrite(pfixexpr->infixexpr, 1, b, objfile)
                         POP  BC
                         POP  HL
                    POP  DE
                    POP  IX
                    RET


; ========================================================================================
;
; 16bit add+1
;
; IN: HL local pointer to word
;
; Registers changed after return:
;
;    A.BCDE../IXIY  same
;    .F....HL/....  different
;
.Add16bit_1         INC  (HL)
                    RET  NZ
                    INC  HL
                    INC  (HL)
                    DEC  HL
                    RET


; ========================================================================================
;
; 16bit add+2
;
; Registers changed after return:
;
;    AFBCDE../IXIY  same
;    ......HL/....  different
;
.Add16bit_2         CALL Add16bit_1
                    JP   Add16bit_1

; ========================================================================================
;
; 16bit add+3
;
; Registers changed after return:
;
;    AFBCDE../IXIY  same
;    ......HL/....  different
;
.Add16bit_3         CALL Add16bit_2
                    JP   Add16bit_1

; ========================================================================================
;
; 16bit add+4
;
; Registers changed after return:
;
;    AFBCDE../IXIY  same
;    ......HL/....  different
;
.Add16bit_4         CALL Add16bit_2
                    JP   Add16bit_2

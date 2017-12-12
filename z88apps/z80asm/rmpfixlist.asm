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

 MODULE RemovePfixList

LIB mfree, Read_pointer

INCLUDE "rtmvars.def"
INCLUDE "symbol.def"

XDEF RemovePfixList

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

.remv_nodes_loop    INC  B
                    DEC  B
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
                         INC  B
                         DEC  B
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
                    INC  B
                    DEC  B
                    CALL NZ, mfree                ; if ( pfixexpr->infixexpr != NULL ) free(pfixexpr->infixexpr)
                    POP  HL
                    POP  BC
                    CALL mfree                    ; free(pfixexpr)
                    POP  DE
                    POP  BC
                    POP  AF
                    RET

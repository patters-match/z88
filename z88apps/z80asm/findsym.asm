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

Module FindSymbols

LIB Read_byte, Set_byte, Read_pointer, GetVarPointer
LIB Find, StrCmp

INCLUDE "rtmvars.def"
INCLUDE "symbol.def"

XREF CurrentModule                                          ; currmodule.asm

XDEF GetSymPtr, FindSymbol, NULL_pointer


; **************************************************************************************************
;
; GetSymPtr - get pointer to found symbol in avltree.
;
;    IN:  CDE = pointer to identifier
;   OUT:  BHL = pointer to found symbol, otherwise NULL.
;
; Registers changed after return:
;
;    ...CDE../....  same
;    AFB...HL/IXIY  different
;
.GetSymPtr          CALL CurrentModule       ; pointer to current module in BHL...
                    LD   A, module_localroot
                    CALL Read_pointer        ; get pointer to root of local symbols in BHL
                    CALL FindSymbol
                    RET  NC                  ; if ( Findsymbol(id, CURRENTMODULE->localroot) == NULL )
.find_globalsym          LD   HL, globalroot
                         CALL GetVarPointer       ; if ( Findsymbol(id, globalroot != NULL )
                         CALL FindSymbol               ; return symptr;
                         RET  NC                  ; else
                              JR   NULL_pointer        ; return NULL (Fc = 1)


; **************************************************************************************************
;
; FindSymbol - get pointer to found symbol in either local or global avltree.
;
;    IN:  BHL = pointer to current search node
;         CDE = pointer to identifier
;   OUT:  BHL = pointer to found symbol node , Fc = 0
;               otherwise NULL, Fc = 1,
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.FindSymbol         INC  B
                    DEC  B                   ; if ( avlptr == NULL )
                    JR   NZ, examine_node
                         SCF                      ; Fz = 1, Fc = 1, return NULL;
                         RET
                                             ; else
.examine_node       PUSH IY
                    LD   IY, compidentifier
                    CALL Find                     ; found = find(avlptr, identifier, compidentifier)
                    POP  IY
                    JR   NC, found_node           ; if ( found == NULL )
                    RET                                ; return NULL
                                                  ; else
.found_node         PUSH BC
                    LD   A, symtree_type               ; symptr->type |= SYMTOUCHED
                    CALL Read_byte
                    SET  SYMTOUCHED,A
                    LD   C,A
                    LD   A, symtree_type
                    CALL Set_byte
                    POP  BC                            ; return symptr (Fc = 0)
                    RET


; **************************************************************************************************
;
; return NULL pointer in BHL, Fc = 1
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.NULL_pointer       XOR  A
                    LD   B,A
                    LD   H,A
                    LD   L,A
                    SCF
                    RET


; **************************************************************************************************
;
;    Compare service routine for .FindSymbol
;
;    IN: CDE = search key (main caller parameter)
;        BHL = pointer to current AVL node
;
;    OUT:
;         Fz = 0; Fc = 0:     A > B
;         Fz = 1; Fc = 0:     A = B
;         Fz = 0; Fc = 1:     A < B
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.compidentifier     LD   A, symtree_symname
                    CALL Read_pointer        ;      get pointer to symbol identfier (string)
                    JP   Strcmp              ;      retur strcmp(symptr->symname, identifier)


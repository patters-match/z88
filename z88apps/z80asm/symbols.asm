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

     MODULE Symbol_processing

; external procedures:
     LIB malloc, mfree
     LIB AllocIdentifier
     LIB Compare, CmpPtr, StrCmp
     LIB Read_pointer, Set_pointer
     LIB Read_byte, Set_byte, Insert
     LIB Read_long, Set_long
     LIB Bind_bank_s1
     LIB Find
     LIB copy, memcpy, strcpy

     XREF CurrentModule                                          ; z80asm.asm
     XREF ReportError_STD, ReportError_NULL                      ; errors.asm
     XREF GetVarPointer                                          ; z80asm.asm
     XREF GetPointer                                             ; varptr.asm

; global procedures in this module:
     XDEF NULL_pointer, CmpIDstr, CmpIDval
     XDEF DefineSymbol, DefineDefSym, InsertSym
     XDEF GetSymPtr, FindSymbol
     XDEF FreeSym
     XDEF DeclSymExtern, DeclSymGlobal
     XDEF CopyId, ReleaseId
     XDEF CopyStaticLocal


     INCLUDE "stdio.def"
     INCLUDE "fpp.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


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
                    JR   NC, found_sym       ; if ( Findsymbol(id, CURRENTMODULE->localroot) == NULL )
.find_globalsym          LD   HL, globalroot
                         CALL GetVarPointer
                         CALL FindSymbol
                         JR   NC, found_sym       ; if ( Findsymbol(id, globalroot == NULL )
                              CALL NULL_pointer        ; return NULL
                              SCF
                              RET                 ; else
.found_sym          CP   A                             ; return symptr;
                    RET



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
.FindSymbol         XOR  A
                    CP   B                   ; if ( avlptr == NULL )
                    JR   NZ, examine_node
                         SCF                      ; return NULL;
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
                    POP  BC
                    CP   A                             ; return symptr
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
                    CALL Strcmp              ;      retur strcmp(symptr->symname, identifier)
                    RET



; **************************************************************************************************
;
; Compare symbol string of new node (to be inserted) with string of current node in AVL-tree
;
;    IN:  BHL = pointer to current node in AVL-tree
;         CDE = pointer to search key node
;
;   OUT:
;         Fz = 1; Fc = 0:     A = B
;         Fz = 0; Fc = 1:     A > B
;         Fz = 0; Fc = 0:     A < B
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
;
.CmpIDstr           PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   A, symtree_symname
                    CALL Read_pointer        ; get ptr. to symbol-id. of current node
                    PUSH BC                  ; in BHL
                    PUSH HL
                    LD   B,C
                    EX   DE,HL               ; pointer to search key
                    LD   A, symtree_symname
                    CALL Read_pointer        ; get ptr. to symbol-id. of search key
                    EX   DE,HL               ; in CDE
                    LD   A,B
                    POP  HL
                    POP  BC
                    LD   C,A
                    CALL StrCmp              ; compare strings
                    POP  HL                  ; (and return flags accordingly...)
                    POP  DE
                    POP  BC
                    RET



; **************************************************************************************************
;
; Compare symbol integer of new node (to be inserted) with integer of current node in AVL-tree
;
;    IN:  BHL = pointer to current node in AVL-tree
;         CDE = pointer to search key node
;
;   OUT:
;         Fz = 1; Fc = 0:     A = B
;         Fz = 0; Fc = 1:     A > B
;         Fz = 0; Fc = 0:     A < B
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY ........   same
;    AF....../.... afbcdehl   different
;
.CmpIDval           PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   A, symtree_symvalue
                    CALL Read_long           ; read long integer at current node (BHL)
                    EXX
                    PUSH BC
                    PUSH DE
                    EXX
                    LD   B,C
                    EX   DE,HL               ; pointer to new node
                    LD   A, symtree_symvalue
                    CALL Read_long           ; read long integer at new node
                    POP  HL                  ; high word of HLhl installed
                    EXX
                    POP  HL                  ; low word of HLhl installed
                    PUSH DE                  ; high word of DEde
                    LD   D,B
                    LD   E,C                 ; low word of DEde
                    EXX
                    POP  DE                  ; low word of DEde installed
                    LD   BC,0                ; indicate long integer
                    FPP  (Fp_Cmp)            ; compare long integers
                    CP   0                   ; Fc = 1, if HLhl < DEde, else Fc = 0, if HLhl > DEde
                    RLA                      ; Fz = 1, if HLhl = DEde
.exit_cmpidval      POP  BC                  ;
                    POP  DE
                    POP  HL
                    RET



; **********************************************************************************************************
;
;    Define a DEFINE symbol constant.
;
;    IN:  BHL  = pointer to pointer to root of symbol tree
;         CDE  = pointer to symbol identifier
;         A    = symbol type
;         bcde = long integer of symbol value
;
;    OUT: Fc = 0, symbol successfully created.
;         Fc = 1, symbol not created.
;
; Registers changed after return:
;    ......../..IY  same
;    AFBCDEHL/IX..  different
;
.DefineDefSym       PUSH AF
                    PUSH BC
                    PUSH HL                  ; preserve root
                    XOR  A
                    CALL Read_pointer        ; *root
                    CALL FindSymbol
                    JR   NC, found_defsym    ; if ( FindSymbol(identifier, *root) != NULL)
                         EXX
                         EX   AF,AF'
                         LD   A,0                 ; ahl = owner of symbol, None.
                         EX   AF,AF'
                         LD   HL,0
                         EXX
                         LD   IX, cmpIDstr        ; pointer to compare routine
                         POP  HL
                         POP  BC                  ; root
                         POP  AF                  ; symboltype
                         SET  SYMDEF,A
                         SET  SYMDEFINED,A        ; symboltype |= SYMDEF | SYMDEFINED
                         CALL InsertSym           ; InsertSym(identifier, value, symboltype, root, modowner, symcmp)
                         RET

.found_defsym       POP  HL                  ; else
                    POP  BC
                    POP  AF
                    LD   A, ERR_sym_defined       ; Symbol already defined
                    CALL ReportError_STD          ; ReportError(CURRENTFILE->fname, CURRENTFILE->line, 14);
                    SCF
                    RET




; ******************************************************************************
;
;    Define symbol
;    IN:
;         HL   = local pointer to identifier string
;         DEBC = long integer value of identifier
;         A    = symboltype
;
;    OUT: Fc = 1, if no room for symbol, otherwise Fc = 0
;
; Registers changed after return:
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.DefineSymbol       PUSH BC
                    PUSH DE                       ; preserve symbol value in DEBC
                    PUSH AF
.defsym_continue    CALL AllocIdentifier
                    JP   C, exit_defsym           ; Ups - no room for string...
                    EXX                           ; pointer in BHL
                    POP  BC                       ; preserve symboltype
                    EXX
                    LD   C,B
                    EX   DE,HL                    ; pointer to identifier in CDE
                    LD   HL,globalroot
                    CALL GetVarPointer            ; get pointer to globalroot in BHL
                    CALL FindSymbol               ; if foundsym = Findsymbol( id, globalroot ) == NULL
                    JR   C, create_locsym         ;    return DefLocalSymbol( id, value, symboltype)
                                                  ; else
                         LD   A, symtree_type     ;    if foundsym->type = SYMXDEF
                         CALL Read_byte
                         BIT  SYMXDEF,A
                         JR   Z, create_locsym
                              BIT  SYMDEFINED,A   ;         if SYMDEFINED = 0
                              JR   NZ, glbsym_defined
                                   EXX
                                   OR   B         ;              foundsym->type |= symboltype
                                   EXX
                                   SET SYMDEFINED,A
                                   PUSH BC        ;              (preserve bank of 'id' pointer in CDE)
                                   LD   C,A
                                   LD   A, symtree_type
                                   CALL Set_byte  ;              foundsym->type |= SYMDEFINED
                                   POP  BC
                                   EXX
                                   POP  DE
                                   POP  BC        ;              (get symbol value)
                                   EXX
                                   LD   A, symtree_symvalue
                                   CALL Set_long  ;              foundsym->symvalue = value
                                   PUSH DE        ;              (preserve 'id' pointer in CDE)
                                   PUSH BC
                                   PUSH HL        ;              (preserve foundsym)
                                   CALL CurrentModule ;          (ptr. to current module in BHL)
                                   EX   DE,HL
                                   POP  HL
                                   LD   A,B
                                   POP  BC
                                   PUSH BC
                                   LD   C,A       ;              (CDE = CURRENTMODULE)
                                   LD   A, symtree_modowner
                                   CALL Set_pointer ;            foundsym->owner = CURRENTMODULE
                                   POP  BC
                                   POP  DE
                                   CALL ReleaseID                ; {remove redundant search id}
                                   CP   A         ;              ; return 1   (signal succes)
                                   RET

.create_locsym      ; setup parameter block on stack...
                    EXX
                    LD   H,B                 ; symboltype
                    POP  DE
                    POP  BC                  ; get long integer
                    EXX
                    CALL DefLocalSymbol      ; create local symbol
                    RET

.glbsym_defined     LD   A, ERR_sym_defined
                    CALL ReportError_STD     ; report to error file...
                    SCF                      ; signal error...
                    CALL ReleaseId
                    POP  DE                  ; remove redundant value...
                    POP  BC
                    RET

.exit_defsym        LD   A, ERR_no_room
                    CALL ReportError_NULL
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; ******************************************************************************
;
;    Define symbol as local
;
;    IN:  CDE = *identifier
;
;    OUT: Fc = 1, if no room for symbol, otherwise Fc = 0
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.DefLocalSymbol     CALL CurrentModule
                    LD   A,module_localroot
                    CALL Read_pointer
                    CALL FindSymbol               ; foundsym = FindSymbol(id, CURRENTMODULE->localroot)
                    JR   NC, found_localsym       ; if (foundsym == NULL)
                         EXX
                         LD   A,H                      ; {get symboltype}
                         EXX
                         OR   2**SYMLOCAL | 2**SYMDEFINED; symboltype |= SYMLOCAL | SYMDEFINED

                         PUSH BC
                         PUSH DE
                         PUSH HL

                         PUSH DE
                         CALL CurrentModule
                         LD   DE,module_localroot
                         ADD  HL,DE                    ; BHL = &CURRENTMODULE->localroot
                         POP  DE

                         PUSH AF
                         PUSH BC
                         PUSH HL
                         CALL CurrentModule
                         PUSH BC
                         EX   AF,AF'
                         POP  AF
                         EX   AF,AF'
                         PUSH HL
                         EXX
                         POP  HL                       ; ahl = modowner
                         EXX
                         POP  HL
                         POP  BC
                         POP  AF

                         PUSH IX
                         LD   IX, CmpIDstr
                         CALL InsertSym                ; InsertSymbol(id, value, symboltype, &localroot, modowner)
                         POP  IX
                         POP  HL
                         POP  DE
                         POP  BC                       ; {BHL=foundsym, CDE=id}
                         JR   end_deflocal             ; return 1
                                                  ; else
.found_localsym          LD   A,symtree_type
                         CALL Read_byte
                         BIT  SYMDEFINED,A
                         JR   NZ, localsym_defined     ; if ( foundsym->type & SYMDEFINED == 0 )
                              EXX
                              OR   H                        ; foundsym->type |= symboltype
                              EXX
                              OR   2**SYMLOCAL | 2**SYMDEFINED; foundsym->type |= SYMLOCAL | SYMDEFINED
                              LD   C,A
                              LD   A,symtree_type
                              CALL Set_byte

                              LD   A, symtree_symvalue
                              CALL Set_long                 ; foundsym->symvalue = value
                              PUSH DE
                              PUSH BC
                              PUSH BC
                              PUSH HL

                              CALL CurrentModule
                              EX   DE,HL
                              POP  HL
                              LD   A,B
                              POP  BC
                              LD   C,A                      ; {BHL=foundsym, CDE=CURRENTMODULE}
                              LD   A, symtree_modowner
                              CALL Set_pointer              ; foundsym->owner = CURRENTMODULE
                              POP  BC
                              POP  DE
                              JR   end_deflocal             ; return 1
                                                       ; else
.localsym_defined             CALL ReleaseID                ; {release redundant search ID}
                              LD   A, ERR_sym_decl_local
                              CALL ReportError_STD          ; Reporterror(14)
                              SCF
                              RET
.end_deflocal       CALL ReleaseID                ; {release redundant search ID}
                    CP   A
                    RET


; **********************************************************************************************************
;
;    IN:  BHL  = pointer to pointer to root of symbol tree
;         CDE  = pointer to symbol identifier
;         A    = symbol type
;         ahl  = owner of symbol
;         bcde = long integer of symbol value
;         IX   = pointer to symbol compare routine
;
;    OUT: BHL = pointer to created symbol and Fc = 0,
;         otherwise BHL = NULL, Fc = 1            (no room)
;
; Registers changed after return:
;
;    ...CDE../..IY  same
;    AFB...HL/IX..  different
;
.InsertSym          PUSH BC
                    PUSH DE

                    PUSH HL
                    PUSH BC
                    PUSH AF
                    EX   AF,AF'
                    PUSH AF
                    EX   AF,AF'
                    EXX
                    PUSH HL
                    PUSH DE
                    PUSH BC
                    EXX

                    LD   B,C                      ; id = AllocIdentfier(strlen(identifier))
                    EX   DE,HL                    ; if ( id == NULL )
                    CALL CopyId                        ; return NULL
                    JR   C, err_insertsym         ; else strcpy(id, identfifier)

                    CALL AllocSymbol              ; if ( (newsym=AllocSymbol()) == NULL )
                    JR   C, err_insertsym              ; return NULL

                    LD   A, symtree_symname
                    CALL Set_pointer              ; newsym->symname = identifier

                    EXX
                    POP  BC
                    POP  DE
                    EXX
                    LD   A, symtree_symvalue
                    CALL Set_long                 ; newsym->symvalue = value

                    POP  DE
                    POP  AF
                    LD   C,A                      ; CDE = modowner
                    LD   A, symtree_modowner
                    CALL Set_pointer              ; newsym->owner = modowner

                    POP  AF
                    LD   C,A
                    LD   A, symtree_type
                    CALL Set_Byte                 ; newsym->type = symboltype

                    LD   A,B
                    POP  BC
                    POP  DE
                    LD   C,B
                    LD   B,A                      ; BHL = newsym, CDE = **root of symbol tree
                    EXX
                    PUSH IX
                    POP  HL                       ; pointer to compare routine in hl
                    EXX
                    PUSH IY                       ; preserve original IY
                    LD   IX,0
                    ADD  IX,SP                    ; IX points at original IY
                    LD   IY,-5
                    ADD  IY,SP                    ; IY points at original stack pointer
                    LD   SP,IY                    ; create room on stack for parameters
                    LD   (IY+0),L
                    LD   (IY+1),H
                    LD   (IY+2),B                 ; newsym
                    EXX
                    LD   (IY+3),L
                    LD   (IY+4),H                 ; Compare routine pointer installed
                    EXX
                    LD   B,C
                    EX   DE,HL                    ; BHL = root
                    CALL Insert                   ; Insert( newsym, cmpidstr, &CURRENTMODULE->notdeclroot)
                    LD   SP,IX                    ; {restore original stack pointer}
                    POP  IY                       ; {restore original IY}

                    POP  DE
                    POP  BC                       ; {restore pointer to symbol identfifier}
                    CP   A                        ; {signal success}
                    RET

.err_insertsym      POP  AF
                    POP  AF
                    POP  AF
                    POP  AF
                    POP  AF
                    POP  AF
                    POP  AF
                    POP  DE
                    POP  BC                       ; restore pointer to id
                    CALL NULL_pointer             ; return NULL
                    SCF                           ; signal error
                    RET



; **************************************************************************************************
;
; IN: A = symtype
;
; Registers changed after return:
;
;    ......../..IY  same
;    AFBCDEHL/IX..  different
;
.DeclSymExtern      PUSH AF
                    POP  IX
                    LD   HL, Ident
                    CALL AllocIdentifier          ; allocate search string id
                    RET  C                        ; Ups - no room for string...
                    LD   C,B
                    EX   DE,HL                    ; {CDE = id}
                    CALL CurrentModule
                    LD   A,module_localroot
                    CALL Read_pointer
                    CALL FindSymbol               ; foundsym = FindSymbol( id, CURRENTMODULE->localroot )
                    JR   NC, extern_decl_local    ; if ( foundsym == NULL )
                         LD   HL,globalroot
                         CALL GetVarPointer
                         CALL FindSymbol               ; foundsym = FindSymbol( id, globalroot )
                         JR   NC, extern_redecl        ; if ( foundsym == NULL )
                              LD   HL, globalroot           ; {BHL = &globalroot}
                              CALL GetPointer
                              PUSH IX
                              POP  AF
                              OR   2**SYMXREF                ; symboltype = SYM_NOTDEFINED | SYMXREF | symtype
                              PUSH AF
                              PUSH BC
                              PUSH HL
                              CALL CurrentModule
                              PUSH BC
                              EX   AF,AF'
                              POP  AF
                              EX   AF,AF'
                              PUSH HL
                              EXX
                              POP  HL                       ; ahl = modowner
                              EXX
                              POP  HL
                              POP  BC
                              POP  AF
                              LD   IX, CmpIDstr
                              CALL InsertSym                ; InsertSymbol( ... )
                              CALL ReleaseID                ; {release redundant search id}
                              LD   A, ERR_no_room
                              CALL C, ReportError_STD
                              RET
                                                       ; else
.extern_redecl                CALL ReleaseID                ; {release redundant search id}
                              LD   A, symtree_modowner
                              CALL Read_pointer
                              LD   C,B
                              EX   DE,HL                    ; {foundsym->owner in CDE}
                              CALL CurrentModule            ; {CURRENTMODULE in BHL}
                              CALL CmpPtr                   ; if ( foundsym->owner == CURRENTMODULE )
                              RET  NZ
                                   LD   A, ERR_redecl_not_allw
                                   CALL ReportError_STD          ; ReportError(23)
                                   RET
                                                  ; else
.extern_decl_local       CALL ReleaseID                ; {release redundant search id}
                         LD   A, ERR_sym_decl_local
                         CALL ReportError_STD          ; ReportError(17)
                    RET



; **************************************************************************************************
;
; IN: A = symbol type
; Registers changed after return:
;
;    ......../..IY  same
;    AFBCDEHL/IX..  different
;
.DeclSymGlobal      PUSH AF
                    POP  IX
                    LD   HL, Ident
                    CALL AllocIdentifier          ; allocate string in OZ memory
                    RET  C                        ; Ups - no room for string...
                    LD   C,B
                    EX   DE,HL                    ; {CDE = id}
                    CALL CurrentModule
                    LD   A,module_localroot
                    CALL Read_pointer
                    CALL FindSymbol               ; foundsym = FindSymbol( id, CURRENTMODULE->localroot )
                    JP   NC, global_decl_local    ; if ( foundsym == NULL )
                         LD   HL,globalroot
                         CALL GetVarPointer
                         CALL FindSymbol               ; foundsym = FindSymbol( id, globalroot )
                         JR   NC, global_redecl        ; if ( foundsym == NULL )
                              LD   HL, globalroot           ; {BHL = &globalroot}
                              CALL GetPointer
                              PUSH IX
                              POP  AF
                              OR   2**SYMXDEF                ; symboltype = SYM_NOTDEFINED | SYMXDEF | symtype
                              PUSH AF
                              PUSH BC
                              PUSH HL
                              CALL CurrentModule
                              PUSH BC
                              EX   AF,AF'
                              POP  AF
                              EX   AF,AF'
                              PUSH HL
                              EXX
                              POP  HL                       ; ahl = modowner
                              EXX
                              POP  HL
                              POP  BC
                              POP  AF
                              LD   IX, CmpIDstr
                              CALL InsertSym                ; InsertSymbol( ... )
                              LD   A, ERR_no_room
                              CALL C, ReportError_STD
                              CALL ReleaseID                ; {release redundant search id}
                              RET
                                                       ; else
.global_redecl                CALL ReleaseID                ; {release redundant search id}
                              PUSH BC
                              PUSH HL                       ; {preserve foundsym}
                              LD   A, symtree_modowner
                              CALL Read_pointer
                              LD   C,B
                              EX   DE,HL                    ; {foundsym->owner in CDE}
                              CALL CurrentModule            ; {CURRENTMODULE in BHL}
                              CALL CmpPtr                   ; if ( foundsym->owner != CURRENTMODULE )
                              POP  HL
                              POP  BC                       ; {restore foundsym}
                              JR   Z, global_redecl_err
                                   LD   A, symtree_type
                                   CALL Read_byte
                                   BIT  SYMXREF,A
                                   JR   Z, global_already   ; if ( foundsym->type & SYMXREF )
                                        RES  SYMXREF,A
                                        SET  SYMXDEF,A           ; re-declared as global
                                        LD   C,A
                                        PUSH IX
                                        POP  AF
                                        OR   C
                                        LD   C,A
                                        LD   A, symtree_type
                                        CALL Set_byte            ; foundsym->type |= XDEF | symtype
                                        PUSH BC
                                        PUSH HL
                                        CALL CurrentModule
                                        LD   A,B
                                        EX   DE,HL
                                        POP  HL
                                        POP  BC
                                        LD   C,A
                                        LD   A, symtree_modowner
                                        CALL Set_pointer         ; foundsym->owner = CURRENTMODULE
                                        RET                 ; else

.global_already                         LD   A, ERR_sym_glob_module
                                        CALL ReportError_STD     ; ReportError(22)
                                        RET
                                                            ; else
.global_redecl_err                 LD   A, ERR_redecl_not_allw
                                   CALL ReportError_STD          ; ReportError(23)
                                   RET
                                                  ; else
.global_decl_local       CALL ReleaseID                ; {release redundant search id}
                         LD   A, ERR_sym_decl_local
                         CALL ReportError_STD          ; ReportError(17)
                    RET


; **************************************************************************************************
;
;    Copy static symbols to current module's local symbols
;
.CopyStaticLocal    PUSH IX
                    PUSH IY
                    LD   IX, copydata
                    LD   IY, cmpIDstr
                    CALL CurrentModule
                    LD   DE,module_localroot
                    ADD  HL,DE
                    LD   C,B
                    EX   DE,HL                    ; CDE = &CURRENTMODULE->localroot
                    LD   HL, staticroot
                    CALL GetvarPointer            ; BHL = staticroot
                    CALL Copy                     ; Copy(BHL, CDE, cmpIDstr, copydata)
                    POP  IY
                    POP  IX
                    RET


; **************************************************************************************************
;
;    Create a copy of the symtree data. All fields excecpt symtree_symname are a binary copy.
;    The symname string is created explicitly.
;
;    IN:  BHL = pointer to current node data (to be copied)
;    OUT: BHL = pointer to copy of node data
;
;    Registers changed after return
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.copydata           PUSH BC
                    PUSH HL                       ; preserve pointer to srcnode data
                    CALL AllocSymbol
                    JR   C, sym_notalloc
                         EX   DE,HL
                         POP  HL
                         LD   A,B
                         POP  BC                  ; BHL = srcptr
                         LD   C,A                 ; CDE = dstptr
                         LD   A, SIZEOF_symboltree
                         CALL memcpy              ; copy node data...
                         LD   A, symtree_symname
                         CALL Read_pointer        ; BHL = srcptr->symname
                         PUSH BC
                         PUSH DE                  ; CDE = dstptr
                         CALL CopyId              ; copy srcptr->symname to
                         POP  HL                  ; CDE = symname_cpy
                         LD   A,C
                         POP  BC
                         LD   B,C
                         LD   C,A                 ; BHL = dstptr, CDE = symname_cpy
                         LD   A, symtree_symname
                         CALL Set_pointer         ; dstptr->symname = symname_copy
                         RET                      ; return dstptr

.sym_notalloc       CALL ReportError_NULL
                    POP  AF
                    POP  AF                  ; return NULL - symbol not copied.
                    RET



; **************************************************************************************************
;
; return NULL pointer in BHL.
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
                    RET


; ******************************************************************************
;
;    Allocate and copy identifier
;
;    IN:  BHL = pointer to identifier (length prefixed and null-terminated)
;    OUT: CDE = pointer to new copy of identifier
;         Fc  = 0, successfully allocated and copied, otherwise Fc = 1
;
; Registers changed after return:
;
;    ..B...HL/IXIY  same
;    AF.CDE../....  different
;
.CopyId             PUSH BC
                    PUSH HL
                    XOR  A
                    CALL Read_byte                ; length of string
                    INC  A
                    INC  A                        ; length byte + string + nullterminator
                    CALL malloc                   ; now allocate memory for copy of identifier
                    JR   C, alloc_no_room
                    EX   DE,HL
                    POP  HL
                    LD   A,B
                    POP  BC
                    LD   C,A                      ; BHL = src_string, CDE = dst_string
                    CALL strcpy                   ; strcpy(dst_string, src_string)
                    RET

.alloc_no_room      CALL ReportError_NULL
                    POP  HL
                    POP  BC                       ; restore pointer to source string
                    SCF                           ; and signal error
                    RET



; ***********************************************************************************
;
; Release temporary identifier string
;
; IN: CDE = pointer to identifier string
;
; Registers changed after return:
;
;    AFBC..HL/IXIY same
;    ....DE../.... different
;
.ReleaseId          PUSH AF
                    PUSH BC
                    PUSH HL
                    LD   B,C
                    EX   DE,HL
                    CALL mfree               ; {release tmp. identifier}
                    POP  HL
                    POP  BC
                    POP  AF
                    RET


; ******************************************************************************
;
;    Release symbol back to OZ memory (recursively).
;    This is a supplied service routine for the .deleteall library routine
;
; IN: BHL pointer to symbol node
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.FreeSym            PUSH BC
                    PUSH HL                            ; {preserve node}
                    LD   A, symtree_symname
                    CALL Read_pointer
                    XOR  A
                    CP   B
                    JR   Z, rel_symnode                ; if ( node->symname != NULL )
                         CALL mfree                         ; free(node->symname)

.rel_symnode        POP  HL
                    POP  BC
                    CALL mfree                         ; free(node)
                    RET



; **************************************************************************************************
;
;    Allocate memory for symbol record
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocSymbol        LD   A, SIZEOF_symboltree
                    CALL malloc
                    RET

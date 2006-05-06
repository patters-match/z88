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

     MODULE Module_management

; external procedures:
     LIB malloc, mfree
     LIB Set_pointer, Read_pointer, Set_word, Set_long

     XREF GetVarPointer                      ; varptr.asm
     XREF CurrentModule                      ; module.asm
     XREF RemovePfixList                     ; parsexpr.asm

; global procedures:
     XDEF NewModule, ReleaseExpressions


     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"



; **************************************************************************************************
;
;    Create new module and append to list of modules, if present
;
; OUT:    Fc = 0, success & BHL = pointer to new module
;         Fc = 1, no room & BHL = NULL
;         (pointers in list modified)
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.NewModule          LD   HL, modulehdr
                    CALL GetVarPointer                 ; get pointer to modulehdr pointer
                    XOR  A
                    CP   B
                    JR   NZ, modulehdr_exists          ; if ( modulehdr == NULL ) {
                         CALL AllocModuleHdr           ;    if ( (modulehdr = AllocModuleHdr()) == NULL )
                         JP   C, newm_nullptr          ;         return (no room)...
                                                       ;    else {
                         LD   C,B                      ;
                         EX   DE,HL
                         LD   HL,(modulehdr)
                         LD   A,(modulehdr+2)
                         LD   B,A                      ;         { ptr. to pointer variable 'modulehdr' }
                         XOR  A                        ;
                         CALL Set_pointer              ;         { store pointer to modulehdr record }
                         LD   B,C                      ;
                         EX   DE,HL                    ;         { restore modulehdr ptr. in BHL }
                         XOR  A
                         LD   E,A
                         LD   D,A
                         LD   C,A                      ;         { NULL pointer }
                         LD   A, modules_first
                         CALL Set_pointer              ;         modulehdr->first = NULL
                         LD   A, modules_last
                         CALL Set_pointer              ;         modulehdr->current = NULL
                                                       ;    }
                                                       ; }

.modulehdr_exists   CALL AllocModule                   ; if ( (newm = AllocModule()) == NULL )
                    JP   C, newm_nullptr               ;    Ups - no room
                    XOR  A                               else
                    LD   D,A
                    LD   E,A                                { BHL = newm }
                    LD   C,A                           ;    { CDE = NULL pointer }
                    LD   A, module_next
                    CALL Set_pointer                   ;    newm->nextmodule = NULL
                    LD   A, module_mname
                    CALL Set_pointer                   ;    newm->mname = NULL
                    LD   A, module_cfile
                    CALL Set_pointer                   ;    newm->cfile = NULL
                    LD   A, module_localroot
                    CALL Set_pointer                   ;    newm->localroot = NULL
                    EXX
                    LD   BC,(codesize)
                    LD   DE,0
                    EXX
                    LD   A, module_startoffset
                    CALL Set_long                      ;    newm->startoffset = codesize
                    LD   A, module_origin
                    LD   DE, $FFFF
                    CALL Set_word                      ;    newm->origin = 65535

                    PUSH BC                                 { preserve newm }
                    PUSH HL                            ;
                    CALL AllocExprHdr                  ;    if ( (m = AllocExprhdr()) == NULL )
                    JR   C, mexpr_no_room
                         LD   C,0
                         LD   D,C
                         LD   E,C
                         LD   A, expression_first
                         CALL Set_pointer              ;         m->firstexpr = NULL
                         LD   A, expression_curr
                         CALL Set_pointer              ;         m->currexpr = NULL
                         LD   A,B
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         LD   C,A                      ;         { BHL = newm, CDE = m }
                         LD   A,module_mexpr
                         CALL Set_pointer              ;         newm->mexpr = m
                                                       ;    else
                                                       ;         free(newm)
                                                       ;         return 0

; allocate JR address header and store pointer in module
.alloc_JRaddr       PUSH BC
                    PUSH HL                            ; {preserve newm}
                    CALL AllocJRaddrHdr                ;    if ( (m = AllocJRaddrhdr()) == NULL )
                    JR   C, JRaddr_no_room
                         LD   C,0
                         LD   D,C
                         LD   E,C
                         LD   A, JRpcexpr_first
                         CALL Set_pointer              ;         m->firstref = NULL
                         LD   A, JRpcexpr_last
                         CALL Set_pointer              ;         m->lastref = NULL
                         LD   A,B
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         LD   C,A                      ;         { BHL = newm, CDE = m }
                         LD   A,module_JRaddr
                         CALL Set_pointer              ;         newm->JRaddr = m

                    LD   C,B
                    EX   DE,HL                         ; { CDE = newm }
                    LD   HL, modulehdr
                    CALL GetVarPointer                 ; { get pointer to modulehdr pointer in BHL }
                    PUSH BC
                    PUSH HL                            ; { preserve modulehdr }
                    LD   A, modules_first
                    CALL Read_pointer                  ; { BHL = modulehdr->first }
                    XOR  A
                    CP   B
                    POP  HL                            ; { restore modulehdr }
                    POP  BC
                    JR   NZ, append_module             ; if ( modulehdr->first == NULL )
                         LD   A, modules_first
                         CALL Set_pointer              ;    modulehdr->first = newm
                         LD   A, modules_last
                         CALL Set_pointer              ;    modulehdr->current = newm
                         JR   end_newmodule
                                                       ; else
.append_module      PUSH BC
                    PUSH HL                            ;    { preserve modulehdr }
                    LD   A, modules_last
                    CALL Read_pointer
                    LD   A, module_next
                    CALL Set_pointer                   ;    modulehdr->current->nextmodule = newm
                    POP  HL
                    POP  BC
                    LD   A, modules_last
                    CALL Set_pointer                   ;    modulehdr->current = newm

.end_newmodule      XOR  A                             ; return CDE = newm
                    RET                                ; indicate succes...

; nor room for JD address header, free <newm->mexpr> and <newm>.
.JRaddr_no_room     POP  HL
                    POP  BC
                    PUSH BC
                    PUSH HL                            ;         { BHL = newm }
                    LD   A, module_mexpr
                    CALL Read_pointer
                    CALL mfree                         ;         free(newm->mexpr)

.mexpr_no_room      POP  HL
                    POP  BC                            ;         { restore newm in BHL }
                    CALL mfree                                   free(newm);
.newm_nullptr       EX   DE,HL
                    LD   C,B
                    SCF                                ;         return NULL
                    RET



; **************************************************************************************************
;
;    Release any pass2 expressions in current module
;
;    IN: None.
;
.ReleaseExpressions CALL CurrentModule
                    LD   A, module_mexpr
                    CALL Read_pointer             ; exprhdr = CURRENTMODULE->mexpr
                    XOR  A
                    CP   B
                    RET  Z                        ; if ( exprhdr == NULL ) return

                    PUSH BC
                    PUSH HL                       ; { preserve exprhdr }
                    LD   A, expression_first
                    CALL Read_pointer             ; curexpr = exprhdr->first
                    XOR  A
                    CP   B
                    JR   Z, release_exprhdr       ; if ( curexpr != NULL )
.relexpr_loop            PUSH BC                       ; do
                         PUSH HL
                         LD   A,expr_nextexpr
                         CALL Read_pointer                  ; tmpexpr = curexpr->nextexpr
                         LD   A,B
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         LD   C,A
                         PUSH BC
                         PUSH DE
                         CALL RemovePfixList                ; RemovepfixList(curexpr)
                         POP  HL
                         POP  BC
                         LD   B,C                           ; curexpr = tmpexpr
                         XOR  A
                         CP   B
                    JR   NZ, relexpr_loop              ; while (curexpr != NULL)

.release_exprhdr    POP  HL
                    POP  BC                       ; { restore header of expressions }
                    CALL mfree                    ; free(exprhdr)
                    CALL CurrentModule
                    LD   A, module_mexpr
                    LD   C,0
                    LD   DE,0
                    CALL Set_pointer              ; CURRENTMODULE->mexpr = NULL
                    RET



; **************************************************************************************************
;
;    Allocate memory for module header record
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocModuleHdr     LD   A, SIZEOF_modules
                    CALL malloc
                    RET


; **************************************************************************************************
;
;    Allocate memory for module record
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocModule        LD   A, SIZEOF_module
                    CALL malloc
                    RET


; **************************************************************************************************
;
;    Allocate memory for module expression header list
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocExprHdr       LD   A, SIZEOF_expression
                    CALL malloc
                    RET


; **************************************************************************************************
;
;    Allocate memory for Jump Relative Address header
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocJRaddrHdr     LD   A, SIZEOF_jrpcexpr
                    CALL malloc
                    RET

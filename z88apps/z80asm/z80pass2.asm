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

     MODULE Z80pass2


; external procedures:
     LIB mfree
     LIB CmpPtr
     LIB Read_word, Read_byte, Read_pointer
     LIB Set_word, Set_pointer
     LIB ascorder

     XREF Open_file                                         ; fileio.asm
     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF RemovePfixList                                    ; parsexpr.asm
     XREF EvalPfixExpr                                      ; evalexpr.asm
     XREF GetVarPointer                                     ; z80asm.asm
     XREF CurrentModule                                     ; module.asm

     XREF StoreExpr, Test_7bit_range, Test_8bit_range       ; exprs.asm
     XREF Test_16bit_range, Test_32bit_Range                ;

     XREF Write_fptr, ftell, fseek, Copy_file               ; fileio.asm
     XREF Write_string                                      ;


; routines accissible in this module:
     XDEF Z80pass2


     INCLUDE "stdio.def"
     INCLUDE "syspar.def"
     INCLUDE "integer.def"
     INCLUDE "fileio.def"
     INCLUDE "fpp.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"

; **************************************************************************************************
;
; Try to evaluate expressions that contained undefined symbols in pass1 (forward referenced symbols)
;
.Z80pass2
                    CALL CurrentModule
                    LD   A, module_mexpr
                    CALL Read_pointer
                    LD   A, expression_first           ; pass2expr = CURRENTMODULE->mexpr->firstexpr
                    CALL Read_pointer                  ; if ( pass2expr != NULL )
                    XOR  A
                    CP   B
                    JP   Z, no_pass2exprs
                         CALL Store_pass2exprptr
                         CALL CurrentModule
                         LD   A, module_jraddr
                         CALL Read_pointer
                         LD   A, jrpcexpr_first
                         CALL Read_pointer                  ; CurJR = CURRENTMODULE->JRaddr->firstref
                         LD   (curJR_ptr),HL
                         LD   A,B
                         LD   (curJR_ptr+2),A
                         CALL Get_pass2exprptr
.while_pass2expr                                            ; do
                              CALL EvalPfixExpr                  ; const = EvalPfixExpr(pass2expr)
                              LD   (longint+2),HL
                              EXX
                              LD   (longint),HL                  ; {preserve const}
                              EXX
                              CALL Get_pass2exprptr
                              LD   A, expr_rangetype
                              CALL Read_byte                     ; rtype = pass2expr->rangetype
                              BIT  SYMXREF,A                     ; if (rtype & EXPREXTERN)
                              JR   NZ, pass2_store_expr
                              BIT  SYMADDR,A                     ; if (rtype & EXPRADDR)
                              JR   NZ, pass2_store_expr
                              JR   pass2_evalexpr

.pass2_store_expr             PUSH AF                            ; {preserve rtype}
                              LD   A, expr_stored
                              CALL Read_byte
                              CP   flag_ON                       ; if ( pass2expr->stored == OFF )
                              JR   Z, pass2_ignore
                                   POP  AF
                                   PUSH AF
                                   AND  RANGE                         ; switch(rtype & RANGE)
                                   CP   RANGE_32SIGN
                                   JR   NZ, pass2_store_16const            ; case RANGE_32SIGN: StoreExpr(pass2expr, 'L')
                                        LD   A,'L'
                                        JR   expr_to_objfile

.pass2_store_16const               CP   RANGE_16CONST
                                   JR   NZ, pass2_store_8unsign            ; case RANGE_16CONST: StoreExpr(pass2expr, 'C')
                                        LD   A,'C'
                                        JR   expr_to_objfile

.pass2_store_8unsign               CP   RANGE_8UNSIGN
                                   JR   NZ, pass2_store_8sign              ; case RANGE_8UNSIGN: StoreExpr(pass2expr, 'U')
                                        LD   A,'U'
                                        JR   expr_to_objfile

.pass2_store_8sign                 CP   RANGE_8SIGN
                                   JR   NZ, pass2_ignore
                                   LD   A,'S'                              ; case RANGE_8SIGN: StoreExpr(pass2expr, 'S')
.expr_to_objfile                   CALL StoreExpr

.pass2_ignore                 POP  AF
.pass2_evalexpr               LD   C,A
                              BIT  7,A                           ; if ( rtype & NOTEVALUABLE )
                              JR   Z, pass2expr_patch
                                   AND  RANGE
                                   CP   RANGE_JROFFSET
                                   LD   A,C
                                   JR   NZ, pass2_sym_not_found       ; if ( (rtype & RANGE) == RANGE_JROFFSET )
                                        BIT  6,A                           ; if (rtype & EXPREXTERN)
                                        JR   Z, pass2_JR_not_found
                                             LD   A, ERR_reljmp_local           ; ReportError(25)
                                             CALL Pass2Error
                                             JR   pass2_next_JR            ; else
.pass2_JR_not_found                          LD   A, ERR_not_defined
                                             CALL Pass2Error                    ; ReportError(2)
                                                                           ; curJR = curJR->nextref
.pass2_next_JR                          CALL Release_JRaddr                ; free(prevJR)
                                        JP   pass2_endwhile                ; prevJR = curJR
                                                                      ; else
.pass2_sym_not_found                    LD   A, ERR_not_defined            ; ReportError(pass2expr->srcfile, 2)
                                        CALL Pass2Error
                                        JP   pass2_endwhile
                                                                 ; else
.pass2expr_patch                   LD   IX,(cdefilehandle)            ; file handle for machine code buffer
                                   LD   A,C                           ; switch (rtype & RANGE)
                                   AND  RANGE
                                   CP   RANGE_JROFFSET                     ; case RANGE_JROFFSET:
                                   JR   NZ, pass2_patch_8unsign
                                        LD   HL,(curJR_ptr)
                                        LD   A,(curJR_ptr+2)
                                        LD   B,A
                                        LD   A,jrpc_PCaddr
                                        CALL Read_word                          ; {curJR->PCaddr in DE}
                                        PUSH DE
                                        LD   HL,(longint+2)
                                        LD   DE,0
                                        EXX
                                        LD   HL,(longint)
                                        POP  DE
                                        EXX                                     ; {HLhlC=const, DEdeB=curJR->PCaddr}
                                        LD   BC,0
                                        FPP  (FP_SUB)                           ; const -= curJR->PCaddr
                                        CALL Test_7bit_range                    ; if ( const>=-128 && const<=127 )
                                        JR   C, pass2_JR_range_err
                                             EXX
                                             PUSH HL                                 ; { preserve const}
                                             EXX
                                             CALL Get_pass2exprptr                   ; {pass2expr}
                                             LD   DE, expr_codepos
                                             CALL fseek                              ; patchptr
                                             POP  HL
                                             LD   A,L                                ; *patchptr = const
                                             CALL_OZ(Os_Pb)
                                             CALL Release_JRaddr
                                             JP   pass2_endwhile                ; else
                                                                                     ; ReportError(7)
.pass2_JR_range_err                          CALL Release_JRaddr                ; curJR = curJR->nextref
                                             CALL Get_pass2exprptr              ; free(prevJR)
                                             JP   pass2_range_err               ; prevJR = curJR

.pass2_patch_8unsign               CP   RANGE_8UNSIGN                      ; case RANGE_8UNSIGN:
                                   JR   NZ, pass2_patch_8sign
                                        BIT  6,C                                ; if !(rtype & EXPREXTERN) && !(rtype & EXPRADDR)
                                        JP   NZ, pass2_endwhile
                                        BIT  3,C
                                        JP   NZ, pass2_endwhile
                                             LD   HL,(longint+2)
                                             EXX
                                             LD   HL,(longint)
                                             EXX
                                             LD   C,0                                ; const = (unsigned char) const
                                             CALL Test_8bit_range                    ; if (const>=0 && const<=255)
                                             JP   C, pass2_range_err
                                                  CALL Get_pass2exprptr                   ; {pass2expr}
                                                  LD   DE, expr_codepos
                                                  CALL fseek                              ; patchptr
                                                  LD   A,(longint)                        ; *patchptr = const
                                                  CALL_OZ(Os_Pb)                     ; else
                                             JP   pass2_endwhile                          ; reporterror(7)

.pass2_patch_8sign                 CP   RANGE_8SIGN                        ; case RANGE_8SIGN:
                                   JR   NZ, pass2_patch_16const
                                        BIT  6,C                                ; if !(rtype & EXPREXTERN) && !(rtype & EXPRADDR)
                                        JP   NZ, pass2_endwhile
                                        BIT  3,C
                                        JR   NZ, pass2_endwhile
                                             LD   HL,(longint+2)
                                             EXX
                                             LD   HL,(longint)
                                             EXX
                                             LD   C,0                                ; const = (char) const
                                             CALL Test_7bit_range                    ; if (const>=-128 && const<=127)
                                             JR   C, pass2_range_err
                                                  CALL Get_pass2exprptr                   ; {pass2expr}
                                                  LD   DE, expr_codepos
                                                  CALL fseek                              ; patchptr
                                                  LD   A,(longint)                        ; *patchptr = const
                                                  CALL_OZ(Os_Pb)                     ; else
                                             JR   pass2_endwhile                          ; reporterror(7)

.pass2_patch_16const               CP   RANGE_16CONST                      ; case RANGE_16CONST
                                   JR   NZ, pass2_patch_32sign
                                        BIT  6,C                                ; if !(rtype & EXPREXTERN) && !(rtype & EXPRADDR)
                                        JR   NZ, pass2_endwhile
                                        BIT  3,C
                                        JR   NZ, pass2_endwhile
                                             LD   HL,(longint+2)
                                             EXX
                                             LD   HL,(longint)
                                             EXX
                                             LD   C,0                                ; const = (unsigned char) const
                                             CALL Test_16bit_range                   ; if (const>=0 && const<=65535)
                                             JR   C, pass2_range_err
                                                  CALL Get_pass2exprptr                   ; {pass2expr}
                                                  LD   DE, expr_codepos
                                                  CALL fseek                              ; patchptr
                                                  LD   HL,(longint)                       ; *patchptr = const
                                                  LD   A,L
                                                  CALL_OZ(Os_Pb)
                                                  LD   A,H
                                                  CALL_OZ(Os_Pb)                     ; else
                                             JR   pass2_endwhile                          ; reporterror(7)

.pass2_patch_32sign                                                        ; case RANGE_32SIGN:
                                   BIT  6,C                                     ; if !(rtype & EXPREXTERN) && !(rtype & EXPRADDR)
                                   JR   NZ, pass2_endwhile
                                   BIT  3,C
                                   JR   NZ, pass2_endwhile
                                        LD   HL,(longint+2)
                                        EXX
                                        LD   HL,(longint)
                                        EXX
                                        LD   C,0
                                        CALL Test_32bit_range                        ; if (const>=LONG_MIN && const<=LONG_MAX)
                                        JR   C, pass2_range_err
                                             CALL Get_pass2exprptr                        ; {pass2expr}
                                             LD   DE, expr_codepos
                                             CALL fseek                                   ; patchptr
                                             LD   B,0                                     ; (local ptr)
                                             LD   HL,longint                              ; *patchptr = const
                                             CALL write_fptr                         ; else
                                             JR   pass2_endwhile                          ; reporterror(7)

.pass2_range_err                   LD   A, ERR_range
                                   CALL Pass2Error

.pass2_endwhile               CALL Get_pass2exprptr
                              PUSH BC
                              PUSH HL                            ; prevexpr = pass2expr
                              LD   A, expr_nextexpr
                              CALL Read_pointer                  ; pass2expr = pass2expr->nextexpr
                              CALL Store_pass2exprptr
                              POP  HL
                              POP  BC
                              CALL RemovePfixList                ; RemovePfixList(prevexpr)

                         CALL Get_pass2exprptr
                         XOR  A
                         CP   B
                         JP   NZ, while_pass2expr           ; while ( pass2expr != NULL )

                         LD   C,0
                         LD   D,C
                         LD   E,C
                         CALL CurrentModule
                         PUSH BC
                         PUSH HL
                         LD   A, module_mexpr
                         CALL Read_pointer
                         CALL mfree                              ; free(CURRENTMODULE->mexpr)
                         POP  HL
                         POP  BC
                         LD   A, module_mexpr
                         CALL Set_pointer                        ; CURRENTMODULE->mexpr = NULL
                         PUSH BC
                         PUSH HL
                         LD   A, module_jraddr
                         CALL Read_pointer
                         CALL mfree                              ; free(CURRENTMODULE->JRaddr)
                         POP  HL
                         POP  BC
                         LD   A, module_jraddr
                         CALL Set_pointer                        ; CURRENTMODULE->JRaddr = NULL
.no_pass2exprs
.manipulate_objfile LD   IX,(objfilehandle)
                    CALL ftell
                    LD   (fptr_namedecl),BC
                    LD   (fptr_namedecl+2),DE                    ; fptr_namedecl = ftell(objfile)
                    CALL CurrentModule
                    LD   A, module_localroot
                    CALL Read_pointer

                    PUSH IY
                    LD   IY, StoreLocalName
                    CALL ascorder                                ; ascorder(CURRENTMODULE->localroot, StoreLocalName)
                    LD   HL, globalroot
                    CALL GetVarPointer
                    PUSH BC
                    PUSH HL
                    LD   IY, StoreGlobalName
                    CALL ascorder                                ; ascorder(globalroot, StoreGlobalName)

                    CALL ftell
                    LD   (fptr_libnames),BC
                    LD   (fptr_libnames+2),DE                    ; fptr_libnames = ftell(objfile)
                    POP  HL
                    POP  BC
                    LD   IY, StoreLibReference
                    CALL ascorder                                ; ascorder(globalroot, StoreLibReference)
                    POP  IY

                    CALL ftell
                    LD   (fptr_modname),BC
                    LD   (fptr_modname+2),DE                     ; fptr_modname = ftell(objfile)
                    CALL CurrentModule
                    LD   A,module_mname
                    CALL Read_pointer                            ; {BHL=CURRENTMODULE->mname}
                    XOR  A
                    CALL Read_byte                               ; length of string + 1
                    LD   C,A
                    INC  C
                    LD   DE,0
                    CALL Write_string                            ; fwrite(&modname, strlen(modname), objfile)

                    LD   BC,(codeptr)
                    CALL Disp_modulesize
                    LD   A,B
                    OR   C
                    JR   NZ, code_generated                      ; if ( codeptr == 0 )
                         LD   DE,-1
                         LD   (fptr_modcode),DE
                         LD   (fptr_modcode+2),DE                     ; fptr_modcode = -1
                         JR   z80pass2_origin                    ; else

.code_generated          LD   HL,(codesize)
                         ADD  HL,BC                                   ; CODESIZE += codeptr
                         LD   (codesize),HL
                         LD   IX,(objfilehandle)
                         CALL ftell
                         LD   (fptr_modcode),BC
                         LD   (fptr_modcode+2),DE                     ; fptr_modcode = ftell(objfile)
                         LD   BC,(codeptr)
                         LD   A,C
                         CALL_OZ(Os_Pb)                               ; fputc(codeptr%256, objfile)
                         LD   A,B
                         CALL_OZ(Os_Pb)                               ; fputc(codeptr/256, objfile)
                         LD   DE,0
                         LD   (longint),DE
                         LD   (longint+2),DE
                         LD   B,0                                     ; {local pointer}
                         LD   HL, longint
                         LD   IX,(cdefilehandle)
                         CALL fseek                                   ; fseek(cdefile, 0, SEEK_SET)

                         LD   BC,(codeptr)
                         XOR  A                                       ; ABC = SIZEOF(cdefile)
                         LD   HL,cdefilehandle
                         LD   DE,objfilehandle
                         CALL Copy_file                               ; fwrite(codearea, codesize, objfile)

.z80pass2_origin    LD   HL, modulehdr
                    CALL GetVarPointer
                    LD   A, modules_first
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL                                   ; CDE = modulehdr->first
                    CALL CurrentModule                           ; BHL = CURRENTMODULE
                    CALL CmpPtr                                  ; if ( modulehdr->first == CURRENTMODULE )
                    JR   NZ, write_origin
                         BIT deforigin, (IY + RTMflags)               ; if ( deforigin )
                         JR   Z, write_origin
                              LD   DE,(explicitORIG)
                              LD   A, module_origin                        ; explicit origin overrides ORG directive...
                              CALL Set_word                                ; CURRENTMODULE->origin = EXPLICIT_ORIGIN

.write_origin       LD   IX,(objfilehandle)
                    LD   BC,8
                    LD   DE,0
                    LD   (longint),BC
                    LD   (longint+2),DE
                    LD   HL, longint
                    CALL fseek                                   ; fseek(objfile, 8, SEEK_SET)
                    CALL CurrentModule
                    LD   A, module_origin
                    CALL Read_word                               ; {CURRENTMODULE->origin}
                    LD   A,E
                    CALL_OZ(Os_Pb)                               ; fputc(origin%256, objfile)
                    LD   A,D
                    CALL_OZ(Os_Pb)                               ; fputc(origin/256, objfile)

                    LD   BC,30
                    LD   DE,0                                    ; fptr_exprdecl = 30
                    LD   (fptr_exprdecl),BC
                    LD   (fptr_exprdecl+2),DE

                    LD   BC,(fptr_namedecl)
                    LD   DE,(fptr_namedecl+2)
                    LD   HL, fptr_exprdecl                       ; if ( fptr_namedecl == fptr_exprdecl )
                    CALL DefineDeclaration                            ; fptr_exprdecl = -1

                    LD   BC,(fptr_libnames)
                    LD   DE,(fptr_libnames+2)
                    LD   HL, fptr_namedecl                       ; if ( fptr_libnames == fptr_namedecl )
                    CALL DefineDeclaration                            ; fptr_namedecl = -1

                    LD   BC,(fptr_modname)
                    LD   DE,(fptr_modname+2)
                    LD   HL, fptr_libnames                       ; if ( fptr_modname == fptr_libnames )
                    CALL DefineDeclaration                            ; fptr_libnames = -1

                    LD   B,0
                    LD   HL, fptr_modname
                    CALL Write_fptr                              ; WriteLong(fptr_modname, objfile)
                    LD   HL, fptr_exprdecl
                    CALL Write_fptr                              ; WriteLong(fptr_exprdecl, objfile)
                    LD   HL, fptr_namedecl
                    CALL Write_fptr                              ; WriteLong(fptr_namedecl, objfile)
                    LD   HL, fptr_libnames
                    CALL Write_fptr                              ; WriteLong(fptr_libnames, objfile)
                    LD   HL, fptr_modcode
                    JP   Write_fptr                              ; WriteLong(fptr_modcode, objfile)


; **************************************************************************************************
;
;    IN:  BC = size of module
;
.Disp_modulesize    PUSH IX
                    PUSH BC
                    LD   HL, modsize_msg
                    CALL_OZ(Gn_sop)
                    PUSH BC
                    LD   BC, NQ_OHN
                    CALL_OZ(Os_Nq)                ; get handle in IX for standard output
                    POP  BC
                    LD   DE,0
                    LD   HL,2                     ; BC contains integer...
                    LD   A,1
                    CALL_OZ(Gn_Pdn)               ; write ASCII integer to standard output
                    LD   HL, bytes_msg
                    CALL_OZ(Gn_Sop)
                    POP  BC
                    POP  IX
                    RET

.modsize_msg        DEFM 1, "2H5Size of module is ", 0
.bytes_msg          DEFM " bytes", 13, 10, 0



; **************************************************************************************************
;
;    IN:  fptr_a:   DEBC = file pointer to declaration sectionn file pointer
;         fptr_b:   HL   = local pointer to another declaration section file pointer
;
;    OUT: If DEBC == (HL), then (HL) = -1
;
.DefineDeclaration  PUSH HL
                    LD   A,C
                    CP   (HL)
                    INC  HL
                    JR   NZ, section_declared
                    LD   A,B
                    CP   (HL)
                    INC  HL
                    JR   NZ, section_declared
                    LD   A,E
                    CP   (HL)
                    JR   NZ, section_declared     ; if ( fptr_a == fptr_b )
                         POP  HL
                         LD   B,4
                         LD   A,-1
.define_loop             LD   (HL),A
                         INC  HL
                         DJNZ define_loop              ; fptr_b = -1
                         RET
.section_declared   POP  HL
                    RET



; **************************************************************************************************
;
.Get_pass2exprptr   LD   HL,(pass2expr_ptr)
                    LD   A,(pass2expr_ptr+2)
                    LD   B,A
                    RET


; **************************************************************************************************
;
.Store_pass2exprptr LD   (pass2expr_ptr),HL
                    LD   A,B
                    LD   (pass2expr_ptr+2),A
                    RET


; **************************************************************************************************
;
.Release_JRaddr     LD   HL,(curJR_ptr)
                    LD   A,(curJR_ptr+2)          ; prevJR = curJR
                    LD   B,A
                    PUSH BC
                    PUSH HL
                    LD   A, jrpc_next
                    CALL Read_pointer
                    LD   (curJR_ptr),HL
                    LD   A,B
                    LD   (curJR_ptr+2),A          ; curJR = curJR->nextref
                    POP  HL
                    POP  BC
                    JP   mfree                    ; free(prevJR)


; **************************************************************************************************
;
; Report pass2 error
;
;    IN:    A = error code
;         BHL = pass2expr
;
; Registers changed after return:
;    AFBCDEHL/IXIY  same
;    ......../....  different
;
.Pass2Error         PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH AF
                    LD   A, expr_curline
                    CALL Read_word           ; pass2expr->curline
                    LD   A, expr_srcfile
                    CALL Read_pointer        ; pass2expr->srcfile
                    POP  AF
                    CALL ReportError         ; ReportError(pass2expr->srcfile, pass2expr->curline, ERR)
                    POP  HL
                    POP  DE
                    POP  BC
                    RET



; **************************************************************************************************
;
; Store symbol name to object file
;
;    IN: BHL = pointer to current node in symbol tree
;
.StoreLocalName     LD   A, symtree_type
                    CALL Read_byte                ; {symnode->type}
                    LD   E,A
                    BIT  SYMLOCAL,E               ; if ( SYMLOCAL && SYMTOUCHED )
                    RET  Z
                    BIT  SYMTOUCHED,E
                    RET  Z
                    LD   A, SYMLOCAL                   ; StoreName(symnode, SYMLOCAL)
                    JR   storename0

; **************************************************************************************************
;
; Store symbol name to object file
;
;    IN: BHL = pointer to current node in symbol tree
;
.StoreGlobalName    LD   A, symtree_type
                    CALL Read_byte                ; {symnode->type}
                    LD   E,A
                    BIT  SYMXDEF,E                ; if ( SYMGLOBAL && SYMTOUCHED )
                    RET  Z
                    BIT  SYMTOUCHED,E
                    RET  Z
                    LD   A, SYMXDEF                    ; StoreName(symnode, SYMXDEF)

.storename0         PUSH BC
                    PUSH HL
                    CALL StoreName
                    POP  HL
                    POP  BC
                    RET


; **************************************************************************************************
;
;    IN:  A = symscope
;
.StoreName               BIT  SYMLOCAL,E               ; switch(symscope)
                         JR   Z, sym_global                 ; case SYMLOCAL: fputc('L', objfile)
                              LD   A,'L'                    ;                break
                              JR   write_symscope
.sym_global              LD   A,'G'                         ; case SYMXDEF:  fputc('G',objfile)
.write_symscope          CALL_OZ(Os_Pb)                     ;                break
                         JP   C, ReportError_NULL

                         BIT  SYMADDR,E
                         JR   Z, sym_constant               ; if ( symnode->type & SYMADDR )
                              LD   A,'A'                         ; fputc('A', objfile)
                              JR   write_symtype            ; else
.sym_constant            LD   A,'C'                              ; fputc('C', objfile)
.write_symtype           CALL_OZ(Os_Pb)
                         JP   C, ReportError_NULL

                         LD   DE, symtree_symvalue
                         CALL Write_fptr                    ; WriteLong(symnode->symvalue, objfile)
                         LD   A,symtree_symname
                         CALL Read_pointer
                         XOR  A
                         CALL Read_byte
                         LD   C,A
                         INC  C
                         LD   DE,0
                         JP   Write_string                  ; fwrite( symnode->symname, objfile)



; **************************************************************************************************
;
; Store library references to object file
;
;    IN: BHL = pointer to current node in symbol tree
;
.StoreLibReference
                    LD   A, symtree_type
                    CALL Read_byte                ; {symnode->type}
                    BIT  SYMTOUCHED,A
                    RET  Z
                    BIT  SYMXREF,A
                    RET  Z
                    BIT  SYMDEF,A                 ; if ( (symnode->type & SYMXREF) &&
                    RET  Z                        ; (symnode->type & SYMDEF) && (node->type & SYMTOUCHED) )
                         LD   A,symtree_symname
                         CALL Read_pointer
                         XOR  A
                         CALL Read_byte
                         LD   C,A
                         INC  C
                         LD   DE,0
                         JP   Write_string             ; fwrite( symnode->symname, objfile)

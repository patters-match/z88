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

     MODULE Read_expressions

; external procedures:

     LIB Read_word, Read_pointer, Set_word, Read_byte
     LIB Set_pointer, Read_long, Set_long, Set_byte

     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF GetSym                                            ; prsline.asm
     XREF CurrentFileName                                   ; srcfile.asm
     XREF CurrentModule                                     ; module.asm
     XREF ParseNumExpr, RemovePfixList                      ; parsexpr.asm
     XREF EvalPfixExpr                                      ; evalexpr.asm
     XREF GetPointer, GetVarPointer                         ; varptr.asm
     XREF ModuleBaseAddr                                    ; modlink.asm
     XREF Add32bit                                          ; add32bit.asm
     XREF Display_integer                                   ; z80pass1.asm
     XREF Keyboard_Interrupt                                ; z80asm.asm

     XREF Open_file, ftell, fseek, Read_fptr, Write_fptr    ; fileio.asm
     XREF Close_file, Read_string

     XREF Test_32bit_range, Test_16bit_range                ; exprs.asm
     XREF Test_8bit_range, Test_7bit_range


; routines accessible in this module:
     XDEF ModuleExpressions


     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "fpp.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
; Evaluate object module expressions and patch constants and relocated addresses
; into the executable machine code file (cdefile)
;
;    IN:  None.
;    OUT: None.
;
.ModuleExpressions  LD   HL, link2_msg
                    CALL_OZ(Gn_Sop)                         ; puts("Pass2...")

                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-8
                    ADD  IX,SP
                    LD   SP,IX
                    PUSH HL                                 ; preserve pointer to RETurn address
                    LD   (IX+6),0
                    LD   (IX+7),0                           ; evaluated expressions counter

                    LD   HL,linkhdr
                    CALL GetVarPointer
                    LD   A,linklist_firstmod
                    CALL Read_pointer
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   (IX+2),B                           ; curlink = linkhdr->firstlink

.eval_modules_loop  CALL Keyboard_Interrupt                 ; Keyboard_Interrupt()
                    JP   Z, exit_evalexprs                  ; abort-keys pressed, abort linking...
                    PUSH BC
                    PUSH HL
                    LD   A, linkedmod_module
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL                              ; curlink->moduleinfo in CDE
                    LD   HL, CURMODULE
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer                        ; CURRENTMODULE = curlink->moduleinfo
                    POP  HL
                    POP  BC
                    LD   A, linkedmod_modstart
                    CALL Read_long
                    EXX
                    LD   (IX+3),C
                    LD   (IX+4),B
                    LD   (IX+5),E                           ; fptr_base = curlink->modulestart
                    EXX
                    PUSH IX                                 ; preserve pointer to local variables
                    LD   A, linkedmod_objfname
                    CALL Read_pointer                       ; BHL = curlink->objfname
                    INC  HL
                    LD   A, OP_IN
                    CALL Open_file                          ; if ( (objfile = fopen(curlink->objfname, "r")) == NULL)
                    POP  DE
                    CALL C, ReportError_NULL                     ; ReportError_NULL()
                    JP   C, exit_evalexprs                       ; return
                         LD   (objfilehandle),IX            ; else
                         PUSH DE
                         POP  IX                                 ; {restore pointer to local variables}
                         LD   C,(IX+3)
                         LD   B,(IX+4)
                         LD   (longint),BC
                         LD   C,(IX+5)
                         LD   B,0
                         LD   (longint+2),BC                     ; fptr_base at (longint)
                         LD   BC,10
                         LD   DE,0
                         LD   HL, longint
                         CALL Add32bit                           ; longint = fptr_base+10
                         PUSH IX                                 ; {preserve pointer to local variables}
                         LD   IX,(objfilehandle)
                         CALL fseek                              ; fseek(objfile, longint, SEEK_SET)
                         LD   HL, fptr_modname
                         CALL Read_fptr
                         LD   HL, fptr_exprdecl
                         CALL Read_fptr
                         LD   HL, fptr_namedecl
                         CALL Read_fptr
                         LD   HL, fptr_libnames
                         CALL Read_fptr
                         POP  IX

                    LD   A,(fptr_exprdecl+3)                     ; get high byte of file pointer
                    CP   -1
                    JR   Z, get_next_link                        ; if ( fptr_exprdecl != -1 )
                         LD   C,(IX+3)
                         LD   B,(IX+4)
                         LD   E,(IX+5)
                         LD   D,0
                         LD   (longint),BC
                         LD   (longint+2),DE                     ; fptr_base at (longint)
                         LD   BC,(fptr_exprdecl)
                         LD   DE,(fptr_exprdecl+2)
                         LD   HL, longint
                         CALL Add32bit                                ; longint = fptr_base + fptr_exprdecl
                         PUSH IX
                         LD   IX,(objfilehandle)
                         LD   B,0                                     ; {filepointer at beginning of expressions}
                         CALL fseek                                   ; fseek(objfile, longint, SEEK_SET)
                         POP  IX                                      ; {restore pointer to local variables}
                         EXX
                         LD   C,(IX+6)
                         LD   B,(IX+7)                                ; set up counter parameter for .ReadExpression call
                         EXX
                         LD   HL,(fptr_exprdecl)
                         LD   A,(fptr_exprdecl+2)
                         LD   B,A                                     ; BHL = fptr_exprdecl
                         LD   A,(fptr_namedecl+3)
                         CP   -1
                         JR   Z, check_libnameptr                     ; if ( fptr_namedecl != -1 )
                              LD   DE,(fptr_namedecl)
                              LD   A,(fptr_namedecl+2)
                              LD   C,A
                              CALL ReadExpressions                         ; ReadExpr(fptr_exprdecl, fptr_namedecl, exprcounter)
                              JR   continue_next_link                 ; else
.check_libnameptr             LD   A,(fptr_libnames+3)
                              CP   -1
                              JR   Z, read_until_modname                   ; if ( fptr_libnames != -1 )
                                   LD   DE,(fptr_libnames)
                                   LD   A,(fptr_libnames+2)
                                   LD   C,A
                                   CALL ReadExpressions                         ; ReadExpressions(fptr_exprdecl, fptr_libnames, exprcounter)
                                   JR   continue_next_link                 ; else
.read_until_modname                LD   DE,(fptr_modname)
                                   LD   A,(fptr_modname+2)
                                   LD   C,A
                                   CALL ReadExpressions                         ; ReadExpressions(fptr_exprdecl, fptr_modname, exprcounter)
.continue_next_link LD   (IX+6),C
                    LD   (IX+7),B                                ; updated expression counter from .ReadExpression

.get_next_link      LD   HL, objfilehandle
                    CALL Close_file                              ; fclose(objfile)

                    LD   L,(IX+0)
                    LD   H,(IX+1)
                    LD   B,(IX+2)
                    LD   A, linkedmod_nextlink
                    CALL Read_pointer
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   (IX+2),B                                ; curlink = curlink->nextlink
                    INC  B
                    DEC  B
                    JP   NZ, eval_modules_loop              ; while ( curlink != NULL )

.exit_evalexprs     POP  HL
                    LD   SP,HL                              ; restore pointer at RETurn address
                    RET

.link2_msg          DEFM 1, "2H5Pass2...", 10, 13, 0



; **************************************************************************************************
;
; Evaluate expressions in objfile and patch into z80 executable code file
;
;    IN:  BHL = nextexpr, relative file pointer to start of object module names
;         CDE = endexprs, relative file pointer to end of object module names
;         bc  = current expression counter
;    OUT: BC  = updated expression counter
;
;    Local variables on stack, defined by IX:
;         (IX+0,2) = nextexpr
;         (IX+3,5) = endexprs
;         (IX+6,7) = expression counter
;
;    Registers changed after return:
;         ......../IXIY  same
;         AFBCDEHL/....  different
;
.ReadExpressions    PUSH IX
                    EXX
                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-8
                    ADD  IX,SP
                    LD   SP,IX
                    PUSH HL                       ; preserve pointer to original IX
                    LD   (IX+6),C
                    LD   (IX+7),B                 ; store current expression counter
                    EXX
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   (IX+2),B                 ; preserve nextexpr filepointer
                    LD   (IX+3),E
                    LD   (IX+4),D
                    LD   (IX+5),C                 ; preserve endexpr filepointer

.while_evalexpr     PUSH IX                       ; {preserve pointer to local variables}

                    LD   IX,(objfilehandle)
                    CALL_OZ(Os_Gb)                ; type = fgetc(objfile)
                    PUSH AF                       ; {preserve type}
                    CALL_OZ(Os_Gb)
                    LD   E,A
                    CALL_OZ(Os_Gb)
                    LD   D,A                      ; offsetptr
                    PUSH DE                       ; {preserve offsetptr}

                    CALL ModuleBaseAddr           ; ASMPC = modulehdr->first->origin + CURRENTMODULE->startoffset
                    LD   H,B
                    LD   L,C
                    ADD  HL,DE
                    LD   (asm_pc),HL              ; ASMPC += offsetptr
                    LD   HL, asm_pc_ptr
                    CALL GetVarPointer
                    INC  B
                    DEC  B
                    JR   Z, readexpr_continue     ; if (asm_pc_ptr != NULL)
                         EXX
                         LD   DE,0
                         LD   BC,(asm_pc)
                         EXX
                         LD   A, symtree_symvalue
                         CALL Set_long                 ; asm_pc_ptr->symvalue = ASMPC

.readexpr_continue  CALL CurrentModule
                    LD   A, module_startoffset
                    CALL Read_word
                    POP  HL
                    ADD  HL,DE
                    LD   (longint),HL             ; {patchptr is only 16bit wide}
                    LD   HL,0
                    LD   (longint+2),HL           ; patchptr = CURRENTMODULE->startoffset + offsetptr

                    CALL_OZ(OS_Gb)                ; exprlen = fgetc(objfile)
                    INC  A                        ; ++exprlen, incl. null terminator
                    LD   C,A
                    LD   B,0                      ; local pointer...
                    LD   HL, linebuffer
                    DEC  A
                    LD   (HL),A                   ; remember length of string (excl. null-terminator)
                    INC  HL
                    LD   (lineptr),HL             ; lineptr = linebuffer+1
                    CALL Read_string              ; fgets(objfile, linebuffer+1, strlen)

                    POP  AF                       ; restore type
                    POP  IX
                    PUSH IX                       ; preserve pointer to local variables

                    LD   HL, 1+1+1+1
                    ADD  HL,BC
                    LD   C,(IX+0)
                    LD   B,(IX+1)
                    ADD  HL,BC                    ; nextexpr += 1+1+1+1+exprlen
                    LD   (IX+0),L
                    LD   (IX+1),H
                    JR   NC, parse_expr
                         INC  (IX+2)              ; correct for overflow...

.parse_expr         LD   C,A                      ; type
                    CALL Getsym                   ; Getsym()
                    CALL ParseNumExpr             ; pfixexpr = ParseNumExpr()
                    JP   C, exprmsg_err           ; if ( pfixexpr != NULL )
                         LD   A, expr_rangetype
                         CALL Read_byte
                         LD   E,A
                         AND  NOTEVALUABLE
                         JR   Z, evaluate_expr         ; if ( pfixexpr->rangetype & NOTEVALUABLE )
                              CALL RemovePfixList
                              LD   A, ERR_not_Defined
                              JP   evalexpr_error  ; else

.evaluate_expr                LD   A,C
                              LD   C,E
                              PUSH AF                       ; {preserve expression type in A}
                              PUSH BC                       ; {preserve rangetype in C}
                              PUSH HL                       ; {preserve pfixexpr}
                              CALL EvalPfixExpr             ; const = EvalPfixExpr(pfixexpr)

                              POP  DE
                              POP  BC
                              PUSH BC                       ; {preserve rangetype}
                              PUSH HL
                              EXX
                              PUSH HL                       ; {preserve const}
                              EXX
                              EX   DE,HL                    ; BHL = pointer to postfix expression
                              CALL RemovePfixList
                              EXX
                              POP  HL
                              EXX
                              POP  HL
                              POP  DE                       ; {rangetype restored in E}
                              LD   BC,0                     ; {const restored in HLhlC}

                              LD   IX,(cdefilehandle)       ; get handle for binfile (compiled machine code file)

                              POP  AF
                              CP   'U'                      ; switch(type)
                              JR   NZ, evalexpr_8sign            ; case RANGE_8UNSIGN:
                                   CALL Test_8bit_range               ; if (const>=0 && const<=255)
                                   JR   C, evalexpr_range_err
                                        EXX
                                        PUSH HL                            ; {preserve const}
                                        EXX
                                        LD   B,0                           ; {local pointer}
                                        LD   HL,longint
                                        CALL fseek                         ; fseek(binfile, patchptr, SEEK_SET)
                                        POP  HL
                                        LD   A,L
                                        CALL_OZ(Os_Pb)                     ; fputc(binfile, const)
                                        JR   evalexpr_endwhile        ; else
                                                                           ; ReportError(7)
.evalexpr_8sign               CP   'S'                           ; case RANGE_8SIGN:
                              JR   NZ, evalexpr_16const
                                   CALL Test_7bit_range               ; if (const>=-128 && const<=127)
                                   JR   C, evalexpr_range_err
                                        EXX
                                        PUSH HL                            ; {preserve const}
                                        EXX
                                        LD   B,0                           ; {local pointer}
                                        LD   HL,longint
                                        CALL fseek                         ; fseek(binfile, patchptr, SEEK_SET)
                                        POP  HL
                                        LD   A,L
                                        CALL_OZ(Os_Pb)                     ; fputc(binfile, const)
                                        JR   evalexpr_endwhile        ; else
                                                                           ; ReportError(7)
.evalexpr_16const             CP   'C'                           ; case RANGE_16CONST:
                              JR   NZ, evalexpr_32sign
.patch_16const                     CALL Test_16bit_range              ; if (const>=0 && const<=65535)
                                   JR   C, evalexpr_range_err
                                        EXX
                                        PUSH HL                            ; {preserve const}
                                        EXX
                                        LD   B,0                           ; {local pointer}
                                        LD   HL,longint
                                        CALL fseek                         ; fseek(binfile, patchptr, SEEK_SET)
                                        POP  HL
                                        LD   A,L                           ; fputc(binfile, const%256)
                                        CALL_OZ(Os_Pb)
                                        LD   A,H
                                        CALL_OZ(Os_Pb)                     ; fputc(binfile, const/256)

                                        BIT  autorelocate,(IY + RTMflags2)
                                        CALL NZ, RelocationAddress         ; if (autorelocate) RelocationAddress(pfixexpr->type, const)
                                        JR   evalexpr_endwhile        ; else
                                                                           ; ReportError(7)

.evalexpr_32sign              CALL Test_32bit_range              ; case RANGE_32SIGN:
                              JR   C, evalexpr_range_err              ; if (const>=LONG_MIN && const<=LONG_MAX)
                                   PUSH HL
                                   EXX
                                   PUSH HL                                 ; {preserve const}
                                   EXX
                                   LD   B,0                                ; {local pointer}
                                   LD   HL,longint
                                   CALL fseek                              ; fseek(binfile, patchptr, SEEK_SET)
                                   POP  HL
                                   LD   (longint),HL
                                   POP  HL
                                   LD   (longint+2),HL
                                   LD   HL,longint
                                   CALL Write_fptr                         ; WriteLong(binfile, const)
                                   JR   evalexpr_endwhile             ; else
                                                                           ; ReportError(7)
.evalexpr_range_err           LD   A, ERR_range
.evalexpr_error               CALL CurrentFileName
                              LD   DE,0
                              CALL ReportError

.exprmsg_err                  CALL ExprMsg

.evalexpr_endwhile       POP  IX                            ; {restore pointer to local variables}

                         LD   C,(IX+6)
                         LD   B,(IX+7)
                         INC  BC
                         LD   (IX+6),C
                         LD   (IX+7),B
                         CALL Display_integer               ; display total number of expressions evaluated.

                         LD   A,(IX+5)
                         CP   (IX+2)
                         JR   C, exit_evalexpr
                         LD   L,(IX+3)
                         LD   H,(IX+4)
                         LD   C,(IX+0)
                         LD   B,(IX+1)
                         SBC  HL,BC
                         JR   C, exit_evalexpr
                         JR   Z, exit_evalexpr
                         JP   while_evalexpr                ; while ( nextexpr < endexprs )

.exit_evalexpr      LD   C,(IX+6)
                    LD   B,(IX+7)
                    POP  HL
                    LD   SP,HL                              ; restore pointer to original IX
                    POP  IX                                 ; return BC = expression counter
                    RET


; ******************************************************************************
;
.ExprMsg            PUSH IX
                    PUSH AF
                    LD   IX, (errfilehandle)
                    LD   B,0
                    LD   HL, err_exprmsg
                    LD   C,(HL)
                    INC  HL
                    LD   DE,0
                    CALL_OZ(Os_Mv)                          ; fprintf(errfile, "Error in expression ")
                    LD   HL, linebuffer
                    LD   C,(HL)
                    INC  HL                                 ; {point at expression}
                    LD   DE,0
                    CALL_OZ(Os_Mv)                          ; fprintf(errfile, linebuffer+1)
                    LD   A,13
                    CALL_OZ(Os_Pb)                          ; fputc(errfile, '\n')
                    POP  AF
                    POP  IX
                    RET
.err_exprmsg        DEFM end_exprmsg - $PC - 1, "Error in expression "
.end_exprmsg



; ******************************************************************************
;
;    Add a relocation element to table
;
.RelocationAddress  BIT  symaddr,E
                    RET  Z                        ; if ( rangetype & SYMADDR )

                    PUSH IX
                    LD   IX,(relocfilehandle)
                    LD   HL,(asm_pc)
                    LD   DE,(curroffset)
                    CP   A
                    SBC  HL,DE                         ; offset = asm_pc-curroffset
                    JR   C, offset_16bit
                    XOR  A
                    OR   H
                    JR   NZ, offset_16bit              ; if ( offset>=0 && offset<=255 )
                         LD   A,L
                         CALL_OZ(OS_Pb)                     ; *relocptr++ = offset
                         LD   DE, 1                         ; ++size_reloctable
                         JR   update_relocvars         ; else
.offset_16bit            XOR  A
                         CALL_OZ(OS_Pb)                     ; *relocptr++ = 0
                         LD   A,L
                         CALL_OZ(OS_Pb)                     ; *relocptr++ = offset % 256
                         LD   A,H
                         CALL_OZ(OS_Pb)                     ; *relocptr++ = offset / 256
                         LD   DE, 3                         ; size_reloctable += 3

.update_relocvars   POP  IX
                    LD   HL,(size_reloctable)
                    ADD  HL,DE
                    LD   (size_reloctable),HL
                    LD   HL,(totaladdr)
                    INC  HL
                    LD   (totaladdr),HL                ; ++totaladdr
                    LD   HL,(asm_pc)
                    LD   (curroffset),HL               ; curroffset = .asmpc
                    RET

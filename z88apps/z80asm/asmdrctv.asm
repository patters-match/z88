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
; This module contains logic control for various assembler directives
;

     MODULE Assembler_directives


; external procedures:
     LIB Read_byte, Read_word, Set_word, Read_pointer
     LIB Set_pointer, Set_long, Read_long
     LIB AllocIdentifier, CmpPtr, memcompare
     LIB mfree

     XREF ReportError_STD, STDerr_syntax, STDerr_ill_ident  ; errors.asm
     XREF ReportError, ReportError_NULL                     ;

     XREF CurrentFile, CurrentFileName                      ; srcfile.asm
     XREF NewFile, PrevFile                                 ;
     XREF Display_filename                                  ;

     XREF ExprUnsigned8, ExprAddress, ExprLong              ; exprs.asm
     XREF Test_16bit_range                                  ;

     XREF asm_pc_p1, asm_pc_p2, asm_pc_p4                   ; z80pass1.asm

     XREF DefineSymbol, DefineDefSym, NULL_pointer          ; symbols.asm
     XREF DeclSymExtern, DeclSymGlobal, cmpIDstr            ;

     XREF GetConstant                                       ; getconst.asm
     XREF Getsym, CheckRegister8, IndirectRegisters         ; prsline.asm
     XREF SearchID                                          ; prsident.asm
     XREF WriteByte, WriteWord, Flushbuffer                 ; bytesio.asm
     XREF ParseNumExpr                                      ; parsexpr.asm
     XREF EvalPfixExpr                                      ; evalexpr.asm
     XREF RemovePfixlist                                    ; rmpfixlist.asm
     XREF GetVarPointer                                     ; z80asm.asm
     XREF CurrentModule                                     ; module.asm
     XREF Open_file, Close_file, Copy_file, ftell, fseek    ; fileio.asm
     XREF Z80pass1, FetchLine                               ; z80pass1.asm
     XREF Init_sourcefile                                   ; asmsrcfiles.asm

; global procedures:
     XDEF DEFS_fn, ORG_fn, BINARY_fn, DeclModule
     XDEF DEFC_fn, DEFB_fn, DEFW_fn, DEFL_fn, DEFM_fn
     XDEF DEFGROUP_fn, DEFVARS_fn, DS_fn, DEFINE_fn, XLIB_fn, LIB_fn
     XDEF INCLUDE_fn, XDEF_fn, XREF_fn
     XDEF ELSE_fn, ENDIF_fn

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "fpp.def"
     INCLUDE "integer.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"



; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.INCLUDE_fn         CALL FetchFileName            ; {read filename into stringconst}
                    LD   HL,(buffer_end)
                    LD   DE,(nextline)
                    CP   A
                    SBC  HL,DE                    ; get distance between next line and buffer end
                    PUSH HL                       ; (the current file pointer is set at buffer end)
                    CALL CurrentFile
                    LD   A, srcfile_filepointer
                    CALL Read_long                ; CURRENTFILE->filepointer
                    EXX
                    LD   H,B
                    LD   L,C
                    POP  BC
                    CP   A
                    SBC  HL,BC                    ; CURRENTFILE->filepointer -= distance
                    LD   B,H
                    LD   C,L
                    EX   DE,HL
                    LD   DE,0
                    SBC  HL,DE                    ; {adjust high word}
                    EX   DE,HL                    ; DEBC = file pointer to beginning of next line
                    EXX
                    LD   A, srcfile_filepointer
                    CALL Set_long
                    LD   HL, srcfilehandle
                    CALL Close_file               ; fclose(z80asmfile)
                    LD   B,0
                    LD   HL, stringconst+1        ; {pointer to local string}
                    LD   A, OP_IN
                    CALL Open_file                ; if ( (z80asmfile = fopen(ident,"r") == NULL )
                    JR   NC, inclfile_opened
                         LD   A, ERR_file_open
                         CALL ReportError_STD          ; reporterror(0)
                         CALL CurrentFileName          ; {BHL points at filename}
                         INC  HL                       ; file name after length byte
                         LD   A,OP_IN
                         CALL Open_file                ; z80asmfile = fopen( CURRENTFILE->fname, "r" )
                         LD   (srcfilehandle),IX
                         CALL CurrentFile
                         CALL Init_sourcefile
                         LD   DE, srcfile_filepointer
                         JP   fseek                    ; fseek(z80asmfile, CURRENTFILE->filepointer, SEEK_SET)
                                                 ; else

.inclfile_opened         LD   (srcfilehandle),IX       ; {DE points at explicit filename}
                         CALL CurrentFile              ; sourcefile_open = 1
                         CALL NewFile                  ; nfile = NewFile(CURRENTFILE, ident)
                         CALL CurrentModule
                         LD   A, module_cfile
                         CALL Set_pointer              ; CURRENTFILE = nfile
                         CALL Init_sourcefile          ; reset current source file pointer and buffer pointers
                         SET  srcfile_open,(IY + RTMflags3)
                         LD   A,(ASSEMBLE_ERROR)
                         CP   ERR_no_room
                         RET  Z                        ; if ( ASSEMBLE_ERROR == 3) return

                         CALL CurrentFileName
                         INC  HL                       ; file name after length byte
                         CALL Display_filename         ; puts(CURRENTFILE->fname)

                         CALL Z80pass1                 ; Z80pass1()
                         CALL PrevFile                 ; pfile = PrevFile()
                         CALL CurrentModule
                         LD   A, module_cfile
                         CALL Set_pointer              ; CURRENTFILE = pfile
                         LD   A,(ASSEMBLE_ERROR)       ; switch(ASSEMBLE_ERROR)
                         CP   ERR_file_open                 ; case 0: return
                         RET  Z
                         CP   ERR_no_room                   ; case 3: return
                         RET  Z
                         CP   ERR_max_codesize              ; case 12: return
                         RET  Z
                         LD   HL, srcfilehandle
                         CALL Close_file               ; sourcefile_open = fclose(z80asmfile)
                         RES  srcfile_open,(IY + RTMflags3)
                         CALL CurrentFileName          ; {BHL points at filename}
                         INC  HL                       ; file name begins after length byte
                         LD   A,OP_IN
                         CALL Open_file                ; z80asmfile = fopen( CURRENTFILE->fname, "r" )
                         JR   NC, inclfile_opened2     ; if ( z80asmfile == NULL )
                              CALL NULL_pointer
                              LD   DE,0
                              LD   A,ERR_file_open
                              CALL ReportError              ; reporterror(null, 0, 3)
                              JR   end_include         ; else
.inclfile_opened2             CALL Init_sourcefile
                              SET  srcfile_open,(IY + RTMflags3)
                              LD   (srcfilehandle),IX       ; sourcefile_open = 1
                              CALL CurrentFile
                              LD   DE, srcfile_filepointer
                              CALL fseek                    ; fseek(z80asmfile, CURRENTFILE->filepointer, SEEK_SET)
.end_include        LD   A,sym_newline
                    LD   (sym),A
                    RES  EOF,(IY + RTMflags3)
                    RET


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFGROUP_fn        LD   BC,0                     ; enumconst = 0

.defgroup_lcurly    BIT  EOF, (IY + RTMflags3)    ; while ( !eof(z80asmfile) && Getsym() != lcurly )
                    RET  NZ
                    CALL Getsym
                    CP   sym_lcurly
                    JR   Z, defgroup_begin
                         CALL FetchLine           ; FetchLine()
                         JR   defgroup_lcurly
.defgroup_begin
.fetchgroup_loop    BIT  EOF, (IY + RTMflags3)    ; while ( !eof(z80asmfile) )
                    RET  NZ                            ; do
.fetchgroup_items        CALL Getsym                        ; Getsym()
                         CP   sym_rcurly                    ; switch(sym)
                         RET  Z                                  ; case rcurly: return

                         CP   sym_semicolon
                         JR   Z, defgroup_newline
                         CP   sym_newline                        ; case semicolon:
                         JR   NZ, defgroup_name                  ; case newline:      FetchLine()
.defgroup_newline             CALL FetchLine                     ;                   break
                              JR   fetchgroup_loop

.defgroup_name           CP   sym_name
                         JR   NZ, defgroup_default               ; case name:
                              CALL Copy_ident                                   ; strcpy(stringconst, ident)
                              CALL Getsym
                              CP   sym_assign                                   ; if ( Getsym() == assign )
                              JR   NZ, define_groupname
                                   CALL Getsym                                       ; Getsym()
                                   CALL ParseNumExpr
                                   RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                                        LD   A,expr_rangetype
                                        CALL Read_byte
                                        AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                                        JR   Z, evaluate_enumconst
                                             LD   A, ERR_not_defined
                                             CALL ReportError_STD                    ; reporterror(*, *, 2)
                                             JP   RemovePfixList
                                                                                ; else
.evaluate_enumconst                          PUSH BC
                                             PUSH HL
                                             CALL EvalPfixExpr                       ; enumconst = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                                             POP  HL
                                             POP  BC                                 ; { get pointer to postfix expression }
                                             EXX
                                             PUSH HL                                 ; { preserve enumconst }
                                             EXX
                                             CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                                             POP  BC
.define_groupname             PUSH BC                                      ; {preserve enumconst}
                              LD   HL, stringconst
                              LD   DE,0
                              XOR  A
                              CALL DefineSymbol                            ; DefineSymbol(stringconst, enumconst, 0)
                              POP  BC
                              INC  BC                                      ; enumconst++
                              JR   defgroup_nextitem

.defgroup_default        CALL STDerr_syntax                      ; default:  Reporterror(1)

.defgroup_nextitem  LD   A,(sym)
                    CP   sym_comma
                    JR   Z, fetchgroup_items           ; while ( sym == comma )
                    CP   sym_rcurly
                    RET  Z                             ; if ( sym == rcurly ) return
                    CALL FetchLine
                    JR   fetchgroup_loop


; **************************************************************************************************
;
;    Parse Define Space directive, and return size identifier in A
;    If size identifier found, Fz = 1, otherwise Fz = 0
;
; Registers changed after return:
;    ..BCDEHL/IXIY
;    AF....../....
;
.DS_fn              CALL Getsym                   ; if ( Getsym() == fullstop )
                    CP   sym_fullstop
                    JP   NZ, STDerr_syntax
                    CALL Getsym                        ; if ( Getsym() == name )
                    CP   sym_name
                    JP   NZ, STDerr_syntax
                         LD   A, (Ident+1)                  ; switch( ident[0] )
                         CP   'B'
                         JR   NZ, check_wordsize
                              LD   A,1
                              RET                                ; case 'B': return 1
.check_wordsize          CP   'W'
                         JR   NZ, check_ptrsize
                              LD   A,2
                              RET                                ; case 'W': return 2
.check_ptrsize           CP   'P'
                         JR   NZ, check_longsize
                              LD   A,3
                              RET                                ; case 'P': return 3
.check_longsize          CP   'L'
                         RET  NZ
                              LD   A,4
                              RET                                ; case 'L': return 4



; ******************************************************************************
;
;    Check whether identifier is "DS" or not.
;
.Check_DS_ident     PUSH BC
                    LD   HL, Ident+1
                    LD   DE, DS_mnem
                    LD   BC,3
                    CALL memcompare                                   ; if ( strcmp(Ident, "DS") != 0 )
                    POP  BC
                    RET
.DS_mnem            DEFM "DS", 0



; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFVARS_fn         CALL Getsym
                    CALL ParseNumExpr
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, defvars_evalexpr
                              LD   A, ERR_not_defined                 ; reporterror(*, *, 2)
                              CALL ReportError_STD                    ; break
                              JP   RemovePfixList
                                                                 ; else
.defvars_evalexpr             PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              POP  HL
                              POP  BC                                 ; BHL = pointer to expression
                              EXX
                              PUSH HL                                 ; preserve evaluated offset
                              EXX
                              CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                              POP  HL                                 ; HL = offset

.defvars_lcurly     BIT  EOF, (IY + RTMflags3)    ; while ( !eof(z80asmfile) && Getsym() != lcurly )
                    RET  NZ
                    LD   A,(sym)
                    CP   sym_lcurly
                    JR   Z, defvars_begin
                         CALL FetchLine               ; FetchLine()
                         CALL GetSym                  ; Getsym()
                         JR   defvars_lcurly
.defvars_begin
.fetchvar_loop      BIT  EOF, (IY + RTMflags3)    ; while ( !eof(z80asmfile) && Getsym() != rcurly )
                    RET  NZ
                    CALL Getsym
                    CP   sym_rcurly
                    RET  Z
                         LD   B,H
                         LD   C,L
                         CALL ParseDefvarsize
                         ADD  HL,BC                    ; offset += ParseDefvarsize(offet)
                         CALL Fetchline                ; Fetchline()
                    JR   fetchvar_loop


; **************************************************************************************************
;
;    Parse the DEFVARS field name line.
;
;    IN:  BC = current offset
;    OUT: BC = field size (in bytes)
;
.ParseDefvarsize    PUSH DE
                    PUSH HL
                         LD   A,(sym)
                         CP   sym_name                 ; if ( sym == name )
                         JR   NZ, check_sym
                              CALL Check_DS_Ident           ; if ( strcmp(Ident, "DS") != 0 )
                              JR   Z, check_sym
                                   LD   DE,0                     ; {DEBC = offset}
                                   LD   HL, ident
                                   XOR  A
                                   CALL DefineSymbol             ; DefineSymbol( ident, offset, 0)
                                   CALL GetSym                   ; Getsym()
.check_sym               LD   BC,0                    ; fieldsize = 0
                         CP   sym_semicolon           ; switch(sym)
                         JR   Z, exit_parsedefvarsize       ; case semicolon:
                         CP   sym_newline                   ; case newline:
                         JR   Z, exit_parsedefvarsize       ;         break

.check_name              CP   sym_name                      ; case name:
                         JR   NZ, default
                              CALL Parsevarsize                       fieldsize = Parsevarsize()
                              JR   exit_parsedefvarsize
                                                            ; default:
.default                 CALL STDErr_syntax                           ReportError(1)
.exit_parsedefvarsize
                    POP  HL
                    POP  DE                            ; return fieldsize
                    RET


; ***************************************************************************************
;
;    Parse the field size specifier (constant or expression)
;
;    IN:  None.
;    OUT: BC = field size.
;
.Parsevarsize       CALL Check_DS_ident                ; if ( strcmp(ident, "DS") != 0 ) reporterror(11)
                    JP   NZ, STDerr_ill_ident          ; else
                         CALL DS_fn                         ; if ( (varsize = DS()) == -1 )
                         JP   NZ, STDerr_ill_ident               ; ReportError(11)
                              LD   D,0                      ; else
                              LD   E,A                           ; { varsize in DE }
                              CALL Getsym                        ; Getsym()
                              CALL ParseNumExpr
                              RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                                   LD   A,expr_rangetype
                                   CALL Read_byte
                                   AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                                   JR   Z, fieldsize_evalexpr
                                        LD   A, ERR_not_defined
                                        CALL ReportError_STD                    ; reporterror(*, *, 2)
                                        JP   RemovePfixList
                                                                           ; else
.fieldsize_evalexpr                     PUSH DE                                 ; { preserse varsize }
                                        PUSH BC
                                        PUSH HL                                 ; {preserve postfixexpr pointer}
                                        CALL EvalPfixExpr                       ; multiplier = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                                        POP  HL
                                        POP  BC                                 ; { get pointer to postfix expression }
                                        EXX
                                        PUSH HL                                 ; { preserve multiplier }
                                        EXX
                                        CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                                        POP  HL                                 ; { multiplier }
                                        POP  DE                                 ; { varsize }
                                        CALL_OZ(Gn_M16)                         ; fieldsize = varsize * multiplier

                    LD   B,H
                    LD   C,L                           ; return fieldsize
                    RET


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFS_fn            CALL Getsym                             ; Getsym()
                    CALL ParseNumExpr
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, ds_evalexpr
                              LD   A, ERR_not_defined
                              CALL ReportError_STD                    ; reporterror(*, *, 2)
                              JP   RemovePfixList                ; else
.ds_evalexpr                  PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              CALL Test_16bit_range                   ; if ( const<0 || const>65535 )
                              JR   NC, define_storage                      ; reporterror(7)
                                   LD   A,Err_range
                                   CALL ReportError_STD
                                   JR   end_ds                        ; else
.define_storage                    EXX
                                   PUSH HL
                                   EXX
                                   POP  DE
                                   LD   HL,(asm_pc)
                                   ADD  HL,DE                              ; PC += const
                                   LD   (asm_pc),HL
.ds_loop                           LD   A,D                                ; while ( const-- )
                                   OR   E
                                   JR   Z, end_ds
                                        LD   C,0
                                        CALL WriteByte                     ; *codeptr++ = 0
                                        DEC  DE
                                   JR   ds_loop
.end_ds                  POP  HL
                         POP  BC
                         JP   RemovePfixList                     ; RemovePfixList(postfixexpr)


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFC_fn                                               ; do
.defc_loop          CALL Getsym                             ; Getsym()
                    CP   sym_name                           ; if ( Getsym != name )
                    JP   NZ, STDerr_syntax                       ; reporterror(1)
                         CALL Copy_ident                    ; else
                         CALL Getsym                             ; strcpy(stringconst,ident)
                         CP   sym_assign                         ; if ( Getsym != assign )
                         JP   NZ, STDerr_syntax                       ; ReportError(1)
                              CALL Getsym
                              CALL ParseNumExpr                  ; else
                              RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                                   LD   A,expr_rangetype
                                   CALL Read_byte
                                   AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                                   JR   Z, defc_evalexpr
                                        LD   A, ERR_not_defined                 ; reporterror(*, *, 2)
                                        CALL ReportError_STD                    ; break
                                        JP   RemovePfixList
                                                                           ; else
.defc_evalexpr                          PUSH BC
                                        PUSH HL                                 ; {preserve postfixexpr pointer}
                                        CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                                        EX   DE,HL
                                        EXX
                                        PUSH HL
                                        EXX
                                        POP  BC                                 ; {const = DEBC}
                                        LD   HL, stringconst
                                        LD   A, 0
                                        CALL DefineSymbol                       ; DefineSymbol(stringconst, const, SYMCONST)

.defc_remvexpr                     POP  HL
                                   POP  BC
                                   CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                    LD   A,(sym)
                    CP   sym_comma
                    JR   Z, defc_loop                  ; while ( sym == comma )
                    RET


; **************************************************************************************************
;
; Copy ident into stringconst
;
.Copy_ident         PUSH HL
                    PUSH DE
                    PUSH BC
                    LD   HL, Ident
                    LD   DE, stringconst
                    LD   B,0
                    LD   C,(HL)
                    INC  C                        ; length identifier + string
                    INC  C                        ; + null-terminator
                    LDIR                          ; strcpy(stringconst,ident)
                    POP  BC
                    POP  DE
                    POP  HL
                    RET


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFINE_fn                                             ; do
.define_loop        CALL Getsym                             ; if ( Getsym() != name )
                    CP   sym_name                                ; ReportError(1)
                    JP   NZ, STDerr_syntax                  ; else
                         LD   HL,Ident
                         CALL AllocIdentifier                    ; tmpident to extended memory, BHL = ident
                         JP   C, ReportError_NULL
                         PUSH BC
                         PUSH HL                                 ; preserve pointer to temporary identifier
                         LD   C,B
                         EX   DE,HL                              ; tmpident in CDE
                         EXX
                         LD   DE,0
                         LD   BC,1
                         EXX
                         CALL CurrentModule
                         PUSH DE
                         LD   DE, module_localroot
                         ADD  HL, DE                             ; &CURRENTMODULE->localroot in BHL
                         POP  DE
                         LD   A,0
                         CALL DefineDefSym                       ; DefineDefSym(tmpident, 1, 0, &CURRENTMODULE->localroot)
                         POP  HL
                         POP  BC
                         CALL mfree                              ; free(tmpident)
                    CALL Getsym
                    CP   sym_comma
                    JR   Z, define_loop                ; while ( sym == comma )
                    RET



; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.ORG_fn             CALL Getsym                             ; Getsym()
                    CALL ParseNumExpr
                    RET  C                                  ; if ( (postfixexpr = ParseNumExpr()) != NULL )
                         LD   A,expr_rangetype
                         CALL Read_byte
                         AND  NOTEVALUABLE                       ; if ( postfixexpr->rangetype & NOTEVALUABLE )
                         JR   Z, org_evalexpr
                              LD   A, ERR_not_defined
                              CALL ReportError_STD                    ; reporterror(*, *, 2)
                              JP   RemovePfixList
                                                                 ; else
.org_evalexpr                 PUSH BC
                              PUSH HL                                 ; {preserve postfixexpr pointer}
                              CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {returned in HLhlC}
                              CALL Test_16bit_range                   ; if ( const<0 || const>65535 )
                              JR   NC, check_org                           ; reporterror(7)
                                   LD   A,Err_range
                                   CALL ReportError_STD
                                   JR   end_org                       ; else
.check_org                         EXX
                                   PUSH HL                                 ; {preserve ORG}
                                   EXX
                                   CALL CurrentModule                      ; if (CURRENTMODULE->origin==65535  && CURRENTMODULE==modulehdr->first)
                                   LD   A, module_origin
                                   CALL Read_word
                                   LD   A,D
                                   AND  E
                                   CP   -1
                                   JR   NZ, org_defined
.check_module                      PUSH BC
                                   PUSH HL
                                   LD   HL, modulehdr
                                   CALL GetVarPointer
                                   LD   A,modules_first
                                   CALL Read_pointer
                                   LD   A,B
                                   EX   DE,HL
                                   POP  HL
                                   POP  BC                                      ; {CURRENTMODULE in BHL}
                                   LD   C,A                                     ; {modulehdr->first in CDE}
                                   CALL CmpPtr
                                   JR   NZ, org_defined                         ; {CURRENTMODULE != modulehdr->first}
                                        POP  DE
                                        LD   A, module_origin
                                        CALL Set_word                           ; CURRENTMODULE->origin = ORG
                                        JR   end_org
                                                                           ; else
.org_defined                       POP  HL                                      ; {remove redundant const}
                                   LD   A,ERR_org_defined                       ; reporterror(24)
                                   CALL ReportError_STD
.end_org                 POP  HL
                         POP  BC
                         JP   RemovePfixList                     ; RemovePfixList(postfixexpr)



; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFB_fn                                               ; do
.defb_loop          CALL Getsym                             ; Getsym()
                    CALL ExprUnsigned8
                    RET  C                                  ; if ( !ExprUnsigned8(bytepos) ) break
                         CALL asm_pc_p1                     ; ++PC
                         LD   A, (sym)                      ; if (sym == newline || sym == semicolon)
                         CP   sym_semicolon
                         RET  Z
                         CP   sym_newline                        ; break
                         RET  Z                             ; else
                              CP   sym_comma                     ; if (sym != comma)
                              JP   NZ, STDerr_syntax                  ; ReportError(..., 1)
                                                                      ; break
                    JR   defb_loop                     ; while ( sym == comma )


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFW_fn                                               ; do
.defw_loop          CALL Getsym                             ; Getsym()
                    CALL ExprAddress
                    RET  C                                  ; if ( !ExprAddress(bytepos) ) break
                         CALL asm_pc_p2                     ; PC += 2
                         LD   A, (sym)                      ; if (sym == newline || sym == semicolon)
                         CP   sym_semicolon
                         RET  Z
                         CP   sym_newline                        ; break
                         RET  Z                             ; else
                              CP   sym_comma                     ; if (sym != comma)
                              JP   NZ, STDerr_syntax                  ; ReportError(..., 1)
                                                                      ; break
                    JR   defw_loop                     ; while ( sym == comma )


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFL_fn                                               ; do
.defl_loop          CALL Getsym                             ; Getsym()
                    CALL ExprLong
                    RET  C                                  ; if ( !ExprLong(bytepos) ) break
                         CALL asm_pc_p4                     ; PC += 4

                         LD   A, (sym)                      ; if (sym == newline || sym == semicolon)
                         CP   sym_semicolon
                         RET  Z
                         CP   sym_newline                        ; break
                         RET  Z                             ; else
                              CP   sym_comma                     ; if (sym != comma)
                              JP   NZ, STDerr_syntax                  ; ReportError(..., 1)
                                                                      ; break
                    JR   defl_loop                     ; while ( sym == comma )


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DEFM_fn
.defm_loop          CALL Getsym                        ; do
                    CP   sym_dquote
                    JR   NZ, defm_expr                      ; if ( Getsym() == dquote )
.defm_string_loop        LD   HL, (lineptr)                      ; while ( (const = *lineptr++) != '"' )
                         LD   A,(HL)
                         INC  HL
                         LD   (lineptr),HL                            ; {const = *lineptr++}
                         CP   LF
                         RET  Z
                         CP   CR
                         REt  Z
                         CP   '"'
                         JR   Z, next_defm_expr
                              LD   C,A
                              CALL WriteByte                          ; *codeptr++ = const
                              CALL asm_pc_p1                          ; ++PC
                              JR   defm_string_loop
.next_defm_expr          CALL Getsym                             ; Getsym()
                         JR   check_defm_expr                    ; if ( sym!=strconq && sym!=newline && sym!=lf && sym!=semicolon )
                                                                      ; reporterror(1)
                                                                      ; return
.defm_expr               CALL ExprUnsigned8                 ; else
                         RET  C                                  ; if ( !ExprUnsigned8(bytepos) ) break
                                                                      ; ++bytepos
                         CALL asm_pc_p1                               ; ++PC
.check_defm_Expr         LD   A,(sym)
                         CP   sym_strconq
                         JR   Z, defm_loop
                         CP   sym_newline
                         RET  Z
                         CP   sym_semicolon                      ; if ( sym!=strconq && sym!=newline && sym!=semicolon )
                         RET  Z
                         JP   STDerr_syntax                           ; reporterror(1)
                                                                      ; return
                                                       ; while ( sym!=newline && sym!=newline )



; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.BINARY_fn          CALL FetchFileName
                    LD   B,0
                    LD   HL,stringconst+1
                    LD   A, OP_IN
                    CALL Open_file                ; binfile = open( ident, O_RDONLY, 0 )
                    JR   NC, binary_continue      ; if ( binfile == NULL )
                         LD   A,ERR_file_open          ; ReportError(0)
                         JP   ReportError_STD          ; return
.binary_continue    LD   (tmpfilehandle),IX
                    LD   A,FA_EXT
                    LD   DE,0
                    CALL_OZ(Os_Frm)               ; fstat(binfile, &filestatus)
                    JP   C, ReportError_STD
                    LD   HL,0
                    PUSH BC
                    EXX
                    POP  DE
                    LD   HL,(asm_pc)              ; HLhlC = asm_pc
                    EXX                           ; DEdeB = filestatus.st_size
                    PUSH BC
                    LD   BC,0
                    FPP  (FP_ADD)                 ; HLhlC + DEdeB
                    CALL Test_16bit_range         ; if ( PC + st_size > 65535 )
                    POP  BC                       ; {size of file}
                    JR   NC, binary_continue2
                         LD   A,ERR_max_codesize
                         CALL ReportError_STD          ; ReportError(12)
                         LD   HL, tmpfilehandle
                         JP   Close_file               ; close(binfile)

.binary_continue2   PUSH BC
                    EXX
                    POP  BC
                    LD   (asm_pc),HL              ; PC += filestatus.st_size
                    LD   HL,(codeptr)
                    ADD  HL,BC                    ; codeptr += filestatus.st_size
                    LD   (codeptr),HL
                    EXX
                    CALL FlushBuffer              ; first write bytes in buffer to 'buffer.tmp'
                    XOR  A                        ; no. of bytes is max. 64K...
                    LD   HL, tmpfilehandle
                    LD   DE, cdefilehandle
                    CALL Copy_file                ; copy(binfile, cdefile, filestatus.st_size)
                    LD   HL, tmpfilehandle
                    JP   Close_file               ; close(binfile)


; ************************************************************************************
;
; Fetch file name in double quotes
;
.FetchFileName      CALL Getsym
                    CP   sym_dquote                    ; if ( Getsym() != dquote )
                    JR   NZ, missing_dquote
                         XOR  A                        ; else
                         LD   HL, stringconst
                         LD   (HL),0
                         LD   BC,(lineptr)
                         LD   D,H
                         LD   E,L
                         INC  DE
                         CALL Defaultpath                   ; insert default path if '#' as first char
.fetch_name_loop              LD   A,250
                              CP   (HL)
                              JR   Z, exit_fetch_name       ; for (l=0; l<250; l++)
                                   LD   A,(BC)
                                   CP   '"'
                                   JR   Z, exit_fetch_name            ; if ( (ident[l] == '"' || ident[l] == '\n' )
                                   CP   LF
                                   JR   Z, exit_fetch_name
                                   CP   CR
                                   JR   Z, exit_fetch_name
                                   INC  BC
                                   LD   (DE),A
                                   INC  DE                                 ; ident[l] = *lineptr++
                                   INC  (HL)
                              JR   fetch_name_loop
.exit_fetch_name              XOR  A
                              LD   (DE),A                   ; null-terminate filename
                              RET

.missing_dquote     POP  HL                            ; {remove this subroutine RET address}
                    JP   STDerr_syntax                 ; reporterror(1)


; **************************************************************************************************
;
;    IN:  BC = pointer to current char (the first of the filename) in source line
;         DE = pointer to beginning of buffer to load fetched filename.
;
;    OUT: DE = points at byte after std. path in buffer, ready for rest of filename
;
.Defaultpath        LD   A,(BC)
                    CP   '#'
                    RET  NZ
                         INC  BC                  ; first char was a '#', replace with std. path
                         PUSH BC                  ; and prepare for next byte of filename
                         PUSH HL
                         LD   BC, 5
                         LD   HL, stdpath
                         LDIR                     ; insert standard path before filename...
                         POP  HL                  ; DE ready for first char of filename
                         POP  BC
                    RET
.stdpath            DEFM ":*//*"



; **************************************************************************************************
;
;    MODULE <name>
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DeclModule         CALL Getsym                   ; Getsym()
                    JP   DeclModuleName           ; DeclModuleName()


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.DeclModuleName     CALL CurrentModule
                    PUSH BC
                    PUSH HL
                    LD   A, module_mname
                    CALL Read_pointer
                    XOR  A
                    CP   B
                    JR   NZ, mname_declared            ; if ( CURRENTMODULE->mname == NULL )
                         POP  HL
                         POP  BC
                         LD   A,(sym)
                         CP   sym_name
                         JP   NZ, STDerr_ill_ident          ; if ( sym == name )
                              PUSH BC
                              PUSH HL
                              LD   HL, Ident
                              CALL AllocIdentifier               ; id = AllocIdentifier()
                              LD   A,B
                              EX   DE,HL
                              POP  HL
                              POP  BC
                              LD   C,A                           ; {BHL= CURRENTMODULE, CDE = id}
                              JR   C, mname_no_room              ; if ( id != NULL )
                                   LD   A, module_mname
                                   JP   Set_pointer                   ; CURRENTMODULE->mname = id
                                                                 ; else
.mname_no_room                     LD   A, ERR_no_room
                                   JP   reportError_STD               ; ReportError(3)
                                                            ; else
                                                                 ; reporterror(11)
.mname_Declared     POP  HL                            ; else
                    POP  BC
                    LD   A, ERR_modname_defined
                    JP   ReportError_STD                    ; Reporterror(15)


; **************************************************************************************************
;
; Conditional assembly ELSE directive
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.ELSE_fn            LD   A,sym_elsestatm
                    LD   (sym),A
                    RET


; **************************************************************************************************
;
; Conditional assembly ENDIF directive
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.ENDIF_fn           LD   A,sym_endifstatm
                    LD   (sym),A
                    RET


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.XDEF_fn
.xdef_loop          CALL Getsym              ; do
                    CP   sym_name
                    JP   NZ, STDerr_syntax        ; if ( Getsym() == name
                         XOR  A
                         CALL DeclSymGlobal            ; DeclSymGlobal(0)
                                                  ; else
                    CALL Getsym                        ; reporterror(1)
                    CP   sym_comma
                    JR   Z, xdef_loop        ; while ( Getsym() == comma )
                    CP   sym_newline
                    RET  Z
                    CP   sym_semicolon       ; if ( sym!=newline && sym!=semicolon )
                    CALL NZ, STDerr_syntax        ; reporterror(1)
                    RET


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.XLIB_fn
                    CALL Getsym              ; do
                    CP   sym_name
                    JP   NZ, STDerr_syntax        ; if ( Getsym() == name
                         CALL DeclModuleName           ; DeclModuleName();
                         LD   A, 2**SYMDEF
                         JP   DeclSymGlobal            ; DeclSymGlobal(SYMDEF)
                                                  ; else
                                                       ; reporterror(1)


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.XREF_fn
.xref_loop          CALL Getsym              ; do
                    CP   sym_name
                    JP   NZ, STDerr_syntax        ; if ( Getsym() == name
                         XOR  A
                         CALL DeclSymExtern            ; DeclSymExtern(0)
                                                  ; else
                    CALL Getsym                        ; reporterror(1)
                    CP   sym_comma
                    JR   Z, xref_loop        ; while ( Getsym() == comma )
                    CP   sym_newline
                    RET  Z
                    CP   sym_semicolon       ; if ( sym!=newline && sym!=semicolon )
                    CALL NZ,STDerr_syntax         ; reporterror(1)
                    RET


; **************************************************************************************************
;
; Registers changed after return:
;    ......../..IY
;    AFBCDEHL/IX..
;
.LIB_fn
.lib_loop           CALL Getsym              ; do
                    CP   sym_name
                    JP   NZ, STDerr_syntax        ; if ( Getsym() == name
                         LD   A, 2**SYMDEF
                         CALL DeclSymExtern            ; DeclSymExtern(SYMDEF)
                                                  ; else
                    CALL Getsym                        ; reporterror(1)
                    CP   sym_comma
                    JR   Z, lib_loop         ; while ( Getsym() == comma )
                    CP   sym_newline
                    RET  Z
                    CP   sym_semicolon       ; if ( sym!=newline && sym!=semicolon )
                    CALL NZ,STDerr_syntax         ; reporterror(1)
                    RET

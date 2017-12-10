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

     MODULE Z80pass1

; library procedures:
     LIB Read_word, Read_long, Read_byte, Read_pointer
     LIB Set_word, Set_long, Set_byte, Set_pointer
     LIB GetVarPointer
     LIB Bind_bank_s1

; external procedures:
     XREF GetSym                                            ; prsline.asm
     XREF PrsIdent                                          ; prsident.asm
     XREF STDerr_ill_ident, STDerr_syntax, ReportError_STD  ; errors.asm
     XREF DefineSymbol                                      ; symbols.asm
     XREF CurrentFile, CurrentFileName, CurrentFileLine     ; srcfile.asm
     XREF ParseNumExpr                                      ; parsexpr.asm
     XREF EvalPfixExpr                                      ; evalexpr.asm
     XREF RemovePfixList                                    ; rmpfixlist.asm
     XREF Write_fptr                                        ; modlink.asm
     XREF CurrentModule                                     ; module.asm
     XREF fseek                                             ; fileio.asm

; routines accessible in this module:
     XDEF Z80pass1, IFstatement
     XDEF Pass2Info, FetchLine
     XDEF Add16bit_1, Add16bit_2, Add16bit_3, Add16bit_4
     XDEF asm_pc_p1, asm_pc_p2, asm_pc_p3, asm_pc_p4

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "integer.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ******************************************************************************
;
; Z80 pass1 - read source file for Z80 mnemonics & directives until EOF.
;
; Registers changed after return:
;
;    ......../..IY  same
;    AFBCDEHL/IX..  different
;
.Z80pass1
.readfile_loop
                    LD   A,(IY + RtmFlags3)            ; while( !eof(z80asmfile) )
                    BIT  EOF,A
                    RET  NZ                            ; {
                         LD   A, flag_ON
                         CALL ParseLine                     ; parseline(ON)

                         LD   A,(ASSEMBLE_ERROR)            ; switch(ASSEMBLE_ERROR)
                         CP   ERR_no_room                        ; case ..: return
                         RET  Z
                         CP   ERR_max_codesize                   ; case ..: return
                         RET  Z
                    JR   readfile_loop                 ; }


; **************************************************************************************************
;
; Parse current source line
;
; IN: A = Interpret flag ( -1 = ON, 0 = OFF ). Flag MUST be local due to recursion
;
.ParseLine
                    PUSH AF                                 ; preserve interpret flag

                    LD   HL,totallines
                    INC  (HL)
                    JR   NC, init_asmpc
                    INC  HL
                    INC  (HL)                               ; ++totallines
.init_asmpc
                    LD   HL, asm_pc_ptr
                    CALL GetVarPointer
                    INC  B
                    DEC  B
                    JR   Z, get_sourceline                  ; if (asm_pc_ptr != NULL)
                         EXX                                     ; asm_pc_ptr->symvalue = ASMPC
                         LD   BC,(asm_pc)
                         LD   D,B
                         LD   E,C
                         EXX
                         LD   A, symtree_symvalue
                         CALL Set_long

.get_sourceline     CALL FetchLine                          ; FetchLine()
                    BIT  EOF,(IY + RtmFlags3)
                    JR   NZ, end_parseline                  ; EOF reached...

                    CALL GetSym                             ; Getsym()
                    CP   sym_fullstop
                    JR   NZ, get_z80mnem                    ; if ( sym == fullstop )
                         POP  AF
                         PUSH AF                                 ; {preserve interpret flag}
                         CP   Flag_ON
                         JR   NZ, ignore_label                   ; if ( interpret == ON )
                              CALL GetSym
                              CP   sym_name
                              JR   NZ, illegal_label                  ; if ( Getsym() == name )
                                   LD   HL, ident                          ; local pointer to current symbol
                                   LD   BC,(asm_pc)                         ; current assembler PC (as long int)
                                   LD   DE,0
                                   LD   A, EXPRADDR | 2**SYMTOUCHED
                                   CALL DefineSymbol                       ; DefineSymbol( ident, ASMPC, SYMADDR | SYMTOUCHED )
                                   CALL GetSym                             ; then read z80 mnemonic
                                   JR   get_z80mnem                        ; and parse mnemonic, if any...
                                                                      ; else
.illegal_label                     CALL STDerr_ill_ident                   ; a name must follow a label declaration
                                   JR   end_parseline
.ignore_label                 LD   A, sym_semicolon
                              LD   (sym),A
.get_z80mnem        LD   A,(sym)
                    CP   sym_name                           ; switch(sym)
                    JR   NZ, continue_switch                ;    case name:      ParseIdent(interpret)
                         POP  AF
                         PUSH AF        ; {interpret flag}
                         CALL PrsIdent
                         JR   end_switch
.continue_switch    CP   sym_newline
                    JR   Z, end_switch                      ;    case newline:   break
                    CP   sym_semicolon
                    JR   Z, end_switch                      ;    case semicolon: break

                    CALL STDerr_syntax                      ;    default:     unknown identifier // syntax error
.end_switch
.end_parseline      POP  AF                                 ; {remove local interpret flag}
                    RET


; **************************************************************************************************
;
; Multilevel conditional assembly logic
;
; IN: A = interpret flag
; OUT: None
;
.IFstatement        CP   Flag_ON
                    JR   NZ, interpret_OFF                  ; if (interpret == ON)   {evaluate #IF expression}
                         CALL Evallogexpr                        ; {return value of expression in DEBC}
                         XOR  A
                         OR   D
                         OR   E
                         OR   B
                         OR   C
                         JR   Z, ifelse_loop2                   ; if ( Evallogexpr() != 0 )
                                                                      ; do
.ifelse_loop1                 BIT  EOF,(IY + RtmFlags3)                    ; if ( eof(z80asmfile) )
                              RET  NZ                                           ; return
                              LD   A,Flag_ON                               ; else
                              CALL ParseLine                                    ; ParseLine(ON)
                              LD   A,(sym)
                              CP   sym_elsestatm
                              JR   Z, break_ifelse_loop1
                              CP   sym_endifstatm
                              JR   Z, break_ifelse_loop1
                              JR   ifelse_loop1                       ; while ( sym!=elsestatm && sym!=endifstatm )
.break_ifelse_loop1           CP   sym_elsestatm
                              JR   NZ, end_ifstatement                ; if (sym == elsestatm)
.elsendif_loop1                                                            ; do
                                   BIT  EOF,(IY + RtmFlags3)                    ; if ( eof(z80asmfile) )
                                   RET  NZ                                           ; return
                                   LD   A,Flag_OFF                              ; else
                                   CALL ParseLine                                    ; ParseLine(OFF)
                                   LD   A,(sym)
                                   CP   sym_endifstatm
                                   JR   Z, end_ifstatement
                                   JR   elsendif_loop1                     ; while ( sym!=endifstatm )
                                                                 ; else
                                                                      ; do
.ifelse_loop2                 BIT  EOF,(IY + RtmFlags3)                    ; if ( eof(z80asmfile) )
                              RET  NZ                                           ; return
                              LD   A,Flag_OFF                              ; else
                              CALL ParseLine                                    ; ParseLine(OFF)
                              LD   A,(sym)
                              CP   sym_elsestatm
                              JR   Z, break_ifelse_loop2
                              CP   sym_endifstatm
                              JR   Z, break_ifelse_loop2
                              JR   ifelse_loop2                       ; while ( sym!=elsestatm && sym!=endifstatm )
.break_ifelse_loop2           CP   sym_elsestatm
                              JR   NZ, end_ifstatement                ; if (sym == elsestatm)
.elsendif_loop2                                                            ; do
                                   BIT  EOF,(IY + RtmFlags3)                    ; if ( eof(z80asmfile) )
                                   RET  NZ                                           ; return
                                   LD   A,Flag_ON                               ; else
                                   CALL ParseLine                                    ; ParseLine(ON)
                                   LD   A,(sym)
                                   CP   sym_endifstatm
                                   JR   Z, end_ifstatement
                                   JR   elsendif_loop2                     ; while ( sym!=endifstatm )
                                                            ; else
.interpret_OFF                                              ; {don't evaluate #if expressions & ignore lines until #endif}
.endif_loop                                                      ; do
                         BIT  EOF,(IY + RtmFlags3)                    ; if ( eof(z80asmfile) )
                         RET  NZ                                           ; return
                         LD   A,Flag_OFF                              ; else
                         CALL ParseLine                                    ; ParseLine(OFF)
                         LD   A,(sym)
                         CP   sym_endifstatm
                         JR   Z, end_ifstatement
                         JR   endif_loop                         ; while ( sym!=endifstatm )

.end_ifstatement    LD   A, sym_nil
                    LD   (sym),A
                    RET


; **************************************************************************************************
;
; Evaluated logical expression and return result in DEBC
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.Evallogexpr        CALL Getsym                   ; Getsym()
                    CALL ParseNumExpr
                    JR   NC, expr_evaluable                 ; if ( (postfixexpr = ParseNumExpr()) != NULL )
.return_FALSE            LD   DE,0
                         LD   B,D
                         LD   C,E                                ; const = 0
                         RET                                ; else

.expr_evaluable          PUSH BC
                         PUSH HL
                         CALL EvalPfixExpr                       ; const = EvalPfixExpr(postfixexpr) {result in HLhlC}
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         EXX
                         PUSH HL                                 ; constant in DEhl
                         EXX
                         CALL RemovePfixList                     ; RemovePfixList(postfixexpr)
                         POP  BC                                 ; return const in DEBC
                    RET


; **************************************************************************************************
;
;    IN:  BHL = pfixexpr, pointer to postfix expression
;         C   = RANGE, allowed range of evaluated expression
;
.Pass2Info          LD   A, expr_rangetype
                    CALL Set_byte                      ; pfixexpr->rangetype |= RANGE

                    PUSH BC
                    PUSH HL
                    CALL CurrentFileName
                    LD   A,B
                    EX   DE,HL
                    POP  HL
                    POP  BC
                    LD   C,A                           ; {BHL=pfixexpr, CDE=CURRENTFILE->fname}
                    LD   A, expr_srcfile
                    CALL Set_pointer                   ; pfixexpr->srcfile = CURRENTFILE->fname
                    CALL CurrentFileLine
                    LD   A, expr_curline               ; {BHL=pfixexpr, DE=CURRENTFILE->line}
                    CALL Set_word                      ; pfixexpr->curline = CURRENTFILE->line
                    LD   C,B
                    EX   DE,HL                         ; {CDE = pfixexpr}
                    CALL CurrentModule
                    LD   A, module_mexpr
                    CALL Read_pointer
                    PUSH BC
                    PUSH HL                            ; {preserve CURRENTMODULE->mexpr}
                    LD   A, expression_first
                    CALL Read_pointer                  ; {CURRENTMODULE->mexpr->first}
                    XOR  A
                    CP   B
                    POP  HL
                    POP  BC
                    JR   NZ, pass2info_addexpr         ; if (CURRENTMODULE->mexpr->firstexpr == NULL)
                         LD   A, expression_first
                         CALL Set_pointer                   ; CURRENTMODULE->mexpr->firstexpr = pfixexpr
                         LD   A, expression_curr
                         JP   Set_pointer                   ; CURRENTMODULE->mexpr->currexpr = pfixexpr
                                                       ; else
.pass2info_addexpr       PUSH BC
                         PUSH HL                            ; {preserve CURRENTMODULE->mexpr}
                         LD   A, expression_curr
                         CALL Read_pointer                  ; {CURRENTMODULE->mexpr->currexpr}
                         LD   A, expr_nextexpr
                         CALL Set_pointer                   ; CURRENTMODULE->mexpr->currexpr}nextexpr = pfixexpr
                         POP  HL
                         POP  BC
                         LD   A, expression_curr
                         JP   Set_pointer                   ; CURRENTMODULE->mexpr->currexpr = pfixexpr


; ******************************************************************************
;
; Load file information into buffer
;
;  IN:    None.
; OUT:    HL = pointer to start of buffer information.
;         DE = pointer to end of buffer information
;         Fz = 1, if EOF reached, otherwise Fz = 0
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.LoadBuffer         PUSH IX
                    LD   IX,(srcfilehandle)       ; get file handle
                    CALL CurrentFile
                    LD   DE, srcfile_filepointer
                    CALL fseek                    ; fseek(z80asmfile, CURRENTFILE->filepointer, SEEK_SET)

                    LD   BC, SIZEOF_LINEBUFFER-1  ; read max. bytes into buffer, if possible
                    LD   HL,0
                    LD   DE, linebuffer           ; point at buffer to load file bytes
                    CALL_OZ(Os_Mv)                ; read bytes from file

                    CP   A                        ; Fc = 0
                    LD   HL, SIZEOF_LINEBUFFER-1
                    SBC  HL,BC
                    LD   B,H
                    LD   C,L                      ; number of bytes read physically from file
                    JR   Z, exit_loadbuf          ; exit if EOF reached...

                    PUSH AF
                    EX   DE,HL
                    DEC  HL                       ; HL points at end of block
                    CALL Backward_newline         ; find nearest newline
                    LD   (buffer_end),HL          ; end of buffer is byte after last newline
                    LD   (HL),0                   ; null-terminate end of loaded information

                    PUSH BC                       ; buflength
                    CALL CurrentFile
                    LD   A, srcfile_filepointer
                    CALL Read_long                ; CURRENTFILE->filepointer
                    EXX
                    POP  HL
                    ADD  HL,BC
                    LD   B,H
                    LD   C,L
                    LD   HL,0
                    ADC  HL,DE
                    EX   DE,HL
                    EXX
                    LD   A, srcfile_filepointer
                    CALL Set_long                 ; CURRENTFILE->filepointer += buflength
                    POP  AF

                    LD   DE, (buffer_end)         ; DE: return L-end
                    LD   HL, linebuffer           ; HL: return L-start

.exit_loadbuf       POP  IX
                    RET  NZ
.eof_reached        SET  EOF,(IY + RtmFlags3)     ; no bytes read into buffer...
                    RET


; ******************************************************************************
;
;    Fetch a new source line from the current source file
;
.FetchLine          PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   HL,(nextline)            ; get beginning of new line in buffer
                    LD   DE,(buffer_end)
                    LD   A,H
                    CP   D
                    JR   NZ, get_next_line
                    LD   A,L
                    CP   E
                    JR   NZ, get_next_line        ; if ( lineptr == buffer_end )
                         CALL LoadBuffer               ; EOF = LoadBuffer()
                         JR   Z, exit_fetchline        ; if EOF then return
.get_next_line      LD   (lineptr),HL
                    EX   DE,HL
                    CP   A
                    SBC  HL,DE                    ; {buffer_end - lineptr}
                    LD   B,H
                    LD   C,L                      ; search max characters for CR
                    EX   DE,HL
                    CALL forward_newline

.new_lineptr        LD   (nextline),HL            ; HL points at beginning of new line

                    CALL CurrentFile              ; get pointer to current source file record (in BHL)
                    LD   A, srcfile_line
                    CALL Read_word
                    INC  DE
                    LD   A, srcfile_line
                    CALL Set_word                 ; ++CURRENTFILE->line

.exit_fetchline     POP  HL
                    POP  DE
                    POP  BC
                    RET


; ******************************************************************************
;
;    Find NEWLINE character ahead. Search for the following newline characters:
;         1)   search CR
;         2)   if CR was found, check for a trailing LF (MSDOS newline) to be
;              bypassed, pointing at the first char of the next line.
;         3)   if CR wasn't found, then try to search for LF.
;         4)   if LF wasn't found, return pointer to the end of the buffer.
;
;    IN:  HL = start of search pointer, BC = max. number of bytes to search.
;    OUT: HL = pointer to first char of new line or end of buffer.
;
; rewritten 23.1.97, z80asm V1.01
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.forward_newline    LD   D, CR                    ; HL = line, BC = bufsize
                    LD   E, LF
.srch_nwl_loop                                    ; do while
                    LD   A,D                      ; {
                    CP   (HL)                          ; if ( *line != CR)
                    JR   Z, check_trail_LF             ; {
                         LD   A,E                      ;
                         CP   (HL)                          ; if ( *line++ == LF )
                         INC  HL                                 ;
                         RET  Z                                  ; return line   /* LF */
                         DEC  BC                       ; }
                         LD   A,B
                         OR   C
                         RET  Z
                         JR   srch_nwl_loop
                                                       ; else {
.check_trail_LF          INC  HL                            ; if (++*line != LF)
                         LD   A,E                                ; return line   /* CR */
                         CP   (HL)                               ;
                         RET  NZ                            ; else
                         INC  HL                                 ; return ++line /* CRLF */
                         RET                           ; }
                                                  ; }
                                                  ; while (--bufsize)




; ******************************************************************************
;
;    Find NEWLINE character backwards. Search for the following newline characters:
;         1)   search CR
;         2)   if CR was found, check for a trailing LF (MSDOS newline) to be
;              bypassed, pointing at the first char of the next line.
;         3)   if CR wasn't found, then try to search for LF.
;         4)   if LF wasn't found, return pointer to the end of the buffer.
;
;    IN:  HL = start of search pointer, BC = max. number of bytes to search backwards.
;    OUT: HL = pointer to first char of new line.
;
.backward_newline   PUSH BC
                    PUSH HL                       ; preserve search parameters
                    LD   A, CR
                    CPDR
                    JR   Z, found_CR              ; <CR> found, check for a trailing <LF>
                         POP  HL
                         POP  BC                       ; <CR> not found,
                         LD   A, LF                    ; search for <LF> and
                         CPDR                          ; return pointer to first char of next line
                         INC  BC                       ; number of bytes NOT searched
                         INC  HL
                         INC  HL                       ; point at byte after <LF> (beginning of new line)
                         RET                           ; or end of search pointer...

.found_CR           INC  BC                       ; number of bytes searched, including CR
                    POP  AF
                    POP  AF                       ; remove redundant search parameters
                    INC  HL                       ; point at <CR>
                    INC  HL                       ; and byte after <CR>

                    LD   A, LF
                    CP   (HL)                     ; <CR><LF>?
                    RET  NZ                       ; no - just <CR>, pointer to first char of next line
                    INC  BC                       ; no. of bytes NOT searched
                    INC  HL                       ; point after <CR><LF>...
                    RET



; ========================================================================================
; (asm_pc)++
.asm_pc_p1
                    LD   HL,asm_pc

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
; (asm_pc) += 2
.asm_pc_p2
                    LD   HL,asm_pc

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
; (asm_pc) += 3
.asm_pc_p3
                    LD   HL,asm_pc

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
; (asm_pc) += 4
.asm_pc_p4
                    LD   HL,asm_pc

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

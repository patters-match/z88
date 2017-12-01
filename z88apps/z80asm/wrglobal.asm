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

     MODULE Write_globals

; external procedures:
     LIB Inthex
     LIB CmpPtr
     LIB Read_word, Read_long, Read_byte, Read_pointer
     LIB ascorder


     INCLUDE "fileio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


     XREF CurrentModule                                     ; module.asm
     XREF Write_string                                      ; fileio.asm
     XREF GetVarPointer                                     ; varptr.asm
     XREF Open_file,Close_file                              ; fileio.asm
     XREF ReportError_NULL                                  ; asmerror.asm

; global procedures:
     XDEF WriteGlobals


; **************************************************************************************************
;
; Write Global address definitions to ".def" file. Only touched definitions will be written.
;
.WriteGlobals
                    LD   HL, deffilename
                    CALL GetVarPointer
                    INC  HL                            ; point at first char in filename
                    LD   A, OP_OUT
                    CALL Open_file
                    JP   C, ReportError_NULL
                    LD   (deffilehandle),IX            ; global definitions symbol file created...

                    LD   HL, globalroot
                    CALL GetVarPointer

                    PUSH IY
                    LD   IY, WriteGlobal
                    CALL ascorder
                    POP  IY

                    LD   HL,deffilehandle
                    JP   Close_file


; **************************************************************************************************
; This function is called on each node of the AVL-tree by ascorder library routine.
; IN: BHL points to node of AVL-tree
;
.WriteGlobal        LD   A, symtree_type
                    CALL Read_byte
                    BIT  SYMDEF,A                 ; if ( !(symnode->type & SYMDEF) )
                    RET  NZ
                         AND  EXPRADDR | EXPRGLOBAL | 2**SYMTOUCHED
                         CP   EXPRADDR | EXPRGLOBAL | 2**SYMTOUCHED
                         RET  NZ                            ; if ( SYMTOUCHED && SYMXDEF && SYMADDR )

                              LD   IX,(deffilehandle)
                              PUSH BC
                              PUSH HL
                              LD   BC,5
                              LD   HL, defc_directive
                              CALL Write_string                  ; fwrite( "DEFC ", deffile)
                              POP  HL
                              POP  BC

                              PUSH BC                            ; not library routines...
                              PUSH HL
                              LD   A,symtree_symname
                              CALL Read_pointer
                              XOR  A
                              CALL Read_byte
                              LD   C,A
                              LD   DE,0
                              INC  HL
                              CALL Write_string                  ; fwrite( node->symname, deffile)
                              LD   BC,4
                              LD   HL, separator
                              CALL Write_string                  ; fwrite( "\t= $", deffile)
                              POP  HL
                              POP  BC

                              PUSH BC
                              PUSH HL
                              LD   A, symtree_symvalue
                              CALL Read_long                     ; {symvalue in debc}
                              LD   HL, modulehdr
                              CALL GetVarPointer
                              LD   A, modules_first
                              CALL Read_pointer
                              LD   A, module_origin
                              CALL Read_word                     ; modulehdr->first->origin
                              PUSH DE
                              CALL CurrentModule
                              LD   A, module_startoffset
                              CALL Read_word                     ; CURRENTMODULE->startoffset
                              PUSH DE
                              EXX
                              POP  HL
                              ADD  HL,BC                         ; CURRENTMODULE->startoffset + node->symvalue
                              POP  DE
                              ADD  HL,DE                         ; + modulehdr->first->origin
                              LD   (longint),HL
                              EXX
                              LD   HL,longint                    ; point at value
                              LD   DE, stringconst
                              LD   BC,2
                              CALL IntHex                        ; convert value to HEX string at (stringconst)
                              LD   BC,4
                              EX   DE,HL                         ; {HL points at HEX string}
                              CALL Write_string                  ; fwrite( node->symvalue, deffile)
                              LD   BC,2
                              LD   HL, separator2
                              CALL Write_string                  ; fwrite( "; ", deffile)
                              POP  HL
                              POP  BC

                              LD   A, symtree_modowner
                              CALL Read_pointer
                              LD   A, module_mname
                              CALL Read_pointer
                              XOR  A
                              CALL Read_byte                     ; {length of module name}
                              LD   C,A
                              LD   DE,0
                              INC  HL
                              CALL Write_string                  ; fwrite( node->owner->mname, deffile)

                              LD   A, 13
                              CALL_OZ(Os_Pb)                     ; fputc( deffile, '\n')
                    RET
.defc_directive     DEFM "DEFC "
.separator          DEFM 9, "= $"
.separator2         DEFM "; "

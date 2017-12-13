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

     MODULE Read_names

; external procedures:

     LIB Read_word, Read_pointer, Read_byte
     LIB Set_pointer, Set_long, Set_byte
     LIB GetPointer, GetVarPointer
     LIB InsertSymbol

     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF GetSym                                                      ; prsline.asm
     XREF CurrentFile                                                 ; srcfile.asm
     XREF CurrentModule                                          ; module.asm
     XREF ftell, fseek, Read_fptr, Write_fptr               ; fileio.asm
     XREF ModuleBaseAddr                                         ; modlink.asm
     XREF LoadName                                               ; loadname.asm
     XREF Add32bit                                               ; add32bit.asm

     XREF AllocIdentifier, InsertSym, FindSymbol            ; symbols.asm
     XREF CmpIDstr

     XREF Test_32bit_range, Test_16bit_range                ; exprs.asm
     XREF Test_8bit_range, Test_7bit_range


; routines accessible in this module:
     XDEF ReadNames


     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "fpp.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
;    Read object module names
;
;    IN:  BHL = nextname, relative file pointer to start of object module names
;         CDE = endnames, relative file pointer to end of object module names
;    OUT: None.
;
;    Local variables on stack, defined by IX:
;         (IX+0,2) = nextname
;         (IX+3,5) = endnames
;         (IX+6,7) = loaded name counter
;
;    Registers changed after return:
;         ......../IXIY  same
;         AFBCDEHL/....  different
;
.ReadNames          PUSH IX                       ; preserve IX entry value (probably a pointer)
                    EXX
                    LD   HL,0
                    ADD  HL,SP                    ; current SP in HL
                    LD   IX,-8
                    ADD  IX,SP
                    LD   SP,IX
                    PUSH HL                       ; preserve pointer to original SP
                    EXX
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   (IX+2),B                 ; preserve nextname filepointer
                    LD   (IX+3),E
                    LD   (IX+4),D
                    LD   (IX+5),C                 ; preserve endnames filepointer
                    LD   (IX+6),0
                    LD   (IX+7),0                 ; name counter = 0

                                                  ; do
.while_readnames    PUSH IX                            ; {preserve pointer to local variables}
                    LD   IX,(objfilehandle)
                    CALL_OZ(Os_Gb)
                    LD   D,A                           ; scope = fgetc(objfile)
                    CALL_OZ(Os_Gb)
                    LD   E,A                           ; symtype = fgetc(objfile)
                    LD   B,0
                    LD   HL, longint
                    CALL Read_fptr                     ; value = ReadLong(objfile)
                    CALL LoadName                      ; LoadName(objfile)
                    POP  IX

                    LD   B,0
                    LD   C,(HL)                        ; length of loaded name
                    LD   HL, 1+1+4+1
                    ADD  HL,BC
                    LD   C,(IX+0)
                    LD   B,(IX+1)
                    ADD  HL,BC                         ; nextname += 1+1+4+1+strlen(name)
                    LD   (IX+0),L
                    LD   (IX+1),H
                    JR   NC, select_symtype
                         INC  (IX+2)                   ; correct for overflow...

.select_symtype     LD   A,E                           ; switch(symtype)
                    CP   'A'
                    JR   NZ, sym_constant                   ; case 'A':    symtype = 0 | SYMADDR | SYMDEFINED
                         LD   E, 2**SYMADDR | 2**SYMDEFINED
                         PUSH DE
                         CALL ModuleBaseAddr                               ; CURRENTMODULE->startoffset +
                         LD   DE,0
                         LD   HL,longint                                   ; value += modulehdr->first->origin +
                         CALL Add32bit                                     ;          CURRENTMODULE->startoffset
                         JR   prepare_symparas

.sym_constant            LD   E, 2**SYMDEFINED              ; case 'C':    symtype = 0 | SYMDEFINED
                         PUSH DE

.prepare_symparas   LD   HL, linebuffer
                    CALL AllocIdentifier               ; BHL = pointer to copy of loaded name in OZ memory
                    JR   NC, sym_allocated
                         POP  DE                       ; {remove redundant scope & type}
                         CALL ReportError_NULL
                         JP   exit_readnames
.sym_allocated      LD   C,B
                    EX   DE,HL                         ; CDE = pointer to symbol identifier
                    POP  AF
                    PUSH AF
                    CP   'L'                           ; switch(scope)
                    JP   NZ, symscope_global                ; case 'L':
                         CALL CurrentModule                      ; BHL = CURRENTMODULE
                         LD   A, module_localroot
                         CALL Read_pointer                       ; {BHL=CURRENTMODULE->localroot, CDE=identifier}
                         CALL FindSymbol                         ; foundsym = FindSymbol(id, CURRENTMODULE->localroot, identifier)
                         JR   NC, found_localsym                 ; if (foundsym == NULL)
                              POP  HL
                              LD   A,L                                ; {get symboltype}
                              OR   2**SYMLOCAL                        ; symboltype |= SYMLOCAL
                              EXX
                              LD   BC,(longint)
                              LD   DE,(longint+2)                     ; symbol value
                              EXX
                              CALL CurrentModule
                              PUSH AF
                              PUSH BC
                              EX   AF,AF'
                              POP  AF
                              EX   AF,AF'
                              PUSH HL
                              EXX
                              POP  HL                                 ; ahl = modowner
                              EXX
                              POP  AF
                              PUSH DE
                              LD   DE, module_localroot
                              ADD  HL, DE                             ; &CURRENTMODULE->localroot
                              POP  DE
                              PUSH IX
                              LD   IX, CmpIDstr
                              CALL InsertSym                          ; foundsym = InsertSymbol(identifier, value, symboltype, CmpIDstr
                              POP  IX                                 ;                         &CURRENTMODULE->localroot, CURRENTMODULE)
                              JP   NC, end_symcreate                  ; if ( foundsym == NULL )
                                   JP  exit_readnames                      ; return
                                                                 ; else
.found_localsym                    LD   A, symtree_type
                                   CALL Read_byte
                                   EXX
                                   POP  HL
                                   OR   L                                  ; foundsym->type |= symtype
                                   EXX
                                   OR   2**SYMLOCAL                        ; foundsym->type |= SYMLOCAL

                                   PUSH DE
                                   PUSH BC                                 ; {preserve pointer to identifier}
                                   PUSH BC
                                   PUSH HL                                 ; {preserve pointer to found symbol}
                                   LD   C,A
                                   LD   A,symtree_type
                                   CALL Set_byte
                                   EXX
                                   LD   BC,(longint)
                                   LD   DE,(longint+2)
                                   EXX
                                   LD   A, symtree_symvalue
                                   CALL Set_long                           ; foundsym->symvalue = value

                                   CALL CurrentModule
                                   EX   DE,HL
                                   POP  HL
                                   LD   A,B
                                   POP  BC
                                   LD   C,A                                ; {BHL=foundsym, CDE=CURRENTMODULE}
                                   LD   A, symtree_modowner
                                   CALL Set_pointer                        ; foundsym->owner = CURRENTMODULE
                                   POP  BC
                                   POP  DE
                                   CALL Redefined_msg
                                   JP   end_symcreate

.symscope_global    CP   'X'                                ; case 'G':
                    JP   NZ, symscope_xlib
                         LD   HL, globalroot
                         CALL GetVarPointer                      ; {BHL=globalroot, CDE=identifier}
                         CALL FindSymbol                         ; foundsym = FindSymbol(id, globalroot, identfier)
                         JR   NC, found_globalsym                ; if (foundsym == NULL)
                              POP  HL
                              LD   A,L                                ; {get symboltype}
                              OR   2**SYMXDEF                              ; symboltype |= SYMXDEF
                              EXX
                              LD   BC,(longint)
                              LD   DE,(longint+2)                     ; symbol value
                              EXX
                              LD   HL, globalroot
                              CALL GetPointer                         ; &globalroot
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
                              POP  HL                                 ; ahl = modowner
                              EXX
                              POP  HL
                              POP  BC
                              POP  AF
                              PUSH IX
                              LD   IX, CmpIDstr
                              CALL InsertSym                          ; foundsym = InsertSymbol(identifier, value, symboltype, CmpIDstr
                              POP  IX                                 ;                         &globalroot, CURRENTMODULE)
                              JP   NC, end_symcreate                  ; if ( foundsym == NULL )
                                   JP   exit_readnames                     ; return
                                                                 ; else
.found_globalsym                   LD   A, symtree_type
                                   CALL Read_byte
                                   EXX
                                   POP  HL
                                   OR   L                                  ; foundsym->type |= symtype
                                   EXX
                                   OR   2**SYMXDEF                              ; foundsym->type |= SYMXDEF

                                   PUSH DE
                                   PUSH BC
                                   PUSH BC
                                   PUSH HL
                                   LD   C,A
                                   LD   A,symtree_type
                                   CALL Set_byte
                                   EXX
                                   LD   BC,(longint)
                                   LD   DE,(longint+2)
                                   EXX
                                   LD   A, symtree_symvalue
                                   CALL Set_long                           ; foundsym->symvalue = value

                                   CALL CurrentModule
                                   EX   DE,HL
                                   POP  HL
                                   LD   A,B
                                   POP  BC
                                   LD   C,A                                ; {BHL=foundsym, CDE=CURRENTMODULE}
                                   LD   A, symtree_modowner
                                   CALL Set_pointer                        ; foundsym->owner = CURRENTMODULE
                                   POP  BC
                                   POP  DE
                                   CALL Redefined_msg

.symscope_xlib           LD   HL, globalroot                ; case 'X':
                         CALL GetVarPointer                      ; {BHL=globalroot, CDE=identifier}
                         CALL FindSymbol                         ; foundsym = FindSymbol(id, globalroot, identfier)
                         JR   NC, found_xlibsym                  ; if (foundsym == NULL)
                              POP  HL
                              LD   A,L                                ; {get symboltype}
                              OR   2**SYMXDEF     | 2**SYMDEF              ; symboltype |= SYMXDEF | SYMDEF
                              EXX
                              LD   BC,(longint)
                              LD   DE,(longint+2)                     ; symbol value
                              EXX
                              LD   HL, globalroot
                              CALL GetPointer                         ; &globalroot
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
                              POP  HL                                 ; ahl = modowner
                              EXX
                              POP  HL
                              POP  BC
                              POP  AF
                              PUSH IX
                              LD   IX, CmpIDstr
                              CALL InsertSym                          ; foundsym = InsertSymbol(identifier, value, symboltype, CmpIDstr
                              POP  IX                                 ;                         &globalroot, CURRENTMODULE)
                              JP   NC, end_symcreate                  ; if ( foundsym == NULL )
                                   JP   exit_readnames                     ; return
                                                                 ; else
.found_xlibsym                     LD   A, symtree_type
                                   CALL Read_byte
                                   EXX
                                   POP  HL
                                   OR   L                                  ; foundsym->type |= symtype
                                   EXX
                                   OR   2**SYMXDEF     | 2**SYMDEF              ; foundsym->type |= SYMXDEF | SYMDEF

                                   PUSH DE
                                   PUSH BC
                                   PUSH BC
                                   PUSH HL
                                   LD   C,A
                                   LD   A,symtree_type
                                   CALL Set_byte
                                   EXX
                                   LD   BC,(longint)
                                   LD   DE,(longint+2)
                                   EXX
                                   LD   A, symtree_symvalue
                                   CALL Set_long                           ; foundsym->symvalue = value

                                   CALL CurrentModule
                                   EX   DE,HL
                                   POP  HL
                                   LD   A,B
                                   POP  BC
                                   LD   C,A                                ; {BHL=foundsym, CDE=CURRENTMODULE}
                                   LD   A, symtree_modowner
                                   CALL Set_pointer                        ; foundsym->owner = CURRENTMODULE
                                   POP  BC
                                   POP  DE
                                   CALL Redefined_msg
.end_symcreate      LD   C,(IX+6)
                    LD   B,(IX+7)
                    INC  BC
                    LD   (IX+6),C
                    LD   (IX+7),B

                    LD   A,(IX+5)
                    CP   (IX+2)
                    JR   C, exit_readnames
                    LD   L,(IX+3)
                    LD   H,(IX+4)
                    LD   C,(IX+0)
                    LD   B,(IX+1)
                    SBC  HL,BC
                    JR   C, exit_readnames
                    JR   Z, exit_readnames
                    JP   while_readnames          ; while ( nextname < endnames )

.exit_readnames     POP  HL
                    LD   SP,HL                    ; get entry SP of this routine
                    POP  IX                       ; restore original IX
                    RET


; **************************************************************************************************
;
.Redefined_msg      LD   HL, redef1_msg
                    CALL_OZ(Gn_Sop)
                    LD   HL, linebuffer+1              ; {skip length identifier}
                    CALL_OZ(Gn_Sop)                    ; display symbol name
                    LD   HL, redef2_msg
                    CALL_OZ(Gn_Sop)
                    CALL CurrentModule
                    LD   A, module_mname
                    CALL Read_pointer                  ; CURRENTMODULE->mname
                    INC  HL                            ; {skip length identfifier}
                    CALL_OZ(Gn_Soe)                    ; {module name is null-terminated}
                    CALL_OZ(Gn_Nln)
                    RET
.redef1_msg         DEFM "Symbol <", 0
.redef2_msg         DEFM "> redefined in module ", 0

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

     MODULE Write_mapfile

     LIB transfer, reorder, ascorder
     LIB Inthex
     LIB GetPointer, GetVarPointer

     XREF SIZEOF_relocator

     INCLUDE "fileio.def"
     INCLUDE "stdio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; external procedures:
     LIB malloc, mfree
     LIB CmpPtr
     LIB Read_word, Read_byte
     LIB Set_pointer, Read_pointer
     LIB Read_long

     XREF CurrentModule                                     ; module.asm
     XREF Write_string                                      ; fileio.asm
     XREF ReportError_NULL                                  ; asmerror.asm
     XREF CreateFileName                                    ; crtflnm.asm
     XREF Open_file, Close_file, Delete_file                ; fileio.asm
     XREF InsertSym, CmpIDstr, CmpIDval                     ; symbols.asm

; global procedures:
     XDEF WriteMapFile


; **************************************************************************************************
;
;    IX points at local variables:
;         (IX+0,2) = cmodule
;         (IX+3,5) = **maproot
;
.WriteMapFile       LD   A, (TOTALERRORS)
                    CP   0
                    RET  NZ                            ; if ( TOTALERRORS != 0 ) RETurn

                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-6
                    ADD  IX,SP
                    LD   SP,IX                         ; make 9 bytes room on stack for pointer variables
                    PUSH HL

                    LD   HL, modulehdr
                    CALL GetVarPointer
                    LD   A, modules_first
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL                         ; CDE=modulehdr->first
                    LD   HL, curmodule
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer                   ; CURRENTMODULE = modulehdr->first
                    LD   (IX+0),E
                    LD   (IX+1),D
                    LD   (IX+2),C                      ; cmodule = modulehdr->first

                    LD   A, SIZEOF_pointer
                    CALL malloc
                    CALL C, ReportError_NULL
                    JP   C, exit_mapfile
                    LD   (IX+3),L
                    LD   (IX+4),H
                    LD   (IX+5),B                      ; maproot
                    XOR  A
                    LD   D,A
                    LD   E,A
                    LD   C,A
                    CALL Set_pointer                   ; *maproot = NULL

                    PUSH IX
                    LD   HL, mapfilename
                    LD   DE, mapext
                    CALL CreateFilename
                    JP   C, exit_mapfile
                    INC  HL                            ; point at first char in filename
                    LD   A, OP_OUT                     ; create...
                    CALL Open_file                     ; mapfile = fopen(mapfilename, "w")
                    POP  DE
                    JP   C, exit_mapfile
                    LD   (mapfilehandle),IX            ; map file created...
                    PUSH DE
                    POP  IX

                    LD   HL, mapfile_msg
                    CALL_OZ(Gn_Sop)                    ; puts("Creating mapfile...")

.reorder_locals          LD   L,(IX+0)                 ; do
                         LD   H,(IX+1)
                         LD   B,(IX+2)
                         LD   DE, module_localroot
                         ADD  HL, DE                        ; BHL = cmodule->localroot
                         LD   E,(IX+3)
                         LD   D,(IX+4)
                         LD   C,(IX+5)                      ; CDE = maproot
                         PUSH IY
                         LD   IY, CmpIDstr
                         CALL transfer                      ; transfer( cmodule->localroot, maproot, CmpIDstr)
                         POP  IY
                         LD   L,(IX+0)
                         LD   H,(IX+1)
                         LD   B,(IX+2)
                         LD   A, module_next
                         CALL Read_pointer                  ; cmodule->next
                         LD   (IX+0),L
                         LD   (IX+1),H
                         LD   (IX+2),B                      ; cmodule = cmodule->next
                         XOR  A
                         CP   B
                    JR   NZ, reorder_locals            ; while (cmodule != NULL)

                    LD   HL,globalroot
                    CALL GetPointer
                    LD   E,(IX+3)
                    LD   D,(IX+4)
                    LD   C,(IX+5)
                    PUSH IY
                    LD   IY, CmpIDstr
                    CALL transfer                      ; transfer( globalroot, maproot, CmpIDstr)
                    POP  IY

                    LD   L,(IX+3)
                    LD   H,(IX+4)
                    LD   B,(IX+5)
                    XOR  A
                    CALL Read_pointer                  ; BHL = *maproot
                    CALL WriteMapSymbols               ; WriteMapSymbols(maproot)

                    LD   L,(IX+3)
                    LD   H,(IX+4)
                    LD   B,(IX+5)
                    XOR  A
                    CALL Read_pointer                  ; BHL = *maproot
                    PUSH IY
                    LD   IY, CmpIDval
                    CALL reorder                       ; reorder( maproot, CmpIDval)
                    POP  IY

                    LD   B,C
                    EX   DE,HL                         ; BHL = pointer to new root of map-symbols
                    CALL WriteMapSymbols               ; WriteMapSymbols(maproot)

.exit_mapfile       LD   HL, mapfilehandle
                    CALL Close_file                    ; fclose(mapfile)
                    LD   HL, mapfilename
                    CALL GetVarPointer
                    INC  HL
                    BIT  ASMERROR,(IY+RtmFlags3)
                    CALL NZ, Delete_file               ; if ( ASMERROR ) remove(mapfilename)
                    POP  HL
                    LD   SP,HL
                    RET

.mapext             DEFM "map"
.mapfile_msg        DEFM 1, "2H5Creating mapfile...", 10, 13, 0



; **************************************************************************************************
;
; Write address symbols to ".map" file.
;
;    IN:  BHL = pointer to root of symbols
;
.WriteMapSymbols    PUSH IX
                    PUSH IY
                    LD   IY, writemapsym
                    CALL ascorder                      ; ascorder(maproot, Writemapsym)
                    POP  IY
                    LD   IX,(mapfilehandle)
                    LD   A,13
                    CALL_OZ(Os_Pb)                     ; fputc('\n', mapfile)
                    POP  IX
                    RET


; **************************************************************************************************
;
.Writemapsym        LD   A, symtree_type
                    CALL Read_byte
                    BIT  SYMADDR,A
                    RET  Z                             ; if ( !(node->type & SYMADDR) ) return

                    LD   IX,(mapfilehandle)
                    PUSH BC
                    PUSH HL
                    LD   A,symtree_symname
                    CALL Read_pointer
                    XOR  A
                    CALL Read_byte
                    LD   C,A
                    LD   DE,0
                    INC  HL
                    CALL Write_string                  ; fwrite( symnode->symname, mapfile)
                    LD   BC,3
                    LD   HL, separator
                    CALL Write_string                  ; fwrite( "\t= ", symbolfile)
                    POP  HL
                    POP  BC                            ; symnode

                    PUSH BC
                    PUSH HL
                    LD   DE, symtree_symvalue
                    ADD  HL,DE                         ; point at symbol value
                    XOR  A
                    CALL Read_byte
                    LD   E,A
                    LD   A,1
                    CALL Read_byte
                    LD   D,A                           ; DE = address integer
                    LD   A,(RuntimeFlags2)
                    BIT  autorelocate, A
                    CALL NZ, add_relochdr              ; add relocation header size to address
                    PUSH DE
                    LD   B,0                           ; local address
                    LD   HL,0
                    ADD  HL,SP                         ; HL points at address integer on stack
                    LD   DE, stringconst
                    LD   C,2
                    CALL IntHex                        ; convert value to HEX string at (stringconst)
                    POP  AF                            ; remove redundant integer
                    LD   BC,4
                    EX   DE,HL                         ; {HL points at HEX string}
                    CALL Write_string                  ; fwrite( symnode->symvalue, symbolfile)
                    LD   BC,2
                    LD   HL, separator2
                    CALL Write_string                  ; fwrite( ", ", mapfile)
                    POP  HL
                    POP  BC                            ; symnode

                    PUSH BC
                    PUSH HL
                    LD   A, symtree_type
                    CALL Read_byte
                    BIT  SYMLOCAL,A
                    JR   Z, symscope_global            ; if ( symnode->type & SYMLOCAL )
                    LD   A,'L'                         ; fputc('L', mapfile)
                    JR   write_symscope           ; else
.symscope_global    LD   A,'G'                         ; fputc('G', mapfile)
.write_symscope     CALL_OZ(Os_Pb)
                    LD   BC,2
                    LD   HL, separator3
                    CALL Write_string                  ; fwrite( ": ", mapfile)
                    POP  HL
                    POP  BC                            ; symnode
                    LD   A, symtree_modowner
                    CALL Read_pointer
                    LD   A, module_mname
                    CALL Read_pointer
                    XOR  A
                    CALL Read_byte
                    INC  HL
                    LD   C,A
                    LD   DE, 0
                    CALL Write_string                  ; fwrite( "%s", symnode->owner->mname)
                    LD   A, 13
                    CALL_OZ(Os_Pb)                     ; {terminate line}
                    POP  IX
                    RET

.separator          DEFM 9, "= "
.separator2         DEFM ", "
.separator3         DEFM ": "

; ******************************************************************************
;
;    Add relocation header size to address integer.
;
;    IN:  DE = address integer
;    OUT: DE = address integer + relocation header
;
.add_relochdr       PUSH BC
                    PUSH HL
                    LD   HL, SIZEOF_relocator
                    LD   BC,(size_reloctable)
                    ADD  HL,BC
                    ADD  HL,DE
                    EX   DE,HL
                    POP  HL
                    POP  BC
                    RET

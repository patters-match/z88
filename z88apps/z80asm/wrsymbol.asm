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

     MODULE Write_symboltable

     LIB ascorder
     LIB Inthex

     INCLUDE "fileio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"

; external procedures:
     LIB CmpPtr
     LIB Read_word, Read_long, Read_byte, Read_pointer

     XREF CurrentModule                                     ; currmod.asm
     XREF Write_string                                      ; fileio.asm
     XREF GetVarPointer                                     ; varptr.asm

; global procedures:
     XDEF WriteSymbols


; **************************************************************************************************
;
.WriteSymbols       LD   A, (TOTALERRORS)
                    CP   0
                    RET  NZ                            ; if ( TOTALERRORS == 0 )
                         LD   IX,(symfilehandle)
                         LD   HL, sym1_msg
                         LD   B,0
                         LD   C,(HL)
                         INC  HL
                         CALL Write_string                  ; "Local Module symbols:"
                         CALL CurrentModule
                         LD   A, module_localroot
                         CALL Read_pointer
                         LD   IX,0                          ; counter = 0
                         PUSH IY
                         LD   IY, WriteSymbol               ; ascorder(CURRENTMODULE->localroot, WriteSymbol)
                         CALL ascorder
                         POP  IY
                         CALL Write_endmsg                  ; if ( counter == 0 ) fputs("None.", symbolfile)

                         LD   IX,(symfilehandle)
                         LD   HL, sym2_msg
                         LD   B,0
                         LD   C,(HL)
                         INC  HL
                         CALL Write_string                  ; "Global Module symbols:"
                         LD   HL, globalroot
                         CALL GetVarPointer
                         LD   IX,0                          ; counter = 0
                         PUSH IY
                         LD   IY, WriteSymbol
                         CALL ascorder                      ; ascorder(globalroot, WriteSymbol)
                         POP  IY
                         CALL Write_endmsg                  ; if ( counter == 0 ) fputs("None.", symbolfile)
                    RET

.sym1_msg           DEFM msg1_end-sym1_msg-1, 13, "Local Module Symbols:", 13
.msg1_end
.sym2_msg           DEFM msg2_end-sym2_msg-1, 13, 13, "Global Module Symbols:", 13
.msg2_end


; **************************************************************************************************
;
.Write_endmsg       PUSH IX
                    POP  BC
                    LD   A,B
                    OR   C
                    RET  NZ
                    LD   IX,(symfilehandle)
                    LD   HL, sym3_msg
                    LD   BC,6
                    CALL Write_string
                    RET
.sym3_msg           DEFM "None.", 13



; **************************************************************************************************
;
; Write symbol to ".sym" file. Only touched definitions will be written.
;
;    IN:  BHL = pointer to current node of symbol tree
;         IX  = counter
;    OUT: IX = total amount of symbols written to symbol file.
;
.WriteSymbol        PUSH BC
                    PUSH HL
                    LD   A, symtree_modowner
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL                    ; CDE = symnode->owner
                    CALL CurrentModule
                    CALL CmpPtr                   ; if ( symnode->owner == CURRENTMODULE )
                    POP  HL
                    POP  BC
                    RET  NZ
                         LD   A, symtree_type
                         CALL Read_byte
                         BIT  SYMTOUCHED,A                  ; if ( symnode->type, SYMTOUCHED )
                         RET  Z
                              BIT  SYMLOCAL,A                    ; if ( symnode->type, SYMLOCAL || node->type, SYMXDEF )
                              JR   NZ, write_sym
                              BIT  SYMXDEF,A
                              RET  Z
.write_sym                         PUSH IX                            ; {preserve counter}
                                   LD   IX,(symfilehandle)
                                   PUSH BC
                                   PUSH HL
                                   LD   A,symtree_symname
                                   CALL Read_pointer
                                   XOR  A
                                   CALL Read_byte
                                   LD   C,A
                                   LD   DE,0
                                   INC  HL
                                   CALL Write_string                  ; fwrite( symnode->symname, symbolfile)
                                   LD   BC,3
                                   LD   HL, separator
                                   CALL Write_string                  ; fwrite( "\t= ", symbolfile)
                                   POP  HL
                                   POP  BC
                                   LD   DE, symtree_symvalue
                                   ADD  HL,DE                         ; point at symbol value (long word)
                                   LD   DE, stringconst
                                   LD   C,4
                                   CALL IntHex                        ; convert value to HEX string at (stringconst)
                                   LD   BC,8
                                   EX   DE,HL                         ; {HL points at HEX string}
                                   CALL Write_string                  ; fwrite( symnode->symvalue, symbolfile)
                                   LD   A, 13
                                   CALL_OZ(Os_Pb)                     ; {terminate line}
                                   POP  IX
                                   INC  IX                            ; ++counter
                    RET
.separator          DEFM 9, "= "

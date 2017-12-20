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
; ********************************************************************************************************************

MODULE CreateAsmPcIdent

INCLUDE "rtmvars.def"

LIB mfree, AllocIdentifier
LIB GetPointer, GetVarPointer, Set_pointer

XREF ReportError, ReportError_NULL, ReportError_STD    ; asmerror.asm
XREF FreeSym, FindSymbol, DefineDefSym                 ; symbols.asm

XDEF CreateasmPC_ident

; *****************************************************************************************
;
;    Create the standard "ASMPC" identifier in the global variable area.
;    The z80asm runtime variable asm_pc_ptr holds the pointer to the created symbol.
;
.CreateasmPC_ident  LD   HL, asmpc_ident
                    CALL AllocIdentifier                    ; tmpident to extended memory, BHL = asmpc_ident
                    JP   C, ReportError_NULL
                    LD   C,B
                    EX   DE,HL                              ; .asmpc_ident in CDE
                    PUSH BC
                    PUSH DE                                 ; preserve pointer to temporary identifier
                    EXX
                    LD   BC,0
                    LD   D,B
                    LD   E,C
                    EXX
                    LD   HL, globalroot
                    CALL GetPointer                         ; &globalroot in BHL
                    XOR  A                                  ; A=0
                    CALL DefineDefSym                       ; DefineDefSym(asmpc_tmpident, 0, 0, &globalroot)
                    JR   C, err_create_asmpc
                    POP  DE
                    POP  BC
                    PUSH BC
                    PUSH DE
                    LD   HL, globalroot
                    CALL GetVarPointer                      ; globalroot in BHL
                    CALL FindSymbol
                    EX   DE,HL
                    LD   C,B
                    LD   HL,asm_pc_ptr
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer                        ; asm_pc_ptr = FindSymbol(.asmpc_ident, globalroot)
                    JR   exit_create_asmpc

.err_create_asmpc   LD   A, Err_no_room
                    CALL ReportError_NULL

.exit_create_asmpc  POP  HL
                    POP  BC
                    LD   B,C
                    PUSH AF
                    CALL mfree                              ; free(tmpident)
                    POP  AF
                    RET

.asmPC_ident        DEFM 5, "ASMPC", 0
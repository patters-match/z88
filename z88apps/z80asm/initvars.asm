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

INCLUDE "rtmvars.def"
INCLUDE "symbol.def"

LIB AllocVarPointer

XDEF InitVars, InitFiles, InitPointers


; ****************************************************************************************
;
; Setup IY register to base of variables and preset runtime flags.
;
.InitVars           LD   HL, z80asm_vars
                    PUSH HL
                    POP  IY                            ; IY points at base of variable
                    LD   (HL), 2**datestamp | 2**mapref | 2**z80bin | 2**symtable
                               ; datestamp, map file,   linking,   symbol file
                    INC  HL
                    LD   (HL), @00000000               ; reset RTMflags2
                    INC  HL
                    LD   (HL), @00000000               ; reset RTMflags3
                    RET


; ****************************************************************************************
;
;    Reset Area for filename pointers and handles
;
.InitFiles          LD   BC, end_file_area - file_area
                    LD   HL, objfilename
.clear_handles      LD   (HL),0
                    INC  HL
                    DEC  BC
                    LD   A,B
                    OR   C
                    JR   NZ, clear_handles
                    RET


; ****************************************************************************************
;
.InitPointers       LD   HL, modulehdr                 ; allocate room for 'modulehdr' variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, libraryhdr                ; allocate room for 'libraryhdr' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, linkhdr                   ; allocate room for 'linkhdr' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, CURMODULE                 ; allocate room for 'CURMODULE' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, CURLIBRARY                ; allocate room for 'CURLIBRARY' variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, LASTMODULE                ; allocate room for 'LASTMODULE' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, globalroot                ; allocate room for 'globalroot' pointer variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, staticroot                ; allocate room for 'staticroot' pointer variable
                    CALL AllocVarPointer
                    LD   HL, asm_pc_ptr                ; allocate room for 'asm_pc_ptr' pointer variable
                    JP   AllocVarPointer


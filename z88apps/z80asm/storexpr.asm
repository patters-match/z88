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

MODULE StoreExpr

LIB Read_byte, Set_byte, Read_word, Read_pointer, Bind_bank_s1

INCLUDE "fileio.def"
INCLUDE "rtmvars.def"
INCLUDE "symbol.def"

XREF Write_string                                           ; fileio.asm

XDEF StoreExpr

; ********************************************************************************************************************
;
; Store infix expression to object file
;
; IN:     A   = range
;         BHL = pfixexpr pointer
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.StoreExpr          PUSH IX
                    PUSH DE
                         LD   IX,(objfilehandle)            ; {get handle for object file}
                         CALL_OZ(Os_Pb)                     ; fputc(range, objfile)
                         LD   A, expr_codepos
                         CALL Read_word                     ; pfixexpr->codepos
                         LD   A,E                           ;
                         CALL_OZ(Os_Pb)                     ; fputc(codepos%256, objfile)
                         LD   A,D
                         CALL_OZ(Os_Pb)                     ; fputc(codepos%256, objfile)

                         PUSH HL
                         PUSH BC
                         LD   C,-1
                         LD   A, expr_stored
                         CALL Set_byte                      ; pfixexpr->stored = ON
                         LD   A,expr_infixexpr
                         CALL Read_pointer                  ; pfixexpr->infixexpr
                         LD   A,B
                         CALL Bind_bank_s1                  ; make sure that expression is paged in
                         PUSH AF                            ; preserve old bank binding
                         PUSH HL
                         XOR  A
                         LD   C,SIZEOF_infixexpr            ; search max. characters for null-terminator
                         PUSH HL
                         CPIR                               ; {find null-terminator}
                         POP  DE
                         SBC  HL,DE
                         LD   A,L
                         LD   C,L                           ; b = strlen(pfixexpr->infixexpr) + 1
                         DEC  A
                         CALL_OZ(Os_Pb)                     ; fputc( strlen(pfixexpr->infixexpr), objfile)
                         LD   DE,0
                         POP  HL
                         POP  AF
                         CALL Bind_bank_s1                  ; {pfixexpr->infixexpr in BHL}
                         CALL Write_string                  ; fwrite(pfixexpr->infixexpr, 1, b, objfile)
                         POP  BC
                         POP  HL
                    POP  DE
                    POP  IX
                    RET

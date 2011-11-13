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

     MODULE GetVarPointer

     LIB Mfree, Read_pointer, Set_pointer
     LIB GetPointer, GetVarPointer

     XDEF FreeVarPointer

     INCLUDE "memory.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"




; ****************************************************************************************
;
; Free room for pointer variable back to OZ memory
;
;    IN: HL = local pointer to pointer variable
;
;    OUT: None.
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.FreeVarPointer     PUSH HL
                    CALL GetVarPointer                 ; *pointer
                    XOR  A
                    CP   B
                    PUSH AF
                    CALL NZ, Mfree                     ; free(*pointer)
                    POP  AF
                    POP  HL
                    RET  Z                             ; if ( *POINTER == NULL ) return
                    PUSH HL
                    CALL GetPointer
                    CALL Mfree                         ; free(pointer)
                    POP  HL
                    LD   (HL),0
                    INC  HL
                    LD   (HL),0
                    INC  HL
                    LD   (HL),0                        ; pointer = NULL
                    RET

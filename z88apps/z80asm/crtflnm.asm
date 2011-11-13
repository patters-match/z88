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

     MODULE CreateFilename

     LIB Bind_bank_s1, Set_pointer
     LIB AllocVarPointer

     XREF CurrentFile, CurrentFileName                      ; currfile.asm
     XREF CopyID                                            ; symbols.asm
     XREF ReportError_NULL                                  ; asmerror.asm


     XDEF CreateFilename


; *****************************************************************************************
;
; Create a file name with specified extension from a copy of the current source file name
;
; In:     HL = local pointer to pointer variable to be created
;         DE = local pointer to extension
;
; Out:    BHL = pointer to created file name, Fc = 0
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.CreateFilename     PUSH DE
                    PUSH HL
                    CALL CurrentFilename               ; get pointer to source file name in BHL
                    CALL CopyID                        ; create a copy, CDE = pointer to copy
                    JR   C, err_createfname            ; Ups - no memory

                    POP  HL                            ; allocate room for pointer variable
                    CALL AllocVarPointer               ; BHL = &filename
                    CALL C, ReportError_NULL           ; Ups - no memory...
                    JR   C, err_createfname
                    XOR  A
                    CALL Set_pointer                   ; filename = Allocidentifier(srcfilename)
                    POP  HL                            ; local pointer to extension
                    PUSH BC
                    PUSH DE
                    LD   A,C
                    CALL Bind_bank_s1
                    PUSH AF
                    LD   A,(DE)                        ; length of file name
                    INC  DE                            ; point at first byte of filename
                    SUB  3                             ; - extension
                    LD   B,0
                    LD   C,A                           ; length of filename in BC
                    EX   DE,HL
                    ADD  HL,BC                         ; HL points at first char of extension
                    LD   C,3
                    EX   DE,HL
                    LDIR                               ; overwrite old extension with new
                    POP  AF
                    CALL Bind_bank_s1
                    POP  HL
                    POP  BC
                    LD   B,C                           ; BHL points at filename...
                    CP   A
                    RET
.err_createfname    POP  HL
                    POP  DE
                    RET

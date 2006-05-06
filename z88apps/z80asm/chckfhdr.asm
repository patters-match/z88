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
; $Id$
;
; ********************************************************************************************************************


     MODULE Check_objfile

     LIB memcompare

     XREF Read_string              ; fileio.asm
     XREF GetVarPointer            ; varptr.asm
     XREF ReportError              ; asmerror.asm

     XDEF CheckObjfile, CheckFileHeader

     INCLUDE "rtmvars.def"


; ************************************************************************************
;
; Read header of file (The first 8 bytes).
;
; The file has just been opened and points at the first byte of the file
;
;    IN:  IX = handle of file.
;
;    OUT: DE points at start of buffer containing header
;
.ReadFileHeader     PUSH HL
                    LD   BC,8
                    LD   HL, Ident                ; read header at (ident)
                    PUSH HL
                    CALL Read_string
                    POP  DE
                    POP  HL
                    RET


; ************************************************************************************
;
; Check header of file. If header is not present, report error.
;
; The file has just been opened and points at the first byte of the file
;
;    IN:  IX = handle of file.
;         HL = pointer to header to be checked
;
;    OUT: A = 0, if header present
;         A = -1, if header not present.
;
;    Registers changed after return
;         ......../IXIY  same
;         AFBCDEHL/....  different
;
;
.CheckFileHeader    CALL ReadFileHeader
                    CALL memcompare
                    LD   A,-1
                    RET  NZ                            ; A = -1 if not equal
                    XOR  A                             ; otherwise A = 0
                    RET


; *********************************************************************************
;
; Check Object file header
;
;    OUT: A = 0, if header present
;         A = -1, if header not present.
;
;    Registers changed after return
;         ......../IXIY  same
;         AFBCDEHL/....  different
;
.CheckObjfile       LD   HL, objheader
                    CALL CheckFileHeader
                    RET  Z
                    LD   A, ERR_not_relfile
                    LD   HL, objfilename
                    CALL GetVarPointer
                    LD   DE,0
                    CALL ReportError              ; ReportError( objfilename, 0, 26)
                    LD   A,-1                     ; header is illegal
                    RET
.objheader          DEFM "Z80RMF01"

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

     MODULE mCreateLibFileName

     LIB AllocIdentifier

     XREF ReportError_NULL                             ; asmerror.asm
     XREF Open_file, fseek                             ; fileio.asm

     XDEF CreateLibFileName

     INCLUDE "rtmvars.def"
     INCLUDE "fileio.def"
     INCLUDE "error.def"


; ****************************************************************************************
;
;    Create library file from filename stored at (DE)
;    The '.lib' extension will be added, if not present.
;
;    IN:  (DE) = filename
;    OUT: BHL = pointer to library filename (length prefixed & null-terminated)
;
.CreateLibFileName  PUSH DE
                    INC  DE
                    LD   HL, libext                    ; pointer 'lib' extension
                    LD   B, -1                         ; write extension (and create current path)
                    LD   C, MAX_IDLENGTH
                    LD   A, @10000001
                    CALL_OZ(Gn_Esa)                    ; write '.lib' extension
                    POP  HL                            ; point at length identifier of filename
                    JP   C, ReportError_NULL
                    DEC  C
                    LD   (HL),C                        ; store length of filename
                    CALL AllocIdentifier
                    JP   C, ReportError_NULL
                    RET

.libext             DEFM "lib"

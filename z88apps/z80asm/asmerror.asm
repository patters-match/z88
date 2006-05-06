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

     MODULE Assembler_errors

     XREF Report_Error
     XREF CurrentFileName, CurrentFileLine

     XDEF STDerr_syntax, STDerr_ill_ident
     XDEF ReportError_NULL, ReportError_STD

     INCLUDE "rtmvars.def"


; ***************************************************************************
;
; ReportError( CURRENTFILE->fname, CURRENTFILE->line, <Syntax error> )
;
.STDerr_syntax      LD   A, ERR_syntax
                    CALL ReportError_STD
                    RET


; ========================================================================================
;
; ReportError( CURRENTFILE->fname,CURRENTFILE->line, <Illegal Ident> )
;
.STDerr_ill_ident   LD   A, ERR_ill_ident
                    CALL ReportError_STD
                    RET


; ========================================================================================
;
;         A   = error code (referring to the error message)
;
.ReportError_STD    PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    CALL CurrentFileName               ; CURRENTFILE->fname in BHL
                    CALL CurrentFileLine               ; CURRENTFILE->line in DE
                    CALL Report_Error
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET


; **************************************************************************************************
;
.ReportError_NULL   PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   B,0
                    LD   H,B
                    LD   L,B
                    LD   D,B
                    LD   E,B
                    CALL Report_Error                   ; ReportError(NULL, 0, ERR)
                    POP  HL
                    POP  DE
                    POP  BC
                    RET

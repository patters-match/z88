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

     MODULE Current_file

     LIB Read_pointer, Read_word

     XREF CurrentModule
     XDEF CurrentFile, CurrentFileName, CurrentFileLine

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
; Return pointer to current file in BHL
;
.CurrentFile        PUSH AF
                    CALL CurrentModule            ; get pointer to current module
                    LD   A, module_cfile
                    CALL Read_pointer             ; get pointer to current file
                    POP  AF
                    RET


; **************************************************************************************************
;
; Return pointer to current filename in BHL
;
.CurrentFileName    PUSH AF
                    CALL CurrentFile              ; get pointer to current file
                    XOR  A
                    CP   B
                    JR   Z, no_filename           ; no file present
                    LD   A, srcfile_fname
                    CALL Read_pointer             ; get pointer to filename of current file
.no_filename        POP  AF
                    RET


; **************************************************************************************************
;
; Return current linenumber of sourcefile in DE
;
.CurrentFileLine    PUSH AF
                    PUSH BC
                    PUSH HL
                    CALL CurrentFile              ; get pointer to current file in BHL
                    XOR  A
                    CP   B
                    JR   Z, no_file
                    LD   A, srcfile_line
                    CALL Read_word                ; get linenumber of current file (word) in DE
                    POP  HL
                    POP  BC
                    POP  AF
                    RET
.no_file            LD   DE,0
                    POP  HL
                    POP  BC
                    POP  AF
                    RET

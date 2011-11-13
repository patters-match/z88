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

     MODULE Split_codefile

     LIB GetPointer, GetVarPointer, Read_pointer, Set_pointer

     INCLUDE "fileio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"

     XREF Open_file, Close_file, Delete_file      ; fileio.asm
     XREF Copy_file                               ;

     XREF ReportError_NULL                        ; stderror.asm
     XREF CreateFilename                          ; crtflnm.asm

     XDEF SplitCodefile


; ******************************************************************************
;
;    Split code file into 16K blocks. Each file will use a '.bn#' extension,
;    identified with '0' as the first block, then '1' ...
;    If the present code is not larger than 16K then no files are created.
;
.SplitCodefile      LD   BC, 16384
                    LD   HL,(codesize)
                    CP   A
                    SBC  HL,BC
                    RET  C
                    BIT  ASMERROR, (IY + RtmFlags3)
                    RET  NZ                  ; if (codesize > 16384 && !ASMERROR)
                         LD   HL, modulehdr
                         CALL GetVarPointer
                         LD   A, modules_first
                         CALL Read_pointer
                         LD   C,B
                         EX   DE,HL               ; CDE=modulehdr->first
                         LD   HL, curmodule
                         CALL GetPointer
                         XOR  A
                         CALL Set_pointer         ; CURRENTMODULE = modulehdr->first
                         LD   HL, binfilename
                         CALL GetVarPointer
                         INC  HL
                         LD   A, OP_IN
                         CALL Open_file           ; cdefilehandle = fopen(CURRENTFILE->filename,"rb")
                         LD   (cdefilehandle),IX
                         LD   A, '0'-1            ; codeblocknum = '0'-1
                         PUSH AF

.codefile_loop           POP  AF                  ; do
                         INC  A
                         PUSH AF
                         LD   BC, 16384
                         LD   HL,(codesize)
                         LD   D,H
                         LD   E,L
                         CP   A
                         SBC  HL,BC
                         CALL NC, Use16K
                         CALL C, UseRemainder          ; codeblock = (codesize/16384) ? 16384: CODESIZE%16384
                         EX   DE,HL
                         CP   A
                         SBC  HL,DE
                         LD   (codesize),HL            ; codesize -= codeblock
                         PUSH DE

                         LD   HL, bnxext
                         LD   DE, stringconst
                         LD   BC, 3
                         LDIR
                         DEC  DE
                         LD   (DE),A                   ; bnxext[3] = codeblocknum

                         LD   HL, tmpfilename
                         LD   DE, stringconst
                         CALL CreateFilename           ;
                         JR   C, err_codefile
                         INC  HL
                         LD   A, OP_OUT
                         CALL Open_file
                         JR   C, err_codefile
                         LD   (tmpfilehandle),IX

                         XOR  A
                         POP  BC                       ; ABC = codeblock
                         LD   HL, cdefilehandle
                         LD   DE, tmpfilehandle
                         CALL Copy_file                ; Copy_file(cdefilehandle, tmpfilehandle, codeblock)
                         LD   HL, tmpfilehandle
                         CALL Close_file               ; fclose(tmpfilehandle)

                         LD   HL,(codesize)
                         LD   A,H
                         OR   L
                         JR   NZ, codefile_loop   ; while(codesize != 0)

                         POP  AF                  ; remove redundant codeblocknum variable
                         LD   HL, cdefilehandle
                         CALL Close_file          ; fclose(cdefilehandle)
                         LD   HL, binfilename
                         CALL GetVarPointer
                         INC  HL
                         CALL Delete_file         ; remove(binfilename)
                         RET

.err_codefile            POP  BC                  ; remove redundant codeblock variable
                         POP  BC                  ; remove redundant codeblocknum variable
                         CALL ReportError_NULL
                         LD   HL, cdefilehandle
                         CALL Close_file
                         RET

.Use16K                  LD   H,B
                         LD   L,C
                         RET
.UseRemainder            ADD  HL,BC          ; convert back to original codesize
                         RET

.bnxext             DEFM "bn#"

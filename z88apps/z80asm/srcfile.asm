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

     MODULE Sourcefile_management

; external procedures:
     LIB Read_pointer, Set_pointer, Read_word, Set_word
     LIB Set_long
     LIB malloc, mfree
     LIB AllocIdentifier

     XREF CurrentModule                                     ; module.asm
     XREF CurrentFile                                       ; currfile.asm
     XREF ReportError                                       ; errors.asm

; global procedures:
     XDEF PrevFile, NewFile, SetFile


     INCLUDE "stdio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
; IN: None
;
; OUT: CDE = pointer to previous file (now current file)
;
.PrevFile           CALL AllocUsedFile       ; newusedfile = AllocUsedFile()
                    JR   NC, get_prevfile    ; if ( newusedfile == NULL )
                         LD   A,ERR_no_room
                         LD   DE,0
                         CALL ReportError         ; ReportError(NULL, 0, 3)
                         CALL CurrentFile
                         LD   C,B
                         EX   DE,HL               ; return CURRENTFILE (in CDE)
                         RET

.get_prevfile       PUSH BC
                    PUSH HL                  ; {preserve newusedfile}
                    CALL CurrentFile
                    PUSH BC                  ; ownedfile = CURRENTFILE
                    PUSH HL                  ; {preserve ownedfile}
                    LD   A, srcfile_prevsource
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL
                    CALL CurrentModule       ; {CDE = CURRENTFILE->prevsourcefile}
                    LD   A, module_cfile
                    CALL Set_pointer         ; CURRENTFILE = CURRENTFILE->prevsourcefile
                    LD   C,0
                    LD   D,C
                    LD   E,C                  ; {NULL}
                    CALL CurrentFile
                    LD   A, srcfile_newsource
                    CALL Set_pointer         ; CURRENTFILE->newsourcefile = NULL
                    POP  HL
                    POP  BC                  ; {ownedfile}
                    LD   C,0
                    LD   A, srcfile_prevsource
                    CALL Set_pointer         ; ownedfile->prevsourcefile = NULL
                    LD   A,B
                    EX   DE,HL
                    POP  HL
                    POP  BC                  ; {BHL = newusedfile}
                    LD   C,A                 ; {CDE = ownedfile}
                    PUSH BC
                    PUSH DE                  ; {preserve ownedfile}
                    LD   C,B
                    EX   DE,HL               ; {CDE = newusedfile}
                    CALL CurrentFile
                    LD   A, srcfile_usedsrcfile
                    CALL Read_pointer
                    LD   A,B
                    LD   B,C
                    LD   C,A
                    EX   DE,HL               ; {BHL=newusedfile, CDE=CURRENTFILE->usedsourcefile}
                    LD   A,usedfile_nextfile ; newusedfile->nextusedfile = CURRENTFILE->usedsourcefile}
                    CALL Set_pointer
                    LD   C,B
                    EX   DE,HL               ; {CDE = newusedfile}
                    CALL CurrentFile
                    LD   A, srcfile_usedsrcfile
                    CALL Set_pointer         ; CURRENTFILE->usedsourcefile = newusedfile
                    LD   A,C
                    EX   DE,HL
                    POP  DE
                    POP  BC
                    LD   B,A                 ; {BHL=newusedfile, CDE=ownedfile}
                    LD   A,usedfile_nextfile ; newusedfile->ownedsourcefile = ownedfile
                    CALL Set_pointer
                    CALL CurrentFile
                    LD   C,B
                    EX   DE,HL               ; return CURRENTFILE (in CDE)
                    RET


; **************************************************************************************************
;
; IN:     BHL = pointer to current node, curfile
;          DE = local pointer to filename string, fname
;
; OUT:    CDE = pointer to new node
;
;    Registers changed after return:
;         ......../IXIY   same
;         AFBCDEHL/....   different
;
.NewFile            PUSH IX
                    PUSH DE
                    POP  IX                       ; {IX = fname}
                    XOR  A
                    CP   B                        ; if ( curfile == NULL )
                    JR   NZ, set_newfile2
                         CALL AllocFile
                         JR   NC, set_newfile1         ; if ( (curfile = AllocFile()) == NULL )
                              LD   A,ERR_no_room
                              LD   DE,0
                              CALL ReportError              ; ReportError(NULL, 0, 3)
                              LD   C,B
                              EX   DE,HL                    ; return NULL (in CDE)
                              JR   end_newfile
                                                       ; else
.set_newfile1                 LD   C,B
                              EX   DE,HL                    ; {CDE = curfile}
                              LD   B,0
                              LD   H,B
                              LD   L,B
                              CALL Setfile                  ;                curfile:   nfile:  fname:
                              JR   end_newfile              ; return   Set_file( NULL, curfile,  fname )
                                                  ; else
.set_newfile2            PUSH HL                       ; {BHL = curfile}
                         PUSH BC
                         CALL AllocFile                ; nfile = AllocFile()
                         LD   A,B
                         POP  BC
                         LD   C,A
                         EX   DE,HL
                         POP  HL                       ; {BHL = curfile, CDE = nfile}
                         JR   NC, set_newfile3         ; if ( nfile == NULL )
                              LD   A,ERR_no_room
                              LD   DE,0
                              CALL ReportError              ; ReportError(NULL,0,3)
                              LD   C,B
                              EX   DE,HL                    ; return nfile (in CDE)
                              JR   end_newfile
                                                       ; else
.set_newfile3                 CALL Setfile                  ; return Setfile(curfile, nfile, fname)

.end_newfile        POP  IX
                    RET


; **************************************************************************************************
;
; IN:     BHL = pointer to current node, curfile
;         CDE = pointer to new node, nfile
;          IX = local pointer to filename string, fname
;
; OUT:    CDE = pointer to new node, nfile
;
;    Registers changed after return:
;         ......../IXIY   same
;         AFBCDEHL/....   different
;
.SetFile            PUSH HL
                    PUSH BC
                    PUSH DE
                    PUSH IX
                    POP  HL
                    CALL AllocIdentifier               ; filename = AllocIdentifier(fname)
                    JR   NC, set_file_record           ; if ( filename == NULL )
                         LD   A,ERR_no_room
                         LD   DE,0
                         CALL ReportError                   ; ReportError(NULL,0,3)
                         POP  DE
                         POP  BC
                         POP  HL                            ; return nfile (in CDE)
                         RET
.set_file_record    LD   A,B
                    EX   DE,HL                         ; {CDE = filename
                    POP  HL
                    POP  BC
                    PUSH BC
                    LD   B,C
                    LD   C,A                           ; {BHL=nfile, CDE=filename}
                    LD   A, srcfile_fname
                    CALL Set_pointer                   ; nfile->fname = filename
                    LD   A,B
                    POP  BC
                    LD   C,B
                    LD   B,A
                    POP  DE                            ; {BHL=nfile, CDE=curfile}
                    LD   A, srcfile_prevsource
                    CALL Set_pointer                   ; nfile->prevsourcefile = curfile
                    LD   C,0
                    LD   D,C
                    LD   E,C
                    LD   A, srcfile_newsource
                    CALL Set_pointer                   ; nfile->newsourcefile = NULL
                    LD   A, srcfile_usedsrcfile
                    CALL Set_pointer                   ; nfile->usedsourcefile = NULL
                    LD   A, srcfile_line
                    CALL Set_word                      ; nfile->line = 0
                    PUSH DE
                    PUSH DE
                    EXX
                    POP  BC
                    POP  DE                            ; fileptr = 0
                    EXX
                    LD   A, srcfile_filepointer
                    CALL Set_long                      ; nfile->filepointer = 0
                    LD   C,B
                    EX   DE,HL                         ; return nfile (in CDE)
                    RET



; **************************************************************************************************
;
;
.AllocFile          LD   A, SIZEOF_srcfile
                    CALL malloc
                    RET


; **************************************************************************************************
;
;
.AllocUsedFile      LD   A, SIZEOF_usedfile
                    CALL malloc
                    RET

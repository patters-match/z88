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

     MODULE AsmSourceFiles

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"

     LIB mfree
     LIB AllocIdentifier
     LIB GetPointer, GetVarPointer
     LIB Read_pointer, Set_pointer
     LIB Read_word, Set_word
     LIB delete_all

     XREF ReportError, ReportError_NULL, ReportError_STD    ; asmerror.asm
     XREF FreeSym, DefineDefSym                             ; symbols.asm
     XREF LoadName                                          ; loadname.asm
     XREF FindSymbol, CopyStaticLocal                       ; symbols.asm
     XREF CurrentModule, ReleaseExpressions                 ; module.asm
     XREF CreateFilename                                    ; crtflnm.asm
     XREF Open_file, Close_file, fseek                      ; fileIO.asm
     XREF Read_fptr, Read_string, Delete_file               ; fileIO.asm
     XREF FreeVarPointer                                    ; varptr.asm
     XREF Init_CDEbuffer, FlushBuffer                       ; bytesIO.asm
     XREF Z80pass1                                          ; Z80pass1.asm
     XREF Z80pass2                                          ; Z80pass2.asm
     XREF CheckObjfile                                      ; chckfhdr.asm
     XREF GetFileStamp, CheckDateStamps                     ; datestmp.asm
     XREF WriteSymbols                                      ; wrsymbol.asm
     XREF WriteGlobals                                      ; wrglobal.asm
     XREF CurrentFile, CurrentFileName                      ; currfile.asm
     XREF Display_filename                                  ; srcfile.asm
     XREF CreateasmPC_ident                                 ; asmpcid.asm

     XDEF Init_Sourcefile, AsmSourceFiles, Close_files
     XDEF empty_msg

; global variables:
     XREF cdefile

; ********************************************************************************************************************
;
.Init_Sourcefile    LD   HL, linebuffer
                    LD   (lineptr),HL
                    LD   (nextline),HL
                    LD   (buffer_end),HL
                    RET


; ********************************************************************************************************************
;
; Assemble module files, if necessary...
;
.AsmSourceFiles     XOR  A
                    LD   H,A
                    LD   L,A
                    LD   (TOTALERRORS),A          ; TOTALERRORS = 0
                    LD   (codesize),HL            ; codesize = 0
                    LD   (totallines),HL          ; totallines = 0

                    LD   HL, modulehdr
                    CALL GetVarPointer
                    LD   A,modules_first
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL                    ; {CDE = modulehdr->first}
                    LD   HL,CURMODULE
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer              ; CURRENTMODULE = modulehdr->first

                    CALL Create_Z88_ident         ; DefineDefSym( "Z88", -1, &staticroot )

                    BIT  globaldef, (IY + RTMflags)
                    CALL NZ, CreateDefFileName    ; deffile = CreateDefFileName(CurrentFile)
                    JP   C, ReportError_NULL      ; (global def file will be created after assembly)
.asmfiles_loop                                    ; do
                    RES  EOF,(IY + RtmFlags3)          ; clear file flag
                    RES  ASMERROR,(IY + RtmFlags3)     ; reset to no errors for this module
                    LD   A, -1
                    LD   (ASSEMBLE_ERROR),A            ; reset global error variable
                    LD   HL,0
                    LD   (codeptr),HL                  ; codeptr = 0
                    LD   (asm_pc),HL                   ; asm_pc = 0

                    CALL CreateasmPC_ident            ; create "ASMPC" in globalroot
                    CALL CopyStaticLocal               ; copy static symbols to current local variables

                    CALL CurrentModule
                    LD   DE,(codesize)
                    LD   A, module_startoffset
                    CALL Set_word                      ; CURRENTMODULE->startoffset = codesize

                    LD   HL, objfilename
                    LD   DE, objext                    ; Create oject file name from current
                    CALL CreateFilename                ; source file name
                    JP   C, ReportError_NULL

                    CALL TestAsmFile                   ; flag = Test.asmFile()
                    CP   -1
                    RET  Z                             ; if ( flag == -1 ) return
                    CP   1
                    CALL Z, AsmSourceFile              ; if ( flag == 1 ) .asmSourceFile()
                    CALL Close_files                   ; close any open module files
                    LD   HL, objfilename
                    CALL FreeVarPointer                ; release pointer variable back to OZ memory

                    PUSH IY
                    LD   IY, FreeSym
                    LD   HL, globalroot
                    PUSH HL
                    CALL GetVarPointer
                    CALL delete_all                    ; delete_all(globalroot, FreeSym)
                    POP  HL
                    CALL GetPointer
                    LD   C,0
                    LD   D,C
                    LD   E,C                           ; CDE = NULL
                    XOR  A
                    CALL Set_pointer                   ; globalroot = NULL

                    CALL CurrentModule
                    PUSH BC
                    PUSH HL
                    LD   A, module_localroot
                    CALL Read_pointer
                    CALL delete_all                    ; delete_all(CURRENTMODULE->localroot, FreeSym)
                    POP  HL
                    POP  BC
                    LD   C,0
                    LD   D,C
                    LD   E,C                           ; CDE = NULL
                    LD   A, module_localroot
                    CALL Set_pointer                   ; CURRENTMODULE->localroot = NULL
                    POP  IY

                    CALL ReleaseExpressions            ; ReleaseExpressions()

                    CALL CurrentModule
                    LD   A, module_next
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL
                    LD   HL, CURMODULE
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer                   ; CURRENTMODULE = CURRENTMODULE->next
                    XOR  A
                    CP   C
                    JP   NZ, asmfiles_loop        ; while ( CURRENTMODULE != NULL )
                    RET


; *****************************************************************************************
;
;    IN: None.
;
.asmSourceFile      LD   HL, objfilename
                    CALL GetVarPointer                 ; BHL points at file name
                    CALL CreateObjfile                 ; Create object file, and write header...
                    JP   C, ReportError_NULL

                    BIT  symtable, (IY + RTMflags)
                    CALL NZ, CreateSymFile             ; create symbol file...
                    RET  C

                    LD   A, OP_OUT
                    LD   B,0
                    LD   HL, cdefile
                    CALL Open_file                     ; open ':RAM.-/temp.buf'
                    JP   C, ReportError_NULL
                    LD   (cdefilehandle),IX            ; preserve handle for future file references
                    CALL Init_CDEbuffer                ; reset code buffer variables

                    LD   HL, errfilename
                    LD   DE, errext
                    CALL CreateFilename
                    JP   C, ReportError_NULL
                    INC  HL                            ; point at first char in filename
                    LD   A, OP_OUT
                    CALL Open_file
                    JP   C, ReportError_NULL
                    LD   (errfilehandle),IX            ; error file created...

                    CALL disp_pass1
                    CALL Z80pass1                      ; Pass1: Parsing & code generation...
                    CALL FlushBuffer                   ; ensure that all machine code is written to file...
                    LD   HL, cdefilehandle
                    CALL Close_file                    ; close ':ram.-/temp.buf'

                    CALL CurrentModule
                    LD   A, module_mname
                    CALL Read_pointer
                    XOR  A
                    CP   B
                    JR   NZ, continue_asm              ; if ( CURRENTMODULE->mname == NULL )
                         CALL CurrentFileName
                         LD   DE,0
                         LD   A, ERR_modname_notdef
                         CALL ReportError                   ; ReportError(*, 0, 16)

.continue_asm       BIT  ASMERROR,(IY + RtmFlags3)
                    JR   NZ, finish_assembly           ; if ( !ASMERROR )
                         CALL disp_pass2
                         LD   A, OP_UP
                         LD   B,0
                         LD   HL, cdefile
                         CALL Open_file
                         JP   C, ReportError_NULL
                         LD   (cdefilehandle),IX
                         CALL Z80pass2                      ; Pass2: Expression evaluation & patching...

                    BIT  globaldef,(IY + RTMflags)
                    JR   Z, write_symfile              ; if ( globaldef )
                         CALL WriteGlobals                  ; WriteGlobals()
.write_symfile      BIT  symtable,(IY + RTMflags)
                    JR   Z, finish_assembly             ; if ( symtable )
                         CALL WriteSymbols                  ; WriteSymbols

.finish_assembly    CALL Close_files                   ; close source, object, code, symbol & error files
                    BIT  ASMERROR, (IY + RtmFlags3)
                    LD   HL, errfilename
                    CALL Z, DeleteFile                 ; delete error file, if no assembler errors
                    LD   HL, symfilename
                    CALL NZ, DeleteFile                ; delete symbol file
                    LD   HL, objfilename
                    CALL NZ, DeleteFile                ; delete object file, if assembler errors

                    LD   HL, errfilename
                    CALL FreeVarPointer                ; release pointer variable back to OZ memory

                    LD   HL, symfilename
                    JP   FreeVarPointer                ; release pointer variable back to OZ memory


; *****************************************************************************************
;
;    Create the standard "Z88" identifier (defined in static variable area)
;
.Create_Z88_ident   LD   HL, Z88_ident                 ; DEFINE a symbol...
                    CALL AllocIdentifier                    ; tmpident to extended memory, BHL = .asmpc_ident
                    JP   C, ReportError_NULL
                    PUSH BC
                    PUSH HL                                 ; preserve pointer to temporary identifier
                    LD   C,B
                    EX   DE,HL                              ; tmpident in CDE
                    EXX
                    LD   BC,-1
                    LD   D,B
                    LD   E,C
                    EXX
                    LD   HL, staticroot
                    CALL GetPointer                         ; &staticroot in BHL
                    LD   A,0
                    CALL DefineDefSym                       ; DefineDefSym("Z88", 0, 0, &staticroot)

                    POP  HL
                    POP  BC
                    JP   mfree                              ; free(tmpident)


; *****************************************************************************************
;
;    IN:  None.
;
;    OUT: A = -1, file open error
;         A = 0, use object file information
;         A = 1, assemble source file
;
.TestAsmFile        BIT  datestamp,(IY + RTMflags)     ; if ( datestamp )
                    JR   Z, open_force
                         LD   DE, datestamp_src
                         CALL CurrentFileName
                         INC  HL
                         CALL GetFileStamp                  ; if ( stat(CURRENTFILE->fname, &afile) == -1 )
                         JP   C, GetModuleInfo                   return GetModuleInfo()
                              LD   DE, datestamp_obj        ; else
                              LD   HL, objfilename
                              CALL GetVarPointer
                              INC  HL
                              CALL GetFileStamp                  ; if ( stat(objfilename, &ofile) != -1 )
                              JR   C, open_force                      ; if ( afile.st_mtime <= ofile.st_mtime )
                                   CALL CheckDateStamps
                                   JP   Z, GetModuleInfo                   ; return GetModuleInfo()

.open_force         LD   HL, empty_msg
                    CALL_OZ(Gn_sop)                    ; puts("");
                    CALL CurrentFileName
                    INC  HL
                    CALL Display_filename              ; puts(CURRENTFILE->fname)
                    LD   A, OP_IN
                    CALL Open_file                     ; open source file of current module
                    JR   C, openforce_err
                    LD   (srcfilehandle),IX
                    CALL Init_sourcefile
                    SET  srcfile_open, (IY + RtmFlags3); srcfile_open = 1
                    LD   A,1
                    RET
.openforce_err      CALL ReportError_NULL
                    LD   A,-1
                    RET


; *****************************************************************************************
;
; Read information from module file and store information in current module record.
;
.GetModuleInfo      LD   HL, objfilename
                    CALL GetVarPointer                 ; BHL = pointer to object file name
                    INC  HL
                    LD   A, OP_IN
                    CALL Open_file
                    JP   C, objfile_error              ; if ( (objfile = fopen(objfilename, "rb") != NULL )
                         CALL CheckObjfile                  ; if ( CheckObjfile() == -1 )
                         JR   Z, read_objfile
                              CALL_OZ(Gn_Cl)                     ; fclose(objfile)
                              LD   A,-1                          ; return -1;
                              RET

.read_objfile            LD   HL,0
                         LD   (longint+2),HL
                         LD   L,26
                         LD   (longint),HL
                         LD   B,H                           ; {local pointer}
                         LD   HL, longint
                         CALL fseek                         ; fseek(objfile, 26, SEEK_SET)
                         LD   HL, fptr_modcode
                         CALL Read_fptr                     ; fptr_modcode = ReadLong(objfile)
                         LD   A,(fptr_modcode+3)
                         CP   -1
                         JR   Z, end_moduleinfo             ; if ( fptr_modcode != -1 )
                              CALL fseek                         ; fseek(objfile, fptr_modcode, SEEK_SET)
                              CALL_OZ(Os_Gb)
                              LD   E,A
                              CALL_OZ(Os_Gb)
                              LD   D,A
                              PUSH DE
                              CALL CurrentModule
                              LD   A, module_startoffset
                              CALL Read_word
                              EX   DE,HL
                              POP  DE
                              ADD  HL,DE                    ; if ( CURRENTMODULE->startoffset+size > 64K )
                              JR   NC, update_codesize
                                   LD   A, ERR_max_codesize
                                   LD   HL, objfilename
                                   CALL GetVarPointer
                                   LD   DE,0
                                   CALL ReportError              ; ReportError(objfilename, 0, 12)
                                   JR   get_module_name     ; else
.update_codesize              LD   HL,(codesize)
                              ADD  HL,DE
                              LD   (codesize),HL                 ; CODESIZE += size

.get_module_name         LD   HL,0
                         LD   (longint+2),HL
                         LD   L,10
                         LD   (longint),HL
                         LD   B,H                           ; {local pointer}
                         LD   HL, longint
                         CALL fseek                         ; fseek(objfile, 10, SEEK_SET)
                         LD   HL, fptr_modname
                         CALL Read_fptr                     ; fptr_modname = ReadLong(objfile)
                         CALL fseek                         ; fseek(objfile, fptr_modname, SEEK_SET)
                         CALL LoadName                      ; Loadname(objfile)
                         CALL AllocIdentifier               ; if ( (m = AllocIdentifier(size+1)) == NULL )
                         JR   NC, define_modname
                              LD   A, ERR_no_room
                              CALL ReportError_NULL              ; ReportError(3)
                              JR   end_moduleinfo           ; else
.define_modname          LD   C,B
                         EX   DE,HL
                         CALL CurrentModule
                         LD   A, module_mname                    ; strcpy(m, ident)
                         CALL Set_pointer                        ; CURRENTMODULE->mname = m

.end_moduleinfo          CALL_OZ(Gn_Cl)                     ; fclose(objfile)

                         LD   HL, using_msg
                         CALL_OZ(Gn_sop)                    ; printf("Using ");
                         LD   HL, objfilename
                         CALL GetVarPointer                 ; BHL = pointer to object file name
                         INC  HL
                         CALL Display_filename              ; puts(objfilename)

                         XOR  A                             ; return 0
                         RET

.objfile_error      CALL ReportError_NULL                   ; reportError(0)
                    LD   A,-1                               ; return -1
                    RET


; ****************************************************************************************
;
.CreateSymFile      LD   HL, symfilename
                    LD   DE, symext
                    CALL CreateFilename
                    JP   C, ReportError_NULL
                    INC  HL                            ; point at first char in filename
                    LD   A, OP_OUT
                    CALL Open_file
                    JP   C, ReportError_NULL
                    LD   (symfilehandle),IX            ; symbol file created...
                    RET


; ****************************************************************************************
;
; Create global definition filename, but only if source can be opened...
;
.CreateDefFileName  CALL CurrentFileName
                    INC  HL
                    LD   A, OP_IN
                    CALL Open_file                     ; try to open source file of current module
                    RET  C                             ; Ups - not possible...
                    CALL_OZ(Gn_Cl)

                    LD   HL, deffilename
                    LD   DE, defext
                    CALL CreateFilename
                    JP   C, ReportError_NULL
                    RET


; ****************************************************************************************
;
; IN:     BHL = pointer to object file name (at length identifier of name)
;
.CreateObjfile      PUSH BC
                    INC  HL                            ; point at first char in file name
                    PUSH HL
                    LD   A, OP_OUT
                    CALL Open_file
                    JR   C, objcreate_err
                    LD   BC, 30
                    LD   DE,0
                    LD   HL, Z80header
                    CALL_OZ(Os_Mv)                     ; write header to objfile
                    CALL_OZ(Gn_Cl)
                    POP  HL
                    POP  BC
                    LD   A, OP_UP
                    CALL Open_file
                    LD   (objfilehandle),IX            ; store file handle
                    LD   DE,30
                    LD   (longint),DE
                    LD   E,0
                    LD   (longint+2),DE
                    LD   B,0
                    LD   HL, longint
                    JP   fseek                         ; set file pointer at end of objfile
.objcreate_err
                    POP  HL
                    POP  BC
                    RET
.Z80header          DEFM "Z80RMF01oomodnexprnamelibnmodc"


; *****************************************************************************************
;
; Delete file from OZ memory
;
;    IN:  HL = local pointer to &filename pointer.
;
.DeleteFile         PUSH AF
                    CALL GetVarPointer            ; get pointer to error file name
                    XOR  A
                    CP   B
                    JR   Z, exit_delfile               ; if ( filename != NULL )
                    INC  HL
                    CALL Delete_file                   ; remove(filename)
.exit_delfile       POP  AF
                    RET


; ****************************************************************************************
;
.Close_files        LD   HL,srcfilehandle
                    CALL Close_file
                    LD   HL,cdefilehandle
                    CALL Close_file
                    LD   HL,objfilehandle
                    CALL Close_file
                    LD   HL,errfilehandle
                    CALL Close_file
                    LD   HL,symfilehandle
                    CALL Close_file
                    LD   HL,relocfilehandle
                    JP   Close_file


; ****************************************************************************************
;
.Disp_pass1         LD   HL, pass1_msg
                    CALL_OZ(Gn_Sop)
                    RET


; ****************************************************************************************
;
.Disp_pass2         LD   HL, pass2_msg
                    CALL_OZ(Gn_Sop)
                    RET


; ****************************************************************************************
.objext             DEFM "obj"
.defext             DEFM "def"
.errext             DEFM "err"
.symext             DEFM "sym"

.pass1_msg          DEFM 1, "2H5Pass1...", CR,LF,0
.pass2_msg          DEFM 1, "2H5Pass2...", CR,LF,0
.Z88_ident          DEFM 3, "Z88", 0
.empty_msg          DEFM 1, "2H5", 13, 10, 0
.using_msg          DEFM 1, "2H5", "Using ", 0

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

     MODULE z80asm_Main


; external procedures:
     LIB init_malloc, release_pools, mfree
     LIB Bind_bank_s1
     LIB Read_pointer, Set_pointer
     LIB Read_word, Set_word
     LIB GetPointer, GetVarPointer, AllocVarPointer
     LIB AllocIdentifier
     LIB delete_all

     XREF Command_line                                      ; cmdline.asm
     XREF Z80pass1, Display_integer                         ; Z80pass1.asm
     XREF Z80pass2                                          ; Z80pass2.asm
     XREF LinkModules                                       ; linkmod.asm
     XREF CurrentModule, NewModule, ReleaseExpressions      ; module.asm
     XREF NewFile, Display_filename                         ; srcfile.asm
     XREF CurrentFile, CurrentFileName                      ; currfile.asm
     XREF Init_CDEbuffer, FlushBuffer                       ; bytesIO.asm
     XREF ReportError, ReportError_NULL, ReportError_STD    ; ASMERROR.asm

     XREF z80asm_errmsg, Get_stdoutp_handle                 ; stderror.asm
     XREF Write_stdmessage                                  ;

     XREF z80asm_windows                                    ; windows.asm
     XREF Get_time, Display_asmtime                         ; comptime.asm
     XREF Disp_allocmem                                     ; dispmem.asm
     XREF SplitCodefile                                     ; spltfile.asm

     XREF FreeSym, DefineSymbol, DefineDefSym               ; symbols.asm
     XREF FindSymbol, CopyStaticLocal                       ;

     XREF z80asm_ERH                                        ; ehandler.asm
     XREF GetFileStamp, CheckDateStamps                     ; datestmp.asm
     XREF WriteSymbols                                      ; wrsymbol.asm
     XREF WriteGlobals                                      ; wrglobal.asm
     XREF WriteMapFile                                      ; mapfile.asm
     XREF CreateFilename                                    ; crtflnm.asm
     XREF CheckObjfile                                      ; chckobjf.asm
     XREF MakeLibrary                                       ; makelib.asm
     XREF LoadName                                          ; loadname.asm

     XREF Open_file, Close_file, Close_files, fseek         ; fileIO.asm
     XREF Read_fptr, Read_string, Delete_file               ;
     XREF Delete_bufferfiles                                ;

     XREF FreeVarPointer                                    ; varptr.asm

; global variables:
     XDEF cdefile
     XDEF objext, defext, binext, errext, libext
     XDEF z80header

; global variables - these declarations MUST be declared global:
; ( "defs_h" defines their address constants )

     XDEF pool_index, pool_handles, MAX_POOLS
     XDEF allocated_mem

; global procedures:
     XDEF Init_sourcefile
     XDEF CreateasmPC_ident
     XDEF Keyboard_interrupt

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "saverst.def"
     INCLUDE "director.def"
     INCLUDE "memory.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"
     INCLUDE "applic.def"
     INCLUDE "mth.def"

     ORG z80asm_DOR

; The Z80 Assembler application DOR:
;

                    DEFB 0, 0, 0                        ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                            ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0              ; total length of DOR
.DORStart0          DEFB '@'                            ; Key to info section
                    DEFB InfoEnd0-InfoStart0            ; length of info section
.InfoStart0         DEFW 0                              ; reserved...
                    DEFB 'A'                            ; application key letter
                    DEFB 0                              ;
                    DEFW 0                              ;
                    DEFW 0                              ; Unsafe workspace
                    DEFW z80asm_workspace               ; Safe workspace
                    DEFW z80asm_entry                   ; Entry point of code in seg. 2
                    DEFB 0                              ; bank binding to segment 0   (Intuition, for debugging)
                    DEFB 0                              ; bank binding to segment 1
                    DEFB z80asm_bank1                   ; bank binding to segment 2   (z80asm)
                    DEFB z80asm_bank2                   ; bank binding to segment 3   (z80asm)
                    DEFB @00000001                      ; Good application
                    DEFB 0                              ; no caps lock on activation
.InfoEnd0           DEFB 'H'                            ; Key to help section
                    DEFB 12                             ; total length of help
                    DEFW z80asm_topics
                    DEFB z80asm_MTH_bank                ; point to topics (info)
                    DEFW z80asm_commands
                    DEFB z80asm_MTH_bank                ; point to commands (info)
                    DEFW z80asm_help
                    DEFB z80asm_MTH_bank                ; point to help
                    DEFW token_base
                    DEFB tokens_bank                    ; point to token base
                    DEFB 'N'                            ; Key to name section
                    DEFB NameEnd0-NameStart0            ; length of name
.NameStart0         DEFM "Z80asm", 0
.NameEnd0           DEFB $FF
.DOREnd0




; ************************************************************************************************************
;
.z80asm_entry
                    CALL InitVars                      ; reset variables, pointers...
                    CALL z80asm_windows                ; Display Z80 assembler windows
;                    CALL Intuition_init                ; activate Intuition (resided in segment 0)

.z80asm_loop        CALL Init_malloc                   ; do
                    CALL InitPointers                       ; initialize memory allocation in segment 1.
                    CALL InitFiles                          ; and clear file variables.

                    RES  deforigin, (IY + RTMflags)         ; prepare for new explicit origin
                    RES  library, (IY + RTMflags)
                    RES  createlib, (IY + RTMflags)         ; prepare for new libraries, or none...
                    RES  autorelocate, (IY + RTMflags2)
                    RES  codesegment, (IY + RTMflags2)
                    RES  applname,(IY + RtmFlags3)          ; prepare for new application ref. name

                    CALL Command_line                       ; Enter assembler commands...
                    JR   C, z80asm_loop                     ; Ups - syntax error or no modules, try again...
                                                       ; while ( modulehdr == NULL )
                    CALL Get_time
                    CALL AsmSourceFiles                ; AsmSourceFiles()
                    CALL Close_files                   ; close any open files...

                    BIT  createlib, (IY + RTMflags)
                    CALL NZ, MakeLibrary               ; Create library from compiled object modules

                    BIT  z80bin, (IY + RTMflags)
                    JR   Z, assembly_completed         ; if Z80bin
                         CALL LinkModules                   ; Link object modules into executable machine code
                         BIT  codesegment, (IY + RTMflags2)
                         CALL NZ, SplitCodefile             ; if (codesegment) SplitCodefile()
                         BIT  mapref, (IY + RTMflags)
                         CALL NZ, WriteMapFile              ; Write address map file of relocated machine code

.assembly_completed CALL Delete_bufferfiles            ; delete any redundant files in :RAM.-
                    CALL Disp_allocmem                 ; first display amount of RTM memory
                    CALL Release_pools                 ; then free RTM memory
                    CALL DisplayErrors                 ; display error status, if necessary...
                    JR   z80asm_loop



; ****************************************************************************************
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
                    CALL NZ, CreateDefFile        ; deffile = fopen( "xxx.def", "w")
                    JP   C, ReportError_NULL

                    RES  abort,(IY + RtmFlags3)   ; reset keyboard abort status

                    LD   HL, break_msg
                    CALL_OZ(Gn_Sop)               ; "Use []ESC to abort assembly or linking"

.asmfiles_loop                                    ; do
                    RES  EOF,(IY + RtmFlags3)          ; clear file flag
                    RES  ASMERROR,(IY + RtmFlags3)     ; reset to no errors for this module
                    LD   A, -1
                    LD   (ASSEMBLE_ERROR),A            ; reset global error variable
                    LD   HL,0
                    LD   (codeptr),HL                  ; codeptr = 0
                    LD   (asm_pc),HL                   ; asm_pc = 0

                    CALL Keyboard_interrupt            ; Keyboard_interrupt()
                    JP   Z, end_asmsrcfiles            ; abort-keys pressed, stop parsing...

                    CALL CreateasmPC_ident            ; create "ASMPC" in globalroot
                    CALL CopyStaticLocal               ; copy static symbols to current local variables

                    CALL CurrentModule
                    LD   DE,(codesize)
                    LD   A, module_startoffset
                    CALL Set_word                      ; CURRENTMODULE->startoffset = codesize

                    LD   HL, objfilename
                    LD   DE, objext                    ; Create oject file name from current
                    CALL CreateFilename                ; source file name
                    CALL C, ReportError_NULL
                    JR   C, end_asmsrcfiles

                    CALL TestAsmFile                   ; flag = Test.asmFile()
                    CP   -1
                    JR   Z, end_asmsrcfiles            ; if ( flag == -1 ) return
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
                    CALL Disp_allocmem

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

.end_asmsrcfiles    CALL Disp_totallines          ; disptotallines()
                    LD   HL,deffilehandle
                    CALL Close_file               ; fclose(deffile) {if previously opened}
                    RET



; *****************************************************************************************
;
;    Create the standard "ASMPC" identifier in the global variable area.
;    The z80asm runtime variable asm_pc_ptr holds the pointer to the created symbol.
;
.CreateasmPC_ident  LD   HL, asmpc_ident
                    CALL AllocIdentifier                    ; tmpident to extended memory, BHL = asmpc_ident
                    JP   C, ReportError_NULL
                    LD   C,B
                    EX   DE,HL                              ; .asmpc_ident in CDE
                    PUSH BC
                    PUSH DE                                 ; preserve pointer to temporary identifier
                    EXX
                    LD   BC,0
                    LD   D,B
                    LD   E,C
                    EXX
                    LD   HL, globalroot
                    CALL GetPointer                         ; &globalroot in BHL
                    LD   A,0
                    CALL DefineDefSym                       ; DefineDefSym(asmpc_tmpident, 0, 0, &globalroot)
                    JR   C, err_create_asmpc
                    POP  DE
                    POP  BC
                    PUSH BC
                    PUSH DE
                    LD   HL, globalroot
                    CALL GetVarPointer                      ; globalroot in BHL
                    CALL FindSymbol
                    EX   DE,HL
                    LD   C,B
                    LD   HL,asm_pc_ptr
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer                        ; asm_pc_ptr = FindSymbol(.asmpc_ident, globalroot)
                    CP   A
                    JR   exit_create_asmpc

.err_create_asmpc   LD   A, Err_no_room
                    CALL ReportError_NULL

.exit_create_asmpc  POP  HL
                    POP  BC
                    LD   B,C
                    PUSH AF
                    CALL mfree                              ; free(tmpident)
                    POP  AF
                    RET


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
                    CALL mfree                              ; free(tmpident)
                    RET


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
                         CALL CheckObjfile
                         CP   -1                            ; if ( CheckObjfile() == -1 )
                         JR   NZ, read_objfile
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
                         CALL Disp_allocmem                 ; display amount of allocated memory
                         CALL Z80pass2                      ; Pass2: Expression evaluation & patching...
                         CALL Disp_allocmem                 ; display amount of allocated memory
                    BIT  globaldef,(IY + RTMflags)
                    JR   Z, write_symfile              ; if ( globaldef )
                         LD   HL, globalroot
                         CALL GetVarPointer
                         CALL WriteGlobals                  ; WriteGlobals(globalroot)
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
                    CALL FreeVarPointer                ; release pointer variable back to OZ memory
                    RET


; *****************************************************************************
;
; Read the keyboard and check if <SQUARE><ESC> is pressed.
; If pressed (the binary pattern in register A is 0 at the keys pressed down),
; the current compiling process instructions is stopped and the command
; line is re-entered.
;
; Register status after return:
;
;       ..BCDEHL/IXIYPC  same
;       AF....../......  different
;
; Fz = 1, when abort keys pressed, otherwise Fz = 0.
;
.Keyboard_interrupt PUSH BC
                    LD   BC,$7FB2                 ; port $B2, keyboard row A15
                    IN   A,(C)                    ; scan A15...
                    POP  BC
                    AND  @01100000                ; <SQU><ESC> pressed?
                    RET  NZ                       ; no, continue assembler processing

                    PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX
                    SET  abort,(IY + RtmFlags3)
                    SET  ASMERROR,(IY + RtmFlags3)
                    LD   A, ERR_keyboard_abort
                    CALL z80asm_errmsg            ; HL points to error message
                    CALL Get_stdoutp_handle       ; IX contains handle to std. output
                    CALL Write_stdmessage         ; display "Assembly aborted from keyboard"
                    CALL_OZ(Gn_Nln)
                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    CP   A                        ; signal keyboard abortion!
                    RET



; *****************************************************************************************
;
.DisplayErrors      LD   A,(TOTALERRORS)
                    CP   0
                    JP   Z, Display_AsmTime       ; display time used to assemble file (if no errors)
                    LD   A, ERR_totalerrors
                    CALL ReportError_NULL
                    CALL Wait_key
                    RET



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
                    CALL fseek                         ; set file pointer at end of objfile
                    CP   A
                    RET
.objcreate_err      POP  HL
                    POP  BC
                    RET
.Z80header          DEFM "Z80RMF01oomodnexprnamelibnmodc"



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
; Create global definition file, but only if source can be opened...
;
.CreateDefFile      CALL CurrentFileName
                    INC  HL
                    LD   A, OP_IN
                    CALL Open_file                     ; try to open source file of current module
                    RET  C                             ; Ups - not possible...
                    LD   HL, deffilename
                    LD   DE, defext
                    CALL CreateFilename
                    JP   C, ReportError_NULL
                    INC  HL                            ; point at first char in filename
                    LD   A, OP_OUT
                    CALL Open_file
                    JP   C, ReportError_NULL
                    LD   (deffilehandle),IX            ; global definitions symbol file created...
                    RET


; ****************************************************************************************
;
; Press a key using standard OZ page wait facility.
; - The z80asm screen is redrawn, if the z80asm application is left.
;
.Wait_key           LD   A, SR_PWT
                    CALL_OZ(Os_Sr)                     ; page wait for key to be pressed
                    RET  NC
                    CALL z80asm_ERH                    ; act upon system error
                    RET



; ****************************************************************************************
;
.Init_Sourcefile    LD   HL, linebuffer
                    LD   (lineptr),HL
                    LD   (nextline),HL
                    LD   (buffer_end),HL
                    RET


; ****************************************************************************************
;
; Setup IY register to base of variables and preset runtime flags.
;
.InitVars           LD   HL, z80asm_vars
                    PUSH HL
                    POP  IY                            ; IY points at base of variable
                    LD   (HL), 2**datestamp | 2**mapref | 2**z80bin | 2**symtable
                               ; datestamp, map file,   linking,   symbol file
                    INC  HL
                    LD   (HL), @00000000               ; reset RTMflags2
                    INC  HL
                    LD   (HL), @00000000               ; reset RTMflags3
                    RET


; ****************************************************************************************
;
;    Reset Area for filename pointers and handles
;
.InitFiles          LD   BC, end_file_area - file_area
                    LD   HL, objfilename
.clear_handles      LD   (HL),0
                    INC  HL
                    DEC  BC
                    LD   A,B
                    OR   C
                    JR   NZ, clear_handles
                    RET



; ****************************************************************************************
;
.InitPointers       LD   HL, modulehdr                 ; allocate room for 'modulehdr' variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, libraryhdr                ; allocate room for 'libraryhdr' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, linkhdr                   ; allocate room for 'linkhdr' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, CURMODULE                 ; allocate room for 'CURMODULE' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, CURLIBRARY                ; allocate room for 'CURLIBRARY' variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, LASTMODULE                ; allocate room for 'LASTMODULE' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, globalroot                ; allocate room for 'globalroot' pointer variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, staticroot                ; allocate room for 'staticroot' pointer variable
                    CALL AllocVarPointer
                    LD   HL, asm_pc_ptr                ; allocate room for 'asm_pc_ptr' pointer variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    RET



; ****************************************************************************************
;
.Disp_pass1         LD   HL, pass1_msg
                    CALL_OZ(Gn_Sop)
                    CALL_OZ(Gn_Nln)
                    RET


; ****************************************************************************************
;
.Disp_pass2         LD   HL, pass2_msg
                    CALL_OZ(Gn_Sop)
                    CALL_OZ(GN_Nln)
                    RET

.Disp_totallines    LD   HL, totalline_msg
                    CALL_OZ(Gn_Sop)
                    LD   BC,(totallines)
                    CALL Display_integer
                    LD   HL, empty_msg
                    CALL_OZ(Gn_Sop)
                    RET

.break_msg          DEFM 1, "2H5Use ", 1, "B", 1, SD_SQUA, 1, "B ", 1, SD_ESC
                    DEFM " to abort assembly or linking.", 13, 10, 0

.z80asm_name        DEFM "z80asm", 0
.Z88_ident          DEFM 3, "Z88", 0
.asmPC_ident        DEFM 5, "ASMPC", 0
.empty_msg          DEFM 1, "2H5", 13, 10, 0
.using_msg          DEFM 1, "2H5", "Using ", 0
.pass1_msg          DEFM 1, "2H5Pass1...", 0
.pass2_msg          DEFM 1, "2H5Pass2...", 0
.totalline_msg      DEFM 1, "2H5Assembled lines: ", 0
.cdefile            DEFM ":RAM.-/temp.buf", 0
.objext             DEFM "obj"
.defext             DEFM "def"
.errext             DEFM "err"
.symext             DEFM "sym"

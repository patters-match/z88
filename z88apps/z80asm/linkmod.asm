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

     MODULE Link_modules

; external procedures:
     LIB Read_word, Read_pointer, Set_word, Read_byte
     LIB Set_pointer, Set_long, Set_byte
     LIB malloc
     LIB CmpPtr
     LIB IntHex

     XREF Disp_allocmem                                     ; dispmem.asm
     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF GetSym                                            ; prsline.asm
     XREF CurrentFile                                       ; srcfile.asm
     XREF CurrentModule                                     ; currmod.asm
     XREF GetPointer, GetVarPointer, FreeVarPointer         ; varptr.asm
     XREF CopyId                                            ; symbols.asm
     XREF CreateFileName                                    ; crtflnm.asm
     XREF Display_filename                                  ; dispflnm.asm
     XREF CheckObjfile                                      ; chckfhdr.asm
     XREF DefineOrigin                                      ; deforig.asm
     XREF Add32bit                                          ; add32bit.asm
     XREF ReadNames                                         ; readname.asm
     XREF LinkLibModules                                    ; linklibm.asm
     XREF ModuleExpressions                                 ; readexpr.asm

     XREF CreateasmPC_ident                                ; z80asm.asm
     XREF Keyboard_Interrupt                                ;

     XREF Display_integer                                   ; z80pass1.asm
     XREF InitRelocTable, RelocationPrefix                  ; reloc.asm

     XREF Test_32bit_range, Test_16bit_range                ; exprs.asm

     XREF Open_file, ftell, fseek, Read_fptr, Write_fptr    ; fileio.asm
     XREF Close_file, Copy_file, Delete_file                ;
     XREF Write_string                                      ;

; routines accessible in this module:
     XDEF LinkModules, LinkModule
     XDEF ModuleBaseAddr

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
;    Link modules:  open all object files, read name definitions, link library routines if specified,
;                   generate machine code file from object module code,
;                   finish with reading object module expressions and patch constants into machine code file.
;    IN:  None.
;    OUT: None.
;
; Registers changed after return:
;
;    ......../..IY  same
;    AFBCDEHL/IX..  different
;
.LinkModules        BIT  ASMERROR,(IY + RtmFlags3)
                    RET  NZ                                 ; if ( ERRORS ) return

                    LD   HL, link_msg
                    CALL_OZ(Gn_Sop)                         ; puts("linking module(s)...\nPass1...")

                    BIT  autorelocate,(IY + RtmFlags2)
                    CALL NZ, InitReloctable                 ; if (autorelocate) InitRelocTable()
                    RET  C

                    LD   HL, modulehdr
                    CALL GetVarPointer
                    PUSH BC
                    PUSH HL                                 ; {remember pointer}
                    LD   A, modules_first
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL                              ; CDE=modulehdr->first
                    LD   HL, curmodule
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer                        ; CURRENTMODULE = modulehdr->first
                    POP  HL
                    POP  BC
                    LD   A, modules_last
                    CALL Read_pointer
                    LD   C,B
                    EX   DE,HL                              ; CDE = modulehdr->last
                    LD   HL, LASTMODULE
                    CALL GetPointer
                    XOR  A
                    CALL Set_pointer                        ; LASTMODULE = modulehdr->last

                    LD   HL, errfilename
                    LD   DE, errext
                    CALL CreateFilename
                    JP   C, linkmodules_err
                    INC  HL                                 ; point at first char in filename
                    LD   A, OP_OUT
                    CALL Open_file                          ; errfile = fopen(errfilename, "w")
                    JP   C, linkmodules_err
                    LD   (errfilehandle),IX                 ; error file created...

                    LD   HL, binfilename
                    LD   DE, binext
                    CALL CreateFilename
                    JP   C, linkmodules_err
                    INC  HL                                 ; point at first char in filename
                    PUSH BC
                    PUSH HL
                    LD   A, OP_OUT                          ; create...
                    CALL Open_file                          ; binfile = fopen(cdefilename, "w")
                    POP  HL
                    POP  BC                                 ; {get copy of binary filename}
                    JP   C, linkmodules_err
                    CALL_OZ(Gn_Cl)
                    LD   A, OP_UP                           ; update...
                    CALL Open_file                          ; binfile = fopen(cdefilename, "w+")
                    LD   (cdefilehandle),IX                 ; binary file created...

                    LD   HL,0
                    LD   (asm_pc),HL
                    CALL CreateasmPC_ident                 ; DefineDefSym( "ASMPC", 0, &globalroot)

                                                            ; do
.modlink_loop
                         CALL Keyboard_Interrupt                 ; Keyboard_Interrupt()
                         JP   Z,linkmodules_err2                 ; abort-keys pressed, stop linking...

.begin_modlink_loop      BIT  library, (IY + RTMflags)           if ( library )
                         JR   Z, modlink_loop_continue
                              LD   HL, libraryhdr
                              CALL GetVarPointer
                              LD   A, liblist_first
                              CALL Read_pointer
                              LD   C,B
                              EX   DE,HL                              ; CDE=libraryhdr->first
                              LD   HL, CURLIBRARY
                              CALL GetPointer
                              XOR  A
                              CALL Set_pointer                        ; CURLIBRARY = libraryhdr->first

.modlink_loop_continue        CALL CurrentFile
                              LD   A, srcfile_line
                              LD   DE,0
                              CALL Set_word                      ; CURRENTFILE->line = 0

                              LD   HL, objfilename
                              LD   DE, objext
                              CALL CreateFilename
                              JP   C, linkmodules_err
                              INC  HL                            ; point at first char in filename
                              CALL Display_filename              ; puts(objfilename)
                              LD   A, OP_IN
                              CALL Open_file                     ; objfile = fopen(objfilename, "r")
                              JP   C, linkmodules_err
                              LD   (objfilehandle),IX            ; object file opened...
                              CALL CheckObjfile
                              CP   -1                            ; if ( CheckObjFile() == -1 )
                              JR   NZ, modlink_loop_continue2
                                   LD   HL,objfilehandle
                                   CALL Close_file                    ; fclose(objfile)
                                   JP   linkmodules_err2              ; return

.modlink_loop_continue2  CALL_OZ(OS_Gb)
                         LD   L,A                                ; lowbyte = fgetc(objfile)
                         CALL_OZ(OS_Gb)
                         LD   H,A                                ; highbyte = fgetc(objfile)
                         PUSH HL
                         LD   HL, modulehdr
                         CALL GetVarPointer
                         LD   A, modules_first
                         CALL Read_pointer                       ; {modulehdr->first}
                         LD   C,B
                         EX   DE,HL
                         CALL CurrentModule
                         CALL CmpPtr                             ; if ( modulehdr->first == CURRENTMODULE )
                         POP  DE                                      ; {lowbyte, highbyte}
                         JR   NZ, link_module_code

                              BIT  autorelocate, (IY + RTMflags2)
                              JR   Z, check_deforigin                 ; if ( autorelocate )
                                   LD   DE,0                               ; CURRENTMODULE->origin = 0
                                   JR   set_origin                    ; else
.check_deforigin                   BIT  deforigin, (IY + RTMflags)         ; if ( deforigin )
                                        JR   Z, check_origin
                                        LD   DE,(explicitORIG)                  ; CURRENTMODULE->origin = EXPLICIT_ORIGIN
.check_origin                           LD   A,-1                          ; else
                                        CP   D
                                        JR   NZ, set_origin
                                        CP   E
                                        JR   NZ, set_origin                     ; if ( CURRENTMODULE->origin == 65535U )
                                             CALL DefineOrigin                       ; DefineOrigin()
.set_origin                        LD   A, module_origin
                                   CALL Set_word
                              CALL Display_ORG                        ; display_ORG (CURRENTMODULE->origin)

.link_module_code        LD   HL, objfilehandle                  ; fclose(objfile)
                         CALL Close_file
                         LD   HL, objfilename
                         CALL GetVarPointer
                         LD   C,0
                         LD   D,C
                         LD   E,C                                ; baseptr = 0
                         CALL LinkModule                         ; LinkModule (objfilename, baseptr)
                         LD   HL, objfilename                    ; free(objfilename)
                         CALL FreeVarPointer                     ; objfilename = NULL

                         CALL CurrentModule                      ; BHL = CURRENTMODULE
                         LD   A, module_next
                         CALL Read_pointer
                         LD   C,B
                         EX   DE,HL                              ; {CDE = CURRENTMODULE->next}
                         LD   HL, CURMODULE
                         CALL GetPointer
                         XOR  A
                         CALL Set_pointer                        ; CURRENTMODULE = CURRENTMODULE->next
                    LD   HL, LASTMODULE
                    CALL GetVarPointer
                    LD   A, module_next
                    CALL Read_pointer                            ; {BHL = LASTMODULE->next, CDE = CURRENTMODULE}
                    CALL CmpPtr
                    JP   NZ, modlink_loop                   ; while ( CURRENTMODULE != LASTMODULE->next )

                    BIT  ASMERROR, (IY + RtmFlags3)
                    JR   NZ, end_linkmodules                ; if ( ASMERROR == OFF )
                         CALL Disp_codesize
                         CALL ModuleExpressions                  ; ModuleExpressions()
                         BIT  autorelocate, (IY + RTMflags2)
                         CALL NZ, RelocationPrefix

.end_linkmodules    LD   HL, cdefilehandle
                    CALL Close_file                         ; fclose(binfile)
                    LD   HL, errfilehandle
                    CALL Close_file                         ; fclose(errfile)

                    LD   HL, errfilename
                    PUSH HL
                    CALL GetVarPointer
                    INC  HL
                    BIT  ASMERROR, (IY + RtmFlags3)
                    CALL Z, Delete_file                     ; if ( ASMERROR == OFF ) remove(errfilename)
                    POP  HL                                 ; free(errfilename)
                    CALL FreeVarPointer                     ; errfilename = NULL

                    LD   HL, binfilename
                    CALL GetVarPointer
                    INC  HL
                    BIT  ASMERROR, (IY + RtmFlags3)
                    CALL NZ, Delete_file                    ; if ( ASMERROR ) remove(binfilename)
                    RET

.linkmodules_err    CALL ReportError_NULL                   ; ReportError()...
.linkmodules_err2   LD   HL, errfilehandle
                    CALL Close_file                         ; fclose(errfile)
                    LD   HL, cdefilehandle
                    CALL Close_file                         ; fclose(binfile)
                    LD   HL, binfilename
                    CALL GetVarPointer
                    INC  HL
                    CALL Delete_file                        ; remove(binfilename)
                    RET

.link_msg           DEFM 1, "2H5", 10, 13, "linking module(s)...", 10, 13, "Pass1...", 10, 13, 0
.errext             DEFM "err"
.objext             DEFM "obj"
.binext             DEFM "bin"



; **************************************************************************************************
;
;    Display the codesize of all linked modules.
;
.Disp_codesize      LD   HL, codesizemsg
                    CALL_OZ(Gn_sop)
                    LD   BC,(codesize)
                    CALL Display_integer
                    CALL_OZ(Gn_Nln)
                    RET
.codesizemsg        DEFM 1, "2H5Code size of linked modules is ", 0



; **************************************************************************************************
;
; Link module code and read name definitions.
; Link also library modules, if referenced in the library name section of the object file
;
;    IN:  BHL = pointer to filename
;         CDE = base pointer of object module
;
;    OUT: Fc = 0, module successfully linked, otherwise Fc = 1.
;
;    Local variables created on stack:
;         (IX+0,2)  pointer to filename
;         (IX+3,5)  base pointer of object module
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.LinkModule         CALL Keyboard_Interrupt                 ; Keyboard_Interrupt()
                    RET  Z                                  ; abort-keys pressed, stop linking...

                    PUSH IX
                    EXX
                    LD   HL,0
                    ADD  HL,SP                                   ; current SP in HL
                    LD   IX,-6
                    ADD  IX,SP
                    LD   SP,IX                                   ; allocate room for parameter variables
                    PUSH HL                                      ; preserve pointer to original SP
                    EXX
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   (IX+2),B                                ; filename pointer stored
                    LD   (IX+3),E
                    LD   (IX+4),D
                    LD   (IX+5),C                                ; base pointer stored

                    LD   (longint),DE
                    LD   D,0
                    LD   E,C
                    LD   (longint+2),DE                          ; base pointer at (longint)
                    LD   A, OP_IN
                    INC  HL

                    PUSH IX                                      ; preserve pointer to local variables
                    CALL Open_file
                    LD   (objfilehandle),IX                      ; objfile = fopen(filename, "r")
                    LD   HL,longint
                    LD   BC,10
                    LD   DE,0
                    CALL Add32bit
                    CALL fseek                                   ; fseek(objfile, fptr_base+10, SEEK_SET)
                    LD   HL, fptr_modname
                    CALL Read_fptr                               ; fptr_modname = ReadLong(objfile)
                    LD   HL, fptr_exprdecl
                    CALL Read_fptr                               ; fptr_exprdecl = ReadLong(objfile)
                    LD   HL, fptr_namedecl
                    CALL Read_fptr                               ; fptr_namedecl = ReadLong(objfile)
                    LD   HL, fptr_libnames
                    CALL Read_fptr                               ; fptr_libnames = ReadLong(objfile)
                    LD   HL, fptr_modcode
                    CALL Read_fptr                               ; fptr_modcode = ReadLong(objfile)
                    POP  IX

                    CALL Disp_allocmem                           ; display amount of allocated OZ memory

                    LD   A,(fptr_modcode+3)
                    CP   -1
                    JP   Z, read_modnames                        ; if ( fptr_modcode != -1 )
                         LD   HL, fptr_modcode
                         LD   C,(IX+3)
                         LD   B,(IX+4)
                         LD   E,(IX+5)
                         LD   D,0
                         CALL Add32bit                                ; fptr_modcode += fptr_base
                         PUSH IX
                         LD   IX,(objfilehandle)
                         LD   B,0                                     ; {local pointer}
                         CALL fseek                                   ; fseek( objfile, fptr_modcode+fptr_base, SEEK_SET)
                         CALL_OZ(OS_Gb)
                         LD   C,A                                     ; lowbyte = fgetc(objfile)
                         CALL_OZ(OS_Gb)
                         LD   B,A                                     ; highbyte = fgetc(objfile)
                         POP  IX                                      ; {restore base pointer to local variables}
                         PUSH BC                                      ; preserve size
                         CALL CurrentModule
                         LD   A, module_startoffset
                         CALL Read_word
                         EX   DE,HL                                   ; HL = CURRENTMODULE->startoffset
                         POP  BC                                      ; restore size
                         ADD  HL,BC
                         JR   NC, load_modulecode                     ; if ( CURRENTMODULE->startoffset + size > MAXCODESIZE )
                              LD   HL, objfilehandle
                              CALL Close_file                              ; fclose(objfile)
                              LD   A, ERR_max_codesize
                              LD   L,(IX+0)
                              LD   H,(IX+1)
                              LD   B,(IX+2)                                ; BHL = filename
                              LD   DE,0
                              CALL ReportError                             ; ReportError()
                              SCF
                              JP   exit_linkmod                            ; return 0
                                                                      ; else
.load_modulecode              PUSH BC                                      ; {preserve module code size}
                              PUSH IX                                      ; {preserve pointer to local variables}
                              LD   IX, (cdefilehandle)
                              CALL CurrentModule
                              LD   DE, module_startoffset                  ; set file pointer for module code
                              CALL fseek                                   ; fseek(binfile, CURRENTMODULE->startoffset, SEEK_SET)
                              POP  IX
                              LD   HL, objfilehandle                       ; from object file
                              LD   DE, cdefilehandle                       ; to binary file
                              XOR  A
                              POP  BC                                      ; ABC = size, no of bytes to copy
                              PUSH BC
                              CALL Copy_file
                              POP  BC                                      ; {restore size}
                              JR   NC, update_codesize                     ; if ( Copy_file() == 0 )
                                   LD   HL, objfilehandle
                                   CALL Close_file                              ; fclose(objfile)
                                   LD   A, ERR_no_room
                                   LD   L,(IX+0)
                                   LD   H,(IX+1)
                                   LD   B,(IX+2)                                ; BHL = filename
                                   LD   DE,0
                                   CALL ReportError                             ; ReportError()
                                   SCF
                                   JP   exit_linkmod                            ; return 0

.update_codesize         PUSH BC                                      ; preserve size
                         CALL CurrentModule                           ; BHL = CURRENTMODULE
                         LD   A, module_startoffset
                         CALL Read_word                               ; DE = CURRENTMODULE->startoffset
                         EX   DE,HL                                   ; startoffset in HL
                         LD   DE,(codesize)
                         CP   A
                         SBC  HL,DE
                         POP  BC
                         JR   NZ, read_modnames                       ; if ( CURRENTMODULE->startoffset == CODESIZE )
                              EX   DE,HL                                   ; HL = CODESIZE
                              ADD  HL,BC
                              LD   (codesize),HL                           ; CODESIZE += size

.read_modnames      LD   A,(fptr_namedecl+3)
                    CP   -1
                    JR   Z, read_modlibnames                     ; if ( fptr_namedecl != -1 )
                         LD   BC,(fptr_namedecl)
                         LD   (longint),BC
                         LD   DE,(fptr_namedecl+2)
                         LD   (longint+2),DE
                         LD   C,(IX+3)
                         LD   B,(IX+4)
                         LD   E,(IX+5)
                         LD   D,0                                     ; DEBC = fptr_base
                         LD   HL, longint
                         CALL Add32bit
                         PUSH IX                                      ; {preserve pointer to local variables}
                         LD   IX,(objfilehandle)
                         LD   B,0                                     ; {local pointer}
                         CALL fseek                                   ; fseek( fptr_base + fptr_namedecl, objfile, SEEK_SET)
                         POP  IX

                         LD   A,(fptr_libnames+3)
                         CP   -1
                         JR   Z, endnames_modname                     ; if ( fptr_libnames != -1 )
                              LD   DE,(fptr_libnames)
                              LD   A,(fptr_libnames+2)                     ; ReadNames( fptr_namedecl, fptr_libnames)
                              LD   C,A
                              JR   module_names                       ; else
.endnames_modname             LD   DE,(fptr_modname)                       ; ReadNames( fptr_namedecl, fptr_modname)
                              LD   A,(fptr_modname+2)
                              LD   C,A
.module_names            LD   HL,(fptr_namedecl)
                         LD   A,(fptr_namedecl+2)
                         LD   B,A
                         CALL ReadNames

.read_modlibnames   LD   HL,objfilehandle                        ; fclose(objfile)
                    CALL Close_file

                    BIT  library, (IY + RTMflags)
                    JR   Z, link_pass2_module                    ; if ( library )
                         LD   A,(fptr_libnames+3)
                         CP   -1
                         JR   Z, link_pass2_module                    ; if ( fptr_namedecl != -1 )
                              POP  DE                                      ; get entry SP for .LinkModule
                              PUSH IX
                              POP  HL                                      ; HL points at local variables
                              LD   IX,-12
                              ADD  IX,SP                                   ; make room for new parameters
                              LD   SP,IX                                   ; IX points at base of parameter block
                              PUSH DE                                      ; preserve entry SP for .LinkModule
                              PUSH IX
                              POP  DE                                      ; DE points at base of new parameter block
                              LD   BC,6                                    ; HL points at base of current parameter block
                              LDIR                                         ; copy current local variables into parameter block
                              LD   HL,(fptr_libnames)
                              LD   A,(fptr_libnames+2)
                              LD   (IX+6),L
                              LD   (IX+7),H
                              LD   (IX+8),A                                ; fptr_libnames parameter
                              LD   HL,(fptr_modname)
                              LD   A,(fptr_modname+2)
                              LD   (IX+9),L
                              LD   (IX+10),H
                              LD   (IX+11),A                               ; fptr_modname parameter
                              CALL LinkLibModules                          ; flag = LinkLibModules(filename,fptr_base,fptr_libnames,fptr_modname)
                              JR   C, exit_linkmod                         ; if flag = 0 return

.link_pass2_module  LD   L,(IX+0)
                    LD   H,(IX+1)
                    LD   B,(IX+2)                           ; BHL = filename
                    LD   E,(IX+3)
                    LD   D,(IX+4)
                    LD   C,(IX+5)                           ; CDE = fptr_base
                    CALL LinkTracedModule                   ; flag = LinkTracedModule(filename, fptr_base)

                    CALL Disp_allocmem                      ; display amount of allocated OZ memory

.exit_linkmod       POP  HL                                 ; get SP for .LinkModule entry
                    LD   SP,HL                              ; point at RETurn address
                    POP  IX
                    RET                                     ; return flag



; **************************************************************************************************
;
; Return base relocation address of current module,
;    CURRENTMODULE->startoffset + modulehdr->first->origin
;    in BC
;
.ModuleBaseAddr     PUSH DE
                    PUSH HL
                    LD   HL, modulehdr
                    CALL GetVarPointer
                    LD   A, modules_first
                    CALL Read_pointer
                    LD   A, module_origin
                    CALL Read_word                ; modulehdr->first->origin
                    PUSH DE
                    CALL CurrentModule
                    LD   A, module_startoffset
                    CALL Read_word                ; CURRENTMODULE->startoffset
                    EX   DE,HL                    ; baseaddr = CURRENTMODULE->startoffset
                    POP  DE
                    ADD  HL,DE                    ; baseaddr += modulehdr->first->origin
                    LD   B,H
                    LD   C,L
                    POP  HL
                    POP  DE
                    RET



; **************************************************************************************************
;
;    Link pass1 traced module into list of modules (preparing it for pass2 expression evaluation)
;
;    IN:  BHL = pointer to filename
;         CDE = file base pointer
;    OUT: Fc = 1 if no room in OZ memory, otherwise Fc = 0
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.LinkTracedModule   PUSH DE
                    PUSH HL
                    PUSH BC
                    LD   HL, linkhdr
                    CALL GetVarPointer
                    XOR  A
                    CP   B
                    JR   NZ, linkhdr_exists            ; if ( linkhdr == NULL ) {
                         CALL Alloclinkhdr             ;    if ( (linkhdr = Alloclinkhdr()) == NULL )
                         JP   C, newl_nullptr          ;         return (no room)...
                                                       ;    else {
                         LD   C,B                      ;
                         EX   DE,HL                    ;         ; CDE = linkhdr
                         LD   HL,linkhdr
                         CALL GetPointer
                         XOR  A
                         CALL Set_pointer              ;
                         LD   B,C                      ;
                         EX   DE,HL                    ;         { restore linkhdr ptr. in BHL }
                         XOR  A
                         LD   E,A
                         LD   D,A
                         LD   C,A                      ;         { NULL pointer }
                         LD   A, linklist_firstmod
                         CALL Set_pointer              ;         linkhdr->firstmod = NULL
                         LD   A, linklist_lastmod
                         CALL Set_pointer              ;         linkhdr->lastmod = NULL
                                                       ;    }
                                                       ; }

.linkhdr_exists     POP  BC
                    POP  HL
                    PUSH HL
                    PUSH BC                            ; BHL = filename
                    CALL CopyId                        ; CDE = allocated copy of filename
                    JR   C, newl_nullptr               ; if ( CDE == NULL )   Ups - no room
                         CALL AllocTracedModule             ; if ( (newl = AllocTracedModule()) == NULL )
                         JR   C, newl_nullptr               ; else
                              LD   A, linkedmod_objfname
                              CALL Set_pointer                   ; newl->objfname = CDE
                              XOR  A
                              LD   D,A
                              LD   E,A
                              LD   C,A
                              LD   A, linkedmod_nextlink
                              CALL Set_pointer                   ; newl->nextlink = NULL
                              EXX
                              POP  DE
                              LD   D,0                           ; E = high byte of baseptr (former C register)
                              POP  HL                            ; redundant register...
                              POP  BC                            ; DEBC = baseptr
                              EXX
                              LD   A, linkedmod_modstart
                              CALL Set_long                      ; newl->modstart = baseptr
                              PUSH BC
                              PUSH HL                            ; preserve newl
                              CALL CurrentModule
                              LD   A,B
                              EX   DE,HL
                              POP  HL
                              POP  BC
                              LD   C,A                           ; {BHL = newl, CDE = CURRENTMODULE}
                              LD   A, linkedmod_module
                              CALL Set_pointer                   ; newl->module = CURRENTMODULE

                              LD   C,B
                              EX   DE,HL                         ; { CDE = newl }
                              LD   HL, linkhdr
                              CALL GetVarPointer
                              PUSH BC
                              PUSH HL
                              LD   A, linklist_firstmod
                              CALL Read_pointer                  ; { BHL = linkhdr->firstmod }
                              XOR  A
                              CP   B
                              POP  HL                            ; { restore linkhdr }
                              POP  BC
                              JR   NZ, append_module             ; if ( linkhdr->firstmod == NULL )
                                   LD   A, linklist_firstmod
                                   CALL Set_pointer                   ;    linkhdr->firstmod = newl
                                   LD   A, linklist_lastmod
                                   CALL Set_pointer                   ;    linkhdr->lastmod = newl
                                   JR   end_newlinkedmod
                                                                 ; else
.append_module                PUSH BC
                              PUSH HL                                 ;    { preserve linkhdr }
                              LD   A, linklist_lastmod
                              CALL Read_pointer
                              LD   A, linkedmod_nextlink
                              CALL Set_pointer                        ;    linkhdr->lastmod->next = newl
                              POP  HL
                              POP  BC
                              LD   A, linklist_lastmod
                              CALL Set_pointer                        ;    linkhdr->lastmod = newl

.end_newlinkedmod   XOR  A                             ; return CDE = newm
                    RET                                ; indicate succes...

.newl_nullptr       POP  BC
                    POP  HL
                    POP  DE
                    SCF                                ; return error
                    RET


; **************************************************************************************************
;
;    Display the selected ORIGIN for the linked machine code modules
;
;    IN:  DE = address of origin
;
.Display_ORG        PUSH DE
                    LD   BC,2                     ; B = 0, local pointer
                    LD   HL,0                     ; C = 2, 16bit hex Ascii conversion
                    ADD  HL,SP                    ; HL = local pointer to 16bit integer
                    LD   DE, stringconst
                    CALL IntHex                   ; ConvertIntHex(2, SP, stringconst)
                    PUSH DE
                    LD   HL, ORG_message
                    CALL_OZ(Gn_Sop)
                    POP  HL
                    CALL_OZ(Gn_Sop)
                    CALL_OZ(Gn_Nln)
                    POP  DE
                    RET
.ORG_message        DEFM 1, "2H5ORG address for code is ", 0


; ***********************************************************************************************
;
;    Allocate memory for header of list of linked modules
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.Alloclinkhdr       LD   A, SIZEOF_linklist
                    CALL malloc
                    RET


; **************************************************************************************************
;
;    Allocate memory for traced module information record
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocTracedModule  LD   A, SIZEOF_linkedmod
                    CALL malloc
                    RET

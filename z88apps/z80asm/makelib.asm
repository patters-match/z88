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

     MODULE Make_library

     LIB IntHex, Read_pointer, Set_pointer
     LIB GetVarPointer

     XREF ReportError_NULL                             ; ASMERROR.asm
     XREF CreateFilename                               ; crtflnm.asm
     XREF CurrentModule                                ; module.asm
     XREF CheckObjFile                                 ; Chckfhdr.asm
     XREF Add32bit                                     ; add32bit.asm

     XREF Open_file, fseek, ftell, fsize, Close_file   ; fileio.asm
     XREF Write_fptr, Copy_file, Delete_file

     XREF AllocVarPointer, GetPointer   ; varptr.asm
     XREF FreeVarPointer

     XDEF MakeLibrary

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ****************************************************************************************
;
;    If no errors, make library file from object module files, previously compiled
;
.MakeLibrary        LD   A,(TOTALERRORS)
                    OR   A
                    RET  NZ
                         LD   HL, creatlib_msg         ; "Creating library..."
                         CALL_OZ(Gn_Sop)

                         LD   HL, libfilename
                         CALL GetVarPointer
                         INC  HL                            ; point at first char of filename
                         LD   A, OP_OUT
                         CALL Open_file                     ; create library file
                         JP   C, ReportError_NULL
                         LD   (libfilehandle),IX            ; store handle of library file
                         LD   BC,8
                         LD   DE,0
                         LD   HL, Z80Libheader
                         CALL_OZ(Os_Mv)                     ; write header to library file
                         CALL C, ReportError_NULL
                         JP   C, err_makelibrary

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

.makelib_loop            LD   HL, objfilename
                         LD   DE, objext               ; Create oject file name from current
                         CALL CreateFilename           ; source file name
                         CALL C, ReportError_NULL
                         JP   C, err_makelibrary
                         INC  HL
                         LD   A, OP_IN
                         CALL Open_file                ; objfile = fopen(objfilename, "r")
                         CALL C, ReportError_NULL
                         JP   C, err_makelibrary
                         LD   (objfilehandle),IX
                         CALL CheckObjfile
                         JR   Z, copy_objfile
                              LD   HL, objfilehandle
                              CALL Close_file               ; fclose(objfile)
                              JP   err_makelibrary

.copy_objfile            LD   HL,0
                         LD   (longint),HL
                         LD   (longint+2),HL
                         LD   B,H
                         LD   HL, longint
                         CALL fseek                    ; point at start of object file

                         LD   IX,(libfilehandle)
                         CALL ftell
                         LD   (longint),BC
                         LD   (longint+2),DE

                         LD   HL, objfilename
                         CALL GetVarPointer            ; printf("%s", objfilename);
                         INC  HL
                         LD   DE, Ident
                         PUSH DE
                         LD   C, 18                    ; get filename without path...
                         CALL_OZ(Gn_Fcm)
                         POP  HL
                         CALL_OZ(Gn_Sop)               ; write filename to message window
                         LD   HL, lib2_msg
                         CALL_OZ(Gn_sop)               ; printf(" module at ");

                         LD   HL,longint               ; point at value
                         LD   DE, stringconst
                         LD   BC,2
                         CALL IntHex                   ; convert value to HEX string at (stringconst)
                         EX   DE,HL                    ; HL points at ASCII HEX string
                         CALL_OZ(Gn_Sop)               ; display position of module in library
                         CALL_OZ(Gn_Nln)

                         CALL CurrentModule
                         LD   A, module_next
                         CALL Read_pointer
                         INC  B
                         DEC  B
                         JR   NZ, another_module       ; if ( CURRENTMODULE->nextmodule == NULL )
                              LD   HL, -1
                              LD   (longint),HL             ; fptr_nextmodule = -1
                              LD   (longint+2),HL
                              JR   write_nextmodptr
                                                       ; else
.another_module               LD   IX,(objfilehandle)
                              CALL fsize                    ; DEBC = sizeof(objfile)
                              LD   HL,longint
                              CALL Add32bit                 ; (longint) = sizeof(objfile) + ftell(libfile)
                              LD   DE,0
                              LD   BC,8
                              CALL Add32bit                 ; (longint): fptr_nextmodule = ftell(libfile) + sizeof(objfile) + 8

.write_nextmodptr        LD   IX,(libfilehandle)
                         LD   B,0
                         LD   HL, longint
                         CALL Write_fptr               ; WriteLong(fptr_nextmodule, libfile)

                         PUSH IX
                         LD   IX,(objfilehandle)
                         CALL fsize
                         POP  IX
                         LD   (longint),BC
                         LD   (longint+2),DE
                         LD   B,0
                         LD   HL, longint
                         CALL Write_fptr               ; WriteLong(sizeof(objfile, libfile)

                         LD   A,(longint+2)
                         LD   BC, (longint)            ; ABC = size of object file
                         LD   HL, objfilehandle        ; HL = pointer to source file handle
                         LD   DE, libfilehandle        ; DE = pointer to destination file handle
                         CALL Copy_file

                         LD   HL, objfilename
                         CALL FreeVarPointer           ; release pointer variable back to OZ memory
                         LD   HL, objfilehandle
                         CALL Close_file

                         CALL CurrentModule
                         LD   A, module_next
                         CALL Read_pointer
                         LD   C,B
                         EX   DE,HL
                         LD   HL,CURMODULE
                         CALL GetPointer
                         XOR  A
                         CALL Set_pointer              ; CURRENTMODULE = CURRENTMODULE->nextmodule

                         INC  C
                         DEC  C
                         JP   NZ, makelib_loop    ; while ( CURRENTMODULE == NULL )

                    LD   HL, libfilehandle
                    CALL Close_file
                    RES  createlib, (IY + RTMflags)
                    RET                           ; library created, it's single functionality (option disabled)

.err_makelibrary    LD   HL, libfilehandle
                    CALL Close_file               ; fclose(libfile)
                    LD   HL, libfilename
                    CALL GetVarPointer
                    INC  HL
                    JP   Delete_file              ; remove(libfilename)

.Z80Libheader       DEFM "Z80LMF01"
.creatlib_msg       DEFM 1, "2H5Creating library...", 13, 10, 0
.lib2_msg           DEFM " module at ", 0
.objext             DEFM "obj"

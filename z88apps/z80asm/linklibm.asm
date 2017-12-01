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

     MODULE Link_library_modules

; external procedures:
     LIB memcompare, CmpPtr
     LIB Bind_bank_s1
     LIB AllocIdentifier, mfree
     LIB Read_word, Read_pointer, Set_word, Read_byte
     LIB Set_pointer, Read_long, Set_long, Set_byte

     XREF LinkModule                                        ; linkmod.asm
     XREF CurrentModule, NewModule                          ; module.asm
     XREF NewFile                                           ; srcfile.asm
     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF GetSym                                            ; prsline.asm
     XREF CurrentFile                                       ; srcfile.asm
     XREF EvalPfixExpr                                      ; evalexpr.asm
     XREF GetPointer, GetVarPointer, FreeVarPointer         ; varptr.asm
     XREF CopyId, FindSymbol                                ; symbols.asm
     XREF CreateFileName                                    ; crtflnm.asm
     XREF DefineOrigin                                      ; deforig.asm
     XREF Add32bit                                          ; add32bit.asm
     XREF ReadNames                                         ; readname.asm
     XREF LoadName                                          ; loadname.asm

     XREF Test_32bit_range, Test_16bit_range                ; exprs.asm

     XREF Open_file, fseek, Read_fptr, Write_fptr           ; fileio.asm
     XREF Close_file

; routines accessible in this module:
     XDEF LinkLibModules

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"



; **************************************************************************************************
;
;    Link library modules
;
;    IN:  IX points at parameter block:
;         (IX+0,2)  = filename
;         (IX+3,5)  = fptr_base
;         (IX+6,8)  = nextlibname
;         (IX+9,11) = end_libnames
;
;    OUT: Fc = 1, if error occurred, otherwise Fc = 0
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.LinkLibModules
.read_libname_loop       LD   L,(IX+0)                           ; do
                         LD   H,(IX+1)
                         LD   B,(IX+2)
                         INC  HL                                      ; filename
                         LD   A, OP_IN
                         PUSH IX                                      ; preserve pointer to local variables
                         CALL Open_file
                         LD   (objfilehandle),IX                      ; objfile = fopen(filename, "r")
                         POP  IX

                         LD   L,(IX+6)
                         LD   H,(IX+7)
                         LD   E,(IX+8)
                         LD   D,0
                         LD   (longint),HL
                         LD   (longint+2),DE                          ; nextlibname at (longint)
                         LD   C,(IX+3)
                         LD   B,(IX+4)
                         LD   E,(IX+5)                                ; DEBC = fptr_base
                         LD   HL, longint
                         CALL Add32bit                                ; longint = fptr_base + nextlibname
                         PUSH IX
                         LD   IX,(objfilehandle)
                         LD   B,0                                     ; {local pointer}
                         CALL fseek                                   ; fseek( fptr_base + nextlibname, objfile, SEEK_SET)
                         CALL LoadName                                ; LoadName(objfile)
                         POP  IX                                      ; restore pointer to parameter block
                         PUSH HL

                         LD   B,0
                         LD   C,(HL)                                  ; l = strlen(name)
                         INC  BC                                      ; ++l (incl. length prefix byte)
                         LD   L,(IX+6)
                         LD   H,(IX+7)
                         ADD  HL,BC                                   ; nextlibname += l
                         LD   (IX+6),L
                         LD   (IX+7),H
                         JR   NC, find_libname
                              INC  (IX+8)                             ; {adjust for overflow}

.find_libname            LD   HL, objfilehandle
                         CALL Close_file                              ; fclose(objfile)
                         POP  HL
                         CALL AllocIdentifier                         ; modname = AllocId(name)
                         JR   NC, search_globalroot                   ; if ( modname == NULL )
                              LD   A, ERR_no_room
                              CALL ReportError_NULL                        ; ReportError(3)
                              RET                                          ; return 0

.search_globalroot       LD   C,B
                         EX   DE,HL                                   ; {CDE = modname}
                         LD   HL, globalroot
                         CALL GetVarPointer                           ; {BHL = globalroot}
                         PUSH BC
                         PUSH DE                                      ; preserve modname pointer
                         CALL FindSymbol                              ; if ( FindSymbol(modname, globalroot) == NULL )
                         JR   NC, get_next_libname
                              CALL SearchLibraries                         ; SearchLibraries(modname)

.get_next_libname        POP  HL
                         POP  BC
                         LD   B,C                                     ; {get pointer to modname}
                         CALL mfree                                   ; free(modname)

                         LD   A,(IX+11)
                         CP   (IX+8)
                         JR   C, exit_linklibmod
                         LD   L,(IX+9)
                         LD   H,(IX+10)                               ; {nextlibname}
                         LD   E,(IX+6)
                         LD   D,(IX+7)                                ; {end_libnames}
                         SBC  HL,DE
                         JR   C, exit_linklibmod
                         JR   Z, exit_linklibmod
                         JP   read_libname_loop                  ; while ( nextlibname < end_libnames )

.exit_linklibmod    CP   A                                       ; return 1
                    RET



; **************************************************************************************************
;
;    Search libraries for module name
;
;    IN:  CDE = pointer to string of module name
;    OUT: None.
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.SearchLibraries    LD   B,3
                    PUSH BC
.searchlibs_loop    POP  BC                                 ; for ( i = 3; i > 0; --i )
                    DEC  B
                    RET  Z
                         PUSH BC

.nextlib_loop            LD   HL, CURLIBRARY                     ; while ( CURRENTLIB != NULL )
                         CALL GetVarPointer
                         XOR  A
                         CP   B
                         JR   Z, get_firstlib
                              CALL SearchLibFile
                              JR   NC, exit_searchlibs                ; if ( SearchLibFile( CURRENTLIB, modname ) ) return
                              PUSH DE
                              PUSH BC                                 ; {preserve modname pointer in CDE}
                              LD   A,libfile_next
                              CALL Read_pointer                       ; BHL = CURRENTLIB->next
                              LD   C,B
                              EX   DE,HL
                              LD   HL, CURLIBRARY
                              CALL GetPointer
                              XOR  A
                              CALL Set_pointer                        ; CURRENTLIB = CURRENTLIB->nextlib
                              CP   C
                              JR   Z, search_nextlib                  ; if ( CURRENTLIB != NULL )
                                   LD   B,C
                                   EX   DE,HL                              ; BHL = CURRENTLIB
                                   LD   A, libfile_nextobjfile
                                   CALL Read_long                          ; CURRENTLIB->nextobjfile
                                   EXX
                                   CP   A
                                   LD   HL,0
                                   SBC  HL,DE
                                   EXX
                                   JR   C, reset_nextlib
                                   EXX
                                   LD   HL,8
                                   SBC  HL,BC
                                   EXX
                                   JR   Z, search_nextlib                  ; if ( CURRENTLIB->nextobjfile != 8 )
.reset_nextlib                          EXX
                                        LD   DE,0
                                        LD   BC,8
                                        EXX
                                        LD   A,libfile_nextobjfile
                                        CALL Set_long                           ; CURRENTLIB->nextobjfile = 8
.search_nextlib               POP  BC
                              POP  DE                                 ; {restore modname pointer in CDE}
                              JR   nextlib_loop

.get_firstlib            PUSH BC
                         PUSH DE                                 ; {preserve modname pointer in CDE}
                         LD   HL, libraryhdr
                         CALL GetVarPointer
                         LD   A, liblist_first
                         CALL Read_pointer
                         LD   C,B
                         EX   DE,HL
                         LD   HL, CURLIBRARY
                         CALL GetPointer
                         XOR  A
                         CALL Set_pointer                        ; CURRENTLIB = libraryhdr->first
                         LD   B,C
                         EX   DE,HL                              ; {BHL = CURRENTLIB}
                         EXX
                         LD   BC,8
                         LD   DE,0
                         EXX
                         LD   A, libfile_nextobjfile
                         CALL Set_long                           ; CURRENTLIB->nextobjfile = 8
                         POP  DE
                         POP  BC
                         JR   searchlibs_loop               ; FOR loop...

.exit_searchlibs    POP  BC                                 ; {remove loop counter}
                    RET



; **************************************************************************************************
;
;    Search library file for specified module
;
;    IN:  BHL = pointer to current library
;         CDE = pointer to string of module name
;
;    OUT: Fc = 1 if module wasn't found, otherwise Fc = 0
;
;    Local variables on stack:
;         (IX+0,2)  = curlib
;         (IX+3,5)  = modname
;         (IX+6,8)  = file pointer
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.SearchLibfile      PUSH IX
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    EXX
                    LD   HL,0
                    ADD  HL,SP                                   ; current SP in HL
                    LD   IX,-9
                    ADD  IX,SP
                    LD   SP,IX                                   ; allocate room on stack
                    PUSH HL                                      ; preserve pointer to original SP
                    EXX
                    LD   (IX+0),L
                    LD   (IX+1),H                                ; preserve curlib pointer
                    LD   (IX+2),B
                    LD   (IX+3),E
                    LD   (IX+4),D
                    LD   (IX+5),C                                ; preserve modname pointer

                    LD   A, libfile_filename
                    CALL Read_pointer                            ; curlib->filename
                    INC  HL
                    LD   A, OP_IN
                    PUSH IX                                      ; preserve pointer to local variables
                    CALL Open_file
                    LD   (objfilehandle),IX                      ; objfile = fopen(curlib->filename, "r")
                    POP  IX

.searchlibfile_loop LD   L,(IX+0)
                    LD   H,(IX+1)
                    LD   B,(IX+2)                                ; curlib pointer
                    LD   A, libfile_nextobjfile+3                ; {get high byte of file pointer}
                    CALL Read_byte
                    CP   -1
                    JP   Z, end_of_libfile                       ; while (curlib->nextobjfile != -1)
.find_avail_module       PUSH IX                                      ; do
                         LD   IX, (objfilehandle)
                         LD   DE, libfile_nextobjfile
                         CALL fseek                                        ; fseek(objfile, curlib->nextobjfile, SEEK_SET)
                         LD   A, libfile_nextobjfile
                         CALL Read_long
                         EXX
                         LD   (longint),BC
                         LD   (longint+2),DE                               ; currentlibmodule = curlib->nextobjfile
                         EXX
                         LD   DE, libfile_nextobjfile
                         CALL Read_fptr                                    ; curlib->nextobjfile = ReadLong(objfile)
                         CALL_OZ(Os_Gb)
                         LD   E,A
                         CALL_OZ(Os_Gb)
                         LD   D,A
                         CALL_OZ(Os_Gb)
                         LD   C,A
                         CALL_OZ(Os_Gb)                                    ; {skip redundant byte of file pointer}
                         POP  IX
                         LD   (IX+6),E
                         LD   (IX+7),D
                         LD   (IX+8),C                                     ; modulesize = ReadLong(objfile)
                         XOR  A
                         CP   C
                         JR   NZ, check_modulename
                         CP   D
                         JR   NZ, check_modulename
                         CP   E
                         JR   NZ, check_modulename                    ; while ( modulesize == 0 &&
                         LD   A, libfile_nextobjfile+3
                         CALL Read_byte                               ; {get high byte of file pointer}
                         CP   -1
                         JR   NZ, find_avail_module                   ;                             curlib->nextobjfile != -1)

.check_modulename        XOR  A
                         CP   C
                         JR   NZ, get_module_name
                         CP   D
                         JR   NZ, get_module_name
                         CP   E
                         JR   Z, searchlibfile_loop                  ; if ( modulesize != 0 )
.get_module_name              PUSH IX                                      ; {preserve pointer to local variables}
                              LD   BC,(longint+2)
                              PUSH BC
                              LD   BC,(longint)
                              PUSH BC                                      ; {preserve currentlibmodule}
                              LD   BC, 4+4+8+2
                              LD   DE,0
                              LD   HL, longint
                              CALL Add32bit
                              LD   IX,(objfilehandle)                      ; {B=0, local pointer}
                              CALL fseek                                   ; fseek(objfile, currentlibmodule+4+4+8+2, SEEK_SET)
                              CALL Read_fptr                               ; fptr_mname = ReadLong(objfile), fileptr. at  (longint)
                              POP  BC
                              POP  DE
                              PUSH DE
                              PUSH BC                                      ; {preserve currentlibmodule}
                              CALL Add32bit                                ; {fptr_mname += currentlibmodule}
                              LD   BC,4+4
                              LD   DE,0
                              CALL Add32bit                                ; {fptr_mname += 4+4}
                              CALL fseek                                   ; fseek(objfile, fptr_mname, SEEK_SET)
                              CALL LoadName                                ; mname = Loadname(objfile)
                              POP  BC
                              POP  DE
                              LD   (longint),BC
                              LD   (longint+2),DE                          ; {currentlibmodule}
                              POP  IX                                      ; {restore pointer to local variables}
                              LD   A,(IX+5)                                ; {bank number of modname pointer}
                              CALL Bind_bank_s1
                              PUSH AF                                      ; {preserve old bank binding}

                              LD   E,(IX+3)
                              LD   D,(IX+4)
                              LD   A,(DE)
                              INC  DE
                              CP   (HL)                                    ; are strings of equal length?
                              INC  HL                                      ; point at first char of loaded name
                              JR   NZ, modname_notequal                    ; if ( strcmp(mname, modname) == 0 )
                                   LD   B,0
                                   LD   C,A                                     ; {length of both strings}
                                   CALL memcompare                              ; equal length, compare strings...
                                   JR   NZ, modname_notequal
                                   POP  AF
                                   CALL Bind_bank_s1                            ; {restore prev. bank binding}
                                   LD   HL, objfilehandle
                                   CALL Close_file                              ; fclose(objfile)
                                   LD   BC,4+4
                                   LD   DE,0
                                   LD   HL, longint
                                   CALL Add32bit                                ; {currentlibmodule+4+4}
                                   LD   HL,(longint)
                                   LD   A,(longint+2)
                                   LD   (IX+6),L
                                   LD   (IX+7),H
                                   LD   (IX+8),A                                ; {currentlibmodule+4+4 on parameter stack}
                                   CALL LinkLibModule                           ; LinkLibModule(curlib, modname, baseptr)
                                   JR   exit_searchlibfile

.modname_notequal             POP  AF
                              CALL Bind_bank_s1                       ; {restore prev. bank binding}
                         JP   searchlibfile_loop                 ; {while (curlib->nextobjfile != -1)

.end_of_libfile     SCF

.end_searchlibfile  LD   HL,objfilehandle
                    CALL Close_file                              ; fclose(objfile)

.exit_searchlibfile POP  HL                                      ; pointer to entry SP
                    LD   SP,HL                                   ; remove local variables
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  IX
                    RET                                          ; return to caller


; **************************************************************************************************
;
;    Link library module machine code and name definitions.
;
;    IN:  IX points at parameters:
;              (IX+0,2)  = library
;              (IX+3,5)  = modname
;              (IX+6,8)  = curmodule
;
;    OUT: Fc = 0 if successfully linked, otherwise Fc = 1
;
; Registers changed after return:
;
;    ......../..IY  same
;    AFBCDEHL/IX..  different
;
.LinkLibModule      CALL CurrentModule
                    PUSH BC
                    PUSH HL                            ; tmpmodule = CURRENTMODULE
                    CALL NewModule
                    JR   C, end_linklibmodule          ; if ( (newm = NewModule()) != NULL )
                         LD   HL, CURMODULE
                         CALL GetPointer
                         XOR  A                             ; {CDE = newm, pointer to new module}
                         CALL Set_pointer                   ; {CURRENTMODULE = newm}
                         LD   L,(IX+3)
                         LD   H,(IX+4)
                         LD   B,(IX+5)
                         CALL CopyId                        ; mname = AllocId(modname)
                         JR   C, end_linklibmodule          ; if ( mname == NULL ) return 0
                         LD   HL, CURMODULE
                         CALL GetVarPointer
                         LD   A, module_mname               ; {CDE = pointer to mname}
                         CALL Set_pointer                   ; CURRENTMODULE = mname
                         LD   L,(IX+0)
                         LD   H,(IX+1)
                         LD   B,(IX+2)                      ; BHL = curlib
                         LD   A, libfile_filename
                         CALL Read_pointer                  ; BHL = curlib->libfilename
                         PUSH BC
                         PUSH HL                            ; remember pointer to libfilename

                         LD   A,B
                         CALL Bind_bank_s1
                         LD   DE, cdebuffer
                         PUSH DE
                         PUSH AF                            ; preserve old segment 2 bank binding
                         LD   B,0
                         LD   C,(HL)
                         INC  C
                         INC  C                             ; length incl. length byte and terminator
                         LDIR                               ; copy into safe area
                         POP  AF
                         CALL Bind_bank_s1                  ; restore previos bank binding
                         POP  DE                            ; DE = local pointer to filename
                         XOR  A
                         LD   B,A
                         LD   H,A
                         LD   L,A                           ; BHL = NULL
                         CALL NewFile                       ; nfile = NewFile(NULL, library->filename)
                         CALL CurrentModule
                         LD   A, module_cfile
                         CALL Set_pointer                   ; CURRENTFILE = nfile

                         CALL Disp_libmod_msg               ; printf("linking library module <%s>\n", library->filename)

                         POP  HL
                         POP  BC                            ; BHL = libfilename
                         LD   E,(IX+6)
                         LD   D,(IX+7)
                         LD   C,(IX+8)                      ; curmodule, file base pointer of object module in library file
                         CALL LinkModule                    ; flag = LinkModule(curlib->filename, curmodule)

.end_linklibmodule  POP  DE
                    POP  BC                            ; {tmpmodule in BDE}
                    PUSH AF                            ; preserve error flag

                    PUSH BC
                    LD   HL, CURMODULE
                    CALL GetPointer
                    LD   A,B
                    POP  BC
                    LD   C,B
                    LD   B,A                           ; {BHL = &CURRENTMODULE, CDE = tmpmodule}
                    XOR  A
                    CALL Set_pointer                   ; CURRENTMODULE = tmpmodule

                    POP  AF
                    RET                                ; return flag



; **************************************************************************************************
;
; Display library module message
;
.Disp_libmod_msg    LD   HL, libmod_msg
                    CALL_OZ(Gn_Sop)
                    LD   L,(IX+3)
                    LD   H,(IX+4)
                    LD   B,(IX+5)
                    INC  HL
                    CALL_OZ(Gn_Soe)               ; printf(modname)
                    LD   HL, libmod_msg2
                    CALL_OZ(Gn_sop)
                    RET

.libmod_msg         DEFM 1, "2H5Library module <", 0
.libmod_msg2        DEFM ">", 13, 10, 0

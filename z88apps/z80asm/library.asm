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

     MODULE Library_management

; external procedures:
     LIB malloc, mfree
     LIB Set_pointer, Read_pointer, Set_word, Set_long

     XREF GetPointer, GetVarPointer          ; varptr.asm

; global procedures:
     XDEF NewLibrary


     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"



; **************************************************************************************************
;
;    Create new library and append to list of libraries, if present
;
; OUT:    Fc = 0, success & BHL = pointer to new library
;         Fc = 1, no room & BHL = NULL
;         (pointers in list modified)
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.NewLibrary         LD   HL, libraryhdr
                    CALL GetVarPointer                 ; get pointer to library pointer
                    XOR  A
                    CP   B
                    JR   NZ, libhdr_exists             ; if ( libraryhdr == NULL ) {
                         CALL AllocLibraryHdr          ;    if ( (libraryhdr = AllocLibraryHdr()) == NULL )
                         JP   C, newl_nullptr          ;         return (no room)...
                                                       ;    else {
                         LD   C,B                      ;
                         EX   DE,HL
                         LD   HL,libraryhdr
                         CALL GetPointer               ;         { ptr. to pointer variable 'libraryhdr' }
                         XOR  A                        ;
                         CALL Set_pointer              ;         { store pointer to libraryhdr record }
                         LD   B,C                      ;
                         EX   DE,HL                    ;         { restore libraryhdr ptr. in BHL }
                         XOR  A
                         LD   E,A
                         LD   D,A
                         LD   C,A                      ;         { NULL pointer }
                         LD   A, liblist_first
                         CALL Set_pointer              ;         libraryhdr->first = NULL
                         LD   A, liblist_current
                         CALL Set_pointer              ;         libraryhdr->current = NULL
                                                       ;    }
                                                       ; }

.libhdr_exists      CALL AllocLibrary                  ; if ( (newl = AllocLibrary()) == NULL )
                    JP   C, newl_nullptr               ;    Ups - no room
                    XOR  A                               else
                    LD   D,A
                    LD   E,A                                { BHL = newl }
                    LD   C,A                           ;    { CDE = NULL pointer }
                    LD   A, libfile_next
                    CALL Set_pointer                   ;    newl->next = NULL
                    LD   A, libfile_filename
                    CALL Set_pointer                   ;    newl->filename = NULL
                    EXX
                    LD   BC,-1
                    LD   D,B
                    LD   E,C
                    EXX
                    LD   A, libfile_nextobjfile
                    CALL Set_long                      ;    newl->nextobjfile = -1

                    LD   C,B
                    EX   DE,HL                         ; { CDE = newl }
                    LD   HL, libraryhdr
                    CALL GetVarPointer                 ; { get pointer to modulehdr pointer in BHL }
                    PUSH BC
                    PUSH HL                            ; { preserve modulehdr }
                    LD   A, liblist_first
                    CALL Read_pointer                  ; { BHL = liblist->first }
                    XOR  A
                    CP   B
                    POP  HL                            ; { restore libraryhdr }
                    POP  BC
                    JR   NZ, append_library            ; if ( libraryhdr->first == NULL )
                         LD   A, liblist_first
                         CALL Set_pointer              ;    libraryhdr->first = newl
                         LD   A, liblist_current
                         CALL Set_pointer              ;    libraryhdr->current = newl
                         JR   end_newlibrary
                                                       ; else
.append_library     PUSH BC
                    PUSH HL                            ;    { preserve libraryhdr }
                    LD   A, liblist_current
                    CALL Read_pointer
                    LD   A, libfile_next
                    CALL Set_pointer                   ;    libraryhdr->current->next = newl
                    POP  HL
                    POP  BC
                    LD   A, liblist_current
                    CALL Set_pointer                   ;    libraryhdr->current = newl

.end_newlibrary     XOR  A
                    LD   B,C
                    EX   DE,HL                         ; return BHL = newl
                    RET                                ; indicate succes...

.newl_nullptr       EX   DE,HL
                    LD   C,B
                    SCF                                ; return NULL
                    RET

; ***********************************************************************************************
;
;    Allocate memory for module header record
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocLibraryHdr    LD   A, SIZEOF_libraries
                    CALL malloc
                    RET


; **************************************************************************************************
;
;    Allocate memory for module record
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocLibrary       LD   A, SIZEOF_libfile
                    CALL malloc
                    RET

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

     MODULE Module_management

; external procedures:
     LIB malloc, mfree
     LIB GetPointer, GetVarPointer
     LIB Set_pointer, Read_pointer, Set_word, Set_long

     XREF RemovePfixList                               ; rmpfixlist.asm
     XREF Display_filename                             ; dispflnm.asm
     XREF Open_file                                    ; fileio.asm
     XREF CurrentFile, CurrentFileName                 ; currfile.asm
     XREF CurrentModule                                ; currmodule.asm
     XREF NewFile                                      ; srcfile.asm
     XREF ReportError, ReportError_NULL                ; errors.asm

; global procedures:
     XDEF NewModule, CreateModule, CreateModules
     XDEF ReleaseExpressions

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "error.def"
     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; *********************************************************************************************
;
; Create new module for file name
;
; IN:     None.
; OUT:    Fc = 0, module created with file name
;         Fc = 1, no room for module, illegal file name or file not found
;
.CreateModule       CALL NewModule
                    RET  C                             ; Ups - no room
                    LD   HL, CURMODULE
                    CALL GetPointer
                    XOR  A                             ; {CDE = pointer to new module}
                    CALL Set_pointer                   ; CURRENTMODULE = NewModule()

                    CALL CreateSrcFilename             ; add '.asm' extension to file name
                    INC  HL                            ; point at first char in file name
                    CALL Display_filename
                    LD   A, OP_IN
                    CALL Open_file                     ; open file to get expanded file name
                    JR   C, module_operr               ; DE points at explicit filename
                    CALL_OZ(Gn_Cl)
                    CALL ModuleFileName                ; create extended OZ file name
                    CP   A                             ; signal success
                    RET

.module_operr       CP   RC_Ivf                        ; if ( error != RC_ivf )
                    JR   Z, bad_filename
                         BIT  datestamp,(IY + RTMflags)     ; if ( !datestamp )
                         JR   NZ, use_shortname
                              SCF
                              JP   ReportError_NULL              ; report open error if no date stamping...
                                                                 ; then return to caller
                                                            ; else
.use_shortname           LD   DE, cdebuffer                      ; file couldn't be opened, but use
                         CALL ModuleFileName                     ; non-extended file name
                         CP   A
                         RET                           ; else
.bad_filename       SCF
                    JP   ReportError_NULL                   ; report error


; *********************************************************************************************
;
; Open modules file and create modules for each specified file name in modules file
;
.CreateModules      LD   B,0
                    LD   HL, cdebuffer+1                    ; point at first char of filename
                    LD   A, OP_IN
                    CALL Open_file
                    JP   C, ReportError_NULL
.fetch_modname           LD   B, 252
                         LD   HL, cdebuffer
                         LD   DE, cdebuffer+1
.read_name               CALL_OZ(Os_Gb)
                         JR   C, createmodules_end          ; EOF occurred...
                         CALL Check_EOL
                         JR   Z, filename_fetched
                         LD   (DE),A
                         INC  DE
                         DJNZ read_name

.filename_fetched        XOR  A
                         LD   (DE),A                        ; null-terminate filename
                         LD   A, 252
                         SUB  B                             ; length of file name
                         LD   (HL),A
                         PUSH IX                            ; preserve handle of modules file
                         CALL CreateModule                  ; create new module for file
                         POP  IX
                         JR   C, createmodules_err          ; error occurred
                         JR   fetch_modname                 ; read next module file...

.createmodules_end  CP   A
.createmodules_err  PUSH AF
                    CALL_OZ(Gn_Cl)                     ; close module file
                    POP  AF
                    RET

.Check_EOL          CP   LF
                    RET  Z                             ; LF = EOL
                    CP   CR
                    RET  NZ                            ; filename byte

                    PUSH HL                            ; CR fetched, check for
                    PUSH DE                            ; trailing LF
                    PUSH BC                            ; {preserve main registers first}
                    LD   A, FA_PTR
                    LD   DE,0
                    CALL_OZ(Os_Frm)                    ; file pointer in DEBC
                    CALL_OZ(OS_Gb)                     ; get next byte from file
                    JR   C, eol_reached                ; EOF reached...
                         CP   LF
                         JR   Z, eol_reached           ; trailing LF fetched...
                              PUSH DE                       ; Ups - first byte of new filename
                              PUSH BC                       ; unget byte (restore previous filep.)
                              LD   HL,0
                              ADD  HL,SP                    ; HL points at file pointer
                              LD   A, FA_PTR
                              CALL_OZ(OS_Fwm)               ; restore file pointer at CR
                              POP  BC
                              POP  DE                       ; remove redundant file pointer
.eol_reached        CP   A
                    POP  BC                            ; return Fz = 1 to indicate EOL
                    POP  DE
                    POP  HL                            ; original BC, DE, HL restored
                    RET


; *********************************************************************************************
;
; Add extension to file name
;
; IN:     None.
;
; OUT:    HL = pointer to new local file name,
;         D = 0
;         E = length of new file name
;
; Registers changed after return:
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.CreateSrcFileName  LD   DE, srcext
                    LD   HL, cdebuffer                 ; local pointer to filename
                    PUSH HL
                    LD   B,0
                    LD   C,(HL)                        ; length of file name
                    INC  HL                            ; point at first char
                    ADD  HL,BC                         ; point at null-terminator
                    PUSH BC                            ; preserve length
                    LD   C,4
                    EX   DE,HL                         ; HL points to extension...
                    LDIR                               ; add extension to file name
                    XOR  A
                    LD   (DE),A                        ; null-terminate file name
                    LD   HL,4
                    POP  BC
                    ADD  HL,BC                         ; length inclusive extension
                    EX   DE,HL
                    POP  HL
                    LD   (HL),E                        ; new length stored
                    RET
.srcext             DEFM ".asm"


; *********************************************************************************************
;
;    IN:  DE = local pointer to filename
;
.ModuleFileName     CALL CurrentFile                   ; BHL = NULL
                    CALL NewFile                       ; return pointer to file record in CDE
                    CALL CurrentModule
                    LD   A, module_cfile
                    JP   Set_pointer                   ; CURRENTMODULE->cfile = NewFile(NULL, textfile)


; **************************************************************************************************
;
;    Create new module and append to list of modules, if present
;
; OUT:    Fc = 0, success & BHL = pointer to new module
;         Fc = 1, no room & BHL = NULL
;         (pointers in list modified)
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.NewModule          LD   HL, modulehdr
                    CALL GetVarPointer                 ; get pointer to modulehdr pointer
                    XOR  A
                    CP   B
                    JR   NZ, modulehdr_exists          ; if ( modulehdr == NULL ) {
                         CALL AllocModuleHdr           ;    if ( (modulehdr = AllocModuleHdr()) == NULL )
                         JP   C, newm_nullptr          ;         return (no room)...
                                                       ;    else {
                         LD   C,B                      ;
                         EX   DE,HL
                         LD   HL,(modulehdr)
                         LD   A,(modulehdr+2)
                         LD   B,A                      ;         { ptr. to pointer variable 'modulehdr' }
                         XOR  A                        ;
                         CALL Set_pointer              ;         { store pointer to modulehdr record }
                         LD   B,C                      ;
                         EX   DE,HL                    ;         { restore modulehdr ptr. in BHL }
                         XOR  A
                         LD   E,A
                         LD   D,A
                         LD   C,A                      ;         { NULL pointer }
                         LD   A, modules_first
                         CALL Set_pointer              ;         modulehdr->first = NULL
                         LD   A, modules_last
                         CALL Set_pointer              ;         modulehdr->current = NULL
                                                       ;    }
                                                       ; }

.modulehdr_exists   CALL AllocModule                   ; if ( (newm = AllocModule()) == NULL )
                    JP   C, newm_nullptr               ;    Ups - no room
                    XOR  A                               else
                    LD   D,A
                    LD   E,A                                { BHL = newm }
                    LD   C,A                           ;    { CDE = NULL pointer }
                    LD   A, module_next
                    CALL Set_pointer                   ;    newm->nextmodule = NULL
                    LD   A, module_mname
                    CALL Set_pointer                   ;    newm->mname = NULL
                    LD   A, module_cfile
                    CALL Set_pointer                   ;    newm->cfile = NULL
                    LD   A, module_localroot
                    CALL Set_pointer                   ;    newm->localroot = NULL
                    EXX
                    LD   BC,(codesize)
                    LD   DE,0
                    EXX
                    LD   A, module_startoffset
                    CALL Set_long                      ;    newm->startoffset = codesize
                    LD   A, module_origin
                    LD   DE, $FFFF
                    CALL Set_word                      ;    newm->origin = 65535

                    PUSH BC                                 { preserve newm }
                    PUSH HL                            ;
                    CALL AllocExprHdr                  ;    if ( (m = AllocExprhdr()) == NULL )
                    JR   C, mexpr_no_room
                         LD   C,0
                         LD   D,C
                         LD   E,C
                         LD   A, expression_first
                         CALL Set_pointer              ;         m->firstexpr = NULL
                         LD   A, expression_curr
                         CALL Set_pointer              ;         m->currexpr = NULL
                         LD   A,B
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         LD   C,A                      ;         { BHL = newm, CDE = m }
                         LD   A,module_mexpr
                         CALL Set_pointer              ;         newm->mexpr = m
                                                       ;    else
                                                       ;         free(newm)
                                                       ;         return 0

; allocate JR address header and store pointer in module
.alloc_JRaddr       PUSH BC
                    PUSH HL                            ; {preserve newm}
                    CALL AllocJRaddrHdr                ;    if ( (m = AllocJRaddrhdr()) == NULL )
                    JR   C, JRaddr_no_room
                         LD   C,0
                         LD   D,C
                         LD   E,C
                         LD   A, JRpcexpr_first
                         CALL Set_pointer              ;         m->firstref = NULL
                         LD   A, JRpcexpr_last
                         CALL Set_pointer              ;         m->lastref = NULL
                         LD   A,B
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         LD   C,A                      ;         { BHL = newm, CDE = m }
                         LD   A,module_JRaddr
                         CALL Set_pointer              ;         newm->JRaddr = m

                    LD   C,B
                    EX   DE,HL                         ; { CDE = newm }
                    LD   HL, modulehdr
                    CALL GetVarPointer                 ; { get pointer to modulehdr pointer in BHL }
                    PUSH BC
                    PUSH HL                            ; { preserve modulehdr }
                    LD   A, modules_first
                    CALL Read_pointer                  ; { BHL = modulehdr->first }
                    XOR  A
                    CP   B
                    POP  HL                            ; { restore modulehdr }
                    POP  BC
                    JR   NZ, append_module             ; if ( modulehdr->first == NULL )
                         LD   A, modules_first
                         CALL Set_pointer              ;    modulehdr->first = newm
                         LD   A, modules_last
                         JP   Set_pointer              ;    modulehdr->current = newm (Fc = 0)
                                                       ; else
.append_module      PUSH BC
                    PUSH HL                            ;    { preserve modulehdr }
                    LD   A, modules_last
                    CALL Read_pointer
                    LD   A, module_next
                    CALL Set_pointer                   ;    modulehdr->current->nextmodule = newm
                    POP  HL
                    POP  BC
                    LD   A, modules_last
                    JP   Set_pointer                   ;    modulehdr->current = newm
                                                       ; return CDE = newm (Fc = 0)

; nor room for JD address header, free <newm->mexpr> and <newm>.
.JRaddr_no_room     POP  HL
                    POP  BC
                    PUSH BC
                    PUSH HL                            ;         { BHL = newm }
                    LD   A, module_mexpr
                    CALL Read_pointer
                    CALL mfree                         ;         free(newm->mexpr)

.mexpr_no_room      POP  HL
                    POP  BC                            ;         { restore newm in BHL }
                    CALL mfree                                   free(newm);
.newm_nullptr       EX   DE,HL
                    LD   C,B
                    SCF                                ;         return NULL
                    RET



; **************************************************************************************************
;
;    Release any pass2 expressions in current module
;
;    IN: None.
;
.ReleaseExpressions CALL CurrentModule
                    LD   A, module_mexpr
                    CALL Read_pointer             ; exprhdr = CURRENTMODULE->mexpr
                    XOR  A
                    CP   B
                    RET  Z                        ; if ( exprhdr == NULL ) return

                    PUSH BC
                    PUSH HL                       ; { preserve exprhdr }
                    LD   A, expression_first
                    CALL Read_pointer             ; curexpr = exprhdr->first
                    INC  B
                    DEC  B
                    JR   Z, release_exprhdr       ; if ( curexpr != NULL )
.relexpr_loop            PUSH BC                       ; do
                         PUSH HL
                         LD   A,expr_nextexpr
                         CALL Read_pointer                  ; tmpexpr = curexpr->nextexpr
                         LD   A,B
                         EX   DE,HL
                         POP  HL
                         POP  BC
                         LD   C,A
                         PUSH BC
                         PUSH DE
                         CALL RemovePfixList                ; RemovepfixList(curexpr)
                         POP  HL
                         POP  BC
                         LD   B,C                           ; curexpr = tmpexpr
                         XOR  A
                         CP   B
                    JR   NZ, relexpr_loop              ; while (curexpr != NULL)

.release_exprhdr    POP  HL
                    POP  BC                       ; { restore header of expressions }
                    CALL mfree                    ; free(exprhdr)
                    CALL CurrentModule
                    LD   A, module_mexpr
                    LD   C,0
                    LD   DE,0
                    JP   Set_pointer              ; CURRENTMODULE->mexpr = NULL


; **************************************************************************************************
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
.AllocModuleHdr     LD   A, SIZEOF_modules
                    JP   malloc


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
.AllocModule        LD   A, SIZEOF_module
                    JP   malloc


; **************************************************************************************************
;
;    Allocate memory for module expression header list
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocExprHdr       LD   A, SIZEOF_expression
                    JP   malloc


; **************************************************************************************************
;
;    Allocate memory for Jump Relative Address header
;
;    IN: None
;   OUT: BHL = extended pointer to allocated memory, otherwise NULL if no room
;
; Registers changed after return:
;
;    ...CDE../IXIY  same
;    AFB...HL/....  different
;
.AllocJRaddrHdr     LD   A, SIZEOF_jrpcexpr
                    JP   malloc

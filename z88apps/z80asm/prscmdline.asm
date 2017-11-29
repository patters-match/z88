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

     MODULE Parse_Cmdline

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"
     INCLUDE "stdio.def"
     INCLUDE "fileio.def"

     LIB Release_pools
     LIB AllocIdentifier, mfree
     LIB GetPointer, GetVarPointer

     XREF Getsym                                            ; getsym.asm
     XREF Open_file                                         ; fileio.asm
     XREF UseLibrary, CreateLibrary, NewLibrary             ; library.asm
     XREF GetFileName                                       ; crtflnm.asm
     XREF CurrentModule, CreateModule, NewModule            ; module.asm
     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF DefineDefSym                                      ; symbols.asm
     XREF GetOrigin                                         ; deforig.asm

     XDEF Parse_cmdline

; ****************************************************************************************
;
; Parse command line for file names and various RTMflags
;
; IN:     None.
; OUT:    Fc = 1, problems reading filename, no room error or file open error
;         Fc = 0, command line succesfully parsed
;
.Parse_cmdline      LD   HL, linebuffer
                    LD   (lineptr),HL

.parse_loop         LD   HL,(lineptr)
.skip_spaces        LD   A,(HL)
                    INC  HL
                    CP   0
                    JP   Z, check_modules
                    CP   ' '
                    JR   Z, skip_spaces
                    CP   '-'
                    JR   Z, fetch_flag
                    CP   '#'                           ; if ( isalpha(*lineptr) )
                    JR   Z, read_modulefile
                    DEC  HL
                    CALL GetFileName
                    CALL CreateModule                       ; CreateModule(ident)
                    JR   NC, parse_loop                ; else
                    JR   cmdline_error                      ; release memory and abort command line

.read_modulefile    CALL GetFileName                        ; {get ident}
                    CALL CreateModules                      ; CreateModules(ident)
                    JP   NC, check_modules
                    JR   C, cmdline_error                   ; release memory and abort command line
                                                            ; else
.nonsense           LD   A, ERR_syntax
                    CALL ReportError_NULL
.cmdline_error      CALL Release_pools                           ; Release_pools()
                    SCF                                          ; return 0
                    RET


; ******************************************************************************
;
.fetch_flag
.flag_loop          LD   A,(HL)
                    INC  HL
                    LD   (lineptr),HL
                    CP   0
                    JP   Z, check_modules
                    CP   ' '
                    JR   Z, skip_spaces
                    PUSH HL
                    LD   HL, RTMflag
                    LD   BC, 5
                    CPIR
                    PUSH AF
                    DEC  HL
                    LD   C, 5
                    ADD  HL,BC
                    EX   DE,HL                                   ; DE points at bit number
                    POP  AF
                    POP  HL
                    JR   Z, invert_rtmflag
                    CP   'i'
                    JR   Z, use_library
                    CP   'x'
                    JR   Z, create_library
                    CP   'D'
                    JP   Z, define_symbol
                    CP   'R'
                    JP   Z, define_relocation
                    CP   'c'
                    JP   Z, define_codesegment
                    CP   'r'
                    JP   Z, define_cmdline_org
                    JR   nonsense                                ; unknown flag...


; **************************************************************************************************
;
; invert runtime flag, specified from command line
;
.invert_rtmflag     LD   A,(DE)
                    LD   B,A
                    PUSH HL
                    LD   HL, RunTimeFlags1
                    CALL Switch_bitnumber              ; toggle RTM flag
                    POP  HL
                    JR   flag_loop                     ; fetch next flag


; **************************************************************************************************
.use_library        CALL UseLibrary
                    JR   C, cmdline_error              ; release memory and abort command line
                    JP   parse_loop


; **************************************************************************************************
;
; Create library file, specified from command line as -xfilename .
;
; HL points at first char of filename
;
.create_library     CALL CreateLibrary
                    JR   C, cmdline_error              ; release memory and abort command line
                    JP   parse_loop


; ******************************************************************************
;
;    Define a DEFINE symbol (static). HL points at start of define-name.
;
.define_symbol      CALL Getsym
                    CP   sym_name
                    JR   NZ, ill_name
                         LD   HL, Ident
                         CALL AllocIdentifier                    ; tmpident to extended memory, BHL = asmpc_ident
                         CALL C, ReportError_NULL
                         JP   C, cmdline_error
                         PUSH BC
                         PUSH HL
                         LD   C,B
                         EX   DE,HL                              ; asmpc_ident in CDE
                         EXX
                         LD   BC,-1
                         LD   D,B
                         LD   E,C
                         EXX
                         LD   HL, staticroot
                         CALL GetPointer                         ; &staticroot in BHL
                         LD   A,0
                         CALL DefineDefSym                       ; DefineDefSym(ident, 0, 0, &staticroot)
                         POP  HL
                         POP  BC
                         CALL mfree                              ; free(tmpident)
                         JP   parse_loop

.ill_name           LD   A, ERR_ill_ident
                    CALL ReportError_NULL
                    SCF
                    JP   cmdline_error


; ******************************************************************************
;
;    Define explicit ORIGIN.
;    HL points at first char of ORIGIN constant
;
.define_cmdline_org CALL Getsym                   ; parse command line for constant
                    CALL GetOrigin
                    JP   C, cmdline_error
                         EXX
                         LD   (explicitORIG),HL             ; origin defined.
                         EXX
                         SET  deforigin,(IY + RTMflags)
                    JP   parse_loop


; ******************************************************************************
;
.define_relocation  SET  autorelocate,(IY + RTMflags2)
                    JP   parse_loop


; ******************************************************************************
;
.define_codesegment SET  codesegment,(IY + RTMflags2)
                    JP   parse_loop


; ******************************************************************************
;
.check_modules      LD   HL, modulehdr
                    CALL GetVarPointer                 ; if ( modulehdr == NULL )
                    XOR  A                                  return 0
                    CP   B                             ; else
                    JP   Z, cmdline_error                   return 1
                    RET


; **********************************************************************************
;
;  Switch bit number (specified in D) at (HL)
;
;   Input:          HL = pointer to byte
;                   B : bit number, e.g. BIT 6 = @01000000 .
;
;  This code is used for toggling the z80asm RTM flags
;
; Status of registers on return:
;
;       ...CDEHL/IXIY  same
;       AFB...../....  different
;
.Switch_bitnumber   LD   A,(HL)                           ; fetch byte
                    AND  B                                ; bit set?
                    JR   Z, Set_bitnumber                 ; No, set bit number
.Reset_bitnumber    LD   A,B
                    CPL                                   ; invert B bitpattern
                    LD   B,A
                    LD   A,(HL)
                    AND  B                                ; RES B, (HL)
                    LD   (HL),A
                    RET
.Set_bitnumber      LD   A,(HL)
                    OR   B                                ; SET B, (HL)
                    LD   (HL),A
                    RET

.RTMflag            DEFB 's', 'b', 'm', 'g', 'd'
.RTMflag_bits       DEFB 2**symtable, 2**z80bin, 2**mapref, 2**globaldef, 2**datestamp



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

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
     XREF GetConstant                                       ; getconst.asm
     XREF Open_file                                         ; fileio.asm
     XREF UseLibrary, DefineLibFileName                     ; library.asm
     XREF GetFileName                                       ; crtflnm.asm
     XREF CreateModule, CreateModules                       ; module.asm
     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF Get_stdoutp_handle,Display_error                  ; stderror.asm
     XREF DefineDefSym                                      ; symbols.asm
     XREF Test_16bit_range                                  ; tstrange.asm

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
                    OR   A
                    JP   Z, check_modules
                    CP   ' '
                    JR   Z, skip_spaces
                    CP   '-'
                    JR   Z, fetch_flag
                    CP   '#'                           ; if ( isalpha(*lineptr) )
                    JR   Z, read_modulefile
                    DEC  HL
                    CALL GetFileName
                    LD   (lineptr),HL
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
                    OR   A
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
.use_library        CALL GetFileName                   ; collect filename at (HL) into buffer
                    LD   (lineptr),HL
                    CALL UseLibrary
                    JR   C, cmdline_error              ; release memory and abort command line
                    JP   parse_loop


; **************************************************************************************************
;
; Create library file, specified from command line as -xfilename .
;
; HL points at first char of filename
;
.create_library     CALL GetFileName                   ; get library filename from command line
                    LD   (lineptr),HL
                    CALL DefineLibFileName
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
                    CALL GetVarPointer                 ; if ( modulehdr != NULL )
                    INC  B                                  return 1
                    DEC  B                             ; else
                    JP   Z, cmdline_error                   return 0
                    CP   A
                    RET


; ******************************************************************************
;
;    Get ORIGIN constant
;    (Ident) contains constant (previously read with Getsym).
;
;    return ORG integer in alternate HL, Fc = 0 (successfully fetched),
;    otherwise Fc = 1.
;
.GetOrigin          CALL GetConstant              ; and convert to integer
                    JR   C, illegal_origin        ; syntax error, illegal constant
                         EXX                      ; constant returned in alternate DEBC
                         PUSH DE
                         PUSH BC
                         POP  HL
                         EXX
                         POP  HL
                         LD   C,0                 ; convert constant to HLhlC format
                         CALL Test_16bit_Range    ; range must be [0; 65535]
                         RET  NC

.org_range               LD   A, ERR_range
                         SCF
                         JR   OriginError
.illegal_origin          LD   A, ERR_syntax
                         SCF

.OriginError             PUSH AF
                         PUSH IX
                         CALL Get_stdoutp_handle  ; handle for standard output
                         CALL Display_error       ; display error message
                         CALL_OZ(Gn_Nln)          ; but don't affect z80asm error system
                         POP  IX
                         POP  AF
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


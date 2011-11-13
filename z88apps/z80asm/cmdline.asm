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

     MODULE Command_line


     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"
     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "director.def"
     INCLUDE "error.def"

     LIB Release_pools, Set_pointer
     LIB Bind_bank_s1
     LIB AllocIdentifier, mfree
     LIB IsAlpha
     LIB GetPointer, GetVarPointer, AllocVarPointer

     XREF Disp_allocmem                                     ; z80asm.asm
     XREF ReportError, ReportError_NULL                     ; errors.asm
     XREF CurrentModule, NewModule, ReleaseModules          ; module.asm
     XREF CurrentFile, CurrentFileName                      ; currfile.asm
     XREF NewFile                                           ; srcfile.asm
     XREF Display_filename                                  ; dispflnm.asm
     XREF Open_file                                         ; fileio.asm
     XREF z80asm_ERH                                        ; ehandler.asm
     XREF CreateLibFile                                     ; creatlib.asm
     XREF CheckFileHeader                                   ; chckfhdr.asm
     XREF NewLibrary                                        ; library.asm
     XREF Getsym                                            ; getsym.asm
     XREF GetConstant                                       ; getconst.asm
     XREF GetOrigin                                         ; deforig.asm
     XREF DefineDefSym                                      ; symbols.asm

     XDEF Command_line, Parse_cmdline
     XDEF Display_status


; ****************************************************************************************
;
; Activate command line and parse input.
;
; IN:     None.
; OUT:    Fc = 0, no parsing errors, otherwise Fc = 1
;
.Command_line       CALL Display_status
                    CALL Input_commands
                    CALL Parse_cmdline
                    CALL NC,Display_status             ; display only RTM flags if no command line errors
                    RET


; ****************************************************************************************
;
.Input_commands     LD   HL, commands_msg
                    CALL_OZ(Gn_sop)
                    XOR  A
                    LD   DE,linebuffer
                    LD   (DE),A                        ; null-terminate beginning of line
                    LD   B,255                         ; max. buffer length
                    LD   C,0                           ; cursor position in buffer
.inpline_loop       LD   HL, select_win3
                    CALL_OZ(Gn_Sop)                    ; select command window
                    LD   HL,CurPos                     ; set cursor position for input window
                    CALL_OZ (Gn_Sop)
                    LD   A,@00000001                   ; Info in input buffer...
                    CALL_OZ (Gn_Sip)                   ; input assembler commands & file names...
                    CALL C, z80asm_ERH
                    LD   B,255                         ; re-initiate buffer length
                    CP   IN_ENT
                    RET  Z                             ; <ENTER> pressed - command line finished
                    JR   inpline_loop
.CurPos             DEFM 1, "2X", $20, 0               ; set cursor at beginning of line...
.select_win3        DEFM 1, "2H3", 12, 0               ; select window "3"
.commands_msg       DEFM 1, "2H5awaiting commands...", 13, 10, 0



; ****************************************************************************************
;
.Display_status     PUSH AF
                    CALL Disp_allocmem                 ; display amount of allocated memory
                    LD   HL, select_win2
                    CALL_OZ(Gn_sop)                    ; select window "2" for output
                    LD   HL, base1_flagmsg
                    LD   C,(IY + RTMflags)
                    CALL Disp_flags
                    LD   HL, base2_flagmsg
                    LD   C,(IY + RTMflags2)
                    CALL Disp_flags
                    POP  AF
                    RET

; *****************************************************************************************
;
.Disp_flags         XOR  A                             ; code = 0
                    LD   B,8                           ; parse 8 bits...
.disp_flag_loop     RR   C
                    CALL C,z80asm_flagmsg
                    INC  A
                    DJNZ disp_flag_loop
                    RET
.select_win2        DEFM 1, "2H2", 12, 0               ; select window "2"



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
;
; Create library file, specified from command line as -xfilename .
;
; HL points at first char of filename
;
.create_library     CALL GetFileName                   ; get library filename from command line
                    CALL CreateLibFile                 ; create library file
                    JR   C, cmdline_error              ; release memory and abort command line
                    LD   C,B
                    EX   DE,HL                         ; preserve library filename in CDE
                    LD   HL, libfilename
                    CALL AllocVarPointer
                    JP   C, ReportError_NULL
                    XOR  A                             ; BHL = pointer to pointer variable
                    CALL Set_pointer                   ; libfilename = CDE
                    SET  createlib,(IY + RTMflags)     ; indicate library to be created...
                    JP   parse_loop


; **************************************************************************************************
;
; Use library file during linking, specified from command line as -ifilename .
;
; HL points at first char of filename
;
.use_library        CALL GetFileName                   ; collect filename into buffer
                    LD   A,(DE)                        ; DE now points at start of filename
                    CP   0                             ; zero length means no filename specified.
                    CALL Z, default_libfile            ; use default filename.
                    CALL CreateLibFile
                    JR   C, cmdline_error              ; release memory and abort command line
                    PUSH BC
                    PUSH HL                            ; preserve pointer to library filename
                    INC  HL
                    LD   A,OP_IN
                    CALL Open_file                     ; open file to check for "Z80LMF" header
                    POP  HL
                    POP  BC
                    CALL C, ReportError_NULL
                    JP   C, cmdline_error              ; release memory and abort command line
                    PUSH BC
                    PUSH HL
                    LD   HL, libheader
                    CALL CheckFileHeader               ; check file to be a true library (with header)
                    PUSH AF
                    CALL_OZ(Gn_Cl)                     ; close library file
                    POP  AF
                    POP  HL
                    POP  BC                            ; {pointer to library filename}
                    JR   NZ, not_libfile               ; if ( checkfileheader() == 0 )
                         LD   C,B                           ; CHL points at library filename
                         PUSH HL
                         PUSH BC
                         CALL NewLibrary                    ; libfile = NewLibrary()
                         LD   A,B
                         POP  BC
                         LD   B,A                           ; BHL = library record
                         POP  DE                            ; CDE = library filename
                         JP   C, cmdline_error              ; release memory and abort command line
                         LD   A, libfile_filename
                         CALL Set_pointer                   ; libfile->filename = CDE
                         SET  library,(IY + RTMflags)       ; library = ON
                         CP   A
                         JP   parse_loop
                                                       ; else
.not_libfile        LD   A, ERR_not_libfile
                    LD   DE,0
                    CALL ReportError                        ; ReportError(libfilename, 0, ERR_not_libfile)
                    SCF
                    JP   cmdline_error

.libheader          DEFM "Z80LMF01"


; ******************************************************************************
;
;    Copy default library filename to cdebuffer, DE = pointer.
;
.default_libfile    PUSH DE
                    LD   HL, stdlibfile
                    LD   B,0
                    LD   C,(HL)
                    INC  BC
                    INC  BC                       ; copy filename & null-terminator...
                    LDIR
                    POP  DE
                    RET
.stdlibfile         DEFM 20, ":RAM.*//standard.lib", 0


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

                    BIT  applname,(IY + RtmFlags3)
                    CALL Z, z80asm_Applname            ; application ref. name of first module filename
                    CALL_OZ(Gn_Nln)                    ; {move a line feed in message window}
                    CP   A
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
;    IN:  HL = pointer to first char of filename in command line
;    OUT: DE = pointer to first char of collected filename in another buffer (length id)
;
;    Read filename into cdebuffer, length prefixed and null-terminated.
;
.GetFileName        LD   DE,cdebuffer
                    LD   BC, cdebuffer+1
                    XOR  A
                    LD   (DE),A
.fetchname_loop     CP   253                      ; max. length of name?
                    JR   Z, flnm_fetched
                    LD   A,(HL)
                    CP   0
                    JR   Z, flnm_fetched
                    CP   ' '
                    JR   Z, flnm_fetched
                    INC  HL
                    LD   (BC),A
                    INC  BC
                    EX   DE,HL
                    INC  (HL)                     ; update length of filename
                    LD   A,(HL)
                    EX   DE,HL
                    JR   fetchname_loop

.flnm_fetched       XOR  A
                    LD   (BC),A                   ; null-terminate filename
                    LD   (lineptr),HL             ; update variable
                    RET




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
                         BIT  datestamp,(IY + RTMflags)     if ( !datestamp )
                         JR   NZ, use_shortname
                              CALL ReportError_NULL              ; report open error if no date stamping...
                              SCF                                ; then return to caller
                              RET                           ; else
.use_shortname           LD   DE, cdebuffer                      ; file couldn't be opened, but use
                         CALL ModuleFileName                     ; non-extended file name
                         CP   A
                         RET                           ; else
.bad_filename       CALL ReportError_NULL                   ; report error
                    SCF
                    RET


; *********************************************************************************************
;
;    IN:  DE = local pointer to filename
;
.ModuleFileName     CALL CurrentFile                   ; BHL = NULL
                    CALL NewFile                       ; return pointer to file record in CDE
                    CALL CurrentModule
                    LD   A, module_cfile
                    CALL Set_pointer                   ; CURRENTMODULE->cfile = NewFile(NULL, textfile)
                    RET


; *********************************************************************************************
;
; Open modules file and create modules for each specified file name in modules file
;
.CreateModules      LD   B,0
                    LD   HL, cdebuffer+1                    ; point at first char of filename
                    LD   A, OP_IN
                    CALL Open_file
                    JP   C, ReportError_NULL
                         SET  applname,(IY + RtmFlags3)
                         EX   DE,HL
                         CALL NameApplication               ; Name application with projectfile

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



; ****************************************************************************************
;
; Use the current filename to name the z80asm application
;
.z80asm_ApplName    CALL CurrentFilename          ; current filename (of first module)
                    CALL NameApplication
                    RET


; ****************************************************************************************
;
;    Name z80asm application with filename pointed to by HL.
;
.NameApplication    LD   DE, Ident
                    PUSH DE
                    INC  HL                       ; point at first char of first module filename
                    XOR  A                        ; read filename segment of filename path string...
                    LD   B,-1                     ; look at filename segment...
                    CALL_OZ(Gn_Esa)               ; read filename at (HL)
                    POP  HL
                    CALL_OZ(Dc_Nam)               ; use filename to name 'z80asm' application
                    RET



; ****************************************************************************************
;
; Display message from code in A
;
.z80asm_flagmsg     PUSH AF
                    PUSH HL
                    RLCA                                  ; word boundary
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                            ; HL points at index containing pointer
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                           ; pointer fetched in
                    EX   DE,HL                            ; HL
                    CALL_OZ(Gn_Sop)                       ; display flag message
                    CALL_OZ(Gn_Nln)
                    POP  HL
                    POP  AF
                    RET

.base1_flagmsg      DEFW explorig_msg
                    DEFW uselib_msg
                    DEFW symfile_msg
                    DEFW link_msg
                    DEFW createlib_msg
                    DEFW mapfile_msg
                    DEFW deffile_msg
                    DEFW datecontrol_msg

.base2_flagmsg      DEFW autorel_msg
                    DEFW codesegm_msg
                    DEFW 0
                    DEFW 0
                    DEFW 0
                    DEFW 0
                    DEFw 0
                    DEFW 0

.explorig_msg       DEFM "Using explicit ORG", 0
.uselib_msg         DEFM "Link library modules", 0
.symfile_msg        DEFM "Create symbol file", 0
.link_msg           DEFM "Link/relocate modules", 0
.createlib_msg      DEFM "Create library file", 0
.mapfile_msg        DEFM "Create address map file", 0
.deffile_msg        DEFM "Create global def. file", 0
.datecontrol_msg    DEFM "Date stamp control", 0
.autorel_msg        DEFM "Create relocatable code", 0
.codesegm_msg       DEFM "Split code into 16K banks", 0

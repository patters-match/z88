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
; Copyright (C) Gunther Strube (gstrube@gmail.com), 1995-2017
;
; --------------------------------------------------------------------------------------------------------------------
; OZ Shell Z80 assember toolchain suite - "z80", compiles *.asm to *.obj
; --------------------------------------------------------------------------------------------------------------------
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

module Z80Cmd

include "stdio.def"
include "fileio.def"
include "syspar.def"
include "error.def"
include "time.def"
include "integer.def"

include "z80cmd.inc"                            ; zELF shell command definition and constants
INCLUDE "rtmvars.def"
include "cmdwspace.def"                         ; zELF shell command workspace variable references


org EXEC_ORG

LIB init_malloc, release_pools

xref initvars,initpointers, AsmSourceFiles
xref initfiles

; global variables - these declarations MUST be declared global static libraries

XDEF pool_index, pool_handles, MAX_POOLS
XDEF allocated_mem


; ******************************************************************************
; ELF Executable entry point for Shell commands
;
; In:
;       argc,argv[] stack frame
; Out:
;       -
;
; Registers changed on return:
;    ......../..IY same
;    AFBCDEHL/IX.. different
;
; Stack setup offsets for argc, argv[], IX is setup by Ls program to point at it:
;
;       [8,9]   argv[2] pointer
;       [6,7]   argv[1] pointer
;       [4,5]   argv[0] the program name
;       [2,3]   argc (16bit int)
; SP -> [0,1]   RETurn to ELF loader (and caller)
;
.entry
        push    iy                              ; preserve original IY
        ld      iy,Workspace                    ; let IY be base to access various flags easily

        ld      ix, 0
        add     ix, sp                          ; know base of command stack and arguments
        ld      (stackptr),ix

        ld      a, (ix+4)                       ; get argument count from Shell
        ld      (argc),a

        push    ix
        pop     hl
        ld      de,6
        add     hl,de                           ; point at argv[0] = "z80"
        call    getargvstr                      ; skip program name
        ld      (totalargc),a                   ; total command arguments without name
        ld      (argv0),hl                      ; remember index pointer to first argument
        jr      nz, get_1stargopt
        call    disp_usage                      ; no command line arguments specified, display usage.
        jr      exit_z80cmd

.get_1stargopt
        call    getargvstr                      ; get first argument, DE will point at options argument (if any), HL points at next argument index
        ld      a,(de)
        cp      '-'                             ; options specified?
        jr      nz, eval_arg                    ; no, its 1st argument
        call    parseoptions                    ; yes, parse option flags, define bit variables, adjust first argment pointer & count
        ld      a,(argc)
        or      a
        jr      nz,get_1starg                   ; there's arguments after options

        ; report error.

.get_1starg
        call    getargvstr                      ; get first argument (after options) in DE
.eval_arg

        ; ...
        call    initvars                        ; reset variables, pointers...
        call    init_malloc
        call    initpointers                    ; initialize memory allocation in segment 1.
        call    initfiles                       ; and clear file variables

        call    AsmSourceFiles

; ******************************************************************************
; command exit
;
.exit_z80cmd
        ld      sp,(stackptr)                   ; restore return SP, in case of RC_Quit
        pop     iy                              ; restore original IY
        ld      hl,0                            ; assume SH_OK to caller
        ret     nc
        inc     hl                              ; return SH_ERR to caller, for script-level post-processing
        ret                                     ; return Fc = 1, A = RC_xxx error
.err_z80cmd
        oz      Gn_Esp                          ; report RC error to Shell window, then exit command
        oz      OS_Bout
        oz      OS_Nln
        jr      exit_z80cmd


; ******************************************************************************
; Get argument string pointer via current argv index
;
; IN
;       HL = current pointer to array index item (every item is a 16bit pointer)
; OUT
;       DE = pointer to string of item
;       HL = points at next argument index item, also preserved in (argv)
;       A = (argc) = remaining argument counter, Fz = 1, if last argument were fetched
;
.getargvstr
        ld      de,argc
        ex      de,hl
        dec     (hl)
        ld      a,(hl)                          ; A = remaining argument counter, Fz = 1 if 0 reached
        ex      de,hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (argv),hl
        ret


; ******************************************************************************
; Parse one or more specified options
;
; IN
;       DE points to start of command line argument, the '-' character
;       HL points at next argument index
; OUT
;       options flags set (see z80cmd.inc)
;
.parseoptions
        push    af
        push    de
        inc     de                              ; point at first option identifier
.flag_loop
        ld      a,(de)
        inc     de
        or      a
        jr      z,flags_parsed
        call    valoption                       ; check option character (and set flags accordingly)
        jr      flag_loop
.flags_parsed
        pop     de

        ld      (argv0),hl                      ; adjust first real file argument after options
        ld      a,(argc)
        ld      (totalargc),a                   ; now, total arguments only contains file arguments
        pop     af
        ret
.valoption
        cp      ' '
        jr      z, flag_loop
        cp      'd'
        jr      z, setopt_datestmp              ; datestamp compilation

; more options here...

; ******************************************************************************
; An unknown option were specified, report and exit z80cmd command
        call    err_Hdr
        oz      OS_Pout
        defm    "Unknown option",CR,LF,0
.disp_usage
        oz      OS_Pout
        defm    "usage: z80 ",1,"2+T[-dsg] [-Dsymbol] {file.asm ...} | @project",1,"2-T",CR,LF,0
        cp      a
        jp      exit_z80cmd

.setopt_datestmp
        set     opt_datestamp,(iy + options)    ; -d
        ret


; ******************************************************************************
; Before any error message, report "z80: " to console
.err_Hdr
        oz      OS_Pout
        defm    "z80: ",0
        ret

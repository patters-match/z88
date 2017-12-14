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

     XREF InitVars, InitFiles, InitPointers                 ; initvars.asm
     XREF Command_line                                      ; cmdline.asm
     XREF AsmSourceFiles,empty_msg                          ; asmsrcfiles.asm
     XREF LinkModules                                       ; linkmod.asm
     XREF ReportError, ReportError_NULL, ReportError_STD    ; ASMERROR.asm

     XREF z80asm_errmsg, Get_stdoutp_handle                 ; stderror.asm
     XREF Write_stdmessage                                  ;

     XREF z80asm_windows                                    ; windows.asm
     XREF Get_time, Display_asmtime                         ; comptime.asm
     XREF Disp_allocmem                                     ; dispmem.asm
     XREF SplitCodefile                                     ; spltfile.asm

     XREF z80asm_ERH                                        ; ehandler.asm
     XREF WriteMapFile                                      ; mapfile.asm
     XREF MakeLibrary                                       ; makelib.asm
     XREF Close_files                                       ; fileIO.asm
     XREF Delete_bufferfiles                                ; fileIO.asm
     XREF DeleteRelocTblFile                                ; reloc.asm
     XREF Display_integer                                   ; dispint.asm

; global variables - these declarations MUST be declared global:
; ( "defs_h" defines their address constants )

     XDEF pool_index, pool_handles, MAX_POOLS
     XDEF allocated_mem

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "integer.def"
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
                    CALL Disp_totallines               ; disptotallines()
                    CALL Disp_allocmem
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

                    BIT  autorelocate, (IY + RTMflags2)
                    jr   z,cont_completed
                    CALL DeleteRelocTblFile
.cont_completed
                    CALL Disp_allocmem                 ; first display amount of RTM memory
                    CALL Release_pools                 ; then free RTM memory
                    CALL DisplayErrors                 ; display error status, if necessary...
                    JR   z80asm_loop

; *****************************************************************************************
;
.DisplayErrors      LD   A,(TOTALERRORS)
                    OR   A
                    JP   Z, Display_AsmTime            ; display time used to assemble file (if no errors)
                    LD   A, ERR_totalerrors
                    CALL ReportError_NULL
                    JP   Wait_key


; ****************************************************************************************
.Disp_totallines    LD   HL, totalline_msg
                    CALL_OZ(Gn_Sop)
                    LD   BC,(totallines)
                    CALL Display_integer
                    LD   HL, empty_msg
                    CALL_OZ(Gn_Sop)
                    RET
.totalline_msg      DEFM 1, "2H5Assembled lines: ", 0


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

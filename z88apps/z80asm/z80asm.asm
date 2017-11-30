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
     LIB Read_word, Set_word
     LIB GetVarPointer, AllocVarPointer

     XREF Command_line                                      ; cmdline.asm
     XREF AsmSourceFiles                                    ; asmsrcfiles.asm
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

; global variables - these declarations MUST be declared global:
; ( "defs_h" defines their address constants )

     XDEF pool_index, pool_handles, MAX_POOLS
     XDEF allocated_mem

; global procedures:
     XDEF Keyboard_interrupt

     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
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
                    LD   HL, break_msg
                    CALL_OZ(Gn_Sop)                    ; "Use []ESC to abort assembly or linking"

                    CALL AsmSourceFiles                ; AsmSourceFiles()
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
                    CALL Disp_allocmem                 ; first display amount of RTM memory
                    CALL Release_pools                 ; then free RTM memory
                    CALL DisplayErrors                 ; display error status, if necessary...
                    JR   z80asm_loop


; *****************************************************************************
;
; Read the keyboard and check if <SQUARE><ESC> is pressed.
; If pressed (the binary pattern in register A is 0 at the keys pressed down),
; the current compiling process instructions is stopped and the command
; line is re-entered.
;
; Register status after return:
;
;       ..BCDEHL/IXIYPC  same
;       AF....../......  different
;
; Fz = 1, when abort keys pressed, otherwise Fz = 0.
;
.Keyboard_interrupt PUSH BC
                    LD   BC,$7FB2                 ; port $B2, keyboard row A15
                    IN   A,(C)                    ; scan A15...
                    POP  BC
                    AND  @01100000                ; <SQU><ESC> pressed?
                    RET  NZ                       ; no, continue assembler processing

                    PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX
                    SET  abort,(IY + RtmFlags3)
                    SET  ASMERROR,(IY + RtmFlags3)
                    LD   A, ERR_keyboard_abort
                    CALL z80asm_errmsg            ; HL points to error message
                    CALL Get_stdoutp_handle       ; IX contains handle to std. output
                    CALL Write_stdmessage         ; display "Assembly aborted from keyboard"
                    CALL_OZ(Gn_Nln)
                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    CP   A                        ; signal keyboard abortion!
                    RET


; *****************************************************************************************
;
.DisplayErrors      LD   A,(TOTALERRORS)
                    CP   0
                    JP   Z, Display_AsmTime       ; display time used to assemble file (if no errors)
                    LD   A, ERR_totalerrors
                    CALL ReportError_NULL
                    CALL Wait_key
                    RET


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


; ****************************************************************************************
;
; Setup IY register to base of variables and preset runtime flags.
;
.InitVars           LD   HL, z80asm_vars
                    PUSH HL
                    POP  IY                            ; IY points at base of variable
                    LD   (HL), 2**datestamp | 2**mapref | 2**z80bin | 2**symtable
                               ; datestamp, map file,   linking,   symbol file
                    INC  HL
                    LD   (HL), @00000000               ; reset RTMflags2
                    INC  HL
                    LD   (HL), @00000000               ; reset RTMflags3
                    RET


; ****************************************************************************************
;
;    Reset Area for filename pointers and handles
;
.InitFiles          LD   BC, end_file_area - file_area
                    LD   HL, objfilename
.clear_handles      LD   (HL),0
                    INC  HL
                    DEC  BC
                    LD   A,B
                    OR   C
                    JR   NZ, clear_handles
                    RET


; ****************************************************************************************
;
.InitPointers       LD   HL, modulehdr                 ; allocate room for 'modulehdr' variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, libraryhdr                ; allocate room for 'libraryhdr' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, linkhdr                   ; allocate room for 'linkhdr' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, CURMODULE                 ; allocate room for 'CURMODULE' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, CURLIBRARY                ; allocate room for 'CURLIBRARY' variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, LASTMODULE                ; allocate room for 'LASTMODULE' variable
                    CALL AllocVarPointer
                    RET  C
                    LD   HL, globalroot                ; allocate room for 'globalroot' pointer variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    LD   HL, staticroot                ; allocate room for 'staticroot' pointer variable
                    CALL AllocVarPointer
                    LD   HL, asm_pc_ptr                ; allocate room for 'asm_pc_ptr' pointer variable
                    CALL AllocVarPointer
                    RET  C                             ; Ups - no room...
                    RET


.break_msg          DEFM 1, "2H5Use ", 1, "B", 1, SD_SQUA, 1, "B ", 1, SD_ESC
                    DEFM " to abort assembly or linking.", 13, 10, 0


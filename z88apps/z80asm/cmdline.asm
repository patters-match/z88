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
     LIB Bind_bank_s1, GetVarPointer
     LIB IsAlpha

     XREF Disp_allocmem                                     ; z80asm.asm

     XREF ReleaseModules                                    ; module.asm
     XREF CurrentFile, CurrentFileName                      ; currfile.asm
     XREF z80asm_ERH                                        ; ehandler.asm
     XREF Parse_cmdline                                     ; prscmdline.asm

     XREF GetConstant                                       ; getconst.asm



     XDEF Command_line
     XDEF Display_status
     XDEF z80asm_ApplName, NameApplication


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

                    LD   HL, modulehdr
                    CALL GetVarPointer
                    XOR  A
                    CP   B
                    JR   Z, exit_Disp_Status           ; if ( modulehdr != NULL )
                    BIT  applname,(IY + RtmFlags3)
                    CALL Z, z80asm_Applname                 ; application ref. name of first module filename
.exit_Disp_Status
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

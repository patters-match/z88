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

     MODULE z80asm_windows

     LIB CreateWindow

     INCLUDE "stdio.def"
     INCLUDE "rtmvars.def"

     XDEF z80asm_windows

; ***********************************************************************
;
.z80asm_Windows     CALL DisplayLogo

                    LD   A, 64 | '2'
                    LD   BC, $0000
                    LD   DE, $0819
                    CALL CreateWindow
                    LD   A, 128 | 64 | '3'
                    LD   BC, $001A
                    LD   DE, $0517
                    LD   HL, command_banner
                    CALL CreateWindow
                    LD   A, 128 | 64 | '4'
                    LD   BC, $051A
                    LD   DE, $0317
                    LD   HL, memory_banner
                    CALL CreateWindow
                    LD   A, 128 | '5'
                    LD   BC, $0033
                    LD   DE, $0829
                    LD   HL, message_banner
                    CALL CreateWindow
                    LD   HL, copyright_msg
                    CALL_OZ(Gn_Sop)
                    RET

; ***********************************************************************
;
.DISPLAYLOGO        LD   HL, WINDOW
                    CALL_OZ(GN_SOP)

                    LD   DE, 8*94
                    LD   B, 1
                    LD   HL, LOGO
.LOGOLOOP           LD   A,(HL)
                    CALL_OZ(OS_OUT)
                    CALL NEXTCHAR
                    DEC  DE
                    LD   A,D
                    OR   E
                    JR   NZ, LOGOLOOP
                    RET

.NEXTCHAR           INC  HL
                    INC  B
                    LD   A,7
                    CP   B
                    RET  NZ
                    LD   B,1
                    LD   HL, LOGO
                    RET

.command_banner     DEFM "Command Line", 0
.memory_banner      DEFM "Runtime Memory Usage", 0
.message_banner     DEFM "Messages", 0

.copyright_msg      DEFM "Z80 Module Assembler V1.0.4B", 13, 10
                    DEFM "(c) Gunther Strube 1995-2017", 13, 10, 0

.window             defm 1, "7#1", 32, 32, 32+94, 32+8, 128
                    defm 1, "2C1", 0
.logo               defm "Z80asm"

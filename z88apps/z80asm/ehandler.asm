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

     MODULE Error_handler

     LIB Release_pools

     XREF z80asm_windows, Display_status                    ; windows.asm

     XREF Close_files                                       ; asmsrcfiles.asm
     XREF Delete_bufferfiles                                ;

     XDEF z80asm_ERH

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"
     INCLUDE "error.def"
     INCLUDE "director.def"


; ******************************************************************************************
;
; z80asm error handler
;
.z80asm_ERH         CP   RC_SUSP
                    RET  Z
                    CP   RC_DRAW                        ; application screen corrupted
                    JR   Z,corrupt_scr
                    CP   RC_QUIT
                    JR   Z,z80asm_suicide
                    CP   RC_ESC
                    JR   Z, ackn_esc
                    JR   return_ERH

.corrupt_scr        PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX
                    CALL z80asm_windows                 ; redraw screen before suspension
                    CALL Display_status
                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    LD   A,-1
                    JR   return_ERH

.ackn_esc           CALL_OZ(Os_Esc)                     ; acknowledge ESC key
                    LD   A, $1B                         ; ESC were pressed
.return_ERH         OR   A                              ; Fc = 0, Fz = 0
                    RET

.z80asm_suicide     CALL Close_files                    ; close any open files...
                    CALL Delete_bufferfiles
                    CALL Release_pools                  ; free any open memory pools back to OZ...
                    XOR  A
                    CALL_OZ(Os_Bye)                     ; kill Zprom and return to Index

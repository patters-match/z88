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

     MODULE Display_Sourcefilename

     XDEF Display_filename

     INCLUDE "rtmvars.def"
     INCLUDE "stdio.def"
     INCLUDE "fileio.def"



; **************************************************************************************************
;
; IN: BHL = pointer to filename (B=0 means local pointer)
;
.Display_filename   PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   DE, stringconst          ; compress filename to max. 40 characters
                    LD   C,40                     ; which is copied into stringconst
                    CALL_OZ(Gn_Fcm)
                    LD   HL, select_win5
                    CALL_OZ(Gn_Sop)               ; {select window "5"}
                    LD   HL, stringconst
                    CALL_OZ(Gn_Sop)               ; display compressed filename to window "5"
                    CALL_OZ(Gn_Nln)               ; terminated with <newline>

                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET
.select_win5        DEFM 1, "2H5",  0             ; select window "5"

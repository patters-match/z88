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

Module DisplayInteger

INCLUDE "stdio.def"
INCLUDE "integer.def"

XDEF Display_integer

; ******************************************************************************
;
;    Display integer (current line number, etc.) to window "5"
;    Each line number is terminated by a CR to move the cursor back to the
;    start of the current line.
;
;    IN:  BC = number to display
;    OUT: None.
;
;    Registers changed after return:
;         ....DEHL/IXIY  same
;         AFBC..../....  different
;
.Display_integer    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   IX,-10
                    ADD  IX,SP
                    LD   SP,IX                    ; make 10 byte buffer on stack
                    LD   HL,2                     ; BC contains integer...
                    PUSH IX
                    POP  DE                       ; write ASCII string to buffer
                    LD   A,@01010101              ; 5 character wide number, no leading spaces, use trailing spaces...
                    CALL_OZ(Gn_Pdn)               ; convert
                    LD   A, CR
                    LD   (DE),A                   ; trailing CR (cursor to start of line)
                    INC  DE
                    XOR  A
                    LD   (DE),A                   ; then null-terminate string.

                    LD   HL, select_win5
                    CALL_OZ(Gn_Sop)               ; select message window
                    PUSH IX
                    POP  HL
                    CALL_OZ(Gn_Sop)               ; and display number.

                    LD   HL,10
                    ADD  HL,SP
                    LD   SP,HL                    ; restore SP

                    POP  IX
                    POP  HL
                    POP  DE                       ; original registers restored.
                    RET
.select_win5        DEFM 1, "2H5", 0              ; select window "5"

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
; $Id$
;
; ********************************************************************************************************************

     MODULE Disp_allocmem


     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"
     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "integer.def"


     XDEF Disp_allocmem


; *********************************************************************************************
;
;    Display the amount of memory currently allocated in OZ memory by .malloc
;
;    Registers changed after return
;         AFBCDEHL/IXIY  same
;         ......../....  different
;
.Disp_allocmem      PUSH IX
                    PUSH HL
                    PUSH DE
                    PUSH BC
                    PUSH AF
                    LD   HL, select_win4
                    CALL_OZ(Gn_sop)                         ; display information in window "4"

                    LD   HL, allocated_mem
                    CALL DisplayInteger

                    LD   A,32
                    CALL_OZ(Os_Out)
                    LD   A,'('
                    CALL_OZ(Os_Out)
                    LD   A, FA_EXT
                    LD   DE,0
                    LD   IX, -1
                    CALL_OZ(Os_Frm)                         ; get estimated free memory information
                    LD   (longint),BC
                    LD   (longint+2),DE
                    LD   HL, longint
                    CALL DisplayInteger
                    LD   A,')'
                    CALL_OZ(Os_out)

                    LD   HL, bytes_msg
                    CALL_OZ(Gn_sop)

                    POP  AF
                    POP  BC
                    POP  DE
                    POP  HL
                    POP  IX
                    RET
.select_win4        DEFM 1, "2H4", 12, 0                 ; select window "4" and clear window
.bytes_msg          DEFM " bytes", 0


; *********************************************************************************************
;
;    IN: HL = local pointer to integer 32bit integer
;
.DisplayInteger     LD   DE, Ident                          ; write ASCII representation to (Ident)
                    LD   A,1
                    CALL_OZ(Gn_Pdn)
                    XOR  A
                    LD   (DE),A
                    LD   HL, Ident
                    CALL_OZ(Gn_Sop)                         ; write ASCII integer to standard output
                    RET

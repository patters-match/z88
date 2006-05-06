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

     MODULE  z80asm_time

     INCLUDE "stdio.def"
     INCLUDE "time.def"
     INCLUDE "syspar.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"

     XDEF Get_time, Display_asmtime


; ***********************************************************************
;
.Get_time           LD   C,0
                    LD   DE,0
                    CALL_OZ(GN_Gmt)                    ; current internal machine time
                    LD   (asmtime),BC
                    LD   (asmtime+2),A                 ; current machine time
                    RET                                ; in ABC


; ***********************************************************************
;
.Display_asmtime    PUSH AF
                    LD   C,0
                    LD   DE,0
                    CALL_OZ(GN_Gmt)                    ; current internal machine time
                    LD   H,B
                    LD   L,C
                    LD   BC,(asmtime)
                    SBC  HL,BC
                    LD   D,A
                    LD   A,(asmtime+2)                 ; elapsed time = current - previous
                    LD   E,A
                    LD   A,D
                    SBC  A,E
                    LD   (asmtime),HL
                    LD   (asmtime+2),A                 ; AHL = elapsed time in centiseconds

                    LD   BC, NQ_OHN
                    CALL_OZ(Os_Nq)                     ; get handle in IX for standard output

                    LD   HL, select_win5
                    CALL_OZ(Gn_sop)
                    LD   HL, time1_msg
                    CALL_OZ(Gn_Sop)                    ; "Compiled in '
                    LD   DE,0                          ; write time to #5 window...
                    LD   HL, asmtime                   ; pointer to internal time
                    LD   A, @00110111                  ; time display format
                    CALL_OZ(Gn_Ptm)                    ; display elapsed time...
                    LD   HL, time2_msg
                    CALL_OZ(Gn_Sop)
                    CALL_OZ(Gn_Nln)
                    POP  AF
                    RET
.time1_msg          DEFM "Compiled in", 0
.time2_msg          DEFM "minutes", 0
.select_win5        DEFM 1, "2H5",  0                ; select window "5"

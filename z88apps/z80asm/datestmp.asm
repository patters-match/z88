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

     MODULE Datestamp_check


     INCLUDE "fileio.def"
     INCLUDE "dor.def"
     INCLUDE "fpp.def"

     INCLUDE "rtmvars.def"

     XREF Open_file                          ; fileio.asm

     XDEF GetFileStamp, CheckDateStamps


; *****************************************************************************************
;
;    IN:  DE   = local pointer to write creation date stamp
;         BHL  = pointer to file name
;
;    OUT: (DE) contains date stamp file information
;
.GetFileStamp       LD   A, OP_DOR
                    PUSH DE
                    CALL Open_file                     ; open source file of current module
                    POP  DE
                    RET  C
                    LD   A, DR_Rd
                    LD   B, Dt_Cre
                    LD   C, 6                          ; Read Creation Date at (DE)
                    CALL_OZ(Os_Dor)
                    LD   A, Dr_Fre
                    CALL_OZ(OS_Dor)
                    RET



; *****************************************************************************************
;
; IN:     (datestamp_src) & (datestamp_obj)
;
; OUT:    Fz = 1, if source file < object file
;         Fz = 0, if source file > object file
;
.CheckDateStamps    EXX
                    LD   HL,(datestamp_src+3)          ; low word of source file date
                    PUSH HL
                    LD   DE,(datestamp_obj+3)          ; low word of object file date
                    PUSH DE
                    EXX
                    LD   A,(datestamp_src+3+2)
                    LD   H,0
                    LD   L,A                           ; high word of source file date
                    PUSH HL
                    LD   A,(datestamp_src+3+2)
                    LD   D,H
                    LD   E,A                           ; high word of object file date
                    PUSH DE
                    LD   B,H
                    LD   C,H                           ; integers...
                    FPP  (FP_EQ)                       ; if ( src.date == obj.date )
                    XOR  A
                    CP   H
                    POP  DE
                    POP  HL
                    EXX
                    POP  DE
                    POP  HL
                    EXX
                    JR   Z, compare_dates                   ; return (src.date < obj.date)
.check_time              EXX                           ; else
                         LD   HL,(datestamp_src)            ; low word of source file time
                         LD   DE,(datestamp_obj)            ; low word of object file time
                         EXX
                         LD   A,(datestamp_src+2)
                         LD   H,0
                         LD   L,A                           ; high word of source file time
                         LD   A,(datestamp_obj+2)
                         LD   D,H
                         LD   E,A                           ; high word of object file time

.compare_dates      FPP  (FP_GEQ)
                    XOR  A
                    CP   H                             ; Fz = 1, if src < obj
                    RET

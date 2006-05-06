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

     MODULE Test_range

     XDEF Test_7bit_range, Test_8bit_range
     XDEF Test_16bit_range, Test_32bit_range


     INCLUDE "fpp.def"


; ========================================================================================
;
; Test whether <const> is in range [-128; 127]
;
; IN: HLhlC = const (32bit integer)
;
; OUT: Fc = 0, <const> within range
;      Fc = 1, <const> out of range
;
; Registers changed on return:
;
;    ..BCDEHL/IXIY/......hl
;    AF....../..../afbcde..
;
.Test_7bit_range    PUSH BC
                    PUSH DE
                    LD   B,0
                    LD   DE,-1
                    EXX
                    LD   DE,-128
                    PUSH HL
                    EXX                                     ; -128
                    PUSH HL                                 ; {preserve const}
                    FPP  (FP_GEQ)                           ;
                    LD   A,H
                    POP  HL
                    EXX
                    POP  HL
                    EXX
                    CP   0                                  ; if ( const < -128 )
                    JR   Z, range_7bit_err                     ; reporterror(7)
                         LD   DE,0                          ; else
                         PUSH HL
                         EXX
                         LD   DE,127
                         PUSH HL
                         EXX
                         FPP  (FP_LEQ)
                         LD   A,H
                         EXX
                         POP  HL
                         EXX
                         POP  HL
                         CP   0                                  ; if ( const > 127 )
                         JR   Z, range_7bit_err                       ; reporterror(7)
                              CP   A
                              POP  DE
                              POP  BC
                              RET
.range_7bit_err     SCF
                    POP  DE
                    POP  BC
                    RET



; ========================================================================================
;
; Test whether <const> is in range [-128; 255]
;
; IN: HLhlC = const (32bit integer)
;
; OUT: Fc = 0, <const> within range
;      Fc = 1, <const> out of range
;
; Registers changed on return:
;
;    ..BCDEHL/IXIY/......hl
;    AF....../..../afbcde..
;
.Test_8bit_range    PUSH BC
                    PUSH DE
                    LD   B,0
                    LD   DE,-1
                    EXX
                    LD   DE,-128
                    PUSH HL
                    EXX                                     ; -128
                    PUSH HL                                 ; {preserve const}
                    FPP  (FP_GEQ)                           ;
                    LD   A,H
                    POP  HL
                    EXX
                    POP  HL
                    EXX
                    CP   0                                  ; if ( const < 0 )
                    JR   Z, range_8bit_err                       ; error...
                         LD   DE,0                          ; else
                         PUSH HL
                         EXX
                         LD   DE,255
                         PUSH HL
                         EXX
                         FPP  (FP_LEQ)
                         LD   A,H
                         EXX
                         POP  HL
                         EXX
                         POP  HL
                         CP   0                                  ; if ( const > 255 )
                         JR   Z, range_8bit_err                       ; error...
                              CP   A
                              POP  DE
                              POP  BC
                              RET
.range_8bit_err     SCF
                    POP  DE
                    POP  BC
                    RET


; ========================================================================================
;
; Test whether <const> is in range [-32768; 65535]
;
; IN: HLhlC = const (32bit integer)
;
; OUT: Fc = 0, <const> within range
;      Fc = 1, <const> out of range
;
; Registers changed on return:
;
;    ..BCDEHL/IXIY/......hl
;    AF....../..../afbcde..
;
.Test_16bit_range   PUSH BC
                    PUSH DE
                    LD   B,0
                    LD   DE,-1
                    EXX
                    LD   DE,-32768
                    PUSH HL
                    EXX                                     ; -32768
                    PUSH HL                                 ; {preserve const}
                    FPP  (FP_GEQ)                           ;
                    LD   A,H
                    POP  HL
                    EXX
                    POP  HL
                    EXX
                    CP   0                                  ; if ( const < 0 )
                    JR   Z, range_16bit_err                       ; error...
                         LD   DE,0                          ; else
                         PUSH HL
                         EXX
                         LD   DE,$FFFF
                         PUSH HL
                         EXX
                         FPP  (FP_LEQ)
                         LD   A,H
                         EXX
                         POP  HL
                         EXX
                         POP  HL
                         CP   0                                  ; if ( const > 65535 )
                         JR   Z, range_16bit_err                       ; error...
                              CP   A
                              POP  DE
                              POP  BC
                              RET
.range_16bit_err    SCF
                    POP  DE
                    POP  BC
                    RET



; ========================================================================================
;
; Test whether <const> is in range [-2147483648; 2147483647]
;
; IN: HLhlC = const (32bit integer)
;
; OUT: Fc = 0, <const> within range
;      Fc = 1, <const> out of range
;
; Registers changed on return:
;
;    ..BCDEHL/IXIY/......hl
;    AF....../..../afbcde..
;
.Test_32bit_range   PUSH BC
                    PUSH DE
                    LD   B,0
                    LD   DE,$8000
                    EXX
                    LD   DE,0
                    PUSH HL
                    EXX                                     ; 0
                    PUSH HL                                 ; {preserve const}
                    FPP  (FP_GEQ)                           ;
                    LD   A,H
                    POP  HL
                    EXX
                    POP  HL
                    EXX
                    CP   0                                  ; if ( const < -2147483648 )
                    JR   Z, range_32bit_err                       ; error...
                         LD   DE,$7FFF                      ; else
                         PUSH HL
                         EXX
                         LD   DE,$FFFF
                         PUSH HL
                         EXX
                         FPP  (FP_LEQ)
                         LD   A,H
                         EXX
                         POP  HL
                         EXX
                         POP  HL
                         CP   0                                  ; if ( const > 2148483647 )
                         JR   Z, range_16bit_err                       ; error...
                              CP   A
                              POP  DE
                              POP  BC
                              RET
.range_32bit_err    SCF
                    POP  DE
                    POP  BC
                    RET

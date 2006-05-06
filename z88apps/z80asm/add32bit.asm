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

     MODULE Fast_32bit_addition

     XDEF Add32bit

; ******************************************************************************
;
;    Unsigned 32bit addition
;
;    IN:  HL = pointer to unsigned 32bit integer (low byte - high byte order)
;         DEBC = 32bit integer to be added with (HL)
;
;    OUT: HL = pointer to result ( same as HL(in) )
;    NB:  Overflow is not reported
;
;    Registers changed after return:
;         ..BCDEHL/IXIY  same
;         AF....../....  different
;
.Add32bit           PUSH IX
                    PUSH HL
                    POP  IX                  ; IX points at 32bit integer
                    LD   L,(IX+0)
                    LD   H,(IX+1)
                    ADD  HL,BC
                    LD   (IX+0),L
                    LD   (IX+1),H
                    LD   L,(IX+2)
                    LD   H,(IX+3)
                    ADC  HL,DE
                    LD   (IX+2),L
                    LD   (IX+3),H
.exit_add32bit      PUSH IX
                    POP  HL                  ; HL points at 32bit result
                    POP  IX                  ; restore original IX
                    RET

     XLIB IntHex

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
;
;***************************************************************************************************

     LIB Bind_bank_s1


; **************************************************************************************************
;
; Convert 8bit - 32bit integers to ASCII Hexadecimal
;
;    IN:  BHL  =    pointer to integer (B=0 means local pointer)
;         DE   =    local pointer to write ASCII hex string
;         C    =    size of integer in bytes (e.g. 4 for long word)
;         NB:       all integers in Z80 are stored in <low byte><high byte> order
;
;    OUT: DE   =    pointer to HEX ASCII string
;
;    Registers changed after return
;         ..BCDEHL/IXIY  same
;         AF....../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.IntHex             LD   A,B
                    CP   0
                    JR   Z, convert_integer
                    CALL Bind_bank_s1
                    PUSH AF
                    PUSH HL
                    RES  7,H
                    SET  6,H                      ; force pointer in segment 1
                    CALL Convert_Integer
                    POP  HL
                    POP  AF
                    CALL Bind_bank_s1
                    RET


; ****************************************************************************
;
; INTEGER to HEX conversion
;
; Returns ASCII string of HEX number at (DE) and null-terminates the string.
;
; Register status after return:
;
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.Convert_Integer    PUSH BC
                    PUSH HL
                    PUSH DE
                    LD   B,0
                    DEC  C
                    ADD  HL,BC                    ; point at high byte of integer
                    INC  C
                    LD   B,C                      ; B is loop counter
.convert_loop       PUSH BC
                    LD   A,(HL)
                    DEC  HL
                    CALL CalcHexByte
                    EX   DE,HL
                    LD   (HL),B
                    INC  HL
                    LD   (HL),C                   ; write Hex ASCII at (DE)
                    INC  HL
                    EX   DE,HL
                    POP  BC
                    DJNZ convert_loop
                    XOR  A
                    LD   (DE),A                   ; null-terminate string
                    POP  DE                       ; return pointer to start of string
                    POP  HL
                    POP  BC
                    RET


; ****************************************************************************
; byte in A, will be returned in ASCII form in BC
.CalcHexByte        PUSH HL
                    LD   H,A                  ; copy of A
                    SRL  A
                    SRL  A
                    SRL  A
                    SRL  A                    ; high nibble
                    CALL CalcHexNibble
                    LD   B,A
                    LD   A,H
                    AND  @00001111            ; low nibble
                    CALL CalcHexNibble
                    LD   C,A
                    POP  HL
                    RET


; ******************************************************************
; A(in) = 4 bit integer value, A(out) = ASCII HEX byte
.CalcHexNibble      PUSH HL
                    PUSH BC
                    LD   HL, HexSymbols
                    LD   B,0
                    LD   C,A
                    ADD  HL,BC
                    LD   A,(HL)
                    POP  BC
                    POP  HL
                    RET
.HexSymbols         DEFM "0123456789ABCDEF"

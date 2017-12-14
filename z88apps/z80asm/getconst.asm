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

     MODULE GetConstant

     LIB ToUpper
     XDEF GetConstant

     INCLUDE "fpp.def"
     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ******************************************************************************
;
; GetConstant - parse the current line for a constant (decimal, hex or binary)
;               and return a signed long integer.
;
;  IN:    None.
; OUT:    debc = long integer representation of parsed ASCII constant
;         Fc = 0, if integer collected, otherwise Fc = 1 (syntax error)
;
; Registers changed after return:
;
;    ......../IXIY  ........ same
;    AFBCDEHL/....  afbcdehl different
;
.GetConstant        LD   HL,ident
                    LD   A,(sym)
                    CP   sym_hexconst
                    JR   Z, eval_hexconstant
                    CP   sym_binconst
                    JR   Z, eval_binconstant
                    CP   sym_decmconst
                    JR   Z, eval_decmconstant
                    SCF
                    RET                           ; not a constant...

.eval_binconstant   LD   A,(HL)                   ; get length of identifier
                    INC  HL
                    INC  HL                       ; point at first binary digit
                    DEC  A                        ; binary digits minus binary id '@'
                    OR   A
                    JR   Z, illegal_constant
                    CP   9                        ; max 8bit binary number
                    JR   NC, illegal_constant
                    LD   B,A
                    LD   C,0                      ; B = bitcounter, C = bitcollector
.bitcollect_loop    RLC  C
                    LD   A,(HL)                   ; get ASCII bit
                    INC  HL
                    CP   '0'
                    JR   Z, get_next_bit
                    CP   '1'
                    JR   NZ, illegal_constant
                    SET  0,C
.get_next_bit       DJNZ bitcollect_loop
                    PUSH BC                       ; all bits collected & converted in C
                    EXX
                    LD   DE,0                     ; most significant word of long
                    POP  BC                       ; least significant word of long
                    EXX
                    CP   A                        ; NB: bit constant always unsigned
                    RET

.eval_hexconstant   LD   A,(HL)                   ; get length of identifier
                    INC  HL
                    DEC  A
                    OR   A
                    JR   Z, illegal_constant
                    CP   9
                    JR   NC, illegal_constant     ; max 8 hex digits (signed long)
                    LD   B,0
                    LD   C,A
                    ADD  HL,BC                    ; point at least significat nibble
                    LD   DE,longint               ; point at space for long integer
                    LD   C,0
                    LD   (longint),BC             ; clear long buffer (low word)
                    LD   (longint+2),BC           ; clear long buffer (high word)
                    LD   B,A                      ; number of hex nibbles to process
.readhexbyte_loop   LD   A,(HL)
                    DEC  HL
                    CALL ConvHexNibble            ; convert towards most significant byte
                    RET  C                        ; illegal hex byte encountered
                    LD   (DE),A                   ; lower nibble of byte processed
                    DEC  B
                    JR   Z, nibbles_parsed
                    LD   C,A
                    LD   A,(HL)
                    DEC  HL
                    CALL ConvHexNibble
                    RET  C
                    SLA  A                        ; upper half of nibble processed
                    SLA  A
                    SLA  A
                    SLA  A                        ; into bit 7 - 4.
                    OR   C                        ; merge the two nibbles
                    LD   (DE),A                   ; store converted integer byte
                    INC  DE
                    DJNZ readhexbyte_loop         ; continue until all hexnibbles read
.nibbles_parsed     EXX
                    LD   DE,(longint+2)           ; high word of hex constant
                    LD   BC,(longint)             ; low word of hex constant
                    EXX
                    CP   A                        ; Fz = 1, successfully converted
                    RET                           ; return hex constant in debc

.eval_decmconstant  INC  HL                       ; point at first char in identifier
                    FPP  (Fp_Val)                 ; get value of ASCII constant
                    RET  C                        ; Fz = 0, Fc = 1 - syntax error
                    PUSH HL
                    EXX
                    POP  DE
                    LD   B,H
                    LD   C,L
                    EXX
                    XOR  A
                    CP   C                        ; only integer format allowed
                    RET

.illegal_constant   SCF                           ; Fc = 1, syntax error
                    RET


; ********************************************************************************
;
.ConvHexNibble      CP   'A'
                    JR   NC,hex_alpha        ; digit >= "A"
                    CP   '0'
                    RET  C                   ; digit < "0"
                    CP   ':'
                    CCF
                    RET  C                   ; digit > "9"
                    SUB  48                  ; digit = ["0"; "9"]
                    RET
.hex_alpha          CP   'G'
                    CCF
                    RET  C                   ; digit > "F"
                    SUB  55                  ; digit = ["A"; "F"]
                    RET

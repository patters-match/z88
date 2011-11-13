; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
;***************************************************************************************************

    MODULE RegisterNumberIO


    XREF Write_CRLF, Display_Char, Display_String
    XREF Write_Err_Msg, Syntax_error
    XREF SkipSpaces, GetChar, UpperCase

    XDEF Hex_binary_disp, Hex_ascii_disp, Binary_hex_disp, Ascii_hex_disp
    XDEF Dec_hex_disp
    XDEF IntHexDisp, IntHexDisp_H, Display_binary
    XDEF ConvHexByte, Conv_to_nibble
    XDEF GetRegister16, GetRegister8, GetRegister, Get_Constant

    INCLUDE "defs.h"
    INCLUDE "syspar.def"
    INCLUDE "integer.def"
    INCLUDE "error.def"


; ******************************************************************************************
;
; Hex to binary display.
;
.Hex_binary_disp  CALL SkipSpaces
                  JP   C, Syntax_error
                  CALL ConvHexByte
                  RET  C                    ; illegal hex constant...
                  PUSH AF                   ; converted byte in A
                  CALL Display_Binary
                  CALL Write_CRLF
                  LD   BC, Nq_Ohn           ; get handle for std. output
                  CALL_OZ(Os_Nq)
                  POP  AF
                  PUSH IX                   ; preserve handle
                  LD   B,0
                  LD   C,A                  ; integer in BC
                  PUSH BC                   ; preserve integer
                  LD   DE,0                 ; result to std. output
                  LD   HL,2                 ; indicate BC = integer to be converted
                  LD   A, @00000001         ; to ASCII
                  CALL_OZ(Gn_Pdn)           ; convert integer into ASCII representation
                  LD   A,'d'
                  CALL Display_Char
                  POP  BC
                  POP  IX
                  BIT  7,C                  ; is integer a possible negative number?
                  JP   Z, Write_CRLF        ; no - terminate with CRLF and return...
                  PUSH IX
                  LD   HL,neg_number1
                  CALL Display_string
                  POP  IX
                  LD   A,C
                  NEG                       ; convert from 2. complement
                  LD   C,A
                  LD   DE,0                 ; result to std. output
                  LD   HL,2                 ; indicate BC = integer to be converted
                  LD   A, @00000001         ; to ASCII
                  CALL_OZ(Gn_Pdn)           ; convert integer into ASCII representation
                  LD   HL,neg_number2
                  CALL Display_string
                  JP   Write_CRLF

.neg_number1      DEFM " (-",0
.neg_number2      DEFM "d)",0



; ******************************************************************************************
;
; Hex to binary display.
;
.Hex_ascii_disp   CALL SkipSpaces
                  JP   C, Syntax_error
                  CALL ConvHexByte
                  RET  C                    ; illegal hex constant...
                  CALL Display_Char
                  JP   Write_CRLF


; ******************************************************************************************
;
; Binary to Hex display.
;
.Binary_hex_disp  CALL SkipSpaces
                  JP   C, Syntax_error
                  CALL ConvBinByte
                  RET  C                    ; illegal binary constant...
                  LD   L,A                  ; Fc = 0, 8bit value...
                  CALL IntHexDisp_H
                  JP   Write_CRLF


; ******************************************************************************************
;
; Binary to Hex display.
;
.Ascii_hex_disp   CALL SkipSpaces
                  JP   C, Syntax_error      ; no char specified...
                  CALL GetChar
                  LD   L,A
                  CALL IntHexDisp_H         ; display char in hex
                  CALL Write_CRLF
                  CALL Display_Binary
                  JP   Write_CRLF


; ******************************************************************************************
;
; Decimal to hex display                    V0.19c
;
.Dec_hex_disp     CALL SkipSpaces
                  JP   C, Syntax_error
                  CALL Check_decvalue
                  JP   C, Syntax_error
                  LD   DE,2                 ; conversion result in BC, B ASCII decimals...
                  CALL_OZ(Gn_Gdn)           ; HL ptr. top decimals - convert...
                  JP   C, Write_Err_Msg
                  LD   H,B
                  LD   L,C
                  SCF
                  CALL IntHexDisp_H
                  JP   Write_CRLF



; *****************************************************************************************
;
; Check decimal value                       V0.33
;
.Check_decvalue   PUSH HL                   ; preserve pointer to inp. buffer
                  LD   B,0                  ;
.check_decloop    LD   A,(HL)               ;
                  INC  B                    ;
                  INC  HL                   ;
                  OR   A                    ; ASCII value finished?
                  JR   Z, exit_decvalue
                  CP   '0'                  ;
                  JR   C, err_dechex        ; char < '0'
                  CP   ':'
                  JR   NC, err_dechex       ; char > '9'
                  JR   check_decloop
.exit_decvalue    POP  HL                   ;
                  CP   A                    ; Fc = 0, legal decimal values...
                  RET
.err_dechex       POP  HL                   ;
                  SCF                       ; Fc = 1, syntax error
                  RET



; ********************************************************************************
;
; Check whether A is part of a 16bit register
;
; A = ASCII high byte of a 16bit register.
;
; The following register contains information on return:
;         IX points at register pair   (if register pair found)
;         HL points at current buffer position (low byte of 16bit register)
;         DE = 16 value of register   (if register pair found)
;         Fc = 1 if no register pair was found, otherwise Fc = 0
;
; Please note that if no 16 bit register pair was found, A and HL (buffer ptr.) have
; not changed. The main program will be able to continue from current position in
; input buffer to parse for a hex constant or an 8 bit register.
;
; Status of registers on return:
;
;       AFBC..../IXIY  same
;       ....DEHL/....  different            (HL only different if register pair found)
;
;
.GetRegister16    PUSH BC
                  PUSH AF
                  LD   DE, Z80registers+1   ; lookup table of Z80 registers
                  LD   B,12                 ; total of 12 register pairs
.search_reg16     POP  AF
                  PUSH AF
                  LD   C,A                  ; high byte of 16bit register
                  LD   A,(DE)
                  CP   C
                  JR   Z, check_lb_reg      ; found high byte of 16bit register
.get_next_16reg   INC  DE
                  INC  DE                   ; point at next register pair
                  DJNZ, search_reg16        ; search for 12 register pairs, no more...
                  POP  AF
                  POP  BC
                  SCF                       ; 16 bit register wasn't found
                  RET

.check_lb_reg     DEC  DE                   ; point at low byte register
                  LD   A,(DE)               ; get low byte of 16bit register
                  CP   (HL)                 ; compare with low byte register in
                  JR   Z, found_16bitreg    ; input buffer
                  INC  DE                   ; not found, ptr. back to high byte...
                  JR   get_next_16reg
.found_16bitreg   CALL Fetch_Register       ; DE = contents of reg., IX ptr. to...
                  POP  AF                   ; restore AF
                  POP  BC                   ; restore BC
                  INC  HL                   ; point at char beyond 16bit reg in input buffer
                  CP   A                    ; Fc = 0, signal success!
                  RET


; ********************************************************************************
;
; Check whether the ASCII byte in A is an 8bit register
;
; The following register contains information on return:
;         IX points at 8bit register  (if register found)
;         HL points at current buffer position
;         E = 8bit value of register   (if register found)
;         Fc = 1 if no register was found, otherwise Fc = 0
;
; Status of registers on return:
;
;       A.BC..HL/..IY  same
;       .F..DE../IX..  different
;
;
.GetRegister8     PUSH AF
                  PUSH BC
                  LD   DE, Z80registers     ; lookup table of Z80 registers
                  LD   C,A                  ; register to be found in C
                  CALL search_reg8
                  JR   Z, found_8bitreg
                  LD   DE, Z80registers+1   ; lookuptable of registers
                  CALL search_reg8
                  JR   Z, found_8bitreg
                  POP  BC
                  POP  AF
                  SCF                       ; signal register not found!
                  RET

.found_8bitreg    CALL Fetch_Register       ; 8bit register into E, IX ptr. to...
                  POP  BC
                  POP  AF
                  CP   A                    ; signal success!
                  RET

.search_reg8      LD   B,8                  ; total of 8 register pairs (excl. IX,IY,SP,PC)
.reg8_loop_search LD   A,(DE)
                  CP   C
                  RET  Z                    ; Fz = 1, found register...
.get_next_8reg    INC  DE
                  INC  DE                   ; point at next register pair
                  DJNZ, reg8_loop_search    ; search for 12 register pairs, no more...
                  OR   A                    ; Fz = 0, not found...
                  RET



; **********************************************************************************
;
; Parse input buffer at current buffer ptr. for a 16bit or an 8bit register to
; display or to assign a new value.
; Return Fc = 1 if no register were found (either by syntax error or unknown
; register specification).
;
.GetRegister      CALL GetRegister16        ; try to fetch a 16 bit reg
                  JR   NC, get_16bit_param  ; register pair found, get a parameter
                  CALL GetRegister8         ; try to fetch an 8bit register
                  JR   NC, get_8bit_param   ; 8bit register found, get a parameter
                  LD   A,$0E                ; 'Cannot satisfy request'
                  SCF
                  JP   Write_Err_Msg

.get_16bit_param  LD   C,16
                  JR   get_parameter
.get_8bit_param   LD   C,8
.get_parameter    CALL SkipSpaces
                  JR   C, disp_reg          ; EOL reached, no parameter...
                  PUSH IX                   ; remember ptr. to destination register...
                  CALL Get_Constant         ; hex constant or register variable in DE/E
                  POP  IX
                  RET  C                    ; error reported, return to caller...
                  LD   A,C                  ; of 16bit register...
                  CP   8
                  JR   Z, check_range
.store_16bitint   LD   (IX+0),E             ;
                  LD   (IX+1),D             ; register saved with 16bit integer
                  CP   A                    ; Fc = 0
                  JR   disp_reg

.check_range      INC  D
                  DEC  D
                  JR   NZ, range_error
                  LD   (IX+0),E             ; new value to 8bit register or low byte
                  JR   disp_reg

.range_error      LD   A, RC_OVF
                  CALL Write_Err_Msg        ; integer cannot fit into 8bit source
                  SCF                       ; Fc = 1, indicate error
                  RET

.disp_reg         EX   DE,HL                ; contents of register in HL...
                  LD   A,C
                  CP   8
                  JR   Z, disp_8_reg        ; display 8 bit register
                  SCF                       ; display 16 bit register
                  PUSH HL
                  CALL IntHexDisp_H         ; in Hex...
                  CALL Write_CRLF
                  POP  HL
                  LD   A,H
                  CALL Display_Binary
                  LD   A,47                 ; separate each byte with '/'
                  CALL Display_Char
                  LD   A,L
                  CALL Display_Binary       ; and in binary...
                  JP   Write_CRLF

.disp_8_reg       CP   A
                  CALL IntHexDisp_H         ; in Hex...
                  CALL Write_CRLF
                  LD   A,L
                  CALL Display_Binary       ; and in binary...
                  JP   Write_CRLF



; ********************************************************************************
;
; DE = contents of register, IX ptr. to location of register
;
; Status of registers on return:
;
;       A.....HL/..IY  same
;       .FBCDE../IX..  different
;
;
.Fetch_Register   PUSH HL                   ; don't destroy buffer ptr
                  LD   HL, Z80registers     ; DE = ptr to found register
                  EX   DE,HL                ; DE = ptr to base of lookup table
                  CP   A                    ; Fc = 0
                  SBC  HL,DE                ; register is located in
                  LD   C,L                  ; IY+C
                  PUSH IY                   ; base of registers
                  POP  IX                   ; into IX
                  LD   B,0
                  ADD  IX,BC                ; ptr. to register
                  LD   E,(IX+0)
                  LD   D,(IX+1)             ; contents of register
                  POP  HL                   ; restore buffer ptr.
                  RET

.Z80registers     DEFM "CBEDLH",$FF
                  DEFM "Acbedlh",$FF
                  DEFM "aXIYIPSCP"          ; as stored on stack area (base IY)


; **********************************************************************************
;
; Get constant value defined as ASCII bytes in input buffer, pointed out
; by HL. The subroutine fetches the appropriate integer size as defined in C (8 or 16bit).
; The subroutine also acknowledge register names as parameters (both 8 & 16 bit).
; However, register references must be to the appropriate type, e.g. it is not possible
; to assign an 8 bit value to a 16 bit type.
;
; Integer result returned in DE if 16 bit value, or E if 8 bit value.
;
; Status of registers on return:
;
;       A..C..../..IY  same
;       .FB.DEHL/IX..  different
;
;
; If parameter is successfully fetched Fc = 0; HL ptr to next char in input buffer,
; otherwise Fc = 1.
;
; To obtain an integer constant it is necessary to specify a $ in front of the hexadecimal
; constant, or a  to obtain an 8bit binary integer.
;
.Get_Constant     CALL SkipSpaces           ; ignore spaces...
                  JP   C, syntax_error      ; ups...
                  LD   A,C
                  CP   8                    ; fetch an 8 bit value...
                  JR   Z, get_8bitvalue
                  CALL GetChar
                  CP   '~'
                  JR   Z, get_decvalue
                  CP   '@'                  ; binary constant?
                  JR   Z, binary_constant   ;                                 ** V0.17
                  CP   '''                  ; ASCII char constant?            ** V0.17
                  JR   Z, ascii_constant    ;                                 ** V0.17
                  DEC  HL                   ; unget char                      ** V0.27a
                  PUSH HL                   ; try to fetch 16bit hex constant ** V0.27a
                  CALL ConvHexByte
                  JR   C, fetch_16bitreg    ;                                 ** V0.27a
                  LD   D,A                  ; high byte of integer word in D
                  CALL ConvHexByte
                  JR   C, fetch_16bitreg    ;                                 ** V0.27a
                  LD   E,A
                  POP  IX                   ;                                 ** V0.27a
                  RET
.fetch_16bitreg   POP  HL                   ; restore pointer to parameter    ** V0.27a
                  CALL GetChar              ; get char                        ** V0.27a
                  CALL GetRegister16        ; try to fetch a 16bit register
                  JP   C, Syntax_Error      ; no hex and no register found    ** V0.27a
                  RET                       ; 16bit integer from register in DE

.get_decvalue     CALL Check_decvalue
                  JP   C, Syntax_error
                  PUSH BC                   ; preserve size identifier in C
                  LD   DE,2                 ; conversion result in BC
                  CALL_OZ(Gn_Gdn)           ; HL ptr. top decimals - convert...
                  POP  DE
                  JP   C, Syntax_error
                  LD   A,E
                  LD   D,B
                  LD   E,C                  ; ASCII decimal converted to integer
                  LD   C,A                  ; size identifier in C
                  RET

.get_8bitvalue    CALL GetChar
                  CP   '~'
                  JR   Z, get_decvalue
                  CP   '@'                  ; binary constant?
                  JR   Z, binary_constant   ;                                 ** V0.17
                  CP   '''                  ; ASCII char constant?            ** V0.17
                  JR   Z, ascii_constant    ;                                 ** V0.17
                  DEC  HL                   ; unget char                      ** V0.27a
                  PUSH HL                   ; preserve pointer if fail...     ** V0.27a
.get_8hexvalue    CALL ConvHexByte          ; try to fetch 8bit hex const.    ** V0.27a
                  JR   C, fetch_8bitreg     ; no hex constant                 ** V0.27a
                  POP  IX                   ; remove pointer                  ** V0.27a
                  JR   ret_int_DE

.fetch_8bitreg    POP  HL                   ; restore pointer to parameter    ** V0.27a
                  CALL GetChar              ; get char at buffer              ** V0.27a
                  CALL GetRegister8         ; no constants, find a register..
                  JP   C, Syntax_Error      ; no hex & no register found...   ** V0.27a
                  JR   ret_int_D            ; integer in E of register

.binary_constant  CALL ConvBinByte          ;                                 ** V0.17
                  JR   ret_int_DE

.ascii_constant   CALL SkipSpaces
                  JP   C, Syntax_Error
                  CALL GetChar
.ret_int_DE       LD   E,A                  ; return 8bit constant in E
.ret_int_D        LD   D,0
                  RET


; *********************************************************************************
;
; Convert Hex byte (e.g. 'FF') to integer byte. Both chars are read from input buffer.
; Result returned in A
;
; Register status after return:
;
;       ...CDE../IXIY same
;       AFB...HL/....  different
;
.ConvHexByte     CALL GetChar
                 RET  C                     ; EOL reached, syntax_error
                 CALL UpperCase
                 CALL Conv_to_nibble        ; ASCII to value 0 - 15.
                 CP   16                    ; legal range 0 - 15
                 JR   NC, Illegal_hexval
                 SLA  A
                 SLA  A
                 SLA  A
                 SLA  A                     ; into bit 7 - 4.
                 LD   B,A
                 CALL GetChar
                 RET  C                     ; EOL reached, syntax_error
                 CALL UpperCase
                 CALL Conv_to_nibble        ; ASCII to value 0 - 15.
                 CP   16                    ; legal range 0 - 15
                 JR   NC, Illegal_hexval
                 OR   B                     ; merge the two nibbles
                 RET
.illegal_hexval  SCF
                 RET

; **********************************************************************************
.Conv_to_nibble   CP   '@'                  ; digit >= "A"?
                  JR   NC,hex_alpha         ; digit is in interval "A" - "F"
                  SUB  48                   ; digit is in interval "0" - "9"
                  RET
                  .hex_alpha
                  SUB  55
                  RET


; **********************************************************************************
;
; V0.17:
; Convert a ASCII binary string to integer.
; Result returned in A
;
; If binary ASCII string is fetched successfully from input buffer, Fc = 0
;
; Register status after return:
;
;       ...C..../IXIY same
;       AFB.DEHL/....  different            B = 0 on return
;
;
.ConvBinByte      LD   B,8                  ; byte integer to fetch...
                  LD   DE,@10000000         ; bit mask - starting with Bit 7...
.conv_bin_loop    CALL GetChar
                  CP   '0'
                  JR   Z, get_next_binval
                  CP   '1'
                  JP   NZ, syntax_error     ; only '0' and '1' allowed...
                  LD   A,D
                  OR   E                    ; mask bit into A
                  LD   D,A
.get_next_binval  RRC  E                    ; bit mask rotate right...
                  DJNZ,conv_bin_loop
                  LD   A,D
                  CP   A                    ; Fc = 0, Success!
                  RET


; ****************************************************************************
; INTEGER to HEX conversion
; HL (in) = integer to be converted to an ASCII HEX string
; Fc = 1 convert 16 bit integer, otherwise byte integer
;
; Returns DEBC = 4 byte ASCII string of HEX number, and
; print the string to the current window
;
; Register status after return:
;
;       AF....../IXIY  same
;       ..BCDEHL/....  different
;
.IntHexDisp       PUSH AF
                  JR   NC, calc_low_byte    ; convert only byte
                  LD   A,H
                  CALL CalcHexByte
.calc_low_byte    PUSH DE
                  LD   A,L
                  CALL CalcHexByte          ; DE = low byte ASCII
                  LD   B,D
                  LD   C,E
                  POP  DE
                  POP  AF
                  PUSH AF                   ; get flag register..
                  JR   NC, only_byte_int    ; NC = display only a byte
                  LD   A,D
                  CALL Display_Char         ; V0.17
                  LD   A,E
                  CALL Display_Char         ; V0.17
.only_byte_int    LD   A,B
                  CALL Display_Char         ; V0.17
                  LD   A,C
                  CALL Display_Char         ; string printed... ** V0.17
                  POP  AF
                  RET

.IntHexDisp_H     CALL IntHexDisp
                  PUSH AF
                  LD   A, 'h'               ; same as 'IntHexDisp_H', but with a
                  CALL Display_Char         ; trailing 'H' hex identifier...
                  POP  AF
                  RET


; ****************************************************************************
; byte in A, will be returned in ASCII form in DE
.CalcHexByte      PUSH HL
                  LD   H,A                  ; copy of A
                  SRL  A
                  SRL  A
                  SRL  A
                  SRL  A                    ; high nibble of H
                  CALL CalcHexNibble
                  LD   D,A
                  LD   A,H
                  AND  @00001111            ; low nibble of A
                  CALL CalcHexNibble
                  LD   E,A
                  POP  HL
                  RET


; ******************************************************************
; A(in) = 4 bit integer value, A(out) = ASCII HEX byte
.CalcHexNibble    CP   $0A
                  JR   NC, HexNibble_16
                  ADD  A,$30
                  RET
.HexNibble_16     ADD  A,$37
                  RET


; **************************************************************************************
; Display an binary ASCII string of 8 bit value contained in A
;
; Register status after return:
;
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.Display_Binary   PUSH BC
                  LD   B,A
                  LD   C, @10000000         ; bit 7 set...
.display_loop     LD   A,B
                  AND  C
                  LD   A,'0'
                  JR   Z, disp_bit
                  LD   A, '1'
.disp_bit         CALL Display_Char
                  SRL  C                    ; C >> 1  -> Fc
                  JR   NC, display_loop
                  POP  BC                   ; bit 7 transferred to Fc
                  LD   A,'b'
                  JP   Display_Char

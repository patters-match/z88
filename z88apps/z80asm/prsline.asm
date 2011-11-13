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

; This library of routines contains functions to process ASCII bytes.

     MODULE ParseLine


     LIB IsSpace, IsAlpha, IsAlNum, IsDigit, StrChr, ToUpper

     XREF Getsym
     XREF STDerr_ill_ident

     XDEF CheckCondition, CheckRegister8, CheckRegister16
     XDEF IndirectRegisters

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ******************************************************************************
;
; CheckCondition -  check whether a conditional mnemonic is the current ident.
;                   (Z,C,NZ,NC,P,M,PE,PO).
;
;  IN:    None.
; OUT:    A = opcode value of mnemonic condition (0 - 7), if found
;             else A = -1 ($FF)
;
; Registers changed after return:
;
;    ..BCDE../IXIY  same
;    AF....HL/....  different
;
.CheckCondition     LD   HL, ident
                    LD   A,(HL)
                    CP   1                   ; is identifier length 1 byte?
                    INC  HL
                    JR   Z, test_cond1
                    CP   2                   ; is identifier length 2 bytes?
                    JR   Z, test_cond2
                    LD   A,-1
                    RET
.test_cond1              LD   A,(HL)
                         CP   'Z'
                         JR   Z, cond_Z
                         CP   'C'
                         JR   Z, cond_C
                         CP   'P'
                         JR   Z, cond_P
                         CP   'M'
                         JR   Z, cond_M
                         LD   A,-1
                         RET
.cond_Z                       LD   A,1
                              RET
.cond_C                       LD   A,3
                              RET
.cond_P                       LD   A,6
                              RET
.cond_M                       LD   A,7
                              RET
.test_cond2              LD   A,(HL)
                         CP   'N'
                         JR   Z, cond_not
                         CP   'P'
                         JR   Z, cond_PEPO
                         LD   A,-1
                         RET
.cond_not                INC  HL
                         LD   A,(HL)
                         CP   'Z'
                         JR   Z, cond_NZ
                         CP   'C'
                         JR   Z, cond_NC
                         LD   A,-1
                         RET
.cond_NZ                      XOR  A
                              RET
.cond_NC                      LD   A,2
                              RET

.cond_PEPO               INC  HL
                         LD   A,(HL)
                         CP   'E'
                         JR   Z, cond_PE
                         CP   'O'
                         JR   Z, cond_PO
                         LD   A,-1
                         RET
.cond_PO                      LD   A,4
                              RET
.cond_PE                      LD   A,5
                              RET



; ******************************************************************************
;
; CheckRegister8 -  check the current identifier for an 8bit register mnemonic.
;                   (B,C,D,E,H,L,F,A,I,R)
;                    0 1 2 3 4 5 6 7 8 9
;  IN:    None.
; OUT:    A = opcode value of 8bit register mnemonic (0 - 9), if found
;             else A = -1 ($FF)
;
; Registers changed after return:
;
;    ..BCDE../IXIY  same
;    AF....HL/....  different
;
.CheckRegister8     PUSH BC
                    LD   HL,ident
                    LD   A,(HL)
                    CP   1
                    JR   NZ, std8reg_not_found
.fetch_regopc8      INC  HL
                    LD   A,(HL)              ; fetch 8bit register mnemonic
                    LD   HL,Z80registers
                    LD   BC,10
                    CPIR
                    JR   NZ, unknown_8bit
                    LD   A,9
                    SUB  C
                    POP  BC
                    RET
.std8reg_not_found  CP   3
                    JR   Z, check_ext8_regs  ; is it the 8bit IX/IY registers?

.unknown_8bit       LD   A,-1
                    POP  BC
                    RET

.check_ext8_regs    INC  HL
                    LD   A,(HL)
                    INC  HL
                    CP   'I'
                    JR   NZ, unknown_8bit
                         LD   A,(HL)
                         CP   'X'
                         JR   NZ, check_iy8bit
                              INC  HL
                              LD   A,(HL)
                              CP   'H'
                              JR   NZ, check_ixlow
                                   LD   A, 8 | 4       ; IXH was identified
                                   POP  BC
                                   RET
.check_ixlow                  CP   'L'
                              JR   NZ, unknown_8bit
                                   LD   A, 8 | 5       ; IXL was identified
                                   POP  BC
                                   RET
.check_iy8bit            CP   'Y'
                         JR   NZ, unknown_8bit
                              INC  HL
                              LD   A,(HL)
                              CP   'H'
                              JR   NZ, check_iylow
                                   LD   A, 16 | 4      ; IYH was identified
                                   POP  BC
                                   RET
.check_iylow                  CP   'L'
                              JR   NZ, unknown_8bit
                                   LD   A, 16 | 5      ; IYL was identified
                                   POP  BC
                                   RET

.Z80registers       DEFM "BCDEHLFAIR"


; ******************************************************************************
;
; CheckRegister16 - check the current identifier for a 16it register mnemonic.
;                   (BC,DE,HL,AF,IX,IY,SP)
;
;  IN:    None.
; OUT:    A = opcode value of 16bit register mnemonic (0 - 6), if found
;             else A = -1 ($FF)
;
; Registers changed after return:
;
;    ..BCDE../IXIY  same
;    AF....HL/....  different
;
.CheckRegister16    LD   HL,ident
                    LD   A,(HL)
                    CP   2
                    JR   Z, fetch_regopc16
                    LD   A,-1
                    RET
.fetch_regopc16     INC  HL
                    LD   A,(HL)
                    INC  HL
                    CP   'H'
                    JR   Z, hl_opcode
                    CP   'D'
                    JR   Z, de_opcode
                    CP   'B'
                    JR   Z, bc_opcode
                    CP   'A'
                    JR   Z, af_opcode
                    CP   'I'
                    JR   Z, index_opcode
                    CP   'S'
                    JR   Z, sp_opcode
                    LD   A, -1
                    RET
.hl_opcode          LD   A,(HL)
                    CP   'L'
                    LD   A,2
                    RET
.de_opcode          LD   A,(HL)
                    CP  'E'
                    LD   A,1
                    RET
.bc_opcode          LD   A,(HL)
                    CP   'C'
                    LD   A,0
                    RET
.af_opcode          LD   A,(HL)
                    CP   'F'
                    LD   A,4
                    RET
.sp_opcode          LD   A,(HL)
                    CP   'P'
                    LD   A,3
                    RET
.index_opcode       LD   A,(HL)
                    CP   'X'
                    JR   Z, ix_opcode
                    CP   'Y'
                    LD   A,6
                    RET  Z
                    LD   A, -1
                    RET
.ix_opcode          LD   A,5
                    RET



; ******************************************************************************
;
; IndirectRegisters - parse the current line for an indirect addressing mode
;
;  IN:    None.
; OUT:    A = opcode value of indirect addressing mode (0,1,2,5,6,7), if found
;             else A = -1 ($FF)
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different (affected by GetSym)
;
.IndirectRegisters  PUSH BC
                    PUSH DE
                    PUSH HL
                    CALL GetSym              ; get first parse item of expression
                    CALL CheckRegister16
                    JR   NZ, addr_expr       ; found a possible addr. expression
                    CP   5
                    JR   Z, index_reg_addr   ; IX as indirect address
                    CP   6
                    JR   Z, index_reg_addr   ; IY as indirect address
                    CP   3
                    JR   Z, illegal_addr
                    CP   4
                    JR   Z, illegal_addr

                    PUSH AF
                    CALL GetSym              ; BC, DE or HL as indirect address
                    CP   sym_rparen          ; proper syntax?
                    JR   NZ, illegal_addr    ; right bracket missing
                    CALL GetSym              ; prepare for next read...
                    POP  AF
                    JR   end_indreg

.index_reg_addr     PUSH AF
                    CALL GetSym              ; prepare for index register offset expr.
                    POP  AF                  ; Fz = 1, return 5 or 6
                    JR   end_indreg

.addr_expr          LD   A,7
                    JR   end_indreg

.illegal_addr       CALL STDerr_ill_ident
                    LD   A,-1

.end_indreg         POP  HL
                    POP  DE
                    POP  BC
                    RET

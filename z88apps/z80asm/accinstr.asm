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


;
; This module contain all arithmetic & logical instructions:
;
; 8bit:
;    ADD  A,r       , r = A, B, C, D, E, H, L, IXL, IXH, IYL, IYH
;    ADD  A,n
;    ADD  A,(HL)
;    ADD  A,(IY+d)
;    ADC  ...
;    SUB  ...
;    SBC  ...
;    CP   ...
;    AND  ...
;    OR   ...
;    XOR  ...
;
;    INC  r
;    INC  (HL)
;    INC  (IX+d)
;    INC  (IY+d)
;    DEC  ...
;
; 16bit:
;    ADD  HL,ss     , ss = BC, DE, HL, SP
;    ADC  HL,ss
;    SBC  HL,ss
;    ADD  IX,pp     , pp = BC, DE, IX, SP
;    ADD  IY,rr     , rr = BC, DE, IY, SP
;
;    INC  qq        , qq = BC, DE, HL, SP, IX, IY
;    DEC  qq


     MODULE Arithmetic_logical_instructions


; external procedures:
     LIB Read_byte

     XREF ReportError_STD, STDerr_syntax, STDerr_ill_ident  ; errors.asm

     XREF Getsym, CheckCondition, CheckRegister16           ; prsline.asm
     XREF CheckRegister8, IndirectRegisters                 ;

     XREF WriteByte, WriteWord                              ; writebytes.asm

     XREF Add16bit_1, Add16bit_2, Add16bit_3                ; exprs.asm
     XREF Test_8bit_range                                   ;

     XREF ExprUnsigned8, ExprSigned8                        ; exprprsr.asm

     XREF ix8bit, iy8bit                                    ; ldinstr.asm

; global procedures:
     XDEF ADD_fn, ADC_fn, SUB_fn, SBC_fn
     XDEF CP_fn, AND_fn, OR_fn, XOR_fn
     XDEF INC_fn, DEC_fn

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
;
.AND_fn             LD   C,4
                    JP   ArithLog8_instr


; **************************************************************************************************
;
;
.OR_fn              LD   C,6
                    JP   ArithLog8_instr


; **************************************************************************************************
;
;
.CP_fn              LD   C,7
                    JP   ArithLog8_instr


; **************************************************************************************************
;
;
.SUB_fn             LD   C,2
                    JP   ArithLog8_instr


; **************************************************************************************************
;
;
.XOR_fn             LD   C,5
                    JP   ArithLog8_instr


; **************************************************************************************************
;
;
.ADD_fn             CALL Getsym                        ; Getsym()
                    CALL CheckRegister16               ; switch( acc16 = CheckRegisters16() )
                    LD   B,A                                ; {B=acc16}
                    CP   -1                                 ; case -1:
                    JR   NZ, add_case_2
                         LD   C,0
                         JP    Parse_Acc                          ; Parse_Acc(0)  {ADD A,}
.add_case_2         CP   2                                  ; case 2:
                    JR   NZ, add_case_5
                         CALL Getsym
                         CP   sym_comma                          ; if ( Getsym() == comma )
                         JP   NZ, STDerr_syntax
                              CALL Getsym                             ; Getsym
                              CALL CheckRegister16                    ; reg16 = CheckRegister16()
                              LD   C,A
                              AND  @11111100                          ; if ( reg16>=0 && reg16<=3 )
                              JP   NZ, STDerr_ill_ident
                                   LD   A,C
                                   RLCA                                    ; { ADD  HL, [BC,DE,HL }
                                   RLCA
                                   RLCA
                                   RLCA                                    ; reg16*16
                                   ADD  A,9
                                   LD   C,A
                                   CALL WriteByte                          ; *codeptr++ = 9 + reg16*16
                                   LD   HL, asm_pc
                                   JP   Add16bit_1                         ; ++PC
.add_case_5         CP   5                                  ; case 5:
                    JR   NZ, add_case_6
                         LD   C,221                              ; *codeptr++ = 221
                         CALL WriteByte
                         JR   add_index
.add_case_6         CP   6                                  ; case 6:
                    JR   NZ,add_default
                         LD   C,253                              ; *codeptr++ = 253
                         CALL WriteByte
.add_index               CALL Getsym
                         CP   sym_comma                          ; if ( Getsym() == comma )
                         JP   NZ, STDerr_syntax
                              CALL Getsym                             ; Getsym()
                              CALL CheckRegister16
                              LD   C,A                                ; reg16 = CheckRegister16()
                              CP   0                                  ; switch(reg16)
                              JR   Z, add_switch_reg16_end                 ; case 0:
                              CP   1                                       ; case 1:
                              JR   Z, add_switch_reg16_end
                              CP   3                                       ; case 3: break
                              JR   Z, add_switch_reg16_end
                              CP   5                                       ; case 5:
                              JR   Z, add_reg16_case_index
                              CP   6                                       ; case 6:
                              JP   NZ,STDerr_ill_ident
.add_reg16_case_index              CP   B                                       ; if ( acc16 = reg16 )
                                   JP   NZ, STDerr_ill_ident
                                        LD   C,2
.add_switch_reg16_end         LD   A,C
                              RLCA                                    ; { ADD  IX/IY, rr }
                              RLCA
                              RLCA
                              RLCA                                    ; reg16*16
                              ADD  A,9
                              LD   C,A
                              CALL WriteByte                          ; *codeptr++ = 9 + reg16*16
                              LD   HL, asm_pc
                              JP   Add16bit_2                         ; PC += 2

.add_default        LD   A, ERR_unkn_ident                  ; default:
                    JP   ReportError_STD


; **************************************************************************************************
;
;
.ADC_fn             CALL Getsym                        ; Getsym()
                    CALL CheckRegister16               ; switch( acc16 = CheckRegisters16() )
                    CP   -1                                 ; case -1:
                    JR   NZ, adc_case_2
                         LD   C,1
                         JP   Parse_Acc                          ; Parse_Acc(1)  {ADC A,}
.adc_case_2         CP   2                                  ; case 2:
                    JP   NZ, STDerr_ill_ident
                         CALL Getsym
                         CP   sym_comma                          ; if ( Getsym() == comma )
                         JP   NZ, STDerr_syntax
                              CALL Getsym                             ; Getsym
                              CALL CheckRegister16                    ; reg16 = CheckRegister16()
                              LD   B,A
                              AND  @11111100                          ; if ( reg16>=0 && reg16<=3 )
                              JP   NZ, STDerr_ill_ident
                                   LD   A,B
                                   RLCA                                    ; { ADC  HL, [BC,DE,HL,SP] }
                                   RLCA
                                   RLCA
                                   RLCA                                    ; reg16*16
                                   ADD  A,74
                                   LD   B,A
                                   LD   C,237                              ; *codeptr++ = 237
                                   CALL WriteWord                          ; *codeptr++ = 74 + reg16*16
                                   LD   HL, asm_pc
                                   JP   Add16bit_2                         ; PC += 2


; **************************************************************************************************
;
;
.SBC_fn             CALL Getsym                        ; Getsym()
                    CALL CheckRegister16               ; switch( acc16 = CheckRegisters16() )
                    CP   -1                                 ; case -1:
                    JR   NZ, sbc_case_2
                         LD   C,3
                         JP   Parse_Acc                          ; Parse_Acc(3)  { SBC A, }
.sbc_case_2         CP   2                                  ; case 2:
                    JP   NZ, STDerr_ill_ident
                         CALL Getsym
                         CP   sym_comma                          ; if ( Getsym() == comma )
                         JP   NZ, STDerr_syntax
                              CALL Getsym                             ; Getsym
                              CALL CheckRegister16                    ; reg16 = CheckRegister16()
                              LD   B,A
                              AND  @11111100                          ; if ( reg16>=0 && reg16<=3 )
                              JP   NZ, STDerr_ill_ident
                                   LD   A,B
                                   RLCA                                    ; { SBC  HL, [BC,DE,HL,SP] }
                                   RLCA
                                   RLCA
                                   RLCA                                    ; reg16*16
                                   ADD  A,66
                                   LD   B,A
                                   LD   C,237                              ; *codeptr++ = 237
                                   CALL WriteWord                          ; *codeptr++ = 74 + reg16*16
                                   LD   HL, asm_pc
                                   JP   Add16bit_2                         ; PC += 2


; **************************************************************************************************
;
; IN:     C = standard instruction opcode
;
.Parse_Acc          LD   A,(sym)
                    CP   sym_name                 ; if ( sym == name )
                    JP   NZ, STDerr_syntax
                         CALL CheckRegister8
                         CP   7                        ; if ( CheckRegister8() == 7
                         JP   NZ, STDerr_ill_ident
                              CALL Getsym
                              CP   sym_comma                ; if ( Getsym() == comma )
                              JP   NZ,STDerr_syntax
                                   JP ArithLog8_instr


; **************************************************************************************************
;
; IN:     C = standard instruction opcode
;
.ArithLog8_instr
.skip_acc           CALL Getsym
                    CP   sym_lparen               ; if ( Getsym() == lparen )
                    JR   NZ, get_8bit_reg
                         CALL IndirectRegisters        ; switch ( reg = IndirectRegister() )
                         CP   2                             ; case 2:
                         JR   NZ, indirect_case_5
                              LD   A,C                           ; {opcode}
                              RLCA
                              RLCA
                              RLCA                               ; opcode*8
                              ADD  A,128+6
                              LD   C,A
                              CALL WriteByte                     ; *codeptr++ = 128 + opcode*8 + 6
                              LD   HL,asm_pc
                              JP   Add16bit_1
.indirect_case_5         CP   5
                         JR   NZ, indirect_case_6
                              LD   B,221
                              JR   indirect_case_6_index
.indirect_case_6         CP   6
                         JP   NZ, STDerr_syntax
                              LD   B,253
.indirect_case_6_index        LD   A,C                           ; {opcode}
                              RLCA
                              RLCA
                              RLCA                               ; opcode*8
                              ADD  A,128+6
                              LD   C,B
                              LD   B,A                           ; *codeptr++ = 221 || 253
                              CALL WriteWord                     ; *codeptr++ = 128 + opcode*8 + 6
                              CALL ExprSigned8                   ; ExprSigned8(2)
                              LD   HL,asm_pc
                              JP   Add16bit_3                    ; PC += 3
                                                  ; else
.get_8bit_reg       CALL CheckRegister8                ; switch( reg = CheckRegister8() )
                    CP   -1                                 ; case -1:
                    JR   NZ, direct_case_8
                         LD   A,C
                         RLCA
                         RLCA
                         RLCA
                         ADD  A,192+6
                         LD   C,A
                         CALL WriteByte                          ; *codeptr++ = 192 + opcode*8 + 6
                         CALL ExprUnsigned8                      ; ExprUnsigend8(1)
                         LD   HL,asm_pc
                         JP   Add16bit_2

.direct_case_8      CP   6
                    JP   Z, STDerr_ill_ident                ; case 6:
                    CP   8                                  ; case 8:
                    JP   Z, STDerr_ill_ident
                    CP   9                                  ; case 9: reporterror(11)
                    JP   Z, STDerr_ill_ident

.direct_default     LD   B,A                                ; default:
                    RES  3,B
                    RES  4,B                                     ; remove IXL/H IYL/H identifiers
                    BIT  3,A                                     ; if ( reg & 8) *codeptr++ = 221; ++PC
                    CALL NZ, ix8bit                              ; xxx [A,] IXL/H
                    BIT  4,A                                     ; if ( reg & 16) *codeptr++ = 253; ++PC
                    CALL NZ, iy8bit                              ; xxx [A,] IYL/H
                    LD   A,C
                    RLCA
                    RLCA
                    RLCA
                    ADD  A,128
                    ADD  A,B
                    LD   C,A
                    CALL WriteByte                               ; *codeptr++ = 128 + opcode*8 + reg
                    LD   HL,asm_pc
                    JP   Add16bit_1                              ; ++ PC


; **************************************************************************************************
;
;
.INC_fn             CALL Getsym                             ; Getsym()
                    CALL CheckRegister16                    ; switch( reg16 = CheckRegister16() )
                    CP   -1                                      ; case -1:
                    JR   NZ,inc_case_4
                         LD   C,4
                         JP   IncDec_8bit_instr                       ; IncDec_8bit_instr(4)
.inc_case_4         CP   4                                       ; case 4:
                    JP   Z, STDerr_ill_ident                          ; Reporterror(11)
                    CP   5                                       ; case 5:
                    JR   NZ, inc_case_6
                         LD   BC,$23DD                                ; *codeptr++ = 221
                         JR   inc_index                               ; *codeptr++ = 35
.inc_case_6         CP   6
                    JR   NZ, inc_default
                         LD   BC,$23FD                                ; *codeptr++ = 253
.inc_index               CALL WriteWord
                         LD   HL, asm_pc
                         JP   Add16bit_2                              ; PC += 2

.inc_default             RLCA                                    ; default:
                         RLCA
                         RLCA
                         RLCA                                         ; *codeptr++ = 3 + reg16*16
                         ADD  A,3
                         LD   C,A
                         CALL WriteByte
                         LD   HL,asm_pc
                         JP   Add16bit_1                              ; ++PC


; **************************************************************************************************
;
;
.DEC_fn             CALL Getsym                             ; Getsym()
                    CALL CheckRegister16                    ; switch( reg16 = CheckRegister16() )
                    CP   -1                                      ; case -1:
                    JR   NZ,dec_case_4
                         LD   C,5
                         JP   IncDec_8bit_instr                       ; IncDec_8bit_instr(5)
.dec_case_4         CP   4                                       ; case 4:
                    JP   Z, STDerr_ill_ident                          ; Reporterror(11)
                    CP   5                                       ; case 5:
                    JR   NZ, dec_case_6
                         LD   BC,$2BDD                                ; *codeptr++ = 221
                         JR   dec_index
.dec_case_6         CP   6
                    JR   NZ, dec_default
                         LD   BC,$2BFD                                ; *codeptr++ = 253
.dec_index               CALL WriteWord
                         LD   HL, asm_pc
                         JP   Add16bit_2                              ; PC += 2

.dec_default        RLCA                                         ; default:
                    RLCA
                    RLCA
                    RLCA                                              ; *codeptr++ = 11 + reg16*16
                    ADD  A,11
                    LD   C,A
                    CALL WriteByte
                    LD   HL,asm_pc
                    JP   Add16bit_1                                   ; ++PC


; **************************************************************************************************
;
; IN:     C = standard instruction opcode
;
.IncDec_8bit_instr  LD   A,(sym)
                    CP   sym_lparen                         ; if ( sym == lparen )
                    JR   NZ, incdec_directadr
                         CALL IndirectRegisters                  ; switch( reg = IndirectRegisters() )
                         CP   2                                       ; case 2:
                         JR   NZ, incdec_case_5
                              LD   A,C
                              ADD  A,48
                              LD   C,A
                              CALL WriteByte                               ; *codeptr++ = 48 + opcode
                              LD   HL, asm_pc                               ; ++PC
                              JP   Add16bit_1

.incdec_case_5           CP   5                                       ; case 5:
                         JR   NZ, incdec_case_6
                              LD   B,221                                   ; *codeptr++ = 221
                              JR   incdec_case_6_index
.incdec_case_6           CP   6                                       ; case 6:
                         JP   NZ, STDerr_syntax
                              LD   B,253                                   ; *codeptr++ = 253
.incdec_case_6_index          LD   A,48
                              ADD  A,C
                              LD   C,B
                              LD   B,A                                     ; *codeptr++ = 48 + opcode
                              CALL WriteWord
                              CALL ExprSigned8                             ; ExprSigned8(2)
                              LD   HL, asm_pc
                              JP   Add16bit_3                              ; PC += 3
                                                            ; else
.incdec_directadr        CALL CheckRegister8                     ; switch( reg = CheckRegister8() )
                         CP   6
                         JP   Z, STDerr_ill_ident                     ; case 6:
                         CP   8                                       ; case 8:
                         JP   Z, STDerr_ill_ident
                         CP   9                                       ; case 9: Reporterror(11)
                         JP   Z, STDerr_ill_ident                     ; default:
                              BIT  3,A                                     ; if ( reg & 8) *codeptr++ = 221; ++PC
                              CALL NZ, ix8bit                              ; xxx IXL/H
                              BIT  4,A                                     ; if ( reg & 16) *codeptr++ = 253; ++PC
                              CALL NZ, iy8bit                              ; xxx IYL/H
                              AND  7
                              RLCA
                              RLCA
                              RLCA
                              ADD  A,C
                              LD   C,A
                              CALL WriteByte                               ; *codeptr++ = reg*8 + opcode
                              LD   HL, asm_pc
                              JP   Add16bit_1

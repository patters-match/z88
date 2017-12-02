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
; This module generates machine code for all simple instructions needing no parsing,
; (just the identifier which has already been parsed)
;
; and various simple function instructions.
;

     MODULE LD_instructions


; external procedures:
     LIB Read_byte

     XREF ReportError_STD, STDerr_syntax, STDerr_ill_ident  ; errors.asm

     XREF Getsym, CheckCondition, CheckRegister16           ; prsline.asm
     XREF CheckRegister8, IndirectRegisters                 ;

     XREF WriteByte, WriteWord                              ; writebytes.asm
     XREF Add16bit_1, Add16bit_2, Add16bit_3, Add16bit_4    ; exprs.asm

     XREF FlushBuffer                                       ; bytesio.asm

     XREF ParseNumExpr, EvalPfixExpr, RemovePfixlist        ; exprprsr.asm
     XREF ExprUnsigned8, ExprSigned8, ExprAddress           ;


; global procedures:
     XDEF LD_fn
     XDEF ix8bit, iy8bit

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ***********************************************************************************
;
; LD instructions - main entry
;
.LD_fn              CALL Getsym
                    CP   sym_lparen               ; if ( Getsym() == lparen )
                    JR   NZ, ld_check_8bitreg
                         LD   IX,(lineptr)             ; startexpr = lineptr
                         CALL IndirectRegisters        ; switch( destreg = IndirectRegisters() )
                         CP   2                             ; case 2: /* LD  (HL), */
                         JR   NZ, ld_switch1_5
                              JP  LD_hl8bit_indrct                   ; LD_HL8bit_indrct()

.ld_switch1_5            LD   C,221
                         CP   5                             ; case 5:  /* LD  (IX|IY+d), */
                         JR   Z, ld_switch1_6x
                         CP   6                             ; case 6:
                         JR   NZ, ld_switch1_0                        ; LD_index8bit_indrct(destreg)
                              LD   C,253
.ld_switch1_6x                JP   LD_index8bit_indrct

.ld_switch1_0            CP   0                             ; case 0:  /* LD  (BC),A  */
                         JR   NZ, ld_switch1_1
                              LD   A,(sym)
                              CP   sym_comma                     ; if ( sym == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym                        ; Getsym()
                                   CALL CheckRegister8                ; if ( CheckRegister8() == 7 )
                                   CP   7
                                   JP   NZ, STDerr_ill_ident
                                        LD   C,2
                                        CALL WriteByte                     ; *codeptr++ = 2
                                        LD   HL, asm_pc
                                        JP   Add16bit_1                    ; ++PC

.ld_switch1_1            CP   1                             ; case 1:  /* LD  (DE),A  */
                         JR   NZ, ld_switch1_7
                              LD   A,(sym)
                              CP   sym_comma                     ; if ( sym == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym                        ; Getsym()
                                   CALL CheckRegister8                ; if ( CheckRegister8() == 7 )
                                   CP   7
                                   JP   NZ, STDerr_ill_ident
                                        LD   C,18
                                        CALL WriteByte                     ; *codeptr++ = 18
                                        LD   HL, asm_pc
                                        JP   Add16bit_1                    ; ++PC

.ld_switch1_7            CP   7                             ; case 7:  /* LD  (nn),rr; LD (nn),A */
                         JP   NZ, STderr_syntax
                              JP   LD_address_indrct                  ; LD_address_indrct()
                                                            ; default: Reporterror(1)
                                                  ; else
.ld_check_8bitreg        CALL CheckRegister8           ; switch( destreg = CheckRegister8() )
                         LD   C,A                           ; {destreg=C}
                         CP   -1                            ; case -1: /* LD  rr,(nn); LD  rr,nn; LD  SP,HL|IX|IY */
                         JR   NZ, ld_switch2_6
                              JP   LD_16bit_reg                       ; LD_16bit_reg()

.ld_switch2_6            CP   6
                         JR   NZ, ld_switch2_8              ; case 6: ReportError(11) /* LD F, x */
                              JP   STDerr_ill_ident

.ld_switch2_8            CP   8                             ; case 8:  /* LD  I,A */
                         JR   NZ, ld_switch2_9
                              CALL Getsym
                              CP   sym_comma                     ; if ( Getsym() == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym                        ; Getsym()
                                   CALL CheckRegister8                ; if ( CheckRegister8() == 7 )
                                   CP   7
                                   JP   NZ, STDerr_ill_ident
                                        LD   BC,$47ED                      ; *codeptr++ = 237
                                        CALL WriteWord                     ; *codeptr++ = 71
                                        LD   HL, asm_pc
                                        JP   Add16bit_2                    ; PC += 2

.ld_switch2_9            CP   9                             ; case 9:  /* LD  R, */
                         JR   NZ, ld_switch2_default
                              CALL Getsym
                              CP   sym_comma                     ; if ( Getsym() == comma )
                              JP   NZ, STDerr_syntax
                                   CALL Getsym                        ; Getsym()
                                   CALL CheckRegister8                ; if ( CheckRegister8() == 7 )
                                   CP   7
                                   JP   NZ, STDerr_ill_ident
                                        LD   BC,$4FED                      ; *codeptr++ = 237
                                        CALL WriteWord                     ; *codeptr++ = 71
                                        LD   HL, asm_pc
                                        JP   Add16bit_2                    ; PC += 2
                                                            ; default:
.ld_switch2_default      CALL Getsym
                         CP   sym_comma                          ; if ( Getsym() == comma )
                         JP   NZ, STDerr_syntax
                              CALL Getsym
                              CP   sym_lparen                         ; if ( Getsym == lparen )
                              JR   NZ, ld_8bit_source
                                   JP   LD_r_8bit_indrct                   ; LD_r_8bit_indrct(destreg)  {C=destreg}
                                                                      ; else
.ld_8bit_source                    CALL CheckRegister8                     ; switch( sourcereg = CheckRegister8() )
                                   LD   B,A                                     ; {B=sourcereg}
                                   CP   6
                                   JR   NZ, ld_switch3_8                        ; case 6: Reporterror(11)
                                        JP   STDerr_ill_ident

.ld_switch3_8                      CP   8                                       ; case 8:
                                   JR   NZ, ld_switch3_9
                                        LD   A,C
                                        CP   7                                       ; if ( destreg == 7 )
                                        JP   NZ, STDerr_ill_ident
                                             LD   BC,$57ED                                ; /* LD  A,I */
                                             CALL WriteWord
                                             LD   HL,asm_pc
                                             JP   Add16bit_2                              ; PC += 2

.ld_switch3_9                      CP   9                                       ; case 9:
                                   JR   NZ, ld_switch3_notf
                                        LD   BC,$5FED                                ; /* LD A,R */
                                        CALL WriteWord
                                        LD   HL,asm_pc
                                        JP   Add16bit_2                              ; PC += 2

.ld_switch3_notf                   CP   -1                                      ; case -1: /* LD  r,n */
                                   JR   NZ, ld_switch3_default
                                        LD   A,C
                                        BIT  3,A                                     ; if ( destreg & 8) *codeptr++ = 221; ++PC
                                        CALL NZ, ix8bit                              ; LD IXL/H, n
                                        BIT  4,A                                     ; if ( destreg & 16) *codeptr++ = 253; ++PC
                                        CALL NZ, iy8bit                              ; LD IYL/H, n
                                        AND  7
                                        RLCA                                         ; destreg*8
                                        RLCA
                                        RLCA
                                        ADD  A,6
                                        LD   C,A
                                        CALL WriteByte                               ; *codeptr++ = destreg*8 + 6
                                        CALL ExprUnsigned8                           ; ExprUnsigned8(1)
                                        LD   HL,asm_pc
                                        JP   Add16bit_2                              ; PC += 2
                                                                                ; default:  /* LD  r,r */
.ld_switch3_default                OR   C
                                   AND  16+8
                                   CALL NZ, check_LD_ixiy8bit
                                        LD   A,C
                                        AND  7                                       ; remove IXL/H, IYL/H identifiers
                                        RLCA
                                        RLCA
                                        RLCA
                                        RES  3,B
                                        RES  4,B                                     ; remove IXL/H, IYL/H identifiers
                                        ADD  A,B
                                        ADD  A,64
                                        LD   C,A
                                        CALL WriteByte                               ; *codeptr++ = 64 + destreg*8 + sourcereg
                                        LD   HL, asm_pc
                                        JP   Add16bit_1


; **************************************************************************************************
;
.check_LD_ixiy8bit  CP   16+8
                    JP   Z, STDerr_syntax         ; LD IXL/H, IYL/H or LD IYL/H, IXL/H ... ILLEGAL!!!
                         BIT  3,A
                         JP   NZ, ix8bit               ; LD r,IXL/H or LD IXL/H,r
                         JP   Z, iy8bit                ; LD r,IYL/H or LD IYL/H,r


; **************************************************************************************************
;
; LD  (HL),r
; LD  (HL),n
;
.LD_hl8bit_indrct   LD   A,(sym)
                    CP   sym_comma                ; if ( sym == comma )
                    JP   NZ, STDerr_syntax
                         CALL Getsym                   ; Getsym()
                         CALL CheckRegister8           ; switch( sourcereg = CheckRegister8() )
                         CP   6                             ; case 6:
                         JP   Z, STDerr_ill_ident
                         CP   8                             ; case 8:
                         JP   Z, STDerr_ill_ident
                         CP   9                             ; case 9: reporterror(11)
                         JP   Z, STDerr_ill_ident
                         CP   -1                            ; case -1: /* LD  (HL),n */
                         JR   NZ, hl8bit_default
                              LD   C,54
                              CALL WriteByte                     ; *codeptr++ = 54
                              CALL ExprUnsigned8                 ; ExprUnsigned8(1)
                              LD   HL,asm_pc
                              JP   Add16bit_2                    ; PC += 2
                                                            ; default:
.hl8bit_default               ADD  A,112
                              LD   C,A
                              CALL WriteByte                     ; *codeptr++ = 112 + sourcereg
                              LD   HL,asm_pc
                              JP   Add16bit_1                    ; ++PC


; **************************************************************************************************
;
; LD  (IX+d),r
; LD  (IY+d),r
; LD  (IX+d),n
; LD  (IY+d),n
;
; IN C = destreg
;
.LD_index8bit_indrct
.store_index_opcode CALL WriteByte                ; *codeptr++ = Index register opcode (221/253)

                    CALL Flushbuffer              ; empty code buffer
                    PUSH HL
                    POP  IX                       ; IX = codeptr (points at start of buffer)
                    LD   C,54
                    CALL WriteByte                ; *codeptr++ = 54  /*preset 2. opcode */
                    CALL ExprSigned8
                    RET  C                        ; if ( !ExprSigned8(2) ) return
                    LD   A,(sym)
                    CP   sym_rparen               ; if ( sym != rparen ) Reporterror(1)
                    JP   NZ, STDerr_syntax
                    CALL Getsym
                    CP   sym_comma                ; if ( Getsym() == comma )
                    JP   NZ, STDerr_syntax
                         CALL Getsym                   ; Getsym()
                         CALL CheckRegister8           ; switch( sourcereg = CheckRegister8() )
                         CP   8                             ; case 8: reporterror(11)
                         JP   Z, STDerr_ill_ident
                         CP   9                             ; case 9: reporterror(11)
                         JP   Z, STDerr_ill_ident
                         CP   -1                            ; case -1:  /* LD (IX|IY+d),n */
                         JR   NZ, ld_index8bit_default
                              CALL ExprUnsigned8                 ; ExprUnsigned8(3)
                              LD   HL,asm_pc
                              JP   Add16bit_4                    ; PC += 4

.ld_index8bit_default         ADD  A,112
                              LD   (IX+0),A                 ; *opcodeptr = 112 + sourcereg  /* LD (IX|IY+d),r */
                              LD   HL,asm_pc
                              JP   Add16bit_3               ; PC += 3


; **************************************************************************************************
;
;    LD  r,(HL)
;    LD  r,(IX|IY+d)
;    LD  A,(nn)
;
; IN C = destreg
;
.LD_r_8bit_indrct   CALL IndirectRegisters        ; switch( sourcereg = IndirectRegisters() )
                    CP   2                             ; case 2:  /* LD r,(HL) */
                    JR   NZ, ld_r_8bit_case_5
                         LD   A,C
                         RLCA
                         RLCA
                         RLCA
                         ADD  A,64+6
                         LD   C,A
                         CALL WriteByte                     ; *codeptr++ = 64 + destreg*8 + 6
                         LD   HL,asm_pc
                         JP   Add16bit_1                    ; ++PC

.ld_r_8bit_case_5   CP   5                             ; case 5: /* LD r,(IX+d) */
                    JR   NZ,ld_r_8bit_case_6
                         LD   A,C
                         LD   C,221                         ; *codeptr++ = 221
                         JR   ld_r_8bit_case_6x

.ld_r_8bit_case_6   CP   6                             ; case 6: /* LD r,(IY+d) */
                    JR   NZ, ld_r_8bit_case_7
                         LD   A,C
                         LD   C,253                         ; *codeptr++ = 253
.ld_r_8bit_case_6x       RLCA
                         RLCA
                         RLCA
                         ADD  A,64+6
                         LD   B,A
                         CALL WriteWord                     ; *codeptr++ = 64 + destreg*8 + 6
                         CALL ExprSigned8                   ; ExprSigned8(2)
                         LD   HL,asm_pc
                         JP   Add16bit_3                    ; PC += 3

.ld_r_8bit_case_7   CP   7                             ; case 7: /* LD  A,(nn) */
                    JR   NZ, ld_r_8bit_case_0
                         LD   A,C
                         CP   7                             ; if ( destreg == 7 )
                         JP   NZ, STDerr_ill_ident
                              LD   C,58
                              CALL WriteByte                     ; *codeptr++ = 58
                              CALL ExprAddress                   ; ExprAddress(1)
                              LD   HL,asm_pc
                              JP   Add16bit_3                    ; PC += 3

.ld_r_8bit_case_0   CP   0                             ; case 0: /* LD A,(BC) */
                    JR   NZ,ld_r_8bit_case_1
                         LD   A,C
                         CP   7                             ; if ( destreg == 7 )
                         JP   NZ, STDerr_ill_ident
                              LD   C,10
                              CALL WriteByte                     ; *codeptr++ = 10
                              LD   HL,asm_pc
                              JP   Add16bit_1                    ; ++PC

.ld_r_8bit_case_1   CP   1                             ; case 1: /* LD A,(DE) */
                    JP   NZ, STDerr_ill_ident
                         LD   A,C
                         CP   7                             ; if ( destreg == 7 )
                         JP   NZ, STDerr_ill_ident
                              LD   C,26
                              CALL WriteByte                     ; *codeptr++ = 26
                              LD   HL,asm_pc
                              JP   Add16bit_1                    ; ++PC


; **************************************************************************************************
;
; IN: IX = pointer to start of indirect address expression
;
.LD_address_indrct  CALL ParseNumExpr             ; if ( (addrexpr = ParseNumExpr()) == NULL ) return
                    RET  C                        ; else
                    CALL RemovePfixList                ; RemovePfixList(addrexpr)
                    LD   A,(sym)
                    CP   sym_rparen               ; if ( sym != rparen )
                    JP   NZ, STDerr_syntax             ; reporterror(1)

                    CALL Getsym
                    CP   sym_comma                ; if ( Getsym() == comma )
                    JP   NZ, STDerr_syntax
                         CALL Getsym                   ; Getsym()
                         CALL CheckRegister16          ; switch( sourcereg = CheckRegister16() )
                         CP   2                             ; case 2:
                         JR   NZ, ld_addr_case_0                 ; LD (nn),HL
                              LD   C,34                          ; *codeptr++ = 34
                              CALL WriteByte
                              LD   HL,asm_pc
                              CALL Add16bit_1                    ; ++PC
                              JR   end_ld_addr

.ld_addr_case_0          CP   0                             ; case 0:  LD (nn),BC
                         JR   Z, ld_addr_case_3x
                         CP   1                             ; case 1:  LD (nn),DE
                         JR   Z, ld_addr_case_3x
                         CP   3                             ; case 3:  LD (nn),SP
                         JR   NZ, ld_addr_case_5
.ld_addr_case_3x              LD   C,237
                              RLCA
                              RLCA
                              RLCA
                              RLCA
                              ADD  A,67
                              LD   B,A                           ; *codeptr++ = 237
                              CALL WriteWord                     ; *codeptr++ = 67 + sourcereg*16
                              LD   HL, asm_pc
                              CALL Add16bit_2                    ; PC += 2
                              JR   end_ld_Addr

.ld_addr_case_5          CP   5                             ; case 5: LD (nn),IX
                         JR   NZ, ld_addr_case_6
                              LD   C,221                         ; *codeptr++ = 221
                              JR   ld_addr_case_6x
.ld_addr_case_6          CP   6                             ; case 6: LD (nn),IY
                         JR   NZ, ld_addr_case_notf
                              LD   C,253                         ; *codeptr++ = 253
.ld_addr_case_6x              LD   B,34                          ; *codeptr++ = 34
                              CALL WriteWord
                              LD   HL,asm_pc
                              CALL Add16bit_2
                              JR   end_ld_addr

.ld_addr_case_notf       CP   -1                            ; case -1:
                         JP   NZ, STDerr_ill_ident
                              CALL CheckRegister8
                              CP   7                             ; if ( CheckRegister8() == 7 )
                              JP   NZ, STDerr_ill_ident
                                   LD   C,50                          ; LD (nn),A
                                   CALL WriteByte                     ; *codeptr++ = 50
                                   LD   HL,asm_pc
                                   CALL Add16bit_1                    ; ++PC

.end_ld_addr        LD   (lineptr),IX             ; lineptr = startexpr
                    CALL Getsym                   ; Getsym()
                    CALL ExprAddress              ; ExprAddress(bytepos)
                    LD   HL,asm_pc
                    JP   Add16bit_2               ; PC += 2


; **************************************************************************************************
;
.LD_16bit_reg       CALL CheckRegister16          ; destreg = CheckRegister16
                    LD   C,A                      ; {preserve destreg in C}
                    CP   -1                       ; if ( destreg == -1 )
                    JP   Z, STDerr_syntax              ; reporterror(1)
                                                  ; else
                         CALL Getsym
                         CP   sym_comma                ; if ( Getsym() != comma )
                         JP   NZ,STDerr_syntax              ; reporterror(1)
                                                       ; else
                              CALL Getsym
                              CP   sym_lparen               ; if ( Getsym() == lparen )
                              JR   NZ, get_16bit_reg             ; switch(destreg)
                                   LD   A,C
                                   CP   4                             ; case 4:
                                   JP   Z, STDerr_ill_ident

                                   CP   2                             ; case 2: /* LD  HL,(nn)
                                   JR   NZ, ld_16bit_switch1_5
                                        LD   C, 42
                                        CALL WriteByte                     ; *codeptr++ = 42
                                        LD   HL, asm_pc
                                        CALL Add16bit_1                    ; ++PC
                                        JR   ld_16bit_parseadr1

.ld_16bit_switch1_5                CP   5                             ; case 5:
                                   JR   NZ, ld_16bit_switch1_6
                                        LD   C,221
                                        JR   ld_16bit_switch1_6x

.ld_16bit_switch1_6                CP   6                             ; case 6: /* LD  IX|IY,(nn) */
                                   JR   NZ, ld_16bit_switch1_default
                                        LD   C,253                         ; *codeptr++ = 253
.ld_16bit_switch1_6x                    LD   B,42
                                        CALL WriteWord                     ; *codeptr++ = 42
                                        LD   HL, asm_pc
                                        CALL Add16bit_2                    ; PC += 2
                                        JR   ld_16bit_parseadr1

.ld_16bit_switch1_default               RLCA                          ; default: /* LD  rr,(nn) */
                                        RLCA
                                        RLCA
                                        RLCA                               ; destreg*16
                                        ADD  A,75
                                        LD   C,237                         ; *codeptr++ = 237
                                        LD   B,A
                                        CALL WriteWord                     ; *codeptr++ = 75 + destreg*16
                                        LD   HL,asm_pc
                                        CALL Add16bit_2                    ; PC += 2

.ld_16bit_parseadr1                CALL Getsym                        ; Getsym()
                                   CALL ExprAddress                   ; ExprAddr(bytepos)
                                   LD   HL,asm_pc
                                   JP   Add16bit_2                    ; PC += 2
                                                            ; else
.get_16bit_reg                     CALL CheckRegister16          ; sourcereg = CheckRegister16()
                                   LD   B,A                      ; {sourcereg preserved in B}
                                   CP   -1                       ; switch(sorcereg)
                                   JR   NZ, ld_16bit_switch2_2        ; case -1:
                                        LD   A,C                           ; {get destreg}
                                        CP   4                             ; switch(destreg)  /* LD rr,nn */
                                        JP   Z, STDerr_ill_ident                ; case 4: reporterror(11) /* LD AF,nn !!!*/

                                        CP   5
                                        JP   NZ,ld_16bit_switch3_6              ; case 5:
                                             LD   C,221
                                             JR   ld_16bit_switch3_6x

.ld_16bit_switch3_6                     CP   6                                  ; case 6:
                                        JR   NZ, ld_16bit_switch3_default
                                             LD   C,253                              ; *codeptr++ = 253
.ld_16bit_switch3_6x                         LD   B,33
                                             CALL WriteWord                          ; *codeptr++ = 33
                                             LD   HL, asm_pc
                                             CALL Add16bit_2                         ; PC += 2
                                             JR   ld_16bit_parseadr3
                                                                                ; default
.ld_16bit_switch3_default                    RLCA
                                             RLCA
                                             RLCA
                                             RLCA
                                             ADD  A,1
                                             LD   C,A
                                             CALL WriteByte                          ; *codeptr++ = destreg*16 + 1
                                             LD   HL,asm_pc
                                             CALL Add16bit_1                         ; ++PC

.ld_16bit_parseadr3                     CALL ExprAddress                   ; ExprAddr(bytepos)
                                        LD   HL,asm_pc
                                        JP   Add16bit_2                    ; PC += 2

.ld_16bit_switch2_2                CP   2                             ; case 2: /* LD  SP,HL */
                                   JR   NZ, ld_16bit_switch2_5
                                        LD   A,C                           ; {get destreg}
                                        CP   3                             ; if ( destreg == 3 )
                                        JP   NZ, STDerr_ill_ident
                                             LD   C,249
                                             CALL WriteByte                     ; *codeptr++ = 249
                                             LD   HL,asm_pc
                                             JP   Add16bit_1
.ld_16bit_switch2_5                CP   5
                                   JP   NZ,ld_16bit_switch2_6         ; case 5: /* LD  SP,IX */
                                        LD   A,C
                                        LD   C,221
                                        JR   ld_16bit_switch2_6x

.ld_16bit_switch2_6                CP   6                             ; case 6: /* LD  SP,IY */
                                   JP   NZ, STDerr_ill_ident
                                        LD   A,C
                                        LD   C,253                         ; *codeptr++ = 253
.ld_16bit_switch2_6x                    CP   3                             ; if ( destreg == 3 )
                                        JP   NZ, STDerr_ill_ident
                                             LD   B,249
                                             CALL WriteWord                     ; *codeptr++ = 249
                                             LD   HL, asm_pc
                                             JP   Add16bit_2                    ; PC += 2


; ******************************************************************************
;
.ix8bit             PUSH BC
                    PUSH HL
                    LD   C,221
                    CALL WriteByte           ; *codeptr++ = 221
                    LD   HL,asm_pc
                    CALL Add16bit_1          ; ++PC
                    POP  HL
                    POP  BC
                    RET

; ******************************************************************************
;
.iy8bit             PUSH BC
                    PUSH HL
                    LD   C,253
                    CALL WriteByte           ; *codeptr++ = 253
                    LD   HL,asm_pc
                    CALL Add16bit_1          ; ++PC
                    POP  HL
                    POP  BC
                    RET

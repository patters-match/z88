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

     MODULE ParseIdent


; external procedures:
     LIB Bsearch

     XREF disp_ident
     XREF ReportError_STD                                   ; errors.asm
     XREF IFstatement                                       ; Z80pass.asm

     XREF CCF_fn, SCF_fn                                    ; z80instr.asm
     XREF DAA_fn, CPL_fn                                    ;
     XREF DI_fn, EI_fn                                      ;
     XREF RET_fn, EXX_fn                                    ;
     XREF NOP_fn, HALT_fn                                   ;
     XREF RLA_fn, RRA_fn, RRCA_fn, RLCA_fn                  ;
     XREF CPD_fn, CPDR_fn, CPIR_fn, CPI_fn                  ;
     XREF OUTD_fn, OTDR_fn, OTIR_fn, OUTI_fn                ;
     XREF LDD_fn, LDDR_fn, LDIR_fn, LDI_fn                  ;
     XREF IND_fn, INDR_fn, INIR_fn, INI_fn                  ;
     XREF NEG_fn, RETI_fn, RETN_fn                          ;
     XREF RLD_fn, RRD_fn                                    ;
     XREF EX_fn, OUT_fn, IN_fn, IM_fn, RST_fn               ;
     XREF CALLOZ_fn, FPP_fn                                 ;
     XREF PUSH_fn, POP_fn                                   ;

     XREF JR_fn, DJNZ_fn, JP_fn, CALL_fn                    ; jmpinstr.asm
     XREF LD_fn                                             ; ldinstr.asm

     XREF RES_fn, RL_fn, RLC_fn, RR_fn, RRC_fn              ; bitinstr.asm
     XREF BIT_fn, SET_fn, SLA_fn, SRA_fn, SRL_fn, SLL_fn    ;

     XREF ADD_fn, ADC_fn, SUB_fn, SBC_fn                    ; accinstr.asm
     XREF CP_fn, AND_fn, OR_fn, XOR_fn                      ;
     XREF INC_fn, DEC_fn                                    ;

     XREF DEFS_fn, ORG_fn, BINARY_fn, INCLUDE_fn            ; .asmdrctv.asm
     XREF DEFC_fn, DEFB_fn, DEFW_fn, DEFL_fn, DEFM_fn       ;
     XREF DEFGROUP_fn, DEFVARS_fn, DeclModule               ;
     XREF XDEF_fn, XREF_fn                                  ;
     XREF ELSE_fn, ENDIF_fn                                 ;
     XREF DEFINE_fn, LIB_fn, XLIB_fn                        ;

; global procedures (in this module):
     XDEF PrsIdent, SearchID


     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; *****************************************************************************************
;
; Find current identifier (Ident) in the Z80 command lookup table,
; if found, get the pointer to command function and execute...
;
; IN: A = interpret flag
;
; Registers changed after return:
;
;    ......../..IY  same
;    AFBCDEHL/IX..  different
;
.PrsIdent           PUSH AF                                 ; preserve interpret flag
                    CALL SearchID
                    JR   NZ, ident_not_found                ; if ( found )
                         INC  HL
                         INC  HL
                         LD   E,(HL)
                         INC  HL
                         LD   D,(HL)                             ; pointer to command function in HL
                         EX   DE,HL
                                                                 ; switch(index)
                         CP   34                                      ; case IF_statement:
                         JR   NZ, check_elsendif
                              POP  AF                                      ; {get interpret flag}
                              JP   IFstatement                             ; ifstatement(interpret)
                                                                           ; break

.check_elsendif          CP   28                                      ; case ELSE_statement:
                         JR   Z, case_elsendif
                         CP   29
                         JR   Z, case_elsendif                        ; case ENDIF_statement:
                         JR   default
.case_elsendif                POP  AF
                              JP   (HL)                                    ; execute ELSE/ENDIF statement...

.default                 POP  AF                                      ; default:
                         CP   Flag_ON                                      ; if ( interpret == ON )
                         RET  NZ
                         JP   (HL)                                              ; execute z80 assemble procedure...
                                                            ; else
.ident_not_found    LD   A, ERR_unkn_ident
                    CALL ReportError_STD
                    POP  AF                                      ; {remove local interpret flag}
                    RET


; ********************************************************************************************
;
.SearchID           PUSH IY                                 ; preserve poiner to base of z80asm variables
                    LD   IY,CMP_z80cmd                      ; compare routine for Bsearch
                    LD   HL,Z80cmdlookup                    ; base of lookup table
                    LD   DE,ident
                    CALL Bsearch                            ; find z80 command in lookup table
                    POP  IY
                    RET


; ********************************************************************************************
;
.CMP_z80cmd         LD   A,(HL)                 ; get pointer to string in array element
                    INC  HL
                    LD   H,(HL)
                    LD   L,A                    ; fetched pointer to string
                    LD   A,(DE)                 ; get length of identifier
                    LD   B,A                    ;
                    INC  DE                     ;
                    LD   C,(HL)                 ; get length of array identifier
                    PUSH BC
                    CP   C                      ; use shortest string
                    INC  HL
                    JR   C, compare_strings     ; A < C
                    LD   B,C                    ; A >= C
.compare_strings    LD   A,(DE)
                    CP   (HL)
                    JR   NZ,str_not_equal       ; identifier not equal...
                    INC  DE
                    INC  HL
                    DJNZ compare_strings
                    POP  BC
                    LD   A,B
                    CP   C                      ; set flags according to lengths
                    RET
.str_not_equal      POP  BC
                    RET


; ********************************************************************************************
;
; Z80 assembler command lookup table, format <identifier>, <procedure>
;
.Z80cmdlookup       DEFB 4,92                               ; size of element, no. of elements
                    DEFW ADC_mnem, ADC_fn                   ; 0
                    DEFW ADD_mnem, ADD_fn                   ; 1
                    DEFW AND_mnem, AND_fn                   ; 2
                    DEFW BINARY_mnem, BINARY_fn             ; 3
                    DEFW BIT_mnem, BIT_fn                   ; 4
                    DEFW CALL_mnem, CALL_fn                 ; 5
                    DEFW CALLOZ_mnem, CALLOZ_fn             ; 6
                    DEFW CCF_mnem, CCF_fn                   ; 7
                    DEFW CP_mnem, CP_fn                     ; 8
                    DEFW CPD_mnem, CPD_fn                   ; 9
                    DEFW CPDR_mnem, CPDR_fn                 ; 10
                    DEFW CPI_mnem, CPI_fn                   ; 11
                    DEFW CPIR_mnem, CPIR_fn                 ; 12
                    DEFW CPL_mnem, CPL_fn                   ; 13
                    DEFW DAA_mnem, DAA_fn                   ; 14
                    DEFW DEC_mnem, DEC_fn                   ; 15
                    DEFW DEFB_mnem, DEFB_fn                 ; 16
                    DEFW DEFC_mnem, DEFC_fn                 ; 17
                    DEFW DEFGROUP_mnem, DEFGROUP_fn         ; 18
                    DEFW DEFINE_mnem, DEFINE_fn             ; 19
                    DEFW DEFL_mnem, DEFL_fn                 ; 20
                    DEFW DEFM_mnem, DEFM_fn                 ; 21
                    DEFW DEFS_mnem, DEFS_fn                 ; 22
                    DEFW DEFVARS_mnem, DEFVARS_fn           ; 23
                    DEFW DEFW_mnem, DEFW_fn                 ; 24
                    DEFW DI_mnem, DI_fn                     ; 25
                    DEFW DJNZ_mnem, DJNZ_fn                 ; 26
                    DEFW EI_mnem, EI_fn                     ; 27
                    DEFW ELSE_mnem, ELSE_fn                 ; 28
                    DEFW ENDIF_mmnem, ENDIF_fn              ; 29
                    DEFW EX_mnem, EX_fn                     ; 30
                    DEFW EXX_mnem, EXX_fn                   ; 31
                    DEFW FPP_mnem, FPP_fn                   ; 32
                    DEFW HALT_mnem, HALT_fn                 ; 33
                    DEFW IF_mnem, 0                         ; 34
                    DEFW IM_mnem, IM_fn                     ; 35
                    DEFW IN_mnem, IN_fn
                    DEFW INC_mnem, INC_fn
                    DEFW INCLUDE_mnem, INCLUDE_fn
                    DEFW IND_mnem, IND_fn
                    DEFW INDR_mnem, INDR_fn
                    DEFW INI_mnem, INI_fn
                    DEFW INIR_mnem, INIR_fn
                    DEFW JP_mnem, JP_fn
                    DEFW JR_mnem, JR_fn
                    DEFW LD_mnem, LD_fn
                    DEFW LDD_mnem, LDD_fn
                    DEFW LDDR_mnem, LDDR_fn
                    DEFW LDI_mnem, LDI_fn
                    DEFW LDIR_mnem, LDIR_fn
                    DEFW LIB_mnem, LIB_fn
                    DEFW LSTOFF_mnem, LSTOFF_fn
                    DEFW LSTON_mnem, LSTON_fn
                    DEFW MODULE_mnem, DeclModule
                    DEFW NEG_mnem, NEG_fn
                    DEFW NOP_mnem, NOP_fn
                    DEFW OR_mnem, OR_fn
                    DEFW ORG_mnem, ORG_fn
                    DEFW OTDR_mnem, OTDR_fn
                    DEFW OTIR_mnem, OTIR_fn
                    DEFW OUT_mnem, OUT_fn
                    DEFW OUTD_mnem, OUTD_fn
                    DEFW OUTI_mnem, OUTI_fn
                    DEFW POP_mnem, POP_fn
                    DEFW PUSH_mnem, PUSH_fn
                    DEFW RES_mnem, RES_fn
                    DEFW RET_mnem, RET_fn
                    DEFW RETI_mnem, RETI_fn
                    DEFW RETN_mnem, RETN_fn
                    DEFW RL_mnem, RL_fn
                    DEFW RLA_mnem, RLA_fn
                    DEFW RLC_mnem, RLC_fn
                    DEFW RLCA_mnem, RLCA_fn
                    DEFW RLD_mnem, RLD_fn
                    DEFW RR_mnem, RR_fn
                    DEFW RRA_mnem, RRA_fn
                    DEFW RRC_mnem, RRC_fn
                    DEFW RRCA_mnem, RRCA_fn
                    DEFW RRD_mnem, RRD_fn
                    DEFW RST_mnem, RST_fn
                    DEFW SBC_mnem, SBC_fn
                    DEFW SCF_mnem, SCF_fn
                    DEFW SET_mnem, SET_fn
                    DEFW SLA_mnem, SLA_fn
                    DEFW SLL_mnem, SLL_fn
                    DEFW SRA_mnem, SRA_fn
                    DEFW SRL_mnem, SRL_fn
                    DEFW SUB_mnem, SUB_fn
                    DEFW XDEF_mnem, XDEF_fn
                    DEFW XLIB_mnem, XLIB_fn
                    DEFW XOR_mnem, XOR_fn
                    DEFW XREF_mnem, XREF_fn

.LSTON_fn
.LSTOFF_fn          RET

.ADC_mnem           DEFM 3, "ADC"
.ADD_mnem           DEFM 3, "ADD"
.AND_mnem           DEFM 3, "AND"
.BINARY_mnem        DEFM 6, "BINARY"
.BIT_mnem           DEFM 3, "BIT"
.CALL_mnem          DEFM 4, "CALL"
.CALLOZ_mnem        DEFM 7, "CALL_OZ"
.CCF_mnem           DEFM 3, "CCF"
.CP_mnem            DEFM 2, "CP"
.CPD_mnem           DEFM 3, "CPD"
.CPDR_mnem          DEFM 4, "CPDR"
.CPI_mnem           DEFM 3, "CPI"
.CPIR_mnem          DEFM 4, "CPIR"
.CPL_mnem           DEFM 3, "CPL"
.DAA_mnem           DEFM 3, "DAA"
.DEC_mnem           DEFM 3, "DEC"
.DEFB_mnem          DEFM 4, "DEFB"
.DEFC_mnem          DEFM 4, "DEFC"
.DEFGROUP_mnem      DEFM 8, "DEFGROUP"
.DEFINE_mnem        DEFM 6, "DEFINE"
.DEFL_mnem          DEFM 4, "DEFL"
.DEFM_mnem          DEFM 4, "DEFM"
.DEFS_mnem          DEFM 4, "DEFS"
.DEFVARS_mnem       DEFM 7, "DEFVARS"
.DEFW_mnem          DEFM 4, "DEFW"
.DI_mnem            DEFM 2, "DI"
.DJNZ_mnem          DEFM 4, "DJNZ"

.EI_mnem            DEFM 2, "EI"
.ELSE_mnem          DEFM 4, "ELSE"
.ENDIF_mmnem        DEFM 5, "ENDIF"
.EX_mnem            DEFM 2, "EX"
.EXX_mnem           DEFM 3, "EXX"
.FPP_mnem           DEFM 3, "FPP"
.HALT_mnem          DEFM 4, "HALT"
.IF_mnem            DEFM 2, "IF"
.IM_mnem            DEFM 2, "IM"
.IN_mnem            DEFM 2, "IN"
.INC_mnem           DEFM 3, "INC"
.INCLUDE_mnem       DEFM 7, "INCLUDE"
.IND_mnem           DEFM 3, "IND"
.INDR_mnem          DEFM 4, "INDR"
.INI_mnem           DEFM 3, "INI"
.INIR_mnem          DEFM 4, "INIR"
.JP_mnem            DEFM 2, "JP"
.JR_mnem            DEFM 2, "JR"
.LD_mnem            DEFM 2, "LD"
.LDD_mnem           DEFM 3, "LDD"
.LDDR_mnem          DEFM 4, "LDDR"
.LDI_mnem           DEFM 3, "LDI"
.LDIR_mnem          DEFM 4, "LDIR"
.LIB_mnem           DEFM 3, "LIB"
.LSTOFF_mnem        DEFM 6, "LSTOFF"
.LSTON_mnem         DEFM 5, "LSTON"
.MODULE_mnem        DEFM 6, "MODULE"
.NEG_mnem           DEFM 3, "NEG"
.NOP_mnem           DEFM 3, "NOP"
.OR_mnem            DEFM 2, "OR"
.ORG_mnem           DEFM 3, "ORG"
.OTDR_mnem          DEFM 4, "OTDR"
.OTIR_mnem          DEFM 4, "OTIR"
.OUT_mnem           DEFM 3, "OUT"
.OUTD_mnem          DEFM 4, "OUTD"
.OUTI_mnem          DEFM 4, "OUTI"
.POP_mnem           DEFM 3, "POP"
.PUSH_mnem          DEFM 4, "PUSH"
.RES_mnem           DEFM 3, "RES"
.RET_mnem           DEFM 3, "RET"
.RETI_mnem          DEFM 4, "RETI"
.RETN_mnem          DEFM 4, "RETN"
.RL_mnem            DEFM 2, "RL"
.RLA_mnem           DEFM 3, "RLA"
.RLC_mnem           DEFM 3, "RLC"
.RLCA_mnem          DEFM 4, "RLCA"
.RLD_mnem           DEFM 3, "RLD"
.RR_mnem            DEFM 2, "RR"
.RRA_mnem           DEFM 3, "RRA"
.RRC_mnem           DEFM 3, "RRC"
.RRCA_mnem          DEFM 4, "RRCA"
.RRD_mnem           DEFM 3, "RRD"
.RST_mnem           DEFM 3, "RST"
.SBC_mnem           DEFM 3, "SBC"
.SCF_mnem           DEFM 3, "SCF"
.SET_mnem           DEFM 3, "SET"
.SLA_mnem           DEFM 3, "SLA"
.SLL_mnem           DEFM 3, "SLL"
.SRA_mnem           DEFM 3, "SRA"
.SRL_mnem           DEFM 3, "SRL"
.SUB_mnem           DEFM 3, "SUB"
.XDEF_mnem          DEFM 4, "XDEF"
.XLIB_mnem          DEFM 4, "XLIB"
.XOR_mnem           DEFM 3, "XOR"
.XREF_mnem          DEFM 4, "XREF"

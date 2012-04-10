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
;***************************************************************************************************

    MODULE Disasm_mnemonics


    XDEF Rst_Mnemonic, LD_Mnemonic, Halt_Mnemonic, JP_Mnemonic
    XDEF CALL_Mnemonic, RET_Mnemonic, EXX_Mnemonic, POP_Mnemonic
    XDEF EI_Mnemonic, OUT_Mnemonic, IN_Mnemonic, DI_Mnemonic
    XDEF EX_Mnemonic, BC_Mnemonic, DE_Mnemonic, HL_Mnemonic, PUSH_mnemonic
    XDEF AF_Mnemonic, JR_Mnemonic, DJNZ_Mnemonic, NOP_Mnemonic
    XDEF ADD_Mnemonic, DEC_Mnemonic, INC_Mnemonic, SET_Mnemonic
    XDEF BIT_Mnemonic, RES_Mnemonic, RRD_Mnemonic, RLD_Mnemonic
    XDEF NEG_Mnemonic, IM_Mnemonic, RETI_Mnemonic, RETN_Mnemonic
    XDEF ADC_Mnemonic, SBC_Mnemonic, IX_Mnemonic, IY_Mnemonic
    XDEF OS_Mnemonic, GN_Mnemonic, DC_Mnemonic, FP_Mnemonic
    XDEF SP_Mnemonic

    XDEF Arithm_8bit_lookup, reg16_lookup, RotShift_Acc_lookup, RotShift_CB_lookup
    XDEF ld_block_lookup, cp_block_lookup, in_block_lookup, out_block_lookup
    XDEF reg8_Mnemonic, cc_table
    XDEF OS_2byte_lookup, OS_1byte_lookup, GN_lookup, DC_lookup, FP_lookup


.FP_lookup        DEFB 3,$21,$A2

.FP_Mnemonics     DEFW FP_AND_Mnemonic      ; table of ptr. to string
                  DEFW FP_IDV_Mnemonic
                  DEFW FP_EOR_Mnemonic
                  DEFW FP_MOD_Mnemonic
                  DEFW FP_OR_Mnemonic
                  DEFW FP_LEQ_Mnemonic
                  DEFW FP_NEQ_Mnemonic
                  DEFW FP_GEQ_Mnemonic
                  DEFW FP_LT_Mnemonic
                  DEFW FP_EQ_Mnemonic
                  DEFW FP_MUL_Mnemonic
                  DEFW FP_ADD_Mnemonic
                  DEFW FP_GT_Mnemonic
                  DEFW FP_SUB_Mnemonic
                  DEFW FP_PWR_Mnemonic
                  DEFW FP_DIV_Mnemonic
                  DEFW FP_ABS_Mnemonic
                  DEFW FP_ACS_Mnemonic
                  DEFW FP_ASN_Mnemonic
                  DEFW FP_ATN_Mnemonic
                  DEFW FP_COS_Mnemonic
                  DEFW FP_DEG_Mnemonic
                  DEFW FP_EXP_Mnemonic
                  DEFW FP_INT_Mnemonic
                  DEFW FP_LN_Mnemonic
                  DEFW FP_LOG_Mnemonic
                  DEFW FP_NOT_Mnemonic
                  DEFW FP_RAD_Mnemonic
                  DEFW FP_SGN_Mnemonic
                  DEFW FP_SIN_Mnemonic
                  DEFW FP_SQR_Mnemonic
                  DEFW FP_TAN_Mnemonic
                  DEFW FP_ZER_Mnemonic
                  DEFW FP_ONE_Mnemonic
                  DEFW FP_TRU_Mnemonic
                  DEFW FP_PI_Mnemonic
                  DEFW FP_VAL_Mnemonic
                  DEFW FP_STR_Mnemonic
                  DEFW FP_FIX_Mnemonic
                  DEFW FP_FLT_Mnemonic
                  DEFW FP_TST_Mnemonic
                  DEFW FP_CMP_Mnemonic
                  DEFW FP_NEG_Mnemonic
                  DEFW FP_BAS_Mnemonic
                  DEFW FP_END_Mnemonic


.DC_lookup        DEFB 2,$06,$24

.DC_Mnemonics     DEFW DC_INI_Mnemonic
                  DEFW DC_BYE_Mnemonic
                  DEFW DC_ENT_Mnemonic
                  DEFW DC_NAM_Mnemonic
                  DEFW DC_IN_Mnemonic
                  DEFW DC_OUT_Mnemonic
                  DEFW DC_PRT_Mnemonic
                  DEFW DC_ICL_Mnemonic
                  DEFW DC_NQ_Mnemonic
                  DEFW DC_SP_Mnemonic
                  DEFW DC_ALT_Mnemonic
                  DEFW DC_RBD_Mnemonic
                  DEFW DC_XIN_Mnemonic
                  DEFW DC_GEN_Mnemonic
                  DEFW DC_POL_Mnemonic
                  DEFW DC_SCN_Mnemonic
                  DEFW DC_END_Mnemonic


.GN_lookup        DEFB 2,$06,$7A

.GN_Mnemonics     DEFW GN_GDT_Mnemonic
                  DEFW GN_PDT_Mnemonic
                  DEFW GN_GTM_Mnemonic
                  DEFW GN_PTM_Mnemonic
                  DEFW GN_SDO_Mnemonic
                  DEFW GN_GDN_Mnemonic
                  DEFW GN_PDN_Mnemonic
                  DEFW GN_DIE_Mnemonic
                  DEFW GN_DEI_Mnemonic
                  DEFW GN_GMD_Mnemonic
                  DEFW GN_GMT_Mnemonic
                  DEFW GN_PMD_Mnemonic
                  DEFW GN_PMT_Mnemonic
                  DEFW GN_MSC_Mnemonic
                  DEFW GN_FLO_Mnemonic
                  DEFW GN_FLC_Mnemonic
                  DEFW GN_FLW_Mnemonic
                  DEFW GN_FLR_Mnemonic
                  DEFW GN_FLF_Mnemonic
                  DEFW GN_FPB_Mnemonic
                  DEFW GN_NLN_Mnemonic
                  DEFW GN_CLS_Mnemonic
                  DEFW GN_SKC_Mnemonic
                  DEFW GN_SKD_Mnemonic
                  DEFW GN_SKT_Mnemonic
                  DEFW GN_SIP_Mnemonic
                  DEFW GN_SOP_Mnemonic
                  DEFW GN_SOE_Mnemonic
                  DEFW GN_RBE_Mnemonic
                  DEFW GN_WBE_Mnemonic
                  DEFW GN_CME_Mnemonic
                  DEFW GN_XNX_Mnemonic
                  DEFW GN_XIN_Mnemonic
                  DEFW GN_XDL_Mnemonic
                  DEFW GN_ERR_Mnemonic
                  DEFW GN_ESP_Mnemonic
                  DEFW GN_FCM_Mnemonic
                  DEFW GN_FEX_Mnemonic
                  DEFW GN_OPW_Mnemonic
                  DEFW GN_WCL_Mnemonic
                  DEFW GN_WFN_Mnemonic
                  DEFW GN_PRS_Mnemonic
                  DEFW GN_PFS_Mnemonic
                  DEFW GN_WSM_Mnemonic
                  DEFW GN_ESA_Mnemonic
                  DEFW GN_OPF_Mnemonic
                  DEFW GN_CL_Mnemonic
                  DEFW GN_DEL_Mnemonic
                  DEFW GN_REN_Mnemonic
                  DEFW GN_AAB_Mnemonic
                  DEFW GN_FAB_Mnemonic
                  DEFW GN_LAB_Mnemonic
                  DEFW GN_UAB_Mnemonic
                  DEFW GN_ALP_Mnemonic
                  DEFW GN_M16_Mnemonic
                  DEFW GN_D16_Mnemonic
                  DEFW GN_M24_Mnemonic
                  DEFW GN_D24_Mnemonic
                  DEFW GN_WIN_Mnemonic                  
                  DEFW GN_END_Mnemonic


.OS_1byte_lookup  DEFB 3,$21,$93

.OS_1byte_Mnemonics
                  DEFW OS_BYE_Mnemonic
                  DEFW OS_PRT_Mnemonic
                  DEFW OS_OUT_Mnemonic
                  DEFW OS_IN_Mnemonic
                  DEFW OS_TIN_Mnemonic
                  DEFW OS_XIN_Mnemonic
                  DEFW OS_PUR_Mnemonic
                  DEFW OS_UGB_Mnemonic
                  DEFW OS_GB_Mnemonic
                  DEFW OS_PB_Mnemonic
                  DEFW OS_GBT_Mnemonic
                  DEFW OS_PBT_Mnemonic
                  DEFW OS_MV_Mnemonic
                  DEFW OS_FRM_Mnemonic
                  DEFW OS_FWM_Mnemonic
                  DEFW OS_MOP_Mnemonic
                  DEFW OS_MCL_Mnemonic
                  DEFW OS_MAL_Mnemonic
                  DEFW OS_MFR_Mnemonic
                  DEFW OS_MGB_Mnemonic
                  DEFW OS_MPB_Mnemonic
                  DEFW OS_BIX_Mnemonic
                  DEFW OS_BOX_Mnemonic
                  DEFW OS_NQ_Mnemonic
                  DEFW OS_SP_Mnemonic
                  DEFW OS_SR_Mnemonic
                  DEFW OS_ESC_Mnemonic
                  DEFW OS_ERC_Mnemonic
                  DEFW OS_ERH_Mnemonic
                  DEFW OS_UST_Mnemonic
                  DEFW OS_FN_Mnemonic
                  DEFW OS_WAIT_Mnemonic
                  DEFW OS_ALM_Mnemonic
                  DEFW OS_CLI_Mnemonic
                  DEFW OS_DOR_Mnemonic
                  DEFW OS_FC_Mnemonic
                  DEFW OS_SI_Mnemonic
                  DEFW OS_BOUT_Mnemonic
                  DEFW OS_POUT_Mnemonic
                  DEFW OS_1byte_END


.OS_2byte_lookup  DEFB 2,$C6,$FE

.OS_2byte_Mnemonics
                  DEFW OS_PLOZ_Mnemonic             ; C6
                  DEFW OS_FEP_Mnemonic              ; C8
                  DEFW OS_WTB_Mnemonic              ; CA
                  DEFW OS_WRT_Mnemonic              ; CC
                  DEFW OS_WSQ_Mnemonic              ; CE
                  DEFW OS_ISQ_Mnemonic              ; D0
                  DEFW OS_AXP_Mnemonic              ; D2
                  DEFW OS_SCI_Mnemonic              ; D4
                  DEFW OS_DLY_Mnemonic              ; D6
                  DEFW OS_BLP_Mnemonic              ; D8
                  DEFW OS_BDE_Mnemonic              ; DA
                  DEFW OS_BHL_Mnemonic              ; DC
                  DEFW OS_FTH_Mnemonic              ; DE
                  DEFW OS_VTH_Mnemonic              ; E0
                  DEFW OS_GTH_Mnemonic              ; E2
                  DEFW OS_REN_Mnemonic              ; E4
                  DEFW OS_DEL_Mnemonic              ; E6
                  DEFW OS_CL_Mnemonic               ; E8
                  DEFW OS_OP_Mnemonic               ; EA
                  DEFW OS_OFF_Mnemonic              ; EC
                  DEFW OS_USE_Mnemonic              ; EE
                  DEFW OS_EPR_Mnemonic              ; F0
                  DEFW OS_HT_Mnemonic               ; F2
                  DEFW OS_MAP_Mnemonic              ; F4
                  DEFW OS_EXIT_Mnemonic             ; F6
                  DEFW OS_STK_Mnemonic              ; F8
                  DEFW OS_ENT_Mnemonic              ; FA
                  DEFW OS_POLL_Mnemonic             ; FC
                  DEFW OS_DOM_Mnemonic              ; FE
                  DEFW OS_2byte_END


.cc_table         DEFW condition_0          ; lookup table for conditionals
                  DEFW condition_1
                  DEFW condition_2
                  DEFW condition_3
                  DEFW condition_4
                  DEFW condition_5
                  DEFW condition_6
                  DEFW condition_7

.Arithm_8bit_lookup
                  DEFW ADD_Mnemonic
                  DEFW ADC_Mnemonic
                  DEFW SUB_Mnemonic
                  DEFW SBC_Mnemonic
                  DEFW AND_Mnemonic
                  DEFW XOR_Mnemonic
                  DEFW OR_Mnemonic
                  DEFW CP_Mnemonic

.reg16_lookup     DEFW BC_Mnemonic
                  DEFW DE_Mnemonic
                  DEFW HL_Mnemonic
                  DEFW SP_Mnemonic

.RotShift_Acc_lookup
                  DEFW RLCA_Mnemonic
                  DEFW RRCA_Mnemonic
                  DEFW RLA_Mnemonic
                  DEFW RRA_Mnemonic
                  DEFW DAA_Mnemonic
                  DEFW CPL_Mnemonic
                  DEFW SCF_Mnemonic
                  DEFW CCF_Mnemonic

.RotShift_CB_lookup
                  DEFW RLC_Mnemonic
                  DEFW RRC_Mnemonic
                  DEFW RL_Mnemonic
                  DEFW RR_Mnemonic
                  DEFW SLA_Mnemonic
                  DEFW SRA_Mnemonic
                  DEFW SLL_Mnemonic
                  DEFW SRL_Mnemonic

.ld_block_lookup  DEFW LDI_Mnemonic
                  DEFW LDD_Mnemonic
                  DEFW LDIR_Mnemonic
                  DEFW LDDR_Mnemonic

.cp_block_lookup  DEFW CPI_Mnemonic
                  DEFW CPD_Mnemonic
                  DEFW CPIR_Mnemonic
                  DEFW CPDR_Mnemonic

.in_block_lookup  DEFW INI_Mnemonic
                  DEFW IND_Mnemonic
                  DEFW INIR_Mnemonic
                  DEFW INDR_Mnemonic

.out_block_lookup DEFW OUTI_Mnemonic
                  DEFW OUTD_Mnemonic
                  DEFW OTIR_Mnemonic
                  DEFW OTDR_Mnemonic

.ADC_Mnemonic     DEFM "ADC",0
.ADD_Mnemonic     DEFM "ADD",0
.AND_Mnemonic     DEFM "AND",0
.BIT_Mnemonic     DEFM "BIT",0
.CALL_Mnemonic    DEFM "CALL",0
.CCF_Mnemonic     DEFM "CCF",0
.CP_Mnemonic      DEFM "CP",0
.CPD_Mnemonic     DEFM "CPD",0
.CPDR_Mnemonic    DEFM "CPDR",0
.CPI_Mnemonic     DEFM "CPI",0
.CPIR_Mnemonic    DEFM "CPIR",0
.CPL_Mnemonic     DEFM "CPL",0
.DAA_Mnemonic     DEFM "DAA",0
.DEC_Mnemonic     DEFM "DEC",0
.DI_Mnemonic      DEFM "DI",0
.DJNZ_Mnemonic    DEFM "DJNZ",0
.EI_Mnemonic      DEFM "EI",0
.EX_Mnemonic      DEFM "EX",0
.EXX_Mnemonic     DEFM "EXX",0
.HALT_Mnemonic    DEFM "HALT",0
.IM_Mnemonic      DEFM "IM",0
.IN_Mnemonic      DEFM "IN",0
.INC_Mnemonic     DEFM "INC",0
.IND_Mnemonic     DEFM "IND",0
.INDR_Mnemonic    DEFM "INDR",0
.INI_Mnemonic     DEFM "INI",0
.INIR_Mnemonic    DEFM "INIR",0
.JP_Mnemonic      DEFM "JP",0
.JR_Mnemonic      DEFM "JR",0
.LD_Mnemonic      DEFM "LD",0
.LDD_Mnemonic     DEFM "LDD",0
.LDDR_Mnemonic    DEFM "LDDR",0
.LDI_Mnemonic     DEFM "LDI",0
.LDIR_Mnemonic    DEFM "LDIR",0
.NEG_Mnemonic     DEFM "NEG",0
.NOP_Mnemonic     DEFM "NOP",0
.OR_Mnemonic      DEFM "OR",0
.OTDR_Mnemonic    DEFM "OTDR",0
.OTIR_Mnemonic    DEFM "OTIR",0
.OUTD_Mnemonic    DEFM "OUTD",0
.OUTI_Mnemonic    DEFM "OUTI",0
.OUT_Mnemonic     DEFM "OUT",0
.POP_Mnemonic     DEFM "POP",0
.PUSH_Mnemonic    DEFM "PUSH",0
.RES_Mnemonic     DEFM "RES",0
.RET_Mnemonic     DEFM "RET",0
.RETI_Mnemonic    DEFM "RETI",0
.RETN_Mnemonic    DEFM "RETN",0
.RLA_Mnemonic     DEFM "RLA",0
.RL_Mnemonic      DEFM "RL",0
.RLCA_Mnemonic    DEFM "RLCA",0
.RLC_Mnemonic     DEFM "RLC",0
.RLD_Mnemonic     DEFM "RLD",0
.RRA_Mnemonic     DEFM "RRA",0
.RR_Mnemonic      DEFM "RR",0
.RRCA_Mnemonic    DEFM "RRCA",0
.RRC_Mnemonic     DEFM "RRC",0
.RRD_Mnemonic     DEFM "RRD",0
.RST_Mnemonic     DEFM "RST",0
.SBC_Mnemonic     DEFM "SBC",0
.SCF_Mnemonic     DEFM "SCF",0
.SET_Mnemonic     DEFM "SET",0
.SLA_Mnemonic     DEFM "SLA",0
.SRA_Mnemonic     DEFM "SRA",0
.SRL_Mnemonic     DEFM "SRL",0
.SLL_Mnemonic     DEFM "SLL",0
.SUB_Mnemonic     DEFM "SUB",0
.XOR_Mnemonic     DEFM "XOR",0

.BC_Mnemonic      DEFM "BC",0
.DE_Mnemonic      DEFM "DE",0
.HL_Mnemonic      DEFM "HL",0
.reg8_Mnemonic    DEFM "BCDEHLFA"
.IX_Mnemonic      DEFM "IX",0
.IY_Mnemonic      DEFM "IY",0
.SP_Mnemonic      DEFM "SP",0
.AF_Mnemonic      DEFM "AF",0

.condition_0      DEFM "NZ",0
.condition_1      DEFM "Z",0
.condition_2      DEFM "NC",0
.condition_3      DEFM "C",0
.condition_4      DEFM "PO",0
.condition_5      DEFM "PE",0
.condition_6      DEFM "P",0
.condition_7      DEFM "M",0

.OS_Mnemonic      DEFM "OS",0
.GN_Mnemonic      DEFM "GN",0
.DC_Mnemonic      DEFM "DC",0
.FP_Mnemonic      DEFM "FP",0

.FP_AND_Mnemonic  DEFM "AND"
.FP_IDV_Mnemonic  DEFM "IDV"
.FP_EOR_Mnemonic  DEFM "EOR"
.FP_MOD_Mnemonic  DEFM "MOD"
.FP_OR_Mnemonic   DEFM "OR"
.FP_LEQ_Mnemonic  DEFM "LEQ"
.FP_NEQ_Mnemonic  DEFM "NEQ"
.FP_GEQ_Mnemonic  DEFM "GEQ"
.FP_LT_Mnemonic   DEFM "LT"
.FP_EQ_Mnemonic   DEFM "EQ"
.FP_MUL_Mnemonic  DEFM "MUL"
.FP_ADD_Mnemonic  DEFM "ADD"
.FP_GT_Mnemonic   DEFM "GT"
.FP_SUB_Mnemonic  DEFM "SUB"
.FP_PWR_Mnemonic  DEFM "PWR"
.FP_DIV_Mnemonic  DEFM "DIV"
.FP_ABS_Mnemonic  DEFM "ABS"
.FP_ACS_Mnemonic  DEFM "ACS"
.FP_ASN_Mnemonic  DEFM "ASN"
.FP_ATN_Mnemonic  DEFM "ATN"
.FP_COS_Mnemonic  DEFM "COS"
.FP_DEG_Mnemonic  DEFM "DEG"
.FP_EXP_Mnemonic  DEFM "EXP"
.FP_INT_Mnemonic  DEFM "INT"
.FP_LN_Mnemonic   DEFM "LN"
.FP_LOG_Mnemonic  DEFM "LOG"
.FP_NOT_Mnemonic  DEFM "NOT"
.FP_RAD_Mnemonic  DEFM "RAD"
.FP_SGN_Mnemonic  DEFM "SGN"
.FP_SIN_Mnemonic  DEFM "SIN"
.FP_SQR_Mnemonic  DEFM "SQR"
.FP_TAN_Mnemonic  DEFM "TAN"
.FP_ZER_Mnemonic  DEFM "ZER"
.FP_ONE_Mnemonic  DEFM "ONE"
.FP_TRU_Mnemonic  DEFM "TRU"
.FP_PI_Mnemonic   DEFM "PI"
.FP_VAL_Mnemonic  DEFM "VAL"
.FP_STR_Mnemonic  DEFM "STR"
.FP_FIX_Mnemonic  DEFM "FIX"
.FP_FLT_Mnemonic  DEFM "FLT"
.FP_TST_Mnemonic  DEFM "TST"
.FP_CMP_Mnemonic  DEFM "CMP"
.FP_NEG_Mnemonic  DEFM "NEG"
.FP_BAS_Mnemonic  DEFM "BAS"
.FP_END_Mnemonic

.DC_INI_Mnemonic  DEFM "INI"
.DC_BYE_Mnemonic  DEFM "BYE"
.DC_ENT_Mnemonic  DEFM "ENT"
.DC_NAM_Mnemonic  DEFM "NAM"
.DC_IN_Mnemonic   DEFM "IN"
.DC_OUT_Mnemonic  DEFM "OUT"
.DC_PRT_Mnemonic  DEFM "PRT"
.DC_ICL_Mnemonic  DEFM "ICL"
.DC_NQ_Mnemonic   DEFM "NQ"
.DC_SP_Mnemonic   DEFM "NQ"
.DC_ALT_Mnemonic  DEFM "ALT"
.DC_RBD_Mnemonic  DEFM "RBD"
.DC_XIN_Mnemonic  DEFM "XIN"
.DC_GEN_Mnemonic  DEFM "GEN"
.DC_POL_Mnemonic  DEFM "POL"
.DC_SCN_Mnemonic  DEFM "SCN"
.DC_END_Mnemonic

.GN_GDT_Mnemonic  DEFM "GDT"
.GN_PDT_Mnemonic  DEFM "PDT"
.GN_GTM_Mnemonic  DEFM "GTM"
.GN_PTM_Mnemonic  DEFM "PTM"
.GN_SDO_Mnemonic  DEFM "SDO"
.GN_GDN_Mnemonic  DEFM "GDN"
.GN_PDN_Mnemonic  DEFM "PDN"
.GN_DIE_Mnemonic  DEFM "DIE"
.GN_DEI_Mnemonic  DEFM "DEI"
.GN_GMD_Mnemonic  DEFM "GMD"
.GN_GMT_Mnemonic  DEFM "GMT"
.GN_PMD_Mnemonic  DEFM "PMD"
.GN_PMT_Mnemonic  DEFM "PMT"
.GN_MSC_Mnemonic  DEFM "MSC"
.GN_FLO_Mnemonic  DEFM "FLO"
.GN_FLC_Mnemonic  DEFM "FLC"
.GN_FLW_Mnemonic  DEFM "FLW"
.GN_FLR_Mnemonic  DEFM "FLR"
.GN_FLF_Mnemonic  DEFM "FLF"
.GN_FPB_Mnemonic  DEFM "FPB"
.GN_NLN_Mnemonic  DEFM "NLN"
.GN_CLS_Mnemonic  DEFM "CLS"
.GN_SKC_Mnemonic  DEFM "SKC"
.GN_SKD_Mnemonic  DEFM "SKD"
.GN_SKT_Mnemonic  DEFM "SKT"
.GN_SIP_Mnemonic  DEFM "SIP"
.GN_SOP_Mnemonic  DEFM "SOP"
.GN_SOE_Mnemonic  DEFM "SOE"
.GN_RBE_Mnemonic  DEFM "RBE"
.GN_WBE_Mnemonic  DEFM "WBE"
.GN_CME_Mnemonic  DEFM "CME"
.GN_XNX_Mnemonic  DEFM "XNX"
.GN_XIN_Mnemonic  DEFM "XIN"
.GN_XDL_Mnemonic  DEFM "XDL"
.GN_ERR_Mnemonic  DEFM "ERR"
.GN_ESP_Mnemonic  DEFM "ESP"
.GN_FCM_Mnemonic  DEFM "FCM"
.GN_FEX_Mnemonic  DEFM "FEX"
.GN_OPW_Mnemonic  DEFM "OPW"
.GN_WCL_Mnemonic  DEFM "WCL"
.GN_WFN_Mnemonic  DEFM "WFN"
.GN_PRS_Mnemonic  DEFM "PRS"
.GN_PFS_Mnemonic  DEFM "PFS"
.GN_WSM_Mnemonic  DEFM "WSM"
.GN_ESA_Mnemonic  DEFM "ESA"
.GN_OPF_Mnemonic  DEFM "OPF"
.GN_CL_Mnemonic   DEFM "CL"
.GN_DEL_Mnemonic  DEFM "DEL"
.GN_REN_Mnemonic  DEFM "REN"
.GN_AAB_Mnemonic  DEFM "AAB"
.GN_FAB_Mnemonic  DEFM "FAB"
.GN_LAB_Mnemonic  DEFM "LAB"
.GN_UAB_Mnemonic  DEFM "UAB"
.GN_ALP_Mnemonic  DEFM "ALP"
.GN_M16_Mnemonic  DEFM "M16"
.GN_D16_Mnemonic  DEFM "D16"
.GN_M24_Mnemonic  DEFM "M24"
.GN_D24_Mnemonic  DEFM "D24"
.GN_WIN_Mnemonic  DEFM "WIN"
.GN_END_Mnemonic

.OS_BYE_Mnemonic  DEFM "BYE"
.OS_PRT_Mnemonic  DEFM "PRT"
.OS_OUT_Mnemonic  DEFM "OUT"
.OS_IN_Mnemonic   DEFM "IN"
.OS_TIN_Mnemonic  DEFM "TIN"
.OS_XIN_Mnemonic  DEFM "XIN"
.OS_PUR_Mnemonic  DEFM "PUR"
.OS_UGB_Mnemonic  DEFM "UGB"
.OS_GB_Mnemonic   DEFM "GB"
.OS_PB_Mnemonic   DEFM "PB"
.OS_GBT_Mnemonic  DEFM "GBT"
.OS_PBT_Mnemonic  DEFM "PBT"
.OS_MV_Mnemonic   DEFM "MV"
.OS_FRM_Mnemonic  DEFM "FRM"
.OS_FWM_Mnemonic  DEFM "FWM"
.OS_MOP_Mnemonic  DEFM "MOP"
.OS_MCL_Mnemonic  DEFM "MCL"
.OS_MAL_Mnemonic  DEFM "MAL"
.OS_MFR_Mnemonic  DEFM "MFR"
.OS_MGB_Mnemonic  DEFM "MGB"
.OS_MPB_Mnemonic  DEFM "MPB"
.OS_BIX_Mnemonic  DEFM "BIX"
.OS_BOX_Mnemonic  DEFM "BOX"
.OS_NQ_Mnemonic   DEFM "NQ"
.OS_SP_Mnemonic   DEFM "SP"
.OS_SR_Mnemonic   DEFM "SR"
.OS_ESC_Mnemonic  DEFM "ESC"
.OS_ERC_Mnemonic  DEFM "ERC"
.OS_ERH_Mnemonic  DEFM "ERH"
.OS_UST_Mnemonic  DEFM "UST"
.OS_FN_Mnemonic   DEFM "FN"
.OS_WAIT_Mnemonic DEFM "WAIT"
.OS_ALM_Mnemonic  DEFM "ALM"
.OS_CLI_Mnemonic  DEFM "CLI"
.OS_DOR_Mnemonic  DEFM "DOR"
.OS_FC_Mnemonic   DEFM "FC"
.OS_SI_Mnemonic   DEFM "SI"
.OS_BOUT_Mnemonic DEFM "BOUT"
.OS_POUT_Mnemonic DEFM "POUT"
.OS_1byte_END

.OS_PLOZ_Mnemonic DEFM "PLOZ"
.OS_FEP_Mnemonic  DEFM "FEP"
.OS_WTB_Mnemonic  DEFM "WTB"
.OS_WRT_Mnemonic  DEFM "WRT"
.OS_WSQ_Mnemonic  DEFM "WSQ"
.OS_ISQ_Mnemonic  DEFM "ISQ"
.OS_AXP_Mnemonic  DEFM "AXP"
.OS_SCI_Mnemonic  DEFM "SCI"
.OS_DLY_Mnemonic  DEFM "DLY"
.OS_BLP_Mnemonic  DEFM "BLP"
.OS_BDE_Mnemonic  DEFM "BDE"
.OS_BHL_Mnemonic  DEFM "BHL"
.OS_FTH_Mnemonic  DEFM "FTH"
.OS_VTH_Mnemonic  DEFM "VTH"
.OS_GTH_Mnemonic  DEFM "GTH"
.OS_REN_Mnemonic  DEFM "REN"
.OS_DEL_Mnemonic  DEFM "DEL"
.OS_CL_Mnemonic   DEFM "CL"
.OS_OP_Mnemonic   DEFM "OP"
.OS_OFF_Mnemonic  DEFM "OFF"
.OS_USE_Mnemonic  DEFM "USE"
.OS_EPR_Mnemonic  DEFM "EPR"
.OS_HT_Mnemonic   DEFM "HT"
.OS_MAP_Mnemonic  DEFM "MAP"
.OS_EXIT_Mnemonic DEFM "EXIT"
.OS_STK_Mnemonic  DEFM "STK"
.OS_ENT_Mnemonic  DEFM "ENT"
.OS_POLL_Mnemonic DEFM "POLL"
.OS_DOM_Mnemonic  DEFM "DOM"
.OS_2byte_END

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
                  DEFW OR_Mnemonic
                  DEFW FP_LEQ_Mnemonic
                  DEFW FP_NEQ_Mnemonic
                  DEFW FP_GEQ_Mnemonic
                  DEFW FP_LT_Mnemonic
                  DEFW FP_EQ_Mnemonic
                  DEFW FP_MUL_Mnemonic
                  DEFW ADD_Mnemonic
                  DEFW FP_GT_Mnemonic
                  DEFW SUB_Mnemonic
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


.DC_lookup        DEFB 2,$06,$24

.DC_Mnemonics     DEFW INI_Mnemonic
                  DEFW DC_BYE_Mnemonic
                  DEFW DC_ENT_Mnemonic
                  DEFW DC_NAM_Mnemonic
                  DEFW IN_Mnemonic
                  DEFW OUT_Mnemonic
                  DEFW DC_PRT_Mnemonic
                  DEFW DC_ICL_Mnemonic
                  DEFW DC_NQ_Mnemonic
                  DEFW SP_Mnemonic
                  DEFW DC_ALT_Mnemonic
                  DEFW DC_RBD_Mnemonic
                  DEFW DC_XIN_Mnemonic
                  DEFW DC_GEN_Mnemonic
                  DEFW DC_POL_Mnemonic
                  DEFW DC_SCN_Mnemonic


.GN_lookup        DEFB 2,$06,$78

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
                  DEFW DC_XIN_Mnemonic
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


.OS_1byte_lookup  DEFB 3,$21,$8D

.OS_1byte_Mnemonics
                  DEFW DC_BYE_Mnemonic
                  DEFW DC_PRT_Mnemonic
                  DEFW OUT_Mnemonic
                  DEFW IN_Mnemonic
                  DEFW OS_TIN_Mnemonic
                  DEFW DC_XIN_Mnemonic
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
                  DEFW DC_NQ_Mnemonic
                  DEFW SP_Mnemonic
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


.OS_2byte_lookup  DEFB 2,$CC,$FE

.OS_2byte_Mnemonics
                  DEFW OS_WRT_Mnemonic
                  DEFW OS_WTB_Mnemonic
                  DEFW OS_ISQ_Mnemonic
                  DEFW OS_AXP_Mnemonic
                  DEFW OS_SCI_Mnemonic
                  DEFW OS_DLY_Mnemonic
                  DEFW OS_BLP_Mnemonic
                  DEFW OS_BDE_Mnemonic
                  DEFW OS_BHL_Mnemonic
                  DEFW OS_FTH_Mnemonic
                  DEFW OS_VTH_Mnemonic
                  DEFW OS_GTH_Mnemonic
                  DEFW GN_REN_Mnemonic
                  DEFW GN_DEL_Mnemonic
                  DEFW GN_CL_Mnemonic
                  DEFW OS_OP_Mnemonic
                  DEFW OS_OFF_Mnemonic
                  DEFW OS_USE_Mnemonic
                  DEFW OS_EPR_Mnemonic
                  DEFW OS_HT_Mnemonic
                  DEFW OS_MAP_Mnemonic
                  DEFW OS_EXIT_Mnemonic
                  DEFW OS_STK_Mnemonic
                  DEFW DC_ENT_Mnemonic
                  DEFW OS_POLL_Mnemonic
                  DEFW OS_DOM_Mnemonic


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
.reg8_Mnemonic    DEFM "BCDEHLFA",0
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

.FP_AND_Mnemonic  DEFM "AND",0
.FP_IDV_Mnemonic  DEFM "IDV",0
.FP_EOR_Mnemonic  DEFM "EOR",0
.FP_MOD_Mnemonic  DEFM "MOD",0
.FP_LEQ_Mnemonic  DEFM "LEQ",0
.FP_NEQ_Mnemonic  DEFM "NEQ",0
.FP_GEQ_Mnemonic  DEFM "GEQ",0
.FP_LT_Mnemonic   DEFM "LT",0
.FP_EQ_Mnemonic   DEFM "EQ",0
.FP_MUL_Mnemonic  DEFM "MUL",0
.FP_GT_Mnemonic   DEFM "GT",0
.FP_PWR_Mnemonic  DEFM "PWR",0
.FP_DIV_Mnemonic  DEFM "DIV",0
.FP_ABS_Mnemonic  DEFM "ABS",0
.FP_ACS_Mnemonic  DEFM "ACS",0
.FP_ASN_Mnemonic  DEFM "ASN",0
.FP_ATN_Mnemonic  DEFM "ATN",0
.FP_COS_Mnemonic  DEFM "COS",0
.FP_DEG_Mnemonic  DEFM "DEG",0
.FP_EXP_Mnemonic  DEFM "EXP",0
.FP_INT_Mnemonic  DEFM "INT",0
.FP_LN_Mnemonic   DEFM "LN",0
.FP_LOG_Mnemonic  DEFM "LOG",0
.FP_NOT_Mnemonic  DEFM "NOT",0
.FP_RAD_Mnemonic  DEFM "RAD",0
.FP_SGN_Mnemonic  DEFM "SGN",0
.FP_SIN_Mnemonic  DEFM "SIN",0
.FP_SQR_Mnemonic  DEFM "SQR",0
.FP_TAN_Mnemonic  DEFM "TAN",0
.FP_ZER_Mnemonic  DEFM "ZER",0
.FP_ONE_Mnemonic  DEFM "ONE",0
.FP_TRU_Mnemonic  DEFM "TRU",0
.FP_PI_Mnemonic   DEFM "PI",0
.FP_VAL_Mnemonic  DEFM "VAL",0
.FP_STR_Mnemonic  DEFM "STR",0
.FP_FIX_Mnemonic  DEFM "FIX",0
.FP_FLT_Mnemonic  DEFM "FLT",0
.FP_TST_Mnemonic  DEFM "TST",0
.FP_CMP_Mnemonic  DEFM "CMP",0
.FP_NEG_Mnemonic  DEFM "NEG",0
.FP_BAS_Mnemonic  DEFM "BAS",0

.DC_ALT_Mnemonic  DEFM "ALT",0
.DC_BYE_Mnemonic  DEFM "BYE",0
.DC_ENT_Mnemonic  DEFM "ENT",0
.DC_GEN_Mnemonic  DEFM "GEN",0
.DC_ICL_Mnemonic  DEFM "ICL",0
.DC_NAM_Mnemonic  DEFM "NAM",0
.DC_NQ_Mnemonic   DEFM "NQ",0
.DC_POL_Mnemonic  DEFM "POL",0
.DC_PRT_Mnemonic  DEFM "PRT",0
.DC_RBD_Mnemonic  DEFM "RBD",0
.DC_SCN_Mnemonic  DEFM "SCN",0
.DC_XIN_Mnemonic  DEFM "XIN",0

.GN_AAB_Mnemonic  DEFM "AAB",0
.GN_ALP_Mnemonic  DEFM "ALP",0
.GN_CL_Mnemonic   DEFM "CL",0
.GN_CLS_Mnemonic  DEFM "CLS",0
.GN_CME_Mnemonic  DEFM "CME",0
.GN_D16_Mnemonic  DEFM "D16",0
.GN_D24_Mnemonic  DEFM "D24",0
.GN_DEI_Mnemonic  DEFM "DEI",0
.GN_DEL_Mnemonic  DEFM "DEL",0
.GN_DIE_Mnemonic  DEFM "DIE",0
.GN_ERR_Mnemonic  DEFM "ERR",0
.GN_ESA_Mnemonic  DEFM "ESA",0
.GN_ESP_Mnemonic  DEFM "ESP",0
.GN_FAB_Mnemonic  DEFM "FAB",0
.GN_FCM_Mnemonic  DEFM "FCM",0
.GN_FEX_Mnemonic  DEFM "FEX",0
.GN_FLC_Mnemonic  DEFM "FLC",0
.GN_FLF_Mnemonic  DEFM "FLF",0
.GN_FLO_Mnemonic  DEFM "FLO",0
.GN_FLR_Mnemonic  DEFM "FLR",0
.GN_FLW_Mnemonic  DEFM "FLW",0
.GN_FPB_Mnemonic  DEFM "FPB",0
.GN_GDN_Mnemonic  DEFM "GDN",0
.GN_GDT_Mnemonic  DEFM "GDT",0
.GN_GMD_Mnemonic  DEFM "GMD",0
.GN_GMT_Mnemonic  DEFM "GMT",0
.GN_GTM_Mnemonic  DEFM "GTM",0
.GN_LAB_Mnemonic  DEFM "LAB",0
.GN_M16_Mnemonic  DEFM "M16",0
.GN_M24_Mnemonic  DEFM "M24",0
.GN_MSC_Mnemonic  DEFM "MSC",0
.GN_NLN_Mnemonic  DEFM "NLN",0
.GN_OPF_Mnemonic  DEFM "OPF",0
.GN_OPW_Mnemonic  DEFM "OPW",0
.GN_PDN_Mnemonic  DEFM "PDN",0
.GN_PDT_Mnemonic  DEFM "PDT",0
.GN_PFS_Mnemonic  DEFM "PFS",0
.GN_PMD_Mnemonic  DEFM "PMD",0
.GN_PMT_Mnemonic  DEFM "PMT",0
.GN_PRS_Mnemonic  DEFM "PRS",0
.GN_PTM_Mnemonic  DEFM "PTM",0
.GN_RBE_Mnemonic  DEFM "RBE",0
.GN_REN_Mnemonic  DEFM "REN",0
.GN_SDO_Mnemonic  DEFM "SDO",0
.GN_SIP_Mnemonic  DEFM "SIP",0
.GN_SKC_Mnemonic  DEFM "SKC",0
.GN_SKD_Mnemonic  DEFM "SKD",0
.GN_SKT_Mnemonic  DEFM "SKT",0
.GN_SOE_Mnemonic  DEFM "SOE",0
.GN_SOP_Mnemonic  DEFM "SOP",0
.GN_UAB_Mnemonic  DEFM "UAB",0
.GN_WBE_Mnemonic  DEFM "WBE",0
.GN_WCL_Mnemonic  DEFM "WCL",0
.GN_WFN_Mnemonic  DEFM "WFN",0
.GN_WSM_Mnemonic  DEFM "WSM",0
.GN_XDL_Mnemonic  DEFM "XDL",0
.GN_XNX_Mnemonic  DEFM "XNX",0

.OS_ALM_Mnemonic  DEFM "ALM",0
.OS_BIX_Mnemonic  DEFM "BIX",0
.OS_BOX_Mnemonic  DEFM "BOX",0
.OS_CLI_Mnemonic  DEFM "CLI",0
.OS_DOR_Mnemonic  DEFM "DOR",0
.OS_ERC_Mnemonic  DEFM "ERC",0
.OS_ERH_Mnemonic  DEFM "ERH",0
.OS_ESC_Mnemonic  DEFM "ESC",0
.OS_FC_Mnemonic   DEFM "FC",0
.OS_FN_Mnemonic   DEFM "FN",0
.OS_FRM_Mnemonic  DEFM "FRM",0
.OS_FWM_Mnemonic  DEFM "FWM",0
.OS_GB_Mnemonic   DEFM "GB",0
.OS_GBT_Mnemonic  DEFM "GBT",0
.OS_MAL_Mnemonic  DEFM "MAL",0
.OS_MCL_Mnemonic  DEFM "MCL",0
.OS_MFR_Mnemonic  DEFM "MFR",0
.OS_MGB_Mnemonic  DEFM "MGB",0
.OS_MOP_Mnemonic  DEFM "MOP",0
.OS_MPB_Mnemonic  DEFM "MPB",0
.OS_MV_Mnemonic   DEFM "MV",0
.OS_PB_Mnemonic   DEFM "PB",0
.OS_PBT_Mnemonic  DEFM "PBT",0
.OS_PUR_Mnemonic  DEFM "PUR",0
.OS_SI_Mnemonic   DEFM "SI",0
.OS_SR_Mnemonic   DEFM "SR",0
.OS_TIN_Mnemonic  DEFM "TIN",0
.OS_UGB_Mnemonic  DEFM 0
.OS_UST_Mnemonic  DEFM "UST",0
.OS_WAIT_Mnemonic DEFM "WAIT",0
.OS_AXP_Mnemonic  DEFM "AXP",0
.OS_BDE_Mnemonic  DEFM "BDE",0
.OS_BHL_Mnemonic  DEFM "BHL",0
.OS_BLP_Mnemonic  DEFM "BLP",0
.OS_DLY_Mnemonic  DEFM "DLY",0
.OS_DOM_Mnemonic  DEFM "DOM",0
.OS_EPR_Mnemonic  DEFM "EPR",0
.OS_EXIT_Mnemonic DEFM "EXIT",0
.OS_FTH_Mnemonic  DEFM "FTH",0
.OS_GTH_Mnemonic  DEFM "GTH",0
.OS_HT_Mnemonic   DEFM "HT",0
.OS_ISQ_Mnemonic  DEFM "ISQ",0
.OS_MAP_Mnemonic  DEFM "MAP",0
.OS_OFF_Mnemonic  DEFM "OFF",0
.OS_OP_Mnemonic   DEFM "OP",0
.OS_POLL_Mnemonic DEFM "POLL",0
.OS_SCI_Mnemonic  DEFM "SCI",0
.OS_STK_Mnemonic  DEFM "STK",0
.OS_USE_Mnemonic  DEFM "USE",0
.OS_VTH_Mnemonic  DEFM "VTH",0
.OS_WRT_Mnemonic  DEFM "WRT",0
.OS_WTB_Mnemonic  DEFM "WTB",0

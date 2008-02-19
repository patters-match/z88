
/*
    DDDDDDDDDDDDD            ZZZZZZZZZZZZZZZZ
    DDDDDDDDDDDDDDD        ZZZZZZZZZZZZZZZZ
    DDDD         DDDD               ZZZZZ
    DDDD         DDDD             ZZZZZ
    DDDD         DDDD           ZZZZZ             AAAAAA         SSSSSSSSSSS   MMMM       MMMM
    DDDD         DDDD         ZZZZZ              AAAAAAAA      SSSS            MMMMMM   MMMMMM
    DDDD         DDDD       ZZZZZ               AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
    DDDD         DDDD     ZZZZZ                AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
    DDDDDDDDDDDDDDD     ZZZZZZZZZZZZZZZZZ     AAAA      AAAA           SSSSS   MMMM       MMMM
    DDDDDDDDDDDDD     ZZZZZZZZZZZZZZZZZ      AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM

Copyright (C) Gunther Strube, 1996-2008
*/

/* $Id$ */

typedef struct opcode {                 	/* base structure for Z80 mnemonic */
        char                    *name;
        signed char             args;           /* no. of instruction arguments */
        enum files              includefile;    /* generate INCLUDE file directive */
} opc;

/* main instruction opcodes */
#define JP_opcode 0xC3
#define JP_c_opcode 0xDA
#define JP_nc_opcode 0xD2
#define JP_z_opcode 0xCA
#define JP_nz_opcode 0xC2
#define JP_m_opcode 0xFA
#define JP_p_opcode 0xF2
#define JP_pe_opcode 0xEA
#define JP_po_opcode 0xE2
#define JP_hl_opcode 0xE9

#define CALL_opcode 0xCD
#define CALL_c_opcode 0xDC
#define CALL_nc_opcode 0xD4
#define CALL_z_opcode 0xCC
#define CALL_nz_opcode 0xC4
#define CALL_m_opcode 0xFC
#define CALL_p_opcode 0xF4
#define CALL_pe_opcode 0xEC
#define CALL_po_opcode 0xE4

#define JR_opcode 0x18
#define JR_nz_opcode 0x20
#define JR_z_opcode 0x28
#define JR_c_opcode 0x38
#define JR_nc_opcode 0x30
#define DJNZ_opcode 0x10

#define RET_opcode 0xC9

#define LD_bc_opcode 0x01
#define LD_de_opcode 0x11
#define LD_hl_opcode 0x21
#define LD_sp_opcode 0x31
#define LD_hl_nn_opcode 0x2A
#define LD_nn_hl_opcode 0x22

#define LD_a_nn_opcode 0x3A
#define LD_nn_a_opcode 0x32

/* IX/IY instructions */
#define JP_ix_opcode 0xE9
#define JP_iy_opcode 0xE9
#define LD_ix_opcode 0x21
#define LD_iy_opcode 0x21
#define LD_ix_nn_opcode 0x2A
#define LD_iy_nn_opcode 0x2A
#define LD_nn_ix_opcode 0x22
#define LD_nn_iy_opcode 0x22

/* ED instructions */
#define RETI_opcode 0x4D
#define RETN_opcode 0x45
#define LD_bc_nn_opcode 0x4B
#define LD_de_nn_opcode 0x5B
#define LD_hl_nn_opcode2 0x6B
#define LD_sp_nn_opcode 0x7B
#define LD_nn_bc_opcode 0x43
#define LD_nn_de_opcode 0x53
#define LD_nn_hl_opcode2 0x63
#define LD_nn_sp_opcode 0x73

#define DC_BYE 0x08
#define DC_ENT 0x0A
#define OS_BYE 0x21

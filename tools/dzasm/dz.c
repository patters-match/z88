
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

Copyright (C) Gunther Strube, InterLogic 1996-99
*/

/* $Id$ */

/*
 * Z88 (Z80) Disassembler. All Z88 OZ manifests	are recognized.
 * Disassembler	output is prepared for assembly.
 *
 * All 'undocumented' instructions are recognised, eg. SLL or LD  ixh,ixl.
 *
 * Disassembled	source is compiled using 'Z80asm' by InterLogic, gbs@image.dk
 *
 */

#include <stdio.h>
#include <string.h>
#include "dzasm.h"
#include "avltree.h"
#include "table.h"

extern avltree		*gLabelRef;		/* Binary tree of program labels */
extern DZarea		*gExtern;		/* list	of extern areas	*/
extern avltree		*gExpressions;		/* Binary tree of operand expression for Z80 mnemonics */
extern avltree		*gGlobalConstants;	/* Binary tree of globally replaceable constant names */

static char		undocumented[] = "unknown opcode";	/* error message */

/* Function prototypes */
enum atype		SearchArea(DZarea  *currarea, long  pc);
unsigned char		GetByte(long pc);	/* read	a byte from virtual Z80	memory */
int			CmpAddrRef2(long *key, LabelRef *node);
int			CmpExprAddr2(long *key, Expression *node);
int			CmpConstant2(long *key, GlobalConstant *node);
void			LabelAddr(char *operand, long pc, long addr, enum truefalse dispaddr);

struct opcode mn[] =
{ 	"NOP",			0, none,		/* 00 */
	"LD     BC,%s",		2, none,		/* 01 */
	"LD     (BC),A",	0, none,		/* 02 */
	"INC    BC",		0, none,		/* 03 */
	"INC    B",		0, none,		/* 04 */
	"DEC    B",		0, none,		/* 05 */
	"LD     B,%s",		1, none,		/* 06 */
	"RLCA",			0, none,		/* 07 */

	"EX     AF,AF'",	0, none,		/* 08 */
	"ADD    HL,BC",		0, none,		/* 09 */
	"LD     A,(BC)",	0, none,		/* 0A */
	"DEC    BC",		0, none,		/* 0B */
	"INC    C",		0, none,		/* 0C */
	"DEC    C",		0, none,		/* 0D */
	"LD     C,%s",		1, none,		/* 0E */
	"RRCA",			0, none,		/* 0F */

	"DJNZ   %s",		-1, none,		/* 10 */
	"LD     DE,%s",		2, none,		/* 11 */
	"LD     (DE),A",	0, none,		/* 12 */
	"INC    DE",		0, none,		/* 13 */
	"INC    D",		0, none,		/* 14 */
	"DEC    D",		0, none,		/* 15 */
	"LD     D,%s",		1, none,		/* 16 */
	"RLA",			0, none,		/* 17 */

	"JR     %s",		-1, none,		/* 18 */
	"ADD    HL,DE",		0, none,		/* 19 */
	"LD     A,(DE)",	0, none,		/* 1A */
	"DEC    DE",		0, none,		/* 1B */
	"INC    E",		0, none,		/* 1C */
	"DEC    E",		0, none,		/* 1D */
	"LD     E,%s",		1, none,		/* 1E */
	"RRA",			0, none,		/* 1F */

	"JR     NZ,%s",		-1, none,		/* 20 */
	"LD     HL,%s",		2, none,		/* 21 */
	"LD     (%s),HL",	2, none,	       /* 22 */
	"INC    HL",		0, none,		/* 23 */
	"INC    H",		0, none,		/* 24 */
	"DEC    H",		0, none,		/* 25 */
	"LD     H,%s",		1, none,		/* 26 */
	"DAA",			0, none,		/* 27 */

	"JR     Z,%s",		-1, none,		/* 28 */
	"ADD    HL,HL",		0, none,		/* 29 */
	"LD     HL,(%s)",	2, none,	       /* 2A */
	"DEC    HL",		0, none,		/* 2B */
	"INC    L",		0, none,		/* 2C */
	"DEC    L",		0, none,		/* 2D */
	"LD     L,%s",		1, none,		/* 2E */
	"CPL",			0, none,		/* 2F */

	"JR     NC,%s",		-1, none,		/* 30 */
	"LD     SP,%s",		2, none,	       /* 31 */
	"LD     (%s),A",	2, none,	       /* 32 */
	"INC    SP",		0, none,		/* 33 */
	"INC    (HL)",		0, none,		/* 34 */
	"DEC    (HL)",		0, none,		/* 35 */
	"LD     (HL),%s",	1, none,		/* 36 */
	"SCF",			0, none,		/* 37 */

	"JR     C,%s",		-1, none,		/* 38 */
	"ADD    HL,SP",		0, none,		/* 39 */
	"LD     A,(%s)",	2, none,	       /* 3A */
	"DEC    SP",		0, none,		/* 3B */
	"INC    A",		0, none,		/* 3C */
	"DEC    A",		0, none,		/* 3D */
	"LD     A,%s",		1, none,		/* 3E */
	"CCF",			0, none,		/* 3F */

	"LD     B,B",		0, none,		/* 40 */
	"LD     B,C",		0, none,		/* 41 */
	"LD     B,D",		0, none,		/* 42 */
	"LD     B,E",		0, none,		/* 43 */
	"LD     B,H",		0, none,		/* 44 */
	"LD     B,L",		0, none,		/* 45 */
	"LD     B,(HL)",	0, none,		/* 46 */
	"LD     B,A",		0, none,		/* 47 */

	"LD     C,B",		0, none,		/* 48 */
	"LD     C,C",		0, none,		/* 49 */
	"LD     C,D",		0, none,		/* 4A */
	"LD     C,E",		0, none,		/* 4B */
	"LD     C,H",		0, none,		/* 4C */
	"LD     C,L",		0, none,		/* 4D */
	"LD     C,(HL)",	0, none,		/* 4E */
	"LD     C,A",		0, none,		/* 4F */

	"LD     D,B",		0, none,		/* 50 */
	"LD     D,C",		0, none,		/* 51 */
	"LD     D,D",		0, none,		/* 52 */
	"LD     D,E",		0, none,		/* 53 */
	"LD     D,H",		0, none,		/* 54 */
	"LD     D,L",		0, none,		/* 55 */
	"LD     D,(HL)",	0, none,		/* 56 */
	"LD     D,A",		0, none,		/* 57 */

	"LD     E,B",		0, none,		/* 58 */
	"LD     E,C",		0, none,		/* 59 */
	"LD     E,D",		0, none,		/* 5A */
	"LD     E,E",		0, none,		/* 5B */
	"LD     E,H",		0, none,		/* 5C */
	"LD     E,L",		0, none,		/* 5D */
	"LD     E,(HL)",	0, none,		/* 5E */
	"LD     E,A",		0, none,		/* 5F */

	"LD     H,B",		0, none,		/* 60 */
	"LD     H,C",		0, none,		/* 61 */
	"LD     H,D",		0, none,		/* 62 */
	"LD     H,E",		0, none,		/* 63 */
	"LD     H,H",		0, none,		/* 64 */
	"LD     H,L",		0, none,		/* 65 */
	"LD     H,(HL)",	0, none,		/* 66 */
	"LD     H,A",		0, none,		/* 67 */

	"LD     L,B",		0, none,		/* 68 */
	"LD     L,C",		0, none,		/* 69 */
	"LD     L,D",		0, none,		/* 6A */
	"LD     L,E",		0, none,		/* 6B */
	"LD     L,H",		0, none,		/* 6C */
	"LD     L,L",		0, none,		/* 6D */
	"LD     L,(HL)",	0, none,		/* 6E */
	"LD     L,A",		0, none,		/* 6F */

	"LD     (HL),B",	0, none,		/* 70 */
	"LD     (HL),C",	0, none,		/* 71 */
	"LD     (HL),D",	0, none,		/* 72 */
	"LD     (HL),E",	0, none,		/* 73 */
	"LD     (HL),H",	0, none,		/* 74 */
	"LD     (HL),L",	0, none,		/* 75 */
	"HALT",			0, none,		/* 76 */
	"LD     (HL),A",	0, none,		/* 77 */

	"LD     A,B",		0, none,		/* 78 */
	"LD     A,C",		0, none,		/* 79 */
	"LD     A,D",		0, none,		/* 7A */
	"LD     A,E",		0, none,		/* 7B */
	"LD     A,H",		0, none,		/* 7C */
	"LD     A,L",		0, none,		/* 7D */
	"LD     A,(HL)",	0, none,		/* 7E */
	"LD     A,A",		0, none,		/* 7F */

	"ADD    A,B",		0, none,		/* 80 */
	"ADD    A,C",		0, none,		/* 81 */
	"ADD    A,D",		0, none,		/* 82 */
	"ADD    A,E",		0, none,		/* 83 */
	"ADD    A,H",		0, none,		/* 84 */
	"ADD    A,L",		0, none,		/* 85 */
	"ADD    A,(HL)",	0, none,		/* 86 */
	"ADD    A,A",		0, none,		/* 87 */

	"ADC    A,B",		0, none,		/* 88 */
	"ADC    A,C",		0, none,		/* 89 */
	"ADC    A,D",		0, none,		/* 8A */
	"ADC    A,E",		0, none,		/* 8B */
	"ADC    A,H",		0, none,		/* 8C */
	"ADC    A,L",		0, none,		/* 8D */
	"ADC    A,(HL)",	0, none,		/* 8E */
	"ADC    A,A",		0, none,		/* 8F */

	"SUB    B",		0, none,		/* 90 */
	"SUB    C",		0, none,		/* 91 */
	"SUB    D",		0, none,		/* 92 */
	"SUB    E",		0, none,		/* 93 */
	"SUB    H",		0, none,		/* 94 */
	"SUB    L",		0, none,		/* 95 */
	"SUB    (HL)",		0, none,		/* 96 */
	"SUB    A",		0, none,		/* 97 */

	"SBC    A,B",		0, none,		/* 98 */
	"SBC    A,C",		0, none,		/* 99 */
	"SBC    A,D",		0, none,		/* 9A */
	"SBC    A,E",		0, none,		/* 9B */
	"SBC    A,H",		0, none,		/* 9C */
	"SBC    A,L",		0, none,		/* 9D */
	"SBC    A,(HL)",	0, none,		/* 9E */
	"SBC    A,A",		0, none,		/* 9F */

	"AND    B",		0, none,		/* A0 */
	"AND    C",		0, none,		/* A1 */
	"AND    D",		0, none,		/* A2 */
	"AND    E",		0, none,		/* A3 */
	"AND    H",		0, none,		/* A4 */
	"AND    L",		0, none,		/* A5 */
	"AND    (HL)",		0, none,		/* A6 */
	"AND    A",		0, none,		/* A7 */

	"XOR    B",		0, none,		/* A8 */
	"XOR    C",		0, none,		/* A9 */
	"XOR    D",		0, none,		/* AA */
	"XOR    E",		0, none,		/* AB */
	"XOR    H",		0, none,		/* AC */
	"XOR    L",		0, none,		/* AD */
	"XOR    (HL)",		0, none,		/* AE */
	"XOR    A",		0, none,		/* AF */

	"OR     B",		0, none,		/* B0 */
	"OR     C",		0, none,		/* B1 */
	"OR     D",		0, none,		/* B2 */
	"OR     E",		0, none,		/* B3 */
	"OR     H",		0, none,		/* B4 */
	"OR     L",		0, none,		/* B5 */
	"OR     (HL)",		0, none,		/* B6 */
	"OR     A",		0, none,		/* B7 */

	"CP     B",		0, none,		/* B8 */
	"CP     C",		0, none,		/* B9 */
	"CP     D",		0, none,		/* BA */
	"CP     E",		0, none,		/* BB */
	"CP     H",		0, none,		/* BC */
	"CP     L",		0, none,		/* BD */
	"CP     (HL)",		0, none,		/* BE */
	"CP     A",		0, none,		/* BF */

	"RET    NZ",		0, none,		/* C0 */
	"POP    BC",		0, none,		/* C1 */
	"JP     NZ,%s",		2, none,		/* C2 */
	"JP     %s",		2, none,		/* C3 */
	"CALL   NZ,%s",		2, none,		/* C4 */
	"PUSH   BC",		0, none,		/* C5 */
	"ADD    A,%s",		1, none,		/* C6 */
	"RST    0",		0, none,		/* C7 */

	"RET    Z",		0, none,		/* C8 */
	"RET",			0, none,		/* C9 */
	"JP     Z,%s",		2, none,		/* CA */
	0,			0, none,		/* CB ,	BIT MANIPULATION OPCODES */
	"CALL   Z,%s",		2, none,		/* CC */
	"CALL   %s",		2, none,		/* CD */
	"ADC    A,%s",		1, none,		/* CE */
	"RST    $08",		0, none,		/* CF */

	"RET    NC",		0, none,		/* D0 */
	"POP    DE",		0, none,		/* D1 */
	"JP     NC,%s",		2, none,		/* D2 */
	"OUT    (%s),A",	1, none,		/* D3 */
	"CALL   NC,%s",		2, none,		/* D4 */
	"PUSH   DE",		0, none,		/* D5 */
	"SUB    %s",		1, none,		/* D6 */
	"RST    $10",		0, none,		/* D7 */

	"RET    C",		0, none,		/* D8 */
	"EXX",			0, none,		/* D9 */
	"JP     C,%s",		2, none,		/* DA */
	"IN     A,(%s)",	1, none,		/* DB */
	"CALL   C,%s",		2, none,		/* DC */
	0,			0, none,		/* DD ,	IX  none,OPCODES */
	"SBC    A,%s",		1, none,		/* DE */
	"RST    $18",		0, none,		/* DF */

	"RET    PO",		0, none,		/* E0 */
	"POP    HL",		0, none,		/* E1 */
	"JP     PO,%s",		2, none,		/* E2 */
	"EX     (SP),HL",	0, none,		/* E3 */
	"CALL   PO,%s",		2, none,		/* E4 */
	"PUSH   HL",		0, none,		/* E5 */
	"AND    %s",		1, none,		/* E6 */
	"RST    $20",		0, none,		/* E7 */
	"RET    PE",		0, none,		/* E8 */

	"JP     (HL)",		0, none,		/* E9 */
	"JP     PE,%s",		2, none,		/* EA */
	"EX     DE,HL",		0, none,		/* EB */
	"CALL   PE,%s",		2, none,		/* EC */
	0,			0, none,		/* ED OPCODES */
	"XOR    %s",		1, none,		/* EE */
	"RST    $28",		0, none,		/* EF */

	"RET    P",		0, none,		/* F0 */
	"POP    AF",		0, none,		/* F1 */
	"JP     P,%s",		2, none,		/* F2 */
	"DI",			0, none,		/* F3 */
	"CALL   P,%s",		2, none,		/* F4 */
	"PUSH   AF",		0, none,		/* F5 */
	"OR     %s",		1, none,		/* F6 */
	"RST    $30",		0, none,		/* F7 */

	"RET    M",		0, none,		/* F8 */
	"LD     SP,HL",		0, none,		/* F9 */
	"JP     M,%s",		2, none,		/* FA */
	"EI",			0, none,		/* FB */
	"CALL   M,%s",		2, none,		/* FC */
	0,			0, none,		/* FD, IY  none,OPCODES	*/
	"CP     %s",		1, none,		/* FE */
	"RST    $38",		0, none			/* FF */
};

struct opcode cb[] = {
	"RLC    B",		0, none,		/* CB00	*/
	"RLC    C",		0, none,		/* CB01	*/
	"RLC    D",		0, none,		/* CB02	*/
	"RLC    E",		0, none,		/* CB03	*/
	"RLC    H",		0, none,		/* CB04	*/
	"RLC    L",		0, none,		/* CB05	*/
	"RLC    (HL)",		0, none,		/* CB06	*/
	"RLC    A",		0, none,		/* CB07	*/

	"RRC    B",		0, none,		/* CB08	*/
	"RRC    C",		0, none,		/* CB09	*/
	"RRC    D",		0, none,		/* CB0A	*/
	"RRC    E",		0, none,		/* CB0B	*/
	"RRC    H",		0, none,		/* CB0C	*/
	"RRC    L",		0, none,		/* CB0D	*/
	"RRC    (HL)",		0, none,		/* CB0E	*/
	"RRC    A",		0, none,		/* CB0F	*/

	"RL     B",		0, none,		/* CB10	*/
	"RL     C",		0, none,		/* CB11	*/
	"RL     D",		0, none,		/* CB12	*/
	"RL     E",		0, none,		/* CB13	*/
	"RL     H",		0, none,		/* CB14	*/
	"RL     L",		0, none,		/* CB15	*/
	"RL     (HL)",		0, none,		/* CB16	*/
	"RL     A",		0, none,		/* CB17	*/

	"RR     B",		0, none,		/* CB18	*/
	"RR     C",		0, none,		/* CB19	*/
	"RR     D",		0, none,		/* CB1A	*/
	"RR     E",		0, none,		/* CB1B	*/
	"RR     H",		0, none,		/* CB1C	*/
	"RR     L",		0, none,		/* CB1D	*/
	"RR     (HL)",		0, none,		/* CB1E	*/
	"RR     A",		0, none,		/* CB1F	*/

	"SLA    B",		0, none,		/* CB20	*/
	"SLA    C",		0, none,		/* CB21	*/
	"SLA    D",		0, none,		/* CB22	*/
	"SLA    E",		0, none,		/* CB23	*/
	"SLA    H",		0, none,		/* CB24	*/
	"SLA    L",		0, none,		/* CB25	*/
	"SLA    (HL)",		0, none,		/* CB26	*/
	"SLA    A",		0, none,		/* CB27	*/

	"SRA    B",		0, none,		/* CB28	*/
	"SRA    C",		0, none,		/* CB29	*/
	"SRA    D",		0, none,		/* CB2A	*/
	"SRA    E",		0, none,		/* CB2B	*/
	"SRA    H",		0, none,		/* CB2C	*/
	"SRA    L",		0, none,		/* CB2D	*/
	"SRA    (HL)",		0, none,		/* CB2E	*/
	"SRA    A",		0, none,		/* CB2F	*/

	"SLL    B",		0, none,		/* CB30, undocumented */
	"SLL    C",		0, none,		/* CB31, undocumented */
	"SLL    D",		0, none,		/* CB32, undocumented */
	"SLL    E",		0, none,		/* CB33, undocumented */
	"SLL    H",		0, none,		/* CB34, undocumented */
	"SLL    L",		0, none,		/* CB35, undocumented */
	"SLL    (HL)",		0, none,		/* CB36, undocumented */
	"SLL    A",		0, none,		/* CB37, undocumented */

	"SRL    B",		0, none,		/* CB38	*/
	"SRL    C",		0, none,		/* CB39	*/
	"SRL    D",		0, none,		/* CB3A	*/
	"SRL    E",		0, none,		/* CB3B	*/
	"SRL    H",		0, none,		/* CB3C	*/
	"SRL    L",		0, none,		/* CB3D	*/
	"SRL    (HL)",		0, none,		/* CB3E	*/
	"SRL    A",		0, none,		/* CB3F	*/

	"BIT    0,B",		0, none,		/* CB40	*/
	"BIT    0,C",		0, none,		/* CB41	*/
	"BIT    0,D",		0, none,		/* CB42	*/
	"BIT    0,E",		0, none,		/* CB43	*/
	"BIT    0,H",		0, none,		/* CB44	*/
	"BIT    0,L",		0, none,		/* CB45	*/
	"BIT    0,(HL)",	0, none,		/* CB46	*/
	"BIT    0,A",		0, none,		/* CB47	*/

	"BIT    1,B",		0, none,		/* CB48	*/
	"BIT    1,C",		0, none,		/* CB49	*/
	"BIT    1,D",		0, none,		/* CB4A	*/
	"BIT    1,E",		0, none,		/* CB4B	*/
	"BIT    1,H",		0, none,		/* CB4C	*/
	"BIT    1,L",		0, none,		/* CB4D	*/
	"BIT    1,(HL)",	0, none,		/* CB4E	*/
	"BIT    1,A",		0, none,		/* CB4F	*/

	"BIT    2,B",		0, none,		/* CB50	*/
	"BIT    2,C",		0, none,		/* CB51	*/
	"BIT    2,D",		0, none,		/* CB52	*/
	"BIT    2,E",		0, none,		/* CB53	*/
	"BIT    2,H",		0, none,		/* CB54	*/
	"BIT    2,L",		0, none,		/* CB55	*/
	"BIT    2,(HL)",	0, none,		/* CB56	*/
	"BIT    2,A",		0, none,		/* CB57	*/

	"BIT    3,B",		0, none,		/* CB58	*/
	"BIT    3,C",		0, none,		/* CB59	*/
	"BIT    3,D",		0, none,		/* CB5A	*/
	"BIT    3,E",		0, none,		/* CB5B	*/
	"BIT    3,H",		0, none,		/* CB5C	*/
	"BIT    3,L",		0, none,		/* CB5D	*/
	"BIT    3,(HL)",	0, none,		/* CB5E	*/
	"BIT    3,A",		0, none,		/* CB5F	*/

	"BIT    4,B",		0, none,		/* CB60	*/
	"BIT    4,C",		0, none,		/* CB61	*/
	"BIT    4,D",		0, none,		/* CB62	*/
	"BIT    4,E",		0, none,		/* CB63	*/
	"BIT    4,H",		0, none,		/* CB64	*/
	"BIT    4,L",		0, none,		/* CB65	*/
	"BIT    4,(HL)",	0, none,		/* CB66	*/
	"BIT    4,A",		0, none,		/* CB67	*/

	"BIT    5,B",		0, none,		/* CB68	*/
	"BIT    5,C",		0, none,		/* CB69	*/
	"BIT    5,D",		0, none,		/* CB6A	*/
	"BIT    5,E",		0, none,		/* CB6B	*/
	"BIT    5,H",		0, none,		/* CB6C	*/
	"BIT    5,L",		0, none,		/* CB6D	*/
	"BIT    5,(HL)",	0, none,		/* CB6E	*/
	"BIT    5,A",		0, none,		/* CB6F	*/

	"BIT    6,B",		0, none,		/* CB70	*/
	"BIT    6,C",		0, none,		/* CB71	*/
	"BIT    6,D",		0, none,		/* CB72	*/
	"BIT    6,E",		0, none,		/* CB73	*/
	"BIT    6,H",		0, none,		/* CB74	*/
	"BIT    6,L",		0, none,		/* CB75	*/
	"BIT    6,(HL)",	0, none,		/* CB76	*/
	"BIT    6,A",		0, none,		/* CB77	*/

	"BIT    7,B",		0, none,		/* CB78	*/
	"BIT    7,C",		0, none,		/* CB79	*/
	"BIT    7,D",		0, none,		/* CB7A	*/
	"BIT    7,E",		0, none,		/* CB7B	*/
	"BIT    7,H",		0, none,		/* CB7C	*/
	"BIT    7,L",		0, none,		/* CB7D	*/
	"BIT    7,(HL)",	0, none,		/* CB7E	*/
	"BIT    7,A",		0, none,		/* CB7F	*/

	"RES    0,B",		0, none,		/* CB80	*/
	"RES    0,C",		0, none,		/* CB81	*/
	"RES    0,D",		0, none,		/* CB82	*/
	"RES    0,E",		0, none,		/* CB83	*/
	"RES    0,H",		0, none,		/* CB84	*/
	"RES    0,L",		0, none,		/* CB85	*/
	"RES    0,(HL)",	0, none,		/* CB86	*/
	"RES    0,A",		0, none,		/* CB87	*/

	"RES    1,B",		0, none,		/* CB88	*/
	"RES    1,C",		0, none,		/* CB89	*/
	"RES    1,D",		0, none,		/* CB8A	*/
	"RES    1,E",		0, none,		/* CB8B	*/
	"RES    1,H",		0, none,		/* CB8C	*/
	"RES    1,L",		0, none,		/* CB8D	*/
	"RES    1,(HL)",	0, none,		/* CB8E	*/
	"RES    1,A",		0, none,		/* CB8F	*/

	"RES    2,B",		0, none,		/* CB90	*/
	"RES    2,C",		0, none,		/* CB91	*/
	"RES    2,D",		0, none,		/* CB92	*/
	"RES    2,E",		0, none,		/* CB93	*/
	"RES    2,H",		0, none,		/* CB94	*/
	"RES    2,L",		0, none,		/* CB95	*/
	"RES    2,(HL)",	0, none,		/* CB96	*/
	"RES    2,A",		0, none,		/* CB97	*/

	"RES    3,B",		0, none,		/* CB98	*/
	"RES    3,C",		0, none,		/* CB99	*/
	"RES    3,D",		0, none,		/* CB9A	*/
	"RES    3,E",		0, none,		/* CB9B	*/
	"RES    3,H",		0, none,		/* CB9C	*/
	"RES    3,L",		0, none,		/* CB9D	*/
	"RES    3,(HL)",	0, none,		/* CB9E	*/
	"RES    3,A",		0, none,		/* CB9F	*/

	"RES    4,B",		0, none,		/* CBA0	*/
	"RES    4,C",		0, none,		/* CBA1	*/
	"RES    4,D",		0, none,		/* CBA2	*/
	"RES    4,E",		0, none,		/* CBA3	*/
	"RES    4,H",		0, none,		/* CBA4	*/
	"RES    4,L",		0, none,		/* CBA5	*/
	"RES    4,(HL)",	0, none,		/* CBA6	*/
	"RES    4,A",		0, none,		/* CBA7	*/

	"RES    5,B",		0, none,		/* CBA8	*/
	"RES    5,C",		0, none,		/* CBA9	*/
	"RES    5,D",		0, none,		/* CBAA	*/
	"RES    5,E",		0, none,		/* CBAB	*/
	"RES    5,H",		0, none,		/* CBAC	*/
	"RES    5,L",		0, none,		/* CBAD	*/
	"RES    5,(HL)",	0, none,		/* CBAE	*/
	"RES    5,A",		0, none,		/* CBAF	*/

	"RES    6,B",		0, none,		/* CBB0	*/
	"RES    6,C",		0, none,		/* CBB1	*/
	"RES    6,D",		0, none,		/* CBB2	*/
	"RES    6,E",		0, none,		/* CBB3	*/
	"RES    6,H",		0, none,		/* CBB4	*/
	"RES    6,L",		0, none,		/* CBB5	*/
	"RES    6,(HL)",	0, none,		/* CBB6	*/
	"RES    6,A",		0, none,		/* CBB7	*/

	"RES    7,B",		0, none,		/* CBB8	*/
	"RES    7,C",		0, none,		/* CBB9	*/
	"RES    7,D",		0, none,		/* CBBA	*/
	"RES    7,E",		0, none,		/* CBBB	*/
	"RES    7,H",		0, none,		/* CBBC	*/
	"RES    7,L",		0, none,		/* CBBD	*/
	"RES    7,(HL)",	0, none,		/* CBBE	*/
	"RES    7,A",		0, none,		/* CBBF	*/

	"SET    0,B",		0, none,		/* CBC0	*/
	"SET    0,C",		0, none,		/* CBC1	*/
	"SET    0,D",		0, none,		/* CBC2	*/
	"SET    0,E",		0, none,		/* CBC3	*/
	"SET    0,H",		0, none,		/* CBC4	*/
	"SET    0,L",		0, none,		/* CBC5	*/
	"SET    0,(HL)",	0, none,		/* CBC6	*/
	"SET    0,A",		0, none,		/* CBC7	*/

	"SET    1,B",		0, none,		/* CBC8	*/
	"SET    1,C",		0, none,		/* CBC9	*/
	"SET    1,D",		0, none,		/* CBCA	*/
	"SET    1,E",		0, none,		/* CBCB	*/
	"SET    1,H",		0, none,		/* CBCC	*/
	"SET    1,L",		0, none,		/* CBCD	*/
	"SET    1,(HL)",	0, none,		/* CBCE	*/
	"SET    1,A",		0, none,		/* CBCF	*/

	"SET    2,B",		0, none,		/* CBD0	*/
	"SET    2,C",		0, none,		/* CBD1	*/
	"SET    2,D",		0, none,		/* CBD2	*/
	"SET    2,E",		0, none,		/* CBD3	*/
	"SET    2,H",		0, none,		/* CBD4	*/
	"SET    2,L",		0, none,		/* CBD5	*/
	"SET    2,(HL)",	0, none,		/* CBD6	*/
	"SET    2,A",		0, none,		/* CBD7	*/

	"SET    3,B",		0, none,		/* CBD8	*/
	"SET    3,C",		0, none,		/* CBD9	*/
	"SET    3,D",		0, none,		/* CBDA	*/
	"SET    3,E",		0, none,		/* CBDB	*/
	"SET    3,H",		0, none,		/* CBDC	*/
	"SET    3,L",		0, none,		/* CBDD	*/
	"SET    3,(HL)",	0, none,		/* CBDE	*/
	"SET    3,A",		0, none,		/* CBDF	*/

	"SET    4,B",		0, none,		/* CBE0	*/
	"SET    4,C",		0, none,		/* CBE1	*/
	"SET    4,D",		0, none,		/* CBE2	*/
	"SET    4,E",		0, none,		/* CBE3	*/
	"SET    4,H",		0, none,		/* CBE4	*/
	"SET    4,L",		0, none,		/* CBE5	*/
	"SET    4,(HL)",	0, none,		/* CBE6	*/
	"SET    4,A",		0, none,		/* CBE7	*/

	"SET    5,B",		0, none,		/* CBE8	*/
	"SET    5,C",		0, none,		/* CBE9	*/
	"SET    5,D",		0, none,		/* CBEA	*/
	"SET    5,E",		0, none,		/* CBEB	*/
	"SET    5,H",		0, none,		/* CBEC	*/
	"SET    5,L",		0, none,		/* CBED	*/
	"SET    5,(HL)",	0, none,		/* CBEE	*/
	"SET    5,A",		0, none,		/* CBEF	*/

	"SET    6,B",		0, none,		/* CBF0	*/
	"SET    6,C",		0, none,		/* CBF1	*/
	"SET    6,D",		0, none,		/* CBF2	*/
	"SET    6,E",		0, none,		/* CBF3	*/
	"SET    6,H",		0, none,		/* CBF4	*/
	"SET    6,L",		0, none,		/* CBF5	*/
	"SET    6,(HL)",	0, none,		/* CBF6	*/
	"SET    6,A",		0, none,		/* CBF7	*/

	"SET    7,B",		0, none,		/* CBF8	*/
	"SET    7,C",		0, none,		/* CBF9	*/
	"SET    7,D",		0, none,		/* CBFA	*/
	"SET    7,E",		0, none,		/* CBFB	*/
	"SET    7,H",		0, none,		/* CBFC	*/
	"SET    7,L",		0, none,		/* CBFD	*/
	"SET    7,(HL)",	0, none,		/* CBFE	*/
	"SET    7,A",		0, none			/* CBFF	*/
};


struct opcode ddcb[] = {
	undocumented,		0, none,		/* DDCB00 */
	undocumented,		0, none,		/* DDCB01 */
	undocumented,		0, none,		/* DDCB02 */
	undocumented,		0, none,		/* DDCB03 */
	undocumented,		0, none,		/* DDCB04 */
	undocumented,		0, none,		/* DDCB05 */
	"RLC    (IX%s)",	-2, none,		/* DDCB06 */
	undocumented,		0, none,		/* DDCB07 */

	undocumented,		0, none,		/* DDCB08 */
	undocumented,		0, none,		/* DDCB09 */
	undocumented,		0, none,		/* DDCB0A */
	undocumented,		0, none,		/* DDCB0B */
	undocumented,		0, none,		/* DDCB0C */
	undocumented,		0, none,		/* DDCB0D */
	"RRC    (IX%s)",	-2, none,		/* DDCB0E */
	undocumented,		0, none,		/* DDCB0F */

	undocumented,		0, none,		/* DDCB10 */
	undocumented,		0, none,		/* DDCB11 */
	undocumented,		0, none,		/* DDCB12 */
	undocumented,		0, none,		/* DDCB13 */
	undocumented,		0, none,		/* DDCB14 */
	undocumented,		0, none,		/* DDCB15 */
	"RL     (IX%s)",	-2, none,		/* DDCB16 */
	undocumented,		0, none,		/* DDCB17 */

	undocumented,		0, none,		/* DDCB18 */
	undocumented,		0, none,		/* DDCB19 */
	undocumented,		0, none,		/* DDCB1A */
	undocumented,		0, none,		/* DDCB1B */
	undocumented,		0, none,		/* DDCB1C */
	undocumented,		0, none,		/* DDCB1D */
	"RR     (IX%s)",	-2, none,		/* DDCB1E */
	undocumented,		0, none,		/* DDCB1F */

	undocumented,		0, none,		/* DDCB20 */
	undocumented,		0, none,		/* DDCB21 */
	undocumented,		0, none,		/* DDCB22 */
	undocumented,		0, none,		/* DDCB23 */
	undocumented,		0, none,		/* DDCB24 */
	undocumented,		0, none,		/* DDCB25 */
	"SLA    (IX%s)",	-2, none,		/* DDCB26 */
	undocumented,		0, none,		/* DDCB27 */

	undocumented,		0, none,		/* DDCB28 */
	undocumented,		0, none,		/* DDCB29 */
	undocumented,		0, none,		/* DDCB2A */
	undocumented,		0, none,		/* DDCB2B */
	undocumented,		0, none,		/* DDCB2C */
	undocumented,		0, none,		/* DDCB2D */
	"SRA    (IX%s)",	-2, none,		/* DDCB2E */
	undocumented,		0, none,		/* DDCB2F */

	undocumented,		0, none,		/* DDCB30 */
	undocumented,		0, none,		/* DDCB31 */
	undocumented,		0, none,		/* DDCB32 */
	undocumented,		0, none,		/* DDCB33 */
	undocumented,		0, none,		/* DDCB34 */
	undocumented,		0, none,		/* DDCB35 */
	"SLL    (IX%s)",	-2, none,		/* DDCB36, undocumented	*/
	undocumented,		0, none,		/* DDCB37 */

	undocumented,		0, none,		/* DDCB38 */
	undocumented,		0, none,		/* DDCB39 */
	undocumented,		0, none,		/* DDCB3A */
	undocumented,		0, none,		/* DDCB3B */
	undocumented,		0, none,		/* DDCB3C */
	undocumented,		0, none,		/* DDCB3D */
	"SRL    (IX%s)",	-2, none,		/* DDCB3E */
	undocumented,		0, none,		/* DDCB3F */

	undocumented,		0, none,		/* DDCB40 */
	undocumented,		0, none,		/* DDCB41 */
	undocumented,		0, none,		/* DDCB42 */
	undocumented,		0, none,		/* DDCB43 */
	undocumented,		0, none,		/* DDCB44 */
	undocumented,		0, none,		/* DDCB45 */
	"BIT    0,(IX%s)",	-2, none,		/* DDCB46 */
	undocumented,		0, none,		/* DDCB47 */

	undocumented,		0, none,		/* DDCB48 */
	undocumented,		0, none,		/* DDCB49 */
	undocumented,		0, none,		/* DDCB4A */
	undocumented,		0, none,		/* DDCB4B */
	undocumented,		0, none,		/* DDCB4C */
	undocumented,		0, none,		/* DDCB4D */
	"BIT    1,(IX%s)",	-2, none,		/* DDCB4E */
	undocumented,		0, none,		/* DDCB4F */

	undocumented,		0, none,		/* DDCB50 */
	undocumented,		0, none,		/* DDCB51 */
	undocumented,		0, none,		/* DDCB52 */
	undocumented,		0, none,		/* DDCB53 */
	undocumented,		0, none,		/* DDCB54 */
	undocumented,		0, none,		/* DDCB55 */
	"BIT    2,(IX%s)",	-2, none,		/* DDCB56 */
	undocumented,		0, none,		/* DDCB57 */

	undocumented,		0, none,		/* DDCB58 */
	undocumented,		0, none,		/* DDCB59 */
	undocumented,		0, none,		/* DDCB5A */
	undocumented,		0, none,		/* DDCB5B */
	undocumented,		0, none,		/* DDCB5C */
	undocumented,		0, none,		/* DDCB5D */
	"BIT    3,(IX%s)",	-2, none,		/* DDCB5E */
	undocumented,		0, none,		/* DDCB5F */

	undocumented,		0, none,		/* DDCB60 */
	undocumented,		0, none,		/* DDCB61 */
	undocumented,		0, none,		/* DDCB62 */
	undocumented,		0, none,		/* DDCB63 */
	undocumented,		0, none,		/* DDCB64 */
	undocumented,		0, none,		/* DDCB65 */
	"BIT    4,(IX%s)",	-2, none,		/* DDCB66 */
	undocumented,		0, none,		/* DDCB67 */

	undocumented,		0, none,		/* DDCB68 */
	undocumented,		0, none,		/* DDCB69 */
	undocumented,		0, none,		/* DDCB6A */
	undocumented,		0, none,		/* DDCB6B */
	undocumented,		0, none,		/* DDCB6C */
	undocumented,		0, none,		/* DDCB6D */
	"BIT    5,(IX%s)",	-2, none,		/* DDCB6E */
	undocumented,		0, none,		/* DDCB6F */

	undocumented,		0, none,		/* DDCB70 */
	undocumented,		0, none,		/* DDCB71 */
	undocumented,		0, none,		/* DDCB72 */
	undocumented,		0, none,		/* DDCB73 */
	undocumented,		0, none,		/* DDCB74 */
	undocumented,		0, none,		/* DDCB75 */
	"BIT    6,(IX%s)",	-2, none,		/* DDCB76 */
	undocumented,		0, none,		/* DDCB77 */

	undocumented,		0, none,		/* DDCB78 */
	undocumented,		0, none,		/* DDCB79 */
	undocumented,		0, none,		/* DDCB7A */
	undocumented,		0, none,		/* DDCB7B */
	undocumented,		0, none,		/* DDCB7C */
	undocumented,		0, none,		/* DDCB7D */
	"BIT    7,(IX%s)",	-2, none,		/* DDCB7E */
	undocumented,		0, none,		/* DDCB7F */

	undocumented,		0, none,		/* DDCB80 */
	undocumented,		0, none,		/* DDCB81 */
	undocumented,		0, none,		/* DDCB82 */
	undocumented,		0, none,		/* DDCB83 */
	undocumented,		0, none,		/* DDCB84 */
	undocumented,		0, none,		/* DDCB85 */
	"RES    0,(IX%s)",	-2, none,		/* DDCB86 */
	undocumented,		0, none,		/* DDCB87 */

	undocumented,		0, none,		/* DDCB88 */
	undocumented,		0, none,		/* DDCB89 */
	undocumented,		0, none,		/* DDCB8A */
	undocumented,		0, none,		/* DDCB8B */
	undocumented,		0, none,		/* DDCB8C */
	undocumented,		0, none,		/* DDCB8D */
	"RES    1,(IX%s)",	-2, none,		/* DDCB8E */
	undocumented,		0, none,		/* DDCB8F */

	undocumented,		0, none,		/* DDCB90 */
	undocumented,		0, none,		/* DDCB91 */
	undocumented,		0, none,		/* DDCB92 */
	undocumented,		0, none,		/* DDCB93 */
	undocumented,		0, none,		/* DDCB94 */
	undocumented,		0, none,		/* DDCB95 */
	"RES    2,(IX%s)",	-2, none,		/* DDCB96 */
	undocumented,		0, none,		/* DDCB97 */

	undocumented,		0, none,		/* DDCB98 */
	undocumented,		0, none,		/* DDCB99 */
	undocumented,		0, none,		/* DDCB9A */
	undocumented,		0, none,		/* DDCB9B */
	undocumented,		0, none,		/* DDCB9C */
	undocumented,		0, none,		/* DDCB9D */
	"RES    3,(IX%s)",	-2, none,		/* DDCB9E */
	undocumented,		0, none,		/* DDCB9F */

	undocumented,		0, none,		/* DDCBA0 */
	undocumented,		0, none,		/* DDCBA1 */
	undocumented,		0, none,		/* DDCBA2 */
	undocumented,		0, none,		/* DDCBA3 */
	undocumented,		0, none,		/* DDCBA4 */
	undocumented,		0, none,		/* DDCBA5 */
	"RES    4,(IX%s)",	-2, none,		/* DDCBA6 */
	undocumented,		0, none,		/* DDCBA7 */

	undocumented,		0, none,		/* DDCBA8 */
	undocumented,		0, none,		/* DDCBA9 */
	undocumented,		0, none,		/* DDCBAA */
	undocumented,		0, none,		/* DDCBAB */
	undocumented,		0, none,		/* DDCBAC */
	undocumented,		0, none,		/* DDCBAD */
	"RES    5,(IX%s)",	-2, none,		/* DDCBAE */
	undocumented,		0, none,		/* DDCBAF */

	undocumented,		0, none,		/* DDCBB0 */
	undocumented,		0, none,		/* DDCBB1 */
	undocumented,		0, none,		/* DDCBB2 */
	undocumented,		0, none,		/* DDCBB3 */
	undocumented,		0, none,		/* DDCBB4 */
	undocumented,		0, none,		/* DDCBB5 */
	"RES    6,(IX%s)",	-2, none,		/* DDCBB6 */
	undocumented,		0, none,		/* DDCBB7 */

	undocumented,		0, none,		/* DDCBB8 */
	undocumented,		0, none,		/* DDCBB9 */
	undocumented,		0, none,		/* DDCBBA */
	undocumented,		0, none,		/* DDCBBB */
	undocumented,		0, none,		/* DDCBBC */
	undocumented,		0, none,		/* DDCBBD */
	"RES    7,(IX%s)",	-2, none,		/* DDCBBE */
	undocumented,		0, none,		/* DDCBBF */

	undocumented,		0, none,		/* DDCBC0 */
	undocumented,		0, none,		/* DDCBC1 */
	undocumented,		0, none,		/* DDCBC2 */
	undocumented,		0, none,		/* DDCBC3 */
	undocumented,		0, none,		/* DDCBC4 */
	undocumented,		0, none,		/* DDCBC5 */
	"SET    0,(IX%s)",	-2, none,		/* DDCBC6 */
	undocumented,		0, none,		/* DDCBC7 */

	undocumented,		0, none,		/* DDCBC8 */
	undocumented,		0, none,		/* DDCBC9 */
	undocumented,		0, none,		/* DDCBCA */
	undocumented,		0, none,		/* DDCBCB */
	undocumented,		0, none,		/* DDCBCC */
	undocumented,		0, none,		/* DDCBCD */
	"SET    1,(IX%s)",	-2, none,		/* DDCBCE */
	undocumented,		0, none,		/* DDCBCF */

	undocumented,		0, none,		/* DDCBD0 */
	undocumented,		0, none,		/* DDCBD1 */
	undocumented,		0, none,		/* DDCBD2 */
	undocumented,		0, none,		/* DDCBD3 */
	undocumented,		0, none,		/* DDCBD4 */
	undocumented,		0, none,		/* DDCBD5 */
	"SET    2,(IX%s)",	-2, none,		/* DDCBD6 */
	undocumented,		0, none,		/* DDCBD7 */

	undocumented,		0, none,		/* DDCBD8 */
	undocumented,		0, none,		/* DDCBD9 */
	undocumented,		0, none,		/* DDCBDA */
	undocumented,		0, none,		/* DDCBDB */
	undocumented,		0, none,		/* DDCBDC */
	undocumented,		0, none,		/* DDCBDD */
	"SET    3,(IX%s)",	-2, none,		/* DDCBDE */
	undocumented,		0, none,		/* DDCBDF */

	undocumented,		0, none,		/* DDCBE0 */
	undocumented,		0, none,		/* DDCBE1 */
	undocumented,		0, none,		/* DDCBE2 */
	undocumented,		0, none,		/* DDCBE3 */
	undocumented,		0, none,		/* DDCBE4 */
	undocumented,		0, none,		/* DDCBE5 */
	"SET    4,(IX%s)",	-2, none,		/* DDCBE6 */
	undocumented,		0, none,		/* DDCBE7 */

	undocumented,		0, none,		/* DDCBE8 */
	undocumented,		0, none,		/* DDCBE9 */
	undocumented,		0, none,		/* DDCBEA */
	undocumented,		0, none,		/* DDCBEB */
	undocumented,		0, none,		/* DDCBEC */
	undocumented,		0, none,		/* DDCBED */
	"SET    5,(IX%s)",	-2, none,		/* DDCBEE */
	undocumented,		0, none,		/* DDCBEF */

	undocumented,		0, none,		/* DDCBF0 */
	undocumented,		0, none,		/* DDCBF1 */
	undocumented,		0, none,		/* DDCBF2 */
	undocumented,		0, none,		/* DDCBF3 */
	undocumented,		0, none,		/* DDCBF4 */
	undocumented,		0, none,		/* DDCBF5 */
	"SET    6,(IX%s)",	-2, none,		/* DDCBF6 */
	undocumented,		0, none,		/* DDCBF7 */

	undocumented,		0, none,		/* DDCBF8 */
	undocumented,		0, none,		/* DDCBF9 */
	undocumented,		0, none,		/* DDCBFA */
	undocumented,		0, none,		/* DDCBFB */
	undocumented,		0, none,		/* DDCBFC */
	undocumented,		0, none,		/* DDCBFD */
	"SET    7,(IX%s)",	-2, none,		/* DDCBFE */
	undocumented,		0, none			/* DDCBFF */
};

struct opcode fdcb[] = {
	undocumented,		0, none,		/* FDCB00 */
	undocumented,		0, none,		/* FDCB01 */
	undocumented,		0, none,		/* FDCB02 */
	undocumented,		0, none,		/* FDCB03 */
	undocumented,		0, none,		/* FDCB04 */
	undocumented,		0, none,		/* FDCB05 */
	"RLC    (IY%s)",	-2, none,		/* FDCB06 */
	undocumented,		0, none,		/* FDCB07 */

	undocumented,		0, none,		/* FDCB08 */
	undocumented,		0, none,		/* FDCB09 */
	undocumented,		0, none,		/* FDCB0A */
	undocumented,		0, none,		/* FDCB0B */
	undocumented,		0, none,		/* FDCB0C */
	undocumented,		0, none,		/* FDCB0D */
	"RRC    (IY%s)",	-2, none,		/* FDCB0E */
	undocumented,		0, none,		/* FDCB0F */

	undocumented,		0, none,		/* FDCB10 */
	undocumented,		0, none,		/* FDCB11 */
	undocumented,		0, none,		/* FDCB12 */
	undocumented,		0, none,		/* FDCB13 */
	undocumented,		0, none,		/* FDCB14 */
	undocumented,		0, none,		/* FDCB15 */
	"RL     (IY%s)",	-2, none,		/* FDCB16 */
	undocumented,		0, none,		/* FDCB17 */

	undocumented,		0, none,		/* FDCB18 */
	undocumented,		0, none,		/* FDCB19 */
	undocumented,		0, none,		/* FDCB1A */
	undocumented,		0, none,		/* FDCB1B */
	undocumented,		0, none,		/* FDCB1C */
	undocumented,		0, none,		/* FDCB1D */
	"RR     (IY%s)",	-2, none,		/* FDCB1E */
	undocumented,		0, none,		/* FDCB1F */

	undocumented,		0, none,		/* FDCB20 */
	undocumented,		0, none,		/* FDCB21 */
	undocumented,		0, none,		/* FDCB22 */
	undocumented,		0, none,		/* FDCB23 */
	undocumented,		0, none,		/* FDCB24 */
	undocumented,		0, none,		/* FDCB25 */
	"SLA    (IY%s)",	-2, none,		/* FDCB26 */
	undocumented,		0, none,		/* FDCB27 */

	undocumented,		0, none,		/* FDCB28 */
	undocumented,		0, none,		/* FDCB29 */
	undocumented,		0, none,		/* FDCB2A */
	undocumented,		0, none,		/* FDCB2B */
	undocumented,		0, none,		/* FDCB2C */
	undocumented,		0, none,		/* FDCB2D */
	"SRA    (IY%s)",	-2, none,		/* FDCB2E */
	undocumented,		0, none,		/* FDCB2F */

	undocumented,		0, none,		/* FDCB30 */
	undocumented,		0, none,		/* FDCB31 */
	undocumented,		0, none,		/* FDCB32 */
	undocumented,		0, none,		/* FDCB33 */
	undocumented,		0, none,		/* FDCB34 */
	undocumented,		0, none,		/* FDCB35 */
	"SLL    (IY%s)",	-2, none,		/* FDCB36, undocumented	*/
	undocumented,		0, none,		/* FDCB37 */

	undocumented,		0, none,		/* FDCB38 */
	undocumented,		0, none,		/* FDCB39 */
	undocumented,		0, none,		/* FDCB3A */
	undocumented,		0, none,		/* FDCB3B */
	undocumented,		0, none,		/* FDCB3C */
	undocumented,		0, none,		/* FDCB3D */
	"SRL    (IY%s)",	-2, none,		/* FDCB3E */
	undocumented,		0, none,		/* FDCB3F */

	undocumented,		0, none,		/* FDCB40 */
	undocumented,		0, none,		/* FDCB41 */
	undocumented,		0, none,		/* FDCB42 */
	undocumented,		0, none,		/* FDCB43 */
	undocumented,		0, none,		/* FDCB44 */
	undocumented,		0, none,		/* FDCB45 */
	"BIT    0,(IY%s)",	-2, none,		/* FDCB46 */
	undocumented,		0, none,		/* FDCB47 */

	undocumented,		0, none,		/* FDCB48 */
	undocumented,		0, none,		/* FDCB49 */
	undocumented,		0, none,		/* FDCB4A */
	undocumented,		0, none,		/* FDCB4B */
	undocumented,		0, none,		/* FDCB4C */
	undocumented,		0, none,		/* FDCB4D */
	"BIT    1,(IY%s)",	-2, none,		/* FDCB4E */
	undocumented,		0, none,		/* FDCB4F */

	undocumented,		0, none,		/* FDCB50 */
	undocumented,		0, none,		/* FDCB51 */
	undocumented,		0, none,		/* FDCB52 */
	undocumented,		0, none,		/* FDCB53 */
	undocumented,		0, none,		/* FDCB54 */
	undocumented,		0, none,		/* FDCB55 */
	"BIT    2,(IY%s)",	-2, none,		/* FDCB56 */
	undocumented,		0, none,		/* FDCB57 */

	undocumented,		0, none,		/* FDCB58 */
	undocumented,		0, none,		/* FDCB59 */
	undocumented,		0, none,		/* FDCB5A */
	undocumented,		0, none,		/* FDCB5B */
	undocumented,		0, none,		/* FDCB5C */
	undocumented,		0, none,		/* FDCB5D */
	"BIT    3,(IY%s)",	-2, none,		/* FDCB5E */
	undocumented,		0, none,		/* FDCB5F */

	undocumented,		0, none,		/* FDCB60 */
	undocumented,		0, none,		/* FDCB61 */
	undocumented,		0, none,		/* FDCB62 */
	undocumented,		0, none,		/* FDCB63 */
	undocumented,		0, none,		/* FDCB64 */
	undocumented,		0, none,		/* FDCB65 */
	"BIT    4,(IY%s)",	-2, none,		/* FDCB66 */
	undocumented,		0, none,		/* FDCB67 */

	undocumented,		0, none,		/* FDCB68 */
	undocumented,		0, none,		/* FDCB69 */
	undocumented,		0, none,		/* FDCB6A */
	undocumented,		0, none,		/* FDCB6B */
	undocumented,		0, none,		/* FDCB6C */
	undocumented,		0, none,		/* FDCB6D */
	"BIT    5,(IY%s)",	-2, none,		/* FDCB6E */
	undocumented,		0, none,		/* FDCB6F */

	undocumented,		0, none,		/* FDCB70 */
	undocumented,		0, none,		/* FDCB71 */
	undocumented,		0, none,		/* FDCB72 */
	undocumented,		0, none,		/* FDCB73 */
	undocumented,		0, none,		/* FDCB74 */
	undocumented,		0, none,		/* FDCB75 */
	"BIT    6,(IY%s)",	-2, none,		/* FDCB76 */
	undocumented,		0, none,		/* FDCB77 */

	undocumented,		0, none,		/* FDCB78 */
	undocumented,		0, none,		/* FDCB79 */
	undocumented,		0, none,		/* FDCB7A */
	undocumented,		0, none,		/* FDCB7B */
	undocumented,		0, none,		/* FDCB7C */
	undocumented,		0, none,		/* FDCB7D */
	"BIT    7,(IY%s)",	-2, none,		/* FDCB7E */
	undocumented,		0, none,		/* FDCB7F */

	undocumented,		0, none,		/* FDCB80 */
	undocumented,		0, none,		/* FDCB81 */
	undocumented,		0, none,		/* FDCB82 */
	undocumented,		0, none,		/* FDCB83 */
	undocumented,		0, none,		/* FDCB84 */
	undocumented,		0, none,		/* FDCB85 */
	"RES    0,(IY%s)",	-2, none,		/* FDCB86 */
	undocumented,		0, none,		/* FDCB87 */

	undocumented,		0, none,		/* FDCB88 */
	undocumented,		0, none,		/* FDCB89 */
	undocumented,		0, none,		/* FDCB8A */
	undocumented,		0, none,		/* FDCB8B */
	undocumented,		0, none,		/* FDCB8C */
	undocumented,		0, none,		/* FDCB8D */
	"RES    1,(IY%s)",	-2, none,		/* FDCB8E */
	undocumented,		0, none,		/* FDCB8F */

	undocumented,		0, none,		/* FDCB90 */
	undocumented,		0, none,		/* FDCB91 */
	undocumented,		0, none,		/* FDCB92 */
	undocumented,		0, none,		/* FDCB93 */
	undocumented,		0, none,		/* FDCB94 */
	undocumented,		0, none,		/* FDCB95 */
	"RES    2,(IY%s)",	-2, none,		/* FDCB96 */
	undocumented,		0, none,		/* FDCB97 */

	undocumented,		0, none,		/* FDCB98 */
	undocumented,		0, none,		/* FDCB99 */
	undocumented,		0, none,		/* FDCB9A */
	undocumented,		0, none,		/* FDCB9B */
	undocumented,		0, none,		/* FDCB9C */
	undocumented,		0, none,		/* FDCB9D */
	"RES    3,(IY%s)",	-2, none,		/* FDCB9E */
	undocumented,		0, none,		/* FDCB9F */

	undocumented,		0, none,		/* FDCBA0 */
	undocumented,		0, none,		/* FDCBA1 */
	undocumented,		0, none,		/* FDCBA2 */
	undocumented,		0, none,		/* FDCBA3 */
	undocumented,		0, none,		/* FDCBA4 */
	undocumented,		0, none,		/* FDCBA5 */
	"RES    4,(IY%s)",	-2, none,		/* FDCBA6 */
	undocumented,		0, none,		/* FDCBA7 */

	undocumented,		0, none,		/* FDCBA8 */
	undocumented,		0, none,		/* FDCBA9 */
	undocumented,		0, none,		/* FDCBAA */
	undocumented,		0, none,		/* FDCBAB */
	undocumented,		0, none,		/* FDCBAC */
	undocumented,		0, none,		/* FDCBAD */
	"RES    5,(IY%s)",	-2, none,		/* FDCBAE */
	undocumented,		0, none,		/* FDCBAF */

	undocumented,		0, none,		/* FDCBB0 */
	undocumented,		0, none,		/* FDCBB1 */
	undocumented,		0, none,		/* FDCBB2 */
	undocumented,		0, none,		/* FDCBB3 */
	undocumented,		0, none,		/* FDCBB4 */
	undocumented,		0, none,		/* FDCBB5 */
	"RES    6,(IY%s)",	-2, none,		/* FDCBB6 */
	undocumented,		0, none,		/* FDCBB7 */

	undocumented,		0, none,		/* FDCBB8 */
	undocumented,		0, none,		/* FDCBB9 */
	undocumented,		0, none,		/* FDCBBA */
	undocumented,		0, none,		/* FDCBBB */
	undocumented,		0, none,		/* FDCBBC */
	undocumented,		0, none,		/* FDCBBD */
	"RES    7,(IY%s)",	-2, none,		/* FDCBBE */
	undocumented,		0, none,		/* FDCBBF */

	undocumented,		0, none,		/* FDCBC0 */
	undocumented,		0, none,		/* FDCBC1 */
	undocumented,		0, none,		/* FDCBC2 */
	undocumented,		0, none,		/* FDCBC3 */
	undocumented,		0, none,		/* FDCBC4 */
	undocumented,		0, none,		/* FDCBC5 */
	"SET    0,(IY%s)",	-2, none,		/* FDCBC6 */
	undocumented,		0, none,		/* FDCBC7 */

	undocumented,		0, none,		/* FDCBC8 */
	undocumented,		0, none,		/* FDCBC9 */
	undocumented,		0, none,		/* FDCBCA */
	undocumented,		0, none,		/* FDCBCB */
	undocumented,		0, none,		/* FDCBCC */
	undocumented,		0, none,		/* FDCBCD */
	"SET    1,(IY%s)",	-2, none,		/* FDCBCE */
	undocumented,		0, none,		/* FDCBCF */

	undocumented,		0, none,		/* FDCBD0 */
	undocumented,		0, none,		/* FDCBD1 */
	undocumented,		0, none,		/* FDCBD2 */
	undocumented,		0, none,		/* FDCBD3 */
	undocumented,		0, none,		/* FDCBD4 */
	undocumented,		0, none,		/* FDCBD5 */
	"SET    2,(IY%s)",	-2, none,		/* FDCBD6 */
	undocumented,		0, none,		/* FDCBD7 */

	undocumented,		0, none,		/* FDCBD8 */
	undocumented,		0, none,		/* FDCBD9 */
	undocumented,		0, none,		/* FDCBDA */
	undocumented,		0, none,		/* FDCBDB */
	undocumented,		0, none,		/* FDCBDC */
	undocumented,		0, none,		/* FDCBDD */
	"SET    3,(IY%s)",	-2, none,		/* FDCBDE */
	undocumented,		0, none,		/* FDCBDF */

	undocumented,		0, none,		/* FDCBE0 */
	undocumented,		0, none,		/* FDCBE1 */
	undocumented,		0, none,		/* FDCBE2 */
	undocumented,		0, none,		/* FDCBE3 */
	undocumented,		0, none,		/* FDCBE4 */
	undocumented,		0, none,		/* FDCBE5 */
	"SET    4,(IY%s)",	-2, none,		/* FDCBE6 */
	undocumented,		0, none,		/* FDCBE7 */

	undocumented,		0, none,		/* FDCBE8 */
	undocumented,		0, none,		/* FDCBE9 */
	undocumented,		0, none,		/* FDCBEA */
	undocumented,		0, none,		/* FDCBEB */
	undocumented,		0, none,		/* FDCBEC */
	undocumented,		0, none,		/* FDCBED */
	"SET    5,(IY%s)",	-2, none,		/* FDCBEE */
	undocumented,		0, none,		/* FDCBEF */

	undocumented,		0, none,		/* FDCBF0 */
	undocumented,		0, none,		/* FDCBF1 */
	undocumented,		0, none,		/* FDCBF2 */
	undocumented,		0, none,		/* FDCBF3 */
	undocumented,		0, none,		/* FDCBF4 */
	undocumented,		0, none,		/* FDCBF5 */
	"SET    6,(IY%s)",	-2, none,		/* FDCBF6 */
	undocumented,		0, none,		/* FDCBF7 */

	undocumented,		0, none,		/* FDCBF8 */
	undocumented,		0, none,		/* FDCBF9 */
	undocumented,		0, none,		/* FDCBFA */
	undocumented,		0, none,		/* FDCBFB */
	undocumented,		0, none,		/* FDCBFC */
	undocumented,		0, none,		/* FDCBFD */
	"SET    7,(IY%s)",	-2, none,		/* FDCBFE */
	undocumented,		0, none			/* FDCBFF */
};


struct opcode dd[] = {
	undocumented,		0, none,		/* DD00	*/
	undocumented,		0, none,		/* DD01	*/
	undocumented,		0, none,		/* DD02	*/
	undocumented,		0, none,		/* DD03	*/
	undocumented,		0, none,		/* DD04	*/
	undocumented,		0, none,		/* DD05	*/
	undocumented,		0, none,		/* DD06	*/
	undocumented,		0, none,		/* DD07	*/

	undocumented,		0, none,		/* DD08	*/
	"ADD    IX,BC",		0, none,		/* DD09	*/
	undocumented,		0, none,		/* DD0A	*/
	undocumented,		0, none,		/* DD0B	*/
	undocumented,		0, none,		/* DD0C	*/
	undocumented,		0, none,		/* DD0D	*/
	undocumented,		0, none,		/* DD0E	*/
	undocumented,		0, none,		/* DD0F	*/

	undocumented,		0, none,		/* DD10	*/
	undocumented,		0, none,		/* DD11	*/
	undocumented,		0, none,		/* DD12	*/
	undocumented,		0, none,		/* DD13	*/
	undocumented,		0, none,		/* DD14	*/
	undocumented,		0, none,		/* DD15	*/
	undocumented,		0, none,		/* DD16	*/
	undocumented,		0, none,		/* DD17	*/

	undocumented,		0, none,		/* DD18	*/
	"ADD    IX,DE",		0, none,		/* DD19	*/
	undocumented,		0, none,		/* DD1A	*/
	undocumented,		0, none,		/* DD1B	*/
	undocumented,		0, none,		/* DD1C	*/
	undocumented,		0, none,		/* DD1D	*/
	undocumented,		0, none,		/* DD1E	*/
	undocumented,		0, none,		/* DD1F	*/

	undocumented,		0, none,		/* DD20	*/
	"LD     IX,%s",		2, none,		/* DD21	*/
	"LD     (%s),IX",	2, none,		/* DD22	*/
	"INC    IX",		0, none,		/* DD23	*/
	"INC    IXH",		0, none,		/* DD24, undocumented */
	"DEC    IXH",		0, none,		/* DD25, undocumented */
	"LD     IXH,%s",	1, none,		/* DD26, undocumented */
	undocumented,		0, none,		/* DD27	*/

	undocumented,		0, none,		/* DD28	*/
	"ADD    IX,IX",		0, none,		/* DD29	*/
	"LD     IX,(%s)",	2, none,		/* DD2A	*/
	"DEC    IX",		0, none,		/* DD2B	*/
	"INC    IXL",		0, none,		/* DD24, undocumented */
	"DEC    IXL",		0, none,		/* DD25, undocumented */
	"LD     IXL,%s",	1, none,		/* DD26, undocumented */
	undocumented,		0, none,		/* DD2F	*/

	undocumented,		0, none,		/* DD30	*/
	undocumented,		0, none,		/* DD31	*/
	undocumented,		0, none,		/* DD32	*/
	undocumented,		0, none,		/* DD33	*/
	"INC    (IX%s)",	-4, none,		/* DD34	*/
	"DEC    (IX%s)",	-4, none,		/* DD35	*/
	"LD     (IX%s),%s",	-3, none,		/* DD36	*/
	undocumented,		0, none,		/* DD37	*/

	undocumented,		0, none,		/* DD38	*/
	"ADD    IX,SP",		0, none,		/* DD39	*/
	undocumented,		0, none,		/* DD3A	*/
	undocumented,		0, none,		/* DD3B	*/
	undocumented,		0, none,		/* DD3C	*/
	undocumented,		0, none,		/* DD3D	*/
	undocumented,		0, none,		/* DD3E	*/
	undocumented,		0, none,		/* DD3F	*/

	undocumented,		0, none,		/* DD40	*/
	undocumented,		0, none,		/* DD41	*/
	undocumented,		0, none,		/* DD42	*/
	undocumented,		0, none,		/* DD43	*/
	"LD     B,IXH",		0, none,		/* DD44, undocumented */
	"LD     B,IXL",		0, none,		/* DD45, undocumented */
	"LD     B,(IX%s)",	-4, none,		/* DD46	*/
	undocumented,		0, none,		/* DD47	*/

	undocumented,		0, none,		/* DD48	*/
	undocumented,		0, none,		/* DD49	*/
	undocumented,		0, none,		/* DD4A	*/
	undocumented,		0, none,		/* DD4B	*/
	"LD     C,IXH",		0, none,		/* DD4C, undocumented */
	"LD     C,IXL",		0, none,		/* DD4D, undocumented */
	"LD     C,(IX%s)",	-4, none,		/* DD4E	*/
	undocumented,		0, none,		/* DD4F	*/

	undocumented,		0, none,		/* DD50	*/
	undocumented,		0, none,		/* DD51	*/
	undocumented,		0, none,		/* DD52	*/
	undocumented,		0, none,		/* DD53	*/
	"LD     D,IXH",		0, none,		/* DD54, undocumented */
	"LD     D,IXL",		0, none,		/* DD55, undocumented */
	"LD     D,(IX%s)",	-4, none,		/* DD56	*/
	undocumented,		0, none,		/* DD57	*/

	undocumented,		0, none,		/* DD58	*/
	undocumented,		0, none,		/* DD59	*/
	undocumented,		0, none,		/* DD5A	*/
	undocumented,		0, none,		/* DD5B	*/
	"LD     E,IXH",		0, none,		/* DD5C, undocumented */
	"LD     E,IXL",		0, none,		/* DD5D, undocumented */
	"LD     E,(IX%s)",	-4, none,		/* DD5E	*/
	undocumented,		0, none,		/* DD5F	*/

	"LD     IXH,B",		0, none,		/* DD60, undocumented */
	"LD     IXH,C",		0, none,		/* DD61, undocumented */
	"LD     IXH,D",		0, none,		/* DD62, undocumented */
	"LD     IXH,E",		0, none,		/* DD63, undocumented */
	"LD     IXH,IXH",	0, none,		/* DD64, undocumented */
	"LD     IXH,IXL",	0, none,		/* DD65, undocumented */
	"LD     H,(IX%s)",	-4, none,		/* DD66	*/
	"LD     IXH,A",		0, none,		/* DD67, undocumented */

	"LD     IXL,B",		0, none,		/* DD68, undocumented */
	"LD     IXL,C",		0, none,		/* DD69, undocumented */
	"LD     IXL,D",		0, none,		/* DD6A, undocumented */
	"LD     IXL,E",		0, none,		/* DD6B, undocumented */
	"LD     IXL,IXH",	0, none,		/* DD6C, undocumented */
	"LD     IXL,IXL",	0, none,		/* DD6D, undocumented */
	"LD     L,(IX%s)",	-4, none,		/* DD6E	*/
	"LD     IXL,A",		0, none,		/* DD6F, undocumented */

	"LD     (IX%s),B",	-4, none,		/* DD70	*/
	"LD     (IX%s),C",	-4, none,		/* DD71	*/
	"LD     (IX%s),D",	-4, none,		/* DD72	*/
	"LD     (IX%s),E",	-4, none,		/* DD73	*/
	"LD     (IX%s),H",	-4, none,		/* DD74	*/
	"LD     (IX%s),L",	-4, none,		/* DD75	*/
	undocumented,		0, none,		/* DD76	*/
	"LD     (IX%s),A",	-4, none,		/* DD77	*/

	undocumented,		0, none,		/* DD78	*/
	undocumented,		0, none,		/* DD79	*/
	undocumented,		0, none,		/* DD7A	*/
	undocumented,		0, none,		/* DD7B	*/
	"LD     A,IXH",		0, none,		/* DD7C, undocumented */
	"LD     A,IXL",		0, none,		/* DD7D, undocumented */
	"LD     A,(IX%s)",	-4, none,		/* DD7E	*/
	undocumented,		0, none,		/* DD7F	*/

	undocumented,		0, none,		/* DD80	*/
	undocumented,		0, none,		/* DD81	*/
	undocumented,		0, none,		/* DD82	*/
	undocumented,		0, none,		/* DD83	*/
	"ADD    A,IXH",		0, none,		/* DD84, undocumented */
	"ADD    A,IXL",		0, none,		/* DD85, undocumented */
	"ADD    A,(IX%s)",	-4, none,		/* DD86	*/
	undocumented,		0, none,		/* DD87	*/

	undocumented,		0, none,		/* DD88	*/
	undocumented,		0, none,		/* DD89	*/
	undocumented,		0, none,		/* DD8A	*/
	undocumented,		0, none,		/* DD8B	*/
	"ADC    A,IXH",		0, none,		/* DD8D, undocumented */
	"ADC    A,IXL",		0, none,		/* DD8E, undocumented */
	"ADC    A,(IX%s)",	-4, none,		/* DD8E	*/
	undocumented,		0, none,		/* DD8F	*/

	undocumented,		0, none,		/* DD90	*/
	undocumented,		0, none,		/* DD91	*/
	undocumented,		0, none,		/* DD92	*/
	undocumented,		0, none,		/* DD93	*/
	"SUB    IXH",		0, none,		/* DD94, undocumented */
	"SUB    IXL",		0, none,		/* DD95, undocumented */
	"SUB    (IX%s)",	-4, none,		/* DD96	*/
	undocumented,		0, none,		/* DD97	*/

	undocumented,		0, none,		/* DD98	*/
	undocumented,		0, none,		/* DD99	*/
	undocumented,		0, none,		/* DD9A	*/
	undocumented,		0, none,		/* DD9B	*/
	"SBC    A,IXH",		0, none,		/* DD9C, undocumented */
	"SBC    A,IXL",		0, none,		/* DD9D, undocumented */
	"SBC    A,(IX%s)",	-4, none,		/* DD9E	*/
	undocumented,		0, none,		/* DD9F	*/

	undocumented,		0, none,		/* DDA0	*/
	undocumented,		0, none,		/* DDA1	*/
	undocumented,		0, none,		/* DDA2	*/
	undocumented,		0, none,		/* DDA3	*/
	"AND    IXH",		0, none,		/* DDA4, undocumented */
	"AND    IXL",		0, none,		/* DDA5, undocumented */
	"AND    (IX%s)",	-4, none,		/* DDA6	*/
	undocumented,		0, none,		/* DDA7	*/

	undocumented,		0, none,		/* DDA8	*/
	undocumented,		0, none,		/* DDA9	*/
	undocumented,		0, none,		/* DDAA	*/
	undocumented,		0, none,		/* DDAB	*/
	"XOR    IXH",		0, none,		/* DDAC, undocumented */
	"XOR    IXL",		0, none,		/* DDAD, undocumented */
	"XOR    (IX%s)",	-4, none,		/* DDAE	*/
	undocumented,		0, none,		/* DDAF	*/

	undocumented,		0, none,		/* DDB0	*/
	undocumented,		0, none,		/* DDB1	*/
	undocumented,		0, none,		/* DDB2	*/
	undocumented,		0, none,		/* DDB3	*/
	"OR     IXH",		0, none,		/* DDB4, undocumented */
	"OR     IXL",		0, none,		/* DDB5, undocumented */
	"OR     (IX%s)",	-4, none,		/* DDB6	*/
	undocumented,		0, none,		/* DDB7	*/

	undocumented,		0, none,		/* DDB8	*/
	undocumented,		0, none,		/* DDB9	*/
	undocumented,		0, none,		/* DDBA	*/
	undocumented,		0, none,		/* DDBB	*/
	"CP     IXH",		0, none,		/* DDBC, undocumented */
	"CP     IXL",		0, none,		/* DDBD, undocumented */
	"CP     (IX%s)",	-4, none,		/* DDBE	*/
	undocumented,		0, none,		/* DDBF	*/

	undocumented,		0, none,		/* DDC0	*/
	undocumented,		0, none,		/* DDC1	*/
	undocumented,		0, none,		/* DDC2	*/
	undocumented,		0, none,		/* DDC3	*/
	undocumented,		0, none,		/* DDC4	*/
	undocumented,		0, none,		/* DDC5	*/
	undocumented,		0, none,		/* DDC6	*/
	undocumented,		0, none,		/* DDC7	*/

	undocumented,		0, none,		/* DDC8	*/
	undocumented,		0, none,		/* DDC9	*/
	undocumented,		0, none,		/* DDCA	*/
	undocumented,		0, none,		/* DDCB	*/
	undocumented,		0, none,		/* DDCC	*/
	undocumented,		0, none,		/* DDCD	*/
	undocumented,		0, none,		/* DDCE	*/
	undocumented,		0, none,		/* DDCF	*/

	undocumented,		0, none,		/* DDD0	*/
	undocumented,		0, none,		/* DDD1	*/
	undocumented,		0, none,		/* DDD2	*/
	undocumented,		0, none,		/* DDD3	*/
	undocumented,		0, none,		/* DDD4	*/
	undocumented,		0, none,		/* DDD5	*/
	undocumented,		0, none,		/* DDD6	*/
	undocumented,		0, none,		/* DDD7	*/

	undocumented,		0, none,		/* DDD8	*/
	undocumented,		0, none,		/* DDD9	*/
	undocumented,		0, none,		/* DDDA	*/
	undocumented,		0, none,		/* DDDB	*/
	undocumented,		0, none,		/* DDDC	*/
	undocumented,		0, none,		/* DDDD	*/
	undocumented,		0, none,		/* DDDE	*/
	undocumented,		0, none,		/* DDDF	*/

	undocumented,		0, none,		/* DDE0	*/
	"POP    IX",		0, none,		/* DDE1	*/
	undocumented,		0, none,		/* DDE2	*/
	"EX     (SP),IX",	0, none,		/* DDE3	*/
	undocumented,		0, none,		/* DDE4	*/
	"PUSH   IX",		0, none,		/* DDE5	*/
	undocumented,		0, none,		/* DDE6	*/
	undocumented,		0, none,		/* DDE7	*/

	undocumented,		0, none,		/* DDE8	*/
	"JP     (IX)",		0, none,		/* DDE9	*/
	undocumented,		0, none,		/* DDEA	*/
	undocumented,		0, none,		/* DDEB	*/
	undocumented,		0, none,		/* DDEC	*/
	undocumented,		0, none,		/* DDED	*/
	undocumented,		0, none,		/* DDEE	*/
	undocumented,		0, none,		/* DDEF	*/

	undocumented,		0, none,		/* DDF0	*/
	undocumented,		0, none,		/* DDF1	*/
	undocumented,		0, none,		/* DDF2	*/
	undocumented,		0, none,		/* DDF3	*/
	undocumented,		0, none,		/* DDF4	*/
	undocumented,		0, none,		/* DDF5	*/
	undocumented,		0, none,		/* DDF6	*/
	undocumented,		0, none,		/* DDF7	*/

	undocumented,		0, none,		/* DDF8	*/
	"LD     SP,IX",		0, none,		/* DDF9	*/
	undocumented,		0, none,		/* DDFA	*/
	undocumented,		0, none,		/* DDFB	*/
	undocumented,		0, none,		/* DDFC	*/
	undocumented,		0, none,		/* DDFD	*/
	undocumented,		0, none,		/* DDFE	*/
	undocumented,		0, none			/* DDFF	*/
};


struct opcode fd[] = {
	undocumented,		0, none,		/* FD00	*/
	undocumented,		0, none,		/* FD01	*/
	undocumented,		0, none,		/* FD02	*/
	undocumented,		0, none,		/* FD03	*/
	undocumented,		0, none,		/* FD04	*/
	undocumented,		0, none,		/* FD05	*/
	undocumented,		0, none,		/* FD06	*/
	undocumented,		0, none,		/* FD07	*/

	undocumented,		0, none,		/* FD08	*/
	"ADD    IY,BC",		0, none,		/* FD09	*/
	undocumented,		0, none,		/* FD0A	*/
	undocumented,		0, none,		/* FD0B	*/
	undocumented,		0, none,		/* FD0C	*/
	undocumented,		0, none,		/* FD0D	*/
	undocumented,		0, none,		/* FD0E	*/
	undocumented,		0, none,		/* FD0F	*/

	undocumented,		0, none,		/* FD10	*/
	undocumented,		0, none,		/* FD11	*/
	undocumented,		0, none,		/* FD12	*/
	undocumented,		0, none,		/* FD13	*/
	undocumented,		0, none,		/* FD14	*/
	undocumented,		0, none,		/* FD15	*/
	undocumented,		0, none,		/* FD16	*/
	undocumented,		0, none,		/* FD17	*/

	undocumented,		0, none,		/* FD18	*/
	"ADD    IY,DE",		0, none,		/* FD19	*/
	undocumented,		0, none,		/* FD1A	*/
	undocumented,		0, none,		/* FD1B	*/
	undocumented,		0, none,		/* FD1C	*/
	undocumented,		0, none,		/* FD1D	*/
	undocumented,		0, none,		/* FD1E	*/
	undocumented,		0, none,		/* FD1F	*/

	undocumented,		0, none,		/* FD20	*/
	"LD     IY,%s",		2, none,		/* FD21	*/
	"LD     (%s),IY",	2, none,		/* FD22	*/
	"INC    IY",		0, none,		/* FD23	*/
	"INC    IYH",		0, none,		/* FD24, undocumented */
	"DEC    IYH",		0, none,		/* FD25, undocumented */
	"LD     IYH,%s",	1, none,		/* FD26, undocumented */
	undocumented,		0, none,		/* FD27	*/

	undocumented,		0, none,		/* FD28	*/
	"ADD    IY,IY",		0, none,		/* FD29	*/
	"LD     IY,(%s)",	2, none,		/* FD2A	*/
	"DEC    IY",		0, none,		/* FD2B	*/
	"INC    IYL",		0, none,		/* FD24, undocumented */
	"DEC    IYL",		0, none,		/* FD25, undocumented */
	"LD     IYL,%s",	1, none,		/* FD26, undocumented */
	undocumented,		0, none,		/* FD2F	*/

	undocumented,		0, none,		/* FD30	*/
	undocumented,		0, none,		/* FD31	*/
	undocumented,		0, none,		/* FD32	*/
	undocumented,		0, none,		/* FD33	*/
	"INC    (IY%s)",	-4, none,		/* FD34	*/
	"DEC    (IY%s)",	-4, none,		/* FD35	*/
	"LD     (IY%s),%s",	-3, none,		/* FD36	*/
	undocumented,		0, none,		/* FD37	*/

	undocumented,		0, none,		/* FD38	*/
	"ADD    IY,SP",		0, none,		/* FD39	*/
	undocumented,		0, none,		/* FD3A	*/
	undocumented,		0, none,		/* FD3B	*/
	undocumented,		0, none,		/* FD3C	*/
	undocumented,		0, none,		/* FD3D	*/
	undocumented,		0, none,		/* FD3E	*/
	undocumented,		0, none,		/* FD3F	*/

	undocumented,		0, none,		/* FD40	*/
	undocumented,		0, none,		/* FD41	*/
	undocumented,		0, none,		/* FD42	*/
	undocumented,		0, none,		/* FD43	*/
	"LD     B,IYH",		0, none,		/* FD44, undocumented */
	"LD     B,IYL",		0, none,		/* FD45, undocumented */
	"LD     B,(IY%s)",	-4, none,		/* FD46	*/
	undocumented,		0, none,		/* FD47	*/

	undocumented,		0, none,		/* FD48	*/
	undocumented,		0, none,		/* FD49	*/
	undocumented,		0, none,		/* FD4A	*/
	undocumented,		0, none,		/* FD4B	*/
	"LD     C,IYH",		0, none,		/* FD4C, undocumented */
	"LD     C,IYL",		0, none,		/* FD4D, undocumented */
	"LD     C,(IY%s)",	-4, none,		/* FD4E	*/
	undocumented,		0, none,		/* FD4F	*/

	undocumented,		0, none,		/* FD50	*/
	undocumented,		0, none,		/* FD51	*/
	undocumented,		0, none,		/* FD52	*/
	undocumented,		0, none,		/* FD53	*/
	"LD     D,IYH",		0, none,		/* FD54, undocumented */
	"LD     D,IYL",		0, none,		/* FD55, undocumented */
	"LD     D,(IY%s)",	-4, none,		/* FD56	*/
	undocumented,		0, none,		/* FD57	*/

	undocumented,		0, none,		/* FD58	*/
	undocumented,		0, none,		/* FD59	*/
	undocumented,		0, none,		/* FD5A	*/
	undocumented,		0, none,		/* FD5B	*/
	"LD     E,IYH",		0, none,		/* FD5C, undocumented */
	"LD     E,IYL",		0, none,		/* FD5D, undocumented */
	"LD     E,(IY%s)",	-4, none,		/* FD5E	*/
	undocumented,		0, none,		/* FD5F	*/

	"LD     IYH,B",		0, none,		/* FD60, undocumented */
	"LD     IYH,C",		0, none,		/* FD61, undocumented */
	"LD     IYH,D",		0, none,		/* FD62, undocumented */
	"LD     IYH,E",		0, none,		/* FD63, undocumented */
	"LD     IYH,IYH",	0, none,		/* FD64, undocumented */
	"LD     IYH,IYL",	0, none,		/* FD65, undocumented */
	"LD     H,(IY%s)",	-4, none,		/* FD66	*/
	"LD     IYH,A",		0, none,		/* FD67, undocumented */

	"LD     IYL,B",		0, none,		/* FD68, undocumented */
	"LD     IYL,C",		0, none,		/* FD69, undocumented */
	"LD     IYL,D",		0, none,		/* FD6A, undocumented */
	"LD     IYL,E",		0, none,		/* FD6B, undocumented */
	"LD     IYL,IYH",	0, none,		/* FD6C, undocumented */
	"LD     IYL,IYL",	0, none,		/* FD6D, undocumented */
	"LD     L,(IY%s)",	-4, none,		/* FD6E	*/
	"LD     IYL,A",		0, none,		/* FD6F, undocumented */

	"LD     (IY%s),B",	-4, none,		/* FD70	*/
	"LD     (IY%s),C",	-4, none,		/* FD71	*/
	"LD     (IY%s),D",	-4, none,		/* FD72	*/
	"LD     (IY%s),E",	-4, none,		/* FD73	*/
	"LD     (IY%s),H",	-4, none,		/* FD74	*/
	"LD     (IY%s),L",	-4, none,		/* FD75	*/
	undocumented,		0, none,		/* FD76	*/
	"LD     (IY%s),A",	-4, none,		/* FD77	*/

	undocumented,		0, none,		/* FD78	*/
	undocumented,		0, none,		/* FD79	*/
	undocumented,		0, none,		/* FD7A	*/
	undocumented,		0, none,		/* FD7B	*/
	"LD     A,IYH",		0, none,		/* FD7C, undocumented */
	"LD     A,IYL",		0, none,		/* FD7D, undocumented */
	"LD     A,(IY%s)",	-4, none,		/* FD7E	*/
	undocumented,		0, none,		/* FD7F	*/

	undocumented,		0, none,		/* FD80	*/
	undocumented,		0, none,		/* FD81	*/
	undocumented,		0, none,		/* FD82	*/
	undocumented,		0, none,		/* FD83	*/
	"ADD    A,IYH",		0, none,		/* FD84, undocumented */
	"ADD    A,IYL",		0, none,		/* FD85, undocumented */
	"ADD    A,(IY%s)",	-4, none,		/* FD86	*/
	undocumented,		0, none,		/* FD87	*/

	undocumented,		0, none,		/* FD88	*/
	undocumented,		0, none,		/* FD89	*/
	undocumented,		0, none,		/* FD8A	*/
	undocumented,		0, none,		/* FD8B	*/
	"ADC    A,IYH",		0, none,		/* FD8D, undocumented */
	"ADC    A,IYL",		0, none,		/* FD8E, undocumented */
	"ADC    A,(IY%s)",	-4, none,		/* FD8E	*/
	undocumented,		0, none,		/* FD8F	*/

	undocumented,		0, none,		/* FD90	*/
	undocumented,		0, none,		/* FD91	*/
	undocumented,		0, none,		/* FD92	*/
	undocumented,		0, none,		/* FD93	*/
	"SUB    IYH",		0, none,		/* FD94, undocumented */
	"SUB    IYL",		0, none,		/* FD95, undocumented */
	"SUB    (IY%s)",	-4, none,		/* FD96	*/
	undocumented,		0, none,		/* FD97	*/

	undocumented,		0, none,		/* FD98	*/
	undocumented,		0, none,		/* FD99	*/
	undocumented,		0, none,		/* FD9A	*/
	undocumented,		0, none,		/* FD9B	*/
	"SBC    A,IYH",		0, none,		/* FD9C, undocumented */
	"SBC    A,IYL",		0, none,		/* FD9D, undocumented */
	"SBC    A,(IY%s)",	-4, none,		/* FD9E	*/
	undocumented,		0, none,		/* FD9F	*/

	undocumented,		0, none,		/* FDA0	*/
	undocumented,		0, none,		/* FDA1	*/
	undocumented,		0, none,		/* FDA2	*/
	undocumented,		0, none,		/* FDA3	*/
	"AND    IYH",		0, none,		/* FDA4, undocumented */
	"AND    IYL",		0, none,		/* FDA5, undocumented */
	"AND    (IY%s)",	-4, none,		/* FDA6	*/
	undocumented,		0, none,		/* FDA7	*/

	undocumented,		0, none,		/* FDA8	*/
	undocumented,		0, none,		/* FDA9	*/
	undocumented,		0, none,		/* FDAA	*/
	undocumented,		0, none,		/* FDAB	*/
	"XOR    IYH",		0, none,		/* FDAC, undocumented */
	"XOR    IYL",		0, none,		/* FDAD, undocumented */
	"XOR    (IY%s)",	-4, none,		/* FDAE	*/
	undocumented,		0, none,		/* FDAF	*/

	undocumented,		0, none,		/* FDB0	*/
	undocumented,		0, none,		/* FDB1	*/
	undocumented,		0, none,		/* FDB2	*/
	undocumented,		0, none,		/* FDB3	*/
	"OR     IYH",		0, none,		/* FDB4, undocumented */
	"OR     IYL",		0, none,		/* FDB5, undocumented */
	"OR     (IY%s)",	-4, none,		/* FDB6	*/
	undocumented,		0, none,		/* FDB7	*/

	undocumented,		0, none,		/* FDB8	*/
	undocumented,		0, none,		/* FDB9	*/
	undocumented,		0, none,		/* FDBA	*/
	undocumented,		0, none,		/* FDBB	*/
	"CP     IYH",		0, none,		/* FDBC, undocumented */
	"CP     IYL",		0, none,		/* FDBD, undocumented */
	"CP     (IY%s)",	-4, none,		/* FDBE	*/
	undocumented,		0, none,		/* FDBF	*/

	undocumented,		0, none,		/* FDC0	*/
	undocumented,		0, none,		/* FDC1	*/
	undocumented,		0, none,		/* FDC2	*/
	undocumented,		0, none,		/* FDC3	*/
	undocumented,		0, none,		/* FDC4	*/
	undocumented,		0, none,		/* FDC5	*/
	undocumented,		0, none,		/* FDC6	*/
	undocumented,		0, none,		/* FDC7	*/

	undocumented,		0, none,		/* FDC8	*/
	undocumented,		0, none,		/* FDC9	*/
	undocumented,		0, none,		/* FDCA	*/
	undocumented,		0, none,		/* FDCB	*/
	undocumented,		0, none,		/* FDCC	*/
	undocumented,		0, none,		/* FDCD	*/
	undocumented,		0, none,		/* FDCE	*/
	undocumented,		0, none,		/* FDCF	*/

	undocumented,		0, none,		/* FDD0	*/
	undocumented,		0, none,		/* FDD1	*/
	undocumented,		0, none,		/* FDD2	*/
	undocumented,		0, none,		/* FDD3	*/
	undocumented,		0, none,		/* FDD4	*/
	undocumented,		0, none,		/* FDD5	*/
	undocumented,		0, none,		/* FDD6	*/
	undocumented,		0, none,		/* FDD7	*/

	undocumented,		0, none,		/* FDD8	*/
	undocumented,		0, none,		/* FDD9	*/
	undocumented,		0, none,		/* FDDA	*/
	undocumented,		0, none,		/* FDDB	*/
	undocumented,		0, none,		/* FDDC	*/
	undocumented,		0, none,		/* FDDD	*/
	undocumented,		0, none,		/* FDDE	*/
	undocumented,		0, none,		/* FDDF	*/

	undocumented,		0, none,		/* FDE0	*/
	"POP    IY",		0, none,		/* FDE1	*/
	undocumented,		0, none,		/* FDE2	*/
	"EX     (SP),IY",	0, none,		/* FDE3	*/
	undocumented,		0, none,		/* FDE4	*/
	"PUSH   IY",		0, none,		/* FDE5	*/
	undocumented,		0, none,		/* FDE6	*/
	undocumented,		0, none,		/* FDE7	*/

	undocumented,		0, none,		/* FDE8	*/
	"JP     (IY)",		0, none,		/* FDE9	*/
	undocumented,		0, none,		/* FDEA	*/
	undocumented,		0, none,		/* FDEB	*/
	undocumented,		0, none,		/* FDEC	*/
	undocumented,		0, none,		/* FDED	*/
	undocumented,		0, none,		/* FDEE	*/
	undocumented,		0, none,		/* FDEF	*/

	undocumented,		0, none,		/* FDF0	*/
	undocumented,		0, none,		/* FDF1	*/
	undocumented,		0, none,		/* FDF2	*/
	undocumented,		0, none,		/* FDF3	*/
	undocumented,		0, none,		/* FDF4	*/
	undocumented,		0, none,		/* FDF5	*/
	undocumented,		0, none,		/* FDF6	*/
	undocumented,		0, none,		/* FDF7	*/

	undocumented,		0, none,		/* FDF8	*/
	"LD     SP,IY",		0, none,		/* FDF9	*/
	undocumented,		0, none,		/* FDFA	*/
	undocumented,		0, none,		/* FDFB	*/
	undocumented,		0, none,		/* FDFC	*/
	undocumented,		0, none,		/* FDFD	*/
	undocumented,		0, none,		/* FDFE	*/
	undocumented,		0, none			/* FDFF	*/
};

struct opcode ed[] = {
	undocumented,		0, none,		/* ED00	*/
	undocumented,		0, none,		/* ED01	*/
	undocumented,		0, none,		/* ED02	*/
	undocumented,		0, none,		/* ED03	*/
	undocumented,		0, none,		/* ED04	*/
	undocumented,		0, none,		/* ED05	*/
	undocumented,		0, none,		/* ED06	*/
	undocumented,		0, none,		/* ED07	*/

	undocumented,		0, none,		/* ED08	*/
	undocumented,		0, none,		/* ED09	*/
	undocumented,		0, none,		/* ED0A	*/
	undocumented,		0, none,		/* ED0B	*/
	undocumented,		0, none,		/* ED0C	*/
	undocumented,		0, none,		/* ED0D	*/
	undocumented,		0, none,		/* ED0E	*/
	undocumented,		0, none,		/* ED0F	*/

	undocumented,		0, none,		/* ED10	*/
	undocumented,		0, none,		/* ED11	*/
	undocumented,		0, none,		/* ED12	*/
	undocumented,		0, none,		/* ED13	*/
	undocumented,		0, none,		/* ED14	*/
	undocumented,		0, none,		/* ED15	*/
	undocumented,		0, none,		/* ED16	*/
	undocumented,		0, none,		/* ED17	*/

	undocumented,		0, none,		/* ED18	*/
	undocumented,		0, none,		/* ED19	*/
	undocumented,		0, none,		/* ED1A	*/
	undocumented,		0, none,		/* ED1B	*/
	undocumented,		0, none,		/* ED1C	*/
	undocumented,		0, none,		/* ED1D	*/
	undocumented,		0, none,		/* ED1E	*/
	undocumented,		0, none,		/* ED1F	*/

	undocumented,		0, none,		/* ED20	*/
	undocumented,		0, none,		/* ED21	*/
	undocumented,		0, none,		/* ED22	*/
	undocumented,		0, none,		/* ED23	*/
	undocumented,		0, none,		/* ED24	*/
	undocumented,		0, none,		/* ED25	*/
	undocumented,		0, none,		/* ED26	*/
	undocumented,		0, none,		/* ED27	*/

	undocumented,		0, none,		/* ED28	*/
	undocumented,		0, none,		/* ED29	*/
	undocumented,		0, none,		/* ED2A	*/
	undocumented,		0, none,		/* ED2B	*/
	undocumented,		0, none,		/* ED2C	*/
	undocumented,		0, none,		/* ED2D	*/
	undocumented,		0, none,		/* ED2E	*/
	undocumented,		0, none,		/* ED2F	*/

	undocumented,		0, none,		/* ED30	*/
	undocumented,		0, none,		/* ED31	*/
	undocumented,		0, none,		/* ED32	*/
	undocumented,		0, none,		/* ED33	*/
	undocumented,		0, none,		/* ED34	*/
	undocumented,		0, none,		/* ED35	*/
	undocumented,		0, none,		/* ED36	*/
	undocumented,		0, none,		/* ED37	*/

	undocumented,		0, none,		/* ED38	*/
	undocumented,		0, none,		/* ED39	*/
	undocumented,		0, none,		/* ED3A	*/
	undocumented,		0, none,		/* ED3B	*/
	undocumented,		0, none,		/* ED3C	*/
	undocumented,		0, none,		/* ED3D	*/
	undocumented,		0, none,		/* ED3E	*/
	undocumented,		0, none,		/* ED3F	*/

	"IN     B,(C)",		0, none,		/* ED40	*/
	"OUT    (C),B",		0, none,		/* ED41	*/
	"SBC    HL,BC",		0, none,		/* ED42	*/
	"LD     (%s),BC",	2, none,	       /* ED43 */
	"NEG",			0, none,		/* ED44	*/
	"RETN",			0, none,		/* ED45	*/
	"IM     0",		0, none,		/* ED46	*/
	"LD     I,A",		0, none,		/* ED47	*/

	"IN     C,(C)",		0, none,		/* ED48	*/
	"OUT    (C),C",		0, none,		/* ED49	*/
	"ADC    HL,BC",		0, none,		/* ED4A	*/
	"LD     BC,(%s)",	2, none,	       /* ED4B */
	undocumented,		0, none,		/* ED4C	*/
	"RETI",			0, none,		/* ED4D	*/
	undocumented,		0, none,		/* ED4E	*/
	"LD     R,A",		0, none,		/* ED4F	*/

	"IN     D,(C)",		0, none,		/* ED50	*/
	"OUT    (C),D",		0, none,		/* ED51	*/
	"SBC    HL,DE",		0, none,		/* ED52	*/
	"LD     (%s),DE",	2, none,	       /* ED53 */
	undocumented,		0, none,		/* ED54	*/
	undocumented,		0, none,		/* ED55	*/
	"IM     1",		0, none,		/* ED56	*/
	"LD     A,I",		0, none,		/* ED57	*/

	"IN     E,(C)",		0, none,		/* ED58	*/
	"OUT    (C),E",		0, none,		/* ED59	*/
	"ADC    HL,DE",		0, none,		/* ED5A	*/
	"LD     DE,(%s)",	2, none,	       /* ED5B */
	undocumented,		0, none,		/* ED5C	*/
	undocumented,		0, none,		/* ED5D	*/
	"IM     2",		0, none,		/* ED5E	*/
	"LD     A,R",		0, none,		/* ED5F	*/

	"IN     H,(C)",		0, none,		/* ED60	*/
	"OUT    (C),H",		0, none,		/* ED61	*/
	"SBC    HL,HL",		0, none,		/* ED62	*/
	undocumented,		0, none,		/* ED63	*/
	undocumented,		0, none,		/* ED64	*/
	undocumented,		0, none,		/* ED65	*/
	undocumented,		0, none,		/* ED66	*/
	"RRD",			0, none,		/* ED67	*/

	"IN     L,(C)",		0, none,		/* ED68	*/
	"OUT    (C),L",		0, none,		/* ED69	*/
	"ADC    HL,HL",		0, none,		/* ED6A	*/
	undocumented,		0, none,		/* ED6B	*/
	undocumented,		0, none,		/* ED6C	*/
	undocumented,		0, none,		/* ED6D	*/
	undocumented,		0, none,		/* ED6E	*/
	"RLD",			0, none,		/* ED6F	*/

	"IN     F,(C)",		0, none,		/* ED70	*/
	undocumented,		0, none,		/* ED71	*/
	"SBC    HL,SP",		0, none,		/* ED72	*/
	"LD     (%s),SP",	2, none,	       /* ED73 */
	undocumented,		0, none,		/* ED74	*/
	undocumented,		0, none,		/* ED75	*/
	undocumented,		0, none,		/* ED76	*/
	undocumented,		0, none,		/* ED77	*/

	"IN     A,(C)",		0, none,		/* ED78	*/
	"OUT    (C),A",		0, none,		/* ED79	*/
	"ADC    HL,SP",		0, none,		/* ED7A	*/
	"LD     SP,(%s)",	2, none,	       /* ED7B */
	undocumented,		0, none,		/* ED7C	*/
	undocumented,		0, none,		/* ED7D	*/
	undocumented,		0, none,		/* ED7E	*/
	undocumented,		0, none,		/* ED7F	*/

	undocumented,		0, none,		/* ED80	*/
	undocumented,		0, none,		/* ED81	*/
	undocumented,		0, none,		/* ED82	*/
	undocumented,		0, none,		/* ED83	*/
	undocumented,		0, none,		/* ED84	*/
	undocumented,		0, none,		/* ED85	*/
	undocumented,		0, none,		/* ED86	*/
	undocumented,		0, none,		/* ED87	*/

	undocumented,		0, none,		/* ED88	*/
	undocumented,		0, none,		/* ED89	*/
	undocumented,		0, none,		/* ED8A	*/
	undocumented,		0, none,		/* ED8B	*/
	undocumented,		0, none,		/* ED8C	*/
	undocumented,		0, none,		/* ED8D	*/
	undocumented,		0, none,		/* ED8E	*/
	undocumented,		0, none,		/* ED8F	*/

	undocumented,		0, none,		/* ED90	*/
	undocumented,		0, none,		/* ED91	*/
	undocumented,		0, none,		/* ED92	*/
	undocumented,		0, none,		/* ED93	*/
	undocumented,		0, none,		/* ED94	*/
	undocumented,		0, none,		/* ED95	*/
	undocumented,		0, none,		/* ED96	*/
	undocumented,		0, none,		/* ED97	*/

	undocumented,		0, none,		/* ED98	*/
	undocumented,		0, none,		/* ED99	*/
	undocumented,		0, none,		/* ED9A	*/
	undocumented,		0, none,		/* ED9B	*/
	undocumented,		0, none,		/* ED9C	*/
	undocumented,		0, none,		/* ED9D	*/
	undocumented,		0, none,		/* ED9E	*/
	undocumented,		0, none,		/* ED9F	*/

	"LDI",			0, none,		/* EDA0	*/
	"CPI",			0, none,		/* EDA1	*/
	"INI",			0, none,		/* EDA2	*/
	"OUTI",			0, none,		/* EDA3	*/
	undocumented,		0, none,		/* EDA4	*/
	undocumented,		0, none,		/* EDA5	*/
	undocumented,		0, none,		/* EDA6	*/
	undocumented,		0, none,		/* EDA7	*/

	"LDD",			0, none,		/* EDA8	*/
	"CPD",			0, none,		/* EDA9	*/
	"IND",			0, none,		/* EDAA	*/
	"OUTD",			0, none,		/* EDAB	*/
	undocumented,		0, none,		/* EDAC	*/
	undocumented,		0, none,		/* EDAD	*/
	undocumented,		0, none,		/* EDAE	*/
	undocumented,		0, none,		/* EDAF	*/

	"LDIR",			0, none,		/* EDB0	*/
	"CPIR",			0, none,		/* EDB1	*/
	"INIR",			0, none,		/* EDB2	*/
	"OTIR",			0, none,		/* EDB3	*/
	undocumented,		0, none,		/* EDB4	*/
	undocumented,		0, none,		/* EDB5	*/
	undocumented,		0, none,		/* EDB6	*/
	undocumented,		0, none,		/* EDB7	*/

	"LDDR",			0, none,		/* EDB8	*/
	"CPDR",			0, none,		/* EDB9	*/
	"INDR",			0, none,		/* EDBA	*/
	"OTDR",			0, none,		/* EDBB	*/
	undocumented,		0, none,		/* EDBC	*/
	undocumented,		0, none,		/* EDBD	*/
	undocumented,		0, none,		/* EDBE	*/
	undocumented,		0, none,		/* EDBF	*/

	undocumented,		0, none,		/* EDC0	*/
	undocumented,		0, none,		/* EDC1	*/
	undocumented,		0, none,		/* EDC2	*/
	undocumented,		0, none,		/* EDC3	*/
	undocumented,		0, none,		/* EDC4	*/
	undocumented,		0, none,		/* EDC5	*/
	undocumented,		0, none,		/* EDC6	*/
	undocumented,		0, none,		/* EDC7	*/

	undocumented,		0, none,		/* EDC8	*/
	undocumented,		0, none,		/* EDC9	*/
	undocumented,		0, none,		/* EDCA	*/
	undocumented,		0, none,		/* EDCB	*/
	undocumented,		0, none,		/* EDCC	*/
	undocumented,		0, none,		/* EDCD	*/
	undocumented,		0, none,		/* EDCE	*/
	undocumented,		0, none,		/* EDCF	*/

	undocumented,		0, none,		/* EDD0	*/
	undocumented,		0, none,		/* EDD1	*/
	undocumented,		0, none,		/* EDD2	*/
	undocumented,		0, none,		/* EDD3	*/
	undocumented,		0, none,		/* EDD4	*/
	undocumented,		0, none,		/* EDD5	*/
	undocumented,		0, none,		/* EDD6	*/
	undocumented,		0, none,		/* EDD7	*/

	undocumented,		0, none,		/* EDD8	*/
	undocumented,		0, none,		/* EDD9	*/
	undocumented,		0, none,		/* EDDA	*/
	undocumented,		0, none,		/* EDDB	*/
	undocumented,		0, none,		/* EDDC	*/
	undocumented,		0, none,		/* EDDD	*/
	undocumented,		0, none,		/* EDDE	*/
	undocumented,		0, none,		/* EDDF	*/

	undocumented,		0, none,		/* EDE0	*/
	undocumented,		0, none,		/* EDE1	*/
	undocumented,		0, none,		/* EDE2	*/
	undocumented,		0, none,		/* EDE3	*/
	undocumented,		0, none,		/* EDE4	*/
	undocumented,		0, none,		/* EDE5	*/
	undocumented,		0, none,		/* EDE6	*/
	undocumented,		0, none,		/* EDE7	*/

	undocumented,		0, none,		/* EDE8	*/
	undocumented,		0, none,		/* EDE9	*/
	undocumented,		0, none,		/* EDEA	*/
	undocumented,		0, none,		/* EDEB	*/
	undocumented,		0, none,		/* EDEC	*/
	undocumented,		0, none,		/* EDED	*/
	undocumented,		0, none,		/* EDEE	*/
	undocumented,		0, none,		/* EDEF	*/

	undocumented,		0, none,		/* EDF0	*/
	undocumented,		0, none,		/* EDF1	*/
	undocumented,		0, none,		/* EDF2	*/
	undocumented,		0, none,		/* EDF3	*/
	undocumented,		0, none,		/* EDF4	*/
	undocumented,		0, none,		/* EDF5	*/
	undocumented,		0, none,		/* EDF6	*/
	undocumented,		0, none,		/* EDF7	*/

	undocumented,		0, none,		/* EDF8	*/
	undocumented,		0, none,		/* EDF9	*/
	undocumented,		0, none,		/* EDFA	*/
	undocumented,		0, none,		/* EDFB	*/
	undocumented,		0, none,		/* EDFC	*/
	undocumented,		0, none,		/* EDFD	*/
	undocumented,		0, none,		/* EDFE	*/
	undocumented,		0, none			/* EDFF	*/
};

struct opcode dc[] = {
	"CALL_OZ(DC_INI)",	0, director,	/* 060C	*/
	"CALL_OZ(DC_BYE)",	0, director,	/* 080C	*/
	"CALL_OZ(DC_ENT)",	0, director,	/* 0A0C	*/
	"CALL_OZ(DC_NAM)",	0, director,	/* 0C0C	*/
	"CALL_OZ(DC_IN)",	0, director,	/* 0E0C	*/
	"CALL_OZ(DC_OUT)",	0, director,	/* 100C	*/
	"CALL_OZ(DC_PRT)",	0, director,	/* 120C	*/
	"CALL_OZ(DC_ICL)",	0, director,	/* 140C	*/
	"CALL_OZ(DC_NQ)",	0, director,	/* 160C	*/
	"CALL_OZ(DC_SP)",	0, director,	/* 180C	*/
	"CALL_OZ(DC_ALT)",	0, director,	/* 1A0C	*/
	"CALL_OZ(DC_RBD)",	0, director,	/* 1C0C	*/
	"CALL_OZ(DC_XIN)",	0, director,	/* 1E0C	*/
	"CALL_OZ(DC_GEN)",	0, director,	/* 200C	*/
	"CALL_OZ(DC_POL)",	0, director,	/* 220C	*/
	"CALL_OZ(DC_SCN)",	0, director,	/* 240C	*/
	"CALL_OZ(UNKNOWN)",	0, none
};

struct opcode os1[] = {
	"CALL_OZ(OS_BYE)",	0, director,	/* 21 */
	"CALL_OZ(OS_PRT)",	0, misc,	/* 24 */
	"CALL_OZ(OS_OUT)",	0, stdio,	/* 27 */
	"CALL_OZ(OS_IN)",	0, stdio,	/* 2A */
	"CALL_OZ(OS_TIN)",	0, stdio,	/* 2D */
	"CALL_OZ(OS_XIN)",	0, stdio,	/* 30 */
	"CALL_OZ(OS_PUR)",	0, stdio,	/* 33 */
	"CALL_OZ(OS_UGB)",	0, fileio,	/* 36 */
	"CALL_OZ(OS_GB)",	0, fileio,	/* 39 */
	"CALL_OZ(OS_PB)",	0, fileio,	/* 3C */
	"CALL_OZ(OS_GBT)",	0, fileio,	/* 3F */
	"CALL_OZ(OS_PBT)",	0, fileio,	/* 42 */
	"CALL_OZ(OS_MV)",	0, fileio,	/* 45 */
	"CALL_OZ(OS_FRM)",	0, fileio,	/* 48 */
	"CALL_OZ(OS_FWM)",	0, fileio,	/* 4B */
	"CALL_OZ(OS_MOP)",	0, memory,	/* 4E */
	"CALL_OZ(OS_MCL)",	0, memory,	/* 51 */
	"CALL_OZ(OS_MAL)",	0, memory,	/* 54 */
	"CALL_OZ(OS_MFR)",	0, memory,	/* 57 */
	"CALL_OZ(OS_MGB)",	0, memory,	/* 5A */
	"CALL_OZ(OS_MPB)",	0, memory,	/* 5D */
	"CALL_OZ(OS_BIX)",	0, memory,	/* 60 */
	"CALL_OZ(OS_BOX)",	0, memory,	/* 63 */
	"CALL_OZ(OS_NQ)",	0, syspar,	/* 66 */
	"CALL_OZ(OS_SP)",	0, syspar,	/* 69 */
	"CALL_OZ(OS_SR)",	0, saverestore,	/* 6C */
	"CALL_OZ(OS_ESC)",	0, error,	/* 6F */
	"CALL_OZ(OS_ERC)",	0, error,	/* 72 */
	"CALL_OZ(OS_ERH)",	0, error,	/* 75 */
	"CALL_OZ(OS_UST)",	0, timedate,	/* 78 */
	"CALL_OZ(OS_FN)",	0, misc,	/* 7B */
	"CALL_OZ(OS_WAIT)",	0, director,	/* 7E */
	"CALL_OZ(OS_ALM)",	0, alarm,	/* 81 */
	"CALL_OZ(OS_CLI)",	0, director,	/* 84 */
	"CALL_OZ(OS_DOR)",	0, dor,		/* 87 */
	"CALL_OZ(OS_FC)",	0, memory,	/* 8A */
	"CALL_OZ(OS_SI)",	0, serinterface,/* 8D */
	"CALL_OZ(UNKNOWN)",	0, none
};

struct opcode os2[] = {
	"CALL_OZ(OS_WTB)",	0, tokens,	/* CA06	*/
	"CALL_OZ(OS_WRT)",	0, tokens,	/* CC06	*/
	"CALL_OZ(OS_WSQ)",	0, misc,	/* CE06	*/
	"CALL_OZ(OS_ISQ)",	0, misc,	/* D006	*/
	"CALL_OZ(OS_AXP)",	0, memory,	/* D206	*/
	"CALL_OZ(OS_SCI)",	0, screen,	/* D406	*/
	"CALL_OZ(OS_DLY)",	0, timedate,	/* D606	*/
	"CALL_OZ(OS_BLP)",	0, misc,	/* D806	*/
	"CALL_OZ(OS_BDE)",	0, memory,	/* DA06	*/
	"CALL_OZ(OS_BHL)",	0, memory,	/* DC06	*/
	"CALL_OZ(OS_FTH)",	0, director,	/* DE06	*/
	"CALL_OZ(OS_VTH)",	0, director,	/* E006	*/
	"CALL_OZ(OS_GTH)",	0, director,	/* E206	*/
	"CALL_OZ(OS_REN)",	0, fileio,	/* E406	*/
	"CALL_OZ(OS_DEL)",	0, fileio,	/* E606	*/
	"CALL_OZ(OS_CL)",	0, fileio,	/* E806	*/
	"CALL_OZ(OS_OP)",	0, fileio,	/* EA06	*/
	"CALL_OZ(OS_OFF)",	0, screen,	/* EC06	*/
	"CALL_OZ(OS_USE)",	0, director,	/* EE06	*/
	"CALL_OZ(OS_EPR)",	0, fileio,	/* F006	*/
	"CALL_OZ(OS_HT)",	0, timedate,	/* F206	*/
	"CALL_OZ(OS_MAP)",	0, map,		/* F406	*/
	"CALL_OZ(OS_EXIT)",	0, director,	/* F606	*/
	"CALL_OZ(OS_STK)",	0, director,	/* F806	*/
	"CALL_OZ(OS_ENT)",	0, director,	/* FA06	*/
	"CALL_OZ(OS_POLL)",	0, director,	/* FC06	*/
	"CALL_OZ(OS_DOM)",	0, director,	/* FE06	*/
	"CALL_OZ(UNKNOWN)",	0, none
};

struct opcode gn[] = {
	"CALL_OZ(GN_GDT)",	0, timedate,	/* 0609	*/
	"CALL_OZ(GN_PDT)",	0, timedate,	/* 0809	*/
	"CALL_OZ(GN_GTM)",	0, timedate,	/* 0A09	*/
	"CALL_OZ(GN_PTM)",	0, timedate,	/* 0C09	*/
	"CALL_OZ(GN_SDO)",	0, timedate,	/* 0E09	*/
	"CALL_OZ(GN_GDN)",	0, integer,	/* 1009	*/
	"CALL_OZ(GN_PDN)",	0, integer,	/* 1209	*/
	"CALL_OZ(GN_DIE)",	0, timedate,	/* 1409	*/
	"CALL_OZ(GN_DEI)",	0, timedate,	/* 1609	*/
	"CALL_OZ(GN_GMD)",	0, timedate,	/* 1809	*/
	"CALL_OZ(GN_GMT)",	0, timedate,	/* 1A09	*/
	"CALL_OZ(GN_PMD)",	0, timedate,	/* 1C09	*/
	"CALL_OZ(GN_PMT)",	0, timedate,	/* 1E09	*/
	"CALL_OZ(GN_MSC)",	0, timedate,	/* 2009	*/
	"CALL_OZ(GN_FLO)",	0, filter,	/* 2209	*/
	"CALL_OZ(GN_FLC)",	0, filter,	/* 2409	*/
	"CALL_OZ(GN_FLW)",	0, filter,	/* 2609	*/
	"CALL_OZ(GN_FLR)",	0, filter,	/* 2809	*/
	"CALL_OZ(GN_FLF)",	0, filter,	/* 2A09	*/
	"CALL_OZ(GN_FPB)",	0, filter,	/* 2C09	*/
	"CALL_OZ(GN_NLN)",	0, stdio,	/* 2E09	*/
	"CALL_OZ(GN_CLS)",	0, chars,	/* 3009	*/
	"CALL_OZ(GN_SKC)",	0, chars,	/* 3209	*/
	"CALL_OZ(GN_SKD)",	0, chars,	/* 3409	*/
	"CALL_OZ(GN_SKT)",	0, chars,	/* 3609	*/
	"CALL_OZ(GN_SIP)",	0, stdio,	/* 3809	*/
	"CALL_OZ(GN_SOP)",	0, stdio,	/* 3A09	*/
	"CALL_OZ(GN_SOE)",	0, stdio,	/* 3C09	*/
	"CALL_OZ(GN_RBE)",	0, memory,	/* 3E09	*/
	"CALL_OZ(GN_WBE)",	0, memory,	/* 4009	*/
	"CALL_OZ(GN_CME)",	0, memory,	/* 4209	*/
	"CALL_OZ(GN_XNX)",	0, memory,	/* 4409	*/
	"CALL_OZ(GN_XIN)",	0, memory,	/* 4609	*/
	"CALL_OZ(GN_XDL)",	0, memory,	/* 4809	*/
	"CALL_OZ(GN_ERR)",	0, error,	/* 4A09	*/
	"CALL_OZ(GN_ESP)",	0, error,	/* 4C09	*/
	"CALL_OZ(GN_FCM)",	0, fileio,	/* 4E09	*/
	"CALL_OZ(GN_FEX)",	0, fileio,	/* 5009	*/
	"CALL_OZ(GN_OPW)",	0, fileio,	/* 5209	*/
	"CALL_OZ(GN_WCL)",	0, fileio,	/* 5409	*/
	"CALL_OZ(GN_WFN)",	0, fileio,	/* 5609	*/
	"CALL_OZ(GN_PRS)",	0, fileio,	/* 5809	*/
	"CALL_OZ(GN_PFS)",	0, fileio,	/* 5A09	*/
	"CALL_OZ(GN_WSM)",	0, fileio,	/* 5C09	*/
	"CALL_OZ(GN_ESA)",	0, fileio,	/* 5E09	*/
	"CALL_OZ(GN_OPF)",	0, fileio,	/* 6009	*/
	"CALL_OZ(GN_CL)",	0, fileio,	/* 6209	*/
	"CALL_OZ(GN_DEL)",	0, fileio,	/* 6409	*/
	"CALL_OZ(GN_REN)",	0, fileio,	/* 6609	*/
	"CALL_OZ(GN_AAB)",	0, alarm,	/* 6809	*/
	"CALL_OZ(GN_FAB)",	0, alarm,	/* 6A09	*/
	"CALL_OZ(GN_LAB)",	0, alarm,	/* 6C09	*/
	"CALL_OZ(GN_UAB)",	0, alarm,	/* 6E09	*/
	"CALL_OZ(GN_ALP)",	0, alarm,	/* 7009	*/
	"CALL_OZ(GN_M16)",	0, integer,	/* 7209	*/
	"CALL_OZ(GN_D16)",	0, integer,	/* 7409	*/
	"CALL_OZ(GN_M24)",	0, integer,	/* 7609	*/
	"CALL_OZ(GN_D24)",	0, integer,	/* 7809	*/
	"CALL_OZ(UNKNOWN)",	0, none
};

struct opcode fpp[] = {
	"FPP(FP_AND)",		0, floatp,	   /* 21 */
	"FPP(FP_IDV)",		0, floatp,	   /* 24 */
	"FPP(FP_EOR)",		0, floatp,	   /* 27 */
	"FPP(FP_MOD)",		0, floatp,	   /* 2A */
	"FPP(FP_OR)",		0, floatp,	   /* 2D */
	"FPP(FP_LEQ)",		0, floatp,	   /* 30 */
	"FPP(FP_NEQ)",		0, floatp,	   /* 33 */
	"FPP(FP_GEQ)",		0, floatp,	   /* 36 */
	"FPP(FP_LT)",		0, floatp,	   /* 39 */
	"FPP(FP_EQ)",		0, floatp,	   /* 3C */
	"FPP(FP_MUL)",		0, floatp,	   /* 3F */
	"FPP(FP_ADD)",		0, floatp,	   /* 42 */
	"FPP(FP_GT)",		0, floatp,	   /* 45 */
	"FPP(FP_SUB)",		0, floatp,	   /* 48 */
	"FPP(FP_PWR)",		0, floatp,	   /* 4B */
	"FPP(FP_DIV)",		0, floatp,	   /* 4E */
	"FPP(FP_ABS)",		0, floatp,	   /* 51 */
	"FPP(FP_ACS)",		0, floatp,	   /* 54 */
	"FPP(FP_ASN)",		0, floatp,	   /* 57 */
	"FPP(FP_ATN)",		0, floatp,	   /* 5A */
	"FPP(FP_COS)",		0, floatp,	   /* 5D */
	"FPP(FP_DEG)",		0, floatp,	   /* 60 */
	"FPP(FP_EXP)",		0, floatp,	   /* 63 */
	"FPP(FP_INT)",		0, floatp,	   /* 66 */
	"FPP(FP_LN)",		0, floatp,	   /* 69 */
	"FPP(FP_LOG)",		0, floatp,	   /* 6C */
	"FPP(FP_NOT)",		0, floatp,	   /* 6F */
	"FPP(FP_RAD)",		0, floatp,	   /* 72 */
	"FPP(FP_SGN)",		0, floatp,	   /* 75 */
	"FPP(FP_SIN)",		0, floatp,	   /* 78 */
	"FPP(FP_SQR)",		0, floatp,	   /* 7B */
	"FPP(FP_TAN)",		0, floatp,	   /* 7E */
	"FPP(FP_ZER)",		0, floatp,	   /* 81 */
	"FPP(FP_ONE)",		0, floatp,	   /* 84 */
	"FPP(FP_TRU)",		0, floatp,	   /* 87 */
	"FPP(FP_PI)",		0, floatp,	   /* 8A */
	"FPP(FP_VAL)",		0, floatp,	   /* 8D */
	"FPP(FP_STR)",		0, floatp,	   /* 90 */
	"FPP(FP_FIX)",		0, floatp,	   /* 93 */
	"FPP(FP_FLT)",		0, floatp,	   /* 96 */
	"FPP(FP_TST)",		0, floatp,	   /* 99 */
	"FPP(FP_CMP)",		0, floatp,	   /* 9C */
	"FPP(FP_NEG)",		0, floatp,	   /* 9F */
	"FPP(FP_BAS)",		0, floatp,	   /* A2 */
	"FPP(UNKNOWN)",		0, none
};


/* Modified slightly by	dnh@mfltd.co.uk	to put the formatted output in
 * a string instead of sending it to stdout.  <str> must have space
 * allocated for it.
 *
 * Algorithm logic changed by Gunther Strube (gbs@image.dk) for	additional tables
 * for DD CB, FD CB and	Z88 OS manifests.
 */
long	Disassemble(char *str, long pc, enum truefalse dispaddr)
{
	signed short	i, j;
	struct opcode	*code, *table;
	long		addr;
	char		tmpstr[64], operand[64], operand2[64], hexopc[4], spaces[16];
	long		opcodes[4], opc;
	LabelRef	*foundlabel;
	Expression	*foundexpr;
	GlobalConstant	*foundconst;

	str[0] = '\0';
	addr = pc;
	opc = 0;

	tmpstr[0] = '\0'; operand[0] = '\0'; operand2[0] = '\0'; hexopc[0] = '\0'; spaces[0] = '\0';

	i = GetByte(pc++);
	opcodes[opc++] = i;

    switch(i) {
	case 203:	/* CB opcode table */
			table =	cb;
			i = GetByte(pc++);
			opcodes[opc++] = i;
			break;

	case 237:	/* ED opcode table */
			table =	ed;
			i = GetByte(pc++);
			opcodes[opc++] = i;
			break;

	case 221:	/* DD CB opcode	table */
			i = GetByte(pc);
			if (i == 203) {
				table =	ddcb;
				opcodes[opc++] = i;
				i = GetByte(pc+2);
				pc++;
			}
			else {
				table =	dd;
				i = GetByte(pc++);
				opcodes[opc++] = i;
			}
			break;

	case 253:	/* FD CB opcode	table */
			i = GetByte(pc);
			if (i == 203) {
				table =	fdcb;
				opcodes[opc++] = i;
				i = GetByte(pc+2);
				pc++;
			}
			else {
				table =	fd;
				i = GetByte(pc++);
				opcodes[opc++] = i;
			}
			break;

	case 223:	/* RST 18h, FPP	interface */
			i = GetByte(pc++);
			opcodes[opc++] = i;
			table =	fpp;
			if ((i%3 == 0) && (i>=0x21 && i<=0xa2))
				i = (i / 3) - 11;
			else
				i = 44;	/* signal unknown FPP parameter	*/
			break;

	case 231:	/* RST 20h, main OS interface */
			i = GetByte(pc++);
			opcodes[opc++] = i;
			switch(i) {
				case 6:	/* OS 2	byte low level calls */
					table =	os2;
					i = GetByte(pc++);
					opcodes[opc++] = i;
					if ((i%2 == 0) && (i>=0xca && i<=0xfe))
						i = (i / 2) - 101;
					else
						i = 26;	/* unknown parameter */
					break;

				case 9:	/* GN 2	byte general calls */
					table =	gn;
					i = GetByte(pc++);
					opcodes[opc++] = i;
					if ((i%2 == 0) && (i>=0x06 && i<=0x78))
						i = (i / 2) - 3;
					else
						i = 58;	/* unknown parameter */
					break;

				case 12: /* DC 2 byte low level	calls */
					table =	dc;
					i = GetByte(pc++);
					opcodes[opc++] = i;
					if ((i%2 == 0) && (i>=0x06 && i<=0x24))
						i = (i / 2) - 3;
					else
						i = 16;	/* unknown parameter */
					break;

				default: /* OS 1 byte low level	calls */
					table =	os1;
					if ((i%3 == 0) && (i>=0x21 && i<=0x8d))
						i = (i / 3) - 11;
					else
						i = 37;	/* unknown parameter */
			}
			break;

	default:	/* standard Z80	(Intel 8080 compatible)	opcodes	*/
			table =	mn;
    }

    code = &table[i];

    if (dispaddr == true) sprintf (str,	"%04lX  ", addr);

    switch (code->args)	{
	case 2:
		addr = (unsigned char) GetByte(pc);
		opcodes[opc++] = addr;
		opcodes[opc++] = GetByte(pc+1);
		addr +=	(unsigned short) (256 * GetByte(pc+1));

		LabelAddr(operand, pc, addr, dispaddr);		/* write the 16bit address in correct format */
		sprintf(tmpstr,	code->name, operand);
		pc += 2;
		break;

	case 1:
		opcodes[opc] = GetByte(pc);
		foundexpr = find(gExpressions, &pc, (int (*)()) CmpExprAddr2);
		if (foundexpr != NULL) {
			/* an expression was defined for this operand */
			sprintf(operand, "%s", foundexpr->expr);
		} else {
			foundconst = find(gGlobalConstants, &opcodes[opc], (int (*)()) CmpConstant2);
			if (foundconst != NULL) {
				sprintf(operand, "%s", foundconst->constname);
			} else {
				sprintf(operand, "$%02X", GetByte(pc));
			}
		}

		opc++;
		sprintf(tmpstr,	code->name, operand);
		pc++;
		break;

	case 0:
		sprintf	(tmpstr, code->name);
		break;

	case -1: /* relative addressing	*/
		opcodes[opc++] = GetByte(pc);
		addr = (pc + 1 + (char) GetByte(pc));

		foundlabel = find(gLabelRef, &addr, (int (*)()) CmpAddrRef2);
		if (foundlabel == NULL)
			sprintf(operand, "L_%04lX", addr);
		else {
			if (foundlabel->name != NULL) {
				if (dispaddr == true)
					sprintf(operand, "%s/$%04lX", foundlabel->name, addr);
				else
					sprintf(operand, "%s", foundlabel->name);
			} else {
				sprintf(operand, "L_%04lX", addr);
			}
		}

		sprintf(tmpstr,	code->name, operand);
		pc++;
		break;

	case -2: /* ix/iy bit manipulation */
	        j = i;
		i= (char) GetByte(pc);
		opcodes[opc++] = i;
		opcodes[opc++] = j;

		foundexpr = find(gExpressions, &pc, (int (*)()) CmpExprAddr2);
		if (foundexpr != NULL) {
			/* an expression was defined for this operand */
			sprintf(operand, "+%s", foundexpr->expr);
		} else {
			if (i >= 0)
				sprintf(operand, "+%d",	i);
			else
				sprintf(operand, "%d", i);
		}

		sprintf	(tmpstr, code->name, operand);
		pc += 2; /* move past opcode */
		break;

	case -3: /* LD (IX/IY+r),n */
		i= (char) GetByte(pc); opcodes[opc++] = i;
		foundexpr = find(gExpressions, &pc, (int (*)()) CmpExprAddr2);
		if (foundexpr != NULL) {
			/* an expression was defined for this operand */
			sprintf(operand, "+%s", foundexpr->expr);
		} else {
			if (i >= 0)
				sprintf(operand, "+%d",	i);
			else
				sprintf(operand, "%d", i);
		}
		pc++;

		j=GetByte(pc); opcodes[opc] = j;
		foundexpr = find(gExpressions, &pc, (int (*)()) CmpExprAddr2);
		if (foundexpr != NULL) {
			/* an expression was defined for this operand */
			sprintf(operand2, "%s", foundexpr->expr);
		} else {
			foundconst = find(gGlobalConstants, &opcodes[opc], (int (*)()) CmpConstant2);
			if (foundconst != NULL)
				/* a global constant name was found for this operand */
				sprintf(operand2, "%s", foundconst->constname);
			else
				sprintf(operand2, "$%02X", GetByte(pc));
		}
		opc++;
		pc++;
		sprintf	(tmpstr, code->name, operand, operand2);
		break;

	case -4: /* IX/IY offset, positive/negative constant presentation */
		i = (char) GetByte(pc);
		opcodes[opc++] = i;

		foundexpr = find(gExpressions, &pc, (int (*)()) CmpExprAddr2);
		if (foundexpr != NULL) {
			/* an expression was defined for this operand */
			sprintf(operand, "+%s", foundexpr->expr);
		} else {
			if (i >= 0)
				sprintf(operand, "+%d",	i);
			else
				sprintf(operand, "%d", i);
		}

		sprintf	(tmpstr, code->name, operand);	/* insert operand in mnemonic */
		pc++;
		break;
    }

    if (dispaddr == true) {
    	/* add opcode string sequense before mnemonics */
    	for(i=0; i<opc; i++) {
    		sprintf(hexopc, "%02X ", opcodes[i]);
    		strcat(str,hexopc);
    	}

    	/* add trailing spaces to adjust until mnemonic column */
    	for(i=((4 - opc) * 3); i>0; i--) strcat(str, " ");
    }

    strcat(str, tmpstr);
    /* strcpy(str,tmpstr); */

    return pc;	/* return the location of the next instruction */
}


void	LabelAddr(char *operand, long pc, long addr, enum truefalse dispaddr)
{
	LabelRef	*foundlabel;
	Expression	*foundexpr;
	GlobalConstant	*foundconst;

	foundlabel = find(gLabelRef, &addr, (int (*)()) CmpAddrRef2);
	foundexpr = find(gExpressions, &pc, (int (*)()) CmpExprAddr2);
	foundconst = find(gGlobalConstants, &addr, (int (*)()) CmpConstant2);

	if (foundexpr != NULL) {
		/* an expression was defined for this operand */
		sprintf(operand, "%s", foundexpr->expr);
	} else {
		if (foundlabel == NULL)
			if (foundconst != NULL) {
				if (dispaddr == true)
					sprintf(operand, "%s/$%04lX", foundconst->constname, addr);
				else
					sprintf(operand, "%s", foundconst->constname);
			} else {
				sprintf(operand, "$%04lX", addr);
			}
		else {
			if (foundlabel != NULL)	{
				if (foundlabel->addrref == false && foundconst != NULL) {
					/* A data reference */
					/* Add a global constant name in stead of just a hex digit ... */
					if (dispaddr == true)
						sprintf(operand, "%s/$%04lX", foundconst->constname, addr);
					else
						sprintf(operand, "%s", foundconst->constname);
					return;
				}
				if ((SearchArea(gExtern, addr) != notfound)) {
					/* address in extern code area */
					if (foundlabel->xref == false)
						/* This label has not been declared as XREF */
						if (foundconst != NULL) {
							/* Add a global constant name in stead of just a hex digit ... */
							if (dispaddr == true)
								sprintf(operand, "%s/$%04lX", foundconst->constname, addr);
							else
								sprintf(operand, "%s", foundconst->constname);
						} else {
							sprintf(operand, "$%04lX", addr);	/* outside scope of this program */
						}
					else {
						/* XREF declared label */
						if (foundlabel->name != NULL) {
							if (dispaddr == true)
								sprintf(operand, "%s/$%04lX", foundlabel->name, addr);
							else
								sprintf(operand, "%s", foundlabel->name);
						} else {
							sprintf(operand, "L_%04lX", addr);
						}
					}
				} else {
					/* Local label */
					if (foundlabel->name != NULL) {
						if (dispaddr == true)
							sprintf(operand, "%s/$%04lX", foundlabel->name, addr);
						else
							sprintf(operand, "%s", foundlabel->name);
					} else {
						sprintf(operand, "L_%04lX", addr);
					}
				}
			} else {
				if (foundconst != NULL) {
					if (dispaddr == true)
						sprintf(operand, "%s/$%04lX", foundconst->constname, addr);
					else
						sprintf(operand, "%s", foundconst->constname);
				} else {
					sprintf(operand, "$%04lX", addr);	/* No address label reference, use constant... */
				}
			}
		}
	}
}

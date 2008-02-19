
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
{ 	"nop",			0, none,		/* 00 */
	"ld      bc,%s",	2, none,		/* 01 */
	"ld      (bc),a",	0, none,		/* 02 */
	"inc     bc",		0, none,		/* 03 */
	"inc     b",		0, none,		/* 04 */
	"dec     b",		0, none,		/* 05 */
	"ld      b,%s",		1, none,		/* 06 */
	"rlca",			0, none,		/* 07 */

	"ex      af,af'",	0, none,		/* 08 */
	"add     hl,bc",	0, none,		/* 09 */
	"ld      a,(bc)",	0, none,		/* 0A */
	"dec     bc",		0, none,		/* 0B */
	"inc     c",		0, none,		/* 0C */
	"dec     c",		0, none,		/* 0D */
	"ld      c,%s",		1, none,		/* 0E */
	"rrca",	 		0, none,		/* 0F */

	"djnz    %s",		-1, none,		/* 10 */
	"ld      de,%s",	2, none,		/* 11 */
	"ld      (de),a",	0, none,		/* 12 */
	"inc     de",		0, none,		/* 13 */
	"inc     d",		0, none,		/* 14 */
	"dec     d",		0, none,		/* 15 */
	"ld      d,%s",		1, none,		/* 16 */
	"rla",	 		0, none,		/* 17 */

	"jr      %s",		-1, none,		/* 18 */
	"add     hl,de",	0, none,		/* 19 */
	"ld      a,(de)",	0, none,		/* 1A */
	"dec     de",		0, none,		/* 1B */
	"inc     e",		0, none,		/* 1C */
	"dec     e",		0, none,		/* 1D */
	"ld      e,%s",		1, none,		/* 1E */
	"rra",	 		0, none,		/* 1F */

	"jr      nz,%s",	-1, none,		/* 20 */
	"ld      hl,%s",	2, none,		/* 21 */
	"ld      (%s),hl",	2, none,	       /* 22 */
	"inc     hl",		0, none,		/* 23 */
	"inc     h",		0, none,		/* 24 */
	"dec     h",		0, none,		/* 25 */
	"ld      h,%s",		1, none,		/* 26 */
	"daa",	 		0, none,		/* 27 */

	"jr      z,%s",		-1, none,		/* 28 */
	"add     hl,hl",	0, none,		/* 29 */
	"ld      hl,(%s)",	2, none,	       /* 2A */
	"dec     hl",		0, none,		/* 2B */
	"inc     l",		0, none,		/* 2C */
	"dec     l",		0, none,		/* 2D */
	"ld      l,%s",		1, none,		/* 2E */
	"cpl",	 		0, none,		/* 2F */

	"jr      nc,%s",	-1, none,		/* 30 */
	"ld      sp,%s",	2, none,	       /* 31 */
	"ld      (%s),a",	2, none,	       /* 32 */
	"inc     sp",		0, none,		/* 33 */
	"inc     (hl)",		0, none,		/* 34 */
	"dec     (hl)",		0, none,		/* 35 */
	"ld      (hl),%s",	1, none,		/* 36 */
	"scf",	 		0, none,		/* 37 */

	"jr      c,%s",		-1, none,		/* 38 */
	"add     hl,sp",	0, none,		/* 39 */
	"ld      a,(%s)",	2, none,	       /* 3A */
	"dec     sp",		0, none,		/* 3B */
	"inc     a",		0, none,		/* 3C */
	"dec     a",		0, none,		/* 3D */
	"ld      a,%s",		1, none,		/* 3E */
	"ccf",	 		0, none,		/* 3F */

	"ld      b,b",		0, none,		/* 40 */
	"ld      b,c",		0, none,		/* 41 */
	"ld      b,d",		0, none,		/* 42 */
	"ld      b,e",		0, none,		/* 43 */
	"ld      b,h",		0, none,		/* 44 */
	"ld      b,l",		0, none,		/* 45 */
	"ld      b,(hl)",	0, none,		/* 46 */
	"ld      b,a",		0, none,		/* 47 */

	"ld      c,b",		0, none,		/* 48 */
	"ld      c,c",		0, none,		/* 49 */
	"ld      c,d",		0, none,		/* 4A */
	"ld      c,e",		0, none,		/* 4B */
	"ld      c,h",		0, none,		/* 4C */
	"ld      c,l",		0, none,		/* 4D */
	"ld      c,(hl)",	0, none,		/* 4E */
	"ld      c,a",		0, none,		/* 4F */

	"ld      d,b",		0, none,		/* 50 */
	"ld      d,c",		0, none,		/* 51 */
	"ld      d,d",		0, none,		/* 52 */
	"ld      d,e",		0, none,		/* 53 */
	"ld      d,h",		0, none,		/* 54 */
	"ld      d,l",		0, none,		/* 55 */
	"ld      d,(hl)",	0, none,		/* 56 */
	"ld      d,a",		0, none,		/* 57 */

	"ld      e,b",		0, none,		/* 58 */
	"ld      e,c",		0, none,		/* 59 */
	"ld      e,d",		0, none,		/* 5A */
	"ld      e,e",		0, none,		/* 5B */
	"ld      e,h",		0, none,		/* 5C */
	"ld      e,l",		0, none,		/* 5D */
	"ld      e,(hl)",	0, none,		/* 5E */
	"ld      e,a",		0, none,		/* 5F */

	"ld      h,b",		0, none,		/* 60 */
	"ld      h,c",		0, none,		/* 61 */
	"ld      h,d",		0, none,		/* 62 */
	"ld      h,e",		0, none,		/* 63 */
	"ld      h,h",		0, none,		/* 64 */
	"ld      h,l",		0, none,		/* 65 */
	"ld      h,(hl)",	0, none,		/* 66 */
	"ld      h,a",		0, none,		/* 67 */

	"ld      l,b",		0, none,		/* 68 */
	"ld      l,c",		0, none,		/* 69 */
	"ld      l,d",		0, none,		/* 6A */
	"ld      l,e",		0, none,		/* 6B */
	"ld      l,h",		0, none,		/* 6C */
	"ld      l,l",		0, none,		/* 6D */
	"ld      l,(hl)",	0, none,		/* 6E */
	"ld      l,a",		0, none,		/* 6F */

	"ld      (hl),b",	0, none,		/* 70 */
	"ld      (hl),c",	0, none,		/* 71 */
	"ld      (hl),d",	0, none,		/* 72 */
	"ld      (hl),e",	0, none,		/* 73 */
	"ld      (hl),h",	0, none,		/* 74 */
	"ld      (hl),l",	0, none,		/* 75 */
	"halt",	 		0, none,		/* 76 */
	"ld      (hl),a",	0, none,		/* 77 */

	"ld      a,b",		0, none,		/* 78 */
	"ld      a,c",		0, none,		/* 79 */
	"ld      a,d",		0, none,		/* 7A */
	"ld      a,e",		0, none,		/* 7B */
	"ld      a,h",		0, none,		/* 7C */
	"ld      a,l",		0, none,		/* 7D */
	"ld      a,(hl)",	0, none,		/* 7E */
	"ld      a,a",		0, none,		/* 7F */

	"add     a,b",		0, none,		/* 80 */
	"add     a,c",		0, none,		/* 81 */
	"add     a,d",		0, none,		/* 82 */
	"add     a,e",		0, none,		/* 83 */
	"add     a,h",		0, none,		/* 84 */
	"add     a,l",		0, none,		/* 85 */
	"add     a,(hl)",	0, none,		/* 86 */
	"add     a,a",		0, none,		/* 87 */

	"adc     a,b",		0, none,		/* 88 */
	"adc     a,c",		0, none,		/* 89 */
	"adc     a,d",		0, none,		/* 8A */
	"adc     a,e",		0, none,		/* 8B */
	"adc     a,h",		0, none,		/* 8C */
	"adc     a,l",		0, none,		/* 8D */
	"adc     a,(hl)",	0, none,		/* 8E */
	"adc     a,a",		0, none,		/* 8F */

	"sub     b",		0, none,		/* 90 */
	"sub     c",		0, none,		/* 91 */
	"sub     d",		0, none,		/* 92 */
	"sub     e",		0, none,		/* 93 */
	"sub     h",		0, none,		/* 94 */
	"sub     l",		0, none,		/* 95 */
	"sub     (hl)",		0, none,		/* 96 */
	"sub     a",		0, none,		/* 97 */

	"sbc     a,b",		0, none,		/* 98 */
	"sbc     a,c",		0, none,		/* 99 */
	"sbc     a,d",		0, none,		/* 9A */
	"sbc     a,e",		0, none,		/* 9B */
	"sbc     a,h",		0, none,		/* 9C */
	"sbc     a,l",		0, none,		/* 9D */
	"sbc     a,(hl)",	0, none,		/* 9E */
	"sbc     a,a",		0, none,		/* 9F */

	"and     b",		0, none,		/* A0 */
	"and     c",		0, none,		/* A1 */
	"and     d",		0, none,		/* A2 */
	"and     e",		0, none,		/* A3 */
	"and     h",		0, none,		/* A4 */
	"and     l",		0, none,		/* A5 */
	"and     (hl)",		0, none,		/* A6 */
	"and     a",		0, none,		/* A7 */

	"xor     b",		0, none,		/* A8 */
	"xor     c",		0, none,		/* A9 */
	"xor     d",		0, none,		/* AA */
	"xor     e",		0, none,		/* AB */
	"xor     h",		0, none,		/* AC */
	"xor     l",		0, none,		/* AD */
	"xor     (hl)",		0, none,		/* AE */
	"xor     a",		0, none,		/* AF */

	"or      b",		0, none,		/* B0 */
	"or      c",		0, none,		/* B1 */
	"or      d",		0, none,		/* B2 */
	"or      e",		0, none,		/* B3 */
	"or      h",		0, none,		/* B4 */
	"or      l",		0, none,		/* B5 */
	"or      (hl)",		0, none,		/* B6 */
	"or      a",		0, none,		/* B7 */

	"cp      b",		0, none,		/* B8 */
	"cp      c",		0, none,		/* B9 */
	"cp      d",		0, none,		/* BA */
	"cp      e",		0, none,		/* BB */
	"cp      h",		0, none,		/* BC */
	"cp      l",		0, none,		/* BD */
	"cp      (hl)",		0, none,		/* BE */
	"cp      a",		0, none,		/* BF */

	"ret     nz",		0, none,		/* C0 */
	"pop     bc",		0, none,		/* C1 */
	"jp      nz,%s",	2, none,		/* C2 */
	"jp      %s",		2, none,		/* C3 */
	"call    nz,%s",	2, none,		/* C4 */
	"push    bc",		0, none,		/* C5 */
	"add     a,%s",		1, none,		/* C6 */
	"rst     0",		0, none,		/* C7 */

	"ret     z",		0, none,		/* C8 */
	"ret",	 		0, none,		/* C9 */
	"jp      z,%s",		2, none,		/* CA */
	0,	 		0, none,		/* CB ,	BIT MANIPULATION OPCODES */
	"call    z,%s",		2, none,		/* CC */
	"call    %s",		2, none,		/* CD */
	"adc     a,%s",		1, none,		/* CE */
	"rst     $08",		0, none,		/* CF */

	"ret     nc",		0, none,		/* D0 */
	"pop     de",		0, none,		/* D1 */
	"jp      nc,%s",	2, none,		/* D2 */
	"out     (%s),a",	1, none,		/* D3 */
	"call    nc,%s",	2, none,		/* D4 */
	"push    de",		0, none,		/* D5 */
	"sub     %s",		1, none,		/* D6 */
	"rst     $10",		0, none,		/* D7 */

	"ret     c",		0, none,		/* D8 */
	"exx",	 		0, none,		/* D9 */
	"jp      c,%s",		2, none,		/* DA */
	"in      a,(%s)",	1, none,		/* DB */
	"call    c,%s",		2, none,		/* DC */
	0,	 		0, none,		/* DD ,	IX  none,OPCODES */
	"sbc     a,%s",		1, none,		/* DE */
	"rst     $18",		0, none,		/* DF */

	"ret     po",		0, none,		/* E0 */
	"pop     hl",		0, none,		/* E1 */
	"jp      po,%s",	2, none,		/* E2 */
	"ex      (sp),hl",	0, none,		/* E3 */
	"call    po,%s",	2, none,		/* E4 */
	"push    hl",		0, none,		/* E5 */
	"and     %s",		1, none,		/* E6 */
	"rst     $20",		0, none,		/* E7 */
	"ret     pe",		0, none,		/* E8 */

	"jp      (hl)",		0, none,		/* E9 */
	"jp      pe,%s",	2, none,		/* EA */
	"ex      de,hl",	0, none,		/* EB */
	"call    pe,%s",	2, none,		/* EC */
	0,	 		0, none,		/* ED OPCODES */
	"xor     %s",		1, none,		/* EE */
	"rst     $28",		0, none,		/* EF */

	"ret     p",		0, none,		/* F0 */
	"pop     af",		0, none,		/* F1 */
	"jp      p,%s",		2, none,		/* F2 */
	"di",	 		0, none,		/* F3 */
	"call    p,%s",		2, none,		/* F4 */
	"push    af",		0, none,		/* F5 */
	"or      %s",		1, none,		/* F6 */
	"rst     $30",		0, none,		/* F7 */

	"ret     m",		0, none,		/* F8 */
	"ld      sp,hl",	0, none,		/* F9 */
	"jp      m,%s",		2, none,		/* FA */
	"ei",	 		0, none,		/* FB */
	"call    m,%s",		2, none,		/* FC */
	0,	 		0, none,		/* FD, IY  none,OPCODES	*/
	"cp      %s",		1, none,		/* FE */
	"rst     $38",		0, none			/* FF */
};

struct opcode cb[] = {
	"rlc     b",		0, none,		/* CB00	*/
	"rlc     c",		0, none,		/* CB01	*/
	"rlc     d",		0, none,		/* CB02	*/
	"rlc     e",		0, none,		/* CB03	*/
	"rlc     h",		0, none,		/* CB04	*/
	"rlc     l",		0, none,		/* CB05	*/
	"rlc     (hl)",		0, none,		/* CB06	*/
	"rlc     a",		0, none,		/* CB07	*/

	"rrc     b",		0, none,		/* CB08	*/
	"rrc     c",		0, none,		/* CB09	*/
	"rrc     d",		0, none,		/* CB0A	*/
	"rrc     e",		0, none,		/* CB0B	*/
	"rrc     h",		0, none,		/* CB0C	*/
	"rrc     l",		0, none,		/* CB0D	*/
	"rrc     (hl)",		0, none,		/* CB0E	*/
	"rrc     a",		0, none,		/* CB0F	*/

	"rl      b",		0, none,		/* CB10	*/
	"rl      c",		0, none,		/* CB11	*/
	"rl      d",		0, none,		/* CB12	*/
	"rl      e",		0, none,		/* CB13	*/
	"rl      h",		0, none,		/* CB14	*/
	"rl      l",		0, none,		/* CB15	*/
	"rl      (hl)",		0, none,		/* CB16	*/
	"rl      a",		0, none,		/* CB17	*/

	"rr      b",		0, none,		/* CB18	*/
	"rr      c",		0, none,		/* CB19	*/
	"rr      d",		0, none,		/* CB1A	*/
	"rr      e",		0, none,		/* CB1B	*/
	"rr      h",		0, none,		/* CB1C	*/
	"rr      l",		0, none,		/* CB1D	*/
	"rr      (hl)",		0, none,		/* CB1E	*/
	"rr      a",		0, none,		/* CB1F	*/

	"sla     b",		0, none,		/* CB20	*/
	"sla     c",		0, none,		/* CB21	*/
	"sla     d",		0, none,		/* CB22	*/
	"sla     e",		0, none,		/* CB23	*/
	"sla     h",		0, none,		/* CB24	*/
	"sla     l",		0, none,		/* CB25	*/
	"sla     (hl)",		0, none,		/* CB26	*/
	"sla     a",		0, none,		/* CB27	*/

	"sra     b",		0, none,		/* CB28	*/
	"sra     c",		0, none,		/* CB29	*/
	"sra     d",		0, none,		/* CB2A	*/
	"sra     e",		0, none,		/* CB2B	*/
	"sra     h",		0, none,		/* CB2C	*/
	"sra     l",		0, none,		/* CB2D	*/
	"sra     (hl)",		0, none,		/* CB2E	*/
	"sra     a",		0, none,		/* CB2F	*/

	"sll     b",		0, none,		/* CB30, undocumented */
	"sll     c",		0, none,		/* CB31, undocumented */
	"sll     d",		0, none,		/* CB32, undocumented */
	"sll     e",		0, none,		/* CB33, undocumented */
	"sll     h",		0, none,		/* CB34, undocumented */
	"sll     l",		0, none,		/* CB35, undocumented */
	"sll     (hl)",		0, none,		/* CB36, undocumented */
	"sll     a",		0, none,		/* CB37, undocumented */

	"srl     b",		0, none,		/* CB38	*/
	"srl     c",		0, none,		/* CB39	*/
	"srl     d",		0, none,		/* CB3A	*/
	"srl     e",		0, none,		/* CB3B	*/
	"srl     h",		0, none,		/* CB3C	*/
	"srl     l",		0, none,		/* CB3D	*/
	"srl     (hl)",		0, none,		/* CB3E	*/
	"srl     a",		0, none,		/* CB3F	*/

	"bit     0,b",		0, none,		/* CB40	*/
	"bit     0,c",		0, none,		/* CB41	*/
	"bit     0,d",		0, none,		/* CB42	*/
	"bit     0,e",		0, none,		/* CB43	*/
	"bit     0,h",		0, none,		/* CB44	*/
	"bit     0,l",		0, none,		/* CB45	*/
	"bit     0,(hl)",	0, none,		/* CB46	*/
	"bit     0,a",		0, none,		/* CB47	*/

	"bit     1,b",		0, none,		/* CB48	*/
	"bit     1,c",		0, none,		/* CB49	*/
	"bit     1,d",		0, none,		/* CB4A	*/
	"bit     1,e",		0, none,		/* CB4B	*/
	"bit     1,h",		0, none,		/* CB4C	*/
	"bit     1,l",		0, none,		/* CB4D	*/
	"bit     1,(hl)",	0, none,		/* CB4E	*/
	"bit     1,a",		0, none,		/* CB4F	*/

	"bit     2,b",		0, none,		/* CB50	*/
	"bit     2,c",		0, none,		/* CB51	*/
	"bit     2,d",		0, none,		/* CB52	*/
	"bit     2,e",		0, none,		/* CB53	*/
	"bit     2,h",		0, none,		/* CB54	*/
	"bit     2,l",		0, none,		/* CB55	*/
	"bit     2,(hl)",	0, none,		/* CB56	*/
	"bit     2,a",		0, none,		/* CB57	*/

	"bit     3,b",		0, none,		/* CB58	*/
	"bit     3,c",		0, none,		/* CB59	*/
	"bit     3,d",		0, none,		/* CB5A	*/
	"bit     3,e",		0, none,		/* CB5B	*/
	"bit     3,h",		0, none,		/* CB5C	*/
	"bit     3,l",		0, none,		/* CB5D	*/
	"bit     3,(hl)",	0, none,		/* CB5E	*/
	"bit     3,a",		0, none,		/* CB5F	*/

	"bit     4,b",		0, none,		/* CB60	*/
	"bit     4,c",		0, none,		/* CB61	*/
	"bit     4,d",		0, none,		/* CB62	*/
	"bit     4,e",		0, none,		/* CB63	*/
	"bit     4,h",		0, none,		/* CB64	*/
	"bit     4,l",		0, none,		/* CB65	*/
	"bit     4,(hl)",	0, none,		/* CB66	*/
	"bit     4,a",		0, none,		/* CB67	*/

	"bit     5,b",		0, none,		/* CB68	*/
	"bit     5,c",		0, none,		/* CB69	*/
	"bit     5,d",		0, none,		/* CB6A	*/
	"bit     5,e",		0, none,		/* CB6B	*/
	"bit     5,h",		0, none,		/* CB6C	*/
	"bit     5,l",		0, none,		/* CB6D	*/
	"bit     5,(hl)",	0, none,		/* CB6E	*/
	"bit     5,a",		0, none,		/* CB6F	*/

	"bit     6,b",		0, none,		/* CB70	*/
	"bit     6,c",		0, none,		/* CB71	*/
	"bit     6,d",		0, none,		/* CB72	*/
	"bit     6,e",		0, none,		/* CB73	*/
	"bit     6,h",		0, none,		/* CB74	*/
	"bit     6,l",		0, none,		/* CB75	*/
	"bit     6,(hl)",	0, none,		/* CB76	*/
	"bit     6,a",		0, none,		/* CB77	*/

	"bit     7,b",		0, none,		/* CB78	*/
	"bit     7,c",		0, none,		/* CB79	*/
	"bit     7,d",		0, none,		/* CB7A	*/
	"bit     7,e",		0, none,		/* CB7B	*/
	"bit     7,h",		0, none,		/* CB7C	*/
	"bit     7,l",		0, none,		/* CB7D	*/
	"bit     7,(hl)",	0, none,		/* CB7E	*/
	"bit     7,a",		0, none,		/* CB7F	*/

	"res     0,b",		0, none,		/* CB80	*/
	"res     0,c",		0, none,		/* CB81	*/
	"res     0,d",		0, none,		/* CB82	*/
	"res     0,e",		0, none,		/* CB83	*/
	"res     0,h",		0, none,		/* CB84	*/
	"res     0,l",		0, none,		/* CB85	*/
	"res     0,(hl)",	0, none,		/* CB86	*/
	"res     0,a",		0, none,		/* CB87	*/

	"res     1,b",		0, none,		/* CB88	*/
	"res     1,c",		0, none,		/* CB89	*/
	"res     1,d",		0, none,		/* CB8A	*/
	"res     1,e",		0, none,		/* CB8B	*/
	"res     1,h",		0, none,		/* CB8C	*/
	"res     1,l",		0, none,		/* CB8D	*/
	"res     1,(hl)",	0, none,		/* CB8E	*/
	"res     1,a",		0, none,		/* CB8F	*/

	"res     2,b",		0, none,		/* CB90	*/
	"res     2,c",		0, none,		/* CB91	*/
	"res     2,d",		0, none,		/* CB92	*/
	"res     2,e",		0, none,		/* CB93	*/
	"res     2,h",		0, none,		/* CB94	*/
	"res     2,l",		0, none,		/* CB95	*/
	"res     2,(hl)",	0, none,		/* CB96	*/
	"res     2,a",		0, none,		/* CB97	*/

	"res     3,b",		0, none,		/* CB98	*/
	"res     3,c",		0, none,		/* CB99	*/
	"res     3,d",		0, none,		/* CB9A	*/
	"res     3,e",		0, none,		/* CB9B	*/
	"res     3,h",		0, none,		/* CB9C	*/
	"res     3,l",		0, none,		/* CB9D	*/
	"res     3,(hl)",	0, none,		/* CB9E	*/
	"res     3,a",		0, none,		/* CB9F	*/

	"res     4,b",		0, none,		/* CBA0	*/
	"res     4,c",		0, none,		/* CBA1	*/
	"res     4,d",		0, none,		/* CBA2	*/
	"res     4,e",		0, none,		/* CBA3	*/
	"res     4,h",		0, none,		/* CBA4	*/
	"res     4,l",		0, none,		/* CBA5	*/
	"res     4,(hl)",	0, none,		/* CBA6	*/
	"res     4,a",		0, none,		/* CBA7	*/

	"res     5,b",		0, none,		/* CBA8	*/
	"res     5,c",		0, none,		/* CBA9	*/
	"res     5,d",		0, none,		/* CBAA	*/
	"res     5,e",		0, none,		/* CBAB	*/
	"res     5,h",		0, none,		/* CBAC	*/
	"res     5,l",		0, none,		/* CBAD	*/
	"res     5,(hl)",	0, none,		/* CBAE	*/
	"res     5,a",		0, none,		/* CBAF	*/

	"res     6,b",		0, none,		/* CBB0	*/
	"res     6,c",		0, none,		/* CBB1	*/
	"res     6,d",		0, none,		/* CBB2	*/
	"res     6,e",		0, none,		/* CBB3	*/
	"res     6,h",		0, none,		/* CBB4	*/
	"res     6,l",		0, none,		/* CBB5	*/
	"res     6,(hl)",	0, none,		/* CBB6	*/
	"res     6,a",		0, none,		/* CBB7	*/

	"res     7,b",		0, none,		/* CBB8	*/
	"res     7,c",		0, none,		/* CBB9	*/
	"res     7,d",		0, none,		/* CBBA	*/
	"res     7,e",		0, none,		/* CBBB	*/
	"res     7,h",		0, none,		/* CBBC	*/
	"res     7,l",		0, none,		/* CBBD	*/
	"res     7,(hl)",	0, none,		/* CBBE	*/
	"res     7,a",		0, none,		/* CBBF	*/

	"set     0,b",		0, none,		/* CBC0	*/
	"set     0,c",		0, none,		/* CBC1	*/
	"set     0,d",		0, none,		/* CBC2	*/
	"set     0,e",		0, none,		/* CBC3	*/
	"set     0,h",		0, none,		/* CBC4	*/
	"set     0,l",		0, none,		/* CBC5	*/
	"set     0,(hl)",	0, none,		/* CBC6	*/
	"set     0,a",		0, none,		/* CBC7	*/

	"set     1,b",		0, none,		/* CBC8	*/
	"set     1,c",		0, none,		/* CBC9	*/
	"set     1,d",		0, none,		/* CBCA	*/
	"set     1,e",		0, none,		/* CBCB	*/
	"set     1,h",		0, none,		/* CBCC	*/
	"set     1,l",		0, none,		/* CBCD	*/
	"set     1,(hl)",	0, none,		/* CBCE	*/
	"set     1,a",		0, none,		/* CBCF	*/

	"set     2,b",		0, none,		/* CBD0	*/
	"set     2,c",		0, none,		/* CBD1	*/
	"set     2,d",		0, none,		/* CBD2	*/
	"set     2,e",		0, none,		/* CBD3	*/
	"set     2,h",		0, none,		/* CBD4	*/
	"set     2,l",		0, none,		/* CBD5	*/
	"set     2,(hl)",	0, none,		/* CBD6	*/
	"set     2,a",		0, none,		/* CBD7	*/

	"set     3,b",		0, none,		/* CBD8	*/
	"set     3,c",		0, none,		/* CBD9	*/
	"set     3,d",		0, none,		/* CBDA	*/
	"set     3,e",		0, none,		/* CBDB	*/
	"set     3,h",		0, none,		/* CBDC	*/
	"set     3,l",		0, none,		/* CBDD	*/
	"set     3,(hl)",	0, none,		/* CBDE	*/
	"set     3,a",		0, none,		/* CBDF	*/

	"set     4,b",		0, none,		/* CBE0	*/
	"set     4,c",		0, none,		/* CBE1	*/
	"set     4,d",		0, none,		/* CBE2	*/
	"set     4,e",		0, none,		/* CBE3	*/
	"set     4,h",		0, none,		/* CBE4	*/
	"set     4,l",		0, none,		/* CBE5	*/
	"set     4,(hl)",	0, none,		/* CBE6	*/
	"set     4,a",		0, none,		/* CBE7	*/

	"set     5,b",		0, none,		/* CBE8	*/
	"set     5,c",		0, none,		/* CBE9	*/
	"set     5,d",		0, none,		/* CBEA	*/
	"set     5,e",		0, none,		/* CBEB	*/
	"set     5,h",		0, none,		/* CBEC	*/
	"set     5,l",		0, none,		/* CBED	*/
	"set     5,(hl)",	0, none,		/* CBEE	*/
	"set     5,a",		0, none,		/* CBEF	*/

	"set     6,b",		0, none,		/* CBF0	*/
	"set     6,c",		0, none,		/* CBF1	*/
	"set     6,d",		0, none,		/* CBF2	*/
	"set     6,e",		0, none,		/* CBF3	*/
	"set     6,h",		0, none,		/* CBF4	*/
	"set     6,l",		0, none,		/* CBF5	*/
	"set     6,(hl)",	0, none,		/* CBF6	*/
	"set     6,a",		0, none,		/* CBF7	*/

	"set     7,b",		0, none,		/* CBF8	*/
	"set     7,c",		0, none,		/* CBF9	*/
	"set     7,d",		0, none,		/* CBFA	*/
	"set     7,e",		0, none,		/* CBFB	*/
	"set     7,h",		0, none,		/* CBFC	*/
	"set     7,l",		0, none,		/* CBFD	*/
	"set     7,(hl)",	0, none,		/* CBFE	*/
	"set     7,a",		0, none			/* CBFF	*/
};


struct opcode ddcb[] = {
	undocumented,		0, none,		/* DDCB00 */
	undocumented,		0, none,		/* DDCB01 */
	undocumented,		0, none,		/* DDCB02 */
	undocumented,		0, none,		/* DDCB03 */
	undocumented,		0, none,		/* DDCB04 */
	undocumented,		0, none,		/* DDCB05 */
	"rlc     (ix%s)",	-2, none,		/* DDCB06 */
	undocumented,		0, none,		/* DDCB07 */

	undocumented,		0, none,		/* DDCB08 */
	undocumented,		0, none,		/* DDCB09 */
	undocumented,		0, none,		/* DDCB0A */
	undocumented,		0, none,		/* DDCB0B */
	undocumented,		0, none,		/* DDCB0C */
	undocumented,		0, none,		/* DDCB0D */
	"rrc     (ix%s)",	-2, none,		/* DDCB0E */
	undocumented,		0, none,		/* DDCB0F */

	undocumented,		0, none,		/* DDCB10 */
	undocumented,		0, none,		/* DDCB11 */
	undocumented,		0, none,		/* DDCB12 */
	undocumented,		0, none,		/* DDCB13 */
	undocumented,		0, none,		/* DDCB14 */
	undocumented,		0, none,		/* DDCB15 */
	"rl      (ix%s)",	-2, none,		/* DDCB16 */
	undocumented,		0, none,		/* DDCB17 */

	undocumented,		0, none,		/* DDCB18 */
	undocumented,		0, none,		/* DDCB19 */
	undocumented,		0, none,		/* DDCB1A */
	undocumented,		0, none,		/* DDCB1B */
	undocumented,		0, none,		/* DDCB1C */
	undocumented,		0, none,		/* DDCB1D */
	"rr      (ix%s)",	-2, none,		/* DDCB1E */
	undocumented,		0, none,		/* DDCB1F */

	undocumented,		0, none,		/* DDCB20 */
	undocumented,		0, none,		/* DDCB21 */
	undocumented,		0, none,		/* DDCB22 */
	undocumented,		0, none,		/* DDCB23 */
	undocumented,		0, none,		/* DDCB24 */
	undocumented,		0, none,		/* DDCB25 */
	"sla     (ix%s)",	-2, none,		/* DDCB26 */
	undocumented,		0, none,		/* DDCB27 */

	undocumented,		0, none,		/* DDCB28 */
	undocumented,		0, none,		/* DDCB29 */
	undocumented,		0, none,		/* DDCB2A */
	undocumented,		0, none,		/* DDCB2B */
	undocumented,		0, none,		/* DDCB2C */
	undocumented,		0, none,		/* DDCB2D */
	"sra     (ix%s)",	-2, none,		/* DDCB2E */
	undocumented,		0, none,		/* DDCB2F */

	undocumented,		0, none,		/* DDCB30 */
	undocumented,		0, none,		/* DDCB31 */
	undocumented,		0, none,		/* DDCB32 */
	undocumented,		0, none,		/* DDCB33 */
	undocumented,		0, none,		/* DDCB34 */
	undocumented,		0, none,		/* DDCB35 */
	"sll     (ix%s)",	-2, none,		/* DDCB36, undocumented	*/
	undocumented,		0, none,		/* DDCB37 */

	undocumented,		0, none,		/* DDCB38 */
	undocumented,		0, none,		/* DDCB39 */
	undocumented,		0, none,		/* DDCB3A */
	undocumented,		0, none,		/* DDCB3B */
	undocumented,		0, none,		/* DDCB3C */
	undocumented,		0, none,		/* DDCB3D */
	"srl     (ix%s)",	-2, none,		/* DDCB3E */
	undocumented,		0, none,		/* DDCB3F */

	undocumented,		0, none,		/* DDCB40 */
	undocumented,		0, none,		/* DDCB41 */
	undocumented,		0, none,		/* DDCB42 */
	undocumented,		0, none,		/* DDCB43 */
	undocumented,		0, none,		/* DDCB44 */
	undocumented,		0, none,		/* DDCB45 */
	"bit     0,(ix%s)",	-2, none,		/* DDCB46 */
	undocumented,		0, none,		/* DDCB47 */

	undocumented,		0, none,		/* DDCB48 */
	undocumented,		0, none,		/* DDCB49 */
	undocumented,		0, none,		/* DDCB4A */
	undocumented,		0, none,		/* DDCB4B */
	undocumented,		0, none,		/* DDCB4C */
	undocumented,		0, none,		/* DDCB4D */
	"bit     1,(ix%s)",	-2, none,		/* DDCB4E */
	undocumented,		0, none,		/* DDCB4F */

	undocumented,		0, none,		/* DDCB50 */
	undocumented,		0, none,		/* DDCB51 */
	undocumented,		0, none,		/* DDCB52 */
	undocumented,		0, none,		/* DDCB53 */
	undocumented,		0, none,		/* DDCB54 */
	undocumented,		0, none,		/* DDCB55 */
	"bit     2,(ix%s)",	-2, none,		/* DDCB56 */
	undocumented,		0, none,		/* DDCB57 */

	undocumented,		0, none,		/* DDCB58 */
	undocumented,		0, none,		/* DDCB59 */
	undocumented,		0, none,		/* DDCB5A */
	undocumented,		0, none,		/* DDCB5B */
	undocumented,		0, none,		/* DDCB5C */
	undocumented,		0, none,		/* DDCB5D */
	"bit     3,(ix%s)",	-2, none,		/* DDCB5E */
	undocumented,		0, none,		/* DDCB5F */

	undocumented,		0, none,		/* DDCB60 */
	undocumented,		0, none,		/* DDCB61 */
	undocumented,		0, none,		/* DDCB62 */
	undocumented,		0, none,		/* DDCB63 */
	undocumented,		0, none,		/* DDCB64 */
	undocumented,		0, none,		/* DDCB65 */
	"bit     4,(ix%s)",	-2, none,		/* DDCB66 */
	undocumented,		0, none,		/* DDCB67 */

	undocumented,		0, none,		/* DDCB68 */
	undocumented,		0, none,		/* DDCB69 */
	undocumented,		0, none,		/* DDCB6A */
	undocumented,		0, none,		/* DDCB6B */
	undocumented,		0, none,		/* DDCB6C */
	undocumented,		0, none,		/* DDCB6D */
	"bit     5,(ix%s)",	-2, none,		/* DDCB6E */
	undocumented,		0, none,		/* DDCB6F */

	undocumented,		0, none,		/* DDCB70 */
	undocumented,		0, none,		/* DDCB71 */
	undocumented,		0, none,		/* DDCB72 */
	undocumented,		0, none,		/* DDCB73 */
	undocumented,		0, none,		/* DDCB74 */
	undocumented,		0, none,		/* DDCB75 */
	"bit     6,(ix%s)",	-2, none,		/* DDCB76 */
	undocumented,		0, none,		/* DDCB77 */

	undocumented,		0, none,		/* DDCB78 */
	undocumented,		0, none,		/* DDCB79 */
	undocumented,		0, none,		/* DDCB7A */
	undocumented,		0, none,		/* DDCB7B */
	undocumented,		0, none,		/* DDCB7C */
	undocumented,		0, none,		/* DDCB7D */
	"bit     7,(ix%s)",	-2, none,		/* DDCB7E */
	undocumented,		0, none,		/* DDCB7F */

	undocumented,		0, none,		/* DDCB80 */
	undocumented,		0, none,		/* DDCB81 */
	undocumented,		0, none,		/* DDCB82 */
	undocumented,		0, none,		/* DDCB83 */
	undocumented,		0, none,		/* DDCB84 */
	undocumented,		0, none,		/* DDCB85 */
	"res     0,(ix%s)",	-2, none,		/* DDCB86 */
	undocumented,		0, none,		/* DDCB87 */

	undocumented,		0, none,		/* DDCB88 */
	undocumented,		0, none,		/* DDCB89 */
	undocumented,		0, none,		/* DDCB8A */
	undocumented,		0, none,		/* DDCB8B */
	undocumented,		0, none,		/* DDCB8C */
	undocumented,		0, none,		/* DDCB8D */
	"res     1,(ix%s)",	-2, none,		/* DDCB8E */
	undocumented,		0, none,		/* DDCB8F */

	undocumented,		0, none,		/* DDCB90 */
	undocumented,		0, none,		/* DDCB91 */
	undocumented,		0, none,		/* DDCB92 */
	undocumented,		0, none,		/* DDCB93 */
	undocumented,		0, none,		/* DDCB94 */
	undocumented,		0, none,		/* DDCB95 */
	"res     2,(ix%s)",	-2, none,		/* DDCB96 */
	undocumented,		0, none,		/* DDCB97 */

	undocumented,		0, none,		/* DDCB98 */
	undocumented,		0, none,		/* DDCB99 */
	undocumented,		0, none,		/* DDCB9A */
	undocumented,		0, none,		/* DDCB9B */
	undocumented,		0, none,		/* DDCB9C */
	undocumented,		0, none,		/* DDCB9D */
	"res     3,(ix%s)",	-2, none,		/* DDCB9E */
	undocumented,		0, none,		/* DDCB9F */

	undocumented,		0, none,		/* DDCBA0 */
	undocumented,		0, none,		/* DDCBA1 */
	undocumented,		0, none,		/* DDCBA2 */
	undocumented,		0, none,		/* DDCBA3 */
	undocumented,		0, none,		/* DDCBA4 */
	undocumented,		0, none,		/* DDCBA5 */
	"res     4,(ix%s)",	-2, none,		/* DDCBA6 */
	undocumented,		0, none,		/* DDCBA7 */

	undocumented,		0, none,		/* DDCBA8 */
	undocumented,		0, none,		/* DDCBA9 */
	undocumented,		0, none,		/* DDCBAA */
	undocumented,		0, none,		/* DDCBAB */
	undocumented,		0, none,		/* DDCBAC */
	undocumented,		0, none,		/* DDCBAD */
	"res     5,(ix%s)",	-2, none,		/* DDCBAE */
	undocumented,		0, none,		/* DDCBAF */

	undocumented,		0, none,		/* DDCBB0 */
	undocumented,		0, none,		/* DDCBB1 */
	undocumented,		0, none,		/* DDCBB2 */
	undocumented,		0, none,		/* DDCBB3 */
	undocumented,		0, none,		/* DDCBB4 */
	undocumented,		0, none,		/* DDCBB5 */
	"res     6,(ix%s)",	-2, none,		/* DDCBB6 */
	undocumented,		0, none,		/* DDCBB7 */

	undocumented,		0, none,		/* DDCBB8 */
	undocumented,		0, none,		/* DDCBB9 */
	undocumented,		0, none,		/* DDCBBA */
	undocumented,		0, none,		/* DDCBBB */
	undocumented,		0, none,		/* DDCBBC */
	undocumented,		0, none,		/* DDCBBD */
	"res     7,(ix%s)",	-2, none,		/* DDCBBE */
	undocumented,		0, none,		/* DDCBBF */

	undocumented,		0, none,		/* DDCBC0 */
	undocumented,		0, none,		/* DDCBC1 */
	undocumented,		0, none,		/* DDCBC2 */
	undocumented,		0, none,		/* DDCBC3 */
	undocumented,		0, none,		/* DDCBC4 */
	undocumented,		0, none,		/* DDCBC5 */
	"set     0,(ix%s)",	-2, none,		/* DDCBC6 */
	undocumented,		0, none,		/* DDCBC7 */

	undocumented,		0, none,		/* DDCBC8 */
	undocumented,		0, none,		/* DDCBC9 */
	undocumented,		0, none,		/* DDCBCA */
	undocumented,		0, none,		/* DDCBCB */
	undocumented,		0, none,		/* DDCBCC */
	undocumented,		0, none,		/* DDCBCD */
	"set     1,(ix%s)",	-2, none,		/* DDCBCE */
	undocumented,		0, none,		/* DDCBCF */

	undocumented,		0, none,		/* DDCBD0 */
	undocumented,		0, none,		/* DDCBD1 */
	undocumented,		0, none,		/* DDCBD2 */
	undocumented,		0, none,		/* DDCBD3 */
	undocumented,		0, none,		/* DDCBD4 */
	undocumented,		0, none,		/* DDCBD5 */
	"set     2,(ix%s)",	-2, none,		/* DDCBD6 */
	undocumented,		0, none,		/* DDCBD7 */

	undocumented,		0, none,		/* DDCBD8 */
	undocumented,		0, none,		/* DDCBD9 */
	undocumented,		0, none,		/* DDCBDA */
	undocumented,		0, none,		/* DDCBDB */
	undocumented,		0, none,		/* DDCBDC */
	undocumented,		0, none,		/* DDCBDD */
	"set     3,(ix%s)",	-2, none,		/* DDCBDE */
	undocumented,		0, none,		/* DDCBDF */

	undocumented,		0, none,		/* DDCBE0 */
	undocumented,		0, none,		/* DDCBE1 */
	undocumented,		0, none,		/* DDCBE2 */
	undocumented,		0, none,		/* DDCBE3 */
	undocumented,		0, none,		/* DDCBE4 */
	undocumented,		0, none,		/* DDCBE5 */
	"set     4,(ix%s)",	-2, none,		/* DDCBE6 */
	undocumented,		0, none,		/* DDCBE7 */

	undocumented,		0, none,		/* DDCBE8 */
	undocumented,		0, none,		/* DDCBE9 */
	undocumented,		0, none,		/* DDCBEA */
	undocumented,		0, none,		/* DDCBEB */
	undocumented,		0, none,		/* DDCBEC */
	undocumented,		0, none,		/* DDCBED */
	"set     5,(ix%s)",	-2, none,		/* DDCBEE */
	undocumented,		0, none,		/* DDCBEF */

	undocumented,		0, none,		/* DDCBF0 */
	undocumented,		0, none,		/* DDCBF1 */
	undocumented,		0, none,		/* DDCBF2 */
	undocumented,		0, none,		/* DDCBF3 */
	undocumented,		0, none,		/* DDCBF4 */
	undocumented,		0, none,		/* DDCBF5 */
	"set     6,(ix%s)",	-2, none,		/* DDCBF6 */
	undocumented,		0, none,		/* DDCBF7 */

	undocumented,		0, none,		/* DDCBF8 */
	undocumented,		0, none,		/* DDCBF9 */
	undocumented,		0, none,		/* DDCBFA */
	undocumented,		0, none,		/* DDCBFB */
	undocumented,		0, none,		/* DDCBFC */
	undocumented,		0, none,		/* DDCBFD */
	"set     7,(ix%s)",	-2, none,		/* DDCBFE */
	undocumented,		0, none			/* DDCBFF */
};

struct opcode fdcb[] = {
	undocumented,		0, none,		/* FDCB00 */
	undocumented,		0, none,		/* FDCB01 */
	undocumented,		0, none,		/* FDCB02 */
	undocumented,		0, none,		/* FDCB03 */
	undocumented,		0, none,		/* FDCB04 */
	undocumented,		0, none,		/* FDCB05 */
	"rlc     (iy%s)",	-2, none,		/* FDCB06 */
	undocumented,		0, none,		/* FDCB07 */

	undocumented,		0, none,		/* FDCB08 */
	undocumented,		0, none,		/* FDCB09 */
	undocumented,		0, none,		/* FDCB0A */
	undocumented,		0, none,		/* FDCB0B */
	undocumented,		0, none,		/* FDCB0C */
	undocumented,		0, none,		/* FDCB0D */
	"rrc     (iy%s)",	-2, none,		/* FDCB0E */
	undocumented,		0, none,		/* FDCB0F */

	undocumented,		0, none,		/* FDCB10 */
	undocumented,		0, none,		/* FDCB11 */
	undocumented,		0, none,		/* FDCB12 */
	undocumented,		0, none,		/* FDCB13 */
	undocumented,		0, none,		/* FDCB14 */
	undocumented,		0, none,		/* FDCB15 */
	"rl      (iy%s)",	-2, none,		/* FDCB16 */
	undocumented,		0, none,		/* FDCB17 */

	undocumented,		0, none,		/* FDCB18 */
	undocumented,		0, none,		/* FDCB19 */
	undocumented,		0, none,		/* FDCB1A */
	undocumented,		0, none,		/* FDCB1B */
	undocumented,		0, none,		/* FDCB1C */
	undocumented,		0, none,		/* FDCB1D */
	"rr      (iy%s)",	-2, none,		/* FDCB1E */
	undocumented,		0, none,		/* FDCB1F */

	undocumented,		0, none,		/* FDCB20 */
	undocumented,		0, none,		/* FDCB21 */
	undocumented,		0, none,		/* FDCB22 */
	undocumented,		0, none,		/* FDCB23 */
	undocumented,		0, none,		/* FDCB24 */
	undocumented,		0, none,		/* FDCB25 */
	"sla     (iy%s)",	-2, none,		/* FDCB26 */
	undocumented,		0, none,		/* FDCB27 */

	undocumented,		0, none,		/* FDCB28 */
	undocumented,		0, none,		/* FDCB29 */
	undocumented,		0, none,		/* FDCB2A */
	undocumented,		0, none,		/* FDCB2B */
	undocumented,		0, none,		/* FDCB2C */
	undocumented,		0, none,		/* FDCB2D */
	"sra     (iy%s)",	-2, none,		/* FDCB2E */
	undocumented,		0, none,		/* FDCB2F */

	undocumented,		0, none,		/* FDCB30 */
	undocumented,		0, none,		/* FDCB31 */
	undocumented,		0, none,		/* FDCB32 */
	undocumented,		0, none,		/* FDCB33 */
	undocumented,		0, none,		/* FDCB34 */
	undocumented,		0, none,		/* FDCB35 */
	"sll     (iy%s)",	-2, none,		/* FDCB36, undocumented	*/
	undocumented,		0, none,		/* FDCB37 */

	undocumented,		0, none,		/* FDCB38 */
	undocumented,		0, none,		/* FDCB39 */
	undocumented,		0, none,		/* FDCB3A */
	undocumented,		0, none,		/* FDCB3B */
	undocumented,		0, none,		/* FDCB3C */
	undocumented,		0, none,		/* FDCB3D */
	"srl     (iy%s)",	-2, none,		/* FDCB3E */
	undocumented,		0, none,		/* FDCB3F */

	undocumented,		0, none,		/* FDCB40 */
	undocumented,		0, none,		/* FDCB41 */
	undocumented,		0, none,		/* FDCB42 */
	undocumented,		0, none,		/* FDCB43 */
	undocumented,		0, none,		/* FDCB44 */
	undocumented,		0, none,		/* FDCB45 */
	"bit     0,(iy%s)",	-2, none,		/* FDCB46 */
	undocumented,		0, none,		/* FDCB47 */

	undocumented,		0, none,		/* FDCB48 */
	undocumented,		0, none,		/* FDCB49 */
	undocumented,		0, none,		/* FDCB4A */
	undocumented,		0, none,		/* FDCB4B */
	undocumented,		0, none,		/* FDCB4C */
	undocumented,		0, none,		/* FDCB4D */
	"bit     1,(iy%s)",	-2, none,		/* FDCB4E */
	undocumented,		0, none,		/* FDCB4F */

	undocumented,		0, none,		/* FDCB50 */
	undocumented,		0, none,		/* FDCB51 */
	undocumented,		0, none,		/* FDCB52 */
	undocumented,		0, none,		/* FDCB53 */
	undocumented,		0, none,		/* FDCB54 */
	undocumented,		0, none,		/* FDCB55 */
	"bit     2,(iy%s)",	-2, none,		/* FDCB56 */
	undocumented,		0, none,		/* FDCB57 */

	undocumented,		0, none,		/* FDCB58 */
	undocumented,		0, none,		/* FDCB59 */
	undocumented,		0, none,		/* FDCB5A */
	undocumented,		0, none,		/* FDCB5B */
	undocumented,		0, none,		/* FDCB5C */
	undocumented,		0, none,		/* FDCB5D */
	"bit     3,(iy%s)",	-2, none,		/* FDCB5E */
	undocumented,		0, none,		/* FDCB5F */

	undocumented,		0, none,		/* FDCB60 */
	undocumented,		0, none,		/* FDCB61 */
	undocumented,		0, none,		/* FDCB62 */
	undocumented,		0, none,		/* FDCB63 */
	undocumented,		0, none,		/* FDCB64 */
	undocumented,		0, none,		/* FDCB65 */
	"bit     4,(iy%s)",	-2, none,		/* FDCB66 */
	undocumented,		0, none,		/* FDCB67 */

	undocumented,		0, none,		/* FDCB68 */
	undocumented,		0, none,		/* FDCB69 */
	undocumented,		0, none,		/* FDCB6A */
	undocumented,		0, none,		/* FDCB6B */
	undocumented,		0, none,		/* FDCB6C */
	undocumented,		0, none,		/* FDCB6D */
	"bit     5,(iy%s)",	-2, none,		/* FDCB6E */
	undocumented,		0, none,		/* FDCB6F */

	undocumented,		0, none,		/* FDCB70 */
	undocumented,		0, none,		/* FDCB71 */
	undocumented,		0, none,		/* FDCB72 */
	undocumented,		0, none,		/* FDCB73 */
	undocumented,		0, none,		/* FDCB74 */
	undocumented,		0, none,		/* FDCB75 */
	"bit     6,(iy%s)",	-2, none,		/* FDCB76 */
	undocumented,		0, none,		/* FDCB77 */

	undocumented,		0, none,		/* FDCB78 */
	undocumented,		0, none,		/* FDCB79 */
	undocumented,		0, none,		/* FDCB7A */
	undocumented,		0, none,		/* FDCB7B */
	undocumented,		0, none,		/* FDCB7C */
	undocumented,		0, none,		/* FDCB7D */
	"bit     7,(iy%s)",	-2, none,		/* FDCB7E */
	undocumented,		0, none,		/* FDCB7F */

	undocumented,		0, none,		/* FDCB80 */
	undocumented,		0, none,		/* FDCB81 */
	undocumented,		0, none,		/* FDCB82 */
	undocumented,		0, none,		/* FDCB83 */
	undocumented,		0, none,		/* FDCB84 */
	undocumented,		0, none,		/* FDCB85 */
	"res     0,(iy%s)",	-2, none,		/* FDCB86 */
	undocumented,		0, none,		/* FDCB87 */

	undocumented,		0, none,		/* FDCB88 */
	undocumented,		0, none,		/* FDCB89 */
	undocumented,		0, none,		/* FDCB8A */
	undocumented,		0, none,		/* FDCB8B */
	undocumented,		0, none,		/* FDCB8C */
	undocumented,		0, none,		/* FDCB8D */
	"res     1,(iy%s)",	-2, none,		/* FDCB8E */
	undocumented,		0, none,		/* FDCB8F */

	undocumented,		0, none,		/* FDCB90 */
	undocumented,		0, none,		/* FDCB91 */
	undocumented,		0, none,		/* FDCB92 */
	undocumented,		0, none,		/* FDCB93 */
	undocumented,		0, none,		/* FDCB94 */
	undocumented,		0, none,		/* FDCB95 */
	"res     2,(iy%s)",	-2, none,		/* FDCB96 */
	undocumented,		0, none,		/* FDCB97 */

	undocumented,		0, none,		/* FDCB98 */
	undocumented,		0, none,		/* FDCB99 */
	undocumented,		0, none,		/* FDCB9A */
	undocumented,		0, none,		/* FDCB9B */
	undocumented,		0, none,		/* FDCB9C */
	undocumented,		0, none,		/* FDCB9D */
	"res     3,(iy%s)",	-2, none,		/* FDCB9E */
	undocumented,		0, none,		/* FDCB9F */

	undocumented,		0, none,		/* FDCBA0 */
	undocumented,		0, none,		/* FDCBA1 */
	undocumented,		0, none,		/* FDCBA2 */
	undocumented,		0, none,		/* FDCBA3 */
	undocumented,		0, none,		/* FDCBA4 */
	undocumented,		0, none,		/* FDCBA5 */
	"res    4,(iy%s)",	-2, none,		/* FDCBA6 */
	undocumented,		0, none,		/* FDCBA7 */

	undocumented,		0, none,		/* FDCBA8 */
	undocumented,		0, none,		/* FDCBA9 */
	undocumented,		0, none,		/* FDCBAA */
	undocumented,		0, none,		/* FDCBAB */
	undocumented,		0, none,		/* FDCBAC */
	undocumented,		0, none,		/* FDCBAD */
	"res     5,(iy%s)",	-2, none,		/* FDCBAE */
	undocumented,		0, none,		/* FDCBAF */

	undocumented,		0, none,		/* FDCBB0 */
	undocumented,		0, none,		/* FDCBB1 */
	undocumented,		0, none,		/* FDCBB2 */
	undocumented,		0, none,		/* FDCBB3 */
	undocumented,		0, none,		/* FDCBB4 */
	undocumented,		0, none,		/* FDCBB5 */
	"res     6,(iy%s)",	-2, none,		/* FDCBB6 */
	undocumented,		0, none,		/* FDCBB7 */

	undocumented,		0, none,		/* FDCBB8 */
	undocumented,		0, none,		/* FDCBB9 */
	undocumented,		0, none,		/* FDCBBA */
	undocumented,		0, none,		/* FDCBBB */
	undocumented,		0, none,		/* FDCBBC */
	undocumented,		0, none,		/* FDCBBD */
	"res     7,(iy%s)",	-2, none,		/* FDCBBE */
	undocumented,		0, none,		/* FDCBBF */

	undocumented,		0, none,		/* FDCBC0 */
	undocumented,		0, none,		/* FDCBC1 */
	undocumented,		0, none,		/* FDCBC2 */
	undocumented,		0, none,		/* FDCBC3 */
	undocumented,		0, none,		/* FDCBC4 */
	undocumented,		0, none,		/* FDCBC5 */
	"set     0,(iy%s)",	-2, none,		/* FDCBC6 */
	undocumented,		0, none,		/* FDCBC7 */

	undocumented,		0, none,		/* FDCBC8 */
	undocumented,		0, none,		/* FDCBC9 */
	undocumented,		0, none,		/* FDCBCA */
	undocumented,		0, none,		/* FDCBCB */
	undocumented,		0, none,		/* FDCBCC */
	undocumented,		0, none,		/* FDCBCD */
	"set     1,(iy%s)",	-2, none,		/* FDCBCE */
	undocumented,		0, none,		/* FDCBCF */

	undocumented,		0, none,		/* FDCBD0 */
	undocumented,		0, none,		/* FDCBD1 */
	undocumented,		0, none,		/* FDCBD2 */
	undocumented,		0, none,		/* FDCBD3 */
	undocumented,		0, none,		/* FDCBD4 */
	undocumented,		0, none,		/* FDCBD5 */
	"set     2,(iy%s)",	-2, none,		/* FDCBD6 */
	undocumented,		0, none,		/* FDCBD7 */

	undocumented,		0, none,		/* FDCBD8 */
	undocumented,		0, none,		/* FDCBD9 */
	undocumented,		0, none,		/* FDCBDA */
	undocumented,		0, none,		/* FDCBDB */
	undocumented,		0, none,		/* FDCBDC */
	undocumented,		0, none,		/* FDCBDD */
	"set     3,(iy%s)",	-2, none,		/* FDCBDE */
	undocumented,		0, none,		/* FDCBDF */

	undocumented,		0, none,		/* FDCBE0 */
	undocumented,		0, none,		/* FDCBE1 */
	undocumented,		0, none,		/* FDCBE2 */
	undocumented,		0, none,		/* FDCBE3 */
	undocumented,		0, none,		/* FDCBE4 */
	undocumented,		0, none,		/* FDCBE5 */
	"set     4,(iy%s)",	-2, none,		/* FDCBE6 */
	undocumented,		0, none,		/* FDCBE7 */

	undocumented,		0, none,		/* FDCBE8 */
	undocumented,		0, none,		/* FDCBE9 */
	undocumented,		0, none,		/* FDCBEA */
	undocumented,		0, none,		/* FDCBEB */
	undocumented,		0, none,		/* FDCBEC */
	undocumented,		0, none,		/* FDCBED */
	"set     5,(iy%s)",	-2, none,		/* FDCBEE */
	undocumented,		0, none,		/* FDCBEF */

	undocumented,		0, none,		/* FDCBF0 */
	undocumented,		0, none,		/* FDCBF1 */
	undocumented,		0, none,		/* FDCBF2 */
	undocumented,		0, none,		/* FDCBF3 */
	undocumented,		0, none,		/* FDCBF4 */
	undocumented,		0, none,		/* FDCBF5 */
	"set     6,(iy%s)",	-2, none,		/* FDCBF6 */
	undocumented,		0, none,		/* FDCBF7 */

	undocumented,		0, none,		/* FDCBF8 */
	undocumented,		0, none,		/* FDCBF9 */
	undocumented,		0, none,		/* FDCBFA */
	undocumented,		0, none,		/* FDCBFB */
	undocumented,		0, none,		/* FDCBFC */
	undocumented,		0, none,		/* FDCBFD */
	"set     7,(iy%s)",	-2, none,		/* FDCBFE */
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
	"add     ix,bc",	0, none,		/* DD09	*/
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
	"add     ix,de",	0, none,		/* DD19	*/
	undocumented,		0, none,		/* DD1A	*/
	undocumented,		0, none,		/* DD1B	*/
	undocumented,		0, none,		/* DD1C	*/
	undocumented,		0, none,		/* DD1D	*/
	undocumented,		0, none,		/* DD1E	*/
	undocumented,		0, none,		/* DD1F	*/

	undocumented,		0, none,		/* DD20	*/
	"ld      ix,%s",	2, none,		/* DD21	*/
	"ld      (%s),ix",	2, none,		/* DD22	*/
	"inc     ix",		0, none,		/* DD23	*/
	"inc     ixh",		0, none,		/* DD24, undocumented */
	"dec     ixh",		0, none,		/* DD25, undocumented */
	"ld      ixh,%s",	1, none,		/* DD26, undocumented */
	undocumented,		0, none,		/* DD27	*/

	undocumented,		0, none,		/* DD28	*/
	"add     ix,ix",	0, none,		/* DD29	*/
	"ld      ix,(%s)",	2, none,		/* DD2A	*/
	"dec     ix",		0, none,		/* DD2B	*/
	"inc     ixl",		0, none,		/* DD24, undocumented */
	"dec     ixl",		0, none,		/* DD25, undocumented */
	"ld      ixl,%s",	1, none,		/* DD26, undocumented */
	undocumented,		0, none,		/* DD2F	*/

	undocumented,		0, none,		/* DD30	*/
	undocumented,		0, none,		/* DD31	*/
	undocumented,		0, none,		/* DD32	*/
	undocumented,		0, none,		/* DD33	*/
	"inc     (ix%s)",	-4, none,		/* DD34	*/
	"dec     (ix%s)",	-4, none,		/* DD35	*/
	"ld      (ix%s),%s",	-3, none,		/* DD36	*/
	undocumented,		0, none,		/* DD37	*/

	undocumented,		0, none,		/* DD38	*/
	"add     ix,sp",	0, none,		/* DD39	*/
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
	"ld      b,ixh",	0, none,		/* DD44, undocumented */
	"ld      b,ixl",	0, none,		/* DD45, undocumented */
	"ld      b,(ix%s)",	-4, none,		/* DD46	*/
	undocumented,		0, none,		/* DD47	*/

	undocumented,		0, none,		/* DD48	*/
	undocumented,		0, none,		/* DD49	*/
	undocumented,		0, none,		/* DD4A	*/
	undocumented,		0, none,		/* DD4B	*/
	"ld      c,ixh",	0, none,		/* DD4C, undocumented */
	"ld      c,ixl",	0, none,		/* DD4D, undocumented */
	"ld      c,(ix%s)",	-4, none,		/* DD4E	*/
	undocumented,		0, none,		/* DD4F	*/

	undocumented,		0, none,		/* DD50	*/
	undocumented,		0, none,		/* DD51	*/
	undocumented,		0, none,		/* DD52	*/
	undocumented,		0, none,		/* DD53	*/
	"ld      d,ixh",	0, none,		/* DD54, undocumented */
	"ld      d,ixl",	0, none,		/* DD55, undocumented */
	"ld      d,(ix%s)",	-4, none,		/* DD56	*/
	undocumented,		0, none,		/* DD57	*/

	undocumented,		0, none,		/* DD58	*/
	undocumented,		0, none,		/* DD59	*/
	undocumented,		0, none,		/* DD5A	*/
	undocumented,		0, none,		/* DD5B	*/
	"ld      e,ixh",	0, none,		/* DD5C, undocumented */
	"ld      e,ixl",	0, none,		/* DD5D, undocumented */
	"ld      e,(ix%s)",	-4, none,		/* DD5E	*/
	undocumented,		0, none,		/* DD5F	*/

	"ld      ixh,b",	0, none,		/* DD60, undocumented */
	"ld      ixh,c",	0, none,		/* DD61, undocumented */
	"ld      ixh,d",	0, none,		/* DD62, undocumented */
	"ld      ixh,e",	0, none,		/* DD63, undocumented */
	"ld      ixh,ixh",	0, none,		/* DD64, undocumented */
	"ld      ixh,ixl",	0, none,		/* DD65, undocumented */
	"ld      h,(ix%s)",	-4, none,		/* DD66	*/
	"ld      ixh,a",	0, none,		/* DD67, undocumented */

	"ld      ixl,b",	0, none,		/* DD68, undocumented */
	"ld      ixl,c",	0, none,		/* DD69, undocumented */
	"ld      ixl,d",	0, none,		/* DD6A, undocumented */
	"ld      ixl,e",	0, none,		/* DD6B, undocumented */
	"ld      ixl,ixh",	0, none,		/* DD6C, undocumented */
	"ld      ixl,ixl",	0, none,		/* DD6D, undocumented */
	"ld      l,(ix%s)",	-4, none,		/* DD6E	*/
	"ld      ixl,a",	0, none,		/* DD6F, undocumented */

	"ld      (ix%s),b",	-4, none,		/* DD70	*/
	"ld      (ix%s),c",	-4, none,		/* DD71	*/
	"ld      (ix%s),d",	-4, none,		/* DD72	*/
	"ld      (ix%s),e",	-4, none,		/* DD73	*/
	"ld      (ix%s),h",	-4, none,		/* DD74	*/
	"ld      (ix%s),l",	-4, none,		/* DD75	*/
	undocumented,		0, none,		/* DD76	*/
	"ld      (ix%s),a",	-4, none,		/* DD77	*/

	undocumented,		0, none,		/* DD78	*/
	undocumented,		0, none,		/* DD79	*/
	undocumented,		0, none,		/* DD7A	*/
	undocumented,		0, none,		/* DD7B	*/
	"ld      a,ixh",	0, none,		/* DD7C, undocumented */
	"ld      a,ixl",	0, none,		/* DD7D, undocumented */
	"ld      a,(ix%s)",	-4, none,		/* DD7E	*/
	undocumented,		0, none,		/* DD7F	*/

	undocumented,		0, none,		/* DD80	*/
	undocumented,		0, none,		/* DD81	*/
	undocumented,		0, none,		/* DD82	*/
	undocumented,		0, none,		/* DD83	*/
	"add     a,ixh",	0, none,		/* DD84, undocumented */
	"add     a,ixl",	0, none,		/* DD85, undocumented */
	"add     a,(ix%s)",	-4, none,		/* DD86	*/
	undocumented,		0, none,		/* DD87	*/

	undocumented,		0, none,		/* DD88	*/
	undocumented,		0, none,		/* DD89	*/
	undocumented,		0, none,		/* DD8A	*/
	undocumented,		0, none,		/* DD8B	*/
	"adc     a,ixh",	0, none,		/* DD8D, undocumented */
	"adc     a,ixl",	0, none,		/* DD8E, undocumented */
	"adc     a,(ix%s)",	-4, none,		/* DD8E	*/
	undocumented,		0, none,		/* DD8F	*/

	undocumented,		0, none,		/* DD90	*/
	undocumented,		0, none,		/* DD91	*/
	undocumented,		0, none,		/* DD92	*/
	undocumented,		0, none,		/* DD93	*/
	"sub     ixh",		0, none,		/* DD94, undocumented */
	"sub     ixl",		0, none,		/* DD95, undocumented */
	"sub     (ix%s)",	-4, none,		/* DD96	*/
	undocumented,		0, none,		/* DD97	*/

	undocumented,		0, none,		/* DD98	*/
	undocumented,		0, none,		/* DD99	*/
	undocumented,		0, none,		/* DD9A	*/
	undocumented,		0, none,		/* DD9B	*/
	"sbc     a,ixh",	0, none,		/* DD9C, undocumented */
	"sbc     a,ixl",	0, none,		/* DD9D, undocumented */
	"sbc     a,(ix%s)",	-4, none,		/* DD9E	*/
	undocumented,		0, none,		/* DD9F	*/

	undocumented,		0, none,		/* DDA0	*/
	undocumented,		0, none,		/* DDA1	*/
	undocumented,		0, none,		/* DDA2	*/
	undocumented,		0, none,		/* DDA3	*/
	"and     ixh",		0, none,		/* DDA4, undocumented */
	"and     ixl",		0, none,		/* DDA5, undocumented */
	"and     (ix%s)",	-4, none,		/* DDA6	*/
	undocumented,		0, none,		/* DDA7	*/

	undocumented,		0, none,		/* DDA8	*/
	undocumented,		0, none,		/* DDA9	*/
	undocumented,		0, none,		/* DDAA	*/
	undocumented,		0, none,		/* DDAB	*/
	"xor     ixh",		0, none,		/* DDAC, undocumented */
	"xor     ixl",		0, none,		/* DDAD, undocumented */
	"xor     (ix%s)",	-4, none,		/* DDAE	*/
	undocumented,		0, none,		/* DDAF	*/

	undocumented,		0, none,		/* DDB0	*/
	undocumented,		0, none,		/* DDB1	*/
	undocumented,		0, none,		/* DDB2	*/
	undocumented,		0, none,		/* DDB3	*/
	"or      ixh",		0, none,		/* DDB4, undocumented */
	"or      ixl",		0, none,		/* DDB5, undocumented */
	"or      (ix%s)",	-4, none,		/* DDB6	*/
	undocumented,		0, none,		/* DDB7	*/

	undocumented,		0, none,		/* DDB8	*/
	undocumented,		0, none,		/* DDB9	*/
	undocumented,		0, none,		/* DDBA	*/
	undocumented,		0, none,		/* DDBB	*/
	"cp      ixh",		0, none,		/* DDBC, undocumented */
	"cp      ixl",		0, none,		/* DDBD, undocumented */
	"cp      (ix%s)",	-4, none,		/* DDBE	*/
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
	"pop     ix",		0, none,		/* DDE1	*/
	undocumented,		0, none,		/* DDE2	*/
	"ex      (sp),ix",	0, none,		/* DDE3	*/
	undocumented,		0, none,		/* DDE4	*/
	"push   ix",		0, none,		/* DDE5	*/
	undocumented,		0, none,		/* DDE6	*/
	undocumented,		0, none,		/* DDE7	*/

	undocumented,		0, none,		/* DDE8	*/
	"jp      (ix)",		0, none,		/* DDE9	*/
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
	"ld      sp,ix",	0, none,		/* DDF9	*/
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
	"add     iy,bc",	0, none,		/* FD09	*/
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
	"add     iy,de",	0, none,		/* FD19	*/
	undocumented,		0, none,		/* FD1A	*/
	undocumented,		0, none,		/* FD1B	*/
	undocumented,		0, none,		/* FD1C	*/
	undocumented,		0, none,		/* FD1D	*/
	undocumented,		0, none,		/* FD1E	*/
	undocumented,		0, none,		/* FD1F	*/

	undocumented,		0, none,		/* FD20	*/
	"ld      iy,%s",	2, none,		/* FD21	*/
	"ld      (%s),iy",	2, none,		/* FD22	*/
	"inc     iy",		0, none,		/* FD23	*/
	"inc     iyh",		0, none,		/* FD24, undocumented */
	"dec     iyh",		0, none,		/* FD25, undocumented */
	"ld      iyh,%s",	1, none,		/* FD26, undocumented */
	undocumented,		0, none,		/* FD27	*/

	undocumented,		0, none,		/* FD28	*/
	"add     iy,iy",	0, none,		/* FD29	*/
	"ld      iy,(%s)",	2, none,		/* FD2A	*/
	"dec     iy",		0, none,		/* FD2B	*/
	"inc     iyl",		0, none,		/* FD24, undocumented */
	"dec     iyl",		0, none,		/* FD25, undocumented */
	"ld      iyl,%s",	1, none,		/* FD26, undocumented */
	undocumented,		0, none,		/* FD2F	*/

	undocumented,		0, none,		/* FD30	*/
	undocumented,		0, none,		/* FD31	*/
	undocumented,		0, none,		/* FD32	*/
	undocumented,		0, none,		/* FD33	*/
	"inc     (iy%s)",	-4, none,		/* FD34	*/
	"dec     (iy%s)",	-4, none,		/* FD35	*/
	"ld      (iy%s),%s",	-3, none,		/* FD36	*/
	undocumented,		0, none,		/* FD37	*/

	undocumented,		0, none,		/* FD38	*/
	"add     iy,sp",	0, none,		/* FD39	*/
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
	"ld      b,iyh",	0, none,		/* FD44, undocumented */
	"ld      b,iyl",	0, none,		/* FD45, undocumented */
	"ld      b,(iy%s)",	-4, none,		/* FD46	*/
	undocumented,		0, none,		/* FD47	*/

	undocumented,		0, none,		/* FD48	*/
	undocumented,		0, none,		/* FD49	*/
	undocumented,		0, none,		/* FD4A	*/
	undocumented,		0, none,		/* FD4B	*/
	"ld      c,iyh",	0, none,		/* FD4C, undocumented */
	"ld      c,iyl",	0, none,		/* FD4D, undocumented */
	"ld      c,(iy%s)",	-4, none,		/* FD4E	*/
	undocumented,		0, none,		/* FD4F	*/

	undocumented,		0, none,		/* FD50	*/
	undocumented,		0, none,		/* FD51	*/
	undocumented,		0, none,		/* FD52	*/
	undocumented,		0, none,		/* FD53	*/
	"ld      d,iyh",	0, none,		/* FD54, undocumented */
	"ld      d,iyl",	0, none,		/* FD55, undocumented */
	"ld      d,(iy%s)",	-4, none,		/* FD56	*/
	undocumented,		0, none,		/* FD57	*/

	undocumented,		0, none,		/* FD58	*/
	undocumented,		0, none,		/* FD59	*/
	undocumented,		0, none,		/* FD5A	*/
	undocumented,		0, none,		/* FD5B	*/
	"ld      e,iyh",	0, none,		/* FD5C, undocumented */
	"ld      e,iyl",	0, none,		/* FD5D, undocumented */
	"ld      e,(iy%s)",	-4, none,		/* FD5E	*/
	undocumented,		0, none,		/* FD5F	*/

	"ld      iyh,b",	0, none,		/* FD60, undocumented */
	"ld      iyh,c",	0, none,		/* FD61, undocumented */
	"ld      iyh,d",	0, none,		/* FD62, undocumented */
	"ld      iyh,e",	0, none,		/* FD63, undocumented */
	"ld      iyh,iyh",	0, none,		/* FD64, undocumented */
	"ld      iyh,iyl",	0, none,		/* FD65, undocumented */
	"ld      h,(iy%s)",	-4, none,		/* FD66	*/
	"ld      iyh,a",	0, none,		/* FD67, undocumented */

	"ld      iyl,b",	0, none,		/* FD68, undocumented */
	"ld      iyl,c",	0, none,		/* FD69, undocumented */
	"ld      iyl,d",	0, none,		/* FD6A, undocumented */
	"ld      iyl,e",	0, none,		/* FD6B, undocumented */
	"ld      iyl,iyh",	0, none,		/* FD6C, undocumented */
	"ld      iyl,iyl",	0, none,		/* FD6D, undocumented */
	"ld      l,(iy%s)",	-4, none,		/* FD6E	*/
	"ld      iyl,a",	0, none,		/* FD6F, undocumented */

	"ld      (iy%s),b",	-4, none,		/* FD70	*/
	"ld      (iy%s),c",	-4, none,		/* FD71	*/
	"ld      (iy%s),d",	-4, none,		/* FD72	*/
	"ld      (iy%s),e",	-4, none,		/* FD73	*/
	"ld      (iy%s),h",	-4, none,		/* FD74	*/
	"ld      (iy%s),l",	-4, none,		/* FD75	*/
	undocumented,		0, none,		/* FD76	*/
	"ld      (iy%s),a",	-4, none,		/* FD77	*/

	undocumented,		0, none,		/* FD78	*/
	undocumented,		0, none,		/* FD79	*/
	undocumented,		0, none,		/* FD7A	*/
	undocumented,		0, none,		/* FD7B	*/
	"ld      a,iyh",	0, none,		/* FD7C, undocumented */
	"ld      a,iyl",	0, none,		/* FD7D, undocumented */
	"ld      a,(iy%s)",	-4, none,		/* FD7E	*/
	undocumented,		0, none,		/* FD7F	*/

	undocumented,		0, none,		/* FD80	*/
	undocumented,		0, none,		/* FD81	*/
	undocumented,		0, none,		/* FD82	*/
	undocumented,		0, none,		/* FD83	*/
	"add     a,iyh",	0, none,		/* FD84, undocumented */
	"add     a,iyl",	0, none,		/* FD85, undocumented */
	"add     a,(iy%s)",	-4, none,		/* FD86	*/
	undocumented,		0, none,		/* FD87	*/

	undocumented,		0, none,		/* FD88	*/
	undocumented,		0, none,		/* FD89	*/
	undocumented,		0, none,		/* FD8A	*/
	undocumented,		0, none,		/* FD8B	*/
	"adc     a,iyh",	0, none,		/* FD8D, undocumented */
	"adc     a,iyl",	0, none,		/* FD8E, undocumented */
	"adc     a,(iy%s)",	-4, none,		/* FD8E	*/
	undocumented,		0, none,		/* FD8F	*/

	undocumented,		0, none,		/* FD90	*/
	undocumented,		0, none,		/* FD91	*/
	undocumented,		0, none,		/* FD92	*/
	undocumented,		0, none,		/* FD93	*/
	"sub     iyh",		0, none,		/* FD94, undocumented */
	"sub     iyl",		0, none,		/* FD95, undocumented */
	"sub     (iy%s)",	-4, none,		/* FD96	*/
	undocumented,		0, none,		/* FD97	*/

	undocumented,		0, none,		/* FD98	*/
	undocumented,		0, none,		/* FD99	*/
	undocumented,		0, none,		/* FD9A	*/
	undocumented,		0, none,		/* FD9B	*/
	"sbc     a,iyh",	0, none,		/* FD9C, undocumented */
	"sbc     a,iyl",	0, none,		/* FD9D, undocumented */
	"sbc     a,(iy%s)",	-4, none,		/* FD9E	*/
	undocumented,		0, none,		/* FD9F	*/

	undocumented,		0, none,		/* FDA0	*/
	undocumented,		0, none,		/* FDA1	*/
	undocumented,		0, none,		/* FDA2	*/
	undocumented,		0, none,		/* FDA3	*/
	"and     iyh",		0, none,		/* FDA4, undocumented */
	"and     iyl",		0, none,		/* FDA5, undocumented */
	"and     (iy%s)",	-4, none,		/* FDA6	*/
	undocumented,		0, none,		/* FDA7	*/

	undocumented,		0, none,		/* FDA8	*/
	undocumented,		0, none,		/* FDA9	*/
	undocumented,		0, none,		/* FDAA	*/
	undocumented,		0, none,		/* FDAB	*/
	"xor     iyh",		0, none,		/* FDAC, undocumented */
	"xor     iyl",		0, none,		/* FDAD, undocumented */
	"xor     (iy%s)",	-4, none,		/* FDAE	*/
	undocumented,		0, none,		/* FDAF	*/

	undocumented,		0, none,		/* FDB0	*/
	undocumented,		0, none,		/* FDB1	*/
	undocumented,		0, none,		/* FDB2	*/
	undocumented,		0, none,		/* FDB3	*/
	"or      iyh",		0, none,		/* FDB4, undocumented */
	"or      iyl",		0, none,		/* FDB5, undocumented */
	"or      (iy%s)",	-4, none,		/* FDB6	*/
	undocumented,		0, none,		/* FDB7	*/

	undocumented,		0, none,		/* FDB8	*/
	undocumented,		0, none,		/* FDB9	*/
	undocumented,		0, none,		/* FDBA	*/
	undocumented,		0, none,		/* FDBB	*/
	"cp      iyh",		0, none,		/* FDBC, undocumented */
	"cp      iyl",		0, none,		/* FDBD, undocumented */
	"cp      (iy%s)",	-4, none,		/* FDBE	*/
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
	"pop     iy",		0, none,		/* FDE1	*/
	undocumented,		0, none,		/* FDE2	*/
	"ex      (sp),iy",	0, none,		/* FDE3	*/
	undocumented,		0, none,		/* FDE4	*/
	"push    iy",		0, none,		/* FDE5	*/
	undocumented,		0, none,		/* FDE6	*/
	undocumented,		0, none,		/* FDE7	*/

	undocumented,		0, none,		/* FDE8	*/
	"jp      (iy)",		0, none,		/* FDE9	*/
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
	"ld      sp,iy",	0, none,		/* FDF9	*/
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

	"in      b,(c)",	0, none,		/* ED40	*/
	"out     (c),b",	0, none,		/* ED41	*/
	"sbc     hl,bc",	0, none,		/* ED42	*/
	"ld      (%s),bc",	2, none,	       /* ED43 */
	"neg",			0, none,		/* ED44	*/
	"retn",			0, none,		/* ED45	*/
	"im      0",		0, none,		/* ED46	*/
	"ld      i,a",		0, none,		/* ED47	*/

	"in      c,(c)",	0, none,		/* ED48	*/
	"out     (c),c",	0, none,		/* ED49	*/
	"adc     hl,bc",	0, none,		/* ED4A	*/
	"ld      bc,(%s)",	2, none,	       /* ED4B */
	undocumented,		0, none,		/* ED4C	*/
	"reti",			0, none,		/* ED4D	*/
	undocumented,		0, none,		/* ED4E	*/
	"ld      r,a",		0, none,		/* ED4F	*/

	"in      d,(c)",	0, none,		/* ED50	*/
	"out     (c),d",	0, none,		/* ED51	*/
	"sbc     hl,de",	0, none,		/* ED52	*/
	"ld      (%s),de",	2, none,	       /* ED53 */
	undocumented,		0, none,		/* ED54	*/
	undocumented,		0, none,		/* ED55	*/
	"im      1",		0, none,		/* ED56	*/
	"ld      a,i",		0, none,		/* ED57	*/

	"in      e,(c)",	0, none,		/* ED58	*/
	"out     (c),e",	0, none,		/* ED59	*/
	"adc     hl,de",	0, none,		/* ED5A	*/
	"ld      de,(%s)",	2, none,	       /* ED5B */
	undocumented,		0, none,		/* ED5C	*/
	undocumented,		0, none,		/* ED5D	*/
	"im      2",		0, none,		/* ED5E	*/
	"ld      a,r",		0, none,		/* ED5F	*/

	"in      h,(c)",	0, none,		/* ED60	*/
	"out     (c),h",	0, none,		/* ED61	*/
	"sbc     hl,hl",	0, none,		/* ED62	*/
	undocumented,		0, none,		/* ED63	*/
	undocumented,		0, none,		/* ED64	*/
	undocumented,		0, none,		/* ED65	*/
	undocumented,		0, none,		/* ED66	*/
	"rrd",			0, none,		/* ED67	*/

	"in      l,(c)",	0, none,		/* ED68	*/
	"out     (c),l",	0, none,		/* ED69	*/
	"adc     hl,hl",	0, none,		/* ED6A	*/
	undocumented,		0, none,		/* ED6B	*/
	undocumented,		0, none,		/* ED6C	*/
	undocumented,		0, none,		/* ED6D	*/
	undocumented,		0, none,		/* ED6E	*/
	"rld",			0, none,		/* ED6F	*/

	"in      f,(c)",	0, none,		/* ED70	*/
	undocumented,		0, none,		/* ED71	*/
	"sbc     hl,sp",	0, none,		/* ED72	*/
	"ld      (%s),sp",	2, none,	       /* ED73 */
	undocumented,		0, none,		/* ED74	*/
	undocumented,		0, none,		/* ED75	*/
	undocumented,		0, none,		/* ED76	*/
	undocumented,		0, none,		/* ED77	*/

	"in      a,(c)",	0, none,		/* ED78	*/
	"out     (c),a",	0, none,		/* ED79	*/
	"adc     hl,sp",	0, none,		/* ED7A	*/
	"ld      sp,(%s)",	2, none,	       /* ED7B */
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

	"ldi",			0, none,		/* EDA0	*/
	"cpi",			0, none,		/* EDA1	*/
	"ini",			0, none,		/* EDA2	*/
	"outi",			0, none,		/* EDA3	*/
	undocumented,		0, none,		/* EDA4	*/
	undocumented,		0, none,		/* EDA5	*/
	undocumented,		0, none,		/* EDA6	*/
	undocumented,		0, none,		/* EDA7	*/

	"ldd",			0, none,		/* EDA8	*/
	"cpd",			0, none,		/* EDA9	*/
	"ind",			0, none,		/* EDAA	*/
	"outd",			0, none,		/* EDAB	*/
	undocumented,		0, none,		/* EDAC	*/
	undocumented,		0, none,		/* EDAD	*/
	undocumented,		0, none,		/* EDAE	*/
	undocumented,		0, none,		/* EDAF	*/

	"ldir",			0, none,		/* EDB0	*/
	"cpir",			0, none,		/* EDB1	*/
	"inir",			0, none,		/* EDB2	*/
	"otir",			0, none,		/* EDB3	*/
	undocumented,		0, none,		/* EDB4	*/
	undocumented,		0, none,		/* EDB5	*/
	undocumented,		0, none,		/* EDB6	*/
	undocumented,		0, none,		/* EDB7	*/

	"lddr",			0, none,		/* EDB8	*/
	"cpdr",			0, none,		/* EDB9	*/
	"indr",			0, none,		/* EDBA	*/
	"otdr",			0, none,		/* EDBB	*/
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
	"oz      Dc_ini",	0, director,	/* 060C	*/
	"oz      Dc_bye",	0, director,	/* 080C	*/
	"oz      Dc_ent",	0, director,	/* 0A0C	*/
	"oz      Dc_nam",	0, director,	/* 0C0C	*/
	"oz      Dc_in",	0, director,	/* 0E0C	*/
	"oz      Dc_out",	0, director,	/* 100C	*/
	"oz      Dc_prt",	0, director,	/* 120C	*/
	"oz      Dc_icl",	0, director,	/* 140C	*/
	"oz      Dc_nq",	0, director,	/* 160C	*/
	"oz      Dc_sp",	0, director,	/* 180C	*/
	"oz      Dc_alt",	0, director,	/* 1A0C	*/
	"oz      Dc_rbd",	0, director,	/* 1C0C	*/
	"oz      Dc_xin",	0, director,	/* 1E0C	*/
	"oz      Dc_gen",	0, director,	/* 200C	*/
	"oz      Dc_pol",	0, director,	/* 220C	*/
	"oz      Dc_scn",	0, director,	/* 240C	*/
	"oz      unknown",	0, none
};

struct opcode os1[] = {
	"oz      Os_bye",	0, director,	/* 21 */
	"oz      Os_prt",	0, printer,	/* 24 */
	"oz      Os_out",	0, stdio,	/* 27 */
	"oz      Os_in",	0, stdio,	/* 2A */
	"oz      Os_tin",	0, stdio,	/* 2D */
	"oz      Os_xin",	0, stdio,	/* 30 */
	"oz      Os_pur",	0, stdio,	/* 33 */
	"oz      Os_ugb",	0, fileio,	/* 36 */
	"oz      Os_gb",	0, fileio,	/* 39 */
	"oz      Os_pb",	0, fileio,	/* 3C */
	"oz      Os_gbt",	0, fileio,	/* 3F */
	"oz      Os_pbt",	0, fileio,	/* 42 */
	"oz      Os_mv",	0, fileio,	/* 45 */
	"oz      Os_frm",	0, fileio,	/* 48 */
	"oz      Os_fwm",	0, fileio,	/* 4B */
	"oz      Os_mop",	0, memory,	/* 4E */
	"oz      Os_mcl",	0, memory,	/* 51 */
	"oz      Os_mal",	0, memory,	/* 54 */
	"oz      Os_mfr",	0, memory,	/* 57 */
	"oz      Os_mgb",	0, memory,	/* 5A */
	"oz      Os_mpb",	0, memory,	/* 5D */
	"oz      Os_bix",	0, memory,	/* 60 */
	"oz      Os_box",	0, memory,	/* 63 */
	"oz      Os_nq",	0, syspar,	/* 66 */
	"oz      Os_sp",	0, syspar,	/* 69 */
	"oz      Os_sr",	0, saverestore,	/* 6C */
	"oz      Os_esc",	0, error,	/* 6F */
	"oz      Os_erc",	0, error,	/* 72 */
	"oz      Os_erh",	0, error,	/* 75 */
	"oz      Os_ust",	0, timedate,	/* 78 */
	"oz      Os_fn",	0, handle,	/* 7B */
	"oz      Os_wait",	0, director,	/* 7E */
	"oz      Os_alm",	0, alarm,	/* 81 */
	"oz      Os_cli",	0, director,	/* 84 */
	"oz      Os_dor",	0, dor,		/* 87 */
	"oz      Os_fc",	0, memory,	/* 8A */
	"oz      Os_si",	0, serinterface,/* 8D */
	"oz      unknown)",	0, none
};

struct opcode os2[] = {
	"oz      Os_wtb",	0, tokens,	/* CA06	*/
	"oz      Os_wrt",	0, tokens,	/* CC06	*/
	"oz      Os_wsq",	0, printer,	/* CE06	*/
	"oz      Os_isq",	0, printer,	/* D006	*/
	"oz      Os_axp",	0, memory,	/* D206	*/
	"oz      Os_sci",	0, screen,	/* D406	*/
	"oz      Os_dly",	0, timedate,	/* D606	*/
	"oz      Os_blp",	0, stdio,	/* D806	*/
	"oz      Os_bde",	0, memory,	/* DA06	*/
	"oz      Os_bhl",	0, memory,	/* DC06	*/
	"oz      Os_fth",	0, director,	/* DE06	*/
	"oz      Os_vth",	0, director,	/* E006	*/
	"oz      Os_gth",	0, director,	/* E206	*/
	"oz      Os_ren",	0, fileio,	/* E406	*/
	"oz      Os_del",	0, fileio,	/* E606	*/
	"oz      Os_cl",	0, fileio,	/* E806	*/
	"oz      Os_op",	0, fileio,	/* EA06	*/
	"oz      Os_off",	0, screen,	/* EC06	*/
	"oz      Os_use",	0, director,	/* EE06	*/
	"oz      Os_epr",	0, fileio,	/* F006	*/
	"oz      Os_ht",	0, timedate,	/* F206	*/
	"oz      Os_map",	0, map,		/* F406	*/
	"oz      Os_exit",	0, director,	/* F606	*/
	"oz      Os_stk",	0, director,	/* F806	*/
	"oz      Os_ent",	0, director,	/* FA06	*/
	"oz      Os_poll",	0, director,	/* FC06	*/
	"oz      Os_dom",	0, director,	/* FE06	*/
	"oz      unknown",	0, none
};

struct opcode gn[] = {
	"oz      Gn_gdt",	0, timedate,	/* 0609	*/
	"oz      Gn_pdt",	0, timedate,	/* 0809	*/
	"oz      Gn_gtm",	0, timedate,	/* 0A09	*/
	"oz      Gn_ptm",	0, timedate,	/* 0C09	*/
	"oz      Gn_sdo",	0, timedate,	/* 0E09	*/
	"oz      Gn_gdn",	0, integer,	/* 1009	*/
	"oz      Gn_pdn",	0, integer,	/* 1209	*/
	"oz      Gn_die",	0, timedate,	/* 1409	*/
	"oz      Gn_dei",	0, timedate,	/* 1609	*/
	"oz      Gn_gmd",	0, timedate,	/* 1809	*/
	"oz      Gn_gmt",	0, timedate,	/* 1A09	*/
	"oz      Gn_pmd",	0, timedate,	/* 1C09	*/
	"oz      Gn_pmt",	0, timedate,	/* 1E09	*/
	"oz      Gn_msc",	0, timedate,	/* 2009	*/
	"oz      Gn_flo",	0, filter,	/* 2209	*/
	"oz      Gn_flc",	0, filter,	/* 2409	*/
	"oz      Gn_flw",	0, filter,	/* 2609	*/
	"oz      Gn_flr",	0, filter,	/* 2809	*/
	"oz      Gn_flf",	0, filter,	/* 2A09	*/
	"oz      Gn_fpb",	0, filter,	/* 2C09	*/
	"oz      Gn_nln",	0, stdio,	/* 2E09	*/
	"oz      Gn_cls",	0, chars,	/* 3009	*/
	"oz      Gn_skc",	0, chars,	/* 3209	*/
	"oz      Gn_skd",	0, chars,	/* 3409	*/
	"oz      Gn_skt",	0, chars,	/* 3609	*/
	"oz      Gn_sip",	0, stdio,	/* 3809	*/
	"oz      Gn_sop",	0, stdio,	/* 3A09	*/
	"oz      Gn_soe",	0, stdio,	/* 3C09	*/
	"oz      Gn_rbe",	0, memory,	/* 3E09	*/
	"oz      Gn_wbe",	0, memory,	/* 4009	*/
	"oz      Gn_cme",	0, memory,	/* 4209	*/
	"oz      Gn_xnx",	0, memory,	/* 4409	*/
	"oz      Gn_xin",	0, memory,	/* 4609	*/
	"oz      Gn_xdl",	0, memory,	/* 4809	*/
	"oz      Gn_err",	0, error,	/* 4A09	*/
	"oz      Gn_esp",	0, error,	/* 4C09	*/
	"oz      Gn_fcm",	0, fileio,	/* 4E09	*/
	"oz      Gn_fex",	0, fileio,	/* 5009	*/
	"oz      Gn_opw",	0, fileio,	/* 5209	*/
	"oz      Gn_wcl",	0, fileio,	/* 5409	*/
	"oz      Gn_wfn",	0, fileio,	/* 5609	*/
	"oz      Gn_prs",	0, fileio,	/* 5809	*/
	"oz      Gn_pfs",	0, fileio,	/* 5A09	*/
	"oz      Gn_wsm",	0, fileio,	/* 5C09	*/
	"oz      Gn_esa",	0, fileio,	/* 5E09	*/
	"oz      Gn_opf",	0, fileio,	/* 6009	*/
	"oz      Gn_cl",	0, fileio,	/* 6209	*/
	"oz      Gn_del",	0, fileio,	/* 6409	*/
	"oz      Gn_ren",	0, fileio,	/* 6609	*/
	"oz      Gn_aab",	0, alarm,	/* 6809	*/
	"oz      Gn_fab",	0, alarm,	/* 6A09	*/
	"oz      Gn_lab",	0, alarm,	/* 6C09	*/
	"oz      Gn_uab",	0, alarm,	/* 6E09	*/
	"oz      Gn_alp",	0, alarm,	/* 7009	*/
	"oz      Gn_m16",	0, integer,	/* 7209	*/
	"oz      Gn_d16",	0, integer,	/* 7409	*/
	"oz      Gn_m24",	0, integer,	/* 7609	*/
	"oz      Gn_d24",	0, integer,	/* 7809	*/
	"oz      unknown",	0, none
};

struct opcode fpp[] = {
	"fpp     Fp_and",	0, floatp,	   /* 21 */
	"fpp     Fp_idv",	0, floatp,	   /* 24 */
	"fpp     Fp_eor",	0, floatp,	   /* 27 */
	"fpp     Fp_mod",	0, floatp,	   /* 2A */
	"fpp     Fp_or",	0, floatp,	   /* 2D */
	"fpp     Fp_leq",	0, floatp,	   /* 30 */
	"fpp     Fp_neq",	0, floatp,	   /* 33 */
	"fpp     Fp_geq",	0, floatp,	   /* 36 */
	"fpp     Fp_lt",	0, floatp,	   /* 39 */
	"fpp     Fp_eq",	0, floatp,	   /* 3C */
	"fpp     Fp_mul",	0, floatp,	   /* 3F */
	"fpp     Fp_add",	0, floatp,	   /* 42 */
	"fpp     Fp_gt",	0, floatp,	   /* 45 */
	"fpp     Fp_sub",	0, floatp,	   /* 48 */
	"fpp     Fp_pwr",	0, floatp,	   /* 4B */
	"fpp     Fp_div",	0, floatp,	   /* 4E */
	"fpp     Fp_abs",	0, floatp,	   /* 51 */
	"fpp     Fp_acs",	0, floatp,	   /* 54 */
	"fpp     Fp_asn",	0, floatp,	   /* 57 */
	"fpp     Fp_atn",	0, floatp,	   /* 5A */
	"fpp     Fp_cos",	0, floatp,	   /* 5D */
	"fpp     Fp_deg",	0, floatp,	   /* 60 */
	"fpp     Fp_exp",	0, floatp,	   /* 63 */
	"fpp     Fp_int",	0, floatp,	   /* 66 */
	"fpp     Fp_ln",	0, floatp,	   /* 69 */
	"fpp     Fp_log",	0, floatp,	   /* 6C */
	"fpp     Fp_not",	0, floatp,	   /* 6F */
	"fpp     Fp_rad",	0, floatp,	   /* 72 */
	"fpp     Fp_sgn",	0, floatp,	   /* 75 */
	"fpp     Fp_sin",	0, floatp,	   /* 78 */
	"fpp     Fp_sqr",	0, floatp,	   /* 7B */
	"fpp     Fp_tan",	0, floatp,	   /* 7E */
	"fpp     Fp_zer",	0, floatp,	   /* 81 */
	"fpp     Fp_one",	0, floatp,	   /* 84 */
	"fpp     Fp_tru",	0, floatp,	   /* 87 */
	"fpp     Fp_pi",	0, floatp,	   /* 8A */
	"fpp     Fp_val",	0, floatp,	   /* 8D */
	"fpp     Fp_str",	0, floatp,	   /* 90 */
	"fpp     Fp_fix",	0, floatp,	   /* 93 */
	"fpp     Fp_flt",	0, floatp,	   /* 96 */
	"fpp     Fp_tst",	0, floatp,	   /* 99 */
	"fpp     Fp_cmp",	0, floatp,	   /* 9C */
	"fpp     Fp_neg",	0, floatp,	   /* 9F */
	"fpp     Fp_bas",	0, floatp,	   /* A2 */
	"fpp     unknown",	0, none
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

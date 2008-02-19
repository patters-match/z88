
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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "avltree.h"
#include "dzasm.h"
#include "table.h"

extern struct PrsAddrStack	*gParseAddress;	/* Address parsing stack */
extern DZarea			*gExtern;	/* list	of extern areas	*/
extern DZarea			*gAreas;
extern avltree			*gLabelRef;	/* Binary tree of program labels */
extern long			gEndOfCode;	/* Last	address	of machine code	file */
extern long			Org;
extern char			ident[];
extern char			separators[];
extern enum truefalse		collectfile_changed, collectfile_available;

extern struct opcode dc[];	/* Z88 OS low level call mnemonics */
extern struct opcode os1[];	/* Z88 OS low level 1 byte argument call mnemonics */
extern struct opcode os2[];	/* Z88 OS low level 2 byte argument call mnemonics */
extern struct opcode gn[];	/* Z88 OS general 2 byte argument call mnemonics */
extern struct opcode fpp[];	/* Z88 OS floating point call mnemonics	*/

char			*gIncludeFiles[] = { "none", "stdio", "fileio", "director", "memory", "dor", "syspar", "saverst",
                                             "fpp", "integer", "serintfc", "screen", "time", "char", "error", "map",
                                             "alarm", "filter", "tokens", "interrpt", "printer", "handle" };

enum truefalse		gIncludeList[] = { false, false, false, false, false, false, false, false,
					  false, false,	false, false, false, false, false, false,
					  false, false,	false, false, false, false};

avltree				*VisitedAddresses;	/* collection of parsed label adresses during a pp command session */

unsigned char			GetByte(long pc);
void				DZpass1(void);
void				DispParsedArea(long start, long end);
void				PushItem(long addr, struct PrsAddrStack **stackpointer);
void				StoreDataRef(long  label);
void				StoreAddrRef(long  label);
void				DelParsedAddr(ParsedAddress *node);
long				PopItem(struct PrsAddrStack **stackpointer);
struct PrsAddrStack		*AllocStackItem(void);
ParsedAddress			*AllocParsedAddress(void);
LabelRef			*AllocLabel(void);
LabelRef			*InitLabelRef(long  label, char *labelname);
int				CmpParseAddr(ParsedAddress *key, ParsedAddress *node);
int				CmpParseAddr2(long *key, ParsedAddress *node);
int				CmpAddrRef(LabelRef *key, LabelRef *node);
int				CmpAddrRef2(long *key, LabelRef *node);
DZarea				*InsertArea(struct area **arealist, long startrange, long  endrange, enum atype	 t);
enum atype			SearchArea(DZarea  *currarea, long  pc);
enum symbols			cmdlGetSym(void);
enum truefalse			LocalLabel(long  pc);
enum truefalse			AddressVisited(long pc);
void				DefineLabel(void);
void		    CreateLabel(long addr, char	*label);
char				*AllocLabelname(char *name);
long				GetConstant(void);
void				CreateLabelRef(avltree	**avlptr, long	labeladdr, char *labelname, enum truefalse  scope);
void				JoinAreas(DZarea  *currarea);

char		mainlookup[] = {
				0,	/* 00 NOP */
				2,	/* 01 LD BC,nn */
				0,	/* 02 LD (BC),A	*/
				0,	/* 03 INC BC */
				0,	/* 04 INC B */
				0,	/* 05 DEC B */
				1,	/* 06 LD B,n */
				0,	/* 07 RLCA */

				0,	/* 08 EX AF,AF' */
				0,	/* 09 ADD HL,BC	*/
				0,	/* 0A LD A,(BC)	*/
				0,	/* 0B DEC BC */
				0,	/* 0C INC C */
				0,	/* 0D DEC C */
				1,	/* 0E LD C,n */
				0,	/* 0F RRCA */

				1,	/* 10 DJNZ n */
				2,	/* 11 LD DE,nn */
				0,	/* 12 LD (DE),A	*/
				0,	/* 13 INC DE */
				0,	/* 14 INC D */
				0,	/* 15 DEC D */
				1,	/* 16 LD D,n */
				0,	/* 17 RLA */

				1,	/* 18 JR n */
				0,	/* 19 ADD HL,DE	*/
				0,	/* 1A LD A,(DE)	*/
				0,	/* 1B DEC DE */
				0,	/* 1C INC E */
				0,	/* 1D DEC E */
				1,	/* 1E LD E,n */
				0,	/* 1F RRA */

				1,	/* 20 JR NZ,n */
				2,	/* 21 LD HL,nn */
				2,	/* 22 LD (nn),HL */
				0,	/* 23 INC HL */
				0,	/* 24 INC H */
				0,	/* 25 DEC H */
				1,	/* 26 LD H,n */
				0,	/* 27 DAA */

				1,	/* 28 JR Z,n */
				0,	/* 29 ADD HL,HL	*/
				2,	/* 2A LD HL,(nn) */
				0,	/* 2B DEC HL */
				0,	/* 2C INC L */
				0,	/* 2D DEC L */
				1,	/* 2E LD L,n */
				0,	/* 2F CPL */

				1,	/* 30 JR NC,n */
				2,	/* 31 LD SP,nn */
				2,	/* 32 LD (nn),A	*/
				0,	/* 33 INC SP */
				0,	/* 34 INC (HL) */
				0,	/* 35 DEC (HL) */
				1,	/* 36 LD (HL),n	*/
				0,	/* 37 SCF */

				1,	/* 38 JR C,n */
				0,	/* 39 ADD HL,SP	*/
				2,	/* 3A LD A,(nn)	*/
				0,	/* 3B DEC SP */
				0,	/* 3C INC A */
				0,	/* 3D DEC A */
				1,	/* 3E LD A,n */
				0,	/* 3F CCF */

				0,	/* 40 LD B,B */
				0,	/* 41 LD B,C */
				0,	/* 42 LD B,D */
				0,	/* 43 LD B,E */
				0,	/* 44 LD B,H */
				0,	/* 45 LD B,L */
				0,	/* 46 LD B,(HL)	*/
				0,	/* 47 LD B,A */

				0,	/* 48 LD C,B */
				0,	/* 49 LD C,C */
				0,	/* 4A LD C,D */
				0,	/* 4B LD C,E */
				0,	/* 4C LD C,H */
				0,	/* 4D LD C,L */
				0,	/* 4E LD C,(HL)	*/
				0,	/* 4F LD C,A */

				0,	/* 50 LD D,B */
				0,	/* 51 LD D,C */
				0,	/* 52 LD D,D */
				0,	/* 53 LD D,E */
				0,	/* 54 LD D,H */
				0,	/* 55 LD D,L */
				0,	/* 56 LD D,(HL)	*/
				0,	/* 57 LD D,A */

				0,	/* 58 LD E,B */
				0,	/* 59 LD E,C */
				0,	/* 5A LD E,D */
				0,	/* 5B LD E,E */
				0,	/* 5C LD E,H */
				0,	/* 5D LD E,L */
				0,	/* 5E LD E,(HL)	*/
				0,	/* 5F LD E,A */

				0,	/* 60 LD H,B */
				0,	/* 61 LD H,C */
				0,	/* 62 LD H,D */
				0,	/* 63 LD H,E */
				0,	/* 64 LD H,H */
				0,	/* 65 LD H,L */
				0,	/* 66 LD H,(HL)	*/
				0,	/* 67 LD H,A */

				0,	/* 68 LD L,B */
				0,	/* 69 LD L,C */
				0,	/* 6A LD L,D */
				0,	/* 6B LD L,E */
				0,	/* 6C LD L,H */
				0,	/* 6D LD L,L */
				0,	/* 6E LD L,(HL)	*/
				0,	/* 6F LD L,A */

				0,	/* 70 LD (HL),B	*/
				0,	/* 71 LD (HL),C	*/
				0,	/* 72 LD (HL),D	*/
				0,	/* 73 LD (HL),E	*/
				0,	/* 74 LD (HL),H	*/
				0,	/* 75 LD (HL),L	*/
				0,	/* 76 HALT */
				0,	/* 77 LD (HL),A	*/

				0,	/* 78 LD A,B */
				0,	/* 79 LD A,C */
				0,	/* 7A LD A,D */
				0,	/* 7B LD A,E */
				0,	/* 7C LD A,H */
				0,	/* 7D LD A,L */
				0,	/* 7E LD A,(HL)	*/
				0,	/* 7F LD A,A */

				0,	/* 80 ADD A,B */
				0,	/* 81 ADD A,C */
				0,	/* 82 ADD A,D */
				0,	/* 83 ADD A,E */
				0,	/* 84 ADD A,H */
				0,	/* 85 ADD A,L */
				0,	/* 86 ADD A,(HL) */
				0,	/* 87 ADD A,A */

				0,	/* 88 ADC A,B */
				0,	/* 89 ADC A,C */
				0,	/* 8A ADC A,D */
				0,	/* 8B ADC A,E */
				0,	/* 8C ADC A,H */
				0,	/* 8D ADC A,L */
				0,	/* 8E ADC A,(HL) */
				0,	/* 8F ADC A,A */

				0,	/* 90 SUB B */
				0,	/* 91 SUB C */
				0,	/* 92 SUB D */
				0,	/* 93 SUB E */
				0,	/* 94 SUB H */
				0,	/* 95 SUB L */
				0,	/* 96 SUB (HL) */
				0,	/* 97 SUB A */

				0,	/* 98 SBC A,B */
				0,	/* 99 SBC A,C */
				0,	/* 9A SBC A,D */
				0,	/* 9B SBC A,E */
				0,	/* 9C SBC A,H */
				0,	/* 9D SBC A,L */
				0,	/* 9E SBC A,(HL) */
				0,	/* 9F SBC A,A */

				0,	/* A0 AND B */
				0,	/* A1 AND C */
				0,	/* A2 AND D */
				0,	/* A3 AND E */
				0,	/* A4 AND H */
				0,	/* A5 AND L */
				0,	/* A6 AND (HL) */
				0,	/* A7 AND A */

				0,	/* A8 XOR B */
				0,	/* A9 XOR C */
				0,	/* AA XOR D */
				0,	/* AB XOR E */
				0,	/* AC XOR H */
				0,	/* AD XOR L */
				0,	/* AE XOR (HL) */
				0,	/* AF XOR A */

				0,	/* B0 OR B */
				0,	/* B1 OR C */
				0,	/* B2 OR D */
				0,	/* B3 OR E */
				0,	/* B4 OR H */
				0,	/* B5 OR L */
				0,	/* B6 OR (HL) */
				0,	/* B7 OR A */

				0,	/* B8 CP B */
				0,	/* B9 CP C */
				0,	/* BA CP D */
				0,	/* BB CP E */
				0,	/* BC CP H */
				0,	/* BD CP L */
				0,	/* BE CP (HL) */
				0,	/* BF CP A */

				0,	/* C0 RET NZ */
				0,	/* C1 POP BC */
				2,	/* C2 JP NZ,nn */
				2,	/* C3 JP nn */
				2,	/* C4 CALL NZ,nn */
				0,	/* C5 PUSH BC */
				1,	/* C6 ADD A,n */
				0,	/* C7 RST 00h */

				0,	/* C8 RET Z */
				0,	/* C9 RET */
				2,	/* CA JP Z,nn */
				0,	/* CB .. */
				2,	/* CC CALL Z,nn	*/
				2,	/* CD CALL nn */
				1,	/* CE ADC A,n */
				0,	/* CF RST 08h */

				0,	/* D0 RET NC */
				0,	/* D1 POP DE */
				2,	/* D2 JP NC,nn */
				1,	/* D3 OUT (n),A	*/
				2,	/* D4 CALL NC,nn */
				0,	/* D5 PUSH DE */
				1,	/* D6 SUB n */
				0,	/* D7 RST 10h */

				0,	/* D8 RET C */
				0,	/* D9 EXX */
				2,	/* DA JP C,nn */
				1,	/* DB IN A,(n) */
				2,	/* DC CALL C,nn	*/
				0,	/* DD .. */
				1,	/* DE SBC A,n */
				0,	/* DF RST 18h */

				0,	/* E0 RET PO */
				0,	/* E1 POP HL */
				2,	/* E2 JP PO,nn */
				0,	/* E3 EX (SP),HL */
				2,	/* E4 CALL PO,nn */
				0,	/* E5 PUSH HL */
				1,	/* E6 AND n */
				0,	/* E7 RST 20h */

				0,	/* E8 RET PE */
				0,	/* E9 JP (HL) */
				2,	/* EA JP PE,nn */
				0,	/* EB EX DE,HL */
				2,	/* EC CALL PE,nn */
				0,	/* ED .. */
				1,	/* EE XOR n */
				0,	/* EF RST 28h */

				0,	/* F0 RET P */
				0,	/* F1 POP AF */
				2,	/* F2 JP P,nn */
				0,	/* F3 DI */
				2,	/* F4 CALL P,nn	*/
				0,	/* F5 PUSH AF */
				1,	/* F6 OR n */
				0,	/* F7 RST 30h */

				0,	/* F8 RET M */
				0,	/* F9 LD SP,HL */
				2,	/* FA JP M,nn */
				0,	/* FB EI */
				2,	/* FC CALL M,nn	*/
				0,	/* FD .. */
				1,	/* FE CP n */
				0,	/* FF RST 38h */
		};

char		indexlookup[] =	{       /* DD, FD opcodes */
				32,	/* DD00	*/
				32,	/* DD01	*/
				32,	/* DD02	*/
				32,	/* DD03	*/
				32,	/* DD04	*/
				32,	/* DD05	*/
				32,	/* DD06	*/
				32,	/* DD07	*/

				32,	/* DD08	*/
				0,	/* DD09	ADD IX,BC */
				32,	/* DD0A	*/
				32,	/* DD0B	*/
				32,	/* DD0C	*/
				32,	/* DD0D	*/
				32,	/* DD0E	*/
				32,	/* DD0F	*/

				32,	/* DD10	*/
				32,	/* DD11	*/
				32,	/* DD12	*/
				32,	/* DD13	*/
				32,	/* DD14	*/
				32,	/* DD15	*/
				32,	/* DD16	*/
				32,	/* DD17	*/

				32,	/* DD18	*/
				0,	/* DD19	ADD IX,DE */
				32,	/* DD1A	*/
				32,	/* DD1B	*/
				32,	/* DD1C	*/
				32,	/* DD1D	*/
				32,	/* DD1E	*/
				32,	/* DD1F	*/

				32,	/* DD20	*/
				2,	/* DD21	LD IX,nn */
				2,	/* DD22	LD (nn),IX */
				0,	/* DD23	INC IX */
				16,	/* DD24	INC IXH	undocumented */
				16,	/* DD25	DEC IXH	undocumented */
				17,	/* DD26	LD IXH,n undocumented */
				32,	/* DD27	*/

				32,	/* DD28	*/
				0,	/* DD29	ADD IX,IX */
				2,	/* DD2A	LD IX,(nn) */
				0,	/* DD2B	DEC IX */
				16,	/* DD2C	INC IXL	undocumented */
				16,	/* DD2D	DEC IXL	undocumented */
				17,	/* DD2E	LD IXL,n undocumented */
				32,	/* DD2F	*/

				32,	/* DD30	*/
				32,	/* DD31	*/
				32,	/* DD32	*/
				32,	/* DD33	*/
				1,	/* DD34	INC (IX+d) */
				1,	/* DD35	DEC (IX+d) */
				2,	/* DD36	LD (IX+d),n */
				32,	/* DD37	*/

				32,	/* DD38	*/
				0,	/* DD39	ADD IX,SP */
				32,	/* DD3A	*/
				32,	/* DD3B	*/
				32,	/* DD3C	*/
				32,	/* DD3D	*/
				32,	/* DD3E	*/
				32,	/* DD3F	*/

				32,	/* DD40	*/
				32,	/* DD41	*/
				32,	/* DD42	*/
				32,	/* DD43	*/
				16,	/* DD44	LD B,IXH undocumented */
				16,	/* DD45	LD B,IXL undocumented */
				1,	/* DD46	LD B,(IX+d) */
				32,	/* DD47	*/

				32,	/* DD48	*/
				32,	/* DD49	*/
				32,	/* DD4A	*/
				32,	/* DD4B	*/
				16,	/* DD4C	LD C,IXH undocumented */
				16,	/* DD4D	LD C,IXL undocumented */
				1,	/* DD4E	LD C,(IX+d) */
				32,	/* DD4F	*/

				32,	/* DD50	*/
				32,	/* DD51	*/
				32,	/* DD52	*/
				32,	/* DD53	*/
				16,	/* DD54	LD D,IXH undocumented */
				16,	/* DD55	LD D,IXL undocumented */
				1,	/* DD56	LD D,(IX+d) */
				32,	/* DD57	*/

				32,	/* DD58	*/
				32,	/* DD59	*/
				32,	/* DD5A	*/
				32,	/* DD5B	*/
				16,	/* DD5C	LD E,IXH undocumented */
				16,	/* DD5D	LD E,IXL undocumented */
				1,	/* DD5E	LD E,(IX+d) */
				32,	/* DD5F	*/

				16,	/* DD60	LD IXH,B undocumented */
				16,	/* DD61	LD IXH,C undocumented */
				16,	/* DD62	LD IXH,D undocumented */
				16,	/* DD63	LD IXH,E undocumented */
				16,	/* DD64	LD IXH,IXH undocumented	*/
				16,	/* DD65	LD IXH,IXL undocumented	*/
				1,	/* DD66	LD H,(IX+d) */
				16,	/* DD67	LD IXH,A undocumented */

				16,	/* DD68	LD IXL,B undocumented */
				16,	/* DD69	LD IXL,C undocumented */
				16,	/* DD6A	LD IXL,D undocumented */
				16,	/* DD6B	LD IXL,E undocumented */
				16,	/* DD6C	LD IXL,IXH undocumented	*/
				16,	/* DD6D	LD IXL,IXL undocumented	*/
				1,	/* DD6E	LD L,(IX+d) */
				16,	/* DD6F	LD IXL,A undocumented */

				1,	/* DD70	LD (IX+d),B */
				1,	/* DD71	LD (IX+d),C */
				1,	/* DD72	LD (IX+d),D */
				1,	/* DD73	LD (IX+d),E */
				1,	/* DD74	LD (IX+d),H */
				1,	/* DD75	LD (IX+d),L */
				32,	/* DD76	*/
				1,	/* DD77	LD (IX+d),A */

				32,	/* DD78	*/
				32,	/* DD79	*/
				32,	/* DD7A	*/
				32,	/* DD7B	*/
				16,	/* DD7C	LD A,IXH undocumented */
				16,	/* DD7D	LD A,IXL undocumented */
				1,	/* DD7E	LD A,(IX+d) */
				32,	/* DD7F	*/

				32,	/* DD80	*/
				32,	/* DD81	*/
				32,	/* DD82	*/
				32,	/* DD83	*/
				16,	/* DD84	ADD A,IXH undocumented */
				16,	/* DD85	ADD A,IXL undocumented */
				1,	/* DD86	ADD A,(IX+d) */
				32,	/* DD87	*/

				32,	/* DD88	*/
				32,	/* DD89	*/
				32,	/* DD8A	*/
				32,	/* DD8B	*/
				16,	/* DD8C	ADC A,IXH undocumented */
				16,	/* DD8D	ADC A,IXL undocumented */
				1,	/* DD8E	ADC A,(IX+d) */
				32,	/* DD8F	*/

				32,	/* DD90	*/
				32,	/* DD91	*/
				32,	/* DD92	*/
				32,	/* DD93	*/
				16,	/* DD94	SUB IXH	undocumented */
				16,	/* DD95	SUB IXL	undocumented */
				1,	/* DD96	SUB (IX+d) */
				32,	/* DD97	*/

				32,	/* DD98	*/
				32,	/* DD99	*/
				32,	/* DD9A	*/
				32,	/* DD9B	*/
				16,	/* DD9C	SBC A,IXH undocumented */
				16,	/* DD9D	SBC A,IXL undocumented */
				1,	/* DD9E	SBC A,(IX+d) */
				32,	/* DD9F	*/

				32,	/* DDA0	*/
				32,	/* DDA1	*/
				32,	/* DDA2	*/
				32,	/* DDA3	*/
				16,	/* DDA4	AND IXH	undocumented */
				16,	/* DDA5	AND IXL	undocumented */
				1,	/* DDA6	AND (IX+d) */
				32,	/* DDA7	*/

				32,	/* DDA8	*/
				32,	/* DDA9	*/
				32,	/* DDAA	*/
				32,	/* DDAB	*/
				16,	/* DDAC	XOR IXH	undocumented */
				16,	/* DDAD	XOR IXL	undocumented */
				1,	/* DDAE	XOR (IX+d) */
				32,	/* DDAF	*/

				32,	/* DDB0	*/
				32,	/* DDB1	*/
				32,	/* DDB2	*/
				32,	/* DDB3	*/
				16,	/* DDB4	OR IXH undocumented */
				16,	/* DDB5	OR IXL undocumented */
				1,	/* DDB6	OR (IX+d) */
				32,	/* DDB7	*/

				32,	/* DDB8	*/
				32,	/* DDB9	*/
				32,	/* DDBA	*/
				32,	/* DDBB	*/
				16,	/* DDBC	CP IXH undocumented */
				16,	/* DDBD	CP IXL undocumented */
				1,	/* DDBE	CP (IX+d) */
				32,	/* DDBF	*/

				32,	/* DDC0	*/
				32,	/* DDC1	*/
				32,	/* DDC2	*/
				32,	/* DDC3	*/
				32,	/* DDC4	*/
				32,	/* DDC5	*/
				32,	/* DDC6	*/
				32,	/* DDC7	*/

				32,	/* DDC8	*/
				32,	/* DDC9	*/
				32,	/* DDCA	*/
				32,	/* DDCB	*/
				32,	/* DDCC	*/
				32,	/* DDCD	*/
				32,	/* DDCE	*/
				32,	/* DDCF	*/

				32,	/* DDD0	*/
				32,	/* DDD1	*/
				32,	/* DDD2	*/
				32,	/* DDD3	*/
				32,	/* DDD4	*/
				32,	/* DDD5	*/
				32,	/* DDD6	*/
				32,	/* DDD7	*/

				32,	/* DDD8	*/
				32,	/* DDD9	*/
				32,	/* DDDA	*/
				32,	/* DDDB	*/
				32,	/* DDDC	*/
				32,	/* DDDD	*/
				32,	/* DDDE	*/
				32,	/* DDDF	*/

				32,	/* DDE0	*/
				0,	/* DDE1	POP IX */
				32,	/* DDE2	*/
				0,	/* DDE3	EX (SP),IX */
				32,	/* DDE4	*/
				0,	/* DDE5	PUSH IX	*/
				32,	/* DDE6	*/
				32,	/* DDE7	*/

				32,	/* DDE8	*/
				0,	/* DDE9	JP (IX)	*/
				32,	/* DDEA	*/
				32,	/* DDEB	*/
				32,	/* DDEC	*/
				32,	/* DDED	*/
				32,	/* DDEE	*/
				32,	/* DDEF	*/

				32,	/* DDF0	*/
				32,	/* DDF1	*/
				32,	/* DDF2	*/
				32,	/* DDF3	*/
				32,	/* DDF4	*/
				32,	/* DDF5	*/
				32,	/* DDF6	*/
				32,	/* DDF7	*/

				32,	/* DDF8	*/
				0,	/* DDF9	LD SP,IX */
				32,	/* DDFA	*/
				32,	/* DDFB	*/
				32,	/* DDFC	*/
				32,	/* DDFD	*/
				32,	/* DDFE	*/
				32,	/* DDFF	*/
		};

char		cbindexlookup[]	= {     /* DD, FD opcodes */
				32,	/* DDCB00 */
				32,	/* DDCB01 */
				32,	/* DDCB02 */
				32,	/* DDCB03 */
				32,	/* DDCB04 */
				32,	/* DDCB05 */
				0,	/* DDCB06 RLC (IX+d) */
				32,	/* DDCB07 */

				32,	/* DDCB08 */
				32,	/* DDCB09 */
				32,	/* DDCB0A */
				32,	/* DDCB0B */
				32,	/* DDCB0C */
				32,	/* DDCB0D */
				0,	/* DDCB0E RRC (IX+d) */
				32,	/* DDCB0F */

				32,	/* DDCB10 */
				32,	/* DDCB11 */
				32,	/* DDCB12 */
				32,	/* DDCB13 */
				32,	/* DDCB14 */
				32,	/* DDCB15 */
				0,	/* DDCB16 RL (IX+d) */
				32,	/* DDCB17 */

				32,	/* DDCB18 */
				32,	/* DDCB19 */
				32,	/* DDCB1A */
				32,	/* DDCB1B */
				32,	/* DDCB1C */
				32,	/* DDCB1D */
				0,	/* DDCB1E RR (IX+d) */
				32,	/* DDCB1F */

				32,	/* DDCB20 */
				32,	/* DDCB21 */
				32,	/* DDCB22 */
				32,	/* DDCB23 */
				32,	/* DDCB24 */
				32,	/* DDCB25 */
				0,	/* DDCB26 SLA (IX+d) */
				32,	/* DDCB27 */

				32,	/* DDCB28 */
				32,	/* DDCB29 */
				32,	/* DDCB2A */
				32,	/* DDCB2B */
				32,	/* DDCB2C */
				32,	/* DDCB2D */
				0,	/* DDCB2E SRA (IX+d) */
				32,	/* DDCB2F */

				32,	/* DDCB30 */
				32,	/* DDCB31 */
				32,	/* DDCB32 */
				32,	/* DDCB33 */
				32,	/* DDCB34 */
				32,	/* DDCB35 */
				16,	/* DDCB36 SLL (IX+d) */
				32,	/* DDCB37 */

				32,	/* DDCB38 */
				32,	/* DDCB39 */
				32,	/* DDCB3A */
				32,	/* DDCB3B */
				32,	/* DDCB3C */
				32,	/* DDCB3D */
				0,	/* DDCB3E SRL (IX+d) */
				32,	/* DDCB3F */

				32,	/* DDCB40 */
				32,	/* DDCB41 */
				32,	/* DDCB42 */
				32,	/* DDCB43 */
				32,	/* DDCB44 */
				32,	/* DDCB45 */
				0,	/* DDCB46 BIT 0,(IX+d) */
				32,	/* DDCB47 */

				32,	/* DDCB48 */
				32,	/* DDCB49 */
				32,	/* DDCB4A */
				32,	/* DDCB4B */
				32,	/* DDCB4C */
				32,	/* DDCB4D */
				0,	/* DDCB4E BIT 1,(IX+d) */
				32,	/* DDCB4F */

				32,	/* DDCB50 */
				32,	/* DDCB51 */
				32,	/* DDCB52 */
				32,	/* DDCB53 */
				32,	/* DDCB54 */
				32,	/* DDCB55 */
				0,	/* DDCB56 BIT 2,(IX+d) */
				32,	/* DDCB57 */

				32,	/* DDCB58 */
				32,	/* DDCB59 */
				32,	/* DDCB5A */
				32,	/* DDCB5B */
				32,	/* DDCB5C */
				32,	/* DDCB5D */
				0,	/* DDCB5E BIT 3,(IX+d) */
				32,	/* DDCB5F */

				32,	/* DDCB60 */
				32,	/* DDCB61 */
				32,	/* DDCB62 */
				32,	/* DDCB63 */
				32,	/* DDCB64 */
				32,	/* DDCB65 */
				0,	/* DDCB66 BIT 4,(IX+d) */
				32,	/* DDCB67 */

				32,	/* DDCB68 */
				32,	/* DDCB69 */
				32,	/* DDCB6A */
				32,	/* DDCB6B */
				32,	/* DDCB6C */
				32,	/* DDCB6D */
				0,	/* DDCB6E BIT 5,(IX+d) */
				32,	/* DDCB6F */

				32,	/* DDCB70 */
				32,	/* DDCB71 */
				32,	/* DDCB72 */
				32,	/* DDCB73 */
				32,	/* DDCB74 */
				32,	/* DDCB75 */
				0,	/* DDCB76 BIT 6,(IX+d) */
				32,	/* DDCB77 */

				32,	/* DDCB78 */
				32,	/* DDCB79 */
				32,	/* DDCB7A */
				32,	/* DDCB7B */
				32,	/* DDCB7C */
				32,	/* DDCB7D */
				0,	/* DDCB7E BIT 7,(IX+d) */
				32,	/* DDCB7F */

				32,	/* DDCB80 */
				32,	/* DDCB81 */
				32,	/* DDCB82 */
				32,	/* DDCB83 */
				32,	/* DDCB84 */
				32,	/* DDCB85 */
				0,	/* DDCB86 RES 0,(IX+d) */
				32,	/* DDCB87 */

				32,	/* DDCB88 */
				32,	/* DDCB89 */
				32,	/* DDCB8A */
				32,	/* DDCB8B */
				32,	/* DDCB8C */
				32,	/* DDCB8D */
				0,	/* DDCB8E RES 1,(IX+d) */
				32,	/* DDCB8F */

				32,	/* DDCB90 */
				32,	/* DDCB91 */
				32,	/* DDCB92 */
				32,	/* DDCB93 */
				32,	/* DDCB94 */
				32,	/* DDCB95 */
				0,	/* DDCB96 RES 2,(IX+d) */
				32,	/* DDCB97 */

				32,	/* DDCB98 */
				32,	/* DDCB99 */
				32,	/* DDCB9A */
				32,	/* DDCB9B */
				32,	/* DDCB9C */
				32,	/* DDCB9D */
				0,	/* DDCB9E RES 3,(IX+d) */
				32,	/* DDCB9F */

				32,	/* DDCBA0 */
				32,	/* DDCBA1 */
				32,	/* DDCBA2 */
				32,	/* DDCBA3 */
				32,	/* DDCBA4 */
				32,	/* DDCBA5 */
				0,	/* DDCBA6 RES 4,(IX+d) */
				32,	/* DDCBA7 */

				32,	/* DDCBA8 */
				32,	/* DDCBA9 */
				32,	/* DDCBAA */
				32,	/* DDCBAB */
				32,	/* DDCBAC */
				32,	/* DDCBAD */
				0,	/* DDCBAE RES 5,(IX+d) */
				32,	/* DDCBAF */

				32,	/* DDCBB0 */
				32,	/* DDCBB1 */
				32,	/* DDCBB2 */
				32,	/* DDCBB3 */
				32,	/* DDCBB4 */
				32,	/* DDCBB5 */
				0,	/* DDCBB6 RES 6,(IX+d) */
				32,	/* DDCBB7 */

				32,	/* DDCBB8 */
				32,	/* DDCBB9 */
				32,	/* DDCBBA */
				32,	/* DDCBBB */
				32,	/* DDCBBC */
				32,	/* DDCBBD */
				0,	/* DDCBBE RES 7,(IX+d) */
				32,	/* DDCBBF */

				32,	/* DDCBC0 */
				32,	/* DDCBC1 */
				32,	/* DDCBC2 */
				32,	/* DDCBC3 */
				32,	/* DDCBC4 */
				32,	/* DDCBC5 */
				0,	/* DDCBC6 SET 0,(IX+d) */
				32,	/* DDCBC7 */

				32,	/* DDCBC8 */
				32,	/* DDCBC9 */
				32,	/* DDCBCA */
				32,	/* DDCBCB */
				32,	/* DDCBCC */
				32,	/* DDCBCD */
				0,	/* DDCBCE SET 1,(IX+d) */
				32,	/* DDCBCF */

				32,	/* DDCBD0 */
				32,	/* DDCBD1 */
				32,	/* DDCBD2 */
				32,	/* DDCBD3 */
				32,	/* DDCBD4 */
				32,	/* DDCBD5 */
				0,	/* DDCBD6 SET 2,(IX+d) */
				32,	/* DDCBD7 */

				32,	/* DDCBD8 */
				32,	/* DDCBD9 */
				32,	/* DDCBDA */
				32,	/* DDCBDB */
				32,	/* DDCBDC */
				32,	/* DDCBDD */
				0,	/* DDCBDE SET 3,(IX+d) */
				32,	/* DDCBDF */

				32,	/* DDCBE0 */
				32,	/* DDCBE1 */
				32,	/* DDCBE2 */
				32,	/* DDCBE3 */
				32,	/* DDCBE4 */
				32,	/* DDCBE5 */
				0,	/* DDCBE6 SET 4,(IX+d) */
				32,	/* DDCBE7 */

				32,	/* DDCBE8 */
				32,	/* DDCBE9 */
				32,	/* DDCBEA */
				32,	/* DDCBEB */
				32,	/* DDCBEC */
				32,	/* DDCBED */
				0,	/* DDCBEE SET 5,(IX+d) */
				32,	/* DDCBEF */

				32,	/* DDCBF0 */
				32,	/* DDCBF1 */
				32,	/* DDCBF2 */
				32,	/* DDCBF3 */
				32,	/* DDCBF4 */
				32,	/* DDCBF5 */
				0,	/* DDCBF6 SET 6,(IX+d) */
				32,	/* DDCBF7 */

				32,	/* DDCBF8 */
				32,	/* DDCBF9 */
				32,	/* DDCBFA */
				32,	/* DDCBFB */
				32,	/* DDCBFC */
				32,	/* DDCBFD */
				0,	/* DDCBFE SET 7,(IX+d) */
				32,	/* DDCBFF */
		};

char		edlookup[] = {
				32,	/* ED00	*/
				32,	/* ED01	*/
				32,	/* ED02	*/
				32,	/* ED03	*/
				32,	/* ED04	*/
				32,	/* ED05	*/
				32,	/* ED06	*/
				32,	/* ED07	*/

				32,	/* ED08	*/
				32,	/* ED09	*/
				32,	/* ED0A	*/
				32,	/* ED0B	*/
				32,	/* ED0C	*/
				32,	/* ED0D	*/
				32,	/* ED0E	*/
				32,	/* ED0F	*/

				32,	/* ED10	*/
				32,	/* ED11	*/
				32,	/* ED12	*/
				32,	/* ED13	*/
				32,	/* ED14	*/
				32,	/* ED15	*/
				32,	/* ED16	*/
				32,	/* ED17	*/

				32,	/* ED18	*/
				32,	/* ED19	*/
				32,	/* ED1A	*/
				32,	/* ED1B	*/
				32,	/* ED1C	*/
				32,	/* ED1D	*/
				32,	/* ED1E	*/
				32,	/* ED1F	*/

				32,	/* ED20	*/
				32,	/* ED21	*/
				32,	/* ED22	*/
				32,	/* ED23	*/
				32,	/* ED24	*/
				32,	/* ED25	*/
				32,	/* ED26	*/
				32,	/* ED27	*/

				32,	/* ED28	*/
				32,	/* ED29	*/
				32,	/* ED2A	*/
				32,	/* ED2B	*/
				32,	/* ED2C	*/
				32,	/* ED2D	*/
				32,	/* ED2E	*/
				32,	/* ED2F	*/

				32,	/* ED30	*/
				32,	/* ED31	*/
				32,	/* ED32	*/
				32,	/* ED33	*/
				32,	/* ED34	*/
				32,	/* ED35	*/
				32,	/* ED36	*/
				32,	/* ED37	*/

				32,	/* ED38	*/
				32,	/* ED39	*/
				32,	/* ED3A	*/
				32,	/* ED3B	*/
				32,	/* ED3C	*/
				32,	/* ED3D	*/
				32,	/* ED3E	*/
				32,	/* ED3F	*/

				0,	/* ED40	IN B,(C) */
				0,	/* ED41	OUT (C),B */
				0,	/* ED42	SBC HL,BC */
				2,	/* ED43	LD (nn),BC */
				0,	/* ED44	NEG */
				0,	/* ED45	RETN */
				0,	/* ED46	IM 0 */
				0,	/* ED47	LD I,A */

				0,	/* ED48	IN C,(C) */
				0,	/* ED49	OUT (C),C */
				0,	/* ED4A	ADC HL,BC */
				2,	/* ED4B	LD BC,(nn) */
				32,	/* ED4C	*/
				0,	/* ED4D	RETI */
				32,	/* ED4E	*/
				0,	/* ED4F	LD R,A */

				0,	/* ED50	IN D,(C) */
				0,	/* ED51	OUT (C),D */
				0,	/* ED52	SBC HL,DE */
				2,	/* ED53	LD (nn),DE */
				32,	/* ED54	*/
				32,	/* ED55	*/
				0,	/* ED56	IM 1 */
				0,	/* ED57	LD A,I */

				0,	/* ED58	IN E,(C) */
				0,	/* ED59	OUT (C),E */
				0,	/* ED5A	ADC HL,DE */
				2,	/* ED5B	LD DE,(nn) */
				32,	/* ED5C	*/
				32,	/* ED5D	*/
				0,	/* ED5E	IM 2 */
				0,	/* ED5F	LD A,R */

				0,	/* ED60	IN H,(C) */
				0,	/* ED61	OUT (C),H */
				0,	/* ED62	SBC HL,HL */
				32,	/* ED63	*/
				32,	/* ED64	*/
				32,	/* ED65	*/
				32,	/* ED66	*/
				0,	/* ED67	RRD */

				0,	/* ED68	IN L,(C) */
				0,	/* ED69	OUT (C),L */
				0,	/* ED6A	ADC HL,HL */
				32,	/* ED6B	*/
				32,	/* ED6C	*/
				32,	/* ED6D	*/
				32,	/* ED6E	*/
				0,	/* ED6F	RLD */

				0,	/* ED70	IN F,(C) */
				32,	/* ED71	*/
				0,	/* ED72	SBC HL,SP */
				2,	/* ED73	LD (nn),SP */
				32,	/* ED74	*/
				32,	/* ED75	*/
				32,	/* ED76	*/
				32,	/* ED77	*/

				0,	/* ED78	IN A,(C) */
				0,	/* ED79	OUT (C),A */
				0,	/* ED7A	ADC HL,SP */
				2,	/* ED7B	LD SP,(nn) */
				32,	/* ED7C	*/
				32,	/* ED7D	*/
				32,	/* ED7E	*/
				32,	/* ED7F	*/

				32,	/* ED80	*/
				32,	/* ED81	*/
				32,	/* ED82	*/
				32,	/* ED83	*/
				32,	/* ED84	*/
				32,	/* ED85	*/
				32,	/* ED86	*/
				32,	/* ED87	*/

				32,	/* ED88	*/
				32,	/* ED89	*/
				32,	/* ED8A	*/
				32,	/* ED8B	*/
				32,	/* ED8C	*/
				32,	/* ED8D	*/
				32,	/* ED8E	*/
				32,	/* ED8F	*/

				32,	/* ED90	*/
				32,	/* ED91	*/
				32,	/* ED92	*/
				32,	/* ED93	*/
				32,	/* ED94	*/
				32,	/* ED95	*/
				32,	/* ED96	*/
				32,	/* ED97	*/

				32,	/* ED98	*/
				32,	/* ED99	*/
				32,	/* ED9A	*/
				32,	/* ED9B	*/
				32,	/* ED9C	*/
				32,	/* ED9D	*/
				32,	/* ED9E	*/
				32,	/* ED9F	*/

				0,	/* EDA0	LDI */
				0,	/* EDA1	CPI */
				0,	/* EDA2	INI */
				0,	/* EDA3	OUTI */
				32,	/* EDA4	*/
				32,	/* EDA5	*/
				32,	/* EDA6	*/
				32,	/* EDA7	*/

				0,	/* EDA8	LED */
				0,	/* EDA9	CPD */
				0,	/* EDAA	IND */
				0,	/* EDAB	OUTD */
				32,	/* EDAC	*/
				32,	/* EDAD	*/
				32,	/* EDAE	*/
				32,	/* EDAF	*/

				0,	/* EDB0	LDIR */
				0,	/* EDB1	CPIR */
				0,	/* EDB2	INIR */
				0,	/* EDB3	OTIR */
				32,	/* EDB4	*/
				32,	/* EDB5	*/
				32,	/* EDB6	*/
				32,	/* EDB7	*/

				0,	/* EDB8	LEDR */
				0,	/* EDB9	CPDR */
				0,	/* EDBA	INDR */
				0,	/* EDBB	OTDR */
				32,	/* EDBC	*/
				32,	/* EDBD	*/
				32,	/* EDBE	*/
				32,	/* EDBF	*/

				32,	/* EDC0	*/
				32,	/* EDC1	*/
				32,	/* EDC2	*/
				32,	/* EDC3	*/
				32,	/* EDC4	*/
				32,	/* EDC5	*/
				32,	/* EDC6	*/
				32,	/* EDC7	*/

				32,	/* EDC8	*/
				32,	/* EDC9	*/
				32,	/* EDCA	*/
				32,	/* EDCB	*/
				32,	/* EDCC	*/
				32,	/* EDCD	*/
				32,	/* EDCE	*/
				32,	/* EDCF	*/

				32,	/* EDD0	*/
				32,	/* EDD1	*/
				32,	/* EDD2	*/
				32,	/* EDD3	*/
				32,	/* EDD4	*/
				32,	/* EDD5	*/
				32,	/* EDD6	*/
				32,	/* EDD7	*/

				32,	/* EDD8	*/
				32,	/* EDD9	*/
				32,	/* EDDA	*/
				32,	/* EDDB	*/
				32,	/* EDDC	*/
				32,	/* EDDD	*/
				32,	/* EDDE	*/
				32,	/* EDDF	*/

				32,	/* EDE0	*/
				32,	/* EDE1	*/
				32,	/* EDE2	*/
				32,	/* EDE3	*/
				32,	/* EDE4	*/
				32,	/* EDE5	*/
				32,	/* EDE6	*/
				32,	/* EDE7	*/

				32,	/* EDE8	*/
				32,	/* EDE9	*/
				32,	/* EDEA	*/
				32,	/* EDEB	*/
				32,	/* EDEC	*/
				32,	/* EDED	*/
				32,	/* EDEE	*/
				32,	/* EDEF	*/

				32,	/* EDF0	*/
				32,	/* EDF1	*/
				32,	/* EDF2	*/
				32,	/* EDF3	*/
				32,	/* EDF4	*/
				32,	/* EDF5	*/
				32,	/* EDF6	*/
				32,	/* EDF7	*/

				32,	/* EDF8	*/
				32,	/* EDF9	*/
				32,	/* EDFA	*/
				32,	/* EDFB	*/
				32,	/* EDFC	*/
				32,	/* EDFD	*/
				32,	/* EDFE	*/
				32,	/* EDFF	*/
		};


/* Parse area and define end of	area. Start of area defined by <pc> parameter.
 * Continue until terminating instruction is found.
 * return address of end of area (<pc>+length of instruction).
 */
long	ParseArea(long pc)
{
    unsigned char	i;
    long		label;

    while(pc <=	gEndOfCode) {

	i = GetByte(pc++);  /* point at	2. opcode */
	switch(i) {
	    case 203:	    /* CB opcode table,	all instruction	uses 2 byte opcode */
			    pc++; /* ready for next instruction	*/
			    break;

	    case 237:	    /* ED opcode table */
			    i =	GetByte(pc++);		/* point at 3. byte operand or next instruction	*/
			    switch(i) {
				    case    RETI_opcode:
				    case    RETN_opcode:
							/* end of area */
							return pc-1;

				    case    LD_bc_nn_opcode:
				    case    LD_de_nn_opcode:
				    case    LD_hl_nn_opcode2:
				    case    LD_sp_nn_opcode:
				    case    LD_nn_sp_opcode:
				    case    LD_nn_bc_opcode:
				    case    LD_nn_de_opcode:
				    case    LD_nn_hl_opcode2:
							/* remember data address */
							label =	(unsigned char) GetByte(pc++);
							label += (unsigned short) (256 * GetByte(pc++));
							StoreDataRef(label);
							break;

				    default:
							if (edlookup[i]	& 32) {
								printf("\nError: Unknown instruction at %04lX\n", pc-2);
								return pc-2;
							}
							pc += edlookup[i] & 15;
			    }
			    break;

	    case 221:	    /* IX, IY instructions */
	    case 253:
			    i =	GetByte(pc++);		/* point at 3. byte operand or next instruction	*/
			    if (i == 203) {
					i = GetByte(pc+1);	/* opcode is at	offset 3 */
					if (cbindexlookup[i] & 32) {
						printf("\nError: Unknown instruction at %04lX\n", pc-2);
						return pc-2;
					}

					if (cbindexlookup[i] & 16)
						printf("\nWarning: Undocumented instruction at %04lX\n",	pc-2);
					pc += 2;	    /* xx CB opcode table, always 4 bytes, point at next instruction */
			    }
			    else {
				    switch(i) {
					    case    JP_hl_opcode:
								/* end of area */
								return pc-1;

					    case    LD_hl_opcode:
					    case    LD_hl_nn_opcode:
					    case    LD_nn_hl_opcode:
								/* remember data address */
								label =	(unsigned char) GetByte(pc++);
								label += (unsigned short) (256 * GetByte(pc++));
								StoreDataRef(label);
								break;
					    default:
								if (indexlookup[i] & 32) {
									printf("\nError: Unknown instruction at %04lX\n", pc-2);
									return pc-2;
								}

								if (indexlookup[i] & 16)
									printf("\nWarning: Undocumented instruction at %04lX\n",	pc-2);

								pc += indexlookup[i] & 15;
				    }
			    }
			    break;

	    case 223:
			    /* RST 18h,	FPP interface, 1 byte parameter	*/
			    gIncludeList[floatp] = true;      /* mark INCLUDE file to be added in source */
			    pc++;
			    break;

	    case 231:
			    /* RST 20h,	main OS	interface, 1 or	2 byte parameter */
			    i =	GetByte(pc++);
			    switch(i) {
				    case 6:
					    /* OS 2 byte low level calls */
					    i =	GetByte(pc++);
					    i =	(i / 2)	- 101;
					    gIncludeList[os2[i].includefile] = true;
					    break;

				    case 9:
					    /* GN 2 byte general calls */
					    i =	GetByte(pc++);
					    i =	(i / 2)	- 3;
					    gIncludeList[gn[i].includefile] = true;
					    break;

				    case 12:
					    /* DC 2 byte low level calls */
					    i =	GetByte(pc++);
					    gIncludeList[dc[(i/2)-3].includefile] = true;
					    if ((i==DC_BYE) || (i==DC_ENT)) return pc-1;	/* end of area */
					    break;

				    default:
					    /* OS 1 byte low level calls */
					    gIncludeList[os1[(i/3)-11].includefile] = true;
					    if (i==OS_BYE) return pc-1;	/* end of area */
			    }
			    break;

	    default:
			    /* standard	Z80 (Intel 8080	compatible) opcodes */
			    switch(i) {
				    case    RET_opcode:
						    /* end of area */
						    return pc-1;

				    case    JR_opcode:
						    label = (char) GetByte(pc++);
						    label += pc;
						    PushItem(label, &gParseAddress); /*	calculate and push label on parse stack	*/
						    StoreAddrRef(label);
						    /* end of area */
						    return pc-1;

				    case    JR_z_opcode:
				    case    JR_nz_opcode:
				    case    JR_c_opcode:
				    case    JR_nc_opcode:
				    case    DJNZ_opcode:
						    label = (char) GetByte(pc++);
						    label += pc;
						    PushItem(label, &gParseAddress); /*	calculate and push label on parse stack	*/
						    /* calculate and push label	on parse stack */
						    StoreAddrRef(label);
						    break;

				    case    JP_opcode:
						    label = (unsigned char) GetByte(pc++);
						    label += (unsigned short) (256 * GetByte(pc));
						    PushItem(label, &gParseAddress);
						    /* push label on parse stack, end of area */
						    StoreAddrRef(label);
						    return pc;

				    case    JP_hl_opcode:
						    /* end of area */
						    return pc-1;

				    case    JP_nz_opcode:
				    case    JP_z_opcode:
				    case    JP_nc_opcode:
				    case    JP_c_opcode:
				    case    JP_p_opcode:
				    case    JP_m_opcode:
				    case    JP_pe_opcode:
				    case    JP_po_opcode:
				    case    CALL_nz_opcode:
				    case    CALL_z_opcode:
				    case    CALL_nc_opcode:
				    case    CALL_c_opcode:
				    case    CALL_p_opcode:
				    case    CALL_m_opcode:
				    case    CALL_pe_opcode:
				    case    CALL_opcode:
				    case    CALL_po_opcode:
						    label = (unsigned char) GetByte(pc++);
						    label += (unsigned short) (256 * GetByte(pc++));
						    PushItem(label, &gParseAddress); /*	push label on parse stack */
						    StoreAddrRef(label);
						    break;

				    case    LD_bc_opcode:
				    case    LD_de_opcode:
				    case    LD_hl_opcode:
				    case    LD_sp_opcode:
				    case    LD_hl_nn_opcode:
				    case    LD_nn_hl_opcode:
				    case    LD_a_nn_opcode:
				    case    LD_nn_a_opcode:
						    /* remember	data address */
						    label = (unsigned char) GetByte(pc++);
						    label += (unsigned short) (256 * GetByte(pc++));
						    StoreDataRef(label);
						    break;

				    default:
					    pc += mainlookup[i];
			    }
	}
    }

    return gEndOfCode;	/* This	should never happen! */
}



/* Parse code and create program and data areas	*/
void	DZpass1(void)
{
	long		pc, endarea;
	enum atype	foundarea;

	VisitedAddresses = NULL;

	while(gParseAddress!=NULL) {
		pc = PopItem(&gParseAddress);
		if (LocalLabel(pc) == true) {
			foundarea = SearchArea(gAreas, pc);
			if (foundarea != program && foundarea != vacuum && foundarea != notfound)
				puts("Warning: parsing code inside possible data area!");

			endarea	= ParseArea(pc);
			DispParsedArea(pc, endarea);

			if (foundarea == vacuum || foundarea == notfound) {
				if (InsertArea(&gAreas, pc, endarea, program) == NULL) {
					puts("No room");
					break;
				}
			}
		}
	}

	JoinAreas(gAreas);	/* scan	list and join equal type areas */
	deleteall(&VisitedAddresses, (void (*)()) DelParsedAddr);	/* removed collect addresses for this session */
}


enum truefalse	AddressVisited(long pc)
{
	ParsedAddress	*newaddr, *foundaddr;

	foundaddr = find(VisitedAddresses, &pc, (int (*)()) CmpParseAddr2);
	if (foundaddr == NULL) {
		newaddr = AllocParsedAddress();
		if (newaddr != NULL) {
			newaddr->addr = pc;
			newaddr->visited = 1;

			insert(&VisitedAddresses, newaddr, (int (*)()) CmpParseAddr);
		}

		return false;	/* indicate that address was not previously visited */
	} else {
		foundaddr->visited++;
		return true;
	}
}


void	DelParsedAddr(ParsedAddress *node)
{
	if (node != NULL) free(node);
}


void	DispParsedArea(long start, long end)
{
	static short	i = 0;

	if (i++	% 4 == 0)
		printf("\n[%04lXh-%04lXh]", start, end);
	else
		printf("\t[%04lXh-%04lXh]", start, end);
}


/* Store data reference	in avltree */
void		StoreDataRef(long  labeladdr)
{
	LabelRef	*newref, *foundref;

	foundref = find(gLabelRef, &labeladdr, (int (*)()) CmpAddrRef2);
	if (foundref == NULL) {
		newref = InitLabelRef(labeladdr, NULL);
		if (newref != NULL) {
			newref->addrref = false;
		} else {
			puts("No room");
			return;
		}

		if(SearchArea(gExtern, labeladdr) != notfound)
			newref->local =	false;			/* extern address */
		else
			newref->local =	true;			/* local address */

		insert(&gLabelRef, newref, (int (*)()) CmpAddrRef);
		collectfile_changed = true;
	}
	else
		foundref->referenced = true;
}


/* Store Label reference in avltree */
void		StoreAddrRef(long  labeladdr)
{
	LabelRef	*newref, *foundref;

	foundref = find(gLabelRef, &labeladdr, (int (*)()) CmpAddrRef2);
	if (foundref == NULL) {
		newref = InitLabelRef(labeladdr, NULL);
		if (newref != NULL) {
			newref->addrref = true;
		} else {
			puts("No room");
			return;
		}

		if(SearchArea(gExtern, labeladdr) != notfound)
			newref->local =	false;			/* extern address */
		else
			newref->local =	true;			/* local address */

		insert(&gLabelRef, newref, (int (*)()) CmpAddrRef);
		collectfile_changed = true;
	}
	else
		foundref->referenced = true;
}


/* check if address label is inside local or external areas */
enum truefalse	LocalLabel(long  pc)
{
	LabelRef	*foundref;

	foundref = find(gLabelRef, &pc,	(int (*)()) CmpAddrRef2);
	if (foundref ==	NULL)
		return false;
	else
		return foundref->local;
}


int		CmpParseAddr2(long *key, ParsedAddress *node)
{
	return (*key) - (node->addr);
}


int		CmpParseAddr(ParsedAddress *key, ParsedAddress *node)
{
	return (key->addr) - (node->addr);
}


int		CmpAddrRef2(long *key, LabelRef *node)
{
	return (*key) - (node->addr);
}


int		CmpAddrRef(LabelRef *key, LabelRef *node)
{
	return (key->addr) - (node->addr);
}

void		DefineScope(void)
{
	long		addr;
	LabelRef	*foundlblref;
	enum truefalse	xrefscope = false;
	enum truefalse	xdefscope = false;

	if (cmdlGetSym() != name) {
		puts("Missing scope definition.");
		return;
	} else {
		if (strcmp(ident, "xref") == 0)
			xrefscope = true;
		else if (strcmp(ident, "xdef") == 0) {
			xdefscope = true;
		} else {
			puts("Unknown scope definition.");
			return;
		}
	}

	cmdlGetSym();
	if ((addr=GetConstant()) == -1) {
		puts("Address/constant not legal");
		return;
	}

	foundlblref = find(gLabelRef, &addr, (int (*)()) CmpAddrRef2);
	if (foundlblref != NULL) {
		if (xrefscope == true) {
			foundlblref->xref = true;
			foundlblref->xdef = false;
		}
		if (xdefscope == true) {
			foundlblref->xref = false;
			foundlblref->xdef = true;
		}
		collectfile_changed = true;
	} else {
		puts("Address/constant not found");
		return;
	}
}

void		CreateLabel(long addr, char	*label)
{
	char		*newlabel;
	LabelRef	*foundref;
	enum truefalse	local;
	
	foundref = find(gLabelRef, &addr, (int (*)()) CmpAddrRef2);
	if (foundref != NULL) {
		/* add/replace label name to address */
		newlabel = AllocLabelname(label);
		if (newlabel != NULL) strcpy(newlabel, label);

		if (foundref->name != NULL) free(foundref->name);
		foundref->name = newlabel;
		collectfile_changed = true;
	} else {
		/* create new label */
		if (SearchArea(gExtern, addr) != notfound)
			local = false;		/* address not within range of loaded code... */
		else
			local = true;

		CreateLabelRef(&gLabelRef, addr, label, local);
	}
}

void		DefineLabel(void)
{
	long		addr;
	long		tmp;

	cmdlGetSym();
	if ((tmp=GetConstant()) == -1) {
		puts("Label address not legal");
		return;
	} else
		addr = tmp;

	if (cmdlGetSym() != name) {
		puts("Missing label name definition.");
		return;
	}

	CreateLabel(addr, ident);
}


/* Add an address label	to the parse stack */
void	PushItem(long	addr, struct PrsAddrStack **stackpointer)
{
	struct PrsAddrStack	  *newitem;

	if (AddressVisited(addr) == false) {
		/* Add only address on parsing stack if it hasn't been visited yet... */
		if ((newitem = AllocStackItem()) != NULL) {
			newitem->labeladdr = addr;
			newitem->previtem = *stackpointer;	/* link	new node to current node */
			*stackpointer =	newitem;		/* update stackpointer to new item */
		} else
			puts("No room");
	}
}


/* get an address label	(to be parsed) from the	stack */
long	PopItem(struct PrsAddrStack **stackpointer)
{
	struct PrsAddrStack	*stackitem;
	long			address;

	address	= (*stackpointer)->labeladdr;
	stackitem = *stackpointer;
	*stackpointer =	(*stackpointer)->previtem;	/* move	stackpointer to	previous item */
	free(stackitem);				/* return old item memory to OS	*/
	return address;
}


LabelRef	*InitLabelRef(long  labeladdr, char *labelname)
{
	LabelRef	*newlabel;

	newlabel = AllocLabel();
	if (newlabel ==	NULL) return NULL;

	newlabel->addr = labeladdr;
	newlabel->name = NULL;

	if (labelname != NULL) {
		newlabel->name = AllocLabelname(labelname);
		if (newlabel->name != NULL)
			strcpy(newlabel->name, labelname);
	}

	newlabel->referenced = false;
	newlabel->xref = false;
	newlabel->local	= false;
	newlabel->addrref = false;

	return newlabel;
}


/* create a label address item */
LabelRef	*AllocLabel(void)
{
	return (LabelRef *) malloc(sizeof(LabelRef));
}

char		*AllocLabelname(char *name)
{
	return (char *) malloc(strlen(name)+1);
}

/* create a label address stack	item */
struct PrsAddrStack	*AllocStackItem(void)
{
	return (struct PrsAddrStack *) malloc(sizeof(struct PrsAddrStack));
}

ParsedAddress	*AllocParsedAddress(void)
{
	return (ParsedAddress	*) malloc(sizeof(ParsedAddress));
}

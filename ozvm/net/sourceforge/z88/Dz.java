package net.sourceforge.z88;

/*
 * Z88 (Z80) Disassembler. All Z88 OZ manifests are recognised.
 * Code converted & improved from C source, as part of the DZasm 0.22 utility.
 *
 * All 'undocumented' Z80 instructions are recognized, eg. SLL or LD  ixh,ixl.
 */

public class Dz {

	private static final char[] hexcodes = 
		{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
	
	private static final String mainStrMnem[] = {
		"NOP", /* 00 */
		"LD   BC,{0}", /* 01 */
		"LD   (BC),A", /* 02 */
		"INC  BC", /* 03 */
		"INC  B", /* 04 */
		"DEC  B", /* 05 */
		"LD   B,{0}", /* 06 */
		"RLCA", /* 07 */

		"EX   AF,AF'", /* 08 */
		"ADD  HL,BC", /* 09 */
		"LD   A,(BC)", /* 0A */
		"DEC  BC", /* 0B */
		"INC  C", /* 0C */
		"DEC  C", /* 0D */
		"LD   C,{0}", /* 0E */
		"RRCA", /* 0F */

		"DJNZ {0}", /* 10 */
		"LD   DE,{0}", /* 11 */
		"LD   (DE),A", /* 12 */
		"INC  DE", /* 13 */
		"INC  D", /* 14 */
		"DEC  D", /* 15 */
		"LD   D,{0}", /* 16 */
		"RLA", /* 17 */

		"JR   {0}", /* 18 */
		"ADD  HL,DE", /* 19 */
		"LD   A,(DE)", /* 1A */
		"DEC  DE", /* 1B */
		"INC  E", /* 1C */
		"DEC  E", /* 1D */
		"LD   E,{0}", /* 1E */
		"RRA", /* 1F */

		"JR   NZ,{0}", /* 20 */
		"LD   HL,{0}", /* 21 */
		"LD   ({0}),HL", /* 22 */
		"INC  HL", /* 23 */
		"INC  H", /* 24 */
		"DEC  H", /* 25 */
		"LD   H,{0}", /* 26 */
		"DAA", /* 27 */

		"JR   Z,{0}", /* 28 */
		"ADD  HL,HL", /* 29 */
		"LD   HL,({0})", /* 2A */
		"DEC  HL", /* 2B */
		"INC  L", /* 2C */
		"DEC  L", /* 2D */
		"LD   L,{0}", /* 2E */
		"CPL", /* 2F */

		"JR   NC,{0}", /* 30 */
		"LD   SP,{0}", /* 31 */
		"LD   ({0}),A", /* 32 */
		"INC  SP", /* 33 */
		"INC  (HL)", /* 34 */
		"DEC  (HL)", /* 35 */
		"LD   (HL),{0}", /* 36 */
		"SCF", /* 37 */

		"JR   C,{0}", /* 38 */
		"ADD  HL,SP", /* 39 */
		"LD   A,({0})", /* 3A */
		"DEC  SP", /* 3B */
		"INC  A", /* 3C */
		"DEC  A", /* 3D */
		"LD   A,{0}", /* 3E */
		"CCF", /* 3F */

		"LD   B,B", /* 40 */
		"LD   B,C", /* 41 */
		"LD   B,D", /* 42 */
		"LD   B,E", /* 43 */
		"LD   B,H", /* 44 */
		"LD   B,L", /* 45 */
		"LD   B,(HL)", /* 46 */
		"LD   B,A", /* 47 */

		"LD   C,B", /* 48 */
		"LD   C,C", /* 49 */
		"LD   C,D", /* 4A */
		"LD   C,E", /* 4B */
		"LD   C,H", /* 4C */
		"LD   C,L", /* 4D */
		"LD   C,(HL)", /* 4E */
		"LD   C,A", /* 4F */

		"LD   D,B", /* 50 */
		"LD   D,C", /* 51 */
		"LD   D,D", /* 52 */
		"LD   D,E", /* 53 */
		"LD   D,H", /* 54 */
		"LD   D,L", /* 55 */
		"LD   D,(HL)", /* 56 */
		"LD   D,A", /* 57 */

		"LD   E,B", /* 58 */
		"LD   E,C", /* 59 */
		"LD   E,D", /* 5A */
		"LD   E,E", /* 5B */
		"LD   E,H", /* 5C */
		"LD   E,L", /* 5D */
		"LD   E,(HL)", /* 5E */
		"LD   E,A", /* 5F */

		"LD   H,B", /* 60 */
		"LD   H,C", /* 61 */
		"LD   H,D", /* 62 */
		"LD   H,E", /* 63 */
		"LD   H,H", /* 64 */
		"LD   H,L", /* 65 */
		"LD   H,(HL)", /* 66 */
		"LD   H,A", /* 67 */

		"LD   L,B", /* 68 */
		"LD   L,C", /* 69 */
		"LD   L,D", /* 6A */
		"LD   L,E", /* 6B */
		"LD   L,H", /* 6C */
		"LD   L,L", /* 6D */
		"LD   L,(HL)", /* 6E */
		"LD   L,A", /* 6F */

		"LD   (HL),B", /* 70 */
		"LD   (HL),C", /* 71 */
		"LD   (HL),D", /* 72 */
		"LD   (HL),E", /* 73 */
		"LD   (HL),H", /* 74 */
		"LD   (HL),L", /* 75 */
		"HALT", /* 76 */
		"LD   (HL),A", /* 77 */

		"LD   A,B", /* 78 */
		"LD   A,C", /* 79 */
		"LD   A,D", /* 7A */
		"LD   A,E", /* 7B */
		"LD   A,H", /* 7C */
		"LD   A,L", /* 7D */
		"LD   A,(HL)", /* 7E */
		"LD   A,A", /* 7F */

		"ADD  A,B", /* 80 */
		"ADD  A,C", /* 81 */
		"ADD  A,D", /* 82 */
		"ADD  A,E", /* 83 */
		"ADD  A,H", /* 84 */
		"ADD  A,L", /* 85 */
		"ADD  A,(HL)", /* 86 */
		"ADD  A,A", /* 87 */

		"ADC  A,B", /* 88 */
		"ADC  A,C", /* 89 */
		"ADC  A,D", /* 8A */
		"ADC  A,E", /* 8B */
		"ADC  A,H", /* 8C */
		"ADC  A,L", /* 8D */
		"ADC  A,(HL)", /* 8E */
		"ADC  A,A", /* 8F */

		"SUB  B", /* 90 */
		"SUB  C", /* 91 */
		"SUB  D", /* 92 */
		"SUB  E", /* 93 */
		"SUB  H", /* 94 */
		"SUB  L", /* 95 */
		"SUB  (HL)", /* 96 */
		"SUB  A", /* 97 */

		"SBC  A,B", /* 98 */
		"SBC  A,C", /* 99 */
		"SBC  A,D", /* 9A */
		"SBC  A,E", /* 9B */
		"SBC  A,H", /* 9C */
		"SBC  A,L", /* 9D */
		"SBC  A,(HL)", /* 9E */
		"SBC  A,A", /* 9F */

		"AND  B", /* A0 */
		"AND  C", /* A1 */
		"AND  D", /* A2 */
		"AND  E", /* A3 */
		"AND  H", /* A4 */
		"AND  L", /* A5 */
		"AND  (HL)", /* A6 */
		"AND  A", /* A7 */

		"XOR  B", /* A8 */
		"XOR  C", /* A9 */
		"XOR  D", /* AA */
		"XOR  E", /* AB */
		"XOR  H", /* AC */
		"XOR  L", /* AD */
		"XOR  (HL)", /* AE */
		"XOR  A", /* AF */

		"OR   B", /* B0 */
		"OR   C", /* B1 */
		"OR   D", /* B2 */
		"OR   E", /* B3 */
		"OR   H", /* B4 */
		"OR   L", /* B5 */
		"OR   (HL)", /* B6 */
		"OR   A", /* B7 */

		"CP   B", /* B8 */
		"CP   C", /* B9 */
		"CP   D", /* BA */
		"CP   E", /* BB */
		"CP   H", /* BC */
		"CP   L", /* BD */
		"CP   (HL)", /* BE */
		"CP   A", /* BF */

		"RET  NZ", /* C0 */
		"POP  BC", /* C1 */
		"JP   NZ,{0}", /* C2 */
		"JP   {0}", /* C3 */
		"CALL NZ,{0}", /* C4 */
		"PUSH BC", /* C5 */
		"ADD  A,{0}", /* C6 */
		"RST  00h", /* C7 */

		"RET  Z", /* C8 */
		"RET", /* C9 */
		"JP   Z,{0}", /* CA */
		"", /* CB BIT MANIPULATION OPCODES */
		"CALL Z,{0}", /* CC */
		"CALL {0}", /* CD */
		"ADC  A,{0}", /* CE */
		"RST  08h", /* CF */

		"RET  NC", /* D0 */
		"POP  DE", /* D1 */
		"JP   NC,{0}", /* D2 */
		"OUT  ({0}),A", /* D3 */
		"CALL NC,{0}", /* D4 */
		"PUSH DE", /* D5 */
		"SUB  {0}", /* D6 */
		"RST  10h", /* D7 */

		"RET  C", /* D8 */
		"EXX", /* D9 */
		"JP   C,{0}", /* DA */
		"IN   A,({0})", /* DB */
		"CALL C,{0}", /* DC */
		"", /* DD IX OPCODES */
		"SBC  A,{0}", /* DE */
		"RST  18h", /* DF */

		"RET  PO", /* E0 */
		"POP  HL", /* E1 */
		"JP   PO,{0}", /* E2 */
		"EX   (SP),HL", /* E3 */
		"CALL PO,{0}", /* E4 */
		"PUSH HL", /* E5 */
		"AND  {0}", /* E6 */
		"RST  20h", /* E7 */
		"RET  PE", /* E8 */

		"JP   (HL)", /* E9 */
		"JP   PE,{0}", /* EA */
		"EX   DE,HL", /* EB */
		"CALL PE,{0}", /* EC */
		"", /* ED OPCODES */
		"XOR  {0}", /* EE */
		"RST  28h", /* EF */

		"RET  P", /* F0 */
		"POP  AF", /* F1 */
		"JP   P,{0}", /* F2 */
		"DI", /* F3 */
		"CALL P,{0}", /* F4 */
		"PUSH AF", /* F5 */
		"OR   {0}", /* F6 */
		"RST  30h", /* F7 */

		"RET  M", /* F8 */
		"LD   SP,HL", /* F9 */
		"JP   M,{0}", /* FA */
		"EI", /* FB */
		"CALL M,{0}", /* FC */
		"", /* FD IY OPCODES */
		"CP   {0}", /* FE */
		"RST  38h" /* FF */
	};

	private static final int mainArgsMnem[] = {
		0, /* 00 "NOP"          */
		2, /* 01 "LD   BC,n"    */
		0, /* 02 "LD   (BC),A"  */
		0, /* 03 "INC  BC"      */
		0, /* 04 "INC  B"       */
		0, /* 05 "DEC  B"       */
		1, /* 06 "LD   B,n"     */
		0, /* 07 "RLCA"         */

		0, /* 08 "EX   AF,AF'"  */
		0, /* 09 "ADD  HL,BC"   */
		0, /* 0A "LD   A,(BC)"  */
		0, /* 0B "DEC  BC"      */
		0, /* 0C "INC  C"       */
		0, /* 0D "DEC  C"       */
		1, /* 0E "LD   C,n"     */
		0, /* 0F "RRCA"         */

		-1, /* 10 "DJNZ n"       */
		2, /* 11 "LD   DE,nn"   */
		0, /* 12 "LD   (DE),A"  */
		0, /* 13 "INC  DE"      */
		0, /* 14 "INC  D"       */
		0, /* 15 "DEC  D"       */
		1, /* 16 "LD   D,n"     */
		0, /* 17 "RLA"          */

		-1, /* 18 "JR   n"       */
		0, /* 19 "ADD  HL,DE"   */
		0, /* 1A "LD   A,(DE)"  */
		0, /* 1B "DEC  DE"      */
		0, /* 1C "INC  E"       */
		0, /* 1D "DEC  E"       */
		1, /* 1E "LD   E,n"     */
		0, /* 1F "RRA"          */

		-1, /* 20 "JR   NZ,n"    */
		2, /* 21 "LD   HL,nn"   */
		2, /* 22 "LD   (nn),HL" */
		0, /* 23 "INC  HL"      */
		0, /* 24 "INC  H"       */
		0, /* 25 "DEC  H"       */
		1, /* 26 "LD   H,n"     */
		0, /* 27 "DAA"          */

		-1, /* 28 "JR   Z,n"     */
		0, /* 29 "ADD  HL,HL"   */
		2, /* 2A "LD   HL,(nn)" */
		0, /* 2B "DEC  HL"      */
		0, /* 2C "INC  L"       */
		0, /* 2D "DEC  L"       */
		1, /* 2E "LD   L,n"     */
		0, /* 2F "CPL"          */

		-1, /* 30 "JR   NC,n"    */
		2, /* 31 "LD   SP,n"    */
		2, /* 32 "LD   (nn),A"  */
		0, /* 33 "INC  SP"      */
		0, /* 34 "INC  (HL)"    */
		0, /* 35 "DEC  (HL)"    */
		1, /* 36 "LD   (HL),n"  */
		0, /* 37 "SCF"          */

		-1, /* 38 "JR   C,n"     */
		0, /* 39 "ADD  HL,SP"   */
		2, /* 3A "LD   A,(nn)"  */
		0, /* 3B "DEC  SP"      */
		0, /* 3C "INC  A"       */
		0, /* 3D "DEC  A"       */
		1, /* 3E "LD   A,n"     */
		0, /* 3F "CCF"          */

		0, /* 40 "LD   B,B"     */
		0, /* 41 "LD   B,C"     */
		0, /* 42 "LD   B,D"     */
		0, /* 43 "LD   B,E"     */
		0, /* 44 "LD   B,H"     */
		0, /* 45 "LD   B,L"     */
		0, /* 46 "LD   B,(HL)"  */
		0, /* 47 "LD   B,A"     */

		0, /* 48 "LD   C,B"     */
		0, /* 49 "LD   C,C"     */
		0, /* 4A "LD   C,D"     */
		0, /* 4B "LD   C,E"     */
		0, /* 4C "LD   C,H"     */
		0, /* 4D "LD   C,L"     */
		0, /* 4E "LD   C,(HL)"  */
		0, /* 4F "LD   C,A"     */

		0, /* 50 "LD   D,B"     */
		0, /* 51 "LD   D,C"     */
		0, /* 52 "LD   D,D"     */
		0, /* 53 "LD   D,E"     */
		0, /* 54 "LD   D,H"     */
		0, /* 55 "LD   D,L"     */
		0, /* 56 "LD   D,(HL)"  */
		0, /* 57 "LD   D,A"     */

		0, /* 58 "LD   E,B"     */
		0, /* 59 "LD   E,C"     */
		0, /* 5A "LD   E,D"     */
		0, /* 5B "LD   E,E"     */
		0, /* 5C "LD   E,H"     */
		0, /* 5D "LD   E,L"     */
		0, /* 5E "LD   E,(HL)"  */
		0, /* 5F "LD   E,A"     */

		0, /* 60 "LD   H,B"     */
		0, /* 61 "LD   H,C"     */
		0, /* 62 "LD   H,D"     */
		0, /* 63 "LD   H,E"     */
		0, /* 64 "LD   H,H"     */
		0, /* 65 "LD   H,L"     */
		0, /* 66 "LD   H,(HL)"  */
		0, /* 67 "LD   H,A"     */

		0, /* 68 "LD   L,B"     */
		0, /* 69 "LD   L,C"     */
		0, /* 6A "LD   L,D"     */
		0, /* 6B "LD   L,E"     */
		0, /* 6C "LD   L,H"     */
		0, /* 6D "LD   L,L"     */
		0, /* 6E "LD   L,(HL)"  */
		0, /* 6F "LD   L,A"     */

		0, /* 70 "LD   (HL),B"  */
		0, /* 71 "LD   (HL),C"  */
		0, /* 72 "LD   (HL),D"  */
		0, /* 73 "LD   (HL),E"  */
		0, /* 74 "LD   (HL),H"  */
		0, /* 75 "LD   (HL),L"  */
		0, /* 76 "HALT"         */
		0, /* 77 "LD   (HL),A"  */

		0, /* 78 "LD   A,B"     */
		0, /* 79 "LD   A,C"     */
		0, /* 7A "LD   A,D"     */
		0, /* 7B "LD   A,E"     */
		0, /* 7C "LD   A,H"     */
		0, /* 7D "LD   A,L"     */
		0, /* 7E "LD   A,(HL)"  */
		0, /* 7F "LD   A,A"     */

		0, /* 80 "ADD  A,B"     */
		0, /* 81 "ADD  A,C"     */
		0, /* 82 "ADD  A,D"     */
		0, /* 83 "ADD  A,E"     */
		0, /* 84 "ADD  A,H"     */
		0, /* 85 "ADD  A,L"     */
		0, /* 86 "ADD  A,(HL)"  */
		0, /* 87 "ADD  A,A"     */

		0, /* 88 "ADC  A,B"     */
		0, /* 89 "ADC  A,C"     */
		0, /* 8A "ADC  A,D"     */
		0, /* 8B "ADC  A,E"     */
		0, /* 8C "ADC  A,H"     */
		0, /* 8D "ADC  A,L"     */
		0, /* 8E "ADC  A,(HL)"  */
		0, /* 8F "ADC  A,A"     */

		0, /* 90 "SUB  B"       */
		0, /* 91 "SUB  C"       */
		0, /* 92 "SUB  D"       */
		0, /* 93 "SUB  E"       */
		0, /* 94 "SUB  H"       */
		0, /* 95 "SUB  L"       */
		0, /* 96 "SUB  (HL)"    */
		0, /* 97 "SUB  A"       */

		0, /* 98 "SBC  A,B"     */
		0, /* 99 "SBC  A,C"     */
		0, /* 9A "SBC  A,D"     */
		0, /* 9B "SBC  A,E"     */
		0, /* 9C "SBC  A,H"     */
		0, /* 9D "SBC  A,L"     */
		0, /* 9E "SBC  A,(HL)"  */
		0, /* 9F "SBC  A,A"     */

		0, /* A0 "AND  B"       */
		0, /* A1 "AND  C"       */
		0, /* A2 "AND  D"       */
		0, /* A3 "AND  E"       */
		0, /* A4 "AND  H"       */
		0, /* A5 "AND  L"       */
		0, /* A6 "AND  (HL)"    */
		0, /* A7 "AND  A"       */

		0, /* A8 "XOR  B"       */
		0, /* A9 "XOR  C"       */
		0, /* AA "XOR  D"       */
		0, /* AB "XOR  E"       */
		0, /* AC "XOR  H"       */
		0, /* AD "XOR  L"       */
		0, /* AE "XOR  (HL)"    */
		0, /* AF "XOR  A"       */

		0, /* B0 "OR   B"       */
		0, /* B1 "OR   C"       */
		0, /* B2 "OR   D"       */
		0, /* B3 "OR   E"       */
		0, /* B4 "OR   H"       */
		0, /* B5 "OR   L"       */
		0, /* B6 "OR   (HL)"    */
		0, /* B7 "OR   A"       */

		0, /* B8 "CP   B"       */
		0, /* B9 "CP   C"       */
		0, /* BA "CP   D"       */
		0, /* BB "CP   E"       */
		0, /* BC "CP   H"       */
		0, /* BD "CP   L"       */
		0, /* BE "CP   (HL)"    */
		0, /* BF "CP   A"       */

		0, /* C0 "RET  NZ"      */
		0, /* C1 "POP  BC"      */
		2, /* C2 "JP   NZ,n"    */
		2, /* C3 "JP   n"       */
		2, /* C4 "CALL NZ,nn"   */
		0, /* C5 "PUSH BC"      */
		1, /* C6 "ADD  A,n"     */
		0, /* C7 "RST  0"       */

		0, /* C8 "RET  Z"       */
		0, /* C9 "RET"          */
		2, /* CA "JP   Z,nn"    */
		0, /* CB BIT MANIPULATION OPCODES */
		2, /* CC "CALL Z,nn"    */
		2, /* CD "CALL nn"      */
		1, /* CE "ADC  A,n"     */
		0, /* CF "RST  08"      */

		0, /* D0 "RET  NC"      */
		0, /* D1 "POP  DE"      */
		2, /* D2 "JP   NC,nn"   */
		1, /* D3 "OUT  (n),A"   */
		2, /* D4 "CALL NC,nn"   */
		0, /* D5 "PUSH DE"      */
		1, /* D6 "SUB  n"       */
		0, /* D7 "RST  10H"     */

		0, /* D8 "RET  C"       */
		0, /* D9 "EXX"          */
		2, /* DA "JP   C,nn"    */
		1, /* DB "IN   A,(n)"   */
		2, /* DC "CALL C,nn"    */
		0, /* DD IX OPCODES     */
		1, /* DE "SBC  A,n"     */
		0, /* DF "RST  18H"     */

		0, /* E0 "RET  PO"      */
		0, /* E1 "POP  HL"      */
		2, /* E2 "JP   PO,n"    */
		0, /* E3 "EX   (SP),HL" */
		2, /* E4 "CALL PO,nn"   */
		0, /* E5 "PUSH HL"      */
		1, /* E6 "AND  n"       */
		0, /* E7 "RST  20H"     */
		0, /* E8 "RET  PE"      */

		0, /* E9 "JP   (HL)"    */
		2, /* EA "JP   PE,nn"   */
		0, /* EB "EX   DE,HL"   */
		2, /* EC "CALL PE,nn"   */
		0, /* ED OPCODES        */
		1, /* EE "XOR  n"       */
		0, /* EF "RST  28H"     */

		0, /* F0 "RET  P"       */
		0, /* F1 "POP  AF"      */
		2, /* F2 "JP   P,nn"    */
		0, /* F3 "DI"           */
		2, /* F4 "CALL P,nn"    */
		0, /* F5 "PUSH AF"      */
		1, /* F6 "OR   n"       */
		0, /* F7 "RST  30H"     */

		0, /* F8 "RET  M"       */
		0, /* F9 "LD   SP,HL"   */
		2, /* FA "JP   M,nn"    */
		0, /* FB "EI"           */
		2, /* FC "CALL M,nn"    */
		0, /* FD IY OPCODES     */
		1, /* FE "CP   n"       */
		0 /* FF "RST  38H"     */
	};

	private static final String cbStrMnem[] = {
		"RLC  B", /* CB00 */
		"RLC  C", /* CB01 */
		"RLC  D", /* CB02 */
		"RLC  E", /* CB03 */
		"RLC  H", /* CB04 */
		"RLC  L", /* CB05 */
		"RLC  (HL)", /* CB06 */
		"RLC  A", /* CB07 */

		"RRC  B", /* CB08 */
		"RRC  C", /* CB09 */
		"RRC  D", /* CB0A */
		"RRC  E", /* CB0B */
		"RRC  H", /* CB0C */
		"RRC  L", /* CB0D */
		"RRC  (HL)", /* CB0E */
		"RRC  A", /* CB0F */

		"RL   B", /* CB10 */
		"RL   C", /* CB11 */
		"RL   D", /* CB12 */
		"RL   E", /* CB13 */
		"RL   H", /* CB14 */
		"RL   L", /* CB15 */
		"RL   (HL)", /* CB16 */
		"RL   A", /* CB17 */

		"RR   B", /* CB18 */
		"RR   C", /* CB19 */
		"RR   D", /* CB1A */
		"RR   E", /* CB1B */
		"RR   H", /* CB1C */
		"RR   L", /* CB1D */
		"RR   (HL)", /* CB1E */
		"RR   A", /* CB1F */

		"SLA  B", /* CB20 */
		"SLA  C", /* CB21 */
		"SLA  D", /* CB22 */
		"SLA  E", /* CB23 */
		"SLA  H", /* CB24 */
		"SLA  L", /* CB25 */
		"SLA  (HL)", /* CB26 */
		"SLA  A", /* CB27 */

		"SRA  B", /* CB28 */
		"SRA  C", /* CB29 */
		"SRA  D", /* CB2A */
		"SRA  E", /* CB2B */
		"SRA  H", /* CB2C */
		"SRA  L", /* CB2D */
		"SRA  (HL)", /* CB2E */
		"SRA  A", /* CB2F */

		"SLL  B", /* CB30, "?" */
		"SLL  C", /* CB31, "?" */
		"SLL  D", /* CB32, "?" */
		"SLL  E", /* CB33, "?" */
		"SLL  H", /* CB34, "?" */
		"SLL  L", /* CB35, "?" */
		"SLL  (HL)", /* CB36, "?" */
		"SLL  A", /* CB37, "?" */

		"SRL  B", /* CB38 */
		"SRL  C", /* CB39 */
		"SRL  D", /* CB3A */
		"SRL  E", /* CB3B */
		"SRL  H", /* CB3C */
		"SRL  L", /* CB3D */
		"SRL  (HL)", /* CB3E */
		"SRL  A", /* CB3F */

		"BIT  0,B", /* CB40 */
		"BIT  0,C", /* CB41 */
		"BIT  0,D", /* CB42 */
		"BIT  0,E", /* CB43 */
		"BIT  0,H", /* CB44 */
		"BIT  0,L", /* CB45 */
		"BIT  0,(HL)", /* CB46 */
		"BIT  0,A", /* CB47 */

		"BIT  1,B", /* CB48 */
		"BIT  1,C", /* CB49 */
		"BIT  1,D", /* CB4A */
		"BIT  1,E", /* CB4B */
		"BIT  1,H", /* CB4C */
		"BIT  1,L", /* CB4D */
		"BIT  1,(HL)", /* CB4E */
		"BIT  1,A", /* CB4F */

		"BIT  2,B", /* CB50 */
		"BIT  2,C", /* CB51 */
		"BIT  2,D", /* CB52 */
		"BIT  2,E", /* CB53 */
		"BIT  2,H", /* CB54 */
		"BIT  2,L", /* CB55 */
		"BIT  2,(HL)", /* CB56 */
		"BIT  2,A", /* CB57 */

		"BIT  3,B", /* CB58 */
		"BIT  3,C", /* CB59 */
		"BIT  3,D", /* CB5A */
		"BIT  3,E", /* CB5B */
		"BIT  3,H", /* CB5C */
		"BIT  3,L", /* CB5D */
		"BIT  3,(HL)", /* CB5E */
		"BIT  3,A", /* CB5F */

		"BIT  4,B", /* CB60 */
		"BIT  4,C", /* CB61 */
		"BIT  4,D", /* CB62 */
		"BIT  4,E", /* CB63 */
		"BIT  4,H", /* CB64 */
		"BIT  4,L", /* CB65 */
		"BIT  4,(HL)", /* CB66 */
		"BIT  4,A", /* CB67 */

		"BIT  5,B", /* CB68 */
		"BIT  5,C", /* CB69 */
		"BIT  5,D", /* CB6A */
		"BIT  5,E", /* CB6B */
		"BIT  5,H", /* CB6C */
		"BIT  5,L", /* CB6D */
		"BIT  5,(HL)", /* CB6E */
		"BIT  5,A", /* CB6F */

		"BIT  6,B", /* CB70 */
		"BIT  6,C", /* CB71 */
		"BIT  6,D", /* CB72 */
		"BIT  6,E", /* CB73 */
		"BIT  6,H", /* CB74 */
		"BIT  6,L", /* CB75 */
		"BIT  6,(HL)", /* CB76 */
		"BIT  6,A", /* CB77 */

		"BIT  7,B", /* CB78 */
		"BIT  7,C", /* CB79 */
		"BIT  7,D", /* CB7A */
		"BIT  7,E", /* CB7B */
		"BIT  7,H", /* CB7C */
		"BIT  7,L", /* CB7D */
		"BIT  7,(HL)", /* CB7E */
		"BIT  7,A", /* CB7F */

		"RES  0,B", /* CB80 */
		"RES  0,C", /* CB81 */
		"RES  0,D", /* CB82 */
		"RES  0,E", /* CB83 */
		"RES  0,H", /* CB84 */
		"RES  0,L", /* CB85 */
		"RES  0,(HL)", /* CB86 */
		"RES  0,A", /* CB87 */

		"RES  1,B", /* CB88 */
		"RES  1,C", /* CB89 */
		"RES  1,D", /* CB8A */
		"RES  1,E", /* CB8B */
		"RES  1,H", /* CB8C */
		"RES  1,L", /* CB8D */
		"RES  1,(HL)", /* CB8E */
		"RES  1,A", /* CB8F */

		"RES  2,B", /* CB90 */
		"RES  2,C", /* CB91 */
		"RES  2,D", /* CB92 */
		"RES  2,E", /* CB93 */
		"RES  2,H", /* CB94 */
		"RES  2,L", /* CB95 */
		"RES  2,(HL)", /* CB96 */
		"RES  2,A", /* CB97 */

		"RES  3,B", /* CB98 */
		"RES  3,C", /* CB99 */
		"RES  3,D", /* CB9A */
		"RES  3,E", /* CB9B */
		"RES  3,H", /* CB9C */
		"RES  3,L", /* CB9D */
		"RES  3,(HL)", /* CB9E */
		"RES  3,A", /* CB9F */

		"RES  4,B", /* CBA0 */
		"RES  4,C", /* CBA1 */
		"RES  4,D", /* CBA2 */
		"RES  4,E", /* CBA3 */
		"RES  4,H", /* CBA4 */
		"RES  4,L", /* CBA5 */
		"RES  4,(HL)", /* CBA6 */
		"RES  4,A", /* CBA7 */

		"RES  5,B", /* CBA8 */
		"RES  5,C", /* CBA9 */
		"RES  5,D", /* CBAA */
		"RES  5,E", /* CBAB */
		"RES  5,H", /* CBAC */
		"RES  5,L", /* CBAD */
		"RES  5,(HL)", /* CBAE */
		"RES  5,A", /* CBAF */

		"RES  6,B", /* CBB0 */
		"RES  6,C", /* CBB1 */
		"RES  6,D", /* CBB2 */
		"RES  6,E", /* CBB3 */
		"RES  6,H", /* CBB4 */
		"RES  6,L", /* CBB5 */
		"RES  6,(HL)", /* CBB6 */
		"RES  6,A", /* CBB7 */

		"RES  7,B", /* CBB8 */
		"RES  7,C", /* CBB9 */
		"RES  7,D", /* CBBA */
		"RES  7,E", /* CBBB */
		"RES  7,H", /* CBBC */
		"RES  7,L", /* CBBD */
		"RES  7,(HL)", /* CBBE */
		"RES  7,A", /* CBBF */

		"SET  0,B", /* CBC0 */
		"SET  0,C", /* CBC1 */
		"SET  0,D", /* CBC2 */
		"SET  0,E", /* CBC3 */
		"SET  0,H", /* CBC4 */
		"SET  0,L", /* CBC5 */
		"SET  0,(HL)", /* CBC6 */
		"SET  0,A", /* CBC7 */

		"SET  1,B", /* CBC8 */
		"SET  1,C", /* CBC9 */
		"SET  1,D", /* CBCA */
		"SET  1,E", /* CBCB */
		"SET  1,H", /* CBCC */
		"SET  1,L", /* CBCD */
		"SET  1,(HL)", /* CBCE */
		"SET  1,A", /* CBCF */

		"SET  2,B", /* CBD0 */
		"SET  2,C", /* CBD1 */
		"SET  2,D", /* CBD2 */
		"SET  2,E", /* CBD3 */
		"SET  2,H", /* CBD4 */
		"SET  2,L", /* CBD5 */
		"SET  2,(HL)", /* CBD6 */
		"SET  2,A", /* CBD7 */

		"SET  3,B", /* CBD8 */
		"SET  3,C", /* CBD9 */
		"SET  3,D", /* CBDA */
		"SET  3,E", /* CBDB */
		"SET  3,H", /* CBDC */
		"SET  3,L", /* CBDD */
		"SET  3,(HL)", /* CBDE */
		"SET  3,A", /* CBDF */

		"SET  4,B", /* CBE0 */
		"SET  4,C", /* CBE1 */
		"SET  4,D", /* CBE2 */
		"SET  4,E", /* CBE3 */
		"SET  4,H", /* CBE4 */
		"SET  4,L", /* CBE5 */
		"SET  4,(HL)", /* CBE6 */
		"SET  4,A", /* CBE7 */

		"SET  5,B", /* CBE8 */
		"SET  5,C", /* CBE9 */
		"SET  5,D", /* CBEA */
		"SET  5,E", /* CBEB */
		"SET  5,H", /* CBEC */
		"SET  5,L", /* CBED */
		"SET  5,(HL)", /* CBEE */
		"SET  5,A", /* CBEF */

		"SET  6,B", /* CBF0 */
		"SET  6,C", /* CBF1 */
		"SET  6,D", /* CBF2 */
		"SET  6,E", /* CBF3 */
		"SET  6,H", /* CBF4 */
		"SET  6,L", /* CBF5 */
		"SET  6,(HL)", /* CBF6 */
		"SET  6,A", /* CBF7 */

		"SET  7,B", /* CBF8 */
		"SET  7,C", /* CBF9 */
		"SET  7,D", /* CBFA */
		"SET  7,E", /* CBFB */
		"SET  7,H", /* CBFC */
		"SET  7,L", /* CBFD */
		"SET  7,(HL)", /* CBFE */
		"SET  7,A" /* CBFF */
	};

	private static final String ddcbStrMnem[] = {
		"?", /* DDCB00 */
		"?", /* DDCB01 */
		"?", /* DDCB02 */
		"?", /* DDCB03 */
		"?", /* DDCB04 */
		"?", /* DDCB05 */
		"RLC  (IX{0})", /* DDCB06 */
		"?", /* DDCB07 */

		"?", /* DDCB08 */
		"?", /* DDCB09 */
		"?", /* DDCB0A */
		"?", /* DDCB0B */
		"?", /* DDCB0C */
		"?", /* DDCB0D */
		"RRC  (IX{0})", /* DDCB0E */
		"?", /* DDCB0F */

		"?", /* DDCB10 */
		"?", /* DDCB11 */
		"?", /* DDCB12 */
		"?", /* DDCB13 */
		"?", /* DDCB14 */
		"?", /* DDCB15 */
		"RL   (IX{0})", /* DDCB16 */
		"?", /* DDCB17 */

		"?", /* DDCB18 */
		"?", /* DDCB19 */
		"?", /* DDCB1A */
		"?", /* DDCB1B */
		"?", /* DDCB1C */
		"?", /* DDCB1D */
		"RR   (IX{0})", /* DDCB1E */
		"?", /* DDCB1F */

		"?", /* DDCB20 */
		"?", /* DDCB21 */
		"?", /* DDCB22 */
		"?", /* DDCB23 */
		"?", /* DDCB24 */
		"?", /* DDCB25 */
		"SLA  (IX{0})", /* DDCB26 */
		"?", /* DDCB27 */

		"?", /* DDCB28 */
		"?", /* DDCB29 */
		"?", /* DDCB2A */
		"?", /* DDCB2B */
		"?", /* DDCB2C */
		"?", /* DDCB2D */
		"SRA  (IX{0})", /* DDCB2E */
		"?", /* DDCB2F */

		"?", /* DDCB30 */
		"?", /* DDCB31 */
		"?", /* DDCB32 */
		"?", /* DDCB33 */
		"?", /* DDCB34 */
		"?", /* DDCB35 */
		"SLL  (IX{0})", /* DDCB36 */
		"?", /* DDCB37 */

		"?", /* DDCB38 */
		"?", /* DDCB39 */
		"?", /* DDCB3A */
		"?", /* DDCB3B */
		"?", /* DDCB3C */
		"?", /* DDCB3D */
		"SRL  (IX{0})", /* DDCB3E */
		"?", /* DDCB3F */

		"?", /* DDCB40 */
		"?", /* DDCB41 */
		"?", /* DDCB42 */
		"?", /* DDCB43 */
		"?", /* DDCB44 */
		"?", /* DDCB45 */
		"BIT  0,(IX{0})", /* DDCB46 */
		"?", /* DDCB47 */

		"?", /* DDCB48 */
		"?", /* DDCB49 */
		"?", /* DDCB4A */
		"?", /* DDCB4B */
		"?", /* DDCB4C */
		"?", /* DDCB4D */
		"BIT  1,(IX{0})", /* DDCB4E */
		"?", /* DDCB4F */

		"?", /* DDCB50 */
		"?", /* DDCB51 */
		"?", /* DDCB52 */
		"?", /* DDCB53 */
		"?", /* DDCB54 */
		"?", /* DDCB55 */
		"BIT  2,(IX{0})", /* DDCB56 */
		"?", /* DDCB57 */

		"?", /* DDCB58 */
		"?", /* DDCB59 */
		"?", /* DDCB5A */
		"?", /* DDCB5B */
		"?", /* DDCB5C */
		"?", /* DDCB5D */
		"BIT  3,(IX{0})", /* DDCB5E */
		"?", /* DDCB5F */

		"?", /* DDCB60 */
		"?", /* DDCB61 */
		"?", /* DDCB62 */
		"?", /* DDCB63 */
		"?", /* DDCB64 */
		"?", /* DDCB65 */
		"BIT  4,(IX{0})", /* DDCB66 */
		"?", /* DDCB67 */

		"?", /* DDCB68 */
		"?", /* DDCB69 */
		"?", /* DDCB6A */
		"?", /* DDCB6B */
		"?", /* DDCB6C */
		"?", /* DDCB6D */
		"BIT  5,(IX{0})", /* DDCB6E */
		"?", /* DDCB6F */

		"?", /* DDCB70 */
		"?", /* DDCB71 */
		"?", /* DDCB72 */
		"?", /* DDCB73 */
		"?", /* DDCB74 */
		"?", /* DDCB75 */
		"BIT  6,(IX{0})", /* DDCB76 */
		"?", /* DDCB77 */

		"?", /* DDCB78 */
		"?", /* DDCB79 */
		"?", /* DDCB7A */
		"?", /* DDCB7B */
		"?", /* DDCB7C */
		"?", /* DDCB7D */
		"BIT  7,(IX{0})", /* DDCB7E */
		"?", /* DDCB7F */

		"?", /* DDCB80 */
		"?", /* DDCB81 */
		"?", /* DDCB82 */
		"?", /* DDCB83 */
		"?", /* DDCB84 */
		"?", /* DDCB85 */
		"RES  0,(IX{0})", /* DDCB86 */
		"?", /* DDCB87 */

		"?", /* DDCB88 */
		"?", /* DDCB89 */
		"?", /* DDCB8A */
		"?", /* DDCB8B */
		"?", /* DDCB8C */
		"?", /* DDCB8D */
		"RES  1,(IX{0})", /* DDCB8E */
		"?", /* DDCB8F */

		"?", /* DDCB90 */
		"?", /* DDCB91 */
		"?", /* DDCB92 */
		"?", /* DDCB93 */
		"?", /* DDCB94 */
		"?", /* DDCB95 */
		"RES  2,(IX{0})", /* DDCB96 */
		"?", /* DDCB97 */

		"?", /* DDCB98 */
		"?", /* DDCB99 */
		"?", /* DDCB9A */
		"?", /* DDCB9B */
		"?", /* DDCB9C */
		"?", /* DDCB9D */
		"RES  3,(IX{0})", /* DDCB9E */
		"?", /* DDCB9F */

		"?", /* DDCBA0 */
		"?", /* DDCBA1 */
		"?", /* DDCBA2 */
		"?", /* DDCBA3 */
		"?", /* DDCBA4 */
		"?", /* DDCBA5 */
		"RES  4,(IX{0})", /* DDCBA6 */
		"?", /* DDCBA7 */

		"?", /* DDCBA8 */
		"?", /* DDCBA9 */
		"?", /* DDCBAA */
		"?", /* DDCBAB */
		"?", /* DDCBAC */
		"?", /* DDCBAD */
		"RES  5,(IX{0})", /* DDCBAE */
		"?", /* DDCBAF */

		"?", /* DDCBB0 */
		"?", /* DDCBB1 */
		"?", /* DDCBB2 */
		"?", /* DDCBB3 */
		"?", /* DDCBB4 */
		"?", /* DDCBB5 */
		"RES  6,(IX{0})", /* DDCBB6 */
		"?", /* DDCBB7 */

		"?", /* DDCBB8 */
		"?", /* DDCBB9 */
		"?", /* DDCBBA */
		"?", /* DDCBBB */
		"?", /* DDCBBC */
		"?", /* DDCBBD */
		"RES  7,(IX{0})", /* DDCBBE */
		"?", /* DDCBBF */

		"?", /* DDCBC0 */
		"?", /* DDCBC1 */
		"?", /* DDCBC2 */
		"?", /* DDCBC3 */
		"?", /* DDCBC4 */
		"?", /* DDCBC5 */
		"SET  0,(IX{0})", /* DDCBC6 */
		"?", /* DDCBC7 */

		"?", /* DDCBC8 */
		"?", /* DDCBC9 */
		"?", /* DDCBCA */
		"?", /* DDCBCB */
		"?", /* DDCBCC */
		"?", /* DDCBCD */
		"SET  1,(IX{0})", /* DDCBCE */
		"?", /* DDCBCF */

		"?", /* DDCBD0 */
		"?", /* DDCBD1 */
		"?", /* DDCBD2 */
		"?", /* DDCBD3 */
		"?", /* DDCBD4 */
		"?", /* DDCBD5 */
		"SET  2,(IX{0})", /* DDCBD6 */
		"?", /* DDCBD7 */

		"?", /* DDCBD8 */
		"?", /* DDCBD9 */
		"?", /* DDCBDA */
		"?", /* DDCBDB */
		"?", /* DDCBDC */
		"?", /* DDCBDD */
		"SET  3,(IX{0})", /* DDCBDE */
		"?", /* DDCBDF */

		"?", /* DDCBE0 */
		"?", /* DDCBE1 */
		"?", /* DDCBE2 */
		"?", /* DDCBE3 */
		"?", /* DDCBE4 */
		"?", /* DDCBE5 */
		"SET  4,(IX{0})", /* DDCBE6 */
		"?", /* DDCBE7 */

		"?", /* DDCBE8 */
		"?", /* DDCBE9 */
		"?", /* DDCBEA */
		"?", /* DDCBEB */
		"?", /* DDCBEC */
		"?", /* DDCBED */
		"SET  5,(IX{0})", /* DDCBEE */
		"?", /* DDCBEF */

		"?", /* DDCBF0 */
		"?", /* DDCBF1 */
		"?", /* DDCBF2 */
		"?", /* DDCBF3 */
		"?", /* DDCBF4 */
		"?", /* DDCBF5 */
		"SET  6,(IX{0})", /* DDCBF6 */
		"?", /* DDCBF7 */

		"?", /* DDCBF8 */
		"?", /* DDCBF9 */
		"?", /* DDCBFA */
		"?", /* DDCBFB */
		"?", /* DDCBFC */
		"?", /* DDCBFD */
		"SET  7,(IX{0})", /* DDCBFE */
		"?" /* DDCBFF */
	};

	private static final int ddcbArgsMnem[] = {
		0, /* DDCB00 */
		0, /* DDCB01 */
		0, /* DDCB02 */
		0, /* DDCB03 */
		0, /* DDCB04 */
		0, /* DDCB05 */
		-2, /* DDCB06 */
		0, /* DDCB07 */

		0, /* DDCB08 */
		0, /* DDCB09 */
		0, /* DDCB0A */
		0, /* DDCB0B */
		0, /* DDCB0C */
		0, /* DDCB0D */
		-2, /* DDCB0E */
		0, /* DDCB0F */

		0, /* DDCB10 */
		0, /* DDCB11 */
		0, /* DDCB12 */
		0, /* DDCB13 */
		0, /* DDCB14 */
		0, /* DDCB15 */
		-2, /* DDCB16 */
		0, /* DDCB17 */

		0, /* DDCB18 */
		0, /* DDCB19 */
		0, /* DDCB1A */
		0, /* DDCB1B */
		0, /* DDCB1C */
		0, /* DDCB1D */
		-2, /* DDCB1E */
		0, /* DDCB1F */

		0, /* DDCB20 */
		0, /* DDCB21 */
		0, /* DDCB22 */
		0, /* DDCB23 */
		0, /* DDCB24 */
		0, /* DDCB25 */
		-2, /* DDCB26 */
		0, /* DDCB27 */

		0, /* DDCB28 */
		0, /* DDCB29 */
		0, /* DDCB2A */
		0, /* DDCB2B */
		0, /* DDCB2C */
		0, /* DDCB2D */
		-2, /* DDCB2E */
		0, /* DDCB2F */

		0, /* DDCB30 */
		0, /* DDCB31 */
		0, /* DDCB32 */
		0, /* DDCB33 */
		0, /* DDCB34 */
		0, /* DDCB35 */
		-2, /* DDCB36 */
		0, /* DDCB37 */

		0, /* DDCB38 */
		0, /* DDCB39 */
		0, /* DDCB3A */
		0, /* DDCB3B */
		0, /* DDCB3C */
		0, /* DDCB3D */
		-2, /* DDCB3E */
		0, /* DDCB3F */

		0, /* DDCB40 */
		0, /* DDCB41 */
		0, /* DDCB42 */
		0, /* DDCB43 */
		0, /* DDCB44 */
		0, /* DDCB45 */
		-2, /* DDCB46 */
		0, /* DDCB47 */

		0, /* DDCB48 */
		0, /* DDCB49 */
		0, /* DDCB4A */
		0, /* DDCB4B */
		0, /* DDCB4C */
		0, /* DDCB4D */
		-2, /* DDCB4E */
		0, /* DDCB4F */

		0, /* DDCB50 */
		0, /* DDCB51 */
		0, /* DDCB52 */
		0, /* DDCB53 */
		0, /* DDCB54 */
		0, /* DDCB55 */
		-2, /* DDCB56 */
		0, /* DDCB57 */

		0, /* DDCB58 */
		0, /* DDCB59 */
		0, /* DDCB5A */
		0, /* DDCB5B */
		0, /* DDCB5C */
		0, /* DDCB5D */
		-2, /* DDCB5E */
		0, /* DDCB5F */

		0, /* DDCB60 */
		0, /* DDCB61 */
		0, /* DDCB62 */
		0, /* DDCB63 */
		0, /* DDCB64 */
		0, /* DDCB65 */
		-2, /* DDCB66 */
		0, /* DDCB67 */

		0, /* DDCB68 */
		0, /* DDCB69 */
		0, /* DDCB6A */
		0, /* DDCB6B */
		0, /* DDCB6C */
		0, /* DDCB6D */
		-2, /* DDCB6E */
		0, /* DDCB6F */

		0, /* DDCB70 */
		0, /* DDCB71 */
		0, /* DDCB72 */
		0, /* DDCB73 */
		0, /* DDCB74 */
		0, /* DDCB75 */
		-2, /* DDCB76 */
		0, /* DDCB77 */

		0, /* DDCB78 */
		0, /* DDCB79 */
		0, /* DDCB7A */
		0, /* DDCB7B */
		0, /* DDCB7C */
		0, /* DDCB7D */
		-2, /* DDCB7E */
		0, /* DDCB7F */

		0, /* DDCB80 */
		0, /* DDCB81 */
		0, /* DDCB82 */
		0, /* DDCB83 */
		0, /* DDCB84 */
		0, /* DDCB85 */
		-2, /* DDCB86 */
		0, /* DDCB87 */

		0, /* DDCB88 */
		0, /* DDCB89 */
		0, /* DDCB8A */
		0, /* DDCB8B */
		0, /* DDCB8C */
		0, /* DDCB8D */
		-2, /* DDCB8E */
		0, /* DDCB8F */

		0, /* DDCB90 */
		0, /* DDCB91 */
		0, /* DDCB92 */
		0, /* DDCB93 */
		0, /* DDCB94 */
		0, /* DDCB95 */
		-2, /* DDCB96 */
		0, /* DDCB97 */

		0, /* DDCB98 */
		0, /* DDCB99 */
		0, /* DDCB9A */
		0, /* DDCB9B */
		0, /* DDCB9C */
		0, /* DDCB9D */
		-2, /* DDCB9E */
		0, /* DDCB9F */

		0, /* DDCBA0 */
		0, /* DDCBA1 */
		0, /* DDCBA2 */
		0, /* DDCBA3 */
		0, /* DDCBA4 */
		0, /* DDCBA5 */
		-2, /* DDCBA6 */
		0, /* DDCBA7 */

		0, /* DDCBA8 */
		0, /* DDCBA9 */
		0, /* DDCBAA */
		0, /* DDCBAB */
		0, /* DDCBAC */
		0, /* DDCBAD */
		-2, /* DDCBAE */
		0, /* DDCBAF */

		0, /* DDCBB0 */
		0, /* DDCBB1 */
		0, /* DDCBB2 */
		0, /* DDCBB3 */
		0, /* DDCBB4 */
		0, /* DDCBB5 */
		-2, /* DDCBB6 */
		0, /* DDCBB7 */

		0, /* DDCBB8 */
		0, /* DDCBB9 */
		0, /* DDCBBA */
		0, /* DDCBBB */
		0, /* DDCBBC */
		0, /* DDCBBD */
		-2, /* DDCBBE */
		0, /* DDCBBF */

		0, /* DDCBC0 */
		0, /* DDCBC1 */
		0, /* DDCBC2 */
		0, /* DDCBC3 */
		0, /* DDCBC4 */
		0, /* DDCBC5 */
		-2, /* DDCBC6 */
		0, /* DDCBC7 */

		0, /* DDCBC8 */
		0, /* DDCBC9 */
		0, /* DDCBCA */
		0, /* DDCBCB */
		0, /* DDCBCC */
		0, /* DDCBCD */
		-2, /* DDCBCE */
		0, /* DDCBCF */

		0, /* DDCBD0 */
		0, /* DDCBD1 */
		0, /* DDCBD2 */
		0, /* DDCBD3 */
		0, /* DDCBD4 */
		0, /* DDCBD5 */
		-2, /* DDCBD6 */
		0, /* DDCBD7 */

		0, /* DDCBD8 */
		0, /* DDCBD9 */
		0, /* DDCBDA */
		0, /* DDCBDB */
		0, /* DDCBDC */
		0, /* DDCBDD */
		-2, /* DDCBDE */
		0, /* DDCBDF */

		0, /* DDCBE0 */
		0, /* DDCBE1 */
		0, /* DDCBE2 */
		0, /* DDCBE3 */
		0, /* DDCBE4 */
		0, /* DDCBE5 */
		-2, /* DDCBE6 */
		0, /* DDCBE7 */

		0, /* DDCBE8 */
		0, /* DDCBE9 */
		0, /* DDCBEA */
		0, /* DDCBEB */
		0, /* DDCBEC */
		0, /* DDCBED */
		-2, /* DDCBEE */
		0, /* DDCBEF */

		0, /* DDCBF0 */
		0, /* DDCBF1 */
		0, /* DDCBF2 */
		0, /* DDCBF3 */
		0, /* DDCBF4 */
		0, /* DDCBF5 */
		-2, /* DDCBF6 */
		0, /* DDCBF7 */

		0, /* DDCBF8 */
		0, /* DDCBF9 */
		0, /* DDCBFA */
		0, /* DDCBFB */
		0, /* DDCBFC */
		0, /* DDCBFD */
		-2, /* DDCBFE */
		0 /* DDCBFF */
	};

	private static final String fdcbStrMnem[] = {
		"?", /* FDCB00 */
		"?", /* FDCB01 */
		"?", /* FDCB02 */
		"?", /* FDCB03 */
		"?", /* FDCB04 */
		"?", /* FDCB05 */
		"RLC  (IY{0})", /* FDCB06 */
		"?", /* FDCB07 */

		"?", /* FDCB08 */
		"?", /* FDCB09 */
		"?", /* FDCB0A */
		"?", /* FDCB0B */
		"?", /* FDCB0C */
		"?", /* FDCB0D */
		"RRC  (IY{0})", /* FDCB0E */
		"?", /* FDCB0F */

		"?", /* FDCB10 */
		"?", /* FDCB11 */
		"?", /* FDCB12 */
		"?", /* FDCB13 */
		"?", /* FDCB14 */
		"?", /* FDCB15 */
		"RL   (IY{0})", /* FDCB16 */
		"?", /* FDCB17 */

		"?", /* FDCB18 */
		"?", /* FDCB19 */
		"?", /* FDCB1A */
		"?", /* FDCB1B */
		"?", /* FDCB1C */
		"?", /* FDCB1D */
		"RR   (IY{0})", /* FDCB1E */
		"?", /* FDCB1F */

		"?", /* FDCB20 */
		"?", /* FDCB21 */
		"?", /* FDCB22 */
		"?", /* FDCB23 */
		"?", /* FDCB24 */
		"?", /* FDCB25 */
		"SLA  (IY{0})", /* FDCB26 */
		"?", /* FDCB27 */

		"?", /* FDCB28 */
		"?", /* FDCB29 */
		"?", /* FDCB2A */
		"?", /* FDCB2B */
		"?", /* FDCB2C */
		"?", /* FDCB2D */
		"SRA  (IY{0})", /* FDCB2E */
		"?", /* FDCB2F */

		"?", /* FDCB30 */
		"?", /* FDCB31 */
		"?", /* FDCB32 */
		"?", /* FDCB33 */
		"?", /* FDCB34 */
		"?", /* FDCB35 */
		"SLL  (IY{0})", /* FDCB36 */
		"?", /* FDCB37 */

		"?", /* FDCB38 */
		"?", /* FDCB39 */
		"?", /* FDCB3A */
		"?", /* FDCB3B */
		"?", /* FDCB3C */
		"?", /* FDCB3D */
		"SRL  (IY{0})", /* FDCB3E */
		"?", /* FDCB3F */

		"?", /* FDCB40 */
		"?", /* FDCB41 */
		"?", /* FDCB42 */
		"?", /* FDCB43 */
		"?", /* FDCB44 */
		"?", /* FDCB45 */
		"BIT  0,(IY{0})", /* FDCB46 */
		"?", /* FDCB47 */

		"?", /* FDCB48 */
		"?", /* FDCB49 */
		"?", /* FDCB4A */
		"?", /* FDCB4B */
		"?", /* FDCB4C */
		"?", /* FDCB4D */
		"BIT  1,(IY{0})", /* FDCB4E */
		"?", /* FDCB4F */

		"?", /* FDCB50 */
		"?", /* FDCB51 */
		"?", /* FDCB52 */
		"?", /* FDCB53 */
		"?", /* FDCB54 */
		"?", /* FDCB55 */
		"BIT  2,(IY{0})", /* FDCB56 */
		"?", /* FDCB57 */

		"?", /* FDCB58 */
		"?", /* FDCB59 */
		"?", /* FDCB5A */
		"?", /* FDCB5B */
		"?", /* FDCB5C */
		"?", /* FDCB5D */
		"BIT  3,(IY{0})", /* FDCB5E */
		"?", /* FDCB5F */

		"?", /* FDCB60 */
		"?", /* FDCB61 */
		"?", /* FDCB62 */
		"?", /* FDCB63 */
		"?", /* FDCB64 */
		"?", /* FDCB65 */
		"BIT  4,(IY{0})", /* FDCB66 */
		"?", /* FDCB67 */

		"?", /* FDCB68 */
		"?", /* FDCB69 */
		"?", /* FDCB6A */
		"?", /* FDCB6B */
		"?", /* FDCB6C */
		"?", /* FDCB6D */
		"BIT  5,(IY{0})", /* FDCB6E */
		"?", /* FDCB6F */

		"?", /* FDCB70 */
		"?", /* FDCB71 */
		"?", /* FDCB72 */
		"?", /* FDCB73 */
		"?", /* FDCB74 */
		"?", /* FDCB75 */
		"BIT  6,(IY{0})", /* FDCB76 */
		"?", /* FDCB77 */

		"?", /* FDCB78 */
		"?", /* FDCB79 */
		"?", /* FDCB7A */
		"?", /* FDCB7B */
		"?", /* FDCB7C */
		"?", /* FDCB7D */
		"BIT  7,(IY{0})", /* FDCB7E */
		"?", /* FDCB7F */

		"?", /* FDCB80 */
		"?", /* FDCB81 */
		"?", /* FDCB82 */
		"?", /* FDCB83 */
		"?", /* FDCB84 */
		"?", /* FDCB85 */
		"RES  0,(IY{0})", /* FDCB86 */
		"?", /* FDCB87 */

		"?", /* FDCB88 */
		"?", /* FDCB89 */
		"?", /* FDCB8A */
		"?", /* FDCB8B */
		"?", /* FDCB8C */
		"?", /* FDCB8D */
		"RES  1,(IY{0})", /* FDCB8E */
		"?", /* FDCB8F */

		"?", /* FDCB90 */
		"?", /* FDCB91 */
		"?", /* FDCB92 */
		"?", /* FDCB93 */
		"?", /* FDCB94 */
		"?", /* FDCB95 */
		"RES  2,(IY{0})", /* FDCB96 */
		"?", /* FDCB97 */

		"?", /* FDCB98 */
		"?", /* FDCB99 */
		"?", /* FDCB9A */
		"?", /* FDCB9B */
		"?", /* FDCB9C */
		"?", /* FDCB9D */
		"RES  3,(IY{0})", /* FDCB9E */
		"?", /* FDCB9F */

		"?", /* FDCBA0 */
		"?", /* FDCBA1 */
		"?", /* FDCBA2 */
		"?", /* FDCBA3 */
		"?", /* FDCBA4 */
		"?", /* FDCBA5 */
		"RES  4,(IY{0})", /* FDCBA6 */
		"?", /* FDCBA7 */

		"?", /* FDCBA8 */
		"?", /* FDCBA9 */
		"?", /* FDCBAA */
		"?", /* FDCBAB */
		"?", /* FDCBAC */
		"?", /* FDCBAD */
		"RES  5,(IY{0})", /* FDCBAE */
		"?", /* FDCBAF */

		"?", /* FDCBB0 */
		"?", /* FDCBB1 */
		"?", /* FDCBB2 */
		"?", /* FDCBB3 */
		"?", /* FDCBB4 */
		"?", /* FDCBB5 */
		"RES  6,(IY{0})", /* FDCBB6 */
		"?", /* FDCBB7 */

		"?", /* FDCBB8 */
		"?", /* FDCBB9 */
		"?", /* FDCBBA */
		"?", /* FDCBBB */
		"?", /* FDCBBC */
		"?", /* FDCBBD */
		"RES  7,(IY{0})", /* FDCBBE */
		"?", /* FDCBBF */

		"?", /* FDCBC0 */
		"?", /* FDCBC1 */
		"?", /* FDCBC2 */
		"?", /* FDCBC3 */
		"?", /* FDCBC4 */
		"?", /* FDCBC5 */
		"SET  0,(IY{0})", /* FDCBC6 */
		"?", /* FDCBC7 */

		"?", /* FDCBC8 */
		"?", /* FDCBC9 */
		"?", /* FDCBCA */
		"?", /* FDCBCB */
		"?", /* FDCBCC */
		"?", /* FDCBCD */
		"SET  1,(IY{0})", /* FDCBCE */
		"?", /* FDCBCF */

		"?", /* FDCBD0 */
		"?", /* FDCBD1 */
		"?", /* FDCBD2 */
		"?", /* FDCBD3 */
		"?", /* FDCBD4 */
		"?", /* FDCBD5 */
		"SET  2,(IY{0})", /* FDCBD6 */
		"?", /* FDCBD7 */

		"?", /* FDCBD8 */
		"?", /* FDCBD9 */
		"?", /* FDCBDA */
		"?", /* FDCBDB */
		"?", /* FDCBDC */
		"?", /* FDCBDD */
		"SET  3,(IY{0})", /* FDCBDE */
		"?", /* FDCBDF */

		"?", /* FDCBE0 */
		"?", /* FDCBE1 */
		"?", /* FDCBE2 */
		"?", /* FDCBE3 */
		"?", /* FDCBE4 */
		"?", /* FDCBE5 */
		"SET  4,(IY{0})", /* FDCBE6 */
		"?", /* FDCBE7 */

		"?", /* FDCBE8 */
		"?", /* FDCBE9 */
		"?", /* FDCBEA */
		"?", /* FDCBEB */
		"?", /* FDCBEC */
		"?", /* FDCBED */
		"SET  5,(IY{0})", /* FDCBEE */
		"?", /* FDCBEF */

		"?", /* FDCBF0 */
		"?", /* FDCBF1 */
		"?", /* FDCBF2 */
		"?", /* FDCBF3 */
		"?", /* FDCBF4 */
		"?", /* FDCBF5 */
		"SET  6,(IY{0})", /* FDCBF6 */
		"?", /* FDCBF7 */

		"?", /* FDCBF8 */
		"?", /* FDCBF9 */
		"?", /* FDCBFA */
		"?", /* FDCBFB */
		"?", /* FDCBFC */
		"?", /* FDCBFD */
		"SET  7,(IY{0})", /* FDCBFE */
		"?" /* FDCBFF */
	};

	private static final int fdcbArgsMnem[] = {
		0, /* FDCB00 */
		0, /* FDCB01 */
		0, /* FDCB02 */
		0, /* FDCB03 */
		0, /* FDCB04 */
		0, /* FDCB05 */
		-2, /* FDCB06 */
		0, /* FDCB07 */

		0, /* FDCB08 */
		0, /* FDCB09 */
		0, /* FDCB0A */
		0, /* FDCB0B */
		0, /* FDCB0C */
		0, /* FDCB0D */
		-2, /* FDCB0E */
		0, /* FDCB0F */

		0, /* FDCB10 */
		0, /* FDCB11 */
		0, /* FDCB12 */
		0, /* FDCB13 */
		0, /* FDCB14 */
		0, /* FDCB15 */
		-2, /* FDCB16 */
		0, /* FDCB17 */

		0, /* FDCB18 */
		0, /* FDCB19 */
		0, /* FDCB1A */
		0, /* FDCB1B */
		0, /* FDCB1C */
		0, /* FDCB1D */
		-2, /* FDCB1E */
		0, /* FDCB1F */

		0, /* FDCB20 */
		0, /* FDCB21 */
		0, /* FDCB22 */
		0, /* FDCB23 */
		0, /* FDCB24 */
		0, /* FDCB25 */
		-2, /* FDCB26 */
		0, /* FDCB27 */

		0, /* FDCB28 */
		0, /* FDCB29 */
		0, /* FDCB2A */
		0, /* FDCB2B */
		0, /* FDCB2C */
		0, /* FDCB2D */
		-2, /* FDCB2E */
		0, /* FDCB2F */

		0, /* FDCB30 */
		0, /* FDCB31 */
		0, /* FDCB32 */
		0, /* FDCB33 */
		0, /* FDCB34 */
		0, /* FDCB35 */
		-2, /* FDCB36 */
		0, /* FDCB37 */

		0, /* FDCB38 */
		0, /* FDCB39 */
		0, /* FDCB3A */
		0, /* FDCB3B */
		0, /* FDCB3C */
		0, /* FDCB3D */
		-2, /* FDCB3E */
		0, /* FDCB3F */

		0, /* FDCB40 */
		0, /* FDCB41 */
		0, /* FDCB42 */
		0, /* FDCB43 */
		0, /* FDCB44 */
		0, /* FDCB45 */
		-2, /* FDCB46 */
		0, /* FDCB47 */

		0, /* FDCB48 */
		0, /* FDCB49 */
		0, /* FDCB4A */
		0, /* FDCB4B */
		0, /* FDCB4C */
		0, /* FDCB4D */
		-2, /* FDCB4E */
		0, /* FDCB4F */

		0, /* FDCB50 */
		0, /* FDCB51 */
		0, /* FDCB52 */
		0, /* FDCB53 */
		0, /* FDCB54 */
		0, /* FDCB55 */
		-2, /* FDCB56 */
		0, /* FDCB57 */

		0, /* FDCB58 */
		0, /* FDCB59 */
		0, /* FDCB5A */
		0, /* FDCB5B */
		0, /* FDCB5C */
		0, /* FDCB5D */
		-2, /* FDCB5E */
		0, /* FDCB5F */

		0, /* FDCB60 */
		0, /* FDCB61 */
		0, /* FDCB62 */
		0, /* FDCB63 */
		0, /* FDCB64 */
		0, /* FDCB65 */
		-2, /* FDCB66 */
		0, /* FDCB67 */

		0, /* FDCB68 */
		0, /* FDCB69 */
		0, /* FDCB6A */
		0, /* FDCB6B */
		0, /* FDCB6C */
		0, /* FDCB6D */
		-2, /* FDCB6E */
		0, /* FDCB6F */

		0, /* FDCB70 */
		0, /* FDCB71 */
		0, /* FDCB72 */
		0, /* FDCB73 */
		0, /* FDCB74 */
		0, /* FDCB75 */
		-2, /* FDCB76 */
		0, /* FDCB77 */

		0, /* FDCB78 */
		0, /* FDCB79 */
		0, /* FDCB7A */
		0, /* FDCB7B */
		0, /* FDCB7C */
		0, /* FDCB7D */
		-2, /* FDCB7E */
		0, /* FDCB7F */

		0, /* FDCB80 */
		0, /* FDCB81 */
		0, /* FDCB82 */
		0, /* FDCB83 */
		0, /* FDCB84 */
		0, /* FDCB85 */
		-2, /* FDCB86 */
		0, /* FDCB87 */

		0, /* FDCB88 */
		0, /* FDCB89 */
		0, /* FDCB8A */
		0, /* FDCB8B */
		0, /* FDCB8C */
		0, /* FDCB8D */
		-2, /* FDCB8E */
		0, /* FDCB8F */

		0, /* FDCB90 */
		0, /* FDCB91 */
		0, /* FDCB92 */
		0, /* FDCB93 */
		0, /* FDCB94 */
		0, /* FDCB95 */
		-2, /* FDCB96 */
		0, /* FDCB97 */

		0, /* FDCB98 */
		0, /* FDCB99 */
		0, /* FDCB9A */
		0, /* FDCB9B */
		0, /* FDCB9C */
		0, /* FDCB9D */
		-2, /* FDCB9E */
		0, /* FDCB9F */

		0, /* FDCBA0 */
		0, /* FDCBA1 */
		0, /* FDCBA2 */
		0, /* FDCBA3 */
		0, /* FDCBA4 */
		0, /* FDCBA5 */
		-2, /* FDCBA6 */
		0, /* FDCBA7 */

		0, /* FDCBA8 */
		0, /* FDCBA9 */
		0, /* FDCBAA */
		0, /* FDCBAB */
		0, /* FDCBAC */
		0, /* FDCBAD */
		-2, /* FDCBAE */
		0, /* FDCBAF */

		0, /* FDCBB0 */
		0, /* FDCBB1 */
		0, /* FDCBB2 */
		0, /* FDCBB3 */
		0, /* FDCBB4 */
		0, /* FDCBB5 */
		-2, /* FDCBB6 */
		0, /* FDCBB7 */

		0, /* FDCBB8 */
		0, /* FDCBB9 */
		0, /* FDCBBA */
		0, /* FDCBBB */
		0, /* FDCBBC */
		0, /* FDCBBD */
		-2, /* FDCBBE */
		0, /* FDCBBF */

		0, /* FDCBC0 */
		0, /* FDCBC1 */
		0, /* FDCBC2 */
		0, /* FDCBC3 */
		0, /* FDCBC4 */
		0, /* FDCBC5 */
		-2, /* FDCBC6 */
		0, /* FDCBC7 */

		0, /* FDCBC8 */
		0, /* FDCBC9 */
		0, /* FDCBCA */
		0, /* FDCBCB */
		0, /* FDCBCC */
		0, /* FDCBCD */
		-2, /* FDCBCE */
		0, /* FDCBCF */

		0, /* FDCBD0 */
		0, /* FDCBD1 */
		0, /* FDCBD2 */
		0, /* FDCBD3 */
		0, /* FDCBD4 */
		0, /* FDCBD5 */
		-2, /* FDCBD6 */
		0, /* FDCBD7 */

		0, /* FDCBD8 */
		0, /* FDCBD9 */
		0, /* FDCBDA */
		0, /* FDCBDB */
		0, /* FDCBDC */
		0, /* FDCBDD */
		-2, /* FDCBDE */
		0, /* FDCBDF */

		0, /* FDCBE0 */
		0, /* FDCBE1 */
		0, /* FDCBE2 */
		0, /* FDCBE3 */
		0, /* FDCBE4 */
		0, /* FDCBE5 */
		-2, /* FDCBE6 */
		0, /* FDCBE7 */

		0, /* FDCBE8 */
		0, /* FDCBE9 */
		0, /* FDCBEA */
		0, /* FDCBEB */
		0, /* FDCBEC */
		0, /* FDCBED */
		-2, /* FDCBEE */
		0, /* FDCBEF */

		0, /* FDCBF0 */
		0, /* FDCBF1 */
		0, /* FDCBF2 */
		0, /* FDCBF3 */
		0, /* FDCBF4 */
		0, /* FDCBF5 */
		-2, /* FDCBF6 */
		0, /* FDCBF7 */

		0, /* FDCBF8 */
		0, /* FDCBF9 */
		0, /* FDCBFA */
		0, /* FDCBFB */
		0, /* FDCBFC */
		0, /* FDCBFD */
		-2, /* FDCBFE */
		0 /* FDCBFF */
	};

	private static final String ddStrMnem[] = {
		"?", /* DD00 */
		"?", /* DD01 */
		"?", /* DD02 */
		"?", /* DD03 */
		"?", /* DD04 */
		"?", /* DD05 */
		"?", /* DD06 */
		"?", /* DD07 */

		"?", /* DD08 */
		"ADD  IX,BC", /* DD09 */
		"?", /* DD0A */
		"?", /* DD0B */
		"?", /* DD0C */
		"?", /* DD0D */
		"?", /* DD0E */
		"?", /* DD0F */

		"?", /* DD10 */
		"?", /* DD11 */
		"?", /* DD12 */
		"?", /* DD13 */
		"?", /* DD14 */
		"?", /* DD15 */
		"?", /* DD16 */
		"?", /* DD17 */

		"?", /* DD18 */
		"ADD  IX,DE", /* DD19 */
		"?", /* DD1A */
		"?", /* DD1B */
		"?", /* DD1C */
		"?", /* DD1D */
		"?", /* DD1E */
		"?", /* DD1F */

		"?", /* DD20 */
		"LD   IX,{0}", /* DD21 */
		"LD   ({0}),IX", /* DD22 */
		"INC  IX", /* DD23 */
		"INC  IXH", /* DD24 */
		"DEC  IXH", /* DD25 */
		"LD   IXH,{0}", /* DD26 */
		"?", /* DD27 */

		"?", /* DD28 */
		"ADD  IX,IX", /* DD29 */
		"LD   IX,({0})", /* DD2A */
		"DEC  IX", /* DD2B */
		"INC  IXL", /* DD24 */
		"DEC  IXL", /* DD25 */
		"LD   IXL,{0}", /* DD26 */
		"?", /* DD2F */

		"?", /* DD30 */
		"?", /* DD31 */
		"?", /* DD32 */
		"?", /* DD33 */
		"INC  (IX{0})", /* DD34 */
		"DEC  (IX{0})", /* DD35 */
		"LD   (IX{0}),{1}", /* DD36 */
		"?", /* DD37 */

		"?", /* DD38 */
		"ADD  IX,SP", /* DD39 */
		"?", /* DD3A */
		"?", /* DD3B */
		"?", /* DD3C */
		"?", /* DD3D */
		"?", /* DD3E */
		"?", /* DD3F */

		"?", /* DD40 */
		"?", /* DD41 */
		"?", /* DD42 */
		"?", /* DD43 */
		"LD   B,IXH", /* DD44 */
		"LD   B,IXL", /* DD45 */
		"LD   B,(IX{0})", /* DD46 */
		"?", /* DD47 */

		"?", /* DD48 */
		"?", /* DD49 */
		"?", /* DD4A */
		"?", /* DD4B */
		"LD   C,IXH", /* DD4C */
		"LD   C,IXL", /* DD4D */
		"LD   C,(IX{0})", /* DD4E */
		"?", /* DD4F */

		"?", /* DD50 */
		"?", /* DD51 */
		"?", /* DD52 */
		"?", /* DD53 */
		"LD   D,IXH", /* DD54 */
		"LD   D,IXL", /* DD55 */
		"LD   D,(IX{0})", /* DD56 */
		"?", /* DD57 */

		"?", /* DD58 */
		"?", /* DD59 */
		"?", /* DD5A */
		"?", /* DD5B */
		"LD   E,IXH", /* DD5C */
		"LD   E,IXL", /* DD5D */
		"LD   E,(IX{0})", /* DD5E */
		"?", /* DD5F */

		"LD   IXH,B", /* DD60 */
		"LD   IXH,C", /* DD61 */
		"LD   IXH,D", /* DD62 */
		"LD   IXH,E", /* DD63 */
		"LD   IXH,IXH", /* DD64 */
		"LD   IXH,IXL", /* DD65 */
		"LD   H,(IX{0})", /* DD66 */
		"LD   IXH,A", /* DD67 */

		"LD   IXL,B", /* DD68 */
		"LD   IXL,C", /* DD69 */
		"LD   IXL,D", /* DD6A */
		"LD   IXL,E", /* DD6B */
		"LD   IXL,IXH", /* DD6C */
		"LD   IXL,IXL", /* DD6D */
		"LD   L,(IX{0})", /* DD6E */
		"LD   IXL,A", /* DD6F */

		"LD   (IX{0}),B", /* DD70 */
		"LD   (IX{0}),C", /* DD71 */
		"LD   (IX{0}),D", /* DD72 */
		"LD   (IX{0}),E", /* DD73 */
		"LD   (IX{0}),H", /* DD74 */
		"LD   (IX{0}),L", /* DD75 */
		"?", /* DD76 */
		"LD   (IX{0}),A", /* DD77 */

		"?", /* DD78 */
		"?", /* DD79 */
		"?", /* DD7A */
		"?", /* DD7B */
		"LD   A,IXH", /* DD7C */
		"LD   A,IXL", /* DD7D */
		"LD   A,(IX{0})", /* DD7E */
		"?", /* DD7F */

		"?", /* DD80 */
		"?", /* DD81 */
		"?", /* DD82 */
		"?", /* DD83 */
		"ADD  A,IXH", /* DD84 */
		"ADD  A,IXL", /* DD85 */
		"ADD  A,(IX{0})", /* DD86 */
		"?", /* DD87 */

		"?", /* DD88 */
		"?", /* DD89 */
		"?", /* DD8A */
		"?", /* DD8B */
		"ADC  A,IXH", /* DD8D */
		"ADC  A,IXL", /* DD8E */
		"ADC  A,(IX{0})", /* DD8E */
		"?", /* DD8F */

		"?", /* DD90 */
		"?", /* DD91 */
		"?", /* DD92 */
		"?", /* DD93 */
		"SUB  IXH", /* DD94 */
		"SUB  IXL", /* DD95 */
		"SUB  (IX{0})", /* DD96 */
		"?", /* DD97 */

		"?", /* DD98 */
		"?", /* DD99 */
		"?", /* DD9A */
		"?", /* DD9B */
		"SBC  A,IXH", /* DD9C */
		"SBC  A,IXL", /* DD9D */
		"SBC  A,(IX{0})", /* DD9E */
		"?", /* DD9F */

		"?", /* DDA0 */
		"?", /* DDA1 */
		"?", /* DDA2 */
		"?", /* DDA3 */
		"AND  IXH", /* DDA4 */
		"AND  IXL", /* DDA5 */
		"AND  (IX{0})", /* DDA6 */
		"?", /* DDA7 */

		"?", /* DDA8 */
		"?", /* DDA9 */
		"?", /* DDAA */
		"?", /* DDAB */
		"XOR  IXH", /* DDAC */
		"XOR  IXL", /* DDAD */
		"XOR  (IX{0})", /* DDAE */
		"?", /* DDAF */

		"?", /* DDB0 */
		"?", /* DDB1 */
		"?", /* DDB2 */
		"?", /* DDB3 */
		"OR   IXH", /* DDB4 */
		"OR   IXL", /* DDB5 */
		"OR   (IX{0})", /* DDB6 */
		"?", /* DDB7 */

		"?", /* DDB8 */
		"?", /* DDB9 */
		"?", /* DDBA */
		"?", /* DDBB */
		"CP   IXH", /* DDBC */
		"CP   IXL", /* DDBD */
		"CP   (IX{0})", /* DDBE */
		"?", /* DDBF */

		"?", /* DDC0 */
		"?", /* DDC1 */
		"?", /* DDC2 */
		"?", /* DDC3 */
		"?", /* DDC4 */
		"?", /* DDC5 */
		"?", /* DDC6 */
		"?", /* DDC7 */

		"?", /* DDC8 */
		"?", /* DDC9 */
		"?", /* DDCA */
		"?", /* DDCB */
		"?", /* DDCC */
		"?", /* DDCD */
		"?", /* DDCE */
		"?", /* DDCF */

		"?", /* DDD0 */
		"?", /* DDD1 */
		"?", /* DDD2 */
		"?", /* DDD3 */
		"?", /* DDD4 */
		"?", /* DDD5 */
		"?", /* DDD6 */
		"?", /* DDD7 */

		"?", /* DDD8 */
		"?", /* DDD9 */
		"?", /* DDDA */
		"?", /* DDDB */
		"?", /* DDDC */
		"?", /* DDDD */
		"?", /* DDDE */
		"?", /* DDDF */

		"?", /* DDE0 */
		"POP  IX", /* DDE1 */
		"?", /* DDE2 */
		"EX   (SP),IX", /* DDE3 */
		"?", /* DDE4 */
		"PUSH IX", /* DDE5 */
		"?", /* DDE6 */
		"?", /* DDE7 */

		"?", /* DDE8 */
		"JP   (IX)", /* DDE9 */
		"?", /* DDEA */
		"?", /* DDEB */
		"?", /* DDEC */
		"?", /* DDED */
		"?", /* DDEE */
		"?", /* DDEF */

		"?", /* DDF0 */
		"?", /* DDF1 */
		"?", /* DDF2 */
		"?", /* DDF3 */
		"?", /* DDF4 */
		"?", /* DDF5 */
		"?", /* DDF6 */
		"?", /* DDF7 */

		"?", /* DDF8 */
		"LD   SP,IX", /* DDF9 */
		"?", /* DDFA */
		"?", /* DDFB */
		"?", /* DDFC */
		"?", /* DDFD */
		"?", /* DDFE */
		"?" /* DDFF */
	};

	private static final int ddArgsMnem[] = {
		0, /* DD00 */
		0, /* DD01 */
		0, /* DD02 */
		0, /* DD03 */
		0, /* DD04 */
		0, /* DD05 */
		0, /* DD06 */
		0, /* DD07 */

		0, /* DD08 */
		0, /* DD09 */
		0, /* DD0A */
		0, /* DD0B */
		0, /* DD0C */
		0, /* DD0D */
		0, /* DD0E */
		0, /* DD0F */

		0, /* DD10 */
		0, /* DD11 */
		0, /* DD12 */
		0, /* DD13 */
		0, /* DD14 */
		0, /* DD15 */
		0, /* DD16 */
		0, /* DD17 */

		0, /* DD18 */
		0, /* DD19 */
		0, /* DD1A */
		0, /* DD1B */
		0, /* DD1C */
		0, /* DD1D */
		0, /* DD1E */
		0, /* DD1F */

		0, /* DD20 */
		2, /* DD21 */
		2, /* DD22 */
		0, /* DD23 */
		0, /* DD24 */
		0, /* DD25 */
		1, /* DD26 */
		0, /* DD27 */

		0, /* DD28 */
		0, /* DD29 */
		2, /* DD2A */
		0, /* DD2B */
		0, /* DD24 */
		0, /* DD25 */
		1, /* DD26 */
		0, /* DD2F */

		0, /* DD30 */
		0, /* DD31 */
		0, /* DD32 */
		0, /* DD33 */
		-4, /* DD34 */
		-4, /* DD35 */
		-3, /* DD36 */
		0, /* DD37 */

		0, /* DD38 */
		0, /* DD39 */
		0, /* DD3A */
		0, /* DD3B */
		0, /* DD3C */
		0, /* DD3D */
		0, /* DD3E */
		0, /* DD3F */

		0, /* DD40 */
		0, /* DD41 */
		0, /* DD42 */
		0, /* DD43 */
		0, /* DD44 */
		0, /* DD45 */
		-4, /* DD46 */
		0, /* DD47 */

		0, /* DD48 */
		0, /* DD49 */
		0, /* DD4A */
		0, /* DD4B */
		0, /* DD4C */
		0, /* DD4D */
		-4, /* DD4E */
		0, /* DD4F */

		0, /* DD50 */
		0, /* DD51 */
		0, /* DD52 */
		0, /* DD53 */
		0, /* DD54 */
		0, /* DD55 */
		-4, /* DD56 */
		0, /* DD57 */

		0, /* DD58 */
		0, /* DD59 */
		0, /* DD5A */
		0, /* DD5B */
		0, /* DD5C */
		0, /* DD5D */
		-4, /* DD5E */
		0, /* DD5F */

		0, /* DD60 */
		0, /* DD61 */
		0, /* DD62 */
		0, /* DD63 */
		0, /* DD64 */
		0, /* DD65 */
		-4, /* DD66 */
		0, /* DD67 */

		0, /* DD68 */
		0, /* DD69 */
		0, /* DD6A */
		0, /* DD6B */
		0, /* DD6C */
		0, /* DD6D */
		-4, /* DD6E */
		0, /* DD6F */

		-4, /* DD70 */
		-4, /* DD71 */
		-4, /* DD72 */
		-4, /* DD73 */
		-4, /* DD74 */
		-4, /* DD75 */
		0, /* DD76 */
		-4, /* DD77 */

		0, /* DD78 */
		0, /* DD79 */
		0, /* DD7A */
		0, /* DD7B */
		0, /* DD7C */
		0, /* DD7D */
		-4, /* DD7E */
		0, /* DD7F */

		0, /* DD80 */
		0, /* DD81 */
		0, /* DD82 */
		0, /* DD83 */
		0, /* DD84 */
		0, /* DD85 */
		-4, /* DD86 */
		0, /* DD87 */

		0, /* DD88 */
		0, /* DD89 */
		0, /* DD8A */
		0, /* DD8B */
		0, /* DD8D */
		0, /* DD8E */
		-4, /* DD8E */
		0, /* DD8F */

		0, /* DD90 */
		0, /* DD91 */
		0, /* DD92 */
		0, /* DD93 */
		0, /* DD94 */
		0, /* DD95 */
		-4, /* DD96 */
		0, /* DD97 */

		0, /* DD98 */
		0, /* DD99 */
		0, /* DD9A */
		0, /* DD9B */
		0, /* DD9C */
		0, /* DD9D */
		-4, /* DD9E */
		0, /* DD9F */

		0, /* DDA0 */
		0, /* DDA1 */
		0, /* DDA2 */
		0, /* DDA3 */
		0, /* DDA4 */
		0, /* DDA5 */
		-4, /* DDA6 */
		0, /* DDA7 */

		0, /* DDA8 */
		0, /* DDA9 */
		0, /* DDAA */
		0, /* DDAB */
		0, /* DDAC */
		0, /* DDAD */
		-4, /* DDAE */
		0, /* DDAF */

		0, /* DDB0 */
		0, /* DDB1 */
		0, /* DDB2 */
		0, /* DDB3 */
		0, /* DDB4 */
		0, /* DDB5 */
		-4, /* DDB6 */
		0, /* DDB7 */

		0, /* DDB8 */
		0, /* DDB9 */
		0, /* DDBA */
		0, /* DDBB */
		0, /* DDBC */
		0, /* DDBD */
		-4, /* DDBE */
		0, /* DDBF */

		0, /* DDC0 */
		0, /* DDC1 */
		0, /* DDC2 */
		0, /* DDC3 */
		0, /* DDC4 */
		0, /* DDC5 */
		0, /* DDC6 */
		0, /* DDC7 */

		0, /* DDC8 */
		0, /* DDC9 */
		0, /* DDCA */
		0, /* DDCB */
		0, /* DDCC */
		0, /* DDCD */
		0, /* DDCE */
		0, /* DDCF */

		0, /* DDD0 */
		0, /* DDD1 */
		0, /* DDD2 */
		0, /* DDD3 */
		0, /* DDD4 */
		0, /* DDD5 */
		0, /* DDD6 */
		0, /* DDD7 */

		0, /* DDD8 */
		0, /* DDD9 */
		0, /* DDDA */
		0, /* DDDB */
		0, /* DDDC */
		0, /* DDDD */
		0, /* DDDE */
		0, /* DDDF */

		0, /* DDE0 */
		0, /* DDE1 */
		0, /* DDE2 */
		0, /* DDE3 */
		0, /* DDE4 */
		0, /* DDE5 */
		0, /* DDE6 */
		0, /* DDE7 */

		0, /* DDE8 */
		0, /* DDE9 */
		0, /* DDEA */
		0, /* DDEB */
		0, /* DDEC */
		0, /* DDED */
		0, /* DDEE */
		0, /* DDEF */

		0, /* DDF0 */
		0, /* DDF1 */
		0, /* DDF2 */
		0, /* DDF3 */
		0, /* DDF4 */
		0, /* DDF5 */
		0, /* DDF6 */
		0, /* DDF7 */

		0, /* DDF8 */
		0, /* DDF9 */
		0, /* DDFA */
		0, /* DDFB */
		0, /* DDFC */
		0, /* DDFD */
		0, /* DDFE */
		0 /* DDFF */
	};

	private static final String fdStrMnem[] = {
		"?", /* FD00 */
		"?", /* FD01 */
		"?", /* FD02 */
		"?", /* FD03 */
		"?", /* FD04 */
		"?", /* FD05 */
		"?", /* FD06 */
		"?", /* FD07 */

		"?", /* FD08 */
		"ADD  IY,BC", /* FD09 */
		"?", /* FD0A */
		"?", /* FD0B */
		"?", /* FD0C */
		"?", /* FD0D */
		"?", /* FD0E */
		"?", /* FD0F */

		"?", /* FD10 */
		"?", /* FD11 */
		"?", /* FD12 */
		"?", /* FD13 */
		"?", /* FD14 */
		"?", /* FD15 */
		"?", /* FD16 */
		"?", /* FD17 */

		"?", /* FD18 */
		"ADD  IY,DE", /* FD19 */
		"?", /* FD1A */
		"?", /* FD1B */
		"?", /* FD1C */
		"?", /* FD1D */
		"?", /* FD1E */
		"?", /* FD1F */

		"?", /* FD20 */
		"LD   IY,{0}", /* FD21 */
		"LD   ({0}),IY", /* FD22 */
		"INC  IY", /* FD23 */
		"INC  IYH", /* FD24 */
		"DEC  IYH", /* FD25 */
		"LD   IYH,{0}", /* FD26 */
		"?", /* FD27 */

		"?", /* FD28 */
		"ADD  IY,IY", /* FD29 */
		"LD   IY,({0})", /* FD2A */
		"DEC  IY", /* FD2B */
		"INC  IYL", /* FD24 */
		"DEC  IYL", /* FD25 */
		"LD   IYL,{0}", /* FD26 */
		"?", /* FD2F */

		"?", /* FD30 */
		"?", /* FD31 */
		"?", /* FD32 */
		"?", /* FD33 */
		"INC  (IY{0})", /* FD34 */
		"DEC  (IY{0})", /* FD35 */
		"LD   (IY{0}),{1}", /* FD36 */
		"?", /* FD37 */

		"?", /* FD38 */
		"ADD  IY,SP", /* FD39 */
		"?", /* FD3A */
		"?", /* FD3B */
		"?", /* FD3C */
		"?", /* FD3D */
		"?", /* FD3E */
		"?", /* FD3F */

		"?", /* FD40 */
		"?", /* FD41 */
		"?", /* FD42 */
		"?", /* FD43 */
		"LD   B,IYH", /* FD44 */
		"LD   B,IYL", /* FD45 */
		"LD   B,(IY{0})", /* FD46 */
		"?", /* FD47 */

		"?", /* FD48 */
		"?", /* FD49 */
		"?", /* FD4A */
		"?", /* FD4B */
		"LD   C,IYH", /* FD4C */
		"LD   C,IYL", /* FD4D */
		"LD   C,(IY{0})", /* FD4E */
		"?", /* FD4F */

		"?", /* FD50 */
		"?", /* FD51 */
		"?", /* FD52 */
		"?", /* FD53 */
		"LD   D,IYH", /* FD54 */
		"LD   D,IYL", /* FD55 */
		"LD   D,(IY{0})", /* FD56 */
		"?", /* FD57 */

		"?", /* FD58 */
		"?", /* FD59 */
		"?", /* FD5A */
		"?", /* FD5B */
		"LD   E,IYH", /* FD5C */
		"LD   E,IYL", /* FD5D */
		"LD   E,(IY{0})", /* FD5E */
		"?", /* FD5F */

		"LD   IYH,B", /* FD60 */
		"LD   IYH,C", /* FD61 */
		"LD   IYH,D", /* FD62 */
		"LD   IYH,E", /* FD63 */
		"LD   IYH,IYH", /* FD64 */
		"LD   IYH,IYL", /* FD65 */
		"LD   H,(IY{0})", /* FD66 */
		"LD   IYH,A", /* FD67 */

		"LD   IYL,B", /* FD68 */
		"LD   IYL,C", /* FD69 */
		"LD   IYL,D", /* FD6A */
		"LD   IYL,E", /* FD6B */
		"LD   IYL,IYH", /* FD6C */
		"LD   IYL,IYL", /* FD6D */
		"LD   L,(IY{0})", /* FD6E */
		"LD   IYL,A", /* FD6F */

		"LD   (IY{0}),B", /* FD70 */
		"LD   (IY{0}),C", /* FD71 */
		"LD   (IY{0}),D", /* FD72 */
		"LD   (IY{0}),E", /* FD73 */
		"LD   (IY{0}),H", /* FD74 */
		"LD   (IY{0}),L", /* FD75 */
		"?", /* FD76 */
		"LD   (IY{0}),A", /* FD77 */

		"?", /* FD78 */
		"?", /* FD79 */
		"?", /* FD7A */
		"?", /* FD7B */
		"LD   A,IYH", /* FD7C */
		"LD   A,IYL", /* FD7D */
		"LD   A,(IY{0})", /* FD7E */
		"?", /* FD7F */

		"?", /* FD80 */
		"?", /* FD81 */
		"?", /* FD82 */
		"?", /* FD83 */
		"ADD  A,IYH", /* FD84 */
		"ADD  A,IYL", /* FD85 */
		"ADD  A,(IY{0})", /* FD86 */
		"?", /* FD87 */

		"?", /* FD88 */
		"?", /* FD89 */
		"?", /* FD8A */
		"?", /* FD8B */
		"ADC  A,IYH", /* FD8D */
		"ADC  A,IYL", /* FD8E */
		"ADC  A,(IY{0})", /* FD8E */
		"?", /* FD8F */

		"?", /* FD90 */
		"?", /* FD91 */
		"?", /* FD92 */
		"?", /* FD93 */
		"SUB  IYH", /* FD94 */
		"SUB  IYL", /* FD95 */
		"SUB  (IY{0})", /* FD96 */
		"?", /* FD97 */

		"?", /* FD98 */
		"?", /* FD99 */
		"?", /* FD9A */
		"?", /* FD9B */
		"SBC  A,IYH", /* FD9C */
		"SBC  A,IYL", /* FD9D */
		"SBC  A,(IY{0})", /* FD9E */
		"?", /* FD9F */

		"?", /* FDA0 */
		"?", /* FDA1 */
		"?", /* FDA2 */
		"?", /* FDA3 */
		"AND  IYH", /* FDA4 */
		"AND  IYL", /* FDA5 */
		"AND  (IY{0})", /* FDA6 */
		"?", /* FDA7 */

		"?", /* FDA8 */
		"?", /* FDA9 */
		"?", /* FDAA */
		"?", /* FDAB */
		"XOR  IYH", /* FDAC */
		"XOR  IYL", /* FDAD */
		"XOR  (IY{0})", /* FDAE */
		"?", /* FDAF */

		"?", /* FDB0 */
		"?", /* FDB1 */
		"?", /* FDB2 */
		"?", /* FDB3 */
		"OR   IYH", /* FDB4 */
		"OR   IYL", /* FDB5 */
		"OR   (IY{0})", /* FDB6 */
		"?", /* FDB7 */

		"?", /* FDB8 */
		"?", /* FDB9 */
		"?", /* FDBA */
		"?", /* FDBB */
		"CP   IYH", /* FDBC */
		"CP   IYL", /* FDBD */
		"CP   (IY{0})", /* FDBE */
		"?", /* FDBF */

		"?", /* FDC0 */
		"?", /* FDC1 */
		"?", /* FDC2 */
		"?", /* FDC3 */
		"?", /* FDC4 */
		"?", /* FDC5 */
		"?", /* FDC6 */
		"?", /* FDC7 */

		"?", /* FDC8 */
		"?", /* FDC9 */
		"?", /* FDCA */
		"?", /* FDCB */
		"?", /* FDCC */
		"?", /* FDCD */
		"?", /* FDCE */
		"?", /* FDCF */

		"?", /* FDD0 */
		"?", /* FDD1 */
		"?", /* FDD2 */
		"?", /* FDD3 */
		"?", /* FDD4 */
		"?", /* FDD5 */
		"?", /* FDD6 */
		"?", /* FDD7 */

		"?", /* FDD8 */
		"?", /* FDD9 */
		"?", /* FDDA */
		"?", /* FDDB */
		"?", /* FDDC */
		"?", /* FDFD */
		"?", /* FDDE */
		"?", /* FDDF */

		"?", /* FDE0 */
		"POP  IY", /* FDE1 */
		"?", /* FDE2 */
		"EX   (SP),IY", /* FDE3 */
		"?", /* FDE4 */
		"PUSH IY", /* FDE5 */
		"?", /* FDE6 */
		"?", /* FDE7 */

		"?", /* FDE8 */
		"JP   (IY)", /* FDE9 */
		"?", /* FDEA */
		"?", /* FDEB */
		"?", /* FDEC */
		"?", /* FDED */
		"?", /* FDEE */
		"?", /* FDEF */

		"?", /* FDF0 */
		"?", /* FDF1 */
		"?", /* FDF2 */
		"?", /* FDF3 */
		"?", /* FDF4 */
		"?", /* FDF5 */
		"?", /* FDF6 */
		"?", /* FDF7 */

		"?", /* FDF8 */
		"LD   SP,IY", /* FDF9 */
		"?", /* FDFA */
		"?", /* FDFB */
		"?", /* FDFC */
		"?", /* FDFD */
		"?", /* FDFE */
		"?" /* FDFF */
	};

	private static final int fdArgsMnem[] = {
		0, /* FD00 */
		0, /* FD01 */
		0, /* FD02 */
		0, /* FD03 */
		0, /* FD04 */
		0, /* FD05 */
		0, /* FD06 */
		0, /* FD07 */

		0, /* FD08 */
		0, /* FD09 */
		0, /* FD0A */
		0, /* FD0B */
		0, /* FD0C */
		0, /* FD0D */
		0, /* FD0E */
		0, /* FD0F */

		0, /* FD10 */
		0, /* FD11 */
		0, /* FD12 */
		0, /* FD13 */
		0, /* FD14 */
		0, /* FD15 */
		0, /* FD16 */
		0, /* FD17 */

		0, /* FD18 */
		0, /* FD19 */
		0, /* FD1A */
		0, /* FD1B */
		0, /* FD1C */
		0, /* FD1D */
		0, /* FD1E */
		0, /* FD1F */

		0, /* FD20 */
		2, /* FD21 */
		2, /* FD22 */
		0, /* FD23 */
		0, /* FD24 */
		0, /* FD25 */
		1, /* FD26 */
		0, /* FD27 */

		0, /* FD28 */
		0, /* FD29 */
		2, /* FD2A */
		0, /* FD2B */
		0, /* FD24 */
		0, /* FD25 */
		1, /* FD26 */
		0, /* FD2F */

		0, /* FD30 */
		0, /* FD31 */
		0, /* FD32 */
		0, /* FD33 */
		-4, /* FD34 */
		-4, /* FD35 */
		-3, /* FD36 */
		0, /* FD37 */

		0, /* FD38 */
		0, /* FD39 */
		0, /* FD3A */
		0, /* FD3B */
		0, /* FD3C */
		0, /* FD3D */
		0, /* FD3E */
		0, /* FD3F */

		0, /* FD40 */
		0, /* FD41 */
		0, /* FD42 */
		0, /* FD43 */
		0, /* FD44 */
		0, /* FD45 */
		-4, /* FD46 */
		0, /* FD47 */

		0, /* FD48 */
		0, /* FD49 */
		0, /* FD4A */
		0, /* FD4B */
		0, /* FD4C */
		0, /* FD4D */
		-4, /* FD4E */
		0, /* FD4F */

		0, /* FD50 */
		0, /* FD51 */
		0, /* FD52 */
		0, /* FD53 */
		0, /* FD54 */
		0, /* FD55 */
		-4, /* FD56 */
		0, /* FD57 */

		0, /* FD58 */
		0, /* FD59 */
		0, /* FD5A */
		0, /* FD5B */
		0, /* FD5C */
		0, /* FD5D */
		-4, /* FD5E */
		0, /* FD5F */

		0, /* FD60 */
		0, /* FD61 */
		0, /* FD62 */
		0, /* FD63 */
		0, /* FD64 */
		0, /* FD65 */
		-4, /* FD66 */
		0, /* FD67 */

		0, /* FD68 */
		0, /* FD69 */
		0, /* FD6A */
		0, /* FD6B */
		0, /* FD6C */
		0, /* FD6D */
		-4, /* FD6E */
		0, /* FD6F */

		-4, /* FD70 */
		-4, /* FD71 */
		-4, /* FD72 */
		-4, /* FD73 */
		-4, /* FD74 */
		-4, /* FD75 */
		0, /* FD76 */
		-4, /* FD77 */

		0, /* FD78 */
		0, /* FD79 */
		0, /* FD7A */
		0, /* FD7B */
		0, /* FD7C */
		0, /* FD7D */
		-4, /* FD7E */
		0, /* FD7F */

		0, /* FD80 */
		0, /* FD81 */
		0, /* FD82 */
		0, /* FD83 */
		0, /* FD84 */
		0, /* FD85 */
		-4, /* FD86 */
		0, /* FD87 */

		0, /* FD88 */
		0, /* FD89 */
		0, /* FD8A */
		0, /* FD8B */
		0, /* FD8D */
		0, /* FD8E */
		-4, /* FD8E */
		0, /* FD8F */

		0, /* FD90 */
		0, /* FD91 */
		0, /* FD92 */
		0, /* FD93 */
		0, /* FD94 */
		0, /* FD95 */
		-4, /* FD96 */
		0, /* FD97 */

		0, /* FD98 */
		0, /* FD99 */
		0, /* FD9A */
		0, /* FD9B */
		0, /* FD9C */
		0, /* FD9D */
		-4, /* FD9E */
		0, /* FD9F */

		0, /* FDA0 */
		0, /* FDA1 */
		0, /* FDA2 */
		0, /* FDA3 */
		0, /* FDA4 */
		0, /* FDA5 */
		-4, /* FDA6 */
		0, /* FDA7 */

		0, /* FDA8 */
		0, /* FDA9 */
		0, /* FDAA */
		0, /* FDAB */
		0, /* FDAC */
		0, /* FDAD */
		-4, /* FDAE */
		0, /* FDAF */

		0, /* FDB0 */
		0, /* FDB1 */
		0, /* FDB2 */
		0, /* FDB3 */
		0, /* FDB4 */
		0, /* FDB5 */
		-4, /* FDB6 */
		0, /* FDB7 */

		0, /* FDB8 */
		0, /* FDB9 */
		0, /* FDBA */
		0, /* FDBB */
		0, /* FDBC */
		0, /* FDBD */
		-4, /* FDBE */
		0, /* FDBF */

		0, /* FDC0 */
		0, /* FDC1 */
		0, /* FDC2 */
		0, /* FDC3 */
		0, /* FDC4 */
		0, /* FDC5 */
		0, /* FDC6 */
		0, /* FDC7 */

		0, /* FDC8 */
		0, /* FDC9 */
		0, /* FDCA */
		0, /* FDCB */
		0, /* FDCC */
		0, /* FDCD */
		0, /* FDCE */
		0, /* FDCF */

		0, /* FDD0 */
		0, /* FDD1 */
		0, /* FDD2 */
		0, /* FDD3 */
		0, /* FDD4 */
		0, /* FDD5 */
		0, /* FDD6 */
		0, /* FDD7 */

		0, /* FDD8 */
		0, /* FDD9 */
		0, /* FDDA */
		0, /* FDDB */
		0, /* FDDC */
		0, /* FDFD */
		0, /* FDDE */
		0, /* FDDF */

		0, /* FDE0 */
		0, /* FDE1 */
		0, /* FDE2 */
		0, /* FDE3 */
		0, /* FDE4 */
		0, /* FDE5 */
		0, /* FDE6 */
		0, /* FDE7 */

		0, /* FDE8 */
		0, /* FDE9 */
		0, /* FDEA */
		0, /* FDEB */
		0, /* FDEC */
		0, /* FDED */
		0, /* FDEE */
		0, /* FDEF */

		0, /* FDF0 */
		0, /* FDF1 */
		0, /* FDF2 */
		0, /* FDF3 */
		0, /* FDF4 */
		0, /* FDF5 */
		0, /* FDF6 */
		0, /* FDF7 */

		0, /* FDF8 */
		0, /* FDF9 */
		0, /* FDFA */
		0, /* FDFB */
		0, /* FDFC */
		0, /* FDFD */
		0, /* FDFE */
		0 /* FDFF */
	};

	private static final String edStrMnem[] = {
		"?", /* ED00 */
		"?", /* ED01 */
		"?", /* ED02 */
		"?", /* ED03 */
		"?", /* ED04 */
		"?", /* ED05 */
		"?", /* ED06 */
		"?", /* ED07 */

		"?", /* ED08 */
		"?", /* ED09 */
		"?", /* ED0A */
		"?", /* ED0B */
		"?", /* ED0C */
		"?", /* ED0D */
		"?", /* ED0E */
		"?", /* ED0F */

		"?", /* ED10 */
		"?", /* ED11 */
		"?", /* ED12 */
		"?", /* ED13 */
		"?", /* ED14 */
		"?", /* ED15 */
		"?", /* ED16 */
		"?", /* ED17 */

		"?", /* ED18 */
		"?", /* ED19 */
		"?", /* ED1A */
		"?", /* ED1B */
		"?", /* ED1C */
		"?", /* ED1D */
		"?", /* ED1E */
		"?", /* ED1F */

		"?", /* ED20 */
		"?", /* ED21 */
		"?", /* ED22 */
		"?", /* ED23 */
		"?", /* ED24 */
		"?", /* ED25 */
		"?", /* ED26 */
		"?", /* ED27 */

		"?", /* ED28 */
		"?", /* ED29 */
		"?", /* ED2A */
		"?", /* ED2B */
		"?", /* ED2C */
		"?", /* ED2D */
		"?", /* ED2E */
		"?", /* ED2F */

		"?", /* ED30 */
		"?", /* ED31 */
		"?", /* ED32 */
		"?", /* ED33 */
		"?", /* ED34 */
		"?", /* ED35 */
		"?", /* ED36 */
		"?", /* ED37 */

		"?", /* ED38 */
		"?", /* ED39 */
		"?", /* ED3A */
		"?", /* ED3B */
		"?", /* ED3C */
		"?", /* ED3D */
		"?", /* ED3E */
		"?", /* ED3F */

		"IN   B,(C)", /* ED40 */
		"OUT  (C),B", /* ED41 */
		"SBC  HL,BC", /* ED42 */
		"LD   ({0}),BC", /* ED43 */
		"NEG", /* ED44 */
		"RETN", /* ED45 */
		"IM   0", /* ED46 */
		"LD   I,A", /* ED47 */

		"IN   C,(C)", /* ED48 */
		"OUT  (C),C", /* ED49 */
		"ADC  HL,BC", /* ED4A */
		"LD   BC,({0})", /* ED4B */
		"?", /* ED4C */
		"RETI", /* ED4D */
		"?", /* ED4E */
		"LD   R,A", /* ED4F */

		"IN   D,(C)", /* ED50 */
		"OUT  (C),D", /* ED51 */
		"SBC  HL,DE", /* ED52 */
		"LD   ({0}),DE", /* ED53 */
		"?", /* ED54 */
		"?", /* ED55 */
		"IM   1", /* ED56 */
		"LD   A,I", /* ED57 */

		"IN   E,(C)", /* ED58 */
		"OUT  (C),E", /* ED59 */
		"ADC  HL,DE", /* ED5A */
		"LD   DE,({0})", /* ED5B */
		"?", /* ED5C */
		"?", /* ED5D */
		"IM   2", /* ED5E */
		"LD   A,R", /* ED5F */

		"IN   H,(C)", /* ED60 */
		"OUT  (C),H", /* ED61 */
		"SBC  HL,HL", /* ED62 */
		"?", /* ED63 */
		"?", /* ED64 */
		"?", /* ED65 */
		"?", /* ED66 */
		"RRD", /* ED67 */

		"IN   L,(C)", /* ED68 */
		"OUT  (C),L", /* ED69 */
		"ADC  HL,HL", /* ED6A */
		"?", /* ED6B */
		"?", /* ED6C */
		"?", /* ED6D */
		"?", /* ED6E */
		"RLD", /* ED6F */

		"IN   F,(C)", /* ED70 */
		"?", /* ED71 */
		"SBC  HL,SP", /* ED72 */
		"LD   ({0}),SP", /* ED73 */
		"?", /* ED74 */
		"?", /* ED75 */
		"?", /* ED76 */
		"?", /* ED77 */

		"IN   A,(C)", /* ED78 */
		"OUT  (C),A", /* ED79 */
		"ADC  HL,SP", /* ED7A */
		"LD   SP,({0})", /* ED7B */
		"?", /* ED7C */
		"?", /* ED7D */
		"?", /* ED7E */
		"?", /* ED7F */

		"?", /* ED80 */
		"?", /* ED81 */
		"?", /* ED82 */
		"?", /* ED83 */
		"?", /* ED84 */
		"?", /* ED85 */
		"?", /* ED86 */
		"?", /* ED87 */

		"?", /* ED88 */
		"?", /* ED89 */
		"?", /* ED8A */
		"?", /* ED8B */
		"?", /* ED8C */
		"?", /* ED8D */
		"?", /* ED8E */
		"?", /* ED8F */

		"?", /* ED90 */
		"?", /* ED91 */
		"?", /* ED92 */
		"?", /* ED93 */
		"?", /* ED94 */
		"?", /* ED95 */
		"?", /* ED96 */
		"?", /* ED97 */

		"?", /* ED98 */
		"?", /* ED99 */
		"?", /* ED9A */
		"?", /* ED9B */
		"?", /* ED9C */
		"?", /* ED9D */
		"?", /* ED9E */
		"?", /* ED9F */

		"LDI", /* EDA0 */
		"CPI", /* EDA1 */
		"INI", /* EDA2 */
		"OUTI", /* EDA3 */
		"?", /* EDA4 */
		"?", /* EDA5 */
		"?", /* EDA6 */
		"?", /* EDA7 */

		"LDD", /* EDA8 */
		"CPD", /* EDA9 */
		"IND", /* EDAA */
		"OUTD", /* EDAB */
		"?", /* EDAC */
		"?", /* EDAD */
		"?", /* EDAE */
		"?", /* EDAF */

		"LDIR", /* EDB0 */
		"CPIR", /* EDB1 */
		"INIR", /* EDB2 */
		"OTIR", /* EDB3 */
		"?", /* EDB4 */
		"?", /* EDB5 */
		"?", /* EDB6 */
		"?", /* EDB7 */

		"LDDR", /* EDB8 */
		"CPDR", /* EDB9 */
		"INDR", /* EDBA */
		"OTDR", /* EDBB */
		"?", /* EDBC */
		"?", /* EDBD */
		"?", /* EDBE */
		"?", /* EDBF */

		"?", /* EDC0 */
		"?", /* EDC1 */
		"?", /* EDC2 */
		"?", /* EDC3 */
		"?", /* EDC4 */
		"?", /* EDC5 */
		"?", /* EDC6 */
		"?", /* EDC7 */

		"?", /* EDC8 */
		"?", /* EDC9 */
		"?", /* EDCA */
		"?", /* EDCB */
		"?", /* EDCC */
		"?", /* EDCD */
		"?", /* EDCE */
		"?", /* EDCF */

		"?", /* EDD0 */
		"?", /* EDD1 */
		"?", /* EDD2 */
		"?", /* EDD3 */
		"?", /* EDD4 */
		"?", /* EDD5 */
		"?", /* EDD6 */
		"?", /* EDD7 */

		"?", /* EDD8 */
		"?", /* EDD9 */
		"?", /* EDDA */
		"?", /* EDDB */
		"?", /* EDDC */
		"?", /* EDDD */
		"?", /* EDDE */
		"?", /* EDDF */

		"?", /* EDE0 */
		"?", /* EDE1 */
		"?", /* EDE2 */
		"?", /* EDE3 */
		"?", /* EDE4 */
		"?", /* EDE5 */
		"?", /* EDE6 */
		"?", /* EDE7 */

		"?", /* EDE8 */
		"?", /* EDE9 */
		"?", /* EDEA */
		"?", /* EDEB */
		"?", /* EDEC */
		"?", /* EDED */
		"?", /* EDEE */
		"?", /* EDEF */

		"?", /* EDF0 */
		"?", /* EDF1 */
		"?", /* EDF2 */
		"?", /* EDF3 */
		"?", /* EDF4 */
		"?", /* EDF5 */
		"?", /* EDF6 */
		"?", /* EDF7 */

		"?", /* EDF8 */
		"?", /* EDF9 */
		"?", /* EDFA */
		"?", /* EDFB */
		"?", /* EDFC */
		"?", /* EDFD */
		"?", /* EDFE */
		"?", /* EDFF */
	};

	private static final int edArgsMnem[] = {
		0, /* ED00 */
		0, /* ED01 */
		0, /* ED02 */
		0, /* ED03 */
		0, /* ED04 */
		0, /* ED05 */
		0, /* ED06 */
		0, /* ED07 */

		0, /* ED08 */
		0, /* ED09 */
		0, /* ED0A */
		0, /* ED0B */
		0, /* ED0C */
		0, /* ED0D */
		0, /* ED0E */
		0, /* ED0F */

		0, /* ED10 */
		0, /* ED11 */
		0, /* ED12 */
		0, /* ED13 */
		0, /* ED14 */
		0, /* ED15 */
		0, /* ED16 */
		0, /* ED17 */

		0, /* ED18 */
		0, /* ED19 */
		0, /* ED1A */
		0, /* ED1B */
		0, /* ED1C */
		0, /* ED1D */
		0, /* ED1E */
		0, /* ED1F */

		0, /* ED20 */
		0, /* ED21 */
		0, /* ED22 */
		0, /* ED23 */
		0, /* ED24 */
		0, /* ED25 */
		0, /* ED26 */
		0, /* ED27 */

		0, /* ED28 */
		0, /* ED29 */
		0, /* ED2A */
		0, /* ED2B */
		0, /* ED2C */
		0, /* ED2D */
		0, /* ED2E */
		0, /* ED2F */

		0, /* ED30 */
		0, /* ED31 */
		0, /* ED32 */
		0, /* ED33 */
		0, /* ED34 */
		0, /* ED35 */
		0, /* ED36 */
		0, /* ED37 */

		0, /* ED38 */
		0, /* ED39 */
		0, /* ED3A */
		0, /* ED3B */
		0, /* ED3C */
		0, /* ED3D */
		0, /* ED3E */
		0, /* ED3F */
		0, /* ED40 */
		0, /* ED41 */
		0, /* ED42 */
		2, /* ED43 */
		0, /* ED44 */
		0, /* ED45 */
		0, /* ED46 */
		0, /* ED47 */

		0, /* ED48 */
		0, /* ED49 */
		0, /* ED4A */
		2, /* ED4B */
		0, /* ED4C */
		0, /* ED4D */
		0, /* ED4E */
		0, /* ED4F */

		0, /* ED50 */
		0, /* ED51 */
		0, /* ED52 */
		2, /* ED53 */
		0, /* ED54 */
		0, /* ED55 */
		0, /* ED56 */
		0, /* ED57 */

		0, /* ED58 */
		0, /* ED59 */
		0, /* ED5A */
		2, /* ED5B */
		0, /* ED5C */
		0, /* ED5D */
		0, /* ED5E */
		0, /* ED5F */

		0, /* ED60 */
		0, /* ED61 */
		0, /* ED62 */
		0, /* ED63 */
		0, /* ED64 */
		0, /* ED65 */
		0, /* ED66 */
		0, /* ED67 */

		0, /* ED68 */
		0, /* ED69 */
		0, /* ED6A */
		0, /* ED6B */
		0, /* ED6C */
		0, /* ED6D */
		0, /* ED6E */
		0, /* ED6F */

		0, /* ED70 */
		0, /* ED71 */
		0, /* ED72 */
		2, /* ED73 */
		0, /* ED74 */
		0, /* ED75 */
		0, /* ED76 */
		0, /* ED77 */

		0, /* ED78 */
		0, /* ED79 */
		0, /* ED7A */
		2, /* ED7B */
		0, /* ED7C */
		0, /* ED7D */
		0, /* ED7E */
		0, /* ED7F */

		0, /* ED80 */
		0, /* ED81 */
		0, /* ED82 */
		0, /* ED83 */
		0, /* ED84 */
		0, /* ED85 */
		0, /* ED86 */
		0, /* ED87 */

		0, /* ED88 */
		0, /* ED89 */
		0, /* ED8A */
		0, /* ED8B */
		0, /* ED8C */
		0, /* ED8D */
		0, /* ED8E */
		0, /* ED8F */

		0, /* ED90 */
		0, /* ED91 */
		0, /* ED92 */
		0, /* ED93 */
		0, /* ED94 */
		0, /* ED95 */
		0, /* ED96 */
		0, /* ED97 */

		0, /* ED98 */
		0, /* ED99 */
		0, /* ED9A */
		0, /* ED9B */
		0, /* ED9C */
		0, /* ED9D */
		0, /* ED9E */
		0, /* ED9F */

		0, /* EDA0 */
		0, /* EDA1 */
		0, /* EDA2 */
		0, /* EDA3 */
		0, /* EDA4 */
		0, /* EDA5 */
		0, /* EDA6 */
		0, /* EDA7 */

		0, /* EDA8 */
		0, /* EDA9 */
		0, /* EDAA */
		0, /* EDAB */
		0, /* EDAC */
		0, /* EDAD */
		0, /* EDAE */
		0, /* EDAF */

		0, /* EDB0 */
		0, /* EDB1 */
		0, /* EDB2 */
		0, /* EDB3 */
		0, /* EDB4 */
		0, /* EDB5 */
		0, /* EDB6 */
		0, /* EDB7 */

		0, /* EDB8 */
		0, /* EDB9 */
		0, /* EDBA */
		0, /* EDBB */
		0, /* EDBC */
		0, /* EDBD */
		0, /* EDBE */
		0, /* EDBF */

		0, /* EDC0 */
		0, /* EDC1 */
		0, /* EDC2 */
		0, /* EDC3 */
		0, /* EDC4 */
		0, /* EDC5 */
		0, /* EDC6 */
		0, /* EDC7 */

		0, /* EDC8 */
		0, /* EDC9 */
		0, /* EDCA */
		0, /* EDCB */
		0, /* EDCC */
		0, /* EDCD */
		0, /* EDCE */
		0, /* EDCF */

		0, /* EDD0 */
		0, /* EDD1 */
		0, /* EDD2 */
		0, /* EDD3 */
		0, /* EDD4 */
		0, /* EDD5 */
		0, /* EDD6 */
		0, /* EDD7 */

		0, /* EDD8 */
		0, /* EDD9 */
		0, /* EDDA */
		0, /* EDDB */
		0, /* EDDC */
		0, /* EDDD */
		0, /* EDDE */
		0, /* EDDF */

		0, /* EDE0 */
		0, /* EDE1 */
		0, /* EDE2 */
		0, /* EDE3 */
		0, /* EDE4 */
		0, /* EDE5 */
		0, /* EDE6 */
		0, /* EDE7 */

		0, /* EDE8 */
		0, /* EDE9 */
		0, /* EDEA */
		0, /* EDEB */
		0, /* EDEC */
		0, /* EDED */
		0, /* EDEE */
		0, /* EDEF */

		0, /* EDF0 */
		0, /* EDF1 */
		0, /* EDF2 */
		0, /* EDF3 */
		0, /* EDF4 */
		0, /* EDF5 */
		0, /* EDF6 */
		0, /* EDF7 */

		0, /* EDF8 */
		0, /* EDF9 */
		0, /* EDFA */
		0, /* EDFB */
		0, /* EDFC */
		0, /* EDFD */
		0, /* EDFE */
		0, /* EDFF */
	};

	private static final String ozdcStrMnem[] = {
		"CALL_OZ(DC_INI)", /* E7 060C */
		"CALL_OZ(DC_BYE)", /* E7 080C */
		"CALL_OZ(DC_ENT)", /* E7 0A0C */
		"CALL_OZ(DC_NAM)", /* E7 0C0C */
		"CALL_OZ(DC_IN)", /* E7 0E0C */
		"CALL_OZ(DC_OUT)", /* E7 100C */
		"CALL_OZ(DC_PRT)", /* E7 120C */
		"CALL_OZ(DC_ICL)", /* E7 140C */
		"CALL_OZ(DC_NQ)", /* E7 160C */
		"CALL_OZ(DC_SP)", /* E7 180C */
		"CALL_OZ(DC_ALT)", /* E7 1A0C */
		"CALL_OZ(DC_RBD)", /* E7 1C0C */
		"CALL_OZ(DC_XIN)", /* E7 1E0C */
		"CALL_OZ(DC_GEN)", /* E7 200C */
		"CALL_OZ(DC_POL)", /* E7 220C */
		"CALL_OZ(DC_SCN)", /* E7 240C */
		"CALL_OZ(UNKNOWN)" };

	private static final String ozos1StrMnem[] = {
		"CALL_OZ(OS_BYE)", /* E7 21 */
		"CALL_OZ(OS_PRT)", /* E7 24 */
		"CALL_OZ(OS_OUT)", /* E7 27 */
		"CALL_OZ(OS_IN)", /* E7 2A */
		"CALL_OZ(OS_TIN)", /* E7 2D */
		"CALL_OZ(OS_XIN)", /* E7 30 */
		"CALL_OZ(OS_PUR)", /* E7 33 */
		"CALL_OZ(OS_UGB)", /* E7 36 */
		"CALL_OZ(OS_GB)", /* E7 39 */
		"CALL_OZ(OS_PB)", /* E7 3C */
		"CALL_OZ(OS_GBT)", /* E7 3F */
		"CALL_OZ(OS_PBT)", /* E7 42 */
		"CALL_OZ(OS_MV)", /* E7 45 */
		"CALL_OZ(OS_FRM)", /* E7 48 */
		"CALL_OZ(OS_FWM)", /* E7 4B */
		"CALL_OZ(OS_MOP)", /* E7 4E */
		"CALL_OZ(OS_MCL)", /* E7 51 */
		"CALL_OZ(OS_MAL)", /* E7 54 */
		"CALL_OZ(OS_MFR)", /* E7 57 */
		"CALL_OZ(OS_MGB)", /* E7 5A */
		"CALL_OZ(OS_MPB)", /* E7 5D */
		"CALL_OZ(OS_BIX)", /* E7 60 */
		"CALL_OZ(OS_BOX)", /* E7 63 */
		"CALL_OZ(OS_NQ)", /* E7 66 */
		"CALL_OZ(OS_SP)", /* E7 69 */
		"CALL_OZ(OS_SR)", /* E7 6C */
		"CALL_OZ(OS_ESC)", /* E7 6F */
		"CALL_OZ(OS_ERC)", /* E7 72 */
		"CALL_OZ(OS_ERH)", /* E7 75 */
		"CALL_OZ(OS_UST)", /* E7 78 */
		"CALL_OZ(OS_FN)", /* E7 7B */
		"CALL_OZ(OS_WAIT)", /* E7 7E */
		"CALL_OZ(OS_ALM)", /* E7 81 */
		"CALL_OZ(OS_CLI)", /* E7 84 */
		"CALL_OZ(OS_DOR)", /* E7 87 */
		"CALL_OZ(OS_FC)", /* E7 8A */
		"CALL_OZ(OS_SI)", /* E7 8D */
		"CALL_OZ(UNKNOWN)" };

	private static final String ozos2StrMnem[] = {
		"CALL_OZ(OS_WTB)", /* E7 CA06 */
		"CALL_OZ(OS_WRT)", /* E7 CC06 */
		"CALL_OZ(OS_WSQ)", /* E7 CE06 */
		"CALL_OZ(OS_ISQ)", /* E7 D006 */
		"CALL_OZ(OS_AXP)", /* E7 D206 */
		"CALL_OZ(OS_SCI)", /* E7 D406 */
		"CALL_OZ(OS_DLY)", /* E7 D606 */
		"CALL_OZ(OS_BLP)", /* E7 D806 */
		"CALL_OZ(OS_BDE)", /* E7 DA06 */
		"CALL_OZ(OS_BHL)", /* E7 DC06 */
		"CALL_OZ(OS_FTH)", /* E7 DE06 */
		"CALL_OZ(OS_VTH)", /* E7 E006 */
		"CALL_OZ(OS_GTH)", /* E7 E206 */
		"CALL_OZ(OS_REN)", /* E7 E406 */
		"CALL_OZ(OS_DEL)", /* E7 E606 */
		"CALL_OZ(OS_CL)", /* E7 E806 */
		"CALL_OZ(OS_OP)", /* E7 EA06 */
		"CALL_OZ(OS_OFF)", /* E7 EC06 */
		"CALL_OZ(OS_USE)", /* E7 EE06 */
		"CALL_OZ(OS_EPR)", /* E7 F006 */
		"CALL_OZ(OS_HT)", /* E7 F206 */
		"CALL_OZ(OS_MAP)", /* E7 F406 */
		"CALL_OZ(OS_EXIT)", /* E7 F606 */
		"CALL_OZ(OS_STK)", /* E7 F806 */
		"CALL_OZ(OS_ENT)", /* E7 FA06 */
		"CALL_OZ(OS_POLL)", /* E7 FC06 */
		"CALL_OZ(OS_DOM)", /* E7 FE06 */
		"CALL_OZ(UNKNOWN)" };

	private static final String ozgnStrMnem[] = {
		"CALL_OZ(GN_GDT)", /* E7 0609 */
		"CALL_OZ(GN_PDT)", /* E7 0809 */
		"CALL_OZ(GN_GTM)", /* E7 0A09 */
		"CALL_OZ(GN_PTM)", /* E7 0C09 */
		"CALL_OZ(GN_SDO)", /* E7 0E09 */
		"CALL_OZ(GN_GDN)", /* E7 1009 */
		"CALL_OZ(GN_PDN)", /* E7 1209 */
		"CALL_OZ(GN_DIE)", /* E7 1409 */
		"CALL_OZ(GN_DEI)", /* E7 1609 */
		"CALL_OZ(GN_GMD)", /* E7 1809 */
		"CALL_OZ(GN_GMT)", /* E7 1A09 */
		"CALL_OZ(GN_PMD)", /* E7 1C09 */
		"CALL_OZ(GN_PMT)", /* E7 1E09 */
		"CALL_OZ(GN_MSC)", /* E7 2009 */
		"CALL_OZ(GN_FLO)", /* E7 2209 */
		"CALL_OZ(GN_FLC)", /* E7 2409 */
		"CALL_OZ(GN_FLW)", /* E7 2609 */
		"CALL_OZ(GN_FLR)", /* E7 2809 */
		"CALL_OZ(GN_FLF)", /* E7 2A09 */
		"CALL_OZ(GN_FPB)", /* E7 2C09 */
		"CALL_OZ(GN_NLN)", /* E7 2E09 */
		"CALL_OZ(GN_CLS)", /* E7 3009 */
		"CALL_OZ(GN_SKC)", /* E7 3209 */
		"CALL_OZ(GN_SKD)", /* E7 3409 */
		"CALL_OZ(GN_SKT)", /* E7 3609 */
		"CALL_OZ(GN_SIP)", /* E7 3809 */
		"CALL_OZ(GN_SOP)", /* E7 3A09 */
		"CALL_OZ(GN_SOE)", /* E7 3C09 */
		"CALL_OZ(GN_RBE)", /* E7 3E09 */
		"CALL_OZ(GN_WBE)", /* E7 4009 */
		"CALL_OZ(GN_CME)", /* E7 4209 */
		"CALL_OZ(GN_XNX)", /* E7 4409 */
		"CALL_OZ(GN_XIN)", /* E7 4609 */
		"CALL_OZ(GN_XDL)", /* E7 4809 */
		"CALL_OZ(GN_ERR)", /* E7 4A09 */
		"CALL_OZ(GN_ESP)", /* E7 4C09 */
		"CALL_OZ(GN_FCM)", /* E7 4E09 */
		"CALL_OZ(GN_FEX)", /* E7 5009 */
		"CALL_OZ(GN_OPW)", /* E7 5209 */
		"CALL_OZ(GN_WCL)", /* E7 5409 */
		"CALL_OZ(GN_WFN)", /* E7 5609 */
		"CALL_OZ(GN_PRS)", /* E7 5809 */
		"CALL_OZ(GN_PFS)", /* E7 5A09 */
		"CALL_OZ(GN_WSM)", /* E7 5C09 */
		"CALL_OZ(GN_ESA)", /* E7 5E09 */
		"CALL_OZ(GN_OPF)", /* E7 6009 */
		"CALL_OZ(GN_CL)", /* E7 6209 */
		"CALL_OZ(GN_DEL)", /* E7 6409 */
		"CALL_OZ(GN_REN)", /* E7 6609 */
		"CALL_OZ(GN_AAB)", /* E7 6809 */
		"CALL_OZ(GN_FAB)", /* E7 6A09 */
		"CALL_OZ(GN_LAB)", /* E7 6C09 */
		"CALL_OZ(GN_UAB)", /* E7 6E09 */
		"CALL_OZ(GN_ALP)", /* E7 7009 */
		"CALL_OZ(GN_M16)", /* E7 7209 */
		"CALL_OZ(GN_D16)", /* E7 7409 */
		"CALL_OZ(GN_M24)", /* E7 7609 */
		"CALL_OZ(GN_D24)", /* E7 7809 */
		"CALL_OZ(UNKNOWN)", };

	private static final String ozfppStrMnem[] = {
		"FPP(FP_AND)", /* DF 21 */
		"FPP(FP_IDV)", /* DF 24 */
		"FPP(FP_EOR)", /* DF 27 */
		"FPP(FP_MOD)", /* DF 2A */
		"FPP(FP_OR)", /* DF 2D */
		"FPP(FP_LEQ)", /* DF 30 */
		"FPP(FP_NEQ)", /* DF 33 */
		"FPP(FP_GEQ)", /* DF 36 */
		"FPP(FP_LT)", /* DF 39 */
		"FPP(FP_EQ)", /* DF 3C */
		"FPP(FP_MUL)", /* DF 3F */
		"FPP(FP_ADD)", /* DF 42 */
		"FPP(FP_GT)", /* DF 45 */
		"FPP(FP_SUB)", /* DF 48 */
		"FPP(FP_PWR)", /* DF 4B */
		"FPP(FP_DIV)", /* DF 4E */
		"FPP(FP_ABS)", /* DF 51 */
		"FPP(FP_ACS)", /* DF 54 */
		"FPP(FP_ASN)", /* DF 57 */
		"FPP(FP_ATN)", /* DF 5A */
		"FPP(FP_COS)", /* DF 5D */
		"FPP(FP_DEG)", /* DF 60 */
		"FPP(FP_EXP)", /* DF 63 */
		"FPP(FP_INT)", /* DF 66 */
		"FPP(FP_LN)", /* DF 69 */
		"FPP(FP_LOG)", /* DF 6C */
		"FPP(FP_NOT)", /* DF 6F */
		"FPP(FP_RAD)", /* DF 72 */
		"FPP(FP_SGN)", /* DF 75 */
		"FPP(FP_SIN)", /* DF 78 */
		"FPP(FP_SQR)", /* DF 7B */
		"FPP(FP_TAN)", /* DF 7E */
		"FPP(FP_ZER)", /* DF 81 */
		"FPP(FP_ONE)", /* DF 84 */
		"FPP(FP_TRU)", /* DF 87 */
		"FPP(FP_PI)", /* DF 8A */
		"FPP(FP_VAL)", /* DF 8D */
		"FPP(FP_STR)", /* DF 90 */
		"FPP(FP_FIX)", /* DF 93 */
		"FPP(FP_FLT)", /* DF 96 */
		"FPP(FP_TST)", /* DF 99 */
		"FPP(FP_CMP)", /* DF 9C */
		"FPP(FP_NEG)", /* DF 9F */
		"FPP(FP_BAS)", /* DF A2 */
		"FPP(UNKNOWN)" };

	private final Z80 z80vm;

	private final String byteToHex(int b) {
		StringBuffer hexString = new StringBuffer(3);
		
		hexString.append(hexcodes[b/16]).append(hexcodes[b%16]).append('h');
		return hexString.toString();		
	}
	
	private final String addrToHex(int addr) {
		int msb = addr/256, lsb = addr%256;
		StringBuffer hexString = new StringBuffer(5);
		
		hexString.append(hexcodes[msb/16]).append(hexcodes[msb%16]);
		hexString.append(hexcodes[lsb/16]).append(hexcodes[lsb%16]).append('h');
		return hexString.toString();
	}
	
	public Dz(Z80 vm) {
		z80vm = vm;
	}

	/**
	 * Disassemble Z80 instruction at address pc. The Ascii string
	 * is generated into the opcode argument, which the caller
	 * can display appropriately.
	 * The address of the next instruction is returned, when 
	 * disassembly has completed. You can therefore use this method
	 * in a loop and perform continous disassembly.
	 * 
	 * @param opcode (StringBuffer, the container for the Ascii disassembly)
	 * @param pc (int, the current address (Program Counter of Z80 instruction)
	 * @param dispaddr (boolean, - display Hex address as part of disassembly)
	 * @return int (address of following instruction)
	 */
	public final int getInstrAscii(StringBuffer opcode, int pc, boolean dispaddr) {
		int i, addr;
		byte relidx;
		String strMnem[] = null;
		int argsMnem[] = null;

		opcode.setLength(1);
		opcode.setLength(32);	// StringBuffer cleaned.
		
		addr = pc;

		i = z80vm.readByte(pc++);
		switch (i) {
			case 203 : /* CB opcode strMnem */
				strMnem = cbStrMnem;
				i = z80vm.readByte(pc++);
				break;

			case 237 : /* ED opcode strMnem */
				strMnem = edStrMnem;
				argsMnem = edArgsMnem;
				i = z80vm.readByte(pc++);
				break;

			case 221 : /* DD CB opcode strMnem */
				i = z80vm.readByte(pc++);
				if (i == 203) {
					strMnem = ddcbStrMnem;
					argsMnem = ddcbArgsMnem;
					i = z80vm.readByte(pc + 2);
					pc++;
				} else {
					strMnem = ddStrMnem;
					argsMnem = ddArgsMnem;
					i = z80vm.readByte(pc++);
				}
				break;

			case 253 : /* FD CB opcode strMnem */
				i = z80vm.readByte(pc);
				if (i == 203) {
					strMnem = fdcbStrMnem;
					argsMnem = fdcbArgsMnem;
					i = z80vm.readByte(pc + 2);
					pc++;
				} else {
					strMnem = fdStrMnem;
					argsMnem = fdArgsMnem;
					i = z80vm.readByte(pc++);
				}
				break;

			case 223 : /* RST 18h, FPP interface */
				i = z80vm.readByte(pc++);
				strMnem = ozfppStrMnem;
				if ((i % 3 == 0) && (i >= 0x21 && i <= 0xa2))
					i = (i / 3) - 11;
				else
					i = strMnem.length - 1; /* unknown parameter */
				break;

			case 231 : /* RST 20h, main OS interface */
				i = z80vm.readByte(pc++);
				switch (i) {
					case 6 : /* OS 2 byte low level calls */
						strMnem = ozos2StrMnem;
						i = z80vm.readByte(pc++);
						if ((i % 2 == 0) && (i >= 0xca && i <= 0xfe))
							i = (i / 2) - 101;
						else
							i = strMnem.length - 1; /* unknown parameter */
						break;

					case 9 : /* GN 2 byte general calls */
						strMnem = ozgnStrMnem;
						i = z80vm.readByte(pc++);
						if ((i % 2 == 0) && (i >= 0x06 && i <= 0x78))
							i = (i / 2) - 3;
						else
							i = strMnem.length - 1; /* unknown parameter */
						break;

					case 12 : /* DC 2 byte low level calls */
						strMnem = ozdcStrMnem;
						i = z80vm.readByte(pc++);
						if ((i % 2 == 0) && (i >= 0x06 && i <= 0x24))
							i = (i / 2) - 3;
						else
							i = strMnem.length - 1; /* unknown parameter */
						break;

					default : /* OS 1 byte low level calls */
						strMnem = ozos1StrMnem;
						if ((i % 3 == 0) && (i >= 0x21 && i <= 0x8d))
							i = (i / 3) - 11;
						else
							i = strMnem.length - 1; /* unknown parameter */
				}
				break;

			default : /* standard Z80 (Intel 8080 compatible) opcodes */
				strMnem = mainStrMnem;
				argsMnem = mainArgsMnem;
		}

		if (dispaddr == true) {
			opcode.append(addrToHex(addr)).append(' ');
		}
		
		if (argsMnem != null) {
			opcode.append(strMnem[i]);	// the instruction opcode string with replace macro
			int replaceMacro = opcode.indexOf("{0}");
			
			switch (argsMnem[i]) {
				case 2 :
					addr = z80vm.readByte(pc);
					addr += 256 * z80vm.readByte(pc + 1);
										
					opcode.replace(replaceMacro, replaceMacro+3, addrToHex(addr));
					pc += 2; /* move past opcode */
					break;

				case 1 :
					opcode.replace(replaceMacro, replaceMacro+3, byteToHex(z80vm.readByte(pc)));
					pc++; /* move past opcode */
					break;

				case 0 :
					/* no replace macro, ie. no arguments for instruction */
					break;

				case -1 : /* relative jump addressing (+/- 128 byte range) */
					byte reljmp = (byte) z80vm.readByte(pc);
					int reladdr = (pc + 1 + reljmp) & 0xFFFF;
					opcode.replace(replaceMacro, replaceMacro+3, addrToHex(reladdr));

					pc++; /* move past opcode */
					break;

				case -2 : /* ix/iy bit manipulation */
					relidx = (byte) z80vm.readByte(pc);
					if (relidx >= 0)
						opcode.replace(replaceMacro, replaceMacro+3, "+" + Integer.toString(relidx));
					else
						opcode.replace(replaceMacro, replaceMacro+3, Integer.toString(relidx));

					pc += 2; /* move past opcode */
					break;

				case -3 : /* LD (IX/IY+r),n */
					int replaceOperand = opcode.indexOf("{1}");
					relidx = (byte) z80vm.readByte(pc++);

					if (relidx >= 0)
						opcode.replace(replaceMacro, replaceMacro+3, "+" + Integer.toString(relidx));
					else
						opcode.replace(replaceMacro, replaceMacro+3, Integer.toString(relidx));
						
					opcode.replace(replaceOperand, replaceOperand+3, Integer.toHexString(z80vm.readByte(pc++)));
					break;

				case -4 :
					/* IX/IY offset, positive/negative constant presentation */
					relidx = (byte) z80vm.readByte(pc++);

					if (relidx >= 0)
						opcode.replace(replaceMacro, replaceMacro+3, "+" + Integer.toString(relidx));
					else
						opcode.replace(replaceMacro, replaceMacro+3, Integer.toString(relidx));

					break;
			}
		}

		return pc; // return the location of the next instruction
	}
}
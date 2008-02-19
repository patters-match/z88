
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
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include "dzasm.h"
#include "avltree.h"
#include "table.h"

/* External variables */
extern char		    	_prog_name[], _vers[];
extern char	    		cmdline[], *lineptr;
extern char 			ident[];
extern enum symbols 	sym;
extern enum symbols		ssym[];
extern enum truefalse	exit_program;
extern enum truefalse	collectfile_changed, collectfile_available;
extern char			    separators[];
extern FILE			    *infile;
extern DZarea			*gAreas;
extern long			    Org, Codesize, gEndOfCode;
extern avltree			*gLabelRef;			/* Binary tree of program labels and data references */
extern avltree			*gRemarks;			/* Binary tree of comments for output file */
extern avltree			*gExpressions;			/* Binary tree of operand expression for Z80 mnemonics */
extern avltree			*gGlobalConstants;		/* Binary tree of globally replaceable constant names */
extern IncludeFile		*gIncludeFilenames;
extern struct PrsAddrStack	*gParseAddress;			/* stack of addresses to be disassembled */

int		CmpConstant(GlobalConstant *key, GlobalConstant *node);
int		CmpConstant2(long *key, GlobalConstant *node);
int		CmpCommentRef(Remark *key, Remark *node);
int		CmpCommentRef2(long *key, Remark *node);
int		CmpExprAddr(Expression *key, Expression *node);
int		CmpExprAddr2(long *key, Expression *node);
int		CmpAddrRef2(long *key, LabelRef *node);
DZarea		*InsertArea(struct area **arealist, long	 startrange, long  endrange, enum atype	 t);
int		    SearchCmd(void);
long		GetConstant(void);
long		Disassemble(char *str, long pc, enum truefalse  dispaddr);
void		DisplayMemory(long pc);
void		DZpass1(void);
void		StoreAddrRef(long  label);
void		PushItem(long addr, struct PrsAddrStack **stackpointer);
void		DisplayMnemonic(FILE *out, long addr, char *mnemonic);
void		GetCmdline(void);
void		StoreDataRef(long  label);
void		ClearDataStructs();
void		SampleDZ(void);
void		SampleMemory(void);
void		help();
void		GenCollectFile(void);
void		ReadCollectFile(void);
void		ReloadCollectFile(void);
void		DZpass2(void);
void		DispAllAreas(void);
void		DispAreas(FILE *out, DZarea *arealist, enum truefalse resolved);
void		DispVoidAreas(FILE *out, DZarea *arealist);
void		DispUnknownAreas(void);
void		ParseDZ(void);
void		ParseLookupTable(void);
void		ParsePointerTable(void);
void		ParseVectorTable(void);
void		FindCode(void);
void		DefineMemory(void);
void		DefProgArea(void);
void		DefMemAddrArea(void);
void		DefMemStrArea(void);
void		DefineLabel(void);
void		CreateLabel(long addr, char	*label);
void		DefStorageArea(void);
void		ClearDataStructs(void);
void		DefMemProgArea(void);
void		DefineScope(void);
void		RemarkOutput(void);
void		DefineExpression(void);
void		AddExpression(long expraddr, char *exprstr);
void		AddGlobalConstant(long constant, char *conststr);
void		DefineIncludeFile(void);
void		GenCollectFile(void);
void		DefMemByteArea(void);
void		DefineConstant(void);
void 		ParseMth(void);
void		ParseRomDor(void);
void		ParseFrontDor(void);
void		ParseApplDOR(long address);
void 		quit(void);
enum truefalse   isNullPointer(long address);
int         getPointer(long address);
int         getPointerOffset(long address);
unsigned char	*DecodeAddress(long pc, unsigned char *segm, unsigned short *offset);
unsigned char	GetByte(long pc);
IncludeFile	*AllocIncludeFile(void);
IncludeFile	*AddIncludeFile(char *inclflnm);
Remark		*AllocRemark(void);
Remark		*AddRemark(long Address, char pos, char *commentstr);
Commentline	*AllocCommentline(void);
Commentline	*AddCommentline(Remark *entity, char *commentstr);
Expression	*AllocMnemExpr(void);
GlobalConstant	*AllocGlobalConstant(void);
char		*AllocLabelname(char *name);
float		ResolvedAreas(void);
enum symbols	cmdlGetSym(void);
enum truefalse	CmpString(long saddr, unsigned char  *sptr, unsigned char  l);


struct dzcmd dzcommands[] = {
 {"aa", DispAllAreas},
 {"av", DispUnknownAreas},
 {"ca", DZpass2},
 {"cc", GenCollectFile},
 {"dc", DefineConstant},
 {"de", DefineExpression},
 {"di", DefineIncludeFile},
 {"dl", DefineLabel},
 {"dm", DefineMemory},
 {"dx", DefineScope},
 {"dz", SampleDZ},
 {"h", help},
 {"help", help},
 {"mf", FindCode},
 {"mth", ParseMth},
 {"mv", SampleMemory},
 {"pl", ParseLookupTable},
 {"pp", ParseDZ},
 {"ppt", ParsePointerTable},
 {"pv", ParseVectorTable},
 {"q", quit},
 {"rc", ReloadCollectFile},
 {"rem", RemarkOutput}
};

size_t totaldzcmds = 23;


void 	quit(void)
{
	if (collectfile_available == true && collectfile_changed == true) {
		printf("Collect information has been changed.\nUpdate Collect file? [ENTER = Yes, N = No]> ");
		GetCmdline();
		if (*lineptr != 'N' && *lineptr != 'n') GenCollectFile();
	}

	ClearDataStructs();
	exit_program = true;
}


void	help(void)
{
	printf("%s, V%s\n\n", _prog_name, _vers);
	puts("aa\t\t\tDisplay information about all areas.");
	puts("av\t\t\tDisplay information about unknown areas.");
	puts("dz adr\t\t\tView disassembly at address <adr>.");
	puts("\t\t\tDuring disassembly, type <adr> for different address.");
	puts("dc adr name\t\tDefine global constant names to replace matching data");
	puts("\t\t\toperands in instructions.");
	puts("de adr \"expr\"\t\tDefine expression mnemonic at operand address");
	puts("di \"filename\"\t\tDefine explicit include file.");
	puts("dl adr name\t\tDefine label for address with name.");
	puts("dx scope adr\t\tDefine scope for address/constant.");
	puts("\t\t\tScope types are: xref (external) or xdef (global).");
	puts("dm type ad1 ad2\t\tDefine memory type areas [ad1;ad2].");
	puts("\t\t\tTypes are: prog, defw, defb, defm, defs.");
	puts("mv adr\t\t\tView memory dump at address <adr>.");
	puts("\t\t\tDuring viewing, type <ENTER> for next 128 bytes,");
	puts("\t\t\t+-offset for displaying new relative location, or just");
	puts("\t\t\tadr for new absolute address of memory dump.");
	puts("mf adr $hex\t\tFind hex sequense from <adr> onwards.");
	puts("\t\t\tFor each found match, mv command is called.");
	puts("\t\t\tType 'q' to abort mv/mf or 'n' to view next match.");
	puts("cc\t\t\tCreate 'collect' file in current directory.");
	puts("rc\t\t\tReload 'collect' file from current directory.");
	puts("\t\t\t(current collected information is deleted)");
	puts("rem adr < >\t\tAdd comment at disassembly address boundary,");
	puts("\t\t\teither printed before mnemonics line using '<'");
	puts("\t\t\tor trailed after mnemonics on same line using '>'.");
	puts("pp adr\t\t\tParse program from <adr> and forward.");
	puts("pl adr1 adr2\t\tParse subroutines via lookup table [adr1;adr2].");
	puts("pv adr\t\t\tParse JP instruction vector table at <adr> and forward.");
	puts("mth type addr\tParse Application, Menu, Topic, Help data structures.");
  puts("\t\t\tTypes are: romhdr,frontdor,appldor,hlpdor,mth");
	puts("\t\t\tMTH structures are automaticaly parsed through Appl DOR.");
	puts("ca\t\t\tCreate assembler source file in current directory.");
	puts("q\t\t\tQuit current sub command or DZasm.");
}


/* read 24bit pointer at address */
int   getPointer(long address)
{
    unsigned char b0,b1,b2;
    
    b0 = GetByte(address);
    b1 = GetByte(address+1);
    b2 = GetByte(address+2);
    
	return b0 + b1 * 256 + b2 * 65536;
}

/* read 16bit pointer offset at address and adjust with ORG */
int   getPointerOffset(long address)
{
    int p = getPointer(address);
    
    p &= 0x3FFF;            /* preserve only the 14bit offset of the DOR pointer */
	p |= (Org & 0xC000);    /* and mask the segment of the ORG segment */

	return p;
}


/* return pointer to null-terminated application name in DOR */
char *getApplDorName(long dorAddress)
{
    long            nextsection;
	unsigned char	segm;
	unsigned short 	offset;
    
    if (GetByte(dorAddress+9) != 0x83 && GetByte(dorAddress+11) != '@') 
        return NULL;    /* Application DOR wasn't recognized */

    nextsection = dorAddress + 13 + GetByte(dorAddress+12); /* skip Info section, and go to Help section */
    nextsection = nextsection + 2 + GetByte(nextsection+1); /* skip Help section, and go to Name section */

	return (char *) DecodeAddress(nextsection+2, &segm, &offset); /* 3rd byte in Name section is first char of appl name */
}


/* is 24bit pointer at address = 0? */
enum truefalse   isNullPointer(long address)
{
    int b;
    
	for (b=(int) address; b<(address+3); b++) {
	    if (GetByte(b) != 0) {
	        return false;
	    }
	}
	
	return true;
}


void 	ParseMth(void)
{
	if (cmdlGetSym() != name) {
 		puts("MTH type wasn't specified.");
 		return;
	}
	
	if (strcmp(ident, "romhdr") == 0)
		ParseRomDor();
	if (strcmp(ident, "frontdor") == 0)
		ParseFrontDor();
}


void	ParseApplDOR(long dorAddress)
{
    long helpSection, endAddress;
    int applEntry, nextApplDor, mthTopics, mthCommands, mthHelp, mthTokens;
    char applLabelName[32];
    LabelRef *lr;
        
	if (Codesize != 16384) {
 		puts("OZ static structures can only be parsed in 16K bank files.");
 		return;
	}
	
	if (GetByte(gEndOfCode-1) != 'O' && GetByte(gEndOfCode) != 'Z') {
 		puts("ROM Header not found at top of bank.");
 		return;		
	}
	
    printf("Parsing %s application DOR\n", getApplDorName(dorAddress));
    
    if (GetByte(dorAddress+9) != 0x83 && GetByte(dorAddress+11) != '@') {
        puts("Application DOR was not recognized.");
        return;
    }

    /* get pointer to next application DOR in list */
    if (isNullPointer(dorAddress+3) == false) {
        nextApplDor = getPointerOffset(dorAddress+3);

        strcpy(applLabelName, "applDor_");
        strcat(applLabelName, getApplDorName(nextApplDor));    
        CreateLabel(nextApplDor,applLabelName);
	}
	
	applEntry = GetByte(dorAddress + 13 + 10) + 256 * GetByte(dorAddress + 13 + 10 + 1);
    strcpy(applLabelName, getApplDorName(dorAddress));    	
    strcat(applLabelName, "_entry");            
    CreateLabel(applEntry, applLabelName);
	
	helpSection = dorAddress + 13 + GetByte(dorAddress+12); /* point at start of Help section */
	helpSection += 2; /* point at pointer to MTH Topics */

    strcpy(applLabelName, getApplDorName(dorAddress));    	
	mthTopics = getPointerOffset(helpSection);    
    if (isNullPointer(mthTopics) == false) {
        /* topics pointer points at real MTH */
   	    lr = find(gLabelRef, &mthTopics, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_topics");            
            CreateLabel(mthTopics,applLabelName);
        }
   	} else {
   	    /* Topics pointer contains 0 - no MTH topics defined for application */
   	    lr = find(gLabelRef, &mthTopics, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_no_topics");            
            CreateLabel(mthTopics,applLabelName);
        }   	    
   	}
    helpSection += 3;

    strcpy(applLabelName, getApplDorName(dorAddress));    
	mthCommands = getPointerOffset(helpSection);
    if (isNullPointer(mthCommands) == false) {
        /* Commands pointer points at real MTH */
   	    lr = find(gLabelRef, &mthCommands, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_commands");            
            CreateLabel(mthCommands,applLabelName);
        }
   	} else {
   	    /* Commands pointer contains 0 - no MTH commands defined for application */
   	    lr = find(gLabelRef, &mthCommands, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_no_commands");            
            CreateLabel(mthCommands,applLabelName);
        }   	    
   	}
    helpSection += 3;

    strcpy(applLabelName, getApplDorName(dorAddress));    
	mthHelp = getPointerOffset(helpSection);
    if (isNullPointer(mthHelp) == false) {
        /* Help pointer points at real MTH */
   	    lr = find(gLabelRef, &mthHelp, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_help");            
            CreateLabel(mthHelp,applLabelName);
        }
   	} else {
   	    /* Help pointer contains 0 - no MTH Help defined for application */
   	    lr = find(gLabelRef, &mthHelp, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_no_help");            
            CreateLabel(mthHelp,applLabelName);
        }   	    
   	}
    helpSection += 3;
	
    strcpy(applLabelName, getApplDorName(dorAddress));    
	mthTokens = getPointerOffset(helpSection);
    if (isNullPointer(mthTokens) == false) {
        /* Tokens pointer points at real MTH */
   	    lr = find(gLabelRef, &mthTokens, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_tokens");            
            CreateLabel(mthTokens,applLabelName);
        }
   	} else {
   	    /* Tokens pointer contains 0 - no Tokens defined for application */
   	    lr = find(gLabelRef, &mthTokens, (int (*)()) CmpAddrRef2);
   	    if (lr == NULL) {
            strcat(applLabelName, "_no_tokens");            
            CreateLabel(mthTokens,applLabelName);
        }   	    
   	}
    helpSection += 3;
	
    endAddress = dorAddress + 10 + GetByte(dorAddress+10); 
    InsertArea(&gAreas, dorAddress, endAddress, appldor); /* Define area of Application DOR */    
    if (isNullPointer(dorAddress+3) == false) {
        ParseApplDOR(nextApplDor); /* a brother pointer exists to the next application (DOR) */
    }
}


/* Front DOR is located at $3FC0 in top bank of application card */
void	ParseFrontDor(void)
{
    long pc = Org + 0x3fc0;
    long frontDor = pc;
    int applDor;
    char applLabelName[32];
    
	if (Codesize != 16384) {
 		puts("OZ static structures can only be parsed in 16K bank files.");
 		return;
	}
	
	if (GetByte(gEndOfCode-1) != 'O' && GetByte(gEndOfCode) != 'Z') {
 		puts("ROM Header not found at top of bank.");
 		return;		
	}
	
    puts("Parsing Front DOR..");

	/* first 3 bytes of Front DOR is always zero */
	if (isNullPointer(pc) == false) {
        puts("Front DOR wasn't recognized. Aborted parsing.");
        return;
	}

	pc += 3;
	if (isNullPointer(pc) == false) {
	    /* TODO: Pointer to Help Front DOR available, parse Help structures */
	} 

	pc += 3;
	applDor = getPointer(pc);
	
	applDor &= 0x3FFF; /* preserve only the 14bit offset of the DOR pointer */
	applDor |= (Org & 0xC000); /* and mask the segment of the ORG segment */
	
	pc += 3; /* point at DOR type */
    if (GetByte(pc++) != 0x13) {
        puts("Front DOR wasn't recognized. Aborted parsing.");
        return;        
    }
	CreateLabel(frontDor,"frontdor");

    strcpy(applLabelName, "applDor_");
    strcat(applLabelName, getApplDorName(applDor));    
    CreateLabel(applDor,applLabelName);
    
    pc += GetByte(pc); /* the DOR length is added to point at last byte of Front DOR) */
    InsertArea(&gAreas, frontDor, pc, frontdor);
    CreateLabel(pc+1,"frontdor_end");

    InsertArea(&gAreas, pc+1, gEndOfCode-8, defb); /* resolve area between Front DOR and ROM header */
    
    ParseApplDOR(applDor);
}


void	ParseRomDor(void)
{
	if (Codesize != 16384) {
 		puts("OZ static structures can only be parsed in 16K bank files.");
 		return;
	}
	
	if (GetByte(gEndOfCode-1) != 'O' && GetByte(gEndOfCode) != 'Z') {
 		puts("ROM Header not found at top of bank.");
 		return;		
	}
	
	puts("Parsing ROM header..");
	CreateLabel(gEndOfCode-7,"romhdr");
	InsertArea(&gAreas, gEndOfCode-7, gEndOfCode, romhdr);
	ParseFrontDor();
}


void	ParseLookupTable(void)
{
	long	startrange, endrange, pc, pointer;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((pc=GetConstant()) == -1) {
		puts("Start range Address not legal.");
		return;
	}
	/* fetch address constant for end range */
	cmdlGetSym();
	if ((endrange=GetConstant()) == -1) {
		puts("End Range Address not legal.");
		return;
	}

	startrange = pc;
	StoreDataRef(pc);			/* Define beginning of table as	label... */
	while(pc < endrange) {
		pointer	= (unsigned char) GetByte(pc++);
		pointer	+= (unsigned short) (256 * GetByte(pc++));
		PushItem(pointer, &gParseAddress);	/* first address to parse */
		StoreAddrRef(pointer);			/* define pointer as a label */
		DZpass1();				/* Parse areas from pc onwards */
	}

	InsertArea(&gAreas, startrange,	endrange, addrtable);

	printf("\n\n%-3.2f%% resolved.\n", ResolvedAreas());
}


void	ParsePointerTable(void)
{
	long	startrange, endrange, pc, offset;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((pc=GetConstant()) == -1) {
		puts("Start range Address not legal.");
		return;
	}
	/* fetch address constant for end range */
	cmdlGetSym();
	if ((endrange=GetConstant()) == -1) {
		puts("End Range Address not legal.");
		return;
	}

	startrange = pc;
	StoreDataRef(pc);			/* Define beginning of table as	label... */
	while(pc < endrange) {
		offset	= (unsigned char) GetByte(pc++);
		offset	+= (unsigned short) (256 * GetByte(pc++));
		pc++; /* skip bank number, not used here... */
		StoreAddrRef(offset);	/* define pointer as a label */
	}

	InsertArea(&gAreas, startrange,	endrange, addrtable);

	printf("\n\n%-3.2f%% resolved.\n", ResolvedAreas());
}


void	ParseVectorTable(void)
{
	long	pc;

	/* fetch address constant */
	cmdlGetSym();
	if ((pc=GetConstant()) == -1) {
		puts("Address not legal.");
		return;
	}

      	if ((pc	>= Org)	&& (pc <= gEndOfCode)) {
		StoreAddrRef(pc);			/* define JP base vector as a label */
		while(GetByte(pc) == JP_opcode)	{
		  	PushItem(pc, &gParseAddress);		/* first address to parse */
		       	DZpass1();				/* Parse areas from pc onwards */
	       		pc += 3;				/* point at next JP instruction	*/
		}

		printf("\n\n%-3.2f%% resolved.\n", ResolvedAreas());
     	}
	else
     		puts("JP vector table out of program range.");
}


void	ParseDZ(void)
{
	long	pc;

	/* fetch address constant */
	cmdlGetSym();
	if ((pc=GetConstant()) == -1) {
		puts("Parse Address not legal.");
		return;
	}

	if ((pc	>= Org)	&& (pc <= gEndOfCode)) {
		PushItem(pc, &gParseAddress);		/* first address to parse */
		StoreAddrRef(pc);			/* define entry	also as	a label	*/
		DZpass1();				/* Parse areas from pc onwards */

		printf("\n\n%-3.2f%% resolved.\n", ResolvedAreas());
	}
	else
		puts("Parse Address out of loaded code range.");
}


void	SampleDZ(void)
{
	static long	last_pc = -1;

	long		lines;
	long		pc0, pc;
	char		mnemonic[64];
	LabelRef	*foundlabel;

	cmdlGetSym();
	if (last_pc != -1 && sym == newline) {
		/* no address argument was specified - use last known dz address */
		pc = last_pc;
	} else {
		/* try to fetch disassemble address constant */
		if ((pc=GetConstant()) == -1) {
			puts("Address not legal.");
			return;
		}
	}

	last_pc = pc;
	if ((pc	>= 0) && (pc <= MAXCODESIZE-1)) {
		do
		{
			for(lines=0; lines<16; lines++)	{
				foundlabel = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
				if (foundlabel != NULL) {
					if (foundlabel->name != NULL)
						printf(".%s\n", foundlabel->name);
					else
						printf(".L_%04lX\n", foundlabel->addr);
				}
				pc0 = pc;
				pc = Disassemble(mnemonic, pc, true);
				fprintf(stdout,"\t\t");
				DisplayMnemonic(stdout, pc0, mnemonic);
			}
			printf("dzasm>dz>");
			GetCmdline(); cmdlGetSym();
			if (GetConstant() != -1) pc = GetConstant();
		}
		while(*cmdline != 'q');
	}
	else
		puts("Disassemble address out of Z80 address space!");
}


void	SampleMemory(void)
{
	long	pc;

	/* fetch address constant */
	cmdlGetSym();
	if ((pc=GetConstant()) == -1) {
		puts("Address not legal.");
		return;
	}

	DisplayMemory(pc);
}


void	DisplayMemory(long pc)
{
	long	rows, columns, b;

	do {
		if ((pc	< 0) || (pc > (MAXCODESIZE-1))) {
			puts("Address not legal.");
			break;
		}

		for(rows=0; rows<8; rows++) {
			printf("%04lX ",	pc+rows*16);
			for(columns=0; columns<16; columns++)
				printf("%02X ",	GetByte(pc + rows*16 + columns));
			for(columns=0; columns<16; columns++) {
				b = GetByte(pc + rows*16 + columns);
				printf("%c", (b>=32 && b<=127) ? b : '.' );
			}
			putchar('\n');
		}

		printf("dzasm>mv>");

		GetCmdline(); cmdlGetSym();
		switch(sym) {
			case minus:
				cmdlGetSym();
				if (GetConstant() != -1)
					pc -= GetConstant();
				else
					puts("Illegal offset.");
				break;
			case plus:
				cmdlGetSym();
				if (GetConstant() != -1)
					pc += GetConstant();
				else
					puts("Illegal offset.");
				break;

			case decmconst:
			case hexconst:
			case binconst:
				pc = GetConstant();
				break;

			default:
				pc += 16*8;
				break;
		}
	}
	while(cmdline[0] != 'q' && cmdline[0] != 'n');
}


void	FindCode(void)
{
	unsigned char	s[64];
	unsigned char	*searchptr, i, c, length;
	long		saddr;

	searchptr = s;

	/* fetch address constant for search start */
	cmdlGetSym();
	if ((saddr=GetConstant()) == -1) {
		puts("Address not legal.");
		return;
	}

	cmdlGetSym();
	if (sym != hexconst) {
		puts("Only hex code sequense allowed");
		return;
	}

	length = strlen((char *) (ident+1));
	if (length%2 !=	0) {
		puts("Illegal hex code sequense!");
		return;
	}

	for(i=1; i<=length; i += 2) {
		ident[i] = toupper(ident[i]); ident[i+1] = toupper(ident[i+1]);
		*searchptr = 16	* ((ident[i]<='9') ? ident[i]-48 : ident[i]-55);
		*searchptr += (ident[i+1]<='9') ? ident[i+1]-48 : ident[i+1]-55;
		++searchptr;
	}
	length = length	/ 2;	/* actual length of search chars */

	i = 0; c=0;
	printf("Searching from %04lX", saddr);
	while(saddr < gEndOfCode) {
		if (!c++) putchar('.');
		if (CmpString(saddr, s,	length)	== true) {
			printf(" - found match at %04lX:\n", saddr);
			++i;
			DisplayMemory(saddr);
			if (cmdline[0] == 'q') return;
		}

		++saddr;
	}

	printf("\n%d matches were found.\n", i);
}


enum truefalse	CmpString(long saddr, unsigned char  *sptr, unsigned char  l)
{
	while(l--) {
		if (*sptr++ != GetByte(saddr++)) return false;
	}

	return true;
}



void	DefMemProgArea(void)
{
	long		start, end;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((start=GetConstant()) == -1) {
		puts("Start Range Address not legal.");
		return;
	}
	/* fetch address constant for end range */
	cmdlGetSym();
	if ((end=GetConstant()) == -1) {
		puts("End Range Address not legal.");
		return;
	}

	if ((start < Org) || (start > gEndOfCode) || (end < Org) || (end > gEndOfCode))	{
		puts("Area out of code range.");
		return;
	}
	if (start > end) {
		puts("Illegal range.");
		return;
	}

	StoreAddrRef(start);	/* define entry	also as	a label	*/
	if (InsertArea(&gAreas, start, end, program) == NULL) puts("No room");
}


void	DefMemAddrArea(void)
{
	long		start, end, table, pointer;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((start=GetConstant()) == -1) {
		puts("Start Range Address not legal.");
		return;
	}
	/* fetch address constant for end range */
	cmdlGetSym();
	if ((end=GetConstant()) == -1) {
		puts("End Range Address not legal.");
		return;
	}

	if ((start < Org) || (start > gEndOfCode) || (end < Org) || (end > gEndOfCode))	{
		puts("Area out of code range.");
		return;
	}
	if (start > end) {
		puts("Illegal range.");
		return;
	}
	if ((end - start+1) % 2 != 0) {
		puts("DEFW table cannot fit last pointer.");
		return;
	}

	StoreDataRef(start);			/* Define beginning of table as label... */
	for(table = start; table<end; table += 2) {
		pointer	= (unsigned char) GetByte(table);
		pointer	+= (unsigned short) (256 * GetByte(table+1));
		StoreDataRef(pointer);		/* The pointer is label... */
	}
	if (InsertArea(&gAreas, start, end, defw) == NULL) puts("No room");
}


void		DefineIncludeFile(void)
{
	short		i;

	cmdlGetSym();
	if (sym == dquote) {
		i = 0;
		while((*lineptr != '\'') && (*lineptr != '"') && (*lineptr != '\n')) ident[i++] = *lineptr++;
		ident[i] = '\0';

		AddIncludeFile(ident);
	} else {
		puts("Filename not specified");
	}
}



void	DefineExpression(void)
{
	long		expraddr;
	short		i;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((expraddr=GetConstant()) == -1) {
		puts("Expression address illegal or not specified.");
		return;
	}

	cmdlGetSym();
	if (sym != dquote && sym != squote)
		puts("Expression not specified properly.");
	else {
		i = 0;
		while((*lineptr != '\'') && (*lineptr != '"') && (*lineptr != '\n')) ident[i++] = *lineptr++;
		ident[i] = '\0';

		AddExpression(expraddr,ident);
	}
}


void	AddExpression(long expraddr, char *exprstr)
{
	Expression	*foundexpr, *newexpr;

	foundexpr = find(gExpressions, &expraddr, (int (*)()) CmpExprAddr2);
	if (foundexpr != NULL) {
		/* mnemonic expression already created, update string expression */
		if (foundexpr->expr != NULL) free(foundexpr->expr);
		foundexpr->expr = AllocLabelname(exprstr);
		if (foundexpr->expr != NULL) strcpy(foundexpr->expr, exprstr);
	} else {
		/* not found, create a new expression ... */
		newexpr = AllocMnemExpr();
		if (newexpr != NULL) {
			newexpr->addr = expraddr;
			newexpr->expr = AllocLabelname(exprstr);
			if (newexpr->expr != NULL) strcpy(newexpr->expr, exprstr);
			insert(&gExpressions, newexpr, (int (*)()) CmpExprAddr);

			collectfile_changed = true;
		} else
			puts("No room for expression");
	}
}


void	DefineConstant(void)
{
	long	constaddr;

	/* fetch address constant for */
	cmdlGetSym();
	if ((constaddr=GetConstant()) == -1) {
		puts("Constant illegal or not specified.");
		return;
	}

	cmdlGetSym();
	if (sym != name)
		puts("Constant name not specified.");
	else {
		AddGlobalConstant(constaddr,ident);
	}
}


void	AddGlobalConstant(long constant, char *conststr)
{
	GlobalConstant	*foundconst, *newconst;

	foundconst = find(gGlobalConstants, &constant, (int (*)()) CmpConstant2);
	if (foundconst != NULL) {
		/* mnemonic constant name already created, update string ... */
		if (foundconst->constname != NULL) free(foundconst->constname);
		foundconst->constname = AllocLabelname(conststr);
		if (foundconst->constname != NULL) strcpy(foundconst->constname, conststr);
	} else {
		/* not found, create a new constant name ... */
		newconst = AllocGlobalConstant();
		if (newconst != NULL) {
			newconst->constantval = constant;
			newconst->constname = AllocLabelname(conststr);
			if (newconst->constname != NULL) strcpy(newconst->constname, conststr);
			insert(&gGlobalConstants, newconst, (int (*)()) CmpConstant);

			collectfile_changed = true;
		} else
			puts("No room for global constant");
	}
}


void	DefMemStrArea(void)
{
	long	start, end;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((start=GetConstant()) == -1) {
		puts("Start Range Address not legal.");
		return;
	}
	/* fetch address constant for end range */
	cmdlGetSym();
	if ((end=GetConstant()) == -1) {
		puts("End Range Address not legal.");
		return;
	}

	if ((start < Org) || (start > gEndOfCode) || (end < Org) || (end > gEndOfCode))	{
		puts("String out of code range.");
		return;
	}
	if (start > end) {
		puts("Illegal range.");
		return;
	}
	StoreDataRef(start);		     /*	Define beginning of string as label... */
	if (InsertArea(&gAreas, start, end, string) == NULL) puts("No room");
}


void	RemarkOutput(void)
{
	long		remaddr;
	enum symbols	remtype;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((remaddr=GetConstant()) == -1) {
		puts("Remark Address not legal.");
		return;
	}

	cmdlGetSym();
	remtype = sym;

	switch(remtype) {
		case less:
			puts("dzasm>rem>Remarks will be inserted on separate line before mnemonic output.");
			puts("dzasm>rem>Several contigous comment lines may be created for this address.");
			break;

		case greater:
			puts("dzasm>rem>Remark will be added after mnemonic output on same line.");
			puts("dzasm>rem>Only first (single) line is printed in output.");
			break;

		default:
			puts("Preamble or postamble indicator missing.");
			return;
	}

	puts("dzasm>rem>");
	puts("dzasm>rem>Finish line with <ENTER>. End comment with a '.' as the first");
	puts("dzasm>rem>character on command line.");

	while(cmdline[0] != '.') {
		printf("dzasm>rem>\"");
		GetCmdline();
		if (cmdline[0] != '.') AddRemark(remaddr, separators[remtype], cmdline);
	}
}


void	DefineMemory(void)
{
	if (cmdlGetSym() != name)
		puts("Memory area type wasn't specified.");

	if (strcmp(ident, "prog") == 0)
		DefMemProgArea();
	else if (strcmp(ident, "defw") == 0)
		DefMemAddrArea();
	else if (strcmp(ident, "defb") == 0)
		DefMemByteArea();
	else if (strcmp(ident, "defm") == 0)
		DefMemStrArea();
	else if (strcmp(ident, "defs") == 0)
		DefStorageArea();
	else
		puts("Memory area type unknown.");
}


void	DefStorageArea(void)
{
	long		start, end;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((start=GetConstant()) == -1) {
		puts("Start Range Address not legal.");
		return;
	}
	/* fetch address constant for end range */
	cmdlGetSym();
	if ((end=GetConstant()) == -1) {
		puts("End Range Address not legal.");
		return;
	}

	if ((start < Org) || (start > gEndOfCode) || (end < Org) || (end > gEndOfCode))	{
		puts("Area out of code range.");
		return;
	}
	if (start > end) {
		puts("Illegal range.");
		return;
	}

	if (InsertArea(&gAreas, start, end, defs) == NULL) puts("No room");
}


void	DefMemByteArea(void)
{
	long		start, end;

	/* fetch address constant for start range */
	cmdlGetSym();
	if ((start=GetConstant()) == -1) {
		puts("Start Range Address not legal.");
		return;
	}
	/* fetch address constant for end range */
	cmdlGetSym();
	if ((end=GetConstant()) == -1) {
		puts("End Range Address not legal.");
		return;
	}

	if ((start < Org) || (start > gEndOfCode) || (end < Org) || (end > gEndOfCode))	{
		puts("Area out of code range.");
		return;
	}
	if (start > end) {
		puts("Illegal range.");
		return;
	}

	if (InsertArea(&gAreas, start, end, defb) == NULL) puts("No room");
}


void	ReloadCollectFile(void)
{
	if (collectfile_available == true && collectfile_changed == true) {
		printf("Collect information has been changed.\nLoose updates? [ENTER = Yes, N = No]> ");
		GetCmdline();
		if (*lineptr == 'N' || *lineptr == 'n') return;
	}

	ClearDataStructs();
	ReadCollectFile();
}



void	DispUnknownAreas(void)
{
	DispVoidAreas(stdout, gAreas);

	printf("\n%-3.2f%% resolved.\n", ResolvedAreas());
}


void	DispAllAreas(void)
{
	DispAreas(stdout, gAreas, true);

	printf("\n\n%-3.2f%% resolved.\n", ResolvedAreas());
}


int 	idcmp (const char *idptr, const struct dzcmd *symptr)
{
	return strcmp (idptr, symptr->cmd);
}


int	SearchCmd (void)
{
	struct dzcmd *foundsym;

	foundsym = (struct dzcmd *) bsearch (ident, dzcommands, totaldzcmds, sizeof (struct dzcmd), (fptr) idcmp);

	if (foundsym == NULL)
		return -1;
	else
		return foundsym - dzcommands;
}


void 	ExecuteCommand(void)
{
	int id;

	if ((id = SearchCmd ()) == -1)
		puts("Command not available.");
	else
		(dzcommands[id].dzcmd) ();
}


/*
	Parse command line, and execute commands that are recognized
*/
void	ParseCommands(void)
{
	if (cmdlGetSym() == name)
		ExecuteCommand();
	else
		if (*lineptr != '\n') puts("Unknown or illegal command");
}


enum symbols	cmdlGetSym(void)
{
	char	*instr;
	int	c, chcount = 0;

	ident[0] = '\0';

	for (;;)
	{       /* Ignore leading white spaces, if any... */
		c = *lineptr++;
		if ((c == '\0') || (c == '\n')) {
			lineptr--;
			sym = newline;
			return newline;
		}
		else {
			if (!isspace(c)) break;
		}
	}

	instr =	strchr(separators, c);
	if (instr != NULL) {
		sym = ssym[(instr-separators)];
		return sym;	/* index of found char in separators[] */
	}

	ident[chcount++] = (char) c;
	switch (c) {
		case '$':
			sym = hexconst;
			break;

		case '@':
			sym = binconst;
			break;
		case '~':
			sym = decmconst;
			break;

		default:
			if (isalpha(c)) {
				sym = name;	/* an identifier found */
			} else if (isxdigit(c) || isdigit(c)) {
				sym = hexconst;		/* a hexadecimal number found */
                        } else {
				sym = nil;	/* rubbish ... */
			}
			break;
	}

	/* Read	identifier until space or legal	separator is found */
	if (sym	== name) {
		for (;;) {
			c = *lineptr++;
			if ((!iscntrl(c)) && (strchr(separators, c) == NULL)) {
				if (!isalnum(c)) {
					if (c != '_') {
						sym = nil;
						break;
					} else
						ident[chcount++] = '_';	/* underscore in identifier */
				} else
					ident[chcount++] = (char) c;
			} else {
				lineptr--;  /* puch character back into stream for next read */
				break;
			}
		}
	} else
		for (;;) {
			c = *lineptr++;
			if (!iscntrl(c)	&& (strchr(separators, c) == NULL))
				ident[chcount++] = c;
			else {
				lineptr--;  /* puch character back into stream for next read */
				break;
			}
		}

	ident[chcount] = '\0';
	return sym;
}


int		CmpConstant(GlobalConstant *key, GlobalConstant *node)
{
	return (key->constantval) - (node->constantval);
}


int		CmpConstant2(long *key, GlobalConstant *node)
{
	return (*key) - (node->constantval);
}


int		CmpExprAddr(Expression *key, Expression *node)
{
	return (key->addr) - (node->addr);
}


int		CmpExprAddr2(long *key, Expression *node)
{
	return (*key) - (node->addr);
}

int		CmpCommentRef(Remark *key, Remark *node)
{
	return (key->addr) - (node->addr);
}


int		CmpCommentRef2(long *key, Remark *node)
{
	return (*key) - (node->addr);
}


void		DisplayMnemonic(FILE *out, long addr, char *mnemonic)
{
	Remark		*foundcomment;
	Commentline	*curline;

	foundcomment = find(gRemarks, &addr, (int (*)()) CmpCommentRef2);
	if (foundcomment != NULL) {
		curline = foundcomment->comments;
		if (curline != NULL) {
			if (foundcomment->position == '<') {
				while(curline != NULL) {
					fprintf(out, "; %s", curline->line);
					curline = curline->next;
				}
				fprintf(out, "%s\n", mnemonic);
			} else {
				fprintf(out, "%s\t\t; %s", mnemonic, curline->line);
			}
		}
	} else {
		/* No comments, just display mnemonic text */
		fprintf(out, "%s\n", mnemonic);
	}
}


Remark		*AddRemark(long Address, char pos, char *commentstr)
{
	Remark	*foundcomment, *newcomment;

	foundcomment = find(gRemarks, &Address, (int (*)()) CmpCommentRef2);
	if (foundcomment == NULL) {
		/* create a comment entry in comments collection for this address */
		newcomment = AllocRemark();
		if (newcomment == NULL)
			return NULL;
		else {
			newcomment->addr = Address;
			newcomment->position = pos;
			newcomment->comments = NULL;
			insert(&gRemarks, newcomment, (int (*)()) CmpCommentRef);

			foundcomment = newcomment;
			collectfile_changed = true;
		}
	}

	if (AddCommentline(foundcomment, commentstr) == NULL)
		return NULL;	/* no room for new comment line ... */
	else
		return foundcomment;
}


Commentline	*AddCommentline(Remark *entity, char *commentstr)
{
	Commentline	*newcomment, *curcomment;
	char		*newstr;

	if (entity == NULL) return NULL;	/* this shouldn't happen... */

	newstr = (char *) malloc(strlen(commentstr)+1);
	if (newstr == NULL)
		return NULL;			/* no room for new comment line! */
	else
		strcpy(newstr, commentstr);	/* copy comment line... */

	newcomment = AllocCommentline();
	if (newcomment == NULL) {
		free(newstr);
		return NULL;			/* no room for new comment! */
	} else {
		newcomment->line = newstr;
		newcomment->next = NULL;
	}

	curcomment = entity->comments;			/* head of linked list */
	if (curcomment == NULL) {
		entity->comments = newcomment;		/* added first comment line */
	} else {
		while(curcomment->next != NULL)
			curcomment = curcomment->next;	/* get to end of list */
		curcomment->next = newcomment;		/* and add the new comment line */
	}

	collectfile_changed = true;
	return newcomment;	/* indicate success */
}


IncludeFile	*AddIncludeFile(char *inclflnm)
{
	IncludeFile	*newinclfl, *curinclfl;
	char		*newstr;

	newstr = (char *) malloc(strlen(inclflnm)+1);
	if (newstr == NULL)
		return NULL;			/* no room for new include filename! */
	else
		strcpy(newstr, inclflnm);	/* copy comment line... */

	newinclfl = AllocIncludeFile();
	if (newinclfl == NULL) {
		free(newstr);
		return NULL;			/* no room for new include filename! */
	} else {
		newinclfl->filename = newstr;
		newinclfl->next = NULL;
	}

	curinclfl = gIncludeFilenames;			/* head of linked list */
	if (curinclfl == NULL) {
		gIncludeFilenames = newinclfl;		/* added first include file */
	} else {
		while(curinclfl->next != NULL)
			curinclfl = curinclfl->next;	/* get to end of list */
		curinclfl->next = newinclfl;		/* and add the new include filename */
	}

	collectfile_changed = true;
	return newinclfl;	/* indicate success */
}


GlobalConstant	*AllocGlobalConstant(void)
{
	return (GlobalConstant *) malloc(sizeof(GlobalConstant));
}

Expression	*AllocMnemExpr(void)
{
	return (Expression *) malloc(sizeof(Expression));
}

Remark		*AllocRemark(void)
{
	return (Remark *) malloc(sizeof(Remark));
}

Commentline	*AllocCommentline(void)
{
	return (Commentline *) malloc(sizeof(Commentline));
}

IncludeFile	*AllocIncludeFile(void)
{
	return (IncludeFile *) malloc(sizeof(IncludeFile));
}

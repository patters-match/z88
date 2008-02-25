
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
#include "dzasm.h"
#include "avltree.h"

FILE			*asmfile = NULL;

extern long		        Org, Codesize;
extern enum truefalse	gIncludeList[];
extern DZarea		    *gExtern;		/* list	of extern areas	*/
extern DZarea		    *gAreas;		/* list	of areas currently examined */
extern avltree		    *gLabelRef;		/* Binary tree of program labels */
extern avltree		    *gRemarks;		/* Binary tree of comments for output file */
extern char		        ident[];
extern char		        Z80codeflnm[];		/* name	of Z80 code file */
extern char		        *gIncludeFiles[], *gAreaTypes[];
extern IncludeFile	    *gIncludeFilenames;

unsigned char	GetByte(long pc);
long			Disassemble(char *str, long pc, enum truefalse  dispaddr);
void			DZpass2(void);
void			Z80Asm(long pc, long  endarea);
void			VoidOutput(long	 pc, long  endarea);
void			DefwOutput(long	 pc, long  endarea);
void			DefmOutput(long	 pc, long  endarea);
void			DeclExtProg(void);
void			DeclExtData(void);
void			DeclGlobalProg(void);
void			DeclGlobalData(void);
void			XdefDataItem(LabelRef  *itemptr);
void			XdefAddrItem(LabelRef  *itemptr);
void			VoidAsciiOutput(long	pc);
void			XrefAddrItem(LabelRef  *itemptr);
void			XrefDataItem(LabelRef  *itemptr);
void			DisplayMnemonic(FILE *out, long addr, char *mnemonic);
void			DefbOutput(long	 pc, long  endarea);
void			RomHdrOutput(long	 pc, long  endarea);
void			FrontDOROutput(long	 pc, long  endarea);
void			ApplDOROutput(long	 pc, long  endarea);
void			MthTopicOutput(DZarea *currarea, long pc, long endarea);
void			DefStorageOutput(long pc, long  endarea);
int             CmpAddrRef2(long *key, LabelRef *node);
int			    CmpCommentRef2(long *key, Remark *node);
void			LabelAddr(char *operand, long pc, long addr, enum truefalse dispaddr);
int             getPointer(long address);
int             getPointerOffset(long address);
enum truefalse  isNullPointer(long address);
unsigned char	*DecodeAddress(long pc, unsigned char *segm, unsigned short *offset);
char			*getApplDorName(long dorAddress);


/* Create assembler source (with labels) from program and data areas */
void	DZpass2(void)
{
	DZarea		*currarea;
	enum files	ifile;
	char		outasmflnm[64];
	IncludeFile	*curIncludeFile;

	puts("Generating assembler source...");

	strcpy(outasmflnm,Z80codeflnm);
	if (strchr(outasmflnm,'.') != NULL) *(strchr(outasmflnm, '.')) ='\0';
	strcat(outasmflnm, ".asm");

	asmfile	= fopen(outasmflnm, "w");
	if (asmfile == NULL) {
		puts("Couldn't open assembler output file.");
		return;
	}

	/* define the MODULE name */
	strcpy(outasmflnm,Z80codeflnm);
	if (strchr(outasmflnm,'.') != NULL) *(strchr(outasmflnm, '.')) ='\0';
	fprintf(asmfile, "MODULE %s\n\n", outasmflnm);

	DeclExtProg();			/* XREF	for all	external program references */
	DeclExtData();			/* XREF	for all	external data references */
	DeclGlobalProg();		/* XDEF	for all	local program references */
	DeclGlobalData();		/* XDEF	for all	local data references */

	fprintf(asmfile, "\nORG $%04lX\n\n", Org);

	for (ifile = stdio; ifile <= handle; ifile++) {
		if (gIncludeList[ifile]	== true)
			fprintf(asmfile, "        include \"%s.def\"\n", gIncludeFiles[ifile]);
	}

	curIncludeFile = gIncludeFilenames;
	while(curIncludeFile != NULL) {
		fprintf(asmfile, "        include \"%s\"\n", curIncludeFile->filename);
		curIncludeFile = curIncludeFile->next;
	}
	fputc('\n', asmfile);

	currarea = gAreas;		/* point at first list */
	while(currarea != NULL)	{
		printf("%s\t [%04lX - %04lX]\n", gAreaTypes[currarea->areatype], currarea->start, currarea->end);

		switch(currarea->areatype) {
			case	program:
					Z80Asm(currarea->start,	currarea->end);
					break;

			case	vacuum:
					VoidOutput(currarea->start, currarea->end);
					break;
			case	defb:
					DefbOutput(currarea->start, currarea->end);
					break;
			case    defs:
					DefStorageOutput(currarea->start, currarea->end);
					break;
			case	defw:
			case	addrtable:
					DefwOutput(currarea->start, currarea->end);
					break;

			case	string:
					DefmOutput(currarea->start, currarea->end);
					break;
					
			case	romhdr:
					RomHdrOutput(currarea->start, currarea->end);
					break;
					
			case	frontdor:
					FrontDOROutput(currarea->start, currarea->end);
					break;

			case	appldor:
					ApplDOROutput(currarea->start, currarea->end);
					break;

			case	helpdor:
					DefbOutput(currarea->start, currarea->end);
					break;

			case	mthtpc:
					MthTopicOutput(currarea, currarea->start, currarea->end);
					break;

			case	mthcmd:
					DefbOutput(currarea->start, currarea->end);
					break;

			case	mthhlp:
					DefmOutput(currarea->start, currarea->end);
					break;

			case	mthtkn:
					DefbOutput(currarea->start, currarea->end);
					break;
		    default:
		        printf("Unknown area type: %d!\n", currarea->areatype);
		}

		currarea = currarea->nextarea;
	}

	fclose(asmfile);
	puts("Assembler Source Generation completed.");
}


void	VoidOutput(long	 pc, long  endarea)
{
	long			column,	offset;
	enum truefalse	exitdump;
	LabelRef	    *foundlabel;

	exitdump = false;
	fprintf(asmfile, "; %04lXh\n", pc);

	do {
		for(column=0; column<16; column++) {
			if (pc+column >	endarea) {
				if (column != 0) VoidAsciiOutput(pc);
				exitdump = true;
				break;
			}

			offset = pc+column;
			if ((foundlabel	= find(gLabelRef, &offset, (int (*)()) CmpAddrRef2)) != NULL) {
				if (column != 0) VoidAsciiOutput(pc);
				if (foundlabel->name != NULL)
					fprintf(asmfile, ".%s\n", foundlabel->name);
				else
					fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
				pc = foundlabel->addr;
				column=0;
			}

			if (column == 0)
				fprintf(asmfile, "        defb    $%02X", GetByte(pc));
			else
				fprintf(asmfile, ",$%02X", GetByte(pc +	column));
		}
		if (exitdump ==	false) {
			VoidAsciiOutput(pc);
			pc += 16;
		}
	}
	while(exitdump == false);

	fputc('\n', asmfile);
}


void	DefbOutput(long	 pc, long  endarea)
{
	long			column,	offset;
	enum truefalse		exitdump, defbline;
	LabelRef	       	*foundlabel;
	Remark			*foundcomment;
	Commentline		*curline;

	exitdump = false;

	do {
		defbline = true;
		for(column=0; column<8; column++) {
			offset = pc+column;

			if (offset > endarea) {
				defbline = true;
				exitdump = true;
				break;
			}

			if ((foundlabel	= find(gLabelRef, &offset, (int (*)()) CmpAddrRef2)) != NULL) {
				defbline = true;
				if (foundlabel->name != NULL)
					fprintf(asmfile, "\n.%s\n", foundlabel->name);
				else
					fprintf(asmfile, "\n.L_%04lX\n", foundlabel->addr);
			}

			foundcomment = find(gRemarks, &offset, (int (*)()) CmpCommentRef2);
			if (foundcomment != NULL) {
				curline = foundcomment->comments;
				if (curline != NULL) {
					if (foundcomment->position == '<') {
						if (defbline == false) {
							fprintf(asmfile, "\n");
						}

						while(curline != NULL) {
							fprintf(asmfile, "; %s", curline->line);
							curline = curline->next;
						}

					} else {
						if (defbline == true)
							fprintf(asmfile, "        defb    $%02X", GetByte(offset));
						else
							fprintf(asmfile, ",$%02X", GetByte(offset));

						fprintf(asmfile, "        ; %s", curline->line);
						pc = offset+1;
						break;
					}
				}
			}

			if (defbline == true) {
				defbline = false;
				fprintf(asmfile, "        defb    $%02X", GetByte(offset));
			} else
				fprintf(asmfile, ",$%02X", GetByte(offset));
		}

		pc += column;
		fputc('\n', asmfile);
	}
	while(exitdump == false);

	if (defbline == false) fputc('\n', asmfile);
}


void	DefStorageOutput(long pc, long  endarea)
{
	LabelRef	*foundlabel;

	foundlabel = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
	if (foundlabel != NULL)	{
		if (foundlabel->name != NULL)
			fprintf(asmfile, ".%s\n", foundlabel->name);
		else
			fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
	}

	fprintf(asmfile, "        defs    %ld ($ff)\t; %04lXh - %04lXh\n\n", endarea-pc+1, pc, endarea);
}


void	VoidAsciiOutput(long	pc)
{
	long	column,	b;

	fprintf(asmfile, "\t; ");
	for(column=0; column<16; column++) {
		b = GetByte(pc + column);
		fprintf(asmfile, "%c", (b>=32 && b<=127) ? b : '.' );
	}
	fputc('\n', asmfile);
}


void	DefwOutput(long	 pc, long  endarea)
{
	long		pointer;
	LabelRef	*foundlabel;
	Remark		*foundcomment;
	Commentline	*curline;
	char		operand[64];

	while(pc < endarea) {
		foundlabel = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
		if (foundlabel != NULL)	{
			if (foundlabel->name != NULL)
				fprintf(asmfile, ".%s\n", foundlabel->name);
			else
				fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
		}

		pointer	= (unsigned char) GetByte(pc);
		pointer	+= (unsigned short) (GetByte(pc+1) * 256);

		LabelAddr(operand, pc, pointer, false);	/* write the address in correct format */

		foundcomment = find(gRemarks, &pc, (int (*)()) CmpCommentRef2);
		if (foundcomment != NULL) {
			curline = foundcomment->comments;
			if (curline != NULL) {
				if (foundcomment->position == '<') {
					while(curline != NULL) {
						fprintf(asmfile, "; %s", curline->line);
						curline = curline->next;
					}

					fprintf(asmfile, "        defw    %s\n", operand);
				} else {
					fprintf(asmfile, "        defw    %s", operand);
					fprintf(asmfile, "        ; %s", curline->line);
				}
			}
		} else {
			fprintf(asmfile, "        defw    %s\n", operand);
		}

		pc += 2;
	}
}


void	DefmOutput(long	 pc, long  endarea)
{
	enum truefalse	asciistring, startline;
	long			pointer, byte, strsize;
	LabelRef		*foundlabel;

	asciistring = false;
	startline = true;
	strsize = 0;

	do {
		pointer	= pc;
		foundlabel = find(gLabelRef, &pointer, (int (*)()) CmpAddrRef2);
		if (foundlabel != NULL)	{
			if (asciistring	== true) {
				asciistring = false;
				if (foundlabel->name != NULL)
					if (startline == true)
						fprintf(asmfile, ".%s\n", foundlabel->name);
					else {
						fprintf(asmfile, "\"\n.%s\n", foundlabel->name);
						startline = true;
					}
				else {
					if (startline == true)
						fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
					else {
						fprintf(asmfile, "\"\n.L_%04lX\n", foundlabel->addr);
						startline = true;
					}
				}
			}
			else {
				if (foundlabel->name != NULL)
					if (startline == true)
						fprintf(asmfile, ".%s\n", foundlabel->name);
					else {
						fprintf(asmfile, "\n.%s\n", foundlabel->name);
						startline = true;
					}
				else {
					if (startline == true)
						fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
					else {
						fprintf(asmfile, "\n.L_%04lX\n", foundlabel->addr);
						startline = true;
					}
				}
			}
		}

		if (startline == true) {
			strsize = 0;
			fprintf(asmfile,"        defm    ");
		}

		byte = GetByte(pc++);
		if (byte >= 32 && byte < 127) {
			if (asciistring == true)
				if (byte != '"')
					fputc(byte, asmfile);
				else
					fprintf(asmfile, "\", '\"', \"", byte);
			else {
				asciistring = true;
				if (startline == true) {
					startline = false;
					if (byte == '"') {
						fprintf(asmfile, "'\"'", byte);
					} else {
						fprintf(asmfile, "\"%c", byte);
					}
				}
				else {
					if (byte == '"') {
						fprintf(asmfile, ", '\"'");
						asciistring = false;
					} else {
						fprintf(asmfile, ", \"%c", byte);
					}
				}
			}
		}
		else {
			if ((strsize > 15) && (startline == false) && (byte != 0)) {
				/* Line contain string of 16 characters or more, and */
				/* a non printable characters is about to be 'added' (but not a NUL); */
				/* put it on a new line */
				if (asciistring	== true) {
					asciistring = false;
					fprintf(asmfile,"\"\n        defm    ");
				} else {
					fprintf(asmfile,"\n        defm    ");
				}
				startline = true;
				strsize = 0;
			}

			if (asciistring	== true) {
				asciistring = false;
				fprintf(asmfile, "\", $%02X", byte);
			}
			else {
				if (startline == true) {
					startline = false;
					fprintf(asmfile, "$%02X", byte);
				}
				else
					fprintf(asmfile, ", $%02X", byte);
			}

			if (byte == 0) {
				/* a null terminator was encountered - create a new line ... */
				fprintf(asmfile,"\n");
				startline = true;
				strsize = 0;
			}
		}

		strsize++;
	}
	while(pc <= endarea);

	if (asciistring	== true)
		fprintf(asmfile, "\"\n");
	else
		fputs("\n", asmfile);
}


void	RomHdrOutput(long	 pc, long  endarea)
{
	LabelRef		*foundlabel;

	foundlabel = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
	if (foundlabel != NULL)	{
		if (foundlabel->name != NULL)
			fprintf(asmfile, ".%s\n", foundlabel->name);
		else
			fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
	}

    fprintf(asmfile, "        defb    $%02x\t; Low byte Card ID\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; High byte Card ID\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; 4 bit Country code\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; External application ($80) / OZ ROM ($81)\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Size of card in 16K banks\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Subtype of card\n", GetByte(pc++));
    DefmOutput(pc, endarea);
}


void    FrontDOROutput(long	 pc, long  endarea)
{
	LabelRef		*foundlabel;
	int             applDor;
	unsigned char	segm;
	unsigned short 	offset;

	foundlabel = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
	if (foundlabel != NULL)	{
		if (foundlabel->name != NULL)
			fprintf(asmfile, ".%s\n", foundlabel->name);
		else
			fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
	}
    
    fprintf(asmfile, "        defp    0,0\n");
    pc += 3;
    fprintf(asmfile, "        defp    0,0\n"); /* TODO: implement Help Front DOR, if available */
    pc += 3;
    applDor = getPointerOffset(pc);
        
    foundlabel = find(gLabelRef, &applDor, (int (*)()) CmpAddrRef2);
    fprintf(asmfile, "        defp    %s & $3fff,$%02x\t; Pointer to first application DOR\n", foundlabel->name, GetByte(pc+2));
    pc += 3;
    fprintf(asmfile, "        defb    $%02x\t; DOR type = ROM Front DOR\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; DOR length\n", GetByte(pc++));
    fprintf(asmfile, "        defb    '%c'\t; Name section\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Length of name\n", GetByte(pc++));
    fprintf(asmfile, "        defm    \"%s\",0\t\n", DecodeAddress(pc, &segm, &offset));
    fprintf(asmfile, "        defb    $%02x\t; DOR Terminator\n", GetByte(pc+6));
}


void    ApplDOROutput(long	 pc, long  endarea)
{
	LabelRef		*lr, *applDorBaseLabel, *nextApplDorLabel;
	int             applDorOffset, applEntry, lengthByte, mthTopics, mthCommands, mthHelp, mthTokens;
	unsigned char	segm;
	unsigned short 	offset;
	char            dorStartName[32], dorEndName[32];
    char            applStartName[32], applEndName[32];
    
    /* Label is always defined for start of DOR by parser */
	applDorBaseLabel = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
	fprintf(asmfile, ".%s\n", applDorBaseLabel->name);
    
    fprintf(asmfile, "        defp    0,0\n");
    pc += 3;
    applDorOffset = getPointerOffset(pc);
    
    if (isNullPointer(pc) == false) {
        nextApplDorLabel = find(gLabelRef, &applDorOffset, (int (*)()) CmpAddrRef2);
        fprintf(asmfile, "        defp    %s & $3fff,$%02x\t; Pointer to next application DOR\n", nextApplDorLabel->name, GetByte(pc+2));
    } else {
        fprintf(asmfile, "        defp    0,0\t; Pointer to next application DOR (None)\n");
    }
    pc += 3;
    fprintf(asmfile, "        defp    0,0\t; Link to Son (always 0)\n");
    pc += 3;
    fprintf(asmfile, "        defb    $%02x\t; DOR type = Application ROM\n", GetByte(pc++));
    pc++; /* skip DOR length byte, use label distance expression instead */

    strcpy(dorStartName, applDorBaseLabel->name);
    strcat(dorStartName, "_Start");
    strcpy(dorEndName, applDorBaseLabel->name);
    strcat(dorEndName, "_End");
    
    fprintf(asmfile, "        defb    %s-%s\t; DOR length\n", dorEndName, dorStartName);
    fprintf(asmfile, ".%s\n", dorStartName);    
    fprintf(asmfile, "        defb    '%c'\t; Info section\n", GetByte(pc++));       
    fprintf(asmfile, "        defb    $%02x\t; Length of info section\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x,$%02x\t; Future expansion\n", GetByte(pc++), GetByte(pc++));
    fprintf(asmfile, "        defb    '%c'\t; Application key letter\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; continuous RAM size in 256-byte pages\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x,$%02x\t; estimate of environment overhead\n", GetByte(pc++), GetByte(pc++));
    fprintf(asmfile, "        defw    $%04x\t; Unsafe workspace\n", GetByte(pc++) + 256 * GetByte(pc++));
    fprintf(asmfile, "        defw    $%04x\t; Safe workspace\n", GetByte(pc++) + 256 * GetByte(pc++));
    
    applEntry = GetByte(pc++) + 256 * GetByte(pc++);
    lr = find(gLabelRef, &applEntry, (int (*)()) CmpAddrRef2);
    fprintf(asmfile, "        defw    %s\t; Entry point for application code\n", lr->name);
    
    fprintf(asmfile, "        defb    $%02x\t; Segment 0 entry bank binding\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Segment 1 entry bank binding\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Segment 2 entry bank binding\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Segment 3 entry bank binding\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Application type byte 1\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Application type byte 2\n", GetByte(pc++));

    fprintf(asmfile, "        defb    '%c'\t; Help section\n", GetByte(pc++));
    fprintf(asmfile, "        defb    $%02x\t; Length of section\n", GetByte(pc++));
   	mthTopics = getPointerOffset(pc);
    lr = find(gLabelRef, &mthTopics, (int (*)()) CmpAddrRef2);
    fprintf(asmfile, "        defp    %s & $3fff,$%02x\t; Pointer to Topics\n", lr->name, GetByte(pc+2));
    pc += 3;

   	mthCommands = getPointerOffset(pc);
    lr = find(gLabelRef, &mthCommands, (int (*)()) CmpAddrRef2);
    fprintf(asmfile, "        defp    %s & $3fff,$%02x\t; Pointer to Commands\n", lr->name, GetByte(pc+2));
    pc += 3;

   	mthHelp = getPointerOffset(pc);
    lr = find(gLabelRef, &mthHelp, (int (*)()) CmpAddrRef2);
    fprintf(asmfile, "        defp    %s & $3fff,$%02x\t; Pointer to Help\n", lr->name, GetByte(pc+2));
    pc += 3;
    
   	mthTokens = getPointerOffset(pc);
    lr = find(gLabelRef, &mthTokens, (int (*)()) CmpAddrRef2);
    fprintf(asmfile, "        defp    %s & $3fff,$%02x\t; Pointer to Token Base\n", lr->name, GetByte(pc+2));
    pc += 3;

    fprintf(asmfile, "        defb    '%c'\t; Name section\n", GetByte(pc++));
    lengthByte = GetByte(pc++); /* get length byte of Application Name */

    strcpy(applStartName, applDorBaseLabel->name);
    strcat(applStartName, "_Name");
    strcpy(applEndName, applDorBaseLabel->name);
    strcat(applEndName, "_NameEnd");

    fprintf(asmfile, "        defb    %s-%s\t; Length of name\n", applEndName, applStartName);
    fprintf(asmfile, ".%s\n", applStartName);    
    fprintf(asmfile, "        defm    \"%s\",0\t\n", DecodeAddress(pc, &segm, &offset));
    fprintf(asmfile, ".%s\n", applEndName);    
    fprintf(asmfile, "        defb    $%02x\t; DOR Terminator\n", GetByte(pc+lengthByte));
    fprintf(asmfile, ".%s\n\n", dorEndName);    
}


void MthTopicOutput(DZarea *currarea, long pc, long endarea)
{
	long tpcptr = pc;
	long tpcEnd, tpcHelp, tpcHelpOffset;
	int tpclength, tpcno = 1;
	LabelRef *lr;
	char tpcLabelName[32], mthHelpLabelName[32];
	MthPointers	*mthp = (MthPointers *) currarea->attributes;
	long dorAddress = mthp->dorAddress;
	long mthHelp = mthp->mthHelp;

	lr = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
	fprintf(asmfile, ".%s\n", lr->name);
	fprintf(asmfile, "        defb    0\t; Start topic marker\n");

	if (mthHelp != 0) {
		lr = find(gLabelRef, &mthHelp, (int (*)()) CmpAddrRef2);
		sprintf(mthHelpLabelName,"%s", lr->name);
	}

	/* Scan Topics area until 0 byte end-marker */
	tpcptr++; /* point at length byte of first topic entry */

	while(tpcptr != endarea) {
		lr = find(gLabelRef, &tpcptr, (int (*)()) CmpAddrRef2);
		sprintf(tpcLabelName,"%s", lr->name);
		
		fprintf(asmfile, ".%s\n", tpcLabelName);
		fprintf(asmfile, "        defb    %s_end-%s+1\t; Length of topic\n", tpcLabelName, tpcLabelName);

		tpclength = GetByte(tpcptr);
		tpcEnd = tpcptr + tpclength - 1;
		DefmOutput(tpcptr+1, tpcEnd-4);

		tpcHelpOffset = GetByte(tpcEnd-3) * 256 + GetByte(tpcEnd-2);
		if (tpcHelpOffset != 0 && mthHelp != 0) {
			tpcHelp = mthHelp+tpcHelpOffset;
			lr = find(gLabelRef, &tpcHelp, (int (*)()) CmpAddrRef2);
			fprintf(asmfile, "        defb    (%s-%s) / 256\t; high byte of help offset\n", lr->name, mthHelpLabelName);
			fprintf(asmfile, "        defb    (%s-%s) %% 256\t; low byte of help offset\n", lr->name, mthHelpLabelName);
		} else {
			fprintf(asmfile, "        defw    0\t; No help page\n");
		}
		fprintf(asmfile, "        defb    $%02x\t; Topic attribute\n", GetByte(tpcEnd-1));
		fprintf(asmfile, ".%s_end\n", tpcLabelName);
		fprintf(asmfile, "        defb    %s_end-%s+1\n", tpcLabelName, tpcLabelName);

		tpcptr += tpclength; /* point at next topic */
	}
	fprintf(asmfile, "        defb    0\t; End topic marker\n");
}


/* XREF	for all	external program references */
void	DeclExtProg(void)
{
	fprintf(asmfile, "\n; External Call References:");
	if (gLabelRef == NULL)
		fputs("; None.\n", asmfile);
	else
		inorder(gLabelRef, (void  (*)()) XrefAddrItem);

	fputs("\n",asmfile);
}


/* XREF	for all	external data references */
void	DeclExtData(void)
{
	fprintf(asmfile, "\n; External Data References:");
	if (gLabelRef == NULL)
		fputs("; None.\n", asmfile);
	else
		inorder(gLabelRef, (void (*)())	XrefDataItem);

	fputs("\n",asmfile);
}

void	DeclGlobalProg(void)
{
	fprintf(asmfile, "\n; Global Call References:");
	if (gLabelRef == NULL)
		fputs("; None.\n", asmfile);
	else
		inorder(gLabelRef, (void  (*)()) XdefAddrItem);

	fputs("\n",asmfile);
}


void	DeclGlobalData(void)
{
	fprintf(asmfile, "\n; Global Data References:");
	if (gLabelRef == NULL)
		fputs("; None.\n", asmfile);
	else
		inorder(gLabelRef, (void  (*)()) XdefDataItem);

	fputs("\n",asmfile);
}


/* write XDEF declarations, if user has specified them */
void	XdefAddrItem(LabelRef  *itemptr)
{
	static short	items =	0;

	if (itemptr->local == true && itemptr->xdef == true && itemptr->addrref == true ) {
		if (items++ % 8	== 0)
			fprintf(asmfile, "\nXDEF ");
		else
			fprintf(asmfile, ", ");

		if (itemptr->name != NULL)
			fprintf(asmfile, "%s", itemptr->name);
		else
			fprintf(asmfile, "L_%04lX", itemptr->addr);
	}
}


/* write XDEF declarations, if user has specified them */
void	XdefDataItem(LabelRef  *itemptr)
{
	static short	items =	0;

	if (itemptr->local == true && itemptr->xdef == true && itemptr->addrref == false ) {
		if (items++ % 8	== 0)
			fprintf(asmfile, "\nXDEF ");
		else
			fprintf(asmfile, ", ");

		if (itemptr->name != NULL)
			fprintf(asmfile, "%s", itemptr->name);
		else
			fprintf(asmfile, "L_%04lX", itemptr->addr);
	}
}


/* write XREF declarations, if user has specified them */
void	XrefAddrItem(LabelRef  *itemptr)
{
	static short	items =	0;

	if (itemptr->local != true && itemptr->xref == true && itemptr->addrref != true ) {
		if (items++ % 8	== 0)
			fprintf(asmfile, "\nXREF ");
		else
			fprintf(asmfile, ", ");

		if (itemptr->name != NULL)
			fprintf(asmfile, "%s", itemptr->name);
		else
			fprintf(asmfile, "L_%04lX", itemptr->addr);
	}
}


/* write XREF declarations, if user has specified them */
void	XrefDataItem(LabelRef  *itemptr)
{
	static short	items =	0;

	if (itemptr->local != true && itemptr->xref == true && itemptr->addrref != false ) {
		if (items++ % 8	== 0)
			fprintf(asmfile, "\nXREF ");
		else
			fprintf(asmfile, ", ");

		if (itemptr->name != NULL)
			fprintf(asmfile, "%s", itemptr->name);
		else
			fprintf(asmfile, "L_%04lX", itemptr->addr);
	}
}


/* generate Z80	assembler code,	based on parsed	areas and label	references */
void	Z80Asm(long pc, long  endarea)
{
	LabelRef		*foundlabel;
	char			mnemonic[64];
	long			pc0;

	while(pc <= endarea) {
		foundlabel = find(gLabelRef, &pc, (int (*)()) CmpAddrRef2);
		if (foundlabel != NULL) {
			if (foundlabel->name != NULL)
				fprintf(asmfile, ".%s\n", foundlabel->name);
			else
				fprintf(asmfile, ".L_%04lX\n", foundlabel->addr);
		}

		pc0 = pc;
		pc = Disassemble(mnemonic, pc, false);
		strcpy(ident,"        ");
		strcat(ident, mnemonic);
		DisplayMnemonic(asmfile, pc0, ident);
	}

	fputc('\n', asmfile);
}

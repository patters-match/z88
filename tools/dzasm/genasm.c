
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
void			DefStorageOutput(long pc, long  endarea);
int             CmpAddrRef2(long *key, LabelRef *node);
int			    CmpCommentRef2(long *key, Remark *node);
void			LabelAddr(char *operand, long pc, long addr, enum truefalse dispaddr);

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

	for (ifile = stdio; ifile <= intrrupt;	ifile++) {
		if (gIncludeList[ifile]	== true)
			fprintf(asmfile, "\tINCLUDE \"%s.def\"\n", gIncludeFiles[ifile]);
	}

	curIncludeFile = gIncludeFilenames;
	while(curIncludeFile != NULL) {
		fprintf(asmfile, "\tINCLUDE \"%s\"\n", curIncludeFile->filename);
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
		}

		currarea = currarea->nextarea;
	}

	fclose(asmfile);
	puts("Assembler Source Generation completed.");
}


void	VoidOutput(long	 pc, long  endarea)
{
	Remark			*foundcomment;
	Commentline		*curline;
	long			column,	offset;
	enum truefalse		exitdump;
	LabelRef	       *foundlabel;

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
				fprintf(asmfile, "\t\tDEFB $%02X", GetByte(pc));
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
							fprintf(asmfile, "\t\tDEFB $%02X", GetByte(offset));
						else
							fprintf(asmfile, ",$%02X", GetByte(offset));

						fprintf(asmfile, "\t\t; %s", curline->line);
						pc = offset+1;
						break;
					}
				}
			}

			if (defbline == true) {
				defbline = false;
				fprintf(asmfile, "\t\tDEFB $%02X", GetByte(offset));
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

	fprintf(asmfile, "\t\tDEFS %ld\t; %04lXh - %04lXh\n\n", endarea-pc+1, pc, endarea);
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

					fprintf(asmfile, "\t\tDEFW %s\n", operand);
				} else {
					fprintf(asmfile, "\t\tDEFW %s", operand);
					fprintf(asmfile, "\t\t; %s", curline->line);
				}
			}
		} else {
			fprintf(asmfile, "\t\tDEFW %s\n", operand);
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
			fprintf(asmfile,"\t\tDEFM ");
		}

		byte = GetByte(pc++);
		if (byte >= 32 && byte <= 127) {
			if (asciistring == true)
				if (byte != '"')
					fputc(byte, asmfile);
				else
					fprintf(asmfile, "\" & '\"' & \"", byte);
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
						fprintf(asmfile, " & '\"'");
					} else {
						fprintf(asmfile, " & \"%c", byte);
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
					fprintf(asmfile,"\"\n\t\tDEFM ");
				} else {
					fprintf(asmfile,"\n\t\tDEFM ");
				}
				startline = true;
				strsize = 0;
			}

			if (asciistring	== true) {
				asciistring = false;
				fprintf(asmfile, "\" & $%02X", byte);
			}
			else {
				if (startline == true) {
					startline = false;
					fprintf(asmfile, "$%02X", byte);
				}
				else
					fprintf(asmfile, " & $%02X", byte);
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
	enum truefalse		linefeed;
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
		strcpy(ident,"\t\t");
		strcat(ident, mnemonic);
		DisplayMnemonic(asmfile, pc0, ident);
	}

	fputc('\n', asmfile);
}

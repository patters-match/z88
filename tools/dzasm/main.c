
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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "dzasm.h"
#include "avltree.h"

extern char		ident[];
extern enum symbols	sym;

#ifdef QDOS
#include <qdos.h>
void			consetup_title();
void			(*_consetup) ()	= consetup_title;
int			    (*_readkbd) (chanid_t, timeout_t, char *) = readkbd_move;
struct WINDOWDEF	_condetails = {2, 1, 0, 7, 484, 256, 0, 0};
#endif

char			_prog_name[] = "DZasm - Z80/Z88 Assembler Source Code Generator";
char			_vers[]	= "0.34";
char			_copyright[] = "\x7f InterLogic 1996-99";

enum truefalse		debug =	false, exit_program = false;
enum truefalse		collectfile_available = false, collectfile_changed = false;

char			Z80codeflnm[64];		/* Filename of Z80 code	file */
char			collectfilename[64];		/* Filename of collect file related to binary file */
long			Org, Codesize, gEndOfCode;
unsigned char		*Segments[4];			/* array of pointers to 4 x 16K segments, defining 64K address space */
DZarea			*gExtern = NULL;		/* list	of extern areas	*/
DZarea			*gAreas = NULL;			/* list	of areas currently examined */
struct PrsAddrStack	*gParseAddress = NULL;		/* stack of addresses to be disassembled */
avltree			*gLabelRef = NULL;		/* Binary tree of program labels and data references */
avltree			*gRemarks = NULL;		/* Binary tree of comments for output file */
avltree			*gExpressions = NULL;		/* Binary tree of expressions for mnemonic operands */
avltree			*gGlobalConstants = NULL;	/* Binary tree of globally replaceable constant names */
IncludeFile		*gIncludeFilenames = NULL;
char			cmdline[256];			/* Command line input buffer */
char			*lineptr;			/* pointer to current char in command line */

unsigned char		GetByte(long pc);
long			PopItem(struct PrsAddrStack **stackpointer);
enum atype		SearchArea(DZarea  *currarea, long  pc);
DZarea			*InsertArea(struct area **arealist, long startrange, long  endrange, enum atype	 t);
void			DelExpression(Expression  *node);
void			InitDZ(void);
void			DispVoidAreas(FILE  *out, DZarea *arealist);
void			ReadCollectFile(void);
void			ClearDataStructs(void);
void			AllocZ80Space(void);
void			ParseCommands(void);
void			DeleteIncludeFiles(void);
void			ReadFileBinary(FILE *infile, long Org);
unsigned char	*DecodeAddress(long pc, unsigned char *segm, unsigned short *offset);



/* Read	a byte at the current Disassembler PC */
unsigned char	GetByte(long pc)
{
	unsigned short 	offset;
	unsigned char	segm;

	if ((pc < 0) || (pc > (MAXCODESIZE-1))) {
		puts("PC out of 64K address space!");
		return 255;
	}
	else {
		return *( DecodeAddress(pc, &segm, &offset) );
	}
}


unsigned char	*DecodeAddress(long pc, unsigned char *segm, unsigned short *offset)
{
	*offset = (pc & 0x3FFF);		/* bit 0-14 is offset within a bank */
	*segm = (pc & 0xC000) >> 14;		/* bit 15,16 identifies segment number 0-3 ... */
	/* printf("%04lX = %d, %04X\n", pc, *segm, *offset); */

	return (Segments[*segm] + *offset);	/* return pointer to 16K segment with corresponding offset */
}


void	GetCmdline(void)
{
	fflush(stdin);
	fgets(cmdline,255,stdin);
	lineptr = cmdline;
}


/* User	input of code origin and program calculation of	implicit code size,
 * local and extern code areas.
 */
void	InitDZ(void)
{
	FILE	*infile;

	AllocZ80Space();

	infile = fopen(Z80codeflnm,"rb");		   /* get Z80 code file */
	if (infile == NULL) {
		puts("Code file not found.");
		exit(1);
	}
	fseek(infile, 0L, SEEK_END);	/* file	pointer	to end of file */
	Codesize = ftell(infile);

	printf("Origin of code (hex): "); scanf("%lx", &Org);
	gEndOfCode = Org+Codesize-1;
	if (gEndOfCode > MAXCODESIZE-1) {
		puts("Binary image out of Z80 address space range!");
		fclose(infile);
		exit(1);
	}

	InsertArea(&gAreas, Org, gEndOfCode, vacuum); /* define	local area to be parsed	*/

	if (Org	> 0) InsertArea(&gExtern, 0, Org-1, vacuum);		/* extern area,	before code */
	if (Org+Codesize < MAXCODESIZE-1) InsertArea(&gExtern, (Org+Codesize), MAXCODESIZE-1, vacuum);	/* extern area,	after code */

	printf("Extern areas: "); DispVoidAreas(stdout,	gExtern); putchar('\n');
	printf("Code area to be parsed is %lXh-%lXh\n",	Org, gEndOfCode);

	rewind(infile);				/* file	pointer	to start of file */
	ReadFileBinary(infile, Org);

	fclose(infile);
}


void	DeleteAreas(DZarea  *currarea)
{
	DZarea		*nextarea;

	while(currarea != NULL)	{
		nextarea = currarea->nextarea;
		free(currarea);
		currarea = nextarea;
	}
}


void	DelLabel(LabelRef  *labelptr)
{
	if (labelptr != NULL) {
		if (labelptr->name != NULL) free(labelptr->name);
		free(labelptr);
	}
}

void	DelExpression(Expression  *node)
{
	if (node != NULL) {
		if (node->expr != NULL) free(node->expr);
		free(node);
	}
}


void	DelGlobalConstant(GlobalConstant  *node)
{
	if (node != NULL) {
		if (node->constname != NULL) free(node->constname);
		free(node);
	}
}


void	DelRemark(Remark *itemptr)
{
	Commentline	*curline, *tmpline;

	if (itemptr != NULL) {
		curline = itemptr->comments;
		while(curline != NULL) {
			if (curline->line != NULL) free(curline->line);

			tmpline = curline;
			curline = curline->next;

			free(tmpline);
		}

		/* All comment lines free'd, now release the node itself... */
		free(itemptr);
	}
}


void	DeleteIncludeFiles(void)
{
	IncludeFile *tmp, *curIncludeFile;

	curIncludeFile = gIncludeFilenames;
	while(curIncludeFile != NULL) {
		if (curIncludeFile->filename != NULL) free(curIncludeFile->filename);
		tmp = curIncludeFile->next;
		free(curIncludeFile);
		curIncludeFile = tmp;
	}
}


void	ClearDataStructs(void)
{
	char	s;

	for (s=0; s<=3;s++) free(Segments[s]);

	while(gParseAddress != NULL) PopItem(&gParseAddress);	/* Delete parsing stack	*/

	DeleteAreas(gAreas);
	gAreas = NULL;
	DeleteAreas(gExtern);
	gExtern	= NULL;
	DeleteIncludeFiles();
	gIncludeFilenames = NULL;

	deleteall(&gLabelRef, (void (*)()) DelLabel);
	deleteall(&gRemarks, (void (*)()) DelRemark);
	deleteall(&gExpressions, (void (*)()) DelExpression);
	deleteall(&gGlobalConstants, (void (*)()) DelGlobalConstant);
}


/* Allocate 64K address space in 4 individual 16 segments */
void	AllocZ80Space(void)
{
	char	s;
	short	m;

	for(s=0; s<=3; s++) {
		Segments[s] = (unsigned char *) malloc(16384U);
		/* printf("Segment %d = %08lX\n", s, Segments[s]); */

		if (Segments[s] != NULL) {
			for(m=0; m<16384U; m++) Segments[s][m] = 255;
		} else {
			puts("Insufficient room for Z80 address space");
			for(; s>=0; --s) free(Segments[s]);
			exit(1);
		}
	}
}


int	main (int argc, char *argv[])
{
	FILE	*infile;

	gParseAddress =	NULL;				/* init	address	parsing	stack */
	gLabelRef = NULL;				/* init	label references avltree */
	gAreas = NULL;					/* init	local areas */
	gExtern	= NULL;					/* init	extern areas */
	gRemarks = NULL;
	gExpressions = NULL;
	gGlobalConstants = NULL;
	gIncludeFilenames = NULL;

	printf("%s, V%s\n", _prog_name, _vers);

	Z80codeflnm[0] = '\0';
	collectfilename[0] = '\0';

	while (--argc > 0) {
		++argv;

		if ((*argv)[0] == '-') {
			/* Get options first */
		} else {
			strcpy(Z80codeflnm,*argv);
			break;
		}
	}

	if (strlen(Z80codeflnm) == 0) {
		puts("Binary file not specified.");
		return 0;
	} else {
		strcpy(collectfilename,Z80codeflnm);
		if (strchr(collectfilename,'.') != NULL) *(strchr(collectfilename, '.')) ='\0';
		strcat(collectfilename, ".clt");
	}

	if ((infile = fopen(collectfilename, "r")) != NULL) {
		fclose(infile);
		ReadCollectFile();		/* read	previous parsing info from 'collect' file */
	}
	else
		InitDZ();	/* Input origin	and calculate code boundaries */

	exit_program = false;
	collectfile_changed = false;

	puts("\ntype 'h' or 'help' for list of functionality.");
	do {
		printf("dzasm>");
		GetCmdline();
		ParseCommands();
	}
	while(exit_program == false);

	puts("DZasm ended.");
	return 0;
}


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
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "dzasm.h"
#include "avltree.h"

extern DZarea	*gExtern;		/* list	of extern areas	*/
extern DZarea	*gAreas;		/* list	of areas currently examined */
extern char		*gAreaTypes[];		/* text	identifiers for	area type enumerations */
extern char		Z80codeflnm[];		/* name	of Z80 code file */
extern char		collectfilename[];	/* Filename of collect file related to binary file */
extern char		*gIncludeFiles[];	/* string array	of include filename mnemonics */
extern avltree	*gLabelRef;		/* Binary tree of program labels */
extern avltree	*gRemarks;		/* Binary tree of address comment lines */
extern avltree	*gExpressions;		/* Binary tree of operand expression for Z80 mnemonics */
extern avltree	*gGlobalConstants;	/* Binary tree of globally replaceable constant names */
extern enum truefalse	collectfile_changed, collectfile_available;
extern enum truefalse	gIncludeList[];		/* array of 'touched' (true) include file references */
extern long		Org, Codesize, gEndOfCode;
extern IncludeFile	*gIncludeFilenames;

enum symbols		sym;
enum symbols		ssym[] = {
				space, strconq,	dquote,	squote,	semicolon, comma, fullstop,
				lparen,	lcurly,	rcurly,	rparen,	plus, minus, multiply, divi, mod, power,
				assign,	bin_and, bin_or, bin_xor, less,	greater, log_not, constexpr
			 };

char			separators[] = " &\"\';,.({})+-*/%^=~|:<>!#";
char			ident[256];
short			counter;
FILE			*collect = NULL;

void			AllocZ80Space(void);
void			GenCollectFile(void);
void			ExtAddrItem(LabelRef  *itemptr);
void			LocAddrItem(LabelRef  *itemptr);
void			ExtDataItem(LabelRef *itemptr);
void			LocDataItem(LabelRef *itemptr);
void			ListAreas(DZarea  *currarea);
void			ReadCollectFile(void);
void			GetAreas(DZarea	 **arealist);
void			GetLabelRef(avltree  **avlptr, enum truefalse scope);
void			GetDataRef(avltree  **avlptr, enum truefalse scope);
void			CreateDataRef(avltree  **avlptr, long  labeladdr, char *labelname, enum truefalse  scope);
void			CreateLabelRef(avltree	**avlptr, long	labeladdr, char *labelname, enum truefalse  scope);
void			ListIncludeFiles(void);
void			GetIncludeFiles(void);
void			ListComments(void);
void			ListExpressions(void);
void			ListExpressionItem(Expression *itemptr);
void			GetExpressions(void);
void			GetComments(void);
void			AddExpression(long expraddr, char *exprstr);
void			AddGlobalConstant(long constant, char *conststr);
void			ReadFileBinary(FILE *infile, long Org);
void			ListExplIncludeFiles(void);
void			GetExplIncludefiles(void);
void			ListGlobalConstants(void);
void			GetGlobalConstants(void);
enum atype		GetAreaType(char *ident);
enum symbols		GetSym(void);
long			GetConstant(void);
DZarea			*InsertArea(struct area **arealist, long	 startrange, long  endrange, enum atype	 t);
int			    CmpAddrRef(LabelRef *key, LabelRef *node);
int			    CmpAddrRef2(long *key, LabelRef *node);
LabelRef		*InitLabelRef(long  label, char *labelname);
Remark			*AddRemark(long Address, char pos, char *commentstr);
IncludeFile		*AddIncludeFile(char *inclflnm);
unsigned char	*DecodeAddress(long pc, unsigned char *segm, unsigned short *offset);


/* Create 'collect' file  */
void	GenCollectFile(void)
{
	collect	= fopen(collectfilename,"w");
	if (collect == NULL) {
		puts("Couldn't create/update collect file.");
		return;
	}

	fprintf(collect, "; File:\n{%s}\n\n", Z80codeflnm);

	fputs("; Local Areas:\n", collect);
	ListAreas(gAreas);
	fputs("\n", collect);

	fputs("; External Areas:\n", collect);
	ListAreas(gExtern);
	fputs("\n", collect);

	fputs("; Local Label References:\n{", collect);
	counter	= 0;
	if (gLabelRef != NULL) inorder(gLabelRef, (void	 (*)())	LocAddrItem);
	fputs("\n}\n\n", collect);

	fputs("; External Label References:\n{", collect);
	counter	= 0;
	if (gLabelRef != NULL) inorder(gLabelRef, (void	 (*)())	ExtAddrItem);
	fputs("\n}\n\n", collect);

	fputs("; Local Data References:\n{", collect);
	counter	= 0;
	if (gLabelRef != NULL) inorder(gLabelRef, (void  (*)()) LocDataItem);
	fputs("\n}\n\n", collect);

	fputs("; External Data References:\n{",	collect);
	counter	= 0;
	if (gLabelRef != NULL) inorder(gLabelRef, (void  (*)()) ExtDataItem);
	fputs("\n}\n\n", collect);

	fputs("; Include files referenced in code:\n", collect);
	ListIncludeFiles();

	fputs("; Explicit Include files:\n", collect);
	ListExplIncludeFiles();

	fputs("\n; Comments added to code:\n", collect);
	ListComments();

	fputs("\n; Expressions added to code:\n", collect);
	ListExpressions();

	fputs("\n; Global constants:\n", collect);
	ListGlobalConstants();

	fclose(collect);

	if (collectfile_available == true)
		puts("Collect file updated.");
	else
		puts("Collect file created.");

	collectfile_changed = false;
	collectfile_available = true;
}


void	ExtAddrItem(LabelRef *itemptr)
{
	if (itemptr->local == false && itemptr->addrref == true) {
		if (counter++ %	2 == 0)
			fprintf(collect, "\n$%04lX", itemptr->addr);
		else
			fprintf(collect, ", $%04lX", itemptr->addr);
		if (itemptr->name != NULL) fprintf(collect, " %s", itemptr->name);
	}
}


void	LocAddrItem(LabelRef *itemptr)
{
	if (itemptr->local == true && itemptr->addrref == true) {
		if (counter++ %	2 == 0)
			fprintf(collect, "\n$%04lX", itemptr->addr);
		else
			fprintf(collect, ", $%04lX", itemptr->addr);
		if (itemptr->name != NULL) fprintf(collect, " %s", itemptr->name);
		if (itemptr->xdef == true) fprintf(collect, " +");
	}
}


void	ExtDataItem(LabelRef *itemptr)
{
	if (itemptr->local == false && itemptr->addrref == false) {
		if (counter++ %	2 == 0)
			fprintf(collect, "\n$%04lX", itemptr->addr);
		else
			fprintf(collect, ", $%04lX", itemptr->addr);
		if (itemptr->name != NULL) fprintf(collect, " %s", itemptr->name);
	}
}


void	LocDataItem(LabelRef *itemptr)
{
	if (itemptr->local == true && itemptr->addrref == false) {
		if (counter++ %	2 == 0)
			fprintf(collect, "\n$%04lX", itemptr->addr);
		else
			fprintf(collect, ", $%04lX", itemptr->addr);
		if (itemptr->name != NULL) fprintf(collect, " %s", itemptr->name);
		if (itemptr->xdef == true) fprintf(collect, " +");
	}
}


void	ListAreas(DZarea  *currarea)
{
	short	 items = 0;

	fputs("{", collect);

	while(currarea != NULL)	{
		if (items++ % 2	== 0)
			fprintf(collect, "\n($%04lX, $%04lX %s)",
				currarea->start, currarea->end,	gAreaTypes[currarea->areatype]);
		else
			fprintf(collect, ", ($%04lX, $%04lX %s)",
				currarea->start, currarea->end,	gAreaTypes[currarea->areatype]);

		currarea = currarea->nextarea;
	}

	fputs("\n}\n", collect);
}


void	ReadFileBinary(FILE *infile, long pc)
{
	int		c;
	unsigned short 	offset;
	unsigned char	segm;

	Codesize = 0;
	while((c=fgetc(infile)) != EOF) {
		if (pc < MAXCODESIZE) {
			*( DecodeAddress(pc, &segm, &offset) ) = (unsigned char) c;
			pc++;
			Codesize++;
		} else {
			puts("Binary file truncated at top of 64K address space.");
			break;
		}
	}
}


/* Read	data from collect file to establish previous parsing of	code */
void	ReadCollectFile(void)
{
	FILE		*infile = NULL;
	char		*cptr;
	int			c;

	collect	= fopen(collectfilename, "rb");
	if (collect == NULL) {
		puts("Collect file not found.");
		return;
	}
	else
		puts("Reading collect file...");

	cptr = ident;
	while(GetSym() != lcurly);		/* Get to start	of name	*/
	while((c=fgetc(collect)) != '}') {      /* read filename of collect file */
		*cptr++	= (char) c;
	}
	*cptr =	'\0';
	printf("Filename: %s\n", ident);

	if (strcmp(Z80codeflnm, ident) != 0) {
		puts("Collect file does not belong to binary file");
		fclose(collect);
		exit(1);
	}

	AllocZ80Space();
	strcpy(Z80codeflnm, ident);		/* store to global file	name */

	puts("Reading local areas...");
	GetAreas(&gAreas);
	if (gAreas == NULL) {
		fclose(collect);
		return;
	}

	Org = gAreas->start;

	infile = fopen(Z80codeflnm,"rb");	/* get Z80 code	*/
	if (infile == NULL) {
		printf("'%s' not found.\n", Z80codeflnm);
		fclose(collect);
		return;
	}

	rewind(infile);
	ReadFileBinary(infile, Org);
	gEndOfCode = Org+Codesize-1;

	puts("Reading extern areas...");
	GetAreas(&gExtern);

	puts("Reading local label references...");
	GetLabelRef(&gLabelRef,	true);

	puts("Reading extern label references...");
	GetLabelRef(&gLabelRef,	false);

	puts("Reading local data references...");
	GetDataRef(&gLabelRef, true);

	puts("Reading extern data references...");
	GetDataRef(&gLabelRef, false);

	puts("Reading Include file references...");
	GetIncludeFiles();

	puts("Reading Explicit Include filenames...");
	GetExplIncludefiles();

	puts("Reading Comments...");
	GetComments();

	puts("Reading Expressions...");
	GetExpressions();

	puts("Reading global constants...");
	GetGlobalConstants();

	fclose(collect);
	fclose(infile);

	collectfile_available = true;
	collectfile_changed = false;
}


void	GetLabelRef(avltree  **avlptr, enum truefalse  localscope)
{
	long		labeladdr;
	LabelRef	*foundref;

	while(GetSym() != lcurly);	/* Get to start	of label references */

	GetSym();			/* get first label reference */
	while(sym != rcurly) {
		if (sym==hexconst || sym==decmconst) {
			labeladdr = (unsigned short) GetConstant();

			if (GetSym() ==	name) {
				CreateLabelRef(avlptr, labeladdr, ident, localscope);
				GetSym();
			} else {
				CreateLabelRef(avlptr, labeladdr, NULL, localscope);
			}

			if (sym == plus) {
				if (localscope == true) {
					/* only local references can be declared as global */
					foundref = find(*avlptr, &labeladdr, (int (*)()) CmpAddrRef2);
					foundref->xdef = true;
					foundref->xref = false;
				}

				GetSym();
			}

			if (sym == comma) GetSym();       /* Read past comma to get next constant */
		}
		else {
			puts("Label reference address not identified.");
			break;
		}
	}
}


void	GetDataRef(avltree  **avlptr, enum truefalse  localscope)
{
	long		dataaddr;
	LabelRef	*foundref;

	while(GetSym() != lcurly);	/* Get to start	of data	references */

	GetSym();			/* get first data reference */
	while(sym != rcurly) {
		if (sym==hexconst || sym==decmconst) {
			dataaddr = (unsigned short) GetConstant();

			if (GetSym() ==	name) {
				CreateDataRef(avlptr, dataaddr, ident, localscope);
				GetSym();
			} else {
				CreateDataRef(avlptr, dataaddr, NULL, localscope);
			}
			if (sym == plus) {
				if (localscope == true) {
					/* only local references can be declared as global */
					foundref = find(*avlptr, &dataaddr, (int (*)()) CmpAddrRef2);
					foundref->xdef = true;
					foundref->xref = false;
				}

				GetSym();
			}

			if (sym == comma) GetSym();       /* Read past comma to get next constant */
		}
		else {
			puts("Data reference address not identified.");
			break;
		}
	}
}


void	CreateLabelRef(avltree	**avlptr, long	labeladdr, char *labelname, enum truefalse  localscope)
{
	LabelRef	*newref, *foundref;

	foundref = find(*avlptr, &labeladdr, (int (*)()) CmpAddrRef2);
	if (foundref == NULL) {
		newref = InitLabelRef(labeladdr,labelname);
		if (newref == NULL) {
			puts("No room");
			return;
		}

		newref->local =	localscope;
		newref->xdef = false;
		newref->xref = false;
		newref->referenced = true;
		newref->addrref = true;
		insert(avlptr, newref, (int (*)()) CmpAddrRef);
		collectfile_changed = true;
	}
}


void	CreateDataRef(avltree  **avlptr, long  labeladdr, char *labelname, enum truefalse  localscope)
{
	LabelRef	*newref, *foundref;

	foundref = find(*avlptr, &labeladdr, (int (*)()) CmpAddrRef2);
	if (foundref == NULL) {
		newref = InitLabelRef(labeladdr,labelname);
		if (newref == NULL) {
			puts("No room");
			return;
		}

		newref->local =	localscope;
		newref->xdef = false;
		newref->xref = false;
		newref->referenced = true;
		newref->addrref = false;
		insert(avlptr, newref, (int (*)()) CmpAddrRef);
		collectfile_changed = true;
	}
}


void	ListIncludeFiles(void)
{
	int	i;

	fputs("{\n", collect);

	for (i = 1; i<=20; i++)	{
		if (gIncludeList[i] == true)
			fprintf(collect, "\t+ ; '%s.def'\n", gIncludeFiles[i]);
		else
			fprintf(collect, "\t- ; '%s.def'\n", gIncludeFiles[i]);
	}

	fputs("}\n\n", collect);
}


void	ListRemarkItem(Remark *itemptr)
{
	Commentline	*curline;
	char		*lineptr;

	fprintf(collect, "\t($%04lX,%c", itemptr->addr,itemptr->position);

	curline = itemptr->comments;
	if (curline != NULL) {
		while(curline != NULL) {
			lineptr = curline->line;
			fprintf(collect, " \"");
			while(*lineptr != '\0') {
				if (*lineptr != '\n') fputc(*lineptr, collect);
				lineptr++;
			}
			fprintf(collect, "\"");

			curline = curline->next;
			if (curline != NULL) fprintf(collect, "\n\t\t");
		}
	}

	fprintf(collect, ")\n");
}


void	ListComments(void)
{
	fputs("{\n", collect);

	if (gRemarks !=	NULL) inorder(gRemarks,	(void  (*)()) ListRemarkItem);

	fputs("}\n", collect);
}


void	ListExpressionItem(Expression *itemptr)
{
	char		*lineptr;

	fprintf(collect, "\t($%04lX", itemptr->addr);

	if (itemptr->expr != NULL) {
		fprintf(collect, ",\"");
		lineptr = itemptr->expr;
		while(*lineptr != '\0') {
			if (*lineptr != '\n') fputc(*lineptr, collect);
			lineptr++;
		}
		fprintf(collect, "\"",itemptr->expr);
	}
	fprintf(collect, ")\n");
}


void	ListExplIncludeFiles(void)
{
	IncludeFile	*curIncludeFile;

	fputs("{\n", collect);

	curIncludeFile = gIncludeFilenames;
	while(curIncludeFile != NULL) {
		fprintf(collect, "\t(\"%s\")\n", curIncludeFile->filename);
		curIncludeFile = curIncludeFile->next;
	}

	fputs("}\n", collect);
}


void	ListExpressions(void)
{
	fputs("{\n", collect);

	if (gExpressions != NULL) inorder(gExpressions, (void (*)()) ListExpressionItem);

	fputs("}\n", collect);
}


void	ListGlobalConstant(GlobalConstant *itemptr)
{
	if (counter++ %	8 == 0)
		fprintf(collect, "\n\t$%04lX", itemptr->constantval);
	else
		fprintf(collect, ", $%04lX", itemptr->constantval);
	fprintf(collect, " %s", itemptr->constname);
}


void	ListGlobalConstants(void)
{
	fputs("{\n", collect);

	counter = 0;
	if (gGlobalConstants != NULL) inorder(gGlobalConstants, (void (*)()) ListGlobalConstant);

	fputs("\n}\n", collect);
}


void	GetGlobalConstants(void)
{
	long		constaddr;

	while(GetSym() != lcurly);	/* Get to start	of label references */

	GetSym();			/* get first label reference */
	while(sym != rcurly) {
		if (sym==hexconst || sym==decmconst) {
			constaddr = (unsigned short) GetConstant();

			if (GetSym() ==	name) {
				AddGlobalConstant(constaddr, ident);
				GetSym();
			}

			if (sym == comma) GetSym();       /* Read past comma to get next constant */
		}
		else {
			puts("Global constant address not identified.");
			break;
		}
	}
}


void	GetIncludeFiles(void)
{
	int	i;

	while(GetSym() != lcurly);	/* Get to start	of Include file	references */

	for (i = 1; i<=21; i++)	{
		if (GetSym() ==	rcurly)
			break;
		else {
			switch(sym) {
				case plus:
					gIncludeList[i]	= true;
					break;
				case minus:
					gIncludeList[i]	= false;
					break;
				default:
					puts("Unknown parameter.");
					break;
			}
		}
	}
}


void	GetComments(void)
{
	long	remaddr;
	char	c, i, pos;

	while(GetSym() != lcurly);	/* Get to start	of remark entities */

	while(sym != rcurly) {
		GetSym();
		while(sym == lparen) {	/* get remark entity */
			GetSym();
			if (sym==hexconst || sym==decmconst) {
				remaddr = (unsigned short) GetConstant();

				if (GetSym() ==	comma) {
					GetSym();
					if (sym == less || sym == greater) {
						pos = separators[sym];

						/* read comment lines for this Remark entity... */
						while (GetSym() == dquote) {
							i = 0;
							while((c = fgetc(collect)) != '"') {
								ident[i] = c;
								i++;
							}
							ident[i] = '\0';
							strcat(ident,"\n");

							AddRemark(remaddr, pos, ident);
						}
					} else {
						puts("Remark position not identified.");
						return;
					}
				} else {
					puts("Syntax error in Remark specification.");
					return;
				}
			}
			else {
				puts("Remark address not identified.");
				return;
			}
		}
	}
}


void	GetExpressions(void)
{
	long	expraddr;
	char	c, i;

	while(GetSym() != lcurly);	/* Get to start	of remark entities */

	while(sym != rcurly) {
		GetSym();
		while(sym == lparen) {	/* get remark entity */
			GetSym();
			if (sym==hexconst || sym==decmconst) {
				expraddr = (unsigned short) GetConstant();

				if (GetSym() ==	comma) {
					/* read expression for this entity... */
					while (GetSym() == dquote) {
						i = 0;
						while((c = fgetc(collect)) != '"') {
							ident[i] = c;
							i++;
						}
						ident[i] = '\0';

						AddExpression(expraddr, ident);
					}
				} else {
					puts("Syntax error in Expression specification.");
					return;
				}
			}
			else {
				puts("Expression address not identified.");
				return;
			}
		}
	}
}


void	GetExplIncludefiles(void)
{
	char	c, i;

	while(GetSym() != lcurly);	/* Get to start	of remark entities */

	while(sym != rcurly) {
		GetSym();
		while(sym == lparen) {	/* get include file entity */
			while (GetSym() == dquote) {
				i = 0;
				while((c = fgetc(collect)) != '"') {
					ident[i] = c;
					i++;
				}
				ident[i] = '\0';

				AddIncludeFile(ident);
			}
		}
	}
}


void	GetAreas(DZarea	 **arealist)
{
	long		start, end;
	enum atype	areaid;

	while(GetSym() != lcurly);		/* Get to start	of local areas */

	GetSym();				/* Read	( */
	while(sym != rcurly) {
		if (sym	== lparen) {
			GetSym();
			if (sym==hexconst || sym==decmconst) {
				start =	GetConstant();
				if (GetSym() ==	comma) GetSym();	/* read	past ; */
				if (sym==hexconst || sym==decmconst) {
					end = GetConstant();
					if (GetSym() ==	name) {
						areaid = GetAreaType(ident);
						if (areaid != notfound) {
							InsertArea(arealist, start, end, areaid);
						} else {
							puts("Area name not recognized.");
							return;
						}
					}
					else {
						puts("Missing area name.");
						return;
					}

					if (GetSym() ==	rparen)	{
						if (GetSym() ==	comma) GetSym();       /* Read past comma */
					}
					else {
						puts("Missing ).");
						return;
					}
				}
			}
			else {
				puts("Illegal Constant.");
				return;
			}
		}
		else {
			puts("Area start not identified.");
			return;
		}
	}
}


enum atype	GetAreaType(char  *ident)
{
	enum atype	a;

	for(a =	vacuum;	a<notfound; a++)
		if (strcmp(ident, gAreaTypes[a]) == 0)	return a;

	return notfound;
}


void	Skipline(void)
{
	int	c;

	while ((c=fgetc(collect)) != '\n' && c!=EOF); /* get to	beginning of next line... */
}


enum symbols	GetSym(void)
{
	char	*instr;
	int	c, chcount = 0;

	ident[0] = '\0';

	for (;;) {              /* Ignore leading white spaces, if any... */
		c = fgetc(collect);
		if ((c == EOF) || (c ==	'\x1A')) {
			sym = newline;
			return newline;
		}
		else {
			if (!isspace(c)) break;
		}
	}

	instr =	strchr(separators, c);
	if (instr != NULL) {
		sym = ssym[instr - separators];	/* index of found char in separators[] */
		switch(sym) {
			case	newline:	GetSym();
						return sym;

			case	semicolon:	while(sym == semicolon)	{
							Skipline();	/* ignore comment line,	prepare	for next line */
							GetSym();
						}
						return sym;

			default:		return sym;
		}

	}

	ident[chcount++] = c;
	switch (c) {
		case '$':
			sym = hexconst;
			break;

		case '@':
			sym = binconst;
			break;

		case '#':
			sym = name;
			break;
		case '~':
			sym = decmconst;
			break;

		default:
			if (isdigit(c))
				sym = decmconst;	/* a decimal number found */
			else {
				if (isalpha(c))
					sym = name;	/* an identifier found */
				else
					sym = nil;	/* rubbish ... */
			}
			break;
	}

	/* Read	identifier until space or legal	separator is found */
	if (sym	== name) {
		for (;;) {
			c = fgetc(collect);
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
				ungetc(c, collect);  /*	push character back into stream	for next read */
				break;
			}
		}
	} else
		for (;;) {
			c = fgetc(collect);
			if (!iscntrl(c)	&& (strchr(separators, c) == NULL))
				ident[chcount++] = c;
			else {
				ungetc(c, collect);  /*	puch character back into stream	for next read */
				break;
			}
		}

	ident[chcount] = '\0';
	return sym;
}


long	GetConstant(void)
{
	long		size, l, intresult = 0;
	long		bitvalue = 1;

	if ((sym != hexconst) && (sym != binconst) && (sym != decmconst) && (sym != name)) {
		return -1;		/* syntax error	- illegal constant definition */
	}
	size = strlen(ident);
	if (sym	!= decmconst)
		if ((--size) ==	0) {
			return -1;	/* syntax error	- no constant specified	*/
		}
	switch (ident[0]) {
		case '@':
			if (size > 8) {
				return -1;     /* max 8	bit */
			}
			for (l = 1; l <= size; l++)
				if (strchr("01", ident[l]) == NULL) {
					return -1;
				}
			/* convert ASCII binary	to integer */
			for (l = size; l >= 1; l--) {
				if (ident[l] ==	'1')
					intresult += bitvalue;
				bitvalue <<= 1;	       /* logical shift	left & 16 bit 'adder' */
			}
			return (intresult);

		case '$':
			for (l = 1; l <= size; l++)
				if (isxdigit(ident[l]) == 0) {
					return -1;
				}
			sscanf((char *)	(ident + 1), "%lx", &intresult);
			return (intresult);
		case '~':
			for (l = 1; l <= (size - 1); l++)
				if (isdigit(ident[l]) == 0) {
					return -1;
				}
			return (atol(ident));
		default:
			for (l = 0; l <= size; l++)
				if (isxdigit(ident[l]) == 0) {
					return -1;
				}
			sscanf((char *)	(ident), "%lx", &intresult);
			return (intresult);
	}
}

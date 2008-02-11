
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
#include "dzasm.h"

extern enum truefalse	debug;
extern long		Codesize;
extern DZarea		*gExtern;		/* list	of extern areas	*/
extern DZarea		*gAreas;		/* list	of areas currently examined */
extern enum truefalse	collectfile_changed;

char			*gAreaTypes[] =	{ 	"void", "program", "addrtable", "defw", "defb", "defs",
						"string", "nop", "romhdr", "frontdor", "appldor", "helpdor", "appltopic",
						"infotopic", "mthcommands", "mthhelp", "mthtokens"
					};

DZarea			*InitArea(long	startaddr, long	 endaddr, enum atype  t);
DZarea			*NewArea(void);
void			JoinAreas(DZarea  *currarea);
enum atype		SearchArea(DZarea  *currarea, long  pc);
DZarea			*InsertArea(struct area **arealist, long startrange, long  endrange, enum atype	t);
void			DispAreas(FILE *out, DZarea *arealist);
void			ValidateAreas(DZarea  *currarea);
void			DispVoidAreas(FILE  *out, DZarea *arealist);
float			ResolvedAreas(void);


void	DispAreas(FILE	*out, DZarea *arealist)
{
	DZarea		*currarea;
	int		counter;

	currarea = arealist;		  /* point at first area */
	counter	= 0;

	while(currarea != NULL)	{
		if (counter++ %	3 == 0)	fputc('\n',out);
		fprintf(out, "%04lXh-%04lXh [%s]\t",
			currarea->start, currarea->end,	gAreaTypes[currarea->areatype]);
		currarea = currarea->nextarea;		/* next	area...	*/
	}
}


float	ResolvedAreas(void)
{
	float		totalarea = 0;
	DZarea		*currarea;

	currarea = gAreas;		/* pointer to first area */
	while(currarea != NULL)	{
		if (currarea->areatype != vacuum)
			totalarea += currarea->end - currarea->start + 1;
		currarea = currarea->nextarea;
	}

	return totalarea*100/Codesize;
}


void	DispVoidAreas(FILE  *out, DZarea *arealist)
{
	DZarea		*currarea;
	int		counter;

	currarea = arealist;		/* point at first area */
	counter	= 0;

	while(currarea != NULL)	{
		if (currarea->areatype == vacuum) {
			if (counter++ %	3 == 0)	putchar('\n');
			fprintf(out, "%04lXh-%04lXh [%s]\t",
				currarea->start, currarea->end,	gAreaTypes[currarea->areatype]);
		}
		currarea = currarea->nextarea;		/* area	not found, check next */
	}
	fputc('\n', out);
}



enum atype	SearchArea(DZarea  *currarea, long  pc)
{
	while(currarea != NULL)	{
		if (pc <= currarea->end)
			if (pc >= currarea->start)
				return currarea->areatype;

		currarea = currarea->nextarea;		/* area	not found, check next */
	}

	return notfound;       /* area not found */
}


/* insert area (program	or data) into an area list */
DZarea	*InsertArea(DZarea **arealist, long  startrange, long  endrange, enum atype t)
{
	DZarea	   *newarea, *currarea,	*tmparea;

	newarea	= InitArea(startrange, endrange, t);
	if (newarea==NULL) return NULL;

	if (*arealist==NULL)
		*arealist = newarea;		/* first area in list */
	else {
		currarea = *arealist;		/* point at first subarea */

		for(;;)				/* parse list for entry	of new area */
		{
			if (newarea->start > currarea->end) {
				if (currarea->nextarea == NULL)	{
					/* append newarea to end of list */
					currarea->nextarea = newarea;
					newarea->prevarea = currarea;
					break;	/* exit	search loop */
				}
				else {
					currarea = currarea->nextarea;	/* examine next	sub-area in list */
				}
			}
			else {
				if (newarea->start > currarea->start) {
					if (newarea->end < currarea->end) {
						tmparea	= InitArea(newarea->end+1, currarea->end, currarea->areatype);
						if (tmparea == NULL) {
							free(newarea);	/* Ups - no more room */
							return NULL;
						}

						if (currarea->nextarea != NULL)
							currarea->nextarea->prevarea = tmparea;

						tmparea->nextarea = currarea->nextarea;
						tmparea->prevarea = newarea;		/* new upper bound */

						newarea->nextarea = tmparea;
						newarea->prevarea = currarea;		/* middle inserted */

						currarea->end =	newarea->start-1;
						currarea->nextarea = newarea;		/* lower bound adjusted	*/
					}
					else {
						/* New area end	> current area end */
						if (newarea->end > currarea->end) {
							if (newarea->end == currarea->nextarea->end) {
								currarea->end =	startrange - 1;
								currarea->nextarea->start = startrange;
								free(newarea);		/* remove redundant area */
							}
							else {
								currarea->end =	startrange - 1;
								currarea->nextarea->start = endrange + 1;

								newarea->nextarea = currarea->nextarea;
								currarea->nextarea->prevarea = newarea;

								newarea->prevarea = currarea;
								currarea->nextarea = newarea;
							}
						}
						else {
							newarea->nextarea = currarea->nextarea;
							if (currarea->nextarea != NULL)
								currarea->nextarea->prevarea = newarea;

							currarea->nextarea = newarea;
							newarea->prevarea = currarea;

							currarea->end =	newarea->start - 1;	/* adjust area intervals */
						}
					}

					break;
				}
				else {
					if (newarea->start == currarea->start) {
						if (newarea->end == currarea->end) {
							/* area	size matches, newarea redundant	*/
							free(newarea);
							currarea->areatype = t;
						}
						else {
							if (newarea->end < currarea->end) {
								newarea->nextarea = currarea;	/* insert newarea before current */
								newarea->prevarea = currarea->prevarea;

								if (currarea->prevarea != NULL)
									currarea->prevarea->nextarea = newarea;
								else {
									*arealist = newarea;	/* newarea inserted first in list */
								}
								currarea->prevarea = newarea;	/* newarea now inserted	properly */
								currarea->start	= newarea->end+1;
							}
							else {
								if (newarea->end == currarea->nextarea->end) {

									currarea->nextarea->start = currarea->start;
									currarea->nextarea->areatype = t;

									currarea->nextarea->prevarea = currarea->prevarea;
									if (currarea->prevarea != NULL)
										currarea->prevarea->nextarea = currarea->nextarea;
									else
										*arealist = currarea->nextarea;
									free(currarea);
									free(newarea);		/* remove redundant area */
								}
								else {
									currarea->end =	endrange;
									currarea->areatype = t;
									currarea->nextarea->start = endrange+1;
									free(newarea);
								}
							}
						}
					}
					else {
						newarea->nextarea = currarea;	/* insert newarea before current */
						newarea->prevarea = currarea->prevarea;

						if (currarea->prevarea != NULL)
							currarea->prevarea->nextarea = newarea;
						else {
							*arealist = newarea;	/* newarea inserted first in list */
						}
						currarea->prevarea = newarea;	/* newarea now inserted	properly */

						if (newarea->end > currarea->start)
							currarea->start	= newarea->end+1;	/* adjust for overlap */
					}

					break;
				}
			}
		} /* for */
	}

	collectfile_changed = true;
	return newarea;			/* newarea inserted successfully */
}


/* Join	two equal type areas into a single area	*/
void	JoinAreas(DZarea    *currarea)
{
	DZarea		*tmparea;

	while(currarea != NULL)	{
		while (currarea->nextarea != NULL) {
			tmparea	= currarea->nextarea;
			if (currarea->areatype == tmparea->areatype) {
				/* extend end range next into current */
				/* delete next and adjust pointers in list */

				currarea->end =	tmparea->end;		/* range extended */
				currarea->nextarea = tmparea->nextarea;	/* new nextarea	*/
				if (tmparea->nextarea != NULL)
					tmparea->nextarea->prevarea = currarea;
				free(tmparea);				/* tmparea now redundant */
			}
			else
				break;		/* two areas not equal,	move to	next area */
		}
		currarea = currarea->nextarea;
	}
}


void	ValidateAreas(DZarea  *currarea)
{
	long	pc;

	pc = currarea->start;
	while(currarea != NULL)	{
		if ((pc	> currarea->start) || (pc > currarea->end)) {
			printf("Area range out of order: [%04lXh - %04lXh]\n", currarea->start, currarea->end);
			return;
		}
		if (currarea->start > currarea->end) {
			printf("Illegal range found: [%04lXh - %04lXh]\n", currarea->start, currarea->end);
			return;
		}
		if (currarea->prevarea != NULL)	{
			if ((currarea->start - currarea->prevarea->end)	> 1) {
				printf("Illegal gap found between: [%04lXh - %04lXh] and [%04lXh - %04lXh]\n",
					currarea->prevarea->start, currarea->prevarea->end, currarea->start, currarea->end);
				return;
			}
		}
		pc = currarea->end;
		currarea = currarea->nextarea;		/* area	not found, check next */
	}
}


/* create and initialize an area */
DZarea	*InitArea(long	startaddr, long	 endaddr, enum atype  t)
{
	DZarea	   *narea;

	narea =	NewArea();
	if (narea == NULL) return NULL;

	narea->start = startaddr;
	narea->end = endaddr;
	narea->areatype	= t;
	narea->parsed =	false;
	narea->prevarea	= NULL;
	narea->nextarea	= NULL;
	narea->attributes = NULL;

	return narea;
}


/* create an area */
DZarea	*NewArea(void)
{
	return (DZarea *) malloc(sizeof(DZarea));
}

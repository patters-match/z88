
/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

  Copyright (C) 1991-2008, Gunther Strube, gbs@users.sourceforge.net

  This file is part of Mpm.
  Mpm is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by the Free Software Foundation;
  either version 2, or (at your option) any later version.
  Mpm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License along with Mpm;
  see the file COPYING.  If not, write to the
  Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

  $Id$

 -------------------------------------------------------------------------------------------------*/


#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include "config.h"
#include "datastructs.h"
#include "symtables.h"
#include "exprprsr.h"
#include "modules.h"
#include "pass.h"
#include "errors.h"
#include "z80_prsline.h"


/* local functions */
static void StoreGlobalName (symbol_t * node);
static void StoreLocalName (symbol_t * node);
static void StoreName (symbol_t * node, unsigned long symscope);
static void WriteHeader (void);
static void WriteSymbolTable (char *msg, avltree_t * root);
static void LineCounter (void);
static void PatchListFile (expression_t *pass2expr);
static void StoreLibReference (symbol_t * node);
static void ReleaseFileList(filelist_t *list);
static void ReleasePathList(pathlist_t **plist);
static void ReleaseOwnedFile (usedsrcfile_t *ownedfile);
static sourcefile_t *AllocFile (void);
static sourcefile_t *Setfile (sourcefile_t *curfile, sourcefile_t *newfile, char *fname);
static usedsrcfile_t *AllocUsedFile (void);
static labels_t *AllocAddressItem (void);
static pcrelative_t *AllocJRPC (void);
static pathlist_t *AllocPathNode(void);
static filelist_t *AllocFileListNode (void);
static int Flncmp(char *f1, char *f2);
static void WriteSymbol (symbol_t *n);


/* externally defined variables */
extern FILE *srcasmfile, *errfile, *listfile, *objfile, *mapfile;
extern char copyrightmsg[];
extern char *date, ident[], separators[];
extern char *srcfilename, *lstfilename, *objfilename, *errfilename;
extern enum symbols sym;
extern enum flag createlistingfile, uselistingfile, verbose, writeline;
extern enum flag pass1, symtable, deforigin, EOL;
extern enum flag BIGENDIAN, USEBIGENDIAN;
extern unsigned long PC, oldPC;
extern unsigned long EXPLICIT_ORIGIN;
extern unsigned char *codearea, *codeptr;
extern size_t CODESIZE;
extern int ASSEMBLE_ERROR, ERRORS, WARNINGS;
extern int PAGENO, LINENO, PAGELEN, TOTALERRORS;
extern long listfileptr, TOTALLINES;
extern modules_t *modulehdr;
extern module_t *CURRENTMODULE;
extern avltree_t *globalroot;
extern const char wrnext[];

/* globally defined variables */
labels_t *addresses = NULL;
char line[MAX_LINE_BUFFER_SIZE+1];
int sourcefile_open;
pathlist_t *gIncludePath = NULL;
pathlist_t *gLibraryPath = NULL;


void
GetLine (void)
{
  long fptr;
  int l,c;

  fptr = ftell (srcasmfile);            /* remember file position */

  c = '\0';
  for (l=0; (l<MAX_LINE_BUFFER_SIZE) && (c!='\n'); l++)
    {
      c = GetChar(srcasmfile);
      if (c != EOF)
        line[l] = c;    /* line feed inclusive */
      else
        break;
    }
  line[l] = '\0';

  fseek (srcasmfile, fptr, SEEK_SET);   /* resume file position */
}


/* ----------------------------------------------------------------
   get a character from file with CR/LF/CRLF parsing capability.

   return '\n' byte if a CR/LF/CRLF variation line feed is found.
   ---------------------------------------------------------------- */
int
GetChar (FILE *fptr)
{
  int c;

  c = fgetc (fptr);
  if (c == 13)
    {
      /* Mac line feed found, poll for MSDOS line feed */
      c = fgetc (fptr);
      if (c != 10)
        ungetc (c, fptr); /* push non-line-feed character back into file stream */

      c = '\n'; /* always return the symbolic '\n' for line feed */
    }
  else
    if (c == 10)
      c = '\n'; /* UNIX line feed */

  return c; /* return all other characters */
}


/* ----------------------------------------------------------------------------------------
   static void FetchDependencies (FILE *projectfile, filelist_t **dependencies)

   Fetch a module file dependencies, if they are specified on the same line
   defined with a trailing ':' after the module file name:
        <module filename>: <dependency filename1> <dependency filenameX>

   return pointer to list of dependencies <dependencies> variable, or NULL if no list were
   found
   ---------------------------------------------------------------------------------------- */
static void
FetchDependencies (FILE *projectfile, filelist_t **dependencies)
{
  enum flag dependencySpecified = OFF;
  char tempflnm[MAX_FILENAME_SIZE+1];
  int c;

  for (;;)
    {
      if (feof (projectfile))
        {
          break; /* no dependency filenames in current line... */
        }
      else
        {
          c = GetChar (projectfile);
          switch(c)
          {
            case '\n':
            case '\x1A': /* end of line, no dependencies... */
              return;

            case ';':    /* a comment, skip line and return (no dependencies) */
              EOL = OFF;
              SkipLine(projectfile);
              return;

            case ':':
              /* now, we're ready to parse dependency filenames, until EOL */
              dependencySpecified = ON;
              break;

            default:
              if (!isspace (c) && dependencySpecified == ON)
                { /* found a real char as first of a dependency filename... */
                  ungetc (c, projectfile); /* let Fetchfilename() get the first char.. */

                  Fetchfilename(projectfile, tempflnm);
                  AddFileNameNode (tempflnm, dependencies);

                  /* there might be another dependency file, loop again until EOL */
                }
          }
        }
    }
}


/* ----------------------------------------------------------------------------------------
   void FetchModuleFilename(FILE *projectfile, char *filename, filelist_t **dependencies)

   Fetch a module filename from a project file, @projectfilename, and optionally, the
   dependency files which are listed on the same line defined with a trailing ':' after
   the module file name:
        <module filename>: <dependency filename1> <dependency filenameX>

   Dependencies in a project file are only evaluated if the -d option is used on the
   command line for Mpm.

   Empty lines and comment lines are skipped until a real module filename is found. Then,
   on the same line the dependencies are specified.

   return found filename in <filename> variable (truncated to max MAX_FILENAME_SIZE chars),
   and a pointer to a list of dependencies files if the were specified.
   ---------------------------------------------------------------------------------------- */
void
FetchModuleFilename(FILE *projectfile, char *filename, filelist_t **dependencies)
{
  int c;
  filename[0] = '\0'; /* preset with null-termination, in case no filename was found */

  for (;;)
    {
      if (feof (projectfile))
        {
          break; /* no more module filenames in project file */
        }
      else
        {
          c = GetChar (projectfile);
          switch(c)
          {
               case '\n':
               case '\x1A': /* end of line, get first char on next line */
              break;

            case ';':    /* a comment, skip and prepare for start of next line */
              EOL = OFF; /* always force a line skip in project file */
              SkipLine(projectfile);
              break;

            default:
              if (!isspace (c))
                { /* found a real char as first of a filename... */
                  ungetc (c, projectfile); /* let Fetchfilename() get first char.. */

                  Fetchfilename(projectfile, filename);

                  /* fetch dependencies, if specified with ':' after this file - otherwise skip line */
                  FetchDependencies (projectfile, dependencies);
                  return; /* the line has ended */
                }
          }
        }
    }
}


/* ----------------------------------------------------------------
   Fetch a filename from current file pointer <fptr>, onwards.
   The filename is stored / null-terminated in the buffer <filename>,
   truncated at #define MAX_FILENAME_SIZE chars.

   Terminating character of the filename is a space, EOL or a double quote.

   on return, the file pointer is updated to point at the beginning
   of the next line (or EOF if last line was read).
   ---------------------------------------------------------------- */
void
FetchLinefilename (FILE *fptr, char *filename)
{
    int c;

    Fetchfilename(fptr, filename);

    c = GetChar (fptr);
    if (c != '\n')
        SkipLine (fptr); /* skip rest of line and get ready for first char of next line */
}


/* ----------------------------------------------------------------
   Fetch a filename from current file pointer <fptr>, onwards.
   The filename is stored / null-terminated in the buffer <filename>,
   truncated at MAX_FILENAME_SIZE chars.

   on return, the file pointer <fptr> is at the terminating character
   of the filename, ie. a space, EOL or a double quote.
   ---------------------------------------------------------------- */
void
Fetchfilename (FILE *fptr, char *filename)
{
  int l, c = 0;

  for (l = 0; l<=MAX_FILENAME_SIZE; )
    {
      if (!feof (fptr))
        {
          c = GetChar (fptr);
          if ((c == '\n') || (c == EOF))
            break;

          if (!isspace(c) && c != ':' && c != '"' && c != ';')
            {
              /* read filename until a space, a comment or a double quote */
              /* swallow '#' (old syntax no longer used), but use all other chars in filename */
              if (c != '#') filename[l++] = (char) c;
            }
          else
            {
              break;
            }
        }
      else
        {
          break;                /* fatal - end of file reached! */
        }
    }
  filename[l] = '\0';           /* null-terminate file name string */

  ungetc (c, fptr);             /* evaluate last char by caller... */
}


int
AssembleSourceFile (void)
{
  char *wrnfilename;
  char objhdrprefix[] = "oooomodnexprnamelibnmodc";       /* template of pointers to sections of OBJ file */

  srcasmfile = fopen (AdjustPlatformFilename(srcfilename), "rb");
  sourcefile_open = 1;

  if ((errfile = fopen (AdjustPlatformFilename(errfilename), "w")) == NULL)
    {                           /* Create error file */
      ReportIOError (errfilename);
      return 0;
    }

  if (createlistingfile == ON)
    {
      if ((listfile = fopen (AdjustPlatformFilename(lstfilename), "w+")) != NULL)
        {                       /* Create Listing or symbol file */
          PAGENO = 0;
          LINENO = 6;
          WriteHeader ();                       /* Begin list/symbol file with a header */
          listfileptr = ftell (listfile);       /* Get file pos. of next line in list file */
        }
      else
        {
          ReportIOError (lstfilename);
          return 0;
        }
    }

  if ((objfile = fopen (AdjustPlatformFilename(objfilename), "w+b")) != NULL)           /* Create relocatable object file */
    {
      fwrite (MPMOBJECTHEADER, sizeof (char), strlen (MPMOBJECTHEADER), objfile);
      fwrite (objhdrprefix, sizeof (char), strlen (objhdrprefix), objfile);
    }
  else
    {
      ReportIOError (objfilename);
      return 0;
    }

  if (verbose)
    printf ("Assembling '%s'...\nPass1...\n", srcfilename);

  pass1 = ON;
  SourceFilePass1 ();
  pass1 = OFF;  /* GetSymPtr will only generate page references in Pass1 (if listing file out is enabled) */

  while(addresses != NULL) GetAddress (&addresses);     /* remove label address stack, if allocated... */

  /*
   * Source file no longer needed
   * (file could already have been closed, if fatal error occurred during INCLUDE processing).
   */
  if (sourcefile_open)
    {
      fclose (srcasmfile);
      srcasmfile = NULL;
    }
  if (CURRENTMODULE->mname == NULL)     /* Module name must be defined */
    ReportError (CURRENTFILE->fname, 0, Err_ModNameMissing);

  if (ERRORS == 0)
    {
      if (verbose)
        puts ("Pass2...");
      SourceFilePass2 ();
    }

  if (listfile != NULL)
    {
      fseek (listfile, 0, SEEK_END);
      fputc (12, listfile);     /* end listing file with a Form Feed */
      fclose (listfile);
      listfile = NULL;
      if (ERRORS != 0 && lstfilename != NULL)
        remove (lstfilename);   /* remove incomplete list file */
    }

  fclose (objfile);
  objfile = NULL;

  if (ERRORS != 0 && objfilename != NULL)
    remove (objfilename);       /* remove incomplete object file */

  if (errfile != NULL)
    {
      fclose (errfile);
      errfile = NULL;
      if (ERRORS == 0 && WARNINGS == 0 && errfilename != NULL)
        remove (errfilename);   /* remove empty error file */

      if (ERRORS == 0 && WARNINGS > 0 && errfilename != NULL)
        {
          wrnfilename = AddFileExtension(errfilename, wrnext);
          if (wrnfilename != NULL)
            {
              rename (errfilename, wrnfilename);   /* rename error file as a warning file */
              free(wrnfilename);
            }
        }
    }

  return 1;
}


void
SourceFilePass1 (void)
{
  line[0] = '\0';               /* reset contents of list buffer */

  while (!feof (srcasmfile))
    {
      if (uselistingfile == ON) writeline = ON;
      ParseLine (ON);               /* before parsing it */

      /* If, fatal errors, return immediatly... */
      if (ASSEMBLE_ERROR == Err_Memory || ASSEMBLE_ERROR == Err_MaxCodeSize) return;
    }
}


void
SourceFilePass2 (void)
{
  expression_t *pass2expr, *prevexpr;
  pcrelative_t *curJR, *prevJR;
  long constant;
  long fptr_exprdecl, fptr_namedecl, fptr_modname, fptr_modcode, fptr_libnmdecl;
  unsigned char *patchptr;

  if ((pass2expr = CURRENTMODULE->mexpr->firstexpr) != NULL)
    {
      curJR = CURRENTMODULE->JRaddr->firstref;  /* point at first Jump Relative PC address in this module */
      do
        {
          constant = EvalPfixExpr (pass2expr);
          if (pass2expr->stored == OFF)
            {
              if ((pass2expr->rangetype & SYMXREF) || (pass2expr->rangetype & SYMADDR))
                {
                  /* Expression contains symbol declared as external or defined as a relocatable
                   * address, store expression in relocatable file */
                  switch (pass2expr->rangetype & RANGE)
                    {
                      case RANGE_32SIGN:
                        StoreExpr (pass2expr, 'L');
                        break;

                      case RANGE_16CONST:
                        StoreExpr (pass2expr, 'C');
                        break;

                      case RANGE_16OFFSET:
                        StoreExpr (pass2expr, 'O');
                        break;

                      case RANGE_8UNSIGN:
                        StoreExpr (pass2expr, 'U');
                        break;

                      case RANGE_8SIGN:
                        StoreExpr (pass2expr, 'S');
                        break;
                    }
                }
            }
          if ((pass2expr->rangetype & NOTEVALUABLE) && (pass2expr->stored==OFF))
            {
              if ((pass2expr->rangetype & RANGE) == RANGE_JROFFSET8)
                {
                  if (pass2expr->rangetype & SYMXREF)
                    ReportError (pass2expr->srcfile, pass2expr->curline, Err_ReljumpLocal);   /* Jump Relative used an external label - */
                  else
                    ReportError (pass2expr->srcfile, pass2expr->curline, Err_SymNotDefined);

                  prevJR = curJR;
                  curJR = curJR->nextref;       /* get ready for next Jump Relative instruction */
                  free (prevJR);
                }
              else
                ReportError (pass2expr->srcfile, pass2expr->curline, Err_SymNotDefined);
            }
          else
            {
              patchptr = codearea + pass2expr->codepos;         /* absolute patch pos. in memory buffer */
              switch (pass2expr->rangetype & RANGE)
                {
                  case RANGE_JROFFSET8:
                          constant -= curJR->pcaddr;    /* get module PC at JR instruction */
                          if (constant >= -128 && constant <= 127)
                            {
                              *patchptr = (char) constant;      /* opcode is stored, now store relative jump */
                            }
                          else
                            ReportError (pass2expr->srcfile, pass2expr->curline, 7);
                          prevJR = curJR;
                          curJR = curJR->nextref;       /* get ready for JR instruction */
                          free (prevJR);
                          break;

                  case RANGE_8UNSIGN:
                    *patchptr = (unsigned char) constant; /* opcode is stored, now store byte */
                    break;

                  case RANGE_8SIGN:
                    if (constant >= -128 && constant <= 127)
                      {
                        *patchptr = (char) constant;      /* opcode is stored, now store
                                                           * signed operand */
                      }
                    else
                      ReportError (pass2expr->srcfile, pass2expr->curline, Err_ExprOutOfRange);
                    break;

                  case RANGE_16CONST:
                    if (constant >= -32768 && constant <= 65535)
                      StoreWord((unsigned short) constant, patchptr);
                    else
                      ReportError (pass2expr->srcfile, pass2expr->curline, Err_ExprOutOfRange);
                    break;

                  case RANGE_16OFFSET:
                    if ( (constant < 0) || (constant > 65535) )
                       ReportError (pass2expr->srcfile, pass2expr->curline, Err_ExprOutOfRange);
                    else
                      {
                        StoreWord((unsigned short) constant, patchptr);
                        if (constant >= 16384)
                          ReportWarning (pass2expr->srcfile, pass2expr->curline, Warn_OffsetBoundary);
                      }
                    break;

                  case RANGE_32SIGN:
                    StoreLong (constant, patchptr);
                    break;
                }
            }

          if (listfile != NULL)
            PatchListFile (pass2expr);

          prevexpr = pass2expr;
          pass2expr = pass2expr->nextexpr;      /* get next pass2 expression */
          RemovePfixlist (prevexpr);    /* release current expression */
        }
      while (pass2expr != NULL);        /* re-evaluate expressions and patch in code */

      free (CURRENTMODULE->mexpr);      /* Release header of expressions list */
      free (CURRENTMODULE->JRaddr);     /* Release header of relative jump address list */
      CURRENTMODULE->mexpr = NULL;
      CURRENTMODULE->JRaddr = NULL;
    }

  if ((TOTALERRORS == 0) && (symtable == ON))
    {
      if (createlistingfile == OFF)
        {
          /* create a dedicated *.SYM file for the symbol table, if listing file is not enabled */
          if ((listfile = fopen (AdjustPlatformFilename(lstfilename), "w+")) != NULL)
            {
               PAGENO = 0;
               LINENO = 6;
            }
          else
            {
               ReportIOError (lstfilename);
            }
        }

      if (listfile != NULL)
        {
           WriteSymbolTable ("Local Module Symbols:", CURRENTMODULE->localroot);
           WriteSymbolTable ("Global Module Symbols:", globalroot);
        }
    }

  fptr_namedecl = ftell (objfile);

  /* Store Local Name declarations to relocatable file */
  InOrder (CURRENTMODULE->localroot, (void (*)(void *)) StoreLocalName);

  /* Store Global name declarations to relocatable file */
  InOrder (globalroot, (void (*)(void *)) StoreGlobalName);

  /* Store library reference name declarations to relocatable file */
  fptr_libnmdecl = ftell (objfile);
  InOrder (globalroot, (void (*)(void *)) StoreLibReference);

  fptr_modname = ftell (objfile);
  constant = strlen (CURRENTMODULE->mname);

  fputc (constant, objfile);                  /* write length of module name to relocatable file */
  fwrite (CURRENTMODULE->mname, sizeof (char), (size_t) constant, objfile);     /* write module name to relocatable file */

  if ((constant = codeptr - codearea) == 0)
    fptr_modcode = -1;          /* no code generated!  */
  else
    {
      fptr_modcode = ftell (objfile);
      WriteLong (constant, objfile);                                    /* write module code size (32bit) */
      fwrite (codearea, sizeof (char), (size_t) constant, objfile);     /* then the actual binary code */
    }
  CODESIZE += constant;

  if (verbose)
    printf ("Size of module is %ld bytes\n", constant);

  fseek (objfile, SIZEOF_MPMOBJHDR, SEEK_SET);  /* set file pointer to point at ORG (just after watermark) */
  if ((modulehdr->first == CURRENTMODULE))
    {
      if (deforigin)
        CURRENTMODULE->origin = EXPLICIT_ORIGIN;        /* use origin from command line */
    }
  WriteLong (CURRENTMODULE->origin, objfile);           /* Write Origin (32bit) */

  fptr_exprdecl = SIZEOF_MPMOBJHDR + 4+4+4+4+4+4;       /* distance to expression section... */

  if (fptr_namedecl == fptr_exprdecl)
    fptr_exprdecl = -1;         /* no expressions */
  if (fptr_libnmdecl == fptr_namedecl)
    fptr_namedecl = -1;         /* no name declarations */
  if (fptr_modname == fptr_libnmdecl)
    fptr_libnmdecl = -1;        /* no library reference declarations */

  WriteLong (fptr_modname, objfile);    /* write fptr. to module name */
  WriteLong (fptr_exprdecl, objfile);   /* write fptr. to name declarations */
  WriteLong (fptr_namedecl, objfile);   /* write fptr. to name declarations */
  WriteLong (fptr_libnmdecl, objfile);  /* write fptr. to library name declarations */
  WriteLong (fptr_modcode, objfile);    /* write fptr. to module code */
}


void
Pass2info (expression_t *pfixexpr,      /* pointer to header of postfix expression linked list */
           unsigned long constrange,    /* allowed size of value to be parsed */
           long byteoffset)             /* position in listing file to patch */
{
  if (uselistingfile == ON)
    byteoffset = listfileptr + 16 + 3 * byteoffset + 6 * ((byteoffset) / 32);
  else
    byteoffset = -1;            /* indicate that this expression is not going to be patched in listing file */

  pfixexpr->nextexpr = NULL;
  pfixexpr->rangetype = constrange;
  pfixexpr->srcfile = CURRENTFILE->fname;       /* pointer to record containing current source file name */
  pfixexpr->curline = CURRENTFILE->line;        /* pointer to record containing current line number */
  pfixexpr->listpos = byteoffset;               /* now calculated as absolute file pointer */

  if (CURRENTMODULE->mexpr->firstexpr == NULL)
    {
      CURRENTMODULE->mexpr->firstexpr = pfixexpr;
      CURRENTMODULE->mexpr->currexpr = pfixexpr;        /* Expression header points at first expression */
    }
  else
    {
      CURRENTMODULE->mexpr->currexpr->nextexpr = pfixexpr;      /* Current expr. node points to new expression node */
      CURRENTMODULE->mexpr->currexpr = pfixexpr;                /* Pointer to current expr. node updated */
    }
}



sourcefile_t *
Prevfile (void)
{
  usedsrcfile_t *newusedfile;
  sourcefile_t *ownedfile;

  if ((newusedfile = AllocUsedFile ()) == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      return (CURRENTFILE);                     /* return parameter pointer - nothing happended! */
    }

  ownedfile = CURRENTFILE;
  CURRENTFILE = CURRENTFILE->prevsourcefile;    /* get back to owner file - now the current */
  CURRENTFILE->newsourcefile = NULL;            /* current file is now the last in the list */
  ownedfile->prevsourcefile = NULL;             /* pointer to owner now obsolete... */

  /* set ptr to next record to current ptr to another used file */
  newusedfile->nextusedfile = CURRENTFILE->usedsourcefile;

  CURRENTFILE->usedsourcefile = newusedfile;    /* new used file now inserted into list */
  newusedfile->ownedsourcefile = ownedfile;     /* the inserted record now points to previously owned file */
  return (CURRENTFILE);
}


sourcefile_t *
Newfile (sourcefile_t *curfile, char *fname)
{
  sourcefile_t *nfile;

  if (curfile == NULL)
    {                           /* file record has not yet been created */
      if ((curfile = AllocFile ()) == NULL)
        {
          ReportError (NULL, 0, Err_Memory);
          return (NULL);
        }
      else
        return (Setfile (NULL, curfile, fname));
    }
  else if ((nfile = AllocFile ()) == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      return (curfile);
    }
  else
    return (Setfile (curfile, nfile, fname));
}


sourcefile_t *
FindFile (sourcefile_t *srcfile, char *flnm)
{
  sourcefile_t *foundfile;

  if (srcfile != NULL)
    {
      if ((foundfile = FindFile(srcfile->prevsourcefile, flnm)) != NULL)
        return foundfile;       /* trying to include an already included file recursively! */

      if (Flncmp(srcfile->fname,flnm) == 0)
        return srcfile;         /* this include file already used! */
      else
        return NULL;            /* this include file didn't match filename searched */
    }
  else
    return NULL;
}


void
ReleaseFile (sourcefile_t *srcfile)
{
  if (srcfile->usedsourcefile != NULL)
    ReleaseOwnedFile (srcfile->usedsourcefile);

  if (srcfile->dependencies != NULL)
    ReleaseFileList(srcfile->dependencies);

  free (srcfile->fname);        /* Release allocated area for filename */
  free (srcfile);               /* Release file information record for this file */
}



/*
 * Write current source line to list file with Hex dump of assembled instruction
 */
void
WriteListFileLine (void)
{
  int l, k;

  if (strlen (line) == 0)
    strcpy (line, "\n");

  l = PC - oldPC;       /* get distance of bytes written since last listing file line */
  if (l == 0)
    fprintf (listfile, "%-4d  %08lX%14s%s", CURRENTFILE->line, oldPC, "", line); /* no bytes generated */
  else if (l <= 4)
    {
      fprintf (listfile, "%-4d  %08lX  ", CURRENTFILE->line, oldPC);
      for (; l; l--)
        fprintf (listfile, "%02X ", *(codeptr - l));
      fprintf (listfile, "%*s%s", (unsigned short) (4 - (PC - oldPC)) * 3, "", line);
    }
  else
    {
      while (l)
        {
          LineCounter ();
          if (l)
            fprintf (listfile, "%-4d  %08lX  ", CURRENTFILE->line, (PC - l));
          for (k = (l - 32 > 0) ? 32 : l; k; k--)
            fprintf (listfile, "%02X ", *(codeptr - l--));
          fprintf (listfile, "\n");
        }
      fprintf (listfile, "%18s%s", "", line);
      LineCounter ();
    }
  LineCounter ();                       /* Update list file line counter - check page boundary */
  listfileptr = ftell (listfile);       /* Get file position for beginning of next line in list file */

  oldPC = PC;
}


void
AddAddress (symbol_t *label, labels_t **stackpointer)
{
  labels_t *newitem;

  if ((newitem = AllocAddressItem ()) != NULL)
    {
      newitem->labelsym = label;
      newitem->prevlabel = *stackpointer;       /* link new node to current node */
      *stackpointer = newitem;                  /* update stackpointer to new item */
    }
  else
    ReportError (NULL, 0, Err_Memory);
}



symbol_t *
GetAddress (labels_t **stackpointer)
{

  labels_t *stackitem;
  symbol_t *labelsym;

  labelsym = (*stackpointer)->labelsym;
  stackitem = *stackpointer;
  *stackpointer = (*stackpointer)->prevlabel;           /* Move stackpointer to previous item */
  free (stackitem);                                     /* return old item memory to OS */
  return labelsym;
}


void
NewJRaddr (void)
{
  pcrelative_t *newJRPC;

  if ((newJRPC = AllocJRPC ()) == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      return;
    }
  else
    {
      newJRPC->nextref = NULL;
      newJRPC->pcaddr = PC;
    }

  if (CURRENTMODULE->JRaddr->firstref == NULL)
    {               /* no list yet */
      CURRENTMODULE->JRaddr->firstref = newJRPC;    /* initialise first reference */
      CURRENTMODULE->JRaddr->lastref = newJRPC;
    }
  else
    {
      CURRENTMODULE->JRaddr->lastref->nextref = newJRPC;    /* update last entry with new entry */
      CURRENTMODULE->JRaddr->lastref = newJRPC;             /* point to new entry */
    }
}


static void
StoreGlobalName (symbol_t * node)
{
  if ((node->type & SYMXDEF) && (node->type & SYMTOUCHED))
    StoreName (node, SYMXDEF);
}


static void
StoreLocalName (symbol_t * node)
{
  if ((node->type & SYMLOCAL) && (node->type & SYMTOUCHED))
    StoreName (node, SYMLOCAL);
}


static void
StoreName (symbol_t * node, unsigned long scope)
{
  int b;

  switch (scope)
    {
      case SYMLOCAL:
        fputc ('L', objfile);
        break;

      case SYMXDEF:
        if (node->type & SYMDEF)
          fputc ('X', objfile);
        else
          fputc ('G', objfile);
        break;
    }
  if (node->type & SYMADDR) {    /* then write type of symbol */
    fputc ('A', objfile);        /* either a relocatable 32bit address */
  }
  else {
    fputc ('C', objfile);       /* or a 32bit constant */
  }
  WriteLong (node->symvalue, objfile);

  b = strlen (node->symname);
  fputc (b, objfile);           /* write length of symbol name to relocatable file */
  fwrite (node->symname, sizeof (char), (size_t) b, objfile);   /* write symbol name to relocatable file */
}


static void
StoreLibReference (symbol_t * node)
{
  size_t b;

  if ((node->type & SYMXREF) && (node->type & SYMDEF) && (node->type & SYMTOUCHED))
    {
      b = strlen (node->symname);
      fputc ((int) b, objfile);                                 /* write length of symbol name to relocatable file */
      fwrite (node->symname, sizeof (char), b, objfile);        /* write symbol name to relocatable file */
    }
}


static sourcefile_t *
Setfile (sourcefile_t *curfile,    /* pointer to record of current source file */
         sourcefile_t *nfile,      /* pointer to record of new source file */
         char *filename)           /* pointer to filename string */
{
  if ((nfile->fname = AllocIdentifier (strlen (filename) + 1)) == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      return (nfile);
    }
  nfile->prevsourcefile = curfile;
  nfile->newsourcefile = NULL;
  nfile->usedsourcefile = NULL;
  nfile->dependencies = NULL;
  nfile->filepointer = 0;
  nfile->line = 0;              /* Reset to 0 as line counter during parsing */
  nfile->fname = strcpy (nfile->fname, filename);

  return (nfile);
}


static void
ReleaseOwnedFile (usedsrcfile_t *ownedfile)
{
  /* Release first other files called by this file */
  if (ownedfile->nextusedfile != NULL)
    ReleaseOwnedFile (ownedfile->nextusedfile);

  /* Release first file owned by this file */
  if (ownedfile->ownedsourcefile != NULL)
    ReleaseFile (ownedfile->ownedsourcefile);

  free (ownedfile);             /* Then release this owned file */
}



static int
Flncmp(char *f1, char *f2)
{
   int i;

   if (strlen(f1) != strlen(f2))
     return -1;
   else
     {
       i = strlen(f1);
       while(--i >= 0)
         if( tolower(f1[i]) != tolower(f2[i]) )
           return -1;

       /* filenames equal */
       return 0;
     }
}



static void
PatchListFile (expression_t *pass2expr)
{
  int i;
  unsigned char *cptr;
  long c;

  c = EvalPfixExpr (pass2expr);

  if (pass2expr->listpos == -1)
    return;                     /* listing wasn't switched ON during pass1 */
  else
    {
      fseek (listfile, pass2expr->listpos, SEEK_SET);   /* set file pointer in list file */
      switch (pass2expr->rangetype & RANGE)
        {                       /* look only at range bits */
          case RANGE_8UNSIGN:
          case RANGE_8SIGN:
          case RANGE_JROFFSET8:
            fprintf (listfile, "%02X", (unsigned char) c);
            break;

          case RANGE_16CONST:
          case RANGE_16OFFSET:
            if (USEBIGENDIAN == ON)
              {
                fprintf (listfile, "%02X ", (unsigned short) c / 256);
                fprintf (listfile, "%02X", (unsigned short) c % 256);
              }
            else
              {
                fprintf (listfile, "%02X ", (unsigned short) c % 256);
                fprintf (listfile, "%02X", (unsigned short) c / 256);
              }
            break;

          case RANGE_32SIGN:
            if ((BIGENDIAN == ON && USEBIGENDIAN == ON) || (BIGENDIAN == OFF && USEBIGENDIAN == OFF))
              {
                cptr = (unsigned char *) &c;
                for (i = 0; i <= 3; i++) fprintf (listfile, "%02X ", (unsigned char) cptr[i]);
              }
            else
              {
                /*
                 we are on a Big Endian architecture, but store 32bit integer in Little Endian byte order
                 OR
                 we are on a Little Endian architecture, but store 32bit integer in Big Endian byte order
                */
                cptr = (unsigned char *) &c;
                for (i = 3; i >= 0; i--) fprintf (listfile, "%02X ", (unsigned char) cptr[i]);
              }
            break;
        }
    }
}


static void
LineCounter (void)
{
  if (++LINENO > PAGELEN)
    {
      fprintf (listfile, "\x0C\n");     /* send FORM FEED to file */
      WriteHeader ();
      LINENO = 6;
    }
}


static void
WriteHeader ()
{
  fprintf (listfile, "%s", copyrightmsg);
  fprintf (listfile, "%*.*s", (int) 122 - strlen (copyrightmsg), (int) strlen (date), date);
  fprintf (listfile, "Page %03d%*s'%s'\n\n\n", ++PAGENO, (int) 122 - 9 - 2 - strlen (lstfilename), "", lstfilename);
}


static void
WriteSymbolTable (char *msg, avltree_t * root)
{
  fseek (listfile, 0, SEEK_END); /* get to the end of the listing file */

  LINENO = PAGELEN+1;
  LineCounter();                   /* top of new page */

  fputc ('\n', listfile);
  fprintf (listfile, "%s", msg);
  fputc ('\n', listfile);
  fputc ('\n', listfile);
  LINENO += 4;

  InOrder (root, (void (*)(void *)) WriteSymbol);     /* write symbol table */
}

static void
WriteSymbol (symbol_t *n)
{
  int k;
  pagereference_t *page;

  if (n->owner == CURRENTMODULE)
    {                           /* Write only symbols related to current module */
      if ((n->type & SYMLOCAL) || (n->type & SYMXDEF))
        {
          if (n->type & SYMTOUCHED)
            {
              fprintf (listfile, "%s%*s", n->symname, 32-strlen(n->symname),"");
              fprintf (listfile, "= %08lX", n->symvalue);
              if (n->references != NULL)
                {
                  page = n->references->firstref;
                  fprintf (listfile, " : %3d* ", page->pagenr);
                  page = page->nextref;
                  k = 17;
                  while (page != NULL)
                    {
                      if (k-- == 0)
                        {
                          fprintf (listfile, "\n%45s", "");
                          k = 16;
                          LineCounter ();
                        }
                      fprintf (listfile, "%3d ", page->pagenr);
                      page = page->nextref;
                    }
                }
              fprintf (listfile, "\n");
              LineCounter ();
            }
        }
    }
}



/* ------------------------------------------------------------------------------------------
   FILE *OpenObjectFile(char *filename, char **objversion)

   Open the specified file and evaluate that it is an Z80asm or Mpm generated
   object file. If successfully validated, the opened file handle is returned to the
   caller, and a pointer to the object file watermark type string is returned.
   The file pointer has been positioned at the first byte after the watermark
   (it points at the object module ORIGIN).

   If the object file couldn't be opened or is not recognized,
   a NULL file handle and NULL watermark is returned.
   The routine also reports errors to the global error system for file I/O and
   unrecognized object file.
   ------------------------------------------------------------------------------------------ */
FILE *
OpenObjectFile(char *filename, const char **objversion)
{
  FILE *objf;
  char watermark[64];

  if ((objf = fopen (AdjustPlatformFilename(filename), "rb")) == NULL)
    {
      ReportIOError (filename);
      *objversion = NULL;
      return NULL;
    }
  else
    {
      fread (watermark, 1U, SIZEOF_MPMOBJHDR, objf);     /* try to read Mpm object file watermark */
      watermark[SIZEOF_MPMOBJHDR] = '\0';

      if (strcmp (watermark, MPMOBJECTHEADER) == 0)
        {
          *objversion = MPMOBJECTHEADER;                 /* found Mpm object file */
          return objf;
        }

      fseek (objf, 0, SEEK_SET);
      fread (watermark, 1U, SIZEOF_Z80ASMOBJHDR, objf);  /* try to read Z80asm object file watermark */
      watermark[SIZEOF_Z80ASMOBJHDR] = '\0';
      if (strcmp (watermark, Z80ASMOBJHDR) == 0)
        {
          *objversion = Z80ASMOBJHDR;                    /* found Z80asm V1 object file */
          return objf;
        }
    }

  ReportError (filename, 0, Err_Objectfile);     /* object file was not recognized */
  fclose (objf);
  *objversion = NULL;
  return NULL;
}


/* ------------------------------------------------------------------------------------------
    int StatFile(char *filename, pathlist_t *pathlist, struct stat *pfstat)

    Return the operating system file status information at <pfstat> memory area.
    The filename will be combined with each directory node in <pathlist> and a file
    stat function will be executed.

   Returns:
    -1 if the file was not found in one of the specified <pathlist>.
    0 or 1 and contents filled at <pfstat> location.
   ------------------------------------------------------------------------------------------ */
int
StatFile(char *filename, pathlist_t *pathlist, struct stat *fstat)
{
  char tempflnm[MAX_FILENAME_SIZE+1];
  FILE *filehandle;

  strcpy(tempflnm, filename);
  filehandle = OpenFile(tempflnm, pathlist, ON);
  if (filehandle == NULL)
    /* file was not found */
    return -1;
  else
    {
        fclose(filehandle);
        return stat (tempflnm, fstat);
    }
}


/* ------------------------------------------------------------------------------------------
   FILE *OpenFile(char *filename, pathlist_t *pathlist, enum flag expandfilename)

    The filename will be combined with each directory node in <pathlist> and a file
    open IO function will be executed.

   Returns:
    A file handle, if the file was successfully opened in one of the specified
    directories of <pathlist>, otherwise NULL, if the file wasn't found in
    the <pathlist>.
    The absolute filename of the found file will be written to <filename> string buffer,
    if <expandfilename> argument == ON.
   ------------------------------------------------------------------------------------------ */
FILE *
OpenFile(char *filename, pathlist_t *pathlist, enum flag expandfilename)
{
  char tempflnm[MAX_FILENAME_SIZE+1];
  char tempdirsep[] = {DIRSEP, 0};
  FILE *filehandle;

  filehandle = fopen (AdjustPlatformFilename(filename), "rb");
  if (filehandle != NULL) return filehandle;

  while (pathlist != NULL)
    {
      strcpy(tempflnm, pathlist->directory);
      strcat(tempflnm, tempdirsep);
      strcat(tempflnm, filename);

      filehandle = fopen (AdjustPlatformFilename(tempflnm), "rb");
      if (filehandle != NULL)
        {
          if (expandfilename == ON) strcpy(filename, tempflnm);
          return filehandle;                  /* file was found! */
        }
      else
        pathlist = pathlist->nextdir;         /* file not in this directory, try next ... */
    }

  return NULL;
}


/* ------------------------------------------------------------------------------------------
   char *AddFileExtension(const char *filename, char* extension)

   Allocate a new filename and add/replace with extension.
   Return NULL, if filename couldn't be allocated.
   ------------------------------------------------------------------------------------------ */
char *
AddFileExtension(const char *oldfilename, const char *extension)
{
  char *newfilename;
  int b;
  int pathsepCount = 0;

  if ((newfilename = AllocIdentifier (strlen (oldfilename) + strlen(extension) + 1)) != NULL)
    {
      strcpy (newfilename, oldfilename);

      /* scan filename backwards and find extension, but before a pathname separator */
      for (b=strlen(newfilename)-1; b>=0; b--) {
          if (newfilename[b] == '\\' || newfilename[b] == '/') pathsepCount++; /* Ups, we've scanned past the short filename */

          if (newfilename[b] == '.' && pathsepCount == 0) {
               break; /* we found an extension before a path separator! */
          }
      }

      if (b > 0)
        strcpy ( (newfilename+b), extension); /* replace old extension with new */
      else
        strcat( newfilename, extension);   /* missing extension, concatanate new */
    }

  return newfilename;
}


/* ------------------------------------------------------------------------------------------
   char *AdjustPlatformFilename(char *filename)

   Adjust filename to use the platform specific directory specifier, which is defined as
   DIRSEP in config.h. Adjusting the filename at runtime enables the freedom to not worry
   about paths in filenames when porting Z80 projects to Windows or Unix platforms.

   Example: if a filename contains a '/' (Unix directory separator) it will be converted
   to a '\' if mpm currently is compiling on Windows (or Dos).

   Returns:
   same pointer as argument (beginning of filename)
   ------------------------------------------------------------------------------------------ */
char *
AdjustPlatformFilename(char *filename)
{
   char *flnmptr = filename;

   if (filename == NULL)
     return NULL;

   while(*flnmptr != '\0')
     {
        if (*flnmptr == '/' || *flnmptr == '\\')
          *flnmptr = DIRSEP;

        flnmptr++;
     }

   return filename;
}


/* ------------------------------------------------------------------------------------------
   void AddPathNode (char *path, pathlist_t **plist)

    Scans string <path> for sub paths (separated by ';' or ':' depending on OS) and adds
    them to the path list.

   Returns:
    Updates path list, which is referenced by <plist> pointer.
   ------------------------------------------------------------------------------------------ */
void
AddPathNode (char *path, pathlist_t **plist)
{
  pathlist_t *newnode;
  char *pathcpy, *pathtoken, *newtoken, *newpath;

  if (path == NULL) return;             /* nothing to do - no path has been specified */
  if (strlen(path) == 0) return;        /* nothing to do - path is empty! */

  pathcpy = (char *) malloc (strlen(path)+1);
  if (pathcpy == NULL) return;          /* nothing to do - no memory to add paths to list */

  strcpy(pathcpy, path);
  pathtoken = pathcpy;

  while(pathtoken != NULL)
    {
      newtoken = memchr(pathtoken, ENVPATHSEP, strlen(pathtoken));
      if (newtoken != NULL) *newtoken++ = 0;

      if ((newnode = AllocPathNode()) != NULL)
        {
          newpath = AllocIdentifier (strlen(pathtoken)+1);
          if (newpath != NULL)
            {
              strcpy(newpath, pathtoken);
              /* remove directory separator */
              if (newpath[strlen(newpath) - 1] == DIRSEP) newpath[strlen(newpath) - 1] = '\0';

              newnode->directory = newpath;
              newnode->nextdir = *plist;          /* link new node before current node */
              *plist = newnode;                   /* update start of path list to new node */
            }
          else
            break;                                /* couldn't allocate memory for sub path */
        }
      else {
        ReportError (NULL, 0, Err_Memory);
        break;
      }

      pathtoken = newtoken;      /* get next sub path, if available */
    }

  free(pathcpy);    /* release temp working copy of path argument variable */
}


/* ------------------------------------------------------------------------------------------
   void AddFileNameNode (char *filename, filelist_t **flist)

   Add filename (insert as first) to list of filenames <flist>.
   With initial list, the caller must initialize *flist = NULL.

   Returns:
    Updates filename list, which is referenced by <flist> pointer (start of list).
   ------------------------------------------------------------------------------------------ */
void
AddFileNameNode (char *filename, filelist_t **flist)
{
  filelist_t *newnode;
  char *filenameCpy;

  if (filename == NULL) return;         /* nothing to do - no filename has been specified */
  if (strlen(filename) == 0) return;    /* nothing to do - filename is empty! */

  filenameCpy = (char *) malloc (strlen(filename)+1);
  if (filenameCpy == NULL) return;      /* nothing to do - no memory to add paths to list */
  strcpy(filenameCpy, filename);

  if ((newnode = AllocFileListNode()) != NULL)
    {
      newnode->filename = filenameCpy;
      newnode->nextfile = *flist;         /* link new node before current node */
      *flist = newnode;                   /* update start of list to new node */
    }
  else
    {
      ReportError (NULL, 0, Err_Memory);
    }
}


void ReleasePathInfo(void)
{
  ReleasePathList(&gIncludePath);
  ReleasePathList(&gLibraryPath);
}


static void
ReleaseFileList(filelist_t *list)
{
  filelist_t *node;

  while(list != NULL)
    {
      node = list;
      free(node->filename);   /* release the actual filename string */

      node = node->nextfile;  /* point at next file in list */
      free(list);            /* release this file list node */
      list = node;           /* get ready for releasing the next node */
    }
}


static void
ReleasePathList(pathlist_t **plist)
{
  pathlist_t *node;

  while(*plist != NULL)
    {
      node = *plist;
      free(node->directory);  /* release the actual directory path string */

      node = node->nextdir;   /* point at next path node in list */
      free(*plist);           /* release this path node */
      *plist = node;          /* then get ready for releasing the next node */
    }
}


static labels_t *
AllocAddressItem (void)
{
  return (labels_t *) malloc (sizeof (labels_t));
}


static pathlist_t *
AllocPathNode (void)
{
  return (pathlist_t *) malloc (sizeof (pathlist_t));
}

static filelist_t *
AllocFileListNode (void)
{
  return (filelist_t *) malloc (sizeof (filelist_t));
}


static usedsrcfile_t *
AllocUsedFile (void)
{
  return (usedsrcfile_t *) malloc (sizeof (usedsrcfile_t));
}


static sourcefile_t *
AllocFile (void)
{
  return (sourcefile_t *) malloc (sizeof (sourcefile_t));
}


static pcrelative_t *
AllocJRPC (void)
{
  return (pcrelative_t *) malloc (sizeof (pcrelative_t));     /* allocate new Branch Relative PC address */
}

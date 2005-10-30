
/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

  Copyright (C) 1991-2003, Gunther Strube, gbs@users.sourceforge.net

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
#include "config.h"
#include "datastructs.h"
#include "symtables.h"
#include "exprprsr.h"
#include "libraries.h"
#include "modules.h"
#include "pass.h"
#include "errors.h"


/* local functions */
static pcrelativelist_t *AllocJRaddrHdr (void);
static tracedmodule_t *AllocTracedModule (void);
static tracedmodules_t *AllocLinkHdr (void);
static module_t *AllocModule (void);
static modules_t *AllocModuleHdr (void);
static void ReadExpr (long nextexpr, long endexpr);
static void WriteExprMsg (void);
static void RedefinedMsg (void);
static void ReadNames (long nextname, long endnames);
static void ModuleExpr (void);
static void WriteMapSymbol (symbol_t * mapnode);
static int LinkTracedModule (char *filename, long baseptr);
static void WriteBinFile(char *filename, unsigned char *codebase, size_t length);

/* externally defined variables */
extern FILE *listfile, *mapfile, *srcasmfile, *errfile, *libfile;
extern char line[], ident[];
extern char *objfilename, *errfilename, *libfilename;
extern const char objext[], binext[], segmbinext[], mapext[], errext[], libext[], defext[];
extern char binfilename[];
extern enum symbols sym, GetSym (void);
extern enum flag uselistingfile, symtable, autorelocate, codesegment;
extern enum flag verbose, deforigin, createglobaldeffile, EOL, uselibraries, asmerror, expl_binflnm;
extern unsigned long PC;
extern unsigned long EXPLICIT_ORIGIN;
extern size_t CODESIZE;
extern unsigned char *codearea, PAGELEN;
extern int ASSEMBLE_ERROR, listfileptr;
extern module_t *CURRENTMODULE;
extern int PAGENO, TOTALERRORS;
extern avltree_t *globalroot;
extern symbol_t *gAsmpcPtr;     /* pointer to Assembler PC symbol (defined in global symbol variables) */
extern enum flag BIGENDIAN, USEBIGENDIAN;
extern pathlist_t *gLibraryPath;


/* global variables */
modules_t *modulehdr = NULL;
module_t *CURRENTMODULE;


/* local variables */
static tracedmodules_t *linkhdr;
static FILE *deffile;


static void
ReadNames (long nextname, long endnames)
{
  char scope, symid;
  unsigned long symtype = SYMDEFINED;
  long value;
  symbol_t *foundsymbol;
  symvalue_t symval;

  do
    {
      scope = fgetc (srcasmfile);
      symid = fgetc (srcasmfile);     /* type of name */
      value = ReadLong (srcasmfile);
      ReadName ();                      /* read symbol name */
      nextname += 1 + 1 + 4 + 1 + strlen (line);

      switch (symid)
        {
        case 'A':
          symtype = SYMADDR | SYMDEFINED;
          value += modulehdr->first->origin + CURRENTMODULE->startoffset;   /* Absolute address */
          break;

        case 'C':
          symtype = SYMDEFINED;
          break;
        }

      symval = value;

      switch (scope)
        {
        case 'L':
          if ((foundsymbol = FindSymbol (line, CURRENTMODULE->localroot)) == NULL)
            {
              foundsymbol = CreateSymbol (line, symval, symtype | SYMLOCAL, CURRENTMODULE);
              if (foundsymbol != NULL)
                Insert (&CURRENTMODULE->localroot, foundsymbol, (int (*)()) cmpidstr);
            }
          else
            {
              foundsymbol->symvalue = value;
              foundsymbol->type |= (symtype | SYMLOCAL);
              foundsymbol->owner = CURRENTMODULE;
              RedefinedMsg ();
            }
          break;

        case 'G':
          if ((foundsymbol = FindSymbol (line, globalroot)) == NULL)
            {
              foundsymbol = CreateSymbol (line, symval, symtype | SYMXDEF, CURRENTMODULE);
              if (foundsymbol != NULL)
                Insert (&globalroot, foundsymbol, (int (*)()) cmpidstr);
            }
          else
            {
              foundsymbol->symvalue = value;
              foundsymbol->type |= (symtype | SYMXDEF);
              foundsymbol->owner = CURRENTMODULE;
              RedefinedMsg ();
            }
          break;

        case 'X':
          if ((foundsymbol = FindSymbol (line, globalroot)) == NULL)
            {
              foundsymbol = CreateSymbol (line, symval, symtype | SYMXDEF | SYMDEF, CURRENTMODULE);
              if (foundsymbol != NULL)
                Insert (&globalroot, foundsymbol, (int (*)()) cmpidstr);
            }
          else
            {
              foundsymbol->symvalue = value;
              foundsymbol->type |= (symtype | SYMXDEF | SYMDEF);
              foundsymbol->owner = CURRENTMODULE;
              RedefinedMsg ();
            }

          break;
        }
    }
  while (nextname < endnames);
}


void
ReadExpr (long nextexpr, long endexpr)
{
  char type;
  long offsetptr, constant, i, fptr;
  expression_t *postfixexpr;
  unsigned char *patchptr;

  do
    {
      type = fgetc (srcasmfile);
      offsetptr = ReadLong (srcasmfile);

      /* assembler PC as absolute address */
      PC = modulehdr->first->origin + CURRENTMODULE->startoffset + offsetptr;

      gAsmpcPtr->symvalue = PC;                 /* update assembler program counter */

      i = fgetc (srcasmfile);                   /* get length of infix expression */
      fptr = ftell (srcasmfile);                /* file pointer is at start of expression */
      fgets (line, i + 1, srcasmfile);          /* read string for error reference */
      fseek (srcasmfile, fptr, SEEK_SET);       /* reset file pointer to start of expression */
      nextexpr += 1 + 4 + 1 + i + 1;

      EOL = OFF;                                /* reset end of line parsing flag - a line is to be parsed... */

      GetSym ();

      if ((postfixexpr = ParseNumExpr ()) != NULL)      /* parse numerical expression */
        {
          if (postfixexpr->rangetype & NOTEVALUABLE)
            {
              ReportError (CURRENTFILE->fname, 0, Err_SymNotDefined);
              WriteExprMsg ();
            }
          else
            {
              constant = EvalPfixExpr (postfixexpr);
              patchptr = codearea + CURRENTMODULE->startoffset + offsetptr;     /* absolute patch pos. in memory buffer */
              switch (type)
                {
                case 'U':
                  *patchptr = (unsigned char) constant;
                  break;

                case 'S':
                  if ((constant >= -128) && (constant <= 255))
                    *patchptr = (char) constant;        /* opcode is stored, now store relative jump */
                  else
                    {
                      ReportError (CURRENTFILE->fname, 0, Err_ExprOutOfRange);
                      WriteExprMsg ();
                    }
                  break;

                case 'C':
                  if ((constant >= -32768) && (constant <= 65535))
                      StoreWord ((unsigned short) constant, patchptr);
                  else
                    {
                      ReportError (CURRENTFILE->fname, 0, Err_ExprOutOfRange);
                      WriteExprMsg ();
                    }

                  break;

                case 'O':
                    if ( (constant < 0) || (constant > 65535) )
                      {
                        ReportError (CURRENTFILE->fname, 0, Err_ExprOutOfRange);
                        WriteExprMsg ();
                      }
                    else
                      {
                        StoreWord((unsigned short) constant, patchptr);
                        if (constant >= 16384)
                          {
                            ReportWarning (CURRENTFILE->fname, 0, Warn_OffsetBoundary);
                            WriteExprMsg ();
                          }
                      }
                  break;

                case 'L':
                  StoreLong (constant, patchptr);
                  break;
            }
          RemovePfixlist (postfixexpr);
        }
      }
      else
        WriteExprMsg ();
    }
  while (nextexpr < endexpr);
}


static void
RedefinedMsg (void)
{
  printf ("Symbol <%s> redefined in module '%s'\n", line, CURRENTMODULE->mname);
}



static void
WriteExprMsg (void)
{
  fprintf (errfile, "Error/Warning in expression %s\n\n", line);
}


void
LinkModules (void)
{
  char fheader[128];
  module_t *lastobjmodule;
  long constant;
  int link_error;

  symtable = uselistingfile = OFF;
  linkhdr = NULL;

  if (verbose)
    puts ("Linking module(s)...\nPass1...");

  CURRENTMODULE = modulehdr->first;     /* begin with first module */
  lastobjmodule = modulehdr->last;      /* remember this last module, further modules are libraries */

  errfilename = AddFileExtension((const char *) CURRENTFILE->fname, errext);
  if (errfilename == NULL)
    {
      ReportError (NULL, 0, Err_Memory);   /* No more room */
      return;
    }

  if ((errfile = fopen (errfilename, "a")) == NULL)
    {                                   /* open error file */
      ReportIOError (errfilename);      /* couldn't open error file */
      free (errfilename);
      errfilename = NULL;
      return;
    }

  PC = 0;
  gAsmpcPtr = DefineDefSym (ASSEMBLERPC, PC, &globalroot);    /* Create standard '$PC' identifier */

  if (gAsmpcPtr == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      free (errfilename);
      return;
    }

  if (uselibraries)
    {
      /* Index libraries for quick lookup, before linking starts */
      IndexLibraries();
    }

  do
    {                           /* link machine code & read symbols in all modules */

      CURRENTFILE->line = 0;    /* no line references on errors during linking process */

      objfilename = AddFileExtension((const char *) CURRENTFILE->fname, objext);
      if (objfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      if ((srcasmfile = fopen (objfilename, "rb")) != NULL)
        {                                                       /* open relocatable file for reading */
          fread (fheader, 1U, SIZEOF_MPMOBJHDR, srcasmfile);    /* read watermark from file into array */
          fheader[SIZEOF_MPMOBJHDR] = '\0';
        }
      else
        {
          ReportIOError (objfilename);  /* couldn't open relocatable file */
          break;
        }

      if (strcmp (fheader, MPMOBJECTHEADER) != 0)
        {                       /* compare header of file */
          ReportError (objfilename, 0, Err_Objectfile);
          fclose (srcasmfile);
          srcasmfile = NULL;
          break;
        }

      constant = ReadLong (srcasmfile);     /* get ORIGIN */

      if (modulehdr->first == CURRENTMODULE)
        {                       /* origin of first module */
          if (deforigin)
            CURRENTMODULE->origin = EXPLICIT_ORIGIN;        /* use origin from command line */
          else
            {
              CURRENTMODULE->origin = constant;
              if (CURRENTMODULE->origin == 0xFFFFFFFF)
                DefineOrigin ();    /* Define origin of first module from the keyboard */
            }

          if (verbose == ON)
            printf ("ORG address for code is %04lX\n", CURRENTMODULE->origin);
        }
      fclose (srcasmfile);

      link_error = LinkModule (objfilename, 0);

      free (objfilename);               /* release allocated file name */
      objfilename = NULL;

      CURRENTMODULE = CURRENTMODULE->nextmodule;        /* get next module, if any */
    }
  while (CURRENTMODULE != lastobjmodule->nextmodule && link_error == 0);   /* parse only object modules, not added library modules */

  if (verbose == ON)
    printf ("Code size of linked modules is %d bytes\n", CODESIZE);

  if (asmerror == OFF)
    ModuleExpr ();              /*  Evaluate expressions in all modules */

  if (createglobaldeffile == ON)
    CreateDeffile ();

  ReleaseLinkInfo ();           /* Release module link information */
  fclose (errfile);

  if (TOTALERRORS == 0)
    remove (errfilename);

  free (errfilename);
  errfilename = NULL;
  errfile = NULL;
}


int
LinkModule (char *filename, long fptr_base)
{
  long fptr_namedecl, fptr_modname, fptr_modcode, fptr_libnmdecl;
  size_t size;
  int linklib_error;

  srcasmfile = OpenFile (filename, gLibraryPath, OFF);  /* open object file for reading */
  fseek (srcasmfile, fptr_base + SIZEOF_MPMOBJHDR + 4U, SEEK_SET);  /* get ready to read module name file pointer */

  fptr_modname = ReadLong (srcasmfile);         /* get file pointer to module name */
  ReadLong (srcasmfile);                        /* read past file pointer to expression declarations */
  fptr_namedecl = ReadLong (srcasmfile);        /* get file pointer to name declarations */
  fptr_libnmdecl = ReadLong (srcasmfile);       /* get file pointer to library name declarations */
  fptr_modcode = ReadLong (srcasmfile);         /* get file pointer to module code */

  if (fptr_modcode != -1)
    {
      fseek (srcasmfile, fptr_base + fptr_modcode, SEEK_SET);   /* set file pointer to module code */
      size = ReadLong (srcasmfile);                             /* get 32bit integer code size */
      if (CURRENTMODULE->startoffset + size > MAXCODESIZE)
        {
          ReportError (filename, 0, Err_MaxCodeSize);
          return Err_MaxCodeSize;
        }
      else
        fread (codearea + CURRENTMODULE->startoffset, sizeof (char), size, srcasmfile); /* read module code */

      if (CURRENTMODULE->startoffset == CODESIZE)
        CODESIZE += size;       /* a new module has been added */
    }

  if (fptr_namedecl != -1)
    {
      fseek (srcasmfile, fptr_base + fptr_namedecl, SEEK_SET);  /* set file pointer to point at name declarations */

      if (fptr_libnmdecl != -1)
        ReadNames (fptr_namedecl, fptr_libnmdecl);      /* Read symbols until library declarations */
      else
        ReadNames (fptr_namedecl, fptr_modname);        /* Read symbols until module name */
    }

  fclose (srcasmfile);

  if (fptr_libnmdecl != -1)
    {
      if (uselibraries)
        {                       /* link library modules, if any LIB references are present */
          linklib_error = LinkLibModules (filename, fptr_base, fptr_libnmdecl, fptr_modname);    /* link library modules */
          if (linklib_error != 0)
            return linklib_error;
        }
    }

  return LinkTracedModule (filename, fptr_base);        /* Remember module for pass2 */
}



char *
ReadName (void)
{
  size_t strlength;

  strlength = fgetc (srcasmfile);
  fread (line, sizeof (char), strlength, srcasmfile);   /* read name */
  line[strlength] = '\0';

  return line;
}



static void
ModuleExpr (void)
{
  long fptr_namedecl, fptr_modname, fptr_exprdecl, fptr_libnmdecl;
  long fptr_base;
  tracedmodule_t *curlink;

  if (verbose)
    puts ("Pass2...");

  curlink = linkhdr->firstlink;
  do
    {
      CURRENTMODULE = curlink->moduleinfo;
      fptr_base = curlink->modulestart;

      if ((srcasmfile = OpenFile (curlink->objfilename, gLibraryPath, OFF)) != NULL)
        {
          fseek (srcasmfile, fptr_base + SIZEOF_MPMOBJHDR + 4, SEEK_SET);         /* point at module name file pointer */
          fptr_modname = ReadLong (srcasmfile);                 /* get file pointer to module name */
          fptr_exprdecl = ReadLong (srcasmfile);                /* get file pointer to expression declarations */
          fptr_namedecl = ReadLong (srcasmfile);                /* get file pointer to name declarations */
          fptr_libnmdecl = ReadLong (srcasmfile);               /* get file pointer to library name declarations */
        }
      else
        {
          ReportIOError (curlink->objfilename);         /* couldn't open relocatable file */
          return;
        }

      if (fptr_exprdecl != -1)
        {
          fseek (srcasmfile, fptr_base + fptr_exprdecl, SEEK_SET);
          if (fptr_namedecl != -1)
            ReadExpr (fptr_exprdecl, fptr_namedecl);    /* Evaluate until beginning of name declarations */
          else if (fptr_libnmdecl != -1)
            ReadExpr (fptr_exprdecl, fptr_libnmdecl);   /* Evaluate until beginning of library reference declarations */
          else
            ReadExpr (fptr_exprdecl, fptr_modname);     /* Evaluate until beginning of module name */
        }
      fclose (srcasmfile);

      srcasmfile = NULL;
      curlink = curlink->nextlink;
    }
  while (curlink != NULL);
}


void
CreateBinFile (void)
{
  char *tmpstr;
  char binfilenumber = '0';
  size_t codeblock, offset;

  if (expl_binflnm == ON)
    {
      /* use predefined filename from command line for generated binary */
      tmpstr = AllocIdentifier (strlen(binfilename)+1);
      strcpy (tmpstr, binfilename);
    }
  else
    {
      /* create output filename, based on project filename */
      tmpstr = AddFileExtension( (const char *) modulehdr->first->cfile->fname, binext);
    }
  if (tmpstr == NULL)
    {
      ReportError (NULL, 0, Err_Memory);   /* No more room */
      return;
    }

  if (codesegment == ON)
    {
      if (CODESIZE > 16384)
        {
          /* executable binary larger than 16K, use different extension */
          tmpstr = AddFileExtension( tmpstr, segmbinext);
          offset = 0;
          do
            {
              codeblock = (CODESIZE / 16384U) ? 16384U : CODESIZE % 16384U;
              CODESIZE -= codeblock;
              tmpstr[strlen (tmpstr) - 1] = binfilenumber++;     /* binary 16K block file number */
              WriteBinFile(tmpstr, codearea+offset, codeblock);
              offset += codeblock;
            }
          while (CODESIZE);
        }
      else
        {
           /* split binary option enabled, but code size isn't > 16K */
           WriteBinFile(tmpstr, codearea, CODESIZE);
        }
    }
  else
    {
      /* Dump executable binary as one continous block to file system */
      WriteBinFile(tmpstr, codearea, CODESIZE);
    }

  if (verbose)
    puts ("Code generation completed.");

  free (tmpstr);
}


static void
WriteBinFile(char *filename, unsigned char *codebase, size_t length)
{
  FILE *binaryfile;

  binaryfile = fopen (filename, "wb");    /* binary output to xxxxx.[bin|.bnX] */
  if (binaryfile != NULL)
    {
      fwrite (codebase, sizeof (char), length, binaryfile);   /* write code as one big chunk */
      fclose (binaryfile);
    }
  else
    ReportIOError (filename);
}


static int
LinkTracedModule (char *filename, long baseptr)
{
  tracedmodule_t *newm;
  char *fname;

  if (linkhdr == NULL)
    {
      if ((linkhdr = AllocLinkHdr ()) == NULL)
        {
          ReportError (NULL, 0, Err_Memory);
          return Err_Memory;
        }
      else
        {
          linkhdr->firstlink = NULL;
          linkhdr->lastlink = NULL;     /* library header initialised */
        }
    }

  fname = AllocIdentifier (strlen (filename) + 1);      /* get a Copy module file name */
  if (fname != NULL)
    strcpy (fname, filename);
  else
    {
      ReportError (NULL, 0, Err_Memory);
      return Err_Memory;
    }

  if ((newm = AllocTracedModule ()) == NULL)
    {
      free (fname);             /* release redundant Copy of filename */
      ReportError (NULL, 0, Err_Memory);
      return Err_Memory;
    }
  else
    {
      newm->nextlink = NULL;
      newm->objfilename = fname;
      newm->modulestart = baseptr;
      newm->moduleinfo = CURRENTMODULE;         /* pointer to current (active) module structure */
    }

  if (linkhdr->firstlink == NULL)
    {
      linkhdr->firstlink = newm;
      linkhdr->lastlink = newm; /* First module trace information */
    }
  else
    {
      linkhdr->lastlink->nextlink = newm;       /* current/last linked module points now at new current */
      linkhdr->lastlink = newm;                 /* pointer to current linked module updated */
    }

  return 0; /* indicate "no errors" */
}




/* read long word in Little Endian format from file */
long
ReadLong (FILE * fileid)
{
  int i;
  unsigned long fptr = 0;

  if (BIGENDIAN == ON)
    {
      /* load integer as low byte, byte order into high byte, low byte order internally */
      for (i = 1; i <= 3; i++)
        {
          fptr |= fgetc (fileid) << 24;
          fptr >>= 8;
        }
      fptr |= fgetc (fileid) << 24;
    }
  else
    {
      /* low byte, high byte order...    */
      fread (&fptr, sizeof (long), 1, fileid);
    }

  return fptr;
}


/* write long word in Little Endian Format to file */
void
WriteLong (long fptr, FILE * fileid)
{
  int i;

  if (BIGENDIAN == ON)
    {
      for (i = 0; i < 4; i++)
        {
          fputc (fptr & 255, fileid);
          fptr >>= 8;
        }
     }
   else
     {
       /* low byte, high byte order... */
       fwrite (&fptr, sizeof (fptr), 1, fileid);
     }
}

/* store 16bit word in memory buffer in Endian byte order defined by USEBIGENDIAN flag control */
void
StoreWord (unsigned short w, unsigned char *mptr)
{
  unsigned char *cptr;
  unsigned short *wptr;

  if ((BIGENDIAN == ON && USEBIGENDIAN == ON) || (BIGENDIAN == OFF && USEBIGENDIAN == OFF))
    {
      wptr = (unsigned short *) mptr;
      *wptr = w;
    }
  else
    {
      /*
        we are on a Big Endian architecture, but store 16bit integer in Little Endian byte order
        OR
        we are on a Little Endian architecture, but store 16bit integer in Big Endian byte order
      */
      cptr = (unsigned char *) &w;
      *mptr++ = cptr[1];
      *mptr = cptr[0];
    }
}


/* store long word in memory buffer in Endian byte order defined by USEBIGENDIAN flag control */
void
StoreLong (long lw, unsigned char *mptr)
{
  int i;
  unsigned char *cptr;
  long *lptr;

  if ((BIGENDIAN == ON && USEBIGENDIAN == ON) || (BIGENDIAN == OFF && USEBIGENDIAN == OFF))
    {
      lptr = (long *) mptr;
      *lptr = lw;
    }
  else
    {
      /*
        we are on a Big Endian architecture, but store 32bit integer in Little Endian byte order
        OR
        we are on a Little Endian architecture, but store 32bit integer in Big Endian byte order
      */
      cptr = (unsigned char *) &lw;
      for (i = 3; i >= 0; i--)
        {
          *mptr++ = cptr[i];
        }
    }
}



/* get long word in memory buffer in Endian byte order defined by USEBIGENDIAN flag control */
unsigned long
LoadLong (unsigned char *mptr)
{
  int i;
  unsigned char *cptr;
  long *lptr, lw;

  if ((BIGENDIAN == ON && USEBIGENDIAN == ON) || (BIGENDIAN == OFF && USEBIGENDIAN == OFF))
    {
      lptr = (long *) mptr;
      return *lptr;
    }
  else
    {
        /*
           we are on a Big Endian architecture, but read 32bit integer in Little Endian byte order
           OR
           we are on a Little Endian architecture, but read 32bit integer in Big Endian byte order
        */
        if (USEBIGENDIAN == ON && BIGENDIAN == OFF)
          {
             cptr = (unsigned char *) &lw;
             for (i = 3; i >= 0; i--)
               {
                 cptr[i] = *mptr++;
               }
          }
        if (USEBIGENDIAN == OFF && BIGENDIAN == ON)
          {
            cptr = (unsigned char *) &lw;
            for (i = 3; i >= 0; i--)
              {
                cptr[3-i] = *mptr++;
              }
          }

        return lw;
    }
}

void
DefineOrigin (void)
{
  printf ("ORG not yet defined!\nPlease enter as hexadecimal: ");
  scanf ("%lx", &modulehdr->first->origin);
}



void
CreateDeffile (void)
{
  char *globaldefname;

  /* use first module filename to create global definition file */

  globaldefname = AddFileExtension((const char *) modulehdr->first->cfile->fname, defext);
  if (globaldefname == NULL)
    {
      ReportError (NULL, 0, Err_Memory);   /* No more room */
      createglobaldeffile = OFF;
    }
  else
    {
      if ((deffile = fopen (globaldefname, "w")) != NULL)
        {
            InOrder (globalroot, (void (*)()) WriteGlobal);
            fclose(deffile);
            deffile = NULL;
        }
      else
        {                       /* Create DEFC file with global label declarations */
          ReportIOError (globaldefname);
          createglobaldeffile = OFF;
        }
    }

  free (globaldefname);
}



void
WriteMapFile (void)
{
  avltree_t *maproot = NULL, *newmaproot = NULL;
  module_t *cmodule;
  char *mapfilename;

  cmodule = modulehdr->first;   /* begin with first module */

  mapfilename = AddFileExtension((const char *) cmodule->cfile->fname, mapext);
  if (mapfilename == NULL)
    {
      ReportError (NULL, 0, Err_Memory);   /* No more room */
      return;
    }

  if ((mapfile = fopen (mapfilename, "w")) != NULL)
    {                           /* Create MAP file */
      if (verbose)
        puts ("Creating map...");

      do
        {
          Move (&cmodule->localroot, &maproot, (int (*)()) cmpidstr);   /* Move all local address symbols alphabetically */
          cmodule = cmodule->nextmodule;        /* alphabetically */
        }
      while (cmodule != NULL);

      Move (&globalroot, &maproot, (int (*)()) cmpidstr);       /* Move all global address symbols alphabetically */

      if (maproot == NULL)
        fputs ("None.\n", mapfile);
      else
        {
          InOrder (maproot, (void (*)()) WriteMapSymbol);       /* Write map symbols alphabetically */
          Move (&maproot, &newmaproot, (int (*)()) cmpidval);   /* then re-order symbols numerically */
          fputs ("\n\n", mapfile);

          InOrder (newmaproot, (void (*)()) WriteMapSymbol);    /* Write map symbols numerically */
          DeleteAll (&newmaproot, (void (*)()) FreeSym);        /* then release all map symbols */
        }

      fclose (mapfile);
    }
  else
    {
      ReportIOError (mapfilename);
    }

  free (mapfilename);
}



static void
WriteMapSymbol (symbol_t * mapnode)
{
  if (mapnode->type & SYMADDR)
    {
      fprintf (mapfile, "%s%*s", mapnode->symname, 32-strlen(mapnode->symname),"");
      fprintf (mapfile, "= %08lX, ", mapnode->symvalue);

      if (mapnode->type & SYMLOCAL)
        fputc ('L', mapfile);
      else
        fputc ('G', mapfile);

      fprintf (mapfile, ": %s\n", mapnode->owner->mname);
    }
}



void
WriteGlobal (symbol_t * node)
{
  if ((node->type & SYMADDR) && (node->type & SYMXDEF) && !(node->type & SYMDEF))
    {
      /* Write only global definitions - not library routines */
      fprintf (deffile, "DEFC %s", node->symname);
      fprintf (deffile, " = $%08lX", node->symvalue);
      fprintf (deffile, "; Module %s\n", node->owner->mname);
    }
}


module_t *
NewModule (void)
{
  module_t *newm;

  if (modulehdr == NULL)
    {
      if ((modulehdr = AllocModuleHdr ()) == NULL)
        return NULL;
      else
        {
          modulehdr->first = NULL;
          modulehdr->last = NULL;       /* Module header initialised */
        }
    }
  if ((newm = AllocModule ()) == NULL)
    return NULL;
  else
    {
      newm->nextmodule = NULL;
      newm->mname = NULL;
      newm->startoffset = CODESIZE;
      newm->origin = -1;
      newm->cfile = NULL;
      newm->localroot = NULL;
      newm->notdeclroot = NULL;

      if ((newm->mexpr = AllocExprHdr ()) != NULL)
        {                       /* Allocate room for expression header */
          newm->mexpr->firstexpr = NULL;
          newm->mexpr->currexpr = NULL;         /* Module expression header initialised */
        }
      else
        {
          free (newm);          /* remove partial module definition */
          return NULL;          /* No room for header */
        }

      if ((newm->JRaddr = AllocJRaddrHdr ()) != NULL)
        {
          newm->JRaddr->firstref = NULL;
          newm->JRaddr->lastref = NULL;         /* Module JRaddr list header initialised */
        }
      else
        {
          free (newm->mexpr);   /* remove expression header */
          free (newm);          /* remove partial module definition */
          return NULL;          /* No room for header */
        }
    }

  if (modulehdr->first == NULL)
    {
      modulehdr->first = newm;
      modulehdr->last = newm;   /* First module in list */
    }
  else
    {
      modulehdr->last->nextmodule = newm;       /* current/last module points now at new current */
      modulehdr->last = newm;                   /* pointer to current module updated */
    }

  return newm;
}


void
ReleaseLinkInfo (void)
{
  tracedmodule_t *m, *n;

  if (linkhdr == NULL)
    return;

  m = linkhdr->firstlink;

  do
    {
      if (m->objfilename != NULL)
        free (m->objfilename);

      n = m->nextlink;
      free (m);
      m = n;
    }
  while (m != NULL);

  free (linkhdr);

  linkhdr = NULL;
}


void
ReleaseModules (void)
{
  module_t *tmpptr, *curptr;

  if (modulehdr == NULL)
    return;

  curptr = modulehdr->first;
  do
    {
      if (curptr->cfile != NULL)
        ReleaseFile (curptr->cfile);

      DeleteAll (&curptr->localroot, (void (*)()) FreeSym);
      DeleteAll (&curptr->notdeclroot, (void (*)()) FreeSym);

      if (curptr->mexpr != NULL)
        ReleaseExprns (curptr->mexpr);

      if (curptr->mname != NULL)
        free (curptr->mname);

      tmpptr = curptr;
      curptr = curptr->nextmodule;
      free (tmpptr);            /* Release module */
    }
  while (curptr != NULL);       /* until all modules are released */

  free (modulehdr);
  modulehdr = NULL;
  CURRENTMODULE = NULL;
}


static modules_t *
AllocModuleHdr (void)
{
  return (modules_t *) malloc (sizeof (modules_t));
}


static module_t *
AllocModule (void)
{
  return (module_t *) malloc (sizeof (module_t));
}


static tracedmodules_t *
AllocLinkHdr (void)
{
  return (tracedmodules_t *) malloc (sizeof (tracedmodules_t));
}


static tracedmodule_t *
AllocTracedModule (void)
{
  return (tracedmodule_t *) malloc (sizeof (tracedmodule_t));
}


static pcrelativelist_t *
AllocJRaddrHdr (void)
{
  return (pcrelativelist_t *) malloc (sizeof (pcrelativelist_t));
}

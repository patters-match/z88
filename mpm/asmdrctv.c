
/*
   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM
*/

/*
  Copyright (C) 1991-2003, Gunther Strube

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
*/

/* $Id$ */


#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <limits.h>
#include "config.h"
#include "datastructs.h"
#include "errors.h"
#include "asmdrctv.h"
#include "symtables.h"
#include "exprprsr.h"
#include "pass.h"


/* external functions, assembler specific, <processor>_prsline.c */
extern void ParseLine (enum flag interpret);
extern enum symbols GetSym (void);


/* local functions */
static int idcmp (const char *idptr, const identfunc_t *symptr);
static void AdjustLabelAddresses(unsigned long OrigPC, unsigned long PC);
static long Evallogexpr (void);
static long Parsedefvarsize (long offset);
static long Parsevarsize (void);
static FILE *OpenIncludeFile(char *specfilename);
static void DeclModuleName (void);
static void AlignAddress(long adj);
static void Ifstatement (enum flag interpret);
static int DEFSP (void);


/* externally defined variables, assembler specific, <processor>_asmdrctv.c */
extern identfunc_t directives[];          /* points at table of directive identifiers for this assembler */
extern size_t totaldirectives;            /* total number of directive identifiers for this assembler */

/* externally defined variables */
extern FILE *srcasmfile, *listfile;
extern unsigned char *codeptr, *codearea;
extern char ident[], line[];
extern unsigned long PC, oldPC;
extern enum symbols sym;
extern enum flag verbose, writeline, EOL;
extern modules_t *modulehdr;
extern module_t *CURRENTMODULE;
extern int ASSEMBLE_ERROR;
extern int sourcefile_open;
extern enum flag uselistingfile;
extern labels_t *addresses;
extern pathlist_t *gIncludePath;
extern size_t totalmpmid;
extern identfunc_t mpmident[];


/* local variables */
static char stringconst[255];



void
ParseDirectives (enum flag interpret)
{
  ptrfunc function;

  if ((function = SearchFunction (directives, totaldirectives)) == NULL)
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_UnknownIdent);
      SkipLine (srcasmfile);
    }
  else
    {
      if (function == IFstat)
        {
          if (interpret == OFF)
            SkipLine (srcasmfile);  /* skip current line until EOL */
          Ifstatement (interpret);
        }
      else if ((function == ELSEstat) || (function == ENDIFstat))
        {
          (function)();
          SkipLine (srcasmfile);
        }
      else
        {
          if (interpret == ON) (function)();
          SkipLine (srcasmfile);    /* skip current line until EOL */
        }
    }
}



static int
idcmp (const char *idptr, const identfunc_t *symptr)
{
  return strcmp (idptr, symptr->asm_mnem);
}


ptrfunc
SearchFunction (identfunc_t asmident[], size_t totalid)
{
  identfunc_t *foundsym;

  foundsym = (identfunc_t *) bsearch (ident, asmident, totalid, sizeof (identfunc_t), (fptr) idcmp);

  if (foundsym == NULL)
    return NULL;
  else
    return foundsym->asm_func;
}


void
ParseMpmIdent (enum flag interpret)
{
  ptrfunc function;

  if ((function = SearchFunction (mpmident, totalmpmid)) == NULL)
    {
       /* Mnemonic was not found, try to execute a directive... */
       ParseDirectives (interpret);
    }
  else
    {
      if (interpret == ON) (function)();
      SkipLine (srcasmfile);      /* skip current line until EOL */
    }
}


void
ListingOn (void)
{
  if (listfile != NULL)
    {
      uselistingfile = ON;       /* switch listing ON again... */
      writeline = OFF;           /* but don't write this line to listing file */
    }

  line[0] = '\0';
}



void
ListingOff (void)
{
  if (listfile != NULL)
    uselistingfile = writeline = OFF;        /* but don't write this line to listing file */
  line[0] = '\0';
}



/* dummy function - not used but needed for C compiler & program logic... */
void
IFstat (void)
{
}


void
ELSEstat (void)
{
  sym = elsestatm;
  writeline = OFF;              /* but don't write this line in listing file */
}


void
ENDIFstat (void)
{
  sym = endifstatm;
  writeline = OFF;              /* but don't write this line in listing file */
}


/* multilevel conditional assembly logic */
static void
Ifstatement (enum flag interpret)
{
  if (interpret == ON)
    {                           /* evaluate IF expression */
      if (Evallogexpr () != 0)
        {
          do
            {                   /* expression is TRUE, interpret lines until ELSE or ENDIF */
              if (!feof (srcasmfile))
                {
                  writeline = ON;
                  ParseLine (ON);
                }
              else
                return;         /* end of file - exit from this IF level */
            }
          while ((sym != elsestatm) && (sym != endifstatm));

          if (sym == elsestatm)
            {
              do
                { /* then ignore lines until ENDIF ... */
                  if (!feof (srcasmfile))
                    {
                      writeline = OFF;
                      ParseLine (OFF);
                    }
                  else
                    return;
                }
              while (sym != endifstatm);
            }
        }
      else
        {
          do
            { /* expression is FALSE, ignore until ELSE or ENDIF */
              if (!feof (srcasmfile))
                {
                  writeline = OFF;
                  ParseLine (OFF);
                }
              else
                return;
            }
          while ((sym != elsestatm) && (sym != endifstatm));

          if (sym == elsestatm)
            {
              do
                {
                  if (!feof (srcasmfile))
                    {
                      writeline = ON;
                      ParseLine (ON);
                    }
                  else
                    return;
                }
              while (sym != endifstatm);
            }
        }
    }
  else
    {
      do
        { /* don't evaluate IF expression and ignore all lines until ENDIF */
          if (!feof (srcasmfile))
            {
              writeline = OFF;
              ParseLine (OFF);
            }
          else
            return;             /* end of file - exit from this IF level */
        }
      while (sym != endifstatm);
    }

  sym = nil;
}


static long
Evallogexpr (void)
{
  expression_t *postfixexpr;
  long constant = 0;

  GetSym ();                    /* get logical expression */
  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      constant = EvalPfixExpr (postfixexpr);
      RemovePfixlist (postfixexpr);     /* remove linked list, expression evaluated */
    }
  return constant;
}


static void
AlignAddress(long align)
{
  unsigned long OrigPC;
  long adjustment, remainder;

  remainder = PC % align;
  if (remainder != 0) /* Is it necessary to align? */
    {
      adjustment = align-remainder;

      if ((PC+adjustment) > MAXCODESIZE)
        {
           ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
           return;
        }
      else
        {
           OrigPC = PC;
           while(adjustment--)
             {
               *codeptr++ = 0;  /* pad adjustment with null bytes */
               ++PC;
             }

           AdjustLabelAddresses(OrigPC,PC);
        }
    }
}


void ALIGN(void)
{
  expression_t *postfixexpr;
  long constant;

  GetSym ();                    /* get numerical expression */

  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      if (postfixexpr->rangetype & NOTEVALUABLE)
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          constant = EvalPfixExpr (postfixexpr);     /* ALIGN expression must not contain undefined symbols */
          if (constant >= 0 && constant < 17)
            AlignAddress(constant);                     /* Align the codeptr and PC according to value */
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprOutOfRange);
        }
      RemovePfixlist (postfixexpr);
    }
}


void
DeclGlobalIdent (void)
{
  do
    {
      if (GetSym () == name)
        DeclSymGlobal (ident, 0);
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          return;
        }
    }
  while (GetSym () == comma);

  if (sym != newline)
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}



void
DeclGlobalLibIdent (void)
{
  if (GetSym () == name)
    {
      DeclModuleName ();        /* XLIB name is implicit MODULE name */
      DeclSymGlobal (ident, SYMDEF);
    }
  else
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
      return;
    }
}



void
DeclExternIdent (void)
{
  do
    {
      if (GetSym () == name)
        DeclSymExtern (ident, 0);       /* Define symbol as extern */
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          return;
        }
    }
  while (GetSym () == comma);

  if (sym != newline)
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}



void
DeclLibIdent (void)
{
  do
    {
      if (GetSym () == name)
        DeclSymExtern (ident, SYMDEF);  /* Define symbol as extern LIB reference */
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          return;
        }
    }
  while (GetSym () == comma);

  if (sym != newline)
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}



void
DeclModule (void)
{
  GetSym ();
  DeclModuleName ();
}


static long
Parsevarsize (void)
{
  expression_t *postfixexpr;
  long offset = 0, varsize, size_multiplier;

  if (strcmp (ident, "DS") != 0)
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
  else
    {
      if ((varsize = DEFSP ()) == -1)
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_UnknownIdent);
      else
        {
          GetSym ();

          if ((postfixexpr = ParseNumExpr ()) != NULL)
            {
              if (postfixexpr->rangetype & NOTEVALUABLE)
                {
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
                  RemovePfixlist (postfixexpr);
                }
              else
                {
                  size_multiplier = EvalPfixExpr (postfixexpr);
                  RemovePfixlist (postfixexpr);
                  if (size_multiplier > 0 && size_multiplier <= MAXCODESIZE)
                    offset = varsize * size_multiplier;
                  else
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
                }
            }
        }
    }

  return offset;
}



static long
Parsedefvarsize (long offset)
{
  long varoffset = 0;

  switch (sym)
    {
    case name:
      if (strcmp (ident, "DS") != 0)
        {
          DefineSymbol (ident, (symvalue_t) offset, 0);
          GetSym();
        }
      if (sym == name)
          varoffset = Parsevarsize ();
      break;

    default:
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
    }

  return varoffset;
}



void
DEFVARS (void)
{
  expression_t *postfixexpr;
  long offset;

  writeline = OFF;              /* DEFVARS definitions are not output'ed to uselistingfile file */
  GetSym ();

  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {                           /* expr. must not be stored in relocatable file */
      if (postfixexpr->rangetype & NOTEVALUABLE)
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
          RemovePfixlist (postfixexpr);
          return;
        }
      else
        {
          offset = EvalPfixExpr (postfixexpr);  /* offset expression must not contain undefined symbols */
          RemovePfixlist (postfixexpr);
        }
    }
  else
    return;                     /* syntax error - get next line from file... */

  while (!feof (srcasmfile) && sym != lcurly)
    {
      SkipLine (srcasmfile);

      EOL = OFF;
      ++CURRENTFILE->line;
      GetSym ();
    }

  if (sym == lcurly)
    {
      while (!feof (srcasmfile) && GetSym () != rcurly)
        {
          if (EOL == ON)
            {
              ++CURRENTFILE->line;
              EOL = OFF;
            }
          else
            offset += Parsedefvarsize (offset);
        }
    }
}



void
DEFGROUP (void)
{
  expression_t *postfixexpr;
  long enumconst = 0;

  writeline = OFF;              /* DEFGROUP definitions are not output'ed to listing file */

  while (!feof (srcasmfile) && GetSym () != lcurly)
    {
      SkipLine (srcasmfile);
      EOL = OFF;
      ++CURRENTFILE->line;
    }

  if (sym == lcurly)
    {
      while (!feof (srcasmfile) && sym != rcurly)
        {
          if (EOL == ON)
            {
              ++CURRENTFILE->line;
              EOL = OFF;
            }
          else
            {
              do
                {
                  GetSym ();
                  switch (sym)
                    {
                    case rcurly:
                    case semicolon:
                    case newline:
                      break;

                    case name:
                      strcpy (stringconst, ident);      /* remember name */
                      if (GetSym () == assign)
                        {
                          GetSym ();

                          if ((postfixexpr = ParseNumExpr ()) != NULL)
                            {
                              if (postfixexpr->rangetype & NOTEVALUABLE)
                                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
                              else
                                {
                                  enumconst = EvalPfixExpr (postfixexpr);
                                  DefineSymbol (stringconst, enumconst++, 0);
                                }
                              RemovePfixlist (postfixexpr);
                            }
                          GetSym ();    /* prepare for next identifier */
                        }
                      else {
                        DefineSymbol (stringconst, enumconst++, 0);
                      }
                      break;

                    default:
                      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
                      break;
                    }
                }
              while (sym == comma);     /* get enum definitions separated by comma in current line */

              SkipLine (srcasmfile);    /* ignore rest of line */
            }
        }
    }
}


/* DEFS <size> [(<byte>)] */
void
DEFS ()
{
  expression_t *sizeexpr, *byteexpr;
  long constant, byte;

  GetSym ();                    /* get numerical expression */
  if ((sizeexpr = ParseNumExpr ()) != NULL)
    {                           /* expr. must not be stored in relocatable file */
      if (sizeexpr->rangetype & NOTEVALUABLE)
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          constant = EvalPfixExpr (sizeexpr);

          if (constant < 0)
            {
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprOutOfRange);
            }
          else
            {
              if ((PC + constant) > MAXCODESIZE)
                {
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
                }
              else
                {
                  PC += constant;
                  byte = 0;     /* use 0 as default padding byte */

                  if (sym == lparen)
                    {
                      GetSym();
                      if ((byteexpr = ParseNumExpr ()) != NULL)
                        {                           /* expr. must not be stored in relocatable file */
                          if (byteexpr->rangetype & NOTEVALUABLE)
                            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
                          else
                            {
                              byte = EvalPfixExpr (byteexpr);
                              if (byte < 0 || byte > 255)
                                {
                                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprOutOfRange);
                                }
                            }

                            RemovePfixlist (byteexpr);     /* remove linked list, expression evaluated */
                        }
                    }

                  while (constant--) *codeptr++ = byte;
                }
            }
        }

      RemovePfixlist (sizeexpr);     /* remove linked list, expression evaluated */
    }
}



void
DefSym (void)
{
  do
    {
      if (GetSym () == name) {
        DefineDefSym (ident, 1, &CURRENTMODULE->localroot);
      } else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          break;
        }
    }
  while (GetSym () == comma);
}


void
DEFC (void)
{
  expression_t *postfixexpr;
  long constant;

  do
    {
      if (GetSym () == name)
        {
          strcpy (stringconst, ident);  /* remember name */

          if (GetSym () == assign)
            {
              GetSym ();        /* get numerical expression */
              if ((postfixexpr = ParseNumExpr ()) != NULL)
                {               /* expr. must not be stored in
                                   * relocatable file */
                  if (postfixexpr->rangetype & NOTEVALUABLE)
                    {
                      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
                      break;
                    }
                  else
                    {
                      constant = EvalPfixExpr (postfixexpr);    /* DEFC expression must not contain undefined symbols */
                      DefineSymbol (stringconst, constant, 0);
                    }
                  RemovePfixlist (postfixexpr);
                }
              else
                break;          /* syntax error - get next line from file... */
            }
          else
            {
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
              break;
            }
        }
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          break;
        }
    }
  while (sym == comma);         /* get all DEFC definition separated by comma */
}



void
ORG (void)
{

  expression_t *postfixexpr;
  unsigned long orgaddr;

  GetSym ();                    /* get numerical expression */

  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      if (postfixexpr->rangetype & NOTEVALUABLE)
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          orgaddr = EvalPfixExpr (postfixexpr);        /* ORG expression must not contain undefined symbols */
          CURRENTMODULE->origin = orgaddr;
        }
      RemovePfixlist (postfixexpr);
    }
}


void
DEFB (void)
{
  long bytepos = 0;

  do
    {
      if ((PC+1) > MAXCODESIZE)
        {
           ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
           return;
        }

      GetSym ();
      if (!ExprUnsigned8 (bytepos))
        break;                  /* syntax error - get next line from file... */
      ++PC;                     /* DEFB allocated, update assembler PC */
      ++bytepos;

      if (sym == newline)
        break;
      else if (sym != comma)
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          break;
        }
    }
  while (sym == comma);         /* get all DEFB definitions separated by comma */
}



void
DEFW (void)
{
  long bytepos = 0;

#if ALIGN_ADRESSES == 1
  AlignAddress(2);              /* make sure that 16bit words are address aligned before actually creating them */
  bytepos += (PC-oldPC);        /* adjust for automatic address alignment */
#endif

  do
    {
      if ((PC+2) > MAXCODESIZE)
        {
           ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
           return;
        }

      GetSym ();
      if (!ExprAddr16 (bytepos))
        break;                  /* syntax error - get next line from file... */
      PC += 2;                  /* DEFW allocated, update assembler PC */
      bytepos += 2;

      if (sym == newline)
        break;
      else if (sym != comma)
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          break;
        }
    }
  while (sym == comma);         /* get all DEFB definitions separated by comma */
}


/* Z88 specific feature: a 24bit pointer; 16 offset within bank, then bank number */
void
DEFP (void)
{
  long bytepos = 0;

  do
    {
      if ((PC+3) > MAXCODESIZE)
        {
           ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
           return;
        }

      GetSym ();
      if (!ExprAddr16 (bytepos))
        break;                  /* syntax error - get next line from file... */
      PC += 2;                  /* DEFW allocated, update assembler PC */
      bytepos += 2;

      if (sym != comma)
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          break;
        }
      else
        {
          GetSym ();
          if (!ExprUnsigned8 (bytepos))
            break;                  /* syntax error - get next line from file... */
          ++PC;                     /* Bank number allocated, update assembler PC */
          ++bytepos;
        }
    }
  while (sym == comma);         /* get all DEFP definitions separated by comma */
}


void
DEFL (void)
{
  long bytepos = 0;

#if ALIGN_ADRESSES == 1
  AlignAddress(4);              /* make sure that 32bit words are address aligned before actually creating them */
  bytepos += (PC-oldPC);        /* adjust for automatic address alignment */
#endif

  do
    {
      if ((PC+4) > MAXCODESIZE)
        {
           ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
           return;
        }

      GetSym ();
      if (!ExprLong (bytepos))
        break;                  /* syntax error - get next line from file... */
      PC += 4;                  /* DEFL allocated, update assembler PC */
      bytepos += 4;

      if (sym == newline)
        break;
      else if (sym != comma)
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          break;
        }
    }
  while (sym == comma);         /* get all DEFB definitions separated by comma */
}



void
ASCII(enum flag nullterminate)
{
  long constant, bytepos = 0;

  do
    {
      if (GetSym () == dquote)
        {
          while (!feof (srcasmfile))
            {
              if ((PC+1) > MAXCODESIZE)
                {
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
                  return;
                }

              constant = GetChar (srcasmfile);
              if (constant == EOF)
                {
                  sym = newline;
                  EOL = ON;
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
                  return;
                }
              else
                {
                  if (constant != '\"')
                    {
                      *codeptr++ = (unsigned char) constant;
                      ++bytepos;
                      ++PC;
                    }
                  else
                    {
                      GetSym ();

                      if (sym != strconq && sym != comma && sym != newline && sym != semicolon)
                        {
                          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
                          return;
                        }
                      break;    /* get out of loop */
                    }
                }
            }
        }
      else
        {
          if ((PC+1) > MAXCODESIZE)
            {
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
              return;
            }

          if (!ExprUnsigned8 (bytepos))
            break;              /* syntax error - get next line from file... */

          if (sym != strconq && sym != comma && sym != newline && sym != semicolon)
            {
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);   /* expression separator not found */
              break;
            }
          ++bytepos;
          ++PC;
        }
    }
  while (sym != newline && sym != semicolon);

  if (nullterminate == ON)
    {
      if ((PC+1) <= MAXCODESIZE)
        {
           *codeptr++ = 0;
           ++PC;
        }
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);
        }
    }
}


void
DEFM (void)
{
        ASCII(OFF);
}


void
DEFMZ (void)
{
        ASCII(ON);
}


/* ---------------------------------------------------------------
   Size specifiers
     DS.B = 8 bit
     DS.W = 16 bit ('Word')
     DS.P = 24 bit ('Pointer')
     DS.L = 32 bit ('Long')
   --------------------------------------------------------------- */
static int
DEFSP (void)
{
  if (GetSym () == fullstop)
    if (GetSym () == name)
      switch (ident[0])
        {
          case 'B':
            return 1;

          case 'W':
            return 2;

          case 'P':
            return 3;

          case 'L':
            return 4;

          default:
            return -1;
        }
    else
      {
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        return -1;
      }
  else
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
      return -1;
    }
}


void
IncludeFile (void)
{
  if (GetSym () == dquote)
    {                           /* fetch filename of include file */
      Fetchfilename (srcasmfile, ident);

      CURRENTFILE->filepointer = ftell (srcasmfile);    /* remember file position of current source file */
      fclose (srcasmfile);

      if ((srcasmfile = OpenIncludeFile(ident)) == NULL)
        {                       /* Open include file */
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_FileIO);
          srcasmfile = fopen (CURRENTFILE->fname, "rb");                /* re-open current source file */
          fseek (srcasmfile, CURRENTFILE->filepointer, SEEK_SET);       /* file position to beginning of line
                                                                         * following INCLUDE line */
          return;
        }
      else
        {
          sourcefile_open = 1;
          CURRENTFILE = Newfile (CURRENTFILE, ident);   /* Allocate new file into file information list */

          if (ASSEMBLE_ERROR == Err_Memory) return;     /* No room... */

          if (verbose)
            puts (CURRENTFILE->fname);  /* display name of INCLUDE file */

          SourceFilePass1 ();           /* parse include file */

          CURRENTFILE = Prevfile ();    /* Now get back to current file... */

          switch (ASSEMBLE_ERROR)
            {
            case Err_FileIO:
            case Err_Memory:
            case Err_MaxCodeSize:
              return;           /* Fatal errors, return immediatly... */
            }

          sourcefile_open = fclose (srcasmfile);

          if ((srcasmfile = fopen (CURRENTFILE->fname, "rb")) == NULL)
            {                   /* re-open current source file */
              ReportIOError(CURRENTFILE->fname);
            }
          else
            {
              fseek (srcasmfile, CURRENTFILE->filepointer, 0);  /* file position to beginning of */
              sourcefile_open = 1;
            }
        }     /* line following INCLUDE line */
    }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);

  sym = newline;
  writeline = OFF;    /* don't write current source line to listing file (empty line of INCLUDE file) */
}


static FILE *
OpenIncludeFile(char *specfilename)
{
  FILE *fh;

  fh = OpenFile(specfilename, gIncludePath, ON);
  if (fh != NULL)
    {
      if (FindFile(CURRENTFILE, specfilename) != NULL)
        {
          /* Ups - this file has already been INCLUDE'ed */
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IncludeFile);
          fclose(fh);
          fh = NULL;
        }
    }

  return fh;
}



void
BINARY (void)
{
  FILE *binfile;
  long Codesize;

  if (GetSym () == dquote)
    {
      Fetchfilename (srcasmfile, ident);

      if ((binfile = fopen (ident, "rb")) == NULL)
        {
          ReportIOError (ident);
          return;
        }

      fseek(binfile, 0L, SEEK_END); /* file pointer to end of file */
      Codesize = ftell(binfile);
      fseek(binfile, 0L, SEEK_SET); /* file pointer to start of file */

      if ((codeptr - codearea + Codesize) <= MAXCODESIZE)
        {
          fread (codeptr, sizeof (char), Codesize, binfile);     /* read binary code */
          codeptr += Codesize;                                   /* codeptr updated */
          PC += Codesize;
        }
      else
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize);

      fclose (binfile);
    }
   else
     ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}



static void
DeclModuleName (void)
{
  if (CURRENTMODULE->mname == NULL)
    {
      if (sym == name)
        {
          if ((CURRENTMODULE->mname = AllocIdentifier (strlen (ident) + 1)) != NULL)
            strcpy (CURRENTMODULE->mname, ident);
          else
            ReportError (NULL, 0, Err_Memory);
        }
      else
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
    }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ModNameDefined);
}



static void
AdjustLabelAddresses(unsigned long OrigPC, unsigned long NewPC)
{
    symbol_t *lbl;

    while(addresses != NULL)
      {
        lbl = GetAddress (&addresses);
        if (lbl->symvalue - OrigPC == 0)
          lbl->symvalue = NewPC;
        else
          break;  /* this label address were smaller than OrigPC */
      }           /* (declared two or more times before previous label definition */
}

/* -------------------------------------------------------------------------------------------------

    MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
     MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
     MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
     MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
     MMMM       MMMM     PPPP              MMMM       MMMM
     MMMM       MMMM     PPPP              MMMM       MMMM
    MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

                          ZZZZZZZZZZZZZZ    888888888888        000000000
                        ZZZZZZZZZZZZZZ    8888888888888888    0000000000000
                                ZZZZ      8888        8888  0000         0000
                              ZZZZ          888888888888    0000         0000
                            ZZZZ          8888        8888  0000         0000
                          ZZZZZZZZZZZZZZ  8888888888888888    0000000000000
                        ZZZZZZZZZZZZZZ      888888888888        000000000


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

  $Id$

 -------------------------------------------------------------------------------------------------*/


#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <limits.h>
#include "config.h"
#include "datastructs.h"
#include "exprprsr.h"
#include "asmdrctv.h"
#include "errors.h"


/* external functions, assembler specific, <processor>_prsline.c */
extern enum symbols GetSym (void);


/* Z80 specific functions */
static void CALLOZ (void);
static void CALLPKG (void);
static void FPP (void);


/* externally defined variables */
extern char ident[], line[];
extern unsigned char *codeptr;
extern module_t *CURRENTMODULE;
extern unsigned char *codeptr;
extern unsigned long PC;


/* Directive names, as defined for Zilog Z80 standard conventions, including a few 'additions' */
identfunc_t directives[] = {
 {"ALIGN", ALIGN},
 {"ASCII", DEFM},
 {"ASCIIZ", DEFMZ},
 {"BINARY", BINARY},
 {"BYTE", DEFB},
 {"CALL_OZ", CALLOZ},
 {"CALL_PKG", CALLPKG},
 {"DB", DEFB},
 {"DC", DEFC},
 {"DEFB", DEFB},
 {"DEFC", DEFC},
 {"DEFGROUP", DEFGROUP},
 {"DEFINE", DefSym},
 {"DEFL", DEFL},
 {"DEFM", DEFM},
 {"DEFMZ", DEFMZ},
 {"DEFP", DEFP},
 {"DEFS", DEFS},
 {"DEFSYM", DefSym},
 {"DEFVARS", DEFVARS},
 {"DEFW", DEFW},
 {"DL", DEFL},
 {"DM", DEFM},
 {"DMZ", DEFM},
 {"DP", DEFP},
 {"DS", DEFS},
 {"DV", DEFVARS},
 {"DW", DEFW},
 {"ELSE", ELSEstat},
 {"ENDIF", ENDIFstat},
 {"ENUM", DEFGROUP},
 {"ERROR", ERROR},
 {"EXTERN", DeclExternIdent},
 {"FPP", FPP},
 {"GLOBAL", DeclGlobalIdent},
 {"IF", IFstat},
 {"INCLUDE", IncludeFile},
 {"LIB", DeclLibIdent},
 {"LIBRARY", DeclLibIdent},
 {"LONG", DEFL},
 {"LSTOFF", ListingOff},
 {"LSTON", ListingOn},
 {"MODULE", DeclModule},
 {"ORG", ORG},
 {"OZ", CALLOZ},
 {"SPACE", DEFS},
 {"STRING", DEFS},
 {"VARAREA", DEFVARS},
 {"WORD", DEFW},
 {"XDEF", DeclGlobalIdent},
 {"XLIB", DeclGlobalLibIdent},
 {"XREF", DeclExternIdent}
};

size_t totaldirectives = 52;


static void
CALLOZ (void)
{
  long constant;
  expression_t *postfixexpr;

  if ((PC+3) > MAXCODESIZE)
    {
       ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize); /* No room for instruction */
       return;
    }

  *codeptr++ = 231;     /* RST 20H instruction */
  ++PC;

  if (GetSym () == lparen)
    GetSym ();          /* Optional parenthesis around expression */

  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      if (postfixexpr->rangetype & NOTEVALUABLE)
         /* CALL_OZ expression must be evaluable */
         ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          constant = EvalPfixExpr (postfixexpr);
          if ((constant > 0) && (constant <= 255))
            {
              *codeptr++ = constant;    /* 1 byte OZ parameter */
              ++PC;
            }
          else if ((constant > 255) && (constant <= 65535))
            {
              *codeptr++ = constant & 255;  /* 2 byte OZ parameter */
              *codeptr++ = constant >> 8;
              PC += 2;
            }
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
        }

      RemovePfixlist (postfixexpr); /* remove linked list, because expr. was evaluated */
    }
}


static void
CALLPKG (void)
{
  long constant;
  expression_t *postfixexpr;

  if ((PC+3) > MAXCODESIZE)
    {
       ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize); /* No room for instruction */
       return;
    }

  *codeptr++ = 0xCF;        /* RST 08H instruction */
  ++PC;

  if (GetSym () == lparen)
    GetSym ();          /* Optional parenthesis around expression */

  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      if (postfixexpr->rangetype & NOTEVALUABLE)
        /* CALL_PKG expression must be evaluable */
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          constant = EvalPfixExpr (postfixexpr);
          if ((constant >= 0) && (constant <= 65535))
            {
              *codeptr++ = constant % 256;
              *codeptr++ = constant / 256;
              PC += 2;
            }
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
        }

      RemovePfixlist (postfixexpr); /* remove linked list because expr. was evaluated */
    }
}



static void
FPP (void)
{
  long constant;
  expression_t *postfixexpr;

  if ((PC+2) > MAXCODESIZE)
    {
       ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_MaxCodeSize); /* No room for instruction */
       return;
    }

  *codeptr++ = 223;     /* RST 18H instruction */
  ++PC;

  if (GetSym () == lparen)
    GetSym ();          /* Optional parenthesis around expression */

  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      if (postfixexpr->rangetype & NOTEVALUABLE)
        /* FPP expression must be evaluable */
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          constant = EvalPfixExpr (postfixexpr);
          if ((constant > 0) && (constant < 255))
            {
              *codeptr++ = constant;    /* 1 byte OZ parameter */
              ++PC;
            }
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
        }

      RemovePfixlist (postfixexpr); /* remove linked list, because expr. was evaluated */
    }
}

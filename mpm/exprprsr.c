
/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

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
#include <limits.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <float.h>
#include <math.h>
#include "config.h"
#include "datastructs.h"
#include "exprprsr.h"
#include "errors.h"
#include "symtables.h"
#include "modules.h"
#include "pass.h"


/* external functions, assembler specific, <processor>_prsline.c */
extern void ParseLine (enum flag interpret);
extern enum symbols GetSym (void);
extern long GetConstant (char *evalerr);


/* local functions */
static void PushItem (long oprconst, pfixstack_t **stackpointer);
static long PopItem (pfixstack_t **stackpointer);
static void CalcExpression (enum symbols opr, pfixstack_t **stackptr);
static int Condition (expression_t *pfixexpr);
static int Expression (expression_t *pfixexpr);
static int Term (expression_t *pfixexpr);
static int Pterm (expression_t *pfixexpr);
static int Factor (expression_t *pfixexpr);
static expression_t *AllocExpr (void);
static void NewPfixSymbol (expression_t *pfixexpr, long oprconst, enum symbols oprtype, char *symident, unsigned long type);
static pfixstack_t *AllocStackItem (void);
static postfixexpr_t *AllocPfixSymbol (void);
static long Pw (long x, long y);


/* global variables */
extern module_t *CURRENTMODULE;
extern avltree_t *globalroot;
extern enum symbols sym, ssym[], pass1;
extern enum flag uselistingfile;
extern char ident[], separators[];
extern unsigned char *codearea, *codeptr;
extern unsigned long PC, oldPC;
extern FILE *srcasmfile, *objfile;



expression_t *
ParseNumExpr (void)
{
  expression_t *pfixhdr;
  enum symbols constant_expression = nil;

  if ((pfixhdr = AllocExpr ()) == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      return NULL;
    }
  else
    {
      pfixhdr->firstnode = NULL;
      pfixhdr->currentnode = NULL;
      pfixhdr->rangetype = 0;
      pfixhdr->stored = OFF;
      pfixhdr->codepos = codeptr - codearea;

      if ((pfixhdr->infixexpr = (char *) malloc(256)) == NULL)
        {
          ReportError (NULL, 0, Err_Memory);
          free (pfixhdr);
          return NULL;
        }
      else
        pfixhdr->infixptr = pfixhdr->infixexpr;         /* initialise pointer to start of buffer */
    }

  if (sym == constexpr)
    {
      GetSym ();                /* leading '?' : ignore relocatable address expression */
      constant_expression = constexpr;  /* convert to constant expression */
      *pfixhdr->infixptr++ = separators[constexpr];
    }

  if (Condition (pfixhdr))
    {                           /* parse expression... */
      if (constant_expression == constexpr)
        NewPfixSymbol (pfixhdr, 0, constexpr, NULL, 0); /* convert to constant expression */

      pfixhdr->infixptr = '\0';
      return pfixhdr;
    }
  else
    {
      RemovePfixlist (pfixhdr);
      return NULL;              /* syntax error in expression or no room */
    }                           /* for postfix expression */
}


long
EvalPfixExpr (expression_t *pfixlist)
{
  pfixstack_t *stackptr = NULL;
  postfixexpr_t *pfixexpr;
  symbol_t *symptr;

  pfixlist->rangetype &= EVALUATED;     /* prefix expression as evaluated */
  pfixexpr = pfixlist->firstnode;       /* initiate to first node */

  do
    {
      switch (pfixexpr->operatortype)
        {
        case number:
          if (pfixexpr->id == NULL)     /* Is operand an identifier? */
            PushItem (pfixexpr->operandconst, &stackptr);
          else
            {                   /* symbol was not defined and not declared */
              if (pfixexpr->type != SYM_NOTDEFINED)
                {               /* if all bits are set to zero */
                  if (pfixexpr->type & SYMLOCAL)
                    {
                      symptr = FindSymbol (pfixexpr->id, CURRENTMODULE->localroot);
                      pfixlist->rangetype |= (symptr->type & SYMTYPE);  /* Copy appropriate type
                                                                         * bits */
                      PushItem (symptr->symvalue, &stackptr);
                    }
                  else
                    {
                      symptr = FindSymbol (pfixexpr->id, globalroot);
                      if (symptr != NULL)
                        {
                          pfixlist->rangetype |= (symptr->type & SYMTYPE);      /* Copy appropriate type
                                                                                 * bits */
                          if (symptr->type & SYMDEFINED)
                            PushItem (symptr->symvalue, &stackptr);
                          else
                            {
                              pfixlist->rangetype |= NOTEVALUABLE;
                              PushItem (0, &stackptr);
                            }
                        }
                      else
                        {
                          pfixlist->rangetype |= NOTEVALUABLE;
                          PushItem (0, &stackptr);
                        }
                    }
                }
              else
                { /* try to Find symbol now as either */

                  symptr = GetSymPtr (pfixexpr->id);    /* declared local or global */
                  if (symptr != NULL)
                    {
                      pfixlist->rangetype |= (symptr->type & SYMTYPE);  /* Copy appropriate type bits */
                      if (symptr->type & SYMDEFINED)
                        PushItem (symptr->symvalue, &stackptr);
                      else
                        {
                          pfixlist->rangetype |= NOTEVALUABLE;
                          PushItem (0, &stackptr);
                        }
                    }
                  else
                    {
                      pfixlist->rangetype |= NOTEVALUABLE;
                      PushItem (0, &stackptr);
                    }
                }
            }
          break;

        case negated:
          stackptr->stackconstant = -stackptr->stackconstant;
          break;

        case log_not:
          stackptr->stackconstant = !(stackptr->stackconstant);
          break;

        case bin_not:
          stackptr->stackconstant = ~(stackptr->stackconstant);
          break;

        case div256:
          stackptr->stackconstant = stackptr->stackconstant / 256;
          break;

        case mod256:
          stackptr->stackconstant = stackptr->stackconstant % 256;
          break;

        case constexpr:
          pfixlist->rangetype &= CLEAR_EXPRADDR;            /* convert to constant expression */
          break;

        default:
          CalcExpression (pfixexpr->operatortype, &stackptr);   /* expression requiring two operands */
          break;
        }

      pfixexpr = pfixexpr->nextoperand;         /* get next operand in postfix expression */
    }
  while (pfixexpr != NULL);

  if (stackptr != NULL)
    return PopItem (&stackptr);
  else
    return 0;  /* Unbalanced stack - probably during low memory... */
}


void
RemovePfixlist (expression_t *pfixexpr)
{
  postfixexpr_t *node, *tmpnode;

  if (pfixexpr == NULL)
    return;

  node = pfixexpr->firstnode;
  while (node != NULL)
    {
      tmpnode = node->nextoperand;
      if (node->id != NULL)
        free (node->id);        /* Remove symbol id, if defined */

      free (node);
      node = tmpnode;
    }

  if (pfixexpr->infixexpr != NULL)
    free (pfixexpr->infixexpr); /* release infix expr. string */

  free (pfixexpr);              /* release header of postfix expression */
}


int
ExprLong (int listoffset)
{

  expression_t *pfixexpr;
  long constant;
  int flag = 1;

  if ((pfixexpr = ParseNumExpr ()) != NULL)
    {                           /* parse numerical expression */
      if ((pfixexpr->rangetype & SYMXREF) || (pfixexpr->rangetype & SYMADDR))
        /* expression contains external reference or address label, must be recalculated during linking */
        StoreExpr (pfixexpr, 'L');

      if (pfixexpr->rangetype & SYMXREF)
        RemovePfixlist (pfixexpr);
      else
        {
          if ((pfixexpr->rangetype & SYMADDR) && (uselistingfile == OFF))
            /* expression contains address label */
            RemovePfixlist (pfixexpr);  /* no listing file - evaluate during linking... */
          else
            {
              if (pfixexpr->rangetype & NOTEVALUABLE)
                Pass2info (pfixexpr, RANGE_32SIGN, listoffset);
              else
                {
                  constant = EvalPfixExpr (pfixexpr);
                  RemovePfixlist (pfixexpr);
                  StoreLong (constant, codeptr);
                }
            }
        }
    }
  else
    flag = 0;

  codeptr += 4;
  return flag;
}



int
ExprAddr16 (int listoffset)
{
  expression_t *pfixexpr;
  long constant;
  int flag = 1;

  if ((pfixexpr = ParseNumExpr ()) != NULL)
    {                           /* parse numerical expression */
      if ((pfixexpr->rangetype & SYMXREF) || (pfixexpr->rangetype & SYMADDR))
        /* expression contains external reference or address label, must be recalculated during linking */
        StoreExpr (pfixexpr, 'C');

      if (pfixexpr->rangetype & SYMXREF)
        RemovePfixlist (pfixexpr);
      else
        {
          if ((pfixexpr->rangetype & SYMADDR) && (uselistingfile == OFF))
            /* expression contains address label */
            RemovePfixlist (pfixexpr);  /* no listing file - evaluate during linking... */
          else
            {
              if (pfixexpr->rangetype & NOTEVALUABLE)
                Pass2info (pfixexpr, RANGE_16CONST, listoffset);
              else
                {
                  constant = EvalPfixExpr (pfixexpr);
                  RemovePfixlist (pfixexpr);
                  if (constant >= -32768 && constant <= 65535)
                    StoreWord((unsigned short) constant, codeptr);
                  else
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
                }
            }
        }
    }
  else
    flag = 0;

  codeptr += 2;
  return flag;
}


int
ExprOffset16 (int listoffset)
{
  expression_t *pfixexpr;
  long constant;
  int flag = 1;

  if ((pfixexpr = ParseNumExpr ()) != NULL)
    {                           /* parse numerical expression */
      if ((pfixexpr->rangetype & SYMXREF) || (pfixexpr->rangetype & SYMADDR))
        /* expression contains external reference or address label, must be recalculated during linking */
        StoreExpr (pfixexpr, 'O');

      if (pfixexpr->rangetype & SYMXREF)
        RemovePfixlist (pfixexpr);
      else
        {
          if ((pfixexpr->rangetype & SYMADDR) && (uselistingfile == OFF))
            /* expression contains address label */
            RemovePfixlist (pfixexpr);  /* no listing file - evaluate during linking... */
          else
            {
              if (pfixexpr->rangetype & NOTEVALUABLE)
                Pass2info (pfixexpr, RANGE_16OFFSET, listoffset);
              else
                {
                  constant = EvalPfixExpr (pfixexpr);
                  RemovePfixlist (pfixexpr);
                  if ( (constant < 0) || (constant > 65535) )
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
                  else
                    {
                      StoreWord((unsigned short) constant, codeptr);
                      if (constant >= 16384)
                        ReportWarning (CURRENTFILE->fname, CURRENTFILE->line, Warn_OffsetBoundary);
                    }
                }
            }
        }
    }
  else
    flag = 0;

  codeptr += 2;
  return flag;
}


int
ExprUnsigned8 (int listoffset)
{
  expression_t *pfixexpr;
  long constant;
  int flag = 1;

  if ((pfixexpr = ParseNumExpr ()) != NULL)
    {                           /* parse numerical expression */
      if ((pfixexpr->rangetype & SYMXREF) || (pfixexpr->rangetype & SYMADDR))
        /* expression contains external reference or address label, must be recalculated during linking */
        StoreExpr (pfixexpr, 'U');

      if (pfixexpr->rangetype & SYMXREF)
        RemovePfixlist (pfixexpr);
      else
        {
          if ((pfixexpr->rangetype & SYMADDR) && (uselistingfile == OFF))
            /* expression contains address label */
            RemovePfixlist (pfixexpr);  /* no listing file - evaluate during linking... */
          else
            {
              if (pfixexpr->rangetype & NOTEVALUABLE)
                Pass2info (pfixexpr, RANGE_8UNSIGN, listoffset);
              else
                {
                  constant = EvalPfixExpr (pfixexpr);
                  RemovePfixlist (pfixexpr);
                  if ((constant < -128) || (constant > 255))
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
                  else
                    *codeptr = (unsigned char) constant;
                }
            }
        }
    }
  else
    flag = 0;

  ++codeptr;
  return flag;
}



int
ExprSigned8 (int listoffset)
{
  expression_t *pfixexpr;
  long constant;
  int flag = 1;

  if ((pfixexpr = ParseNumExpr ()) != NULL)
    {                           /* parse numerical expression */
      if ((pfixexpr->rangetype & SYMXREF) || (pfixexpr->rangetype & SYMADDR))
        /* expression contains external reference or address label, must be recalculated during linking */
        StoreExpr (pfixexpr, 'S');

      if (pfixexpr->rangetype & SYMXREF)
        RemovePfixlist (pfixexpr);
      else
        {
          if ((pfixexpr->rangetype & SYMADDR) && (uselistingfile == OFF))
            /* expression contains address label */
            RemovePfixlist (pfixexpr);  /* no listing file - evaluate during linking... */
          else
            {
              if (pfixexpr->rangetype & NOTEVALUABLE)
                Pass2info (pfixexpr, RANGE_8SIGN, listoffset);
              else
                {
                  constant = EvalPfixExpr (pfixexpr);
                  RemovePfixlist (pfixexpr);
                  if (constant >= -128 && constant <= 255)
                    *codeptr = (char) constant;
                  else
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
                }
            }
        }
    }
  else
    flag = 0;

  ++codeptr;
  return flag;
}


void
ReleaseExprns (expressions_t *express)
{
  expression_t *tmpexpr, *curexpr;

  curexpr = express->firstexpr;
  while (curexpr != NULL)
    {
      tmpexpr = curexpr->nextexpr;
      RemovePfixlist (curexpr);
      curexpr = tmpexpr;
    }

  free (express);
}


expressions_t *
AllocExprHdr (void)
{
  return (expressions_t *) malloc (sizeof (expressions_t));
}


void
StoreExpr (expression_t *pfixexpr, char range)
{
  unsigned char b;

  fputc (range, objfile);                       /* range of expression */
  WriteLong (pfixexpr->codepos, objfile);       /* write patch pointer inside code module */
  b = strlen (pfixexpr->infixexpr);
  fputc (b, objfile);                           /* length prefixed string */
  fwrite (pfixexpr->infixexpr, sizeof (b), (size_t) b, objfile);
  fputc (0, objfile);                           /* null-terminate expression */

  pfixexpr->stored = ON;
}


static void
CalcExpression (enum symbols opr, pfixstack_t **stackptr)
{
  long leftoperand, rightoperand;

  rightoperand = PopItem (stackptr);    /* first get right operator */
  leftoperand = PopItem (stackptr);     /* then get left operator... */

  switch (opr)
    {
      case bin_and:
        PushItem (leftoperand & rightoperand, stackptr);
        break;

      case bin_or:
        PushItem (leftoperand | rightoperand, stackptr);
        break;

      case bin_nor:
        PushItem (~(leftoperand | rightoperand), stackptr);
        break;

      case bin_xor:
        PushItem (leftoperand ^ rightoperand, stackptr);
        break;

      case plus:
        PushItem (leftoperand + rightoperand, stackptr);
        break;

      case minus:
        PushItem (leftoperand - rightoperand, stackptr);
        break;

      case multiply:
        PushItem (leftoperand * rightoperand, stackptr);
        break;

      case divi:
        PushItem (leftoperand / rightoperand, stackptr);
        break;

      case mod:
        PushItem (leftoperand % rightoperand, stackptr);
        break;

      case lshift:
        PushItem (leftoperand << (rightoperand % 32), stackptr);
        break;

      case rshift:
        PushItem ((unsigned long) leftoperand >> (rightoperand % 32), stackptr);
        break;

      case power:
        PushItem (Pw (leftoperand, rightoperand), stackptr);
        break;

      case assign:
        PushItem ((leftoperand == rightoperand), stackptr);
        break;

      case lessequal:
        PushItem ((leftoperand <= rightoperand), stackptr);
        break;

      case greatequal:
        PushItem ((leftoperand <= rightoperand), stackptr);
        break;

      case notequal:
        PushItem ((leftoperand != rightoperand), stackptr);
        break;

      default:
        PushItem (0, stackptr);
    }
}


long
Pw (long x, long y)
{
  long i;

  for (i = 1; y > 0; --y)
    i *= x;

  return i;
}

static void
NewPfixSymbol (expression_t *pfixexpr,
               long oprconst,
               enum symbols oprtype,
               char *symident,
               unsigned long symtype)
{
  postfixexpr_t *newnode;

  if ((newnode = AllocPfixSymbol ()) != NULL)
    {
      newnode->operandconst = oprconst;
      newnode->operatortype = oprtype;
      newnode->nextoperand = NULL;
      newnode->type = symtype;

      if (symident != NULL)
        {
          newnode->id = AllocIdentifier (strlen (symident) + 1);        /* Allocate symbol */

          if (newnode->id == NULL)
            {
              free (newnode);
              ReportError (NULL, 0, Err_Memory);
              return;
            }
          strcpy (newnode->id, symident);
        }
      else
        newnode->id = NULL;
    }
  else
    {
      ReportError (NULL, 0, Err_Memory);

      return;
    }

  if (pfixexpr->firstnode == NULL)
    {
      pfixexpr->firstnode = newnode;
      pfixexpr->currentnode = newnode;
    }
  else
    {
      pfixexpr->currentnode->nextoperand = newnode;
      pfixexpr->currentnode = newnode;
    }
}



static void
PushItem (long oprconst, pfixstack_t **stackpointer)
{
  pfixstack_t *newitem;

  if ((newitem = AllocStackItem ()) != NULL)
    {
      newitem->stackconstant = oprconst;
      newitem->prevstackitem = *stackpointer;   /* link new node to current node */
      *stackpointer = newitem;  /* update stackpointer to new item */
    }
  else
    ReportError (NULL, 0, Err_Memory);
}



static long
PopItem (pfixstack_t **stackpointer)
{

  pfixstack_t *stackitem;
  long constant;

  constant = (*stackpointer)->stackconstant;
  stackitem = *stackpointer;
  *stackpointer = (*stackpointer)->prevstackitem;       /* Move stackpointer to previous item */
  free (stackitem);                                     /* return old item memory to OS */
  return constant;
}



static int
Factor (expression_t *pfixexpr)
{
  long constant;
  symbol_t *symptr;
  char eval_err;
  int c;

  switch (sym)
    {
    case name:
      symptr = GetSymPtr (ident);
      if (symptr != NULL)
        {
          if (symptr->type & SYMDEFINED)
            {
              pfixexpr->rangetype |= (symptr->type & SYMTYPE);  /* Copy appropriate type bits */
              NewPfixSymbol (pfixexpr, symptr->symvalue, number, NULL, symptr->type);
            }
          else
            {
              pfixexpr->rangetype |= ((symptr->type & SYMTYPE) | NOTEVALUABLE);
              /* Copy appropriate declaration bits */

              NewPfixSymbol (pfixexpr, 0, number, ident, symptr->type);
              /* symbol only declared, store symbol name */
            }
        }
      else
        {
          pfixexpr->rangetype |= NOTEVALUABLE;  /* expression not evaluable */
          NewPfixSymbol (pfixexpr, 0, number, ident, SYM_NOTDEFINED);   /* symbol not found */
        }
      strcpy (pfixexpr->infixptr, ident);       /* add identifier to infix expr */
      pfixexpr->infixptr += strlen (ident);     /* update pointer */

      GetSym ();
      break;

    case hexconst:
    case binconst:
    case decmconst:
      strcpy (pfixexpr->infixptr, ident);       /* add constant to infix expr */
      pfixexpr->infixptr += strlen (ident);     /* update pointer */
      constant = GetConstant (&eval_err);

      if (eval_err == 1)
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprSyntax);
          return 0;             /* syntax error in expression */
        }
      else
        {
          NewPfixSymbol (pfixexpr, constant, number, NULL, 0);
        }

      GetSym ();
      break;

    case lparen:
      *pfixexpr->infixptr++ = separators[lparen];      /* store '(' in infix expr */
      GetSym ();

      if (Condition (pfixexpr))
        {
          if (sym == rparen)
            {
              *pfixexpr->infixptr++ = separators[rparen];      /* store '(' in infix expr */
              GetSym ();
              break;
            }
          else
            {
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprBracket);
              return 0;
            }
        }
      else
        return 0;

    case log_not:
      *pfixexpr->infixptr++ = separators[log_not];
      GetSym ();

      if (!Factor (pfixexpr))
        return 0;
      else
        NewPfixSymbol (pfixexpr, 0, log_not, NULL, 0);  /* Unary logical NOT... */
      break;

    case div256:
      *pfixexpr->infixptr++ = separators[div256];
      GetSym ();

      if (!Factor (pfixexpr))
        return 0;
      else
        NewPfixSymbol (pfixexpr, 0, div256, NULL, 0);  /* Unary Divide By 256 */
      break;

    case mod256:
      *pfixexpr->infixptr++ = separators[mod256];
      GetSym ();

      if (!Factor (pfixexpr))
        return 0;
      else
        NewPfixSymbol (pfixexpr, 0, mod256, NULL, 0);  /* Unary Modulus 256 */
      break;

    case bin_not:
      *pfixexpr->infixptr++ = separators[bin_not];
      GetSym ();

      if (!Factor (pfixexpr))
        return 0;
      else
        NewPfixSymbol (pfixexpr, 0, bin_not, NULL, 0);  /* Unary Binary NOT... */
      break;

    case squote:
      *pfixexpr->infixptr++ = separators[squote];
      if (feof (srcasmfile))
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          return 0;
        }
      else
        {
          c = GetChar (srcasmfile);
          if (c == EOF)
            {
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
              return 0;
            }
          else
            {
              *pfixexpr->infixptr++ = c;         /* store char in infix expr */
              if (GetSym () == squote)
                {
                  *pfixexpr->infixptr++ = separators[squote];
                  NewPfixSymbol (pfixexpr, (long) c, number, NULL, 0);
                }
              else
                {
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprSyntax);
                  return 0;
                }
            }
        }

      GetSym ();
      break;

    default:
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprSyntax);
      return 0;
    }

  return 1;  /* syntax OK */
}



static int
Pterm (expression_t *pfixexpr)
{
  if (!Factor (pfixexpr))
    return (0);

  while (sym == power)
    {
      strcpy (pfixexpr->infixptr, "**");       /* add '**' power symbol to infix expr */
      pfixexpr->infixptr += 2;

      GetSym ();
      if (Factor (pfixexpr))
        NewPfixSymbol (pfixexpr, 0, power, NULL, 0);
      else
        return 0;
    }

  return (1);
}



static int
Term (expression_t *pfixexpr)
{
  enum symbols mulsym;

  if (!Pterm (pfixexpr))
    return (0);

  while ((sym == multiply) || (sym == divi) || (sym == mod))
    {
      *pfixexpr->infixptr++ = separators[sym];  /* store '/', '%', '*' in infix expression */
      mulsym = sym;
      GetSym ();
      if (Pterm (pfixexpr))
        NewPfixSymbol (pfixexpr, 0, mulsym, NULL, 0);
      else
        return 0;
    }

  return (1);
}



static int
Expression (expression_t *pfixexpr)
{
  enum symbols addsym;

  if ((sym == plus) || (sym == minus))
    {
      if (sym == minus)
        *pfixexpr->infixptr++ = separators[minus];

      addsym = sym;
      GetSym ();

      if (Term (pfixexpr))
        {
          if (addsym == minus)
            NewPfixSymbol (pfixexpr, 0, negated, NULL, 0);      /* operand is signed, plus is redundant... */
        }
      else
        return (0);
    }
  else if (!Term (pfixexpr))
    return (0);

  while ((sym == plus) || (sym == minus) ||
         (sym == bin_and) || (sym == bin_or) || (sym == bin_nor) || (sym == bin_xor) ||
         (sym == lshift) || (sym == rshift))
    {
      if (sym == lshift) {
        strcpy (pfixexpr->infixptr, "<<");
        pfixexpr->infixptr += 2;
      } else if (sym == rshift) {
        strcpy (pfixexpr->infixptr, ">>");
        pfixexpr->infixptr += 2;
      } else
        *pfixexpr->infixptr++ = separators[sym];

      addsym = sym;
      GetSym ();

      if (Term (pfixexpr))
        NewPfixSymbol (pfixexpr, 0, addsym, NULL, 0);
      else
        return (0);
    }

  return (1);
}


static int
Condition (expression_t *pfixexpr)
{
  enum symbols relsym;

  if (!Expression (pfixexpr))
    return 0;

  switch (sym)
    {
    case less:      /* '<' */
    case greater:   /* '>' */
    case assign:    /* '=' */
      *pfixexpr->infixptr++ = separators[sym];
      relsym = sym;
      GetSym ();
      break;

    case lessequal:
      strcpy(pfixexpr->infixptr,"<=");
      pfixexpr->infixptr += 2;
      relsym = sym;
      GetSym ();
      break;

    case greatequal:
      strcpy(pfixexpr->infixptr,">=");
      pfixexpr->infixptr += 2;
      relsym = sym;
      GetSym ();
      break;

    default:
      return 1;                 /* implicit (left side only) expression */
    }

  if (!Expression (pfixexpr))
    return 0;
  else
    NewPfixSymbol (pfixexpr, 0, relsym, NULL, 0);       /* condition... */

  return 1;
}


static expression_t *
AllocExpr (void)
{
  return (expression_t *) malloc (sizeof (expression_t));
}


static postfixexpr_t *
AllocPfixSymbol (void)
{
  return (postfixexpr_t *) malloc (sizeof (postfixexpr_t));
}


static pfixstack_t *
AllocStackItem (void)
{
  return (pfixstack_t *) malloc (sizeof (pfixstack_t));
}

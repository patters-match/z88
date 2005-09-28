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
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "config.h"
#include "datastructs.h"
#include "symtables.h"
#include "pass.h"
#include "asmdrctv.h"
#include "errors.h"


/* globally available functions, Z80 specific line parsing */
void ParseLine (enum flag interpret);
long GetConstant (char *evalerr);
enum symbols GetSym (void);
int IndirectRegisters (void);
int CheckCondition (void);
int CheckRegister8 (void);
int CheckRegister16 (void);


/* externally defined variables */
extern unsigned long PC;
extern FILE *srcasmfile;
extern char ident[];
extern short currentline;
extern module_t *CURRENTMODULE;
extern enum flag EOL, uselistingfile, writeline;
extern avltree_t *globalroot;
extern symbol_t *gAsmpcPtr;     /* pointer to Assembler PC symbol (defined in global symbol variables) */
extern long TOTALLINES;
extern labels_t *addresses;


/* globally defined variables */
enum symbols sym, ssym[] =
{space, bin_and, dquote, squote, semicolon, comma, fullstop,
 lparen, lcurly, lexpr, rexpr, rcurly, rparen, plus, minus, multiply, divi, mod, bin_xor,
 assign, bin_or, bin_nor, bin_not,less, greater, log_not, hash, constexpr};

char separators[] = " &\"\';,.({[]})+-*/%^=|:~<>!#?";
char ident[255];


void
ParseLine (enum flag interpret)
{
  symbol_t *labeladdr;

  gAsmpcPtr->symvalue = PC;   /* update assembler program counter */

  if (PC <= MAXCODESIZE)   /* room for machine code? */
    {
      ++CURRENTFILE->line;
      ++TOTALLINES;
      if (uselistingfile == ON) GetLine ();  /* get a Copy of current source line */

      EOL = OFF;        /* reset END OF LINE flag */
      GetSym ();
      if (sym == fullstop)
        {
          if (interpret == ON)
            {           /* Generate only possible label declaration if line parsing is allowed */
              if (GetSym () == name)
                {
                  labeladdr = DefineSymbol (ident, PC, SYMADDR | SYMTOUCHED);
                  if (labeladdr != NULL) AddAddress (labeladdr, &addresses);

                  GetSym ();    /* check for another identifier referencing problems in expressions */
                }
              else
                {
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);  /* a name must follow a label declaration */
                  return;   /* read in a new source line */
                }
            }
          else
            {
              SkipLine (srcasmfile);
              sym = newline;    /* ignore label and rest of line */
            }
        }
      switch (sym)
        {
          case name:
            ParseMpmIdent (interpret);
            break;

          case newline:
            break;        /* empty line, get next... */

          default:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        }

      if (uselistingfile == ON && writeline == ON)
        WriteListFileLine ();   /* Write current source line to list file, if allowed */
    }
  else
    ReportError (NULL, 0, Err_MaxCodeSize);  /* no more room in machine code area */
}


enum symbols
GetSym (void)
{
  char *instr;
  int c, chcount = 0;

  ident[0] = '\0';

  if (EOL == ON)
    {
      sym = newline;
      return sym;
    }
  for (;;)
    {               /* Ignore leading white spaces, if any... */
      if (feof (srcasmfile))
        {
          sym = newline;
          EOL = ON;
          return newline;
        }
      else
        {
          c = GetChar (srcasmfile);
          if ((c == '\n') || (c == EOF) || (c == '\x1A'))
            {
              sym = newline;
              EOL = ON;
              return newline;
            }
          else
            if (!isspace (c)) break;
        }
    }

  instr = strchr (separators, c);
  if (instr != NULL)
    {
      sym = ssym[instr - separators];   /* index of found char in separators[] */
      if (sym == semicolon || sym == hash)
        {
          SkipLine (srcasmfile);    /* ';' or '#', ignore comment line, prepare for next line */
          sym = newline;
        }

      switch (sym)
       {
         case multiply:
           c = GetChar (srcasmfile);
           if (c == '*')
             sym = power;       /* '**' */
           else
             ungetc (c, srcasmfile);    /* '*' was found, puch this character back into stream for next read */
           break;

         case less:         /* '<' */
           c = GetChar (srcasmfile);
           switch (c)
             {
               case '<':
                sym = lshift;       /* '<<' */
                break;

               case '>':
                 sym = notequal;    /* '<>' */
                 break;

               case '=':
                 sym = lessequal;       /* '<=' */
                 break;

               default:
                 ungetc (c, srcasmfile);    /* '<' was found, puch this character back into stream for next read */
                 break;
             }
           break;

         case greater:          /* '>' */
           c = GetChar (srcasmfile);
           switch (c)
             {
               case '>':
                sym = rshift;       /* '>>' */
                break;

               case '=':
                 sym = greatequal;      /* '>=' */
                 break;

               default:
                 ungetc (c, srcasmfile);    /* '>' was found, puch this character back into stream for next read */
                 break;
             }
           break;

         default:
           break;   /* just to keep the C compiler happy... */
       }

       return sym;
    }

  ident[chcount++] = (char) toupper (c);
  switch (c)
    {
    case '$':
      sym = hexconst;
      break;

    case '@':
      sym = binconst;
      break;

    case '_':                   /* leading '_' allowed for name definitions */
      sym = name;
      break;

    case '#':
      sym = name;
      break;

    default:
      if (isdigit (c))
        {
          sym = decmconst;  /* a decimal number found */
        }
      else
        {
          if (isalpha (c))
            {
              sym = name;   /* an identifier found */
            }
          else
            {
              sym = nil;    /* rubbish ... */
            }
        }
      break;
    }

  /* Read identifier until space or legal separator is found */
  if (sym == name)
    {
      for (;;)
        {
          if (feof (srcasmfile))
            {
              break;
            }
          else
            {
              c = GetChar (srcasmfile);
              if ((c != EOF) && (!iscntrl (c)) && (strchr (separators, c) == NULL))
                {
                  if (!isalnum (c))
                    {
                      if (c != '_')
                        {
                          sym = nil;
                          break;
                        }
                      else
                        {
                          ident[chcount++] = '_';   /* underscore in identifier */
                        }
                    }
                  else
                    {
                      ident[chcount++] = (char) toupper (c);
                    }
                }
              else
                {
                  ungetc (c, srcasmfile);   /* puch character back into stream for next read */
                  break;
                }
            }
        }
    }
  else
    {
      for (;;)
        {
          if (feof (srcasmfile))
            {
              break;
            }
          else
            {
              c = GetChar (srcasmfile);
              if ((c != EOF) && !iscntrl (c) && (strchr (separators, c) == NULL))
                {
                  ident[chcount++] = (char) toupper (c);
                }
              else
                {
                  ungetc (c, srcasmfile);   /* puch character back into stream for next read */

                  ident[chcount] = '\0';
                  if ((strcmp(ident,ASSEMBLERPC) == 0) && (sym == hexconst))
                    {   /* the internal Assembler Program Counter */
                      sym = name;
                    }

                  break;
                }
            }
        }
    }

  ident[chcount] = '\0';
  return sym;
}


/* ----------------------------------------------------------------
   Identify Z80 instruction condition codes:
        Z, NZ, C, NC, PE, PO, M
   ---------------------------------------------------------------- */
int
CheckCondition (void)
{
  switch (*ident)
    {
    case 'Z':           /* is it zero flag ? */
      if (*(ident + 1) == '\0')
    return (1);
      else
    return -1;

    case 'N':           /* is it NZ, NC ? */
      if (*(ident + 2) == '\0')
    switch (*(ident + 1))
      {
      case 'Z':
        return (0);
      case 'C':
        return (2);
      default:
        return (-1);
      }
      else
    return -1;

    case 'C':           /* is it carry flag ? */
      if (*(ident + 1) == '\0')
    return (3);
      else
    return -1;

    case 'P':
      switch (*(ident + 1))
    {
    case '\0':
      return (6);       /* P */

    case 'O':
      if (*(ident + 2) == '\0')
        return (4);     /* PO */
      else
        return -1;

    case 'E':
      if (*(ident + 2) == '\0')
        return (5);     /* PE */
      else
        return (-1);
    default:
      return (-1);
    }

    case 'M':           /* is it minus flag ? */
      if (*(ident + 1) == '\0')
    return (7);
      else
    return -1;

    default:
      return -1;
    }
}


/* ----------------------------------------------------------------
   Identify Z80 8bit registers mnemonics:
        A, B, C, D, E, H, L, I, R, F
   ---------------------------------------------------------------- */
int
CheckRegister8 (void)
{
  if (sym == name)
    {
      if (*(ident + 1) == '\0')
        {
          switch (*ident)
            {
              case 'A':
                return 7;
              case 'H':
                return 4;
              case 'B':
                return 0;
              case 'L':
                return 5;
              case 'C':
                return 1;
              case 'D':
                return 2;
              case 'E':
                return 3;
              case 'I':
                return 8;
              case 'R':
                return 9;
              case 'F':
                return 6;
            }
        }
      else
        {
          if (strcmp (ident, "IXL") == 0)
            return (8 + 5);
          else if (strcmp (ident, "IXH") == 0)
            return (8 + 4);
          else if (strcmp (ident, "IYL") == 0)
            return (16 + 5);
          else if (strcmp (ident, "IYH") == 0)
            return (16 + 4);
        }
    }

  return -1;
}


/* ----------------------------------------------------------------
   Identify Z80 16bit registers mnemonics:
        BC, DE, HL, IX, IY, AF, SP
   ---------------------------------------------------------------- */
int
CheckRegister16 (void)
{
  if (sym == name)
    if (*(ident + 2) == '\0')
      switch (*ident)
    {
    case 'H':
      if (*(ident + 1) == 'L')
        return (2);
      break;

    case 'B':
      if (*(ident + 1) == 'C')
        return (0);
      break;

    case 'D':
      if (*(ident + 1) == 'E')
        return (1);
      break;

    case 'A':
      if (*(ident + 1) == 'F')
        return (4);
      break;

    case 'S':
      if (*(ident + 1) == 'P')
        return (3);
      break;

    case 'I':
      switch (*(ident + 1))
        {
        case 'X':
          return (5);
        case 'Y':
          return (6);
        }
    }
  return -1;
}


/* ---------------------------------------------------------------------------
   This function will parse the current line for an indirect addressing mode.
   The return code can be:

   0 - 2   :   (BC); (DE); (HL)
   5, 6    :   (IX <+|- expr.> ); (IY <+|- expr.> )
   7       :   (nn), nn = 16bit address expression

   The function also returns a pointer to the parsed expression,
   now converted to postfix.
   --------------------------------------------------------------------------- */
int
IndirectRegisters (void)
{
  int reg16;

  GetSym ();
  reg16 = CheckRegister16 ();
  switch (reg16)
    {
    case 0:         /* 0 to 2 = BC, DE, HL */
    case 1:
    case 2:
      if (GetSym () == rparen)
    {           /* (BC) | (DE) | (HL) | ? */
      GetSym ();
      return (reg16);   /* indicate (BC), (DE), (HL) */
    }
      else
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, 1);   /* Right bracket missing! */
      return -1;
    }

    case 5:         /* 5, 6 = IX, IY */
    case 6:
      GetSym ();        /* prepare expression evaluation */
      return (reg16);

    case -1:            /* sym could be a '+', '-' or a symbol... */
      return 7;

    default:
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, 11);
      return -1;
    }
}


long
GetConstant (char *evalerr)
{
  short size, l;
  long lv;
  unsigned long bitvalue = 1;

  lv = 0;
  *evalerr = 0;         /* preset to no errors */

  if ((sym != hexconst) && (sym != binconst) && (sym != decmconst))
    {
      *evalerr = 1;
      return lv;       /* syntax error - illegal constant definition */
    }
  size = strlen (ident);

  /* hex constant specified as 0x... */
  if ( ident[0] == '0' && toupper(ident[1]) == 'X')
    {
      for (l = 2; l < size; l++)
        {
          if (isxdigit (ident[l]) == 0)
            {
              *evalerr = 1;
              return lv;
            }
        }

      sscanf ((char *) (ident + 2), "%lx", &lv);
      return lv;
    }

  if (sym != decmconst)
    if ((--size) == 0)
      {
        *evalerr = 1;
        return lv;     /* syntax error - no constant specified */
      }

  switch (ident[0])
    {
    case '@':
      if (size > 32)
        {
           *evalerr = 1;
           return lv;       /* max 32 bit */
        }
      for (l = 1; l <= size; l++)
        if (strchr ("01", ident[l]) == NULL)
          {
            *evalerr = 1;
            return lv;
          }
      /* convert ASCII binary to integer */
      for (l = size; l >= 1; l--)
        {
          if (ident[l] == '1')
            lv += bitvalue;
          bitvalue <<= 1;       /* logical shift left & 32 bit 'adder' */
        }

      /* convert ASCII binary to 32bit integer */
      return lv;

    case '$':
      for (l = 1; l <= size; l++)
        if (isxdigit (ident[l]) == 0)
          {
            *evalerr = 1;
            return lv;
          }
        sscanf ((char *) (ident + 1), "%lx", &lv);
      return lv;

    default:
      for (l = 0; l <= (size - 1); l++)
        if (isdigit (ident[l]) == 0)
          {
            *evalerr = 1;
            return lv;
          }
      return atol (ident);
    }
}
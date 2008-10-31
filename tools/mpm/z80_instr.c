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
#include <string.h>
#include <stdlib.h>
#include "config.h"
#include "datastructs.h"
#include "exprprsr.h"
#include "modules.h"
#include "pass.h"
#include "asmdrctv.h"
#include "errors.h"
#include "z80_prsline.h"


/* externally defined variables */
extern FILE *srcasmfile;
extern enum symbols sym;
extern enum flag writeline, EOL;
extern unsigned long PC, oldPC;
extern unsigned char *codeptr;
extern module_t *CURRENTMODULE;
extern enum flag BIGENDIAN, USEBIGENDIAN;


void
LD (void)
{
  long exprptr;
  int sourcereg, destreg;

  if (GetSym () == lparen)
    {
      exprptr = ftell (srcasmfile); /* remember start of expression */
      switch (destreg = IndirectRegisters ())
        {
          case 2:
            LD_HL8bit_indrct ();  /* LD  (HL),  */
            break;

          case 5:
          case 6:
            LD_index8bit_indrct (destreg);    /* LD  (IX|IY+d),  */
            break;

          case 0:
            if (sym == comma)
              {           /* LD  (BC),A  */
                GetSym ();
                if (CheckRegister8 () == 7)
                  {
                    *codeptr++ = 2;
                    ++PC;
                  }
                else
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;

          case 1:
            if (sym == comma)
              {           /* LD  (DE),A  */
                GetSym ();
                if (CheckRegister8 () == 7)
                  {
                    *codeptr++ = 18;
                    ++PC;
                  }
                else
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;

          case 7:
            LD_address_indrct (exprptr);  /* LD  (nn),rr  ;  LD  (nn),A  */
            break;
        }
    }
  else
    {
      switch (destreg = CheckRegister8 ())
        {
          case -1:
            LD_16bit_reg ();    /* LD rr,(nn)   ;  LD  rr,nn   ;   LD  SP,HL|IX|IY   */
            break;

          case 6:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);    /* LD F,? */
            break;

          case 8:
            if (GetSym () == comma)
              {
                GetSym ();
                if (CheckRegister8 () == 7)
                  {         /* LD  I,A */
                    *codeptr++ = 237;
                    *codeptr++ = 71;
                    PC += 2;
                  }
                else
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;

          case 9:
            if (GetSym () == comma)
              {
                GetSym ();
                if (CheckRegister8 () == 7)
                  {         /* LD  R,A */
                    *codeptr++ = 237;
                    *codeptr++ = 79;
                    PC += 2;
                  }
                else
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;

          default:
            if (GetSym () == comma)
              {
                if (GetSym () == lparen)
                  LD_r_8bit_indrct (destreg);   /* LD  r,(HL)  ;   LD  r,(IX|IY+d)  */
                else
                  {
                    sourcereg = CheckRegister8 ();
                    if (sourcereg == -1)
                      {     /* LD  r,n */
                        if (destreg & 8)
                          {
                            *codeptr++ = 221;   /* LD IXl,n or LD IXh,n */
                            ++PC;
                          }
                        else if (destreg & 16)
                          {
                            *codeptr++ = 253;   /* LD  IYl,n or LD  IYh,n */
                            ++PC;
                          }
                        destreg &= 7;
                        *codeptr++ = destreg * 8 + 6;
                        ExprUnsigned8 (1);
                        PC += 2;
                        return;
                      }
                    if (sourcereg == 6)
                      {
                        /* LD x, F */
                        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                        return;
                      }
                    if ((sourcereg == 8) && (destreg == 7))
                      {     /* LD A,I */
                        *codeptr++ = 237;
                        *codeptr++ = 87;
                        PC += 2;
                        return;
                      }
                    if ((sourcereg == 9) && (destreg == 7))
                      {     /* LD A,R */
                        *codeptr++ = 237;
                        *codeptr++ = 95;
                        PC += 2;
                        return;
                      }
                    if ((destreg & 8) || (sourcereg & 8))
                      {     /* IXl or IXh */
                        *codeptr++ = 221;
                        ++PC;
                      }
                    else if ((destreg & 16) || (sourcereg & 16))
                      {     /* IYl or IYh */
                        *codeptr++ = 253;
                        ++PC;
                      }
                    sourcereg &= 7;
                    destreg &= 7;

                    *codeptr++ = 64 + destreg * 8 + sourcereg;  /* LD  r,r  */
                    ++PC;
                  }
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;
        }
    }
}


/*
 * LD (HL),r LD   (HL),n
 */
void
LD_HL8bit_indrct (void)
{
  int sourcereg;

  if (sym == comma)
    {
      GetSym ();
      switch (sourcereg = CheckRegister8 ())
        {
          case 6:
          case 8:
          case 9:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            break;

          case -1:        /* LD  (HL),n  */
            *codeptr++ = 54;
            ExprUnsigned8 (1);
            PC += 2;
            break;

          default:
            *codeptr++ = 112 + sourcereg;     /* LD  (HL),r  */
            ++PC;
            break;
        }
    }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}


/*
 * LD (IX|IY+d),r LD   (IX|IY+d),n
 */
void
LD_index8bit_indrct (int destreg)
{
  int sourcereg;
  unsigned char *opcodeptr;

  if (destreg == 5)
    *codeptr++ = 221;
  else
    *codeptr++ = 253;
  opcodeptr = codeptr;      /* pointer to instruction opcode */
  *codeptr++ = 54;          /* preset 2. opcode to LD (IX|IY+d),n  */

  if (!ExprSigned8 (2))
    return;         /* IX/IY offset expression */
  if (sym != rparen)
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);   /* ')' wasn't found in line */
      return;
    }
  if (GetSym () == comma)
    {
      GetSym ();
      switch (sourcereg = CheckRegister8 ())
        {
          case 6:
          case 8:
          case 9:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            break;

          case -1:
            ExprUnsigned8 (3);    /* Execute, store & patch 8bit expression for <n> */
            PC += 4;
            break;

          default:
            *opcodeptr = 112 + sourcereg;     /* LD  (IX|IY+d),r  */
            PC += 3;
            break;
        }
    }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}


/*
 * LD  r,(HL) LD  r,(IX|IY+d) LD  A,(nn)
 */
void
LD_r_8bit_indrct (int destreg)
{
  int sourcereg;

  switch (sourcereg = IndirectRegisters ())
    {
      case 2:
        *codeptr++ = 64 + destreg * 8 + 6;    /* LD   r,(HL)  */
        ++PC;
        break;

      case 5:
      case 6:
        if (sourcereg == 5)
          *codeptr++ = 221;
        else
          *codeptr++ = 253;

        *codeptr++ = 64 + destreg * 8 + 6;
        ExprSigned8 (2);
        PC += 3;
        break;

      case 7:         /* LD  A,(nn)  */
        if (destreg == 7)
          {
            *codeptr++ = 58;
            ExprAddr16 (1);
            PC += 3;
          }
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;

      case 0:
        if (destreg == 7)
          {           /* LD   A,(BC)  */
            *codeptr++ = 10;
            ++PC;
          }
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;

      case 1:
        if (destreg == 7)
          {           /* LD   A,(DE)  */
            *codeptr++ = 26;
            ++PC;
          }
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;

      default:
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;
    }
}


void
LD_address_indrct (long exprptr)
{
  int sourcereg;
  long bytepos;
  expression_t *addrexpr;

  if ((addrexpr = ParseNumExpr ()) == NULL)
    return;         /* parse to right bracket */
  else
    RemovePfixlist (addrexpr);  /* remove this expression again */

  if (sym != rparen)
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);   /* Right bracket missing! */
      return;
    }
  if (GetSym () == comma)
    {
      GetSym ();
      switch (sourcereg = CheckRegister16 ())
        {
          case 2:
            *codeptr++ = 34;  /* LD  (nn),HL  */
            bytepos = 1;
            ++PC;
            break;

          case 0:
          case 1:     /* LD  (nn),dd   => dd: BC,DE,SP  */
          case 3:
            *codeptr++ = 237;
            *codeptr++ = 67 + sourcereg * 16;
            bytepos = 2;
            PC += 2;
            break;

          case 5:     /* LD  (nn),IX    ;    LD  (nn),IY   */
          case 6:
            if (sourcereg == 5)
              *codeptr++ = 221;
            else
              *codeptr++ = 253;
            *codeptr++ = 34;
            bytepos = 2;
            PC += 2;
            break;

          case -1:
            if (CheckRegister8 () == 7)
              {
                *codeptr++ = 50;  /* LD  (nn),A  */
                ++PC;
                bytepos = 1;
              }
            else
              {
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                return;
              }
            break;

          default:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            return;
        }
    }
  else
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
      return;
    }

  fseek (srcasmfile, exprptr, SEEK_SET);    /* rewind fileptr to beginning of address expression */
  GetSym ();
  ExprAddr16 (bytepos); /* re-parse, evaluate, etc. */
  PC += 2;
}


void
LD_16bit_reg (void)
{
  int sourcereg, destreg;
  long bytepos;

  destreg = CheckRegister16 ();
  if (destreg == -1)
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
  else
    {
      if (GetSym () == comma)
        {
          if (GetSym () != lparen)
            {
              switch (sourcereg = CheckRegister16 ())
                {
                  case -1:      /* LD  rr,nn  */
                    switch (destreg)
                      {
                        case 4:
                          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                          return;

                          case 5:
                          case 6:
                            if (destreg == 5)
                              *codeptr++ = 221;
                            else
                              *codeptr++ = 253;

                            *codeptr++ = 33;
                            bytepos = 2;
                            PC += 2;
                            break;

                          default:
                            *codeptr++ = destreg * 16 + 1;
                            bytepos = 1;
                            ++PC;
                            break;
                      }

                    ExprAddr16 (bytepos);
                    PC += 2;
                    break;

                  case 2:
                    if (destreg == 3)
                      {         /* LD  SP,HL  */
                        *codeptr++ = 249;
                        ++PC;
                      }
                    else
                      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                    break;

                  case 5:       /* LD  SP,IX    LD  SP,IY  */
                  case 6:
                    if (destreg == 3)
                      {
                        if (sourcereg == 5)
                          *codeptr++ = 221;
                        else
                          *codeptr++ = 253;

                        *codeptr++ = 249;
                        PC += 2;
                      }
                    else
                      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                    break;

                  default:
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                    break;
                }
            }
          else
            {
              switch (destreg)
                {
                  case 4:
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                    return;

                  case 2:
                    *codeptr++ = 42;  /* LD   HL,(nn)  */
                    bytepos = 1;
                    ++PC;
                    break;

                  case 5:     /* LD  IX,(nn)    LD  IY,(nn)  */
                  case 6:
                    if (destreg == 5)
                      *codeptr++ = 221;
                    else
                      *codeptr++ = 253;

                    *codeptr++ = 42;
                    bytepos = 2;
                    PC += 2;
                    break;

                  default:
                    *codeptr++ = 237;
                    *codeptr++ = 75 + destreg * 16;
                    bytepos = 2;
                    PC += 2;
                    break;
                }

              GetSym ();
              ExprAddr16 (bytepos);
              PC += 2;
            }
        }
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        }
    }
}


void
NOP (void)
{
  *codeptr++ = 0;
  ++PC;
}



void
HALT (void)
{
  *codeptr++ = 118;
  ++PC;
}



void
LDI (void)
{
  *codeptr++ = 237;
  *codeptr++ = 160;
  PC += 2;
}



void
LDIR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 176;
  PC += 2;
}



void
LDD (void)
{
  *codeptr++ = 237;
  *codeptr++ = 168;
  PC += 2;
}



void
LDDR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 184;
  PC += 2;
}



void
CPI (void)
{
  *codeptr++ = 237;
  *codeptr++ = 161;
  PC += 2;
}



void
CPIR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 177;
  PC += 2;
}



void
CPD (void)
{
  *codeptr++ = 237;
  *codeptr++ = 169;
  PC += 2;
}



void
CPDR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 185;
  PC += 2;
}



void
IND (void)
{
  *codeptr++ = 237;
  *codeptr++ = 170;
  PC += 2;
}



void
INDR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 186;
  PC += 2;
}



void
INI (void)
{
  *codeptr++ = 237;
  *codeptr++ = 162;
  PC += 2;
}



void
INIR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 178;
  PC += 2;
}



void
OUTI (void)
{
  *codeptr++ = 237;
  *codeptr++ = 163;
  PC += 2;
}



void
OUTD (void)
{
  *codeptr++ = 237;
  *codeptr++ = 171;
  PC += 2;
}



void
OTIR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 179;
  PC += 2;
}



void
OTDR (void)
{
  *codeptr++ = 237;
  *codeptr++ = 187;
  PC += 2;
}


void
CP (void)
{
  ExtAccumulator (7);
}


void
AND (void)
{
  ExtAccumulator (4);
}



void
OR (void)
{
  ExtAccumulator (6);
}



void
XOR (void)
{
  ExtAccumulator (5);
}


void
SUB (void)
{
  ExtAccumulator (2);
}


void
SET (void)
{
  BitTest_instr (192);
}



void
RES (void)
{
  BitTest_instr (128);
}



void
BIT (void)
{
  BitTest_instr (64);
}



void
RLC (void)
{
  RotShift_instr (0);
}



void
RRC (void)
{
  RotShift_instr (1);
}



void
RL (void)
{
  RotShift_instr (2);
}



void
RR (void)
{
  RotShift_instr (3);
}



void
SLA (void)
{
  RotShift_instr (4);
}



void
SRA (void)
{
  RotShift_instr (5);
}



void
SLL (void)
{
  RotShift_instr (6);
}



void
SRL (void)
{
  RotShift_instr (7);
}



void
CPL (void)
{
  *codeptr++ = 47;
  ++PC;
}



void
RLA (void)
{
  *codeptr++ = 23;
  ++PC;
}



void
RRA (void)
{
  *codeptr++ = 31;
  ++PC;
}



void
RRCA (void)
{
  *codeptr++ = 15;
  ++PC;
}



void
RLCA (void)
{
  *codeptr++ = 7;
  ++PC;
}



void
EXX (void)
{
  *codeptr++ = 217;
  ++PC;
}



void
PUSH (void)
{
  PushPop_instr (197);
}



void
POP (void)
{
  PushPop_instr (193);
}




void
RETI (void)
{
  *codeptr++ = 237;
  *codeptr++ = 77;
  PC += 2;
}



void
RETN (void)
{
  *codeptr++ = 237;
  *codeptr++ = 69;
  PC += 2;
}



void
RLD (void)
{
  *codeptr++ = 237;
  *codeptr++ = 111;
  PC += 2;
}



void
RRD (void)
{
  *codeptr++ = 237;
  *codeptr++ = 103;
  PC += 2;
}



void
NEG (void)
{
  *codeptr++ = 237;
  *codeptr++ = 68;
  PC += 2;
}



void
CALL (void)
{
  Subroutine_addr (205, 196);
}



void
JP (void)
{
  JP_instr (195, 194);
}



void
CCF (void)
{
  *codeptr++ = 63;
  ++PC;
}



void
SCF (void)
{
  *codeptr++ = 55;
  ++PC;
}



void
DI (void)
{
  *codeptr++ = 243;
  ++PC;
}



void
EI (void)
{
  *codeptr++ = 251;
  ++PC;
}



void
DAA (void)
{
  *codeptr++ = 39;
  ++PC;
}



/*
 * Allow specification of "<instr> [A,]xxx" for ADD, ADC, SBC, SUB, AND, OR, XOR, CP instructions
 */
void
ExtAccumulator (int opcode)
{
  long fptr;

  fptr = ftell (srcasmfile);

  if (GetSym () == name)
    {
      if (CheckRegister8 () == 7)
        {
          if (GetSym () == comma)
            {
              /* <instr> A, ... */
              ArithLog8_instr (opcode);

              return;
            }
        }
    }

  /* reparse and code generate (if possible) */
  sym = nil;
  EOL = OFF;

  fseek (srcasmfile, fptr, SEEK_SET);
  ArithLog8_instr (opcode);
}


void
PushPop_instr (int opcode)
{
  int qq;

  if (GetSym () == name)
    switch (qq = CheckRegister16 ())
      {
        case 0:
        case 1:
        case 2:
          *codeptr++ = opcode + qq * 16;
          ++PC;
          break;

        case 4:
          *codeptr++ = opcode + 48;
          ++PC;
          break;

        case 5:
          *codeptr++ = 221;
          *codeptr++ = opcode + 32;
          PC += 2;
          break;

        case 6:
          *codeptr++ = 253;
          *codeptr++ = opcode + 32;
          PC += 2;
          break;

        default:
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
      }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}


void
RET (void)
{
  long constant;

  switch (GetSym ())
    {
      case name:
        if ((constant = CheckCondition ()) != -1)
          *codeptr++ = 192 + (unsigned char) (constant * 8);    /* RET <cc> instruction opcode */
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;

      case newline:
        *codeptr++ = 201;
        break;

      default:
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        return;
    }
  ++PC;
}


void
EX (void)
{
  if (GetSym () == lparen)
    if (GetSym () == name)
      if (CheckRegister16 () == 3)  /* EX  (SP) */
        if (GetSym () == rparen)
          if (GetSym () == comma)
            if (GetSym () == name)
              switch (CheckRegister16 ())
                {
                  case 2:
                    *codeptr++ = 227; /* EX  (SP),HL  */
                    ++PC;
                    break;

                  case 5:
                    *codeptr++ = 221;
                    *codeptr++ = 227; /* EX  (SP),IX  */
                    PC += 2;
                    break;

                  case 6:
                    *codeptr++ = 253;
                    *codeptr++ = 227; /* EX  (SP),IY  */
                    PC += 2;
                    break;

                  default:
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
      else
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
    else
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
  else if (sym == name)
    {
      switch (CheckRegister16 ())
        {
          case 1:
            if (GetSym () == comma)   /* EX DE,HL */
              if (GetSym () == name)
                if (CheckRegister16 () == 2)
                  {
                    *codeptr++ = 235;
                    ++PC;
                  }
                else
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
              else
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;

          case 4:
            if (GetSym () == comma)   /* EX  AF,AF' */
              if (GetSym () == name)
                if (CheckRegister16 () == 4)
                  {
                    *codeptr++ = 8;
                    ++PC;
                  }
                else
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
              else
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;

          default:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        }
    }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}



void
OUT (void)
{
  long reg;

  if (GetSym () == lparen)
    {
      GetSym ();
      if (CheckRegister8 () == 1)
        {           /* OUT (C) */
          if (GetSym () == rparen)
            if (GetSym () == comma)
              if (GetSym () == name)
                switch (reg = CheckRegister8 ())
                  {
                    case 6:
                    case 8:
                    case 9:
                    case -1:
                      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                      break;

                    default:
                      *codeptr++ = 237;
                      *codeptr++ = 65 + (unsigned char) (reg * 8);  /* OUT (C),r  */
                      PC += 2;
                      break;
                  }
              else
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        }
      else
        {
          *codeptr++ = 211;
          if (!ExprUnsigned8 (1))
            return;
          PC += 2;
          if (sym == rparen)
            if (GetSym () == comma)
              if (GetSym () == name)
                {
                  if (CheckRegister8 () != 7)
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                }
              else
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        }
    }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}


void
IN (void)
{
  long inreg;

  if (GetSym () == name)
    {
      switch (inreg = CheckRegister8 ())
        {
          case 8:
          case 9:
          case -1:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            break;

          default:
            if (GetSym () != comma)
              {
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
                break;
              }
            if (GetSym () != lparen)
              {
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
                break;
              }
            GetSym ();
            switch (CheckRegister8 ())
              {
                case 1:
                  *codeptr++ = 237;
                  *codeptr++ = 64 + (unsigned char) (inreg * 8);  /* IN r,(C) */
                  PC += 2;
                  break;

                case -1:
                  if (inreg == 7)
                    {
                      *codeptr++ = 219;
                      if (ExprUnsigned8 (1))
                        if (sym != rparen)
                          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
                      PC += 2;
                    }
                  else
                    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                  break;

                default:
                  ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                  break;
              }
            break;
        }
    }
  else
    ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
}


void
IM (void)
{
  long constant;
  expression_t *postfixexpr;

  GetSym ();
  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      if (postfixexpr->rangetype & NOTEVALUABLE)
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          constant = EvalPfixExpr (postfixexpr);
          switch (constant)
            {
              case 0:
                *codeptr++ = 237;
                *codeptr++ = 70;  /* IM 0 */
                break;

              case 1:
                *codeptr++ = 237;
                *codeptr++ = 86;  /* IM 1 */
                break;

              case 2:
                *codeptr++ = 237;
                *codeptr++ = 94;  /* IM 2 */
                break;
            }
          PC += 2;
        }
      RemovePfixlist (postfixexpr); /* remove linked list, because expr. was evaluated */
    }
}


void
RST (void)
{
  long constant;
  expression_t *postfixexpr;

  GetSym ();
  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {
      if (postfixexpr->rangetype & NOTEVALUABLE)
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
      else
        {
          constant = EvalPfixExpr (postfixexpr);
          if ((constant >= 0 && constant <= 56) && (constant % 8 == 0))
            {
              *codeptr++ = (unsigned char) (199 + constant);  /* RST  00H, ... 38H */
              ++PC;
            }
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
        }
      RemovePfixlist (postfixexpr);
    }
}


void
Subroutine_addr (int opcode0, int opcode)
{
  long constant;

  GetSym ();
  if ((constant = CheckCondition ()) != -1)
    {               /* check for a condition */
      *codeptr++ = opcode + (unsigned char) (constant * 8);   /* get instruction opcode */
      if (GetSym () == comma)
        GetSym ();
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
          return;
        }
    }
  else
    *codeptr++ = opcode0;   /* JP nn, CALL nn */

  ExprAddr16 (1);
  PC += 3;
}


void
JP_instr (int opc0, int opc)
{
  long startexpr;       /* file pointer to start of address expression */

  startexpr = ftell (srcasmfile);   /* remember position of possible start of expression */
  if (GetSym () == lparen)
    {
      GetSym ();
      switch (CheckRegister16 ())
        {
          case 2:     /* JP (HL) */
            *codeptr++ = 233;
            ++PC;
            break;

          case 5:     /* JP (IX) */
            *codeptr++ = 221;
            *codeptr++ = 233;
            PC += 2;
            break;

          case 6:     /* JP (IY) */
            *codeptr++ = 253;
            *codeptr++ = 233;
            PC += 2;
            break;

          case -1:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;

          default:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            break;
        }
    }
  else
    {
      fseek (srcasmfile, startexpr, SEEK_SET);  /* no indirect register were found, reparse line after 'JP' */
      Subroutine_addr (opc0, opc);  /* base opcode for <instr> nn; <instr> cc, nn */
    }
}


void
JR (void)
{
  expression_t *postfixexpr;
  long constant;

  GetSym ();
  switch (constant = CheckCondition ())
  {           /* check for a condition */
    case 0:
    case 1:
    case 2:
    case 3:
      *codeptr++ = 32 + (unsigned char) (constant * 8);
      if (GetSym () == comma)
        GetSym ();    /* point at start of address expression */
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);   /* comma missing */
          return;
        }
      break;

    case -1:
      *codeptr++ = 24;  /* opcode for JR  e */
      break;        /* identifier not a condition id - check for legal expression */

    default:
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);   /* illegal condition, syntax
                                     * error  */
      return;
  }

  PC += 2;          /* assembler PC points at next instruction */
  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {               /* get numerical expression */
      if (postfixexpr->rangetype & NOTEVALUABLE)
        {
          NewJRaddr ();     /* Amend another JR PC address to the list */
          Pass2info (postfixexpr, RANGE_JROFFSET8, 1);
          ++codeptr;        /* update code pointer */
        }
      else
        {
          constant = EvalPfixExpr (postfixexpr);
          constant -= PC;
          RemovePfixlist (postfixexpr);     /* remove linked list - expression evaluated. */
          if ((constant >= -128) && (constant <= 127))
            *codeptr++ = (unsigned char) constant;  /* opcode is stored, now store relative jump */
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprOutOfRange);
        }
    }
}


void
DJNZ (void)
{
  expression_t *postfixexpr;
  long constant;

  *codeptr++ = 16;      /* DJNZ opcode */

  if (GetSym () == comma)
    GetSym ();          /* optional comma */

  PC += 2;
  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {               /* get numerical expression */
      if (postfixexpr->rangetype & NOTEVALUABLE)
        {
          NewJRaddr ();     /* Amend another JR PC address to the list */
          Pass2info (postfixexpr, RANGE_JROFFSET8, 1);
          ++codeptr;        /* update code pointer */
        }
      else
        {
          constant = EvalPfixExpr (postfixexpr);
          constant -= PC;
          RemovePfixlist (postfixexpr);     /* remove linked list - expression evaluated. */
          if ((constant >= -128) && (constant <= 127))
            *codeptr++ = (unsigned char) constant;  /* opcode is stored, now store relative jump */
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_ExprOutOfRange);
        }
    }
}


void
ADD (void)
{
  int acc16, reg16;
  long fptr;

  fptr = ftell (srcasmfile);

  GetSym ();
  switch (acc16 = CheckRegister16 ())
    {
      case -1:
        fseek (srcasmfile, fptr, SEEK_SET);
        ExtAccumulator(0);                   /* 16 bit register wasn't found - try to evaluate the 8 bit version */
        break;

      case 2:
        if (GetSym () == comma)
          {
            GetSym ();
            reg16 = CheckRegister16 ();
            if (reg16 >= 0 && reg16 <= 3)
              {
                *codeptr++ = 9 + 16 * reg16;  /* ADD HL,rr */
                ++PC;
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
          }
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        break;

      case 5:
      case 6:
        if (GetSym () == comma)
          {
            GetSym ();
            reg16 = CheckRegister16 ();
            switch (reg16)
              {
              case 0:
              case 1:
              case 3:
                break;

              case 5:
              case 6:
                if (acc16 == reg16)
              reg16 = 2;
                else
              {
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                return;
              }
                break;

              default:
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                return;
              }
            if (acc16 == 5)
              *codeptr++ = 221;
            else
              *codeptr++ = 253;

            *codeptr++ = 9 + 16 * reg16;
            PC += 2;
          }
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        break;

      default:
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_UnknownIdent);
        break;
    }
}


void
SBC (void)
{
  int reg16;
  long fptr;

  fptr = ftell (srcasmfile);

  GetSym ();
  switch (CheckRegister16 ())
    {
      case -1:
        fseek (srcasmfile, fptr, SEEK_SET);
        ExtAccumulator(3);                   /* 16 bit register wasn't found - try to evaluate the 8 bit version */
        break;

      case 2:
        if (GetSym () == comma)
          {
            GetSym ();
            reg16 = CheckRegister16 ();
            if (reg16 >= 0 && reg16 <= 3)
              {
                *codeptr++ = 237;
                *codeptr++ = 66 + 16 * reg16;
                PC += 2;
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
          }
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        break;

      default:
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;
    }
}


void
ADC (void)
{
  int reg16;
  long fptr;

  fptr = ftell (srcasmfile);

  GetSym ();
  switch (CheckRegister16 ())
    {
      case -1:
        fseek (srcasmfile, fptr, SEEK_SET);
        ExtAccumulator(1);                   /* 16 bit register wasn't found - try to evaluate the 8 bit version */
        break;

      case 2:
        if (GetSym () == comma)
          {
            GetSym ();
            reg16 = CheckRegister16 ();
            if (reg16 >= 0 && reg16 <= 3)
              {
                *codeptr++ = 237;
                *codeptr++ = 74 + 16 * reg16;
                PC += 2;
              }
            else
              ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
          }
        else
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
        break;

      default:
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;
    }
}


void
ArithLog8_instr (int opcode)
{
  long reg;

  if (GetSym () == lparen)
    {
      switch (reg = IndirectRegisters ())
        {
          case 2:
            *codeptr++ = 128 + opcode * 8 + 6;  /* xxx  A,(HL) */
            ++PC;
            break;

          case 5:           /* xxx A,(IX+d) */
          case 6:
            if (reg == 5)
              *codeptr++ = 221;
            else
              *codeptr++ = 253; /* xxx A,(IY+d) */
            *codeptr++ = 128 + opcode * 8 + 6;
            ExprSigned8 (2);
            PC += 3;
            break;

          default:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;
        }
    }
  else
    {               /* no indirect addressing, try to get an 8bit register */
      reg = CheckRegister8 ();
      switch (reg)
        {
          /* 8bit register wasn't found, try to evaluate an expression */
          case -1:
            *codeptr++ = 192 + opcode * 8 + 6;    /* xxx  A,n */
            ExprUnsigned8 (1);
            PC += 2;
            break;

          case 6:     /* xxx A,F illegal */
          case 8:     /* xxx A,I illegal */
          case 9:     /* xxx A,R illegal */
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            break;

          default:
            if (reg & 8)
              {           /* IXl or IXh */
                *codeptr++ = 221;
                ++PC;
              }
            else if (reg & 16)
              {           /* IYl or IYh */
                *codeptr++ = 253;
                ++PC;
              }
            reg &= 7;

            *codeptr++ = (unsigned char) (128 + opcode * 8 + reg);  /* xxx  A,r */
            ++PC;
            break;
        }
    }
}



void
INC (void)
{
  int reg16;

  GetSym ();
  switch (reg16 = CheckRegister16 ())
    {
      case -1:
        IncDec_8bit_instr (4);    /* 16 bit register wasn't found - try to evaluate the 8bit version */
        break;

      case 4:
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;

      case 5:
        *codeptr++ = 221;
        *codeptr++ = 35;
        PC += 2;
        break;

      case 6:
        *codeptr++ = 253;
        *codeptr++ = 35;
        PC += 2;
        break;

      default:
        *codeptr++ = 3 + reg16 * 16;
        ++PC;
        break;
    }
}


void
DEC (void)
{
  int reg16;

  GetSym ();
  switch (reg16 = CheckRegister16 ())
    {
      case -1:
        IncDec_8bit_instr (5);    /* 16 bit register wasn't found - try to evaluate the 8bit version */
        break;

      case 4:
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
        break;

      case 5:
        *codeptr++ = 221;
        *codeptr++ = 43;
        PC += 2;
        break;

      case 6:
        *codeptr++ = 253;
        *codeptr++ = 43;
        PC += 2;
        break;

      default:
        *codeptr++ = 11 + reg16 * 16;
        ++PC;
        break;
    }
}


void
IncDec_8bit_instr (int opcode)
{
  long reg;

  if (sym == lparen)
    {
      switch (reg = IndirectRegisters ())
        {
          case 2:
            *codeptr++ = 48 + opcode; /* INC/DEC (HL) */
            ++PC;
            break;

          case 5:     /* INC/DEC (IX+d) */
          case 6:
            if (reg == 5)
              *codeptr++ = 221;
            else
              *codeptr++ = 253;   /* INC/DEC (IY+d) */
            *codeptr++ = 48 + opcode;
            ExprSigned8 (2);
            PC += 3;
            break;

          default:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;
        }
    }
  else
    {               /* no indirect addressing, try to get an 8bit register */
      reg = CheckRegister8 ();
      switch (reg)
        {
          case 6:
          case 8:
          case 9:
            /* INC/DEC I ;  INC/DEC R illegal */
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            break;

          case 12:
          case 13:
            *codeptr++ = 221;
            *codeptr++ = (unsigned char) (reg & 7) * 8 + opcode;  /* INC/DEC  ixh,ixl */
            PC += 2;
            break;

          case 20:
          case 21:
            *codeptr++ = 253;
            *codeptr++ = (unsigned char) (reg & 7) * 8 + opcode;  /* INC/DEC  iyh,iyl */
            PC += 2;
            break;

          default:
            *codeptr++ = (unsigned char) reg * 8 + opcode;    /* INC/DEC  r */
            ++PC;
            break;
        }
    }
}



void
BitTest_instr (int opcode)
{
  long bitnumber, reg;
  expression_t *postfixexpr;

  GetSym ();
  if ((postfixexpr = ParseNumExpr ()) != NULL)
    {               /* Expression must not be stored in object file */
      if (postfixexpr->rangetype & NOTEVALUABLE)
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymNotDefined);
        }
      else
        {
          bitnumber = EvalPfixExpr (postfixexpr);
          if (bitnumber >= 0 && bitnumber <= 7)
            {           /* bit 0 - 7 */
              if (sym == comma)
                {
                  if (GetSym () == lparen)
                    {
                      switch ((reg = IndirectRegisters ()))
                        {
                          case 2:
                            *codeptr++ = 203; /* (HL)  */
                            *codeptr++ = opcode + (unsigned char) (bitnumber * 8 + 6);
                            PC += 2;
                            break;

                          case 5:
                          case 6:
                            if (reg == 5)
                              *codeptr++ = 221;
                            else
                              *codeptr++ = 253;
                            *codeptr++ = 203;
                            ExprSigned8 (2);
                            *codeptr++ = opcode + (unsigned char) (bitnumber * 8 + 6);
                            PC += 4;
                            break;

                          default:
                            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
                            break;
                        }
                    }
                  else
                    {       /* no indirect addressing, try to get an 8bit register */
                      reg = CheckRegister8 ();
                      switch (reg)
                        {
                          case 6:
                          case 8:
                          case 9:
                          case -1:
                            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
                            break;

                          default:
                            *codeptr++ = 203;
                            *codeptr++ = (unsigned char) (opcode + bitnumber * 8 + reg);
                            PC += 2;
                        }
                    }
                }
              else
                ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            }
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IntegerRange);
        }
      RemovePfixlist (postfixexpr);
    }
}


void
RotShift_instr (int opcode)
{
  long reg;

  if (GetSym () == lparen)
    {
      switch ((reg = IndirectRegisters ()))
        {
          case 2:
            *codeptr++ = 203;
            *codeptr++ = (unsigned char) (opcode * 8 + 6);
            PC += 2;
            break;

          case 5:
          case 6:
            if (reg == 5)
              *codeptr++ = 221;
            else
              *codeptr++ = 253;
            *codeptr++ = 203;
            ExprSigned8 (2);
            *codeptr++ = (unsigned char) (opcode * 8 + 6);
            PC += 4;
            break;

          default:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_Syntax);
            break;
        }
    }
  else
    {               /* no indirect addressing, try to get an 8bit register */
      reg = CheckRegister8 ();
      switch (reg)
        {
          case 6:
          case 8:
          case 9:
          case -1:
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_IllegalIdent);
            break;

          default:
            *codeptr++ = 203;
            *codeptr++ = (unsigned char) (opcode * 8 + reg);
            PC += 2;
        }
    }
}


/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

  Copyright (C) 1991-2006, Gunther Strube, gbs@users.sourceforge.net

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


/* global functions */
symfunc SearchAsmFunction (const char *ident);

void ALIGN(void);
void BINARY (void);
void DEFB (void), DEFC (void), DEFM (void), DEFMZ (void), DEFW (void), DEFP (void), DEFL (void);
void DEFGROUP (void), DEFVARS (void), DEFS (void);
void ERROR(void), LINE(void);
void DeclExternIdent (void), DeclGlobalIdent (void), DeclLibIdent (void), DeclGlobalLibIdent (void);
void DeclModule (void);
void DefSym (void), UnDefineSym(void);
void IFstat (void), ELSEstat (void), ENDIFstat (void);
void ENDDEFstat (void);
void IncludeFile (void);
void ListingOn (void), ListingOff (void);
void ORG (void);
void ParseDirectives (enum flag interpret);
void ParseMpmIdent (enum flag interpret);

/* Z88 specific functions implemented in z80_asmdrctv.c */
void CALLOZ (void);
void EXTCALL (void);
void CALLPKG (void);
void FPP (void);
void INVOKE (void); /* ported from z80asm for Ti83/Ti83Plus target */

/* Z80 instruction implemented in z80_instr.c */
void LD (void);
void ADC (void), ADD (void), DEC (void), IM (void), IN (void), INC (void);
void JR (void), LD (void), OUT (void), RET (void), SBC (void);
void RST (void);
void AND (void), BIT (void), CALL (void), CCF (void), CP (void), CPD (void);
void CPDR (void), CPI (void), CPIR (void), CPL (void), DAA (void);
void DI (void), DJNZ (void);
void EI (void), EX (void), EXX (void), HALT (void);
void IND (void), INDR (void), INI (void), INIR (void), JP (void);
void LDD (void), LDDR (void);
void LDI (void), LDIR (void), NEG (void), NOP (void), OR (void), OTDR (void), OTIR (void);
void OUTD (void), OUTI (void), POP (void), PUSH (void), RES (void);
void RETI (void), RETN (void);
void RL (void), RLA (void), RLC (void), RLCA (void), RLD (void), RR (void), RRA (void), RRC (void);
void RRCA (void), RRD (void);
void SCF (void), SET (void), SLA (void), SLL (void), SRA (void);
void SRL (void), SUB (void), XOR (void);
void ArithLog8_instr (int opcode);
void ExtAccumulator (int opcode);
void JP_instr (int opc0, int opc);
void Subroutine_addr (int opc0, int opc);
void JP_instr (int opc0, int opc);
void PushPop_instr (int opcode);
void RotShift_instr (int opcode);
void BitTest_instr (int opcode);
void IncDec_8bit_instr (int opcode);
void LD_HL8bit_indrct (void);
void LD_16bit_reg (void);
void LD_index8bit_indrct (int reg);
void LD_address_indrct (long exprptr);
void LD_r_8bit_indrct (int reg);

/* Assembler functions implemented in asmdrctv.c */
symbol_t *AsmSymLinkAddr (void *);
symbol_t *AsmSymDay (void);
symbol_t *AsmSymHour (void);
symbol_t *AsmSymMinute (void);
symbol_t *AsmSymMinute (void);
symbol_t *AsmSymMonth (void);
symbol_t *AsmSymAssemblerPC (void);
symbol_t *AsmSymSecond (void);
symbol_t *AsmSymYear (void);

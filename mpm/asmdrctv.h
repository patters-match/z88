
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


/* global functions */
ptrfunc SearchFunction (identfunc_t asmident[], size_t totalid);
void ALIGN(void);
void BINARY (void);
void DEFB (void), DEFC (void), DEFM (void), DEFMZ (void), DEFW (void), DEFP (void), DEFL (void);
void DEFGROUP (void), DEFVARS (void), DEFS (void);
void ERROR(void);
void DeclExternIdent (void), DeclGlobalIdent (void), DeclLibIdent (void), DeclGlobalLibIdent (void);
void DeclModule (void);
void DefSym (void);
void IFstat (void), ELSEstat (void), ENDIFstat (void);
void IncludeFile (void);
void ListingOn (void), ListingOff (void);
void ORG (void);
void ParseDirectives (enum flag interpret);
void ParseMpmIdent (enum flag interpret);

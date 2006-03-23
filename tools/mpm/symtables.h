
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
char       *AllocIdentifier (size_t len);
int        cmpidstr (symbol_t * kptr, symbol_t * p);
int        cmpidval (symbol_t * kptr, symbol_t * p);
symbol_t   *CreateSymNode (symbol_t *symptr);
symbol_t   *CreateSymbol (char *identifier, symvalue_t value, unsigned long symboltype, module_t *symowner);
void       DeclSymGlobal (char *identifier, unsigned long libtype);
void       DeclSymExtern (char *identifier, unsigned long libtype);
symbol_t   *DefineDefSym (char *identifier, long value, avltree_t **root);
symbol_t   *DefineSymbol (char *identifier, symvalue_t value, unsigned long symboltype);
symbol_t   *GetSymPtr (char *identifier);
symbol_t   *FindSymbol (char *identifier, avltree_t * treeptr);
void       FreeSym (symbol_t * node);

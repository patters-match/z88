
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
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "datastructs.h"
#include "symtables.h"
#include "errors.h"


/* local functions */
static symbol_t *DefLocalSymbol (char *identifier, symvalue_t value, unsigned long symboltype);
static void InsertPageRef (symbol_t * symptr, short pageno);
static void AppendPageRef (symbol_t * symptr, short pageno);
static void MovePageRefs (char *identifier, symbol_t * definedsym);
static pagereferences_t *AllocSymRef (void);
static pagereference_t *AllocPageRef (void);
static symbol_t *AllocSymbol (void);


/* external variables */
extern int PAGENO;
extern enum flag symtable, uselistingfile, pass1;
extern FILE *listfile;
extern module_t *CURRENTMODULE;    /* pointer to current module */


/* global variables */
avltree_t *globalroot = NULL, *staticroot = NULL;
symbol_t *gAsmpcPtr;        /* pointer to Assembler PC symbol (defined in global symbol_t variables) */


symbol_t *
CreateSymNode (symbol_t * symptr)
{
  return CreateSymbol (symptr->symname, symptr->symvalue, symptr->type, symptr->owner);
}


symbol_t *
CreateSymbol (char *identifier, symvalue_t value, unsigned long symboltype, module_t *symowner)
{
  symbol_t *newsym;

  if ((newsym = AllocSymbol ()) == NULL)
    { /* Create area for a new symbol structure */
      ReportError (NULL, 0, Err_Memory);
      return NULL;
    }
  newsym->symname = AllocIdentifier (strlen (identifier) + 1);  /* Allocate area for a new symbol identifier */
  if (newsym->symname != NULL)
    strcpy (newsym->symname, identifier);   /* store identifier symbol */
  else
    {
      free (newsym);        /* Ups no more memory left.. */
      ReportError (NULL, 0, Err_Memory);
      return NULL;
    }

  newsym->references = NULL;
  newsym->owner = symowner;
  newsym->type = symboltype;
  newsym->symvalue = value;

  if ((pass1 == ON) && (symtable == ON) && (listfile != NULL))
    InsertPageRef (newsym, PAGENO);     /* store first page reference of listfile for this symbol */

  return newsym;        /* pointer to new symbol node */
}



int
cmpidstr (symbol_t * kptr, symbol_t * p)
{
  return strcmp (kptr->symname, p->symname);
}


int
cmpidval (symbol_t * kptr, symbol_t * p)
{
  return (kptr->symvalue - p->symvalue);
}



/*
 * DefineSymbol will create a record in memory, inserting it into an AVL tree (or creating the first record)
 */
symbol_t *
DefineSymbol (char *identifier,
              symvalue_t value,         /* value of symbol, label */
              unsigned long symboltype) /* symbol is either address label or constant */
{
  symbol_t *foundsymbol;

  if ((foundsymbol = FindSymbol (identifier, globalroot)) == NULL)  /* symbol not declared as global/extern */
    return DefLocalSymbol (identifier, value, symboltype);
  else if (foundsymbol->type & SYMXDEF)
    {
      if ((foundsymbol->type & SYMDEFINED) == 0)
        {
          /* symbol declared global, but not yet defined */
          foundsymbol->symvalue = value;
          /* defined, and typed as address label or constant */
          foundsymbol->type |= (symboltype | SYMDEFINED);

          foundsymbol->owner = CURRENTMODULE;   /* owner of symbol is always creator */
          if ((pass1 == ON) && (symtable == ON) && (listfile != NULL))
            {
              /* First element in list is definition of symbol */
              InsertPageRef (foundsymbol, PAGENO);
              /* Move page references from possible forward referenced symbol */
              MovePageRefs (identifier, foundsymbol);
            }
          return foundsymbol;
        }
      else
        {
          ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymDefined);  /* global symbol already defined */
          return NULL;
        }
    }
  else
    /* Extern declaration of symbol, now define local symbol. */
    return DefLocalSymbol (identifier, value, symboltype);

  /* the extern symbol is now no longer accessible */
}


static symbol_t *
DefLocalSymbol (char *identifier,
                symvalue_t value,           /* value of symbol, label */
                unsigned long symboltype)   /* symbol is either address label or constant */
{
  symbol_t *foundsymbol;

  if ((foundsymbol = FindSymbol (identifier, CURRENTMODULE->localroot)) == NULL)
    {               /* symbol not declared as local */
      foundsymbol = CreateSymbol (identifier, value, symboltype | SYMLOCAL | SYMDEFINED, CURRENTMODULE);
      if (foundsymbol == NULL)
        return NULL;
      else
        Insert (&CURRENTMODULE->localroot, foundsymbol, (int (*)()) cmpidstr);

      if ((pass1 == ON) && (symtable == ON) && (listfile != NULL))
         MovePageRefs (identifier, foundsymbol);     /* Move page references from forward referenced symbol */
      return foundsymbol;
    }
  else if ((foundsymbol->type & SYMDEFINED) == 0)
    {               /* symbol declared local, but not yet defined */
      foundsymbol->symvalue = value;
      /* local symbol type set to address label or constant */
      foundsymbol->type |= symboltype | SYMLOCAL | SYMDEFINED;

      foundsymbol->owner = CURRENTMODULE;   /* owner of symbol is always creator */
      if ((pass1 == ON) && (symtable == ON) && (listfile != NULL))
        {
          InsertPageRef (foundsymbol, PAGENO);  /* First element in list is definition of symbol */
          /* Move page references from possible forward referenced symbol */
          MovePageRefs (identifier, foundsymbol);
        }
      return foundsymbol;
    }
  else
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymDefined);  /* local symbol already defined */
      return NULL;
    }
}




/*
 * search for symbol in either local tree or global tree, return found pointer if defined/declared, otherwise return
 * NULL
 */
symbol_t *
GetSymPtr (char *identifier)
{
  symbol_t *symbolptr;        /* pointer to current search node in AVL tree */
  symvalue_t symval;

  if ((symbolptr = FindSymbol (identifier, CURRENTMODULE->localroot)) == NULL)
    {
      if ((symbolptr = FindSymbol (identifier, globalroot)) == NULL)
        {
          if ((pass1 == ON) && (symtable == ON) && (listfile != NULL))
            {
              if ((symbolptr = FindSymbol (identifier, CURRENTMODULE->notdeclroot)) == NULL)
                {
                  symval = 0;
                  symbolptr = CreateSymbol (identifier, symval, SYM_NOTDEFINED, CURRENTMODULE);
                  if (symbolptr != NULL)
                    Insert (&CURRENTMODULE->notdeclroot, symbolptr, (int (*)()) cmpidstr);
                }
              else
                {
                  /* symbol found in forward referenced tree, note page reference */
                  AppendPageRef (symbolptr, PAGENO);
                }
            }

            return NULL;
        }
      else
        {
          if ((pass1 == ON) && (symtable == ON) && (listfile != NULL)) {
            AppendPageRef (symbolptr, PAGENO);  /* symbol found as global/extern declaration */
          }
          return symbolptr; /* symbol at least declared - return pointer to it... */
        }
    }
  else
    {
      if ((pass1 == ON) && (symtable == ON) && (listfile != NULL))
        AppendPageRef (symbolptr, PAGENO);  /* symbol found as local declaration */
      return symbolptr;     /* symbol at least declared - return pointer to it... */
    }
}



int
compidentifier (char *identifier, symbol_t * p)
{
  return strcmp (identifier, p->symname);
}


/*
 * return pointer to found symbol in a symbol tree, otherwise NULL if not found
 */
symbol_t *
FindSymbol (char *identifier,   /* pointer to current identifier */
            avltree_t * treeptr)  /* pointer to root of AVL tree */
{
  symbol_t *found;

  if (treeptr == NULL)
    return NULL;
  else
    {
      found = Find (treeptr, identifier, (int (*)()) compidentifier);
      if (found == NULL)
        return NULL;
      else
        {
          found->type |= SYMTOUCHED;
          return found;     /* symbol found (declared/defined) */
        }
    }
}



void
DeclSymGlobal (char *identifier, unsigned long libtype)
{
  symbol_t *foundsym, *clonedsym;
  symvalue_t symval;

  if ((foundsym = FindSymbol (identifier, CURRENTMODULE->localroot)) == NULL)
    {
      if ((foundsym = FindSymbol (identifier, globalroot)) == NULL)
        {
          symval = 0;
          foundsym = CreateSymbol (identifier, symval, SYM_NOTDEFINED | SYMXDEF | libtype, CURRENTMODULE);
          if (foundsym != NULL)
            Insert (&globalroot, foundsym, (int (*)()) cmpidstr);   /* declare symbol as global */
        }
      else
        {
          if (foundsym->owner != CURRENTMODULE)
            {                       /* this symbol is declared in another module */
              if (foundsym->type & SYMXREF)
                {
                  foundsym->owner = CURRENTMODULE;  /* symbol now owned by this module */
                  foundsym->type &= XREF_OFF;       /* re-declare symbol as global if symbol was */
                  foundsym->type |= SYMXDEF | libtype;  /* declared extern in another module */
                }
               else                              /* cannot declare two identical global's */
                 ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymDeclGlobalModule);    /* Already declared global */
            }
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymRedeclaration);    /* re-declaration not allowed */
        }
    }
  else
    {
      if (FindSymbol (identifier, globalroot) == NULL)
        {
          /* If no global symbol of identical name has been created, then re-declare local symbol as global symbol */
          foundsym->type &= SYMLOCAL_OFF;
          foundsym->type |= SYMXDEF;
          clonedsym = CreateSymbol (foundsym->symname, foundsym->symvalue, foundsym->type, CURRENTMODULE);
          if (clonedsym != NULL)
            {
              Insert (&globalroot, clonedsym, (int (*)()) cmpidstr);

              /* original local symbol cloned as global symbol, now delete old local ... */
              DeleteNode (&CURRENTMODULE->localroot, foundsym, (int (*)()) cmpidstr, (void (*)()) FreeSym);
            }
        }
      else
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymDeclGlobal);  /* already declared global */
   }
}



void
DeclSymExtern (char *identifier, unsigned long libtype)
{
  symbol_t *foundsym, *extsym;
  symvalue_t symval;

  if ((foundsym = FindSymbol (identifier, CURRENTMODULE->localroot)) == NULL)
    {
      if ((foundsym = FindSymbol (identifier, globalroot)) == NULL)
        {
          symval = 0;
          foundsym = CreateSymbol (identifier, symval, SYM_NOTDEFINED | SYMXREF | libtype, CURRENTMODULE);
          if (foundsym != NULL)
            Insert (&globalroot, foundsym, (int (*)()) cmpidstr);   /* declare symbol as extern */
        }
      else if (foundsym->owner == CURRENTMODULE)
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymRedeclaration);    /* Re-declaration not allowed */
    }
  else
   {
      if (FindSymbol (identifier, globalroot) == NULL)
        {
          /* If no external symbol of identical name has been declared, then re-declare local
             symbol as external symbol, but only if local symbol is not defined yet */
          if ((foundsym->type & SYMDEFINED) == 0)
            {
              symval = 0;
              foundsym->type &= SYMLOCAL_OFF;
              foundsym->type |= (SYMXREF | libtype);
              extsym = CreateSymbol (identifier, symval, foundsym->type, CURRENTMODULE);
              if (extsym != NULL)
                {
                  Insert (&globalroot, extsym, (int (*)()) cmpidstr);

                  /* original local symbol cloned as external symbol, now delete old local ... */
                  DeleteNode (&CURRENTMODULE->localroot, foundsym, (int (*)()) cmpidstr, (void (*)()) FreeSym);
                }
            }
          else
            ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymDeclLocal);    /* already declared local */
        }
      else
        ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymRedeclaration);  /* re-declaration not allowed */
   }
}


static void
InsertPageRef (symbol_t * symptr, short pageno)
{
  pagereference_t *newref, *tmpptr;
  pagereferences_t *pagerefs;

  pagerefs = symptr->references;
  if (pagerefs == NULL)
    {
      if ((pagerefs = AllocSymRef ()) == NULL)
        {
          ReportError (NULL, 0, Err_Memory);
          return;
        }
      pagerefs->firstref = NULL;
      pagerefs->lastref = NULL;                   /* Page reference list initialised... */
      symptr->references = pagerefs;
    }

  if (pagerefs->firstref != NULL)
    if (pagerefs->firstref->pagenr == pageno)     /* symbol reference on the same page - ignore */
      return;

  if ((newref = AllocPageRef ()) == NULL)     /* new page reference of symbol - allocate... */
    {
      ReportError (NULL, 0, Err_Memory);
      return;
    }
  else
    {
      newref->pagenr = pageno;
      newref->nextref = pagerefs->firstref;   /* next reference will be current first reference */
    }

  if (pagerefs->firstref == NULL)
    {                                 /* If this is the first reference, then the... */
      pagerefs->firstref = newref;    /* Current reference (last) points at new reference */
      pagerefs->lastref = newref;     /* first page reference is also last page reference. */
    }
  else
    {
      pagerefs->firstref = newref;                  /* Current reference (last) points at new reference */
      if (newref->pagenr == pagerefs->lastref->pagenr)
        {                                           /* last reference = new reference */
          tmpptr = newref;
          while (tmpptr->nextref != pagerefs->lastref)
            tmpptr = tmpptr->nextref;               /* get reference before last reference */
          free (tmpptr->nextref);                   /* remove redundant reference */
          tmpptr->nextref = NULL;                   /* end of list */
          pagerefs->lastref = tmpptr;               /* update pointer to last reference */
        }
    }
}


static void
AppendPageRef (symbol_t * symptr, short pageno)
{
  pagereference_t *newref;
  pagereferences_t *pagerefs;

  pagerefs = symptr->references;
  if (pagerefs == NULL)
    {
      InsertPageRef(symptr, pageno);
      return;
    }

  if (pagerefs->lastref != NULL)
    if ((pagerefs->firstref->pagenr == pageno) || (pagerefs->lastref->pagenr == pageno))
      /* symbol reference on the same page - ignore */
      return;

  if ((newref = AllocPageRef ()) == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      return;
    }
  else
    {
      newref->pagenr = pageno;
      newref->nextref = NULL;
    }

  if (pagerefs->lastref == NULL)
    {
      pagerefs->lastref = newref;
      pagerefs->firstref = newref;            /* First page reference in list */
    }
  else
    {
      pagerefs->lastref->nextref = newref;    /* current reference (last) points at new reference */
      pagerefs->lastref = newref;             /* ptr to last reference updated to new reference */
    }
}



/*
 * Move pointer to list of page references from forward symbol and
 * append it to first reference of defined symbol.
 */
static void
MovePageRefs (char *identifier, symbol_t * definedsym)
{
  symbol_t *forwardsym;
  pagereference_t *tmpref;
  pagereferences_t *definedrefs, *forwardrefs;

  definedrefs = definedsym->references;
  if (definedrefs == NULL) return;      /* no page references */

  if ((forwardsym = FindSymbol (identifier, CURRENTMODULE->notdeclroot)) != NULL)
    {
      forwardrefs = forwardsym->references;
      if (forwardrefs == NULL) return;      /* no page references */

      if (definedrefs->firstref->pagenr == forwardrefs->lastref->pagenr)
        {
          if (forwardrefs->firstref != forwardrefs->lastref)
            {
              tmpref = forwardrefs->firstref;    /* more than one reference */
              while (tmpref->nextref != forwardrefs->lastref)
                tmpref = tmpref->nextref;   /* get reference before last reference */

              free (tmpref->nextref);   /* remove redundant reference */
              tmpref->nextref = NULL;   /* end of list */
              forwardrefs->lastref = tmpref;     /* update pointer to last reference */
              definedrefs->firstref->nextref = forwardrefs->firstref;
              definedrefs->lastref = forwardrefs->lastref;
              /* forward page reference list appended */
           }
         else
            free (forwardrefs->firstref);    /* remove the redundant reference */
        }
      else
        {
          definedrefs->firstref->nextref = forwardrefs->firstref;
          definedrefs->lastref = forwardrefs->lastref;
          /* last reference not on the same page as definition */
          /* forward page reference list now appended  */
        }

      free (forwardrefs);    /* remove pointer information to forward page reference list */
      forwardsym->references = NULL;
      /* symbol is not needed anymore, remove from symbol table of forward references */
      DeleteNode (&CURRENTMODULE->notdeclroot, forwardsym, (int (*)()) cmpidstr, (void (*)()) FreeSym);
    }
}


symbol_t *
DefineDefSym (char *identifier, long value, avltree_t ** root)
{
  symbol_t *staticsym;
  symvalue_t symval;

  if (FindSymbol (identifier, *root) == NULL)
    {
      symval = value;
      staticsym = CreateSymbol (identifier, symval, SYMDEF | SYMDEFINED, NULL);
      if (staticsym != NULL)
        {
          Insert (root, staticsym, (int (*)()) cmpidstr);
          return staticsym;
        }
      else
        return NULL;
    }
  else
    {
      ReportError (CURRENTFILE->fname, CURRENTFILE->line, Err_SymDefined);  /* symbol already defined */
      return NULL;
    }
}


char *
AllocIdentifier (size_t len)
{
  return (char *) malloc (len);
}


void
FreeSym (symbol_t * node)
{
  pagereference_t *pref, *tmpref;

  if (node->references != NULL)
    {
      if (node->references->firstref != NULL)
        {
          pref = node->references->firstref;    /* get first page reference in list */
          do
            {
              tmpref = pref;
              pref = pref->nextref;
              free (tmpref);
            }
          while (pref != NULL); /* free page reference list... */
        }
      free (node->references);  /* Then remove head/end pointer record to list */
    }
  if (node->symname != NULL)
    free (node->symname);   /* release symbol identifier */

  free (node);          /* then release the symbol record */
}


static symbol_t *
AllocSymbol (void)
{
  return (symbol_t *) malloc (sizeof (symbol_t));
}


static pagereferences_t *
AllocSymRef (void)
{
  return (pagereferences_t *) malloc (sizeof (pagereferences_t));
}


static pagereference_t *
AllocPageRef (void)
{
  return (pagereference_t *) malloc (sizeof (pagereference_t));
}

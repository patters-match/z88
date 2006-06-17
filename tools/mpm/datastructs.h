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



#include "avltree.h"    /* base symbol data structures and routines that manages a symbol table */

typedef void (*ptrfunc) (void);                           /* ptr to function returning void */
typedef int (*fptr) (const void *, const void *);

typedef
struct asmsym       { char *asm_mnem;           /* identifier definition & function implementation */
                      ptrfunc asm_func;
                    } identfunc_t;

/* Structured data types : */

enum flag           { OFF, ON };

enum symbols        { space, bin_and, dquote, squote, semicolon, comma, fullstop, lparen, lcurly, lexpr, rexpr, rcurly, rparen,
                      plus, minus, multiply, divi, mod, bin_xor, assign, bin_or, bin_nor, colon = bin_nor, bin_not, less,
                      mod256 = less, greater, div256 = greater, log_not, constexpr, newline, power, lshift, rshift,
                      lessequal, greatequal, notequal, name, number, decmconst, hexconst, binconst, charconst, registerid,
                      strconq = fullstop, negated, nil, ifstatm, elsestatm, endifstatm, enddefstatm, label
                    };

typedef
struct pfixstack    { long                stackconstant;    /* stack structure used to evaluate postfix expressions */
                      struct pfixstack   *prevstackitem;    /* pointer to previous element on stack */
                    } pfixstack_t;

typedef
struct postfixexpr  { struct postfixexpr *nextoperand;      /* pointer to next element in postfix expression */
                      long               operandconst;
                      enum symbols       operatortype;
                      char               *id;               /* pointer to identifier */
                      unsigned long      type;              /* type of identifier (local, global, rel. address or constant) */
                    } postfixexpr_t;

typedef
struct expression   { struct expression  *nextexpr;         /* pointer to next expression */
                      postfixexpr_t      *firstnode;
                      postfixexpr_t      *currentnode;
                      unsigned long      rangetype;         /* range type of evaluated expression */
                      enum flag          stored;            /* Flag to indicate that expression has been stored to object file */
                      char               *infixexpr;        /* pointer to ASCII infix expression */
                      char               *infixptr;         /* pointer to current char in infix expression */
                      long               codepos;           /* rel. position in module code to patch (in pass 2) */
                      char               *srcfile;          /* expr. in file 'srcfile' - allocated name area deleted by ReleaseFile */
                      short              curline;           /* expression in line of source file */
                      long               listpos;           /* position in listing file to patch (in pass 2) */
                    } expression_t;

typedef
struct exprlist     { expression_t        *firstexpr;       /* header of list of expressions in current module */
                      expression_t        *currexpr;
                    } expressions_t;

typedef
struct usedfile     { struct usedfile    *nextusedfile;
                      struct sourcefile  *ownedsourcefile;
                    } usedsrcfile_t;

typedef
struct sourcefile   { struct sourcefile  *prevsourcefile;   /* pointer to previously parsed source file */
                      struct sourcefile  *newsourcefile;    /* pointer to new source file to be parsed */
                      usedsrcfile_t      *usedsourcefile;   /* list of pointers to used files owned by this file */
                      long               filepointer;       /* file pointer of current source file */
                      short              line;              /* current line number of current source file */
                      char               *fname;            /* pointer to file name of current source file */
                    } sourcefile_t;

typedef
struct JRPC         { struct JRPC        *nextref;          /* pointer to next JR address reference  */
                      unsigned long      pcaddr;            /* absolute of PC address of Branch Relative instruction  */
                    } pcrelative_t;

typedef
struct JRPC_Hdr     { pcrelative_t       *firstref;         /* pointer to first JR address reference in list */
                      pcrelative_t       *lastref;          /* pointer to last JR address reference in list */
                    } pcrelativelist_t;

typedef
struct module       { struct module      *nextmodule;       /* pointer to next module */
                      char               *mname;            /* pointer to string of module name */
                      unsigned long      startoffset;       /* this module's start offset from start of code buffer */
                      unsigned long      origin;            /* address origin of current machine code module during linking */
                      sourcefile_t       *cfile;            /* pointer to current file record */
                      avltree_t          *notdeclroot;      /* pointer to root of symbols not yet declared/defined */
                      avltree_t          *localroot;        /* pointer to root of local symbols tree */
                      expressions_t      *mexpr;            /* pointer to expressions in this module */
                      pcrelativelist_t   *JRaddr;           /* pointer to list of JR PC addresses */
                    } module_t;

typedef
struct modules      { module_t           *first;            /* pointer to first module */
                      module_t           *last;             /* pointer to current/last module */
                    } modules_t;

typedef
struct pageref      { struct pageref     *nextref;          /* pointer to next page reference of symbol */
                      short              pagenr;            /* page number where symbol is referenced */
                    } pagereference_t;                      /* the first symbol node in identifies the symbol definition */

typedef
struct symref       { pagereference_t    *firstref;         /* Pointer to first page number reference of symbol */
                      pagereference_t    *lastref;          /* Pointer to last/current page number reference */
                    } pagereferences_t;                     /* NB: First reference defines creation of symbol */

typedef long symvalue_t;                                    /* symbol value is a 32bit integer */

typedef
struct node         { unsigned long      type;              /* type of symbol */
                      char               *symname;          /* pointer to symbol identifier */
                      symvalue_t         symvalue;          /* value of symbol (size dependents on type) */
                      pagereferences_t   *references;       /* pointer to all found page references of symbol */
                      module_t           *owner;            /* pointer to module which owns symbol */
                    } symbol_t;

typedef
struct labels       { struct labels      *prevlabel;        /* pointer to previous label occurence on stack */
                      symbol_t           *labelsym;         /* pointer to label in symbol table */
                    } labels_t;

typedef
struct pathlist     { struct pathlist   *nextdir;           /* pointer to next directory path in list */
                      char              *directory;         /* name of directory */
                    } pathlist_t;

typedef
struct libfile      { struct libfile    *nextlib;           /* pointer to next library file in list */
                      char              *libfilename;       /* filename of library (incl. extension) */
                      const char        *libwatermark;      /* pointer to watermark identifier identified at start of library file */
                    } libfile_t;

typedef
struct liblist      { libfile_t         *firstlib;          /* pointer to first library file specified from command line */
                      libfile_t         *currlib;           /* pointer to current library file specified from command line */
                    } libraries_t;

typedef
struct libobject    { char              *libname;           /* name of library module (the LIB reference name) */
                      libfile_t         *library;           /* pointer to library file information */
                      long              modulestart;        /* base pointer of beginning of object module inside library file */
                    } libobject_t;

typedef
struct linkedmod    { struct linkedmod  *nextlink;          /* pointer to next module link */
                      char              *objfilename;       /* filename of library/object file (incl. extension) */
                      long              modulestart;        /* base pointer of beginning of object module */
                      module_t          *moduleinfo;        /* pointer to main module information */
                    } tracedmodule_t;

typedef
struct linkmodlist  { tracedmodule_t    *firstlink;         /* pointer to first linked object module */
                      tracedmodule_t    *lastlink;          /* pointer to last linked module in list */
                    } tracedmodules_t;


#define CURRENTFILE     CURRENTMODULE->cfile
#define ASSEMBLERPC     "$PC"
#define __ASSEMBLERPC   "ASMPC"                             /* backward compatibility with old Z80asm */


/* Bitmasks for symtype */
#define SYMDEFINED      0x01000000                          /* bitmask 00000001 00000000 00000000 00000000 */
#define SYMTOUCHED      0x02000000                          /* bitmask 00000010 00000000 00000000 00000000 */
#define SYMDEF          0x04000000                          /* bitmask 00000100 00000000 00000000 00000000 */
#define SYMADDR         0x08000000                          /* bitmask 00001000 00000000 00000000 00000000 */
#define SYMLOCAL        0x10000000                          /* bitmask 00010000 00000000 00000000 00000000 */
#define SYMXDEF         0x20000000                          /* bitmask 00100000 00000000 00000000 00000000 */
#define SYMXREF         0x40000000                          /* bitmask 01000000 00000000 00000000 00000000 */


/* #define SYM_BASE32      0x00000100                        symbol value is defined as 32bit native integer (long) */
/* #define SYM_BASE64      0x00000200                        symbol value is defined as 64bit integer (dlong_t) */
/* #define SYM_BASE128     0x00000400                        symbol value is defined as 128bit integer (qlong_t) */

#define SYMLOCAL_OFF    0xEFFFFFFF                          /* bitmask 11101111 11111111 11111111 11111111 */
#define XDEF_OFF        0xDFFFFFFF                          /* bitmask 11011111 11111111 11111111 11111111 */
#define XREF_OFF        0xBFFFFFFF                          /* bitmask 10111111 11111111 11111111 11111111 */
#define SYMTYPE         0x78000000                          /* bitmask 01111000 00000000 00000000 00000000 */
#define SYM_NOTDEFINED  0x00000000

/* bitmasks for expression evaluation in rangetype */
#define RANGE           0x000000FF                          /* bitmask 00000000 00000000 00000000 11111111   Range types are 0 - 255 */
#define NOTEVALUABLE    0x80000000                          /* bitmask 10000000 00000000 00000000 00000000   Expression is not evaluable */
#define EVALUATED       0x7FFFFFFF                          /* bitmask 01111111 11111111 11111111 11111111   Expression is not evaluable */
#define CLEAR_EXPRADDR  0xF7FFFFFF                          /* bitmask 11110111 11111111 11111111 11111111   Convert to constant expression */

#define RANGE_JROFFSET8  0
#define RANGE_8UNSIGN    2
#define RANGE_8SIGN      3
#define RANGE_16CONST    4
#define RANGE_16OFFSET   5
#define RANGE_32SIGN     7

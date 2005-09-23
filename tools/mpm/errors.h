
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


#define Err_FileIO 0               /* "File open/read error" */
#define Err_Syntax 1               /* "Syntax error" */
#define Err_SymNotDefined 2        /* "symbol not defined" */
#define Err_Memory 3               /* "Not enough memory" */
#define Err_IntegerRange 4         /* "Integer out of range" */
#define Err_ExprSyntax 5           /* "Syntax error in expression" */
#define Err_ExprBracket 6          /* "Right bracket missing" */
#define Err_ExprOutOfRange 7       /* "Out of range" */
#define Err_SrcfileMissing 8       /* "Source filename missing" */
#define Err_IllegalOption 9        /* "Illegal option" */
#define Err_UnknownIdent 10        /* "Unknown identifier" */
#define Err_IllegalIdent 11        /* "Illegal label/identifier" */
#define Err_MaxCodeSize 12         /* "Max. code size of %ld bytes reached" */
#define Err_Status 13              /* "errors occurred during assembly" */
#define Err_SymDefined 14          /* "symbol already defined" */
#define Err_ModNameDefined 15      /* "Module name already defined" */
#define Err_ModNameMissing 16      /* "Module name not defined" */
#define Err_LibReference 17        /* "Library reference not found" */
#define Err_SymDeclLocal 18        /* "symbol already declared local" */
#define Err_SymDeclGlobal 19       /* "symbol already declared global" */
#define Err_SymDeclExtern 20       /* "symbol already declared external" */
#define Err_NoArguments 21         /* "No command line arguments" */
#define Err_IllegalSrcfile 22      /* "Illegal source filename" */
#define Err_SymDeclGlobalModule 23 /* "symbol declared global in another module" */
#define Err_SymRedeclaration 24    /* "Re-declaration not allowed" */
#define Err_OrgDefined 25          /* "ORG already defined" */
#define Err_ReljumpLocal 26        /* "Relative jump address must be local" */
#define Err_Objectfile 27          /* "Not an MPM object file" */
#define Err_SymResvName 28         /* "Reserved name" */
#define Err_LibfileOpen 29         /* "Couldn't open library file" */
#define Err_Libfile 30             /* "Not a library file" */
#define Err_EnvVariable 31         /* "Environment variable not defined" */
#define Err_IncludeFile 32         /* "Cannot include file recursively" */
#define Warn_Status 33             /* "warnings occurred during assembly" */
#define Warn_OffsetBoundary 34     /* "offset reaches beyond 16K boundary" */

void ReportWarning (char *filename, short lineno, int warnno);
void ReportAsmMessage (char *filename, short lineno, char *message);
void ReportError (char *filename, short linenr, int errnum);
void ReportIOError (char *filename);

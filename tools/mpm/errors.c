
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




#include <stdio.h>
#include <string.h>
#include "config.h"          /* mpm compiler constant definitions */
#include "datastructs.h"     /* mpm data structure definitions */
#include "errors.h"


/* externally defined variables */
extern enum flag asmerror, clinemode;
extern module_t *CURRENTMODULE;
extern FILE *errfile;
extern short clineno;


/* global variables */
int ASSEMBLE_ERROR, ERRORS, TOTALERRORS, WARNINGS, TOTALWARNINGS;


/* local variables */
static char *errmsg[] = {
 "File open/read error",                                         /* 0  */
 "Syntax error",                                                 /* 1  */
 "symbol not defined",                                           /* 2  */
 "Not enough memory",                                            /* 3  */
 "Integer out of range",                                         /* 4  */
 "Syntax error in expression",                                   /* 5  */
 "Right bracket missing",                                        /* 6  */
 "Expression out of range",                                      /* 7  */
 "Source filename missing",                                      /* 8  */
 "Illegal option",                                               /* 9  */
 "Unknown identifier",                                           /* 10 */
 "Illegal label/identifier",                                     /* 11 */
 "Max. code size of %ld bytes reached",                          /* 12 */
 "errors occurred during assembly",                              /* 13 */
 "Symbol already defined",                                       /* 14 */
 "Module name already defined",                                  /* 15 */
 "Module name not defined",                                      /* 16 */
 "Library reference not found",                                  /* 17 */
 "Symbol already declared local",                                /* 18 */
 "Symbol already declared global",                               /* 19 */
 "Symbol already declared external",                             /* 20 */
 "No command line arguments",                                    /* 21 */
 "Illegal source filename",                                      /* 22 */
 "Symbol declared global in another module",                     /* 23 */
 "Re-declaration not allowed",                                   /* 24 */
 "ORG already defined",                                          /* 25 */
 "Relative jump address must be local",                          /* 26 */
 "Mpm object file not recognized",                               /* 27 */
 "Reserved name",                                                /* 28 */
 "Couldn't open library file",                                   /* 29 */
 "Mpm library file not recognized",                              /* 30 */
 "Environment variable not defined",                             /* 31 */
 "Cannot include file recursively",                              /* 32 */
 "warnings occurred during assembly",                            /* 33 */
 "Warning: bank offset reaches beyond 16K boundary"              /* 34 */

};


void
ReportWarning (char *filename, short lineno, int warnno)
{
  char wrnstr[256], wrnflnmstr[128], wrnmodstr[128], wrnlinestr[64];

  wrnflnmstr[0] = '\0';
  wrnmodstr[0] = '\0';
  wrnlinestr[0] = '\0';
  wrnstr[0] = '\0';

  if (filename != NULL)
    sprintf (wrnflnmstr,"File '%s', ", filename);

  if (CURRENTMODULE != NULL)
    if ( CURRENTMODULE->mname != NULL )
      sprintf(wrnmodstr,"Module '%s', ", CURRENTMODULE->mname);

  if (lineno != 0)
    sprintf (wrnlinestr, "at line %d, ", lineno);

  strcpy(wrnstr, wrnflnmstr);
  strcat(wrnstr, wrnmodstr);
  strcat(wrnstr, wrnlinestr);
  strcat(wrnstr, errmsg[warnno]);

  switch(warnno)
    {
      case Warn_Status:
        fprintf (stderr, "%d %s\n", TOTALWARNINGS, errmsg[warnno]);
        break;

      default:
        if (errfile == NULL)
          fprintf (stderr, "%s\n", wrnstr);
        else
          fprintf (errfile, "%s\n", wrnstr);
     }

  ++WARNINGS;
  ++TOTALWARNINGS;
}


void
ReportAsmMessage  (char *filename, short lineno, char *message)
{
  char  errstr[256], errflnmstr[128], errmodstr[128], errlinestr[64];

  ASSEMBLE_ERROR = -1;      /* Error directive message */
  asmerror = ON;

  errflnmstr[0] = '\0';
  errmodstr[0] = '\0';
  errlinestr[0] = '\0';
  errstr[0] = '\0';

  if (filename != NULL)
    sprintf (errflnmstr,"File '%s', ", filename);

  if (CURRENTMODULE != NULL)
    if ( CURRENTMODULE->mname != NULL )
      sprintf(errmodstr,"Module '%s', ", CURRENTMODULE->mname);

  if (lineno != 0)
    sprintf (errlinestr, "at line %d, ", lineno);

  strcpy(errstr, errflnmstr);
  strcat(errstr, errmodstr);
  strcat(errstr, errlinestr);
  strcat(errstr, message);

  if (errfile == NULL)
    fprintf (stderr, "%s\n", errstr);
  else
    fprintf (errfile, "%s\n", errstr);

  ++ERRORS;
  ++TOTALERRORS;
}


void
ReportError (char *filename, short lineno, int errnum)
{
  char  errstr[256], errflnmstr[128], errmodstr[128], errlinestr[64];

  ASSEMBLE_ERROR = errnum;      /* set the global error variable for general error trapping */
  asmerror = ON;

  errflnmstr[0] = '\0';
  errmodstr[0] = '\0';
  errlinestr[0] = '\0';
  errstr[0] = '\0';

  if (clinemode == ON && clineno)
    lineno=clineno;  /* use last known external line number reference for error report */

  if (filename != NULL)
    sprintf (errflnmstr,"File '%s', ", filename);

  if (CURRENTMODULE != NULL)
    if ( CURRENTMODULE->mname != NULL )
      sprintf(errmodstr,"Module '%s', ", CURRENTMODULE->mname);

  if (lineno != 0)
    sprintf (errlinestr, "at line %d, ", lineno);

  strcpy(errstr, errflnmstr);
  strcat(errstr, errmodstr);
  strcat(errstr, errlinestr);
  strcat(errstr, errmsg[errnum]);

  switch(errnum)
    {
      case Err_MaxCodeSize:
        if (errfile == NULL) {
          fprintf (stderr, errstr, MAXCODESIZE);
          fputc ('\n',stderr);
        }
        else {
          fprintf (errfile, errstr, MAXCODESIZE);
          fputc ('\n',errfile);
        }
        break;

      case Err_Status:
        fprintf (stderr, "%d %s\n", TOTALERRORS, errmsg[errnum]);
        break;

      default:
        if (errfile == NULL)
          fprintf (stderr, "%s\n", errstr);
        else
          fprintf (errfile, "%s\n", errstr);
     }

  ++ERRORS;
  ++TOTALERRORS;
}


void
ReportIOError (char *filename)
{
  ASSEMBLE_ERROR = 0;
  asmerror = ON;

  if (CURRENTMODULE != NULL)
    if ( CURRENTMODULE->mname != NULL )
       fprintf(stderr,"Module '%s', ", CURRENTMODULE->mname);

  fprintf (stderr,"File '%s' couldn't be opened or created\n", filename);

  ++ERRORS;
  ++TOTALERRORS;
}

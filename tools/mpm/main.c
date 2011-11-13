
/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

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


 -------------------------------------------------------------------------------------------------*/



#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "config.h"             /* compilation constant definitions */
#include "datastructs.h"        /* data structure definitions */
#include "symtables.h"          /* functions to access local/global/extern symbol table data */
#include "libraries.h"          /* functions to manage libraries */
#include "z80_relocate.h"       /* functions to manage Z80 code auto-relocation */
#include "modules.h"            /* functions to manage compiled modules */
#include "errors.h"             /* functions for error reporting and error message definitions */
#include "pass.h"               /* functions for source file management and Pass 1 & 2 */
#include "options.h"            /* functions to cmd line arguments and display of help */


/* local functions */
static void ReleaseFilenames (void);
static void CloseFiles (void);
static void DefineEndianLayout(void);
static int CheckFileDependencies(struct stat *ofile);
static int TestAsmFile (void);
static int GetModuleSize (void);


/* global variables */
FILE *srcasmfile, *listfile, *errfile, *objfile, *mapfile, *projectfile, *libfile,  *testfile;

long TOTALLINES;
int PAGELEN, PAGENO, LINENO;

char *srcfilename, *lstfilename, *objfilename, *errfilename, *libfilename;
const char asmext[] = ".asm", lstext[] = ".lst", symext[] = ".sym", defext[] = ".def", binext[] = ".bin";
const char mapext[] = ".map", wrnext[] = ".wrn", errext[] = ".err", libext[] = ".lib", segmbinext[] = ".bn0";
const char crcext[] = ".crc";

char srcext[5];                                 /* contains default source file extension */
char objext[5];                                 /* contains default object file extension */
char binfilename[MAX_FILENAME_SIZE+1];          /* -o explicit filename buffer */

enum flag compiled;                             /* if project files were compiled, then ON */

long listfileptr;
unsigned char *codearea, *codeptr;
size_t CODESIZE;
unsigned long PC, oldPC;                /* Program Counter */
unsigned long tm_year, tm_month, tm_day, tm_hour, tm_min, tm_sec;
time_t asmtime;                         /* time of assembly in seconds */
char *date;                             /* pointer to datestring calculated from asmtime */

/* externally defined variables */
extern int ASSEMBLE_ERROR, ERRORS, TOTALERRORS, WARNINGS, TOTALWARNINGS;
extern enum flag datestamp, verbose, useothersrcext, symtable, autorelocate, crc32file;
extern enum flag createlistingfile, createlibrary, asmerror, mpmbin, mapref, createglobaldeffile;
extern enum flag BIGENDIAN, USEBIGENDIAN;
extern libraries_t *libraryhdr;
extern modules_t *modulehdr;
extern module_t *CURRENTMODULE;
extern avltree_t *globalroot, *staticroot;
extern symbol_t *gAsmpcPtr, *__gAsmpcPtr; /* pointer to Assembler PC symbol (defined in global symbol variables) */
extern unsigned char *reloctable;
extern char copyrightmsg[];
extern pathlist_t *gIncludePath;


static void
ReleaseFilenames (void)
{
  if (srcfilename != NULL) free (srcfilename);
  if (lstfilename != NULL) free (lstfilename);
  if (objfilename != NULL) free (objfilename);
  if (errfilename != NULL) free (errfilename);
  srcfilename = lstfilename = objfilename = errfilename = NULL;
}


static void
CloseFiles (void)
{
  if (srcasmfile != NULL) fclose (srcasmfile);
  if (listfile != NULL) fclose (listfile);
  if (objfile != NULL) fclose (objfile);
  if (errfile != NULL) fclose (errfile);
  srcasmfile = listfile = objfile = errfile = NULL;
}


/* ------------------------------------------------------------------------------------------
   static int CheckFileDependencies(struct stat *ofile)
       Parameters:
           <ofile> pointer to current stat structure that contains file date stamp.

   Called by TestAsmFile(), to evaluate the specified dependencies of the current
   source code file (CURRENTFILE), by comparing the datestamp of the object file with each
   dependency file, and return the following status:

        1) return 1, if the dependency source file date stamp > object code file date stamp
           (a dependency is new newer than last compilation of source code)
        2) return 0, if object file is newer.
        3) return -1 if or if dependency file doesn't exist.
   ------------------------------------------------------------------------------------------ */
static int
CheckFileDependencies(struct stat *ofile)
{
  filelist_t *dependfile;
  struct stat dpstat;

  dependfile = CURRENTFILE->dependencies; /* get first dependency file in list */
  do
    {
      if (StatFile(dependfile->filename, gIncludePath, &dpstat) != -1)
        {
          /* dependency file status were fetched, is it older than object file?*/
          if (dpstat.st_mtime > ofile->st_mtime)
            /* dependency file is newer than object file, current source code file must be compiled.. */
            {
              if (verbose)
                printf ("Dependency '%s' > '%s', compile '%s'.\n", dependfile->filename, objfilename, srcfilename);
              return 1;
            }
        }
      else
        {
          ReportError (dependfile->filename, 0, Err_FileIO);
        }

      dependfile = dependfile->nextfile;
    }
  while(dependfile != NULL);

  return 0; /* indicate that object file is newer than dependencies (no compilation needed) */
}


/* ------------------------------------------------------------------------------------------
   static int TestAsmFile (void)

   If -d option has been defined at the command line for Mpm, then evaluate whether
   current source code file is newer than object file. The following rules apply:

        1) return 1, if source code file date stamp > object code file date stamp
           (or only source code file exists)
        2) return 0, if object file is newer or if source file doesn't exist
        3) return -1 if source nor object file exist.
   ------------------------------------------------------------------------------------------ */
static int
TestAsmFile (void)
{
  struct stat afile, ofile;

  if (datestamp)
    {                           /* assemble only updated source files (and dependencies) */
      if (stat (srcfilename, &afile) == -1)
        return GetModuleSize ();        /* if source file not available (strange!), then try object file... */
      else
        {
          if (stat (objfilename, &ofile) != -1) /* if object file is not available, then compile source */
            {
              if (afile.st_mtime <= ofile.st_mtime)
                /* object file and source file available, evaluate which is newer... */
                {
                  /* source is older than object module, */
                  if (CURRENTFILE->dependencies != NULL)
                    {
                      /* check if source file dependencies is newer than object file */
                      if (CheckFileDependencies(&ofile) == 1)
                        return 1; /* source code needs to be compiled - in all other cases use object file */
                    }
                  return GetModuleSize ();
                }
            }
        }
    }
  else
    {
      if ((srcasmfile = fopen (srcfilename, "rb")) == NULL)
        {                                           /* check Open source file, if no datestamp validation */
          ReportIOError (srcfilename);              /* Object module is not found or */
          return -1;                                /* source has recently been updated */
        }
      fclose(srcasmfile);
    }

  return 1; /* assemble if no datestamp check or if object file not found */
}


static int
GetModuleSize (void)
{
  char modulename[258];
  const char *objwatermark;
  long fptr_modcode, fptr_modname;
  size_t size;

  if ((objfile = OpenObjectFile(objfilename, &objwatermark)) == NULL)
    {
      return -1;
    }
  else
    {
      fseek (objfile, strlen(objwatermark) + 4, SEEK_SET);  /* point at module name file pointer (just after ORG address) */
      fptr_modname = ReadLong (objfile);                    /* get file pointer to module name */
      
      fseek (objfile, fptr_modname, SEEK_SET);              /* set file pointer to module name */

      size = fgetc (objfile);
      fread (modulename, sizeof (char), size, objfile);     /* read module name */
      modulename[size] = '\0';
      if ((CURRENTMODULE->mname = AllocIdentifier (size + 1)) == NULL)
        {
          ReportError (NULL, 0, Err_Memory);
          return -1;
        }
      else
        strcpy (CURRENTMODULE->mname, modulename);

      /* pre-calculate size of linked binary, before actually linking it (needed when adding lib modules) */
      if (mpmbin == ON)
        {
          fseek (objfile, strlen(objwatermark) + 4+4+4+4+4, SEEK_SET);  /* set file pointer to point at module code pointer file pointer */
          fptr_modcode = ReadLong (objfile);                /* get file pointer to module code */
          if (fptr_modcode != -1)
            {
              fseek (objfile, fptr_modcode, SEEK_SET);      /* set file pointer to module code */
              size = ReadLong (objfile);                    /* read 32 bit integer length of module code */
              if (CURRENTMODULE->startoffset + size > MAXCODESIZE)
                ReportError (objfilename, 0, Err_MaxCodeSize);
              else
                CODESIZE += size;
            }
        }
    }

  fclose (objfile);
  return 0;  /* indicate that file is not to be compiled */
}


/* ------------------------------------------------------------------------------------------
   Investigate whether the memory architecture running this assembler
   use Little Endian (low byte - high byte order) or Big Endian (high byte - low byte order)
   ------------------------------------------------------------------------------------------ */
static void
DefineEndianLayout(void)
{
   unsigned short  v = 0x8000;
   unsigned char   *vp;
   
   vp = (unsigned char *) &v;  /* point at first byte of signed long word */
   if (*vp == 0x80)
     BIGENDIAN = ON;
   else
     BIGENDIAN = OFF;        /* little endian - low byte, high byte order */
}


/* ------------------------------------------------------------------------------------------
   Main entry of Mpm
   ------------------------------------------------------------------------------------------ */
int
main (int argc, char *argv[])
{
  int asmflag;
  char argument[MAX_FILENAME_SIZE+1];  /* temp variable for command line arguments and filenames */
  int b, pathsepCount = 0;
  filelist_t *moduledependencies = NULL; /* pointer to list of module source file dependency files */

  DefineEndianLayout();

  USEBIGENDIAN = OFF;           /* for Z80, code generation always use little endian format on integers */

  DefaultOptions();

  libfilename = NULL;
  projectfile = NULL;
  CURRENTMODULE = NULL;

  globalroot = NULL;            /* global identifier tree initialized */
  staticroot = NULL;            /* static identifier tree initialized */

  if (DefineDefSym (OS_ID, 1, &staticroot) == NULL)
    exit (1);

  /* Get command line arguments, if any... */
  if (argc == 1)
    {
      puts(copyrightmsg);
      puts("Try -h for more information.");
      exit (1);
    }
  else
    if ((argc == 2 && strcmp(argv[1],"-h") == 0))
      {
        prompt();
        exit(1);
      }

  time (&asmtime);
  date = asctime (localtime (&asmtime));        /* get current system time for date in list file */

  codearea = (unsigned char *) calloc (MAXCODESIZE, sizeof (char));     /* Allocate memory for machine code */
  if (codearea == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      exit (1);
    }
  CODESIZE = 0;

  PAGELEN = 66;
  TOTALERRORS = 0;
  TOTALWARNINGS = 0;
  TOTALLINES = 0;

  compiled = OFF; /* preset flag to nothing compiled (yet..) */

  if ((CURRENTMODULE = NewModule ()) == NULL)
    {                                      /* then create a dummy module */
      ReportError (NULL, 0, Err_Memory);   /* this is needed during command line parsing */
      exit (1);
    }
  while (--argc > 0)
    {                           /* Get options first */
      ++argv;

      if ((*argv)[0] == '-')
        SetAsmFlag (((*argv) + 1));
      else
        {
          if ((*argv)[0] == '@')
            if ((projectfile = fopen (AdjustPlatformFilename( (*argv + 1) ), "rb")) == NULL)
              ReportIOError ((*argv + 1));
          break;
        }
    }

  ReleaseModules ();            /* Now remove dummy module again, not needed */

  if (!argc && projectfile == NULL)
    {
      ReportError (NULL, 0, Err_SrcfileMissing);
      exit (1);
    }

  if (verbose == ON)
    display_options ();         /* display status messages of select assembler options */

  if (useothersrcext == OFF)
    strcpy (srcext, asmext);    /* use ".asm" as default source file extension */

  for (;;)
    {                           /* Module loop */
      srcasmfile = listfile = objfile = errfile = NULL;
      srcfilename = lstfilename = objfilename = errfilename = NULL;
      moduledependencies = NULL; /* prepare for new list (old list assigned to previous CURRENTFILE) */

      codeptr = codearea;       /* Pointer (PC) to store instruction opcode */
      ERRORS = 0;
      WARNINGS = 0;
      ASSEMBLE_ERROR = -1;      /* General error flag */

      if (projectfile == NULL)
        {
          if (argc > 0)
            {
              if ((*argv)[0] != '-')
                {
                  strncpy(argument, *argv, MAX_FILENAME_SIZE);
                  --argc;
                  ++argv;       /* get ready for next filename */
                }
              else
                {
                  ReportError (NULL, 0, Err_IllegalSrcfile);    /* Illegal source file name */
                  break;
                }
            }
          else
            break;
        }
      else
        {
          /* get a module filename from project file, and optionally get the dependency files assigned to it... */
          FetchModuleFilename(projectfile, argument, &moduledependencies);
          if (strlen (argument) == 0)
            {
              /* in previous loop iteration, the last filename from project file were fetched... */
              fclose (projectfile);
              break;
            }
        }

      /* scan fetched filename backwards and truncate extension, if found, but before a pathname separator */
      for (b=strlen(argument)-1; b>=0; b--) {
          if (argument[b] == '\\' || argument[b] == '/') pathsepCount++; /* Ups, we've scanned past the short filename */

          if (argument[b] == '.' && pathsepCount == 0) {
               argument[b] = '\0'; /* truncate file extension */
               break;
          }
      }

      srcfilename = AdjustPlatformFilename(AddFileExtension((const char *) argument, srcext));
      if (srcfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      objfilename = AddFileExtension((const char *) srcfilename, objext);
      if (objfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      if (createlistingfile == ON)
        {
          lstfilename = AddFileExtension((const char *) srcfilename, lstext);
          if (lstfilename == NULL)
            {
              ReportError (NULL, 0, Err_Memory);   /* No more room */
              break;
            }
        }

      if (createlistingfile == OFF && symtable == ON)
        {
          /* Create symbol table in separate file (listing file not enabled) */
          lstfilename = AddFileExtension((const char *) srcfilename, symext);
          if (lstfilename == NULL)
            {
              ReportError (NULL, 0, Err_Memory);   /* No more room */
              break;
            }
        }

      errfilename = AddFileExtension((const char *) srcfilename, errext);
      if (errfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      if ((CURRENTMODULE = NewModule ()) == NULL)
        {                       /* Create module data structures for new file */
          ReportError (NULL, 0, Err_Memory);
          break;
        }
      if ((CURRENTFILE = Newfile (NULL, srcfilename)) == NULL)
        break;                  /* Create first file record, if possible */

      CURRENTFILE->dependencies = moduledependencies; /* assign file dependencies, if defined in project file (or just NULL) */

      if ((asmflag = TestAsmFile ()) == 1)
        {
          PC = oldPC = 0;
          Copy (staticroot, &CURRENTMODULE->localroot, (int (*)(void *,void *)) cmpidstr, (void *(*)(void *)) CreateSymNode);

          DefineDefSym ("$YEAR", 0, &globalroot);       /* Create standard '$YEAR' assembler function return value */
          DefineDefSym ("$MONTH", 0, &globalroot);     /* Create standard '$MONTH' assembler function return value  */
          DefineDefSym ("$DAY", 0, &globalroot);         /* Create standard '$DAY' assembler function return value  */
          DefineDefSym ("$HOUR", 0, &globalroot);       /* Create standard '$HOUR' assembler function return value  */
          DefineDefSym ("$MINUTE", 0, &globalroot);      /* Create standard '$MINUTE' assembler function return value  */
          DefineDefSym ("$SECOND", 0, &globalroot);      /* Create standard '$SECOND' assembler function return value  */

          gAsmpcPtr = DefineDefSym (ASSEMBLERPC, PC, &globalroot);      /* Create standard '$PC' assembler function return value */
          __gAsmpcPtr = DefineDefSym (__ASSEMBLERPC, PC, &globalroot);  /* 'ASMPC' identifier for compatibility with z80asm */
          if (gAsmpcPtr == NULL || __gAsmpcPtr == NULL)
            {
              ReportError (NULL, 0, Err_Memory);
              return 0;
            }

          if (AssembleSourceFile() == 1)
             compiled = ON;             /* a compilation was processed */

          DeleteAll (&CURRENTMODULE->localroot, (void (*)(void *)) FreeSym);
          DeleteAll (&CURRENTMODULE->notdeclroot, (void (*)(void *)) FreeSym);
          DeleteAll (&globalroot, (void (*)(void *)) FreeSym);

          if (verbose)
            putchar ('\n');     /* separate module texts */
        }
      else if (asmflag == -1)
        break;                  /* file open error - stop assembler */

      ReleaseFilenames ();
    }                           /* for */

  ReleaseFilenames ();
  CloseFiles ();

  if (compiled == ON)
    {
      if (TOTALERRORS == 0 && verbose)
        printf ("Total of %ld lines assembled.\n", TOTALLINES);
    }
  else
    {
      if (TOTALERRORS == 0 && verbose == ON)
        puts("Nothing compiled - all files are up to date.");

      if (TOTALERRORS == 0)
        {
          /* all object files compiled, but is binary available? */
          if (createlibrary == ON)
            {
              if ((testfile = fopen(libfilename, "r")) != NULL)
                fclose(testfile);
              else
                /* if library file doesn't exist, then it needs to be generated! */
                compiled = ON;
          }

          if (mpmbin == ON && datestamp == ON && ExistBinFile() == OFF)
            {
              /* a previous compilation of this project might not have generated */
              /* the linked executable binary (without -b option) */
              /* so, if the binary doesn't exist, create it now... */
              if (verbose)
                puts("Executable binary is missing, create it..");
              compiled = ON;
            }
        }
    }

  if (compiled == ON)
    {
      if (createlibrary)
        {
          if (TOTALERRORS == 0)
            {
              CreateLibfile ();
              PopulateLibrary ();
              fclose (libfile);
            }
          else
            {
              remove (libfilename);
            }

          free (libfilename);
          libfilename = NULL;
        }

      if (TOTALERRORS == 0 && createglobaldeffile == ON)
        CreateDeffile ();

      if (TOTALERRORS == 0 && mpmbin == ON)
        {
          /* a module was re-compiled with a newer object file in the project */
          /* or a missing executable binary needs to be generated */
          LinkModules ();

          if (mapref == ON)
            WriteMapFile ();

          CreateBinFile ();

          if (crc32file == ON)
            CreateCrc32File();
        }
    }

  ReleaseFilenames ();
  CloseFiles ();

  DeleteAll (&globalroot, (void (*)(void *)) FreeSym);
  DeleteAll (&staticroot, (void (*)(void *)) FreeSym);

  if (modulehdr != NULL)
    ReleaseModules ();          /* Release module information (symbols, etc.) */

  if (libraryhdr != NULL)
    ReleaseLibraries ();        /* Release library information */
  free (codearea);              /* Release area for machine code */

  if (autorelocate == ON)
    FreeRelocTable();

  ReleasePathInfo();            /* release collected path info (as defined from env. and cmd.line) */

  if (asmerror)
    ReportError (NULL, 0, Err_Status);

  if (TOTALWARNINGS > 0)
    ReportWarning (NULL, 0, Warn_Status);

  if (asmerror)
    {
      exit (1);
    }
  else
    {
      exit (0);         /* assembler successfully ended */
    }
}

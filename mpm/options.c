
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
#include <ctype.h>
#include "config.h"
#include "datastructs.h"
#include "options.h"
#include "libraries.h"
#include "symtables.h"
#include "pass.h"
#include "errors.h"


/* local functions */
static void GetCmdLineDefSym(char *flagid);


/* globally defined variables */
char copyrightmsg[] = MPM_COPYRIGHTMSG;

enum flag pass1, uselistingfile, symtable, mpmbin, writeline, mapref;
enum flag createglobaldeffile, datestamp;
enum flag deforigin, verbose, asmerror, EOL, uselibraries, createlibrary, autorelocate;
enum flag useothersrcext, codesegment, expl_binflnm;
enum flag BIGENDIAN, USEBIGENDIAN;
unsigned long EXPLICIT_ORIGIN;          /* origin defined from command line */


/* externally defined variables */
extern char asmext[], lstext[], objext[], defext[], binext[];
extern char mapext[], errext[], libext[], srcext[];
extern char separators[];
extern char binfilename[];
extern avltree_t *staticroot;
extern long TARGETPROCESSOR;
extern pathlist_t *gIncludePath;
extern pathlist_t *gLibraryPath;


void
DefaultOptions (void)
{
  /* define the default paths for INCLUDE files and for libraries */
  AddPathNode (getenv(ENVNAME_INCLUDEPATH), &gIncludePath);
  AddPathNode (getenv(ENVNAME_LIBRARYPATH), &gLibraryPath);

  symtable = writeline = mapref = ON;
  verbose = useothersrcext = uselistingfile = mpmbin = datestamp = asmerror = codesegment = OFF;
  deforigin = createglobaldeffile = uselibraries = createlibrary = autorelocate = OFF;
}



void
SetAsmFlag (char *flagid)
{
  enum flag Option;

  /* use ".xxx" as source file in stead of ".asm" */
  if (*flagid == 'e')
    {
      useothersrcext = ON;
      srcext[0] = '.';
      strncpy ((srcext + 1), (flagid + 1), 3);  /* Copy argument string */
      srcext[4] = '\0';         /* max. 3 letters extension */
      return;
    }

  /* specify library file for static linking */
  if (*flagid == 'l')
    {
      GetLibfile ((flagid + 1));
      return;
    }

  /* create Include Path list from argument */
  if (*flagid == 'I')
    {
      AddPathNode (++flagid, &gIncludePath);
      return;
    }

  /* create Library Path list from argument */
  if (*flagid == 'L')
    {
      AddPathNode (++flagid, &gLibraryPath);
      return;
    }

  /* create library file */
  if (*flagid == 'x')
    {
      CreateLibfile ((flagid + 1));
      return;
    }

  /* explicit origin */
  if (*flagid == 'r')
    {
      sscanf (flagid + 1, "%lx", &EXPLICIT_ORIGIN);
      deforigin = ON;           /* explicit origin has been defined */
      return;
    }

  /* explicit output filename */
  if (*flagid == 'o')
    {
      sscanf (flagid + 1, "%s", binfilename); /* store explicit filename for .bin file */
      expl_binflnm = ON;
      return;
    }

  /* explicit symbol definition */
  if (*flagid == 'D')
    {
      GetCmdLineDefSym(flagid);
      return;
    }

  /* all special cases evaluated, now check for single letter flag options... */
  if (*flagid == 'n')
    {
      Option = OFF;
      flagid++;
    }
  else
    Option = ON;

  while(*flagid != 0)
    {
      switch(*flagid)
        {
          case 'c': codesegment = Option; break;
          case 't': uselistingfile = Option; break;
          case 'a': mpmbin = Option; datestamp = Option; break;
          case 's': symtable = Option; break;
          case 'b': mpmbin = Option; break;
          case 'v': verbose = Option; break;
          case 'd': datestamp = Option; break;
          case 'm': mapref = Option; break;
          case 'g': createglobaldeffile = Option; break;
        }

      flagid++;
    }
}


static void
GetCmdLineDefSym(char *flagid)
{
  char ident[254];
  int i;

  strcpy (ident, (flagid + 1));     /* Copy argument string */
  if (!isalpha(ident[0]) && ident[0] != '_')
    {
      ReportError (NULL, 0, Err_IllegalIdent);    /* symbol must begin with alpha */
      return;
    }
  i = 0;
  while (ident[i] != '\0')
    {
      if (strchr (separators, ident[i]) == NULL)
        {
          if (!isalnum (ident[i]) && ident[i] != '_')
            {
              ReportError (NULL, 0, Err_IllegalIdent);        /* illegal char in identifier */
              return;
            }
          else
            ident[i] = toupper (ident[i]);
        }
      else
        {
          ReportError (NULL, 0, Err_IllegalIdent);        /* illegal char in identifier */
          return;
        }
      ++i;
    }

  DefineDefSym (ident, 1, &staticroot);
}


void
display_options (void)
{
  if (datestamp == ON)
    puts ("Assemble only updated files.");
  else
    puts ("Assemble all files");
  if (uselistingfile == ON)
    puts ("Create listing file.");
  if (symtable == ON && uselistingfile == ON)
    puts ("Create symbol table.");
  if (createglobaldeffile == ON)
    puts ("Create global definition file.");
  if (createlibrary == ON)
    puts ("Create library from specified modules.");
  if (mpmbin == ON)
    puts ("Link/relocate assembled modules.");
  if (uselibraries == ON)
    puts ("Link library modules with code.");
  if (mpmbin == ON && mapref == ON)
    puts ("Create address map file.");
  putchar ('\n');
}



void
prompt (void)
{
  puts(copyrightmsg);
  puts ("mpm [options] [ @<modulefile> | {<filename>} ]");
  printf ("To assemble 'program%s' use 'program' or 'program%s'.\n", asmext, asmext);
  puts ("@<modulefile> contains file names of all modules to be linked; File names");
  puts ("are put on separate lines ended with \\n. File types recognized by or");
  puts ("created by mpm (defined by the following extensions):");
  printf ("%s = source file (default), or alternative -e<ext> (3 chars)\n", asmext);
  printf ("%s = object file, %s = listing file, %s = static linked executable binary\n", objext, lstext, binext);
  printf ("%s = map file, %s = const def file, %s = error file, %s = library file\n", mapext, defext, errext, libext);
  puts ("\nFlag Options: -n = option OFF, eg. -nts = no listing file, no symbol table.");
  printf ("-v verbose assembly, -t listing file, -s symbol table, -m bin. address map file\n");
  puts ("-b static linking & relocation into executable binary of specified modules.");
  puts ("-g Global Relocation Address DEF File, from modules as DEFC address defs.");
  puts ("-d date stamp control, assemble only if source file > object file.");
  puts ("-a = -bd (assemble only updated source files, then static link modules).");
  puts (DEFAULT_OPTIONS);

  puts ("\nParameterized Options (parameter value immediately followed after option):");
  puts ("-r<ORG> Explicit relocation <ORG> defined in hex (ignore ORG in first module).");
  puts("-I<Include File Path> Multiple Search Path for INCLUDE directive.");
  puts("-L<Library File Path> Multiple Search Path for -l option (link with library).");
  printf("  use %c to separate individual directory paths or multiple -I or -L options.\n", ENVPATHSEP);
  puts ("-D<symbol> define symbol as logically TRUE (used for conditional assembly)");
  puts ("-o<bin filename> explicit output filename of static linked modules.");
  printf ("-l<library file> link LIB modules into binary as referenced by %s modules.\n", objext);
  puts ("-x<library file> create library from specified modules ( e.g. with @<modules> )");
}

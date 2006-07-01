
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

enum flag pass1, uselistingfile, createlistingfile, symtable, mpmbin, writeline, mapref;
enum flag createglobaldeffile, datestamp, addressalign;
enum flag deforigin, verbose, asmerror, EOL, uselibraries, createlibrary, autorelocate;
enum flag useothersrcext, codesegment, expl_binflnm;
enum flag ti83plus, swapIXIY, clinemode;
enum flag BIGENDIAN, USEBIGENDIAN;
unsigned long EXPLICIT_ORIGIN;          /* origin defined from command line */


/* externally defined variables */
extern const char asmext[], symext[], lstext[], defext[], binext[];
extern const char mapext[], errext[], libext[];
extern char srcext[], objext[];
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
  AddPathNode (getenv("Z80_OZFILES"), &gIncludePath);        /* be compatible with good old Z80asm */
  AddPathNode (getenv(ENVNAME_INCLUDEPATH), &gIncludePath);
  AddPathNode (getenv(ENVNAME_LIBRARYPATH), &gLibraryPath);

  symtable = writeline = mapref = ON;
  verbose = useothersrcext = createlistingfile = mpmbin = datestamp = asmerror = codesegment = addressalign = OFF;
  deforigin = createglobaldeffile = uselibraries = createlibrary = autorelocate = ti83plus = swapIXIY = clinemode = OFF;

  strcpy(objext, ".obj"); /* default object filename extension */
}



void
SetAsmFlag (char *flagid)
{
  enum flag Option;

  /* check wether to use an RST or CALL when Invoke for TI83x is used */
  if (strcmp(flagid, "plus") == 0)
    {
      ti83plus = ON;
      return;
    }

  /* IX and IY swap option */
  if (strcmp (flagid, "IXIY") == 0)
    {
      swapIXIY = ON;
      return;
    }

  /* use ".xxx" as source file in stead of ".asm" */
  if (*flagid == 'e')
    {
      useothersrcext = ON;
      srcext[0] = '.';
      strncpy ((srcext + 1), (flagid + 1), 3);  /* Copy argument string */
      srcext[4] = '\0';                         /* max. 3 letters extension */
      return;
    }

  /* djm: mod to get .o files produced instead of .obj */
  /* gbs: extended to use argument as definition, e.g. -Mo, which defines .o extension */
  if (*flagid == 'M')
    {
      strncpy ((objext + 1), (flagid + 1), 3);   /* copy argument string (append after '.') */
      objext[4] = '\0';                          /* max. 3 letters extension */
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
      if (strlen(flagid+1) > 255) *(flagid+255) = '\0'; /* truncate if filename argument > 255 */

      sscanf (flagid + 1, "%s", binfilename); /* store explicit filename for compiled binary */
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
          case 'h': prompt(); break;
          case 'c': codesegment = Option; break;
          case 'C': clinemode = Option; break;
          case 't': createlistingfile = uselistingfile = Option; break;
          case 'a': mpmbin = Option; datestamp = Option; break;
          case 's': symtable = Option; break;
          case 'b': mpmbin = Option; break;
          case 'v': verbose = Option; break;
          case 'd': datestamp = Option; break;
          case 'm': mapref = Option; break;
          case 'g': createglobaldeffile = Option; break;
          case 'A': addressalign = Option; break;
          case 'R': autorelocate = Option; break;
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
  if (createlistingfile == ON)
    puts ("Create listing file.");
  if (symtable == ON && createlistingfile == ON)
    puts ("Create symbol table.");
  if (symtable == ON && createlistingfile == OFF)
    puts ("Create symbol table file.");
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
  if (autorelocate == ON)
    puts ("Create relocatable code.");
  if (codesegment == ON && autorelocate == OFF)
    puts ("Split code into 16K banks.");
  putchar ('\n');
}



void
prompt (void)
{
  puts(copyrightmsg);
  puts ("mpm [options] {<filename>} | @<modulefile>}");
  printf ("To assemble 'program%s' use 'program' or 'program%s'.\n", asmext, asmext);
  puts ("@<modulefile> contains file names of all modules to be linked; File names");
  puts ("are put on separate lines ended with \\n. File types recognized by or");
  puts ("created by mpm (defined by the following extensions):");
  printf ("%s = source file (default), or alternative -e<ext> (3 chars)\n", asmext);
  printf ("%s = object file, %s = listing file, %s = symbol table file\n", objext, lstext, symext);
  printf ("%s = static linked executable binary, %s = address map file\n", binext, mapext);
  printf ("%s = constant definition file, %s = error file, %s = library file\n", defext, errext, libext);
  puts ("\nFlag Options: -n = option OFF, eg. -nts = no listing file, no symbol table.");
  printf ("-v verbose assembly, -t listing file, -s symbol table, -m bin. address map file\n");
  puts ("-b static linking & relocation into executable binary of specified modules.");
  puts ("-c split executable binary into 16K files using auto-appended .bnX extension.");
  puts ("-g Global Relocation Address DEF File, XDEF from modules as DEFC address defs.");
  puts ("-R Generate relocatable program (code must run in RAM due to address patching)");
  puts ("-C Override compile error line numbers using LINE directive line number");
  puts ("-A Address align DEFW & DEFL constants");
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


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
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "datastructs.h"
#include "symtables.h"
#include "libraries.h"
#include "modules.h"
#include "errors.h"
#include "pass.h"


/* local functions */
static int cmpmodname (char *modname, libobject_t *p);
static int cmplibnames (libobject_t * kptr, libobject_t * p);
static int SearchLibraries (char *modname);
static int LinkLibModule (libfile_t *library, long module_basefptr, char *modname);
static void LoadLibraryIndex(libfile_t *curlib);
static void ReleaseIndexObj(libobject_t *libidxobj);
static libobject_t *FindLibModule (char *modname);
static libobject_t *AllocLibObject (void);
static libfile_t *NewLibrary (void);
static libfile_t *AllocLib (void);
static libraries_t *AllocLibHdr (void);
static void ReleaseLibrariesIndex (void);


/* externally defined variables */
extern enum flag verbose, deforigin, EOL, createlibrary, uselibraries, asmerror;
extern module_t *CURRENTMODULE;
extern modules_t *modulehdr;
extern char *errfilename, *libfilename;
extern const char objext[], errext[], libext[];
extern char line[];
extern FILE *srcasmfile, *errfile, *libfile;
extern avltree_t *globalroot;
extern pathlist_t *gLibraryPath;


/* global variables */
libraries_t *libraryhdr = NULL;


/* local variables */
static char MPMlibhdr[] = MPMLIBRARYHEADER;
static avltree_t *libraryindex = NULL;



/* ------------------------------------------------------------------------------------------
   void CreateLib (void)

   Create a library file, containing concatanated object file modules.
   The current linked list of modules is scanned and for each module the object file is
   loaded and appended to the library file.
   ------------------------------------------------------------------------------------------ */
void
CreateLib (void)
{
  long Codesize;
  FILE *objectfile;
  long fptr;
  char *filebuffer, *fname;

  if (verbose)
    puts ("Creating library...");

  CURRENTMODULE = modulehdr->first;

  errfilename = AddFileExtension((const char *) libfilename, errext);
  if (errfilename == NULL)
    {
      ReportError (NULL, 0, Err_Memory);   /* No more room */
      return;
    }

  if ((errfile = fopen (AdjustPlatformFilename(errfilename), "w")) == NULL)
    {                           /* open error file */
      ReportIOError (errfilename);
      free (errfilename);
      errfilename = NULL;
      return;
    }

  do
    {
      fname = AddFileExtension((const char *) CURRENTFILE->fname, objext);

      if (fname == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      if ((objectfile = fopen (AdjustPlatformFilename(fname), "rb")) != NULL)
        {
          fseek(objectfile, 0L, SEEK_END);   /* file pointer to end of file */
          Codesize = ftell(objectfile);      /* - to get size... */
          fseek(objectfile, 0L, SEEK_SET);

          filebuffer = (char *) malloc ((size_t) Codesize);
          if (filebuffer == NULL)
            {
              ReportError (CURRENTFILE->fname, 0, Err_Memory);
              fclose (objectfile);
              free(fname);
              break;
            }
          fread (filebuffer, sizeof (char), Codesize, objectfile);      /* load object file */
          fclose (objectfile);

          if (memcmp (filebuffer, MPMOBJECTHEADER, SIZEOF_MPMOBJHDR) == 0)
            {
              if (verbose)
                printf ("<%s> module at %04lX.\n", CURRENTFILE->fname, ftell (libfile));

              if (CURRENTMODULE->nextmodule == NULL)
                WriteLong (-1, libfile);        /* this is the last module */
              else
                {
                  fptr = ftell (libfile) + 4 + 4;
                  WriteLong (fptr + Codesize, libfile);  /* file pointer to next module */
                }

              WriteLong (Codesize, libfile);        /* size of this module */
              fwrite (filebuffer, sizeof (char), (size_t) Codesize, libfile);       /* write module to uselibraries */
              free (filebuffer);
            }
          else
            {
              free (filebuffer);
              free(fname);
              ReportError (CURRENTFILE->fname, 0, Err_Objectfile);
              break;
            }
        }
      else
        {
          ReportError (CURRENTFILE->fname, 0, Err_FileIO);
          free(fname);
          break;
        }

      free(fname);
      CURRENTMODULE = CURRENTMODULE->nextmodule;
    }
  while (CURRENTMODULE != NULL);

  fclose (errfile);
  errfile = NULL;

  if (asmerror == OFF) remove(errfilename);     /* no errors */

  free (errfilename);
  errfilename = NULL;
}


void
CreateLibfile (char *filename)
{
  size_t l;

  l = strlen (filename);
  if (l)
    {
      libfilename = AddFileExtension((const char *) filename, libext);
      if (libfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          return;
        }
    }
  else
    {
      if ((filename = getenv (ENVNAME_STDLIBRARY)) != NULL)
        {
          libfilename = AddFileExtension((const char *) filename, libext);
          if (libfilename == NULL)
            {
              ReportError (NULL, 0, Err_Memory);   /* No more room */
              return;
            }
        }
    }

  /* create library file... */
  if ((libfile = fopen (AdjustPlatformFilename(libfilename), "w+b")) == NULL)
    {
      ReportError (libfilename, 0, Err_LibfileOpen);
      if (libfilename != NULL)
        {
          free (libfilename);
          libfilename = NULL;
        }
    }
  else
    {
      createlibrary = ON;
      fwrite (MPMlibhdr, sizeof (char), SIZEOF_MPMLIBHDR, libfile);   /* write library header */
    }
}


void
GetLibfile (char *filename)
{
  libfile_t *newlib;
  char *f = NULL, fheader[128];
  int l;

  for(l=0; l<128; l++) fheader[l] = 0;   /* clear buffer for library file watermark */

  l = strlen (filename);
  if (l>0)
    {
      f = AddFileExtension((const char *) filename, libext);
      if (f == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          return;
        }
    }
  else
    {
      filename = getenv (ENVNAME_STDLIBRARY);
      if (filename != NULL)
        {
          f = AddFileExtension((const char *) filename, libext);
          if (f == NULL)
            {
              ReportError (NULL, 0, Err_Memory);   /* No more room */
              return;
            }
        }
    }

  if ((srcasmfile = OpenFile (f, gLibraryPath, OFF)) == NULL)
    {                           /* Does file exist? */
      ReportError (NULL, 0, Err_LibfileOpen);
      free(f); /* discard previously allocated library filename */
      return;
    }
  else
    {
      fread (fheader, 1U, SIZEOF_MPMLIBHDR, srcasmfile);      /* read potential library watermark from file into array */
      fheader[SIZEOF_MPMLIBHDR] = '\0';
    }
  fclose (srcasmfile);
  srcasmfile = NULL;

  if (strcmp (fheader, MPMlibhdr) != 0)
    {         /* compare header of file */
      ReportError (f, 0, Err_Libfile);
      free(f); /* discard previously allocated library filename */
    }
  else
    uselibraries = ON;

  /* Library file has been recognised, insert it into linked list of libraries */
  if ((newlib = NewLibrary ()) == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      free(f); /* discard previously allocated library filename */
      return;
    }
  newlib->libfilename = f;
}


void
IndexLibraries(void)
{
  libfile_t *curlib;

  if (verbose)
    puts ("Indexing libraries...");

  libraryindex = NULL;
  curlib = libraryhdr->firstlib;

  do
    {
      LoadLibraryIndex(curlib);
      curlib = curlib->nextlib;
    }
  while(curlib != NULL);       /* until all library files are parsed */
}


void
ReleaseLibraries (void)
{
  libfile_t *curptr, *tmpptr;

  curptr = libraryhdr->firstlib;

  do
    {
      if (curptr->libfilename != NULL)
        free (curptr->libfilename);

      tmpptr = curptr;
      curptr = curptr->nextlib;
      free (tmpptr);            /* release library */
    }
  while (curptr != NULL);       /* until all libraries are released */

  free (libraryhdr);            /* Release library header */
  libraryhdr = NULL;

  ReleaseLibrariesIndex ();
}


/* ------------------------------------------------------------------------------------------
   int SearchLibraries (char *modname)

   Find reference to this LIB module name in library index and append it to the linked
   list of application modules. Then, parse linked LIB module for own LIB references
   and link them too (recursive).

   Returns:
            0, successfully found and linked this LIB module into the modules list.
            Err_LibReference, if LIB reference was not found.
            Err_Memory, if memory was not available for allocation of LIB module objects.
            Err_MaxCodeSize, if code buffer max was reached during linking of LIB modules.
   ------------------------------------------------------------------------------------------ */
static int
SearchLibraries (char *modname)
{
  libobject_t *foundlib;

  foundlib = FindLibModule (modname);    /* search for library module name in library index */
  if (foundlib != NULL)
    return LinkLibModule (foundlib->library, foundlib->modulestart, modname);
  else
    return Err_LibReference;
}


/* ------------------------------------------------------------------------------------------
   int LinkLibModules (char *filename, long fptr_base, long nextname, long endnames)

   char *filename      name of library file
   long fptr_base      base file pointer of object (library) module file
   long nextname       relative file pointer to start of LIB name section of object file
   long endnames       relative file pointer to end of LIB name section of object file

   For each LIB name reference in this object file, look it up in the library index
   and automatically append it to the linked list of application modules.

   Returns:
   ------------------------------------------------------------------------------------------ */
int
LinkLibModules (char *filename, long fptr_base, long nextname, long endnames)
{
  long mnl;
  char *modname;

  do
    {
      srcasmfile = OpenFile (filename, gLibraryPath, OFF);   /* open object file for reading */
      fseek (srcasmfile, fptr_base + nextname, SEEK_SET);    /* set file pointer to point at library name declarations */
      ReadName ();                                           /* read library reference name */
      fclose (srcasmfile);

      mnl = strlen (line);
      nextname += (1 + mnl);        /* remember module pointer to next name in this object module */

      if (FindSymbol (line, globalroot) == NULL)
        {
          modname = AllocIdentifier ((size_t) mnl + 1);
          if (modname == NULL)
            {
              ReportError (NULL, 0, Err_Memory);
              return Err_Memory;
            }

          strcpy (modname, line);
          if (SearchLibraries (modname) != 0)
            printf("Warning: LIB reference '%s' was not found in libraries.\n", modname);

          free (modname);
        }
    }
  while (nextname < endnames);

  return 0;
}


/* ------------------------------------------------------------------------------------------
   int LinkLibModule (libfile_t *library, long module_fptrbase, char *modname)

   Returns:
            0, successfully linked this LIB module to the application modules list.
            Err_Memory, if memory was not available for allocation of this LIB module object.
            Err_MaxCodeSize, if code buffer max was reached during linking of this LIB module.
   ------------------------------------------------------------------------------------------ */
static int
LinkLibModule (libfile_t *library, long module_basefptr, char *modname)
{
  module_t *tmpmodule;
  int link_error;
  char *mname;

  tmpmodule = CURRENTMODULE;    /* remember current module */

  if ((CURRENTMODULE = NewModule ()) != NULL)
    {
      mname = AllocIdentifier (strlen (modname) + 1);   /* make a Copy of module name */
      if (mname != NULL)
        {
          strcpy (mname, modname);
          CURRENTMODULE->mname = mname;                         /* create new module for library */
          CURRENTFILE = Newfile (NULL, library->libfilename);   /* filename for 'module' */

          if (verbose)
            printf ("Linking library module <%s>\n", modname);

          link_error = LinkModule (library->libfilename, module_basefptr);  /* link module & read names */
        }
      else
        {
          ReportError (NULL, 0, Err_Memory);
          link_error = Err_Memory;
        }
    }
  else
    link_error = 0;

  CURRENTMODULE = tmpmodule;    /* restore previous current module */
  return link_error;
}


static int
cmpmodname (char *modname, libobject_t *p)
{
  return strcmp (modname, p->libname);
}

static libobject_t *
FindLibModule (char *modname)    /* pointer to module name in object file */
{
  if (libraryindex == NULL)
    return NULL;
  else
    return Find (libraryindex, modname, (int (*)()) cmpmodname);
}


static int
cmplibnames (libobject_t * kptr, libobject_t * p)
{
  return strcmp (kptr->libname, p->libname);
}

static libobject_t *
AddLibIndexObj(libfile_t *curlib, char *modname, long objfile_baseptr)
{
  libobject_t *newlibobj;

  newlibobj = AllocLibObject();
  if (newlibobj == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      return NULL;
    }
  else
    {
      newlibobj->libname = AllocIdentifier (strlen (modname) + 1);  /* Allocate area for a new module name */
      if (newlibobj->libname == NULL)
        {
          free(newlibobj);
          ReportError (NULL, 0, Err_Memory);
          return NULL;
        }
      else
        {
          strcpy(newlibobj->libname, modname);        /* library (module) name */
          newlibobj->library = curlib;                /* reference to library file containing library module */
          newlibobj->modulestart = objfile_baseptr;   /* file pointer to base of linkable object in library file */

          Insert (&libraryindex, newlibobj, (int (*)()) cmplibnames); /* Insert new library index object into LibraryIndex AVL tree */
          return newlibobj;
        }
    }
}


static void
LoadLibraryIndex(libfile_t *curlib)
{
  long currentlibmodule, nextlibmodule;
  long modulesize, fptr_mname, objfile_base;
  char *mname;
  libobject_t *foundlib;

  srcasmfile = OpenFile (curlib->libfilename, gLibraryPath, OFF);
  if (srcasmfile != NULL)
    {
      currentlibmodule = SIZEOF_MPMLIBHDR;                       /* first available module in library */

      do
        { /* parse all available active modules in library file */
          do
            {
              fseek (srcasmfile, currentlibmodule, SEEK_SET);    /* point at beginning of a object file module */
              nextlibmodule = ReadLong (srcasmfile);             /* get file pointer to next module in library */
              modulesize = ReadLong (srcasmfile);                /* get size of current module */
            }
          while (modulesize == 0 && nextlibmodule != -1);

          if (modulesize != 0)
            {
              /* point at module name file pointer                 [ object file  ....................... ]
               * (past <Next Object File> & <Object File Length> & <Object file Watermark> & <ORG address>)
               */
              objfile_base = currentlibmodule + 4 + 4;
              fseek (srcasmfile, objfile_base + SIZEOF_MPMOBJHDR + 4, SEEK_SET);

              fptr_mname = ReadLong (srcasmfile);                       /* get module name file pointer */
              fseek (srcasmfile, objfile_base + fptr_mname, SEEK_SET);  /* point at module name */
              mname = ReadName ();                                      /* read module name into buffer variable */

              /* check for lib module in library index */
              foundlib = FindLibModule(mname);
              if (foundlib == NULL)
                {
                  /* This Library module was not found in the index, Insert library module definition */
                  if (AddLibIndexObj(curlib, mname, objfile_base) == NULL)
                    return; /* Ups, no room left for library index, abort library index creation */
                }
              else
                {
                  /* a library module has already been loaded into the index */
                  /* issue a warning message and replace existing library module info with new info */
                  printf ("Warning: Duplicate objects not allowed in Library Index!\n"
                          "Object '%s' from library file '%s'\nwill be replaced with object from file '%s'\n",
                          foundlib->libname, foundlib->library->libfilename, curlib->libfilename);

                  /* module name is the same, but other attributes need to be replaced */
                  foundlib->library = curlib;             /* point to new library file */
                  foundlib->modulestart = objfile_base;   /* file pointer to library object in new library file */
                }
            }

            currentlibmodule = nextlibmodule;
        }
      while (nextlibmodule != -1);  /* parse all available active modules in library file */

      fclose (srcasmfile);  /* library file parsed successfully */
    }
}


static void
ReleaseIndexObj(libobject_t *libidxobj)
{
  free(libidxobj->libname);   /* release allocated space for library module name */
}                             /* remaining properties of structure are static data */


static void
ReleaseLibrariesIndex (void)
{
  DeleteAll (&libraryindex, (void (*)()) ReleaseIndexObj);
  libraryindex = NULL;
}


static libfile_t *
NewLibrary (void)
{
  libfile_t *newl;

  if (libraryhdr == NULL)
    {
      if ((libraryhdr = AllocLibHdr ()) == NULL)
        return NULL;
      else
        {
          libraryhdr->firstlib = NULL;
          libraryhdr->currlib = NULL;   /* library header initialised */
        }
    }
  if ((newl = AllocLib ()) == NULL)
    return NULL;
  else
    {
      newl->nextlib = NULL;
      newl->libfilename = NULL;
    }

  if (libraryhdr->firstlib == NULL)
    {
      libraryhdr->firstlib = newl;
      libraryhdr->currlib = newl;       /* First library in list */
    }
  else
    {
      libraryhdr->currlib->nextlib = newl;      /* current/last library points now at new current */
      libraryhdr->currlib = newl;               /* pointer to current module updated */
    }

  return newl;
}


static libraries_t *
AllocLibHdr (void)
{
  return (libraries_t *) malloc (sizeof (libraries_t));
}


static libfile_t *
AllocLib (void)
{
  return (libfile_t *) malloc (sizeof (libfile_t));
}


static libobject_t *
AllocLibObject (void)
{
  return (libobject_t *) malloc (sizeof (libobject_t));
}

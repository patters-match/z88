
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

  $Id$

 -------------------------------------------------------------------------------------------------*/

#include <sys/stat.h>


/* global functions */
FILE *OpenObjectFile(char *filename, const char **objversion);
FILE *OpenFile(char *filename, pathlist_t *pathlist, enum flag expandfilename);
char *AdjustPlatformFilename(char *filename);
char *AddFileExtension(const char *oldfilename, const char *extension);
int AssembleSourceFile (void);
int GetChar(FILE *fptr);
int StatFile(char *filename, pathlist_t *pathlist, struct stat *fstat);
sourcefile_t *FindFile (sourcefile_t *srcfile, char *fname);
sourcefile_t *Newfile (sourcefile_t *curfile, char *fname);
sourcefile_t *Prevfile (void);
symbol_t *GetAddress (labels_t **stackpointer);
void AddAddress (symbol_t *label, labels_t **stackpointer);
void AddPathNode (char *path, pathlist_t **plist);
void AddFileNameNode (char *filename, filelist_t **flist);
void FetchModuleFilename(FILE *projectfile, char *filename, filelist_t **dependencies);
void Fetchfilename (FILE *fptr, char *filename);
void FetchLinefilename (FILE *fptr, char *filename);
void GetLine (void);
void NewJRaddr (void);
void Pass2info (expression_t *expression, unsigned long constrange, long lfileptr);
void ReleaseFile (sourcefile_t *srcfile);
void ReleasePathInfo(void);
void SourceFilePass1 (void);
void SourceFilePass2 (void);
void WriteListFileLine (void);
void WriteMapFile (void);

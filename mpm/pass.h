
/*
   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM
*/

/*
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
*/


/* global functions */
FILE *OpenFile(char *filename, pathlist_t *pathlist, enum flag expandfilename);
int AssembleSourceFile (void);
int GetChar(FILE *fptr);
sourcefile_t *FindFile (sourcefile_t *srcfile, char *fname);
sourcefile_t *Newfile (sourcefile_t *curfile, char *fname);
sourcefile_t *Prevfile (void);
symbol_t *GetAddress (labels_t **stackpointer);
void AddAddress (symbol_t *label, labels_t **stackpointer);
void AddPathNode (char *path, pathlist_t **plist);
void Fetchfilename (FILE *fptr, char *filename);
void GetLine (void);
void NewJRaddr (void);
void Pass2info (expression_t *expression, unsigned long constrange, long lfileptr);
void ReleaseFile (sourcefile_t *srcfile);
void ReleasePathInfo(void);
void SkipLine (FILE *fptr);
void SourceFilePass1 (void);
void SourceFilePass2 (void);
void WriteListFileLine (void);
void WriteMapFile (void);



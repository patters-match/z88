
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
char *ReadName (void);
int LinkModule (char *filename, long fptr_base);
long ReadLong (FILE * fileid);
module_t *NewModule (void);
unsigned long LoadLong (unsigned char *mptr);
void CreateBinFile (void);
void CreateDeffile (void);
void DefineOrigin (void);
void LinkModules (void);
void ReleaseLinkInfo (void);
void ReleaseModules (void);
void StoreLong (long lw, unsigned char *mptr);
void StoreWord (unsigned short w, unsigned char *mptr);
void WriteGlobal (symbol_t * node);
void WriteLong (long fptr, FILE * fileid);
void WriteMapFile (void);

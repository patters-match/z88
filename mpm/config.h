
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



/* ----------------------------------------------------------------------------------------- */
/* Z80 specific assembler definitions and constants                                          */
#ifdef MPM_Z80

#define MPM_COPYRIGHTMSG "[M]ultiple [P]rocessor [M]odule Assembler - Z80 Edition V1.1 b4 (18/11/2004)"

#define MPMOBJECTHEADER  "MPMRMF-Z80-V01"
#define SIZEOF_MPMOBJHDR 14
#define MPMLIBRARYHEADER "MPMLMF-Z80-V01"
#define SIZEOF_MPMLIBHDR 14

#define DEFAULT_OPTIONS "Default flag options: -sm -nvdbtg"

#define ENVNAME_INCLUDEPATH "MPM_Z80_INCLUDEPATH"
#define ENVNAME_LIBRARYPATH "MPM_Z80_LIBPATH"
#define ENVNAME_STDLIBRARY "MPM_Z80_STDLIBRARY"

#define MAXCODESIZE 65536

#define ALIGN_ADRESSES 0
#endif
/* ----------------------------------------------------------------------------------------- */


#if MSDOS
#define OS_ID "MSDOS"
#define DIRSEP 0x5C         /* "\" */
#define ENVPATHSEP 0x3B     /* ";" */
#endif

#if UNIX
#define OS_ID "UNIX"
#define DIRSEP 0x2F         /* "/" */
#define ENVPATHSEP 0x3A     /* ":" */
#endif

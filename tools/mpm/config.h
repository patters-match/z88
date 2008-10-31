
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



/* ----------------------------------------------------------------------------------------- */
/* Z80 specific assembler definitions and constants                                          */
#ifdef MPM_Z80

#define MPM_COPYRIGHTMSG "[M]ultiple [P]rocessor [M]odule Assembler - Z80 Edition V1.3 build 1"
#define VERSION_NUMBER 13

/* Z80asm object & library file watermark V1 series must both have always same length */
#define Z80ASMOBJHDR  "Z80RMF01"
#define SIZEOF_Z80ASMOBJHDR 8
#define Z80ASMLIBHDR "Z80LMF01"
#define SIZEOF_Z80ASMLIBHDR 8

/* MPM object & library file watermark must both have always same length */
#define MPMOBJECTHEADER  "MPMRMF-Z80-V01"
#define SIZEOF_MPMOBJHDR 14
#define MPMLIBRARYHEADER "MPMLMF-Z80-V01"
#define SIZEOF_MPMLIBHDR 14


#define DEFAULT_OPTIONS "Default flag options: -sm -nvadbctgAC"

#define ENVNAME_INCLUDEPATH "MPM_Z80_INCLUDEPATH"
#define ENVNAME_LIBRARYPATH "MPM_Z80_LIBPATH"
#define ENVNAME_STDLIBRARY "MPM_Z80_STDLIBRARY"

#endif
/* ----------------------------------------------------------------------------------------- */

#if MSDOS
#define OS_ID "MSDOS"
#define DIRSEP 0x5C         /* "\" */
#define ENVPATHSEP 0x3B     /* ";" */
#define MAXCODESIZE 65532	/* MSDOS 64K heap boundary */
#endif

#if UNIX
#define OS_ID "UNIX"
#define DIRSEP 0x2F         /* "/" */
#define ENVPATHSEP 0x3A     /* ":" */
#define MAXCODESIZE 65536
#endif

#define MAX_LINE_BUFFER_SIZE 254
#define MAX_FILENAME_SIZE 254
#define MAX_NAME_SIZE 255
#define MAX_NAME_SIZE 255
#define MAX_EXPR_SIZE 254 /* length of expression in object file max 254 + null = 1 byte */

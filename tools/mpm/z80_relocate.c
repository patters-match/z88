/* -------------------------------------------------------------------------------------------------

    MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
     MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
     MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
     MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
     MMMM       MMMM     PPPP              MMMM       MMMM
     MMMM       MMMM     PPPP              MMMM       MMMM
    MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

                          ZZZZZZZZZZZZZZ    888888888888        000000000
                        ZZZZZZZZZZZZZZ    8888888888888888    0000000000000
                                ZZZZ      8888        8888  0000         0000
                              ZZZZ          888888888888    0000         0000
                            ZZZZ          8888        8888  0000         0000
                          ZZZZZZZZZZZZZZ  8888888888888888    0000000000000
                        ZZZZZZZZZZZZZZ      888888888888        000000000


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

#include <stdio.h>
#include <stdlib.h>

#include "config.h"
#include "datastructs.h"
#include "z80_relocate.h"
#include "modules.h"
#include "errors.h"


/* local variables */

/*
   This binary code sequense is a compiled version of the 'relocate.asm' file
   (bundled with these C source files for reference) that represents the program
   address patch initialisation, performed a single time on the program binary.
   Subsequent calls to the start of the relocatable code just jumps straight to
   the first instruction of the real program.
 */
static unsigned char reloc_routine[] =
"\x08\xD9\xFD\xE5\xE1\x01\x49\x00\x09\x5E\x23\x56\xD5\x23\x4E\x23"
"\x46\x23\xE5\x09\x44\x4D\xE3\x7E\x23\xB7\x20\x06\x5E\x23\x56\x23"
"\x18\x03\x16\x00\x5F\xE3\x19\x5E\x23\x56\xEB\x09\xEB\x72\x2B\x73"
"\xD1\xE3\x2B\x7C\xB5\xE3\xD5\x20\xDD\xF1\xF1\xFD\x36\x00\xC3\xFD"
"\x71\x01\xFD\x70\x02\xD9\x08\xFD\xE9";
static size_t sizeof_relocroutine = 73;
static unsigned char *reloctable = NULL, *relocptr = NULL;
static unsigned short totaladdr, curroffset, sizeof_reloctable;


/* private functions */
static unsigned char *AllocRelocTable( void );


unsigned char *
InitRelocTable( void )
{
   if ((reloctable = AllocRelocTable()) != NULL)
     {
       relocptr = reloctable;
       relocptr += 4;                /* point at first offset to store */
       totaladdr = 0;
       sizeof_reloctable = 0;        /* relocation table, still 0 elements .. */
       curroffset = 0;
     }

   return reloctable;
}


void
RegisterRelocEntry( unsigned short PC )
{
   long constant;

   /* define distance distance between current and previous relocatable address */
   constant = PC - curroffset;

   if ((constant >= 0) && (constant <= 255))
     {
        *relocptr++ = (unsigned char) constant;
        sizeof_reloctable++;
     }
   else
     {
        *relocptr++ = 0;
        *relocptr++ = (unsigned short) (PC - curroffset) % 256U;
        *relocptr++ = (unsigned short) (PC - curroffset) / 256U;
        sizeof_reloctable += 3;
     }

   totaladdr++;
   curroffset = PC;
}


void
WriteRelocHeader( char *filename )
{
  if (totaladdr != 0)  /* only write relocation header (code + table) if a relocation entries were registered */
    {
      WriteBinFile(filename, "wb", reloc_routine, sizeof_relocroutine);/* first the relocate routine */

      reloctable[0] = (unsigned short) totaladdr % 256U;           /* create 4 byte header */
      reloctable[1] = (unsigned short) totaladdr / 256U;           /* - total of relocation elements */
      reloctable[2] = (unsigned short) sizeof_reloctable % 256U;
      reloctable[3] = (unsigned short) sizeof_reloctable / 256U;   /* - total size of relocation table elements */

      WriteBinFile(filename, "ab", reloctable, sizeof_reloctable + 4); /* then append relocation table inclusive 4 byte header */
      printf ("Relocation header is %d bytes.\n", sizeof_relocroutine + sizeof_reloctable + 4);
    }
}


void
FreeRelocTable ( void )
{
   if ( reloctable != NULL)
     free (reloctable);
}


static unsigned char *
AllocRelocTable( void )
{
   return (unsigned char *) malloc (32768U);
}

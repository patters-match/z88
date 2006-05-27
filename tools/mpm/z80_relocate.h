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


unsigned char *InitRelocTable( void );
void RegisterRelocEntry ( unsigned long PC );
void WriteRelocHeader ( char *filename );
void FreeRelocTable ( void );

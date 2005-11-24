**************************************************************************************************

This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
                                                      000000000000000000   ZZZZZZZZZZZZZZZZZZZ
OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
or modify it under the terms of the GNU General      0000            0000            ZZZZZ
Public License as published by the Free Software     0000            0000          ZZZZZ
Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with OZ; see the file
COPYING. If not, write to:
                                 Free Software Foundation, Inc.
                                 59 Temple Place-Suite 330,
                                 Boston, MA 02111-1307, USA.

$Id$
***************************************************************************************************


---------------------------------------------------------------------------------------------------
Compiling the Z88 ROM from the SVN repository
---------------------------------------------------------------------------------------------------

To compile the Z88 ROM, make sure that you have first compiled the Mpm assembler
that is located in the /tools/mpm directory. Use your favorite C compiler on your
platform with the following supplied make files:

cd /tools/mpm
make -f makefile.z80.borlandccp55.win32  [using free Borland C++ V5.5 for Windows]
or
make -f makefile.z80.unix [using GCC on CygWin/Windows, GCC/Linux/*X]

Important: The scripts only work with Mpm Assembler V1.1 b7 (22/11/2005) or later.

Then, just simply execute the rom.bat script (or rom.sh for UNix developers)
and you will have the latest OZ rom compiled from Subversion. Default rom
is UK. You can specify the following country codes to get a localised Z88 ROM:
        DK      Denmark
        FR      France
        SE      Swedish/Finish
        FI      Swedish/Finish

Command line example:
        rom DK
        rom dk

both variations will compile a danish Z88 rom, and stored as 'oz.bin' in the
current directory of the rom compile scripts. You can install/run the rom in the
Z88 emulator, OZvm (in /tools/ozvm), or using a conventional Eprom programmer
and re-blow your 128K chip to be inserted into a real Z88.



---------------------------------------------------------------------------------------------------
Source code guidelines for developers
---------------------------------------------------------------------------------------------------

All source files in these folders follow some guide lines.

All file and folder names are lower case.
All ASCII files contain no tabulator encoding (ASCII 9) for tabulating columns.

Z80 mnemonics:
mnemonics are in lower case.
there's 8 spaces between Z80 instruction and register/parameter, eg.
      ld      hl,0.

Here's a complete example:

.Calculator
        ld      iy, $1FAC
        ld      a, 5
        oz      OS_Esc                          ; Examine special condition


Labels begin at column 1
The assembler begins at column 9
Line comments begin at column 50.

All register input/output parameters in functions or other semantic entity uses
the style from the Developer's Notes.

All variable names and language is plain english.



Z88 Forever!
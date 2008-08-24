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

Since you're reading this, it means that you successfully checked out a fresh copy of the SVN
repository.

To compile the Z88 ROM, you need two utilities - Mpm (assembler) and MakeApp (binary file loader) -
that are necessary to compile the ROM sources into a complete 128K binary. Further, two complete
directories must have been checked out from SVN:
        /oz
        /tools

These contain all the necessary sources and tools to get your Z88 ROM compiled.

Begin with compiling the Mpm assembler, which is located in the /tools/mpm directory. Use your
favorite C compiler on your platform with the following supplied make files:

cd /tools/mpm
make -f makefile.z80.borlandccp55.win32  [using free Borland C++ V5.5 on Windows]
or
make -f makefile.z80.gcc.win32 [using MinGW or Cygwin GCC on Windows]
or
nmake /f makefile.z80.msvc.win32 [using Microsoft Visual C V6.0 or later ]
or
make -f makefile.z80.gcc.unix [using GCC on GCC/Linux/Mac OSX/Unix]

Then, to compile & run the MakeApp utility you need to have a Java Runtime Environment (JRE) 1.4.x or
later installed. Download & install it from http://java.sun.com for your operating system platform.

cd /tools/makeapp
makejar.bat (or ./makeapp.sh for Unix) script).

The bat file (or shell script) contains Java-related instructions if you have problem getting the
java compiler working. An executable JAR file will be produced (makeapp.jar) in the /tools/makeapp
directory.

                                     -  *  -

You've now ready to compile the Z88 rom! Just execute the makerom.bat script (or makerom.sh for Unix
developers) and you will have the latest OZ rom compiled from SVN, that can be installed as a binary
for slot 0 or slot 1.

To use slot 0 you need to have a 512K flash AMD chip fitted onto the original motherboard.

To use slot 1 you just need a 1MB flash card in slot 1. OZ gets booted automatically by the built-in ROM
and using an external card saves modifying the original Z88 altogether.

OZ has been ported to slots 0 and 1, which enables you to blow the code to either slot. To compile it, use
the following commands.

        makerom-slot0.bat   (DOS Slot 0)
        makerom-slot1.bat   (DOS slot 1)
or
        ./makerom-slot0.sh  (UNIX slot 0)
        ./makerom-slot1.sh  (UNIX slot 1)

You use RomUpdate (/z88apps/romupdate) to actually blow the bank binaries to the flash card.
Upload "romupdate.bas", "romupdate.crc", and the generated "romupdate.cfg" file with the
oz.* bank files to your Z88. Start a BBC BASIC application and RUN"romupdate.bas". The flash card will
be cleared and the binaries blown; finally the Z88 is hard reset and OZ is booted from either slot 0 or 1.

You can install/run the rom binary in the Z88 emulator, OZvm (in /tools/ozvm), or using a conventional
Eprom programmer and re-blow your 128K or larger chip to be inserted into a real Z88.
The easiest way for run the compiled ROM is to execute the run-oz.bat/sh script which will run the
emulator with the latest OZ installed in slot 1 and boot the "virtual" Z88.

Important:
The rom script only works with Mpm Assembler V1.2 build 8 or later.
(You will have a fully working version, if you are using the latest sources from the SVN checkout)


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
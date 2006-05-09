:: ******************************************************************************************************************
::
::    ZZZZZZZZZZZZZZZZZZZZ    8888888888888       00000000000
::  ZZZZZZZZZZZZZZZZZZZZ    88888888888888888    0000000000000
::               ZZZZZ      888           888  0000         0000
::             ZZZZZ        88888888888888888  0000         0000
::           ZZZZZ            8888888888888    0000         0000       AAAAAA         SSSSSSSSSSS   MMMM       MMMM
::         ZZZZZ            88888888888888888  0000         0000      AAAAAAAA      SSSS            MMMMMM   MMMMMM
::       ZZZZZ              8888         8888  0000         0000     AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
::     ZZZZZ                8888         8888  0000         0000    AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
::   ZZZZZZZZZZZZZZZZZZZZZ  88888888888888888    0000000000000     AAAA      AAAA           SSSSS   MMMM       MMMM
:: ZZZZZZZZZZZZZZZZZZZZZ      8888888888888       00000000000     AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM
::
:: Z80asm compile script for DOS/Windows
:: (C) Gunther Strube (gbs@users.sf.net) 1995-2006
::
:: Z80asm is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: Z80asm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with Z80asm;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: ******************************************************************************************************************

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\z80asm

:: delete previously compiled files
del *.obj *.bin *.map mth.def z80asm.epr z80asm.bn? z80asm.6?

:: Compile the MTH, application code and rom header
..\..\tools\mpm\mpm -b -I..\..\oz\sysdef tokens
..\..\tools\mpm\mpm -bg -I..\..\oz\sysdef mth
..\..\tools\mpm\mpm -bc -I..\..\oz\sysdef -l..\..\stdlib\standard.lib @z80asm
..\..\tools\mpm\mpm -b -I..\..\oz\sysdef romhdr

:: Create a 64K image with Z80asm (required by MakeApp)
java -jar ..\..\tools\makeapp\makeapp.jar -f z80asm.loadmap

:: bottom 16K of 64K image is not used. A new z80asm.epr image will be generated.
del z80asm.epr z80asm.60

:: final binary is 48K Eprom image
copy /B z80asm.61 + /B z80asm.62 + /B z80asm.63 /B z80asm.epr

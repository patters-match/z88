:: **************************************************************************************************
:: Kernel (banks 0,7) compilation script for Windows/DOS.
::
:: This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
::                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
:: OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
:: or modify it under the terms of the GNU General      0000            0000            ZZZZZ
:: Public License as published by the Free Software     0000            0000          ZZZZZ
:: Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
:: any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
:: that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
:: without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
:: BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
:: the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with OZ; see the file
:: COPYING. If not, write to:
::                                  Free Software Foundation, Inc.
::                                  59 Temple Place-Suite 330,
::                                  Boston, MA 02111-1307, USA.
::
:: $Id$
:: ***************************************************************************************************

:: create binaries for lowram and application data
cd bank7
..\..\tools\mpm\mpm -bg -nv -I..\sysdef @lowram.prj
dir *.err 2>nul >nul || goto COMPILE_APPDORS
cd ..
goto COMPILE_ERROR

:COMPILE_APPDORS
..\..\tools\mpm\mpm -bg -nv -I..\sysdef appdors.asm
cd ..

:: compile kernel to resolve labels for lowram.asm
echo compiling kernel
..\tools\mpm\mpm -bg -nv -DKB%1 -I.\sysdef @kernel.prj

:: create lowram.bin with correct addresses
cd bank7
..\..\tools\mpm\mpm -b -nv -DFINAL -I..\sysdef @lowram.prj
cd ..

:: compile kernel with correct lowram code
..\tools\mpm\mpm -bc -nv -DKB%1 -I.\sysdef @kernel.prj

:COMPILE_ERROR
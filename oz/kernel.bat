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


:: create lowram.def (address pre-compilation) for kernel1.prj compilation
cd bank7
..\..\tools\mpm\mpm -g -nv -I..\sysdef @lowram.prj
dir *.err 2>nul >nul || goto COMPILE_APPDORS
cd ..
goto COMPILE_ERROR

:: create application DOR data (binary) and address references for bank 2 compile script
:COMPILE_APPDORS
..\..\tools\mpm\mpm -bg -nv -I..\sysdef appdors.asm

:: pre-compile kernel in bank 0 to resolve labels for lowram.asm
cd ..\bank0
echo compiling kernel
..\..\tools\mpm\mpm -g -nv -I..\sysdef @kernel0.prj

:: create final lowram binary with correct addresses from bank 0 kernel
cd ..\bank7
..\..\tools\mpm\mpm -b -nv -DCOMPILE_BINARY -I..\sysdef @lowram.prj

:: compile final kernel binary for bank 7 with correct lowram code and correct bank 0 references
..\..\tools\mpm\mpm -bg -nv -DCOMPILE_BINARY -DKB%1 -I..\sysdef @kernel7.prj

:: compile final kernel binary for bank 0 using correct bank 7 references
cd ..\bank0
..\..\tools\mpm\mpm -b -nv -DCOMPILE_BINARY -I..\sysdef @kernel0.prj
cd ..
:COMPILE_ERROR
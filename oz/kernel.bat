:: **************************************************************************************************
:: Kernel compilation script for Windows/DOS.
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

:: ensure that we have an up-to-date standard library
:: (NB: this is done temporarily while integrating Flash / File Area standard libraries into OZ)
cd ..\stdlib
call makelib.bat
cd ..\oz

:: create ostables.def (address pre-compilation) containing OS system base lookup table address in bank 0
cd os
..\..\tools\mpm\mpm -g ostables.asm
dir *.err 2>nul >nul || goto PRECOMPILE_LOWRAM
goto COMPILE_ERROR

:: create lowram.def and keymap.def (address pre-compilation) for kernel0.prj and kernel7.prj compilation
:PRECOMPILE_LOWRAM
..\..\tools\mpm\mpm -g -I..\def lowram.asm
dir *.err 2>nul >nul || goto PRECOMPILE_BANK0
goto COMPILE_ERROR

:: pre-compile kernel in bank 0 to resolve labels for lowram.asm
:PRECOMPILE_BANK0
..\..\tools\mpm\mpm -g -I..\def @kernel0.prj
dir *.err 2>nul >nul || goto COMPILE_LOWRAM
goto COMPILE_ERROR

:: create final lowram binary with correct addresses from bank 0 kernel
:COMPILE_LOWRAM
..\..\tools\mpm\mpm -b -DCOMPILE_BINARY -I..\def lowram.asm
dir *.err 2>nul >nul || goto COMPILE_KERNEL7
goto COMPILE_ERROR

:: compile final kernel binary for bank 7 with correct lowram code and correct bank 0 references
:COMPILE_KERNEL7
..\..\tools\mpm\mpm -bg -DCOMPILE_BINARY -DKB%1 -I..\def -l..\..\stdlib\standard.lib @kernel7.prj
dir *.err 2>nul >nul || goto COMPILE_KERNEL0
goto COMPILE_ERROR

:: compile final kernel binary with OS tables for bank 0 using correct bank 7 references
:COMPILE_KERNEL0
..\..\tools\mpm\mpm -b -DCOMPILE_BINARY -I..\def @kernel0.prj
..\..\tools\mpm\mpm -b -DCOMPILE_BINARY ostables.asm

:COMPILE_ERROR
cd ..
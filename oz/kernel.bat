:: **************************************************************************************************
:: OZ Kernel compilation script for Windows/DOS.
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

cd os

:: create lowram.def and keymap.def (address pre-compilation) for lower and upper kernel compilation
:PRECOMPILE_LOWRAM
cd lowram
..\..\..\tools\mpm\mpm -dg -DOZ_SLOT%1 %2 -I..\..\def @lowram.prj
if ERRORLEVEL 1 goto LOWRAM_COMPILE_ERROR
cd ..

:: pre-compile but no linking of (lower) kernel to resolve labels for lowram.asm
:PRECOMPILE_KERNEL0
..\..\tools\mpm\mpm -g -DOZ_SLOT%1 %2 -I..\def -Ilowram @kernel0.prj
if ERRORLEVEL 1 goto COMPILE_ERROR

:: create final lowram binary with correct addresses from lower kernel
:COMPILE_LOWRAM
cd lowram
..\..\..\tools\mpm\mpm -b -DOZ_SLOT%1 %2 -DCOMPILE_BINARY -I..\..\def @lowram.prj
if ERRORLEVEL 1 goto LOWRAM_COMPILE_ERROR
cd ..

:: compile final (upper) kernel binary with correct lowram code and correct lower kernel references
:COMPILE_KERNEL1
..\..\tools\mpm\mpm -dbg -DCOMPILE_BINARY -DOZ_SLOT%1 %2 -I..\def -Ilowram -l..\..\stdlib\standard.lib @kernel1.prj
if ERRORLEVEL 1 goto COMPILE_ERROR

:: compile final kernel 0 binary using correct kernel 1 references
:COMPILE_KERNEL0
..\..\tools\mpm\mpm -db -DCOMPILE_BINARY -DOZ_SLOT%1 %2 -I..\def -Ilowram @kernel0.prj
if ERRORLEVEL 1 goto COMPILE_ERROR

:: compile final OSTABLE
:COMPILE_FINALOSTABLES
..\..\tools\mpm\mpm -db -DOZ_SLOT%1 -I..\def @ostables.prj
if ERRORLEVEL 1 goto COMPILE_ERROR
goto END

:LOWRAM_COMPILE_ERROR
cd ..
:COMPILE_ERROR
set compile_status=1

:END
:: All files of kernel were successfully compiled..
cd ..

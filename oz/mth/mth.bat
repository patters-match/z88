:: **************************************************************************************************
:: Windows/DOS compilation script for MTH, keymaps, font bitmaps and OZ ROM header.
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

@echo off

:COMPILE_KEYMAPS
..\..\tools\mpm\mpm -bg -I..\def keymaps.asm
dir *.err 2>nul >nul || goto COMPILE_LORES1
goto COMPILE_ERROR

:COMPILE_LORES1
..\..\tools\mpm\mpm -bg -I..\def lores1.asm
dir *.err 2>nul >nul || goto COMPILE_HIRES1
goto COMPILE_ERROR

:COMPILE_HIRES1
..\..\tools\mpm\mpm -bg -I..\def hires1.asm
dir *.err 2>nul >nul || goto COMPILE_MTH
goto COMPILE_ERROR

:COMPILE_MTH
..\..\tools\mpm\mpm -bg -I..\def @mth.prj
dir *.err 2>nul >nul || goto COMPILE_ROMHDR
goto COMPILE_ERROR

:COMPILE_ROMHDR
..\..\tools\mpm\mpm -b -I..\def romhdr.asm
dir *.err 2>nul >nul || goto END
goto COMPILE_ERROR

:COMPILE_ERROR
echo Compilation error occurred! Script aborted.
:END


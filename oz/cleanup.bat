:: **************************************************************************************************
:: OZ ROM compilation cleanup script for Windows/DOS.
:: (C) Gunther Strube (gbs@users.sf.net) 2005-2007
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
:: ***************************************************************************************************

@echo off

:: delete all compile output files, if available..
del /Q ozs?.?? romupdate.cfg 2>nul >nul
del /S /Q *.bn? *.bin *.epr *.map *.obj *.lst *.err *.wrn *.sym 2>nul >nul

:: remove generated DEF files (they are part of the compile dependencies...)
del /Q mth\keymaps.def 2>nul >nul
del /Q mth\lores1.def 2>nul >nul
del /Q mth\hires1.def 2>nul >nul
del /Q mth\mth.def 2>nul >nul
del /Q os\kernel0.def 2>nul >nul
del /Q os\kernel1.def 2>nul >nul
del /Q os\lowram\lowram.def 2>nul >nul
del /Q apps\clcalalm.def 2>nul >nul
del /Q apps\clock\clcalalm.def 2>nul >nul
del /Q apps\impexport\impexp.def 2>nul >nul
del /Q apps\intuition\debug0a.def 2>nul >nul
del /Q apps\intuition\debug0b.def 2>nul >nul

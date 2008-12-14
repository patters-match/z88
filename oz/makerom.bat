:: **************************************************************************************************
:: OZ ROM slot 0/1 compilation script for Windows/DOS
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
:: $Id$
:: ***************************************************************************************************

@echo off

:: compile_status = 1 is used to signal compile error return status in compile scripts
set compile_status=0

:: return version of Mpm to command line environment.
:: Only V1.3 or later of Mpm supports source file dependency
..\tools\mpm\mpm -version 2>nul >nul
if ERRORLEVEL 13 goto COMPILE_OZ
echo Mpm version is less than V1.3, OZ compilation aborted.
echo Mpm displays the following:
..\tools\mpm\mpm
goto END

:COMPILE_OZ
:: ensure that we have an up-to-date standard library, before compiling OZ
cd ..\stdlib
call makelib.bat
cd ..\oz

:: OZ ROM slot directive (first command line argument)
set ozslot=%1

if "%ozslot%"=="0" goto COMPILE_OZ_SLOT0
if "%ozslot%"=="1" goto COMPILE_OZ_SLOT1

:: if no (or unknown) slot directive is specified, compile ROM for slot 1
:COMPILE_OZ_SLOT1
set ozslot=1
set oz_bin="oz.epr"
goto COMPILE_OZ

:COMPILE_OZ_SLOT0
set oz_bin="oz.bin"

:COMPILE_OZ
ECHO Compiling OZ ROM for slot %ozslot%

:: delete previous binary outut, error and warning files... but NOT obj files!
del /Q oz-*.?? romupdate.cfg
del /S /Q *.err *.wrn 2>nul >nul

:: -------------------------------------------------------------------------------------------------
:COMPILE_DIARY
echo compiling Diary application
cd apps\diary
call makeapp %ozslot%
cd ..\..
if ERRORLEVEL 0 goto COMPILE_PIPEDREAM
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_PIPEDREAM
echo compiling PipeDream application
cd apps\pipedream
call makeapp %ozslot%
cd ..\..
if ERRORLEVEL 0 goto COMPILE_IMPEXP
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_IMPEXP
echo compiling Imp/Export popdown
cd apps\impexport
call makeapp %ozslot%
cd ..\..
if ERRORLEVEL 0 goto COMPILE_CLCALALM
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_CLCALALM
echo compiling Clock, Alarm and Calendar popdowns
cd apps\clock
call makeapp %ozslot%
cd ..\..
if ERRORLEVEL 0 goto COMPILE_MTH
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:: create application DOR data (binary)
:COMPILE_MTH
echo compiling MTH structures
cd mth
call mth %ozslot% 2>nul >nul
cd ..
if ERRORLEVEL 0 goto COMPILE_KERNEL
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_KERNEL
echo compiling OZ kernel
call kernel %ozslot% 2>nul >nul
if "%compile_status%"=="1" goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_DCCALLS
echo compiling Index popdown / DC System calls
cd dc
call dc %ozslot% 2>nul >nul
cd ..
if ERRORLEVEL 0 goto COMPILE_FPP
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FPP
echo compiling Floating Point Package
cd fp
call fpp %ozslot% 2>nul >nul
cd ..
if ERRORLEVEL 0 goto COMPILE_TERMINAL
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_TERMINAL
echo compiling Terminal popdown
cd apps\terminal
call makeapp %ozslot% 2>nul >nul
cd ..\..
if ERRORLEVEL 0 goto COMPILE_FILER
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FILER
echo compiling Filer popdown
cd apps\filer
call makeapp %ozslot% 2>nul >nul
cd ..\..
if ERRORLEVEL 0 goto COMPILE_GNCALLS
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_GNCALLS
echo compiling GN System calls
cd gn
call gn %ozslot% 2>nul >nul
cd ..
if ERRORLEVEL 0 goto COMPILE_CALCULATOR
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_CALCULATOR
echo compiling Calculator popdown
cd apps\calculator
call makeapp %ozslot% 2>nul >nul
cd ..\..
if ERRORLEVEL 0 goto COMPILE_PNLPRED
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_PNLPRED
echo compiling Panel and PrinterEd applications
cd apps\panelprted
call makeapp %ozslot% 2>nul >nul
cd ..\..
if ERRORLEVEL 0 goto COMPILE_EAZYLINK
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_EAZYLINK
echo compiling EazyLink
cd apps\eazylink
call makeapp %ozslot% 2>nul >nul
cd ..\..
if ERRORLEVEL 0 goto COMPILE_FLASHSTORE
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FLASHSTORE
echo compiling Flashstore
cd apps\flashstore
call makeapp %ozslot% 2>nul >nul
cd ..\..
if ERRORLEVEL 0 goto COMPILE_ROMHDR
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_ROMHDR
echo compiling OZ ROM Header
cd mth
..\..\tools\mpm\mpm -db -DOZ_SLOT%ozslot% -I..\def @romhdr.prj 2>nul >nul
cd ..
if ERRORLEVEL 0 goto COMPILE_INTUITION
goto COMPILE_ERROR

:COMPILE_INTUITION
echo compiling Intuition for OZ
cd apps\intuition
call make.debugOZ.bat %ozslot%
cd ..\..
if ERRORLEVEL 0 goto COMBINE_BANKS
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:: ROM was compiled successfully, combine the compiled 16K banks into a complete 512K binary
:COMBINE_BANKS
echo Compiled Z88 ROM, and combined into %oz_bin% file.
..\tools\makeapp\makeapp.bat -f rom.slot%ozslot%.loadmap
goto END

:COMPILE_ERROR
echo Compilation error occurred! Script aborted.
dir /S *.err 2>nul >nul || goto END

:: List error files, only if any were created during compilation
dir /S *.err

:END

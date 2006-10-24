:: **************************************************************************************************
:: OZ ROM compilation script for Windows/DOS
:: (C) Gunther Strube (gbs@users.sf.net) 2005
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

:: get OZ localisation compilation directive (first command line argument)
set ozlocale=%1

:: convert lower case argument to upper case ...
if "%ozlocale%"=="uk" set ozlocale=UK
if "%ozlocale%"=="fr" set ozlocale=FR
if "%ozlocale%"=="dk" set ozlocale=DK
if "%ozlocale%"=="fi" set ozlocale=FI
if "%ozlocale%"=="se" set ozlocale=SE

:: compile known localisations
if "%ozlocale%"=="UK" goto COMPILE_OZ
if "%ozlocale%"=="FR" goto COMPILE_OZ
if "%ozlocale%"=="DK" goto COMPILE_OZ
if "%ozlocale%"=="FI" goto COMPILE_OZ
if "%ozlocale%"=="SE" goto COMPILE_OZ

:: if no (or unknown) locale is specified, use default UK
ECHO Unknown or no locale argument specified
set ozlocale=UK

:COMPILE_OZ
if "%ozlocale%"=="UK" ECHO Compiling English Z88 ROM
if "%ozlocale%"=="DK" ECHO Compiling Danish Z88 ROM
if "%ozlocale%"=="FR" ECHO Compiling French Z88 ROM
if "%ozlocale%"=="SE" ECHO Compiling Swedish Z88 ROM
if "%ozlocale%"=="FI" ECHO Compiling Finnish Z88 ROM

:: delete previous compiled files...
call cleanup

:: -------------------------------------------------------------------------------------------------
echo compiling Diary application
cd apps\diary
call bank1 %ozlocale% 2>nul >nul
cd ..\..
dir apps\diary\*.err 2>nul >nul || goto COMPILE_IMPEXP
type apps\diary\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_IMPEXP
echo compiling Imp/Export popdown
cd apps\impexport
call bank1 %ozlocale% 2>nul >nul
cd ..\..
dir apps\impexport\*.err 2>nul >nul || goto COMPILE_BANK1
type apps\impexport\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_BANK1
echo compiling bank 1
cd bank1
call bank1 %ozlocale% 2>nul >nul
cd ..
dir bank1\*.err 2>nul >nul || goto COMPILE_MTH
type bank1\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:: create application DOR data (binary)
:COMPILE_MTH
echo compiling MTH structures
cd mth
call mth %ozlocale% 2>nul >nul
cd ..
dir mth\*.err 2>nul >nul || goto COMPILE_KERNEL
type mth\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_KERNEL
echo compiling OZ kernel
call kernel %ozlocale% 2>nul >nul
dir os\*.err 2>nul >nul || goto CHECK_KERNEL7_ERRORS
type os\*.err
goto COMPILE_ERROR
:CHECK_KERNEL7_ERRORS
dir os\*.err 2>nul >nul || goto COMPILE_DCCALLS
type os\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_DCCALLS
echo compiling Index popdown / DC System calls
cd dc
call bank2 2>nul >nul
cd ..
dir dc\*.err 2>nul >nul || goto COMPILE_FPP
type dc\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FPP
echo compiling Floating Point Package
cd fpp
call bank2 2>nul >nul
cd ..
dir fpp\*.err 2>nul >nul || goto COMPILE_TERMINAL
type fpp\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_TERMINAL
echo compiling Terminal popdown
cd apps\terminal
call bank2 2>nul >nul
cd ..\..
dir apps\terminal\*.err 2>nul >nul || goto COMPILE_FILER
type apps\terminal\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FILER
echo compiling Filer popdown
cd apps\filer
call bank2 2>nul >nul
cd ..\..
dir apps\filer\*.err 2>nul >nul || goto COMPILE_GNCALLS
type apps\filer\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_GNCALLS
echo compiling GN System calls
cd gn
call bank3 %ozlocale% 2>nul >nul
cd ..
dir gn\*.err 2>nul >nul || goto COMPILE_CALCULATOR
type gn\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_CALCULATOR
echo compiling Calculator popdown
cd apps\calculator
call bank3 %ozlocale% 2>nul >nul
cd ..\..
dir apps\calculator\*.err 2>nul >nul || goto COMPILE_BANK6
type apps\calculator\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_BANK6
echo compiling bank 6
cd bank6
call bank6 2>nul >nul
cd ..
dir bank6\*.err 2>nul >nul || goto COMPILE_EAZYLINK
type bank6\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_EAZYLINK
echo compiling EazyLink
cd apps\eazylink
call make.eazylink.bat
cd ..\..
dir apps\eazylink\*.err 2>nul >nul || goto COMBINE_BANKS
type apps\eazylink\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:: ROM was compiled successfully, combine the compiled 16K banks into a complete 256K binary
:COMBINE_BANKS
echo Compiled Z88 ROM, and combined into "oz.bin" file.
..\tools\makeapp\makeapp.bat -f rom.loadmap
goto END

:COMPILE_ERROR
echo Compilation error occurred! Script aborted.
:END

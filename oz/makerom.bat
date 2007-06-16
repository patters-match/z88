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

:: delete previous compiled files...
call cleanup

:: -------------------------------------------------------------------------------------------------
:COMPILE_DIARY
echo compiling Diary application
cd apps\diary
call makeapp 2>nul >nul
cd ..\..
dir apps\diary\*.err 2>nul >nul || goto COMPILE_PIPEDREAM
type apps\diary\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_PIPEDREAM
echo compiling PipeDream application
cd apps\pipedream
call makeapp 2>nul >nul
cd ..\..
dir apps\pipedream\*.err 2>nul >nul || goto COMPILE_IMPEXP
type apps\pipedream\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_IMPEXP
echo compiling Imp/Export popdown
cd apps\impexport
call makeapp 2>nul >nul
cd ..\..
dir apps\impexport\*.err 2>nul >nul || goto COMPILE_CLCALALM
type apps\impexport\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_CLCALALM
echo compiling Clock, Alarm and Calendar popdowns
cd apps\clock
call makeapp 2>nul >nul
cd ..\..
dir apps\clock\*.err apps\alarm\*.err apps\calendar\*.err 2>nul >nul || goto COMPILE_MTH
type apps\clock\*.err apps\alarm\*.err apps\calendar\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:: create application DOR data (binary)
:COMPILE_MTH
echo compiling MTH structures
cd mth
call mth 2>nul >nul
cd ..
dir mth\*.err 2>nul >nul || goto COMPILE_KERNEL
type mth\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_KERNEL
echo compiling OZ kernel
call kernel 2>nul >nul
dir os\*.err 2>nul >nul || goto CHECK_KERNEL1_ERRORS
type os\*.err
goto COMPILE_ERROR
:CHECK_KERNEL1_ERRORS
dir os\*.err 2>nul >nul || goto COMPILE_DCCALLS
type os\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_DCCALLS
echo compiling Index popdown / DC System calls
cd dc
call dc 2>nul >nul
cd ..
dir dc\*.err apps\index\*.err 2>nul >nul || goto COMPILE_FPP
type dc\*.err apps\index\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FPP
echo compiling Floating Point Package
cd fp
call fpp 2>nul >nul
cd ..
dir fp\*.err 2>nul >nul || goto COMPILE_TERMINAL
type fp\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_TERMINAL
echo compiling Terminal popdown
cd apps\terminal
call makeapp 2>nul >nul
cd ..\..
dir apps\terminal\*.err 2>nul >nul || goto COMPILE_FILER
type apps\terminal\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FILER
echo compiling Filer popdown
cd apps\filer
call makeapp 2>nul >nul
cd ..\..
dir apps\filer\*.err 2>nul >nul || goto COMPILE_GNCALLS
type apps\filer\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_GNCALLS
echo compiling GN System calls
cd gn
call gn 2>nul >nul
cd ..
dir gn\*.err 2>nul >nul || goto COMPILE_CALCULATOR
type gn\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_CALCULATOR
echo compiling Calculator popdown
cd apps\calculator
call makeapp 2>nul >nul
cd ..\..
dir apps\calculator\*.err 2>nul >nul || goto COMPILE_PNLPRED
type apps\calculator\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_PNLPRED
echo compiling Panel and PrinterEd applications
cd apps\panelprted
call makeapp 2>nul >nul
cd ..\..
dir apps\panelprted\*.err 2>nul >nul || goto COMPILE_EAZYLINK
type apps\panelprted\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_EAZYLINK
echo compiling EazyLink
cd apps\eazylink
call makeapp
cd ..\..
dir apps\eazylink\*.err 2>nul >nul || goto COMPILE_FLASHSTORE
type apps\eazylink\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:COMPILE_FLASHSTORE
echo compiling Flashstore
cd apps\flashstore
call makeapp
cd ..\..
dir apps\flashstore\*.err 2>nul >nul || goto COMBINE_BANKS
type apps\flashstore\*.err
goto COMPILE_ERROR

:: -------------------------------------------------------------------------------------------------
:: ROM was compiled successfully, combine the compiled 16K banks into a complete 512K binary
:COMBINE_BANKS
echo Compiled Z88 ROM, and combined into "oz.bin" file.
..\tools\makeapp\makeapp.bat -f rom.loadmap
goto END

:COMPILE_ERROR
echo Compilation error occurred! Script aborted.
:END

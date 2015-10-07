:: *************************************************************************************
:: FlashTest
:: (C) Gunther Strube (gstrube@gmail.com) 1997-2014
::
:: FlashTest is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: FlashTest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with FlashTest;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************
@echo off

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\flashtest

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_FLASHTEST
echo Mpm version is less than V1.5, FlashTest compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_FLASHTEST

del *.obj *.map flashtest.epr fltest.bin romhdr.bin
mpm -I..\..\oz\def -l..\..\stdlib\standard.lib -b fltest.asm ramcard.asm
mpm -b romhdr.asm
dir *.err 2>nul >nul || goto CREATE_EPR
goto LIST_ERRORS

:CREATE_EPR
:: Create a 16K Rom Card with FlashTest
z88card flashtest.epr fltest.bin 0000 romhdr.bin 3fc0
goto END

:LIST_ERRORS
del *.obj *.map flashtest.epr fltest.bin romhdr.bin
type *.err
:END

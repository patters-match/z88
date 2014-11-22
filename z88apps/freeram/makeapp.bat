:: *************************************************************************************
:: FreeRam
:: (C) Gunther Strube (gstrube@gmail.com) 1998
::
:: FreeRam is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: FreeRam is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with FreeRam;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

@echo off

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\freeram

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_FREERAM
echo Mpm version is less than V1.5, FreeRam compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_FREERAM

del *.obj *.bin *.map FreeRam.63 FreeRam.epr
mpm -b -I..\..\oz\def -l..\..\stdlib\standard.lib freeram.asm
mpm -b romhdr

:: Create a 16K Rom Card with FreeRam
z88card -f freeram.loadmap

:END
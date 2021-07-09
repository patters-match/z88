:: *************************************************************************************
:: ZetriZ
:: (C) Gunther Strube (hello@bits4fun.net) 1995-2006
::
:: ZetriZ is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: ZetriZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with ZetriZ;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

@echo off

del /S /Q *.obj *.sym *.bin *.map zetriz.epr 2>nul >nul

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\zetriz

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_ZETRIZ
echo Mpm version is less than V1.5, Zetriz compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_ZETRIZ

:: Compile the MTH and the application code
mpm -b -I..\..\oz\def -l..\..\stdlib\standard.lib @zetriz.prj
mpm -b -I..\..\oz\def romhdr

:: Create a 16K Rom Card with ZetriZ to be blown by RomCombiner, Zprom or RomUpdate on real cards
z88card -f zetriz.loadmap

:END
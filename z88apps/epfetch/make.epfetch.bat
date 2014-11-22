:: *************************************************************************************
:: EP-Fetch2 application make script for DOS/Windows
::
:: EP-Fetch2 is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: EP-Fetch2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with EP-Fetch2;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

@echo off

:: compile EP-Fetch2 application from scratch
:: (this compile script is located in /z88apps/epfetch)

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_EPFETCH
echo Mpm version is less than V1.5, Ep-Fetch2 compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_EPFETCH

del *.obj *.bin *.map
mpm -bg -I..\..\oz\def epfetch2
mpm -b romhdr

:: Create a 16K Rom Card with EP-Fetch2
z88card -f epfetch2.loadmap

:END
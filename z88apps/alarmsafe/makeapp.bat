:: *************************************************************************************
::
:: AlarmSafe compile script for DOS/Windows
:: Alarm archiving popdown utility, (c) Garry Lancaster, 1998-2011
::
:: AlarmSafe is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: AlarmSafe is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with AlarmSafe;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
::
:: *************************************************************************************

@echo off

del *.obj *.sym *.bin *.map *.6? alarmsafe.epr

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_ALARMSAFE
echo Mpm version is less than V1.5, AlarmSafe compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_ALARMSAFE
:: Assemble the popdown and MTH
mpm -b -I..\..\oz\def alarmsafe.asm

:: Assemble the card header
mpm -b -I..\..\oz\def romheader.asm

:: Create a 16K Rom Card with AlarmSafe
z88card -f alarmsafe.loadmap

:END

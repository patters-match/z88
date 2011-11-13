:: *************************************************************************************
:: Unix execute script and auto-compiler for Z88 Forth AppGen Tools
:: Z88 Forth AppGen Tools (c) Garry Lancaster, 1999-2011
::
:: Z88 Forth AppGen Tools is free software; you can redistribute it and/or modify it under
:: the terms of the GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: Z88 Forth AppGen Tools is distributed in the hope that it will be useful, but WITHOUT
:: ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
:: PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with Z88
:: Forth AppGen Tools; see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: *************************************************************************************

::@echo off

set FORTH_PATH=%0
set FORTH_PATH=%FORTH_PATH:\makeforthapp.bat=%
set OZVM_PATH=%FORTH_PATH%\..\ozvm
set OZ_ROM=%FORTH_PATH%\..\..\oz\oz.bin

if exist %OZ_ROM% goto EXECUTE_MAKEFORTHAPP
echo Please build OZ for slot 0 - oz.bin. Aborting.
goto END_MAKEFORTHAPP

:EXECUTE_MAKEFORTHAPP
java -jar %OZVM_PATH%\z88.jar ram0 512 rom %OZ_ROM% crd1 16 27c %FORTH_PATH%\camelforth.epr fcd2 1024 29f fcd3 1024 29f -f %FORTH_PATH%\boot.cli -f %FORTH_PATH%\appgen.fth %* initdebug %FORTH_PATH%\extractapp.dbg

:END_MAKEFORTHAPP


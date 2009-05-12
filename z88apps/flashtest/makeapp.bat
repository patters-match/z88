:: *************************************************************************************
:: FlashTest
:: (C) Gunther Strube (gbs@users.sf.net) 1997-2005
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
:: $Id$
::
:: *************************************************************************************
@echo off

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\flashtest

del *.obj *.map flashtest.epr fltest.bin romhdr.bin
..\..\tools\mpm\mpm -I..\..\oz\def -l..\..\stdlib\standard.lib -b fltest.asm ramcard.asm fepcrdid.asm fepcrddata.asm fepblera.asm
..\..\tools\mpm\mpm -b romhdr.asm
dir *.err 2>nul >nul || goto CREATE_EPR
goto LIST_ERRORS

:CREATE_EPR
:: Create a 16K Rom Card with FlashTest
..\..\tools\makeapp\makeapp.bat flashtest.epr fltest.bin 0000 romhdr.bin 3fc0
goto END

:LIST_ERRORS
del *.obj *.map flashtest.epr fltest.bin romhdr.bin
type *.err
:END
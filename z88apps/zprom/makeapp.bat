:: *************************************************************************************
:: Zprom
:: (C) Gunther Strube (gbs@users.sf.net) 1993-2005
::
:: Zprom is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: Zprom is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with Zprom;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: *************************************************************************************

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\zprom

:: Compile the MTH and the application code
del *.obj *.bin *.map zprom.epr
..\..\tools\mpm\mpm -b -I..\..\oz\def tokens
..\..\tools\mpm\mpm -bg -I..\..\oz\def mthzprom
..\..\tools\mpm\mpm -b -I..\..\oz\def -l..\..\stdlib\standard.lib @zprom
..\..\tools\mpm\mpm -b -I..\..\oz\def romhdr

:: Create a 32K Rom Card with Zprom ($3E contains MTH, $3F contains application code)
..\..\tools\makeapp\makeapp.bat -sz 32 zprom.epr tokens.bin 3e0000 mthzprom.bin 3e0400 zprom.bin 3fc000 romhdr.bin 3f3fc0

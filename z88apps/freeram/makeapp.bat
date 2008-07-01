:: *************************************************************************************
:: FreeRam
:: (C) Gunther Strube (gbs@users.sf.net) 1998
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
:: $Id$
::
:: *************************************************************************************

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\freeram

del *.obj *.bin *.map FreeRam.63 FreeRam.epr
..\..\tools\mpm\mpm -b -I..\..\oz\def -l..\..\stdlib\standard.lib freeram.asm
..\..\tools\mpm\mpm -b romhdr

:: Create a 16K Rom Card with FreeRam
..\..\tools\makeapp\makeapp.bat -f freeram.loadmap
:: *************************************************************************************
::
:: Installer/Bootstrap/Packages compile script for DOS/Windows
:: Installer/Bootstrap/Packages (c) Garry Lancaster 1998-2011
::
:: Installer/Bootstrap/Packages is free software; you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by the Free Software
:: Foundation; either version 2, or (at your option) any later version.
:: Installer/Bootstrap/Packages is distributed in the hope that it will be useful, but
:: WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
:: FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with
:: Installer/Bootstrap/Packages; see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: *************************************************************************************

del *.obj *.sym *.bin *.map *.6? ibp.epr

:: Assemble the popdown and MTH
..\..\tools\mpm\mpm -b -oibp.bin -I..\..\oz\def @ibp.prj

:: Assemble the card header
..\..\tools\mpm\mpm -b -I..\..\oz\def romheader.asm

:: Create a 16K Rom Card with Installer/Bootstrap/Packages
..\..\tools\makeapp\makeapp.bat -f ibp.loadmap


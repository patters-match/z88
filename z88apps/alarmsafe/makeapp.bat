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
:: $Id$
::
:: *************************************************************************************

del *.obj *.sym *.bin *.map *.6? alarmsafe.epr

:: Assemble the popdown and MTH
..\..\tools\mpm\mpm -b -I..\..\oz\def alarmsafe.asm

:: Assemble the card header
..\..\tools\mpm\mpm -b -I..\..\oz\def romheader.asm

:: Create a 16K Rom Card with AlarmSafe
..\..\tools\makeapp\makeapp.bat -f alarmsafe.loadmap


:: *************************************************************************************
:: RomUpdate - Popdown compile script
:: (C) Gunther Strube (gbs@users.sf.net) 2005
::
:: RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with RomUpdate;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: *************************************************************************************
@echo off

del *.obj *.bin *.map romupdate.epr
..\..\tools\mpm\mpm -b -oromupdate.bin -DPOPDOWN -I..\..\oz\sysdef -l..\..\stdlib\standard.lib @romupdate.popdown.prj
dir *.err 2>nul >nul || goto COMPILE_ROMHDR
goto LIST_ERRORS

:COMPILE_ROMHDR
..\..\tools\mpm\mpm -b romhdr
dir *.err 2>nul >nul || goto CREATE_JAR
goto LIST_ERRORS

:CREATE_JAR
:: Create a 16K Rom Card with RomUpdate
java -jar ..\..\tools\makeapp\makeapp.jar romupdate.epr romupdate.bin 3f0000 romhdr.bin 3f3fc0
goto END

:LIST_ERRORS
type *.err
:END
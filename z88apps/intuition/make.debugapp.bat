:: *************************************************************************************
:: Intuition Z88 application make script for DOS/Windows
:: (C) Gunther Strube (gbs@users.sourceforge.net) 1991-2005
::
:: Intuition is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with Intuition;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: *************************************************************************************

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\intuition

:: compile Intuition application from scratch
:: Intuition application uses segment 2 for bank switching (Intuition application is located in segment 3)
del *.def *.obj *.bin *.map *.epr
..\..\tools\mpm\mpm -b -g -DSEGMENT2 -I..\..\oz\sysdef -l..\..\stdlib\standard.lib mthdbg tokens mthtext
..\..\tools\mpm\mpm -b -DSEGMENT2 -I..\..\oz\sysdef -l..\..\stdlib\standard.lib @debugapl
..\..\tools\mpm\mpm -b -DSEGMENT2 romhdr

:: produce individual banks to be blown by RomCombiner or Zprom on real cards
java -jar ..\..\tools\makeapp\makeapp.jar intuition.62 mthdbg.bin 0000
java -jar ..\..\tools\makeapp\makeapp.jar intuition.63 debugger.bin 0000 romhdr.bin 3fc0

:: produce a complete 32K card image for OZvm
java -jar ..\..\tools\makeapp\makeapp.jar -sz 32 intuition.epr mthdbg.bin 3e0000 debugger.bin 3f0000 romhdr.bin 3f3fc0

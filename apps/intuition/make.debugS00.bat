:: *************************************************************************************
:: Intuition make script (DOS/Windows) to build executable for upper 8K segment 0
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

:: compile Intuition code from scratch
:: Intuition uses segment 3 for bank switching (Intuition is located at $2000 - upper 8K of segment 0)
del *.def *.obj *.bin *.map
..\..\csrc\mpm\mpm -b -g -DINT_SEGM0 -DSEGMENT3 -I..\oz\sysdef -l..\stdlib\standard.lib @debug0b
..\..\csrc\mpm\mpm -b -DINT_SEGM0 -DSEGMENT3 -I..\oz\sysdef -l..\stdlib\standard.lib @debug0a

:: combine the two images as a single 16K executable, to be executed at $2000 in upper 8K segment 0
:: 'debug0a.bin' is the bootstrap and the core instruction debugger
:: 'debug0b.bin' contains the debugger command line
java -jar ..\..\makeapp.jar debugS00.bin debug0a.bin 0000 debug0b.bin 2000

# delete the redundant output binaries
del debug0a.bin debug0b.bin

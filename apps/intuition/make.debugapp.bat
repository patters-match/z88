:: *************************************************************************************
:: Intuition
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

del *.obj *.bin *.map *.epr
..\..\csrc\mpm\mpm -b -g -I..\oz\sysdef -l..\stdlib\standard.lib mthdbg tokens mthtext
..\..\csrc\mpm\mpm -b -I..\oz\sysdef -l..\stdlib\standard.lib @debugapl
..\..\csrc\mpm\mpm -b romhdr
java -jar ..\..\makeapp.jar -sz 32 intuition.epr mthdbg.bin 3e0000 debugger.bin 3f0000 romhdr.bin 3f3fc0
::java -jar ..\..\z88.jar ram1 1024 fcd3 512 28f crd2 1024 29f flashstore.epr debug
java -jar ..\..\z88.jar ram0 512 s3 intuition.epr

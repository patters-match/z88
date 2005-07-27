:: *************************************************************************************
:: FlashStore
:: (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2005
::
:: FlashStore is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with FlashStore;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: *************************************************************************************

del *.obj *.bin *.map flashstore.epr
..\..\csrc\mpm\mpm -a -I..\oz\sysdef -l..\stdlib\standard.lib @flashstore
..\..\csrc\mpm\mpm -b romhdr
:: java -jar ..\..\makeapp.jar -sz 32 appfiles.crd filearea.bnk 3e0000 flashstore.epr 3f0000
java -jar ..\..\makeapp.jar flashstore.epr fsapp.bin 3f0000 romhdr.bin 3f3fc0
:: java -jar ..\..\z88.jar ram0 512 epr1 1024 29f epr2 1024 28f crd3 128 27c flashstore.epr
:: java -jar ..\..\z88.jar ram0 512 crd3 128 27c flashstore.epr
java -jar ..\..\z88.jar fcd3 512 28f crd2 1024 29f flashstore.epr

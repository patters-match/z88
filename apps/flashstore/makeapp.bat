:: *************************************************************************************
:: FlashStore
:: (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2004
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

del *.obj *.bin *.map *.epr
..\..\csrc\mpm\mpm -bv -I..\oz\sysdef -l..\stdlib\standard.lib @flashstore
..\..\csrc\mpm\mpm -bv romhdr
java -jar ..\..\makeapp.jar flashstore.epr fsapp.bin 3f0000 romhdr.bin 3f3fc0
java -jar ..\..\z88.jar ram1 1024 crd3 1024 29f flashstore.epr

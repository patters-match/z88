:: *************************************************************************************
:: EazyLink application make script for DOS/Windows
:: (C) Gunther Strube (gbs@users.sourceforge.net) 2005
::
:: EazyLink is free software; you can redistribute it and/or modify it under the terms of the
:: GNU General Public License as published by the Free Software Foundation;
:: either version 2, or (at your option) any later version.
:: EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
:: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
:: See the GNU General Public License for more details.
:: You should have received a copy of the GNU General Public License along with EazyLink;
:: see the file COPYING. If not, write to the
:: Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
::
:: $Id$
::
:: *************************************************************************************

:: compile EazyLink application from scratch
del *.obj *.bin *.map *.63 *.epr
..\..\csrc\mpm\mpm -b -I..\oz\sysdef -l..\stdlib\standard.lib @eazylink
..\..\csrc\mpm\mpm -b romhdr

:: produce bank to be blown by RomCombiner or Zprom on real cards
java -jar ..\..\makeapp.jar eazylink.63 eazylink.bin 0000 romhdr.bin 3fc0

:: produce a complete 16K card image for OZvm
java -jar ..\..\makeapp.jar eazylink.epr eazylink.bin 0000 romhdr.bin 3fc0

:: execute OZvm and install card, ready to be used after initial hard reset of the virtual Z88
java -jar ..\..\z88.jar ram0 512 s2 eazylink.epr
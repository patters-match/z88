:: *************************************************************************************
:: FlashStore
:: (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2005
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

:: ensure that we have an up-to-date standard library
cd ..\..\stdlib
call makelib.bat
cd ..\z88apps\flashstore

del *.obj *.bin *.map flashstore.63 flashstore.epr
..\..\tools\mpm\mpm -b -I..\..\oz\def -l..\..\stdlib\standard.lib @flashstore
..\..\tools\mpm\mpm -b romhdr

:: Create a 16K Rom Card with FlashStore
..\..\tools\makeapp\makeapp.bat -f flashstore.loadmap

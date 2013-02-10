:: *************************************************************************************
:: FlashStore
:: (C) Gunther Strube (gstrube@gmail.com) & Thierry Peycru (pek@users.sf.net), 1997-2012
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
::
:: *************************************************************************************

call makeapp.bat

:: Execute OZvm with preloaded FlashStore in slot 2 (on a 1Mb AMD Flash)
:: and a 512K Intel Flash Card in slot 3
java -jar ..\..\bin\z88.jar fcd3 512 28f crd2 1024 29f flashstore.epr

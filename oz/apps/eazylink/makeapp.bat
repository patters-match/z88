:: *************************************************************************************
:: EazyLink application OZ ROM make script for DOS/Windows
:: (C) Gunther Strube (gbs@users.sourceforge.net) 2005-2006
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
::
:: *************************************************************************************

:: compile EazyLink application from scratch
:: (this compile script is located in /z88apps/eazylink)
..\..\..\tools\mpm\mpm -b -DOZ_SLOT%1 -I..\..\def -l..\..\..\stdlib\standard.lib @eazylink.prj

#!/bin/bash

# *************************************************************************************
# FlashStore
# (C) Gunther Strube (gstrube@gmail.com) & Thierry Peycru (pek@users.sf.net), 1997-2014
#
# FlashStore is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with FlashStore;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/flashstore

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, FlashStore compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

rm -f fsapp.bin flashstore.63 flashstore.epr
mpm -bg -I../../oz/def mth
mpm -b -I../../oz/def -l../../stdlib/standard.lib @flashstore
mpm -b romhdr

# Create a 16K Rom Card with FlashStore
z88card -f flashstore.loadmap

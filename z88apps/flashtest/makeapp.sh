#!/bin/bash

# *************************************************************************************
# FlashTest
# (C) Gunther Strube (gbs@users.sf.net) 1997-2014
#
# FlashTest is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# FlashTest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with FlashTest;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/flashtest

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, FlashTest compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

rm -f *.obj *.map flashtest.epr fltest.bin romhdr.bin
mpm -b -I../../oz/def -l../../stdlib/standard.lib fltest.asm ramcard.asm
mpm -b romhdr.asm
if test `find . -name '*.err' | wc -l` != 0; then
    rm -f *.obj *.map flashtest.epr fltest.bin romhdr.bin
    cat *.err
else
    # Create a 16K Rom Card with FlashTest
    z88card flashtest.epr fltest.bin 0000 romhdr.bin 3fc0
fi

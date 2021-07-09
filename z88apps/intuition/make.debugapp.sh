#!/bin/bash

# *************************************************************************************
# Intuition Z88 application make script for UNIX/LINUX operating systems
# (C) Gunther Strube (hello@bits4fun.net) 1991-2014
#
# Intuition is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with Intuition;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/intuition

# compile Intuition application from scratch
# Intuition application uses segment 2 for bank switching (Intuition application is located in segment 3)
rm -f *.err *.def *.lst *.obj *.bin *.map *.epr

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, Intuition compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

mpm -b -g -DSEGMENT2 -I../../oz/def -l../../stdlib/standard.lib mthdbg tokens mthtext
mpm -b -DSEGMENT2 -I../../oz/def -l../../stdlib/standard.lib @debugapl
mpm -b -DSEGMENT2 romhdr

# produce individual banks to be blown by RomCombiner or Zprom on real cards
z88card intuition.62 mthdbg.bin 0000
z88card intuition.63 debugger.bin 0000 romhdr.bin 3fc0

# produce a complete 32K card image for OZvm
z88card -sz 32 intuition.epr mthdbg.bin 3e0000 debugger.bin 3f0000 romhdr.bin 3f3fc0

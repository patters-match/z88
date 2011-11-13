#!/bin/bash

# **************************************************************************************************
# OZ ROM slot 0/1 compilation script for Unix.
# (C) Gunther Strube (gbs@users.sf.net) 2005-2007
#
# This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
#                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
# OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
# or modify it under the terms of the GNU General      0000            0000            ZZZZZ
# Public License as published by the Free Software     0000            0000          ZZZZZ
# Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
# any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
# that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
# without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
# BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
# the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with OZ; see the file
# COPYING. If not, write to:
#                                  Free Software Foundation, Inc.
#                                  59 Temple Place-Suite 330,
#                                  Boston, MA 02111-1307, USA.
#
# ***************************************************************************************************

# return version of Mpm to command line environment.
# validate that MPM is V1.3 or later - only this version or later supports source file dependency
MPM_VERSIONTEXT=`../tools/mpm/mpm -version`

if test $? -lt 13; then
  echo Mpm version is less than V1.3, OZ compilation aborted.
  echo Mpm displays the following:
  ../tools/mpm/mpm
  exit 1
fi

# ensure that we have an up-to-date standard library, before compiling OZ
cd ../stdlib; ./makelib.sh; cd ../oz

if test $# -eq 0; then
  # no slot directive is specified, compile ROM for slot 1 as default
  ozslot=1
elif (test $1 != "0") && (test $1 != "1"); then
  # illegal parameters are ignored and preset with slot 1
  ozslot=1
else
  ozslot=$1
fi

if (test $ozslot == "0"); then
  os_bin="oz.bin"
else
  os_bin="oz.epr"
fi

echo compiling OZ ROM for slot $ozslot

# -------------------------------------------------------------------------------------------------
# delete previous error and warning files...
find . -name "*.err" | xargs rm -f
find . -name "*.wrn" | xargs rm -f
# delete all compile output files, if available..
rm -f oz-*.?? romupdate.cfg

# -------------------------------------------------------------------------------------------------
echo compiling Diary application
cd apps/diary
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/diary/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling PipeDream application
cd apps/pipedream
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/pipedream/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Imp/Export popdown
cd apps/impexport
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/impexport/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Clock, Alarm and Calendar popdowns
cd apps/clock
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/clock/*.err apps/alarm/*.err apps/calendar/*.err
  echo Script aborted.
  exit 1
fi


# -------------------------------------------------------------------------------------------------
echo compiling MTH structures
cd mth
. mth.sh $ozslot
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat mth/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling OZ kernel
. kernel.sh $ozslot
if test `find . -name '*.err' | wc -l` != 0; then
  cat os/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Index popdown / DC System calls
cd dc
. dc.sh $ozslot
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat dc/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Floating Point Package
cd fp
. fpp.sh $ozslot
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat fpp/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling compiling Terminal popdown
cd apps/terminal
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/terminal/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Filer popdown
cd apps/filer
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/filer/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling GN system calls
cd gn
. gn.sh $ozslot
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat gn/*.err
  echo Script aborted.
  exit 1
fi

echo compiling Calculator popdown
cd apps/calculator
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/calculator/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Panel and PrinterEd applications
cd apps/panelprted
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/panelprted/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling EazyLink
cd apps/eazylink
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/eazylink/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Flashstore
cd apps/flashstore
. makeapp.sh $ozslot
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/flashstore/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling OZ ROM Header
cd mth
../../tools/mpm/mpm -b -DOZ_SLOT$ozslot -I../def @romhdr.prj
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat mth/*.err
  echo Script aborted.
  exit 1
fi

if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/intuition/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
# ROM was compiled successfully, combine the compiled 16K banks into a complete 512K binary
echo Compiled Z88 ROM, now being combined into $os_bin file.
../tools/makeapp/makeapp.sh -f rom.slot$ozslot.loadmap

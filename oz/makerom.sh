#!/bin/bash

# **************************************************************************************************
# OZ ROM compilation script for Unix.
# (C) Gunther Strube (gbs@users.sf.net) 2005
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
# $Id$
# ***************************************************************************************************

# get OZ localisation compilation directive (first command line argument)
if test $# -eq 0; then
  echo no locale argument specified, use default UK
  ozlocale="UK"
else
  ozlocale="`echo $1 | tr a-z A-Z`"
fi

if test "$ozlocale" = "FR"; then
  echo Compiling French Z88 ROM
elif test "$ozlocale" = "UK"; then
  echo Compiling English Z88 ROM
elif test "$ozlocale" = "DK"; then
  echo Compiling Danish Z88 ROM
elif test "$ozlocale" = "SE"; then
  echo Compiling Swedish Z88 ROM
elif test "$ozlocale" = "FI"; then
  echo Compiling Finnish Z88 ROM
else
  echo Unknown locale specified - using default UK
  ozlocale="UK"
fi


# delete previous compiled files (incl error and warning files)...
. cleanup.sh

# -------------------------------------------------------------------------------------------------
echo compiling Diary application
cd apps/diary
. bank1.sh $ozlocale
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/diary/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Imp/Export popdown
cd apps/impexport
. bank1.sh $ozlocale
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/impexport/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Clock, Alarm & Calendar popdowns
cd apps/clock
. bank1.sh $ozlocale
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/clock/*.err apps/alarm/*.err apps/calendar/*.err
  echo Script aborted.
  exit 1
fi


# -------------------------------------------------------------------------------------------------
echo compiling MTH structures
cd mth
. mth.sh $ozlocale
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat mth/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling OZ kernel
. kernel.sh $ozlocale
if test `find . -name '*.err' | wc -l` != 0; then
  cat os/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Index popdown / DC System calls
cd dc
. bank2.sh
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat dc/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Floating Point Package
cd fpp
. bank2.sh
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat fpp/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling compiling Terminal popdown
cd apps/terminal
. bank2.sh
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/terminal/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling Filer popdown
cd apps/filer
. bank2.sh
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/filer/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling GN system calls
cd gn
. bank3.sh $ozlocale
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat gn/*.err
  echo Script aborted.
  exit 1
fi

echo compiling Calculator popdown
cd apps/calculator
. bank3.sh $ozlocale
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/calculator/*.err
  echo Script aborted.
  exit 1
fi


# -------------------------------------------------------------------------------------------------
echo compiling bank 6
cd bank6
. bank6.sh
cd ..
if test `find . -name '*.err' | wc -l` != 0; then
  cat bank6/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling EazyLink
cd apps/eazylink
. make.eazylink.sh
cd ../..
if test `find . -name '*.err' | wc -l` != 0; then
  cat apps/eazylink/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
# ROM was compiled successfully, combine the compiled 16K banks into a complete 256K binary
echo Compiled Z88 ROM, now being combined into "oz.bin" file.
../tools/makeapp/makeapp.sh -f rom.loadmap

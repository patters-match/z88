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
  echo Compiling Swedish/Finish Z88 ROM
elif test "$ozlocale" = "FI"; then 
  echo Compiling Swedish/Finish Z88 ROM
else
  echo Unknown locale specified - using default UK
  ozlocale="UK"
fi 


# delete previous compiled files (incl error and warning files)...
. cleanup.sh

# -------------------------------------------------------------------------------------------------
echo compiling bank 1
cd bank1
. bank1.sh
cd ..
if test "`find . -name '*.err' | wc -l`" != 0; then
  cat bank1/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling kernel banks 0 and 7
. kernel.sh $ozlocale 
if test "`find . -name '*.err' | wc -l`" != 0; then
  cat bank0/*.err
  cat bank7/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling bank 2
cd bank2
. bank2.sh
cd ..
if test "`find . -name '*.err' | wc -l`" != 0; then
  cat bank2/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling bank 3
cd bank3
. bank3.sh
cd ..
if test "`find . -name '*.err' | wc -l`" != 0; then
  cat bank3/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
echo compiling bank 6
cd bank6
. bank6.sh
cd ..
if test "`find . -name '*.err' | wc -l`" != 0; then
  cat bank6/*.err
  echo Script aborted.
  exit 1
fi

# -------------------------------------------------------------------------------------------------
# ROM was compiled successfully, combine the compiled 16K banks 0-7 into a complete 128K binary
echo Compiled Z88 ROM, and combined into "oz.bin" file.
java -jar ../tools/makeapp/makeapp.jar -f rom.loadmap

#!/bin/bash

# **************************************************************************************************
# OZ Kernel compilation script for Unix.
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

COMPILE_ERROR=0

cd os

# create lowram.def and keymap.def (address pre-compilation) for lower & upper kernel compilation
# (argument $1 contains the country localisation)
cd lowram
../../../tools/mpm/mpm -g -DOZ_SLOT$1 $2 -I../../def @lowram.prj
if test $? -gt 0; then
  COMPILE_ERROR=1
fi
cd ..

# pre-compile (lower) kernel to resolve labels for lowram.asm
if test "$COMPILE_ERROR" -eq 0; then
  ../../tools/mpm/mpm -g -DOZ_SLOT$1 $2 -I../def -Ilowram @kernel0.prj
  if test $? -gt 0; then
    COMPILE_ERROR=1
  fi
fi

# create final lowram binary with correct addresses from lower kernel
cd lowram
if test "$COMPILE_ERROR" -eq 0; then
  ../../../tools/mpm/mpm -b -DOZ_SLOT$1 $2 -DCOMPILE_BINARY -I../../def @lowram.prj
  if test $? -gt 0; then
    COMPILE_ERROR=1
  fi
fi
cd ..

# compile final (upper) kernel binary with correct lowram code and correct lower kernel references
if test "$COMPILE_ERROR" -eq 0; then
  ../../tools/mpm/mpm -bg -DCOMPILE_BINARY -DOZ_SLOT$1 $2 -I../def -Ilowram -l../../stdlib/standard.lib @kernel1.prj
  if test $? -gt 0; then
    COMPILE_ERROR=1
  fi
fi

# compile final kernel binary with OS tables for bank 0 using correct upper kernel references
if test "$COMPILE_ERROR" -eq 0; then
  ../../tools/mpm/mpm -b -DCOMPILE_BINARY -DOZ_SLOT$1 $2 -I../def -Ilowram @kernel0.prj
  if test $? -gt 0; then
    COMPILE_ERROR=1
  fi
fi

if test "$COMPILE_ERROR" -eq 0; then
  ../../tools/mpm/mpm -b -DOZ_SLOT$1 -I../def @ostables.prj
  if test $? -gt 0; then
    COMPILE_ERROR=1
  fi
fi

cd ..

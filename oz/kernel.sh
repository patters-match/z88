#!/bin/bash

# **************************************************************************************************
# Kernel (banks 0,7) compilation script for Unix.
# This script is called with country localisation argument ('UK', 'DK', 'FR', 'FI' or 'SE').
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

COMPILE_ERROR=0

# create ostables.def (address pre-compilation) containing OS system base lookup table address in bank 0
cd bank0
../../tools/mpm/mpm -g ostables.asm
cd ..
if test "`find . -name '*.err' | wc -l`" != 0; then
  COMPILE_ERROR=1
fi

# create lowram.def and keymap.def (address pre-compilation) for kernel0.prj and kernel7.prj compilation
# (argument $1 contains the country localisation)
if test "$COMPILE_ERROR" = 0; then 
  cd bank7
  ../../tools/mpm/mpm -g -I../sysdef @lowram.prj
  ../../tools/mpm/mpm -bg -DKB"$1" -I../sysdef keymap.asm
  cd ..
fi
if test "`find . -name '*.err' | wc -l`" != 0; then
  COMPILE_ERROR=1
fi

# create application DOR data (binary) and address references for bank 2 compile script
if test "$COMPILE_ERROR" = 0; then 
  cd bank7
  ../../tools/mpm/mpm -bg -I../sysdef appdors.asm
  cd ..
fi
if test "`find . -name '*.err' | wc -l`" != 0; then
  COMPILE_ERROR=1
fi

# pre-compile kernel in bank 0 to resolve labels for lowram.asm
if test "$COMPILE_ERROR" = 0; then 
  cd bank0
  ../../tools/mpm/mpm -g -I../sysdef @kernel0.prj
  cd ..
fi
if test "`find . -name '*.err' | wc -l`" != 0; then
  COMPILE_ERROR=1
fi

# create final lowram binary with correct addresses from bank 0 kernel
if test "$COMPILE_ERROR" = 0; then 
  cd bank7
  ../../tools/mpm/mpm -b -DCOMPILE_BINARY -I../sysdef @lowram.prj
  cd ..
fi
if test "`find . -name '*.err' | wc -l`" != 0; then
  COMPILE_ERROR=1
fi

# compile final kernel binary for bank 7 with correct lowram code and correct bank 0 references
if test "$COMPILE_ERROR" = 0; then 
  cd bank7
  ../../tools/mpm/mpm -bg -DCOMPILE_BINARY -DKB"$1" -I../sysdef @kernel7.prj
  cd ..
if test "`find . -name '*.err' | wc -l`" != 0; then
  COMPILE_ERROR=1
fi

# compile final kernel binary with OS tables for bank 0 using correct bank 7 references
if test "$COMPILE_ERROR" = 0; then 
  cd bank0
  ../../tools/mpm/mpm -b -DCOMPILE_BINARY -I../sysdef @kernel0.prj
  ../../tools/mpm/mpm -b -DCOMPILE_BINARY ostables.asm
  cd ..
fi

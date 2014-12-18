#!/bin/bash

# ******************************************************************************************************************
#
#    ZZZZZZZZZZZZZZZZZZZZ    8888888888888       00000000000
#  ZZZZZZZZZZZZZZZZZZZZ    88888888888888888    0000000000000
#               ZZZZZ      888           888  0000         0000
#             ZZZZZ        88888888888888888  0000         0000
#           ZZZZZ            8888888888888    0000         0000       AAAAAA         SSSSSSSSSSS   MMMM       MMMM
#         ZZZZZ            88888888888888888  0000         0000      AAAAAAAA      SSSS            MMMMMM   MMMMMM
#       ZZZZZ              8888         8888  0000         0000     AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
#     ZZZZZ                8888         8888  0000         0000    AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
#   ZZZZZZZZZZZZZZZZZZZZZ  88888888888888888    0000000000000     AAAA      AAAA           SSSSS   MMMM       MMMM
# ZZZZZZZZZZZZZZZZZZZZZ      8888888888888       00000000000     AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM
#
# Z80asm compile script for Linux/Unix
# (C) Gunther Strube (gstrube@gmail.com) 1995-2006
#
# Z80asm is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# Z80asm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with Z80asm;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# ******************************************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/z80asm

# delete previously compiled files
rm -f *.obj *.bin *.map mth.def z80asm.epr z80asm.bn? z80asm.6?

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, Z80asm compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

# Compile the MTH, application code and rom header
mpm -b -I../../oz/def tokens
mpm -bg -I../../oz/def mth
mpm -b -cz80 -I../../oz/def -l../../stdlib/standard.lib @z80asm.prj
mpm -b -I../../oz/def romhdr

# Create an image with Z80asm application
z88card -f z80asm.loadmap

#!/bin/bash

# *************************************************************************************
# Z88 Standard Library Makefile for Unix/Linux
# (C) Gunther Strube (gstrube@gmail.com) 1991-2012
#
# This is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# The software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this software;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# Compile library routines into .obj files and generate the standard.lib file
# (to be used by other applications that needs to statically link routines from this library)
#
# The standard library is located in /stdlib
# The Z80 assembler is located in /tools/mpm
# The OZ Manifests are located in /oz/def

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, Standard library compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

# compile only updated source files and build the standard.lib file
mpm -I../oz/def -d -xstandard.lib @standard

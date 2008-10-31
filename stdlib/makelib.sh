#!/bin/bash

# *************************************************************************************
# Z88 Standard Library Makefile for Unix/Linux
# (C) Gunther Strube (gbs@users.sf.net) 1991-2005
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
# $Id$
#
# *************************************************************************************

# Compile library routines into .obj files and generate the standard.lib file
# (to be used by other applications that needs to statically link routines from this library)
#
# The standard library is located in /stdlib
# The Z80 assembler is located in /tools/mpm
# The OZ Manifests are located in /oz/def

# compile only updated source files and build the standard.lib file
../tools/mpm/mpm -I../oz/def -d -xstandard.lib @standard

#!/bin/bash

# **************************************************************************************************
# OZ ROM compilation cleanup script for Unix.
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
# $Id$
# ***************************************************************************************************

# delete all compile output files, if available..
rm -f oz-*.?? romupdate.cfg

# delete all compile output files
find . -name "*.bin" | xargs rm -f
find . -name "*.epr" | xargs rm -f
find . -name "*.map" | xargs rm -f
find . -name "*.err" | xargs rm -f
find . -name "*.obj" | xargs rm -f
find . -name "*.lst" | xargs rm -f
find . -name "*.err" | xargs rm -f
find . -name "*.sym" | xargs rm -f

# remove generated DEF files (they are part of the compile dependencies...)
rm -f mth\hires1.def
rm -f mth\keymaps.def
rm -f mth\lores1.def
rm -f mth\mth.def
rm -f os\kernel0.def
rm -f os\kernel1.def
rm -f os\lowram\lowram.def
rm -f apps\clcalalm.def
rm -f apps\clock\clcalalm.def
rm -f apps\impexport\impexp.def

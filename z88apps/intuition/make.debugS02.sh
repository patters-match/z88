#!/bin/bash

# *************************************************************************************
# Intuition make script for UNIX/LINUX to build executable for segment 2 address space
# (C) Gunther Strube (gbs@users.sourceforge.net) 1991-2005
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

# compile Intuition code from scratch
# Intuition uses segment 3 for bank switching (Intuition is located at $8000 - segment 2)
rm -f *.err *.lst *.def *.obj *.bin *.map
../../tools/mpm/mpm -b -DSEGMENT3 -r8000 -odebugS02.bin -I../../oz/def -l../../stdlib/standard.lib @debug

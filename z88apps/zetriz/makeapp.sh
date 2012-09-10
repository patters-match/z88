#!/bin/bash

# *************************************************************************************
# ZetriZ
# (C) Gunther Strube (gstrube@gmail.com) 1995-2006
#
# ZetriZ is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# ZetriZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with ZetriZ;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/zetriz

# Compile the MTH and the application code
rm -f *.obj *.sym *.bin *.map zetriz.epr
mpm -b -I../../oz/def -l../../stdlib/standard.lib @zetriz
mpm -b -I../../oz/def romhdr

# Create a 16K Rom Card with ZetriZ to be blown by RomCombiner, Zprom or RomUpdate on real cards
z88card -f zetriz.loadmap

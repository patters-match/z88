#!/bin/bash

# *************************************************************************************
# RomCombiner
# (c) Garry Lancaster, 2000 (yahoogroups@zxplus3e.plus.com)
#
# RomCombiner is free software# you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# RomCombiner is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with RomCombiner;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/romcombiner

rm -f *.obj *.bin *.map
../../tools/mpm/mpm -b -I../../oz/def -l../../stdlib/standard.lib romcombiner.asm ../romupdate/crc32.asm

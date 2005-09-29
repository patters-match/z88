#!/bin/bash

# *************************************************************************************
# FlashStore
# (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2005
#
# FlashStore is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with FlashStore;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
#
# *************************************************************************************

rm -f *.obj *.bin *.map *.epr
../../tools/mpm/mpm -b -I../../oz/sysdef -l../../stdlib/standard.lib @flashstore
../../tools/mpm/mpm -b romhdr

# Create a 16K Rom Card with FlashStore
java -jar ../../tools/makeapp/makeapp.jar flashstore.epr fsapp.bin 3f0000 romhdr.bin 3f3fc0

# Execute OZvm with preloaded FlashStore in slot 2 (on a 1Mb AMD Flash)
# and a 512K Intel Flash Card in slot 3
java -jar ../../tools/ozvm/z88.jar fcd3 512 28f crd2 1024 29f flashstore.epr

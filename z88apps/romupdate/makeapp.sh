#!/bin/bash

# *************************************************************************************
# RomUpdate
# (C) Gunther Strube (gbs@users.sf.net) 2005
#
# RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with RomUpdate;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
#
# *************************************************************************************

del *.obj *.bin *.map romupdate.epr
../../tools/mpm/mpm -b -I../../oz/sysdef -l../../stdlib/standard.lib @romupdate
../../tools/mpm/mpm -b romhdr

# Create a 16K Rom Card with RomUpdate
java -jar ../../tools/makeapp/makeapp.jar romupdate.epr romupdate.bin 3f0000 romhdr.bin 3f3fc0

# Execute OZvm with preloaded RomUpdate in slot 2 (on a 16K Eprom)
# and a 1MB Amd Flash Card in slot 3 preloaded with FlashStore
java -jar ../../tools/ozvm/z88.jar crd2 16 27c romupdate.epr crd3 1024 29f ../flashstore/flashstore.epr

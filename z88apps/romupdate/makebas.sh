#!/bin/bash

# *************************************************************************************
# RomUpdate - BBC BASIC compile script
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

del *.obj *.bin *.bas *.map
../../tools/mpm/mpm -b -I../../oz/sysdef -l../../stdlib/standard.lib @romupdate.bbcbasic.prj

# this is actually to be run as a BBC BASIC program on the Z88
mv bbcbasic.bin romupdate.bas

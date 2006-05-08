#!/bin/bash

# *************************************************************************************
# ZetriZ
# (C) Gunther Strube (gbs@users.sf.net) 1995-2006
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
# $Id$
#
# *************************************************************************************

rm -f *.obj *.bin *.map zetriz.epr

# Compile the MTH and the application code
../../tools/mpm/mpm -b -I../../oz/sysdef -l../../stdlib/standard.lib @zetriz
../../tools/mpm/mpm -b -I../../oz/sysdef romhdr

# Create a 16K Rom Card with ZetriZ
java -jar ../../tools/makeapp/makeapp.jar -sz 16 zetriz.epr zetriz.bin 3fc000 romhdr.bin 3f3fc0

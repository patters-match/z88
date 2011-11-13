#!/bin/bash

# *************************************************************************************
# XY-Modem popdown make script for Unix/Linux/MAC OS X
# (C) Dennis Groning (dennisgr@algonet.se) 1999-2008
#
# XY-Modem is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# XY-Modem is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with XY-Modem;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

# compile XY-Modem popdown from scratch
rm -f *.obj *.bin *.map *.63 *.epr
../../tools/mpm/mpm -b -I../../oz/def xy-modem.asm

# Create a 16K Rom Card with XY-Modem
../../tools/makeapp/makeapp.sh xy-modem.epr xy-modem.bin 32d4

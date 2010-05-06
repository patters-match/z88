#!/bin/bash

# *************************************************************************************
# EP-Fetch2 application make script for Unix/Linux
#
# EP-Fetch2 is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# EP-Fetch2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with EP-Fetch2;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
#
# *************************************************************************************

# compile EazyLink application from scratch
rm -f *.obj *.bin *.map
../../tools/mpm/mpm -bg -I../../oz/def epfetch2
../../tools/mpm/mpm -b romhdr

# Create a 16K Rom Card with EP-Fetch2
../../tools/makeapp/makeapp.sh -f epfetch2.loadmap

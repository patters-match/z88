#!/bin/bash

# *************************************************************************************
# Zprom + FlashTest make script
# (C) Gunther Strube (gbs@users.sf.net) 2006
#
# Zprom & FlashTest is free software; you can redistribute it and/or modify it under
# the terms of theGNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# Zprom & FlashTest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with Zprom & FlashTest;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
# *************************************************************************************

# ensure that we have an up-to-date standard library
cd ../../stdlib; ./makelib.sh; cd ../z88apps/zprom

# Compile the MTH and the application code
rm -f *.obj *.bin *.map zprom.epr
../../tools/mpm/mpm -b -I../../oz/sysdef tokens
../../tools/mpm/mpm -bg -I../../oz/sysdef mthzprom
../../tools/mpm/mpm -b -I../../oz/sysdef -l../../stdlib/standard.lib @zprom
../../tools/mpm/mpm -b -I../../oz/sysdef romhdr

# Compile FlashTest to reside at $EB00 in bank $3F
../../tools/mpm/mpm -rEB00 -I../../oz/sysdef -l../../stdlib/standard.lib -b ../flashtest/fltest.asm

# Create a 32K Rom Card with Zprom and FlashTest ($3E contains MTH, $3F contains application code for Zprom and FlashTest)
java -jar ../../tools/makeapp/makeapp.jar -f zprom+flashtest.loadmap
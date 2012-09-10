#!/bin/bash

# *************************************************************************************
#
# UUtools compile script for Linux/Unix/MAC OSX
# UUtools utility, (c) Garry Lancaster, 2000-2001
#
# UUtools is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# UUtools is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with UUtools;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# *************************************************************************************

rm *.6? *.bin zcc_opt.def *.epr

# Compile the application & package with z88dk
zcc -lz88 -create-app -make-app -o uutools.bin uutools.c uuapp.c mimepkg.c

# Create a 16K Rom Card with UUtools, and generate a proper card Id
z88card -f uutools.loadmap


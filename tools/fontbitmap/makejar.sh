#!/bin/bash

# *************************************************************************************
# Unix compile script for FontBitMap - Z88 Font Bitmap Source Code Generator
# (C) Gunther Strube (gbs@users.sf.net) 2003-2006
#
# FontBitMap is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# FontBitMap is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with FontBitMap;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
#
# ------------------------------------------------------------------------------------
# Before executing this script, a Java 1.4 Runtime Environment or later must have been
# installed.
#
# To test the availablity of command line java interpreter, just type "java -version".
# This will display the version and the runtime options to your console window.
# ------------------------------------------------------------------------------------
#
# *************************************************************************************

# create a temporary dir for files to be included in the executable JAR file
mkdir ../fontbitmap-builddir

# compile the java classes of the project
echo compiling java classes
java -jar ../jdk/ecj.jar -d ../fontbitmap-builddir -nowarn -g:none -source 1.4 -target 1.4 net

# finally, build the executable jar
cd ../fontbitmap-builddir
java -jar ../jdk/makejar.jar -cm ../fontbitmap/fontbitmap.jar ../fontbitmap/META-INF/MANIFEST.MF .

# clean up the temp build stuff
cd ../fontbitmap
rm -fR ../fontbitmap-builddir
echo fontbitmap.jar completed.

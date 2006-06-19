#!/bin/bash

# *************************************************************************************
# Unix compile script for OZvm - the Z88 emulator.
# (C) Gunther Strube (gbs@users.sf.net) 2003-2005
#
# OZvm is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# OZvm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with OZvm;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
#
# ------------------------------------------------------------------------------------
# Before executing this script, a Java Development Kit 1.4 or later must have been
# installed and the PATH environment variable set to the <jdk install>/bin folder.
#
# To test the availablity of command line java compiler, just type "javac -version".
# This will display the version and the compile options to your console window.
#
# *************************************************************************************

# create a temporary dir for files to be included in the executable JAR file
mkdir ../ozvm-builddir

# compile the java classes of the project
echo compiling java classes
java -jar ../jdk/ecj.jar -d ../ozvm-builddir -nowarn -g:none -source 1.4 -target 1.4 com net

# copy the remaining application files 
echo building executable jar
cp -fR pixel ../ozvm-builddir
cp -f ./ozvm-manual.html ../ozvm-builddir
cp -f ./Z88.rom ../ozvm-builddir

# finally, build the executable jar
cd ../ozvm-builddir
jar cfm ../ozvm/z88.jar ../ozvm/META-INF/MANIFEST.MF .

# clean up the temp build stuff
cd ../ozvm
rm -fR ../ozvm-builddir
echo z88.jar completed.

#!/bin/bash

# *************************************************************************************
# Unix compile script for OZvm - the Z88 emulator.
# (C) Gunther Strube (gstrube@gmail.com) 2003-2011
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
mkdir ../ozvm-builddir

# compile the java classes of the project
echo compiling java classes
java -jar ../jdk/ecj.jar -d ../ozvm-builddir -nowarn -g:none -source 1.4 -target 1.4 src/com

# copy the remaining application files 
echo building executable jar
cp -fR src/pixel ../ozvm-builddir
cp -f src/ozvm-manual.html ../ozvm-builddir

# JAR file only needs (compiled) class files and other embedded resources
find ../ozvm-builddir -name '.svn' | xargs rm -fR

# finally, build the executable jar
cd ../ozvm-builddir
java -jar ../jdk/makejar.jar -cm ../ozvm/z88.jar ../ozvm/src/META-INF/MANIFEST.MF .

# clean up the temp build stuff
cd ../ozvm
rm -fR ../ozvm-builddir
echo z88.jar completed.

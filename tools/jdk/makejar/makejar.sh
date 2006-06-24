#!/bin/bash

# *************************************************************************************
# Unix compile script for MakeJar - the Java Archive tool.
# (C) Gunther Strube (gbs@users.sf.net) 2006
#
# MakeJar is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# MakeJar is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with MakeJar;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id: makejar.sh 2358 2006-06-22 23:16:17Z gbs $
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
mkdir ../makejar-builddir

# compile the java classes of the project
echo compiling java classes
java -jar ../ecj.jar -d ../makejar-builddir -nowarn -g:none -source 1.4 -target 1.4 net

# finally, build the executable jar
cd ../makejar-builddir
java -jar ../makejar.jar -cm ../makejar.jar ../makejar/META-INF/MANIFEST.MF .

# clean up the temp build stuff
cd ../makejar
rm -fR ../makejar-builddir
echo makejar.jar completed.

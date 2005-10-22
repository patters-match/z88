#!/bin/bash

# *************************************************************************************
# Unix compile script for MakeApp - the Z88 Application Card Generator.
# (C) Gunther Strube (gbs@users.sf.net) 2005
#
# MakeApp is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
# MakeApp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with MakeApp;
# see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$
#
# ------------------------------------------------------------------------------------
# Before executing this script, a Java Development Kit 1.4 or later must have been
# installed and the PATH environment variable set to the <jdk install>\bin folder.
#
# To test the availablity of command line java compiler, just type "javac -version".
# This will display the version and the compile options to your console window.
#
# *************************************************************************************

# compile the java classes of the project
echo compiling java classes
javac -nowarn -g:none net/sourceforge/z88/tools/*.java

# create a temporary dir for files to be included in the executable JAR file
mkdir ../makeapp-builddir

# copy all application files (without hidden files)
echo building executable jar
cp -fR net ../makeapp-builddir

# JAR file only needs (compiled) class files (*.java files are redundant)
find ../makeapp-builddir -name '*.java' | xargs rm
find ../ozvm-builddir -name '.svn' | xargs rm -fR

# finally, build the executable jar
cd ../makeapp-builddir
jar cfm ../makeapp/makeapp.jar ../makeapp/META-INF/MANIFEST.MF .

# clean up the temp build stuff
cd ../makeapp
rm -fR ../makeapp-builddir
echo makeapp.jar completed.
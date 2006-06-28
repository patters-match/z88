#!/bin/bash

# *************************************************************************************
# Unix execute script and auto-compiler for MakeApp - the Z88 Application Card Generator.
# (C) Gunther Strube (gbs@users.sf.net) 2006
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
# The purpose of this script is to poll for the existence of the makeapp.jar java
# executable archive, and automatically execute it, if it exists. If not, it will 
# automatically be compiled, then executed, completely transparent to the calling script.
# ------------------------------------------------------------------------------------
#
# *************************************************************************************

# remember the current path from where this script is called
RETURN_PATH=$PWD

# get the relative path to this script (to be used for change directory command)
MAKEAPP_PATH=$0
MAKEAPP_PATH=${MAKEAPP_PATH/makeapp.sh/}

# define the '<path>/makeapp.jar' filename, based on this script name...
MAKEAPP_JAR=$0
MAKEAPP_JAR=${MAKEAPP_JAR/.sh/.jar}

if [ ! -f "$MAKEAPP_JAR" ]; then
  # the makeapp.jar has not yet been compiled,
  # to compile it, change to /makeapp directory (temporarily)...
  cd $MAKEAPP_PATH
  
  # compile the makeapp.jar file, but suppress the output messages while compiling
  # (the outside calling script should be unaware of the compilation)
  . makejar.sh > /dev/null
  
  # now, return back to the original path from where this script was called...
  cd $RETURN_PATH
fi

# execute the makeapp executable and supply the arguments that was assigned this script
java -jar $MAKEAPP_JAR "$@"

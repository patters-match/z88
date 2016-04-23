#!/bin/bash

# *************************************************************************************
#
# Z-Help + Z-Macro compile script for Linux/Unix/MAC OSX
#
# *************************************************************************************

rm -f *.obj *.sym *.bin *.map

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, PDrom compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

# Assemble the applications for $C000 in bank 62
mpm -b -I../../oz/def -rC000 zhelp+zmacro.asm


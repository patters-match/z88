#!/bin/bash

# *************************************************************************************
#
# ZipUp & UnZip & XY-modem compile script for Linux/Unix/MAC OSX
#
# *************************************************************************************

# compile XY-Modem popdown from scratch
cd ../xymodem
rm -f *.obj *.bin *.map

if test $? -lt 15; then
  echo Mpm version is less than V1.5, XY-Modem compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

mpm -b -I../../oz/def xy-modem.asm
cd ../ziputils

# --------------------------------------------------------------------

cd unzip; ./makeapp.sh; cd ..
cd zipup; ./makeapp.sh; cd ..

# Create a 16K Rom Card with ZipUp & Unzip & XY-modem
z88card -f ziputils+xymodem.loadmap
